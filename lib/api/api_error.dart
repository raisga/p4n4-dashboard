import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// The header p4n4-api logs each request under. [AuthClient] sends one with
/// every API call and the API echoes it, so an error someone reports can be
/// found in the server's log.
const requestIdHeader = 'X-Request-ID';

final _random = Random.secure();

/// A new request ID: 16 hex digits, within what p4n4-api accepts.
String newRequestId() => [for (var i = 0; i < 8; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

/// The ID p4n4-api answered [res] under, if it said.
String? requestIdOf(http.BaseResponse res) => res.headers[requestIdHeader.toLowerCase()];

/// A request p4n4-api turned down, or one that never got an answer. Each
/// client's own exception extends it, so screens can show any of them alike.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.requestId});

  /// From [res], an error answer: the API's message (the first field's for a
  /// validation error), else [fallback], else the status.
  factory ApiException.from(http.Response res, {String? fallback}) {
    final (code, message) = apiError(res.body);
    return ApiException(
      message ?? fallback ?? 'HTTP ${res.statusCode}',
      statusCode: res.statusCode,
      code: code,
      requestId: requestIdOf(res),
    );
  }

  final String message;

  /// Null when the API couldn't be reached.
  final int? statusCode;

  /// The API's error code, e.g. `topic_not_allowed`, `runner_unavailable`.
  final String? code;

  /// The ID the API logged the request under, to quote in a report.
  final String? requestId;

  @override
  String toString() => requestId == null ? message : '$message (request $requestId)';
}

/// The code and message of p4n4-api's error body
/// (`{"error": {"code", "message", "fields"}}`); for a validation error, the
/// first field's message, which is enough to act on.
(String?, String?) apiError(String body) {
  try {
    final error = (jsonDecode(body) as Map)['error'] as Map;
    final fields = error['fields'];
    final message = fields is List && fields.isNotEmpty ? (fields.first as Map)['message'] : error['message'];
    return (error['code'] as String?, message as String?);
  } catch (_) {
    return (null, null);
  }
}

/// The decoded body of a success (null when empty), or an [ApiException].
Object? apiBody(http.Response res) {
  if (res.statusCode >= 200 && res.statusCode < 300) return res.body.isEmpty ? null : jsonDecode(res.body);
  throw ApiException.from(res);
}
