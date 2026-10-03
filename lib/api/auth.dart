import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// p4n4-api's sign-in endpoints (`/api/v1/auth/*`).
///
/// Access tokens last 1 h and refresh tokens 7 d. Every refresh returns a new
/// pair and retires the old refresh token; reusing a retired one revokes the
/// whole sign-in, so callers must never refresh with the same token twice
/// (see [AuthClient]).

/// The result of signing in or refreshing.
class ApiTokens {
  const ApiTokens({required this.access, required this.refresh, required this.username, required this.role});

  factory ApiTokens.fromJson(Map<String, dynamic> j) => ApiTokens(
    access: j['access_token'] as String,
    refresh: j['refresh_token'] as String,
    username: j['username'] as String,
    role: j['role'] as String,
  );

  final String access;
  final String refresh;
  final String username;

  /// p4n4-api role: `admin` or `operator`.
  final String role;
}

/// A sign-in that failed for a reason worth showing (bad password, expired
/// session, rate limit), as opposed to the API being unreachable.
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// What p4n4-api says about sign-in, from `GET /auth/me` without a token.
enum AuthMode {
  /// Auth is on: sign in with a username and password.
  required,

  /// `P4N4_API_AUTH=off`: every request is treated as an admin.
  off,

  /// No answer (or not p4n4-api): nothing to sign in to.
  unreachable,
}

const _timeout = Duration(seconds: 8);

Future<AuthMode> probeAuth(Uri api) async {
  try {
    final res = await http.get(api.resolve('api/v1/auth/me')).timeout(_timeout);
    if (res.statusCode == 401) return AuthMode.required;
    if (res.statusCode == 200 && (jsonDecode(res.body) as Map)['auth'] == false) return AuthMode.off;
    return AuthMode.unreachable;
  } catch (_) {
    return AuthMode.unreachable;
  }
}

Future<ApiTokens> signIn(Uri api, String username, String password) =>
    _tokens(api.resolve('api/v1/auth/token'), {'username': username, 'password': password});

Future<ApiTokens> refreshTokens(Uri api, String refreshToken) =>
    _tokens(api.resolve('api/v1/auth/refresh'), {'refresh_token': refreshToken});

/// Revokes the sign-in behind [refreshToken]. Best effort: signing out locally
/// shouldn't depend on reaching the API.
Future<void> signOutApi(Uri api, String refreshToken) async {
  try {
    await http
        .post(
          api.resolve('api/v1/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(_timeout);
  } catch (_) {}
}

Future<ApiTokens> _tokens(Uri url, Map<String, String> body) async {
  final res = await http
      .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
      .timeout(_timeout);
  return switch (res.statusCode) {
    200 => ApiTokens.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
    401 when url.path.endsWith('/token') => throw const AuthException('Wrong username or password.', statusCode: 401),
    401 => throw const AuthException('Your session has expired. Sign in again.', statusCode: 401),
    429 => throw const AuthException('Too many attempts. Wait a minute and try again.', statusCode: 429),
    final code => throw http.ClientException('HTTP $code', url),
  };
}

/// Where [AuthClient] gets tokens: implemented by `Session`.
abstract interface class ApiCredentials {
  /// The access token for the p4n4-api that serves [url], if signed in to it.
  String? accessTokenFor(Uri url);

  /// A fresh access token for [url]'s p4n4-api after a 401, or null when
  /// there's no sign-in to refresh. Concurrent calls for one API share a refresh.
  Future<String?> refreshFor(Uri url);
}

/// Adds the signed-in user's access token to requests for p4n4-api, and
/// refreshes it once when the API answers 401.
///
/// Installed for the whole app with `http.runWithClient` (main.dart), so the
/// API calls elsewhere stay plain `http.get`s. Other URLs (Ollama, cameras,
/// Grafana) pass through untouched.
class AuthClient extends http.BaseClient {
  AuthClient(this._inner, this._credentials, {bool Function(Uri)? viaProxy}) : _viaProxy = viaProxy ?? ((_) => false);

  final http.Client _inner;
  final ApiCredentials _credentials;

  /// Whether [Uri] goes through the dashboard container's proxy. Its optional
  /// basic auth needs `Authorization`, so the token travels in
  /// `X-Upstream-Authorization` there and nginx moves it back.
  final bool Function(Uri) _viaProxy;

  static const upstreamHeader = 'X-Upstream-Authorization';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url;
    // The auth endpoints carry their own credentials and must not loop on 401.
    if (url.path.contains('/api/v1/auth/')) return _inner.send(request);
    final token = _credentials.accessTokenFor(url);
    if (token != null) _authorize(request, token);
    final res = await _inner.send(request);
    if (res.statusCode != 401 || request is! http.Request) return res;

    // Expired or missing access token: refresh once and retry.
    final fresh = await _credentials.refreshFor(url);
    if (fresh == null) return res;
    await res.stream.drain<void>();
    final retry = http.Request(request.method, url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..bodyBytes = request.bodyBytes;
    _authorize(retry, fresh);
    return _inner.send(retry);
  }

  void _authorize(http.BaseRequest request, String token) =>
      request.headers[_viaProxy(request.url) ? upstreamHeader : 'Authorization'] = 'Bearer $token';

  @override
  void close() => _inner.close();
}
