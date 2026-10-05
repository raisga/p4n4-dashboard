import 'dart:convert';

import 'package:http/http.dart' as http;

/// Settings keys holding URLs, which `config.json` may give as paths
/// (`/grafana/`) to resolve against the page.
const _urlKeys = {'apiBase', 'grafanaBase', 'edgeMetricsUrl'};

/// Set by `make run` (`--dart-define=P4N4_DEV_PROXY=true`): the dev server
/// proxies the services like the container does (web_dev_config.yaml), so
/// use the same paths when no `config.json` says otherwise.
const devProxy = bool.fromEnvironment('P4N4_DEV_PROXY');

/// The container's `config.json` routes, for [devProxy].
const devProxyDefaults = <String, dynamic>{'apiBase': '/'};

/// Web only: settings defaults for this deployment, from a `config.json`
/// served next to the app (the container renders it from env vars):
///
/// ```json
/// {"defaults": {"host": "", "apiBase": "/", "grafanaBase": "/grafana/"}}
/// ```
///
/// They sit between the brand's defaults and what the user saved. A missing
/// or broken file never blocks startup: the host then defaults to the machine
/// that served the page, which on web is where the stacks are, not the
/// viewer's `localhost`.
Future<Map<String, Object>> loadRuntimeDefaults(Uri page, {http.Client? client}) async {
  Map<String, dynamic> raw = devProxy ? devProxyDefaults : const {};
  final c = client ?? http.Client();
  try {
    final res = await c.get(page.resolve('config.json')).timeout(const Duration(seconds: 3));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body['defaults'] is Map) raw = (body['defaults'] as Map).cast<String, dynamic>();
    }
  } catch (_) {
    // No config: use the page's host only.
  } finally {
    if (client == null) c.close();
  }
  return runtimeDefaults(raw, page);
}

/// [raw] `config.json` defaults made concrete for [page]: an empty or missing
/// `host` becomes the page's host, and relative URLs resolve against the page.
/// Values that aren't strings or booleans are dropped.
Map<String, Object> runtimeDefaults(Map<String, dynamic> raw, Uri page) {
  final out = <String, Object>{
    for (final MapEntry(:key, :value) in raw.entries)
      if (value is String || value is bool) key: value as Object,
  };
  if ((out['host'] as String? ?? '').isEmpty) {
    out.remove('host');
    if (page.host.isNotEmpty) out['host'] = page.host;
  }
  for (final key in _urlKeys) {
    if (out[key] case final String v when v.isNotEmpty && !Uri.parse(v).hasScheme) {
      out[key] = page.resolve(v).toString();
    }
  }
  return out;
}
