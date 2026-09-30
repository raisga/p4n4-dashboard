import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _load(Map<String, Object> prefs, {Map<String, Object> defaults = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: defaults);
}

void main() {
  test('first run has one deployment that uses the brand defaults', () async {
    final s = await _load({}, defaults: {'host': 'edge.local', 'grafanaPath': '/d/x'});
    expect(s.deployments, hasLength(1));
    expect(s.host, 'edge.local');
    expect(s.grafanaPath, '/d/x');
    expect(s.apiUri, Uri.parse('http://edge.local:8000'));
  });

  test('connecting switches every connection setting but not app-wide ones', () async {
    final s = await _load({});
    s.host = '10.0.0.1';
    s.videoUrl = 'http://10.0.0.1:8080/stream';
    s.themeMode = ThemeMode.dark;
    final site = Deployment(id: s.newDeploymentId(), name: 'Site', values: {'host': '10.0.0.2'});
    await s.saveDeployment(site);

    await s.connect(site.id);
    expect(s.deployment.name, 'Site');
    expect(s.host, '10.0.0.2');
    expect(s.videoUrl, isEmpty);
    expect(s.themeMode, ThemeMode.dark);

    s.grafanaPath = '/d/site';
    await s.connect(s.deployments.first.id);
    expect(s.host, '10.0.0.1');
    expect(s.videoUrl, 'http://10.0.0.1:8080/stream');
    expect(s.grafanaPath, '/');
  });

  test('a deployment can use an API that is not on port 8000', () async {
    final s = await _load({});
    final d = Deployment(id: 'x', name: 'X', values: {'host': 'x.lan', 'apiBase': 'https://api.x.lan'});
    expect(s.apiUriOf(d), Uri.parse('https://api.x.lan'));
    expect(s.apiUriOf(d.copyWith(values: {'host': 'x.lan'})), Uri.parse('http://x.lan:8000'));
  });

  test('the connected deployment cannot be removed; others can', () async {
    final s = await _load({});
    final other = Deployment(id: s.newDeploymentId(), name: 'Other', values: {'host': 'o'});
    await s.saveDeployment(other);
    await s.removeDeployment(s.deployment.id);
    expect(s.deployments, hasLength(2));
    await s.removeDeployment(other.id);
    expect(s.deployments, hasLength(1));
  });

  test('deployments and the connected one survive a restart', () async {
    final s = await _load({});
    final site = Deployment(id: s.newDeploymentId(), name: 'Site', values: {'host': '10.0.0.2'});
    await s.saveDeployment(site);
    await s.connect(site.id);
    s.videoUrl = 'http://cam';

    final again = await AppSettings.load();
    expect(again.deployments.map((d) => d.name), ['Default', 'Site']);
    expect(again.deployment.id, site.id);
    expect(again.videoUrl, 'http://cam');
  });

  group('migration from top-level settings', () {
    test('moves them into the deployment on the current host', () async {
      final s = await _load({
        'host': '10.0.0.5',
        'videoUrl': 'http://cam',
        'themeMode': 'dark',
        'deployments': jsonEncode([
          {'name': 'Lab', 'host': '10.0.0.9'},
          {'name': 'Site', 'host': '10.0.0.5'},
        ]),
      });
      expect(s.deployments.map((d) => d.name), ['Lab', 'Site']);
      expect(s.deployment.name, 'Site');
      expect(s.videoUrl, 'http://cam');
      expect(s.themeMode, ThemeMode.dark);
      expect(s.hostOf(s.deployments.first), '10.0.0.9');
      expect(s.deployments.first.values, isNot(contains('videoUrl')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('host'), isFalse);
      expect(prefs.containsKey('videoUrl'), isFalse);
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('adds a Default deployment when none is on the current host', () async {
      final s = await _load({
        'host': '10.0.0.5',
        'deployments': jsonEncode([
          {'name': 'Lab', 'host': '10.0.0.9'},
        ]),
      });
      expect(s.deployments.map((d) => d.name), ['Default', 'Lab']);
      expect(s.deployment.name, 'Default');
      expect(s.host, '10.0.0.5');
    });
  });
}
