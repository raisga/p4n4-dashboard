import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/agent_client.dart';
import 'package:p4n4_dashboard/api/views.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/role.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _load(Map<String, Object> prefs, {Map<String, Object> defaults = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  return AppSettings.load(defaults: defaults, secrets: MemorySecretStore());
}

/// p4n4-api's views endpoint holding [stored]; records what's PUT, refusing it with [putStatus] 403.
MockClient _api(Map<String, Object?> stored, List<Map<String, Object?>> puts, {int putStatus = 200}) =>
    MockClient((r) async {
      expect(r.url.path, '/api/v1/dashboard/views');
      if (r.method == 'GET') return http.Response(jsonEncode(stored), 200);
      if (putStatus != 200) {
        return http.Response('{"error": {"code": "forbidden", "message": "Requires the admin role."}}', putStatus);
      }
      puts.add((jsonDecode(r.body) as Map).cast());
      return http.Response(r.body, 200);
    });

const _none = {'tab_order': null, 'power_tabs': null, 'normie_tabs': null};

void main() {
  test('views from the API win over this device and the brand', () async {
    final s = await _load({'normieTabs': 'video'}, defaults: {'normieTabs': 'grafana', 'tabOrder': 'edge'});
    expect(s.tabsFor(Role.normie), [DashTab.video], reason: 'no API views yet: the local copy');

    s.views = const DashboardViews(normieTabs: ['agent', 'edge']);
    expect(s.tabsFor(Role.normie), [DashTab.edge, DashTab.agent], reason: "the brand's order still applies");
    expect(s.tabsFor(Role.power), s.tabOrder, reason: 'fields the API leaves null: the defaults');

    s.views = const DashboardViews(normieTabs: [], tabOrder: ['agent']);
    expect(s.tabsFor(Role.normie), isEmpty, reason: 'an empty list hides every tab but Home');
    expect(s.tabOrder.first, DashTab.agent);
  });

  test('changes are saved to the API, whole, and the local copy goes', () async {
    final s = await _load({'powerTabs': 'services,edge'});
    final puts = <Map<String, Object?>>[];
    await http.runWithClient(() => s.setTabsFor(Role.normie, [DashTab.grafana]), () => _api(_none, puts));
    expect(puts, [
      {
        'tab_order': null,
        'power_tabs': ['services', 'edge'], // the device's unsaved choice, kept
        'normie_tabs': ['grafana'],
      },
    ]);
    expect(s.tabsFor(Role.normie), [DashTab.grafana]);
    expect(s.localViews, isNull);
  });

  test('a change the API refuses is undone', () async {
    final s = await _load({});
    s.views = const DashboardViews(normieTabs: ['agent']);
    await expectLater(
      http.runWithClient(() => s.setTabsFor(Role.normie, [DashTab.video]), () => _api(_none, [], putStatus: 403)),
      throwsA(isA<ViewsException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
    expect(s.tabsFor(Role.normie), [DashTab.agent]);
  });

  group('views kept on this device before the API had them', () {
    test('go to an API that has none, once', () async {
      final s = await _load({'normieTabs': 'agent,video', 'tabOrder': 'video,agent'});
      final puts = <Map<String, Object?>>[];
      final views = await http.runWithClient(() => loadViews(s, Uri.parse('http://pi:8000/')), () => _api(_none, puts));
      expect(puts, [
        {
          'tab_order': ['video', 'agent'],
          'power_tabs': null,
          'normie_tabs': ['agent', 'video'],
        },
      ]);
      expect(views.normieTabs, ['agent', 'video']);
      expect(s.localViews, isNull);
    });

    test("are dropped when the API has views of its own", () async {
      final s = await _load({'normieTabs': 'video'});
      final puts = <Map<String, Object?>>[];
      final views = await http.runWithClient(
        () => loadViews(s, Uri.parse('http://pi:8000/')),
        () => _api({
          ..._none,
          'normie_tabs': ['grafana'],
        }, puts),
      );
      expect(puts, isEmpty);
      expect(views.normieTabs, ['grafana']);
      expect(s.localViews, isNull);
    });

    test('stay until an admin signs in on this device', () async {
      final s = await _load({'normieTabs': 'video'});
      final views = await http.runWithClient(
        () => loadViews(s, Uri.parse('http://pi:8000/')),
        () => _api(_none, [], putStatus: 403),
      );
      expect(views.isEmpty, isTrue);
      expect(s.localViews?.normieTabs, ['video']);
      expect(s.tabsFor(Role.normie), [DashTab.video]);
    });
  });

  test('ViewsWatcher follows the connected deployment', () async {
    final s = await _load({});
    final watcher = ViewsWatcher(
      s,
      fetch: (api) async => DashboardViews(normieTabs: [api.host == 'localhost' ? 'agent' : 'video']),
    );
    addTearDown(watcher.dispose);
    await pumpEventQueue();
    expect(s.tabsFor(Role.normie), [DashTab.agent]);

    s.host = 'site-b';
    await pumpEventQueue();
    expect(s.tabsFor(Role.normie), [DashTab.video]);
  });

  group("the brand's assistant", () {
    test('comes from its defaults; blank values and none at all mean no seed', () async {
      expect((await _load({})).assistantDefault, isNull);
      expect((await _load({}, defaults: {'ollamaModel': ' '})).assistantDefault, isNull);
      final s = await _load({}, defaults: {'ollamaModel': 'gemma4:e2b'});
      expect((s.assistantDefault!.backend, s.assistantDefault!.chosen), (AgentBackend.ollama, 'gemma4:e2b'));
      final letta = (await _load({}, defaults: {'agentBackend': 'letta', 'lettaAgentId': 'agent-7'})).assistantDefault!;
      expect((letta.backend, letta.chosen), (AgentBackend.letta, 'agent-7'));
    });

    test('is only offered when the deployment has it installed', () {
      const options = [AgentOption('qwen2.5:0.5b', 'qwen2.5:0.5b')];
      expect(seedAvailable(const AssistantConfig(model: 'qwen2.5:0.5b'), options), isTrue);
      expect(seedAvailable(const AssistantConfig(model: 'gemma4:e2b'), options), isFalse);
      expect(seedAvailable(const AssistantConfig(backend: AgentBackend.letta), const []), isFalse);
      expect(seedAvailable(const AssistantConfig(backend: AgentBackend.letta), options), isTrue);
    });
  });
}
