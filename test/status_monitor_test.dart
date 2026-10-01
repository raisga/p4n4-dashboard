import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/services.dart';
import 'package:p4n4_dashboard/api/status_monitor.dart';

final _a = (api: Uri.parse('http://a:8000'), host: 'a');
final _b = (api: Uri.parse('http://b:8000'), host: 'b');
const _report = ServiceReport({}, viaApi: true);

/// A monitor whose checks are counted, and whose clock follows fake time.
({StatusMonitor monitor, Map<StatusTarget, int> calls, void Function(Duration) advance}) _setup({
  Future<ServiceReport> Function(StatusTarget)? check,
}) {
  final calls = <StatusTarget, int>{};
  var now = DateTime(2026);
  final monitor = StatusMonitor(
    clock: () => now,
    check: (t) {
      calls[t] = (calls[t] ?? 0) + 1;
      return check?.call(t) ?? Future.value(_report);
    },
  );
  addTearDown(monitor.dispose);
  return (monitor: monitor, calls: calls, advance: (d) => now = now.add(d));
}

void main() {
  testWidgets('tabs watching the same target share one check', (tester) async {
    final (:monitor, :calls, advance: _) = _setup();
    monitor.watch('home', [_a], interval: const Duration(seconds: 30));
    monitor.watch('services', [_a], interval: const Duration(seconds: 15));
    monitor.watch('clients', [_a, _b], interval: const Duration(seconds: 30));
    await tester.pump();
    expect(calls, {_a: 1, _b: 1});
    expect(monitor.statusOf(_a).report, same(_report));
    monitor.unwatch('home');
    monitor.unwatch('services');
    monitor.unwatch('clients');
  });

  testWidgets('fresh data is reused; stale data is re-checked at the shortest interval', (tester) async {
    final (:monitor, :calls, :advance) = _setup();
    monitor.watch('home', [_a], interval: const Duration(seconds: 30));
    await tester.pump();

    // Switching to another tab within the interval doesn't re-check.
    monitor.unwatch('home');
    advance(const Duration(seconds: 10));
    monitor.watch('services', [_a], interval: const Duration(seconds: 15));
    await tester.pump();
    expect(calls[_a], 1);

    // Due after 15 s (Services' interval), picked up on the next tick.
    advance(const Duration(seconds: 5));
    await tester.pump(StatusMonitor.tick);
    expect(calls[_a], 2);
    monitor.unwatch('services');
  });

  testWidgets('concurrent refreshes join the check in flight', (tester) async {
    final done = Completer<ServiceReport>();
    final (:monitor, :calls, advance: _) = _setup(check: (_) => done.future);
    final first = monitor.refresh(_a);
    final second = monitor.refresh(_a);
    await tester.pump();
    expect(monitor.statusOf(_a).checking, isTrue);
    done.complete(_report);
    await Future.wait([first, second]);
    expect(calls[_a], 1);
    expect(monitor.statusOf(_a).checking, isFalse);
  });

  testWidgets('nothing is polled once every tab has unwatched', (tester) async {
    final (:monitor, :calls, :advance) = _setup();
    monitor.watch('home', [_a], interval: const Duration(seconds: 5));
    await tester.pump();
    monitor.unwatch('home');
    advance(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(calls[_a], 1);
  });

  testWidgets('a failed check keeps the last report', (tester) async {
    var fail = false;
    final (:monitor, calls: _, advance: _) = _setup(
      check: (_) => fail ? Future.error(StateError('down')) : Future.value(_report),
    );
    await monitor.refresh(_a);
    fail = true;
    await monitor.refresh(_a);
    expect(monitor.statusOf(_a).report, same(_report));
  });
}
