import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/api/metrics_monitor.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/status_monitor.dart';
import 'package:p4n4_dashboard/core/incidents.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/thresholds.dart';
import 'package:p4n4_dashboard/widgets/common.dart' show Level;
import 'package:shared_preferences/shared_preferences.dart';

final MetricsSource _pi = (uri: Uri.parse('http://pi:8000/api/v1/edge/metrics'), demo: false);
final MetricsSource _jetson = (uri: Uri.parse('http://jetson:8000/api/v1/edge/metrics'), demo: false);

/// Watches on behalf of a test.
final _owner = Object();

/// Every HTTP catalog entry up, but [down].
ServiceReport _report({Set<String> down = const {}, bool viaApi = true, bool unreachable = false}) => ServiceReport({
  for (final s in stacks)
    for (final d in s.services.where((d) => !d.tcpOnly)) d: unreachable ? false : !down.contains(d.name),
}, viaApi: viaApi && !unreachable);

void main() {
  group('MetricsMonitor', () {
    testWidgets('screens watching one source share its fetches and its history', (tester) async {
      var fetches = 0;
      final monitor = MetricsMonitor(
        fetch: (uri) async => EdgeMetrics(cpu: (++fetches).toDouble(), mem: 50),
        clock: () => tester.binding.clock.now(),
      );
      final home = Object(), device = Object();
      monitor.watch(home, [_pi], interval: const Duration(seconds: 30));
      monitor.watch(device, [_pi], interval: const Duration(seconds: 2));
      await tester.pump();
      expect(fetches, 1, reason: 'one fetch for both');
      await tester.pump(const Duration(seconds: 10));
      expect(fetches, 6, reason: 'as often as the most eager watcher');
      expect([for (final s in monitor.of(_pi).history) s.metrics.cpu], [1, 2, 3, 4, 5, 6]);

      monitor.unwatch(device);
      await tester.pump(const Duration(seconds: 10));
      expect(fetches, 6, reason: "Home's 30 s now");
      monitor.dispose();
    });

    testWidgets('a failed fetch keeps the readings so far, and says why', (tester) async {
      var fail = false;
      final monitor = MetricsMonitor(
        fetch: (_) async => fail ? throw Exception('timeout') : const EdgeMetrics(cpu: 10, mem: 20),
        clock: () => tester.binding.clock.now(),
      );
      monitor.watch(_owner, [_pi], interval: const Duration(seconds: 2));
      await tester.pump();
      fail = true;
      await tester.pump(const Duration(seconds: 2));
      final m = monitor.of(_pi);
      expect(m.latest?.cpu, 10);
      expect('${m.error}', contains('timeout'));
      monitor.dispose();
    });

    testWidgets('demo sources are made up, each on its own', (tester) async {
      final monitor = MetricsMonitor(
        fetch: (_) => throw StateError('no network for demo data'),
        clock: () => tester.binding.clock.now(),
      );
      final demo = (uri: _pi.uri, demo: true);
      monitor.watch(_owner, [demo], interval: const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 4));
      expect(monitor.of(demo).history, hasLength(3));
      expect(monitor.of(demo).error, isNull);
      expect(monitor.of(_pi).history, isEmpty, reason: 'the real source is another one');
      monitor.dispose();
    });

    testWidgets('history is capped at the longest chart', (tester) async {
      final monitor = MetricsMonitor(
        fetch: (_) async => const EdgeMetrics(cpu: 1, mem: 1),
        clock: () => tester.binding.clock.now(),
      );
      monitor.watch(_owner, [_pi], interval: const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: MetricsMonitor.maxHistory + 30));
      expect(monitor.of(_pi).history, hasLength(MetricsMonitor.maxHistory));
      monitor.dispose();
    });

    testWidgets('forgets what nobody has watched for a while', (tester) async {
      final monitor = MetricsMonitor(
        fetch: (_) async => const EdgeMetrics(cpu: 1, mem: 1),
        clock: () => tester.binding.clock.now(),
        keep: const Duration(minutes: 10),
      );
      final clients = Object(), home = Object();
      monitor.watch(clients, [_pi, _jetson], interval: const Duration(seconds: 30));
      monitor.watch(home, [_pi], interval: const Duration(seconds: 30));
      await tester.pump();
      monitor.unwatch(clients);
      await tester.pump(const Duration(minutes: 9));
      expect(monitor.of(_jetson).history, isNotEmpty, reason: 'not long enough');
      await tester.pump(const Duration(minutes: 2));
      expect(monitor.of(_jetson).history, isEmpty, reason: 'unwatched for 10 minutes');
      expect(monitor.of(_pi).history, isNotEmpty, reason: 'Home still watches it');
      monitor.dispose();
    });
  });

  testWidgets('StatusMonitor forgets targets nobody has watched for a while', (tester) async {
    final monitor = StatusMonitor(
      check: (_) async => _report(),
      clock: () => tester.binding.clock.now(),
      keep: const Duration(minutes: 10),
    );
    final pi = (api: Uri.parse('http://pi:8000/'), host: 'pi');
    final jetson = (api: Uri.parse('http://jetson:8000/'), host: 'jetson');
    monitor.watch(_owner, [pi, jetson], interval: const Duration(seconds: 30));
    await tester.pump();
    monitor.watch(_owner, [pi], interval: const Duration(seconds: 30));
    await tester.pump(const Duration(minutes: 11));
    expect(monitor.known, [pi]);
    expect(monitor.statusOf(jetson).report, isNull);
    monitor.dispose();
  });

  group('thresholds', () {
    test('levels follow them, and an outage turns critical after its minutes', () {
      const t = Thresholds(temperature: (60, 75), serviceDownMinutes: 10);
      expect(
        [
          for (final c in <double>[59.9, 60, 74, 75]) t.level(Reading.temperature, c),
        ],
        [Level.normal, Level.high, Level.high, Level.critical],
      );
      expect(t.level(Reading.cpu, 80), Level.high, reason: 'the defaults for the rest');
      expect(t.downLevel(const Duration(minutes: 9)), Level.high);
      expect(t.downLevel(const Duration(minutes: 10)), Level.critical);
    });

    test('read from JSON, keeping the defaults for anything odd', () {
      final t = Thresholds.fromJson({
        'cpu': [60, 80],
        'memory': [90, 80], // high above critical
        'disk': 'full',
        'serviceDownMinutes': 2,
      });
      expect(t.cpu, (60.0, 80.0));
      expect(t.memory, const Thresholds().memory);
      expect(t.disk, const Thresholds().disk);
      expect(t.serviceDownMinutes, 2);
      expect(Thresholds.fromJson(t.toJson()), t);
    });

    test('kept per deployment, over the brand default', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load(
        defaults: {
          'thresholds': {
            'temperature': [75, 85],
          },
        },
        secrets: MemorySecretStore(),
      );
      expect(settings.thresholds.temperature, (75.0, 85.0), reason: "the brand's, e.g. for a Jetson");
      expect(settings.ownThresholds, isFalse);
      await settings.setThresholds(settings.thresholds.copyWith(Reading.cpu, (50, 70)));
      expect((settings.thresholds.cpu, settings.thresholds.temperature), ((50.0, 70.0), (75.0, 85.0)));
      final other = Deployment(id: 'other', name: 'Other');
      await settings.saveDeployment(other);
      expect(settings.thresholdsOf(other).cpu, const Thresholds().cpu);
      await settings.setThresholds(null);
      expect(settings.ownThresholds, isFalse);
    });
  });

  group('incidents', () {
    late AppSettings settings;
    late StatusMonitor monitor;
    late IncidentLog log;
    final t0 = DateTime(2026, 10, 17, 14, 2);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = await AppSettings.load(secrets: MemorySecretStore());
      monitor = StatusMonitor(check: (_) async => _report());
      log = IncidentLog(monitor, settings);
    });

    tearDown(() {
      log.dispose();
      monitor.dispose();
    });

    test('a service that stops answering opens one, and coming back ends it', () {
      final d = settings.deployment;
      log.record(d, _report(), t0);
      expect(log.of(d), isEmpty);
      log.record(d, _report(down: {'Node-RED'}), t0);
      log.record(d, _report(down: {'Node-RED'}), t0.add(const Duration(minutes: 3)));
      expect(log.ongoing(d, 'Node-RED')?.start, t0, reason: 'still the same outage');
      log.record(d, _report(), t0.add(const Duration(minutes: 7)));
      final i = log.of(d).single;
      expect((i.service, i.start, i.end), ('Node-RED', t0, t0.add(const Duration(minutes: 7))));
      expect(i.lengthAt(DateTime(2030)), const Duration(minutes: 7));
    });

    test("an unreachable deployment is one outage, and keeps the services' open", () {
      final d = settings.deployment;
      log.record(d, _report(down: {'Grafana'}), t0);
      log.record(d, _report(unreachable: true), t0.add(const Duration(minutes: 1)));
      expect(log.ongoing(d, 'Grafana'), isNotNull, reason: 'nothing says Grafana is back');
      expect(log.ongoing(d, Incident.unreachable), isNotNull);
      log.record(d, _report(), t0.add(const Duration(minutes: 5)));
      expect(log.of(d).where((i) => i.ongoing), isEmpty);
      expect(log.of(d).map((i) => i.service), ['Grafana', Incident.unreachable]);
    });

    test('follows the status checks, and outlives a restart', () async {
      final d = settings.deployment;
      var down = <String>{};
      monitor = StatusMonitor(check: (_) async => _report(down: down));
      log = IncidentLog(monitor, settings);
      down = {'Ollama'};
      await monitor.refresh(settings.statusTarget);
      expect(log.ongoing(d, 'Ollama'), isNotNull);

      final again = IncidentLog(monitor, settings);
      expect(again.ongoing(d, 'Ollama')?.start, log.ongoing(d, 'Ollama')?.start, reason: 'read back from the device');
      again.dispose();

      await log.clear(d);
      expect(IncidentLog(monitor, settings).of(d), isEmpty);
    });

    test('keeps the latest ones, never dropping an ongoing outage', () {
      final d = settings.deployment;
      log.record(d, _report(down: {'n8n'}), t0);
      for (var i = 0; i < IncidentLog.maxPerDeployment + 5; i++) {
        final at = t0.add(Duration(minutes: 2 * i + 1));
        log.record(d, _report(down: {'n8n', 'Letta'}), at);
        log.record(d, _report(down: {'n8n'}), at.add(const Duration(minutes: 1)));
      }
      final all = log.of(d);
      expect(all, hasLength(IncidentLog.maxPerDeployment));
      expect(all.where((i) => i.ongoing).single.service, 'n8n');
      expect(all.last.service, 'Letta');
    });

    test('a removed deployment takes its incidents with it', () async {
      final other = Deployment(id: 'other', name: 'Other', values: {'host': 'other'});
      await settings.saveDeployment(other);
      log.record(other, _report(down: {'Grafana'}), t0);
      await Future<void>.delayed(Duration.zero);
      expect(settings.incidentsOf(other), isNotEmpty);
      await settings.removeDeployment('other');
      expect(settings.incidentsOf(other), isEmpty);
    });
  });
}
