/// p4n4-api, played in the browser for the demo build ([demoMode]).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../api/edge_metrics.dart';
import 'demo.dart';
import 'demo_agent.dart';
import 'demo_charts.dart';
import 'demo_store.dart';

/// An account of the demo's.
class _User {
  _User(this.role, this.password, this.createdAt);

  String role;
  String password;
  final DateTime createdAt;
  DateTime? lastLoginAt;
  bool mustChange = false;

  Map<String, Object?> toJson(String username) => {
    'username': username,
    'role': role,
    'created_at': createdAt.toUtc().toIso8601String(),
    'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
    'must_change_password': mustChange,
  };
}

/// A stack action: queued, then running, then done, as Compose would take.
class _Job {
  _Job(this.id, this.stack, this.action, this.services) : started = DateTime.now();

  final String id;
  final String stack;
  final String action;
  final List<String> services;
  final DateTime started;
  bool applied = false;
}

/// The app's HTTP client in the demo build: p4n4-api's `/api/v1/` endpoints
/// go to [DemoApi], everything else (the app's own files, the demo clips) to
/// [_inner]. `http.runWithClient` makes one per request, so the state lives
/// in the one [DemoApi]; goes under `AuthClient`, which adds the token.
class DemoClient extends http.BaseClient {
  DemoClient(this._inner, this._api);

  final http.Client _inner;
  final DemoApi _api;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      request.url.path.startsWith(DemoApi._prefix) ? _api.send(request) : _inner.send(request);

  @override
  void close() => _inner.close();
}

/// p4n4-api's `/api/v1/` endpoints, answered from [DemoStore], which it reads
/// from `demo/store.json` next to the app on first use with [_loader].
///
/// The accounts are [demoAccounts], with [demoPassword]. What admins and
/// operators change (accounts, stacks, views, the banner, the assistant, chats,
/// alert reviews) holds, and is in the audit log, until the page is reloaded.
class DemoApi {
  DemoApi(this._loader, {Uri? page}) : _page = page ?? Uri.base {
    final since = DateTime.now().subtract(const Duration(days: 21));
    for (final MapEntry(:key, :value) in demoAccounts.entries) {
      _users[key] = _User(value, demoPassword, since);
      // Each has been in before.
      _users[key]!.lastLoginAt = DateTime.now().subtract(Duration(hours: 3 + 20 * _users.length));
      if (key == 'admin') continue;
      _record('admin', 'user.create', key, 'role $value', at: since.add(const Duration(minutes: 3)));
    }
  }

  /// Never closed: it lives as long as the app.
  final http.Client _loader;
  final Uri _page;

  Future<DemoStore>? _store;
  final _metrics = DemoMetrics();
  final _random = math.Random();

  final _users = <String, _User>{};
  final _audit = <Map<String, Object?>>[];
  final _jobs = <String, _Job>{};
  final _stopped = <String>{};
  final _restartedAt = <String, DateTime>{};
  List<Map<String, dynamic>>? _chats;

  /// What was saved here: views, view settings, the banner, the assistant.
  final _saved = <String, Object?>{};

  static const _prefix = '/api/v1/';
  static const _tokenPrefix = 'demo-access.';
  static const _refreshPrefix = 'demo-refresh.';

  Future<DemoStore> get store => _store ??= () async {
    final res = await _loader.get(_page.resolve('demo/store.json'));
    if (res.statusCode != 200) throw http.ClientException('demo/store.json: HTTP ${res.statusCode}');
    return DemoStore((jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast());
  }();

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final body = request is http.Request && request.body.isNotEmpty ? jsonDecode(request.body) : null;
    // A moment's latency, as from a real API, so loading states show as they would.
    await Future<void>.delayed(Duration(milliseconds: 60 + _random.nextInt(140)));
    try {
      return await _route(request, path.substring(_prefix.length), body);
    } catch (e) {
      return _error(request, 500, 'internal', '$e');
    }
  }

  /// The signed-in account a request carries a token for, if any.
  String? _userOf(http.BaseRequest r) {
    final header = r.headers['Authorization'] ?? r.headers['X-Upstream-Authorization'] ?? '';
    final token = header.startsWith('Bearer ') ? header.substring(7) : '';
    final name = token.startsWith(_tokenPrefix) ? token.substring(_tokenPrefix.length) : null;
    return _users.containsKey(name) ? name : null;
  }

  Future<http.StreamedResponse> _route(http.BaseRequest r, String path, Object? body) async {
    final get = r.method == 'GET', put = r.method == 'PUT', post = r.method == 'POST';
    final patch = r.method == 'PATCH', delete = r.method == 'DELETE';
    final q = r.url.queryParameters;
    final b = body is Map ? body : const {};
    final segments = [for (final s in path.split('/')) Uri.decodeComponent(s)];

    // ── sign-in ──
    switch (segments) {
      case ['auth', 'token'] when post:
        final user = _users[b['username']];
        if (user == null || user.password != b['password']) {
          return _error(r, 401, 'invalid_credentials', 'Wrong username or password.');
        }
        user.lastLoginAt = DateTime.now();
        return _json(_tokens(b['username'] as String), r);
      case ['auth', 'refresh'] when post:
        final token = '${b['refresh_token'] ?? ''}';
        final name = token.startsWith(_refreshPrefix) ? token.substring(_refreshPrefix.length) : '';
        return _users.containsKey(name) ? _json(_tokens(name), r) : _error(r, 401, 'invalid_token', 'Sign in again.');
      case ['auth', 'logout']:
        return _json({'ok': true}, r);
    }

    final me = _userOf(r);
    if (me == null) return _error(r, 401, 'unauthorized', 'Sign in.');
    final role = _users[me]!.role;
    final admin = role == 'admin', operator = admin || role == 'operator';
    http.StreamedResponse forbidden() => _error(r, 403, 'forbidden', 'Not allowed for your role.');

    switch (segments) {
      case ['auth', 'me']:
        return _json({'username': me, 'role': role}, r);
      case ['auth', 'password'] when post:
        final user = _users[me]!;
        if (b['current_password'] != user.password) return _error(r, 403, 'forbidden', 'Wrong password.');
        user
          ..password = '${b['new_password']}'
          ..mustChange = false;
        _record(me, 'user.update', me, 'password');
        return _json(_tokens(me), r);

      // ── the project ──
      case ['project'] when get:
        return _json(_project((await store).project), r);
      case ['project', 'home'] when get:
        final s = await store;
        final lang = (q['lang'] ?? '').split('-').first.toLowerCase();
        final md = s.home[lang] ?? s.home[''];
        return md == null ? _empty(r, 204) : _json({'markdown': md}, r);
      case ['project', 'vision'] when get:
        final vision = (await store).vision;
        return vision == null ? _empty(r, 204) : _json({...vision, 'live': null}, r);

      // ── stacks ──
      case ['stacks'] when get:
        return _json(_stacks(await store), r);
      case ['stacks', final stack, final action] when post:
        if (!admin) return forbidden();
        final s = await store;
        final services = [
          for (final st in _allStacks(s))
            if (st['name'] == stack)
              for (final svc in st['services'] as List) (svc as List)[0] as String,
        ];
        if (services.isEmpty) return _error(r, 404, 'not_found', 'No stack $stack.');
        final job = _jobs['job-${_jobs.length + 1}'] = _Job('job-${_jobs.length + 1}', stack, action, services);
        _record(me, 'stack.$action', stack, '');
        return _json(_jobJson(job), r);
      case ['jobs', final id] when get:
        if (!admin) return forbidden();
        final job = _jobs[id];
        return job == null ? _error(r, 404, 'not_found', 'No job $id.') : _json(_jobJson(job), r);

      // ── the feed ──
      case ['feed'] when get:
        final s = await store;
        return _json(
          s.feed(
            limit: int.tryParse(q['limit'] ?? '') ?? 50,
            before: double.tryParse(q['before'] ?? ''),
            canAct: operator,
          ),
          r,
        );
      case ['feed', final id, 'action'] when post:
        if (!operator) return forbidden();
        final action = b['action'] as String;
        if (!(await store).act(id, action)) return _error(r, 404, 'not_found', 'No such alert.');
        _record(me, 'feed.action', id, action);
        return _json({'ok': true}, r);

      // ── the assistant ──
      case ['agents', 'config'] when get:
        return _json(_saved['agents'] ?? _assistant({'backend': 'ollama', 'model': (await store).model}), r);
      case ['agents', 'config'] when put:
        if (!operator) return forbidden();
        _record(me, 'assistant.update', '', '${b['backend']} ${b['model'] ?? b['agent_id'] ?? ''}'.trim());
        return _json(_saved['agents'] = _assistant(b, (await store).model), r);
      case ['agents', 'models'] when get:
        return _json({
          'models': [
            {'name': (await store).model},
          ],
        }, r);
      case ['agents'] when get:
        return _json({'agents': <Object>[]}, r);
      case ['agents', 'chat'] when post:
        return _chat(r, b);

      // ── what admins set for every device ──
      case ['dashboard', 'charts'] when get:
        final charts = computeCharts(await store, q['range']);
        return charts == null ? _error(r, 404, 'not_found', 'No charts.') : _json(charts, r);
      case ['dashboard', final what] when get && _settings.containsKey(what):
        return _json(_saved[what] ?? (what == 'banner' ? await _banner() : const <String, Object>{}), r);
      case ['dashboard', final what] when put && _settings.containsKey(what):
        if (!admin) return forbidden();
        _record(me, _settings[what]!, '', what == 'banner' ? '${b['text'] ?? ''}' : '');
        return _json(_saved[what] = body, r);

      // ── the device ──
      case ['edge', 'metrics'] when get:
        return _json(_edge(), r);

      // ── accounts ──
      case ['users'] when get:
        if (!admin) return forbidden();
        return _json([for (final name in _users.keys.toList()..sort()) _users[name]!.toJson(name)], r);
      case ['users'] when post:
        if (!admin) return forbidden();
        final name = '${b['username'] ?? ''}'.trim();
        if (name.isEmpty || '${b['password'] ?? ''}'.isEmpty) {
          return _error(r, 422, 'invalid', 'A username and a password are required.');
        }
        if (_users.containsKey(name)) return _error(r, 409, 'conflict', 'That username is taken.');
        final user = _users[name] = _User('${b['role'] ?? 'normie'}', '${b['password']}', DateTime.now())
          ..mustChange = b['must_change_password'] == true;
        _record(me, 'user.create', name, 'role ${user.role}');
        return _json(user.toJson(name), r);
      case ['users', final name] when patch:
        if (!admin) return forbidden();
        final user = _users[name];
        if (user == null) return _error(r, 404, 'not_found', 'No such user.');
        final changes = <String>[];
        if (b['role'] case final String newRole when newRole != user.role) {
          if (user.role == 'admin' && _users.values.where((u) => u.role == 'admin').length == 1) {
            return _error(r, 409, 'conflict', "The last admin can't be demoted.");
          }
          user.role = newRole;
          changes.add('role $newRole');
        }
        if (b['password'] case final String password) {
          user.password = password;
          changes.add('password');
        }
        if (b['must_change_password'] case final bool must) user.mustChange = must;
        _record(me, 'user.update', name, changes.join(', '));
        return _json(user.toJson(name), r);
      case ['users', final name, 'sign-out'] when post:
        if (!admin) return forbidden();
        if (!_users.containsKey(name)) return _error(r, 404, 'not_found', 'No such user.');
        _record(me, 'user.sign_out', name, '');
        return _json({'ok': true}, r);
      case ['users', final name] when delete:
        if (!admin) return forbidden();
        if (name == me) return _error(r, 409, 'conflict', "You can't delete your own account.");
        if (_users.remove(name) == null) return _error(r, 404, 'not_found', 'No such user.');
        _record(me, 'user.delete', name, '');
        return _json({'ok': true}, r);
      case ['audit'] when get:
        if (!admin) return forbidden();
        final limit = int.tryParse(q['limit'] ?? '') ?? 50, offset = int.tryParse(q['offset'] ?? '') ?? 0;
        final newest = _audit.reversed.toList();
        return _json({'items': newest.skip(offset).take(limit).toList(), 'total': newest.length}, r);

      // ── messaging chats ──
      case ['chats'] when get:
        if (!admin) return forbidden();
        final s = await store;
        return _json({'channels': s.chats['channels'] ?? const [], 'chats': _chatsOf(s)}, r);
      case ['chats', 'codes'] when post:
        if (!admin) return forbidden();
        final code = List.generate(6, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[_random.nextInt(32)]).join();
        _record(me, 'chats.code', '', '');
        return _json({
          'code': code,
          'expires_at': DateTime.now().add(const Duration(minutes: 10)).toUtc().toIso8601String(),
          'command': '/link $code',
          'links': <Object>[],
        }, r);
      case ['chats', final id] when delete:
        if (!admin) return forbidden();
        _chatsOf(await store).removeWhere((c) => c['id'] == id);
        _record(me, 'chats.unlink', id, '');
        return _json({'ok': true}, r);
    }
    return _error(r, 404, 'not_found', 'Not found.');
  }

  /// Settings kept per deployment, and their audit action.
  static const _settings = {
    'views': 'dashboard.views',
    'view-settings': 'dashboard.view_settings',
    'banner': 'dashboard.banner',
  };

  void _record(String actor, String action, String target, String outcome, {DateTime? at}) => _audit.add({
    'id': _audit.length + 1,
    'at': (at ?? DateTime.now()).toUtc().toIso8601String(),
    'actor': actor,
    'action': action,
    'target': target,
    'outcome': outcome,
  });

  Map<String, Object?> _tokens(String username) => {
    'access_token': '$_tokenPrefix$username',
    'refresh_token': '$_refreshPrefix$username',
    'username': username,
    'role': _users[username]!.role,
    'password_change_required': _users[username]!.mustChange,
  };

  /// The project, its cameras' paths resolved against the app's page.
  Map<String, dynamic> _project(Map<String, dynamic> project) {
    final dashboard = ((project['dashboard'] as Map?) ?? const {}).cast<String, dynamic>();
    return {
      ...project,
      'dashboard': {
        ...dashboard,
        if (dashboard['cameras'] case final List cameras)
          'cameras': [
            for (final c in cameras.cast<Map>())
              {...c, if (c['url'] case final String url) 'url': _page.resolve(url).toString()},
          ],
      },
    };
  }

  List<Map<String, dynamic>> _chatsOf(DemoStore s) =>
      _chats ??= [for (final c in (s.chats['chats'] as List?) ?? const []) (c as Map).cast<String, dynamic>()];

  Map<String, Object?> _assistant(Map<dynamic, dynamic> c, [String? model]) => {
    'backend': c['backend'] ?? 'ollama',
    'model': c['model'] ?? model,
    'agent_id': c['agent_id'],
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  /// The project's note above every view, if it has one.
  Future<Map<String, Object?>> _banner() async {
    final s = await store;
    return {'text': s.banner[s.lang] ?? '', 'tone': 'info'};
  }

  /// The project's stacks, and p4n4-api's own.
  List<Map<String, dynamic>> _allStacks(DemoStore s) => [
    ...s.stacks,
    {
      'name': 'api',
      'services': [
        ['p4n4-api', 'p4n4-api:latest'],
      ],
    },
  ];

  Map<String, Object?> _stacks(DemoStore s) {
    for (final job in _jobs.values) {
      _jobJson(job); // applies the jobs that have finished
    }
    final now = DateTime.now();
    final booted = now.subtract(const Duration(days: 6, hours: 3));
    Map<String, Object?> svc(String stack, String name, String image) {
      final up = !_stopped.contains(stack);
      final started = _restartedAt[stack] ?? booted;
      final uptime = now.difference(started);
      return {
        'name': name,
        'state': up ? 'running' : 'exited',
        'health': up ? 'healthy' : '',
        'image': image,
        'version': image.contains(':') ? image.split(':').last : null,
        'status': up ? 'Up ${_ago(uptime)} (healthy)' : 'Exited (0) ${_ago(now.difference(started))} ago',
        'exit_code': up ? null : 0,
        'ports': <Object>[],
        'started_at': started.toUtc().toIso8601String(),
        'uptime_s': up ? uptime.inSeconds : null,
      };
    }

    return {
      'stacks': [
        for (final st in _allStacks(s))
          {
            'name': st['name'],
            'dir': st['name'],
            'services': [
              for (final x in st['services'] as List) svc(st['name'] as String, x[0] as String, x[1] as String),
            ],
            'running': _stopped.contains(st['name']) ? 0 : (st['services'] as List).length,
            'total': (st['services'] as List).length,
          },
      ],
    };
  }

  static String _ago(Duration d) => d.inDays > 0
      ? '${d.inDays} days'
      : d.inHours > 0
      ? '${d.inHours} hours'
      : d.inMinutes > 0
      ? '${d.inMinutes} minutes'
      : '${d.inSeconds} seconds';

  /// [job] as `GET /api/v1/jobs/{id}` has it now; once done, the stack is as it said.
  Map<String, Object?> _jobJson(_Job job) {
    final elapsed = DateTime.now().difference(job.started);
    final (going, gone) = switch (job.action) {
      'down' => ('Stopping', 'Removed'),
      'restart' => ('Restarting', 'Started'),
      _ => ('Starting', 'Started'),
    };
    final shown = (elapsed.inMilliseconds / 600).floor().clamp(0, job.services.length * 2);
    final output = [for (var i = 0; i < shown; i++) ' Container ${job.services[i ~/ 2]}  ${i.isEven ? going : gone}'];
    final done = shown == job.services.length * 2 && elapsed > const Duration(seconds: 2);
    if (done && !job.applied) {
      job.applied = true;
      if (job.action == 'down') {
        _stopped.add(job.stack);
      } else {
        _stopped.remove(job.stack);
        _restartedAt[job.stack] = DateTime.now();
      }
    }
    return {
      'id': job.id,
      'status': done ? 'succeeded' : (elapsed < const Duration(milliseconds: 500) ? 'queued' : 'running'),
      'output': output,
    };
  }

  /// The edge device, a little busier while the store is open.
  Map<String, Object?> _edge() {
    final m = _metrics.next();
    final hour = DateTime.now().hour;
    final open = hour >= 10 && hour < 20;
    return {
      'cpu_percent': open ? m.cpu : m.cpu * 0.4,
      'mem_percent': m.mem,
      'mem_used_mb': 7620 * m.mem / 100,
      'mem_total_mb': 7620,
      'disk_percent': 32.0,
      'temp_c': open ? m.tempC : (m.tempC ?? 48) - 6,
      'uptime_s': m.uptime?.inSeconds,
      'load': m.load,
      'inference_ms': open ? m.inferenceMs : null,
    };
  }

  /// The assistant's reply as Ollama's stream, with p4n4's tool steps.
  Future<http.StreamedResponse> _chat(http.BaseRequest r, Map<dynamic, dynamic> body) async {
    final s = await store;
    final messages = (body['messages'] as List?) ?? const [];
    final question = messages.whereType<Map>().lastWhere((m) => m['role'] == 'user', orElse: () => const {});
    final reply = DemoAgent(s).answer('${question['content'] ?? ''}');
    Stream<List<int>> lines() async* {
      List<int> line(Object o) => utf8.encode('${jsonEncode(o)}\n');
      for (final (tool, label) in reply.steps) {
        yield line({
          'step': {'tool': tool, 'label': label, 'state': 'running'},
        });
        await Future<void>.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));
        yield line({
          'step': {'tool': tool, 'label': label, 'state': 'done', 'ok': true},
        });
      }
      // Word by word, as a small model on an edge device writes.
      for (final word in RegExp(r'\S+\s*|\s+').allMatches(reply.text)) {
        yield line({
          'message': {'role': 'assistant', 'content': word.group(0)},
          'done': false,
        });
        await Future<void>.delayed(Duration(milliseconds: 18 + _random.nextInt(30)));
      }
      yield line({'done': true});
    }

    return http.StreamedResponse(
      lines(),
      200,
      request: r,
      headers: const {'content-type': 'application/x-ndjson; charset=utf-8'},
    );
  }

  http.StreamedResponse _json(Object? value, http.BaseRequest r, {int status = 200}) {
    final bytes = utf8.encode(jsonEncode(value));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      contentLength: bytes.length,
      request: r,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  http.StreamedResponse _error(http.BaseRequest r, int status, String code, String message) => _json(
    {
      'error': {'code': code, 'message': message},
    },
    r,
    status: status,
  );

  http.StreamedResponse _empty(http.BaseRequest r, int status) =>
      http.StreamedResponse(const Stream.empty(), status, contentLength: 0, request: r);
}
