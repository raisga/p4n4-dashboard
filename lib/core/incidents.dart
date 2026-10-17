import 'package:flutter/widgets.dart';

import '../api/fleet.dart';
import '../api/services.dart';
import '../api/status_monitor.dart';
import 'settings.dart';

/// One outage seen from this device: [service] (a catalog name such as
/// `Node-RED`, or [unreachable] for the whole deployment) down from [start]
/// until [end], or still down.
class Incident {
  const Incident({required this.service, required this.start, this.end});

  factory Incident.fromJson(Map<String, Object?> j) => Incident(
    service: j['service'] as String? ?? '',
    start: DateTime.parse(j['start'] as String).toLocal(),
    end: switch (j['end']) {
      final String end => DateTime.parse(end).toLocal(),
      _ => null,
    },
  );

  /// [service] when nothing on the deployment answered, not even its port probes.
  static const unreachable = '';

  final String service;
  final DateTime start;
  final DateTime? end;

  bool get ongoing => end == null;

  /// How long it lasted, or has lasted by [now].
  Duration lengthAt(DateTime now) => (end ?? now).difference(start);

  Incident endedAt(DateTime at) => Incident(service: service, start: start, end: at);

  Map<String, Object?> toJson() => {
    'service': service,
    'start': start.toUtc().toIso8601String(),
    if (end != null) 'end': end!.toUtc().toIso8601String(),
  };
}

/// Each deployment's service outages, from the status checks this device
/// makes ([StatusMonitor]): a service that stops answering opens an incident,
/// and one that comes back ends it. Kept on this device, the last
/// [maxPerDeployment] per deployment.
///
/// It only knows what was checked: while no screen shows a deployment's
/// status (Home, Services, Clients), nothing is recorded for it, and an
/// outage that began before the first check starts at that check.
class IncidentLog extends ChangeNotifier {
  IncidentLog(this._monitor, this._settings) {
    _monitor.addListener(_check);
  }

  static const maxPerDeployment = 50;

  final StatusMonitor _monitor;
  final AppSettings _settings;

  final _incidents = <String, List<Incident>>{};

  /// The check last applied to each deployment, so each is applied once.
  final _applied = <String, DateTime>{};

  /// [d]'s incidents, oldest first.
  List<Incident> of(Deployment d) => List.unmodifiable(_load(d));

  /// [service]'s outage on [d] going on now, if any.
  Incident? ongoing(Deployment d, String service) =>
      _load(d).where((i) => i.ongoing && i.service == service).lastOrNull;

  List<Incident> _load(Deployment d) => _incidents[d.id] ??= [for (final j in _settings.incidentsOf(d)) ?_parse(j)];

  static Incident? _parse(Map<String, Object?> j) {
    try {
      return Incident.fromJson(j);
    } on Object {
      return null; // unreadable: skip it
    }
  }

  /// Forgets [d]'s incidents (an admin's "Clear" in its history).
  Future<void> clear(Deployment d) async {
    _incidents[d.id] = [];
    notifyListeners();
    await _settings.setIncidentsOf(d, const []);
  }

  void _check() {
    for (final d in _settings.deployments) {
      final status = _monitor.statusOf(_settings.targetOf(d));
      final (report, at) = (status.report, status.checkedAt);
      if (report == null || at == null || _applied[d.id] == at) continue;
      _applied[d.id] = at;
      record(d, report, at);
    }
  }

  /// Opens and ends [d]'s incidents for what [report] says at [at].
  @visibleForTesting
  void record(Deployment d, ServiceReport report, DateTime at) {
    final list = _load(d);
    final open = {
      for (final i in list)
        if (i.ongoing) i.service,
    };
    // Unreachable: the services' own outages stay open, as nothing says they're back.
    final down = !report.viaApi && report.online == 0
        ? {...open, Incident.unreachable}
        : {
            for (final MapEntry(key: def, value: up) in report.up.entries)
              if (up == false) def.name,
          };
    final started = down.difference(open);
    final ended = open.difference(down);
    if (started.isEmpty && ended.isEmpty) return;
    for (final (i, incident) in list.indexed.toList()) {
      if (incident.ongoing && ended.contains(incident.service)) list[i] = incident.endedAt(at);
    }
    list.addAll([for (final s in started) Incident(service: s, start: at)]);
    // The oldest finished ones go first; ongoing ones stay however old.
    while (list.length > maxPerDeployment) {
      final oldest = list.indexWhere((i) => !i.ongoing);
      if (oldest < 0) break;
      list.removeAt(oldest);
    }
    notifyListeners();
    _settings.setIncidentsOf(d, [for (final i in list) i.toJson()]);
  }

  @override
  void dispose() {
    _monitor.removeListener(_check);
    super.dispose();
  }
}

/// Exposes the app's [IncidentLog] and rebuilds dependents when it changes.
class IncidentScope extends InheritedNotifier<IncidentLog> {
  const IncidentScope({super.key, required IncidentLog log, required super.child}) : super(notifier: log);

  static IncidentLog? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IncidentScope>()?.notifier;
}
