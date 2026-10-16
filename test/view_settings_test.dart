import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/view_settings.dart';
import 'package:p4n4_dashboard/api/vision.dart' show VisionTone;
import 'package:p4n4_dashboard/core/alerts.dart';
import 'package:p4n4_dashboard/core/role.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _load([Map<String, Object> prefs = const {}]) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: {'host': 'pi'}, secrets: MemorySecretStore());
}

const _normie = {
  'start_tab': 'agent',
  'home_cards': ['status', 'page'],
  'grafana_path': '/d/simple/overview',
  'cameras': ['gate'],
  'camera_overlay': false,
  'alerts': 'review',
  'alert_sound': false,
};

void main() {
  test('reads each view from the API, and admins always get the defaults', () {
    final v = DashboardViewSettings.fromJson({'normie': _normie, 'power': <String, Object?>{}});
    final n = v.of(Role.normie);
    expect(n.startTab, 'agent');
    expect([for (final c in HomeCard.values) n.showsCard(c)], [true, false, true]);
    expect((n.grafanaPath, n.overlay, n.alertLevel, n.chime), ('/d/simple/overview', false, AlertLevel.review, false));
    expect(n.showsCamera('gate'), isTrue);
    expect(n.showsCamera('demo-gate'), isTrue, reason: 'the demo camera that stands in for it');
    expect(n.showsCamera('yard'), isFalse);
    expect(n.toJson(), _normie, reason: 'and back, unchanged');

    for (final p in [v.of(Role.power), v.of(Role.admin)]) {
      expect(p, const ViewPrefs());
      expect(
        (p.showsCard(HomeCard.device), p.showsCamera('any'), p.overlay, p.alertLevel, p.chime),
        (true, true, true, AlertLevel.all, true),
      );
    }
    expect(() => v.withView(Role.admin, const ViewPrefs()), throwsArgumentError);
  });

  test('copyWith changes only what it is given; null goes back to the default', () {
    const p = ViewPrefs(startTab: 'agent', alerts: AlertLevel.off);
    expect(
      p.copyWith(alertSound: false),
      const ViewPrefs(startTab: 'agent', alerts: AlertLevel.off, alertSound: false),
    );
    expect(p.copyWith(startTab: null), const ViewPrefs(alerts: AlertLevel.off));
  });

  test('home cards go to the API in Home\'s order', () {
    expect(const ViewPrefs(homeCards: {HomeCard.page, HomeCard.status}).toJson()['home_cards'], ['status', 'page']);
  });

  test('a change shows at once, is saved whole, and is undone if refused', () async {
    final s = await _load();
    final sent = <Object?>[];
    await http.runWithClient(
      () => s.setPrefsFor(Role.normie, const ViewPrefs(startTab: 'grafana')),
      () => MockClient((r) async {
        expect((r.method, r.url.path), ('PUT', '/api/v1/dashboard/view-settings'));
        sent.add(jsonDecode(r.body));
        return http.Response(r.body, 200);
      }),
    );
    expect((sent.single as Map)['normie']['start_tab'], 'grafana');
    expect((sent.single as Map)['power']['start_tab'], isNull);
    expect(s.prefsFor(Role.normie).startTab, 'grafana');

    await expectLater(
      http.runWithClient(
        () => s.setPrefsFor(Role.normie, const ViewPrefs(startTab: 'video')),
        () => MockClient(
          (_) async => http.Response('{"error": {"code": "forbidden", "message": "Requires the admin role."}}', 403),
        ),
      ),
      throwsA(isA<ViewSettingsException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
    expect(s.prefsFor(Role.normie).startTab, 'grafana');
  });

  test("each view opens its own Grafana page; normies always in kiosk mode", () async {
    final s = await _load({'grafanaPath': '/d/full/plant', 'grafanaKiosk': false});
    s.viewSettings = const DashboardViewSettings(normie: ViewPrefs(grafanaPath: '/d/simple/overview'));
    expect('${s.grafanaUriFor(Role.normie)}', 'http://pi:3000/d/simple/overview?kiosk=1');
    expect('${s.grafanaUriFor(Role.power)}', 'http://pi:3000/d/full/plant');
    expect(s.grafanaUri, s.grafanaUriFor(Role.admin));
  });

  test('the same view settings again change nothing', () async {
    final s = await _load();
    var notified = 0;
    s.addListener(() => notified++);
    s.viewSettings = DashboardViewSettings.fromJson({'normie': _normie});
    s.viewSettings = DashboardViewSettings.fromJson({'normie': _normie});
    expect(notified, 1);
  });

  test('an alert center can turn alerts away, as a view says', () {
    var level = AlertLevel.review;
    final center = AlertCenter(
      chime: () async {},
      accept: (n) => switch (level) {
        AlertLevel.all => true,
        AlertLevel.review => n.tone == VisionTone.review,
        AlertLevel.off => false,
      },
    );
    addTearDown(center.dispose);
    expect(center.raise(AlertNotice(id: '1', title: 'FYI')), isFalse);
    expect(center.raise(AlertNotice(id: '2', title: 'Risk', tone: VisionTone.review)), isTrue);
    level = AlertLevel.off;
    expect(center.raise(AlertNotice(id: '3', title: 'Risk', tone: VisionTone.review)), isFalse);
    expect(center.shown.map((n) => n.id), ['2']);
  });
}
