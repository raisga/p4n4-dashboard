import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/agent_client.dart' show AgentBackend;
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/pages/login_page.dart';
import 'package:p4n4_dashboard/widgets/common.dart' show TagBadge;
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';
import 'package:p4n4_dashboard/widgets/video_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

/// [label] in the navigation rail or bar; page titles and Home's shortcuts reuse the same words.
Finder nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);

/// p4n4-api's views endpoint: records each saved body and echoes it; with
/// [refuse], PUTs get the 403 non-admins get.
MockClient viewsApi(List<Map<String, Object?>> saved, {bool refuse = false}) => MockClient((r) async {
  if (r.url.path != '/api/v1/dashboard/views') return http.Response('', 404);
  if (r.method != 'PUT') return http.Response('{}', 200);
  if (refuse) return http.Response('{"error": {"code": "forbidden", "message": "Requires the admin role."}}', 403);
  saved.add((jsonDecode(r.body) as Map).cast());
  return http.Response(r.body, 200);
});

/// Opens Settings and, if given, one of its categories by name.
Future<void> openSettings(WidgetTester tester, [String? category]) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (category == null) return;
  await tester.tap(find.text(category).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    ThemeMode mode, {
    String brandId = 'p4n4',
    Role? role = Role.admin,
    Map<String, Object> prefs = const {},
    Map<String, Object> brandDefaults = const {},
  }) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'themeMode': mode.name, 'role': ?role?.name, ...prefs});
    final brand = loadBrand(brandId);
    final settings = await AppSettings.load(
      defaults: {...brand.defaults, ...brandDefaults},
      secrets: MemorySecretStore(),
    );
    // p4n4-api "runs without auth", so sign-in is the role picker.
    final session = await Session.load(settings, probe: (_) async => AuthMode.off);
    tester.view.physicalSize = size;
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
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (name, size, bottomNav) in [
      ('phone', const Size(390, 844), true),
      ('desktop', const Size(1280, 800), false),
    ]) {
      testWidgets('normie $name layout in ${mode.name} mode renders every tab', (tester) async {
        await pumpAt(tester, size, mode, role: Role.normie);
        expect(find.byType(NavigationDestination), bottomNav ? findsNWidgets(4) : findsNothing);
        for (final tab in ['Services', 'Device', 'Clients']) {
          expect(nav(tab), findsNothing, reason: tab);
        }
        expect(find.textContaining('localhost'), findsNothing, reason: 'no hosts for normies');
        expect(find.byTooltip('Sign out'), findsOneWidget);
        for (final tab in ['Home', 'Assistant', 'Charts', 'Cameras']) {
          await tester.tap(nav(tab));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
      });

      testWidgets('power $name layout in ${mode.name} mode renders every tab but Clients', (tester) async {
        await pumpAt(tester, size, mode, role: Role.power);
        expect(find.byType(NavigationDestination), bottomNav ? findsNWidgets(5) : findsNothing);
        expect(find.byType(NavigationRail), bottomNav ? findsNothing : findsOneWidget);
        expect(nav('Clients'), findsNothing);
        expect(find.byTooltip('Clients'), findsNothing);
        if (!bottomNav) expect(find.text('localhost'), findsOneWidget);
        for (final tab in ['Home', 'Assistant', 'Charts', 'Cameras', 'Device', if (!bottomNav) 'Services']) {
          await tester.tap(nav(tab));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
        // Home plus five tabs: on phones the last one opens from the app bar.
        expect(find.byTooltip('Services'), bottomNav ? findsOneWidget : findsNothing);
      });

      testWidgets('admin $name layout in ${mode.name} mode renders every tab', (tester) async {
        await pumpAt(tester, size, mode);
        final brightness = Theme.of(tester.element(find.byType(HomeShell))).brightness;
        expect(brightness, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        expect(find.byType(NavigationBar), bottomNav ? findsOneWidget : findsNothing);
        expect(find.byType(NavigationRail), bottomNav ? findsNothing : findsOneWidget);
        for (final tab in [
          'Home',
          'Assistant',
          'Charts',
          'Cameras',
          'Device',
          if (!bottomNav) ...['Services', 'Clients'],
        ]) {
          await tester.tap(nav(tab));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
        // Past five destinations, phones open the rest from the app bar.
        expect(find.byTooltip('Services'), bottomNav ? findsOneWidget : findsNothing);
        expect(find.byTooltip('Clients'), bottomNav ? findsOneWidget : findsNothing);
        if (bottomNav) {
          await tester.tap(find.byTooltip('Clients'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Client deployments'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'CLIENTS');
        }
      });
    }
  }

  testWidgets('theme toggle cycles system → light → dark', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.system);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    for (final expected in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      await tester.tap(find.byTooltip(RegExp(r'^Theme: ')));
      await tester.pump();
      expect(settings.themeMode, expected);
    }
  });

  testWidgets('acme brand drives name, colours, tabs and settings', (tester) async {
    await pumpAt(tester, const Size(390, 844), ThemeMode.light, brandId: 'acme');
    final brand = loadBrand('acme');
    final context = tester.element(find.byType(HomeShell));

    expect(Theme.of(context).colorScheme.primary, brand.light.accent);
    expect(find.textContaining('acme.edge', findRichText: true), findsOneWidget); // wordmark
    expect(nav('Cameras'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5)); // Home + 4 brand tabs; Clients in the app bar
    await tester.tap(nav('Services'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('acme-api'), findsOneWidget); // the platform name in service labels
    expect(SettingsScope.of(context).host, '192.168.1.50');
    expect(SettingsScope.of(context).grafanaPath, '/d/edge/overview');

    await openSettings(tester);
    expect(find.text('Cameras'), findsNothing);
    expect(find.text('Endpoints'), findsOneWidget);
    await tester.tap(find.text('Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('acme-api base URL'), findsOneWidget);
  });

  testWidgets('sign in picks a view and sign out returns to the role picker', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: null);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    await tester.tap(find.text('Viewer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(nav('Home'), findsOneWidget);
    expect(nav('Services'), findsNothing);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Power user'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(nav('Services'), findsOneWidget);
    expect(nav('Clients'), findsNothing);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('Administrator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(nav('Services'), findsOneWidget);
    expect(nav('Clients'), findsOneWidget);
    expect(nav('Home'), findsOneWidget);
  });

  testWidgets('normie settings hide connection and admin-only sections', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.normie);
    await openSettings(tester);
    expect(find.text('Host'), findsNothing);
    expect(find.text('p4n4-api base URL'), findsNothing);
    // Nothing that changes the system: only preferences for this device.
    for (final section in [
      'Connection',
      'Endpoints',
      'Device readings',
      'Charts',
      'Cameras',
      'Views',
      'Users',
      'Diagnostics',
    ]) {
      expect(find.text(section), findsNothing, reason: section);
    }
    for (final category in ['Appearance', 'Accessibility', 'Language & region', 'About']) {
      expect(find.text(category), findsOneWidget, reason: category);
    }
    // In the category list, and on the Account page open beside it.
    expect(find.text('Signed in without an account'), findsNWidgets(2));
    expect(find.text('Viewer · picked at sign-in'), findsNWidgets(2));

    await tester.tap(find.text('About'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Licenses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('power settings have connection and endpoints but no admin sections', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light, role: Role.power);
    await openSettings(tester, 'Connection');
    expect(find.text('Host'), findsOneWidget);
    await tester.tap(find.text('Endpoints'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Metrics URL'), findsOneWidget);
    expect(find.text('Dashboard path'), findsOneWidget);
    // Admins' calls: what the dashboard shows instead of real readings, and how Grafana is framed.
    expect(find.text('Demo data'), findsNothing);
    expect(find.text('Kiosk mode'), findsNothing);
    // The assistant is chosen on its tab and kept by the API: no Ollama or Letta URLs here.
    expect(find.textContaining('Ollama'), findsNothing);
    for (final section in ['Views', 'Users', 'Diagnostics']) {
      expect(find.text(section), findsNothing, reason: section);
    }
    expect(find.text('Power user · picked at sign-in'), findsOneWidget); // the Account tile's summary
  });

  testWidgets('admins get demo data, kiosk mode and each view\'s tabs in settings', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light);
    await openSettings(tester, 'Endpoints');
    expect(find.text('Demo data'), findsOneWidget);
    expect(find.text('Kiosk mode'), findsOneWidget);
    await tester.tap(find.text('Views'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Power user'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
  });

  testWidgets('an admin previewing the power view gets the power user\'s settings', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light);
    SessionScope.of(tester.element(find.byType(HomeShell))).preview = Role.power;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await openSettings(tester, 'Endpoints');
    expect(find.text('Demo data'), findsNothing);
    expect(find.text('Kiosk mode'), findsNothing);
    expect(find.text('Views'), findsNothing);
  });

  testWidgets('admins choose which tabs each view shows', (tester) async {
    final saved = <Map<String, Object?>>[];
    late AppSettings settings;
    await http.runWithClient(() async {
      await pumpAt(tester, const Size(1280, 4000), ThemeMode.light); // tall enough for every settings section
      settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
      await openSettings(tester, 'Views');

      await tester.tap(find.byKey(const ValueKey('normie-video')));
      await tester.tap(find.byKey(const ValueKey('normie-edge')));
      await tester.tap(find.byKey(const ValueKey('power-services')));
      await tester.pump();
    }, () => viewsApi(saved));
    expect(settings.tabsFor(Role.normie), [DashTab.agent, DashTab.grafana, DashTab.edge]);
    expect(settings.tabsFor(Role.power), [DashTab.agent, DashTab.grafana, DashTab.video, DashTab.edge]);
    // Saved on the deployment's API, for every device: the brand defaults for what wasn't changed.
    expect(saved.last, {
      'tab_order': null,
      'power_tabs': ['agent', 'grafana', 'video', 'edge'],
      'normie_tabs': ['agent', 'grafana', 'edge'],
    });

    final brand = loadBrand('p4n4');
    expect(screensFor(Role.normie, brand, settings), [Screen.home, Screen.agent, Screen.grafana, Screen.edge]);
    expect(screensFor(Role.power, brand, settings), [
      Screen.home,
      Screen.agent,
      Screen.grafana,
      Screen.video,
      Screen.edge,
    ]);
    expect(screensFor(Role.admin, brand, settings), [
      Screen.home,
      Screen.agent,
      Screen.grafana,
      Screen.video,
      Screen.edge,
      Screen.services,
      Screen.clients,
    ]);

    await http.runWithClient(() => settings.setTabsFor(Role.power, []), () => viewsApi(saved));
    expect(screensFor(Role.power, brand, settings), [Screen.home], reason: 'never an empty dashboard');
  });

  testWidgets('admins drag the tabs into the order every view shows', (tester) async {
    final saved = <Map<String, Object?>>[];
    await http.runWithClient(() async {
      await pumpAt(tester, const Size(1280, 4000), ThemeMode.light);
      final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
      NavigationRail rail() => tester.widget(find.byType(NavigationRail));
      await tester.tap(nav('Charts'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(rail().selectedIndex, 2);

      await openSettings(tester, 'Views');
      // Services' handle, dragged above Agent.
      final handle = find.descendant(
        of: find.byKey(const ValueKey('order-services')),
        matching: find.byIcon(Icons.drag_handle),
      );
      final from = tester.getCenter(handle);
      final to = tester.getTopLeft(find.byKey(const ValueKey('order-agent'))).dy;
      final drag = await tester.startGesture(from);
      for (var y = from.dy; y > to; y -= 10) {
        await drag.moveTo(Offset(from.dx, y));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 500)); // let the gap open before dropping
      await drag.up();
      // The drop animates over several frames before the list reports the move.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(settings.tabOrder, [DashTab.services, DashTab.agent, DashTab.grafana, DashTab.video, DashTab.edge]);
      expect(screensFor(Role.normie, loadBrand('p4n4'), settings), [
        Screen.home,
        Screen.agent,
        Screen.grafana,
        Screen.video,
      ]);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      final labels = [
        for (final t in ['Home', 'Services', 'Assistant', 'Charts', 'Cameras', 'Device', 'Clients'])
          tester.getTopLeft(nav(t)).dy,
      ];
      expect(labels, [...labels]..sort(), reason: 'Home, the new order, then Clients');
      expect(rail().selectedIndex, 3, reason: 'Grafana stays open as it moves');

      await settings.resetTabOrder();
      expect(settings.tabOrder, DashTab.values);
    }, () => viewsApi(saved));
    expect(saved.first['tab_order'], ['services', 'agent', 'grafana', 'video', 'edge']);
    expect(saved.last['tab_order'], isNull, reason: 'reset: the brand\'s order again');
  });

  testWidgets('a view change the API refuses is undone and explained', (tester) async {
    late AppSettings settings;
    await http.runWithClient(() async {
      await pumpAt(tester, const Size(1280, 4000), ThemeMode.light);
      settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
      await openSettings(tester, 'Views');
      await tester.tap(find.byKey(const ValueKey('normie-video')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }, () => viewsApi([], refuse: true));
    expect(settings.tabsFor(Role.normie), [DashTab.agent, DashTab.grafana, DashTab.video]);
    expect(find.text("Couldn't save the views: Requires the admin role."), findsOneWidget);
  });

  testWidgets('a saved tab order skips unknown tabs and falls back to the brand\'s', (tester) async {
    SharedPreferences.setMockInitialValues({'tabOrder': 'services,bogus,video'});
    final settings = await AppSettings.load(defaults: {'tabOrder': 'edge'}, secrets: MemorySecretStore());
    expect(settings.tabOrder, [DashTab.services, DashTab.video, DashTab.agent, DashTab.grafana, DashTab.edge]);
    expect(settings.tabsFor(Role.normie), [DashTab.video, DashTab.agent, DashTab.grafana]);

    await http.runWithClient(settings.resetTabOrder, () => viewsApi([]));
    expect(settings.tabOrder, [DashTab.edge, DashTab.agent, DashTab.grafana, DashTab.video, DashTab.services]);
    expect((await SharedPreferences.getInstance()).containsKey('tabOrder'), isFalse, reason: 'on the API now');
  });

  testWidgets('a brand\'s old clientTabs default still sets the normie tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(defaults: {'clientTabs': 'grafana'}, secrets: MemorySecretStore());
    expect(settings.tabsFor(Role.normie), [DashTab.grafana]);
  });

  testWidgets('admins preview the normie view and come back', (tester) async {
    await pumpAt(tester, const Size(1280, 4000), ThemeMode.light);
    await openSettings(tester, 'Views');
    await tester.tap(find.text('See as Viewer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    const banner = "You're seeing the dashboard as a Viewer sees it";
    expect(find.text(banner), findsOneWidget);
    expect(nav('Home'), findsOneWidget);
    expect(nav('Services'), findsNothing);
    expect(find.text('Viewer'), findsOneWidget); // the badge

    await tester.tap(find.text('Back to admin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(banner), findsNothing);
    expect(nav('Clients'), findsOneWidget);
  });

  testWidgets('connecting to a deployment in Clients switches the dashboard to it', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await settings.saveDeployment(Deployment(id: 'site', name: 'Site', values: {'host': '10.0.0.2'}));
    await tester.tap(nav('Clients'));
    await tester.pump(const Duration(milliseconds: 300));

    // The connected deployment's button is disabled, so the enabled one is Site's.
    final connect = find.widgetWithText(TextButton, 'Connect');
    expect(connect, findsNWidgets(2));
    await tester.tap(connect.last);
    await tester.pump();

    expect(settings.deployment.name, 'Site');
    // Each deployment has its own p4n4-api and accounts: sign in there first.
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.pump(); // the API check
    await tester.tap(find.text('Administrator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Site · 10.0.0.2'), findsOneWidget);
  });

  const cameras = [
    Camera(id: 'a', name: 'Gate', url: 'http://cam-a/stream'),
    Camera(id: 'b', name: 'Yard', url: 'http://cam-b/snap.jpg'),
  ];

  testWidgets('video shows one camera or all of them in a grid', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    SettingsScope.of(tester.element(find.byType(HomeShell))).cameras = cameras;
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MjpegView), findsOneWidget);
    expect(find.text('http://cam-a/stream'), findsOneWidget);

    await tester.tap(find.byTooltip('All cameras'));
    await tester.pump();
    expect(find.text('2 cameras'), findsOneWidget);
    expect(find.byType(MjpegView), findsNWidgets(2));

    // Tapping a tile's label opens that camera on its own.
    await tester.tap(find.text('Yard'));
    await tester.pump();
    expect(find.byType(MjpegView), findsOneWidget);
    expect(find.text('http://cam-b/snap.jpg'), findsOneWidget);
    expect(find.byTooltip('All cameras'), findsOneWidget);
  });

  testWidgets('normies see camera names but no URLs or camera controls', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.normie);
    SettingsScope.of(tester.element(find.byType(HomeShell))).cameras = cameras;
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gate'), findsWidgets);
    expect(find.textContaining('http://'), findsNothing);
    expect(find.byTooltip('Add camera'), findsNothing);
    expect(find.byTooltip('Edit camera'), findsNothing);
  });

  testWidgets('admins add a camera; Save waits for a valid URL', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Add camera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final save = find.widgetWithText(FilledButton, 'Save');
    final url = find.widgetWithText(TextField, 'Stream, snapshot or video URL');
    await tester.enterText(url, 'not a url');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Gate');
    await tester.enterText(url, 'http://cam/stream');
    await tester.pump();
    await tester.tap(save);
    // No pumpAndSettle in this test: loading spinners keep animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.cameras.single.name, 'Gate');
    expect(find.byType(MjpegView), findsOneWidget);
  });

  testWidgets('admins swap in demo cameras, which play as video and leave the saved ones alone', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    settings.cameras = cameras;
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Demo cameras'));
    await tester.pump();
    expect(settings.videoDemo, isTrue);
    expect(find.textContaining('Blender Foundation'), findsOneWidget);
    expect(find.byType(VideoView), findsOneWidget);
    // Demo cameras aren't the deployment's to edit.
    expect(find.byTooltip('Add camera'), findsNothing);
    expect(find.byTooltip('Edit camera'), findsNothing);

    await tester.tap(find.byTooltip('All cameras'));
    await tester.pump();
    expect(find.text('${demoCameras.length} cameras'), findsOneWidget);
    expect(find.byType(VideoView), findsNWidgets(demoCameras.length));
    expect(find.byType(MjpegView), findsNothing);

    await tester.tap(find.byTooltip('Demo cameras'));
    await tester.pump();
    expect([for (final c in settings.cameras) c.id], ['a', 'b']);
    expect(find.byType(MjpegView), findsNWidgets(2));
    expect(find.textContaining('Blender Foundation'), findsNothing);
  });

  testWidgets('without cameras, admins are offered the demo ones; normies are not', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Use demo cameras'));
    await tester.pump();
    expect(find.byType(VideoView), findsOneWidget);
  });

  testWidgets('normies get no demo camera switch', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.normie);
    await tester.tap(nav('Cameras'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Demo cameras'), findsNothing);
    expect(find.text('Use demo cameras'), findsNothing);
  });

  group('the assistant', () {
    const models = ['qwen2.5:0.5b', 'llama3.2'];

    /// p4n4-api's agents endpoints; everything else (status checks) is a 404.
    /// [chosenAt] says when an operator chose the assistant (null: never).
    MockClient api(List<http.Request> seen, {String? chosenAt}) => MockClient((r) async {
      seen.add(r);
      return switch ((r.method, r.url.path)) {
        ('GET', '/api/v1/agents/config') => http.Response(
          jsonEncode({'backend': 'ollama', 'model': null, 'agent_id': null, 'updated_at': chosenAt}),
          200,
        ),
        ('PUT', '/api/v1/agents/config') => http.Response(
          jsonEncode({...jsonDecode(r.body) as Map, 'updated_at': 'now', 'updated_by': 'power'}),
          200,
        ),
        ('GET', '/api/v1/agents/models') => http.Response(
          jsonEncode({
            'models': [
              for (final m in models) {'name': m},
            ],
          }),
          200,
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

    testWidgets('viewers chat with it but never see or change its model', (tester) async {
      final seen = <http.Request>[];
      await http.runWithClient(() async {
        await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.normie);
        await tester.tap(nav('Assistant'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Ask your assistant'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(find.byType(SegmentedButton<AgentBackend>), findsNothing);
        for (final m in models) {
          expect(find.text(m), findsNothing, reason: m);
        }

        await tester.tap(find.text('Is everything running normally?'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('All good.'), findsOneWidget);
      }, () => api(seen));

      final chat = seen.singleWhere((r) => r.url.path == '/api/v1/agents/chat');
      expect(
        jsonDecode(chat.body),
        containsPair('model', 'qwen2.5:0.5b'),
        reason: 'the first listed, as the API picks',
      );
      expect(seen.where((r) => r.method == 'PUT'), isEmpty);
    });

    testWidgets('power users choose its model for everyone', (tester) async {
      final seen = <http.Request>[];
      await http.runWithClient(() async {
        await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.power);
        await tester.tap(nav('Assistant'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SegmentedButton<AgentBackend>), findsOneWidget);

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('llama3.2').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }, () => api(seen));

      final put = seen.singleWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body), {'backend': 'ollama', 'model': 'llama3.2', 'agent_id': null});
    });

    /// The Assistant tab with a brand that names `llama3.2` as its assistant.
    Future<List<http.Request>> openWithBrandModel(WidgetTester tester, Role role, {String? chosenAt}) async {
      final seen = <http.Request>[];
      await http.runWithClient(() async {
        await pumpAt(
          tester,
          const Size(1280, 800),
          ThemeMode.light,
          role: role,
          brandDefaults: {'ollamaModel': 'llama3.2'},
        );
        await tester.tap(nav('Assistant'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }, () => api(seen, chosenAt: chosenAt));
      return seen;
    }

    testWidgets("the brand's model becomes the deployment's while nobody has chosen one", (tester) async {
      final seen = await openWithBrandModel(tester, Role.power);
      final put = seen.singleWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body), {'backend': 'ollama', 'model': 'llama3.2', 'agent_id': null});
      expect(
        tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).initialValue,
        'llama3.2',
      );
    });

    testWidgets("a deployment's own choice is never replaced by the brand's", (tester) async {
      final seen = await openWithBrandModel(tester, Role.power, chosenAt: '2026-10-04T12:00:00+00:00');
      expect(seen.where((r) => r.method == 'PUT'), isEmpty);
    });

    testWidgets("viewers don't seed it: the API wouldn't let them choose", (tester) async {
      final seen = await openWithBrandModel(tester, Role.normie);
      expect(seen.where((r) => r.method == 'PUT'), isEmpty);
    });
  });

  testWidgets('viewers see device readings in plain words, without demo data or load average', (tester) async {
    await pumpAt(tester, const Size(1280, 1600), ThemeMode.light, role: Role.normie, prefs: {'normieTabs': 'edge'});
    await tester.tap(nav('Device'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Processor'), findsWidgets);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Load average'), findsNothing);
    expect(find.text('Storage used'), findsOneWidget);
    expect(find.byType(TagBadge), findsWidgets, reason: 'Normal / High / Very high next to readings');
  });

  testWidgets('power users get load average; only admins get the demo-data switch', (tester) async {
    await pumpAt(tester, const Size(1280, 1600), ThemeMode.light, role: Role.power);
    await tester.tap(nav('Device'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Load average'), findsOneWidget);
  });

  testWidgets('admins get the demo-data switch on the Device tab', (tester) async {
    await pumpAt(tester, const Size(1280, 1600), ThemeMode.light);
    await tester.tap(nav('Device'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('viewers given the Services tab see apps to open, not hosts, ports or the API', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light, role: Role.normie, prefs: {'normieTabs': 'services'});
    await tester.tap(nav('Services'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Grafana'), findsOneWidget);
    for (final hidden in ['MQTT', 'p4n4-api', 'Swagger UI', 'API gateway']) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    expect(find.textContaining('localhost'), findsNothing);
    expect(find.byTooltip('Stack actions'), findsNothing);
  });

  testWidgets('only admins get stack actions', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light, role: Role.power);
    await tester.tap(nav('Services'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Stack actions'), findsNothing);
    expect(find.text('p4n4-api'), findsOneWidget);
  });
}
