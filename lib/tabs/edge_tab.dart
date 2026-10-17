import 'package:flutter/material.dart';

import '../api/metrics_monitor.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../core/thresholds.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/edge_sections.dart';
import '../widgets/sparkline.dart';
import '../widgets/support.dart';

const _interval = Duration(seconds: 2);

/// Readings per minute of chart history (one every [_interval]); how many
/// minutes is a setting (Settings → Appearance).
const _perMinute = 30;

/// Live system metrics for the edge device, then its sensors, and for admins
/// and power users its inference model and a way to send devices a command.
class EdgeTab extends StatefulWidget {
  const EdgeTab({super.key, required this.active});

  final bool active;

  @override
  State<EdgeTab> createState() => _EdgeTabState();
}

class _EdgeTabState extends State<EdgeTab> {
  P4Colors get p4 => context.p4;

  // The shared monitor polls and keeps the history, so Home's card and this
  // tab show the same readings and switching tabs keeps the charts.
  late MetricsMonitor _monitor;
  late MetricsSource _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor = MetricsScope.of(context);
    _source = SettingsScope.of(context).metricsSource;
    _schedule();
  }

  @override
  void didUpdateWidget(EdgeTab old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _monitor.unwatch(this);
    super.dispose();
  }

  void _schedule() => widget.active ? _monitor.watch(this, [_source], interval: _interval) : _monitor.unwatch(this);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final session = SessionScope.of(context);
    final technical = session.isTechnical;
    final l = context.l10n;
    final f = context.formats;
    final t = settings.thresholds;
    final metrics = _monitor.of(_source);
    final m = metrics.latest;
    final error = metrics.error;

    final header = PageHeader(
      title: l.navEdge,
      subtitle: l.edgeSubtitle,
      // Demo data is a setting: admins only.
      trailing: session.isAdmin
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(l.edgeDemoSwitch, style: p4.body(size: 13, color: p4.muted)),
                ),
                const SizedBox(width: 8),
                Switch(value: settings.edgeDemo, onChanged: (v) => settings.edgeDemo = v),
              ],
            )
          : null,
    );

    if (m == null && error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            header,
            Expanded(
              child: EmptyState(
                icon: Icons.sensors_off_outlined,
                color: p4.err,
                title: l.edgeNoMetrics,
                message: technical ? l.edgeFetchFailed('${_source.uri}', '$error') : l.edgeUnavailable,
                actions: [
                  if (session.isAdmin)
                    FilledButton(onPressed: () => settings.edgeDemo = true, child: Text(l.useDemoData)),
                  OutlinedButton(onPressed: () => _monitor.refresh(_source), child: Text(l.retry)),
                  if (!technical) const ContactSupportButton(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final capacity = settings.edgeHistoryMinutes * _perMinute;
    final window = metrics.history.length > capacity
        ? metrics.history.sublist(metrics.history.length - capacity)
        : metrics.history;
    final temps = [
      for (final s in window)
        if (s.metrics.tempC != null) s,
    ];
    final infs = [
      for (final s in window)
        if (s.metrics.inferenceMs != null) s,
    ];
    final now = DateTime.now();
    String ago(List<MetricsSample> samples, int i) => '−${f.span(now.difference(samples[i].at))}';
    String agoSeconds(List<MetricsSample> samples, int i) {
      final secs = now.difference(samples[i].at).inSeconds;
      return secs < 120 ? '−${secs}s' : ago(samples, i);
    }

    return PageBody(
      children: [
        header,
        const SizedBox(height: 12),
        // Wraps onto two lines with large text (Settings → Accessibility).
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusIndicator(
              error != null
                  ? Health.down
                  : (m == null ? Health.pending : (settings.edgeDemo ? Health.unknown : Health.up)),
              label: error != null
                  ? l.edgeStale
                  : (settings.edgeDemo ? l.edgeDemoLabel : (m == null ? null : l.edgeLive)),
            ),
            if (technical || settings.edgeDemo)
              Text(
                settings.edgeDemo ? l.edgeSynthetic : _source.uri.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: settings.edgeDemo ? p4.body(size: 13, color: p4.muted) : p4.mono(size: 12, spacing: 0),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (m == null)
          LoadingState(l.deviceLoading)
        else ...[
          TileGrid(
            minWidth: 280,
            children: [
              _MetricTile(
                l.readingProcessor,
                f.percent(m.cpu, technical ? 1 : 0),
                [for (final s in window) s.metrics.cpu],
                (v) => f.percent(v, 1),
                maxY: 100,
                readAt: (i) => agoSeconds(window, i),
                level: (t.level(Reading.cpu, m.cpu), l.levelName(t.level(Reading.cpu, m.cpu))),
              ),
              _MetricTile(
                l.readingMemory,
                f.percent(m.mem, technical ? 1 : 0),
                [for (final s in window) s.metrics.mem],
                (v) => f.percent(v, 1),
                maxY: 100,
                readAt: (i) => agoSeconds(window, i),
                level: (t.level(Reading.memory, m.mem), l.levelName(t.level(Reading.memory, m.mem))),
                sub: m.memUsedMb != null && m.memTotalMb != null
                    ? '${f.decimal(m.memUsedMb! / 1024)} / ${f.decimal(m.memTotalMb! / 1024)} GB'
                    : null,
              ),
              if (m.tempC != null)
                _MetricTile(
                  l.readingTemperature,
                  f.temperature(m.tempC!, technical ? 1 : 0),
                  [for (final s in temps) s.metrics.tempC!],
                  (v) => f.temperature(v, 1),
                  maxY: 100,
                  color: p4.amber,
                  readAt: (i) => agoSeconds(temps, i),
                  level: (
                    t.level(Reading.temperature, m.tempC!),
                    l.levelName(t.level(Reading.temperature, m.tempC!), temperature: true),
                  ),
                ),
              if (m.inferenceMs != null)
                _MetricTile(
                  l.metricInference,
                  '${f.decimal(m.inferenceMs!, technical ? 1 : 0)} ms',
                  [for (final s in infs) s.metrics.inferenceMs!],
                  (v) => '${f.decimal(v)} ms',
                  color: p4.blue,
                  readAt: (i) => agoSeconds(infs, i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TileGrid(
            minWidth: 220,
            children: [
              if (m.disk != null)
                _Fact(l.factDisk, f.percent(m.disk!), progress: m.disk! / 100, level: t.level(Reading.disk, m.disk!)),
              // Load average means little without knowing the core count: technical users only.
              if (m.load != null && technical) _Fact(l.factLoad, m.load!.map((e) => f.decimal(e, 2)).join('  ')),
              if (m.uptime != null) _Fact(l.factUptime, _uptime(m.uptime!)),
            ],
          ),
        ],
        const SizedBox(height: 32),
        SensorsPanel(active: widget.active),
        if (technical) ...[ModelPanel(active: widget.active), CommandPanel()],
      ],
    );
  }

  static String _uptime(Duration d) {
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    return days > 0 ? '${days}d ${h}h ${m}m' : '${h}h ${m}m';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
    this.label,
    this.value,
    this.history,
    this.format, {
    this.maxY,
    this.sub,
    this.color,
    this.level,
    this.readAt,
  });

  final String label;
  final String value;
  final List<double> history;
  final String Function(double) format;
  final double? maxY;
  final String? sub;
  final Color? color;

  /// When each of [history]'s readings came, for the chart's hover readout.
  final String Function(int index)? readAt;

  /// How the reading compares with normal, and that in words.
  final (Level, String)? level;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final minutes = SettingsScope.of(context).edgeHistoryMinutes;
    final capacity = minutes * _perMinute;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: p4.body(size: 14, color: p4.muted, weight: FontWeight.w500),
                ),
              ),
              if (level case (final lvl, final name)) TagBadge(name, color: levelColor(p4, lvl)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: p4.display(size: 30, weight: FontWeight.w800, spacing: -1)),
              if (sub != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    sub!,
                    overflow: TextOverflow.ellipsis,
                    style: p4.body(size: 13, color: p4.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Sparkline(values: history, format: format, maxY: maxY, color: color, capacity: capacity, label: readAt),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(context.l10n.sparkStart(minutes), style: p4.body(size: 11, color: p4.muted)),
              const Spacer(),
              Text(context.l10n.sparkNow, style: p4.body(size: 11, color: p4.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.progress, this.level});

  final String label;
  final String value;
  final double? progress;

  /// The bar's colour: how [progress] compares with the deployment's thresholds.
  final Level? level;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: p4.body(size: 13, color: p4.muted, weight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(value, style: p4.display(size: 18, weight: FontWeight.w700, spacing: -0.3)),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 6,
                color: levelColor(p4, level ?? Level.normal),
                backgroundColor: p4.bg3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
