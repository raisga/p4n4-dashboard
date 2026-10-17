import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/api_error.dart';
import '../api/inference.dart';
import '../api/mqtt_publish.dart';
import '../api/telemetry.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'sparkline.dart';

/// A section of the Device tab: a title, a line on what it's for, and actions.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, this.trailing, required this.child});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: p4.display(size: 18)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: p4.body(size: 13, color: p4.muted)),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Live sensor readings from p4n4-api's stream, one tile per device and
/// sensor; a tile opens that sensor's history. Followed only while the tab
/// shows. Viewers don't see it at all when the deployment has no readings to
/// give (no MQTT, an API without telemetry).
class SensorsPanel extends StatefulWidget {
  const SensorsPanel({super.key, required this.active, this.stream});

  final bool active;

  /// The live stream; [streamTelemetry] unless a test passes its own.
  final Stream<TelemetryEvent> Function(Uri api)? stream;

  @override
  State<SensorsPanel> createState() => _SensorsPanelState();
}

class _SensorsPanelState extends State<SensorsPanel> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  static const _minBackoff = Duration(seconds: 2);
  static const _maxBackoff = Duration(seconds: 30);

  /// The latest reading of each `device/sensor`, in the order they first came.
  final _latest = <String, SensorReading>{};
  StreamSubscription<TelemetryEvent>? _sub;
  Timer? _retry;
  Duration _backoff = _minBackoff;
  Uri? _api;
  bool? _mqtt;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) {
      _api = api;
      _latest.clear();
      _disconnect();
    }
    _follow();
  }

  @override
  void didUpdateWidget(SensorsPanel old) {
    super.didUpdateWidget(old);
    _follow();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  /// Connected while the tab shows, else not.
  void _follow() {
    if (!widget.active) return _disconnect();
    if (_sub == null && _retry == null) _connect();
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
  }

  void _connect() {
    _retry = null;
    final stream = widget.stream ?? (Uri api) => streamTelemetry(api);
    _sub = stream(_api!).listen(
      (e) {
        _backoff = _minBackoff;
        setState(() {
          _error = null;
          switch (e) {
            case TelemetryStatus(:final mqtt):
              _mqtt = mqtt;
            case TelemetryReading(:final reading):
              _mqtt = true;
              _latest['${reading.device}/${reading.sensor}'] = reading;
            case TelemetryDropped():
              break;
          }
        });
      },
      onError: (Object e) => _lost(e),
      onDone: () => _lost(null),
      cancelOnError: true,
    );
  }

  /// The stream ended or failed: tries again later, backing off, while shown.
  void _lost(Object? error) {
    _sub = null;
    if (!mounted) return;
    setState(() => _error = error ?? _error);
    if (!widget.active) return;
    _retry = Timer(_backoff, _connect);
    _backoff = Duration(milliseconds: min(_backoff.inMilliseconds * 2, _maxBackoff.inMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    final technical = SessionScope.of(context).isTechnical;
    final error = _error;
    // Viewers only get it once there's something to show.
    if (!technical && _latest.isEmpty) return const SizedBox.shrink();
    final status = switch ((error, _mqtt)) {
      _ when _latest.isNotEmpty && error == null => null,
      (final e?, _) => l.sensorsUnavailable('$e'),
      (_, false) => l.sensorsNoBroker,
      (_, true) => l.sensorsWaiting,
      _ => l.signInConnecting,
    };
    return _Section(
      title: l.sensorsTitle,
      subtitle: l.sensorsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) Text(status, style: p4.body(size: 13, color: error != null ? p4.warn : p4.muted)),
          if (_latest.isNotEmpty) ...[
            if (status != null) const SizedBox(height: 10),
            TileGrid(
              minWidth: 220,
              children: [for (final r in _latest.values) _SensorTile(r, onOpen: () => _history(r))],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _history(SensorReading r) => showDialog<void>(
    context: context,
    builder: (_) => _SensorHistory(api: _api!, reading: r),
  );
}

/// The field a sensor's tile shows big: `value` when it sends one, else its first number.
String? _mainField(SensorReading r) {
  final numbers = r.numbers;
  return numbers.containsKey('value') ? 'value' : numbers.keys.firstOrNull;
}

class _SensorTile extends StatelessWidget {
  const _SensorTile(this.reading, {required this.onOpen});

  final SensorReading reading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final f = context.formats;
    final l = context.l10n;
    final main = _mainField(reading);
    final numbers = reading.numbers;
    final unit = reading.unit;
    final others = [
      for (final MapEntry(:key, :value) in numbers.entries)
        if (key != main) '$key ${f.decimal(value, value is int ? 0 : 1)}',
      // Words a sensor sends (`"state": "open"`), but not its unit
      for (final MapEntry(:key, :value) in reading.fields.entries)
        if (value is String && key != 'unit') '$key $value' else if (value is bool) '$key ${value ? '✓' : '✗'}',
    ];
    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: main == null ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reading.sensor,
                overflow: TextOverflow.ellipsis,
                style: p4.body(size: 14, color: p4.muted, weight: FontWeight.w500),
              ),
              Text(reading.device, overflow: TextOverflow.ellipsis, style: p4.mono(size: 11, spacing: 0)),
              const SizedBox(height: 6),
              if (main != null)
                Text(
                  '${f.decimal(numbers[main]!, numbers[main] is int ? 0 : 1)}${unit == null ? '' : ' $unit'}',
                  style: p4.display(size: 24, weight: FontWeight.w800, spacing: -0.6),
                ),
              if (others.isNotEmpty)
                Text(
                  others.join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: p4.body(size: 12, color: p4.muted),
                ),
              const SizedBox(height: 4),
              Text(l.sensorReadAt(f.clock(reading.at, seconds: true)), style: p4.body(size: 11, color: p4.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far back a sensor's history goes, and the window each point averages.
enum _Range {
  hour('-1h', '1m'),
  day('-24h', '15m'),
  week('-7d', '2h');

  const _Range(this.start, this.every);

  final String start;
  final String every;
}

/// One sensor's main field over the last hour, day or week, from InfluxDB.
class _SensorHistory extends StatefulWidget {
  const _SensorHistory({required this.api, required this.reading});

  final Uri api;
  final SensorReading reading;

  @override
  State<_SensorHistory> createState() => _SensorHistoryState();
}

class _SensorHistoryState extends State<_SensorHistory> {
  var _range = _Range.hour;
  List<TelemetryPoint>? _points;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final range = _range;
    setState(() {
      _points = null;
      _error = null;
    });
    try {
      final points = await fetchTelemetry(
        widget.api,
        device: widget.reading.device,
        sensor: widget.reading.sensor,
        field: _mainField(widget.reading),
        start: range.start,
        every: range.every,
      );
      if (mounted && range == _range) setState(() => _points = points);
    } catch (e) {
      if (mounted && range == _range) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final r = widget.reading;
    final points = [
      for (final p in _points ?? const <TelemetryPoint>[])
        if (p.value is num) p,
    ];
    final values = [for (final p in points) (p.value as num).toDouble()];
    final unit = r.unit == null ? '' : ' ${r.unit}';
    return AlertDialog(
      title: Text('${r.sensor} · ${r.device}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<_Range>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: _Range.hour, label: Text(l.rangeHour)),
                ButtonSegment(value: _Range.day, label: Text(l.rangeDay)),
                ButtonSegment(value: _Range.week, label: Text(l.rangeWeek)),
              ],
              selected: {_range},
              onSelectionChanged: (v) {
                _range = v.first;
                _load();
              },
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Text(l.sensorHistoryFailed('$_error'), style: p4.body(size: 13, color: p4.err))
            else if (_points == null)
              const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            else if (values.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(l.sensorHistoryEmpty, style: p4.body(color: p4.muted)),
                ),
              )
            else ...[
              Row(
                children: [
                  Text(l.sensorMin('${f.decimal(values.reduce(min))}$unit'), style: p4.body(size: 13, color: p4.muted)),
                  const SizedBox(width: 16),
                  Text(l.sensorMax('${f.decimal(values.reduce(max))}$unit'), style: p4.body(size: 13, color: p4.muted)),
                ],
              ),
              const SizedBox(height: 10),
              Sparkline(
                values: values,
                format: (v) => '${f.decimal(v)}$unit',
                capacity: max(values.length, 2),
                height: 140,
                label: (i) => _range == _Range.hour ? f.clock(points[i].at) : f.dateTime(points[i].at),
              ),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.done))],
    );
  }
}

/// The inference runner's model and counters, a form to classify values by
/// hand (operators and admins), and what it classified lately. For admins
/// and power users; says so when the deployment has no runner.
class ModelPanel extends StatefulWidget {
  const ModelPanel({super.key, required this.active});

  final bool active;

  @override
  State<ModelPanel> createState() => _ModelPanelState();
}

class _ModelPanelState extends State<ModelPanel> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  Uri? _api;
  RunnerInfo? _runner;
  List<InferenceResult>? _recent;
  Object? _error;
  bool _loading = false;

  final _values = TextEditingController();
  InferenceResult? _result;
  String? _classifyError;
  bool _classifying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) {
      _api = api;
      _runner = null;
      _recent = null;
      _result = null;
      if (widget.active) _load();
    }
  }

  @override
  void didUpdateWidget(ModelPanel old) {
    super.didUpdateWidget(old);
    // Fresh counters each time the tab is opened.
    if (widget.active && !old.active) _load();
  }

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api!;
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final runner = await fetchRunner(api);
      List<InferenceResult>? recent;
      try {
        recent = await fetchInferenceResults(api);
      } catch (_) {
        recent = null; // no InfluxDB: the model card still helps
      }
      if (!mounted || api != _api) return;
      setState(() {
        _runner = runner;
        _recent = recent;
        _error = null;
      });
    } catch (e) {
      if (mounted && api == _api) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _classify() async {
    final values = parseFeatures(_values.text);
    if (values == null) return setState(() => _classifyError = l.classifyNotNumbers);
    setState(() {
      _classifying = true;
      _classifyError = null;
      _result = null;
    });
    try {
      final result = await classify(_api!, values);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _classifyError = '$e');
    } finally {
      if (mounted) setState(() => _classifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final runner = _runner;
    final error = _error;
    final f = context.formats;
    final refresh = RefreshButton(busy: _loading, onPressed: _load, tooltip: l.refreshStatus);
    if (runner == null) {
      return _Section(
        title: l.modelTitle,
        trailing: refresh,
        child: Text(switch (error) {
          null => l.signInConnecting,
          ApiException(code: 'runner_unavailable') => l.modelNoRunner,
          _ => l.modelFailed('$error'),
        }, style: p4.body(size: 13, color: error == null ? p4.muted : p4.warn)),
      );
    }
    final expected = runner.expectedFeatures;
    final count = expected == null ? null : parseFeatures(_values.text)?.length;
    return _Section(
      title: l.modelTitle,
      subtitle: l.modelSubtitle,
      trailing: refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagBadge(runner.backend, color: runner.backend == 'mock' ? p4.warn : p4.blue),
                    if (runner.modelFile != null) Text(runner.modelFile!, style: p4.mono(size: 12, spacing: 0)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    if (runner.inferenceCount != null) _fact(l.modelInferences, '${runner.inferenceCount}'),
                    if (runner.lastLatencyMs != null)
                      _fact(l.modelLastLatency, '${f.decimal(runner.lastLatencyMs!)} ms'),
                    if (runner.lastInferenceAt != null) _fact(l.modelLastAt, f.dateTime(runner.lastInferenceAt!)),
                    if (runner.mqttConnected != null)
                      _fact('MQTT', runner.mqttConnected! ? l.healthOnline : l.healthOffline),
                    if (runner.influxOk != null) _fact('InfluxDB', runner.influxOk! ? l.healthOnline : l.healthOffline),
                  ],
                ),
                if (runner.labels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final label in runner.labels) TagBadge(label)]),
                ],
              ],
            ),
          ),
          if (SessionScope.of(context).isTechnical) ...[
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.classifyTitle, style: p4.display(size: 15)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _values,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    style: p4.mono(size: 13, color: p4.text, spacing: 0),
                    decoration: InputDecoration(
                      labelText: l.classifyValues,
                      hintText: '0.12, 0.40, 0.33, …',
                      helperText: expected == null ? null : l.classifyExpects(expected, count ?? 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _classifying || _values.text.trim().isEmpty ? null : _classify,
                        icon: _classifying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_arrow, size: 18),
                        label: Text(l.classify),
                      ),
                      const SizedBox(width: 16),
                      if (_result case final r?)
                        Expanded(
                          child: Text(
                            [
                              r.label,
                              if (r.confidence != null) f.percent(r.confidence! * 100, 1),
                              if (r.anomaly != null) l.classifyAnomaly(f.decimal(r.anomaly!, 2)),
                              if (r.latencyMs != null) '${f.decimal(r.latencyMs!)} ms',
                            ].join(' · '),
                            style: p4.display(size: 15, color: p4.ok),
                          ),
                        ),
                    ],
                  ),
                  if (_classifyError case final e?) ...[
                    const SizedBox(height: 8),
                    Text(e, style: p4.mono(size: 12, color: p4.err, spacing: 0)),
                  ],
                ],
              ),
            ),
          ],
          if (_recent case final recent? when recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.modelRecent, style: p4.display(size: 15)),
                  const SizedBox(height: 8),
                  for (final r in recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(
                              r.at == null ? '' : f.dateTime(r.at!),
                              style: p4.body(size: 12, color: p4.muted),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              [?r.device, r.label].join(' · '),
                              overflow: TextOverflow.ellipsis,
                              style: p4.body(size: 13),
                            ),
                          ),
                          if (r.confidence != null)
                            Text(f.percent(r.confidence! * 100), style: p4.mono(size: 12, spacing: 0)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fact(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: p4.body(size: 12, color: p4.muted)),
      Text(value, style: p4.display(size: 15, weight: FontWeight.w700, spacing: -0.2)),
    ],
  );
}

/// Sends one MQTT message, e.g. a command to a device (admins and power
/// users; the API checks the role and the topic).
class CommandPanel extends StatefulWidget {
  const CommandPanel({super.key});

  @override
  State<CommandPanel> createState() => _CommandPanelState();
}

class _CommandPanelState extends State<CommandPanel> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  final _topic = TextEditingController();
  final _payload = TextEditingController();
  var _qos = 0;
  var _retain = false;
  bool _sending = false;

  /// The outcome of the last send: what was sent, or why it wasn't.
  (bool ok, String text)? _outcome;

  @override
  void dispose() {
    _topic.dispose();
    _payload.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final topic = _topic.text.trim();
    setState(() {
      _sending = true;
      _outcome = null;
    });
    try {
      final bytes = await publishMqtt(
        SettingsScope.of(context).apiUri,
        topic,
        _payload.text,
        qos: _qos,
        retain: _retain,
      );
      if (mounted) setState(() => _outcome = (true, l.commandSent(topic, bytes)));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _outcome = (
          false,
          switch (e) {
            // The topic lists are the API's settings: say which, so an admin knows where to look.
            ApiException(code: 'topic_not_allowed', :final requestId) => [
              l.commandTopicNotAllowed(topic),
              if (requestId != null) '($requestId)',
            ].join(' '),
            ApiException(code: 'mqtt_unavailable') => l.commandNoBroker('$e'),
            ApiException(statusCode: 403) => l.commandNotAllowed,
            _ => l.commandFailed('$e'),
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _topic.text.trim().isNotEmpty && !_topic.text.contains(RegExp('[#+]')) && !_sending;
    return _Section(
      title: l.commandTitle,
      subtitle: l.commandSubtitle,
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topic,
              onChanged: (_) => setState(() {}),
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(labelText: l.commandTopic, hintText: 'devices/shelf-01/cmd'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payload,
              minLines: 1,
              maxLines: 5,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(
                labelText: l.commandPayload,
                hintText: '{"action": "reboot"}',
                helperText: l.commandPayloadHelp,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _qos,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final q in [0, 1, 2]) DropdownMenuItem(value: q, child: Text('QoS $q')),
                  ],
                  onChanged: (v) => setState(() => _qos = v ?? 0),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(value: _retain, onChanged: (v) => setState(() => _retain = v ?? false)),
                    Text(l.commandRetain, style: p4.body(size: 14)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: ready ? _send : null,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 18),
                  label: Text(l.sendTooltip),
                ),
              ],
            ),
            if (_outcome case (final ok, final text)) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ok ? Icons.check_circle_outline : Icons.block, size: 18, color: ok ? p4.ok : p4.err),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text, style: p4.body(size: 13, color: ok ? p4.text : p4.err)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
