import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/views.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

const _welcome = "Welcome to p4n4 dashboard! Here's a quick look around.";
const _navigation = 'Your screens are here. Home shows how everything is doing; tap another screen to open it.';
const _theme = 'Switch between a light and a dark look, or match your device.';
const _settings = 'Language, text size and more are in Settings. You can take this tour again from there.';
const _signOut = "Sign out here when you're done.";

void main() {
  late AppSettings settings;

  Future<void> pumpShell(
    WidgetTester tester, {
    Role role = Role.normie,
    Size size = const Size(1280, 800),
    Map<String, Object> prefs = const {},
    Map<String, Object> brandDefaults = const {},
    Map<String, Object?>? tour,
  }) async {
    SharedPreferences.setMockInitialValues({'edgeDemo': true, 'role': role.name, ...prefs});
    var brand = loadBrand('p4n4');
    if (tour != null) {
      brand = Brand.fromJson({
        'id': brand.id,
        'appName': brand.appName,
        'wordmark': {'text': brand.wordmark},
        'tour': tour,
      });
    }
    settings = await AppSettings.load(defaults: {...brand.defaults, ...brandDefaults}, secrets: MemorySecretStore());
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
    await settle(tester);
  }

  for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1280, 800))]) {
    testWidgets('a normie\'s first sign-in on a $name walks through the shell, once', (tester) async {
      await pumpShell(tester, size: size);
      for (final (i, text) in [_welcome, _navigation, _theme, _settings].indexed) {
        expect(find.text(text), findsOneWidget, reason: text);
        expect(find.text('${i + 1} of 5'), findsOneWidget);
        expect(find.text('Back'), i == 0 ? findsNothing : findsOneWidget);
        await tester.tap(find.text('Next'));
        await settle(tester);
      }
      expect(find.text(_signOut), findsOneWidget);
      expect(find.text('Skip tour'), findsNothing);
      await tester.tap(find.text('Got it'));
      await settle(tester);
      expect(find.text(_signOut), findsNothing);
      expect(settings.tourSeen, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Back returns to the previous step', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(find.text(_welcome), findsOneWidget);
    await skip(tester);
  });

  testWidgets('skipping marks the tour seen', (tester) async {
    await pumpShell(tester);
    await skip(tester);
    expect(find.text(_welcome), findsNothing);
    expect(settings.tourSeen, isTrue);
  });

  testWidgets('a device that has seen the tour doesn\'t show it again', (tester) async {
    await pumpShell(tester, prefs: {'tourSeen': true});
    expect(find.text(_welcome), findsNothing);
  });

  for (final role in [Role.admin, Role.power]) {
    testWidgets('the ${role.name} view has no tour', (tester) async {
      await pumpShell(tester, role: role);
      expect(find.text(_welcome), findsNothing);
      expect(settings.tourSeen, isFalse);
    });
  }

  testWidgets('Settings → Account takes the tour again', (tester) async {
    await pumpShell(tester, prefs: {'tourSeen': true});
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Account').first);
    await settle(tester);
    await tester.tap(find.text('Take the tour'));
    await settle(tester);
    expect(find.text(_welcome), findsOneWidget);
    expect(find.text('1 of 5'), findsOneWidget);
    await skip(tester);
  });

  testWidgets('a single-screen view skips the navigation step', (tester) async {
    await pumpShell(tester, brandDefaults: {'normieTabs': ''});
    expect(find.text('1 of 4'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text(_theme), findsOneWidget);
    await skip(tester);
  });

  testWidgets('navigation appearing mid-tour restarts it with that step', (tester) async {
    await pumpShell(tester, brandDefaults: {'normieTabs': ''});
    expect(find.text('1 of 4'), findsOneWidget);
    settings.views = const DashboardViews(normieTabs: ['agent']);
    await settle(tester);
    expect(find.text('1 of 5'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text(_navigation), findsOneWidget);
    await skip(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every step fits a phone in Spanish at the largest text size', (tester) async {
    await pumpShell(tester, size: const Size(390, 844), prefs: {'locale': 'es', 'textScale': 1.5});
    for (var i = 1; i < 5; i++) {
      expect(find.text('$i de 5'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'step $i');
    }
    await tester.tap(find.text('Entendido'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a brand\'s copy replaces the built-in text in its language', (tester) async {
    await pumpShell(
      tester,
      tour: {
        'welcome': {'en': 'Hello from Acme', 'es': 'Hola desde Acme'},
        'navigation': 'Pick a screen',
      },
    );
    expect(find.text('Hello from Acme'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Pick a screen'), findsOneWidget);
    await skip(tester);
  });
}

/// Lets the tour's fades and step changes finish (no pumpAndSettle: the shell polls).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Closes the tour, so its timers end with the test.
Future<void> skip(WidgetTester tester) async {
  await tester.tap(find.text('Skip tour'));
  await settle(tester);
}
