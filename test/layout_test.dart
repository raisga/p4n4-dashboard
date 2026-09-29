import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpAt(WidgetTester tester, Size size, ThemeMode mode, {String brandId = 'p4n4'}) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'themeMode': mode.name});
    final brand = loadBrand(brandId);
    final settings = await AppSettings.load(defaults: brand.defaults);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BrandScope(
        brand: brand,
        child: SettingsScope(settings: settings, child: const DashboardApp()),
      ),
    );
    await tester.pump();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (name, size, bottomNav) in [
      ('phone', const Size(390, 844), true),
      ('desktop', const Size(1280, 800), false),
    ]) {
      testWidgets('$name layout in ${mode.name} mode renders every tab', (tester) async {
        await pumpAt(tester, size, mode);
        final brightness = Theme.of(tester.element(find.byType(HomeShell))).brightness;
        expect(brightness, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        expect(find.byType(NavigationBar), bottomNav ? findsOneWidget : findsNothing);
        expect(find.byType(NavigationRail), bottomNav ? findsNothing : findsOneWidget);
        for (final tab in ['SERVICES', 'EDGE', 'AGENT', 'GRAFANA', 'VIDEO']) {
          await tester.tap(find.text(tab).last);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
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
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(SettingsScope.of(context).host, '192.168.1.50');
    expect(SettingsScope.of(context).grafanaPath, '/d/edge/overview');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('VIDEO'), findsNothing);
    expect(find.text('acme-api base URL'), findsOneWidget);
  });
}
