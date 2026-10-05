import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/api/camera.dart';
import 'package:p4n4_dashboard/api/fleet.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _load(Map<String, Object> prefs, {Map<String, Object> defaults = const {}, SecretStore? secrets}) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: defaults, secrets: secrets ?? MemorySecretStore());
}

/// What shared_preferences holds, to check no credential is left in it.
Future<String> _savedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return [for (final k in prefs.getKeys()) '$k=${prefs.get(k)}'].join('\n');
}

void main() {
  test('first run has one deployment that uses the brand defaults', () async {
    final s = await _load({}, defaults: {'host': 'edge.local', 'grafanaPath': '/d/x'});
    expect(s.deployments, hasLength(1));
    expect(s.host, 'edge.local');
    expect(s.grafanaPath, '/d/x');
    expect(s.apiUri, Uri.parse('http://edge.local:8000/'));
  });

  test('connecting switches every connection setting but not app-wide ones', () async {
    final s = await _load({});
    s.host = '10.0.0.1';
    s.cameras = [const Camera(id: 'c', name: 'Gate', url: 'http://10.0.0.1:8080/stream')];
    s.themeMode = ThemeMode.dark;
    final site = Deployment(id: s.newDeploymentId(), name: 'Site', values: {'host': '10.0.0.2'});
    await s.saveDeployment(site);

    await s.connect(site.id);
    expect(s.deployment.name, 'Site');
    expect(s.host, '10.0.0.2');
    expect(s.cameras, isEmpty);
    expect(s.themeMode, ThemeMode.dark);

    s.grafanaPath = '/d/site';
    await s.connect(s.deployments.first.id);
    expect(s.host, '10.0.0.1');
    expect(s.cameras.single.url, 'http://10.0.0.1:8080/stream');
    expect(s.grafanaPath, '/');
  });

  test('a deployment can use an API that is not on port 8000', () async {
    final s = await _load({});
    final d = Deployment(id: 'x', name: 'X', values: {'host': 'x.lan', 'apiBase': 'https://api.x.lan'});
    expect(s.apiUriOf(d), Uri.parse('https://api.x.lan/'));
    expect(s.apiUriOf(d.copyWith(values: {'host': 'x.lan'})), Uri.parse('http://x.lan:8000/'));
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
    s.cameras = [const Camera(id: 'c', name: 'Gate', url: 'http://cam')];

    final again = await AppSettings.load(secrets: MemorySecretStore());
    expect(again.deployments.map((d) => d.name), ['Default', 'Site']);
    expect(again.deployment.id, site.id);
    expect(again.cameras.single.name, 'Gate');
  });

  group('cameras', () {
    test('a single videoUrl (e.g. a brand default) appears as one camera', () async {
      final s = await _load({}, defaults: {'videoUrl': 'http://cam/stream'});
      expect(s.cameras.single.url, 'http://cam/stream');
      expect(s.cameras.single.name, 'Camera');
    });

    test('saving cameras replaces the single videoUrl, even with an empty list', () async {
      final s = await _load({}, defaults: {'videoUrl': 'http://cam/stream'});
      final cams = [...s.cameras, Camera(id: s.newCameraId(), name: 'Yard', url: 'http://yard/snap.jpg')];
      s.cameras = cams;
      expect(s.cameras.map((c) => c.name), ['Camera', 'Yard']);
      expect(s.deployment.values, isNot(contains('videoUrl')));

      s.cameras = [];
      expect(s.cameras, isEmpty);
    });

    test('only http(s) URLs with a host are usable', () {
      expect(Camera.parseUrl('http://10.0.0.2:8080/?action=stream'), isNotNull);
      expect(Camera.parseUrl(' https://cam.lan/snap.jpg '), isNotNull);
      expect(Camera.parseUrl('http://'), isNull);
      expect(Camera.parseUrl('rtsp://cam/stream'), isNull);
      expect(Camera.parseUrl('cam.lan'), isNull);
    });

    test('video files and playlists play as video; streams and snapshots don\'t', () {
      for (final url in [
        'https://cdn/clip.mp4',
        'http://nvr/rec/Gate.MOV',
        'http://cam/a.webm',
        'http://hls/live.m3u8',
      ]) {
        expect(
          Camera(id: 'c', name: 'C', url: url).isVideo,
          isTrue,
          reason: url,
        );
      }
      for (final url in ['http://cam/?action=stream', 'http://cam/snapshot.jpg', 'http://cam/mp4', 'not a url.mp4']) {
        expect(
          Camera(id: 'c', name: 'C', url: url).isVideo,
          isFalse,
          reason: url,
        );
      }
      expect(demoCameras.every((c) => c.isVideo && c.id.startsWith('demo-')), isTrue);
    });

    test('demo cameras are a deployment setting that leaves the saved cameras alone', () async {
      final s = await _load({});
      s.cameras = [const Camera(id: 'c', name: 'Gate', url: 'http://cam/stream')];
      s.videoDemo = true;
      expect(s.deployment.values['videoDemo'], isTrue);
      expect(s.cameras.single.name, 'Gate');
    });
  });

  group('credentials', () {
    Deployment d(AppSettings s, String id) => s.deployments.firstWhere((d) => d.id == id);

    test('are kept in secure storage, per deployment, and survive a restart', () async {
      final store = MemorySecretStore();
      final s = await _load({}, secrets: store);
      await s.setApiRefreshToken(s.deployment, 'rt-default');
      final site = Deployment(id: 'site', name: 'Site', values: {'host': 'site'});
      await s.saveDeployment(site);
      expect(s.apiRefreshTokenOf(site), isEmpty);
      await s.setApiRefreshToken(site, 'rt-site');

      expect(store.values, {
        'deployment.default.apiRefreshToken': 'rt-default',
        'deployment.site.apiRefreshToken': 'rt-site',
      });
      expect(await _savedPrefs(), isNot(contains('rt-')));

      final again = await AppSettings.load(secrets: store);
      expect(again.apiRefreshTokenOf(d(again, 'site')), 'rt-site');
      expect(again.apiRefreshTokenOf(d(again, 'default')), 'rt-default');
    });

    test('clearing one deletes it; removing a deployment deletes its own', () async {
      final store = MemorySecretStore({'deployment.default.apiRefreshToken': 'a', 'deployment.x.apiRefreshToken': 'b'});
      final s = await _load({
        'deployments': jsonEncode([
          {'id': 'default', 'name': 'Default', 'values': {}},
          {'id': 'x', 'name': 'X', 'values': {}},
        ]),
      }, secrets: store);
      await s.setApiRefreshToken(s.deployment, '');
      await s.removeDeployment('x');
      expect(store.values, isEmpty);
    });

    test('a plain-text one from an older version moves into secure storage', () async {
      final store = MemorySecretStore();
      final s = await _load({
        'deployments': jsonEncode([
          {
            'id': 'd0',
            'name': 'Site',
            'values': {'host': 'site', 'apiRefreshToken': 'old-rt'},
          },
        ]),
      }, secrets: store);
      expect(s.apiRefreshTokenOf(s.deployment), 'old-rt');
      expect(store.values, {'deployment.d0.apiRefreshToken': 'old-rt'});
      expect(await _savedPrefs(), isNot(contains('old-rt')));
    });

    test('without secure storage, old ones still work and new ones stay in memory', () async {
      final store = MemorySecretStore({}, true);
      final s = await _load({
        'deployments': jsonEncode([
          {
            'id': 'd0',
            'name': 'Site',
            'values': {'host': 'site', 'apiRefreshToken': 'old-rt'},
          },
        ]),
      }, secrets: store);
      expect(s.secureStorageAvailable, isFalse);
      expect(s.apiRefreshTokenOf(s.deployment), 'old-rt');

      await s.setApiRefreshToken(s.deployment, 'new-rt');
      expect(s.apiRefreshTokenOf(s.deployment), 'new-rt');
      expect(store.values, isEmpty);
      expect(await _savedPrefs(), isNot(contains('new-rt')));
    });

    test('a failed write is reported and the value is kept in memory', () async {
      final store = MemorySecretStore();
      final s = await _load({}, secrets: store);
      store.fail = true;
      await s.setApiRefreshToken(s.deployment, 'rt');
      expect(s.secureStorageAvailable, isFalse);
      expect(s.apiRefreshTokenOf(s.deployment), 'rt');
    });

    test('the old Letta password and Ollama/Letta settings are forgotten everywhere', () async {
      // The assistant goes through p4n4-api now, which keeps Letta's password itself.
      final store = MemorySecretStore({'deployment.d0.lettaToken': 'letta-pw', 'deployment.d0.apiRefreshToken': 'rt'});
      final s = await _load({
        'deployments': jsonEncode([
          {
            'id': 'd0',
            'name': 'Site',
            'values': {
              'host': 'site',
              'ollamaBase': '/ollama/',
              'lettaBase': '/letta/',
              'agentBackend': 'letta',
              'ollamaModel': 'llama3.2',
              'lettaAgentId': 'agent-1',
              'lettaToken': 'plain-pw',
            },
          },
        ]),
      }, secrets: store);
      expect(store.values, {'deployment.d0.apiRefreshToken': 'rt'});
      expect(s.deployment.values, {'host': 'site'});
      final saved = await _savedPrefs();
      for (final gone in ['ollama', 'letta', 'agent', '-pw']) {
        expect(saved, isNot(contains(gone)), reason: gone);
      }
    });
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
      expect(s.cameras.single.url, 'http://cam');
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
