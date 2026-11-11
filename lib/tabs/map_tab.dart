import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../core/settings.dart';
import '../core/theme.dart';
import '../drive/dashcam.dart';
import '../drive/drive_scope.dart';
import '../drive/geo.dart';
import '../drive/location.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/dashcam_controls.dart';

/// Whether the Map tab shows a map here: in the Android and iOS apps
/// (MapLibre Native). Elsewhere it says it can't.
bool get mapSupported => !kIsWeb && const {TargetPlatform.android, TargetPlatform.iOS}.contains(defaultTargetPlatform);

/// Where the map comes from.
enum MapSource {
  /// The deployment's own map, from its tiles: no internet needed.
  offline,

  /// [AppSettings.mapFallbackUri], while the deployment's can't be reached.
  online,
}

typedef MapStyle = ({Uri style, MapSource source});

/// The map to show: [own], the deployment's style, if it answers within
/// [timeout] with one; else [fallback], online.
Future<MapStyle> pickMapStyle(
  Uri own,
  Uri fallback, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final r = await (client?.get ?? http.get)(own).timeout(timeout);
    final body = r.statusCode == 200 ? jsonDecode(r.body) : null;
    if (body case {'version': 8, 'sources': Map()}) return (style: own, source: MapSource.offline);
  } catch (_) {
    // Down, or not a map: the fallback.
  }
  return (style: fallback, source: MapSource.online);
}

/// The phone on a map, with the way driven since the app opened: the
/// deployment's own map ([AppSettings.mapStyleUri]), which needs no signal,
/// else an online one. Follows the phone, turned the way it's going, and
/// keeps the screen on while in front. The dashcam starts and saves here too.
///
/// Made the first time it's shown, then kept. Android and iOS only.
class MapTab extends StatefulWidget {
  const MapTab({super.key, required this.active});

  final bool active;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const _trackSource = 'p4n4-track';
  static const _trackLayer = 'p4n4-track-line';
  static const _zoom = 15.0;

  AppSettings? _settings;
  DriveServices? _drive;

  /// What holds the GPS and the screen on: the services while in front.
  DriveServices? _held;
  StreamSubscription<Fix>? _fixes;
  Timer? _redraw;

  /// Shown once: the map exists from then on.
  bool _shown = false;
  MapStyle? _map;
  (Uri, Uri)? _pickedFor;
  bool _picking = false;

  ml.MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _following = true;

  /// The map has been brought in to a street's zoom, at a fix.
  bool _zoomed = false;

  /// That zoom is running. MapLibre stops following on any camera call, so
  /// the stop it reports meanwhile isn't the driver's.
  bool _zooming = false;
  int _drawn = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = SettingsScope.of(context);
    _drive = DriveScope.maybeOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  @override
  void dispose() {
    _letGo();
    super.dispose();
  }

  /// Holds the GPS and the screen while in front; picks the map, again when
  /// its settings change or, on the online one, each time it comes to front.
  void _sync() {
    final drive = widget.active && mapSupported ? _drive : null;
    final arriving = drive != null && drive != _held;
    if (arriving) {
      _letGo();
      _hold(drive);
    } else if (drive == null) {
      _letGo();
    }
    if (drive != null) unawaited(_pick(recheck: arriving));
  }

  void _hold(DriveServices drive) {
    _held = drive;
    _shown = true;
    drive.location.acquire();
    drive.awake.hold();
    _fixes = drive.location.fixes.listen(_onFix);
    _redraw = Timer.periodic(const Duration(seconds: 2), (_) => _drawTrack());
    if (drive.location.last case final last?) _onFix(last);
  }

  void _letGo() {
    final drive = _held;
    if (drive == null) return;
    _held = null;
    unawaited(_fixes?.cancel());
    _fixes = null;
    _redraw?.cancel();
    _redraw = null;
    drive.location.release();
    drive.awake.release();
  }

  Future<void> _pick({bool recheck = false, bool force = false}) async {
    final settings = _settings;
    if (settings == null || _picking) return;
    final wanted = (settings.mapStyleUri, settings.mapFallbackUri);
    final online = _map?.source == MapSource.online;
    if (!force && _pickedFor == wanted && !(recheck && online)) return;
    _picking = true;
    try {
      final picked = await pickMapStyle(wanted.$1, wanted.$2);
      if (!mounted) return;
      _pickedFor = wanted;
      if (picked.style != _map?.style) {
        // A new map, with its own controller.
        _controller = null;
        _styleReady = false;
      }
      _map = picked;
    } finally {
      _picking = false;
      if (mounted) setState(() {});
    }
    // The settings changed meanwhile.
    if (mounted && _held != null) unawaited(_pick());
  }

  void _recheck() {
    unawaited(_pick(force: true));
    setState(() {});
  }

  void _onMapCreated(ml.MapLibreMapController c) {
    _controller = c;
    _styleReady = false;
    _zoomed = false;
  }

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null) return;
    _styleReady = true;
    _drawn = -1;
    final location = _drive?.location;
    // A new style has none of the app's own sources and layers.
    await _quietly(() => c.addGeoJsonSource(_trackSource, location?.track.toGeoJson() ?? _noTrack));
    if (!mounted) return;
    await _quietly(
      () => c.addLineLayer(
        _trackSource,
        _trackLayer,
        ml.LineLayerProperties(
          lineColor: _hex(context.p4.accent),
          lineWidth: 5,
          lineOpacity: 0.8,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      ),
    );
    _drawn = location?.track.revision ?? -1;
    if (location?.last case final last?) _onFix(last);
  }

  static const _noTrack = <String, Object>{'type': 'FeatureCollection', 'features': <Object>[]};

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  void _onFix(Fix fix) {
    final c = _controller;
    if (c == null || !_styleReady) return;
    final at = ml.LatLng(fix.lat, fix.lon);
    unawaited(
      _quietly(
        () => c.updateManualLocation(
          ml.ManualLocationUpdate(
            target: at,
            horizontalAccuracy: fix.accuracy,
            altitude: fix.alt,
            bearing: fix.heading,
            speed: fix.speed,
            timestamp: fix.time,
          ),
        ),
      ),
    );
    if (_zoomed) return;
    _zoomed = true;
    unawaited(
      _quietly(() async {
        _zooming = true;
        try {
          await c.animateCamera(ml.CameraUpdate.newLatLngZoom(at, _zoom));
        } finally {
          _zooming = false;
        }
        if (_following && mounted) await c.updateMyLocationTrackingMode(ml.MyLocationTrackingMode.trackingGps);
      }),
    );
  }

  void _drawTrack() {
    final c = _controller, location = _held?.location;
    if (c == null || !_styleReady || location == null || location.track.revision == _drawn) return;
    _drawn = location.track.revision;
    unawaited(_quietly(() => c.setGeoJsonSource(_trackSource, location.track.toGeoJson())));
  }

  void _follow() {
    setState(() => _following = true);
    final c = _controller;
    if (c != null) unawaited(_quietly(() => c.updateMyLocationTrackingMode(ml.MyLocationTrackingMode.trackingGps)));
  }

  /// A map call that may fail harmlessly: the map closing, or its style
  /// still loading. The next fix tries again.
  static Future<void> _quietly(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final drive = _drive;
    if (!mapSupported || drive == null) {
      return EmptyState(icon: Icons.map_outlined, title: l.mapUnavailable, message: l.mapUnavailableMsg);
    }
    if (!_shown) return const SizedBox.expand();
    final map = _map;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (map == null) Center(child: CircularProgressIndicator(color: context.p4.accent)) else _mapView(map),
        Positioned(
          top: 12,
          left: 12,
          right: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListenableBuilder(listenable: drive.location, builder: (context, _) => _locationPill(drive.location)),
              if (map != null) ...[
                const SizedBox(height: 8),
                _MapPill(
                  icon: map.source == MapSource.offline ? Icons.cloud_off : Icons.public,
                  text: map.source == MapSource.offline ? l.mapOffline : l.mapOnline,
                  tooltip: l.mapRecheck,
                  busy: _picking,
                  onTap: _picking ? null : _recheck,
                ),
              ],
            ],
          ),
        ),
        if (Dashcam.supported)
          Positioned(
            left: 12,
            bottom: 12,
            right: 72,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: DashcamChip(dashcam: drive.dashcam),
            ),
          ),
        if (!_following && map != null)
          Positioned(
            right: 12,
            bottom: 48,
            child: IconButton.filled(tooltip: l.mapFollow, onPressed: _follow, icon: const Icon(Icons.navigation)),
          ),
      ],
    );
  }

  Widget _mapView(MapStyle map) {
    final last = _drive?.location.last;
    return ml.MapLibreMap(
      key: ValueKey(map.style),
      styleString: map.style.toString(),
      initialCameraPosition: last == null
          ? const ml.CameraPosition(target: ml.LatLng(20, 0), zoom: 1)
          : ml.CameraPosition(target: ml.LatLng(last.lat, last.lon), zoom: _zoom),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      // The app's own fixes (LocationService), which also feed the dashcam
      // and the GPS publisher: no second location engine.
      locationSource: const ml.ManualLocationSource(),
      myLocationEnabled: true,
      myLocationTrackingMode: _following ? ml.MyLocationTrackingMode.trackingGps : ml.MyLocationTrackingMode.none,
      myLocationRenderMode: defaultTargetPlatform == TargetPlatform.android
          ? ml.MyLocationRenderMode.gps
          : ml.MyLocationRenderMode.normal,
      onCameraTrackingDismissed: () {
        if (mounted && !_zooming) setState(() => _following = false);
      },
    );
  }

  Widget _locationPill(LocationService location) {
    final l = context.l10n;
    return switch (location.status) {
      LocationStatus.off => const SizedBox.shrink(),
      LocationStatus.live => _SpeedPill(kmh: location.last?.speedKmh),
      LocationStatus.waiting => _MapPill(icon: Icons.gps_not_fixed, text: l.mapLocating, busy: true),
      LocationStatus.denied => _MapPill(
        icon: Icons.location_disabled,
        text: l.mapLocationDenied,
        tooltip: l.retry,
        error: true,
        onTap: location.retry,
      ),
      LocationStatus.disabled => _MapPill(
        icon: Icons.location_off,
        text: l.mapLocationOff,
        tooltip: l.retry,
        error: true,
        onTap: location.retry,
      ),
      LocationStatus.unsupported => _MapPill(
        icon: Icons.location_disabled,
        text: l.mapLocationUnsupported,
        error: true,
      ),
    };
  }
}

/// A rounded label over the map.
class _MapPill extends StatelessWidget {
  const _MapPill({
    required this.icon,
    required this.text,
    this.tooltip,
    this.onTap,
    this.busy = false,
    this.error = false,
  });

  final IconData icon;
  final String text;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool busy;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    const shape = StadiumBorder();
    final pill = Material(
      color: p4.bg.withValues(alpha: 0.92),
      shape: shape.copyWith(side: BorderSide(color: error ? p4.err : p4.border)),
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
              else
                Icon(icon, size: 16, color: error ? p4.err : p4.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(text, style: p4.body(size: 13, color: p4.text)),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}

/// The speed, big enough to read at a glance.
class _SpeedPill extends StatelessWidget {
  const _SpeedPill({required this.kmh});

  final double? kmh;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Material(
      color: p4.bg.withValues(alpha: 0.92),
      shape: StadiumBorder(side: BorderSide(color: p4.border)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(kmh == null ? '–' : '${kmh!.round()}', style: p4.display(size: 26, color: p4.heading)),
            const SizedBox(width: 6),
            Text(context.l10n.mapKmh, style: p4.mono(size: 11, color: p4.muted)),
          ],
        ),
      ),
    );
  }
}
