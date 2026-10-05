import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/auth.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

final _api = Uri.parse('http://pi:8000/');

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, Object> _tokens(String n, {String role = 'admin', String user = 'ana'}) => {
  'access_token': 'access-$n',
  'refresh_token': 'refresh-$n',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_expires_in': 604800,
  'username': user,
  'role': role,
};

Future<(AppSettings, MemorySecretStore)> _settings([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final store = MemorySecretStore();
  return (await AppSettings.load(defaults: {'host': 'pi'}, secrets: store), store);
}

void main() {
  group('p4n4-api auth calls', () {
    Future<T> withApi<T>(Future<T> Function() body, http.Response Function(http.Request) handler) =>
        http.runWithClient(body, () => MockClient((r) async => handler(r)));

    test('the probe tells sign-in, no auth and unreachable apart', () async {
      expect(
        await withApi(() => probeAuth(_api), (_) => _json({'detail': 'Not authenticated.'}, 401)),
        AuthMode.required,
      );
      expect(
        await withApi(() => probeAuth(_api), (_) => _json({'username': 'anonymous', 'role': 'admin', 'auth': false})),
        AuthMode.off,
      );
      expect(await withApi(() => probeAuth(_api), (_) => http.Response('<html>', 404)), AuthMode.unreachable);
      expect(await withApi(() => probeAuth(_api), (_) => throw http.ClientException('refused')), AuthMode.unreachable);
    });

    test('sign-in errors read as messages for people', () async {
      Future<Object?> error(int status) async {
        try {
          await withApi(() => signIn(_api, 'ana', 'x'), (_) => _json({'detail': '…'}, status));
        } catch (e) {
          return e;
        }
        return null;
      }

      expect('${await error(401)}', 'Wrong username or password.');
      expect('${await error(429)}', contains('Too many attempts'));
      expect(await error(500), isA<http.ClientException>());
    });
  });

  group('Session', () {
    test('signing in stores the refresh token securely and maps the API role', () async {
      final (settings, store) = await _settings();
      final session = Session(settings);
      await http.runWithClient(
        () => session.signInWithPassword(' ana ', 'pw'),
        () => MockClient((r) async {
          expect(r.url.path, '/api/v1/auth/token');
          expect(jsonDecode(r.body), {'username': 'ana', 'password': 'pw'});
          return _json(_tokens('1', role: 'operator'));
        }),
      );
      expect(session.role, Role.power, reason: 'operators get the power view');
      expect(session.mode, SignInMode.api);
      expect(session.username, 'ana');
      expect(store.values.values, contains('refresh-1'));
      expect(
        await SharedPreferences.getInstance().then((p) => '${p.getString('deployments')}'),
        isNot(contains('refresh-1')),
      );
      expect(session.accessTokenFor(Uri.parse('http://pi:8000/api/v1/stacks')), 'access-1');
      expect(session.accessTokenFor(Uri.parse('http://pi:11434/api/tags')), isNull, reason: 'not p4n4-api');
    });

    test('refreshes rotate the stored token, and run one at a time', () async {
      final (settings, store) = await _settings();
      var calls = 0;
      final gate = Completer<void>();
      final session = Session(
        settings,
        refreshApi: (api, token) async {
          calls++;
          expect(token, 'refresh-0');
          await gate.future;
          return ApiTokens.fromJson(_tokens('1'));
        },
      );
      await settings.setApiRefreshToken(settings.deployment, 'refresh-0');
      await settings.setSessionOf(settings.deployment, {'mode': 'api', 'role': 'admin', 'user': 'ana'});

      final url = Uri.parse('http://pi:8000/api/v1/stacks');
      final both = Future.wait([session.refreshFor(url), session.refreshFor(url)]);
      gate.complete();
      expect(await both, ['access-1', 'access-1']);
      expect(calls, 1, reason: 'reusing a refresh token would revoke the sign-in');
      expect(store.values.values, contains('refresh-1'));
      expect(store.values.values, isNot(contains('refresh-0')));
    });

    test('a rejected refresh signs out; an unreachable API keeps the session', () async {
      final (settings, _) = await _settings();
      Object failure = const AuthException('expired', statusCode: 401);
      final session = Session(settings, refreshApi: (_, _) async => throw failure);
      final url = Uri.parse('http://pi:8000/api/v1/stacks');

      Future<void> signedIn() async {
        await settings.setApiRefreshToken(settings.deployment, 'refresh-0');
        await settings.setSessionOf(settings.deployment, {'mode': 'api', 'role': 'admin', 'user': 'ana'});
      }

      await signedIn();
      failure = http.ClientException('connection refused');
      expect(await session.refreshFor(url), isNull);
      expect(session.role, Role.admin, reason: 'offline: keep working with the cached role');

      failure = const AuthException('expired', statusCode: 401);
      expect(await session.refreshFor(url), isNull);
      expect(session.role, isNull);
      expect(settings.apiRefreshTokenOf(settings.deployment), isEmpty);
    });

    test('a picker session is dropped once the API requires sign-in', () async {
      final (settings, _) = await _settings();
      var mode = AuthMode.unreachable;
      final session = Session(settings, probe: (_) async => mode);
      await session.signInLocal(Role.admin);

      await session.verify();
      expect(session.role, Role.admin, reason: 'no API to sign in to');
      mode = AuthMode.required;
      await session.verify();
      expect(session.role, isNull);
    });

    test('a role picked before sign-in existed moves to the connected deployment', () async {
      final (settings, _) = await _settings({'role': 'client'});
      final session = await Session.load(settings, probe: (_) async => AuthMode.off);
      expect(session.role, Role.normie, reason: 'the client view is now the normie view');
      expect(session.mode, SignInMode.local);
      expect((await SharedPreferences.getInstance()).getString('role'), isNull);
    });

    test('sign-in is per deployment', () async {
      final (settings, _) = await _settings();
      final session = Session(settings, probe: (_) async => AuthMode.off);
      await session.signInLocal(Role.admin);
      await settings.saveDeployment(Deployment(id: 'b', name: 'B', values: {'host': 'b.lan'}));

      await settings.connect('b');
      expect(session.role, isNull, reason: 'B has its own p4n4-api and accounts');
      await session.signInLocal(Role.normie);
      await settings.connect(settings.deployments.first.id);
      expect(session.role, Role.admin);
    });

    test('API roles map to views, and back', () {
      expect(roleForApi('admin'), Role.admin);
      expect(roleForApi('operator'), Role.power);
      expect(roleForApi('normie'), Role.normie);
      expect(roleForApi('something-new'), Role.normie, reason: 'unknown roles get the least');
      for (final r in Role.values) {
        expect(roleForApi(apiRoleFor(r)), r);
      }
    });

    test('a stored client session reads as normie', () async {
      final (settings, _) = await _settings();
      await settings.setSessionOf(settings.deployment, {'mode': 'api', 'role': 'client', 'user': 'ana'});
      expect(Session(settings).role, Role.normie);
    });

    test('admins preview other views without changing their account', () async {
      final (settings, _) = await _settings();
      final session = Session(settings, probe: (_) async => AuthMode.off);
      await session.signInLocal(Role.admin);

      session.preview = Role.normie;
      expect(session.role, Role.normie);
      expect(session.signedInRole, Role.admin);
      expect(session.isAdmin, isFalse);
      expect(session.isTechnical, isFalse);
      session.preview = Role.power;
      expect((session.role, session.isTechnical), (Role.power, true));
      session.preview = null;
      expect(session.role, Role.admin);

      // Switching deployment ends a preview.
      session.preview = Role.normie;
      await settings.saveDeployment(Deployment(id: 'b', name: 'B', values: {'host': 'b.lan'}));
      await settings.connect('b');
      await session.signInLocal(Role.admin);
      expect(session.role, Role.admin);

      // Only admins can preview.
      await session.signInLocal(Role.power);
      session.preview = Role.normie;
      expect(session.role, Role.power);
    });

    test('signing out forgets the tokens and revokes the sign-in', () async {
      final (settings, store) = await _settings();
      final session = Session(settings);
      await settings.setApiRefreshToken(settings.deployment, 'refresh-9');
      await settings.setSessionOf(settings.deployment, {'mode': 'api', 'role': 'admin', 'user': 'ana'});
      final revoked = Completer<String>();
      await http.runWithClient(
        () async {
          await session.signOut();
          expect(await revoked.future, '{"refresh_token":"refresh-9"}');
        },
        () => MockClient((r) async {
          if (r.url.path == '/api/v1/auth/logout') revoked.complete(r.body);
          return http.Response('', 204);
        }),
      );
      expect(session.role, isNull);
      expect(store.values, isEmpty);
    });
  });

  group('AuthClient', () {
    late AppSettings settings;
    late Session session;
    final seen = <http.Request>[];
    var accepted = 'access-1';

    setUp(() async {
      (settings, _) = await _settings();
      seen.clear();
      accepted = 'access-1';
      session = Session(settings, refreshApi: (_, _) async => ApiTokens.fromJson(_tokens('2')));
      await http.runWithClient(
        () => session.signInWithPassword('ana', 'pw'),
        () => MockClient((_) async => _json(_tokens('1'))),
      );
    });

    AuthClient client({bool proxy = false}) => AuthClient(
      MockClient((r) async {
        seen.add(r);
        final auth = r.headers['Authorization'] ?? r.headers[AuthClient.upstreamHeader];
        return auth == 'Bearer $accepted' ? _json({'ok': true}) : _json({'detail': 'expired'}, 401);
      }),
      session,
      viaProxy: (_) => proxy,
    );

    test('adds the token to p4n4-api calls only', () async {
      final c = client();
      expect((await c.get(Uri.parse('http://pi:8000/api/v1/stacks'))).statusCode, 200);
      expect(seen.single.headers['Authorization'], 'Bearer access-1');
      await c.get(Uri.parse('http://pi:11434/api/tags'));
      expect(seen.last.headers.containsKey('Authorization'), isFalse);
    });

    test('behind the dashboard proxy the token goes in X-Upstream-Authorization', () async {
      await client(proxy: true).get(Uri.parse('http://pi:8000/api/v1/stacks'));
      expect(seen.single.headers[AuthClient.upstreamHeader], 'Bearer access-1');
      expect(seen.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a 401 refreshes once and retries with the new token', () async {
      accepted = 'access-2'; // the API has expired access-1
      final res = await client().get(Uri.parse('http://pi:8000/api/v1/stacks'));
      expect(res.statusCode, 200);
      expect(seen.map((r) => r.headers['Authorization']), ['Bearer access-1', 'Bearer access-2']);
      expect(session.accessTokenFor(Uri.parse('http://pi:8000/api/v1/stacks')), 'access-2');
    });
  });

  testWidgets('signing in with a password opens the view for the account role', (tester) async {
    await http.runWithClient(
      () async {
        SharedPreferences.setMockInitialValues({});
        final brand = loadBrand('p4n4');
        final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
        final session = Session(settings, probe: (_) async => AuthMode.required);
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
        await tester.pump();
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('Administrator'), findsNothing, reason: 'no role picker while the API requires sign-in');

        await tester.enterText(find.widgetWithText(TextField, 'Username'), 'ana');
        await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Wrong username or password.'), findsOneWidget);
        final password = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
        expect(password.focusNode?.hasFocus, isTrue, reason: 'ready to retype');

        await tester.enterText(find.widgetWithText(TextField, 'Password'), 'right');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(HomeShell), findsOneWidget);
        expect(
          find.descendant(of: find.byType(NavigationRail), matching: find.text('Clients')),
          findsOneWidget,
          reason: 'admin account → admin view',
        );
      },
      () => MockClient((r) async {
        final body = jsonDecode(r.body) as Map;
        return body['password'] == 'right' ? _json(_tokens('1')) : _json({'detail': 'Invalid'}, 401);
      }),
    );
  });

  Future<Session> pumpLogin(WidgetTester tester, {required bool offerDevUsers}) async {
    SharedPreferences.setMockInitialValues({});
    final brand = loadBrand('p4n4');
    final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
    final session = Session(settings, probe: (_) async => AuthMode.required);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BrandScope(
        brand: brand,
        child: SettingsScope(
          settings: settings,
          child: SessionScope(
            session: session,
            child: MaterialApp(
              theme: buildTheme(brand.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LoginPage(offerDevUsers: offerDevUsers),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return session;
  }

  testWidgets('dev builds sign in with a dev account in one tap', (tester) async {
    final sent = <Map>[];
    await http.runWithClient(
      () async {
        final session = await pumpLogin(tester, offerDevUsers: true);
        expect(find.text('Dev accounts'), findsOneWidget);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Power user'));
        await tester.pump();
        await tester.pump();
        expect(session.role, Role.power);
      },
      () => MockClient((r) async {
        sent.add(jsonDecode(r.body) as Map);
        return _json(_tokens('1', role: 'operator', user: 'power'));
      }),
    );
    expect(sent, [
      {'username': 'power', 'password': devPassword},
    ]);
  });

  testWidgets('other builds don\'t offer dev accounts', (tester) async {
    await pumpLogin(tester, offerDevUsers: false);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Dev accounts'), findsNothing);
    expect(devUsers, isFalse, reason: 'only `make run` defines P4N4_DEV_USERS');
  });
}
