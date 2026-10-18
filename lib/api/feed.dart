import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// What an item asks a person to do (an alert to review), or doesn't (an event).
enum FeedTone { info, review, neutral }

class FeedAction {
  const FeedAction(this.id, this.label);

  final String id;
  final String label;
}

/// A page about an item (e.g. the project's own review page), opened in the browser.
class FeedLink {
  const FeedLink(this.label, this.url);

  /// Only http(s) links; anything else is no link.
  static FeedLink? fromJson(Object? j) {
    if (j is! Map || j['label'] is! String || j['url'] is! String) return null;
    final url = Uri.tryParse(j['url'] as String);
    if (url == null || !const {'http', 'https'}.contains(url.scheme)) return null;
    return FeedLink(j['label'] as String, url);
  }

  final String label;
  final Uri url;
}

/// One item of the project's feed, as p4n4-api relays it (`GET /api/v1/feed`;
/// dashboard/README.md#feed-contract).
class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    this.time,
    this.alert = false,
    this.subtitle,
    this.detail,
    this.badge,
    this.tone = FeedTone.neutral,
    this.status,
    this.actions = const [],
    this.meta = const {},
    this.synthetic = false,
    this.image = false,
    this.link,
  });

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
    id: j['id'] as String,
    title: j['title'] as String,
    time: DateTime.tryParse((j['time'] ?? '') as String),
    alert: j['kind'] == 'alert',
    subtitle: j['subtitle'] as String?,
    detail: j['detail'] as String?,
    badge: j['badge'] as String?,
    tone: FeedTone.values.asNameMap()[j['tone']] ?? FeedTone.neutral,
    status: j['status'] as String?,
    actions: [
      for (final a in (j['actions'] as List?) ?? const [])
        if (a is Map) FeedAction(a['id'] as String, (a['label'] ?? a['id']) as String),
    ],
    meta: {
      for (final MapEntry(:key, :value) in ((j['meta'] as Map?) ?? const {}).entries)
        if (value != null) key as String: '$value',
    },
    synthetic: j['synthetic'] == true,
    image: j['image'] == true,
    link: FeedLink.fromJson(j['link']),
  );

  final String id;
  final String title;
  final DateTime? time;

  /// An alert (for a person to review), not just an event.
  final bool alert;
  final String? subtitle;

  /// What to do about it, when there is something to do.
  final String? detail;
  final String? badge;
  final FeedTone tone;

  /// An alert's review status (`pending_review`, `attended`, `dismissed`, …).
  final String? status;

  /// Empty for viewers: the API leaves them out for anyone who can't act.
  final List<FeedAction> actions;
  final Map<String, String> meta;
  final bool synthetic;

  /// It has a picture (the evidence), at [FeedApi.image].
  final bool image;
  final FeedLink? link;

  bool get pending => status == 'pending_review';
}

class FeedPage {
  const FeedPage({required this.items, this.title, this.pending, this.nextBefore, this.canAct = false});

  factory FeedPage.fromJson(Map<String, dynamic> j) => FeedPage(
    title: j['title'] as String?,
    items: [
      for (final i in (j['items'] as List?) ?? const [])
        if (i is Map && i['id'] is String && i['title'] is String) FeedItem.fromJson(i.cast()),
    ],
    pending: ((j['counts'] as Map?)?['pending'] as num?)?.toInt(),
    nextBefore: j['next_before'],
    canAct: j['can_act'] == true,
  );

  final String? title;
  final List<FeedItem> items;

  /// Alerts waiting for a person, across the whole feed (not just this page).
  final int? pending;

  /// Pass back as `before` for the next, older page; null on the last one.
  final Object? nextBefore;
  final bool canAct;
}

/// A feed request p4n4-api turned down or couldn't relay. [code] `no_feed`:
/// the project doesn't publish one.
class FeedException extends ApiException {
  const FeedException(super.message, {super.statusCode, super.code, super.requestId});

  bool get notConfigured => code == 'no_feed';
}

class FeedApi {
  FeedApi(this.api);

  /// p4n4-api's base URL.
  final Uri api;

  static const _timeout = Duration(seconds: 12);

  /// Pictures already fetched (or on their way), newest last; a failed one is asked again next time.
  final _images = <String, Future<Uint8List>>{};
  static const _keepImages = 60;

  Future<FeedPage> page({int limit = 50, Object? before}) async {
    final url = api
        .resolve('api/v1/feed')
        .replace(queryParameters: {'limit': '$limit', if (before != null) 'before': '$before'});
    return FeedPage.fromJson(_body(await _guard(http.get(url).timeout(_timeout))));
  }

  /// An item's picture (one with [FeedItem.image]), fetched once.
  Future<Uint8List> image(String itemId) {
    final cached = _images.remove(itemId);
    final future = cached ?? _fetchImage(itemId);
    _images[itemId] = future;
    if (_images.length > _keepImages) _images.remove(_images.keys.first);
    future.then<void>(
      (_) {},
      onError: (Object _) {
        _images.remove(itemId);
      },
    );
    return future;
  }

  Future<Uint8List> _fetchImage(String itemId) async {
    final res = await _guard(
      http.get(api.resolve('api/v1/feed/${Uri.encodeComponent(itemId)}/image')).timeout(_timeout),
    );
    if (res.statusCode == 200) return res.bodyBytes;
    _body(res);
    throw FeedException('HTTP ${res.statusCode}', statusCode: res.statusCode);
  }

  /// Operators and admins only; the API refuses anyone else.
  Future<void> act(String itemId, String action) async {
    _body(
      await _guard(
        http
            .post(
              api.resolve('api/v1/feed/${Uri.encodeComponent(itemId)}/action'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'action': action}),
            )
            .timeout(_timeout),
      ),
    );
  }

  static Future<http.Response> _guard(Future<http.Response> request) async {
    try {
      return await request;
    } on TimeoutException {
      throw const FeedException('No answer in time.', statusCode: 504);
    } on Exception catch (e) {
      throw FeedException('$e');
    }
  }
}

Map<String, dynamic> _body(http.Response res) {
  if (res.statusCode == 200) return (jsonDecode(res.body) as Map).cast();
  String? code, message;
  try {
    final error = (jsonDecode(res.body) as Map)['error'] as Map;
    code = error['code'] as String?;
    message = error['message'] as String?;
  } catch (_) {}
  throw FeedException(
    message ?? 'HTTP ${res.statusCode}',
    statusCode: res.statusCode,
    requestId: requestIdOf(res),
    code: code,
  );
}
