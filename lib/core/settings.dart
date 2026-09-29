import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgentBackend { ollama, letta }

/// User-editable connection settings, persisted with shared_preferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._defaults);

  final SharedPreferences _prefs;

  /// Brand-supplied defaults, used until the user changes a value.
  final Map<String, Object> _defaults;

  static Future<AppSettings> load({Map<String, Object> defaults = const {}}) async =>
      AppSettings._(await SharedPreferences.getInstance(), defaults);

  String _str(String key, String fallback) => _prefs.getString(key) ?? _default(key) ?? fallback;
  bool _bool(String key, bool fallback) => _prefs.getBool(key) ?? _default(key) ?? fallback;

  T? _default<T>(String key) => switch (_defaults[key]) {
    T v => v,
    null => null,
    final v => throw FormatException('Brand default "$key" should be a $T, got ${v.runtimeType}'),
  };

  Future<void> _set(String key, Object value) async {
    switch (value) {
      case String v:
        await _prefs.setString(key, v);
      case bool v:
        await _prefs.setBool(key, v);
    }
    notifyListeners();
  }

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_str('themeMode', 'system')] ?? ThemeMode.system;
  set themeMode(ThemeMode v) => _set('themeMode', v.name);

  /// Host running the p4n4 stacks. Use 10.0.2.2 from the Android emulator.
  String get host => _str('host', 'localhost');
  set host(String v) => _set('host', v.trim());

  /// Builds `http://<host>:<port><path>`.
  Uri url(int port, [String path = '']) => Uri.parse('http://$host:$port$path');

  // p4n4-api gateway
  String get apiBase => _str('apiBase', '');
  set apiBase(String v) => _set('apiBase', v.trim());
  Uri get apiUri => apiBase.isNotEmpty ? Uri.parse(apiBase) : url(8000);

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

  // Video feed: MJPEG stream or a JPEG snapshot URL.
  String get videoUrl => _str('videoUrl', '');
  set videoUrl(String v) => _set('videoUrl', v.trim());
}

/// Exposes [AppSettings] to the widget tree and rebuilds dependents on change.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child}) : super(notifier: settings);

  static AppSettings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
