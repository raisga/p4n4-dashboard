import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';

import '../platform/text_socket.dart';
import 'vision.dart';

/// The project's live detections and verdicts (`dashboard.vision.live`), one
/// [VisionScene] per camera: a vision service's WebSocket, which carries the
/// contract's `detection` messages (boxes, many a second) and `verdict`
/// messages (what someone did, once per event). Reconnects on its own while
/// alive, backing off to [maxBackoff].
class LiveVision {
  LiveVision(
    this.uri, {
    this.onVerdict,
    Future<Stream<String>> Function(Uri uri)? connect,
    this.maxBackoff = _maxBackoff,
  }) : _connect = connect ?? connectTextSocket {
    _open();
    _sweeper = Timer.periodic(const Duration(milliseconds: 500), (_) => _sweep());
  }

  final Uri uri;

  /// Each verdict, as it arrives: where alerts come from.
  final void Function(String camera, VisionBehavior behavior)? onVerdict;
  final Duration maxBackoff;
  final Future<Stream<String>> Function(Uri uri) _connect;

  static const _maxBackoff = Duration(seconds: 30);

  /// Boxes older than this are someone the stream stopped reporting: gone.
  static const boxesFor = Duration(milliseconds: 1500);

  /// How long a verdict stays on screen after it arrives, at least: an
  /// event's own window can be shorter than anyone needs to read it.
  static const verdictFor = Duration(seconds: 8);

  final _cameras = <String, _LiveCamera>{};
  final connected = ValueNotifier(false);
  StreamSubscription<String>? _sub;
  Timer? _retry;
  late final Timer _sweeper;
  var _backoff = const Duration(seconds: 1);
  var _closed = false;

  /// [camera]'s scene, updated as messages arrive (and cleared when they stop).
  ValueListenable<VisionScene> scene(String camera) => _camera(camera).scene;

  _LiveCamera _camera(String id) => _cameras.putIfAbsent(id, _LiveCamera.new);

  Future<void> _open() async {
    if (_closed) return;
    try {
      final stream = await _connect(uri);
      if (_closed) return;
      _sub = stream.listen(
        (m) {
          _backoff = const Duration(seconds: 1);
          connected.value = true;
          handle(m);
        },
        onError: (_) {},
        onDone: _reconnect,
        cancelOnError: false,
      );
    } catch (_) {
      _reconnect();
    }
  }

  void _reconnect() {
    _sub = null;
    connected.value = false;
    if (_closed) return;
    _retry = Timer(_backoff, _open);
    _backoff = Duration(milliseconds: math.min(_backoff.inMilliseconds * 2, maxBackoff.inMilliseconds));
  }

  /// One message from the stream. Anything else (diagnostics, stats) is ignored.
  @visibleForTesting
  void handle(String message, {DateTime? now}) {
    final Object? j;
    try {
      j = jsonDecode(message);
    } on FormatException {
      return;
    }
    if (j is! Map || j['camera_id'] is! String) return;
    final cam = _camera(j['camera_id'] as String);
    final at = now ?? DateTime.now();
    switch (j['type']) {
      case 'detection':
        final (w, h) = (j['frame_width'], j['frame_height']);
        // Without the frame they were measured on, boxes would land on the
        // wrong person: draw none rather than that.
        if (w is! num || h is! num || w <= 0 || h <= 0) return;
        cam
          ..frame = Size(w.toDouble(), h.toDouble())
          ..boxes = [
            for (final o in (j['objects'] as List?) ?? const [])
              if (o case {
                'track_id': final num id,
                'confidence': final num c,
                'bbox': [final num x1, final num y1, final num x2, final num y2],
              })
                VisionBox(id.toInt(), Rect.fromLTRB(x1 / w, y1 / h, x2 / w, y2 / h), c.toDouble()),
          ]
          ..boxesAt = at;
      case 'verdict':
        final behavior = switch (j['behavior']) {
          {'class': final String cls} && final Map b => VisionBehavior(
            track: (j['track_id'] as num?)?.toInt() ?? -1,
            behavior: cls,
            confidence: (b['confidence'] as num?)?.toDouble() ?? 0,
            zone: (j['zone'] as Map?)?['id'] as String?,
            key: j['event_id'] as String?,
          ),
          _ => null,
        };
        if (behavior == null) return;
        final dwell = ((j['window'] as Map?)?['dwell_ms'] as num?)?.toInt() ?? 0;
        cam
          ..behavior = behavior
          ..behaviorUntil = at.add(Duration(milliseconds: math.max(dwell, verdictFor.inMilliseconds)));
        onVerdict?.call(j['camera_id'] as String, behavior);
      default:
        return;
    }
    cam.publish(at);
  }

  void _sweep() {
    final now = DateTime.now();
    for (final cam in _cameras.values) {
      cam.publish(now);
    }
  }

  void dispose() {
    _closed = true;
    _retry?.cancel();
    _sweeper.cancel();
    _sub?.cancel();
    connected.dispose();
    for (final cam in _cameras.values) {
      cam.scene.dispose();
    }
  }
}

class _LiveCamera {
  final scene = ValueNotifier(VisionScene.empty);
  Size? frame;
  List<VisionBox> boxes = const [];
  DateTime? boxesAt;
  VisionBehavior? behavior;
  DateTime? behaviorUntil;

  void publish(DateTime now) {
    final fresh = boxesAt != null && now.difference(boxesAt!) <= LiveVision.boxesFor;
    final current = behaviorUntil != null && now.isBefore(behaviorUntil!);
    final next = VisionScene(boxes: fresh ? boxes : const [], behavior: current ? behavior : null, frame: frame);
    // The sweep runs whether or not anything changed; don't rebuild for it.
    if (next.isEmpty && scene.value.isEmpty) return;
    scene.value = next;
  }
}
