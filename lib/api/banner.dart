import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/settings.dart';
import 'project.dart' show ApiWatcher;

enum BannerTone { info, warning }

/// A message an admin puts above every view, from p4n4-api
/// (`GET/PUT /api/v1/dashboard/banner`): planned maintenance, a known outage.
/// Kept per deployment, so it reaches every device, wall tablets included.
class DashboardBanner {
  const DashboardBanner({this.text = '', this.tone = BannerTone.info, this.until});

  factory DashboardBanner.fromJson(Map<String, dynamic> j) => DashboardBanner(
    text: (j['text'] as String? ?? '').trim(),
    tone: BannerTone.values.asNameMap()[j['tone']] ?? BannerTone.info,
    until: DateTime.tryParse(j['until'] as String? ?? '')?.toLocal(),
  );

  final String text;
  final BannerTone tone;

  /// When it stops showing by itself; null keeps it until an admin clears it.
  final DateTime? until;

  /// Whether there's anything to show at [now] (the API stops sending a
  /// banner once it's over, but a device may not have asked again yet).
  bool showsAt(DateTime now) => text.isNotEmpty && (until == null || until!.isAfter(now));

  Map<String, Object?> toJson() => {'text': text, 'tone': tone.name, 'until': until?.toUtc().toIso8601String()};

  // Equal banners, re-read every minute, don't rebuild the app.
  @override
  bool operator ==(Object other) =>
      other is DashboardBanner && other.text == text && other.tone == tone && other.until == until;

  @override
  int get hashCode => Object.hash(text, tone, until);
}

/// A change the API turned down (only admins may), or that never arrived.
class BannerException implements Exception {
  const BannerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 8);

Future<DashboardBanner> fetchBanner(Uri api) async =>
    DashboardBanner.fromJson(_body(await http.get(api.resolve('api/v1/dashboard/banner')).timeout(_timeout)));

/// Shows [banner] on every device; one with empty text clears it.
Future<DashboardBanner> saveBanner(Uri api, DashboardBanner banner) async {
  final http.Response res;
  try {
    res = await http
        .put(
          api.resolve('api/v1/dashboard/banner'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(banner.toJson()),
        )
        .timeout(_timeout);
  } on TimeoutException {
    throw const BannerException('No answer in time.');
  } on http.ClientException catch (e) {
    throw BannerException(e.message);
  }
  return DashboardBanner.fromJson(_body(res));
}

/// Keeps [AppSettings.banner] in step with the connected deployment, asking
/// again every [every]: a banner should reach a wall tablet nobody touches.
class BannerWatcher extends ApiWatcher<DashboardBanner> {
  BannerWatcher(super.settings, {super.fetch = fetchBanner, super.retry, super.every = const Duration(minutes: 1)})
    : super(apply: (b) => settings.banner = b);
}

// UTF-8 whatever the content type says: `res.body` would read a message's "–" as Latin-1.
Map<String, dynamic> _body(http.Response res) {
  if (res.statusCode == 200) return (jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast();
  String? message;
  try {
    message = ((jsonDecode(res.body) as Map)['error'] as Map)['message'] as String?;
  } catch (_) {}
  throw BannerException(message ?? 'HTTP ${res.statusCode}', statusCode: res.statusCode);
}
