import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/agent_client.dart';
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';

void main() {
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

  group('Letta auth behind the dashboard proxy', () {
    Future<Map<String, String>> headersOf(LettaClient c) async {
      late Map<String, String> seen;
      await http.runWithClient(
        c.listOptions,
        () => MockClient((r) async {
          seen = r.headers;
          return http.Response('[]', 200);
        }),
      );
      return seen;
    }

    test('directly, the token is a normal bearer header', () async {
      final h = await headersOf(LettaClient(Uri.parse('http://pi:8283/'), token: 'pw'));
      expect(h['Authorization'], 'Bearer pw');
      expect(h.containsKey(upstreamAuthorizationHeader), isFalse);
    });

    test('through the proxy, Authorization is left to its basic auth', () async {
      final h = await headersOf(LettaClient(Uri.parse('http://pi:8088/letta/'), token: 'pw', viaProxy: true));
      expect(h[upstreamAuthorizationHeader], 'Bearer pw');
      expect(h.containsKey('Authorization'), isFalse);
    });

    test('only same-origin http(s) URLs count as the page proxy', () {
      final page = Uri.parse('http://pi:8088/');
      expect(viaPageProxy(Uri.parse('http://pi:8088/letta/'), page: page), isTrue);
      expect(viaPageProxy(Uri.parse('http://pi:8283/'), page: page), isFalse);
      expect(viaPageProxy(Uri.parse('https://pi:8088/letta/'), page: page), isFalse);
      expect(viaPageProxy(Uri.parse('http://pi:8088/'), page: Uri.parse('file:///app/')), isFalse);
    });
  });

  test('OllamaClient reads the reply stream to its end, past done', () async {
    // onCancel also runs after a normal close; what matters is whether the reader
    // gave up before the stream ended
    var cancelledEarly = false;
    late final StreamController<List<int>> body;
    body = StreamController<List<int>>(onCancel: () => cancelledEarly = !body.isClosed);
    final mock = MockClient.streaming((request, _) async {
      () async {
        for (final line in [
          {
            'message': {'content': 'Hel'},
            'done': false,
          },
          {
            'message': {'content': 'lo'},
            'done': false,
          },
          {
            'message': {'content': ''},
            'done': true,
          },
        ]) {
          body.add(utf8.encode('${jsonEncode(line)}\n'));
        }
        // The stream ends a moment after done, as over a network
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Anything after done is read but not shown
        body.add(
          utf8.encode(
            '${jsonEncode({
              'message': {'content': ' (after done)'},
            })}\n',
          ),
        );
        await body.close();
      }();
      return http.StreamedResponse(body.stream, 200);
    });
    final reply = await http.runWithClient(
      () => OllamaClient(Uri.parse('http://ollama/')).send('m', [ChatMessage('user', 'hi')]).join(),
      () => mock,
    );
    expect(reply, 'Hello');
    // Cancelling before the stream's own end is what browsers report as net::ERR_ABORTED
    expect(cancelledEarly, isFalse);
  });
}
