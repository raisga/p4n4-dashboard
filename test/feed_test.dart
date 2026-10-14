import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/feed.dart';
import 'package:p4n4_dashboard/api/project.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/tabs/feed_tab.dart';
import 'package:p4n4_dashboard/widgets/rich_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

Map<String, Object?> _feed({bool canAct = true, String status = 'pending_review'}) => {
  'title': 'Live activity',
  'items': [
    {
      'id': 'ALT-20261003-000001',
      'time': '2026-10-03T18:15:00-05:00',
      'kind': 'alert',
      'title': 'Fitting room assistance',
      'subtitle': 'Tries it on · Fitting rooms',
      'detail': 'Assist at the fitting room: offer another size.',
      'badge': 'A3',
      'tone': 'info',
      'status': status,
      if (canAct)
        'actions': [
          {'id': 'attended', 'label': 'Attend'},
          {'id': 'dismissed', 'label': 'Dismiss'},
        ],
      'meta': {'camera_id': 'boutique-cam-04', 'zone_id': 'b-fitting'},
      'synthetic': true,
    },
    {'id': 'EVT-20261003-000007', 'time': '2026-10-03T18:14:00-05:00', 'kind': 'event', 'title': 'Takes garment'},
  ],
  'counts': {'pending': status == 'pending_review' ? 1 : 0},
  'next_before': null,
  'can_act': canAct,
};

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('brand.json', () {
    Map<String, dynamic> base() => (jsonDecode(jsonEncode(_brandJson)) as Map).cast();

    test('the feed tab is opt-in: a brand without a tab list keeps the five', () {
      final brand = Brand.fromJson(base()..remove('tabs'));
      expect(brand.tabs, DashTab.defaults);
      expect(brand.tabs, isNot(contains(DashTab.feed)));
      expect(Brand.fromJson(base()..['tabs'] = ['agent', 'feed']).tabs, [DashTab.agent, DashTab.feed]);
    });

    test('assistant suggestions per language, or one list for all', () {
      final perLanguage = Brand.fromJson(
        base()
          ..['assistant'] = {
            'suggestions': {
              'es': ['¿Qué pasó ayer?'],
              'en': ['What happened yesterday?'],
            },
          },
      );
      expect(perLanguage.suggestionsFor('es'), ['¿Qué pasó ayer?']);
      expect(perLanguage.suggestionsFor('fr'), isNull);
      final all = Brand.fromJson(
        base()
          ..['assistant'] = {
            'suggestions': ['Status?'],
          },
      );
      expect(all.suggestionsFor('fr'), ['Status?']);
      expect(Brand.fromJson(base()).suggestionsFor('en'), isNull);
    });

    test('empty or malformed suggestions are refused', () {
      for (final bad in [
        <String>[],
        [''],
        {'es': <String>[]},
        'ask me',
      ]) {
        expect(
          () => Brand.fromJson(base()..['assistant'] = {'suggestions': bad}),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('views', () {
    test('the feed joins the tab order only where the project serves one', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load(defaults: const {}, secrets: MemorySecretStore());
      expect(settings.tabOrder, DashTab.defaults);
      expect(settings.tabsFor(Role.power), isNot(contains(DashTab.feed)));
      settings.project = ProjectInfo.fromJson({
        'name': 'demo-site',
        'layers': ['iot'],
        'dashboard': {
          'tabs': ['agent', 'grafana', 'feed'],
        },
      });
      expect(settings.tabOrder.last, DashTab.feed);
      expect(settings.tabsFor(Role.admin), contains(DashTab.feed));
      expect(settings.projectAllows(DashTab.feed), isTrue);
    });
  });

  group('FeedApi', () {
    final api = FeedApi(Uri.parse('http://pi:8000/'));

    test('reads a page', () async {
      Uri? asked;
      final page = await http.runWithClient(
        () => api.page(limit: 20, before: 1791074857.9),
        () => MockClient((r) async {
          asked = r.url;
          return _json(_feed());
        }),
      );
      expect(asked!.path, '/api/v1/feed');
      expect(asked!.queryParameters, {'limit': '20', 'before': '1791074857.9'});
      expect(page.items, hasLength(2));
      expect(page.pending, 1);
      expect(page.canAct, isTrue);
      final alert = page.items.first;
      expect((alert.alert, alert.pending, alert.badge, alert.tone), (true, true, 'A3', FeedTone.info));
      expect(alert.actions.map((a) => a.id), ['attended', 'dismissed']);
      expect(alert.meta, {'camera_id': 'boutique-cam-04', 'zone_id': 'b-fitting'});
      expect(page.items.last.alert, isFalse);
    });

    test('acts with the action as the body', () async {
      late http.Request sent;
      await http.runWithClient(
        () => api.act('ALT-V-0f5d', 'attended'),
        () => MockClient((r) async {
          sent = r;
          return _json({'action': 'attended', 'item': {}});
        }),
      );
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/v1/feed/ALT-V-0f5d/action');
      expect(jsonDecode(sent.body), {'action': 'attended'});
    });

    test('a project without a feed says so', () async {
      final error = await http.runWithClient(
        () => api.page().then<Object?>((_) => null, onError: (Object e) => e),
        () => MockClient(
          (_) async => _json({
            'error': {'code': 'no_feed', 'message': 'This project has no feed.'},
          }, 404),
        ),
      );
      expect(error, isA<FeedException>().having((e) => e.notConfigured, 'notConfigured', isTrue));
    });
  });

  group('FeedTab', () {
    Future<List<http.Request>> pump(
      WidgetTester tester,
      Role role,
      Future<http.Response> Function(http.Request) handler,
    ) async {
      final requests = <http.Request>[];
      SharedPreferences.setMockInitialValues({'tourSeen': true, 'role': role.name, 'locale': 'en'});
      final brand = loadBrand('p4n4');
      final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
      final session = await Session.load(settings, probe: (_) async => AuthMode.off);
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await http.runWithClient(
        () async {
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
                    locale: const Locale('en'),
                    home: const Scaffold(body: FeedTab(active: false)),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        },
        () => MockClient((r) async {
          requests.add(r);
          return handler(r);
        }),
      );
      return requests;
    }

    testWidgets('operators see the items, the pending count and the actions', (tester) async {
      var attended = false;
      final requests = await pump(tester, Role.power, (r) async {
        if (r.method == 'POST') {
          attended = true;
          return _json({'action': 'attended', 'item': {}});
        }
        return _json(_feed(status: attended ? 'attended' : 'pending_review'));
      });
      expect(find.text('Live activity'), findsOneWidget);
      expect(find.text('1 to review'), findsOneWidget);
      expect(find.text('Fitting room assistance'), findsOneWidget);
      expect(find.text('Assist at the fitting room: offer another size.'), findsOneWidget);
      expect(find.text('Demo data'), findsOneWidget);
      expect(find.text('Takes garment'), findsOneWidget);

      await http.runWithClient(
        () async {
          await tester.tap(find.text('Attend'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        },
        () => MockClient((r) async {
          requests.add(r);
          if (r.method == 'POST') {
            attended = true;
            return _json({'action': 'attended', 'item': {}});
          }
          return _json(_feed(status: attended ? 'attended' : 'pending_review'));
        }),
      );
      expect(requests.where((r) => r.method == 'POST').single.url.path, '/api/v1/feed/ALT-20261003-000001/action');
      expect(find.text('Attended'), findsOneWidget);
      expect(find.text('1 to review'), findsNothing);
    });

    testWidgets('the filter narrows to alerts', (tester) async {
      await pump(tester, Role.power, (_) async => _json(_feed()));
      await tester.tap(find.text('Alerts'));
      await tester.pump();
      expect(find.text('Fitting room assistance'), findsOneWidget);
      expect(find.text('Takes garment'), findsNothing);
    });

    testWidgets('viewers read without actions', (tester) async {
      await pump(tester, Role.normie, (_) async => _json(_feed(canAct: false)));
      expect(find.text('Fitting room assistance'), findsOneWidget);
      expect(find.text('Attend'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('a project without a feed says how to add one, to technical users', (tester) async {
      await pump(
        tester,
        Role.power,
        (_) async => _json({
          'error': {'code': 'no_feed', 'message': 'No feed.'},
        }, 404),
      );
      expect(find.text('No activity feed'), findsOneWidget);
      expect(find.textContaining('dashboard.feed'), findsOneWidget);
    });
  });

  group('RichMessage', () {
    testWidgets('links, bold and bullets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(P4Colors.dark),
          home: const Scaffold(
            body: RichMessage(
              '**Top:** snacks\n- see [the clip](http://localhost:8095/clip/ds-merl-014-0031)\n- or http://x.example/a.',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      );
      final text = tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!.toPlainText();
      expect(text, 'Top: snacks\n• see the clip\n• or http://x.example/a.');
      final spans = <TextSpan>[];
      tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!.visitChildren((s) {
        if (s is TextSpan && s.recognizer != null) spans.add(s);
        return true;
      });
      expect(spans.map((s) => s.text), ['the clip', 'http://x.example/a']);
    });
  });
}

/// A minimal valid brand.json.
const _brandJson = {
  'id': 'test',
  'appName': 'Test',
  'wordmark': {'text': 'test'},
  'tabs': ['services', 'edge', 'agent', 'grafana', 'video'],
};
