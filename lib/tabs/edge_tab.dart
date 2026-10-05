import 'dart:async';

import 'package:flutter/material.dart';

import '../api/edge_metrics.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/sparkline.dart';

const _interval = Duration(seconds: 2);
const _capacity = 60; // two minutes of history

/// Live system metrics for the edge device.
class EdgeTab extends StatefulWidget {
  const EdgeTab({super.key, required this.active});

  final bool active;

  @override
  State<EdgeTab> createState() => _EdgeTabState();
}

class _EdgeTabState extends State<EdgeTab> {
  P4Colors get p4 => context.p4;

  final _cpu = <double>[], _mem = <double>[], _temp = <double>[], _inf = <double>[];
  final _demo = DemoMetrics();
  EdgeMetrics? _latest;
  Object? _error;
  Timer? _timer;
  String? _sourceKey;
  bool _inFlight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SettingsScope.of(context);
    final key = '${s.edgeDemo}|${s.edgeMetricsUri}';
    if (key != _sourceKey) {
      _sourceKey = key;
      _reset();
    }
    _schedule();
  }

  @override
  void didUpdateWidget(EdgeTab old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    for (final l in [_cpu, _mem, _temp, _inf]) {
      l.clear();
    }
    _latest = null;
    _error = null;
  }

  void _schedule() {
    if (!widget.active) {
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null) {
      _tick();
      _timer = Timer.periodic(_interval, (_) => _tick());
    }
  }

  Future<void> _tick() async {
    if (_inFlight) return;
    final settings = SettingsScope.of(context);
    final key = _sourceKey;
    _inFlight = true;
    try {
      final m = settings.edgeDemo ? _demo.next() : await fetchEdgeMetrics(settings.edgeMetricsUri);
      if (!mounted || key != _sourceKey) return;
      setState(() {
        _error = null;
        _latest = m;
        _push(_cpu, m.cpu);
        _push(_mem, m.mem);
        if (m.tempC != null) _push(_temp, m.tempC!);
        if (m.inferenceMs != null) _push(_inf, m.inferenceMs!);
      });
    } catch (e) {
      if (mounted && key == _sourceKey) setState(() => _error = e);
    } finally {
      _inFlight = false;
    }
  }

  static void _push(List<double> l, double v) {
    l.add(v);
    if (l.length > _capacity) l.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final session = SessionScope.of(context);
    final technical = session.isTechnical;
    final l = context.l10n;
    final f = context.formats;
    final m = _latest;

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

    if (m == null && _error != null) {
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
                message: technical ? l.edgeFetchFailed('${settings.edgeMetricsUri}', '$_error') : l.edgeUnavailable,
                actions: [
                  if (session.isAdmin)
                    FilledButton(onPressed: () => settings.edgeDemo = true, child: Text(l.useDemoData)),
                  OutlinedButton(onPressed: _tick, child: Text(l.retry)),
                ],
              ),
            ),
          ],
        ),
      );
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
              _error != null
                  ? Health.down
                  : (m == null ? Health.pending : (settings.edgeDemo ? Health.unknown : Health.up)),
              label: _error != null
                  ? l.edgeStale
                  : (settings.edgeDemo ? l.edgeDemoLabel : (m == null ? null : l.edgeLive)),
            ),
            if (technical || settings.edgeDemo)
              Text(
                settings.edgeDemo ? l.edgeSynthetic : settings.edgeMetricsUri.toString(),
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
                _cpu,
                (v) => f.percent(v, 1),
                maxY: 100,
                level: (usageLevel(m.cpu), l.levelName(usageLevel(m.cpu))),
              ),
              _MetricTile(
                l.readingMemory,
                f.percent(m.mem, technical ? 1 : 0),
                _mem,
                (v) => f.percent(v, 1),
                maxY: 100,
                level: (usageLevel(m.mem), l.levelName(usageLevel(m.mem))),
                sub: m.memUsedMb != null && m.memTotalMb != null
                    ? '${f.decimal(m.memUsedMb! / 1024)} / ${f.decimal(m.memTotalMb! / 1024)} GB'
                    : null,
              ),
              if (m.tempC != null)
                _MetricTile(
                  l.readingTemperature,
                  f.temperature(m.tempC!, technical ? 1 : 0),
                  _temp,
                  (v) => f.temperature(v, 1),
                  maxY: 100,
                  color: p4.amber,
                  level: (temperatureLevel(m.tempC!), l.levelName(temperatureLevel(m.tempC!), temperature: true)),
                ),
              if (m.inferenceMs != null)
                _MetricTile(
                  l.metricInference,
                  '${f.decimal(m.inferenceMs!, technical ? 1 : 0)} ms',
                  _inf,
                  (v) => '${f.decimal(v)} ms',
                  color: p4.blue,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TileGrid(
            minWidth: 220,
            children: [
              if (m.disk != null) _Fact(l.factDisk, f.percent(m.disk!), progress: m.disk! / 100),
              // Load average means little without knowing the core count: technical users only.
              if (m.load != null && technical) _Fact(l.factLoad, m.load!.map((e) => f.decimal(e, 2)).join('  ')),
              if (m.uptime != null) _Fact(l.factUptime, _uptime(m.uptime!)),
            ],
          ),
        ],
      ],
    );
  }

  static String _uptime(Duration d) {
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    return days > 0 ? '${days}d ${h}h ${m}m' : '${h}h ${m}m';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, this.history, this.format, {this.maxY, this.sub, this.color, this.level});

  final String label;
  final String value;
  final List<double> history;
  final String Function(double) format;
  final double? maxY;
  final String? sub;
  final Color? color;

  /// How the reading compares with normal, and that in words.
  final (Level, String)? level;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
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
          Sparkline(values: history, format: format, maxY: maxY, color: color, capacity: _capacity),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(context.l10n.sparkStart, style: p4.body(size: 11, color: p4.muted)),
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
  const _Fact(this.label, this.value, {this.progress});

  final String label;
  final String value;
  final double? progress;

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
                color: levelColor(p4, usageLevel(progress! * 100)),
                backgroundColor: p4.bg3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
