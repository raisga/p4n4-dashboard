import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/l10n/l10n.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map<String, dynamic>;

/// A message's placeholder names, e.g. `{platform}`; plural cases don't count.
Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)[,}]').allMatches(message).map((m) => m[1]!).toSet()..remove('other');

/// [label] in the navigation rail or bar; page titles and Home's shortcuts reuse the same words.
Finder nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);

void main() {
  group('translations', () {
    final en = _arb('en');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();

    test('every ARB file is a language in the picker, with its name', () {
      final arbs = {
        for (final f in Directory('lib/l10n').listSync().whereType<File>())
          if (RegExp(r'app_(\w+)\.arb$').firstMatch(f.path) case final m?) m[1]!,
      };
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), arbs);
      expect(supportedLanguages.toSet(), arbs);
      for (final code in arbs) {
        expect(knownLanguages.keys, contains(code), reason: 'add "$code" to knownLanguages in lib/l10n/l10n.dart');
      }
    });

    test('languages are listed by their own names', () {
      expect(languageName('es'), (native: 'Español', english: 'Spanish'));
      expect(languageName('xx'), (native: 'XX', english: 'XX'), reason: 'a language nobody named yet');
      final natives = [for (final c in supportedLanguages) languageName(c).native.toLowerCase()];
      expect(natives, [...natives]..sort());
    });

    for (final code in supportedLanguages.where((c) => c != 'en')) {
      test('$code has every English message, with the same placeholders', () {
        final arb = _arb(code);
        expect(arb.keys.where((k) => !k.startsWith('@')).toSet(), keys);
        for (final k in keys.where((k) => k != '@@locale')) {
          expect(_placeholders(arb[k] as String), _placeholders(en[k] as String), reason: k);
        }
      });
    }
  });

  group('locale setting', () {
    Future<AppSettings> load(Map<String, Object> prefs, {Map<String, Object> defaults = const {}}) {
      SharedPreferences.setMockInitialValues(prefs);
      return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
    }

    test('follows the device until one is picked, and is remembered', () async {
      final s = await load({});
      expect(s.locale, isNull);
      s.locale = const Locale('es');
      expect((await load({'locale': 'es'})).locale, const Locale('es'));
      expect((await SharedPreferences.getInstance()).getString('locale'), 'es');
      s.locale = null;
      expect(s.locale, isNull);
    });

    test('a brand can set the default language', () async {
      expect((await load({}, defaults: {'locale': 'es'})).locale, const Locale('es'));
      // The user's choice (here: follow the device) wins over the brand's.
      expect((await load({'locale': ''}, defaults: {'locale': 'es'})).locale, isNull);
    });
  });

  Future<void> pump(
    WidgetTester tester,
    Map<String, Object> prefs, {
    Role role = Role.normie,
    Size size = const Size(1280, 2000),
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
  }

  testWidgets('English unless the device or the settings say otherwise', (tester) async {
    await pump(tester, {});
    expect(nav('Home'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsOneWidget);
  });

  testWidgets('follows a Spanish device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pump(tester, {});
    expect(nav('Inicio'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
  });

  // Spanish runs longer than English: nothing may overflow on a phone.
  for (final role in Role.values) {
    testWidgets('Spanish fits a phone in the ${role.name} view', (tester) async {
      await pump(tester, {'locale': 'es'}, role: role, size: const Size(390, 844));
      for (final d in tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).toList()) {
        await tester.tap(nav(d.label));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: d.label);
      }
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Idioma y región'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'settings');
      // Every category's page, one at a time.
      final categories = find.byIcon(Icons.chevron_right);
      for (var i = 0; i < categories.evaluate().length; i++) {
        await tester.ensureVisible(categories.at(i));
        await tester.tap(categories.at(i));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'settings category $i');
        await tester.tap(find.byType(BackButton)); // pageBack() looks for an English tooltip
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });
  }

  testWidgets('an unsupported device language falls back to English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pump(tester, {});
    expect(nav('Home'), findsOneWidget);
  });

  testWidgets('the language picked in Settings applies at once', (tester) async {
    await pump(tester, {}, role: Role.admin);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Language & region'));
    await tester.pumpAndSettle();
    expect(find.text('Match device (English)'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Spanish'), findsOneWidget, reason: 'each language in English too');
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    await tester.tap(find.text('Sesión iniciada sin cuenta')); // the Account category, by who's signed in
    await tester.pumpAndSettle();
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.text('Ajustes'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // status spinners never settle
    for (final tab in ['Servicios', 'Dispositivo', 'Asistente', 'Gráficas', 'Cámaras', 'Clientes']) {
      await tester.tap(nav(tab));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: tab);
    }
    expect(find.text('Despliegues de clientes'), findsOneWidget);
  });
}
