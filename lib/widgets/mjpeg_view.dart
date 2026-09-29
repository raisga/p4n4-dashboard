import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';

/// Pure-Dart video viewer that works on every platform.
///
/// * `multipart/x-mixed-replace` (MJPEG) streams are decoded frame by frame.
/// * A plain `image/*` response is treated as a snapshot and re-polled.
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

class MjpegViewState extends State<MjpegView> {
  static const _maxBuffer = 8 * 1024 * 1024;

  http.Client? _client;
  StreamSubscription<List<int>>? _sub;
  Timer? _poll;
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
    if (widget.active) _connect();
  }

  @override
  void didUpdateWidget(MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _disconnect();
    _connect();
  }

  void _disconnect() {
    _sub?.cancel();
    _sub = null;
    _poll?.cancel();
    _poll = null;
    _client?.close();
    _client = null;
  }

  Future<void> _connect() async {
    final client = _client = http.Client();
    setState(() {
      _connecting = true;
      _error = null;
    });
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
      setState(() => _connecting = false);
    } catch (e) {
      if (_client != client) return;
      _disconnect();
      setState(() {
        _connecting = false;
        _error = e;
      });
    }
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
          final end = _indexOf(data, 0xD9, start + 2);
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
      onError: (Object e) => setState(() => _error = e),
      onDone: () {
        if (mounted && widget.active) setState(() => _error ??= 'Stream ended');
      },
      cancelOnError: true,
    );
  }

  static int _indexOf(Uint8List d, int marker, int from) {
    for (var i = from; i < d.length - 1; i++) {
      if (d[i] == 0xFF && d[i + 1] == marker) return i;
    }
    return -1;
  }

  void _onFrame(Uint8List bytes) {
    if (!mounted) return;
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
                    '$_error',
                    style: p4.mono(size: 11, color: p4.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: reconnect, child: const Text('RETRY')),
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
