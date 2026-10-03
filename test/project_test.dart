import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/project.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

/// `GET /api/v1/project` for a project made from the mqtt-influx-grafana template.
const _templateProject = {
  'project': 'greenhouse',
  'layers': ['iot'],
  'template': {'name': 'mqtt-influx-grafana', 'version': '0.2.0'},
  'dashboard': {
    'grafana_path': '/d/p4n4-telemetry/telemetry',
    'tabs': ['services', 'edge', 'grafana'],
  },
};

Future<AppSettings> _load({Map<String, Object> prefs = const {}, Map<String, Object> defaults = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
}

void main() {
  group('ProjectInfo', () {
    test('reads the template and dashboard blocks', () {
      final p = ProjectInfo.fromJson(_templateProject);
      expect(p.name, 'greenhouse');
      expect(p.layers, ['iot']);
      expect((p.template, p.templateVersion), ('mqtt-influx-grafana', '0.2.0'));
      expect(p.grafanaPath, '/d/p4n4-telemetry/telemetry');
      expect(p.tabs, {DashTab.services, DashTab.edge, DashTab.grafana});
      expect(p.defaults, {'grafanaPath': '/d/p4n4-telemetry/telemetry'});
    });

    test('a project without a dashboard block restricts nothing', () {
      final p = ProjectInfo.fromJson({
        'project': 'plain',
        'layers': ['iot', 'ai'],
        'template': null,
        'dashboard': null,
      });
      expect(p.tabs, isNull);
      expect(p.grafanaPath, isNull);
      expect(p.defaults, isEmpty);
    });

    test('malformed dashboard settings are ignored, not fatal', () {
      final p = ProjectInfo.fromJson({
        'project': 'odd',
        'dashboard': {
          'grafana_path': 'd/no-slash',
          'tabs': ['charts', 7],
        },
      });
      expect(p.grafanaPath, isNull);
      expect(p.tabs, isNull);
    });

    test('stacks follow the layers; the API stack always shows', () {
      final p = ProjectInfo.fromJson(_templateProject);
      expect([for (final st in stacks) st.suffix].where(p.hasStack), ['iot', 'api']);
      expect(ProjectInfo.fromJson({'project': 'x'}).hasStack('ai'), isTrue);
    });
  });

  group('AppSettings.project', () {
    test('project defaults beat brand defaults; the user beats both', () async {
      final s = await _load(defaults: {'grafanaPath': '/d/brand/home'});
      expect(s.grafanaPath, '/d/brand/home');

      s.project = ProjectInfo.fromJson(_templateProject);
      expect(s.grafanaPath, '/d/p4n4-telemetry/telemetry');
      expect(s.grafanaUri.toString(), 'http://localhost:3000/d/p4n4-telemetry/telemetry?kiosk=1');

      s.grafanaPath = '/d/mine/custom';
      expect(s.grafanaPath, '/d/mine/custom');

      s.project = null;
      expect(s.grafanaPath, '/d/mine/custom');
    });

    test('tabs and stacks are only narrowed while project info is known', () async {
      final s = await _load();
      expect(DashTab.values.every(s.projectAllows), isTrue);
      expect(stacks.every(s.showsStack), isTrue);

      s.project = ProjectInfo.fromJson(_templateProject);
      expect(DashTab.values.where(s.projectAllows), [DashTab.services, DashTab.edge, DashTab.grafana]);
      expect([for (final st in stacks.where(s.showsStack)) st.suffix], ['iot', 'api']);
    });
  });

  group('ProjectWatcher', () {
    test('loads the project, and reloads it when the deployment changes', () async {
      final s = await _load();
      final asked = <Uri>[];
      final watcher = ProjectWatcher(
        s,
        fetch: (api) async {
          asked.add(api);
          return ProjectInfo.fromJson({..._templateProject, 'project': api.host});
        },
      );
      addTearDown(watcher.dispose);
      await pumpEventQueue();
      expect(s.project?.name, 'localhost');

      s.host = '10.0.0.7';
      await pumpEventQueue();
      expect(s.project?.name, '10.0.0.7');

      s.themeMode = ThemeMode.dark; // not a connection setting
      await pumpEventQueue();
      expect(asked, [Uri.parse('http://localhost:8000/'), Uri.parse('http://10.0.0.7:8000/')]);
    });

    test('drops an answer that arrives after switching deployments', () async {
      final s = await _load();
      final pending = <Uri, Future<void>>{};
      final watcher = ProjectWatcher(
        s,
        fetch: (api) async {
          if (api.host == 'localhost') await (pending[api] = Future<void>.delayed(const Duration(milliseconds: 20)));
          return ProjectInfo.fromJson({..._templateProject, 'project': api.host});
        },
      );
      addTearDown(watcher.dispose);
      s.host = 'site-b';
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(s.project?.name, 'site-b');
    });

    test('a failed read is retried as soon as settings change (e.g. after signing in)', () async {
      final s = await _load();
      var signedIn = false;
      final watcher = ProjectWatcher(
        s,
        retry: const Duration(hours: 1),
        fetch: (_) async => signedIn ? ProjectInfo.fromJson(_templateProject) : throw Exception('HTTP 401'),
      );
      addTearDown(watcher.dispose);
      await pumpEventQueue();
      expect(s.project, isNull);

      signedIn = true;
      await s.setSessionOf(s.deployment, {'mode': 'api', 'role': 'admin', 'user': 'ana'});
      await pumpEventQueue();
      expect(s.project?.name, 'greenhouse');
    });

    test('retries while the API is unreachable', () async {
      final s = await _load();
      var calls = 0;
      final watcher = ProjectWatcher(
        s,
        retry: Duration.zero,
        fetch: (_) async {
          if (++calls < 3) throw Exception('connection refused');
          return ProjectInfo.fromJson(_templateProject);
        },
      );
      addTearDown(watcher.dispose);
      for (var i = 0; i < 5 && s.project == null; i++) {
        await Future<void>.delayed(Duration.zero);
        await pumpEventQueue();
      }
      expect(calls, 3);
      expect(s.project?.name, 'greenhouse');
    });
  });

  testWidgets('the connected project hides tabs it does not serve', (tester) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'role': Role.admin.name});
    final brand = loadBrand('p4n4');
    final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
    final session = await Session.load(settings, probe: (_) async => AuthMode.unreachable);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BrandScope(
        brand: brand,
        child: SettingsScope(
          settings: settings,
          child: SessionScope(session: session, child: const DashboardApp()),
        ),
      ),
    );
    await tester.pump();
    for (final tab in ['SERVICES', 'EDGE', 'AGENT', 'GRAFANA', 'VIDEO', 'CLIENTS']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    final aiStack = find.text('p4n4-ai', findRichText: true);
    expect(aiStack, findsOneWidget); // the Services tab's AI section

    settings.project = ProjectInfo.fromJson(_templateProject);
    await tester.pump();
    for (final tab in ['SERVICES', 'EDGE', 'GRAFANA', 'CLIENTS']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    for (final tab in ['AGENT', 'VIDEO']) {
      expect(find.text(tab), findsNothing, reason: tab);
    }
    expect(aiStack, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
