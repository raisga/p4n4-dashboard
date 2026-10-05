import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/agent_client.dart' show AgentBackend, AssistantConfig;
import '../api/camera.dart';
import '../api/fleet.dart';
import '../api/project.dart';
import '../api/services.dart' show StackDef;
import '../api/status_monitor.dart';
import '../api/views.dart';
import 'brand.dart';
import 'role.dart';
import 'secrets.dart';

/// Settings that belong to a deployment, so switching deployments switches
/// them all. Everything else (theme, language) is app-wide; each view's tabs
/// belong to the deployment too, but its p4n4-api keeps them ([views]).
const profileKeys = {
  'host',
  'apiBase',
  'edgeMetricsUrl',
  'edgeDemo',
  'grafanaBase',
  'grafanaPath',
  'grafanaKiosk',
  'videoUrl',
  'cameras',
  'videoDemo',
  'session',
};

/// Profile keys that say where the services are, cleared by
/// [AppSettings.resetConnection].
const connectionKeys = {'host', 'apiBase', 'edgeMetricsUrl', 'grafanaBase', 'grafanaPath', 'grafanaKiosk'};

/// Profile keys whose values are credentials: kept in the platform's secure
/// storage ([SecretStore]) instead of shared_preferences.
const secretKeys = {'apiRefreshToken'};

/// Deployment settings from before the assistant went through p4n4-api:
/// where Ollama and Letta were, the Letta password, and the model or agent
/// (now chosen on the server, for everyone). Removed at load. As brand (or
/// project) defaults, the last three still say which assistant to offer a
/// deployment that never chose one ([AppSettings.assistantDefault]).
const retiredKeys = {'ollamaBase', 'lettaBase', 'lettaToken', 'agentBackend', 'ollamaModel', 'lettaAgentId'};

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
    await settings._dropRetired();
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
        case double v:
          await _prefs.setDouble(key, v);
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

  /// Forgets [retiredKeys], the Letta password included, wherever they're kept.
  Future<void> _dropRetired() async {
    var changed = false;
    for (final d in _deployments) {
      for (final key in retiredKeys) {
        changed = d.values.remove(key) != null || changed;
      }
    }
    if (changed) await _saveDeployments();
    final stale = _secrets.keys.where((id) => retiredKeys.any((k) => id.endsWith('.$k'))).toList();
    for (final id in stale) {
      _secrets.remove(id);
      if (!_secretsOk) continue;
      try {
        await _store.delete(id);
      } catch (_) {
        _secretsOk = false;
      }
    }
  }

  /// The brand's assistant (`agentBackend`, `ollamaModel`, `lettaAgentId` in
  /// its defaults, or the project's), or null when it names none. The Assistant
  /// tab offers it to a deployment's p4n4-api once, while nobody there has
  /// chosen one; after that the deployment's choice stands.
  AssistantConfig? get assistantDefault {
    String? value(String key) => switch (_default<String>(key)) {
      final v? when v.trim().isNotEmpty => v.trim(),
      _ => null,
    };
    final backend = AgentBackend.values.asNameMap()[value('agentBackend')];
    final model = value('ollamaModel'), agent = value('lettaAgentId');
    if (backend == null && model == null && agent == null) return null;
    return AssistantConfig(backend: backend ?? AgentBackend.ollama, model: model, agentId: agent);
  }

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_str('themeMode', 'system')] ?? ThemeMode.system;
  set themeMode(ThemeMode v) => _set('themeMode', v.name);

  /// The language picked in Settings (a code such as `es`), or null to follow
  /// the device. A brand can set the default with `"locale"` in its defaults.
  Locale? get locale => switch (_str('locale', '')) {
    '' => null,
    final code => Locale(code),
  };
  set locale(Locale? v) => _set('locale', v?.languageCode ?? '');

  // Accessibility and region: app-wide, like the theme. A brand can set any
  // of them as a default (e.g. `"textScale": 1.15` for wall-mounted screens).

  /// How much bigger (or smaller) than the device's text size to draw text,
  /// within [textScaleRange].
  double get textScale =>
      switch (_raw('textScale', null) ?? _project?.defaults['textScale'] ?? _defaults['textScale']) {
        num v => v.toDouble().clamp(textScaleRange.$1, textScaleRange.$2),
        _ => 1.0,
      };

  /// Rounded to whole percents, so a slider's steps don't save as 1.1500000001.
  set textScale(double v) => _set('textScale', (v.clamp(textScaleRange.$1, textScaleRange.$2) * 100).round() / 100);

  static const textScaleRange = (0.85, 1.5);

  /// Stronger text and borders, on top of the device's own high-contrast setting.
  bool get highContrast => _bool('highContrast', false);
  set highContrast(bool v) => _set('highContrast', v);

  /// No transitions or animations, on top of the device's own setting.
  bool get reduceMotion => _bool('reduceMotion', false);
  set reduceMotion(bool v) => _set('reduceMotion', v);

  TemperatureUnit get temperatureUnit =>
      TemperatureUnit.values.asNameMap()[_str('temperatureUnit', 'auto')] ?? TemperatureUnit.auto;
  set temperatureUnit(TemperatureUnit v) => _set('temperatureUnit', v.name);

  TimeFormat get timeFormat => TimeFormat.values.asNameMap()[_str('timeFormat', 'auto')] ?? TimeFormat.auto;
  set timeFormat(TimeFormat v) => _set('timeFormat', v.name);

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
  /// Once cameras are saved, that list. Before then, a `videoUrl` the user
  /// stored (in versions before camera lists) appears as one camera named
  /// "Camera"; without one, the connected project's cameras
  /// (`dashboard.cameras` in its `.p4n4.json`, on this deployment's host)
  /// apply, and without those a default `videoUrl` (the project's or the
  /// brand's). A project's cameras never hide one the user set up: saving the
  /// list would then drop it for good.
  List<Camera> get cameras => switch ((deployment.values['cameras'], _raw('videoUrl', null))) {
    (List list, _) => [for (final c in list) Camera.fromJson((c as Map).cast())],
    (_, String url) when url.isNotEmpty => [_singleCamera(url)],
    _ when _project?.cameras.isNotEmpty ?? false => [for (final c in _project!.cameras) c.on(host)],
    _ => [if (_default<String>('videoUrl') case final url? when url.isNotEmpty) _singleCamera(url)],
  };

  static Camera _singleCamera(String url) => Camera(id: 'camera', name: 'Camera', url: url);

  set cameras(List<Camera> v) {
    deployment.values.remove('videoUrl'); // superseded by the list
    _set('cameras', [for (final c in v) c.toJson()]);
  }

  /// Show [demoCameras] in place of [cameras] (which stay as they are).
  bool get videoDemo => _bool('videoDemo', false);
  set videoDemo(bool v) => _set('videoDemo', v);

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

  // Views: each view's tabs and their order, kept by the deployment's p4n4-api

  /// The connected deployment's views (see [ViewsWatcher]); null until
  /// p4n4-api has answered, or without the API. Its fields win over anything
  /// kept on this device and over the brand's defaults.
  DashboardViews? get views => _views;
  DashboardViews? _views;
  set views(DashboardViews? v) {
    if (v == null && _views == null) return;
    _views = v;
    notifyListeners();
  }

  static const _localViewKeys = ['tabOrder', 'powerTabs', 'normieTabs'];

  /// Views an admin set on this device before they moved to p4n4-api, if any;
  /// [loadViews] hands them to the API once.
  DashboardViews? get localViews {
    List<String>? names(String key) => _prefs.getString(key)?.split(',').where((n) => n.isNotEmpty).toList();
    if (!_localViewKeys.any(_prefs.containsKey)) return null;
    return DashboardViews(tabOrder: names('tabOrder'), powerTabs: names('powerTabs'), normieTabs: names('normieTabs'));
  }

  Future<void> forgetLocalViews() async {
    for (final key in _localViewKeys) {
      await _prefs.remove(key);
    }
  }

  /// Tab names for one view field: the API's, else this device's (from before
  /// the API kept them), else the brand's default, else [fallback].
  List<String> _viewNames(List<String>? fromApi, String key, String fallback) =>
      fromApi ?? _str(key, fallback).split(',');

  /// The order of the brand tabs, after Home, in every view. Set by an admin
  /// (or a brand's `tabOrder` default); tabs it leaves out follow in their
  /// default order.
  List<DashTab> get tabOrder {
    final byName = DashTab.values.asNameMap();
    final saved = {for (final n in _viewNames(_views?.tabOrder, 'tabOrder', '')) ?byName[n]};
    return [...saved, ...DashTab.values.where((t) => !saved.contains(t))];
  }

  /// Saves the order for every device (admins only; the API checks).
  Future<void> setTabOrder(List<DashTab> tabs) =>
      _saveViews((v) => DashboardViews(tabOrder: _names(tabs), powerTabs: v.powerTabs, normieTabs: v.normieTabs));

  /// Back to the brand's order, or the default one, on every device.
  Future<void> resetTabOrder() => _saveViews((v) => DashboardViews(powerTabs: v.powerTabs, normieTabs: v.normieTabs));

  /// Brand tabs an admin lets power users and normies see, in [tabOrder].
  /// Admins always see every tab.
  List<DashTab> tabsFor(Role view) {
    final names = switch (view) {
      Role.admin => [for (final t in DashTab.values) t.name],
      Role.power => _viewNames(_views?.powerTabs, 'powerTabs', DashTab.values.map((t) => t.name).join(',')),
      // `clientTabs` is the brand default from before there were three views.
      Role.normie => _views?.normieTabs ?? _str('normieTabs', _str('clientTabs', 'agent,grafana,video')).split(','),
    };
    return [
      for (final t in tabOrder)
        if (names.contains(t.name)) t,
    ];
  }

  /// Saves [view]'s tabs for every device (admins only; the API checks).
  Future<void> setTabsFor(Role view, List<DashTab> tabs) => switch (view) {
    Role.admin => throw ArgumentError('Admins always see every tab'),
    Role.power => _saveViews(
      (v) => DashboardViews(tabOrder: v.tabOrder, powerTabs: _names(tabs), normieTabs: v.normieTabs),
    ),
    Role.normie => _saveViews(
      (v) => DashboardViews(tabOrder: v.tabOrder, powerTabs: v.powerTabs, normieTabs: _names(tabs)),
    ),
  };

  static List<String> _names(List<DashTab> tabs) => [for (final t in tabs) t.name];

  /// Shows [change] at once and saves it to the connected deployment's
  /// p4n4-api; if that fails, puts the views back and rethrows. Unsaved local
  /// views are kept as the starting point, so none of them are lost.
  Future<void> _saveViews(DashboardViews Function(DashboardViews current) change) async {
    final before = _views;
    final next = change(before ?? localViews ?? const DashboardViews());
    views = next;
    try {
      await saveViews(apiUri, next);
    } catch (_) {
      _views = before;
      notifyListeners();
      rethrow;
    }
    await forgetLocalViews();
  }

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

/// How temperatures are shown. [auto] follows the device's region: °F in the
/// few countries that use it, °C everywhere else.
enum TemperatureUnit { auto, celsius, fahrenheit }

/// How times of day are shown. [auto] follows the device's 24-hour setting
/// where it has one, else the language's custom (2:05 PM in English, 14:05 in Spanish).
enum TimeFormat { auto, h12, h24 }

/// Exposes [AppSettings] to the widget tree and rebuilds dependents on change.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child}) : super(notifier: settings);

  static AppSettings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
