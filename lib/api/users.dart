import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/role.dart';

/// p4n4-api accounts (`/api/v1/users`), for admins. Requests carry the
/// signed-in admin's token (see `AuthClient`).
class ApiUser {
  const ApiUser({required this.username, required this.role, this.createdAt});

  factory ApiUser.fromJson(Map<String, dynamic> j) =>
      ApiUser(username: j['username'] as String, role: j['role'] as String, createdAt: j['created_at'] as String?);

  final String username;

  /// The p4n4-api role: `admin`, `operator` or `normie`.
  final String role;
  final String? createdAt;

  /// The dashboard view this account gets.
  Role get view => roleForApi(role);
}

/// A request the API turned down, with its message for people (e.g. "the
/// last admin can't be demoted", "username taken", a short password).
class UsersException implements Exception {
  const UsersException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 8);
const _json = {'Content-Type': 'application/json'};

Future<List<ApiUser>> listUsers(Uri api) async {
  final res = await http.get(api.resolve('api/v1/users')).timeout(_timeout);
  return [for (final u in _body(res) as List) ApiUser.fromJson((u as Map).cast())];
}

Future<ApiUser> createUser(Uri api, {required String username, required String password, required Role view}) async {
  final res = await http
      .post(
        api.resolve('api/v1/users'),
        headers: _json,
        body: jsonEncode({'username': username.trim(), 'password': password, 'role': apiRoleFor(view)}),
      )
      .timeout(_timeout);
  return ApiUser.fromJson((_body(res) as Map).cast());
}

/// Changes [username]'s view and/or resets their password (which signs them
/// out everywhere). Both apply, or neither does.
Future<ApiUser> updateUser(Uri api, String username, {Role? view, String? password}) async {
  final res = await http
      .patch(
        api.resolve('api/v1/users/${Uri.encodeComponent(username)}'),
        headers: _json,
        body: jsonEncode({if (view != null) 'role': apiRoleFor(view), 'password': ?password}),
      )
      .timeout(_timeout);
  return ApiUser.fromJson((_body(res) as Map).cast());
}

Future<void> deleteUser(Uri api, String username) async {
  final res = await http.delete(api.resolve('api/v1/users/${Uri.encodeComponent(username)}')).timeout(_timeout);
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
  throw UsersException(message, statusCode: res.statusCode);
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
