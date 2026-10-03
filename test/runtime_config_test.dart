import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/core/runtime_config.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/widgets/mjpeg_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _page = Uri.parse('http://pi.lan:8088/');

void main() {
  group('runtimeDefaults', () {
    test('an empty host becomes the page host; paths resolve against the page', () {
      final d = runtimeDefaults({'host': '', 'apiBase': '/', 'ollamaBase': '/ollama/', 'lettaBase': 'letta/'}, _page);
      expect(d, {
        'host': 'pi.lan',
        'apiBase': 'http://pi.lan:8088/',
        'ollamaBase': 'http://pi.lan:8088/ollama/',
        'lettaBase': 'http://pi.lan:8088/letta/',
      });
    });

    test('explicit values and absolute URLs are kept; other types are dropped', () {
      final d = runtimeDefaults({
        'host': '10.0.0.5',
        'apiBase': 'http://api.lan:8000',
        'edgeDemo': true,
        'n': 3,
      }, _page);
      expect(d, {'host': '10.0.0.5', 'apiBase': 'http://api.lan:8000', 'edgeDemo': true});
    });

    test('a page under a subpath resolves paths under it', () {
      final d = runtimeDefaults({'ollamaBase': 'ollama/'}, Uri.parse('https://edge.lan/dashboard/'));
      expect(d['ollamaBase'], 'https://edge.lan/dashboard/ollama/');
    });
  });

  group('loadRuntimeDefaults', () {
    Future<Map<String, Object>> load(http.Response Function(http.Request) handler) =>
        loadRuntimeDefaults(_page, client: MockClient((r) async => handler(r)));

    test('reads config.json next to the page', () async {
      Uri? asked;
      final d = await load((r) {
        asked = r.url;
        return http.Response('{"defaults": {"host": "", "apiBase": "/"}}', 200);
      });
      expect(asked, Uri.parse('http://pi.lan:8088/config.json'));
      expect(d, {'host': 'pi.lan', 'apiBase': 'http://pi.lan:8088/'});
    });

    test('without a usable config.json, only the page host applies', () async {
      expect(await load((_) => http.Response('not found', 404)), {'host': 'pi.lan'});
      expect(await load((_) => http.Response('{broken', 200)), {'host': 'pi.lan'});
      expect(await load((_) => http.Response('["no", "defaults"]', 200)), {'host': 'pi.lan'});
      expect(await load((_) => throw http.ClientException('offline')), {'host': 'pi.lan'});
    });
  });

  group('AppSettings', () {
    Future<AppSettings> load(Map<String, Object> defaults, [Map<String, Object> prefs = const {}]) {
      SharedPreferences.setMockInitialValues(prefs);
      return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
    }

    test('brand < runtime config < saved values', () async {
      final brand = {'host': 'localhost', 'edgeDemo': true};
      final runtime = runtimeDefaults({'host': '', 'ollamaBase': '/ollama/'}, _page);
      final s = await load({...brand, ...runtime});
      expect(s.host, 'pi.lan');
      expect(s.edgeDemo, isTrue);
      expect(s.ollamaUri, Uri.parse('http://pi.lan:8088/ollama/'));

      s.host = '10.0.0.9';
      expect(s.host, '10.0.0.9');
    });

    test('base URLs end in a slash, so relative paths keep a proxy prefix', () async {
      expect(AppSettings.baseUri('http://pi.lan/ollama'), Uri.parse('http://pi.lan/ollama/'));
      expect(AppSettings.baseUri('http://pi.lan:8000'), Uri.parse('http://pi.lan:8000/'));
      expect(
        AppSettings.baseUri('http://pi.lan/ollama/').resolve('api/tags'),
        Uri.parse('http://pi.lan/ollama/api/tags'),
      );

      final s = await load({'host': 'pi.lan'});
      expect(s.ollamaUri, Uri.parse('http://pi.lan:11434/'));
      expect(s.lettaUri, Uri.parse('http://pi.lan:8283/'));
      s.apiBase = 'http://pi.lan/p4n4';
      expect(s.edgeMetricsUri, Uri.parse('http://pi.lan/p4n4/api/v1/edge/metrics'));
    });

    test('Grafana pages resolve under the base, keeping a proxy prefix', () async {
      final s = await load({'host': 'pi.lan', 'grafanaPath': '/d/telemetry/home'});
      expect(s.grafanaUri, Uri.parse('http://pi.lan:3000/d/telemetry/home?kiosk=1'));
      s.grafanaBase = 'https://edge.lan/grafana';
      expect(s.grafanaUri, Uri.parse('https://edge.lan/grafana/d/telemetry/home?kiosk=1'));
      s.grafanaKiosk = false;
      s.grafanaPath = '/';
      expect(s.grafanaUri, Uri.parse('https://edge.lan/grafana/'));
    });

    test('resetting the connection brings the defaults back, and keeps cameras', () async {
      final s = await load({'host': 'pi.lan'});
      s.host = '10.0.0.9';
      s.ollamaBase = 'http://other/';
      s.grafanaPath = '/d/x';
      s.edgeDemo = true;
      await s.resetConnection();
      expect(s.host, 'pi.lan');
      expect(s.ollamaBase, '');
      expect(s.grafanaPath, '/');
      expect(s.edgeDemo, isTrue, reason: 'not a connection setting');
    });
  });

  test('web video: still-image URLs are polled as snapshots', () {
    for (final url in [
      'http://cam/snapshot.jpg',
      'http://cam/image.JPEG',
      'http://cam/cgi/snapshot',
      'http://cam/?action=snapshot',
    ]) {
      expect(looksLikeSnapshot(Uri.parse(url)), isTrue, reason: url);
    }
    for (final url in ['http://cam/?action=stream', 'http://go2rtc/api/stream.mjpeg?src=gate', 'http://cam:8081/']) {
      expect(looksLikeSnapshot(Uri.parse(url)), isFalse, reason: url);
    }
  });
}
