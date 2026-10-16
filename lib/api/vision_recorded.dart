import 'dart:async';

import 'package:flutter/foundation.dart';

import 'camera.dart';
import 'vision.dart';

/// The measured clips' vision, on a clock of its own: each camera whose video
/// file the project has measured ([VisionCamera.recording]) loops through its
/// behaviours from when it's first followed, whichever tab is open and whether
/// or not its video is on screen, and reports each occurrence ([onVerdict]),
/// as [LiveVision] does a live verdict. The Video tab keeps its videos in step
/// with [secondsOf], so what it draws is what raised the alert.
class RecordedVision {
  RecordedVision({this.onVerdict, DateTime Function()? now, this.interval = const Duration(milliseconds: 250)})
    : _now = now ?? DateTime.now {
    _epoch = _now();
  }

  /// Each occurrence of a behaviour, as its window starts: where alerts come from.
  final void Function(Camera camera, VisionBehavior behavior)? onVerdict;

  /// How often the clocks are read: behaviours last seconds.
  final Duration interval;
  final DateTime Function() _now;
  late final DateTime _epoch;

  final _tracks = <String, _Track>{};
  Timer? _timer;

  double get _seconds => _now().difference(_epoch).inMicroseconds / 1e6;

  /// Follows [cameras] (the Video tab's), by what [bundle] measured of them.
  /// A camera already followed keeps its clock, so a refetched bundle or a
  /// renamed camera doesn't restart it; the rest start theirs now.
  void follow(List<Camera> cameras, VisionBundle? bundle) {
    final now = _seconds;
    final next = <String, _Track>{};
    for (final c in cameras) {
      final recording = c.isVideo ? bundle?.camera(c.id)?.recording : null;
      if (recording == null) continue;
      next[c.id] = switch (_tracks[c.id]) {
        final t? when t.camera.url == c.url =>
          t
            ..camera = c
            ..recording = recording,
        _ => _Track(c, recording, now),
      };
    }
    _tracks
      ..clear()
      ..addAll(next);
    if (_tracks.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(interval, (_) => tick());
    }
  }

  /// Seconds into [camera]'s clip by its clock, if it's followed.
  double? secondsOf(String camera) {
    final t = _tracks[camera];
    if (t == null || t.recording.duration <= 0) return null;
    return (_seconds - t.start) % t.recording.duration;
  }

  /// Reads every clock, reporting the behaviours that have just started.
  @visibleForTesting
  void tick() {
    final now = _seconds;
    for (final t in _tracks.values) {
      final behavior = t.recording.behaviorAt(now - t.start);
      if (behavior?.key == t.last) continue;
      t.last = behavior?.key;
      if (behavior != null) onVerdict?.call(t.camera, behavior);
    }
  }

  void dispose() {
    _timer?.cancel();
    _tracks.clear();
  }
}

class _Track {
  _Track(this.camera, this.recording, this.start);

  Camera camera;
  VisionRecording recording;

  /// Seconds on [RecordedVision]'s clock when this clip started.
  final double start;

  /// The behaviour occurrence last seen, so each is reported once.
  String? last;
}
