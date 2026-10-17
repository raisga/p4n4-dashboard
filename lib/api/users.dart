import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/role.dart';
import 'api_error.dart';

/// p4n4-api accounts (`/api/v1/users`), for admins. Requests carry the
/// signed-in admin's token (see `AuthClient`).
class ApiUser {
  const ApiUser({
    required this.username,
    required this.role,
    this.createdAt,
    this.lastLoginAt,
    this.mustChangePassword = false,
  });

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
    username: j['username'] as String,
    role: j['role'] as String,
    createdAt: j['created_at'] as String?,
    lastLoginAt: DateTime.tryParse(j['last_login_at'] as String? ?? '')?.toLocal(),
    mustChangePassword: j['must_change_password'] == true,
  );

  final String username;

  /// The p4n4-api role: `admin`, `operator` or `normie`.
  final String role;
  final String? createdAt;

  /// Their last sign-in with a password; null if they never have (or an API
  /// from before it kept track).
  final DateTime? lastLoginAt;

  /// They'll choose a new password before anything else at their next sign-in.
  final bool mustChangePassword;

  /// The dashboard view this account gets.
  Role get view => roleForApi(role);
}

/// A request the API turned down, with its message for people (e.g. "the
/// last admin can't be demoted", "username taken", a short password).
class UsersException extends ApiException {
  const UsersException(super.message, {super.statusCode, super.code, super.requestId});
}

const _timeout = Duration(seconds: 8);
const _json = {'Content-Type': 'application/json'};

Future<List<ApiUser>> listUsers(Uri api) async {
  final res = await http.get(api.resolve('api/v1/users')).timeout(_timeout);
  return [for (final u in _body(res) as List) ApiUser.fromJson((u as Map).cast())];
}

/// With [mustChangePassword], they choose their own password at their first sign-in.
Future<ApiUser> createUser(
  Uri api, {
  required String username,
  required String password,
  required Role view,
  bool mustChangePassword = false,
}) async {
  final res = await http
      .post(
        api.resolve('api/v1/users'),
        headers: _json,
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
          'role': apiRoleFor(view),
          if (mustChangePassword) 'must_change_password': true,
        }),
      )
      .timeout(_timeout);
  return ApiUser.fromJson((_body(res) as Map).cast());
}

/// Changes [username]'s view, resets their password (which signs them out
/// everywhere) and/or sets whether they must choose a new one. All apply, or
/// none does. A reset without [mustChangePassword] doesn't require one.
Future<ApiUser> updateUser(Uri api, String username, {Role? view, String? password, bool? mustChangePassword}) async {
  final res = await http
      .patch(
        _user(api, username),
        headers: _json,
        body: jsonEncode({
          if (view != null) 'role': apiRoleFor(view),
          'password': ?password,
          'must_change_password': ?mustChangePassword,
        }),
      )
      .timeout(_timeout);
  return ApiUser.fromJson((_body(res) as Map).cast());
}

/// Signs [username] out on every device; their password stays the same.
Future<void> signOutUser(Uri api, String username) async {
  final res = await http.post(_user(api, username, 'sign-out')).timeout(_timeout);
  _body(res);
}

Uri _user(Uri api, String username, [String? action]) =>
    api.resolve('api/v1/users/${Uri.encodeComponent(username)}${action == null ? '' : '/$action'}');

Future<void> deleteUser(Uri api, String username) async {
  final res = await http.delete(_user(api, username)).timeout(_timeout);
  _body(res);
}

/// The decoded body of a success, or a [UsersException] with the API's
/// message (`{"error": {"message": ...}}`).
Object? _body(http.Response res) {
  if (res.statusCode >= 200 && res.statusCode < 300) {
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }
  final message = switch (res.statusCode) {
    401 => 'Your session has expired. Sign in again.',
    403 => 'Only admins can manage users.',
    _ => _message(res.body) ?? 'HTTP ${res.statusCode}',
  };
  throw UsersException(message, statusCode: res.statusCode, requestId: requestIdOf(res));
}

String? _message(String body) {
  try {
    final error = (jsonDecode(body) as Map)['error'] as Map;
    // Validation errors name the field: the first one is enough to act on.
    final fields = error['fields'];
    if (fields is List && fields.isNotEmpty) return (fields.first as Map)['message'] as String?;
    return error['message'] as String?;
  } catch (_) {
    return null;
  }
}
