import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/project.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/widgets/markdown_panel.dart';
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

    test('reads cameras: an absolute url, a port and path on the connected host, or a device lens', () {
      final p = ProjectInfo.fromJson({
        'project': 'shop',
        'dashboard': {
          'cameras': [
            {'id': 'floor', 'name': 'Sales floor', 'port': 1984, 'path': '/api/stream.mjpeg?src=floor'},
            {'id': 'door', 'name': 'Door', 'url': 'http://10.0.0.9:8080/?action=stream'},
            {'id': 'root', 'name': 'Root', 'port': 8081},
            {'id': 'dashcam', 'name': 'Dash cam', 'device': 'back'},
            {'id': 'pilot', 'name': 'Pilot cam', 'device': 'front'},
          ],
        },
      });
      final cameras = [for (final c in p.cameras) c.on('shop.local')];
      expect(
        [for (final c in cameras) c.url],
        [
          'http://shop.local:1984/api/stream.mjpeg?src=floor',
          'http://10.0.0.9:8080/?action=stream',
          'http://shop.local:8081/',
          'device:back',
          'device:front',
        ],
      );
      expect([for (final c in cameras) c.device], [null, null, null, CameraLens.back, CameraLens.front]);
      expect(
        [for (final c in p.cameras) (c.id, c.name)],
        [('floor', 'Sales floor'), ('door', 'Door'), ('root', 'Root'), ('dashcam', 'Dash cam'), ('pilot', 'Pilot cam')],
      );
    });

    test('malformed cameras are skipped, not fatal', () {
      final p = ProjectInfo.fromJson({
        'project': 'odd',
        'dashboard': {
          'cameras': [
            {'name': 'No id', 'port': 1984},
            {'id': 'x', 'name': 'No source'},
            {'id': 'y', 'name': 'Bad port', 'port': 70000},
            {'id': 'z', 'name': 'Bad url', 'url': 'rtsp://cam/stream'},
            {'id': 'w', 'name': 'Relative path', 'port': 1984, 'path': 'stream'},
            {'id': 'v', 'name': 'Bad lens', 'device': 'side'},
            'not a camera',
            {'id': 'ok', 'name': 'Fine', 'port': 1984, 'path': '/s'},
          ],
        },
      });
      expect([for (final c in p.cameras) c.id], ['ok']);
      expect(
        ProjectInfo.fromJson({
          'project': 'p',
          'dashboard': {'cameras': 'floor'},
        }).cameras,
        isEmpty,
      );
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

    test('project cameras apply until cameras are saved; they beat the brand videoUrl', () async {
      final s = await _load(defaults: {'videoUrl': 'http://brand-cam/stream'});
      expect([for (final c in s.cameras) c.url], ['http://brand-cam/stream']);

      s.host = 'shop.local';
      s.project = ProjectInfo.fromJson({
        'project': 'shop',
        'dashboard': {
          'cameras': [
            {'id': 'floor', 'name': 'Sales floor', 'port': 1984, 'path': '/api/stream.mjpeg?src=floor'},
          ],
        },
      });
      expect(
        [for (final c in s.cameras) (c.id, c.url)],
        [('floor', 'http://shop.local:1984/api/stream.mjpeg?src=floor')],
      );

      // Editing the list saves it, and the saved list wins from then on
      s.cameras = [...s.cameras, const Camera(id: 'mine', name: 'Mine', url: 'http://10.0.0.5/snapshot.jpg')];
      s.project = ProjectInfo.fromJson({'project': 'shop'});
      expect([for (final c in s.cameras) c.id], ['floor', 'mine']);
    });

    test("a camera the user stored beats the project's, and survives the first edit", () async {
      // A videoUrl saved by a version before camera lists (moved into the deployment)
      final s = await _load(prefs: {'host': 'shop.local', 'videoUrl': 'http://10.0.0.7/mine.mjpeg'});
      s.project = ProjectInfo.fromJson({
        'project': 'shop',
        'dashboard': {
          'cameras': [
            {'id': 'floor', 'name': 'Sales floor', 'port': 1984, 'path': '/api/stream.mjpeg?src=floor'},
          ],
        },
      });
      expect([for (final c in s.cameras) c.url], ['http://10.0.0.7/mine.mjpeg']);

      s.cameras = [...s.cameras, const Camera(id: 'yard', name: 'Yard', url: 'http://10.0.0.8/yard.jpg')];
      expect([for (final c in s.cameras) c.url], ['http://10.0.0.7/mine.mjpeg', 'http://10.0.0.8/yard.jpg']);
      expect(s.deployment.values, isNot(contains('videoUrl')));
    });

    test('tabs and stacks are only narrowed while project info is known', () async {
      final s = await _load();
      expect(DashTab.values.every(s.projectAllows), isTrue);
      expect(stacks.every(s.showsStack), isTrue);

      s.project = ProjectInfo.fromJson(_templateProject);
      expect(DashTab.values.where(s.projectAllows), [DashTab.grafana, DashTab.edge, DashTab.services]);
      expect([for (final st in stacks.where(s.showsStack)) st.suffix], ['iot', 'api']);
    });
  });

  group('fetchProjectHome', () {
    Future<String?> fetch(http.Response Function(http.Request r) answer, [List<Uri>? asked]) => http.runWithClient(
      () => fetchProjectHome(Uri.parse('http://pi:8000/')),
      () => MockClient((r) async {
        asked?.add(r.url);
        return answer(r);
      }),
    );

    test('reads the Markdown as UTF-8', () async {
      final asked = <Uri>[];
      final body = utf8.encode(jsonEncode({'markdown': '# Invernadero\n\nRiego automático.'}));
      final md = await fetch(
        (_) => http.Response.bytes(body, 200, headers: {'content-type': 'application/json'}),
        asked,
      );
      expect(md, '# Invernadero\n\nRiego automático.');
      expect(asked, [Uri.parse('http://pi:8000/api/v1/project/home')]);
    });

    test('asks for the given language', () async {
      final asked = <Uri>[];
      await http.runWithClient(
        () => fetchProjectHome(Uri.parse('http://pi:8000/'), lang: 'es'),
        () => MockClient((r) async {
          asked.add(r.url);
          return http.Response('', 204);
        }),
      );
      expect(asked, [Uri.parse('http://pi:8000/api/v1/project/home?lang=es')]);
    });

    test('is null without a file, with an empty one, or with an API that predates it', () async {
      expect(await fetch((_) => http.Response('', 204)), isNull);
      expect(await fetch((_) => http.Response('{"markdown": " \\n"}', 200)), isNull);
      expect(await fetch((_) => http.Response('{"error": {"code": "not_found"}}', 404)), isNull);
    });

    test('fails on other errors, so what is shown stays', () {
      expect(fetch((_) => http.Response('', 500)), throwsA(isA<http.ClientException>()));
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
    Finder nav(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));
    for (final tab in ['Home', 'Assistant', 'Charts', 'Cameras', 'Device', 'Services', 'Clients']) {
      expect(nav(tab), findsOneWidget, reason: tab);
    }
    await tester.tap(nav('Services'));
    await tester.pump(const Duration(milliseconds: 300));
    final aiStack = find.text('AI stack');
    expect(aiStack, findsOneWidget); // the Services tab's AI section

    settings.project = ProjectInfo.fromJson(_templateProject);
    await tester.pump();
    // Services stays open though tabs before it went away.
    for (final tab in ['Home', 'Charts', 'Device', 'Services', 'Clients']) {
      expect(nav(tab), findsOneWidget, reason: tab);
    }
    for (final tab in ['Assistant', 'Cameras']) {
      expect(nav(tab), findsNothing, reason: tab);
    }
    expect(aiStack, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows the project\'s HOME.md, and nothing without one', (tester) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'tourSeen': true, 'role': Role.admin.name});
    final brand = loadBrand('p4n4');
    final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
    final session = await Session.load(settings, probe: (_) async => AuthMode.unreachable);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? home = '# Welcome to the greenhouse\n\n| Zone | Crop |\n|---|---|\n| A | Basil |';
    final asked = <Uri>[];
    final client = MockClient((r) async {
      if (r.url.path != '/api/v1/project/home') return http.Response('', 404);
      asked.add(r.url);
      return home == null ? http.Response('', 204) : http.Response(jsonEncode({'markdown': home}), 200);
    });
    await http.runWithClient(() async {
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
      // Not read until p4n4-api has described the project.
      expect(find.byType(MarkdownBody), findsNothing);

      settings.project = ProjectInfo.fromJson(_templateProject);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('Welcome to the greenhouse'), findsOneWidget);
      expect(find.text('Basil'), findsOneWidget);
      expect(asked.last.queryParameters, {'lang': 'en'});

      // Reconnecting to a project without one hides the block.
      home = null;
      settings.project = ProjectInfo.fromJson({..._templateProject, 'project': 'other'});
      await tester.pump();
      await tester.pump();
      expect(find.byType(MarkdownBody), findsNothing);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  group('MarkdownPanel', () {
    /// What the panel's links opened: tab names, and `ask:` questions as `ask:<question>`.
    Future<List<String>> pumpPanel(WidgetTester tester, String md, Set<String> tabs, {bool canAsk = true}) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(P4Colors.light),
          home: Scaffold(
            body: MarkdownPanel(md, tabs: tabs, onTab: opened.add, onAsk: canAsk ? (q) => opened.add('ask:$q') : null),
          ),
        ),
      );
      return opened;
    }

    testWidgets('a tab: link opens that tab', (tester) async {
      final opened = await pumpPanel(tester, '[Open the charts](tab:grafana)', {'grafana'});
      await tester.tap(find.textContaining('Open the charts', findRichText: true));
      expect(opened, ['grafana']);
    });

    testWidgets('a link to a tab that is not there is plain text', (tester) async {
      final opened = await pumpPanel(tester, 'See [the cameras](tab:video) now', {'grafana'});
      expect(find.textContaining('See the cameras now', findRichText: true), findsOneWidget);
      await tester.tap(find.textContaining('See the cameras now', findRichText: true));
      expect(opened, isEmpty);
    });

    testWidgets('an ask: link asks the assistant its text', (tester) async {
      final opened = await pumpPanel(tester, '[Is any unit on warning?](ask:)', {});
      await tester.tap(find.textContaining('Is any unit on warning?', findRichText: true));
      expect(opened, ['ask:Is any unit on warning?']);
    });

    testWidgets('an ask: link without an assistant is plain text', (tester) async {
      final opened = await pumpPanel(tester, 'Try [Is any unit on warning?](ask:) there', {}, canAsk: false);
      expect(find.textContaining('Try Is any unit on warning? there', findRichText: true), findsOneWidget);
      await tester.tap(find.textContaining('Try Is any unit on warning? there', findRichText: true));
      expect(opened, isEmpty);
    });
  });
}
