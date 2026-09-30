import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// One snapshot of edge-device system metrics.
///
/// Expected JSON (all fields optional except `cpu_percent` / `mem_percent`):
/// ```json
/// {"cpu_percent": 23.1, "mem_percent": 61.0, "mem_used_mb": 2480, "mem_total_mb": 4096,
///  "disk_percent": 44.2, "temp_c": 51.3, "uptime_s": 86400, "load": [0.4, 0.5, 0.6],
///  "inference_ms": 12.5}
/// ```
class EdgeMetrics {
  const EdgeMetrics({
    required this.cpu,
    required this.mem,
    this.memUsedMb,
    this.memTotalMb,
    this.disk,
    this.tempC,
    this.uptime,
    this.load,
    this.inferenceMs,
  });

  final double cpu;
  final double mem;
  final double? memUsedMb;
  final double? memTotalMb;
  final double? disk;
  final double? tempC;
  final Duration? uptime;
  final List<double>? load;
  final double? inferenceMs;

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  factory EdgeMetrics.fromJson(Map<String, dynamic> j) => EdgeMetrics(
    cpu: _num(j['cpu_percent']) ?? 0,
    mem: _num(j['mem_percent']) ?? 0,
    memUsedMb: _num(j['mem_used_mb']),
    memTotalMb: _num(j['mem_total_mb']),
    disk: _num(j['disk_percent']),
    tempC: _num(j['temp_c']),
    uptime: j['uptime_s'] is num ? Duration(seconds: (j['uptime_s'] as num).toInt()) : null,
    // Non-numeric entries are dropped rather than failing the whole snapshot.
    load: switch ((j['load'] is List ? j['load'] as List : const []).map(_num).nonNulls.toList()) {
      final l when l.isNotEmpty => l,
      _ => null,
    },
    inferenceMs: _num(j['inference_ms']),
  );
}

Future<EdgeMetrics> fetchEdgeMetrics(Uri uri) async {
  final res = await http.get(uri).timeout(const Duration(seconds: 4));
  if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', uri);
  return EdgeMetrics.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

/// Random-walk generator used when demo mode is on.
class DemoMetrics {
  final _rng = Random();
  double _cpu = 25, _mem = 55, _temp = 48, _inf = 14;
  final _start = DateTime.now().subtract(const Duration(hours: 31, minutes: 12));

  double _walk(double v, double step, double lo, double hi) => (v + (_rng.nextDouble() - 0.5) * step).clamp(lo, hi);

  EdgeMetrics next() {
    _cpu = _walk(_cpu, 14, 3, 97);
    _mem = _walk(_mem, 3, 30, 90);
    _temp = _walk(_temp + (_cpu - 40) * 0.01, 1.5, 38, 80);
    _inf = _walk(_inf, 3, 6, 40);
    return EdgeMetrics(
      cpu: _cpu,
      mem: _mem,
      memUsedMb: 4096 * _mem / 100,
      memTotalMb: 4096,
      disk: 44.2,
      tempC: _temp,
      uptime: DateTime.now().difference(_start),
      load: [_cpu / 25, _cpu / 28, _cpu / 30],
      inferenceMs: _inf,
    );
  }
}
