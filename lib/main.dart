import 'package:flutter/material.dart';

import 'core/brand.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'pages/settings_page.dart';
import 'tabs/agent_tab.dart';
import 'tabs/edge_tab.dart';
import 'tabs/grafana_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/video_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final brand = await Brand.load();
  final settings = await AppSettings.load(defaults: brand.defaults);
  runApp(
    BrandScope(
      brand: brand,
      child: SettingsScope(settings: settings, child: const DashboardApp()),
    ),
  );
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    return MaterialApp(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brand.light),
      darkTheme: buildTheme(brand.dark),
      themeMode: SettingsScope.of(context).themeMode,
      home: const HomeShell(),
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _dests = {
  DashTab.services: _Dest('Services', Icons.apps_outlined, Icons.apps),
  DashTab.edge: _Dest('Edge', Icons.memory_outlined, Icons.memory),
  DashTab.agent: _Dest('Agent', Icons.forum_outlined, Icons.forum),
  DashTab.grafana: _Dest('Grafana', Icons.show_chart_outlined, Icons.show_chart),
  DashTab.video: _Dest('Video', Icons.videocam_outlined, Icons.videocam),
};

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  P4Colors get p4 => context.p4;

  int _index = 0;

  Widget _page(DashTab tab, bool active) => switch (tab) {
    DashTab.services => ServicesTab(active: active),
    DashTab.edge => EdgeTab(active: active),
    DashTab.agent => const AgentTab(),
    DashTab.grafana => const GrafanaTab(),
    DashTab.video => VideoTab(active: active),
  };

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final tabs = brand.tabs;
    final wide = MediaQuery.sizeOf(context).width >= 800;
    // Navigation needs at least two destinations; a single-tab brand gets none.
    final nav = tabs.length > 1;
    // IndexedStack keeps chat history and webviews alive; polling tabs pause via `active`.
    final body = IndexedStack(index: _index, children: [for (final (i, tab) in tabs.indexed) _page(tab, _index == i)]);

    return Scaffold(
      appBar: AppBar(
        title: brand.logo != null
            ? Image.asset(brand.logo!, height: 28, semanticLabel: brand.appName)
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: brand.wordmark),
                    TextSpan(
                      text: brand.wordmarkSuffix,
                      style: p4.mono(size: 18, color: p4.muted, weight: FontWeight.w700, spacing: -0.05),
                    ),
                  ],
                ),
              ),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text('// ${SettingsScope.of(context).host}', style: p4.mono())),
            ),
          _ThemeToggle(SettingsScope.of(context)),
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.tune, color: p4.muted),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide && nav
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in tabs.map((t) => _dests[t]!))
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
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              height: 64,
              destinations: [
                for (final d in tabs.map((t) => _dests[t]!))
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
