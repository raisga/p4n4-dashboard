import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatMessage {
  ChatMessage(this.role, this.content);

  final String role; // 'user' | 'assistant' | 'error'
  String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AgentOption {
  const AgentOption(this.id, this.label);

  final String id;
  final String label;
}

/// Carries a service's own `Authorization` value through the dashboard
/// container's proxy (docker/nginx/default.conf.template), leaving
/// `Authorization` to the proxy's basic auth.
const upstreamAuthorizationHeader = 'X-Upstream-Authorization';

/// Whether [uri] goes through the proxy that served this page: web only, same origin.
bool viaPageProxy(Uri uri, {Uri? page}) {
  page ??= Uri.base;
  if (!page.isScheme('http') && !page.isScheme('https')) return false;
  return uri.scheme == page.scheme && uri.host == page.host && uri.port == page.port;
}

abstract interface class AgentClient {
  /// Models (Ollama) or agents (Letta) the user can pick from.
  Future<List<AgentOption>> listOptions();

  /// Sends the conversation and yields the reply incrementally.
  Stream<String> send(String optionId, List<ChatMessage> history);
}

/// Ollama `/api/chat` with NDJSON streaming. Ollama is stateless, so the
/// full history is sent each turn.
class OllamaClient implements AgentClient {
  OllamaClient(this.base);

  final Uri base;

  @override
  Future<List<AgentOption>> listOptions() async {
    final res = await http.get(base.resolve('api/tags')).timeout(const Duration(seconds: 5));
    _check(res.statusCode, res.body);
    final models = (jsonDecode(res.body)['models'] as List).cast<Map<String, dynamic>>();
    return [for (final m in models) AgentOption(m['name'] as String, m['name'] as String)];
  }

  @override
  Stream<String> send(String model, List<ChatMessage> history) async* {
    final client = http.Client();
    try {
      final req = http.Request('POST', base.resolve('api/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': model,
          'stream': true,
          'messages': [
            for (final m in history)
              if (m.role != 'error') m.toJson(),
          ],
        });
      final res = await client.send(req);
      if (res.statusCode != 200) {
        _check(res.statusCode, await res.stream.bytesToString());
      }
      final lines = res.stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final chunk = jsonDecode(line) as Map<String, dynamic>;
        if (chunk['error'] != null) throw AgentException(chunk['error'].toString());
        final text = (chunk['message'] as Map?)?['content'] as String?;
        if (text != null && text.isNotEmpty) yield text;
        if (chunk['done'] == true) break;
      }
    } finally {
      client.close();
    }
  }
}

/// Letta REST API. Letta keeps conversation state server-side, so only the
/// latest user message is sent.
class LettaClient implements AgentClient {
  LettaClient(this.base, {this.token = '', this.viaProxy = false});

  final Uri base;
  final String token;

  /// Through the dashboard container's proxy, which may itself ask for HTTP
  /// basic auth: the browser's credentials then need `Authorization`, so the
  /// token goes in [upstreamAuthorizationHeader] and nginx moves it back.
  final bool viaProxy;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) (viaProxy ? upstreamAuthorizationHeader : 'Authorization'): 'Bearer $token',
  };

  @override
  Future<List<AgentOption>> listOptions() async {
    final res = await http.get(base.resolve('v1/agents/'), headers: _headers).timeout(const Duration(seconds: 5));
    _check(res.statusCode, res.body);
    final agents = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return [for (final a in agents) AgentOption(a['id'] as String, (a['name'] ?? a['id']) as String)];
  }

  @override
  Stream<String> send(String agentId, List<ChatMessage> history) async* {
    final last = history.lastWhere((m) => m.role == 'user');
    final res = await http
        .post(
          base.resolve('v1/agents/$agentId/messages'),
          headers: _headers,
          body: jsonEncode({
            'messages': [last.toJson()],
          }),
        )
        .timeout(const Duration(minutes: 2));
    _check(res.statusCode, res.body);
    final messages = (jsonDecode(res.body)['messages'] as List).cast<Map<String, dynamic>>();
    final replies = [
      for (final m in messages)
        if (m['message_type'] == 'assistant_message') _contentText(m['content']),
    ];
    yield replies.isEmpty ? '(no assistant reply)' : replies.join('\n\n');
  }

  static String _contentText(Object? content) => switch (content) {
    String s => s,
    List parts => parts.map((p) => p is Map ? (p['text'] ?? '') : '$p').join(),
    _ => '',
  };
}

class AgentException implements Exception {
  AgentException(this.message);

  final String message;

  @override
  String toString() => message;
}

void _check(int status, String body) {
  if (status >= 200 && status < 300) return;
  var detail = body;
  try {
    final j = jsonDecode(body);
    if (j is Map) detail = (j['error'] ?? j['detail'] ?? body).toString();
  } catch (_) {}
  throw AgentException('HTTP $status: $detail');
}
