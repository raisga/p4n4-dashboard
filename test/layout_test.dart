import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/pages/login_page.dart';
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    ThemeMode mode, {
    String brandId = 'p4n4',
    Role? role = Role.admin,
  }) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'themeMode': mode.name, 'role': ?role?.name});
    final brand = loadBrand(brandId);
    final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
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
        for (final tab in ['SERVICES', 'EDGE', 'CLIENTS']) {
          expect(find.text(tab), findsNothing, reason: tab);
        }
        expect(find.textContaining('localhost'), findsNothing, reason: 'no hosts for normies');
        expect(find.byTooltip('Sign out'), findsOneWidget);
        for (final tab in ['HOME', 'AGENT', 'GRAFANA', 'VIDEO']) {
          await tester.tap(find.text(tab).last);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
      });

      testWidgets('power $name layout in ${mode.name} mode renders every tab but Clients', (tester) async {
        await pumpAt(tester, size, mode, role: Role.power);
        expect(find.byType(NavigationDestination), bottomNav ? findsNWidgets(5) : findsNothing);
        expect(find.byType(NavigationRail), bottomNav ? findsNothing : findsOneWidget);
        expect(find.text('HOME'), findsNothing);
        expect(find.text('CLIENTS'), findsNothing);
        expect(find.byTooltip('Clients'), findsNothing);
        if (!bottomNav) expect(find.text('// localhost'), findsOneWidget);
        for (final tab in ['SERVICES', 'EDGE', 'AGENT', 'GRAFANA', 'VIDEO']) {
          await tester.tap(find.text(tab).last);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
      });

      testWidgets('admin $name layout in ${mode.name} mode renders every tab', (tester) async {
        await pumpAt(tester, size, mode);
        final brightness = Theme.of(tester.element(find.byType(HomeShell))).brightness;
        expect(brightness, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        expect(find.byType(NavigationBar), bottomNav ? findsOneWidget : findsNothing);
        expect(find.byType(NavigationRail), bottomNav ? findsNothing : findsOneWidget);
        for (final tab in ['SERVICES', 'EDGE', 'AGENT', 'GRAFANA', 'VIDEO', if (!bottomNav) 'CLIENTS']) {
          await tester.tap(find.text(tab).last);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
        // Past five destinations, phones open the rest from the app bar.
        expect(find.byTooltip('Clients'), bottomNav ? findsOneWidget : findsNothing);
        if (bottomNav) {
          await tester.tap(find.byTooltip('Clients'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.textContaining('Deployments', findRichText: true), findsOneWidget);
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
    expect(find.textContaining('acme-iot', findRichText: true), findsOneWidget);
    expect(find.text('VIDEO'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5)); // 4 brand tabs + Clients
    expect(SettingsScope.of(context).host, '192.168.1.50');
    expect(SettingsScope.of(context).grafanaPath, '/d/edge/overview');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('VIDEO'), findsNothing);
    expect(find.text('acme-api base URL'), findsOneWidget);
  });

  testWidgets('sign in picks a view and sign out returns to the role picker', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: null);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    await tester.tap(find.text('Normie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('SERVICES'), findsNothing);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Power user'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SERVICES'), findsOneWidget);
    expect(find.text('CLIENTS'), findsNothing);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('Administrator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SERVICES'), findsOneWidget);
    expect(find.text('CLIENTS'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('normie settings hide connection and admin-only sections', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.normie);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Host'), findsNothing);
    expect(find.text('p4n4-api base URL'), findsNothing);
    expect(find.textContaining('VIEWS', findRichText: true), findsNothing);
    expect(find.text('Signed in without an account'), findsOneWidget);
    expect(find.text('normie view · role picked at sign-in'), findsOneWidget);

    await tester.ensureVisible(find.text('LICENSES'));
    await tester.tap(find.text('LICENSES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('power settings have connection and endpoints but no admin sections', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light, role: Role.power);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Ollama base URL'), findsOneWidget);
    for (final tag in ['VIEWS', 'USERS', 'DIAGNOSTICS']) {
      expect(find.textContaining(tag, findRichText: true), findsNothing, reason: tag);
    }
    expect(find.text('power view · role picked at sign-in'), findsOneWidget);
  });

  testWidgets('admins choose which tabs each view shows', (tester) async {
    await pumpAt(tester, const Size(1280, 4000), ThemeMode.light); // tall enough for every settings section
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('normie-video')));
    await tester.tap(find.byKey(const ValueKey('normie-edge')));
    await tester.tap(find.byKey(const ValueKey('power-services')));
    await tester.pump();
    expect(settings.tabsFor(Role.normie), [DashTab.edge, DashTab.agent, DashTab.grafana]);
    expect(settings.tabsFor(Role.power), [DashTab.edge, DashTab.agent, DashTab.grafana, DashTab.video]);

    final brand = loadBrand('p4n4');
    expect(screensFor(Role.normie, brand, settings), [Screen.home, Screen.edge, Screen.agent, Screen.grafana]);
    expect(screensFor(Role.power, brand, settings), [Screen.edge, Screen.agent, Screen.grafana, Screen.video]);
    expect(screensFor(Role.admin, brand, settings), [...brand.tabs.map(Screen.of), Screen.clients]);

    await settings.setTabsFor(Role.power, []);
    expect(screensFor(Role.power, brand, settings), [Screen.home], reason: 'never an empty dashboard');
  });

  testWidgets('a brand\'s old clientTabs default still sets the normie tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(defaults: {'clientTabs': 'grafana'}, secrets: MemorySecretStore());
    expect(settings.tabsFor(Role.normie), [DashTab.grafana]);
  });

  testWidgets('admins preview the normie view and come back', (tester) async {
    await pumpAt(tester, const Size(1280, 4000), ThemeMode.light);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('PREVIEW NORMIE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Previewing the normie view'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('SERVICES'), findsNothing);
    expect(find.text('NORMIE'), findsOneWidget); // the badge

    await tester.tap(find.text('BACK TO ADMIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Previewing the normie view'), findsNothing);
    expect(find.text('CLIENTS'), findsOneWidget);
  });

  testWidgets('connecting to a deployment in Clients switches the dashboard to it', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await settings.saveDeployment(Deployment(id: 'site', name: 'Site', values: {'host': '10.0.0.2'}));
    await tester.tap(find.text('CLIENTS'));
    await tester.pump(const Duration(milliseconds: 300));

    // The connected deployment's button is disabled, so the enabled one is Site's.
    final connect = find.widgetWithText(TextButton, 'CONNECT');
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
    expect(find.text('// Site · 10.0.0.2'), findsOneWidget);
  });

  const cameras = [
    Camera(id: 'a', name: 'Gate', url: 'http://cam-a/stream'),
    Camera(id: 'b', name: 'Yard', url: 'http://cam-b/snap.jpg'),
  ];

  testWidgets('video shows one camera or all of them in a grid', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    SettingsScope.of(tester.element(find.byType(HomeShell))).cameras = cameras;
    await tester.tap(find.text('VIDEO'));
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
    await tester.tap(find.text('VIDEO'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gate'), findsWidgets);
    expect(find.textContaining('http://'), findsNothing);
    expect(find.byTooltip('Add camera'), findsNothing);
    expect(find.byTooltip('Edit camera'), findsNothing);
  });

  testWidgets('admins add a camera; SAVE waits for a valid URL', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light);
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(find.text('VIDEO'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ADD CAMERA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final save = find.widgetWithText(FilledButton, 'SAVE');
    final url = find.widgetWithText(TextField, 'MJPEG or snapshot URL');
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
}
