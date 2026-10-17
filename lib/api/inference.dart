import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// The edge inference runner through p4n4-api (`/api/v1/inference`): its
/// model, on-demand classification (operators and admins) and the results its
/// pipeline stored.
class RunnerInfo {
  const RunnerInfo({
    required this.backend,
    this.modelFile,
    this.labels = const [],
    this.expectedFeatures,
    this.inferenceCount,
    this.lastInferenceAt,
    this.lastLatencyMs,
    this.mqttConnected,
    this.influxOk,
  });

  factory RunnerInfo.fromJson(Map<String, dynamic> j) => RunnerInfo(
    backend: j['backend'] as String? ?? 'unknown',
    modelFile: j['model_file'] as String?,
    labels: [...?(j['labels'] as List?)?.map((l) => '$l')],
    expectedFeatures: (j['expected_features'] as num?)?.toInt(),
    inferenceCount: (j['inference_count'] as num?)?.toInt(),
    lastInferenceAt: DateTime.tryParse(j['last_inference_at'] as String? ?? '')?.toLocal(),
    lastLatencyMs: (j['last_latency_ms'] as num?)?.toDouble(),
    mqttConnected: j['mqtt_connected'] as bool?,
    influxOk: j['influxdb_ok'] as bool?,
  );

  /// `edge-impulse`, `onnx` or `mock`.
  final String backend;
  final String? modelFile;
  final List<String> labels;

  /// How many values a classification takes, when the model says.
  final int? expectedFeatures;
  final int? inferenceCount;
  final DateTime? lastInferenceAt;
  final double? lastLatencyMs;

  /// Whether the runner's own pipeline reaches MQTT and InfluxDB; null when it doesn't say.
  final bool? mqttConnected;
  final bool? influxOk;
}

/// A classification's outcome, now or stored by the runner's pipeline.
class InferenceResult {
  const InferenceResult({
    required this.label,
    this.confidence,
    this.anomaly,
    this.latencyMs,
    this.device,
    this.backend,
    this.at,
  });

  factory InferenceResult.fromJson(Map<String, dynamic> j) => InferenceResult(
    label: j['label'] as String? ?? '?',
    confidence: (j['confidence'] as num?)?.toDouble(),
    anomaly: (j['anomaly_score'] as num?)?.toDouble(),
    latencyMs: (j['latency_ms'] as num?)?.toDouble(),
    device: j['device'] as String?,
    backend: j['backend'] as String?,
    at: DateTime.tryParse((j['timestamp'] ?? j['time']) as String? ?? '')?.toLocal(),
  );

  final String label;

  /// 0–1.
  final double? confidence;
  final double? anomaly;
  final double? latencyMs;
  final String? device;
  final String? backend;
  final DateTime? at;
}

Future<http.Response> _guard(Future<http.Response> request, Duration timeout) async {
  try {
    return await request.timeout(timeout);
  } on TimeoutException {
    throw const ApiException('No answer in time.', statusCode: 504);
  } on http.ClientException catch (e) {
    throw ApiException(e.message);
  }
}

/// The runner's backend, model and counters. `503 runner_unavailable` when
/// the deployment has no runner, or it's down.
Future<RunnerInfo> fetchRunner(Uri api) async {
  final res = await _guard(http.get(api.resolve('api/v1/inference/runner')), const Duration(seconds: 8));
  return RunnerInfo.fromJson((apiBody(res) as Map).cast());
}

/// Classifies one feature vector (operators and admins). The result isn't
/// stored or published. `422 wrong_feature_count` when the model takes
/// another number of values.
Future<InferenceResult> classify(Uri api, List<double> values) async {
  final res = await _guard(
    http.post(
      api.resolve('api/v1/inference'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'values': values, 'device': 'dashboard'}),
    ),
    const Duration(seconds: 20),
  );
  return InferenceResult.fromJson((apiBody(res) as Map).cast());
}

/// What the runner's pipeline stored since [start], newest first.
Future<List<InferenceResult>> fetchInferenceResults(Uri api, {String start = '-24h', int limit = 10}) async {
  final res = await _guard(
    http.get(api.resolve('api/v1/inference/results').replace(queryParameters: {'start': start, 'limit': '$limit'})),
    const Duration(seconds: 10),
  );
  return [for (final r in ((apiBody(res) as Map)['results'] as List).cast<Map>()) InferenceResult.fromJson(r.cast())];
}

/// The numbers in [text], however they're separated (commas, spaces, new
/// lines), or null if anything in it isn't one.
List<double>? parseFeatures(String text) {
  final parts = text.split(RegExp(r'[\s,;]+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final values = parts.map(double.tryParse).toList();
  return values.any((v) => v == null || !v.isFinite) ? null : values.cast<double>();
}
