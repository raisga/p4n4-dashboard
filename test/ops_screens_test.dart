import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/metrics_monitor.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/status_monitor.dart';
import 'package:p4n4_dashboard/api/telemetry.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/incidents.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/l10n.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/pages/logs_page.dart';
import 'package:p4n4_dashboard/widgets/common.dart' show Panel;
import 'package:p4n4_dashboard/widgets/edge_sections.dart';

import 'support/app.dart';
import 'support/brands.dart';

/// Every HTTP catalog entry up, but [down]; [viaApi] false for port probes.
ServiceReport _report({Set<String> down = const {}, bool viaApi = true, bool none = false}) => ServiceReport({
  for (final s in stacks)
    for (final d in s.services.where((d) => !d.tcpOnly)) d: none ? null : !down.contains(d.name),
}, viaApi: viaApi);

/// A monitor that answers [report] at once, without a network.
StatusMonitor _status(ServiceReport report) => StatusMonitor(check: (_) async => report);

/// Readings that never change, without a network.
MetricsMonitor _metrics({double cpu = 20, double? temp = 48}) => MetricsMonitor(
  fetch: (_) async => EdgeMetrics(cpu: cpu, mem: 40, tempC: temp),
);

/// [child] alone with the app's scopes, as [role] sees it.
Future<void> _pumpAlone(WidgetTester tester, Widget child, {Role role = Role.admin}) async {
  final brand = loadBrand('p4n4');
  await pumpApp(tester, role: role);
  final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
  final session = SessionScope.of(tester.element(find.byType(HomeShell)));
  await tester.pumpWidget(
    BrandScope(
      brand: brand,
      child: SettingsScope(
        settings: settings,
        child: SessionScope(
          session: session,
          child: MaterialApp(
            theme: buildTheme(brand.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appLocales,
            home: Scaffold(body: ListView(children: [child])),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("Home's status summary", () {
    for (final (name, report, title) in [
      ('everything up', _report(), 'Everything is working'),
      ('a service down', _report(down: {'Grafana'}), 'Something needs attention'),
      (
        "the API down and no port answering",
        _report(
          viaApi: false,
          down: {
            for (final s in stacks)
              for (final d in s.services) d.name,
          },
        ),
        "We can't reach your system",
      ),
      ('the API answering without the catalog', _report(none: true), 'Service status unavailable'),
    ]) {
      testWidgets('with $name', (tester) async {
        final status = _status(report), metrics = _metrics();
        addTearDown(status.dispose);
        addTearDown(metrics.dispose);
        await pumpApp(tester, role: Role.normie, status: status, metrics: metrics);
        await settle(tester);
        expect(find.text(title), findsOneWidget);
        if (name == 'a service down') expect(find.text('Affected: Charts'), findsOneWidget, reason: 'in their words');
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('offers the brand\'s support to viewers, not to admins', (tester) async {
      for (final role in [Role.normie, Role.admin]) {
        final status = _status(_report(down: {'Grafana'})), metrics = _metrics();
        await pumpApp(
          tester,
          role: role,
          status: status,
          metrics: metrics,
          brandExtra: {
            'support': {'email': 'help@example.com'},
          },
        );
        await settle(tester);
        expect(find.text('Contact support'), role == Role.normie ? findsOneWidget : findsNothing, reason: role.name);
        await tester.pumpWidget(const SizedBox());
        status.dispose();
        metrics.dispose();
      }
    });

    testWidgets('says how long it has been down, amber at first and red past the threshold', (tester) async {
      final status = _status(_report(down: {'Grafana'})), metrics = _metrics();
      addTearDown(status.dispose);
      addTearDown(metrics.dispose);
      final settings = await pumpApp(tester, status: status, metrics: metrics);
      await settle(tester);
      expect(find.textContaining('Down for'), findsOneWidget);
      Color accent() => (tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Panel),
              matching: find.byWidgetPredicate((w) => w is Container && w.constraints?.maxHeight == 4),
            )
            .first,
      )).color!;
      final p4 = tester.element(find.byType(HomeShell)).p4;
      expect(accent(), p4.warn);
      // The same outage, seen starting long ago.
      final log = IncidentScope.maybeOf(tester.element(find.byType(HomeShell)))!;
      await log.clear(settings.deployment);
      log.record(settings.deployment, _report(), DateTime.now().subtract(const Duration(minutes: 31)));
      log.record(settings.deployment, _report(down: {'Grafana'}), DateTime.now().subtract(const Duration(minutes: 30)));
      await tester.pump();
      expect(find.text('Down for 30m'), findsOneWidget);
      expect(accent(), p4.err);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('readings that stopped coming say how old they are', (tester) async {
      var fail = false;
      final status = _status(_report());
      final metrics = MetricsMonitor(
        fetch: (_) async => fail ? throw Exception('timeout') : const EdgeMetrics(cpu: 20, mem: 40),
      );
      addTearDown(status.dispose);
      addTearDown(metrics.dispose);
      final settings = await pumpApp(
        tester,
        role: Role.normie,
        status: status,
        metrics: metrics,
        prefs: {'edgeDemo': false},
      );
      await settle(tester);
      expect(find.textContaining('Updated at'), findsOneWidget);
      fail = true;
      await metrics.refresh(settings.metricsSource);
      await tester.pump();
      expect(find.textContaining("Couldn't refresh"), findsOneWidget);
      expect(find.text('20%'), findsOneWidget, reason: 'the last readings stay');
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Clients shows each deployment\'s readings and its outages', (tester) async {
    final status = _status(_report(down: {'Node-RED'})), metrics = _metrics(cpu: 93, temp: 51);
    addTearDown(status.dispose);
    addTearDown(metrics.dispose);
    await pumpApp(tester, status: status, metrics: metrics, prefs: {'edgeDemo': false, 'temperatureUnit': 'celsius'});
    await tester.tap(nav('Clients'));
    await settle(tester);
    expect(find.text('93%'), findsOneWidget);
    expect(find.text('51°C'), findsOneWidget);
    expect(find.textContaining('Node-RED down since'), findsOneWidget);
    await tester.tap(find.byTooltip('Outage history'));
    await settle(tester);
    expect(find.textContaining('outages'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(find.text('No outages seen from this device.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Services cards say how long a service has been down, and its version and uptime', (tester) async {
    final report = ServiceReport(
      {
        for (final s in stacks)
          for (final d in s.services.where((d) => !d.tcpOnly)) d: d.name != 'Grafana',
      },
      viaApi: true,
      detail: {
        stacks.first.services.first: const ComposeService(
          'grafana',
          'exited',
          '',
          stack: 'iot',
          status: 'Exited (1) 3 minutes ago',
        ),
        stacks.first.services[1]: const ComposeService(
          'node-red',
          'running',
          'unhealthy',
          stack: 'iot',
          version: '4.0.5',
          uptime: Duration(days: 6, hours: 3),
        ),
      },
    );
    final status = _status(report), metrics = _metrics();
    addTearDown(status.dispose);
    addTearDown(metrics.dispose);
    await pumpApp(tester, status: status, metrics: metrics);
    await tester.tap(nav('Services'));
    await settle(tester);
    expect(find.textContaining('Offline ·'), findsOneWidget);
    expect(find.text('Exited (1) 3 minutes ago'), findsOneWidget);
    expect(find.text('4.0.5 · up 6d 3h'), findsOneWidget);
    expect(find.text('Unhealthy'), findsOneWidget);
    // Admins get each service's logs and a restart.
    await tester.tap(find.byTooltip('Node-RED actions'));
    await settle(tester);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the logs page follows, filters and says when the stream ends', (tester) async {
    final lines = StreamController<String>();
    await _pumpAlone(
      tester,
      SizedBox(
        height: 600,
        child: LogsPage(stack: 'iot', title: 'IoT', follow: (api, stack, {service}) => lines.stream),
      ),
    );
    lines
      ..add('grafana | ready')
      ..add('node-red | ERROR flow failed')
      ..add('grafana | GET /api/health 200');
    await settle(tester);
    expect(find.text('Following new lines'), findsOneWidget);
    expect(find.text('node-red | ERROR flow failed'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'grafana');
    await tester.pump();
    expect(find.text('node-red | ERROR flow failed'), findsNothing);
    expect(find.textContaining('grafana |'), findsNWidgets(2));
    unawaited(lines.close());
    await settle(tester);
    expect(find.text('The log stream ended'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
  });

  testWidgets('the sensors panel shows the latest of each sensor', (tester) async {
    final events = StreamController<TelemetryEvent>();
    await _pumpAlone(tester, SensorsPanel(active: true, stream: (_) => events.stream));
    expect(find.text('Sensors'), findsOneWidget);
    events.add(const TelemetryStatus(mqtt: true));
    await settle(tester);
    expect(find.text('Waiting for readings…'), findsOneWidget);
    for (final v in [21.0, 21.5]) {
      events.add(
        TelemetryReading(
          SensorReading(device: 'env-01', sensor: 'temp', fields: {'value': v, 'unit': 'C'}, at: DateTime(2026)),
        ),
      );
    }
    events.add(
      TelemetryReading(
        SensorReading(
          device: 'door-01',
          sensor: 'door',
          fields: const {'state': 'open', 'battery': 87},
          at: DateTime(2026),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('21.5 C'), findsOneWidget, reason: 'the latest');
    expect(find.text('21.0 C'), findsNothing);
    expect(find.text('87'), findsOneWidget, reason: 'no value field: the first number');
    expect(find.text('state open'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('viewers see no sensors panel until there are readings', (tester) async {
    final events = StreamController<TelemetryEvent>();
    await _pumpAlone(tester, SensorsPanel(active: true, stream: (_) => events.stream), role: Role.normie);
    events.addError(Exception('404'));
    await settle(tester);
    expect(find.text('Sensors'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a command to a topic the API refuses says why', (tester) async {
    await http.runWithClient(
      () async {
        await _pumpAlone(tester, const CommandPanel());
        await tester.enterText(find.widgetWithText(TextField, 'Topic'), 'sensors/env-01/temp');
        await tester.enterText(find.widgetWithText(TextField, 'Message'), '1');
        await tester.pump();
        await tester.tap(find.text('Send'));
        await settle(tester);
        expect(find.textContaining("doesn't allow publishing to sensors/env-01/temp"), findsOneWidget);
        expect(find.textContaining('(r-9)'), findsOneWidget, reason: 'the request ID, for the log');
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'topic_not_allowed', 'message': 'no'},
          }),
          403,
          headers: {'x-request-id': 'r-9'},
        ),
      ),
    );
  });

  group('the Assistant', () {
    /// p4n4-api's agents endpoints: one model; the chat fails once, then answers.
    /// [runWithClient] makes a client per request, so the count lives outside.
    var chats = 0;
    setUp(() => chats = 0);
    MockClient api(List<http.Request> seen) {
      return MockClient((r) async {
        seen.add(r);
        return switch ((r.method, r.url.path)) {
          ('GET', '/api/v1/agents/config') => http.Response(
            jsonEncode({'backend': 'ollama', 'model': 'qwen', 'agent_id': null, 'updated_at': 'then'}),
            200,
          ),
          ('GET', '/api/v1/agents/models') => http.Response(
            jsonEncode({
              'models': [
                {'name': 'qwen'},
              ],
            }),
            200,
          ),
          ('POST', '/api/v1/agents/chat') when chats++ == 0 => http.Response(
            jsonEncode({
              'error': {'code': 'ollama_unavailable', 'message': 'Ollama is busy'},
            }),
            503,
          ),
          ('POST', '/api/v1/agents/chat') => http.Response(
            '${jsonEncode({
              'message': {'content': 'All good.'},
              'done': true,
            })}\n',
            200,
          ),
          _ => http.Response('', 404),
        };
      });
    }

    testWidgets('a failed answer can be asked again, and an answer copied', (tester) async {
      final seen = <http.Request>[];
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      await http.runWithClient(() async {
        await pumpApp(tester, role: Role.normie);
        await tester.tap(nav('Assistant'));
        await settle(tester);
        await tester.tap(find.text('Is everything running normally?'));
        await settle(tester);
        expect(find.text('Something went wrong'), findsOneWidget);
        await tester.tap(find.byTooltip('Try again'));
        await settle(tester);
        expect(find.text('All good.'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing, reason: 'the failure gives way to the answer');
        expect(find.text('Is everything running normally?'), findsOneWidget, reason: 'asked once in the chat');
        await tester.tap(find.byTooltip('Copy').last);
        await tester.pump();
        expect(copied, 'All good.');
      }, () => api(seen));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('the answer style goes with each question; viewers get no own instructions', (tester) async {
      final seen = <http.Request>[];
      await http.runWithClient(() async {
        await pumpApp(tester, role: Role.normie);
        await tester.tap(nav('Assistant'));
        await settle(tester);
        await tester.tap(find.byTooltip('Answer style'));
        await settle(tester);
        expect(find.text('Own instructions'), findsNothing);
        await tester.tap(find.text('Brief').last);
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'How are the fridges?');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await settle(tester);
      }, () => api(seen));
      final chat = seen.firstWhere((r) => r.url.path == '/api/v1/agents/chat');
      final messages = (jsonDecode(chat.body) as Map)['messages'] as List;
      expect(messages.first, {'role': 'system', 'content': startsWith('Answer briefly')});
      expect(messages.last, {'role': 'user', 'content': 'How are the fridges?'});
    });
  });

  testWidgets('admins register a device and see its key once; power users only read', (tester) async {
    final devices = <Map<String, Object?>>[
      {
        'id': 'env-01',
        'name': 'Environment',
        'description': '',
        'enabled': true,
        'key_prefix': 'p4n4_ab12cd34',
        'created_at': '2026-10-01T10:00:00Z',
        'last_seen_at': null,
      },
    ];
    MockClient api() => MockClient(
      (r) async => switch ((r.method, r.url.path)) {
        ('GET', '/api/v1/devices') => http.Response(jsonEncode({'items': devices, 'total': devices.length}), 200),
        ('POST', '/api/v1/devices') => () {
          final body = jsonDecode(r.body) as Map;
          devices.add({...devices.first, 'id': body['id'], 'name': body['name'], 'key_prefix': 'p4n4_99'});
          return http.Response(jsonEncode({...devices.last, 'api_key': 'p4n4_99_secret'}), 201);
        }(),
        _ => http.Response('', 404),
      },
    );
    for (final role in [Role.power, Role.admin]) {
      await http.runWithClient(() async {
        await pumpApp(tester, role: role);
        await tester.tap(find.byTooltip('Settings'));
        await settle(tester);
        await tester.tap(find.text('Devices').first);
        await settle(tester);
        expect(find.textContaining('Environment', findRichText: true), findsOneWidget, reason: role.name);
        expect(find.textContaining('Never seen'), findsOneWidget);
        expect(find.text('Add device'), role == Role.admin ? findsOneWidget : findsNothing, reason: role.name);
        if (role == Role.admin) {
          await tester.tap(find.text('Add device'));
          await settle(tester);
          await tester.enterText(find.widgetWithText(TextField, 'Device ID'), 'door-01');
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Back door');
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Add'));
          await settle(tester);
          expect(find.text('p4n4_99_secret'), findsOneWidget);
          await tester.tap(find.text('Done'));
          await settle(tester);
          expect(find.text('p4n4_99_secret'), findsNothing, reason: 'shown once');
          expect(find.textContaining('Back door', findRichText: true), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      }, api);
    }
  });

  test('a brand names its support by email, phone or page', () {
    final brand = loadBrand(
      'p4n4',
      extra: {
        'support': {'url': 'https://help.example.com', 'email': 'help@example.com', 'phone': '+1 (555) 010-2000'},
      },
    );
    expect(brand.support!.contacts.map((u) => '$u'), [
      'https://help.example.com',
      'mailto:help@example.com',
      'tel:+15550102000',
    ]);
    expect(loadBrand('p4n4').support, isNull);
    expect(
      () => loadBrand(
        'p4n4',
        extra: {
          'support': {'url': 'ftp://x'},
        },
      ),
      throwsFormatException,
    );
  });
}
