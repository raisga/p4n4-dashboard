import 'dart:async';

import 'package:flutter/material.dart';

import '../api/edge_metrics.dart';
import '../api/services.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

const _interval = Duration(seconds: 30);

/// Client home: system health at a glance, a device summary and shortcuts to
/// the other tabs. Deliberately free of hosts, ports and URLs.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.active, required this.shortcuts, required this.onOpen});

  final bool active;

  /// Tabs to offer as shortcut cards.
  final List<DashTab> shortcuts;
  final ValueChanged<DashTab> onOpen;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  P4Colors get p4 => context.p4;

  final _demo = DemoMetrics();
  EdgeMetrics? _metrics;
  bool _metricsFailed = false;
  bool _metricsLoading = false;
  Timer? _timer;
  String? _metricsKey;

  // Service status comes from the shared StatusMonitor; only edge metrics are polled here.
  late StatusMonitor _monitor;
  late StatusTarget _target;

  ServiceReport? get _report => _monitor.statusOf(_target).report;
  bool get _loading => _metricsLoading || _monitor.statusOf(_target).checking;

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
    _schedule();
  }

  @override
  void didUpdateWidget(OverviewTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _fetchMetrics();
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

  Future<void> _refresh() => (_monitor.refresh(_target), _fetchMetrics()).wait;

  Future<void> _fetchMetrics() async {
    if (_metricsLoading || !BrandScope.of(context).tabs.contains(DashTab.edge)) return;
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
    return RefreshIndicator(
      color: p4.accent,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    tag: 'overview',
                    title: Text(brand.appName, style: p4.display(size: 28, weight: FontWeight.w800, spacing: -1)),
                    trailing: IconButton(
                      tooltip: 'Refresh status',
                      onPressed: _loading ? null : _refresh,
                      icon: _loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent),
                            )
                          : Icon(Icons.refresh, color: p4.muted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _summary(),
                  const SizedBox(height: 16),
                  _grid([for (final st in stacks.where((st) => st.suffix != 'api')) _stackTile(st)], minWidth: 220),
                  if (brand.tabs.contains(DashTab.edge)) ...[const SizedBox(height: 16), _device()],
                  if (widget.shortcuts.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    const SectionHeader(tag: 'go to', title: SizedBox.shrink()),
                    const SizedBox(height: 12),
                    _grid([for (final t in widget.shortcuts) _shortcut(t)], minWidth: 220),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final r = _report;
    final (health, title, sub) = switch (r) {
      null => (Health.pending, 'Checking your system…', 'This takes a few seconds.'),
      // The API answered but reported none of the catalog's services.
      _ when r.known == 0 => (
        Health.unknown,
        'Service status unavailable',
        'Your system is responding but didn\'t report service status. Contact your administrator if this persists.',
      ),
      // Probing is the fallback when the API is down, so nothing answering means the host is unreachable.
      _ when !r.viaApi && r.online == 0 => (
        Health.down,
        'We can\'t reach your system',
        'Check that the device is on and connected.',
      ),
      _ when r.online == r.known => (
        Health.up,
        'All systems operational',
        '${r.online} of ${r.known} services running.',
      ),
      _ => (
        Health.down,
        '${r.known - r.online} service${r.known - r.online == 1 ? ' needs' : 's need'} attention',
        '${r.online} of ${r.known} services running. Contact your administrator if this persists.',
      ),
    };
    final color = switch (health) {
      Health.up => p4.ok,
      Health.down => p4.err,
      _ => p4.warn,
    };
    return Panel(
      accent: color,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusIndicator(health),
          const SizedBox(height: 12),
          Text(title, style: p4.display(size: 22, weight: FontWeight.w800, spacing: -0.8)),
          const SizedBox(height: 6),
          Text(
            sub,
            style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
          ),
        ],
      ),
    );
  }

  Widget _stackTile(StackDef st) {
    final r = _report;
    final (online, known) = r?.of(st) ?? (0, 0);
    final health = r == null
        ? Health.pending
        : known == 0
        ? Health.unknown
        : (online == known ? Health.up : Health.down);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(st.label, style: p4.display()),
          const SizedBox(height: 10),
          StatusIndicator(health, label: r == null || known == 0 ? null : '$online / $known online'),
        ],
      ),
    );
  }

  Widget _device() {
    final m = _metrics;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edge device', style: p4.display()),
          const SizedBox(height: 14),
          if (m == null)
            Text(
              _metricsFailed ? 'Device readings are unavailable right now.' : 'Loading readings…',
              style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
            )
          else
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _reading('Processor', '${m.cpu.round()}%'),
                _reading('Memory', '${m.mem.round()}%'),
                if (m.tempC != null) _reading('Temperature', '${m.tempC!.round()}°C'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reading(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: p4.mono(size: 10)),
      const SizedBox(height: 4),
      Text(value, style: p4.display(size: 24, weight: FontWeight.w800, spacing: -0.8)),
    ],
  );

  Widget _shortcut(DashTab tab) {
    final (icon, title, desc) = switch (tab) {
      DashTab.services => (Icons.apps_outlined, 'Services', 'Open the apps running on your system.'),
      DashTab.edge => (Icons.memory_outlined, 'Device', 'Live readings from your edge device.'),
      DashTab.agent => (Icons.forum_outlined, 'Assistant', 'Ask questions about your system.'),
      DashTab.grafana => (Icons.show_chart, 'Dashboards', 'Charts and history for your sensors.'),
      DashTab.video => (Icons.videocam_outlined, 'Camera', 'Watch the live camera feed.'),
    };
    return Material(
      color: p4.bg2,
      shape: Border.all(color: p4.border),
      child: InkWell(
        onTap: () => widget.onOpen(tab),
        hoverColor: p4.bg3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: p4.accent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: p4.display()),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Equal-width columns, at least [minWidth] wide.
  Widget _grid(List<Widget> children, {double minWidth = 260}) => LayoutBuilder(
    builder: (context, c) {
      final cols = (c.maxWidth / minWidth).floor().clamp(1, 4);
      final w = (c.maxWidth - (cols - 1) * 12) / cols - 0.01;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    },
  );
}
