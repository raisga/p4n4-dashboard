import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/users.dart';
import 'package:p4n4_dashboard/core/role.dart';

final _api = Uri.parse('http://pi:8000/');

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Future<T> _withApi<T>(Future<T> Function() body, http.Response Function(http.Request) handler) =>
    http.runWithClient(body, () => MockClient((r) async => handler(r)));

void main() {
  test('lists users with the view each gets', () async {
    final users = await _withApi(() => listUsers(_api), (r) {
      expect((r.method, r.url.path), ('GET', '/api/v1/users'));
      return _json([
        {'username': 'ana', 'role': 'admin', 'created_at': '2026-01-01T00:00:00+00:00'},
        {'username': 'bo', 'role': 'operator', 'created_at': '2026-01-01T00:00:00+00:00'},
        {'username': 'cy', 'role': 'normie', 'created_at': '2026-01-01T00:00:00+00:00'},
      ]);
    });
    expect(
      [for (final u in users) (u.username, u.view)],
      [('ana', Role.admin), ('bo', Role.power), ('cy', Role.normie)],
    );
  });

  test('creates and updates with API role names', () async {
    final sent = <(String, String, String)>[];
    http.Response handler(http.Request r) {
      sent.add((r.method, r.url.path, r.body));
      return _json({'username': 'bo', 'role': 'operator', 'created_at': 'x'}, r.method == 'POST' ? 201 : 200);
    }

    await _withApi(() => createUser(_api, username: ' bo ', password: 'long enough pw', view: Role.power), handler);
    await _withApi(() => updateUser(_api, 'bo', view: Role.normie), handler);
    await _withApi(() => updateUser(_api, 'bo', password: 'another long pw'), handler);
    expect(sent, [
      ('POST', '/api/v1/users', '{"username":"bo","password":"long enough pw","role":"operator"}'),
      ('PATCH', '/api/v1/users/bo', '{"role":"normie"}'),
      ('PATCH', '/api/v1/users/bo', '{"password":"another long pw"}'),
    ]);
  });

  test('refusals carry the API message', () async {
    Future<String> error(http.Response res) async {
      try {
        await _withApi(() => deleteUser(_api, 'ana'), (_) => res);
      } on UsersException catch (e) {
        return e.message;
      }
      return 'no error';
    }

    expect(
      await error(
        _json({
          'error': {'code': 'last_admin', 'message': "'ana' is the last admin."},
        }, 409),
      ),
      "'ana' is the last admin.",
    );
    expect(
      await error(
        _json({
          'error': {
            'code': 'validation_error',
            'message': 'Invalid request.',
            'fields': [
              {
                'loc': ['body', 'password'],
                'message': 'Password must be at least 10 characters.',
              },
            ],
          },
        }, 422),
      ),
      'Password must be at least 10 characters.',
    );
    expect(await error(_json({}, 403)), 'Only admins can manage users.');
    expect(await error(http.Response('', 204)), 'no error');
  });
}
