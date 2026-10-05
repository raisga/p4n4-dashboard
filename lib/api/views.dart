import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/settings.dart';
import 'project.dart' show ApiWatcher;

/// Which tabs each view shows and their order, from p4n4-api
/// (`GET/PUT /api/v1/dashboard/views`): kept per deployment rather than per
/// browser, so an admin's choice applies on every device. Tab names as the
/// API has them (`agent`, `grafana`, …); a null field means the brand's
/// default, not "no tabs".
class DashboardViews {
  const DashboardViews({this.tabOrder, this.powerTabs, this.normieTabs});

  factory DashboardViews.fromJson(Map<String, dynamic> j) => DashboardViews(
    tabOrder: _names(j['tab_order']),
    powerTabs: _names(j['power_tabs']),
    normieTabs: _names(j['normie_tabs']),
  );

  final List<String>? tabOrder;
  final List<String>? powerTabs;
  final List<String>? normieTabs;

  bool get isEmpty => tabOrder == null && powerTabs == null && normieTabs == null;

  Map<String, Object?> toJson() => {'tab_order': tabOrder, 'power_tabs': powerTabs, 'normie_tabs': normieTabs};

  static List<String>? _names(Object? v) => v is List ? [...v.whereType<String>()] : null;
}

/// A change to the views the API turned down (only admins may), or that never arrived.
class ViewsException implements Exception {
  const ViewsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 8);

Future<DashboardViews> fetchViews(Uri api) async =>
    DashboardViews.fromJson(_body(await http.get(api.resolve('api/v1/dashboard/views')).timeout(_timeout)));

Future<DashboardViews> saveViews(Uri api, DashboardViews views) async {
  final http.Response res;
  try {
    res = await http
        .put(
          api.resolve('api/v1/dashboard/views'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(views.toJson()),
        )
        .timeout(_timeout);
  } on TimeoutException {
    throw const ViewsException('No answer in time.');
  } on http.ClientException catch (e) {
    throw ViewsException(e.message);
  }
  return DashboardViews.fromJson(_body(res));
}

/// [api]'s views. While it has none, the ones this device kept before views
/// moved to the API (an admin's choices, in `shared_preferences`) are offered
/// to it once; the local copy goes as soon as the API has views of its own.
Future<DashboardViews> loadViews(AppSettings settings, Uri api) async {
  final server = await fetchViews(api);
  final local = settings.localViews;
  if (local == null) return server;
  if (!server.isEmpty) {
    await settings.forgetLocalViews();
    return server;
  }
  try {
    final saved = await saveViews(api, local);
    await settings.forgetLocalViews();
    return saved;
  } on ViewsException {
    return server; // not an admin: keep the local copy until one signs in here
  }
}

/// Keeps [AppSettings.views] in step with the connected deployment.
class ViewsWatcher extends ApiWatcher<DashboardViews> {
  ViewsWatcher(super.settings, {Future<DashboardViews> Function(Uri api)? fetch, super.retry})
    : super(fetch: fetch ?? ((api) => loadViews(settings, api)), apply: (v) => settings.views = v);
}

Map<String, dynamic> _body(http.Response res) {
  if (res.statusCode == 200) return (jsonDecode(res.body) as Map).cast();
  String? message;
  try {
    message = ((jsonDecode(res.body) as Map)['error'] as Map)['message'] as String?;
  } catch (_) {}
  throw ViewsException(message ?? 'HTTP ${res.statusCode}', statusCode: res.statusCode);
}
