import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/auth.dart' show AuthMode;
import 'package:p4n4_dashboard/api/metrics_monitor.dart';
import 'package:p4n4_dashboard/api/status_monitor.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/session.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brands.dart';

/// [label] in the navigation rail or bar.
Finder nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);

/// The whole app as [role] sees it on a [size] screen, signed in through the
/// role picker (p4n4-api "runs without auth"), with demo edge readings unless
/// [prefs] say otherwise. [status] and [metrics] answer without a network.
Future<AppSettings> pumpApp(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  Role role = Role.admin,
  Map<String, Object> prefs = const {},
  Map<String, dynamic> brandExtra = const {},
  StatusMonitor? status,
  MetricsMonitor? metrics,
}) async {
  SharedPreferences.setMockInitialValues({
    'edgeDemo': true,
    'tourSeen': true,
    'themeMode': 'light',
    'role': role.name,
    ...prefs,
  });
  final brand = loadBrand('p4n4', extra: brandExtra);
  final settings = await AppSettings.load(defaults: brand.defaults, secrets: MemorySecretStore());
  final session = await Session.load(settings, probe: (_) async => AuthMode.off);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BrandScope(
      brand: brand,
      child: SettingsScope(
        settings: settings,
        child: SessionScope(
          session: session,
          child: DashboardApp(status: status, metrics: metrics),
        ),
      ),
    ),
  );
  await tester.pump();
  return settings;
}

/// Lets a frame or two (and the microtasks they start) run.
Future<void> settle(WidgetTester tester, [int frames = 3]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
