import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A messaging channel the project has, e.g. its Telegram bot.
class ChatChannel {
  const ChatChannel({required this.id, this.name, this.state, this.bot, this.url});

  factory ChatChannel.fromJson(Map<String, dynamic> j) => ChatChannel(
    id: j['id'] as String,
    name: j['name'] as String?,
    state: j['state'] as String?,
    bot: j['bot'] as String?,
    url: j['url'] as String?,
  );

  final String id;
  final String? name;

  /// `live`, `mock` (messages are logged, not sent) or `off`.
  final String? state;

  /// The bot's handle and address, e.g. `@store_bot` and https://t.me/store_bot.
  final String? bot;
  final String? url;
}

/// A chat linked to one of the project's channels: it gets the alerts and may
/// talk to the bot.
class LinkedChat {
  const LinkedChat({
    required this.id,
    required this.channel,
    this.name,
    this.linkedAt,
    this.linkedBy,
    this.muted = const [],
  });

  factory LinkedChat.fromJson(Map<String, dynamic> j) => LinkedChat(
    id: j['id'] as String,
    channel: j['channel'] as String,
    name: j['name'] as String?,
    linkedAt: DateTime.tryParse((j['linked_at'] as String?) ?? '')?.toLocal(),
    linkedBy: j['linked_by'] as String?,
    muted: [...?(j['muted'] as List?)?.whereType<String>()],
  );

  final String id;
  final String channel;

  /// The group's title or the person's name.
  final String? name;
  final DateTime? linkedAt;

  /// Who made the code it was linked with.
  final String? linkedBy;

  /// Alert kinds the chat has muted (e.g. `A2`).
  final List<String> muted;
}

class ChatsPage {
  const ChatsPage({this.channels = const [], this.chats = const []});

  factory ChatsPage.fromJson(Map<String, dynamic> j) => ChatsPage(
    channels: [
      for (final c in (j['channels'] as List?) ?? const [])
        if (c case {'id': String _} && final Map m) ChatChannel.fromJson(m.cast()),
    ],
    chats: [
      for (final c in (j['chats'] as List?) ?? const [])
        if (c case {'id': String _, 'channel': String _} && final Map m) LinkedChat.fromJson(m.cast()),
    ],
  );

  final List<ChatChannel> channels;
  final List<LinkedChat> chats;
}

/// A one-time code that links a chat: sent to the bot as [command], or
/// opened as one of [links] (which sends it by itself).
class LinkCode {
  const LinkCode({required this.code, this.expiresAt, this.command, this.links = const []});

  factory LinkCode.fromJson(Map<String, dynamic> j) => LinkCode(
    code: j['code'] as String,
    expiresAt: DateTime.tryParse((j['expires_at'] as String?) ?? '')?.toLocal(),
    command: j['command'] as String?,
    links: [
      for (final l in (j['links'] as List?) ?? const [])
        if (l case {'channel': final String channel, 'url': final String url}) (channel: channel, url: url),
    ],
  );

  final String code;
  final DateTime? expiresAt;
  final String? command;
  final List<({String channel, String url})> links;
}

/// A chats request p4n4-api turned down or couldn't relay. [code] `no_chats`:
/// the project has none; `chats_unavailable`: the bot can't manage them (its
/// [message] says why).
class ChatsException implements Exception {
  const ChatsException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// p4n4-api's `/api/v1/chats`: admins only (the API checks).
class ChatsApi {
  ChatsApi(this.api);

  /// p4n4-api's base URL.
  final Uri api;

  static const _timeout = Duration(seconds: 12);

  Future<ChatsPage> list() async =>
      ChatsPage.fromJson(_body(await _guard(http.get(api.resolve('api/v1/chats')).timeout(_timeout))));

  Future<LinkCode> newCode() async =>
      LinkCode.fromJson(_body(await _guard(http.post(api.resolve('api/v1/chats/codes')).timeout(_timeout))));

  Future<void> unlink(String chatId) async {
    _body(await _guard(http.delete(api.resolve('api/v1/chats/${Uri.encodeComponent(chatId)}')).timeout(_timeout)));
  }

  static Future<http.Response> _guard(Future<http.Response> request) async {
    try {
      return await request;
    } on TimeoutException {
      throw const ChatsException('No answer in time.', statusCode: 504);
    } on Exception catch (e) {
      throw ChatsException('$e');
    }
  }
}

Map<String, dynamic> _body(http.Response res) {
  if (res.statusCode == 200) return (jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast();
  String? code, message;
  try {
    final error = (jsonDecode(res.body) as Map)['error'] as Map;
    code = error['code'] as String?;
    message = error['message'] as String?;
  } catch (_) {}
  throw ChatsException(message ?? 'HTTP ${res.statusCode}', statusCode: res.statusCode, code: code);
}
