import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/project.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/status_monitor.dart';
import 'package:p4n4_dashboard/core/runtime_config.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/platform/html_view.dart';
import 'package:p4n4_dashboard/widgets/common.dart';
import 'package:p4n4_dashboard/widgets/service_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app.dart';

ServiceDef _def(String id) => stacks.expand((s) => s.services).firstWhere((d) => d.id == id);

Future<AppSettings> _settings([Map<String, Object> prefs = const {}, Map<String, Object> defaults = const {}]) async {
  SharedPreferences.setMockInitialValues({'host': 'pi.lan', ...prefs});
  return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
}

/// Every HTTP catalog entry up, but [down].
ServiceReport _report({Set<String> down = const {}}) => ServiceReport({
  for (final s in stacks)
    for (final d in s.services.where((d) => !d.tcpOnly)) d: !down.contains(d.id),
}, viaApi: true);

final _nodeRed = Uri.parse('http://pi.lan:1880');

/// The stand-in `<iframe>`: each page it was asked to load, and the latest
/// one's load and page callbacks.
class _Frames {
  final loads = <Uri>[];
  ValueChanged<FrameLoad>? onLoad;
  ValueChanged<Uri>? onPage;

  Widget build(Uri uri, String title, ValueChanged<FrameLoad> load, ValueChanged<Uri> page) {
    onPage = page;
    return _Frame(this, uri, load);
  }
}

class _Frame extends StatefulWidget {
  const _Frame(this.frames, this.uri, this.load);

  final _Frames frames;
  final Uri uri;
  final ValueChanged<FrameLoad> load;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  @override
  void initState() {
    super.initState();
    widget.frames.loads.add(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    widget.frames.onLoad = widget.load;
    return const ColoredBox(key: ValueKey('frame'), color: Color(0xFF123456));
  }
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  Uri? uri,
  Health health = Health.unknown,
  bool technical = true,
  bool sameOriginOnly = false,
  EmbedSupport support = EmbedSupport.iframe,
  Uri? page,
  _Frames? frames,
  bool reduceMotion = false,
  Set<String> keepQuery = const {},
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(P4Colors.light),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize / tester.view.devicePixelRatio,
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: ServiceViewer(
            uri: uri ?? _nodeRed,
            title: 'Node-RED',
            health: health,
            technical: technical,
            sameOriginOnly: sameOriginOnly,
            keepQuery: keepQuery,
            onClose: () {},
            slowAfter: const Duration(seconds: 15),
            support: support,
            page: page,
            frameBuilder: (frames ?? _Frames()).build,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('service URLs', () {
    test('a service opens at its port on the host by default', () async {
      final s = await _settings();
      expect(s.serviceUri(_def('node-red')), _nodeRed);
      expect(s.serviceUri(_def('influxdb')), Uri.parse('http://pi.lan:8086'));
    });

    test('p4n4-api and Swagger UI follow the API base URL', () async {
      final s = await _settings();
      expect(s.serviceUri(_def('swagger-ui')), Uri.parse('http://pi.lan:8000/swagger-ui'));
      expect(s.serviceUri(_def('p4n4-api')), Uri.parse('http://pi.lan:8000/health'));
      s.apiBase = 'https://edge.lan/gw/';
      expect(s.serviceUri(_def('swagger-ui')), Uri.parse('https://edge.lan/gw/swagger-ui'));
      expect(s.serviceUri(_def('p4n4-api')), Uri.parse('https://edge.lan/gw/health'));
      expect(s.probeUriOf(s.statusTarget, _def('p4n4-api')), Uri.parse('https://edge.lan/gw/health'));
    });

    test('this device\'s URL wins over the project\'s, which wins over config.json\'s', () async {
      final s = await _settings(const {}, {
        'serviceUrls': {'node-red': 'https://edge.lan/svc/node-red/', 'n8n': 'https://edge.lan/svc/n8n/'},
      });
      expect(s.serviceUri(_def('node-red')), Uri.parse('https://edge.lan/svc/node-red/'));
      s.project = ProjectInfo.fromJson({
        'project': 'demo',
        'dashboard': {
          'services': {'node-red': 'http://flows.lan:1880/', 'bogus': 3},
        },
      });
      expect(s.serviceUri(_def('node-red')), Uri.parse('http://flows.lan:1880/'));
      // The project names Node-RED only: n8n keeps the deployment's.
      expect(s.serviceUri(_def('n8n')), Uri.parse('https://edge.lan/svc/n8n/'));

      await s.setServiceUrl(_def('node-red'), ' http://other.lan:1999/ ');
      expect(s.serviceUri(_def('node-red')), Uri.parse('http://other.lan:1999/'));
      expect(s.serviceUrls, {'node-red': 'http://other.lan:1999/'});
      expect(s.defaultServiceUri(_def('node-red')), Uri.parse('http://flows.lan:1880/'));

      await s.setServiceUrl(_def('node-red'), '');
      expect(s.serviceUrls, isEmpty);
      expect(s.serviceUri(_def('node-red')), Uri.parse('http://flows.lan:1880/'));
    });

    test('a path resolves against the page, and a connection reset forgets the URLs', () async {
      final s = await _settings();
      await s.setServiceUrl(_def('node-red'), '/svc/node-red/');
      expect(s.serviceUri(_def('node-red')), Uri.base.resolve('/svc/node-red/'));
      await s.resetConnection();
      expect(s.serviceUrls, isEmpty);
      expect(s.serviceUri(_def('node-red')), s.url(1880));
    });

    test('status probes a web app where it opens, on the connected deployment only', () async {
      final s = await _settings();
      await s.setServiceUrl(_def('node-red'), 'https://edge.lan/svc/node-red/');
      expect(s.probeUriOf(s.statusTarget, _def('node-red')), Uri.parse('https://edge.lan/svc/node-red/'));
      expect(s.probeUriOf(s.statusTarget, _def('swagger-ui')), Uri.parse('http://pi.lan:8000/swagger-ui'));
      // API-only services, and other deployments, keep the port on their host.
      expect(s.probeUriOf(s.statusTarget, _def('ollama')), isNull);
      expect(s.probeUriOf((api: Uri.parse('http://b.lan:8000/'), host: 'b.lan'), _def('node-red')), isNull);
    });

    test(
      'Grafana opens at its home for admins and power users, at the view\'s page in kiosk mode for normies',
      () async {
        final s = await _settings({'grafanaBase': 'https://edge.lan/grafana/', 'grafanaPath': '/d/x/y'});
        expect(s.serviceUri(_def('grafana')), Uri.parse('https://edge.lan/grafana/'));
        expect(s.serviceUri(_def('grafana'), view: Role.power), Uri.parse('https://edge.lan/grafana/'));
        expect(s.serviceUri(_def('grafana'), view: Role.normie), Uri.parse('https://edge.lan/grafana/d/x/y?kiosk=1'));
      },
    );

    test('config.json service URLs resolve against the page; empty ones are dropped', () {
      final page = Uri.parse('https://edge.lan/dash/');
      final out = runtimeDefaults({
        'serviceUrls': {'node-red': '/svc/node-red/', 'n8n': '', 'influxdb': 'http://db.lan:8086/', 'x': 1},
      }, page);
      expect(out['serviceUrls'], {'node-red': 'https://edge.lan/svc/node-red/', 'influxdb': 'http://db.lan:8086/'});
      expect(
        runtimeDefaults({
          'serviceUrls': {'node-red': '', 'n8n': ''},
        }, page).containsKey('serviceUrls'),
        isFalse,
      );
    });

    test('an HTTPS page blocks plain-HTTP addresses, except on the device itself', () {
      final https = Uri.parse('https://edge.lan/');
      expect(blockedAsMixedContent(Uri.parse('http://edge.lan:8086/'), https), isTrue);
      expect(blockedAsMixedContent(Uri.parse('https://edge.lan:8086/'), https), isFalse);
      expect(blockedAsMixedContent(Uri.parse('http://edge.lan:8086/'), Uri.parse('http://edge.lan/')), isFalse);
      for (final local in [
        'http://localhost:1880/',
        'http://127.0.0.1:1880/',
        'http://[::1]:1880/',
        'http://pi.localhost/',
      ]) {
        expect(blockedAsMixedContent(Uri.parse(local), https), isFalse, reason: local);
      }
    });

    test('only web apps embed; n8n only from the same origin', () {
      final embed = {for (final s in stacks) ...s.services.where((d) => d.embed).map((d) => d.id)};
      expect(embed, {'grafana', 'node-red', 'influxdb', 'n8n', 'swagger-ui'});
      expect(_def('n8n').sameOriginOnly, isTrue);
      expect(_def('ollama').embed || _def('mqtt').embed || _def('p4n4-api').embed || _def('ei-runner').embed, isFalse);
    });
  });

  group('ServiceViewer', () {
    testWidgets('loads the page, with a bar until it has', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, frames: frames);
      expect(frames.loads, [_nodeRed]);
      expect(find.byKey(const ValueKey('frame')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Back to services'), findsOneWidget);
      expect(find.byTooltip('Reload'), findsOneWidget);
      expect(find.byTooltip('Open in browser'), findsOneWidget);

      frames.onLoad!(FrameLoad.shown);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Blank?'), findsNothing);

      await tester.tap(find.byTooltip('Reload'));
      await tester.pump();
      expect(frames.loads, [_nodeRed, _nodeRed]);
    });

    testWidgets('says it\'s loading instead of moving a bar with reduce motion', (tester) async {
      await _pumpViewer(tester, reduceMotion: true);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Loading Node-RED…'), findsOneWidget);
    });

    testWidgets('a service that is down says so instead of an empty frame, and loads once it is back', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, health: Health.down, frames: frames);
      expect(find.text('Node-RED is down'), findsOneWidget);
      expect(find.byKey(const ValueKey('frame')), findsNothing);
      expect(frames.loads, isEmpty);

      await _pumpViewer(tester, health: Health.up, frames: frames);
      expect(find.text('Node-RED is down'), findsNothing);
      expect(frames.loads, [_nodeRed]);
    });

    testWidgets('a page that never loads suggests framing is blocked', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, frames: frames);
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('Node-RED is taking a while'), findsOneWidget);
      expect(find.textContaining('may not allow being shown'), findsOneWidget);
      expect(find.text('Open Node-RED'), findsOneWidget);
      // The page stays underneath: it may still turn up.
      expect(find.byKey(const ValueKey('frame')), findsOneWidget);

      await tester.tap(find.text('Keep waiting'));
      await tester.pump();
      expect(find.text('Node-RED is taking a while'), findsNothing);

      await _pumpViewer(tester, frames: frames);
      await tester.pump(const Duration(seconds: 16));
      frames.onLoad!(FrameLoad.shown);
      await tester.pump();
      expect(find.text('Node-RED is taking a while'), findsNothing);
    });

    testWidgets('a same-origin page the browser refused to frame is reported', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, frames: frames);
      frames.onLoad!(FrameLoad.blocked);
      await tester.pump();
      expect(find.text('Can\'t show Node-RED here'), findsOneWidget);
      expect(find.textContaining('dashboard\'s proxy'), findsOneWidget);
      expect(find.byKey(const ValueKey('frame')), findsNothing);
      expect(find.text('Try again'), findsOneWidget, reason: 'its headers may have changed since');
    });

    testWidgets('another origin\'s page gets a "blank?" hint that can be dismissed', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, uri: Uri.parse('http://hint.lan:1880/'), frames: frames);
      frames.onLoad!(FrameLoad.opaque);
      await tester.pump();
      expect(find.textContaining('Blank?'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(find.textContaining('Blank?'), findsNothing);
      expect(find.byKey(const ValueKey('frame')), findsOneWidget);
    });

    testWidgets('a page that loses a kept query parameter is loaded again, once per page', (tester) async {
      final frames = _Frames();
      final home = Uri.parse('https://edge.lan/grafana/d/x?kiosk=1&theme=light');
      await _pumpViewer(tester, uri: home, keepQuery: {'theme'}, frames: frames);
      Future<void> lands(String at) async {
        frames.onLoad!(FrameLoad.shown);
        frames.onPage!(Uri.parse(at));
        await tester.pump();
      }

      // Signed out: Grafana redirects to its login without the theme. Loading
      // the page again lands there too, so it stays.
      await lands('https://edge.lan/grafana/login');
      expect(frames.loads, [home, home]);
      await lands('https://edge.lan/grafana/login');
      expect(frames.loads, [home, home]);
      // Signed in, it lands on its home without the theme: back to the page.
      await lands('https://edge.lan/grafana/');
      expect(frames.loads, [home, home, home]);
      await lands(home.toString());
      expect(frames.loads, hasLength(3));
      // Another page with the theme is the user's to keep.
      await lands('https://edge.lan/grafana/d/other?theme=light');
      expect(frames.loads, hasLength(3));
    });

    testWidgets('a same-origin-only service isn\'t tried from another origin', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, uri: Uri.parse('http://pi.lan:5678/'), sameOriginOnly: true, frames: frames);
      expect(frames.loads, isEmpty);
      expect(find.text('Can\'t show Node-RED here'), findsOneWidget);
      expect(find.byTooltip('Reload'), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a plain-HTTP page isn\'t tried from an HTTPS dashboard', (tester) async {
      final frames = _Frames();
      final https = Uri.parse('https://edge.lan/');
      await _pumpViewer(tester, uri: Uri.parse('http://edge.lan:8086/'), page: https, frames: frames);
      expect(frames.loads, isEmpty);
      expect(find.text('Can\'t show Node-RED here'), findsOneWidget);
      expect(find.textContaining('only on plain HTTP'), findsOneWidget);
      expect(find.text('Try again'), findsNothing, reason: 'it would change nothing');
      // Normies get the plain wording; the device itself is exempt.
      await _pumpViewer(tester, uri: Uri.parse('http://edge.lan:8086/'), page: https, technical: false);
      expect(find.textContaining('HTTP'), findsNothing);
      await _pumpViewer(tester, uri: Uri.parse('http://localhost:8086/'), page: https, frames: frames);
      expect(frames.loads, [Uri.parse('http://localhost:8086/')]);
    });

    testWidgets('Windows and Linux offer the browser instead', (tester) async {
      await _pumpViewer(tester, support: EmbedSupport.none);
      expect(find.textContaining('Embedded view not available'), findsOneWidget);
      expect(find.textContaining('Node-RED opens in your default browser'), findsOneWidget);
      expect(find.text('Open Node-RED'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('fits a phone in Spanish at the largest text size, in every state', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final largest = AppSettings.textScaleRange.$2;
      final es = const Locale('es');
      final uri = Uri.parse('https://un-nombre-de-host-bastante-largo.example.com/svc/node-red/');
      for (final health in [Health.unknown, Health.down]) {
        await tester.pumpWidget(const SizedBox());
        await _pumpViewer(tester, uri: uri, health: health, locale: es, textScale: largest);
        expect(tester.takeException(), isNull, reason: '$health');
      }
      await tester.pumpWidget(const SizedBox());
      final frames = _Frames();
      await _pumpViewer(tester, uri: uri, frames: frames, locale: es, textScale: largest);
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('Seguir esperando'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'slow');
      for (final load in [FrameLoad.opaque, FrameLoad.blocked]) {
        frames.onLoad!(load);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$load');
      }
      await _pumpViewer(tester, uri: uri, support: EmbedSupport.none, locale: es, textScale: largest);
      expect(tester.takeException(), isNull, reason: 'unsupported');
    });

    testWidgets('normies see no URL, in the toolbar or in errors', (tester) async {
      final frames = _Frames();
      await _pumpViewer(tester, technical: false, frames: frames);
      expect(find.textContaining('pi.lan'), findsNothing);
      frames.onLoad!(FrameLoad.blocked);
      await tester.pump();
      expect(find.text('Node-RED can\'t be shown inside the app. Open it in your browser instead.'), findsOneWidget);
      expect(find.textContaining('pi.lan'), findsNothing);
      expect(find.textContaining('proxy'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await _pumpViewer(tester, technical: true, frames: _Frames());
      expect(find.text('$_nodeRed'), findsOneWidget);
    });
  });

  group('Services tab', () {
    Future<void> openServices(
      WidgetTester tester, {
      Size size = const Size(1280, 800),
      Role role = Role.admin,
      ServiceReport? report,
    }) async {
      await pumpApp(
        tester,
        size: size,
        role: role,
        prefs: {'host': 'pi.lan', if (role == Role.normie) 'normieTabs': 'services'},
        status: StatusMonitor(check: (_) async => report ?? _report(down: {'influxdb'})),
      );
      await tester.tap(nav('Services'));
      await settle(tester);
    }

    testWidgets('on a wide screen a web app opens in place of the cards, and back returns', (tester) async {
      await openServices(tester);
      await tester.tap(find.text('Node-RED'));
      await settle(tester);
      // No web view in tests: the viewer offers the browser.
      expect(find.byType(ServiceViewer), findsOneWidget);
      expect(find.text('$_nodeRed'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      await tester.tap(find.byTooltip('Back to services'));
      await settle(tester);
      expect(find.byType(ServiceViewer), findsNothing);
      expect(find.text('InfluxDB'), findsOneWidget);
    });

    testWidgets('says whether p4n4-api is out of reach or only has no status', (tester) async {
      await openServices(tester, report: const ServiceReport({}, viaApi: false));
      expect(find.textContaining("Can't reach p4n4-api"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await openServices(tester, report: const ServiceReport({}, viaApi: false, apiProblem: 'Docker access is off.'));
      expect(find.textContaining('p4n4-api has no service status (Docker access is off)'), findsOneWidget);
      expect(find.textContaining("Can't reach"), findsNothing);
    });

    testWidgets('a service that is down opens to say so', (tester) async {
      await openServices(tester);
      await tester.tap(find.text('InfluxDB'));
      await settle(tester);
      expect(find.text('InfluxDB is down'), findsOneWidget);
    });

    testWidgets('on a phone it opens on a page of its own', (tester) async {
      // Normies here: an admin's Services tab is in the app bar's overflow on a phone.
      await openServices(tester, size: const Size(390, 844), role: Role.normie);
      await tester.tap(find.text('Node-RED'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceViewer), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.byTooltip('Back to services'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceViewer), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('API-only services stay in the browser', (tester) async {
      await openServices(tester);
      await tester.tap(find.text('Ollama'));
      await settle(tester);
      expect(find.byType(ServiceViewer), findsNothing);
    });

    testWidgets('normies get the viewer without the URL', (tester) async {
      await openServices(tester, role: Role.normie);
      expect(find.text('Swagger UI'), findsNothing);
      await tester.tap(find.text('Node-RED'));
      await settle(tester);
      expect(find.byType(ServiceViewer), findsOneWidget);
      expect(find.textContaining('pi.lan'), findsNothing);
    });
  });
}
