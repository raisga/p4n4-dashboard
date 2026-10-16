/// The demo's Charts tab: a static preview has no Grafana to embed, so the
/// project describes its dashboard's panels (`charts` in `demo/store.json`)
/// and the app draws them from the recorded series.
///
/// ```json
/// {"title": "Store", "subtitle": "...", "currency": "$",
///  "ranges": [{"id": "today", "label": "Today", "days": 1}, {"id": "7d", "label": "Last 7 days", "days": 7}],
///  "sections": [{"title": "Activity", "panels": [<panel>, ...]}]}
/// ```
///
/// Panels (`color`s are hex; `labels` name a series' keys):
///
/// - `stat`: one number, `agg` `count`, `sum` (of the values), `mean` or
///   `ratio` (count ÷ the counts of the `per` series), in `unit` `none`,
///   `currency` or `percent`, with its trend
/// - `timeline`: a series' count per hour (one day) or per day
/// - `funnel`: `stages`, each a series' count, against the first
/// - `bars`: several series' counts by key, side by side
/// - `breakdown`: a series' count by key, optionally a `colors` map and an `order`
/// - `share`: each key's part of a series' values
/// - `alerts`: the latest alerts of the feed, with `columns` (time, code, title, zone)
/// - `text`: Markdown
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/rich_message.dart';
import '../widgets/sparkline.dart';
import 'demo_store.dart';

// ── the numbers ──────────────────────────────────────────────────────────────

/// [store]'s charts over range [rangeId], each panel with its `data`; null
/// when the project has none.
Map<String, dynamic>? computeCharts(DemoStore store, String? rangeId) {
  final spec = store.charts;
  if (spec == null) return null;
  final ranges = [for (final r in spec['ranges'] as List) (r as Map).cast<String, dynamic>()];
  final range = ranges.firstWhere((r) => r['id'] == rangeId, orElse: () => ranges.first);
  final span = (range['days'] as num).toInt();
  final hours = _openHours(store);
  Map<String, dynamic> panel(Map<String, dynamic> p) => {...p, 'data': _data(store, p, span, hours)};
  return {
    ...spec,
    'range': range['id'],
    'sections': [
      for (final s in spec['sections'] as List)
        {
          ...(s as Map).cast<String, dynamic>(),
          'panels': [for (final p in s['panels'] as List) panel((p as Map).cast())],
        },
    ],
  };
}

/// The hours a day's chart spans: around those with anything in yesterday's series.
(int, int) _openHours(DemoStore store) {
  var (lo, hi) = (23, 0);
  for (final entries in store.dayFor(1).series.values) {
    for (final e in entries) {
      final h = (e[0] as num) ~/ 3600;
      (lo, hi) = (math.min(lo, h), math.max(hi, h));
    }
  }
  return lo > hi ? (0, 23) : (math.max(0, lo - 1), math.min(23, hi + 1));
}

Object? _data(DemoStore store, Map<String, dynamic> p, int span, (int, int) hours) {
  List<(DateTime, List<dynamic>)> of(String name) => store.entries(name, span: span);
  num value(List<dynamic> e) => e.length > 2 && e[2] is num ? e[2] as num : 1;
  Map<String, num> byKey(String name, {bool sum = false}) {
    final out = <String, num>{};
    for (final (_, e) in of(name)) {
      if (e.length < 2 || e[1] is! String) continue;
      final add = sum ? value(e) : 1;
      out.update(e[1] as String, (v) => v + add, ifAbsent: () => add);
    }
    return out;
  }

  /// [name] per hour (one day) or per day, as `[[iso time, value]]`.
  List<List<Object>> buckets(String name, {bool sum = false}) {
    final today = store.midnight(0);
    final slots = span == 1
        ? [for (var h = hours.$1; h <= hours.$2; h++) today.add(Duration(hours: h))]
        : [for (var back = span - 1; back >= 0; back--) store.midnight(back)];
    final values = List<num>.filled(slots.length, 0);
    for (final (at, e) in of(name)) {
      final i = span == 1 ? at.hour - hours.$1 : slots.indexWhere((d) => d.day == at.day && d.month == at.month);
      if (i >= 0 && i < values.length) values[i] += sum ? value(e) : 1;
    }
    return [
      for (final (i, slot) in slots.indexed) [slot.toIso8601String(), values[i]],
    ];
  }

  switch (p['type']) {
    case 'stat':
      final name = p['series'] as String;
      final entries = of(name);
      final num? v = switch (p['agg']) {
        'sum' => entries.fold<num>(0, (a, x) => a + value(x.$2)),
        'mean' => entries.isEmpty ? null : entries.fold<num>(0, (a, x) => a + value(x.$2)) / entries.length,
        'ratio' => switch ([for (final s in (p['per'] as List?) ?? const []) of(s as String).length]
            .fold(0, (a, b) => a + b)) {
          0 => null,
          final per => entries.length / per,
        },
        _ => entries.length,
      };
      // Up to now: the hours still to come would read as a drop.
      final current = store.now;
      final trend = p['agg'] == 'sum' || p['agg'] == null || p['agg'] == 'count'
          ? [
              for (final b in buckets(name, sum: p['agg'] == 'sum'))
                if (!DateTime.parse(b[0] as String).isAfter(current)) b[1],
            ]
          : null;
      return {'value': v, 'trend': trend};
    case 'timeline':
      return {'unit': span == 1 ? 'hour' : 'day', 'buckets': buckets(p['series'] as String)};
    case 'funnel':
      return [for (final s in p['stages'] as List) of((s as Map)['series'] as String).length];
    case 'bars':
      return [for (final s in p['series'] as List) byKey((s as Map)['series'] as String)];
    case 'breakdown':
      return byKey(p['series'] as String, sum: p['agg'] == 'sum');
    case 'share':
      final weights = byKey(p['series'] as String, sum: true);
      final total = weights.values.fold<num>(0, (a, b) => a + b);
      return {for (final MapEntry(:key, :value) in weights.entries) key: total == 0 ? 0 : value / total};
    case 'alerts':
      final from = store.midnight(span - 1);
      return [
        for (final i in store.items(span: span).where((i) => i.alert && !i.at.isBefore(from)).take(100))
          {
            'time': i.at.toIso8601String(),
            'code': i.badge,
            'title': i.json['title'],
            'zone': (i.json['meta'] as Map?)?['zone_id'],
          },
      ];
  }
  return null;
}

// ── the tab ──────────────────────────────────────────────────────────────────

/// The Charts tab of the demo build, in place of embedded Grafana.
class DemoChartsTab extends StatefulWidget {
  const DemoChartsTab({super.key});

  @override
  State<DemoChartsTab> createState() => _DemoChartsTabState();
}

class _DemoChartsTabState extends State<DemoChartsTab> {
  Map<String, dynamic>? _charts;
  String? _range;
  Object? _error;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_charts == null && _error == null) _load();
    // Today keeps growing.
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = SettingsScope.of(context).apiUri;
    try {
      final url = api.resolve('api/v1/dashboard/charts').replace(queryParameters: {'range': ?_range});
      final res = await http.get(url);
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', url);
      final charts = (jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        _charts = charts;
        _range = charts['range'] as String?;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charts = _charts;
    if (charts == null) {
      return _error == null ? const LoadingState('') : Center(child: Text('$_error'));
    }
    final p4 = context.p4;
    final ranges = [for (final r in charts['ranges'] as List) (r as Map).cast<String, dynamic>()];
    return PageBody(
      maxWidth: 1400,
      onRefresh: _load,
      children: [
        PageHeader(
          title: charts['title'] as String? ?? '',
          subtitle: charts['subtitle'] as String?,
          trailing: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final r in ranges) ButtonSegment(value: r['id'] as String, label: Text(r['label'] as String)),
            ],
            selected: {_range ?? ranges.first['id'] as String},
            onSelectionChanged: (s) {
              setState(() => _range = s.first);
              _load();
            },
          ),
        ),
        for (final section in charts['sections'] as List) ...[
          if ((section as Map)['title'] case final String title) ...[
            const SizedBox(height: 28),
            Text(title, style: p4.display(size: 17)),
          ],
          const SizedBox(height: 12),
          _Section([for (final p in section['panels'] as List) (p as Map).cast<String, dynamic>()], charts: charts),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// A section's panels: stats in a row of tiles, charts two to a row, tables
/// and text across.
class _Section extends StatelessWidget {
  const _Section(this.panels, {required this.charts});

  final List<Map<String, dynamic>> panels;
  final Map<String, dynamic> charts;

  @override
  Widget build(BuildContext context) {
    final stats = [
      for (final p in panels)
        if (p['type'] == 'stat') p,
    ];
    final wide = [
      for (final p in panels)
        if (p['type'] == 'alerts' || p['type'] == 'text') p,
    ];
    final rest = [
      for (final p in panels)
        if (!stats.contains(p) && !wide.contains(p)) p,
    ];
    Widget card(Map<String, dynamic> p) => _PanelCard(p, currency: charts['currency'] as String? ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stats.isNotEmpty) TileGrid(minWidth: 180, children: [for (final p in stats) card(p)]),
        if (stats.isNotEmpty && rest.isNotEmpty) const SizedBox(height: 12),
        if (rest.isNotEmpty) TileGrid(minWidth: 460, children: [for (final p in rest) card(p)]),
        for (final p in wide) ...[const SizedBox(height: 12), card(p)],
      ],
    );
  }
}

Color _hex(Object? hex, Color fallback) {
  if (hex is! String || !hex.startsWith('#') || hex.length != 7) return fallback;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

class _PanelCard extends StatelessWidget {
  const _PanelCard(this.p, {required this.currency});

  final Map<String, dynamic> p;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final f = context.formats;
    final type = p['type'];
    final title = p['title'] as String? ?? '';
    final description = p['description'] as String?;
    final color = _hex(p['color'], p4.accent);
    String number(num? v) {
      if (v == null) return '–';
      return switch (p['unit']) {
        'currency' => NumberFormat.currency(locale: f.locale, symbol: currency, decimalDigits: 2).format(v),
        'percent' => f.percent(v * 100),
        _ => NumberFormat.decimalPattern(f.locale).format(v),
      };
    }

    final Widget body = switch (type) {
      'stat' => _stat(context, number, color),
      'timeline' => _Timeline(p['data'] as Map, color: color),
      'funnel' => _funnel(context, color),
      'bars' => _bars(context),
      'breakdown' => _breakdown(context, color),
      'share' => _share(context, color),
      'alerts' => _AlertsTable(p),
      'text' => RichMessage(p['markdown'] as String? ?? '', style: p4.body(size: 13, color: p4.muted)),
      _ => const SizedBox.shrink(),
    };
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(title, style: p4.display(size: 14, weight: FontWeight.w600, spacing: 0)),
              ),
              if (description != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: description,
                  child: Icon(Icons.info_outline, size: 15, color: p4.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String Function(num?) number, Color color) {
    final p4 = context.p4;
    final data = p['data'] as Map;
    final trend = [for (final v in (data['trend'] as List?) ?? const []) (v as num).toDouble()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number(data['value'] as num?), style: p4.display(size: 28, color: p4.heading)),
        if (trend.length > 1) ...[
          const SizedBox(height: 8),
          Sparkline(values: trend, format: (v) => number(v), color: color, capacity: trend.length, height: 36),
        ],
      ],
    );
  }

  Widget _funnel(BuildContext context, Color color) {
    final f = context.formats;
    final stages = p['stages'] as List;
    final values = [for (final v in p['data'] as List) v as num];
    final first = values.isEmpty || values.first == 0 ? 1 : values.first;
    final outcome = _hex(p['outcome'], color);
    return Column(
      children: [
        for (final (i, s) in stages.indexed)
          _BarRow(
            label: (s as Map)['label'] as String,
            fraction: values[i] / first,
            value:
                '${NumberFormat.decimalPattern(f.locale).format(values[i])}'
                '${i == 0 ? '' : '  ·  ${f.percent(values[i] / first * 100)}'}',
            color: i == stages.length - 1 ? outcome : color,
          ),
      ],
    );
  }

  Widget _bars(BuildContext context) {
    final p4 = context.p4;
    final f = context.formats;
    final series = [for (final s in p['series'] as List) (s as Map).cast<String, dynamic>()];
    final data = [for (final d in p['data'] as List) (d as Map).cast<String, num>()];
    final labels = ((p['labels'] as Map?) ?? const {}).cast<String, String>();
    // Keys with nothing in the range are left out.
    final keys = {for (final d in data) ...d.keys}.toList()
      ..sort((a, b) => (data.first[b] ?? 0).compareTo(data.first[a] ?? 0));
    final max = [for (final d in data) ...d.values].fold<num>(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            for (final s in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _hex(s['color'], p4.accent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(s['label'] as String, style: p4.body(size: 12, color: p4.muted)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labels[key] ?? key, style: p4.body(size: 12.5, color: p4.text)),
                const SizedBox(height: 3),
                for (final (i, s) in series.indexed)
                  _Bar(
                    fraction: (data[i][key] ?? 0) / max,
                    color: _hex(s['color'], p4.accent),
                    value: NumberFormat.decimalPattern(f.locale).format(data[i][key] ?? 0),
                    tooltip: '${labels[key] ?? key} · ${s['label']}: ${data[i][key] ?? 0}',
                    thickness: 8,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _breakdown(BuildContext context, Color color) {
    final f = context.formats;
    final data = (p['data'] as Map).cast<String, num>();
    final labels = ((p['labels'] as Map?) ?? const {}).cast<String, String>();
    final colors = ((p['colors'] as Map?) ?? const {}).cast<String, String>();
    final order = [for (final k in (p['order'] as List?) ?? const []) k as String];
    final keys = order.isNotEmpty ? order : (data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!)));
    final max = data.values.fold<num>(1, math.max);
    return Column(
      children: [
        for (final key in keys)
          _BarRow(
            label: labels[key] ?? key,
            fraction: (data[key] ?? 0) / max,
            value: NumberFormat.decimalPattern(f.locale).format(data[key] ?? 0),
            color: _hex(colors[key], color),
          ),
      ],
    );
  }

  Widget _share(BuildContext context, Color color) {
    final f = context.formats;
    final data = (p['data'] as Map).cast<String, num>();
    final labels = ((p['labels'] as Map?) ?? const {}).cast<String, String>();
    final keys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));
    final max = data.values.fold<num>(0.0001, math.max);
    return Column(
      children: [
        for (final key in keys)
          _BarRow(
            label: labels[key] ?? key,
            fraction: data[key]! / max,
            value: f.percent(data[key]! * 100),
            color: color,
          ),
      ],
    );
  }
}

/// A labelled horizontal bar.
class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.fraction, required this.value, required this.color});

  final String label;
  final double fraction;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: p4.body(size: 12.5, color: p4.text)),
          const SizedBox(height: 3),
          _Bar(fraction: fraction, color: color, value: value, tooltip: '$label: $value'),
        ],
      ),
    );
  }
}

/// A bar from the baseline, rounded at its data end, with its value after it.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.value,
    required this.tooltip,
    this.thickness = 12,
  });

  final double fraction;
  final Color color;
  final String value;
  final String tooltip;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: math.max(2, c.maxWidth * fraction.clamp(0, 1)),
                    height: thickness,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: p4.mono(size: 11.5, color: p4.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical bars per hour or per day, each with its tooltip.
class _Timeline extends StatelessWidget {
  const _Timeline(this.data, {required this.color});

  final Map<dynamic, dynamic> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final f = context.formats;
    final hourly = data['unit'] == 'hour';
    final buckets = [
      for (final b in data['buckets'] as List) (DateTime.parse((b as List)[0] as String), (b[1] as num).toDouble()),
    ];
    final max = buckets.fold<double>(1, (m, b) => math.max(m, b.$2));
    String label(DateTime t) => hourly ? DateFormat.H(f.locale).format(t) : DateFormat.E(f.locale).format(t);
    const height = 150.0;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (t, v) in buckets)
                Expanded(
                  child: Tooltip(
                    message: '${hourly ? f.clock(t) : DateFormat.MMMEd(f.locale).format(t)}: ${v.round()}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: math.max(v > 0 ? 3 : 1, height * v / max),
                        decoration: BoxDecoration(
                          color: v > 0 ? color : p4.border,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(height: 1, color: p4.border),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final (i, (t, _)) in buckets.indexed)
              Expanded(
                child: Text(
                  buckets.length <= 8 || i.isEven ? label(t) : '',
                  textAlign: TextAlign.center,
                  style: p4.mono(size: 10, color: p4.muted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AlertsTable extends StatelessWidget {
  const _AlertsTable(this.p);

  final Map<String, dynamic> p;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final f = context.formats;
    final columns = ((p['columns'] as Map?) ?? const {}).cast<String, String>();
    final labels = ((p['labels'] as Map?) ?? const {}).cast<String, String>();
    final colors = ((p['colors'] as Map?) ?? const {}).cast<String, String>();
    final rows = [for (final r in p['data'] as List) (r as Map).cast<String, dynamic>()];
    TextStyle head = p4.body(size: 12, color: p4.muted, weight: FontWeight.w600);
    Widget cell(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6), child: child);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(120),
            1: FlexColumnWidth(1.3),
            2: FlexColumnWidth(2),
            3: FixedColumnWidth(110),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p4.border)),
              ),
              children: [
                for (final k in ['time', 'code', 'title', 'zone']) cell(Text(columns[k] ?? k, style: head)),
              ],
            ),
            for (final r in rows)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p4.border.withValues(alpha: 0.5))),
                ),
                children: [
                  cell(
                    Text(
                      '${DateFormat.MMMd(f.locale).format(DateTime.parse(r['time'] as String).toLocal())} '
                      '${f.clock(DateTime.parse(r['time'] as String).toLocal())}',
                      style: p4.mono(size: 11, color: p4.text),
                    ),
                  ),
                  cell(
                    Text(
                      labels[r['code']] ?? '${r['code'] ?? ''}',
                      style: p4.body(size: 12.5, color: _hex(colors[r['code']], p4.text), weight: FontWeight.w600),
                    ),
                  ),
                  cell(Text('${r['title'] ?? ''}', style: p4.body(size: 12.5, color: p4.text))),
                  cell(Text('${r['zone'] ?? ''}', style: p4.mono(size: 11, color: p4.muted))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
