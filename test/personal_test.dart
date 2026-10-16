import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/api/view_settings.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

Finder _nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);

int _selected(WidgetTester tester) => tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;

const _cameras = [
  Camera(id: 'a', name: 'Gate', url: 'http://cam-a/stream'),
  Camera(id: 'b', name: 'Yard', url: 'http://cam-b/stream'),
];

void main() {
  Future<AppSettings> load([Map<String, Object> prefs = const {}]) {
    SharedPreferences.setMockInitialValues(prefs);
    return AppSettings.load(defaults: {'host': 'pi'}, secrets: MemorySecretStore());
  }

  test('start tab and camera are per deployment; chart history is app-wide', () async {
    final s = await load();
    expect((s.myStartTab, s.defaultCamera, s.edgeHistoryMinutes), ('', '', 2));
    s.myStartTab = 'grafana';
    s.defaultCamera = 'b';
    s.edgeHistoryMinutes = 10;

    final other = Deployment(id: 'site-b', name: 'Site B', values: {'host': 'site-b'});
    await s.saveDeployment(other);
    await s.connect(other.id);
    expect((s.myStartTab, s.defaultCamera, s.edgeHistoryMinutes), ('', '', 10));
  });

  test('a chart history outside the choices reads as 2 minutes', () async {
    expect((await load({'edgeHistoryMinutes': 7})).edgeHistoryMinutes, 2);
  });

  group('on screen', () {
    Future<AppSettings> pump(WidgetTester tester, Role role, [Map<String, Object> prefs = const {}]) async {
      final settings = await load({'edgeDemo': true, 'tourSeen': true, 'role': role.name, ...prefs});
      final brand = loadBrand('p4n4');
      final session = await Session.load(settings, probe: (_) async => AuthMode.off);
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BrandScope(
          brand: brand,
          child: SettingsScope(
            settings: settings,
            child: SessionScope(session: session, child: const DashboardApp()),
          ),
        ),
      );
      await tester.pump();
      return settings;
    }

    testWidgets("a power user's own start tab wins over the view's", (tester) async {
      final settings = await pump(tester, Role.power, {'myStartTab': 'grafana'});
      settings.viewSettings = const DashboardViewSettings(power: ViewPrefs(startTab: 'agent'));
      await tester.pump();
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      final labels = [for (final d in rail.destinations) (d.label as Text).data];
      expect(labels[_selected(tester)], 'Charts');

      settings.myStartTab = '';
      await tester.pump();
      expect(labels[_selected(tester)], 'Assistant', reason: "the view's, once the user has none");
    });

    testWidgets('an admin previewing the normie view gets its start tab, not their own', (tester) async {
      final settings = await pump(tester, Role.admin, {'myStartTab': 'services'});
      settings.viewSettings = const DashboardViewSettings(normie: ViewPrefs(startTab: 'grafana'));
      SessionScope.of(tester.element(find.byType(HomeShell))).preview = Role.normie;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_selected(tester), 2, reason: 'Home, Assistant, Charts: on Charts');
    });

    testWidgets('the Cameras tab opens on the default camera', (tester) async {
      final settings = await pump(tester, Role.power, {'videoGrid': false, 'defaultCamera': 'b'});
      settings.cameras = _cameras;
      await tester.tap(_nav('Cameras'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<MjpegView>(find.byType(MjpegView)).uri.host, 'cam-b');
    });

    testWidgets("the Device tab's charts span the chosen minutes", (tester) async {
      await pump(tester, Role.power, {'edgeHistoryMinutes': 10});
      await tester.tap(_nav('Device'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('10 min ago'), findsWidgets);
      expect(find.text('2 min ago'), findsNothing);
    });

    testWidgets('admins and power users set their defaults in Appearance; normies get none', (tester) async {
      Future<void> openAppearance() async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Appearance'));
        await tester.pump(const Duration(milliseconds: 500));
      }

      final settings = await pump(tester, Role.power);
      settings.cameras = _cameras;
      await openAppearance();
      for (final label in ['Opens on', 'Chart history', 'Default camera']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.byKey(const ValueKey('edgeHistoryMinutes')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('30 minutes').last);
      await tester.pump(const Duration(milliseconds: 500));
      expect(settings.edgeHistoryMinutes, 30);
      await tester.pumpWidget(const SizedBox());

      await pump(tester, Role.normie);
      await openAppearance();
      for (final label in ['Opens on', 'Chart history', 'Default camera']) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });
  });
}
