import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/drive/dashcam.dart';
import 'package:p4n4_dashboard/drive/geo.dart';
import 'package:p4n4_dashboard/drive/gps_publisher.dart';
import 'package:p4n4_dashboard/drive/links.dart';
import 'package:p4n4_dashboard/drive/location.dart';
import 'package:p4n4_dashboard/drive/obd_relay.dart';
import 'package:p4n4_dashboard/pages/dashcam_clips_page.dart' show clipSize;
import 'package:p4n4_dashboard/tabs/map_tab.dart';
import 'package:p4n4_dashboard/widgets/dashcam_controls.dart' show dashcamElapsed;
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app.dart';

Future<AppSettings> _settings({Map<String, Object> defaults = const {}}) {
  SharedPreferences.setMockInitialValues({});
  return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
}

/// Lets the services' futures and stream events run.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// One end of an OBD-II link: what the other end sent it, and a way to answer.
class _Link implements ByteLink {
  _Link(this.peer);

  @override
  final String peer;

  final _input = StreamController<Uint8List>();
  final _written = <int>[];
  bool closed = false;

  String get written => latin1.decode(_written);

  void receive(String s) => _input.add(Uint8List.fromList(latin1.encode(s)));

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  Future<void> write(Uint8List data) async => _written.addAll(data);

  @override
  Future<void> close() async {
    closed = true;
    unawaited(_input.close());
  }
}

class _Server implements ByteServer {
  final _clients = StreamController<ByteLink>();
  bool closed = false;

  void connect(ByteLink client) => _clients.add(client);

  @override
  int get port => 35100;

  @override
  Stream<ByteLink> get clients => _clients.stream;

  @override
  Future<void> close() async {
    closed = true;
    unawaited(_clients.close());
  }
}

class _Location extends LocationService {
  final _sent = StreamController<Fix>.broadcast();
  int users = 0;

  void send(Fix fix) => _sent.add(fix);

  @override
  Stream<Fix> get fixes => _sent.stream;

  @override
  void acquire() => users++;

  @override
  void release() => users--;
}

class _Broker implements MqttLink {
  final published = <(String, String)>[];
  final _done = Completer<void>();
  bool closed = false;

  @override
  bool publish(String topic, String payload) {
    published.add((topic, payload));
    return true;
  }

  @override
  Future<void> get done => _done.future;

  @override
  void close() {
    closed = true;
    if (!_done.isCompleted) _done.complete();
  }
}

const _mapBrand = {
  'tabs': ['map', 'grafana', 'video', 'services'],
};

void main() {
  group('GPS', () {
    test('a fix goes to the stack in km/h, rounded, unknowns left out', () {
      final fix = Fix(
        lat: 43.73841234,
        lon: 7.42460987,
        time: DateTime(2026),
        alt: 52.04,
        speed: 13.8889,
        heading: 271.26,
        accuracy: 4.44,
      );
      expect(fix.toPayload(), {
        'lat': 43.738412,
        'lon': 7.42461,
        'alt': 52.0,
        'speed': 50.0,
        'heading': 271.3,
        'acc': 4.4,
      });
      expect(Fix(lat: 1, lon: 2, time: DateTime(2026)).toPayload(), {'lat': 1, 'lon': 2});
    });

    test('distances are great-circle metres', () {
      expect(distanceMetres(0, 0, 1, 0), closeTo(111195, 1));
      expect(distanceMetres(43.7, 7.4, 43.7, 7.4), 0);
    });

    test('the track skips fixes that are too close or too vague, and keeps the latest', () {
      final track = Track(max: 3);
      Fix at(double lat, {double? accuracy}) => Fix(lat: lat, lon: 7.42, time: DateTime(2026), accuracy: accuracy);

      expect(track.add(at(43.7)), isTrue);
      expect(track.toGeoJson()['features'], isEmpty, reason: 'a line needs two points');
      expect(track.add(at(43.70001)), isFalse, reason: 'about a metre on');
      expect(track.add(at(43.701, accuracy: 80)), isFalse, reason: 'too vague');
      expect(track.revision, 1);

      for (final lat in [43.701, 43.702, 43.703]) {
        track.add(at(lat));
      }
      expect(track.fixes.map((f) => f.lat), [43.701, 43.702, 43.703]);
      expect(track.revision, 4);
      expect((track.toGeoJson()['features'] as List).single, {
        'type': 'Feature',
        'properties': <String, Object>{},
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [7.42, 43.701],
            [7.42, 43.702],
            [7.42, 43.703],
          ],
        },
      });

      track.clear();
      expect(track.fixes, isEmpty);
      expect(track.revision, 5);
    });

    test('a clip\'s GPX has each fix, its speed and course, and an escaped name', () {
      final t = DateTime.utc(2026, 5, 1, 12);
      final out = gpx([
        Fix(lat: 43.7384, lon: 7.4246, time: t, alt: 52.04, speed: 13.889, heading: 90),
        Fix(lat: 43.739, lon: 7.425, time: t.add(const Duration(seconds: 1))),
      ], name: 'Monaco <1> & "2"');
      expect(out, contains('<name>Monaco &lt;1&gt; &amp; &quot;2&quot;</name>'));
      expect(
        out,
        contains(
          '<trkpt lat="43.7384000" lon="7.4246000"><ele>52.0</ele><time>2026-05-01T12:00:00.000Z</time>'
          '<extensions><gpxtpx:TrackPointExtension><gpxtpx:speed>13.89</gpxtpx:speed>'
          '<gpxtpx:course>90.0</gpxtpx:course></gpxtpx:TrackPointExtension></extensions></trkpt>',
        ),
      );
      expect(out, contains('<trkpt lat="43.7390000" lon="7.4250000"><time>2026-05-01T12:00:01.000Z</time></trkpt>'));
    });

    test('the publisher sends fixes while on, at most one a second, and lets go when off', () async {
      final s = await _settings(defaults: {'host': '10.0.2.2'});
      s.mqttUser = 'p4n4';
      s.driveDevice = 'civic 1';
      final location = _Location();
      final broker = _Broker();
      final dialled = <String>[];
      final publisher = GpsPublisher(
        s,
        location,
        supported: true,
        connect:
            ({
              required String host,
              required int port,
              required String clientId,
              String user = '',
              String password = '',
              Duration timeout = Duration.zero,
            }) async {
              dialled.add('$user@$host:$port');
              return broker;
            },
      );
      addTearDown(publisher.dispose);
      expect(publisher.status, PublishStatus.off);
      expect(location.users, 0);

      s.gpsPublish = true;
      await _settle();
      expect(publisher.status, PublishStatus.connected);
      expect(dialled, ['p4n4@10.0.2.2:1883']);
      expect(location.users, 1);

      location
        ..send(Fix(lat: 43.7384, lon: 7.4246, time: DateTime.now(), speed: 10))
        ..send(Fix(lat: 43.7385, lon: 7.4247, time: DateTime.now(), speed: 10));
      await _settle();
      expect(broker.published, [('sensors/civic1/gps', '{"lat":43.7384,"lon":7.4246,"speed":36.0}')]);
      expect(publisher.sent, 1);

      s.gpsPublish = false;
      await _settle();
      expect(publisher.status, PublishStatus.off);
      expect(broker.closed, isTrue);
      expect(location.users, 0);
    });

    test('the publisher says why the broker can\'t be reached', () async {
      final s = await _settings();
      final publisher = GpsPublisher(
        s,
        _Location(),
        supported: true,
        connect: ({
          required String host,
          required int port,
          required String clientId,
          String user = '',
          String password = '',
          Duration timeout = Duration.zero,
        }) async => throw Exception('Connection refused'),
      );
      addTearDown(publisher.dispose);
      s.gpsPublish = true;
      await _settle();
      expect(publisher.status, PublishStatus.error);
      expect(publisher.error, contains('Connection refused'));
    });
  });

  group('OBD-II relay', () {
    test('only this phone and its containers may read the adapter', () {
      for (final a in ['127.0.0.1', '::1', '::ffff:127.0.0.1', '172.17.0.2', '172.31.255.254']) {
        expect(relayAllowed(a), isTrue, reason: a);
      }
      for (final a in ['172.32.0.1', '172.15.0.1', '192.168.1.20', '10.0.2.2', 'fe80::1', 'car.local', '']) {
        expect(relayAllowed(a), isFalse, reason: a);
      }
    });

    test('an adapter is a Bluetooth address or host:port', () {
      expect(AdapterAddress.parse(' 00-1d-a5-68-98-8b '), const BluetoothAdapter('00:1D:A5:68:98:8B'));
      expect(AdapterAddress.parse('192.168.0.10:35000'), const TcpAdapter('192.168.0.10', 35000));
      expect(AdapterAddress.parse('elm.local:23'), const TcpAdapter('elm.local', 23));
      for (final bad in ['', 'elm.local', 'elm.local:0', 'elm.local:70000', 'elm.local:23/x', 'user@elm:23']) {
        expect(AdapterAddress.parse(bad), isNull, reason: bad);
      }
    });

    Future<({AppSettings settings, ObdRelay relay, _Link adapter, _Server server, List<Object> calls})> start(
      String adapterAddress,
    ) async {
      final s = await _settings();
      s
        ..obdAdapter = adapterAddress
        ..obdRelay = true;
      final adapter = _Link('OBDII'), server = _Server(), calls = <Object>[];
      final relay = ObdRelay(
        s,
        supported: true,
        connectAdapter: (a) async {
          calls.add(a);
          return adapter;
        },
        bind: (port) async {
          calls.add(port);
          return server;
        },
      );
      addTearDown(relay.dispose);
      await _settle();
      return (settings: s, relay: relay, adapter: adapter, server: server, calls: calls);
    }

    test('relays the latest local reader to the adapter and back', () async {
      final (:settings, :relay, :adapter, :server, :calls) = await start('10.0.2.2:35000');
      expect(calls, unorderedEquals([35100, const TcpAdapter('10.0.2.2', 35000)]));
      expect(relay.status, RelayStatus.waiting);
      expect(relay.adapterName, 'OBDII');

      final first = _Link('172.18.0.5');
      server.connect(first);
      await _settle();
      expect(relay.status, RelayStatus.relaying);
      expect(relay.reader, '172.18.0.5');

      first.receive('010C\r');
      await _settle();
      adapter.receive('41 0C 1A F8\r\r>');
      await _settle();
      expect(adapter.written, '010C\r');
      expect(first.written, '41 0C 1A F8\r\r>');
      expect((relay.bytesUp, relay.bytesDown), (5, 14));

      final second = _Link('127.0.0.1');
      server.connect(second);
      await _settle();
      expect(first.closed, isTrue, reason: 'one reader at a time');
      expect(relay.reader, '127.0.0.1');
    });

    test('turns away readers that are not on this phone', () async {
      final (:settings, :relay, :adapter, :server, :calls) = await start('10.0.2.2:35000');
      final stranger = _Link('192.168.1.20');
      server.connect(stranger);
      await _settle();
      expect(stranger.closed, isTrue);
      expect(relay.turnedAway, '192.168.1.20');
      expect(relay.status, RelayStatus.waiting);
    });

    test('waits for an adapter it understands, and stops when turned off', () async {
      final (:settings, :relay, :adapter, :server, :calls) = await start('my car');
      expect(relay.status, RelayStatus.unset);
      expect(calls, isEmpty);

      settings.obdAdapter = '10.0.2.2:35000';
      await _settle();
      expect(relay.status, RelayStatus.waiting);

      settings.obdRelay = false;
      await _settle();
      expect(relay.status, RelayStatus.off);
      expect(server.closed, isTrue);
      expect(adapter.closed, isTrue);
    });

    test('says why the adapter can\'t be reached', () async {
      final s = await _settings();
      s
        ..obdAdapter = '10.0.2.2:35000'
        ..obdRelay = true;
      final relay = ObdRelay(
        s,
        supported: true,
        connectAdapter: (_) async => throw Exception('No route to host'),
        bind: (_) async => _Server(),
      );
      addTearDown(relay.dispose);
      await _settle();
      expect(relay.status, RelayStatus.error);
      expect(relay.error, contains('No route to host'));
    });
  });

  group('dashcam', () {
    test('room is made from the oldest unsaved clips, never the one recording', () {
      final day = DateTime(2026, 5, 1);
      ({String path, int bytes, DateTime modified}) clip(String path, int minute) =>
          (path: path, bytes: 100 << 20, modified: day.add(Duration(minutes: minute)));
      final clips = [clip('c', 6), clip('a', 0), clip('b', 3)];

      expect(clipsToDelete(clips, capBytes: 300 << 20), isEmpty);
      expect(clipsToDelete(clips, capBytes: 250 << 20), ['a']);
      expect(clipsToDelete(clips, capBytes: 150 << 20, keep: 'a'), ['b', 'c']);
      expect(clipsToDelete(clips, capBytes: 1 << 40, freeBytes: 300 << 20, reserveBytes: 500 << 20), [
        'a',
        'b',
      ], reason: 'the phone keeps some room free');
    });

    test('a jolt saves a clip; a bump in the road does not', () {
      final start = DateTime(2026, 5, 1, 12);
      // 50 Hz readings for [ms], of [g] (one spike of it, if [spike]).
      bool feed(ImpactDetector d, Duration at, double g, {bool spike = false, int ms = 300}) {
        var hit = false;
        for (var t = 0; t <= ms; t += 20) {
          final value = !spike || t == 100 ? g * 9.80665 : 0.0;
          hit |= d.add(0, 0, value, start.add(at + Duration(milliseconds: t)));
        }
        return hit;
      }

      final detector = ImpactDetector(thresholdG: 0.5);
      expect(feed(detector, Duration.zero, 3, spike: true), isFalse, reason: 'a pothole');
      expect(feed(detector, const Duration(seconds: 1), 1), isTrue, reason: 'hard braking');
      expect(feed(detector, const Duration(seconds: 10), 1), isFalse, reason: 'one jolt, one clip');
      expect(feed(detector, const Duration(seconds: 45), 1), isTrue);
      expect(feed(ImpactDetector(thresholdG: 0), Duration.zero, 5), isFalse, reason: 'auto-save off');
    });

    test('clips are named for when they began', () {
      final t = DateTime(2026, 5, 1, 7, 8, 9);
      final name = Dashcam.clipName(t);
      expect(name, '20260501-070809');
      expect(DashClip(path: '/files/dashcam/locked/$name.mp4', bytes: 1, modified: t, locked: true).began, t);
      expect(DashClip(path: '/files/dashcam/VID_1.mp4', bytes: 1, modified: t, locked: false).began, isNull);
    });

    test('times and sizes read short', () {
      expect(dashcamElapsed(const Duration(seconds: 5)), '00:05');
      expect(dashcamElapsed(const Duration(minutes: 12, seconds: 34)), '12:34');
      expect(dashcamElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(clipSize(1), '1 MB');
      expect(clipSize(340 << 20), '340 MB');
      expect(clipSize((1.2 * (1 << 30)).round()), '1.2 GB');
    });
  });

  group('map', () {
    final own = Uri.parse('http://10.0.2.2:8088/style.json');
    final online = Uri.parse(AppSettings.defaultMapFallback);
    Future<MapStyle> pick(Future<http.Response> Function() answer) =>
        pickMapStyle(own, online, client: MockClient((_) => answer()), timeout: const Duration(milliseconds: 50));

    test('the deployment\'s own map when it serves one, else the online one', () async {
      expect(await pick(() async => http.Response('{"version":8,"sources":{"osm":{}},"layers":[]}', 200)), (
        style: own,
        source: MapSource.offline,
      ));
      for (final answer in <Future<http.Response> Function()>[
        () async => http.Response('Not found', 404),
        () async => http.Response('{"hello":"world"}', 200),
        () async => http.Response('<html>', 200),
        () async => throw http.ClientException('Connection refused'),
        () => Completer<http.Response>().future,
      ]) {
        expect(await pick(answer), (style: online, source: MapSource.online));
      }
    });

    testWidgets('a brand can add the Map tab; without the phone\'s map it says so', (tester) async {
      await pumpApp(tester, brandExtra: _mapBrand);
      await tester.tap(nav('Map'));
      await settle(tester);
      expect(find.text('No map here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Settings › Drive', () {
    Future<void> open(WidgetTester tester, {String settings = 'Settings', String drive = 'Drive'}) async {
      await tester.tap(find.byTooltip(settings));
      await settle(tester, 5);
      await tester.ensureVisible(find.text(drive));
      await tester.pump();
      await tester.tap(find.text(drive));
      await settle(tester, 5);
    }

    testWidgets('turns on the GPS, the OBD-II relay and sets the dashcam', (tester) async {
      final s = await pumpApp(tester, brandExtra: _mapBrand);
      await open(tester);
      expect(find.text('Map'), findsOneWidget, reason: 'the map styles, for power users');

      await tester.tap(find.text("Send this device's location to the stack"));
      await tester.tap(find.text("Relay the car's OBD-II adapter to the stack"));
      await settle(tester);
      expect((s.gpsPublish, s.obdRelay), (true, true));
      expect(find.text('None chosen'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('dashcamSegment')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('dashcamSegment')));
      await settle(tester);
      await tester.tap(find.text('5 minutes').last);
      await settle(tester);
      expect(s.dashcamSegmentMinutes, 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('only shows when there is something to drive', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester, 5);
      expect(find.text('Drive'), findsNothing);
    });

    for (final (code, settings, drive) in [
      ('es', 'Ajustes', 'Conducción'),
      ('fr', 'Réglages', 'Conduite'),
      ('de', 'Einstellungen', 'Fahren'),
    ]) {
      testWidgets('fits a phone in $code', (tester) async {
        await pumpApp(tester, size: const Size(390, 844), prefs: {'locale': code}, brandExtra: _mapBrand);
        await open(tester, settings: settings, drive: drive);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
