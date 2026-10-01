import 'dart:async';

import 'package:flutter/widgets.dart';

import 'services.dart';

/// What service status is checked against: a p4n4-api URL, plus the host
/// whose ports are probed when that API is down.
typedef StatusTarget = ({Uri api, String host});

/// The latest check of one [StatusTarget].
class TargetStatus {
  const TargetStatus({this.report, this.checkedAt, this.checking = false});

  /// Null until the first check finishes.
  final ServiceReport? report;
  final DateTime? checkedAt;
  final bool checking;
}

/// Shared service-status polling for every tab that shows it (Home, Services,
/// Clients), so a host is checked once however many tabs display it.
///
/// Tabs [watch] the targets they show while visible and [unwatch] when hidden.
/// Watched targets are re-checked once their data is older than the shortest
/// interval any watcher asked for; a check already in flight is shared.
class StatusMonitor extends ChangeNotifier {
  StatusMonitor({Future<ServiceReport> Function(StatusTarget)? check, DateTime Function()? clock})
    : _check = check ?? _checkServices,
      _now = clock ?? DateTime.now;

  static Future<ServiceReport> _checkServices(StatusTarget t) =>
      checkServices(t.api, (d) => Uri.parse('http://${t.host}:${d.port}${d.path}'));

  /// How often due targets are looked for; bounds how late a check can be.
  static const tick = Duration(seconds: 5);

  final Future<ServiceReport> Function(StatusTarget) _check;
  final DateTime Function() _now;

  final _status = <StatusTarget, TargetStatus>{};
  final _inFlight = <StatusTarget, Future<void>>{};
  final _watchers = <Object, ({Set<StatusTarget> targets, Duration interval})>{};
  Timer? _timer;
  bool _disposed = false;

  TargetStatus statusOf(StatusTarget t) => _status[t] ?? const TargetStatus();

  /// Polls [targets] every [interval] on behalf of [owner], replacing what
  /// [owner] watched before. Stale or never-checked targets are checked now.
  void watch(Object owner, Iterable<StatusTarget> targets, {required Duration interval}) {
    _watchers[owner] = (targets: targets.toSet(), interval: interval);
    _timer ??= Timer.periodic(tick, (_) => _poll());
    _poll();
  }

  void unwatch(Object owner) {
    _watchers.remove(owner);
    if (_watchers.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Checks [t] now (e.g. pull-to-refresh), or joins a check already running.
  ///
  /// The check starts in a microtask because tabs [watch] while building,
  /// and notifying listeners mid-build isn't allowed.
  Future<void> refresh(StatusTarget t) => _inFlight[t] ??= Future.microtask(() => _run(t));

  void _poll() {
    final due = <StatusTarget, Duration>{};
    for (final w in _watchers.values) {
      for (final t in w.targets) {
        final i = due[t];
        if (i == null || w.interval < i) due[t] = w.interval;
      }
    }
    for (final MapEntry(key: t, value: interval) in due.entries) {
      final at = _status[t]?.checkedAt;
      if (at == null || _now().difference(at) >= interval) refresh(t);
    }
  }

  Future<void> _run(StatusTarget t) async {
    final previous = _status[t];
    _status[t] = TargetStatus(report: previous?.report, checkedAt: previous?.checkedAt, checking: true);
    _notify();
    try {
      final report = await _check(t);
      _status[t] = TargetStatus(report: report, checkedAt: _now());
    } catch (_) {
      // checkServices already falls back to probes; keep the last report.
      _status[t] = TargetStatus(report: previous?.report, checkedAt: _now());
    } finally {
      _inFlight.remove(t);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// Exposes the app's [StatusMonitor] and rebuilds dependents when any status changes.
class StatusScope extends InheritedNotifier<StatusMonitor> {
  const StatusScope({super.key, required StatusMonitor monitor, required super.child}) : super(notifier: monitor);

  static StatusMonitor of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StatusScope>()!.notifier!;

  /// For callbacks and lifecycle methods that must not subscribe to changes.
  static StatusMonitor read(BuildContext context) => context.getInheritedWidgetOfExactType<StatusScope>()!.notifier!;
}
