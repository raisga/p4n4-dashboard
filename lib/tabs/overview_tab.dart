import 'dart:async';

import 'package:flutter/material.dart';

import '../api/edge_metrics.dart';
import '../api/project.dart';
import '../api/services.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/markdown_panel.dart';

const _interval = Duration(seconds: 30);

/// Home, every view's first tab: one big "is everything OK" card, the device's
/// readings in plain language, and the project's own Markdown when it has some
/// (`HOME.md`, see [fetchProjectHome]).
/// For viewers it's free of service and stack names, hosts, ports and URLs:
/// what's broken is said as what people use (the assistant, charts).
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.active, required this.tabs, required this.onOpen, this.onAsk});

  final bool active;

  /// Tabs this view has, for HOME.md's `tab:` links and the device details link.
  final List<DashTab> tabs;
  final ValueChanged<DashTab> onOpen;

  /// Opens the Assistant and asks it a question (HOME.md's `ask:` links).
  final ValueChanged<String>? onAsk;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  final _demo = DemoMetrics();
  EdgeMetrics? _metrics;
  bool _metricsFailed = false;
  bool _metricsLoading = false;
  Timer? _timer;
  String? _metricsKey;

  // The connected project's HOME.md in the app's language, null while it has
  // none; read again on reconnecting, switching language, refreshing, and
  // coming back to the tab.
  String? _home;
  ProjectInfo? _homeProject;
  String? _homeLang;

  // Service status comes from the shared StatusMonitor; only edge metrics are polled here.
  late StatusMonitor _monitor;
  late StatusTarget _target;

  TargetStatus get _status => _monitor.statusOf(_target);
  bool get _loading => _metricsLoading || _status.checking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor = StatusScope.of(context);
    final s = SettingsScope.of(context);
    _target = s.statusTarget;
    final key = '${s.edgeDemo}|${s.edgeMetricsUri}';
    if (key != _metricsKey) {
      _metricsKey = key;
      _metrics = null;
      _fetchMetrics();
    }
    final lang = Localizations.localeOf(context).languageCode;
    if (s.project != _homeProject || lang != _homeLang) {
      _homeProject = s.project;
      _homeLang = lang;
      _home = null;
      _fetchHome();
    }
    _schedule();
  }

  @override
  void didUpdateWidget(OverviewTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _fetchMetrics();
      _fetchHome();
    }
    _schedule();
  }

  /// Matches polling to [active]; a no-op otherwise, so rebuilds don't push
  /// the next poll back.
  void _schedule() {
    if (!widget.active) {
      _timer?.cancel();
      _timer = null;
      _monitor.unwatch(this);
    } else {
      _timer ??= Timer.periodic(_interval, (_) => _fetchMetrics());
      _monitor.watch(this, [_target], interval: _interval);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _monitor.unwatch(this);
    super.dispose();
  }

  /// Edge readings, when both the brand and the connected project have the Edge tab.
  bool get _showsDevice =>
      BrandScope.of(context).tabs.contains(DashTab.edge) && SettingsScope.of(context).projectAllows(DashTab.edge);

  Future<void> _refresh() => (_monitor.refresh(_target), _fetchMetrics(), _fetchHome()).wait;

  /// Only once p4n4-api has described the project: without it there's no file to read.
  Future<void> _fetchHome() async {
    final (project, lang) = (_homeProject, _homeLang);
    if (project == null) return;
    try {
      final home = await fetchProjectHome(_target.api, lang: lang);
      if (mounted && project == _homeProject && lang == _homeLang && home != _home) setState(() => _home = home);
    } catch (_) {
      // Keep what's shown; the next refresh tries again.
    }
  }

  Future<void> _fetchMetrics() async {
    if (_metricsLoading || !_showsDevice) return;
    final s = SettingsScope.of(context);
    final key = _metricsKey;
    // Not setState: this can run from didChangeDependencies, mid-build.
    _metricsLoading = true;
    try {
      final m = s.edgeDemo ? _demo.next() : await fetchEdgeMetrics(s.edgeMetricsUri);
      if (mounted && key == _metricsKey) {
        setState(() {
          _metrics = m;
          _metricsFailed = false;
        });
      }
    } catch (_) {
      if (mounted && key == _metricsKey) setState(() => _metricsFailed = true);
    } finally {
      _metricsLoading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final checkedAt = _status.checkedAt;
    return PageBody(
      maxWidth: 1000,
      onRefresh: _refresh,
      children: [
        PageHeader(
          title: brand.appName,
          subtitle: checkedAt == null ? null : l.summaryUpdated(context.formats.clock(checkedAt)),
          trailing: RefreshButton(busy: _loading, onPressed: _refresh),
        ),
        const SizedBox(height: 24),
        _summary(),
        if (_showsDevice) ...[const SizedBox(height: 16), _device()],
        if (_home case final home?) ...[
          const SizedBox(height: 16),
          MarkdownPanel(
            home,
            tabs: {for (final t in widget.tabs) t.name},
            onTab: (name) => widget.onOpen(DashTab.values.byName(name)),
            onAsk: widget.tabs.contains(DashTab.agent) ? widget.onAsk : null,
          ),
        ],
      ],
    );
  }

  Widget _summary() {
    final r = _status.report;
    final (health, title, sub) = switch (r) {
      null => (Health.pending, l.summaryChecking, l.summaryCheckingSub),
      // The API answered but reported none of the catalog's services.
      _ when r.known == 0 => (Health.unknown, l.summaryUnavailable, l.summaryUnavailableSub),
      // Probing is the fallback when the API is down, so nothing answering means the host is unreachable.
      _ when !r.viaApi && r.online == 0 => (Health.down, l.summaryUnreachable, l.summaryUnreachableSub),
      _ when r.online == r.known => (Health.up, l.summaryOk, l.summaryOkSub),
      _ => (Health.down, l.summaryAttention, l.summaryAttentionSub),
    };
    final (color, icon) = switch (health) {
      Health.up => (p4.ok, Icons.check_circle_outline),
      Health.down => (p4.err, Icons.error_outline),
      Health.pending => (p4.warn, Icons.hourglass_empty),
      _ => (p4.warn, Icons.help_outline),
    };
    final affected = health == Health.down && r != null && r.online > 0 ? _affected(r) : const <String>[];
    return Panel(
      accent: color,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: p4.display(size: 24, weight: FontWeight.w800, spacing: -0.6)),
                const SizedBox(height: 6),
                Text(sub, style: p4.body(size: 15, color: p4.muted)),
                if (affected.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l.summaryAffected(affected.join(', ')),
                    style: p4.body(size: 14, color: p4.text, weight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What's down: service names for those who know them, and for viewers the
  /// thing they use that each one provides.
  List<String> _affected(ServiceReport r) {
    final technical = SessionScope.of(context).isTechnical;
    final platform = BrandScope.of(context).platform;
    final down = [
      for (final MapEntry(key: def, value: up) in r.up.entries)
        if (up == false) def,
    ];
    if (technical) return [for (final d in down) d.label(platform)];
    return {
      for (final d in down)
        switch (d.name) {
          'Ollama' || 'Letta' => l.featureAssistant,
          'Grafana' => l.featureCharts,
          'InfluxDB' => l.featureHistory,
          'MQTT' => l.featureSensors,
          'Node-RED' || 'n8n' => l.featureAutomations,
          'EI Runner' => l.featureDeviceAi,
          _ => l.featureConnection,
        },
    }.toList();
  }

  Widget _device() {
    final m = _metrics;
    final f = context.formats;
    final details = widget.tabs.contains(DashTab.edge);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.yourDevice, style: p4.display(size: 17))),
              if (details)
                TextButton.icon(
                  onPressed: () => widget.onOpen(DashTab.edge),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(l.deviceDetails),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (m == null)
            Text(_metricsFailed ? l.deviceUnavailable : l.deviceLoading, style: p4.body(color: p4.muted))
          else
            TileGrid(
              minWidth: 180,
              children: [
                _reading(l.readingProcessor, f.percent(m.cpu), usageLevel(m.cpu)),
                _reading(l.readingMemory, f.percent(m.mem), usageLevel(m.mem)),
                if (m.tempC != null)
                  _reading(
                    l.readingTemperature,
                    f.temperature(m.tempC!),
                    temperatureLevel(m.tempC!),
                    temperature: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reading(String label, String value, Level level, {bool temperature = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: p4.body(size: 13, color: p4.muted, weight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        // Wraps the badge under the value with large text (Settings → Accessibility).
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(value, style: p4.display(size: 26, weight: FontWeight.w800, spacing: -0.8)),
            TagBadge(l.levelName(level, temperature: temperature), color: levelColor(p4, level)),
          ],
        ),
      ],
    );
  }
}
