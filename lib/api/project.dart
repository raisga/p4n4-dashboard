import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/brand.dart';
import '../core/settings.dart';
import 'status_monitor.dart';

/// What a deployment's `.p4n4.json` says about itself, from p4n4-api
/// `GET /api/v1/project`.
///
/// The manifest's optional `dashboard` block tunes the dashboard per project:
/// `grafana_path` is the Grafana page to open, and `tabs` lists the tabs the
/// project can serve (the others are hidden while connected).
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    this.layers = const [],
    this.template,
    this.templateVersion,
    this.grafanaPath,
    this.tabs,
  });

  final String name;

  /// Stack layers the project runs (`iot`, `ai`, `edge`).
  final List<String> layers;
  final String? template;
  final String? templateVersion;
  final String? grafanaPath;

  /// Null when the manifest doesn't restrict tabs.
  final Set<DashTab>? tabs;

  /// Whether the project runs the catalog stack with [suffix]. p4n4-api
  /// (`api`) isn't a layer, so it always counts, and a manifest without
  /// layers doesn't hide anything.
  bool hasStack(String suffix) => suffix == 'api' || layers.isEmpty || layers.contains(suffix);

  /// Settings defaults the project supplies, ahead of the brand's (see [AppSettings.project]).
  Map<String, Object> get defaults => {'grafanaPath': ?grafanaPath};

  /// Lenient: a malformed `dashboard` block is ignored rather than failing the
  /// connection. `p4n4 validate` reports it.
  factory ProjectInfo.fromJson(Map<String, dynamic> j) {
    final template = j['template'] is Map ? j['template'] as Map : const {};
    final dashboard = j['dashboard'] is Map ? j['dashboard'] as Map : const {};
    final path = dashboard['grafana_path'];
    final tabNames = dashboard['tabs'] is List ? (dashboard['tabs'] as List).whereType<String>().toSet() : null;
    final tabs = tabNames == null ? null : {...DashTab.values.where((t) => tabNames.contains(t.name))};
    return ProjectInfo(
      name: (j['project'] ?? '') as String,
      layers: [...?(j['layers'] as List?)?.whereType<String>()],
      template: template['name'] as String?,
      templateVersion: template['version'] as String?,
      grafanaPath: path is String && path.startsWith('/') ? path : null,
      tabs: tabs == null || tabs.isEmpty ? null : tabs,
    );
  }
}

/// `GET /api/v1/project`.
Future<ProjectInfo> fetchProject(Uri apiBase) async {
  final res = await http.get(apiBase.resolve('api/v1/project')).timeout(const Duration(seconds: 5));
  if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', res.request?.url);
  return ProjectInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

/// Keeps [AppSettings.project] in step with the connected deployment: reads
/// its project through p4n4-api whenever the API URL or host changes, and
/// retries every [retry] while the API can't be reached. A failed read is
/// also retried on the next settings change, which includes signing in.
class ProjectWatcher {
  ProjectWatcher(this.settings, {this.fetch = fetchProject, this.retry = const Duration(seconds: 30)}) {
    settings.addListener(_check);
    _check();
  }

  final AppSettings settings;
  final Future<ProjectInfo> Function(Uri api) fetch;
  final Duration retry;

  StatusTarget? _target;
  Timer? _timer;

  void _check() {
    final target = settings.statusTarget;
    if (target == _target) {
      // Waiting to retry (e.g. 401 before signing in): try now.
      if (_timer?.isActive ?? false) {
        _timer!.cancel();
        _load(target);
      }
      return;
    }
    _target = target;
    _timer?.cancel();
    settings.project = null;
    _load(target);
  }

  Future<void> _load(StatusTarget target) async {
    try {
      final project = await fetch(target.api);
      if (_target == target) settings.project = project;
    } catch (_) {
      if (_target == target) _timer = Timer(retry, () => _load(target));
    }
  }

  void dispose() {
    _timer?.cancel();
    settings.removeListener(_check);
  }
}
