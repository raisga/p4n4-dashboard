import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// Sends one MQTT message through p4n4-api (`POST /api/v1/mqtt/publish`,
/// operators and admins), e.g. a command to a device. The API keeps people to
/// its allowed topics (`403 topic_not_allowed`: by default anything but
/// `sensors/#` and `inference/#`) and logs every message in the audit log.
///
/// [payload] goes as it is, unless it's valid JSON, which goes as JSON. With
/// [qos] 1 or 2 the answer means the broker has it. Returns the bytes sent.
Future<int> publishMqtt(Uri api, String topic, String payload, {int qos = 0, bool retain = false}) async {
  Object? body;
  try {
    body = jsonDecode(payload);
  } on FormatException {
    body = payload;
  }
  final http.Response res;
  try {
    res = await http
        .post(
          api.resolve('api/v1/mqtt/publish'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'topic': topic.trim(), 'payload': body, 'qos': qos, 'retain': retain}),
        )
        .timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw const ApiException('No answer in time.', statusCode: 504);
  } on http.ClientException catch (e) {
    throw ApiException(e.message);
  }
  return ((apiBody(res) as Map)['bytes'] as num?)?.toInt() ?? 0;
}
