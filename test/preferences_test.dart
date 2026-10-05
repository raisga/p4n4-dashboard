import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/format.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

Future<AppSettings> _load(Map<String, Object> prefs, {Map<String, Object> defaults = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
}

void main() {
  group('accessibility and region settings', () {
    test('start from the defaults and are remembered', () async {
      final s = await _load({});
      expect(s.textScale, 1.0);
      expect(s.highContrast, isFalse);
      expect(s.reduceMotion, isFalse);
      expect(s.temperatureUnit, TemperatureUnit.auto);
      expect(s.timeFormat, TimeFormat.auto);

      s.textScale = 1.15;
      s.highContrast = true;
      s.reduceMotion = true;
      s.temperatureUnit = TemperatureUnit.fahrenheit;
      s.timeFormat = TimeFormat.h24;
      final again = await AppSettings.load(secrets: MemorySecretStore());
      expect(again.textScale, 1.15);
      expect(again.highContrast, isTrue);
      expect(again.reduceMotion, isTrue);
      expect(again.temperatureUnit, TemperatureUnit.fahrenheit);
      expect(again.timeFormat, TimeFormat.h24);
    });

    test('text size is kept in range and in whole percents', () async {
      final s = await _load({});
      s.textScale = 1.1500000001;
      expect(s.textScale, 1.15);
      s.textScale = 4;
      expect(s.textScale, AppSettings.textScaleRange.$2);
      expect((await _load({'textScale': 0.2})).textScale, AppSettings.textScaleRange.$1);
    });

    test('a brand can set them, and the user\'s choice wins', () async {
      final brand = await _load({}, defaults: {'textScale': 1.25, 'highContrast': true, 'timeFormat': 'h12'});
      expect(brand.textScale, 1.25);
      expect(brand.highContrast, isTrue);
      expect(brand.timeFormat, TimeFormat.h12);
      expect((await _load({}, defaults: {'textScale': 1})).textScale, 1.0, reason: 'a whole number in JSON');
      expect((await _load({'textScale': 0.9}, defaults: {'textScale': 1.25})).textScale, 0.9);
      expect((await _load({'temperatureUnit': 'bogus'})).temperatureUnit, TemperatureUnit.auto);
    });

    test('are app-wide: connecting to another deployment keeps them', () async {
      final s = await _load({});
      s.textScale = 1.3;
      s.temperatureUnit = TemperatureUnit.celsius;
      final site = Deployment(id: s.newDeploymentId(), name: 'Site', values: {'host': '10.0.0.2'});
      await s.saveDeployment(site);
      await s.connect(site.id);
      expect(s.textScale, 1.3);
      expect(s.temperatureUnit, TemperatureUnit.celsius);
    });
  });

  group('Formats', () {
    setUpAll(initializeDateFormatting); // the app gets it from flutter_localizations
    const en = Formats(locale: 'en', fahrenheit: false, use24h: null);
    final t = DateTime(2026, 10, 4, 14, 5, 9);

    test('temperatures in the chosen unit', () {
      expect(en.temperature(51.34), '51°C');
      expect(en.temperature(51.34, 1), '51.3°C');
      const f = Formats(locale: 'en', fahrenheit: true, use24h: null);
      expect(f.temperature(100), '212°F');
      expect(f.temperature(51.3, 1), '124.3°F');
    });

    test('decimals in the language\'s style', () {
      expect(en.decimal(1234.5), '1,234.5');
      expect(en.percent(45.26, 1), '45.3%');
      const es = Formats(locale: 'es', fahrenheit: false, use24h: true);
      expect(es.decimal(51.34), '51,3');
      expect(es.temperature(51.34, 1), '51,3°C');
    });

    test('times in the chosen clock', () {
      expect(const Formats(locale: 'en', fahrenheit: false, use24h: true).clock(t), '14:05');
      expect(const Formats(locale: 'en', fahrenheit: false, use24h: true).clock(t, seconds: true), '14:05:09');
      // intl puts a narrow no-break space before AM/PM.
      String plain(String s) => s.replaceAll(' ', ' ');
      expect(plain(const Formats(locale: 'en', fahrenheit: false, use24h: false).clock(t)), '2:05 PM');
      expect(plain(en.clock(t)), '2:05 PM', reason: 'English\'s custom');
    });
  });

  group('in the app', () {
    Future<AppSettings> pump(
      WidgetTester tester,
      Map<String, Object> prefs, {
      Size size = const Size(1280, 900),
      Role role = Role.admin,
    }) async {
      SharedPreferences.setMockInitialValues({'edgeDemo': true, 'role': role.name, ...prefs});
      final brand = loadBrand('p4n4');
      final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
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
      return settings;
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // status spinners never settle
    }

    BuildContext shell(WidgetTester tester) => tester.element(find.byType(HomeShell, skipOffstage: false));

    testWidgets('text size scales on top of the device\'s', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final s = await pump(tester, {'textScale': 1.2});
      expect(MediaQuery.textScalerOf(shell(tester)).scale(10), closeTo(13.2, 0.001));
      s.textScale = 1.0;
      await settle(tester);
      expect(MediaQuery.textScalerOf(shell(tester)).scale(10), closeTo(11, 0.001));
    });

    testWidgets('high contrast strengthens the palette, also when the device asks', (tester) async {
      final s = await pump(tester, {'themeMode': 'light'});
      final brand = loadBrand('p4n4');
      expect(shell(tester).p4.muted, brand.light.muted);
      s.highContrast = true;
      await settle(tester);
      expect(shell(tester).p4.muted, brand.light.contrasted.muted);
      expect(MediaQuery.highContrastOf(shell(tester)), isTrue);

      s.highContrast = false;
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await settle(tester);
      expect(shell(tester).p4.muted, brand.light.contrasted.muted);
    });

    test('a contrasted palette only raises contrast', () {
      for (final c in [P4Colors.light, P4Colors.dark]) {
        double contrast(Color a, Color b) {
          final (x, y) = (a.computeLuminance(), b.computeLuminance());
          return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
        }

        expect(contrast(c.contrasted.muted, c.bg2), greaterThan(contrast(c.muted, c.bg2)));
        expect(contrast(c.contrasted.border, c.bg2), greaterThan(contrast(c.border, c.bg2)));
      }
    });

    testWidgets('reduce motion turns animations off', (tester) async {
      final s = await pump(tester, {});
      expect(MediaQuery.disableAnimationsOf(shell(tester)), isFalse);
      s.reduceMotion = true;
      await settle(tester);
      expect(MediaQuery.disableAnimationsOf(shell(tester)), isTrue);
      expect(Theme.of(shell(tester)).splashFactory, NoSplash.splashFactory);
    });

    testWidgets('temperatures follow the unit picked, or the device\'s region', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final s = await pump(tester, {});
      await settle(tester);
      expect(find.textContaining('°F'), findsWidgets, reason: 'the US uses °F');
      expect(find.textContaining('°C'), findsNothing);
      s.temperatureUnit = TemperatureUnit.celsius;
      await settle(tester);
      expect(find.textContaining('°C'), findsWidgets);
      expect(find.textContaining('°F'), findsNothing);
    });

    testWidgets('search finds a setting and opens its category', (tester) async {
      await pump(tester, {});
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'contrast');
      await settle(tester);
      expect(find.text('High contrast'), findsOneWidget);
      expect(find.text('Accessibility'), findsOneWidget, reason: 'the category it is in');
      expect(find.text('Connection'), findsNothing);
      await tester.tap(find.text('High contrast'));
      await settle(tester);
      expect(find.byType(Switch), findsNWidgets(2), reason: 'the Accessibility page');

      await tester.enterText(find.byType(TextField).first, 'idioma'); // Spanish for "language": not in English
      await settle(tester);
      expect(find.text('Nothing matches "idioma"'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'espanol'); // without its accent
      await settle(tester);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('the theme pictures switch the theme', (tester) async {
      final s = await pump(tester, {'themeMode': 'light'});
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await tester.tap(find.text('Appearance'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Dark'));
      await settle(tester);
      expect(s.themeMode, ThemeMode.dark);
      expect(Theme.of(shell(tester)).brightness, Brightness.dark);
    });

    // The largest text size, in the longer language, on a phone: nothing may overflow.
    for (final role in Role.values) {
      testWidgets('the largest text fits a phone in Spanish in the ${role.name} view', (tester) async {
        await pump(
          tester,
          {'locale': 'es', 'textScale': AppSettings.textScaleRange.$2, 'temperatureUnit': 'fahrenheit'},
          role: role,
          size: const Size(390, 844),
        );
        for (final d in tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).toList()) {
          await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(d.label)));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: d.label);
        }
        await tester.tap(find.byTooltip('Ajustes'));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'settings');
        final categories = find.byIcon(Icons.chevron_right);
        for (var i = 0; i < categories.evaluate().length; i++) {
          await tester.ensureVisible(categories.at(i));
          await tester.tap(categories.at(i));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: 'settings category $i');
          await tester.tap(find.byType(BackButton));
          await settle(tester);
        }
      });
    }

    testWidgets('normies get accessibility and region settings on a phone', (tester) async {
      final s = await pump(tester, {}, role: Role.normie, size: const Size(390, 844));
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await tester.tap(find.text('Language & region'));
      await settle(tester);
      await tester.tap(find.text('24-hour'));
      await settle(tester);
      expect(s.timeFormat, TimeFormat.h24);
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      await tester.tap(find.text('Accessibility'));
      await settle(tester);
      await tester.tap(find.text('Reduce motion'));
      await settle(tester);
      expect(s.reduceMotion, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
