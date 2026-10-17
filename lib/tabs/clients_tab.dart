import 'package:flutter/material.dart';

import '../api/fleet.dart';
import '../api/metrics_monitor.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/format.dart';
import '../core/incidents.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../core/thresholds.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/sparkline.dart';

/// Admins' fleet overview: a card per client deployment with live status
/// from its host, its edge device's readings and the outages seen from here.
class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key, required this.active});

  final bool active;

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  static const _interval = Duration(seconds: 30);

  late StatusMonitor _monitor;
  late MetricsMonitor _metrics;
  late List<StatusTarget> _targets;
  late List<MetricsSource> _sources;

  /// Every deployment's status and readings come from the shared monitors,
  /// keyed by where they're read from, so renaming a deployment keeps them
  /// and the connected one shares checks with Home, Services and Device.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor = StatusScope.of(context);
    _metrics = MetricsScope.of(context);
    final s = SettingsScope.of(context);
    _targets = [for (final d in s.deployments) s.targetOf(d)];
    _sources = [for (final d in s.deployments) s.metricsSourceOf(d)];
    _watch();
  }

  @override
  void didUpdateWidget(ClientsTab old) {
    super.didUpdateWidget(old);
    _watch();
  }

  void _watch() {
    if (widget.active) {
      _monitor.watch(this, _targets, interval: _interval);
      _metrics.watch(this, _sources, interval: _interval);
    } else {
      _monitor.unwatch(this);
      _metrics.unwatch(this);
    }
  }

  @override
  void dispose() {
    _monitor.unwatch(this);
    _metrics.unwatch(this);
    super.dispose();
  }

  Future<void> _refresh() =>
      (Future.wait(_targets.toSet().map(_monitor.refresh)), Future.wait(_sources.toSet().map(_metrics.refresh))).wait;

  Future<void> _edit(AppSettings s, [Deployment? d]) async {
    final result = await showDialog<_DeploymentForm>(
      context: context,
      builder: (_) => _DeploymentDialog(
        initial: d == null ? null : (name: d.name, host: s.hostOf(d), apiBase: d.values['apiBase'] as String? ?? ''),
      ),
    );
    if (result == null) return;
    // An empty API URL means "the default", so drop the key rather than store ''.
    final values = {...?d?.values, 'host': result.host}..remove('apiBase');
    if (result.apiBase.isNotEmpty) values['apiBase'] = result.apiBase;
    // Saving changes the targets, which triggers a check of anything new.
    await s.saveDeployment(
      d == null
          ? Deployment(id: s.newDeploymentId(), name: result.name, values: values)
          : d.copyWith(name: result.name, values: values),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final list = s.deployments;
    // Rebuilt when readings or incidents change.
    MetricsScope.of(context);
    IncidentScope.maybeOf(context);
    return PageBody(
      maxWidth: 1400,
      onRefresh: _refresh,
      children: [
        PageHeader(
          title: l.clientsTitle,
          subtitle: l.clientsIntro,
          trailing: FilledButton.icon(
            onPressed: () => _edit(s),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.add),
          ),
        ),
        const SizedBox(height: 24),
        if (list.isEmpty)
          EmptyState(icon: Icons.devices_other_outlined, title: l.noDeployments, message: l.noDeploymentsMsg)
        else
          TileGrid(minWidth: 340, children: [for (final d in list) _card(s, d)]),
      ],
    );
  }

  Widget _card(AppSettings s, Deployment d) {
    final r = _monitor.statusOf(s.targetOf(d)).report;
    final current = d.id == s.deployment.id;
    final api = s.apiUriOf(d);
    final customApi = api != Uri.parse('http://${s.hostOf(d)}:8000');
    final thresholds = s.thresholdsOf(d);
    final log = IncidentScope.maybeOf(context);
    final incidents = log?.of(d) ?? const <Incident>[];
    final now = DateTime.now();
    final open = [
      for (final i in incidents)
        if (i.ongoing) i,
    ];
    // How long the longest outage now has gone on, for its colour.
    final longest = open.isEmpty ? null : open.map((i) => i.lengthAt(now)).reduce((a, b) => a > b ? a : b);
    final health = switch (r) {
      null => Health.pending,
      _ when r.known == 0 => Health.unknown,
      _ when r.online == 0 => Health.down,
      _ => Health.up,
    };
    final degraded = r != null && r.online > 0 && r.online < r.known;
    final label = switch (r) {
      null => null,
      _ when r.online == 0 => l.healthOffline,
      _ when r.viaApi => l.clientsUp(r.online, r.known),
      _ => l.clientsUpProbed(r.online, r.known),
    };
    // Something down: amber at first, red once it has been down longer than the threshold.
    final statusColor = health == Health.down || degraded
        ? (longest != null ? levelColor(p4, thresholds.downLevel(longest)) : (degraded ? p4.warn : null))
        : null;
    final metrics = _metrics.of(s.metricsSourceOf(d));
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      accent: statusColor ?? (health == Health.down ? p4.err : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(d.name, overflow: TextOverflow.ellipsis, style: p4.display(size: 16)),
              ),
              if (current) ...[const SizedBox(width: 10), TagBadge(l.currentBadge, color: p4.ok)],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            customApi ? '${s.hostOf(d)} · api $api' : s.hostOf(d),
            overflow: TextOverflow.ellipsis,
            style: p4.mono(size: 12, spacing: 0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(child: StatusIndicator(health, label: label)),
              if (statusColor != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.warning_amber_rounded, size: 16, color: statusColor),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _readings(metrics, thresholds),
          if (incidents.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final i in [
              ...open.reversed,
              ...incidents.reversed.where((i) => !i.ongoing).take(open.isEmpty ? 2 : 1),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _incidentText(i, now),
                  overflow: TextOverflow.ellipsis,
                  style: p4.body(
                    size: 12,
                    color: i.ongoing ? levelColor(p4, thresholds.downLevel(i.lengthAt(now))) : p4.muted,
                    weight: i.ongoing ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: current ? null : () => s.connect(d.id), child: Text(l.connect)),
              if (log != null)
                IconButton(
                  tooltip: l.incidentHistory,
                  onPressed: () => _history(log, d),
                  icon: const Icon(Icons.history, size: 18),
                ),
              IconButton(
                tooltip: l.editTooltip,
                onPressed: () => _edit(s, d),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: current ? l.removeCurrentTooltip : l.removeTooltip,
                onPressed: current ? null : () => s.removeDeployment(d.id),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The edge device's processor and temperature, with the processor's last readings.
  Widget _readings(SourceMetrics metrics, Thresholds t) {
    final m = metrics.latest;
    final f = context.formats;
    if (m == null) {
      return Text(
        metrics.error != null ? l.fleetNoReadings : l.deviceLoading,
        style: p4.body(size: 13, color: p4.muted),
      );
    }
    final cpus = [for (final s in metrics.history.reversed.take(_spark).toList().reversed) s.metrics.cpu];
    Widget value(String label, String text, Level level) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: p4.body(size: 12, color: p4.muted)),
        Text(
          text,
          style: p4.display(size: 18, weight: FontWeight.w800, spacing: -0.4, color: levelColor(p4, level)),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        value(l.readingProcessor, f.percent(m.cpu), t.level(Reading.cpu, m.cpu)),
        if (m.tempC != null) ...[
          const SizedBox(width: 20),
          value(l.readingTemperature, f.temperature(m.tempC!), t.level(Reading.temperature, m.tempC!)),
        ],
        const SizedBox(width: 20),
        Expanded(
          child: Opacity(
            opacity: metrics.error != null ? 0.4 : 1,
            child: Sparkline(
              values: cpus,
              format: (v) => f.percent(v),
              maxY: 100,
              capacity: _spark,
              height: 36,
              label: (i) => f.clock(metrics.history[metrics.history.length - cpus.length + i].at),
            ),
          ),
        ),
      ],
    );
  }

  /// Readings in a card's sparkline: the last quarter hour at one every 30 s.
  static const _spark = 30;

  String _serviceName(String service) => service == Incident.unreachable
      ? l.incidentUnreachable
      : service.replaceFirst('p4n4', BrandScope.of(context).platform);

  /// `Node-RED down since 14:02 (12m)`, or `Node-RED down 14:02–14:09`.
  String _incidentText(Incident i, DateTime now) {
    final f = context.formats;
    String at(DateTime t) => DateUtils.isSameDay(t, now) ? f.clock(t) : f.dateTime(t);
    final name = _serviceName(i.service);
    return i.ongoing
        ? l.incidentOngoing(name, at(i.start), f.span(i.lengthAt(now)))
        : l.incidentEnded(name, at(i.start), DateUtils.isSameDay(i.start, i.end!) ? f.clock(i.end!) : at(i.end!));
  }

  Future<void> _history(IncidentLog log, Deployment d) => showDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final now = DateTime.now();
        final all = log.of(d).reversed.toList();
        return AlertDialog(
          title: Text(l.incidentHistoryOf(d.name)),
          content: SizedBox(
            width: 460,
            child: all.isEmpty
                ? Text(l.incidentNone, style: p4.body(color: p4.muted))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      Text(l.incidentNote, style: p4.body(size: 12, color: p4.muted)),
                      const SizedBox(height: 10),
                      for (final i in all)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _incidentText(i, now),
                            style: p4.body(size: 14, color: i.ongoing ? p4.err : p4.text),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            if (all.isNotEmpty) TextButton(onPressed: () => log.clear(d), child: Text(l.clearList)),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
          ],
        );
      },
    ),
  );
}

typedef _DeploymentForm = ({String name, String host, String apiBase});

/// Owns its controllers so they outlive the dialog's exit animation.
class _DeploymentDialog extends StatefulWidget {
  const _DeploymentDialog({this.initial});

  final _DeploymentForm? initial;

  @override
  State<_DeploymentDialog> createState() => _DeploymentDialogState();
}

class _DeploymentDialogState extends State<_DeploymentDialog> {
  P4Colors get p4 => context.p4;

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _host = TextEditingController(text: widget.initial?.host);
  late final _api = TextEditingController(text: widget.initial?.apiBase);

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _api.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim(), host = _host.text.trim(), api = _api.text.trim();
    if (host.isEmpty) return;
    Navigator.pop<_DeploymentForm>(context, (name: name.isEmpty ? host : name, host: host, apiBase: api));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.initial == null ? l.addDeployment : l.editDeployment),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(labelText: l.clientName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(labelText: l.fieldHost, hintText: '192.168.1.50'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _api,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(
                labelText: l.apiUrlOptional,
                hintText: 'http://<host>:8000',
                helperText: l.apiUrlHelp,
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
