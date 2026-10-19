import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/agent_client.dart' show AgentBackend, AssistantConfig;
import '../api/banner.dart' show DashboardBanner;
import '../api/camera.dart';
import '../api/fleet.dart';
import '../api/metrics_monitor.dart' show MetricsSource;
import '../api/project.dart';
import '../api/services.dart' show ServiceDef, StackDef;
import '../api/status_monitor.dart';
import '../api/view_settings.dart' show DashboardViewSettings, ViewPrefs, saveViewSettings;
import '../api/views.dart';
import '../api/vision.dart' show VisionBundle;
import 'brand.dart';
import 'role.dart';
import 'secrets.dart';
import 'thresholds.dart';

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
  'serviceUrls',
  'videoUrl',
  'cameras',
  'videoDemo',
  'session',
  'myStartTab',
  'defaultCamera',
  'thresholds',
};

/// Profile keys that say where the services are, cleared by
/// [AppSettings.resetConnection].
const connectionKeys = {
  'host',
  'apiBase',
  'edgeMetricsUrl',
  'grafanaBase',
  'grafanaPath',
  'grafanaKiosk',
  'serviceUrls',
};

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
        case int v:
          await _prefs.setInt(key, v);
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

  // An admin's or power user's own defaults on this device (Settings →
  // Appearance). Start tab and camera are per deployment: each has its own.

  /// The tab this device opens on (`home` or a tab's name), over the view's
  /// start tab; empty for the view's.
  String get myStartTab => _str('myStartTab', '');
  set myStartTab(String v) => _set('myStartTab', v);

  /// The camera the Cameras tab shows first, by id; empty for the first one.
  String get defaultCamera => _str('defaultCamera', '');
  set defaultCamera(String v) => _set('defaultCamera', v);

  /// How many minutes of readings the Device tab's charts show.
  int get edgeHistoryMinutes => switch (_int('edgeHistoryMinutes', 2)) {
    final m when edgeHistoryOptions.contains(m) => m,
    _ => 2,
  };
  set edgeHistoryMinutes(int v) => _set('edgeHistoryMinutes', v);

  static const edgeHistoryOptions = [2, 10, 30];

  // This device as a shared screen (Settings → This device). App-wide: they're
  // about the device, whichever deployment it shows.

  /// Kiosk mode: the viewer (normie) view is locked on this device. No sign
  /// out, theme or settings but Accessibility; an admin's sign-in leaves it.
  bool get kiosk => _bool('kiosk', false);

  /// Turns kiosk mode on or off. Turning it on keeps the accessibility
  /// settings as they are now, for [restoreKioskAccessibility].
  set kiosk(bool v) {
    if (v) {
      _prefs.setString(
        'kioskAccessibility',
        jsonEncode({'textScale': textScale, 'highContrast': highContrast, 'reduceMotion': reduceMotion}),
      );
    }
    _set('kiosk', v);
  }

  /// Puts text size, contrast and motion back to what they were when kiosk
  /// mode was turned on: a visitor's larger text doesn't stay for the next.
  void restoreKioskAccessibility() {
    final Map<String, Object?> saved;
    try {
      saved = (jsonDecode(_prefs.getString('kioskAccessibility') ?? '{}') as Map).cast();
    } on Object {
      return;
    }
    if (saved['textScale'] case num v when v != textScale) textScale = v.toDouble();
    if (saved['highContrast'] case bool v when v != highContrast) highContrast = v;
    if (saved['reduceMotion'] case bool v when v != reduceMotion) reduceMotion = v;
  }

  /// Minutes without a touch or key after which a kiosk goes back to where
  /// it starts, its conversation cleared; 0 never.
  int get kioskIdleReset => _int('kioskIdleReset', 5);
  set kioskIdleReset(int v) => _set('kioskIdleReset', v);

  /// Minutes without a touch or key after which an admin or power user is
  /// signed out on this device; 0 never.
  int get idleSignOut => _int('idleSignOut', 0);
  set idleSignOut(int v) => _set('idleSignOut', v);

  int _int(String key, int fallback) => switch (_raw(key, null) ?? _default<Object>(key)) {
    num v => v.toInt(),
    _ => fallback,
  };

  /// Whether this device has shown (or been told to skip) the normie view's
  /// tour of the shell. Settings → Account → Take the tour clears it.
  bool get tourSeen => _bool('tourSeen', false);
  set tourSeen(bool v) => _set('tourSeen', v);

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
  Uri get edgeMetricsUri => metricsSourceOf(deployment).uri;

  bool get edgeDemo => _bool('edgeDemo', false);
  set edgeDemo(bool v) => _set('edgeDemo', v);

  /// Where [d]'s edge readings come from (see [MetricsMonitor]): its metrics
  /// URL, else its p4n4-api's; or made up, with demo data on.
  MetricsSource metricsSourceOf(Deployment d) {
    final url = _str('edgeMetricsUrl', '', d);
    return (
      uri: url.isNotEmpty ? Uri.parse(url) : apiUriOf(d).resolve('api/v1/edge/metrics'),
      demo: _bool('edgeDemo', false, d),
    );
  }

  /// The connected deployment's [metricsSourceOf].
  MetricsSource get metricsSource => metricsSourceOf(deployment);

  /// When the connected deployment's readings turn high or critical (Settings → Thresholds).
  Thresholds get thresholds => thresholdsOf(deployment);

  /// [d]'s thresholds: as set on this device, else the project's or brand's
  /// `thresholds` default, else the built-in ones.
  Thresholds thresholdsOf(Deployment d) => switch (d.values['thresholds'] ?? _default<Map>('thresholds')) {
    final Map m => Thresholds.fromJson(m.cast()),
    _ => const Thresholds(),
  };

  /// Whether the connected deployment's thresholds were set on this device.
  bool get ownThresholds => deployment.values.containsKey('thresholds');

  /// Saves the connected deployment's thresholds; null goes back to the defaults.
  Future<void> setThresholds(Thresholds? t) async {
    t == null ? deployment.values.remove('thresholds') : deployment.values['thresholds'] = t.toJson();
    await _saveDeployments();
    notifyListeners();
  }

  // Grafana

  /// Grafana's base URL; empty means `http://<host>:3000/`. Behind the
  /// container's proxy it's `/grafana/` (same origin, so it works over HTTPS).
  String get grafanaBase => _str('grafanaBase', '');
  set grafanaBase(String v) => _set('grafanaBase', v.trim());

  String get grafanaPath => _str('grafanaPath', '/');
  set grafanaPath(String v) => _set('grafanaPath', v.trim().isEmpty ? '/' : v.trim());

  bool get grafanaKiosk => _bool('grafanaKiosk', true);
  set grafanaKiosk(bool v) => _set('grafanaKiosk', v);

  Uri get grafanaUri => grafanaUriFor(Role.admin);

  /// Grafana's home: [grafanaBase], else port 3000 on the host.
  Uri get grafanaHome => grafanaBase.isNotEmpty ? baseUri(grafanaBase) : url(3000, '/');

  /// The Grafana page [view] opens: its own (Settings → Views), else the
  /// deployment's. Normies always get kiosk mode: Grafana's menus aren't theirs.
  Uri grafanaUriFor(Role view) {
    final base = grafanaHome;
    final path = prefsFor(view).grafanaPath ?? grafanaPath;
    // Relative to the base, so a proxy prefix (/grafana/) is kept.
    final u = base.resolve(path.replaceFirst(RegExp('^/+'), ''));
    if (!grafanaKiosk && view != Role.normie) return u;
    return u.replace(queryParameters: {...u.queryParameters, 'kiosk': '1'});
  }

  // Services opened from the Services tab

  /// URLs set on this device for the services the Services tab opens (Settings
  /// → Endpoints), by [ServiceDef.id]. Grafana keeps its own [grafanaBase].
  Map<String, String> get serviceUrls => _urlMap(deployment.values['serviceUrls']);

  /// Sets (or, when empty, clears) [def]'s URL on this device.
  Future<void> setServiceUrl(ServiceDef def, String url) async {
    final urls = {...serviceUrls};
    url.trim().isEmpty ? urls.remove(def.id) : urls[def.id] = url.trim();
    urls.isEmpty ? deployment.values.remove('serviceUrls') : deployment.values['serviceUrls'] = urls;
    await _saveDeployments();
    notifyListeners();
  }

  /// [def]'s URL when this device sets none: the project's (`.p4n4.json`
  /// `dashboard.services`), else the deployment's (`config.json`
  /// `serviceUrls`, e.g. a proxied `/svc/node-red/`) or the brand's, else its
  /// port on the host (Swagger UI: under p4n4-api's base URL).
  Uri defaultServiceUri(ServiceDef def) {
    final given = _urlMap(_project?.defaults['serviceUrls'])[def.id] ?? _urlMap(_defaults['serviceUrls'])[def.id];
    if (given != null) return pageUri(given);
    if (def.onApi) return apiUri.resolve(def.path.replaceFirst(RegExp('^/+'), ''));
    return url(def.port, def.path);
  }

  /// Where [def] opens, embedded or in the browser: the URL set on this
  /// device, else [defaultServiceUri]. Grafana opens at [grafanaHome] for
  /// admins and power users, and at the view's own page, in kiosk mode, for
  /// normies (see [grafanaUriFor]).
  Uri serviceUri(ServiceDef def, {Role view = Role.admin}) {
    if (def.id == 'grafana') return view.technical ? grafanaHome : grafanaUriFor(view);
    final own = serviceUrls[def.id];
    return own != null ? pageUri(own) : defaultServiceUri(def);
  }

  /// Where [StatusMonitor] probes [def] for [t] when p4n4-api can't say: on
  /// the connected deployment, the address a web app or p4n4-api opens at
  /// (it may be proxied, with no port published); else null, its port on the
  /// host.
  Uri? probeUriOf(StatusTarget t, ServiceDef def) =>
      t == statusTarget && (def.embed || def.onApi) ? serviceUri(def) : null;

  /// A full URL as given, or a path resolved against the page (web, behind a proxy).
  static Uri pageUri(String value) {
    final uri = Uri.parse(value.trim());
    return uri.hasScheme ? uri : Uri.base.resolveUri(uri);
  }

  /// Service id → URL, keeping only non-empty strings.
  static Map<String, String> _urlMap(Object? raw) => {
    if (raw is Map)
      for (final MapEntry(:key, :value) in raw.entries)
        if (key is String && value is String && value.trim().isNotEmpty) key: value.trim(),
  };

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

  /// In the grid, a frame every few seconds rather than full motion, for slow
  /// links (Settings → Appearance). App-wide: it's about this device's link.
  bool get videoGridLight => _bool('videoGridLight', false);
  set videoGridLight(bool v) => _set('videoGridLight', v);

  /// Show [demoCameras] in place of [cameras] (which stay as they are).
  bool get videoDemo => _bool('videoDemo', false);
  set videoDemo(bool v) => _set('videoDemo', v);

  /// Open the Video tab on every camera at once, rather than one. App-wide,
  /// like the theme: it's how this device shows them.
  bool get videoGrid => _bool('videoGrid', true);
  set videoGrid(bool v) => _set('videoGrid', v);

  /// What the connected project draws over its cameras (see [VisionWatcher]);
  /// null until p4n4-api has answered, or when the project has none.
  VisionBundle? get vision => _vision;
  VisionBundle? _vision;
  set vision(VisionBundle? v) {
    if (v == null && _vision == null) return;
    _vision = v;
    notifyListeners();
  }

  /// Chime when an alert that asks to check something (a risk) comes in.
  /// App-wide, like the theme: it's about this device's speakers.
  bool get alertSound => _bool('alertSound', true);
  set alertSound(bool v) => _set('alertSound', v);

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

  static String _chatKey(Deployment d, String who) => 'chat.${d.id}.$who';

  /// The Assistant conversation [who] had on [d], as `{role, content}` maps.
  /// Kept on this device so it outlives a reload and signing out and back in.
  List<Map<String, String>> chatOf(Deployment d, String who) {
    try {
      return [
        for (final m in jsonDecode(_prefs.getString(_chatKey(d, who)) ?? '[]') as List)
          (m as Map).cast<String, String>(),
      ];
    } on Object {
      return []; // unreadable: start over
    }
  }

  /// Stores (or, empty, forgets) [who]'s conversation on [d]. It changes with
  /// every message, so this doesn't notify listeners.
  Future<void> setChatOf(Deployment d, String who, List<Map<String, String>> messages) =>
      messages.isEmpty ? _prefs.remove(_chatKey(d, who)) : _prefs.setString(_chatKey(d, who), jsonEncode(messages));

  /// How the Assistant answers on this device: an [AssistantStyle]'s name.
  AssistantStyle get assistantStyle =>
      AssistantStyle.values.asNameMap()[_str('assistantStyle', 'standard')] ?? AssistantStyle.standard;
  set assistantStyle(AssistantStyle v) => _set('assistantStyle', v.name);

  /// The instructions for [AssistantStyle.custom], written by an admin or power user.
  String get assistantCustomPrompt => _str('assistantCustomPrompt', '');
  set assistantCustomPrompt(String v) => _set('assistantCustomPrompt', v.trim());

  static String _incidentsKey(Deployment d) => 'incidents.${d.id}';

  /// [d]'s service outages seen from this device, oldest first (see [IncidentLog]).
  List<Map<String, Object?>> incidentsOf(Deployment d) {
    try {
      return [for (final m in jsonDecode(_prefs.getString(_incidentsKey(d)) ?? '[]') as List) (m as Map).cast()];
    } on Object {
      return [];
    }
  }

  /// Stores (or, empty, forgets) [d]'s incidents. [IncidentLog] notifies its own listeners.
  Future<void> setIncidentsOf(Deployment d, List<Map<String, Object?>> incidents) =>
      incidents.isEmpty ? _prefs.remove(_incidentsKey(d)) : _prefs.setString(_incidentsKey(d), jsonEncode(incidents));

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
    if (v == _views) return;
    _views = v;
    notifyListeners();
  }

  /// The message an admin put above every view (see [BannerWatcher]); null
  /// until p4n4-api has answered, or without the API.
  DashboardBanner? get banner => _banner;
  DashboardBanner? _banner;
  set banner(DashboardBanner? v) {
    if (v == _banner) return;
    _banner = v;
    notifyListeners();
  }

  /// What else each view shows (see [ViewSettingsWatcher]); null until
  /// p4n4-api has answered, or without the API.
  DashboardViewSettings? get viewSettings => _viewSettings;
  DashboardViewSettings? _viewSettings;
  set viewSettings(DashboardViewSettings? v) {
    if (v == _viewSettings) return;
    _viewSettings = v;
    notifyListeners();
  }

  /// [view]'s settings; the defaults for admins, and until the API answers.
  ViewPrefs prefsFor(Role view) => _viewSettings?.of(view) ?? const ViewPrefs();

  /// Shows [prefs] for [view] at once and saves them on the connected
  /// deployment's p4n4-api (admins only; the API checks); if that fails, puts
  /// them back and rethrows.
  Future<void> setPrefsFor(Role view, ViewPrefs prefs) async {
    final before = _viewSettings;
    final next = (before ?? const DashboardViewSettings()).withView(view, prefs);
    viewSettings = next;
    try {
      await saveViewSettings(apiUri, next);
    } catch (_) {
      _viewSettings = before;
      notifyListeners();
      rethrow;
    }
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

  /// The tabs this deployment knows: [DashTab.defaults], plus the feed when the
  /// connected project serves one. An opt-in tab stays out of views and saved
  /// orders until then, so an API that predates it is never sent its name.
  List<DashTab> get knownTabs => [
    ...DashTab.defaults,
    if (_project?.tabs?.contains(DashTab.feed) ?? false) DashTab.feed,
  ];

  /// The order of the brand tabs, after Home, in every view. Set by an admin
  /// (or a brand's `tabOrder` default); tabs it leaves out follow in their
  /// default order.
  List<DashTab> get tabOrder {
    final known = knownTabs;
    final byName = known.asNameMap();
    final saved = {for (final n in _viewNames(_views?.tabOrder, 'tabOrder', '')) ?byName[n]};
    return [...saved, ...known.where((t) => !saved.contains(t))];
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
      Role.admin => [for (final t in knownTabs) t.name],
      Role.power => _viewNames(_views?.powerTabs, 'powerTabs', knownTabs.map((t) => t.name).join(',')),
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
      for (final key in _prefs.getKeys().where((k) => k.startsWith('chat.${d.id}.')).toList()) {
        await _prefs.remove(key);
      }
      await _prefs.remove(_incidentsKey(d));
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

/// How the Assistant answers (Settings, or the Assistant's toolbar): extra
/// instructions sent with each conversation, on this device. [custom] is an
/// admin's or power user's own ([AppSettings.assistantCustomPrompt]).
enum AssistantStyle { standard, brief, steps, simple, custom }

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
