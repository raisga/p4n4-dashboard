import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api/agent_client.dart' show viaPageProxy;
import 'api/auth.dart';
import 'api/project.dart';
import 'api/status_monitor.dart';
import 'core/brand.dart';
import 'core/runtime_config.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'pages/login_page.dart';
import 'platform/http_client.dart';
import 'pages/settings_page.dart';
import 'tabs/agent_tab.dart';
import 'tabs/clients_tab.dart';
import 'tabs/edge_tab.dart';
import 'tabs/grafana_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/video_tab.dart';
import 'widgets/common.dart';

Future<void> main() async {
  final credentials = _SessionCredentials();
  // Every request goes through AuthClient, which adds the signed-in user's
  // token to the connected deployment's p4n4-api calls (lib/api/auth.dart).
  await http.runWithClient(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final brand = await Brand.load()
      ..registerFontLicenses();
    // Lowest priority first: brand < config.json (web) < what the user saved.
    final runtime = kIsWeb ? await loadRuntimeDefaults(Uri.base) : const <String, Object>{};
    final settings = await AppSettings.load(defaults: {...brand.defaults, ...runtime});
    final session = credentials.session = await Session.load(settings);
    ProjectWatcher(settings); // lives as long as the app
    runApp(
      BrandScope(
        brand: brand,
        child: SettingsScope(
          settings: settings,
          child: SessionScope(session: session, child: const DashboardApp()),
        ),
      ),
    );
  }, () => AuthClient(newHttpClient(), credentials, viaProxy: (url) => kIsWeb && viaPageProxy(url)));
}

/// The session once it's loaded: requests made before that (config.json, the
/// first project fetch) go out without a token.
class _SessionCredentials implements ApiCredentials {
  Session? session;

  @override
  String? accessTokenFor(Uri url) => session?.accessTokenFor(url);

  @override
  Future<String?> refreshFor(Uri url) => session?.refreshFor(url) ?? Future.value();
}

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  /// Above the navigator, so pushed screens (e.g. Clients on phones) share it.
  final _status = StatusMonitor();

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final role = SessionScope.of(context).role;
    final app = MaterialApp(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brand.light),
      darkTheme: buildTheme(brand.dark),
      themeMode: SettingsScope.of(context).themeMode,
      // Keyed by role so switching views starts from a fresh shell.
      home: role == null ? const LoginPage() : HomeShell(key: ValueKey(role)),
    );
    return StatusScope(monitor: _status, child: app);
  }
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A navigation destination: one of the brand's tabs, or a screen that only
/// one view has (Home for clients, Clients for admins).
enum Screen {
  home,
  clients,
  services,
  edge,
  agent,
  grafana,
  video;

  static Screen of(DashTab t) => values.byName(t.name);

  DashTab? get tab => DashTab.values.asNameMap()[name];
}

const _dests = {
  Screen.home: _Dest('Home', Icons.home_outlined, Icons.home),
  Screen.clients: _Dest('Clients', Icons.devices_other_outlined, Icons.devices_other),
  Screen.services: _Dest('Services', Icons.apps_outlined, Icons.apps),
  Screen.edge: _Dest('Edge', Icons.memory_outlined, Icons.memory),
  Screen.agent: _Dest('Agent', Icons.forum_outlined, Icons.forum),
  Screen.grafana: _Dest('Grafana', Icons.show_chart_outlined, Icons.show_chart),
  Screen.video: _Dest('Video', Icons.videocam_outlined, Icons.videocam),
};

/// Screens for [role]: admins get every brand tab plus Clients; clients get
/// Home plus the brand tabs an admin has enabled for them. Either way, tabs the
/// connected project doesn't serve (its `.p4n4.json` `dashboard.tabs`) are left out.
List<Screen> screensFor(Role role, Brand brand, AppSettings settings) {
  final tabs = brand.tabs.where(settings.projectAllows);
  return switch (role) {
    Role.admin => [...tabs.map(Screen.of), Screen.clients],
    Role.client => [Screen.home, ...tabs.where(settings.clientTabs.contains).map(Screen.of)],
  };
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  P4Colors get p4 => context.p4;

  int _index = 0;

  /// [all] and [open] are for Home's shortcut cards.
  Widget _page(Screen screen, bool active, List<Screen> all, ValueChanged<Screen> open) => switch (screen) {
    Screen.home => OverviewTab(
      active: active,
      shortcuts: [for (final s in all) ?s.tab],
      onOpen: (t) => open(Screen.of(t)),
    ),
    Screen.clients => ClientsTab(active: active),
    Screen.services => ServicesTab(active: active),
    Screen.edge => EdgeTab(active: active),
    Screen.agent => const AgentTab(),
    Screen.grafana => const GrafanaTab(),
    Screen.video => VideoTab(active: active),
  };

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    final admin = session.isAdmin;
    final all = screensFor(session.role!, brand, SettingsScope.of(context));
    final wide = MediaQuery.sizeOf(context).width >= 800;
    // A phone bottom bar fits five destinations; the rest open from the app bar.
    final screens = wide ? all : all.take(5).toList();
    final extra = all.skip(screens.length);
    final index = _index.clamp(0, screens.length - 1);
    void open(Screen s) {
      if (screens.contains(s)) {
        setState(() => _index = screens.indexOf(s));
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(_dests[s]!.label.toLowerCase())),
            body: _page(s, true, all, open),
          ),
        ),
      );
    }

    // Navigation needs at least two destinations; a single-screen view gets none.
    final nav = screens.length > 1;
    // IndexedStack keeps chat history and webviews alive; polling tabs pause via `active`.
    final body = IndexedStack(
      index: index,
      children: [
        for (final (i, s) in screens.indexed) KeyedSubtree(key: ValueKey(s), child: _page(s, index == i, all, open)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(),
        actions: [
          if (wide) ...[
            if (admin) Center(child: Text('// ${_connection(SettingsScope.of(context))}', style: p4.mono())),
            const SizedBox(width: 12),
            Center(child: TagBadge(admin ? 'admin' : 'client', color: admin ? p4.amber : p4.accent)),
            const SizedBox(width: 8),
          ],
          for (final s in extra)
            IconButton(
              tooltip: _dests[s]!.label,
              icon: Icon(_dests[s]!.icon, color: p4.muted),
              onPressed: () => open(s),
            ),
          _ThemeToggle(SettingsScope.of(context)),
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.tune, color: p4.muted),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: Icon(Icons.logout, color: p4.muted),
            onPressed: session.signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide && nav
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in screens.map((s) => _dests[s]!))
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label.toUpperCase()),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide || !nav
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              height: 64,
              destinations: [
                for (final d in screens.map((s) => _dests[s]!))
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label.toUpperCase(),
                  ),
              ],
            ),
    );
  }
}

/// The connected deployment, named once there's more than one to tell apart.
String _connection(AppSettings s) => s.deployments.length > 1 ? '${s.deployment.name} · ${s.host}' : s.host;

/// Cycles system → light → dark.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle(this.settings);

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final (icon, label, next) = switch (settings.themeMode) {
      ThemeMode.system => (Icons.brightness_auto_outlined, 'system', ThemeMode.light),
      ThemeMode.light => (Icons.light_mode_outlined, 'light', ThemeMode.dark),
      ThemeMode.dark => (Icons.dark_mode_outlined, 'dark', ThemeMode.system),
    };
    return IconButton(
      tooltip: 'Theme: $label',
      icon: Icon(icon, color: context.p4.muted),
      onPressed: () => settings.themeMode = next,
    );
  }
}
