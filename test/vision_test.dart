import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/feed.dart';
import 'package:p4n4_dashboard/api/vision.dart';
import 'package:p4n4_dashboard/api/vision_live.dart';
import 'package:p4n4_dashboard/api/vision_recorded.dart';
import 'package:p4n4_dashboard/core/alerts.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/tabs/video_tab.dart' show alertCamera;
import 'package:p4n4_dashboard/widgets/alert_toasts.dart';
import 'package:p4n4_dashboard/widgets/vision_overlay.dart';

/// A boutique's overlay, as a project's vision file holds it.
Map<String, Object?> _bundleJson() => {
  'version': 1,
  'behaviors': {
    'takes_garment': {'es': 'Toma prenda', 'en': 'Takes garment', 'fr': 'Prend un article'},
    'loss_risk_review': {'es': 'Riesgo de pérdida — revisar', 'en': 'Loss risk — review'},
  },
  'zones': {
    'b-racks-new': {'es': 'Perchas de temporada', 'en': 'New-season racks'},
    'b-racks-premium': {'es': 'Perchas de alta gama', 'en': 'Premium racks'},
  },
  'alerts': [
    {
      'code': 'A4',
      'tone': 'review',
      'behaviors': ['loss_risk_review'],
      'title': {'es': 'Riesgo de pérdida — revisar', 'en': 'Loss risk — review'},
      'suggestion': {'en': 'Approach politely and offer help.'},
    },
    {
      'code': 'A2',
      'tone': 'info',
      'behaviors': ['takes_garment'],
      'zones': ['b-racks-premium'],
      'title': {'en': 'High-value opportunity'},
    },
  ],
  'objects': [
    {
      'id': 'outerwear',
      'label': {'es': 'Chaquetas y abrigos', 'en': 'Jackets and coats'},
    },
    {
      'id': 'accessories',
      'label': {'es': 'Accesorios y bolsos', 'en': 'Accessories and bags'},
    },
    {'no': 'id'},
  ],
  'cameras': {
    'cam-01': {
      'zones': ['b-racks-new'],
      'recording': {
        'duration': 10.0,
        'width': 480,
        'height': 270,
        'boxes': [
          [
            0.0,
            [
              [1, 0.1, 0.2, 0.3, 0.6, 0.9],
            ],
          ],
          [
            0.2,
            [
              [1, 0.2, 0.2, 0.4, 0.6, 0.8],
            ],
          ],
          [0.4, []],
          [2.0, []],
          [
            9.8,
            [
              [7, 0.5, 0.5, 0.6, 0.9, 0.7],
            ],
          ],
        ],
        'behaviors': [
          [0.0, 1.5, 1, 'takes_garment', 1.0],
          [4.0, 5.0, 1, 'loss_risk_review', 0.9],
        ],
        'objects': [
          [
            0.0,
            [
              [0, 0.5, 0.1, 0.7, 0.3, 0.6],
              [1, 0.1, 0.6, 0.2, 0.8, 0.4],
            ],
          ],
          [
            0.2,
            [
              [0, 0.6, 0.1, 0.8, 0.3, 0.7],
            ],
          ],
          [1.0, []],
        ],
      },
    },
    'cam-03': {
      'zones': ['b-racks-premium'],
    },
    'broken': 'not a camera',
  },
};

VisionBundle _bundle() => VisionBundle.fromJson(jsonDecode(jsonEncode(_bundleJson())) as Map<String, dynamic>);

Widget _app(Widget child, {Size size = const Size(800, 450)}) => MaterialApp(
  theme: buildTheme(P4Colors.dark),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox.fromSize(size: size, child: child),
    ),
  ),
);

void main() {
  group('VisionBundle', () {
    test('parses labels, rules and cameras, skipping what it cannot read', () {
      final b = _bundle();
      expect(b.cameras.keys, ['cam-01', 'cam-03']);
      expect(b.cameras['cam-01']!.recording!.frame, const Size(480, 270));
      expect(b.alerts.map((r) => r.code), ['A4', 'A2']);
      expect(b.live, isNull);
    });

    test('a brand\'s demo camera finds the vision of the camera it plays', () {
      final b = _bundle();
      expect(b.camera('cam-01'), same(b.cameras['cam-01']));
      expect(b.camera('demo-cam-01'), same(b.cameras['cam-01']));
      expect(b.camera('demo-cam-02'), isNull);
      expect(b.camera('cam-02'), isNull);
    });

    test('object kinds, named in the dashboard language', () {
      final b = _bundle();
      expect(b.objects.map((o) => o.id), ['outerwear', 'accessories']);
      expect(b.objectLabel(0, 'es'), 'Chaquetas y abrigos');
      expect(b.objectLabel(1, 'fr'), 'Accessories and bags');
      expect(b.objectLabel(9, 'en'), '#9');
    });

    test('labels in the dashboard language, else English, else Spanish', () {
      final b = _bundle();
      expect(b.behaviorLabel('takes_garment', 'es'), 'Toma prenda');
      expect(b.behaviorLabel('takes_garment', 'fr_CA'), 'Prend un article');
      expect(b.behaviorLabel('loss_risk_review', 'fr'), 'Loss risk — review');
      expect(b.behaviorLabel('tries_on', 'en'), 'tries on');
      expect(b.zoneLabel('b-racks-new', 'de'), 'New-season racks');
      expect(b.zoneLabel(null, 'en'), isNull);
    });

    test('an alert rule with zones fits only those zones', () {
      final b = _bundle();
      expect(b.alertFor('loss_risk_review', const [])?.code, 'A4');
      expect(b.alertFor('takes_garment', const ['b-racks-new']), isNull);
      expect(b.alertFor('takes_garment', const ['b-racks-new', 'b-racks-premium'])?.code, 'A2');
      expect(b.alertFor('browsing', const ['b-racks-premium']), isNull);
    });

    test('the live stream resolves against the connected host', () {
      expect(const VisionLive(port: 8000, path: '/stream').on('10.0.0.5'), Uri.parse('ws://10.0.0.5:8000/stream'));
      expect(const VisionLive(url: 'wss://edge.example/stream').on('x'), Uri.parse('wss://edge.example/stream'));
      expect(const VisionLive(url: 'http://edge.example/stream').on('x'), isNull);
      expect(const VisionLive().on('x'), isNull);
    });
  });

  group('VisionRecording', () {
    final rec = _bundle().cameras['cam-01']!.recording!;

    test('a box walks between samples instead of jumping', () {
      final at = rec.sceneAt(0.1).boxes.single;
      expect(at.track, 1);
      expect(at.rect.left, closeTo(0.15, 1e-9));
      expect(at.rect.right, closeTo(0.35, 1e-9));
    });

    test('a person the detector loses briefly is held, then let go', () {
      // 0.4 has no one: the 0.2 box is held for the coast…
      expect(rec.sceneAt(0.5).boxes.single.rect, const Rect.fromLTRB(0.2, 0.2, 0.4, 0.6));
      // …and gone after it.
      expect(rec.sceneAt(0.7).boxes, isEmpty);
    });

    test('a person may belong to a kind (e.g. a team), kept while the box walks', () {
      final teams = VisionRecording.fromJson({
        'duration': 2.0,
        'boxes': [
          [
            0.0,
            [
              [4, 0.1, 0.1, 0.2, 0.5, 0.8, 1],
              [5, 0.5, 0.1, 0.6, 0.5, 0.7],
            ],
          ],
          [
            0.5,
            [
              [4, 0.2, 0.1, 0.3, 0.5, 0.8, 1],
              [5, 0.5, 0.1, 0.6, 0.5, 0.7],
            ],
          ],
        ],
      });
      final boxes = teams.sceneAt(0.25).boxes;
      expect(boxes.map((b) => b.kind), [1, null]);
      expect(boxes.first.rect.left, closeTo(0.15, 1e-9));
    });

    test('no interpolation across the loop seam', () {
      expect(rec.sceneAt(9.9).boxes.single.track, 7);
      expect(rec.sceneAt(9.9).boxes.single.rect, const Rect.fromLTRB(0.5, 0.5, 0.6, 0.9));
    });

    test('an object walks towards its match, one without a match is held, then let go', () {
      final objects = rec.sceneAt(0.1).objects;
      expect(objects.map((o) => o.kind), [0, 1]);
      expect(objects[0].rect.left, closeTo(0.55, 1e-9));
      expect(objects[1].rect, const Rect.fromLTRB(0.1, 0.6, 0.2, 0.8));
      expect(rec.sceneAt(0.5).objects.single.rect, const Rect.fromLTRB(0.6, 0.1, 0.8, 0.3));
      expect(rec.sceneAt(0.7).objects, isEmpty);
      expect(rec.sceneAt(1.1).objects, isEmpty);
    });

    test('behaviours by the second, a new occurrence on every loop', () {
      expect(rec.sceneAt(1.0).behavior!.behavior, 'takes_garment');
      expect(rec.sceneAt(3.0).behavior, isNull);
      final first = rec.sceneAt(4.5).behavior!, second = rec.sceneAt(14.5).behavior!;
      expect(first.behavior, 'loss_risk_review');
      expect(second.behavior, 'loss_risk_review');
      expect(first.key, isNot(second.key));
      expect(rec.sceneAt(4.9).behavior!.key, first.key);
    });
  });

  group('RecordedVision', () {
    const clip = Camera(id: 'demo-cam-01', name: 'New-season racks', url: 'http://edge/clips/cam-01.mp4');
    var now = DateTime(2026);
    void at(double seconds) => now = DateTime(2026).add(Duration(milliseconds: (seconds * 1000).round()));

    RecordedVision recorded(List<(Camera, VisionBehavior)> seen) {
      now = DateTime(2026);
      final r = RecordedVision(now: () => now, onVerdict: (c, b) => seen.add((c, b)));
      addTearDown(r.dispose);
      return r;
    }

    test('reports each occurrence once, loop after loop, with no video playing', () {
      final seen = <(Camera, VisionBehavior)>[];
      final r = recorded(seen)..follow([clip], _bundle());
      for (final t in [0.0, 0.5, 1.0, 3.0, 4.2, 4.8, 9.0, 10.1, 14.5]) {
        at(t);
        r.tick();
      }
      expect(seen.map((s) => s.$2.behavior), [
        'takes_garment',
        'loss_risk_review',
        'takes_garment',
        'loss_risk_review',
      ]);
      expect(seen.map((s) => s.$1.name).toSet(), {'New-season racks'});
      expect(seen.map((s) => s.$2.key).toSet(), hasLength(4));
    });

    test('a camera keeps its clock while followed; the clip\'s position is by that clock', () {
      final r = recorded([])..follow([clip], _bundle());
      at(12.5);
      expect(r.secondsOf(clip.id), closeTo(2.5, 1e-9));
      // A refetched bundle or a renamed camera doesn't restart it.
      r.follow([const Camera(id: 'demo-cam-01', name: 'Racks', url: 'http://edge/clips/cam-01.mp4')], _bundle());
      expect(r.secondsOf(clip.id), closeTo(2.5, 1e-9));
      // Another clip under the same id does.
      r.follow([const Camera(id: 'demo-cam-01', name: 'Racks', url: 'http://edge/clips/other.mp4')], _bundle());
      expect(r.secondsOf(clip.id), 0);
    });

    test('follows only video files the project measured', () {
      final seen = <(Camera, VisionBehavior)>[];
      final r = recorded(seen)
        ..follow([
          const Camera(id: 'cam-01', name: 'Stream', url: 'http://edge:1984/api/stream.mjpeg?src=cam-01'),
          const Camera(id: 'cam-03', name: 'Premium', url: 'http://edge/clips/cam-03.mp4'),
        ], _bundle());
      r.tick();
      expect(r.secondsOf('cam-01'), isNull);
      expect(r.secondsOf('cam-03'), isNull);
      expect(seen, isEmpty);
      r.follow([clip], null);
      expect(r.secondsOf(clip.id), isNull);
    });
  });

  group('LiveVision', () {
    LiveVision live({void Function(String, VisionBehavior)? onVerdict}) => LiveVision(
      Uri.parse('ws://edge:8000/stream'),
      connect: (_) => Completer<Stream<String>>().future,
      onVerdict: onVerdict,
    );

    test('detections become boxes on their frame, per camera', () {
      final l = live();
      addTearDown(l.dispose);
      l.handle(
        jsonEncode({
          'type': 'detection',
          'camera_id': 'nvr-cam-01',
          'frame_width': 1000,
          'frame_height': 500,
          'objects': [
            {
              'track_id': 3,
              'label': 'person',
              'confidence': 0.8,
              'bbox': [100, 50, 300, 450],
            },
          ],
        }),
      );
      final scene = l.scene('nvr-cam-01').value;
      expect(scene.frame, const Size(1000, 500));
      expect(scene.boxes.single.rect, const Rect.fromLTRB(0.1, 0.1, 0.3, 0.9));
      expect(l.scene('nvr-cam-02').value.isEmpty, isTrue);
    });

    test('boxes without their frame size are not drawn', () {
      final l = live();
      addTearDown(l.dispose);
      l.handle(
        jsonEncode({
          'type': 'detection',
          'camera_id': 'c',
          'objects': [
            {
              'track_id': 1,
              'confidence': 0.9,
              'bbox': [1, 2, 3, 4],
            },
          ],
        }),
      );
      l.handle('not json');
      l.handle(jsonEncode({'type': 'diagnostics'}));
      expect(l.scene('c').value.isEmpty, isTrue);
    });

    test('a verdict shows its behaviour, reports it, and fades', () {
      final verdicts = <(String, String)>[];
      final l = live(onVerdict: (cam, b) => verdicts.add((cam, b.behavior)));
      addTearDown(l.dispose);
      final t0 = DateTime(2026, 10, 14, 18);
      l.handle(
        jsonEncode({
          'type': 'verdict',
          'event_id': 'e-1',
          'camera_id': 'c',
          'track_id': 2,
          'zone': {'id': 'b-racks-premium'},
          'behavior': {'class': 'takes_garment', 'confidence': 0.7},
          'window': {'dwell_ms': 1200},
        }),
        now: t0,
      );
      final b = l.scene('c').value.behavior!;
      expect((b.behavior, b.zone, b.track, b.key), ('takes_garment', 'b-racks-premium', 2, 'e-1'));
      expect(verdicts, [('c', 'takes_garment')]);
      // A later message on the camera, past the verdict's time on screen.
      l.handle(
        jsonEncode({'type': 'detection', 'camera_id': 'c', 'frame_width': 10, 'frame_height': 10, 'objects': []}),
        now: t0.add(LiveVision.verdictFor + const Duration(seconds: 1)),
      );
      expect(l.scene('c').value.behavior, isNull);
    });

    testWidgets('reconnects with backoff when the stream ends', (tester) async {
      {
        var attempts = 0;
        final l = LiveVision(
          Uri.parse('ws://edge/stream'),
          connect: (_) async {
            attempts++;
            if (attempts == 1) return Stream.fromIterable(['{}']);
            throw StateError('down');
          },
        );
        await tester.pump();
        expect(attempts, 1);
        await tester.pump(const Duration(seconds: 1));
        expect(attempts, 2);
        await tester.pump(const Duration(seconds: 1));
        expect(attempts, 2, reason: 'backs off to 2 s');
        await tester.pump(const Duration(seconds: 1));
        expect(attempts, 3);
        l.dispose();
        await tester.pump(const Duration(minutes: 1));
        expect(attempts, 3);
      }
    });
  });

  group('AlertCenter', () {
    testWidgets('the same alert on the same camera once per cooldown; risks chime', (tester) async {
      {
        var chimes = 0;
        var now = DateTime(2026, 10, 14, 18);
        final center = AlertCenter(chime: () async => chimes++, now: () => now, cooldown: const Duration(seconds: 60));
        AlertNotice notice(String id, VisionTone tone) => AlertNotice(id: id, title: 'T', tone: tone);
        expect(center.raise(notice('a', VisionTone.review), key: 'cam|A4'), isTrue);
        expect(center.raise(notice('b', VisionTone.review), key: 'cam|A4'), isFalse);
        expect(center.raise(notice('c', VisionTone.info), key: 'cam|A1'), isTrue);
        expect(center.shown.map((n) => n.id), ['c', 'a']);
        expect(chimes, 1);
        now = now.add(const Duration(seconds: 61));
        expect(center.raise(notice('d', VisionTone.review), key: 'cam|A4'), isTrue);
        expect(chimes, 2);
        // Info goes after 8 s, a risk stays for 20.
        await tester.pump(const Duration(seconds: 9));
        expect(center.shown.map((n) => n.id), ['d', 'a']);
        await tester.pump(const Duration(seconds: 12));
        expect(center.shown, isEmpty);
        center.dispose();
      }
    });

    test('no chime when the sound is off; at most maxShown toasts', () {
      var chimes = 0;
      final center = AlertCenter(chime: () async => chimes++, sound: () => false, maxShown: 2);
      addTearDown(center.dispose);
      for (final id in ['a', 'b', 'c']) {
        center.raise(AlertNotice(id: id, title: id, tone: VisionTone.review));
      }
      expect(chimes, 0);
      expect(center.shown.map((n) => n.id), ['c', 'b']);
    });
  });

  group('FeedAlertWatcher', () {
    Map<String, Object?> item(String id, {String status = 'pending_review', String kind = 'alert'}) => {
      'id': id,
      'kind': kind,
      'title': 'Loss risk — review',
      'subtitle': 'Fitting rooms',
      'badge': 'A4',
      'tone': 'review',
      'status': status,
      'meta': {'camera_id': 'boutique-cam-04'},
    };

    test('toasts only the pending alerts that arrive after it starts', () async {
      var items = [item('old')];
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'items': items}), 200, headers: {'content-type': 'application/json'}),
      );
      final center = AlertCenter(chime: () async {});
      addTearDown(center.dispose);
      await http.runWithClient(() async {
        final watcher = FeedAlertWatcher(
          FeedApi(Uri.parse('http://api/')),
          center,
          interval: const Duration(milliseconds: 20),
        );
        addTearDown(watcher.dispose);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(center.shown, isEmpty);
        items = [item('new'), item('event', kind: 'event'), item('done', status: 'attended'), item('old')];
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }, () => client);
      final n = center.shown.single;
      expect(
        (n.id, n.code, n.camera, n.tone, n.fromFeed),
        ('feed:new', 'A4', 'boutique-cam-04', VisionTone.review, true),
      );
    });
  });

  group('VisionOverlay', () {
    final bundle = _bundle();
    final rec = bundle.cameras['cam-01']!.recording!;

    testWidgets('boxes with track tags, the behaviour and the zone', (tester) async {
      await tester.pumpWidget(
        _app(VisionOverlay(scene: rec.sceneAt(1.0), bundle: bundle, zones: const ['b-racks-new'], detailed: true)),
      );
      expect(find.text('Takes garment'), findsOneWidget);
      expect(find.text('New-season racks'), findsOneWidget);
      expect(find.text('No one in view'), findsOneWidget);
      // takes_garment on the new-season racks asks for nothing.
      expect(find.textContaining('A2'), findsNothing);
      await tester.pumpWidget(
        _app(VisionOverlay(scene: rec.sceneAt(0.1), bundle: bundle, zones: const ['b-racks-new'], detailed: true)),
      );
      expect(find.text('1 person'), findsOneWidget);
      expect(find.text('#1 · 90% · Takes garment'), findsOneWidget);
    });

    testWidgets('objects named by kind, and a key to the colours', (tester) async {
      await tester.pumpWidget(
        _app(VisionOverlay(scene: rec.sceneAt(0.1), bundle: bundle, zones: const ['b-racks-new'], detailed: true)),
      );
      expect(find.text('Jackets and coats 60%'), findsOneWidget);
      expect(find.text('Accessories and bags 40%'), findsOneWidget);
      for (final name in ['Person', 'Jackets and coats', 'Accessories and bags']) {
        expect(find.text(name), findsOneWidget, reason: 'the key names $name');
      }
      // In the grid: the boxes only, no names, no key.
      await tester.pumpWidget(_app(VisionOverlay(scene: rec.sceneAt(0.1), bundle: bundle)));
      expect(find.textContaining('Jackets'), findsNothing);
      expect(find.text('Person'), findsNothing);
      expect(visionObjectColor(0), isNot(visionObjectColor(1)));
    });

    testWidgets('the brand picks the colours and what shows', (tester) async {
      Color tagColor(String text) =>
          tester.widget<Container>(find.ancestor(of: find.text(text), matching: find.byType(Container)).first).color!;
      Widget branded(Map<String, Object?> overlay, {bool detailed = true}) => BrandScope(
        brand: Brand.fromJson({
          'id': 'acme',
          'appName': 'Acme',
          'wordmark': {'text': 'acme'},
          'video': {'overlay': overlay},
        }),
        child: _app(
          VisionOverlay(scene: rec.sceneAt(0.1), bundle: bundle, zones: const ['b-racks-new'], detailed: detailed),
        ),
      );

      await tester.pumpWidget(
        branded({
          'people': '#FFFFFF',
          'objects': {'outerwear': '#123456'},
        }),
      );
      expect(tagColor('#1 · 90% · Takes garment'), const Color(0xFFFFFFFF));
      expect(tagColor('Jackets and coats 60%'), const Color(0xFF123456));
      // A kind the brand leaves out keeps the dashboard's colour.
      expect(tagColor('Accessories and bags 40%'), visionObjectColor(1));

      await tester.pumpWidget(branded({'showKey': false}));
      expect(find.text('Jackets and coats 60%'), findsOneWidget);
      expect(find.text('Person'), findsNothing);

      await tester.pumpWidget(branded({'showTags': false}));
      expect(find.textContaining('#1'), findsNothing);
      expect(find.text('Jackets and coats 60%'), findsNothing);
      expect(find.text('Person'), findsOneWidget);

      await tester.pumpWidget(branded({'showObjects': false}));
      expect(find.text('#1 · 90% · Takes garment'), findsOneWidget);
      expect(find.textContaining('Jackets'), findsNothing);
      expect(find.text('Person'), findsNothing);
    });

    testWidgets('a person of a kind is drawn and named in its colour', (tester) async {
      Color tagColor(String text) =>
          tester.widget<Container>(find.ancestor(of: find.text(text), matching: find.byType(Container)).first).color!;
      const scene = VisionScene(
        boxes: [
          VisionBox(3, Rect.fromLTRB(0.1, 0.1, 0.3, 0.9), 0.8, kind: 0),
          VisionBox(9, Rect.fromLTRB(0.6, 0.1, 0.8, 0.9), 0.7),
        ],
        frame: Size(480, 270),
      );
      await tester.pumpWidget(_app(VisionOverlay(scene: scene, bundle: bundle, detailed: true)));
      expect(tagColor('#3 · Jackets and coats · 80%'), visionObjectColor(0));
      expect(tagColor('#9 · 70%'), hudColor);
      expect(find.text('2 people'), findsOneWidget);
    });

    testWidgets('tags that would cover each other: the more confident shows', (tester) async {
      const at = Rect.fromLTRB(0.4, 0.4, 0.6, 0.6);
      const scene = VisionScene(objects: [VisionObject(1, at, 0.3), VisionObject(0, at, 0.8)], frame: Size(480, 270));
      await tester.pumpWidget(_app(VisionOverlay(scene: scene, bundle: bundle, detailed: true)));
      expect(find.text('Jackets and coats 80%'), findsOneWidget);
      expect(find.text('Accessories and bags 30%'), findsNothing);
      expect(visionObjectColors, isNot(contains(hudColor)));
    });

    testWidgets('an alert flags the camera with its code and name', (tester) async {
      await tester.pumpWidget(
        _app(VisionOverlay(scene: rec.sceneAt(4.5), bundle: bundle, zones: const ['b-racks-new'])),
      );
      expect(find.text('A4 · Loss risk — review'), findsOneWidget);
      expect(find.byIcon(Icons.report_outlined), findsOneWidget);
      // The grid has no room for tags or the count.
      expect(find.textContaining('#'), findsNothing);
      // A behaviour in a zone with a rule for it: an opportunity.
      final premium = VisionScene(
        behavior: const VisionBehavior(track: 1, behavior: 'takes_garment', confidence: 1, zone: 'b-racks-premium'),
      );
      await tester.pumpWidget(_app(VisionOverlay(scene: premium, bundle: bundle)));
      expect(find.text('A2 · High-value opportunity'), findsOneWidget);
      expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);
    });

    test('an opportunity is told apart from a risk when the accent is red too', () {
      expect(visionToneColor(P4Colors.dark, VisionTone.review), P4Colors.dark.err);
      final d = P4Colors.dark;
      final red = P4Colors(
        brightness: d.brightness,
        bg: d.bg,
        bg2: d.bg2,
        bg3: d.bg3,
        accent: const Color(0xFFE21A2C),
        accent2: d.accent2,
        onAccent: d.onAccent,
        amber: d.amber,
        blue: d.blue,
        heading: d.heading,
        text: d.text,
        muted: d.muted,
        border: d.border,
        border2: d.border2,
        ok: d.ok,
        warn: d.warn,
        err: d.err,
      );
      expect(visionToneColor(red, VisionTone.info), red.blue);
      expect(visionToneColor(P4Colors.dark, VisionTone.info), isNot(P4Colors.dark.err));
    });
  });

  group('alertCamera', () {
    const cameras = [
      Camera(id: 'demo-boutique-cam-03', name: 'Premium racks', url: 'http://dash/demo/boutique-cam-03.mp4'),
      Camera(id: 'overlay', name: 'Floor', url: 'http://edge:1984/api/stream.mjpeg?src=overlay'),
    ];

    test('the camera an alert names, or the demo camera playing its clip; else none', () {
      expect(alertCamera('overlay', cameras), 'overlay');
      expect(alertCamera('boutique-cam-03', cameras), 'demo-boutique-cam-03');
      expect(alertCamera('demo-boutique-cam-03', cameras), 'demo-boutique-cam-03');
      // The Jetson's own camera id, which no dashboard camera has: the toast opens the feed.
      expect(alertCamera('cam-salon-01', cameras), isNull);
      expect(alertCamera(null, cameras), isNull);
    });
  });

  group('AlertToasts', () {
    testWidgets('shows alerts, opens one on tap, dismisses another', (tester) async {
      final center = AlertCenter(chime: () async {});
      addTearDown(center.dispose);
      final opened = <String>[];
      await tester.pumpWidget(_app(AlertToasts(center: center, onOpen: (n) => opened.add(n.id))));
      center
        ..raise(
          AlertNotice(
            id: 'a',
            title: 'Loss risk — review',
            code: 'A4',
            tone: VisionTone.review,
            where: 'Racks · Loss risk',
          ),
        )
        ..raise(AlertNotice(id: 'b', title: 'Customer looking', code: 'A1', detail: 'Approach and offer sizes.'));
      await tester.pumpAndSettle();
      expect(find.text('Approach and offer sizes.'), findsOneWidget);
      expect(find.text('Racks · Loss risk'), findsOneWidget);
      await tester.tap(find.text('Approach and offer sizes.'));
      await tester.pumpAndSettle();
      expect(opened, ['b']);
      await tester.tap(find.byTooltip('Dismiss alert'));
      await tester.pumpAndSettle();
      expect(center.shown, isEmpty);
      expect(opened, ['b']);
    });
  });
}
