import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The assistant, through p4n4-api's `/api/v1/agents` endpoints: an Ollama
/// model or a Letta agent. The API requires sign-in, keeps the Letta password
/// on the server and decides who may use which model (normies only chat with
/// the one an operator chose), so the dashboard never talks to Ollama or Letta
/// directly. Requests carry the signed-in user's token (see `AuthClient`).
enum AgentBackend { ollama, letta }

class ChatMessage {
  ChatMessage(this.role, this.content, {this.error});

  final String role; // 'user' | 'assistant' | 'error'
  String content;

  /// For `error` messages: what went wrong.
  final AgentException? error;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AgentOption {
  const AgentOption(this.id, this.label);

  final String id;
  final String label;
}

/// Who everyone on the deployment chats with (`GET/PUT /api/v1/agents/config`).
/// A null [model] or [agentId] means the first one the service lists.
class AssistantConfig {
  const AssistantConfig({this.backend = AgentBackend.ollama, this.model, this.agentId, this.updatedAt});

  factory AssistantConfig.fromJson(Map<String, dynamic> j) => AssistantConfig(
    backend: AgentBackend.values.asNameMap()[j['backend']] ?? AgentBackend.ollama,
    model: j['model'] as String?,
    agentId: j['agent_id'] as String?,
    updatedAt: j['updated_at'] as String?,
  );

  final AgentBackend backend;
  final String? model;
  final String? agentId;

  /// When someone last chose the assistant; null if nobody has on this deployment.
  final String? updatedAt;

  bool get everChosen => updatedAt != null;

  /// The chosen model or agent for [backend], if one was chosen.
  String? get chosen => backend == AgentBackend.ollama ? model : agentId;

  /// This config with [backend] switched, or [id] chosen for the current one.
  AssistantConfig copyWith({AgentBackend? backend, String? id}) {
    final b = backend ?? this.backend;
    return AssistantConfig(
      backend: b,
      model: b == AgentBackend.ollama && id != null ? id : model,
      agentId: b == AgentBackend.letta && id != null ? id : agentId,
    );
  }

  Map<String, Object?> toJson() => {'backend': backend.name, 'model': model, 'agent_id': agentId};
}

/// Whether [seed], the brand's assistant (see `AppSettings.assistantDefault`),
/// can be offered to a deployment where nobody has chosen one: its model or
/// agent must be among [options], what the deployment has installed. Without
/// one it only picks the backend, and the first listed applies.
bool seedAvailable(AssistantConfig seed, List<AgentOption> options) =>
    seed.chosen == null ? options.isNotEmpty : options.any((o) => o.id == seed.chosen);

/// A request p4n4-api, Ollama or Letta turned down, or one that never arrived.
class AgentException implements Exception {
  const AgentException(this.message, {this.statusCode, this.code});

  final String message;

  /// Null when the API couldn't be reached.
  final int? statusCode;

  /// The API's error code, e.g. `assistant_restricted`, `ollama_unavailable`.
  final String? code;

  /// Signed out, or not allowed (e.g. a normie asking for another model).
  bool get denied => statusCode == 401 || statusCode == 403;

  /// The API, Ollama or Letta is down or not answering.
  bool get unavailable => statusCode == null || statusCode == 502 || statusCode == 503 || statusCode == 504;

  @override
  String toString() => message;
}

class AgentApi {
  AgentApi(this.api);

  /// p4n4-api's base URL.
  final Uri api;

  static const _json = {'Content-Type': 'application/json'};

  Uri _url(String path) => api.resolve('api/v1/agents$path');

  Future<AssistantConfig> config() async => AssistantConfig.fromJson((await _get('/config') as Map).cast());

  /// Operators and admins only; the API refuses anyone else.
  Future<AssistantConfig> setConfig(AssistantConfig config) async {
    final res = await _guard(
      http.put(_url('/config'), headers: _json, body: jsonEncode(config.toJson())).timeout(const Duration(seconds: 8)),
    );
    return AssistantConfig.fromJson((_body(res) as Map).cast());
  }

  /// Ollama's models or Letta's agents.
  Future<List<AgentOption>> listOptions(AgentBackend backend) async => switch (backend) {
    AgentBackend.ollama => [
      for (final m in ((await _get('/models') as Map)['models'] as List).cast<Map>())
        AgentOption(m['name'] as String, m['name'] as String),
    ],
    AgentBackend.letta => [
      for (final a in ((await _get('') as Map)['agents'] as List).cast<Map>())
        AgentOption(a['id'] as String, (a['name'] ?? a['id']) as String),
    ],
  };

  /// Sends the conversation and yields the reply as it arrives. Ollama keeps
  /// no state, so it gets the whole history; Letta only the last message.
  /// Both get the system's current status, so questions like "is everything
  /// running?" have something to go on.
  Stream<String> send(AgentBackend backend, String id, List<ChatMessage> history) => switch (backend) {
    AgentBackend.ollama => _ollama(id, history),
    AgentBackend.letta => _letta(id, history),
  };

  Stream<String> _ollama(String model, List<ChatMessage> history) async* {
    final client = http.Client();
    try {
      final req = http.Request('POST', _url('/chat'))
        ..headers.addAll(_json)
        ..body = jsonEncode({
          'model': model,
          'stream': true,
          'include_status': true,
          'messages': [
            for (final m in history)
              if (m.role != 'error') m.toJson(),
          ],
        });
      final http.StreamedResponse res;
      try {
        res = await client.send(req);
      } on Exception catch (e) {
        throw AgentException('$e');
      }
      if (res.statusCode != 200) _body(http.Response(await res.stream.bytesToString(), res.statusCode));
      final lines = res.stream.transform(utf8.decoder).transform(const LineSplitter());
      // Read to the end even after `done` (Ollama closes the stream right after it):
      // cancelling first can beat the stream's own end, and browsers then report the
      // request as aborted (net::ERR_ABORTED).
      var done = false;
      await for (final line in lines) {
        if (done || line.trim().isEmpty) continue;
        final chunk = jsonDecode(line) as Map<String, dynamic>;
        if (chunk['error'] != null) throw AgentException(chunk['error'].toString(), statusCode: 502);
        final text = (chunk['message'] as Map?)?['content'] as String?;
        if (text != null && text.isNotEmpty) yield text;
        done = chunk['done'] == true;
      }
    } finally {
      client.close();
    }
  }

  Stream<String> _letta(String agentId, List<ChatMessage> history) async* {
    final last = history.lastWhere((m) => m.role == 'user');
    final res = await _guard(
      http
          .post(
            _url('/${Uri.encodeComponent(agentId)}/chat'),
            headers: _json,
            body: jsonEncode({'message': last.content, 'include_status': true}),
          )
          .timeout(const Duration(minutes: 5)),
    );
    final reply = (_body(res) as Map)['reply'] as String? ?? '';
    yield reply;
  }

  Future<Object?> _get(String path) async =>
      _body(await _guard(http.get(_url(path)).timeout(const Duration(seconds: 8))));

  /// Turns network failures and timeouts into an [AgentException].
  static Future<http.Response> _guard(Future<http.Response> request) async {
    try {
      return await request;
    } on TimeoutException {
      throw const AgentException('No answer in time.', statusCode: 504);
    } on Exception catch (e) {
      throw AgentException('$e');
    }
  }
}

/// The decoded body of a success, or an [AgentException] with the API's code
/// and message (`{"error": {"code": ..., "message": ...}}`).
Object? _body(http.Response res) {
  if (res.statusCode >= 200 && res.statusCode < 300) return res.body.isEmpty ? null : jsonDecode(res.body);
  String? code, message;
  try {
    final error = (jsonDecode(res.body) as Map)['error'] as Map;
    code = error['code'] as String?;
    message = error['message'] as String?;
  } catch (_) {}
  throw AgentException(message ?? 'HTTP ${res.statusCode}', statusCode: res.statusCode, code: code);
}
