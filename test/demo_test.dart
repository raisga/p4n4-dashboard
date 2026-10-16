import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/demo/demo.dart';
import 'package:p4n4_dashboard/demo/demo_agent.dart';
import 'package:p4n4_dashboard/demo/demo_charts.dart';
import 'package:p4n4_dashboard/demo/demo_client.dart';
import 'package:p4n4_dashboard/demo/demo_store.dart';

/// A recorded day as a project writes it: an alert at 10:00 reviewed at
/// 10:05, one to review at 15:00 nobody reviewed, an event at 18:00.
Map<String, dynamic> _day(String date) {
  final stamp = date.replaceAll('-', '');
  return {
    'date': date,
    'items': [
      {
        's': 36000,
        'id': 'ALT-$stamp-000001',
        'kind': 'alert',
        'title': 'Cliente buscando',
        'badge': 'S1',
        'tone': 'info',
      },
      {
        's': 54000,
        'id': 'ALT-$stamp-000002',
        'kind': 'alert',
        'title': 'Riesgo',
        'badge': 'S2',
        'tone': 'review',
        'subtitle': 'shelf-3',
      },
      {'s': 64800, 'id': 'EVT-$stamp-000001', 'kind': 'event', 'title': 'De paso'},
    ],
    'reviews': {
      'ALT-$stamp-000001': [36300, 'attended'],
    },
    'summary': {
      'visitors': 40,
      'sales_transactions': 6,
      'revenue': 1234.5,
      'conversion_rate': 0.15,
      'garments_taken': 20,
      'fitting_room_visits': 9,
      'peak_hour': {'hour': '17:00 - 18:00', 'entries': 9},
      'top_shelf': {'name': 'Camisas · Marca A', 'interactions': 30},
      'alerts': {'total': 2},
    },
    'ranking': {
      'ranking': [
        {'garment_type': 'polo', 'color': 'negro', 'interactions': 12, 'units_sold': 2},
      ],
    },
    'purchase': {
      'events_with_factors': 10,
      'factor_share': [
        {'label': 'Estilo y color', 'share': 0.6},
        {'label': 'Talla y caída', 'share': 0.4},
      ],
      'units_by_category': [
        {'label': 'Tops', 'units': 5},
      ],
    },
    'series': {
      'visitors': [
        [36000],
        [36100],
        [54000],
      ],
      'sales': [
        [54100, 'shelf-2', 100.5],
      ],
    },
    'layout': {
      'shelves': [
        {'shelf_id': 'shelf-2', 'name': 'Camisas', 'interactions': 30, 'units_sold': 5, 'revenue': 600},
        {'shelf_id': 'shelf-3', 'name': 'Vestidos', 'interactions': 28, 'units_sold': 0, 'revenue': 0},
      ],
    },
  };
}

Map<String, dynamic> _fixture() => {
  'lang': 'es',
  'currency': 'PAB',
  'feed_title': 'Actividad en vivo',
  'actions': {'attended': 'Atender', 'dismissed': 'Descartar', 'pending_review': 'Reabrir'},
  'alert_titles': {'S1': 'Cliente buscando', 'S2': 'Revisar'},
  'project': {
    'project': 'demo-store',
    'dashboard': {
      'tabs': ['agent', 'feed'],
      'cameras': [
        {'id': 'cam-1', 'name': 'Floor', 'url': 'demo/cam-1.mp4'},
      ],
    },
  },
  'model': 'test-model',
  'home': {'': '# Home', 'es': '# Inicio'},
  'vision': null,
  'stacks': [
    {
      'name': 'iot',
      'services': [
        ['ingest', 'python:3.13-slim'],
      ],
    },
  ],
  'charts': {
    'title': 'Tienda',
    'currency': 'B/.',
    'ranges': [
      {'id': 'today', 'label': 'Hoy', 'days': 1},
      {'id': '7d', 'label': '7 días', 'days': 7},
    ],
    'sections': [
      {
        'panels': [
          {'type': 'stat', 'title': 'Visitantes', 'series': 'visitors'},
          {'type': 'stat', 'title': 'Ingresos', 'series': 'sales', 'agg': 'sum', 'unit': 'currency'},
          {'type': 'timeline', 'title': 'Por hora', 'series': 'visitors'},
          {
            'type': 'bars',
            'title': 'Estantes',
            'series': [
              {'label': 'Ventas', 'series': 'sales'},
            ],
          },
          {'type': 'alerts', 'title': 'Alertas'},
        ],
      },
    ],
  },
  'anchor': '2026-09-21',
  'days': [for (var i = 0; i < 14; i++) _day(DateTime.utc(2026, 9, 21 + i).toIso8601String().substring(0, 10))],
};

void main() {
  // Thursday 15 October 2026, 10:02: today's first alert is in, not yet reviewed.
  DemoStore storeAt(DateTime now) => DemoStore(_fixture(), clock: () => now);

  test('days repeat weekday for weekday from the anchor', () {
    final store = storeAt(DateTime(2026, 10, 15, 10, 2));
    // 2026-10-15 is 24 days after the anchor: day 10 of the cycle, a Thursday like it.
    expect(store.dayFor(0).date, '2026-10-01');
    expect(DateTime.parse(store.dayFor(0).date).weekday, DateTime(2026, 10, 15).weekday);
    expect(store.dayFor(14).date, store.dayFor(0).date);
  });

  test("today shows what has happened by now, with today's ids", () {
    final store = storeAt(DateTime(2026, 10, 15, 10, 2));
    final today = store.items(span: 1);
    expect(today.map((i) => i.id), ['ALT-20261015-000001']);
    expect(today.single.json['status'], 'pending_review');
    expect(today.single.json['actions'], [
      {'id': 'attended', 'label': 'Atender'},
      {'id': 'dismissed', 'label': 'Descartar'},
    ]);
    // Staff reviewed it at 10:05.
    expect(storeAt(DateTime(2026, 10, 15, 10, 6)).items(span: 1).single.json['status'], 'attended');
  });

  test('the feed pages back through the last 8 days', () {
    final store = storeAt(DateTime(2026, 10, 15, 23));
    final first = store.feed(limit: 4);
    expect((first['items'] as List).length, 4);
    // Every day leaves its alert to review pending.
    expect((first['counts'] as Map)['pending'], 8);
    final rest = store.feed(limit: 100, before: first['next_before'] as double);
    expect((rest['items'] as List).length, 8 * 3 - 4);
    expect(rest['next_before'], isNull);
  });

  test('a review made in the preview sticks', () {
    final store = storeAt(DateTime(2026, 10, 15, 23));
    expect(store.act('ALT-20261015-000002', 'attended'), isTrue);
    expect(store.items(span: 1).firstWhere((i) => i.id == 'ALT-20261015-000002').json['status'], 'attended');
    expect(store.act('EVT-20261015-000001', 'attended'), isFalse);
  });

  test('the assistant answers the brand questions with their tools', () {
    final agent = DemoAgent(storeAt(DateTime(2026, 10, 15, 23)));
    expect(agent.answer('¿Hubo alertas de riesgo de pérdida?').steps.single.$1, 'get_alerts');
    expect(agent.answer('¿Qué prendas se llevan más?').steps.single.$1, 'get_garment_ranking');
    expect(agent.answer('¿Qué decide la compra esta semana?').steps.single.$1, 'get_purchase_factors');
    final yesterday = agent.answer('¿Qué pasó ayer en la tienda?');
    expect(yesterday.steps.single.$1, 'get_store_summary');
    expect(yesterday.text, contains('B/. 1,234.50'));
    expect(agent.answer('¿Hubo alertas de riesgo de pérdida?').text, contains('**8**'));
  });

  test('charts count what has happened in the range', () {
    final store = storeAt(DateTime(2026, 10, 15, 12));
    final today = computeCharts(store, 'today')!;
    final panels = ((today['sections'] as List).first as Map)['panels'] as List;
    expect((panels[0] as Map)['data']['value'], 2); // 10:00 and 10:01, not 15:00
    expect((panels[1] as Map)['data']['value'], 0);
    final week = computeCharts(store, '7d')!;
    final weekPanels = ((week['sections'] as List).first as Map)['panels'] as List;
    expect((weekPanels[0] as Map)['data']['value'], 2 + 6 * 3);
    expect((weekPanels[1] as Map)['data']['value'], closeTo(6 * 100.5, 0.01));
    expect((weekPanels[3] as Map)['data'], [
      {'shelf-2': 6},
    ]);
    expect(((weekPanels[4] as Map)['data'] as List).length, 6 * 2 + 1);
  });

  group('the client', () {
    final page = Uri.parse('https://preview.example/');
    late DemoApi api;
    setUp(() {
      final inner = MockClient((r) async {
        if (r.url.path == '/demo/store.json') return http.Response.bytes(utf8.encode(jsonEncode(_fixture())), 200);
        return http.Response('not found', 404);
      });
      // A client per request, as http.runWithClient makes them, around one API.
      api = DemoApi(inner, page: page);
    });
    Future<http.StreamedResponse> send(http.BaseRequest r) => DemoClient(http.Client(), api).send(r);
    Future<http.Response> call(String method, String path, {Object? body, String? as}) async {
      final req = http.Request(method, page.resolve(path));
      if (as != null) req.headers['Authorization'] = 'Bearer demo-access.$as';
      if (body != null) req.body = jsonEncode(body);
      return http.Response.fromStream(await send(req));
    }

    Object? json(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

    test('signs in each view with the one password', () async {
      expect((await call('GET', 'api/v1/auth/me')).statusCode, 401);
      expect(
        (await call('POST', 'api/v1/auth/token', body: {'username': 'admin', 'password': 'nope'})).statusCode,
        401,
      );
      for (final MapEntry(:key, :value) in demoAccounts.entries) {
        final res = await call('POST', 'api/v1/auth/token', body: {'username': key, 'password': demoPassword});
        expect((json(res) as Map)['role'], value);
      }
      expect((await call('GET', 'api/v1/project')).statusCode, 401);
    });

    test('serves the project, its cameras next to the app, and no banner', () async {
      final project = json(await call('GET', 'api/v1/project', as: 'normie')) as Map;
      expect(project['project'], 'demo-store');
      expect(project['dashboard']['cameras'][0]['url'], 'https://preview.example/demo/cam-1.mp4');
      expect((json(await call('GET', 'api/v1/dashboard/banner', as: 'normie')) as Map)['text'], '');
      expect((json(await call('GET', 'api/v1/project/home?lang=es', as: 'normie')) as Map)['markdown'], '# Inicio');
      expect((json(await call('GET', 'api/v1/agents/config', as: 'normie')) as Map)['model'], 'test-model');
      expect((json(await call('GET', 'api/v1/dashboard/charts?range=7d', as: 'normie')) as Map)['range'], '7d');
    });

    test('lets operators act on the feed, not normies', () async {
      final normie = json(await call('GET', 'api/v1/feed?limit=5', as: 'normie')) as Map;
      expect(normie['can_act'], isFalse);
      expect((normie['items'] as List).every((i) => (i as Map)['actions'] == null), isTrue);
      final power = json(await call('GET', 'api/v1/feed?limit=5', as: 'power')) as Map;
      expect(power['can_act'], isTrue);
      final id = (power['items'] as List).cast<Map>().firstWhere((i) => i['kind'] == 'alert')['id'];
      final action = {'action': 'attended'};
      expect((await call('POST', 'api/v1/feed/$id/action', body: action, as: 'normie')).statusCode, 403);
      expect((await call('POST', 'api/v1/feed/$id/action', body: action, as: 'power')).statusCode, 200);
    });

    test('pretends admin actions work, and logs them', () async {
      expect((await call('GET', 'api/v1/users', as: 'power')).statusCode, 403);
      final created = await call(
        'POST',
        'api/v1/users',
        body: {'username': 'ana', 'password': 'x', 'role': 'normie'},
        as: 'admin',
      );
      expect((json(created) as Map)['username'], 'ana');
      expect((json(await call('GET', 'api/v1/users', as: 'admin')) as List).length, 4);
      expect((await call('DELETE', 'api/v1/users/admin', as: 'admin')).statusCode, 409);
      expect((await call('PATCH', 'api/v1/users/admin', body: {'role': 'normie'}, as: 'admin')).statusCode, 409);

      final job = json(await call('POST', 'api/v1/stacks/iot/down', as: 'admin')) as Map;
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect((json(await call('GET', 'api/v1/jobs/${job['id']}', as: 'admin')) as Map)['status'], 'succeeded');
      final stacks = (json(await call('GET', 'api/v1/stacks', as: 'admin')) as Map)['stacks'] as List;
      expect(((stacks.first as Map)['services'] as List).first['state'], 'exited');

      final audit = json(await call('GET', 'api/v1/audit', as: 'admin')) as Map;
      expect([for (final e in audit['items'] as List) (e as Map)['action']].take(2), ['stack.down', 'user.create']);
    });

    test('streams the assistant with its tool steps', () async {
      final chat = await call(
        'POST',
        'api/v1/agents/chat',
        body: {
          'messages': [
            {'role': 'user', 'content': '¿Qué pasó ayer?'},
          ],
        },
        as: 'normie',
      );
      final lines = const LineSplitter().convert(utf8.decode(chat.bodyBytes)).map(jsonDecode).toList();
      expect(lines.first['step']['tool'], 'get_store_summary');
      expect(lines.last['done'], isTrue);
    });
  });
}
