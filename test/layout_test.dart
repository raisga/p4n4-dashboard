import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    ThemeMode mode, {
    String brandId = 'p4n4',
    Role? role = Role.admin,
  }) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'themeMode': mode.name, 'role': ?role?.name});
    final brand = loadBrand(brandId);
    final settings = await AppSettings.load(defaults: brand.defaults);
    final session = await Session.load();
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
      testWidgets('client $name layout in ${mode.name} mode renders every tab', (tester) async {
        await pumpAt(tester, size, mode, role: Role.client);
        expect(find.byType(NavigationDestination), bottomNav ? findsNWidgets(4) : findsNothing);
        for (final tab in ['SERVICES', 'EDGE', 'CLIENTS']) {
          expect(find.text(tab), findsNothing, reason: tab);
        }
        expect(find.byTooltip('Sign out'), findsOneWidget);
        for (final tab in ['HOME', 'AGENT', 'GRAFANA', 'VIDEO']) {
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

    await tester.tap(find.text('Client'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('SERVICES'), findsNothing);

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

  testWidgets('client settings hide connection and admin-only sections', (tester) async {
    await pumpAt(tester, const Size(1280, 800), ThemeMode.light, role: Role.client);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Host'), findsNothing);
    expect(find.text('p4n4-api base URL'), findsNothing);
    expect(find.textContaining('CLIENT VIEW', findRichText: true), findsNothing);
    expect(find.text('Signed in as client'), findsOneWidget);
  });

  testWidgets('admins choose which tabs the client view shows', (tester) async {
    await pumpAt(tester, const Size(1280, 2000), ThemeMode.light); // tall enough for every settings section
    final settings = SettingsScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'VIDEO'));
    await tester.tap(find.widgetWithText(FilterChip, 'EDGE'));
    await tester.pump();
    expect(settings.clientTabs, [DashTab.edge, DashTab.agent, DashTab.grafana]);

    final brand = loadBrand('p4n4');
    expect(screensFor(Role.client, brand, settings), [Screen.home, Screen.edge, Screen.agent, Screen.grafana]);
    expect(screensFor(Role.admin, brand, settings), [...brand.tabs.map(Screen.of), Screen.clients]);
  });
}
