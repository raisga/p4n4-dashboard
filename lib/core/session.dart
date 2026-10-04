import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth.dart' as auth;
import '../api/fleet.dart';
import 'role.dart';
import 'settings.dart';

export 'role.dart';

/// How the connected deployment was signed in to.
enum SignInMode {
  /// With a p4n4-api account; the role comes from the API.
  api,

  /// With the role picker, which is only offered while p4n4-api runs without
  /// auth or can't be reached. Dropped as soon as the API requires sign-in.
  local,
}

/// Who is signed in to the connected deployment.
///
/// Each deployment runs its own p4n4-api with its own accounts, so sign-in is
/// per deployment: connecting to another one asks to sign in there unless
/// that's been done before. What's kept per deployment:
/// - the role, username and [SignInMode] (in its settings, `session`);
/// - the API refresh token (secure storage, like the Letta password);
/// - the access token (memory only; it lasts an hour and is refreshed on demand).
///
/// Also the token source for [auth.AuthClient]: requests to a deployment's API
/// get its access token, and a 401 refreshes it once.
class Session extends ChangeNotifier implements auth.ApiCredentials {
  Session(this.settings, {this.probe = auth.probeAuth, this.refreshApi = auth.refreshTokens}) {
    settings.addListener(_onSettings);
    _active = settings.deployment.id;
  }

  final AppSettings settings;
  final Future<auth.AuthMode> Function(Uri api) probe;
  final Future<auth.ApiTokens> Function(Uri api, String refreshToken) refreshApi;

  final _access = <String, String>{};
  final _refreshing = <String, Future<String?>>{};
  late String _active;

  /// Loads the session, moving a role picked before sign-in existed (an
  /// app-wide `role` preference) to the connected deployment. That and any
  /// other picker session is checked against the API in the background.
  static Future<Session> load(
    AppSettings settings, {
    Future<auth.AuthMode> Function(Uri api) probe = auth.probeAuth,
    Future<auth.ApiTokens> Function(Uri api, String refreshToken) refreshApi = auth.refreshTokens,
  }) async {
    final session = Session(settings, probe: probe, refreshApi: refreshApi);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('role') case final String legacy) {
      if (Role.named(legacy) case final role? when settings.sessionOf(settings.deployment) == null) {
        await settings.setSessionOf(settings.deployment, {'mode': SignInMode.local.name, 'role': role.name});
      }
      await prefs.remove('role');
    }
    unawaited(session.verify());
    return session;
  }

  Map<String, Object?>? get _info => settings.sessionOf(settings.deployment);

  /// The role signed in with.
  Role? get signedInRole => Role.named(_info?['role']);

  /// The view shown: [signedInRole], or the one an admin is previewing.
  Role? get role => switch (signedInRole) {
    Role.admin => _preview ?? Role.admin,
    final r => r,
  };

  bool get isAdmin => role == Role.admin;

  /// Hosts, URLs, raw errors and endpoint settings (admin and power).
  bool get isTechnical => role?.technical ?? false;

  /// Lets an admin see the dashboard as [view] (null to stop) without
  /// changing their account. Kept in memory: a restart, sign-out or switching
  /// deployment ends it.
  set preview(Role? view) {
    final next = signedInRole == Role.admin && view != Role.admin ? view : null;
    if (next == _preview) return;
    _preview = next;
    notifyListeners();
  }

  Role? get preview => signedInRole == Role.admin ? _preview : null;
  Role? _preview;
  SignInMode? get mode => SignInMode.values.asNameMap()[_info?['mode']];
  String? get username => _info?['user'] as String?;

  /// Signs in to the connected deployment's p4n4-api. Throws
  /// [auth.AuthException] for a wrong password or rate limit, and
  /// `http.ClientException` / `TimeoutException` when the API is unreachable.
  Future<void> signInWithPassword(String username, String password) async {
    final d = settings.deployment;
    final tokens = await auth.signIn(settings.apiUriOf(d), username.trim(), password);
    await _store(d, tokens);
  }

  /// Signs in with the role picker. Only for when [auth.probeAuth] says the
  /// API runs without auth or can't be reached; [verify] undoes it once the
  /// API requires sign-in.
  Future<void> signInLocal(Role role) =>
      settings.setSessionOf(settings.deployment, {'mode': SignInMode.local.name, 'role': role.name});

  Future<void> signOut() async {
    _preview = null;
    final d = settings.deployment;
    final refresh = settings.apiRefreshTokenOf(d);
    _access.remove(d.id);
    await settings.setApiRefreshToken(d, '');
    await settings.setSessionOf(d, null);
    if (refresh.isNotEmpty) unawaited(auth.signOutApi(settings.apiUriOf(d), refresh));
  }

  /// Drops a picker session when the connected deployment's API now requires
  /// sign-in. Runs at startup and on connect.
  Future<void> verify() async {
    final d = settings.deployment;
    if (mode != SignInMode.local) return;
    if (await probe(settings.apiUriOf(d)) == auth.AuthMode.required && settings.deployment.id == d.id) {
      await settings.setSessionOf(d, null);
    }
  }

  Future<void> _store(Deployment d, auth.ApiTokens tokens) async {
    _access[d.id] = tokens.access;
    await settings.setApiRefreshToken(d, tokens.refresh);
    final info = {'mode': SignInMode.api.name, 'role': roleForApi(tokens.role).name, 'user': tokens.username};
    // A role change on the API applies on the next refresh.
    final old = settings.sessionOf(d);
    if (old?['role'] != info['role'] || old?['user'] != info['user'] || old?['mode'] != info['mode']) {
      await settings.setSessionOf(d, info);
    }
  }

  @override
  String? accessTokenFor(Uri url) => switch (settings.deploymentForApi(url)) {
    final d? => _access[d.id],
    null => null,
  };

  @override
  Future<String?> refreshFor(Uri url) {
    final d = settings.deploymentForApi(url);
    if (d == null) return Future.value();
    // One refresh at a time per deployment: reusing a refresh token revokes the sign-in.
    // (A block body: `=> _refreshing.remove(...)` would return this very future
    // to whenComplete, which would then wait on itself.)
    return _refreshing[d.id] ??= _refresh(d).whenComplete(() {
      _refreshing.remove(d.id);
    });
  }

  Future<String?> _refresh(Deployment d) async {
    final token = settings.apiRefreshTokenOf(d);
    if (token.isEmpty) return null;
    try {
      final tokens = await refreshApi(settings.apiUriOf(d), token);
      await _store(d, tokens);
      return tokens.access;
    } on auth.AuthException catch (e) {
      // Expired, revoked, or the account was removed: sign in again.
      if (e.statusCode == 401) {
        _access.remove(d.id);
        await settings.setApiRefreshToken(d, '');
        await settings.setSessionOf(d, null);
      }
      return null;
    } catch (_) {
      return null; // Unreachable: keep the session for when it's back.
    }
  }

  /// The role lives in settings, so every settings change may change it.
  void _onSettings() {
    if (settings.deployment.id == _active) return notifyListeners();
    _active = settings.deployment.id;
    _preview = null;
    notifyListeners();
    unawaited(verify());
  }

  @override
  void dispose() {
    settings.removeListener(_onSettings);
    super.dispose();
  }
}

/// Exposes [Session] to the widget tree and rebuilds dependents on change.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
