import 'dart:async';

import 'package:flutter/widgets.dart';

import 'edge_metrics.dart';

/// Where one deployment's edge readings come from: its metrics URL, or made
/// up when it has demo data on.
typedef MetricsSource = ({Uri uri, bool demo});

/// One reading and when it arrived.
typedef MetricsSample = ({DateTime at, EdgeMetrics metrics});

/// What's known of one [MetricsSource].
class SourceMetrics {
  const SourceMetrics({this.history = const [], this.error, this.checkedAt, this.checking = false});

  /// Readings, oldest first, at most [MetricsMonitor.maxHistory].
  final List<MetricsSample> history;

  /// Why the last check failed; null once one succeeds.
  final Object? error;

  /// When it was last checked, whatever the outcome.
  final DateTime? checkedAt;
  final bool checking;

  EdgeMetrics? get latest => history.lastOrNull?.metrics;

  /// When the last reading arrived.
  DateTime? get updatedAt => history.lastOrNull?.at;
}

/// Shared edge-metrics polling for every screen that shows readings (Home,
/// the Device tab, the fleet grid in Clients), like [StatusMonitor] for
/// service status: a source is fetched once however many screens show it,
/// as often as the most eager of them asks, and its history is shared.
///
/// Screens [watch] the sources they show while visible and [unwatch] when
/// hidden. What nobody has watched for [keep] is forgotten, so a large
/// fleet's readings don't pile up.
class MetricsMonitor extends ChangeNotifier {
  MetricsMonitor({
    Future<EdgeMetrics> Function(Uri)? fetch,
    DateTime Function()? clock,
    this.keep = const Duration(minutes: 10),
  }) : _fetch = fetch ?? fetchEdgeMetrics,
       _now = clock ?? DateTime.now;

  /// How often due sources are looked for; the Device tab polls every 2 s.
  static const tick = Duration(seconds: 1);

  /// Enough for the Device tab's longest chart: 30 minutes at one reading every 2 s.
  static const maxHistory = 900;

  final Future<EdgeMetrics> Function(Uri) _fetch;
  final DateTime Function() _now;
  final Duration keep;

  final _metrics = <MetricsSource, SourceMetrics>{};
  final _demo = <MetricsSource, DemoMetrics>{};
  final _inFlight = <MetricsSource, Future<void>>{};
  final _watchers = <Object, ({Set<MetricsSource> sources, Duration interval})>{};
  Timer? _timer;
  bool _disposed = false;

  SourceMetrics of(MetricsSource s) => _metrics[s] ?? const SourceMetrics();

  /// The sources anyone watches now.
  Set<MetricsSource> get watched => {for (final w in _watchers.values) ...w.sources};

  /// Fetches [sources] every [interval] on behalf of [owner], replacing what
  /// it watched before. Stale or never-fetched sources are fetched now.
  void watch(Object owner, Iterable<MetricsSource> sources, {required Duration interval}) {
    _watchers[owner] = (sources: sources.toSet(), interval: interval);
    _timer ??= Timer.periodic(tick, (_) => _poll());
    _poll();
  }

  void unwatch(Object owner) {
    if (_watchers.remove(owner) == null) return;
    _prune();
    if (_watchers.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Fetches [s] now (e.g. pull-to-refresh), or joins a fetch already running.
  /// Starts in a microtask: screens [watch] while building.
  Future<void> refresh(MetricsSource s) => _inFlight[s] ??= Future.microtask(() => _run(s));

  void _poll() {
    final due = <MetricsSource, Duration>{};
    for (final w in _watchers.values) {
      for (final s in w.sources) {
        final i = due[s];
        if (i == null || w.interval < i) due[s] = w.interval;
      }
    }
    for (final MapEntry(key: s, value: interval) in due.entries) {
      final at = _metrics[s]?.checkedAt;
      // A little early is fine: the tick rounds intervals up otherwise.
      if (at == null || _now().difference(at) >= interval - const Duration(milliseconds: 200)) refresh(s);
    }
    _prune();
  }

  /// Forgets sources nobody has watched for [keep]. Without notifying: it runs
  /// as screens watch (while building) and unwatch (while disposing), and
  /// nobody shows what's forgotten.
  void _prune() {
    final watched = this.watched;
    final now = _now();
    final stale = [
      for (final MapEntry(key: s, value: m) in _metrics.entries)
        if (!watched.contains(s) && !_inFlight.containsKey(s) && now.difference(m.checkedAt ?? now) >= keep) s,
    ];
    for (final s in stale) {
      _metrics.remove(s);
      _demo.remove(s);
    }
  }

  Future<void> _run(MetricsSource s) async {
    final previous = of(s);
    _metrics[s] = SourceMetrics(
      history: previous.history,
      error: previous.error,
      checkedAt: previous.checkedAt,
      checking: true,
    );
    _notify();
    try {
      final m = s.demo ? (_demo[s] ??= DemoMetrics()).next() : await _fetch(s.uri);
      final now = _now();
      final history = [...previous.history, (at: now, metrics: m)];
      _metrics[s] = SourceMetrics(
        history: history.length > maxHistory ? history.sublist(history.length - maxHistory) : history,
        checkedAt: now,
      );
    } catch (e) {
      // Keep the readings so far: a chart doesn't empty for one failed fetch.
      _metrics[s] = SourceMetrics(history: previous.history, error: e, checkedAt: _now());
    } finally {
      _inFlight.remove(s);
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

/// Exposes the app's [MetricsMonitor] and rebuilds dependents when readings change.
class MetricsScope extends InheritedNotifier<MetricsMonitor> {
  const MetricsScope({super.key, required MetricsMonitor monitor, required super.child}) : super(notifier: monitor);

  static MetricsMonitor of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MetricsScope>()!.notifier!;

  /// For lifecycle methods that must not subscribe to changes.
  static MetricsMonitor read(BuildContext context) => context.getInheritedWidgetOfExactType<MetricsScope>()!.notifier!;
}
