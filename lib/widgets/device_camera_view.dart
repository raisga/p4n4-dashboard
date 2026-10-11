import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import '../api/camera.dart' show CameraLens;
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// The camera plugin previews on Android, iOS and in browsers; not on desktop.
bool get deviceCameraSupported =>
    kIsWeb || const {TargetPlatform.android, TargetPlatform.iOS}.contains(defaultTargetPlatform);

/// Done when every camera this app closed has been released, so the next one
/// opens on a free camera.
Future<void> _released = Future.value();

/// The last orientation a camera reported. Android's camera plugin reports it
/// only when the motion sensor sees a change, so a camera opened on a device
/// lying still would preview as if in portrait, sideways in landscape, until
/// the device moves. A new camera starts from this one instead.
DeviceOrientation? _lastOrientation;

bool _isLandscape(DeviceOrientation o) => o == DeviceOrientation.landscapeLeft || o == DeviceOrientation.landscapeRight;

/// A live preview of one of this device's own cameras (a `device:` camera),
/// e.g. a phone in a car as its dash cam. The camera is open only while
/// [active] and the app is in the foreground, so other apps can use it the
/// rest of the time. No audio, nothing recorded.
///
/// The plugin keeps one of the device's cameras open at a time: opening a
/// second one leaves the first on its last frame. So only one view should be
/// [active]; [onShow] puts a button on the others to switch.
class DeviceCameraView extends StatefulWidget {
  const DeviceCameraView({super.key, required this.lens, this.active = true, this.onShow});

  final CameraLens lens;

  /// When false the camera is closed (e.g. the tab is hidden).
  final bool active;

  /// While not [active]: makes this the live camera (shown as a button).
  final VoidCallback? onShow;

  @override
  State<DeviceCameraView> createState() => DeviceCameraViewState();
}

class DeviceCameraViewState extends State<DeviceCameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _error;

  /// The device has no camera facing [DeviceCameraView.lens].
  bool _missing = false;
  bool _foreground = true;

  P4Colors get p4 => context.p4;

  bool get _wanted => widget.active && _foreground && deviceCameraSupported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_wanted) _open();
  }

  @override
  void didUpdateWidget(DeviceCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lens != widget.lens || oldWidget.active != widget.active) {
      _sync(restart: oldWidget.lens != widget.lens);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android takes the camera from a backgrounded app: close it, reopen on return.
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _close();
    super.dispose();
  }

  /// Opens the camera again (after an error, or to pick up a freed camera).
  void reconnect() => _sync(restart: true);

  void _sync({bool restart = false}) {
    if (restart || !_wanted) _close();
    if (_wanted && _controller == null) {
      _open();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _close() {
    if (_controller case final c?) _released = Future.wait([_released, c.dispose().catchError((_) {})]);
    _controller = null;
  }

  Future<void> _open() async {
    setState(() {
      _error = null;
      _missing = false;
    });
    CameraController? c;
    try {
      await _released;
      final all = await availableCameras();
      final want = widget.lens == CameraLens.front ? CameraLensDirection.front : CameraLensDirection.back;
      final description = all.where((d) => d.lensDirection == want).firstOrNull;
      if (!mounted || !_wanted || _controller != null) return;
      if (description == null) return setState(() => _missing = true);
      c = _controller = CameraController(description, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      if (_controller != c || !mounted) return;
      _seedOrientation(c, landscape: MediaQuery.orientationOf(context) == Orientation.landscape);
      setState(() {});
    } catch (e) {
      // Closed or reopened meanwhile: that camera's error is stale.
      if (c != null && _controller != c) return;
      _close();
      if (mounted) setState(() => _error = e is CameraException ? (e.description ?? e.code) : e);
    }
  }

  /// Starts [c] from [_lastOrientation] when what it has contradicts the
  /// screen's [landscape], then keeps [_lastOrientation] up to date from it.
  void _seedOrientation(CameraController c, {required bool landscape}) {
    if (_lastOrientation case final last?
        when _isLandscape(last) == landscape && _isLandscape(c.value.deviceOrientation) != landscape) {
      c.value = c.value.copyWith(deviceOrientation: last);
    }
    var reported = c.value.deviceOrientation;
    if (_isLandscape(reported) == landscape) _lastOrientation = reported;
    c.addListener(() {
      if (c.value.deviceOrientation != reported) _lastOrientation = reported = c.value.deviceOrientation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (!deviceCameraSupported)
          _message(l.deviceCameraUnsupported(defaultTargetPlatform.name), null)
        else if (_missing)
          _message(l.deviceCameraMissing, null)
        else if (_error != null)
          _message('$_error', OutlinedButton(onPressed: reconnect, child: Text(l.retry)))
        else if (c != null && c.value.isInitialized) ...[
          Center(child: CameraPreview(c)),
          _badge(),
        ] else if (_wanted)
          Center(child: CircularProgressIndicator(color: p4.accent))
        else if (widget.onShow case final show?)
          _message(l.deviceCameraOneAtATime, OutlinedButton(onPressed: show, child: Text(l.deviceCameraShow))),
      ],
    );
  }

  Widget _message(String text, Widget? action) => Center(
    child: Container(
      padding: const EdgeInsets.all(16),
      color: p4.bg.withValues(alpha: 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, color: widget.active ? p4.err : p4.muted),
          const SizedBox(height: 8),
          Text(
            text,
            style: p4.mono(size: 11, color: p4.text),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    ),
  );

  /// "Live · Back camera", where `MjpegView` shows "Live · MJPEG".
  Widget _badge() => Positioned(
    left: 12,
    top: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black54,
      child: Text(
        '${context.l10n.cameraLive} · ${widget.lens == CameraLens.front ? context.l10n.frontCamera : context.l10n.backCamera}',
        style: p4.mono(size: 10, color: P4Colors.dark.text),
      ),
    ),
  );
}
