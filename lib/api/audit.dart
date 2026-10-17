import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// One entry in p4n4-api's audit log (`GET /api/v1/audit`, admins only):
/// who changed what, and when. Actions and outcomes are the API's own words
/// (`user.create`, `role normie`), shown as they are.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actor,
    required this.action,
    this.target = '',
    this.outcome = '',
  });

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
    id: j['id'] as int,
    at: DateTime.parse(j['at'] as String).toLocal(),
    actor: j['actor'] as String,
    action: j['action'] as String,
    target: j['target'] as String? ?? '',
    outcome: j['outcome'] as String? ?? '',
  );

  final int id;
  final DateTime at;

  /// A username, or `anonymous` with the API's auth off.
  final String actor;
  final String action;
  final String target;
  final String outcome;
}

/// A page of the log, newest first, and how many entries there are in all.
typedef AuditPage = ({List<AuditEntry> items, int total});

/// A page the API turned down (only admins may read the log), or that never arrived.
class AuditException extends ApiException {
  const AuditException(super.message, {super.statusCode, super.code, super.requestId});
}

Future<AuditPage> fetchAudit(Uri api, {int limit = 50, int offset = 0}) async {
  final http.Response res;
  try {
    res = await http
        .get(api.resolve('api/v1/audit').replace(queryParameters: {'limit': '$limit', 'offset': '$offset'}))
        .timeout(const Duration(seconds: 8));
  } on TimeoutException {
    throw const AuditException('No answer in time.');
  } on http.ClientException catch (e) {
    throw AuditException(e.message);
  }
  if (res.statusCode != 200) {
    throw AuditException('HTTP ${res.statusCode}', statusCode: res.statusCode, requestId: requestIdOf(res));
  }
  // UTF-8 whatever the content type says: outcomes quote people's text (a banner's).
  final body = (jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast<String, dynamic>();
  return (
    items: [for (final e in body['items'] as List) AuditEntry.fromJson((e as Map).cast())],
    total: body['total'] as int,
  );
}
