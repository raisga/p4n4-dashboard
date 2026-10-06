import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import 'admin_sections.dart';

/// Settings' categories, in the order they're listed.
///
/// Everyone gets the personal ones (this device's preferences, nothing that
/// changes the system) and About. Power users also get the connection and
/// endpoint settings; admins also views, users and diagnostics.
enum SettingsCategory {
  account,
  appearance,
  accessibility,
  language,
  connection,
  endpoints,
  views,
  users,
  diagnostics,
  about,
}

/// Headings the categories are listed under; About goes last, under none.
enum _Heading { personal, deployment, admin, app }

/// What the category list shows for a category, and what its page holds.
class _Category {
  const _Category(
    this.id,
    this.group,
    this.icon,
    this.title, {
    required this.summary,
    required this.keywords,
    required this.build,
  });

  final SettingsCategory id;
  final _Heading group;
  final IconData icon;
  final String title;

  /// Its current values in a line (e.g. "English · °C · 2:05 PM"), or what it holds.
  final String summary;

  /// The labels of the settings in it, for search.
  final List<String> keywords;

  final WidgetBuilder build;
}

/// The categories [context]'s user gets, in order.
List<_Category> _categories(BuildContext context) {
  final s = SettingsScope.of(context);
  final brand = BrandScope.of(context);
  final session = SessionScope.of(context);
  final l = context.l10n;
  final f = context.formats;
  final endpoints = [
    if (brand.tabs.contains(DashTab.edge)) l.sectionEdgeMetrics,
    if (brand.tabs.contains(DashTab.grafana)) l.sectionGrafana,
    if (brand.tabs.contains(DashTab.video)) l.sectionVideo,
  ];
  return [
    _Category(
      SettingsCategory.account,
      _Heading.personal,
      Icons.person_outline,
      l.sectionAccount,
      summary: _accountView(l, session, brand),
      keywords: [l.signOut, ?session.username, if (session.signedInRole == Role.normie) l.takeTour],
      build: (_) => const _AccountPage(),
    ),
    _Category(
      SettingsCategory.appearance,
      _Heading.personal,
      Icons.palette_outlined,
      l.sectionAppearance,
      summary: _themeName(l, s.themeMode),
      keywords: [l.themeHeading, l.themeSystem, l.themeLight, l.themeDark],
      build: (_) => const _AppearancePage(),
    ),
    _Category(
      SettingsCategory.accessibility,
      _Heading.personal,
      Icons.accessibility_new,
      l.sectionAccessibility,
      summary: [
        l.textSizeValue(_percent(f, s.textScale)),
        if (s.highContrast) l.highContrast,
        if (s.reduceMotion) l.reduceMotion,
      ].join(' · '),
      keywords: [l.textSize, l.highContrast, l.reduceMotion],
      build: (_) => const _AccessibilityPage(),
    ),
    _Category(
      SettingsCategory.language,
      _Heading.personal,
      Icons.translate,
      l.sectionLanguageRegion,
      summary: [
        languageName(Localizations.localeOf(context).languageCode).native,
        f.fahrenheit ? '°F' : '°C',
        f.clock(DateTime.now()),
      ].join(' · '),
      keywords: [
        l.sectionLanguage,
        l.temperatureUnit,
        l.timeFormat,
        for (final code in supportedLanguages) ...[languageName(code).native, languageName(code).english],
      ],
      build: (_) => const _LanguagePage(),
    ),
    if (session.isTechnical) ...[
      _Category(
        SettingsCategory.connection,
        _Heading.deployment,
        Icons.dns_outlined,
        l.sectionConnection,
        summary: s.deployments.length > 1 ? '${s.deployment.name} · ${s.host}' : s.host,
        keywords: [l.fieldDeployment, l.fieldHost, l.apiBaseUrl(brand.platform), l.resetConnection],
        build: (_) => const _ConnectionPage(),
      ),
      if (endpoints.isNotEmpty)
        _Category(
          SettingsCategory.endpoints,
          _Heading.deployment,
          Icons.hub_outlined,
          l.sectionEndpoints,
          summary: '',
          keywords: [
            ...endpoints,
            if (brand.tabs.contains(DashTab.edge)) ...[l.metricsUrl, if (session.isAdmin) l.demoData],
            if (brand.tabs.contains(DashTab.grafana)) ...[
              l.grafanaBaseUrl,
              l.dashboardPath,
              if (session.isAdmin) l.kioskMode,
            ],
            if (brand.tabs.contains(DashTab.video) && session.isAdmin) l.videoDemoSwitch,
          ],
          build: (_) => const _EndpointsPage(),
        ),
    ],
    if (session.isAdmin) ...[
      _Category(
        SettingsCategory.views,
        _Heading.admin,
        Icons.view_quilt_outlined,
        l.sectionViews,
        summary: '',
        keywords: [l.tabOrder, l.roleName(Role.power), l.roleName(Role.normie)],
        build: (_) => const _ViewsPage(),
      ),
      _Category(
        SettingsCategory.users,
        _Heading.admin,
        Icons.group_outlined,
        l.sectionUsers,
        summary: '',
        keywords: const [],
        build: (_) => const _Group(
          children: [Padding(padding: EdgeInsets.all(20), child: UsersSection())],
        ),
      ),
      _Category(
        SettingsCategory.diagnostics,
        _Heading.admin,
        Icons.monitor_heart_outlined,
        l.sectionDiagnostics,
        summary: '',
        keywords: [l.copySettings],
        build: (_) => const _Group(
          children: [Padding(padding: EdgeInsets.all(20), child: DiagnosticsSection())],
        ),
      ),
    ],
    _Category(
      SettingsCategory.about,
      _Heading.app,
      Icons.info_outline,
      l.sectionAbout,
      summary: '',
      keywords: [l.licenses, for (final link in brand.links) link.label],
      build: (_) => const _AboutPage(),
    ),
  ];
}

String _groupName(AppLocalizations l, _Heading g) => switch (g) {
  _Heading.personal => l.groupPersonal,
  _Heading.deployment => l.groupDeployment,
  _Heading.admin => l.groupAdmin,
  _Heading.app => '',
};

String _themeName(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.themeSystem,
  ThemeMode.light => l.themeLight,
  ThemeMode.dark => l.themeDark,
};

String _percent(Formats f, double scale) => f.percent(scale * 100);

String _accountView(AppLocalizations l, Session session, Brand brand) {
  final role = session.signedInRole;
  final name = role == null ? '-' : l.roleName(role);
  return session.mode == SignInMode.api ? l.accountViewApi(name, brand.platform) : l.accountViewLocal(name);
}

/// Lowercase and without accents, so "configuracion" finds "Configuración".
String _fold(String s) {
  const from = 'áàâäãåéèêëíìîïóòôöõúùûüñçÿ';
  const to = 'aaaaaaeeeeiiiiooooouuuuncy';
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}

bool _matches(String query, String text) => _fold(text).contains(_fold(query.trim()));

/// Settings: categories on the left and the open one on the right where
/// there's room (840px), else a list of categories that each open a page.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.initial});

  /// The category open at first on wide screens, or pushed at once on phones.
  final SettingsCategory? initial;

  /// Where the two-pane layout starts.
  static const wideWidth = 840.0;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsCategory? _selected = widget.initial;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial case final initial?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && MediaQuery.sizeOf(context).width < SettingsPage.wideWidth) _push(initial);
      });
    }
  }

  void _push(SettingsCategory id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _CategoryRoute(id)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    final categories = _categories(context);
    final wide = MediaQuery.sizeOf(context).width >= SettingsPage.wideWidth;
    final selected = categories.firstWhere((c) => c.id == _selected, orElse: () => categories.first);
    final list = _CategoryList(
      categories: categories,
      selected: wide ? selected.id : null,
      query: _query,
      onQuery: (q) => setState(() => _query = q),
      onOpen: (id) => wide ? setState(() => _selected = id) : _push(id),
      wide: wide,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 300,
                  child: ColoredBox(color: p4.bg2, child: list),
                ),
                VerticalDivider(width: 1, color: p4.border),
                Expanded(child: _CategoryBody(selected, key: ValueKey(selected.id), header: true)),
              ],
            )
          : list,
    );
  }
}

/// A category's page on phones. Leaves when the category goes away (e.g. the
/// view changed) instead of showing a stale one.
class _CategoryRoute extends StatelessWidget {
  const _CategoryRoute(this.id);

  final SettingsCategory id;

  @override
  Widget build(BuildContext context) {
    final category = _categories(context).where((c) => c.id == id).firstOrNull;
    if (category == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: _CategoryBody(category, header: false),
    );
  }
}

/// The search field and the categories (or, while searching, the settings
/// that match).
class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.selected,
    required this.query,
    required this.onQuery,
    required this.onOpen,
    required this.wide,
  });

  final List<_Category> categories;

  /// The open category, beside the list; null on phones.
  final SettingsCategory? selected;
  final String query;
  final ValueChanged<String> onQuery;
  final ValueChanged<SettingsCategory> onOpen;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    final searching = query.trim().isNotEmpty;
    final search = TextField(
      onChanged: onQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l.settingsSearch,
        hintStyle: p4.body(size: 14, color: p4.muted),
        prefixIcon: Icon(Icons.search, size: 20, color: p4.muted),
        fillColor: wide ? p4.bg : p4.bg2,
      ),
    );
    final children = <Widget>[];
    if (searching) {
      final hits = [
        for (final c in categories) ...[
          if (_matches(query, c.title) || _matches(query, c.summary)) (c, null),
          for (final k in {...c.keywords})
            if (_matches(query, k) && !_matches(query, c.title)) (c, k),
        ],
      ];
      children.add(
        hits.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                child: Text(
                  l.settingsNoMatch(query.trim()),
                  textAlign: TextAlign.center,
                  style: p4.body(color: p4.muted),
                ),
              )
            : _ListCard(
                wide: wide,
                children: [
                  for (final (c, keyword) in hits)
                    _CategoryTile(
                      c,
                      title: keyword ?? c.title,
                      subtitle: keyword == null ? c.summary : c.title,
                      selected: c.id == selected,
                      onTap: () => onOpen(c.id),
                    ),
                ],
              ),
      );
    } else {
      for (final group in _Heading.values) {
        final inGroup = categories.where((c) => c.group == group).toList();
        if (inGroup.isEmpty) continue;
        final name = _groupName(l, group);
        children.add(
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 12 : 4, children.isEmpty ? 0 : 20, 4, 8),
            child: name.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    name,
                    style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w600, spacing: 0),
                  ),
          ),
        );
        children.add(
          _ListCard(
            wide: wide,
            children: [
              for (final c in inGroup)
                _CategoryTile(c, selected: c.id == selected, onTap: () => onOpen(c.id), showChevron: !wide),
            ],
          ),
        );
      }
    }
    return ListView(
      padding: wide ? const EdgeInsets.fromLTRB(12, 16, 12, 32) : const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 16), ...children],
            ),
          ),
        ),
      ],
    );
  }
}

/// On phones a card of rows with dividers; beside a page, a plain list like a navigation rail's.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.children, required this.wide});

  final List<Widget> children;
  final bool wide;

  @override
  Widget build(BuildContext context) => wide
      ? Column(
          children: [for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 2), child: c)],
        )
      : _Card(children: children);
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
    this.category, {
    required this.selected,
    required this.onTap,
    this.title,
    this.subtitle,
    this.showChevron = true,
  });

  final _Category category;
  final bool selected;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final session = SessionScope.of(context);
    final account = category.id == SettingsCategory.account && title == null;
    final name = account ? (session.username ?? context.l10n.signedInWithoutAccount) : (title ?? category.title);
    final leading = account
        ? CircleAvatar(
            radius: 16,
            backgroundColor: p4.accent.withValues(alpha: 0.15),
            child: session.username == null
                ? Icon(Icons.person_outline, size: 18, color: p4.accent)
                : Text(session.username!.characters.first.toUpperCase(), style: p4.display(size: 14, color: p4.accent)),
          )
        : Icon(category.icon, size: 20, color: selected ? p4.accent : p4.muted);
    return Material(
      color: selected ? p4.accent.withValues(alpha: 0.12) : Colors.transparent,
      shape: selected ? Radii.controlShape : null,
      child: InkWell(
        onTap: onTap,
        customBorder: selected ? Radii.controlShape : null,
        child: Semantics(
          selected: selected,
          button: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 32, child: Center(child: leading)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: p4.display(
                          size: 15,
                          color: selected ? p4.heading : p4.text,
                          weight: selected ? FontWeight.w700 : FontWeight.w600,
                          spacing: 0,
                        ),
                      ),
                      if ((subtitle ?? category.summary).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle ?? category.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: p4.body(size: 13, color: p4.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron) Icon(Icons.chevron_right, color: p4.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A category's settings, scrolling; with its title on top beside the list.
class _CategoryBody extends StatelessWidget {
  const _CategoryBody(this.category, {super.key, required this.header});

  final _Category category;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return ListView(
      padding: header ? const EdgeInsets.fromLTRB(32, 28, 32, 48) : const EdgeInsets.fromLTRB(16, 20, 16, 48),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header) ...[
                  Text(category.title, style: p4.display(size: 26, weight: FontWeight.w800, spacing: -0.6)),
                  const SizedBox(height: 8),
                ],
                if (header) const SizedBox(height: 12),
                category.build(context),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Building blocks

/// A card of rows with dividers between them.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[if (i > 0) Divider(height: 1, thickness: 1, color: p4.border), c],
        ],
      ),
    );
  }
}

/// Settings that go together: an optional heading over a card of rows.
class _Group extends StatelessWidget {
  const _Group({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title!,
                style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w600, spacing: 0),
              ),
            ),
          _Card(children: children),
        ],
      ),
    );
  }
}

/// One setting: a label, a line about it or its value, a control at the end
/// and, for wide controls, one [below].
class _Tile extends StatelessWidget {
  const _Tile({required this.title, this.subtitle, this.icon, this.trailing, this.below, this.onTap});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: p4.muted), const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: p4.display(size: 15, color: p4.text, weight: FontWeight.w600, spacing: 0),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: p4.body(size: 13, color: p4.muted)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (below != null) ...[const SizedBox(height: 12), below!],
        ],
      ),
    );
    return onTap == null
        ? content
        : MergeSemantics(
            child: InkWell(onTap: onTap, child: content),
          );
  }
}

/// An on/off setting; [locked] when the device already has it on.
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.locked = false,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final bool locked;

  @override
  Widget build(BuildContext context) => _Tile(
    title: title,
    subtitle: locked ? context.l10n.onInDeviceSettings : null,
    icon: icon,
    onTap: locked ? null : () => onChanged(!value),
    trailing: Switch(value: value || locked, onChanged: locked ? null : onChanged),
  );
}

/// Pads fields and buttons inside a card.
class _Padded extends StatelessWidget {
  const _Padded({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 14), c],
      ],
    ),
  );
}

/// Builds a row of choices with icons when there's room for them (440px).
class _Compact extends StatelessWidget {
  const _Compact({required this.builder});

  final Widget Function(bool icons) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Align(alignment: Alignment.centerLeft, child: builder(c.maxWidth >= 440)),
  );
}

// Personal

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final session = SessionScope.of(context);
    final brand = BrandScope.of(context);
    final account = _Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: p4.accent.withValues(alpha: 0.15),
                    child: session.username == null
                        ? Icon(Icons.person_outline, color: p4.accent)
                        : Text(
                            session.username!.characters.first.toUpperCase(),
                            style: p4.display(size: 20, color: p4.accent),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(switch (session.username) {
                          final user? => l.signedInAs(user),
                          null => l.signedInWithoutAccount,
                        }, style: p4.display(size: 16)),
                        const SizedBox(height: 2),
                        Text(_accountView(l, session, brand), style: p4.body(size: 13, color: p4.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  session.signOut();
                },
                icon: const Icon(Icons.logout, size: 16),
                label: Text(l.signOut),
              ),
            ],
          ),
        ),
      ],
    );
    // The tour is the normie view's (see HomeShell).
    if (session.signedInRole != Role.normie) return account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        account,
        _Group(
          children: [
            _Tile(
              icon: Icons.tour_outlined,
              title: l.takeTour,
              subtitle: l.takeTourSubtitle,
              trailing: Icon(Icons.chevron_right, color: p4.muted),
              onTap: () {
                // Back to the home screen, which starts the tour once it's unseen.
                final settings = SettingsScope.of(context);
                Navigator.of(context).popUntil((r) => r.isFirst);
                settings.tourSeen = false;
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final brand = BrandScope.of(context);
    return _Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final width = ((c.maxWidth - 2 * gap) / 3).clamp(0.0, 200.0);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final mode in ThemeMode.values)
                    SizedBox(
                      width: width,
                      child: _ThemeOption(
                        label: _themeName(l, mode),
                        light: mode == ThemeMode.dark ? null : brand.light,
                        dark: mode == ThemeMode.light ? null : brand.dark,
                        selected: s.themeMode == mode,
                        onTap: () => s.themeMode = mode,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A theme as a small picture of the dashboard in it; Match device is half light, half dark.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.label, required this.selected, required this.onTap, this.light, this.dark});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final P4Colors? light;
  final P4Colors? dark;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final picture = switch ((light, dark)) {
      (final l?, final d?) => Stack(
        fit: StackFit.expand,
        children: [
          _ThemeSketch(l),
          ClipRect(clipper: const _RightHalf(), child: _ThemeSketch(d)),
        ],
      ),
      (final l?, null) => _ThemeSketch(l),
      (null, final d?) => _ThemeSketch(d),
      _ => const SizedBox.shrink(),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: selected ? p4.accent : p4.border2, width: selected ? 2 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card - 4),
                child: AspectRatio(aspectRatio: 1.5, child: picture),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[Icon(Icons.check_circle, size: 16, color: p4.accent), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: p4.display(
                      size: 13,
                      color: selected ? p4.heading : p4.text,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      spacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RightHalf extends CustomClipper<Rect> {
  const _RightHalf();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_RightHalf oldClipper) => false;
}

/// The dashboard in [c], drawn with boxes: app bar, rail and two cards.
class _ThemeSketch extends StatelessWidget {
  const _ThemeSketch(this.c);

  final P4Colors c;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, Color color) => Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
    Widget card(Color line) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: c.bg2,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: c.border2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bar(18, line), const SizedBox(height: 3), bar(28, c.muted.withValues(alpha: 0.5))],
        ),
      ),
    );
    // Drawn at one size and scaled, so it reads the same in any card.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: 150,
        height: 100,
        child: ColoredBox(
          color: c.bg,
          child: Column(
            children: [
              Container(
                height: 14,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border(bottom: BorderSide(color: c.border2)),
                ),
                alignment: Alignment.centerLeft,
                child: bar(16, c.heading),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 12,
                      color: c.bg2,
                      padding: const EdgeInsets.only(top: 5),
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [card(c.accent), card(c.text)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibilityPage extends StatelessWidget {
  const _AccessibilityPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    // The device's own settings: ours only ever add to them.
    final device = View.of(context).platformDispatcher.accessibilityFeatures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(title: l.textSize, children: const [_TextSize()]),
        _Group(
          children: [
            _SwitchTile(
              icon: Icons.contrast,
              title: l.highContrast,
              value: s.highContrast,
              locked: device.highContrast,
              onChanged: (v) => s.highContrast = v,
            ),
            _SwitchTile(
              icon: Icons.motion_photos_off_outlined,
              title: l.reduceMotion,
              value: s.reduceMotion,
              locked: device.disableAnimations,
              onChanged: (v) => s.reduceMotion = v,
            ),
          ],
        ),
      ],
    );
  }
}

/// A slider for [AppSettings.textScale] and a sentence at that size. Saved
/// when the slider is let go, so the page doesn't reflow under the finger.
class _TextSize extends StatefulWidget {
  const _TextSize();

  @override
  State<_TextSize> createState() => _TextSizeState();
}

class _TextSizeState extends State<_TextSize> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final s = SettingsScope.of(context);
    final (min, max) = AppSettings.textScaleRange;
    final value = _dragging ?? s.textScale;
    // The page is already drawn at the saved size; the sample shows the one being picked.
    final sample = MediaQuery.textScalerOf(context).scale(15) / s.textScale * value / 15;
    return _Padded(
      children: [
        Row(
          children: [
            Tooltip(
              message: l.textSizeSmaller,
              child: Icon(Icons.text_decrease, size: 18, color: p4.muted),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 0.05).round(),
                label: _percent(f, value),
                semanticFormatterCallback: (v) => _percent(f, v),
                onChanged: (v) => setState(() => _dragging = v),
                onChangeEnd: (v) {
                  s.textScale = v;
                  setState(() => _dragging = null);
                },
              ),
            ),
            Tooltip(
              message: l.textSizeLarger,
              child: Icon(Icons.text_increase, size: 22, color: p4.muted),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 56,
              child: Text(
                _percent(f, value),
                textAlign: TextAlign.end,
                style: p4.mono(size: 13, color: p4.text, spacing: 0),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p4.bg3, borderRadius: BorderRadius.circular(Radii.control)),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(sample)),
            child: Text(l.textSizePreview, style: p4.body(size: 15)),
          ),
        ),
        if (value != 1.0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                s.textScale = 1.0;
                setState(() => _dragging = null);
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l.resetToDefault),
            ),
          ),
      ],
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final current = s.locale?.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          children: [
            _Tile(
              icon: Icons.translate,
              title: l.sectionLanguage,
              subtitle: current == null
                  ? l.languageDevice(languageName(_deviceLanguage(context)).native)
                  : languageName(current).native,
              trailing: Icon(Icons.chevron_right, color: context.p4.muted),
              onTap: () => _pickLanguage(context, s),
            ),
          ],
        ),
        _Group(
          title: l.formatsHeading,
          children: [
            _Tile(
              icon: Icons.thermostat_outlined,
              title: l.temperatureUnit,
              below: _Compact(
                builder: (_) => SegmentedButton<TemperatureUnit>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: TemperatureUnit.auto, label: Text(l.unitAuto)),
                    const ButtonSegment(value: TemperatureUnit.celsius, label: Text('°C')),
                    const ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('°F')),
                  ],
                  selected: {s.temperatureUnit},
                  onSelectionChanged: (v) => s.temperatureUnit = v.first,
                ),
              ),
            ),
            _Tile(
              icon: Icons.schedule,
              title: l.timeFormat,
              below: _Compact(
                builder: (_) => SegmentedButton<TimeFormat>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: TimeFormat.auto, label: Text(l.unitAuto)),
                    ButtonSegment(value: TimeFormat.h12, label: Text(l.time12h)),
                    ButtonSegment(value: TimeFormat.h24, label: Text(l.time24h)),
                  ],
                  selected: {s.timeFormat},
                  onSelectionChanged: (v) => s.timeFormat = v.first,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The device's language if the dashboard has it, else English (what
/// MaterialApp falls back to).
String _deviceLanguage(BuildContext context) => basicLocaleListResolution(
  View.of(context).platformDispatcher.locales,
  AppLocalizations.supportedLocales,
).languageCode;

Future<void> _pickLanguage(BuildContext context, AppSettings s) async {
  final code = await showDialog<String>(context: context, builder: (_) => const _LanguageDialog());
  if (code != null) s.locale = code.isEmpty ? null : Locale(code);
}

/// Every language by its own name, with a search field once there are more
/// than a handful. Pops with the code picked, '' to follow the device.
class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final current = SettingsScope.of(context).locale?.languageCode ?? '';
    final searchable = supportedLanguages.length > 6;
    final shown = [
      for (final code in supportedLanguages)
        if (_query.isEmpty ||
            _matches(_query, languageName(code).native) ||
            _matches(_query, languageName(code).english) ||
            _matches(_query, code))
          code,
    ];
    Widget option(String code, String title, String? subtitle, {Locale? locale}) {
      final selected = code == current;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        selected: selected,
        selectedColor: p4.heading,
        title: Text(title, locale: locale),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected ? Icon(Icons.check, color: p4.accent) : null,
        onTap: () => Navigator.of(context).pop(code),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Text(l.sectionLanguage, style: p4.display(size: 18)),
            ),
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: MediaQuery.sizeOf(context).width >= SettingsPage.wideWidth,
                  onChanged: (q) => setState(() => _query = q.trim()),
                  decoration: InputDecoration(
                    hintText: l.searchLanguages,
                    hintStyle: p4.body(size: 14, color: p4.muted),
                    prefixIcon: Icon(Icons.search, size: 20, color: p4.muted),
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_query.isEmpty) option('', l.languageDevice(languageName(_deviceLanguage(context)).native), null),
                  for (final code in shown)
                    option(
                      code,
                      languageName(code).native,
                      languageName(code).english == languageName(code).native ? null : languageName(code).english,
                      locale: Locale(code),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.settingsNoMatch(_query), style: p4.body(color: p4.muted)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Deployment

class _ConnectionPage extends StatelessWidget {
  const _ConnectionPage();

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final brand = BrandScope.of(context);
    return _Group(
      children: [
        _Padded(
          children: [
            if (s.deployments.length > 1)
              DropdownButtonFormField<String>(
                key: ValueKey(s.deployment.id),
                initialValue: s.deployment.id,
                decoration: InputDecoration(labelText: l.fieldDeployment),
                dropdownColor: p4.bg2,
                style: p4.mono(size: 13, color: p4.text, spacing: 0),
                items: [
                  for (final d in s.deployments)
                    DropdownMenuItem(value: d.id, child: Text('${d.name} · ${s.hostOf(d)}')),
                ],
                onChanged: (id) {
                  if (id == null || id == s.deployment.id) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  s.connect(id);
                },
              ),
            _Field(l.fieldHost, s.host, (v) => s.host = v),
            _Field(l.apiBaseUrl(brand.platform), s.apiBase, (v) => s.apiBase = v, hint: s.url(8000, '/').toString()),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: s.resetConnection,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(l.resetConnection),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Power users get the addresses; demo data and kiosk mode are admins' calls.
class _EndpointsPage extends StatelessWidget {
  const _EndpointsPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final brand = BrandScope.of(context);
    final admin = SessionScope.of(context).isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (brand.tabs.contains(DashTab.edge))
          _Group(
            title: l.sectionEdgeMetrics,
            children: [
              _Padded(
                children: [
                  _Field(
                    l.metricsUrl,
                    s.edgeMetricsUrl,
                    (v) => s.edgeMetricsUrl = v,
                    hint: s.apiUri.resolve('api/v1/edge/metrics').toString(),
                  ),
                ],
              ),
              if (admin) _SwitchTile(title: l.demoData, value: s.edgeDemo, onChanged: (v) => s.edgeDemo = v),
            ],
          ),
        if (brand.tabs.contains(DashTab.grafana))
          _Group(
            title: l.sectionGrafana,
            children: [
              _Padded(
                children: [
                  _Field(l.grafanaBaseUrl, s.grafanaBase, (v) => s.grafanaBase = v, hint: s.url(3000, '/').toString()),
                  _Field(l.dashboardPath, s.grafanaPath, (v) => s.grafanaPath = v, hint: '/d/<uid>/<slug>'),
                ],
              ),
              if (admin) _SwitchTile(title: l.kioskMode, value: s.grafanaKiosk, onChanged: (v) => s.grafanaKiosk = v),
            ],
          ),
        if (brand.tabs.contains(DashTab.video))
          _Group(
            title: l.sectionVideo,
            children: [
              for (final c in s.cameras) _CameraRow(c.name, c.url),
              if (s.cameras.isEmpty) _Tile(title: l.noCameras),
              if (admin) _SwitchTile(title: l.videoDemoSwitch, value: s.videoDemo, onChanged: (v) => s.videoDemo = v),
            ],
          ),
      ],
    );
  }
}

/// A camera in Settings: its name, and its URL in small type.
class _CameraRow extends StatelessWidget {
  const _CameraRow(this.name, this.url);

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.videocam_outlined, size: 20, color: p4.muted),
          const SizedBox(width: 14),
          Text(
            name,
            style: p4.display(size: 15, color: p4.text, weight: FontWeight.w600, spacing: 0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(url, overflow: TextOverflow.ellipsis, style: p4.mono(size: 12, spacing: 0)),
          ),
        ],
      ),
    );
  }
}

/// Text field that commits on submit or focus loss.
class _Field extends StatefulWidget {
  const _Field(this.label, this.value, this.onCommit, {this.hint});

  final String label;
  final String value;
  final ValueChanged<String> onCommit;
  final String? hint;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  P4Colors get p4 => context.p4;

  late final _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  void _commit() {
    if (_ctrl.text.trim() != widget.value) widget.onCommit(_ctrl.text);
  }

  /// Shows values changed elsewhere (e.g. a connection reset), unless the
  /// user is editing this field.
  @override
  void didUpdateWidget(_Field old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && !_focus.hasFocus) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      style: p4.mono(size: 13, color: p4.text, spacing: 0),
      onSubmitted: (_) => _commit(),
      decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
    );
  }
}

// Administration

class _ViewsPage extends StatelessWidget {
  const _ViewsPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    final s = SettingsScope.of(context);
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    final tabs = s.tabOrder.where(brand.tabs.contains).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          title: l.tabOrder,
          children: [
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) {
                // Read at drop time, like the chips below. Tabs the brand doesn't have keep their place at the end.
                final order = s.tabOrder;
                final shown = order.where(brand.tabs.contains).toList();
                shown.insert(to, shown.removeAt(from));
                _saveView(context, () => s.setTabOrder([...shown, ...order.where((t) => !brand.tabs.contains(t))]));
              },
              children: [
                for (final (i, t) in tabs.indexed)
                  ListTile(
                    key: ValueKey('order-${t.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Text('${i + 1}', style: p4.mono(size: 12)),
                    minLeadingWidth: 16,
                    title: Text(l.tabName(t)),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: Tooltip(
                        message: l.dragToReorder,
                        child: Icon(Icons.drag_handle, color: p4.muted),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _saveView(context, s.resetTabOrder),
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(l.resetTabOrder),
                ),
              ),
            ),
          ],
        ),
        for (final view in [Role.power, Role.normie])
          _Group(
            title: l.roleName(view),
            children: [
              _Padded(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in s.tabOrder.where(brand.tabs.contains))
                        FilterChip(
                          key: ValueKey('${view.name}-${t.name}'),
                          label: Text(l.tabName(t)),
                          selected: s.tabsFor(view).contains(t),
                          // Read at tap time: two taps can land before a rebuild.
                          onSelected: (on) => _saveView(
                            context,
                            () => s.setTabsFor(view, [
                              for (final c in s.tabOrder)
                                if (c == t ? on : s.tabsFor(view).contains(c)) c,
                            ]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      session.preview = view;
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(l.previewView(l.roleName(view))),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Runs a change to the views (saved on the deployment's p4n4-api), saying
/// so when it didn't save; the change is already undone on screen then.
Future<void> _saveView(BuildContext context, Future<void> Function() change) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    await change();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.viewsSaveFailed('$e'))));
  }
}

// About

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final brand = BrandScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wordmark(size: 22),
                  if (brand.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(brand.tagline, style: p4.body(size: 13, color: p4.muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
        _Group(
          children: [
            for (final link in brand.links)
              _Tile(
                icon: Icons.open_in_new,
                title: link.label,
                onTap: () => launchUrl(link.url, mode: LaunchMode.externalApplication),
              ),
            // Fonts, Flutter and every package the app ships with.
            _Tile(
              icon: Icons.gavel_outlined,
              title: l.licenses,
              trailing: Icon(Icons.chevron_right, color: p4.muted),
              onTap: () => showLicensePage(context: context, applicationName: brand.appName),
            ),
          ],
        ),
      ],
    );
  }
}
