import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/chats.dart';
import 'package:p4n4_dashboard/api/project.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/pages/chats_section.dart';
import 'package:p4n4_dashboard/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

final _api = Uri.parse('http://pi:8000/');

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

const _channel = {
  'id': 'telegram',
  'name': 'Telegram',
  'state': 'mock',
  'mode': 'polling',
  'bot': '@store_bot',
  'url': 'https://t.me/store_bot',
};

Map<String, Object?> _chat(String id, String name, {List<String> muted = const []}) => {
  'id': id,
  'channel': 'telegram',
  'name': name,
  'lang': 'es',
  'linked_at': '2026-10-15T12:00:00+00:00',
  'linked_by': 'root',
  'muted': muted,
};

const _code = {
  'code': 'K7QF3MXP',
  'expires_at': '2099-10-15T12:15:00+00:00',
  'ttl_s': 900,
  'command': '/start K7QF3MXP',
  'links': [
    {'channel': 'telegram', 'url': 'https://t.me/store_bot?start=K7QF3MXP'},
  ],
};

void main() {
  group('ChatsApi', () {
    test('reads the channels and the chats, leaving out what lacks an id', () async {
      final page = await http.runWithClient(
        () => ChatsApi(_api).list(),
        () => MockClient((r) async {
          expect((r.method, r.url.path), ('GET', '/api/v1/chats'));
          return _json({
            'channels': [
              _channel,
              {'name': 'no id'},
            ],
            'chats': [
              _chat('telegram:-1001', 'Piso de ventas', muted: ['A2']),
              {'id': 'no channel'},
            ],
          });
        }),
      );
      expect([for (final c in page.channels) (c.id, c.bot, c.state)], [('telegram', '@store_bot', 'mock')]);
      final chat = page.chats.single;
      expect((chat.id, chat.name, chat.linkedBy), ('telegram:-1001', 'Piso de ventas', 'root'));
      expect(chat.muted, ['A2']);
      expect(chat.linkedAt, DateTime.utc(2026, 10, 15, 12).toLocal());
    });

    test('makes a code with its links, and unlinks by id', () async {
      final sent = <(String, String)>[];
      final code = await http.runWithClient(
        () async {
          final code = await ChatsApi(_api).newCode();
          await ChatsApi(_api).unlink('telegram:-1001');
          return code;
        },
        () => MockClient((r) async {
          sent.add((r.method, r.url.path));
          return r.method == 'POST' ? _json(_code) : _json({'id': 'telegram:-1001', 'unlinked': true});
        }),
      );
      expect((code.code, code.command), ('K7QF3MXP', '/start K7QF3MXP'));
      expect(code.links.single, (channel: 'telegram', url: 'https://t.me/store_bot?start=K7QF3MXP'));
      expect(sent, [('POST', '/api/v1/chats/codes'), ('DELETE', '/api/v1/chats/telegram%3A-1001')]);
    });

    test("refusals carry the API's code and message", () async {
      Future<ChatsException> error(http.Response res) async {
        try {
          await http.runWithClient(() => ChatsApi(_api).list(), () => MockClient((_) async => res));
        } on ChatsException catch (e) {
          return e;
        }
        fail('no error');
      }

      final none = await error(
        _json({
          'error': {'code': 'no_chats', 'message': 'This project has no chats.'},
        }, 404),
      );
      expect((none.statusCode, none.code), (404, 'no_chats'));
      final off = await error(
        _json({
          'error': {'code': 'chats_unavailable', 'message': 'CHANNELS_ADMIN_TOKEN is not set'},
        }, 503),
      );
      expect(off.message, 'CHANNELS_ADMIN_TOKEN is not set');
    });
  });

  test('a project has chats when its manifest names them', () {
    expect(ProjectInfo.fromJson({'project': 'p'}).hasChats, isFalse);
    expect(
      ProjectInfo.fromJson({
        'project': 'p',
        'dashboard': {
          'chats': {'url': 'http://localhost:8096/api/v1/chats'},
        },
      }).hasChats,
      isTrue,
    );
  });

  Future<(AppSettings, Session, Brand)> setUp(Role role) async {
    SharedPreferences.setMockInitialValues({'tourSeen': true, 'role': role.name, 'locale': 'en'});
    final brand = loadBrand('p4n4');
    final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
    final session = await Session.load(settings, probe: (_) async => AuthMode.off);
    return (settings, session, brand);
  }

  Widget app(AppSettings settings, Session session, Brand brand, Widget home) => BrandScope(
    brand: brand,
    child: SettingsScope(
      settings: settings,
      child: SessionScope(
        session: session,
        child: MaterialApp(
          theme: buildTheme(brand.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: home),
        ),
      ),
    ),
  );

  group('ChatsSection', () {
    testWidgets('lists the chats, makes a code, and drops it once its chat links', (tester) async {
      final (settings, session, brand) = await setUp(Role.admin);
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var chats = [
        _chat('telegram:-1001', 'Piso de ventas', muted: ['A2']),
      ];
      final requests = <String>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            app(
              settings,
              session,
              brand,
              const SingleChildScrollView(child: ChatsSection(watchEvery: Duration(seconds: 1))),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Piso de ventas'), findsOneWidget);
          expect(find.textContaining('by root · Muted: A2'), findsOneWidget);
          expect(find.text('Telegram · @store_bot'), findsOneWidget);
          expect(find.textContaining('Mock mode'), findsOneWidget);

          await tester.tap(find.text('Link a chat'));
          await tester.pumpAndSettle();
          expect(find.text('/start K7QF3MXP'), findsOneWidget);
          expect(find.textContaining('send this command to @store_bot'), findsOneWidget);
          expect(find.text('Copy link'), findsOneWidget);
          expect(find.text('Link a chat'), findsNothing);

          // Someone sends the code: the next read has the new chat, and the code goes
          chats = [...chats, _chat('telegram:42', 'Ana')];
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(find.text('Ana'), findsOneWidget);
          expect(find.text('/start K7QF3MXP'), findsNothing);
          expect(find.text('Link a chat'), findsOneWidget);
        },
        () => MockClient((r) async {
          requests.add('${r.method} ${r.url.path}');
          if (r.method == 'POST') return _json(_code);
          return _json({
            'channels': [_channel],
            'chats': chats,
          });
        }),
      );
      expect(requests, ['GET /api/v1/chats', 'POST /api/v1/chats/codes', 'GET /api/v1/chats']);
    });

    testWidgets('unlinks a chat after asking', (tester) async {
      final (settings, session, brand) = await setUp(Role.admin);
      var chats = [_chat('telegram:-1001', 'Piso de ventas')];
      final requests = <String>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(app(settings, session, brand, const ChatsSection()));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Unlink'));
          await tester.pumpAndSettle();
          expect(find.text('Unlink Piso de ventas?'), findsOneWidget);
          chats = [];
          await tester.tap(find.widgetWithText(FilledButton, 'Unlink'));
          await tester.pumpAndSettle();
          expect(find.text('Piso de ventas'), findsNothing);
          expect(find.text('No chats linked yet.'), findsOneWidget);
        },
        () => MockClient((r) async {
          requests.add('${r.method} ${r.url.path}');
          if (r.method == 'DELETE') return _json({'id': 'telegram:-1001', 'unlinked': true});
          return _json({
            'channels': [_channel],
            'chats': chats,
          });
        }),
      );
      expect(requests, ['GET /api/v1/chats', 'DELETE /api/v1/chats/telegram%3A-1001', 'GET /api/v1/chats']);
    });

    testWidgets('says why the chats are unavailable', (tester) async {
      final (settings, session, brand) = await setUp(Role.admin);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(app(settings, session, brand, const ChatsSection()));
          await tester.pumpAndSettle();
        },
        () => MockClient(
          (r) async => _json({
            'error': {'code': 'chats_unavailable', 'message': 'CHANNELS_ADMIN_TOKEN is not set'},
          }, 503),
        ),
      );
      expect(find.text("Couldn't load the chats: CHANNELS_ADMIN_TOKEN is not set"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('Settings', () {
    Future<void> pumpSettings(WidgetTester tester, Role role, {required bool chats}) async {
      final (settings, session, brand) = await setUp(role);
      settings.project = ProjectInfo.fromJson({
        'project': 'p',
        'dashboard': {
          if (chats) 'chats': {'url': 'http://localhost:8096/api/v1/chats'},
        },
      });
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(settings, session, brand, const SettingsPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('admins get Chats when the project has them', (tester) async {
      await pumpSettings(tester, Role.admin, chats: true);
      expect(find.text('Chats'), findsOneWidget);
    });

    testWidgets('not without them, nor for anyone else', (tester) async {
      await pumpSettings(tester, Role.admin, chats: false);
      expect(find.text('Chats'), findsNothing);
      await pumpSettings(tester, Role.power, chats: true);
      expect(find.text('Chats'), findsNothing);
    });
  });
}
