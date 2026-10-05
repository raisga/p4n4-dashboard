import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api/auth.dart';
import 'api/project.dart';
import 'api/status_monitor.dart';
import 'api/views.dart';
import 'core/brand.dart';
import 'core/runtime_config.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'l10n/l10n.dart';
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
    // Both live as long as the app.
    ProjectWatcher(settings);
    ViewsWatcher(settings);
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
    final settings = SettingsScope.of(context);
    // Settings → Accessibility adds to the device's own settings, never takes away from them.
    final device = MediaQuery.of(context);
    final reduceMotion = settings.reduceMotion || device.disableAnimations;
    final highContrast = settings.highContrast || device.highContrast;
    ThemeData theme(P4Colors c) => buildTheme(highContrast ? c.contrasted : c, reduceMotion: reduceMotion);
    final app = MaterialApp(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: theme(brand.light),
      darkTheme: theme(brand.dark),
      themeMode: settings.themeMode,
      themeAnimationDuration: reduceMotion ? Duration.zero : kThemeAnimationDuration,
      // The language picked in Settings, else the device's if supported, else English.
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Keyed by role so switching views starts from a fresh shell.
      home: role == null ? const LoginPage() : HomeShell(key: ValueKey(role)),
    );
    // MaterialApp takes these from the MediaQuery above it (see MediaQuery.fromView's platformData).
    return StatusScope(
      monitor: _status,
      child: MediaQuery(
        data: device.copyWith(
          textScaler: _scaled(device.textScaler, settings.textScale),
          disableAnimations: reduceMotion,
          highContrast: highContrast,
        ),
        child: app,
      ),
    );
  }
}

/// The device's text scaler, [factor] times bigger (Settings → Accessibility → Text size).
TextScaler _scaled(TextScaler device, double factor) => factor == 1 ? device : _ScaledTextScaler(device, factor);

class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this.device, this.factor);

  final TextScaler device;
  final double factor;

  @override
  double scale(double fontSize) => device.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => device.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is _ScaledTextScaler && other.device == device && other.factor == factor;

  @override
  int get hashCode => Object.hash(device, factor);
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);

  final String Function(AppLocalizations) label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A navigation destination: one of the brand's tabs, Home (every view's
/// first) or Clients (admins only, last).
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

final _dests = {
  Screen.home: _Dest((l) => l.navHome, Icons.home_outlined, Icons.home),
  Screen.clients: _Dest((l) => l.navClients, Icons.devices_other_outlined, Icons.devices_other),
  Screen.services: _Dest((l) => l.navServices, Icons.apps_outlined, Icons.apps),
  Screen.edge: _Dest((l) => l.navEdge, Icons.memory_outlined, Icons.memory),
  Screen.agent: _Dest((l) => l.navAgent, Icons.forum_outlined, Icons.forum),
  Screen.grafana: _Dest((l) => l.navGrafana, Icons.show_chart_outlined, Icons.show_chart),
  Screen.video: _Dest((l) => l.navVideo, Icons.videocam_outlined, Icons.videocam),
};

/// Screens for [role]: Home, then the brand tabs in the admin's
/// [AppSettings.tabOrder] (every tab for admins, the ones an admin has enabled
/// for power users and normies), then Clients for admins. Tabs the connected
/// project doesn't serve (its `.p4n4.json` `dashboard.tabs`) are always left out.
List<Screen> screensFor(Role role, Brand brand, AppSettings settings) => [
  Screen.home,
  ...settings.tabsFor(role).where(brand.tabs.contains).where(settings.projectAllows).map(Screen.of),
  if (role == Role.admin) Screen.clients,
];

/// Each view's badge colour.
Color roleColor(P4Colors p4, Role role) => switch (role) {
  Role.admin => p4.amber,
  Role.power => p4.blue,
  Role.normie => p4.accent,
};

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  P4Colors get p4 => context.p4;

  /// The open screen, kept by identity so reordering tabs doesn't switch it.
  Screen? _selected;

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
    final l = context.l10n;
    final role = session.role!;
    final all = screensFor(role, brand, SettingsScope.of(context));
    final wide = MediaQuery.sizeOf(context).width >= 800;
    // A phone bottom bar fits five destinations; the rest open from the app bar.
    final screens = wide ? all : all.take(5).toList();
    final extra = all.skip(screens.length);
    final index = screens.indexOf(_selected ?? Screen.home).clamp(0, screens.length - 1);
    void select(int i) => setState(() => _selected = screens[i]);
    void open(Screen s) {
      if (screens.contains(s)) {
        setState(() => _selected = s);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(_dests[s]!.label(l))),
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
            if (role.technical) _ConnectionLabel(_connection(SettingsScope.of(context))),
            const SizedBox(width: 12),
            Center(child: TagBadge(l.roleName(role), color: roleColor(p4, role))),
            const SizedBox(width: 8),
          ],
          for (final s in extra)
            IconButton(
              tooltip: _dests[s]!.label(l),
              icon: Icon(_dests[s]!.icon, color: p4.muted),
              onPressed: () => open(s),
            ),
          _ThemeToggle(SettingsScope.of(context)),
          IconButton(
            tooltip: l.settingsTooltip,
            icon: Icon(Icons.tune, color: p4.muted),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          IconButton(
            tooltip: l.signOutTooltip,
            icon: Icon(Icons.logout, color: p4.muted),
            onPressed: session.signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _withPreviewBanner(
        session,
        wide && nav
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in screens.map((s) => _dests[s]!))
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label(l)),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide || !nav
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              height: 64,
              destinations: [
                for (final d in screens.map((s) => _dests[s]!))
                  NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label(l)),
              ],
            ),
    );
  }
}

/// While an admin previews another view, a banner above it says so and leads back.
Widget _withPreviewBanner(Session session, Widget body) => switch (session.preview) {
  null => body,
  final view => Column(
    children: [
      _PreviewBanner(view, onExit: () => session.preview = null),
      Expanded(child: body),
    ],
  ),
};

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner(this.view, {required this.onExit});

  final Role view;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    return Material(
      color: roleColor(p4, view).withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: roleColor(p4, view)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.previewingView(l.roleName(view)), style: p4.body(size: 14, weight: FontWeight.w500)),
            ),
            TextButton(onPressed: onExit, child: Text(l.backToAdmin)),
          ],
        ),
      ),
    );
  }
}

/// The connected deployment, named once there's more than one to tell apart.
String _connection(AppSettings s) => s.deployments.length > 1 ? '${s.deployment.name} · ${s.host}' : s.host;

/// Where the dashboard is connected, for admins and power users.
class _ConnectionLabel extends StatelessWidget {
  const _ConnectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dns_outlined, size: 15, color: p4.muted),
          const SizedBox(width: 6),
          Text(text, style: p4.mono(size: 12, spacing: 0)),
        ],
      ),
    );
  }
}

/// Cycles system → light → dark.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle(this.settings);

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, label, next) = switch (settings.themeMode) {
      ThemeMode.system => (Icons.brightness_auto_outlined, l.themeSystem, ThemeMode.light),
      ThemeMode.light => (Icons.light_mode_outlined, l.themeLight, ThemeMode.dark),
      ThemeMode.dark => (Icons.dark_mode_outlined, l.themeDark, ThemeMode.system),
    };
    return IconButton(
      tooltip: l.themeTooltip(label),
      icon: Icon(icon, color: context.p4.muted),
      onPressed: () => settings.themeMode = next,
    );
  }
}
