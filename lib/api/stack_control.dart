import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';
import 'sse.dart';

/// Starting, stopping and restarting a stack through p4n4-api
/// (`POST /api/v1/stacks/{stack}/{action}`, admins only). The API runs each
/// action as a background job, polled at `GET /api/v1/jobs/{id}`.
enum StackAction { up, restart, down }

class StackJob {
  const StackJob({required this.id, required this.status, this.output = const []});

  factory StackJob.fromJson(Map<String, dynamic> j) => StackJob(
    id: j['id'] as String,
    status: j['status'] as String,
    output: [...?(j['output'] as List?)?.whereType<String>()],
  );

  final String id;

  /// `queued`, `running`, `succeeded` or `failed`.
  final String status;

  /// Compose's most recent output lines.
  final List<String> output;

  bool get finished => status == 'succeeded' || status == 'failed';
  bool get failed => status == 'failed';
}

class StackControlException extends ApiException {
  const StackControlException(super.message, {super.statusCode, super.code, super.requestId});
}

const _timeout = Duration(seconds: 10);

Future<StackJob> startStackAction(Uri api, String stack, StackAction action) async {
  final res = await http
      .post(api.resolve('api/v1/stacks/${Uri.encodeComponent(stack)}/${action.name}'))
      .timeout(_timeout);
  return StackJob.fromJson((_body(res) as Map).cast());
}

/// Restarts one Compose [service] of [stack] (`POST
/// /api/v1/stacks/{stack}/services/{service}/restart`), as a job like the rest.
Future<StackJob> startServiceRestart(Uri api, String stack, String service) async {
  final res = await http
      .post(api.resolve('api/v1/stacks/${Uri.encodeComponent(stack)}/services/${Uri.encodeComponent(service)}/restart'))
      .timeout(_timeout);
  return StackJob.fromJson((_body(res) as Map).cast());
}

Future<StackJob> fetchJob(Uri api, String id) async {
  final res = await http.get(api.resolve('api/v1/jobs/${Uri.encodeComponent(id)}')).timeout(_timeout);
  return StackJob.fromJson((_body(res) as Map).cast());
}

/// Starts [action] on [stack] and waits for its job to finish, checking every
/// [every], for at most [limit] (pulling images on a Pi takes a while).
Future<StackJob> runStackAction(
  Uri api,
  String stack,
  StackAction action, {
  Duration every = const Duration(seconds: 2),
  Duration limit = const Duration(minutes: 10),
}) async => waitForJob(api, await startStackAction(api, stack, action), every: every, limit: limit);

/// Checks [job] every [every] until it finishes, for at most [limit].
Future<StackJob> waitForJob(
  Uri api,
  StackJob job, {
  Duration every = const Duration(seconds: 2),
  Duration limit = const Duration(minutes: 10),
}) async {
  final deadline = DateTime.now().add(limit);
  var current = job;
  while (!current.finished) {
    if (DateTime.now().isAfter(deadline)) throw const StackControlException('Still running; check the jobs list.');
    await Future<void>.delayed(every);
    current = await fetchJob(api, current.id);
  }
  return current;
}

/// The decoded body of a success, or a [StackControlException] with the
/// API's message (`{"error": {"message": ...}}`).
Object? _body(http.Response res) {
  if (res.statusCode >= 200 && res.statusCode < 300) return res.body.isEmpty ? null : jsonDecode(res.body);
  String? message;
  try {
    message = ((jsonDecode(res.body) as Map)['error'] as Map)['message'] as String?;
  } catch (_) {}
  throw StackControlException(
    message ?? 'HTTP ${res.statusCode}',
    statusCode: res.statusCode,
    requestId: requestIdOf(res),
  );
}

/// A stack's container logs as they come (`GET /api/v1/stacks/{stack}/logs
/// ?follow=true`, admins only: logs can hold secrets): the last [tail] lines,
/// then new ones, until Compose stops or the listener cancels. Only
/// [service]'s, when given.
Stream<String> followStackLogs(Uri api, String stack, {String? service, int tail = 200}) async* {
  final url = api
      .resolve('api/v1/stacks/${Uri.encodeComponent(stack)}/logs')
      .replace(queryParameters: {'follow': 'true', 'tail': '$tail', 'service': ?service});
  await for (final e in sseGet(url)) {
    switch (e.event) {
      case 'message':
        yield e.data;
      case 'error':
        throw StackControlException(e.data);
      case 'end':
        return;
    }
  }
}
