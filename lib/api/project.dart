import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/brand.dart';
import '../core/settings.dart';
import 'camera.dart';
import 'status_monitor.dart';

/// What a deployment's `.p4n4.json` says about itself, from p4n4-api
/// `GET /api/v1/project`.
///
/// The manifest's optional `dashboard` block tunes the dashboard per project:
/// `grafana_path` is the Grafana page to open, `tabs` lists the tabs the
/// project can serve (the others are hidden while connected), and `cameras`
/// lists the streams the Video tab shows (see [ProjectCamera]).
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    this.layers = const [],
    this.template,
    this.templateVersion,
    this.grafanaPath,
    this.tabs,
    this.cameras = const [],
  });

  final String name;

  /// Stack layers the project runs (`iot`, `ai`, `edge`).
  final List<String> layers;
  final String? template;
  final String? templateVersion;
  final String? grafanaPath;

  /// Null when the manifest doesn't restrict tabs.
  final Set<DashTab>? tabs;

  /// The project's cameras, in display order; empty when it lists none.
  final List<ProjectCamera> cameras;

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
      cameras: [
        if (dashboard['cameras'] case final List list)
          for (final c in list.whereType<Map>()) ?ProjectCamera.fromJson(c.cast<String, dynamic>()),
      ],
    );
  }
}

/// A camera from the manifest's `dashboard.cameras`: an absolute `url`, or a
/// `port` and `path` on whichever host the dashboard is connected to (the
/// manifest can't know it), e.g. go2rtc's `{"port": 1984, "path":
/// "/api/stream.mjpeg?src=floor"}`.
class ProjectCamera {
  const ProjectCamera({required this.id, required this.name, this.url, this.port, this.path = '/'});

  final String id;
  final String name;
  final String? url;
  final int? port;
  final String path;

  /// The [Camera] on [host]; [url] when set, else http://host:port/path.
  Camera on(String host) => Camera(id: id, name: name, url: url ?? 'http://$host:$port$path');

  /// Null (skipped) unless it has an id, a name, and either an http(s) url or a port.
  static ProjectCamera? fromJson(Map<String, dynamic> j) {
    final (id, name, url, port, path) = (j['id'], j['name'], j['url'], j['port'], j['path'] ?? '/');
    if (id is! String || id.isEmpty || name is! String || name.isEmpty || path is! String || !path.startsWith('/')) {
      return null;
    }
    if (url is String && Camera.parseUrl(url) != null) return ProjectCamera(id: id, name: name, url: url);
    if (port is int && port > 0 && port < 65536) return ProjectCamera(id: id, name: name, port: port, path: path);
    return null;
  }
}

/// `GET /api/v1/project`.
Future<ProjectInfo> fetchProject(Uri apiBase) async {
  final res = await http.get(apiBase.resolve('api/v1/project')).timeout(const Duration(seconds: 5));
  if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', res.request?.url);
  return ProjectInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

/// Keeps something the connected deployment's p4n4-api says in step with it:
/// reads it whenever the API URL or host changes, hands it to [apply] (null
/// while switching), and retries every [retry] while the API can't be
/// reached. A failed read is also retried on the next settings change, which
/// includes signing in.
class ApiWatcher<T> {
  ApiWatcher(this.settings, {required this.fetch, required this.apply, this.retry = const Duration(seconds: 30)}) {
    settings.addListener(_check);
    _check();
  }

  final AppSettings settings;
  final Future<T> Function(Uri api) fetch;
  final void Function(T? value) apply;
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
    apply(null);
    _load(target);
  }

  Future<void> _load(StatusTarget target) async {
    try {
      final value = await fetch(target.api);
      if (_target == target) apply(value);
    } catch (_) {
      if (_target == target) _timer = Timer(retry, () => _load(target));
    }
  }

  void dispose() {
    _timer?.cancel();
    settings.removeListener(_check);
  }
}

/// Keeps [AppSettings.project] in step with the connected deployment.
class ProjectWatcher extends ApiWatcher<ProjectInfo> {
  ProjectWatcher(super.settings, {super.fetch = fetchProject, super.retry}) : super(apply: (p) => settings.project = p);
}
