import 'dart:async';

import 'package:flutter/material.dart';

import '../api/edge_metrics.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
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
    final admin = SessionScope.of(context).isAdmin;
    final m = _latest;

    final header = SectionHeader(
      tag: 'edge system',
      title: const StackName('edge', size: 24),
      trailing: admin
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DEMO', style: p4.mono()),
                const SizedBox(width: 8),
                Switch(value: settings.edgeDemo, onChanged: (v) => settings.edgeDemo = v),
              ],
            )
          : null,
    );

    if (m == null && _error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            header,
            Expanded(
              child: EmptyState(
                icon: Icons.sensors_off_outlined,
                title: 'No metrics from edge device',
                message: admin
                    ? 'GET ${settings.edgeMetricsUri} failed:\n$_error\n\n'
                          'Point the metrics URL at an endpoint returning the JSON described in the README, '
                          'or turn on demo data to preview the dashboard.'
                    : 'Device readings are unavailable right now. Try again shortly.',
                actions: [
                  if (admin)
                    FilledButton(onPressed: () => settings.edgeDemo = true, child: const Text('USE DEMO DATA')),
                  OutlinedButton(onPressed: _tick, child: const Text('RETRY')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusIndicator(
                      _error != null
                          ? Health.down
                          : (m == null ? Health.pending : (settings.edgeDemo ? Health.unknown : Health.up)),
                      label: _error != null ? 'stale' : (settings.edgeDemo ? 'demo data' : null),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        settings.edgeDemo
                            ? 'synthetic random walk'
                            : (admin ? settings.edgeMetricsUri.toString() : 'live readings'),
                        overflow: TextOverflow.ellipsis,
                        style: p4.mono(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (m == null)
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: p4.accent)),
                  )
                else ...[
                  _grid([
                    _MetricTile(
                      'CPU',
                      '${m.cpu.toStringAsFixed(1)}%',
                      _cpu,
                      (v) => '${v.toStringAsFixed(1)}%',
                      maxY: 100,
                    ),
                    _MetricTile(
                      'Memory',
                      '${m.mem.toStringAsFixed(1)}%',
                      _mem,
                      (v) => '${v.toStringAsFixed(1)}%',
                      maxY: 100,
                      sub: m.memUsedMb != null && m.memTotalMb != null
                          ? '${_gb(m.memUsedMb!)} / ${_gb(m.memTotalMb!)} GB'
                          : null,
                    ),
                    if (m.tempC != null)
                      _MetricTile(
                        'SoC temp',
                        '${m.tempC!.toStringAsFixed(1)}°C',
                        _temp,
                        (v) => '${v.toStringAsFixed(1)}°C',
                        maxY: 100,
                        color: p4.amber,
                      ),
                    if (m.inferenceMs != null)
                      _MetricTile(
                        'Inference',
                        '${m.inferenceMs!.toStringAsFixed(1)} ms',
                        _inf,
                        (v) => '${v.toStringAsFixed(1)} ms',
                        color: p4.blue,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _grid([
                    if (m.disk != null) _Fact('Disk', '${m.disk!.toStringAsFixed(1)}%', progress: m.disk! / 100),
                    if (m.load != null) _Fact('Load avg', m.load!.map((e) => e.toStringAsFixed(2)).join('  ')),
                    if (m.uptime != null) _Fact('Uptime', _uptime(m.uptime!)),
                  ], minWidth: 220),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _gb(double mb) => (mb / 1024).toStringAsFixed(1);

  static String _uptime(Duration d) {
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    return days > 0 ? '${days}d ${h}h ${m}m' : '${h}h ${m}m';
  }

  Widget _grid(List<Widget> children, {double minWidth = 280}) => LayoutBuilder(
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

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, this.history, this.format, {this.maxY, this.sub, this.color});

  final String label;
  final String value;
  final List<double> history;
  final String Function(double) format;
  final double? maxY;
  final String? sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: p4.mono(spacing: 0.12)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: p4.display(size: 30, weight: FontWeight.w800, spacing: -1)),
              if (sub != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(sub!, overflow: TextOverflow.ellipsis, style: p4.mono()),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Sparkline(values: history, format: format, maxY: maxY, color: color, capacity: _capacity),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('−2 min', style: p4.mono(size: 9)),
              const Spacer(),
              Text('now', style: p4.mono(size: 9)),
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
          Text(label.toUpperCase(), style: p4.mono(spacing: 0.12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: p4.mono(size: 16, color: p4.text, weight: FontWeight.w600, spacing: 0),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress!.clamp(0, 1),
              minHeight: 4,
              color: p4.accent,
              backgroundColor: p4.bg3,
            ),
          ],
        ],
      ),
    );
  }
}
