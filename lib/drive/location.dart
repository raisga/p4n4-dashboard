import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geo.dart';

/// Where this phone's location stands.
enum LocationStatus {
  /// Nothing needs it.
  off,

  /// This platform has none the app can use (desktop, browsers).
  unsupported,

  /// The app may not use it.
  denied,

  /// The phone's location is turned off.
  disabled,

  /// On, no fix yet.
  waiting,

  /// Fixes are coming in.
  live,
}

/// This phone's GPS, for the Map tab, the GPS publisher and the dashcam's
/// GPX sidecars: on while any of them has [acquire]d it, until the last one
/// [release]s it. While the app is open only.
class LocationService extends ChangeNotifier {
  static bool get supported =>
      !kIsWeb && const {TargetPlatform.android, TargetPlatform.iOS}.contains(defaultTargetPlatform);

  LocationStatus get status => _status;
  var _status = LocationStatus.off;

  /// The latest fix, kept when the GPS goes off.
  Fix? get last => _last;
  Fix? _last;

  /// The way driven since the app opened.
  final track = Track();

  /// Each fix as it comes.
  Stream<Fix> get fixes => _fixes.stream;
  final _fixes = StreamController<Fix>.broadcast();

  int _users = 0;
  int _generation = 0;
  StreamSubscription<Position>? _positions;
  StreamSubscription<ServiceStatus>? _service;

  void acquire() {
    if (_users++ == 0) unawaited(_start());
  }

  void release() {
    if (_users == 0) return;
    if (--_users == 0) _stop();
  }

  /// Asks again: after a denial, or with location turned back on.
  Future<void> retry() async {
    if (_users == 0) return;
    _stop();
    await _start();
  }

  Future<void> _start() async {
    if (!supported) return _set(LocationStatus.unsupported);
    final generation = ++_generation;
    bool current() => generation == _generation;
    _set(LocationStatus.waiting);
    _watchService(generation);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (current()) _set(LocationStatus.disabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && current()) permission = await Geolocator.requestPermission();
      if (!current()) return;
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return _set(LocationStatus.denied);
      }
      _positions = Geolocator.getPositionStream(locationSettings: _settings()).listen(
        _onPosition,
        onError: (Object e) {
          if (!current()) return;
          _positions?.cancel();
          _positions = null;
          _set(switch (e) {
            LocationServiceDisabledException() => LocationStatus.disabled,
            _ => LocationStatus.denied,
          });
        },
      );
    } on PermissionDefinitionsNotFoundException {
      if (current()) _set(LocationStatus.unsupported);
    } catch (_) {
      if (current()) _set(LocationStatus.denied);
    }
  }

  /// Starts over when the phone's location comes back on (Android tells).
  void _watchService(int generation) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _service = Geolocator.getServiceStatusStream().listen((s) {
        if (generation != _generation) return;
        if (s == ServiceStatus.enabled && _status == LocationStatus.disabled) {
          unawaited(retry());
        } else if (s == ServiceStatus.disabled) {
          _set(LocationStatus.disabled);
        }
      }, onError: (Object _) {});
    } catch (_) {
      // No service updates here: Try again does it.
    }
  }

  LocationSettings _settings() => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: const Duration(seconds: 1),
    ),
    TargetPlatform.iOS => AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      activityType: ActivityType.automotiveNavigation,
      allowBackgroundLocationUpdates: false,
    ),
    _ => const LocationSettings(accuracy: LocationAccuracy.high),
  };

  void _onPosition(Position p) {
    final fix = Fix(
      lat: p.latitude,
      lon: p.longitude,
      time: p.timestamp,
      alt: p.hasAltitude ? p.altitude : null,
      // A negative speed or course means unknown (iOS).
      speed: p.hasSpeed && p.speed >= 0 ? p.speed : null,
      heading: p.hasHeading && p.heading >= 0 ? p.heading : null,
      accuracy: p.hasAccuracy ? p.accuracy : null,
    );
    _last = fix;
    track.add(fix);
    _fixes.add(fix);
    _set(LocationStatus.live, always: true);
  }

  void _stop() {
    _generation++;
    _positions?.cancel();
    _positions = null;
    _service?.cancel();
    _service = null;
    _set(LocationStatus.off);
  }

  void _set(LocationStatus status, {bool always = false}) {
    if (status == _status && !always) return;
    _status = status;
    notifyListeners();
  }
}
