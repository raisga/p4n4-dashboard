import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/auth.dart';
import 'package:p4n4_dashboard/api/view_settings.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/pages/login_page.dart';
import 'package:p4n4_dashboard/widgets/idle.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, Object> _tokens(String n, String role, String user) => {
  'access_token': 'access-$n',
  'refresh_token': 'refresh-$n',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_expires_in': 604800,
  'username': user,
  'role': role,
};

Finder _nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);

void main() {
  group('Session', () {
    Future<(AppSettings, Session, List<String>)> signedInAdmin() async {
      SharedPreferences.setMockInitialValues({'textScale': 1.0});
      final settings = await AppSettings.load(defaults: {'host': 'pi'}, secrets: MemorySecretStore());
      final session = Session(settings);
      final revoked = <String>[];
      await http.runWithClient(
        () => session.signInWithPassword('root', 'pw'),
        () => MockClient((_) async => _json(_tokens('1', 'admin', 'root'))),
      );
      return (settings, session, revoked);
    }

    MockClient api(String role, String user, List<String> revoked) => MockClient((r) async {
      if (r.url.path.endsWith('/auth/logout')) {
        revoked.add((jsonDecode(r.body) as Map)['refresh_token'] as String);
        return http.Response('', 204);
      }
      return _json(_tokens('2', role, user));
    });

    test('a kiosk signs in with a viewer account, and the admin sign-in here ends', () async {
      final (settings, session, revoked) = await signedInAdmin();
      settings.textScale = 1.25;
      await http.runWithClient(() async {
        await session.startKiosk('tablet', 'pw');
        await pumpEventQueue();
      }, () => api('normie', 'tablet', revoked));
      expect((settings.kiosk, session.signedInRole, session.username), (true, Role.normie, 'tablet'));
      expect(session.kioskLocked, isTrue);
      expect(revoked, ['refresh-1']);

      // A visitor's larger text goes when the kiosk starts over.
      settings.textScale = 1.5;
      settings.restoreKioskAccessibility();
      expect(settings.textScale, 1.25);
    });

    test('only a viewer account starts a kiosk; only an admin leaves it', () async {
      final (settings, session, revoked) = await signedInAdmin();
      await expectLater(
        http.runWithClient(() => session.startKiosk('ops', 'pw'), () => api('operator', 'ops', revoked)),
        throwsA(isA<KioskAccountException>().having((e) => e.expected, 'expected', Role.normie)),
      );
      await pumpEventQueue();
      expect((settings.kiosk, session.username), (false, 'root'), reason: 'still the admin');
      expect(revoked, ['refresh-2'], reason: "the operator's sign-in isn't kept");

      await http.runWithClient(() => session.startKiosk('tablet', 'pw'), () => api('normie', 'tablet', revoked));
      await expectLater(
        http.runWithClient(() => session.leaveKiosk('tablet', 'pw'), () => api('normie', 'tablet', revoked)),
        throwsA(isA<KioskAccountException>().having((e) => e.expected, 'expected', Role.admin)),
      );
      expect(settings.kiosk, isTrue);

      await http.runWithClient(() => session.leaveKiosk('root', 'pw'), () => api('admin', 'root', revoked));
      expect((settings.kiosk, session.signedInRole, session.username), (false, Role.admin, 'root'));
    });
  });

  testWidgets('IdleWatcher fires once per quiet spell; any input starts the count again', (tester) async {
    var idle = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: IdleWatcher(timeout: const Duration(minutes: 5), onIdle: () => idle++, child: const SizedBox.expand()),
      ),
    );
    await tester.pump(const Duration(minutes: 4));
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(minutes: 4));
    expect(idle, 0, reason: 'the tap started the count again');
    await tester.pump(const Duration(minutes: 1));
    expect(idle, 1);
    await tester.pump(const Duration(minutes: 30));
    expect(idle, 1, reason: 'once per quiet spell');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(minutes: 5));
    expect(idle, 2);
  });

  group('on screen', () {
    Future<AppSettings> pump(
      WidgetTester tester,
      Role role,
      Map<String, Object> prefs, {
      Size size = const Size(1280, 800),
    }) async {
      SharedPreferences.setMockInitialValues({'edgeDemo': true, 'tourSeen': false, 'role': role.name, ...prefs});
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

    testWidgets('a kiosk has no sign-out, theme or tour, and its settings are Accessibility only', (tester) async {
      await pump(tester, Role.normie, {'kiosk': true});
      expect(find.byTooltip('Sign out'), findsNothing);
      expect(find.byTooltip('Leave kiosk mode'), findsOneWidget);
      expect(find.text('1 of 5'), findsNothing, reason: 'no tour, though this device never saw it');

      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Text size'), findsWidgets);
      for (final hidden in ['Account', 'Appearance', 'Language & region', 'About']) {
        expect(find.text(hidden), findsNothing, reason: hidden);
      }

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Leave kiosk mode'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sign in with an admin account. This device then stays signed in as that admin.'), findsOne);
    });

    testWidgets('an idle kiosk starts over: its start tab, no conversation, its own text size', (tester) async {
      final settings = await pump(tester, Role.normie, {
        'kiosk': true,
        'kioskIdleReset': 2,
        'kioskAccessibility': '{"textScale": 1.0, "highContrast": false, "reduceMotion": false}',
      });
      settings.viewSettings = const DashboardViewSettings(normie: ViewPrefs(startTab: 'agent'));
      await settings.setChatOf(settings.deployment, 'normie', [
        {'role': 'user', 'content': 'Is the freezer OK?'},
      ]);
      await tester.tap(_nav('Charts'));
      settings.textScale = 1.5;
      await tester.pump(const Duration(seconds: 1));
      int selected() => tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;
      expect(selected(), 2);

      await tester.pump(const Duration(minutes: 2));
      await tester.pump();
      expect(selected(), 1, reason: 'Home, Assistant, Charts: back on Assistant');
      expect(settings.textScale, 1.0);
      expect(settings.chatOf(settings.deployment, 'normie'), isEmpty);
      expect(find.byType(HomeShell), findsOneWidget, reason: 'still signed in');
    });

    testWidgets('a normie on their own device is never reset', (tester) async {
      final settings = await pump(tester, Role.normie, {'tourSeen': true, 'kioskIdleReset': 2});
      await tester.tap(_nav('Charts'));
      await tester.pump(const Duration(minutes: 10));
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 2);
      expect(settings.kiosk, isFalse);
    });

    testWidgets('an admin who walks away is signed out', (tester) async {
      await pump(tester, Role.admin, {'idleSignOut': 15});
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(minutes: 14));
      expect(find.byType(LoginPage), findsNothing);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LoginPage), findsOneWidget, reason: 'Settings closed, signed out');
    });

    testWidgets("admins find This device in Settings; kiosk mode needs the API's accounts", (tester) async {
      await pump(tester, Role.admin, {}, size: const Size(1280, 2000));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('This device'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Needs sign-in with p4n4-api accounts'), findsOneWidget, reason: 'signed in with the picker');
      final kiosk = find.descendant(
        of: find.ancestor(of: find.text('Kiosk mode'), matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(kiosk).onChanged, isNull);
      expect(find.text('Never'), findsNWidgets(1), reason: "admins aren't signed out when idle by default");
    });

    testWidgets('an admin turns a device into a kiosk, and leaves it again', (tester) async {
      await http.runWithClient(
        () async {
          // A device that never showed the normie tour: becoming a kiosk mustn't start it.
          SharedPreferences.setMockInitialValues({'edgeDemo': true, 'tourSeen': false});
          final brand = loadBrand('p4n4');
          final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
          final session = Session(settings, probe: (_) async => AuthMode.required);
          await session.signInWithPassword('root', 'pw');
          tester.view.physicalSize = const Size(1280, 2000);
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
          await tester.tap(find.byTooltip('Settings'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('This device'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.byType(Switch).first);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.enterText(find.widgetWithText(TextField, 'Username'), 'tablet');
          await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pw');
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Turn on'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(AlertDialog), findsNothing, reason: 'the dialog closed');
          expect(find.byType(HomeShell), findsOneWidget, reason: 'back on the shell, Settings closed');
          expect((settings.kiosk, session.username, settings.idleSignOut), (true, 'tablet', 15));
          expect(find.text('1 of 5'), findsNothing, reason: 'no tour');
          expect(find.byTooltip('Sign out'), findsNothing);

          await tester.tap(find.byTooltip('Leave kiosk mode'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.enterText(find.widgetWithText(TextField, 'Username'), 'root');
          await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pw');
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Leave kiosk mode'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(AlertDialog), findsNothing);
          expect((settings.kiosk, session.signedInRole), (false, Role.admin));
          expect(find.byTooltip('Sign out'), findsOneWidget);
        },
        () => MockClient((r) async {
          if (r.url.path.endsWith('/auth/logout')) return http.Response('', 204);
          if (!r.url.path.endsWith('/auth/token')) return http.Response('', 404);
          final user = (jsonDecode(r.body) as Map)['username'];
          return _json(_tokens(user == 'tablet' ? '2' : '1', user == 'tablet' ? 'normie' : 'admin', '$user'));
        }),
      );
    });
  });
}
