import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../platform/html_view.dart';

/// Video viewer for MJPEG streams and JPEG snapshots.
///
/// Native: decoded in pure Dart.
/// * `multipart/x-mixed-replace` (MJPEG) streams are decoded frame by frame.
/// * A plain `image/*` response is treated as a snapshot and re-polled.
///
/// Web: the browser decodes it in an `<img>` ([_BrowserStream]), which needs
/// no CORS headers from the camera. The response type can't be read there, so
/// URLs that look like a still image ([looksLikeSnapshot]) are re-polled.
///
/// Dropped connections are retried with exponential backoff while [active].
class MjpegView extends StatefulWidget {
  const MjpegView({
    super.key,
    required this.uri,
    this.active = true,
    this.snapshotInterval = const Duration(milliseconds: 500),
  });

  final Uri uri;

  /// When false the connection is closed (e.g. the tab is hidden).
  final bool active;
  final Duration snapshotInterval;

  @override
  State<MjpegView> createState() => MjpegViewState();
}

/// Whether [uri] looks like a still image rather than a stream: used on web,
/// where the response's content type can't be read.
@visibleForTesting
bool looksLikeSnapshot(Uri uri) {
  final path = uri.path.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.contains('snapshot') ||
      uri.queryParameters['action'] == 'snapshot';
}

class MjpegViewState extends State<MjpegView> {
  static const _maxBuffer = 8 * 1024 * 1024;
  static const _minBackoff = Duration(seconds: 2);
  static const _maxBackoff = Duration(seconds: 30);

  http.Client? _client;
  StreamSubscription<List<int>>? _sub;
  Timer? _poll;
  Timer? _retry;
  Duration _backoff = _minBackoff;
  Uint8List? _frame;
  Object? _error;
  bool _connecting = false;
  String _mode = '';
  int _frames = 0;
  double _fps = 0;
  final _fpsWatch = Stopwatch();

  P4Colors get p4 => context.p4;

  @override
  void initState() {
    super.initState();
    if (widget.active && !kIsWeb) _connect();
  }

  @override
  void didUpdateWidget(MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) return;
    if (oldWidget.uri != widget.uri || oldWidget.active != widget.active) {
      _disconnect();
      if (widget.active) _connect();
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  void reconnect() {
    if (kIsWeb) return;
    _disconnect();
    _backoff = _minBackoff;
    _connect();
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
    _poll?.cancel();
    _poll = null;
    _client?.close();
    _client = null;
  }

  Future<void> _connect() async {
    final client = _client = http.Client();
    setState(() => _connecting = true);
    try {
      final res = await client.send(http.Request('GET', widget.uri)).timeout(const Duration(seconds: 8));
      if (_client != client) return;
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', widget.uri);
      final type = res.headers['content-type'] ?? '';
      _fpsWatch
        ..reset()
        ..start();
      _frames = 0;
      _fps = 0;
      if (type.startsWith('image/')) {
        _mode = 'snapshot';
        _onFrame(await res.stream.toBytes());
        _poll = Timer.periodic(widget.snapshotInterval, (_) => _snapshot(client));
      } else {
        _mode = 'mjpeg';
        _readMjpeg(res.stream);
      }
      setState(() {
        _connecting = false;
        _error = null;
      });
    } catch (e) {
      if (_client == client) _fail(e);
    }
  }

  /// Shows [e] and schedules a reconnect, backing off after each failure.
  void _fail(Object e) {
    _disconnect();
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _error = e;
    });
    if (!widget.active) return;
    _retry = Timer(_backoff, _connect);
    _backoff = Duration(milliseconds: min(_backoff.inMilliseconds * 2, _maxBackoff.inMilliseconds));
  }

  Future<void> _snapshot(http.Client client) async {
    try {
      final bytes = await client.readBytes(widget.uri).timeout(const Duration(seconds: 5));
      if (_client == client) _onFrame(bytes);
    } catch (_) {
      // Transient; keep polling.
    }
  }

  /// Splits the byte stream on JPEG SOI (FFD8) / EOI (FFD9) markers, which is
  /// more tolerant than relying on each server's multipart boundary format.
  void _readMjpeg(Stream<List<int>> stream) {
    final buf = BytesBuilder(copy: false);
    _sub = stream.listen(
      (chunk) {
        buf.add(chunk);
        var data = buf.takeBytes();
        while (true) {
          final start = _indexOf(data, 0xD8, 0);
          if (start < 0) {
            // Keep a trailing 0xFF in case the marker straddles two chunks.
            data = data.isNotEmpty && data.last == 0xFF ? Uint8List.fromList([0xFF]) : Uint8List(0);
            break;
          }
          final end = frameEnd(data, start);
          if (end < 0) {
            data = Uint8List.sublistView(data, start);
            break;
          }
          _onFrame(Uint8List.fromList(Uint8List.sublistView(data, start, end + 2)));
          data = Uint8List.sublistView(data, end + 2);
        }
        if (data.length > _maxBuffer) data = Uint8List(0);
        buf.add(data);
      },
      onError: (Object e) => _fail(e),
      onDone: () => _fail('Stream ended'),
      cancelOnError: true,
    );
  }

  /// Index of the EOI marker ending the JPEG that starts at [start], or -1 if
  /// it hasn't fully arrived. Header segments are skipped by their length, so
  /// the EOI of an embedded EXIF thumbnail isn't mistaken for the frame's.
  @visibleForTesting
  static int frameEnd(Uint8List d, int start) {
    var i = start + 2;
    while (i + 1 < d.length) {
      // Not at a marker: malformed header, so fall back to a plain scan.
      if (d[i] != 0xFF) return _indexOf(d, 0xD9, i);
      final m = d[i + 1];
      if (m == 0xFF) {
        i++; // fill byte
      } else if (m == 0xD9) {
        return i;
      } else if (m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
        i += 2; // standalone marker, no length
      } else {
        if (i + 3 >= d.length) return -1;
        final next = i + 2 + (d[i + 2] << 8 | d[i + 3]);
        // After the start-of-scan header comes entropy-coded data, where 0xFF
        // is byte-stuffed, so the next FFD9 is the real end.
        if (m == 0xDA) return _indexOf(d, 0xD9, next);
        i = next;
      }
    }
    return -1;
  }

  static int _indexOf(Uint8List d, int marker, int from) {
    for (var i = from; i < d.length - 1; i++) {
      if (d[i] == 0xFF && d[i + 1] == marker) return i;
    }
    return -1;
  }

  void _onFrame(Uint8List bytes) {
    if (!mounted) return;
    _backoff = _minBackoff;
    _frames++;
    final secs = _fpsWatch.elapsedMilliseconds / 1000;
    if (secs >= 1) {
      _fps = _frames / secs;
      _frames = 0;
      _fpsWatch
        ..reset()
        ..start();
    }
    setState(() => _frame = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _BrowserStream(uri: widget.uri, active: widget.active, snapshotInterval: widget.snapshotInterval);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_frame != null)
          Image.memory(
            _frame!,
            gaplessPlayback: true,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        if (_connecting && _frame == null) Center(child: CircularProgressIndicator(color: p4.accent)),
        if (_error != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: p4.bg.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_outlined, color: p4.err),
                  const SizedBox(height: 8),
                  Text(
                    '$_error${_retry != null || _connecting ? '\nreconnecting…' : ''}',
                    style: p4.mono(size: 11, color: p4.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _connecting ? null : reconnect, child: const Text('RETRY')),
                ],
              ),
            ),
          ),
        if (_frame != null && _error == null)
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: P4Colors.dark.err, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE · ${_mode.toUpperCase()}${_fps > 0 ? ' · ${_fps.toStringAsFixed(1)} FPS' : ''}',
                    style: p4.mono(size: 10, color: P4Colors.dark.text),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Web: [MjpegView] as an `<img>`. Errors retry with the same 2 s → 30 s
/// backoff, and snapshots are re-requested with a cache-busting query.
class _BrowserStream extends StatefulWidget {
  const _BrowserStream({required this.uri, required this.active, required this.snapshotInterval});

  final Uri uri;
  final bool active;
  final Duration snapshotInterval;

  @override
  State<_BrowserStream> createState() => _BrowserStreamState();
}

class _BrowserStreamState extends State<_BrowserStream> {
  late Uri _src = widget.uri;
  bool _loaded = false;
  bool _failed = false;
  Timer? _timer;
  Duration _backoff = MjpegViewState._minBackoff;

  bool get _snapshot => looksLikeSnapshot(widget.uri);

  @override
  void didUpdateWidget(_BrowserStream old) {
    super.didUpdateWidget(old);
    if (old.uri != widget.uri || old.active != widget.active) {
      _timer?.cancel();
      _src = widget.uri;
      _loaded = _failed = false;
      _backoff = MjpegViewState._minBackoff;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Uri _fresh() => widget.uri.replace(
    queryParameters: {...widget.uri.queryParameters, '_t': '${DateTime.now().millisecondsSinceEpoch}'},
  );

  void _onLoad() {
    if (!mounted || !widget.active) return;
    _backoff = MjpegViewState._minBackoff;
    setState(() {
      _loaded = true;
      _failed = false;
    });
    if (_snapshot) {
      _timer?.cancel();
      _timer = Timer(widget.snapshotInterval, () => setState(() => _src = _fresh()));
    }
  }

  void _onError() {
    if (!mounted || !widget.active) return;
    setState(() => _failed = true);
    _timer?.cancel();
    _timer = Timer(_backoff, () => setState(() => _src = _fresh()));
    _backoff = Duration(milliseconds: min(_backoff.inMilliseconds * 2, MjpegViewState._maxBackoff.inMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // An empty src closes the connection while the tab is hidden.
        HtmlImage(uri: widget.active ? _src : Uri(), onLoad: _onLoad, onError: _onError),
        if (widget.active && !_loaded && !_failed) Center(child: CircularProgressIndicator(color: p4.accent)),
        if (_failed)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: p4.bg.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_outlined, color: p4.err),
                  const SizedBox(height: 8),
                  Text(
                    'Camera unavailable\nreconnecting…',
                    style: p4.mono(size: 11, color: p4.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        if (_loaded && !_failed)
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text(
                'LIVE · ${_snapshot ? 'SNAPSHOT' : 'MJPEG'}',
                style: p4.mono(size: 10, color: P4Colors.dark.text),
              ),
            ),
          ),
      ],
    );
  }
}
