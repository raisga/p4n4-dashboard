import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/role.dart';
import '../core/settings.dart';
import 'project.dart' show ApiWatcher;

/// Home's cards: the "is everything OK" summary, the device's readings, and
/// the project's own page (HOME.md).
enum HomeCard { status, device, page }

/// Which alerts pop up as toasts: all, only those that ask for review, none.
enum AlertLevel { all, review, off }

/// What one view shows besides its tabs, as an admin set it for every device
/// (`GET/PUT /api/v1/dashboard/view-settings`). Null fields are the defaults.
/// Presentation only: p4n4-api still decides what each role may read.
class ViewPrefs {
  const ViewPrefs({
    this.startTab,
    this.homeCards,
    this.grafanaPath,
    this.cameras,
    this.cameraOverlay,
    this.alerts,
    this.alertSound,
  });

  factory ViewPrefs.fromJson(Object? json) {
    final j = json is Map ? json.cast<String, Object?>() : const <String, Object?>{};
    List<String>? names(Object? v) => v is List ? [...v.whereType<String>()] : null;
    return ViewPrefs(
      startTab: j['start_tab'] as String?,
      homeCards: switch (names(j['home_cards'])) {
        final cards? => {for (final c in cards) ?HomeCard.values.asNameMap()[c]},
        null => null,
      },
      grafanaPath: j['grafana_path'] as String?,
      cameras: names(j['cameras']),
      cameraOverlay: j['camera_overlay'] as bool?,
      alerts: AlertLevel.values.asNameMap()[j['alerts']],
      alertSound: j['alert_sound'] as bool?,
    );
  }

  /// `home` or a tab's name (`agent`, …).
  final String? startTab;
  final Set<HomeCard>? homeCards;

  /// Its Grafana page, instead of the deployment's.
  final String? grafanaPath;

  /// The deployment's cameras it shows, by id.
  final List<String>? cameras;
  final bool? cameraOverlay;
  final AlertLevel? alerts;
  final bool? alertSound;

  bool showsCard(HomeCard card) => homeCards?.contains(card) ?? true;

  /// Whether it shows camera [id]; a demo camera (`demo-<id>`) goes with the camera it stands in for.
  bool showsCamera(String id) {
    final ids = cameras;
    return ids == null || ids.contains(id) || (id.startsWith('demo-') && ids.contains(id.substring(5)));
  }

  bool get overlay => cameraOverlay ?? true;
  AlertLevel get alertLevel => alerts ?? AlertLevel.all;
  bool get chime => alertSound ?? true;

  static const _keep = Object();

  /// A copy with the fields given changed; pass null to go back to a default.
  ViewPrefs copyWith({
    Object? startTab = _keep,
    Object? homeCards = _keep,
    Object? grafanaPath = _keep,
    Object? cameras = _keep,
    Object? cameraOverlay = _keep,
    Object? alerts = _keep,
    Object? alertSound = _keep,
  }) => ViewPrefs(
    startTab: identical(startTab, _keep) ? this.startTab : startTab as String?,
    homeCards: identical(homeCards, _keep) ? this.homeCards : homeCards as Set<HomeCard>?,
    grafanaPath: identical(grafanaPath, _keep) ? this.grafanaPath : grafanaPath as String?,
    cameras: identical(cameras, _keep) ? this.cameras : cameras as List<String>?,
    cameraOverlay: identical(cameraOverlay, _keep) ? this.cameraOverlay : cameraOverlay as bool?,
    alerts: identical(alerts, _keep) ? this.alerts : alerts as AlertLevel?,
    alertSound: identical(alertSound, _keep) ? this.alertSound : alertSound as bool?,
  );

  Map<String, Object?> toJson() => {
    'start_tab': startTab,
    // In Home's own order, whatever order they were picked in.
    'home_cards': homeCards == null
        ? null
        : [
            for (final c in HomeCard.values)
              if (homeCards!.contains(c)) c.name,
          ],
    'grafana_path': grafanaPath,
    'cameras': cameras,
    'camera_overlay': cameraOverlay,
    'alerts': alerts?.name,
    'alert_sound': alertSound,
  };

  @override
  bool operator ==(Object other) => other is ViewPrefs && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// The power and normie views' [ViewPrefs]. Admins always get the defaults.
class DashboardViewSettings {
  const DashboardViewSettings({this.power = const ViewPrefs(), this.normie = const ViewPrefs()});

  factory DashboardViewSettings.fromJson(Map<String, dynamic> j) =>
      DashboardViewSettings(power: ViewPrefs.fromJson(j['power']), normie: ViewPrefs.fromJson(j['normie']));

  final ViewPrefs power;
  final ViewPrefs normie;

  ViewPrefs of(Role view) => switch (view) {
    Role.admin => const ViewPrefs(),
    Role.power => power,
    Role.normie => normie,
  };

  DashboardViewSettings withView(Role view, ViewPrefs prefs) => switch (view) {
    Role.admin => throw ArgumentError('Admins always get the defaults'),
    Role.power => DashboardViewSettings(power: prefs, normie: normie),
    Role.normie => DashboardViewSettings(power: power, normie: prefs),
  };

  Map<String, Object?> toJson() => {'power': power.toJson(), 'normie': normie.toJson()};

  // Re-read every minute: the same settings again don't rebuild the app.
  @override
  bool operator ==(Object other) => other is DashboardViewSettings && other.power == power && other.normie == normie;

  @override
  int get hashCode => Object.hash(power, normie);
}

/// A change the API turned down (only admins may), or that never arrived.
class ViewSettingsException implements Exception {
  const ViewSettingsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 8);

Future<DashboardViewSettings> fetchViewSettings(Uri api) async => DashboardViewSettings.fromJson(
  _body(await http.get(api.resolve('api/v1/dashboard/view-settings')).timeout(_timeout)),
);

/// Replaces both views' settings, for every device.
Future<DashboardViewSettings> saveViewSettings(Uri api, DashboardViewSettings settings) async {
  final http.Response res;
  try {
    res = await http
        .put(
          api.resolve('api/v1/dashboard/view-settings'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(settings.toJson()),
        )
        .timeout(_timeout);
  } on TimeoutException {
    throw const ViewSettingsException('No answer in time.');
  } on http.ClientException catch (e) {
    throw ViewSettingsException(e.message);
  }
  return DashboardViewSettings.fromJson(_body(res));
}

/// Keeps [AppSettings.viewSettings] in step with the connected deployment,
/// asking again every [every], so an admin's change reaches a wall tablet
/// nobody touches.
class ViewSettingsWatcher extends ApiWatcher<DashboardViewSettings> {
  ViewSettingsWatcher(
    super.settings, {
    super.fetch = fetchViewSettings,
    super.retry,
    super.every = const Duration(minutes: 1),
  }) : super(apply: (v) => settings.viewSettings = v);
}

// UTF-8 whatever the content type says: `res.body` would read paths and ids as Latin-1.
Map<String, dynamic> _body(http.Response res) {
  if (res.statusCode == 200) return (jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast();
  String? message;
  try {
    message = ((jsonDecode(utf8.decode(res.bodyBytes)) as Map)['error'] as Map)['message'] as String?;
  } catch (_) {}
  throw ViewSettingsException(message ?? 'HTTP ${res.statusCode}', statusCode: res.statusCode);
}
