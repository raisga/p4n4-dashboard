import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/camera.dart';
import '../api/fleet.dart';
import 'brand.dart';

enum AgentBackend { ollama, letta }

/// Settings that belong to a deployment, so switching deployments switches
/// them all. Everything else (theme, client tabs) is app-wide.
const profileKeys = {
  'host',
  'apiBase',
  'edgeMetricsUrl',
  'edgeDemo',
  'agentBackend',
  'ollamaModel',
  'lettaAgentId',
  'lettaToken',
  'grafanaPath',
  'grafanaKiosk',
  'videoUrl',
  'cameras',
};

/// User-editable settings, persisted with shared_preferences.
///
/// Keys in [profileKeys] are read from and written to the active
/// [deployment]; the getters below always reflect whichever one is connected.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._defaults) {
    _loadDeployments();
  }

  final SharedPreferences _prefs;

  /// Brand-supplied defaults, used until the user changes a value.
  final Map<String, Object> _defaults;

  late List<Deployment> _deployments;
  late String _activeId;

  static Future<AppSettings> load({Map<String, Object> defaults = const {}}) async =>
      AppSettings._(await SharedPreferences.getInstance(), defaults);

  Object? _raw(String key, Deployment? d) =>
      profileKeys.contains(key) ? (d ?? deployment).values[key] : _prefs.get(key);

  String _str(String key, String fallback, [Deployment? d]) => switch (_raw(key, d)) {
    String v => v,
    _ => _default(key) ?? fallback,
  };

  bool _bool(String key, bool fallback, [Deployment? d]) => switch (_raw(key, d)) {
    bool v => v,
    _ => _default(key) ?? fallback,
  };

  T? _default<T>(String key) => switch (_defaults[key]) {
    T v => v,
    null => null,
    final v => throw FormatException('Brand default "$key" should be a $T, got ${v.runtimeType}'),
  };

  Future<void> _set(String key, Object value) async {
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

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_str('themeMode', 'system')] ?? ThemeMode.system;
  set themeMode(ThemeMode v) => _set('themeMode', v.name);

  /// Host running the p4n4 stacks. Use 10.0.2.2 from the Android emulator.
  String get host => hostOf(deployment);
  set host(String v) => _set('host', v.trim());

  /// Builds `http://<host>:<port><path>`.
  Uri url(int port, [String path = '']) => Uri.parse('http://$host:$port$path');

  // p4n4-api gateway
  String get apiBase => _str('apiBase', '');
  set apiBase(String v) => _set('apiBase', v.trim());
  Uri get apiUri => apiUriOf(deployment);

  // Edge metrics
  String get edgeMetricsUrl => _str('edgeMetricsUrl', '');
  set edgeMetricsUrl(String v) => _set('edgeMetricsUrl', v.trim());
  Uri get edgeMetricsUri =>
      edgeMetricsUrl.isNotEmpty ? Uri.parse(edgeMetricsUrl) : apiUri.resolve('/api/v1/edge/metrics');

  bool get edgeDemo => _bool('edgeDemo', false);
  set edgeDemo(bool v) => _set('edgeDemo', v);

  // Agent chat
  AgentBackend get agentBackend =>
      AgentBackend.values.asNameMap()[_str('agentBackend', 'ollama')] ?? AgentBackend.ollama;
  set agentBackend(AgentBackend v) => _set('agentBackend', v.name);

  String get ollamaModel => _str('ollamaModel', '');
  set ollamaModel(String v) => _set('ollamaModel', v.trim());

  String get lettaAgentId => _str('lettaAgentId', '');
  set lettaAgentId(String v) => _set('lettaAgentId', v.trim());

  String get lettaToken => _str('lettaToken', '');
  set lettaToken(String v) => _set('lettaToken', v.trim());

  // Grafana
  String get grafanaPath => _str('grafanaPath', '/');
  set grafanaPath(String v) => _set('grafanaPath', v.trim().isEmpty ? '/' : v.trim());

  bool get grafanaKiosk => _bool('grafanaKiosk', true);
  set grafanaKiosk(bool v) => _set('grafanaKiosk', v);

  Uri get grafanaUri {
    final u = url(3000).resolve(grafanaPath);
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
    return base.isNotEmpty ? Uri.parse(base) : Uri.parse('http://${hostOf(d)}:8000');
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
    _deployments.removeWhere((d) => d.id == id);
    await _saveDeployments();
    notifyListeners();
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
