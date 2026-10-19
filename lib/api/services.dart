import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../platform/probe.dart';
import 'api_error.dart';

class ServiceDef {
  const ServiceDef(
    this.name,
    this.desc,
    this.port,
    this.icon, {
    this.path = '',
    this.tcpOnly = false,
    this.embed = false,
    this.sameOriginOnly = false,
    this.onApi = false,
  });

  /// Catalog name; also used to match the Compose service. A leading "p4n4"
  /// is replaced by the brand's platform name for display (see [label]).
  final String name;
  final String desc;
  final int port;
  final String path;
  final IconData icon;
  final bool tcpOnly;

  /// A web app people use, which the Services tab opens in its embedded
  /// viewer. API-only services (Ollama, Letta, p4n4-api, the inference
  /// runner) and TCP brokers only open in the browser, if at all.
  final bool embed;

  /// Refuses frames from other origins (`X-Frame-Options: SAMEORIGIN`, as
  /// n8n sends): on web it embeds only through the dashboard's proxy.
  final bool sameOriginOnly;

  /// Served by p4n4-api, so it follows the API's base URL (p4n4-api itself,
  /// Swagger UI).
  final bool onApi;

  /// Stable id: lowercase, spaces as dashes (`node-red`, `swagger-ui`). Keys
  /// the per-service URL overrides and matches the Compose service.
  String get id => name.toLowerCase().replaceAll(' ', '-');

  String label(String platform) => name.replaceFirst('p4n4', platform);
}

class StackDef {
  const StackDef(this.label, this.suffix, this.tone, this.services);

  final String label;
  final String suffix;

  /// Picks the stack's colour from the active palette.
  final Color Function(P4Colors) tone;
  final List<ServiceDef> services;
}

/// Service catalog shown in the Services tab.
final stacks = [
  StackDef('IoT Stack', 'iot', (c) => c.blue, [
    ServiceDef('Grafana', 'Dashboards & Visualization', 3000, Icons.show_chart, embed: true),
    ServiceDef('Node-RED', 'Flow Automation', 1880, Icons.account_tree_outlined, embed: true),
    ServiceDef('InfluxDB', 'Time-Series DB', 8086, Icons.storage_outlined, embed: true),
    ServiceDef('MQTT', 'Message Broker', 1883, Icons.wifi_tethering, tcpOnly: true),
  ]),
  StackDef('AI Stack', 'ai', (c) => c.amber, [
    ServiceDef('Ollama', 'Local LLM Inference', 11434, Icons.psychology_outlined),
    ServiceDef('Letta', 'Stateful AI Agents', 8283, Icons.smart_toy_outlined),
    ServiceDef('n8n', 'Workflow Automation', 5678, Icons.hub_outlined, embed: true, sameOriginOnly: true),
    // The edge inference runner: the ai stack's ei-runner profile (it was the edge stack)
    ServiceDef('EI Runner', 'Edge Impulse Inference', 8080, Icons.memory),
  ]),
  StackDef('API Gateway', 'api', (c) => c.text, [
    // It has no page at its root: open (and probe) its health check
    ServiceDef(
      'p4n4-api',
      'REST Gateway — unified entry point for all stacks',
      8000,
      Icons.api,
      path: '/health',
      onApi: true,
    ),
    ServiceDef(
      'Swagger UI',
      'Interactive API docs & explorer',
      8000,
      Icons.menu_book_outlined,
      path: '/swagger-ui',
      embed: true,
      onApi: true,
    ),
  ]),
];

class ComposeService {
  const ComposeService(
    this.name,
    this.state,
    this.health, {
    this.stack = '',
    this.image,
    this.version,
    this.status,
    this.uptime,
  });

  factory ComposeService.fromJson(Map<String, dynamic> j, {String stack = ''}) => ComposeService(
    j['name'] as String,
    j['state'] as String,
    (j['health'] ?? '') as String,
    stack: stack,
    image: j['image'] as String?,
    version: j['version'] as String?,
    status: j['status'] as String?,
    uptime: j['uptime_s'] is num ? Duration(seconds: (j['uptime_s'] as num).toInt()) : null,
  );

  final String name;
  final String state;

  /// `healthy`, `unhealthy`, `starting`, or empty without a healthcheck.
  final String health;

  /// The p4n4-api stack it belongs to (`iot`, `ai`, …), for its logs and restart.
  final String stack;

  /// Its image (`influxdb:2.7`) and that image's tag; null from an API before 0.2.
  final String? image;
  final String? version;

  /// Docker's own summary, e.g. `Up 6 days (healthy)` or `Exited (1) 2 hours ago`.
  final String? status;

  /// How long it has been running; null when it isn't.
  final Duration? uptime;

  bool get running => state == 'running';

  /// Running, but its healthcheck fails.
  bool get unhealthy => running && health == 'unhealthy';
}

/// `GET /api/v1/stacks` → Compose service status, keyed by lowercase service name.
Future<Map<String, ComposeService>> fetchComposeStatus(Uri apiBase) async {
  final res = await http.get(apiBase.resolve('api/v1/stacks')).timeout(const Duration(seconds: 5));
  if (res.statusCode != 200) throw ApiException.from(res);
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  return {
    for (final stack in (body['stacks'] as List).cast<Map>())
      for (final svc in (stack['services'] as List).cast<Map>())
        (svc['name'] as String).toLowerCase(): ComposeService.fromJson(
          svc.cast(),
          stack: stack['name'] as String? ?? '',
        ),
  };
}

/// Maps a catalog entry to its Compose service name(s).
ComposeService? statusFor(ServiceDef def, Map<String, ComposeService> status) {
  final key = def.id;
  final aliases =
      {
        'mqtt': ['mosquitto', 'mqtt'],
        'ei-runner': ['ei-runner', 'edge-impulse', 'runner'],
        'swagger-ui': ['p4n4-api'],
      }[key] ??
      [key];
  for (final a in aliases) {
    for (final e in status.entries) {
      if (e.key == a || e.key.contains(a)) return e.value;
    }
  }
  return null;
}

/// Status of every HTTP catalog entry on one host.
class ServiceReport {
  const ServiceReport(this.up, {required this.viaApi, this.detail = const {}, this.apiProblem});

  /// `null` when p4n4-api answered but has no matching Compose service.
  final Map<ServiceDef, bool?> up;

  /// Whether the status came from p4n4-api rather than port probes.
  final bool viaApi;

  /// When p4n4-api answered but without status (Docker access off, the daemon
  /// down), what it said; null when it came from the API or the API couldn't
  /// be reached.
  final String? apiProblem;

  /// What p4n4-api says about each entry's Compose service (image, uptime,
  /// health); empty from port probes.
  final Map<ServiceDef, ComposeService> detail;

  int get online => up.values.where((v) => v == true).length;
  int get known => up.values.where((v) => v != null).length;

  /// Online/known counts for one stack.
  (int, int) of(StackDef stack) {
    final vs = [
      for (final d in stack.services)
        if (up.containsKey(d)) up[d],
    ].nonNulls;
    return (vs.where((v) => v).length, vs.length);
  }
}

/// Whether a browser on [page] (default: this page) refuses [uri] as mixed
/// content: a plain-HTTP address from an HTTPS page. The device itself
/// (`localhost`, loopback addresses) is exempt, as browsers trust it.
bool blockedAsMixedContent(Uri uri, [Uri? page]) {
  page ??= Uri.base;
  if (!page.isScheme('https') || !uri.isScheme('http')) return false;
  final host = uri.host.toLowerCase();
  return !(host == 'localhost' || host.endsWith('.localhost') || host == '::1' || host.startsWith('127.'));
}

/// Asks p4n4-api at [api] for status and falls back to probing each service's
/// port, built by [urlFor], when the API is unreachable. A probe the browser
/// would block as mixed content says nothing, so that service is unknown.
Future<ServiceReport> checkServices(Uri api, Uri Function(ServiceDef) urlFor) async {
  final defs = [for (final st in stacks) ...st.services.where((d) => !d.tcpOnly)];
  try {
    final status = await fetchComposeStatus(api);
    final found = {for (final d in defs) d: statusFor(d, status)};
    return ServiceReport(
      {for (final MapEntry(:key, :value) in found.entries) key: value?.running},
      viaApi: true,
      detail: {for (final MapEntry(:key, :value) in found.entries) key: ?value},
    );
  } catch (e) {
    final up = await Future.wait(
      defs.map((d) async {
        final url = urlFor(d);
        return blockedAsMixedContent(url) ? null : await probeHttp(url);
      }),
    );
    return ServiceReport(
      Map.fromIterables(defs, up),
      viaApi: false,
      apiProblem: e is ApiException && e.statusCode != null ? e.message : null,
    );
  }
}
