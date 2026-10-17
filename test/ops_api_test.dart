import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/api_error.dart';
import 'package:p4n4_dashboard/api/auth.dart';
import 'package:p4n4_dashboard/api/devices.dart';
import 'package:p4n4_dashboard/api/inference.dart';
import 'package:p4n4_dashboard/api/mqtt_publish.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/sse.dart';
import 'package:p4n4_dashboard/api/stack_control.dart';
import 'package:p4n4_dashboard/api/telemetry.dart';
import 'package:p4n4_dashboard/api/users.dart';

final _api = Uri.parse('http://pi:8000/');

/// An error body as p4n4-api sends it, with the request's ID echoed.
http.Response _error(int status, String code, String message, {String? id}) => http.Response(
  jsonEncode({
    'error': {'code': code, 'message': message},
  }),
  status,
  headers: {'x-request-id': ?id},
);

/// Server-sent events, one chunk per element.
http.StreamedResponse _sse(http.BaseRequest r, List<String> chunks, {int status = 200}) => http.StreamedResponse(
  Stream.fromIterable([for (final c in chunks) utf8.encode(c)]),
  status,
  request: r,
  headers: {'content-type': 'text/event-stream'},
);

class _NoCredentials implements ApiCredentials {
  @override
  String? accessTokenFor(Uri url) => null;

  @override
  Future<String?> refreshFor(Uri url) async => null;
}

void main() {
  group('request IDs', () {
    test('every p4n4-api call carries one, other URLs none', () async {
      final seen = <http.BaseRequest>[];
      final client = AuthClient(
        MockClient((r) async {
          seen.add(r);
          return http.Response('{}', 200);
        }),
        _NoCredentials(),
      );
      await client.get(_api.resolve('api/v1/stacks'));
      await client.get(_api.resolve('api/v1/auth/me'));
      await client.get(Uri.parse('http://pi:3000/api/dashboards'));
      final ids = [for (final r in seen) r.headers[requestIdHeader]];
      expect(ids[0], matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(ids[1], isNotNull, reason: 'sign-in calls too: they fail in the log as well');
      expect(ids[1], isNot(ids[0]));
      expect(ids[2], isNull, reason: "Grafana's API isn't p4n4-api");
    });

    test('errors carry the ID the API answered with, and show it', () async {
      final e = await http.runWithClient(
        () => listUsers(_api).then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient((_) async => _error(409, 'conflict', 'That username is taken.', id: 'abc123')),
      );
      expect(e, isA<UsersException>().having((e) => e.requestId, 'requestId', 'abc123'));
      expect('$e', 'That username is taken. (request abc123)');
      // Without one (an older API), just the message.
      expect('${const ApiException('Nope.')}', 'Nope.');
    });

    test("a validation error names the first field's problem", () {
      final res = http.Response(
        jsonEncode({
          'error': {
            'code': 'validation_error',
            'message': 'Invalid request.',
            'fields': [
              {
                'loc': ['body', 'id'],
                'message': 'too long',
              },
            ],
          },
        }),
        422,
      );
      expect(ApiException.from(res), isA<ApiException>().having((e) => e.message, 'message', 'too long'));
    });
  });

  group('server-sent events', () {
    test('are split at blank lines, keep-alives skipped and data lines joined', () async {
      final events = await parseSse(
        Stream.fromIterable([
          utf8.encode(': keep-alive\n\nevent: status\ndata: {"mqtt":'),
          utf8.encode(' true}\n\ndata: line one\ndata: line two\n\ndata:no space\n\n'),
        ]),
      ).toList();
      expect(events, [
        (event: 'status', data: '{"mqtt": true}'),
        (event: 'message', data: 'line one\nline two'),
        (event: 'message', data: 'no space'),
      ]);
    });

    test('a refused stream is an ApiException with the request ID', () async {
      final error = await http.runWithClient(
        () =>
            sseGet(_api.resolve('api/v1/stacks/iot/logs'))
                .toList()
                .then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient.streaming(
          (r, _) async => http.StreamedResponse(
            Stream.value(utf8.encode('{"error": {"code": "forbidden", "message": "Requires the admin role."}}')),
            403,
            headers: {'x-request-id': 'r-1'},
          ),
        ),
      );
      expect(
        error,
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.code, 'code', 'forbidden')
            .having((e) => e.requestId, 'requestId', 'r-1'),
      );
    });
  });

  group('stack logs and service restarts', () {
    test('follow a stack until Compose ends', () async {
      late http.BaseRequest sent;
      final lines = await http.runWithClient(
        () => followStackLogs(_api, 'iot', service: 'node-red', tail: 50).toList(),
        () => MockClient.streaming((r, _) async {
          sent = r;
          return _sse(r, [
            'data: node-red  | started\n\n',
            ': keep-alive\n\n',
            'data: node-red  | ready\n\n',
            'event: end\ndata: 0\n\n',
            'data: after the end\n\n',
          ]);
        }),
      );
      expect(sent.url.path, '/api/v1/stacks/iot/logs');
      expect(sent.url.queryParameters, {'follow': 'true', 'tail': '50', 'service': 'node-red'});
      expect(sent.headers['Accept'], 'text/event-stream');
      expect(lines, ['node-red  | started', 'node-red  | ready']);
    });

    test("a stream that stops early says why", () async {
      final error = await http.runWithClient(
        () => followStackLogs(_api, 'iot').toList().then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient.streaming(
          (r, _) async => _sse(r, ['event: error\ndata: log line too long; stream stopped\n\n']),
        ),
      );
      expect(error, isA<StackControlException>().having((e) => e.message, 'message', contains('too long')));
    });

    test('restart one service and wait for its job', () async {
      final seen = <String>[];
      var polls = 0;
      final job = await http.runWithClient(
        () async => waitForJob(_api, await startServiceRestart(_api, 'iot', 'node-red'), every: Duration.zero),
        () => MockClient((r) async {
          seen.add('${r.method} ${r.url.path}');
          final done = r.method == 'GET' && ++polls > 1;
          return http.Response(
            jsonEncode({'id': 'j1', 'status': done ? 'succeeded' : 'running', 'output': <String>[]}),
            202,
          );
        }),
      );
      expect(seen.first, 'POST /api/v1/stacks/iot/services/node-red/restart');
      expect(seen.skip(1), everyElement('GET /api/v1/jobs/j1'));
      expect(job.finished && !job.failed, isTrue);
    });
  });

  test("services carry the image, version, uptime and stack p4n4-api reports", () async {
    final report = await http.runWithClient(
      () => checkServices(_api, (d) => Uri.parse('http://pi:${d.port}')),
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'stacks': [
              {
                'name': 'iot',
                'services': [
                  {
                    'name': 'grafana',
                    'state': 'running',
                    'health': 'unhealthy',
                    'image': 'grafana/grafana:11.2.0',
                    'version': '11.2.0',
                    'status': 'Up 6 days (unhealthy)',
                    'uptime_s': 540000,
                  },
                  {'name': 'node-red', 'state': 'exited', 'health': '', 'status': 'Exited (1) 2 hours ago'},
                ],
              },
            ],
          }),
          200,
        ),
      ),
    );
    final grafana = report.detail.entries.singleWhere((e) => e.key.name == 'Grafana').value;
    expect(grafana.stack, 'iot');
    expect(grafana.version, '11.2.0');
    expect(grafana.uptime, const Duration(days: 6, hours: 6));
    expect(grafana.unhealthy, isTrue);
    final nodeRed = report.detail.entries.singleWhere((e) => e.key.name == 'Node-RED').value;
    expect((nodeRed.running, nodeRed.uptime, nodeRed.status), (false, null, 'Exited (1) 2 hours ago'));
    expect(report.detail.keys.map((d) => d.name), isNot(contains('Ollama')), reason: 'not in Compose: no detail');
  });

  group('devices', () {
    final device = {
      'id': 'env-01',
      'name': 'Environment',
      'description': 'Back room',
      'enabled': true,
      'key_prefix': 'p4n4_ab12cd34',
      'created_at': '2026-10-01T10:00:00Z',
      'last_seen_at': null,
    };

    test('list a page, register (the key comes back once), change, rotate and remove', () async {
      final seen = <http.Request>[];
      await http.runWithClient(
        () async {
          final page = await listDevices(_api, limit: 20, offset: 40);
          expect(page.total, 41);
          expect(page.items.single.lastSeenAt, isNull);
          expect(page.items.single.keyPrefix, 'p4n4_ab12cd34');

          final (created, key) = await createDevice(_api, id: ' env-01 ', name: 'Environment');
          expect((created.id, key), ('env-01', 'p4n4_ab12cd34_secret'));

          await updateDevice(_api, 'env-01', enabled: false);
          expect(await rotateDeviceKey(_api, 'env-01'), 'p4n4_new');
          await deleteDevice(_api, 'env-01');
        },
        () => MockClient((r) async {
          seen.add(r);
          return switch ((r.method, r.url.path)) {
            ('GET', '/api/v1/devices') => http.Response(
              jsonEncode({
                'items': [device],
                'total': 41,
                'limit': 20,
                'offset': 40,
              }),
              200,
            ),
            ('POST', '/api/v1/devices') => http.Response(
              jsonEncode({...device, 'api_key': 'p4n4_ab12cd34_secret'}),
              201,
            ),
            ('PATCH', _) => http.Response(jsonEncode({...device, 'enabled': false}), 200),
            ('POST', '/api/v1/devices/env-01/key') => http.Response(
              jsonEncode({'id': 'env-01', 'key_prefix': 'p4n4_new', 'api_key': 'p4n4_new'}),
              200,
            ),
            ('DELETE', _) => http.Response('', 204),
            _ => http.Response('', 404),
          };
        }),
      );
      expect(seen[0].url.queryParameters, {'limit': '20', 'offset': '40'});
      expect(jsonDecode(seen[1].body), {'id': 'env-01', 'name': 'Environment', 'description': ''});
      expect(jsonDecode(seen[2].body), {'enabled': false}, reason: 'only what changes');
      expect(seen.last.method, 'DELETE');
    });

    test('a taken ID is a 409 with the API\'s code', () async {
      final error = await http.runWithClient(
        () => createDevice(_api, id: 'env-01').then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient((_) async => _error(409, 'device_exists', "Device 'env-01' already exists.")),
      );
      expect(error, isA<ApiException>().having((e) => e.code, 'code', 'device_exists'));
    });
  });

  group('telemetry', () {
    test('the live stream gives the broker status, readings and drops', () async {
      late http.BaseRequest sent;
      final events = await http.runWithClient(
        () => streamTelemetry(_api, device: 'env-01').toList(),
        () => MockClient.streaming((r, _) async {
          sent = r;
          return _sse(r, [
            'event: status\ndata: {"mqtt": true}\n\n',
            'event: reading\ndata: {"device": "env-01", "sensor": "temp", "fields": {"value": 21.5, "unit": "C", "ok": true}, "ts": "2026-10-17T10:00:00Z", "received_at": "2026-10-17T10:00:00Z"}\n\n',
            'event: dropped\ndata: 3\n\n',
          ]);
        }),
      );
      expect(sent.url.queryParameters, {'device': 'env-01'});
      expect(events[0], isA<TelemetryStatus>().having((s) => s.mqtt, 'mqtt', true));
      final reading = (events[1] as TelemetryReading).reading;
      expect((reading.device, reading.sensor, reading.unit), ('env-01', 'temp', 'C'));
      expect(reading.numbers, {'value': 21.5}, reason: 'the unit and the flag are no numbers');
      expect(events[2], isA<TelemetryDropped>().having((d) => d.count, 'count', 3));
    });

    test('history asks for a window and averages', () async {
      late http.Request sent;
      final points = await http.runWithClient(
        () => fetchTelemetry(_api, device: 'env-01', sensor: 'temp', field: 'value', start: '-24h', every: '15m'),
        () => MockClient((r) async {
          sent = r;
          return http.Response(
            jsonEncode({
              'points': [
                {'time': '2026-10-17T10:00:00Z', 'device': 'env-01', 'sensor': 'temp', 'field': 'value', 'value': 21.5},
              ],
              'truncated': false,
            }),
            200,
          );
        }),
      );
      expect(sent.url.queryParameters, {
        'device': 'env-01',
        'sensor': 'temp',
        'field': 'value',
        'start': '-24h',
        'every': '15m',
        'limit': '1000',
      });
      expect(points.single.value, 21.5);
      expect(points.single.at, DateTime.utc(2026, 10, 17, 10).toLocal());
    });
  });

  group('inference', () {
    test('the runner, a classification and the stored results', () async {
      final seen = <http.Request>[];
      await http.runWithClient(
        () async {
          final runner = await fetchRunner(_api);
          expect((runner.backend, runner.expectedFeatures), ('onnx', 3));
          expect(runner.labels, ['idle', 'anomaly']);
          expect(runner.influxOk, isFalse);
          final result = await classify(_api, [0.1, 0.2, 0.3]);
          expect((result.label, result.confidence), ('anomaly', 0.91));
          final recent = await fetchInferenceResults(_api);
          expect(recent.single.device, 'edge-01');
        },
        () => MockClient((r) async {
          seen.add(r);
          return switch (r.url.path) {
            '/api/v1/inference/runner' => http.Response(
              jsonEncode({
                'backend': 'onnx',
                'model_file': 'm.onnx',
                'model': {},
                'labels': ['idle', 'anomaly'],
                'expected_features': 3,
                'influxdb_ok': false,
              }),
              200,
            ),
            '/api/v1/inference' => http.Response(
              jsonEncode({
                'device': 'dashboard',
                'timestamp': '2026-10-17T10:00:00Z',
                'label': 'anomaly',
                'confidence': 0.91,
                'anomaly_score': 0.7,
                'latency_ms': 12.0,
                'backend': 'onnx',
                'mode': 'onnx',
              }),
              200,
            ),
            _ => http.Response(
              jsonEncode({
                'results': [
                  {'time': '2026-10-17T09:00:00Z', 'device': 'edge-01', 'label': 'idle', 'confidence': 0.8},
                ],
                'truncated': false,
              }),
              200,
            ),
          };
        }),
      );
      expect(jsonDecode(seen[1].body), {
        'values': [0.1, 0.2, 0.3],
        'device': 'dashboard',
      });
      expect(seen[2].url.queryParameters, {'start': '-24h', 'limit': '10'});
    });

    test('feature values are numbers however they are separated', () {
      expect(parseFeatures('0.1, 2 ,3;4\n-5e-1'), [0.1, 2, 3, 4, -0.5]);
      expect(parseFeatures('1, two'), isNull);
      expect(parseFeatures('  '), isNull);
    });
  });

  group('MQTT publish', () {
    test('JSON goes as JSON, anything else as text', () async {
      final bodies = <Object?>[];
      await http.runWithClient(
        () async {
          expect(await publishMqtt(_api, ' devices/env-01/cmd ', '{"action": "reboot"}', qos: 1), 20);
          await publishMqtt(_api, 'devices/env-01/cmd', 'reboot', retain: true);
        },
        () => MockClient((r) async {
          bodies.add(jsonDecode(r.body));
          return http.Response(jsonEncode({'topic': 'x', 'qos': 1, 'retain': false, 'bytes': 20}), 200);
        }),
      );
      expect(bodies, [
        {
          'topic': 'devices/env-01/cmd',
          'payload': {'action': 'reboot'},
          'qos': 1,
          'retain': false,
        },
        {'topic': 'devices/env-01/cmd', 'payload': 'reboot', 'qos': 0, 'retain': true},
      ]);
    });

    test('a topic outside the allowed ones is a 403 topic_not_allowed', () async {
      final error = await http.runWithClient(
        () => publishMqtt(_api, 'sensors/x/y', '1').then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient((_) async => _error(403, 'topic_not_allowed', "Publishing to 'sensors/x/y' isn't allowed.")),
      );
      expect(error, isA<ApiException>().having((e) => e.code, 'code', 'topic_not_allowed'));
    });
  });
}
