import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/agent_client.dart';
import 'package:p4n4_dashboard/api/auth.dart' show viaPageProxy;
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/stack_control.dart';
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

  test('only same-origin http(s) URLs count as the page proxy', () {
    final page = Uri.parse('http://pi:8088/');
    expect(viaPageProxy(Uri.parse('http://pi:8088/api/v1/agents'), page: page), isTrue);
    expect(viaPageProxy(Uri.parse('http://pi:8000/'), page: page), isFalse);
    expect(viaPageProxy(Uri.parse('https://pi:8088/api/'), page: page), isFalse);
    expect(viaPageProxy(Uri.parse('http://pi:8088/'), page: Uri.parse('file:///app/')), isFalse);
  });

  group('the assistant goes through p4n4-api', () {
    final api = AgentApi(Uri.parse('http://pi:8000/'));

    test('reads and saves the deployment-wide choice', () async {
      final seen = <http.Request>[];
      final config = await http.runWithClient(
        () async {
          final got = await api.config();
          expect(got.backend, AgentBackend.ollama);
          expect(got.chosen, isNull);
          return api.setConfig(got.copyWith(id: 'llama3.2'));
        },
        () => MockClient((r) async {
          seen.add(r);
          return r.method == 'GET'
              ? http.Response('{"backend": "ollama", "model": null, "agent_id": null}', 200)
              : http.Response(r.body, 200);
        }),
      );
      expect(
        [for (final r in seen) '${r.method} ${r.url}'],
        ['GET http://pi:8000/api/v1/agents/config', 'PUT http://pi:8000/api/v1/agents/config'],
      );
      expect(jsonDecode(seen.last.body), {'backend': 'ollama', 'model': 'llama3.2', 'agent_id': null});
      expect(config.chosen, 'llama3.2');
    });

    test('lists Ollama models and Letta agents', () async {
      final options = await http.runWithClient(
        () async => [
          for (final b in AgentBackend.values) [for (final o in await api.listOptions(b)) '${o.id}=${o.label}'],
        ],
        () => MockClient(
          (r) async => switch (r.url.path) {
            '/api/v1/agents/models' => http.Response('{"models": [{"name": "qwen2.5:0.5b"}]}', 200),
            '/api/v1/agents' => http.Response('{"agents": [{"id": "agent-1", "name": "ops"}]}', 200),
            _ => http.Response('', 404),
          },
        ),
      );
      expect(options, [
        ['qwen2.5:0.5b=qwen2.5:0.5b'],
        ['agent-1=ops'],
      ]);
    });

    test('Ollama replies are read to the end of the stream, past done', () async {
      // onCancel also runs after a normal close; what matters is whether the reader
      // gave up before the stream ended
      var cancelledEarly = false;
      late final StreamController<List<int>> body;
      late http.BaseRequest sent;
      body = StreamController<List<int>>(onCancel: () => cancelledEarly = !body.isClosed);
      final mock = MockClient.streaming((request, bytes) async {
        sent = request;
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
        () => api.send(AgentBackend.ollama, 'm', [ChatMessage('user', 'hi')]).join(),
        () => mock,
      );
      expect(reply, 'Hello');
      expect(sent.url, Uri.parse('http://pi:8000/api/v1/agents/chat'));
      // Cancelling before the stream's own end is what browsers report as net::ERR_ABORTED
      expect(cancelledEarly, isFalse);
    });

    test('Letta gets only the new message, with the system status', () async {
      late http.Request sent;
      final reply = await http.runWithClient(
        () => api.send(AgentBackend.letta, 'agent-1', [
          ChatMessage('user', 'first'),
          ChatMessage('assistant', 'ok'),
          ChatMessage('user', 'second'),
        ]).join(),
        () => MockClient((r) async {
          sent = r;
          return http.Response('{"reply": "All running.", "messages": []}', 200);
        }),
      );
      expect(reply, 'All running.');
      expect(sent.url.path, '/api/v1/agents/agent-1/chat');
      expect(jsonDecode(sent.body), {'message': 'second', 'include_status': true});
    });

    test("the API's refusals keep their code; a dead connection counts as unavailable", () async {
      Future<AgentException> failure(MockClient client) async {
        try {
          await http.runWithClient(
            () => api.send(AgentBackend.ollama, 'big:70b', [ChatMessage('user', 'hi')]).join(),
            () => client,
          );
        } on AgentException catch (e) {
          return e;
        }
        fail('expected an AgentException');
      }

      final denied = await failure(
        MockClient(
          (_) async => http.Response(
            '{"error": {"code": "assistant_restricted", "message": "Only operators can choose the model."}}',
            403,
          ),
        ),
      );
      expect((denied.statusCode, denied.code, denied.denied), (403, 'assistant_restricted', true));
      expect(denied.message, 'Only operators can choose the model.');

      final down = await failure(MockClient((_) async => throw http.ClientException('refused')));
      expect(down.unavailable, isTrue);
    });
  });

  test('stack actions start a job and wait for it to finish', () async {
    final seen = <String>[];
    var polls = 0;
    final job = await http.runWithClient(
      () => runStackAction(Uri.parse('http://pi:8000/'), 'ai', StackAction.restart, every: Duration.zero),
      () => MockClient((r) async {
        seen.add('${r.method} ${r.url.path}');
        final status = r.method == 'POST' ? 'queued' : (++polls < 2 ? 'running' : 'succeeded');
        return http.Response(jsonEncode({'id': 'j1', 'status': status, 'output': []}), r.method == 'POST' ? 202 : 200);
      }),
    );
    expect(job.finished && !job.failed, isTrue);
    expect(seen, ['POST /api/v1/stacks/ai/restart', 'GET /api/v1/jobs/j1', 'GET /api/v1/jobs/j1']);
  });
}
