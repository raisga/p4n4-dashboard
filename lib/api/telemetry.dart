import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';
import 'sse.dart';

/// Sensor readings through p4n4-api (`/api/v1/telemetry`): live from MQTT
/// (`sensors/{device}/{sensor}`) and stored in InfluxDB. Anyone signed in reads them.
class SensorReading {
  const SensorReading({required this.device, required this.sensor, required this.fields, required this.at});

  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
    device: j['device'] as String,
    sensor: j['sensor'] as String,
    fields: ((j['fields'] as Map?) ?? const {}).cast<String, Object?>(),
    at: DateTime.tryParse(j['ts'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );

  final String device;
  final String sensor;

  /// As the device sent them, e.g. `{"value": 23.5, "unit": "C"}`.
  final Map<String, Object?> fields;

  /// When it was measured (or received, if the device didn't say).
  final DateTime at;

  /// The numbers, by field name: what can be charted.
  Map<String, num> get numbers => {
    for (final MapEntry(:key, :value) in fields.entries)
      if (value is num) key: value,
  };

  /// The unit sent next to the value (`unit`), if any.
  String? get unit => switch (fields['unit']) {
    final String u when u.isNotEmpty => u,
    _ => null,
  };
}

/// What the live stream says.
sealed class TelemetryEvent {
  const TelemetryEvent();
}

/// Whether p4n4-api is connected to the MQTT broker; first thing on the stream.
class TelemetryStatus extends TelemetryEvent {
  const TelemetryStatus({required this.mqtt});

  final bool mqtt;
}

class TelemetryReading extends TelemetryEvent {
  const TelemetryReading(this.reading);

  final SensorReading reading;
}

/// Readings this client was too slow for and lost, in all so far.
class TelemetryDropped extends TelemetryEvent {
  const TelemetryDropped(this.count);

  final int count;
}

/// Live readings (`GET /api/v1/telemetry/stream`), optionally for one
/// [device] and/or [sensor], until the listener cancels.
Stream<TelemetryEvent> streamTelemetry(Uri api, {String? device, String? sensor}) async* {
  final query = {'device': ?device, 'sensor': ?sensor};
  final url = api.resolve('api/v1/telemetry/stream').replace(queryParameters: query.isEmpty ? null : query);
  await for (final e in sseGet(url)) {
    switch (e.event) {
      case 'status':
        yield TelemetryStatus(mqtt: (jsonDecode(e.data) as Map)['mqtt'] == true);
      case 'reading':
        yield TelemetryReading(SensorReading.fromJson((jsonDecode(e.data) as Map).cast()));
      case 'dropped':
        yield TelemetryDropped(int.tryParse(e.data) ?? 0);
    }
  }
}

/// One stored value.
typedef TelemetryPoint = ({DateTime at, String? device, String? sensor, String field, Object? value});

/// Stored readings, oldest first (`GET /api/v1/telemetry`): since [start] (a
/// span back from now such as `-1h`), averaged into [every] windows when given.
Future<List<TelemetryPoint>> fetchTelemetry(
  Uri api, {
  String? device,
  String? sensor,
  String? field,
  String start = '-1h',
  String? every,
  int limit = 1000,
}) async {
  final url = api
      .resolve('api/v1/telemetry')
      .replace(
        queryParameters: {
          'device': ?device,
          'sensor': ?sensor,
          'field': ?field,
          'start': start,
          'every': ?every,
          'limit': '$limit',
        },
      );
  final http.Response res;
  try {
    res = await http.get(url).timeout(const Duration(seconds: 10));
  } on TimeoutException {
    throw const ApiException('No answer in time.', statusCode: 504);
  } on http.ClientException catch (e) {
    throw ApiException(e.message);
  }
  final body = (apiBody(res) as Map).cast<String, dynamic>();
  return [
    for (final p in (body['points'] as List).cast<Map>())
      (
        at: DateTime.parse(p['time'] as String).toLocal(),
        device: p['device'] as String?,
        sensor: p['sensor'] as String?,
        field: p['field'] as String,
        value: p['value'],
      ),
  ];
}
