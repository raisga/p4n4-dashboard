import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/camera.dart';
import '../api/fleet.dart';
import '../api/project.dart';
import '../api/services.dart' show StackDef;
import '../api/status_monitor.dart';
import 'brand.dart';
import 'secrets.dart';

enum AgentBackend { ollama, letta }

/// Settings that belong to a deployment, so switching deployments switches
/// them all. Everything else (theme, client tabs) is app-wide.
const profileKeys = {
  'host',
  'apiBase',
  'ollamaBase',
  'lettaBase',
  'edgeMetricsUrl',
  'edgeDemo',
  'agentBackend',
  'ollamaModel',
  'lettaAgentId',
  'lettaToken',
  'grafanaBase',
  'grafanaPath',
  'grafanaKiosk',
  'videoUrl',
  'cameras',
  'session',
};

/// Profile keys that say where the services are, cleared by
/// [AppSettings.resetConnection].
const connectionKeys = {
  'host',
  'apiBase',
  'ollamaBase',
  'lettaBase',
  'edgeMetricsUrl',
  'grafanaBase',
  'grafanaPath',
  'grafanaKiosk',
};

/// Profile keys whose values are credentials: kept in the platform's secure
/// storage ([SecretStore]) instead of shared_preferences.
const secretKeys = {'lettaToken', 'apiRefreshToken'};

/// User-editable settings, persisted with shared_preferences.
///
/// Keys in [profileKeys] are read from and written to the active
/// [deployment]; the getters below always reflect whichever one is connected.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._defaults, this._store, Map<String, String>? secrets)
    : _secrets = {...?secrets},
      _secretsOk = secrets != null {
    _loadDeployments();
  }

  final SharedPreferences _prefs;
  final SecretStore _store;

  /// Everything in [_store], read once at load so getters stay synchronous.
  final Map<String, String> _secrets;
  bool _secretsOk;

  /// False when the platform's secure storage can't be used (e.g. Linux
  /// without a keyring service). Credentials set meanwhile are kept in memory
  /// only, until the app closes.
  bool get secureStorageAvailable => _secretsOk;

  /// Brand-supplied defaults, used until the user changes a value.
  final Map<String, Object> _defaults;

  late List<Deployment> _deployments;
  late String _activeId;

  static Future<AppSettings> load({Map<String, Object> defaults = const {}, SecretStore? secrets}) async {
    final store = secrets ?? PlatformSecretStore();
    Map<String, String>? saved;
    try {
      saved = await store.readAll();
    } catch (_) {
      // No secure storage; see [secureStorageAvailable].
    }
    final settings = AppSettings._(await SharedPreferences.getInstance(), defaults, store, saved);
    await settings._moveSecretsToStore();
    return settings;
  }

  static String _secretId(Deployment d, String key) => 'deployment.${d.id}.$key';

  Object? _raw(String key, Deployment? d) {
    d ??= deployment;
    if (secretKeys.contains(key)) return _secrets[_secretId(d, key)] ?? d.values[key];
    return profileKeys.contains(key) ? d.values[key] : _prefs.get(key);
  }

  String _str(String key, String fallback, [Deployment? d]) => switch (_raw(key, d)) {
    String v => v,
    _ => _default(key) ?? fallback,
  };

  bool _bool(String key, bool fallback, [Deployment? d]) => switch (_raw(key, d)) {
    bool v => v,
    _ => _default(key) ?? fallback,
  };

  /// The connected project's defaults win over the brand's.
  T? _default<T>(String key) => switch (_project?.defaults[key] ?? _defaults[key]) {
    T v => v,
    null => null,
    final v => throw FormatException('Brand default "$key" should be a $T, got ${v.runtimeType}'),
  };

  /// The connected deployment's project (`.p4n4.json`), kept current by
  /// [ProjectWatcher]. Null until p4n4-api has answered, or without the API.
  /// Its defaults (e.g. the Grafana page) apply until the user sets a value.
  ProjectInfo? get project => _project;
  ProjectInfo? _project;
  set project(ProjectInfo? v) {
    if (v == null && _project == null) return;
    _project = v;
    notifyListeners();
  }

  /// Whether the connected project can serve [tab]. Without project info,
  /// every tab is allowed.
  bool projectAllows(DashTab tab) => _project?.tabs?.contains(tab) ?? true;

  /// Whether the connected project runs [stack]; every stack without project info.
  bool showsStack(StackDef stack) => _project?.hasStack(stack.suffix) ?? true;

  Future<void> _set(String key, Object value) async {
    if (secretKeys.contains(key)) return _setSecret(key, value as String, deployment);
    if (profileKeys.contains(key)) {
      deployment.values[key] = value;
      await _saveDeployments();
    } else {
      switch (value) {
        case String v:
          await _prefs.setString(key, v);
        case bool v:
          await _prefs.setBool(key, v);
      }
    }
    notifyListeners();
  }

  Future<void> _setSecret(String key, String value, Deployment d, {bool notify = true}) async {
    final id = _secretId(d, key);
    value.isEmpty ? _secrets.remove(id) : _secrets[id] = value;
    // Drop any plain-text copy left from before secure storage.
    if (d.values.remove(key) != null) await _saveDeployments();
    if (notify) notifyListeners();
    if (!_secretsOk) return;
    try {
      value.isEmpty ? await _store.delete(id) : await _store.write(id, value);
    } catch (_) {
      _secretsOk = false;
      notifyListeners();
    }
  }

  /// Credentials used to be saved in shared_preferences with the rest of a
  /// deployment. Moves them into secure storage, removing each plain-text
  /// copy only once it's stored. Without secure storage they stay put.
  Future<void> _moveSecretsToStore() async {
    if (!_secretsOk) return;
    var moved = false;
    try {
      for (final d in _deployments) {
        for (final key in secretKeys) {
          if (d.values[key] case final String v) {
            if (v.isNotEmpty) {
              await _store.write(_secretId(d, key), v);
              _secrets[_secretId(d, key)] = v;
            }
            d.values.remove(key);
            moved = true;
          }
        }
      }
    } catch (_) {
      _secretsOk = false;
    }
    if (moved) await _saveDeployments();
  }

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_str('themeMode', 'system')] ?? ThemeMode.system;
  set themeMode(ThemeMode v) => _set('themeMode', v.name);

  /// Host running the p4n4 stacks. Use 10.0.2.2 from the Android emulator.
  String get host => hostOf(deployment);
  set host(String v) => _set('host', v.trim());

  /// Builds `http://<host>:<port><path>`.
  Uri url(int port, [String path = '']) => Uri.parse('http://$host:$port$path');

  /// A service base URL ending in `/`, so clients can resolve relative paths
  /// (`api/tags`) under it and keep a proxy prefix such as `/ollama/`. A
  /// relative value resolves against the page's URL (web, behind a proxy).
  static Uri baseUri(String value) {
    var uri = Uri.parse(value.trim());
    if (!uri.hasScheme) uri = Uri.base.resolveUri(uri);
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }

  // p4n4-api gateway
  String get apiBase => _str('apiBase', '');
  set apiBase(String v) => _set('apiBase', v.trim());
  Uri get apiUri => apiUriOf(deployment);

  // Edge metrics
  String get edgeMetricsUrl => _str('edgeMetricsUrl', '');
  set edgeMetricsUrl(String v) => _set('edgeMetricsUrl', v.trim());
  Uri get edgeMetricsUri =>
      edgeMetricsUrl.isNotEmpty ? Uri.parse(edgeMetricsUrl) : apiUri.resolve('api/v1/edge/metrics');

  bool get edgeDemo => _bool('edgeDemo', false);
  set edgeDemo(bool v) => _set('edgeDemo', v);

  // Agent chat
  AgentBackend get agentBackend =>
      AgentBackend.values.asNameMap()[_str('agentBackend', 'ollama')] ?? AgentBackend.ollama;
  set agentBackend(AgentBackend v) => _set('agentBackend', v.name);

  /// Ollama and Letta base URLs; empty means `http://<host>:11434/` and
  /// `http://<host>:8283/`. Set them to reach the services through a proxy.
  String get ollamaBase => _str('ollamaBase', '');
  set ollamaBase(String v) => _set('ollamaBase', v.trim());
  Uri get ollamaUri => ollamaBase.isNotEmpty ? baseUri(ollamaBase) : url(11434, '/');

  String get lettaBase => _str('lettaBase', '');
  set lettaBase(String v) => _set('lettaBase', v.trim());
  Uri get lettaUri => lettaBase.isNotEmpty ? baseUri(lettaBase) : url(8283, '/');

  String get ollamaModel => _str('ollamaModel', '');
  set ollamaModel(String v) => _set('ollamaModel', v.trim());

  String get lettaAgentId => _str('lettaAgentId', '');
  set lettaAgentId(String v) => _set('lettaAgentId', v.trim());

  String get lettaToken => _str('lettaToken', '');
  set lettaToken(String v) => _set('lettaToken', v.trim());

  // Grafana

  /// Grafana's base URL; empty means `http://<host>:3000/`. Behind the
  /// container's proxy it's `/grafana/` (same origin, so it works over HTTPS).
  String get grafanaBase => _str('grafanaBase', '');
  set grafanaBase(String v) => _set('grafanaBase', v.trim());

  String get grafanaPath => _str('grafanaPath', '/');
  set grafanaPath(String v) => _set('grafanaPath', v.trim().isEmpty ? '/' : v.trim());

  bool get grafanaKiosk => _bool('grafanaKiosk', true);
  set grafanaKiosk(bool v) => _set('grafanaKiosk', v);

  Uri get grafanaUri {
    final base = grafanaBase.isNotEmpty ? baseUri(grafanaBase) : url(3000, '/');
    // Relative to the base, so a proxy prefix (/grafana/) is kept.
    final u = base.resolve(grafanaPath.replaceFirst(RegExp('^/+'), ''));
    if (!grafanaKiosk) return u;
    return u.replace(queryParameters: {...u.queryParameters, 'kiosk': '1'});
  }

  // Video

  /// The deployment's cameras, in display order.
  ///
  /// Until cameras are first saved, a single `videoUrl` (stored, or a brand
  /// default) appears as one camera named "Camera".
  List<Camera> get cameras => switch (deployment.values['cameras']) {
    List list => [for (final c in list) Camera.fromJson((c as Map).cast())],
    _ => [if (_str('videoUrl', '') case final url when url.isNotEmpty) Camera(id: 'camera', name: 'Camera', url: url)],
  };

  set cameras(List<Camera> v) {
    deployment.values.remove('videoUrl'); // superseded by the list
    _set('cameras', [for (final c in v) c.toJson()]);
  }

  /// A camera id not used by any of [cameras].
  String newCameraId() => _newId(cameras.map((c) => c.id));

  // Sign-in (see Session)

  /// [d]'s p4n4-api refresh token, kept in secure storage; empty when not
  /// signed in with p4n4-api.
  String apiRefreshTokenOf(Deployment d) => _str('apiRefreshToken', '', d);

  /// Stores (or, empty, forgets) [d]'s refresh token. Tokens rotate on every
  /// refresh, so this doesn't notify listeners.
  Future<void> setApiRefreshToken(Deployment d, String token) => _setSecret('apiRefreshToken', token, d, notify: false);

  /// Who is signed in to [d] and how (see `Session`), or null.
  Map<String, Object?>? sessionOf(Deployment d) => switch (d.values['session']) {
    Map m => m.cast<String, Object?>(),
    _ => null,
  };

  Future<void> setSessionOf(Deployment d, Map<String, Object?>? session) async {
    session == null ? d.values.remove('session') : d.values['session'] = session;
    await _saveDeployments();
    notifyListeners();
  }

  /// The deployment whose p4n4-api serves [url], if any.
  Deployment? deploymentForApi(Uri url) {
    final target = url.toString();
    for (final d in _deployments) {
      if (target.startsWith(apiUriOf(d).toString())) return d;
    }
    return null;
  }

  /// Brand tabs shown in the client view, after Home. Set by admins.
  List<DashTab> get clientTabs {
    final names = _str('clientTabs', 'agent,grafana,video').split(',');
    return [
      for (final t in DashTab.values)
        if (names.contains(t.name)) t,
    ];
  }

  set clientTabs(List<DashTab> v) => _set('clientTabs', v.map((t) => t.name).join(','));

  // Deployments

  /// Deployments listed in the admin Clients tab. There is always at least one.
  List<Deployment> get deployments => List.unmodifiable(_deployments);

  /// The deployment the dashboard is connected to.
  Deployment get deployment => _deployments.firstWhere((d) => d.id == _activeId);

  String hostOf(Deployment d) => _str('host', 'localhost', d);

  Uri apiUriOf(Deployment d) {
    final base = _str('apiBase', '', d);
    return base.isNotEmpty ? baseUri(base) : Uri.parse('http://${hostOf(d)}:8000/');
  }

  /// Where [d]'s service status comes from (see [StatusMonitor]).
  StatusTarget targetOf(Deployment d) => (api: apiUriOf(d), host: hostOf(d));

  /// The connected deployment's [targetOf].
  StatusTarget get statusTarget => targetOf(deployment);

  /// Forgets the connected deployment's saved [connectionKeys], so the
  /// defaults apply again (brand, `config.json` on web, the project's). Use it
  /// after the operator changes where the services are.
  Future<void> resetConnection() async {
    final values = deployment.values;
    if (!connectionKeys.any(values.containsKey)) return;
    values.removeWhere((k, _) => connectionKeys.contains(k));
    await _saveDeployments();
    notifyListeners();
  }

  /// Switches every connection setting to [id]'s.
  Future<void> connect(String id) async {
    if (id == _activeId || !_deployments.any((d) => d.id == id)) return;
    _activeId = id;
    await _prefs.setString('activeDeployment', id);
    notifyListeners();
  }

  /// Adds [d], or replaces the deployment with the same id.
  Future<void> saveDeployment(Deployment d) async {
    final i = _deployments.indexWhere((e) => e.id == d.id);
    i < 0 ? _deployments.add(d) : _deployments[i] = d;
    await _saveDeployments();
    notifyListeners();
  }

  /// Removes [id]. The connected deployment can't be removed.
  Future<void> removeDeployment(String id) async {
    if (id == _activeId) return;
    final removed = _deployments.where((d) => d.id == id).toList();
    _deployments.removeWhere((d) => d.id == id);
    await _saveDeployments();
    notifyListeners();
    for (final d in removed) {
      for (final key in secretKeys) {
        if (_secrets.remove(_secretId(d, key)) != null && _secretsOk) {
          try {
            await _store.delete(_secretId(d, key));
          } catch (_) {
            _secretsOk = false;
          }
        }
      }
    }
  }

  /// A new, unused deployment id.
  String newDeploymentId() => _newId(_deployments.map((d) => d.id));

  static String _newId(Iterable<String> taken) {
    final used = taken.toSet();
    var n = DateTime.now().microsecondsSinceEpoch;
    while (used.contains(n.toRadixString(36))) {
      n++;
    }
    return n.toRadixString(36);
  }

  Future<void> _saveDeployments() =>
      _prefs.setString('deployments', jsonEncode([for (final d in _deployments) d.toJson()]));

  void _loadDeployments() {
    final raw = _prefs.getString('deployments');
    final list = raw == null ? <Map>[] : (jsonDecode(raw) as List).cast<Map>();
    if (list.isNotEmpty && list.every((d) => d.containsKey('id'))) {
      _deployments = [for (final d in list) Deployment.fromJson(d.cast())];
      final active = _prefs.getString('activeDeployment');
      _activeId = _deployments.any((d) => d.id == active) ? active! : _deployments.first.id;
    } else {
      _migrate(list);
    }
  }

  /// Before profiles, connection settings were top-level keys and deployments
  /// were `{name, host}` pairs. Those settings move into the deployment on the
  /// current host (or a new "Default" one); other deployments keep their host.
  void _migrate(List<Map> old) {
    final legacy = {
      for (final k in profileKeys)
        if (_prefs.get(k) case final Object v) k: v,
    };
    final host = legacy['host'] as String? ?? _default<String>('host') ?? 'localhost';
    String? active;
    _deployments = [
      for (final (i, d) in old.indexed)
        if (active == null && d['host'] == host)
          Deployment(id: active = 'd$i', name: d['name'] as String, values: legacy)
        else
          Deployment(id: 'd$i', name: d['name'] as String, values: {'host': d['host'] as String}),
    ];
    if (active == null) _deployments.insert(0, Deployment(id: 'default', name: 'Default', values: legacy));
    _activeId = active ?? 'default';
    // Fire-and-forget: the in-memory state is already migrated.
    _saveDeployments();
    _prefs.setString('activeDeployment', _activeId);
    for (final k in legacy.keys) {
      _prefs.remove(k);
    }
  }
}

/// Exposes [AppSettings] to the widget tree and rebuilds dependents on change.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child}) : super(notifier: settings);

  static AppSettings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
