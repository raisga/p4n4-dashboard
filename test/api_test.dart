import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p4n4_dashboard/api/agent_client.dart';
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('EdgeMetrics parses the documented JSON', () {
    final m = EdgeMetrics.fromJson({
      'cpu_percent': 23.1,
      'mem_percent': 61,
      'temp_c': 51.3,
      'uptime_s': 90061,
      'load': [0.4, 0.5, 0.6],
    });
    expect(m.cpu, 23.1);
    expect(m.mem, 61.0);
    expect(m.tempC, 51.3);
    expect(m.uptime, const Duration(days: 1, hours: 1, minutes: 1, seconds: 1));
    expect(m.load, [0.4, 0.5, 0.6]);
    expect(m.disk, isNull);
  });

  test('EdgeMetrics drops malformed load values instead of failing', () {
    EdgeMetrics parse(Object? load) => EdgeMetrics.fromJson({'cpu_percent': 1, 'mem_percent': 2, 'load': load});
    expect(parse([0.4, null, 'x', 0.6]).load, [0.4, 0.6]);
    expect(parse(['x']).load, isNull);
    expect(parse('0.4 0.5 0.6').load, isNull);
  });

  group('MJPEG frame end', () {
    // SOI, an APP1 segment holding a whole thumbnail JPEG (with its own EOI),
    // SOS, entropy data with a stuffed FF00, then the frame's EOI.
    final thumb = [0xFF, 0xD8, 0x01, 0x02, 0xFF, 0xD9];
    final frame = Uint8List.fromList([
      0xFF, 0xD8, //
      0xFF, 0xE1, 0x00, 2 + thumb.length, ...thumb,
      0xFF, 0xDA, 0x00, 0x04, 0x00, 0x00,
      0x12, 0xFF, 0x00, 0x34,
      0xFF, 0xD9,
    ]);

    test('skips an embedded thumbnail\'s EOI', () {
      expect(MjpegViewState.frameEnd(frame, 0), frame.length - 2);
    });

    test('is -1 until the frame has fully arrived', () {
      for (var n = 2; n < frame.length - 1; n++) {
        expect(MjpegViewState.frameEnd(Uint8List.sublistView(frame, 0, n), 0), -1, reason: 'prefix of $n bytes');
      }
    });
  });

  test('statusFor maps catalog entries to compose services', () {
    const status = {
      'grafana': ComposeService('grafana', 'running', ''),
      'mosquitto': ComposeService('mosquitto', 'exited', ''),
    };
    final grafana = stacks.first.services.first;
    final mqtt = stacks.first.services.firstWhere((s) => s.name == 'MQTT');
    expect(statusFor(grafana, status)?.running, isTrue);
    expect(statusFor(mqtt, status)?.running, isFalse);
  });

  test('ChatMessage serializes for Ollama', () {
    expect(ChatMessage('user', 'hi').toJson(), {'role': 'user', 'content': 'hi'});
  });
}
