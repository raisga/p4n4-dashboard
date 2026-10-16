import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_intro/flutter_intro.dart' show Intro;
import 'package:http/http.dart' as http;

import 'api/auth.dart';
import 'api/banner.dart';
import 'api/feed.dart';
import 'api/project.dart';
import 'api/status_monitor.dart';
import 'api/view_settings.dart';
import 'api/views.dart';
import 'api/vision.dart';
import 'api/vision_live.dart';
import 'api/vision_recorded.dart';
import 'core/alerts.dart';
import 'core/brand.dart';
import 'core/chat_history.dart';
import 'core/runtime_config.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'demo/demo.dart';
import 'demo/demo_client.dart';
import 'l10n/l10n.dart';
import 'pages/kiosk_dialogs.dart';
import 'pages/login_page.dart';
import 'pages/password_page.dart';
import 'platform/http_client.dart';
import 'pages/settings_page.dart';
import 'tabs/agent_tab.dart';
import 'tabs/clients_tab.dart';
import 'tabs/edge_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/grafana_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/video_tab.dart';
import 'widgets/alert_toasts.dart';
import 'widgets/common.dart';
import 'widgets/idle.dart';
import 'widgets/tour.dart';

Future<void> main() async {
  final credentials = _SessionCredentials();
  final demoApi = demoMode ? DemoApi(newHttpClient()) : null;
  // Every request goes through AuthClient, which adds the signed-in user's
  // token to the connected deployment's p4n4-api calls (lib/api/auth.dart).
  await http.runWithClient(
    () async {
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
      ViewSettingsWatcher(settings);
      BannerWatcher(settings);
      VisionWatcher(settings);
      runApp(
        BrandScope(
          brand: brand,
          child: SettingsScope(
            settings: settings,
            child: SessionScope(session: session, child: const DashboardApp()),
          ),
        ),
      );
    },
    // The demo build plays p4n4-api itself (lib/demo/).
    () => AuthClient(
      demoApi == null ? newHttpClient() : DemoClient(newHttpClient(), demoApi),
      credentials,
      viaProxy: (url) => kIsWeb && viaPageProxy(url),
    ),
  );
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

  /// To close whatever is open over the shell (Settings, a dialog) when idle.
  final _navigator = GlobalKey<NavigatorState>();

  /// Bumped by each kiosk reset: a new shell starts on its first tab, with
  /// nothing scrolled, typed or open.
  var _resets = 0;

  /// What an idle spell does on this device: signs an admin or power user
  /// out (Settings → This device), or takes a kiosk back to where it starts.
  (Duration?, VoidCallback?) _idle(AppSettings settings, Session session) {
    Duration? minutes(int m) => m > 0 ? Duration(minutes: m) : null;
    return switch (session.signedInRole) {
      Role.admin || Role.power => (minutes(settings.idleSignOut), () => _signOutIdle(session)),
      Role.normie when session.kioskLocked => (minutes(settings.kioskIdleReset), () => _resetKiosk(settings, session)),
      _ => (null, null),
    };
  }

  void _signOutIdle(Session session) {
    _navigator.currentState?.popUntil((r) => r.isFirst);
    unawaited(session.signOut());
  }

  /// The next person finds the kiosk as the admin left it: on its start tab,
  /// without the last conversation, with the kiosk's own text size.
  void _resetKiosk(AppSettings settings, Session session) {
    _navigator.currentState?.popUntil((r) => r.isFirst);
    settings.restoreKioskAccessibility();
    unawaited(settings.setChatOf(settings.deployment, session.username ?? Role.normie.name, const []));
    setState(() => _resets++);
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    final role = session.role;
    final settings = SettingsScope.of(context);
    // Settings → Accessibility adds to the device's own settings, never takes away from them.
    final device = MediaQuery.of(context);
    final reduceMotion = settings.reduceMotion || device.disableAnimations;
    final highContrast = settings.highContrast || device.highContrast;
    ThemeData theme(P4Colors c) => buildTheme(highContrast ? c.contrasted : c, reduceMotion: reduceMotion);
    final (idleAfter, onIdle) = _idle(settings, session);
    final app = MaterialApp(
      navigatorKey: _navigator,
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: theme(brand.light),
      darkTheme: theme(brand.dark),
      themeMode: settings.themeMode,
      themeAnimationDuration: reduceMotion ? Duration.zero : kThemeAnimationDuration,
      // The language picked in Settings, else the device's if supported, else English.
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appLocales,
      // Keyed by role so switching views starts from a fresh shell; a kiosk reset does too.
      home: switch (role) {
        null => const LoginPage(),
        _ when session.passwordChangeRequired => const ChangePasswordPage(),
        final role => HomeShell(key: ValueKey((role, _resets))),
      },
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
        child: IdleWatcher(
          timeout: idleAfter,
          onIdle: onIdle,
          child: TourHost(child: app),
        ),
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
  video,
  feed;

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
  Screen.feed: _Dest((l) => l.navFeed, Icons.dynamic_feed_outlined, Icons.dynamic_feed),
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

  late Intro _intro;

  /// The tour group running (or about to start); null once the tour is seen.
  String? _tourGroup;

  /// A question for the Assistant from Home (HOME.md's `ask:` links), until it takes it.
  final _ask = ValueNotifier<String?>(null);

  /// Every tab, kept by identity: a layout change (rail ↔ bottom bar) moves
  /// them instead of rebuilding them, so the chat and webviews survive it.
  final _tabs = GlobalKey();

  /// The Assistant conversation of who's signed in, and its storage key.
  ChatHistory? _chat;
  String? _chatId;

  /// Alerts shown as toasts over every tab: from the cameras (the vision
  /// overlay) and from the feed.
  late final _alerts = AlertCenter(
    // This device's chime setting, and the view's (Settings → Views).
    sound: () => SettingsScope.of(context).alertSound && _prefs.chime,
    accept: (n) => switch (_prefs.alertLevel) {
      AlertLevel.all => true,
      AlertLevel.review => n.tone == VisionTone.review,
      AlertLevel.off => false,
    },
  );

  /// What an admin set for this view (Settings → Views).
  ViewPrefs get _prefs => SettingsScope.of(context).prefsFor(SessionScope.of(context).role ?? Role.normie);

  /// A camera for the Video tab to show, when an alert's toast is tapped.
  final _videoFocus = ValueNotifier<String?>(null);

  /// The project's live detections, while it streams any.
  LiveVision? _live;

  /// The measured demo clips' behaviours, on their own clocks; their videos
  /// keep in step with them when the Video tab shows them.
  RecordedVision? _recorded;

  /// New feed alerts, while this view has the Feed tab.
  FeedAlertWatcher? _feedAlerts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _intro = Intro.of(context);
    final settings = SettingsScope.of(context);
    final session = SessionScope.of(context);
    final who = session.username ?? session.signedInRole?.name ?? '';
    final id = '${settings.deployment.id}.$who';
    if (id != _chatId) {
      _chat?.dispose();
      _chat = ChatHistory(settings, settings.deployment, who);
      _chatId = id;
    }
    _followAlerts(settings, session);
  }

  /// Keeps the live stream and the feed watcher in step with the deployment.
  void _followAlerts(AppSettings settings, Session session) {
    final vision = settings.vision;
    final liveUri = vision?.live?.on(settings.host);
    if (liveUri != _live?.uri) {
      _live?.dispose();
      _live = liveUri == null
          ? null
          : LiveVision(liveUri, onVerdict: (camera, behavior) => _visionAlert(settings, camera, behavior));
    }
    final role = session.role;
    final brand = BrandScope.of(context);
    final screens = role == null ? const <Screen>[] : screensFor(role, brand, settings);
    // Alerts from the clips' recordings, for whoever can open their cameras.
    (_recorded ??= RecordedVision(
      onVerdict: (camera, behavior) => _visionAlert(settings, camera.id, behavior, name: camera.name, from: 'clip'),
    )).follow(screens.contains(Screen.video) ? videoCameras(settings, brand, view: role!) : const [], vision);
    final api = screens.contains(Screen.feed) ? settings.apiUri : null;
    if (api != _feedAlerts?.api.api) {
      _feedAlerts?.dispose();
      _feedAlerts = api == null ? null : FeedAlertWatcher(FeedApi(api), _alerts);
    }
  }

  /// A verdict that asks for an alert raises it, whichever tab is open: one
  /// from the live stream, or [from] a measured clip, on camera [name].
  void _visionAlert(
    AppSettings settings,
    String camera,
    VisionBehavior behavior, {
    String? name,
    String from = 'live',
  }) {
    final bundle = settings.vision;
    if (bundle == null || !mounted) return;
    final zones = behavior.zone != null ? [behavior.zone!] : bundle.camera(camera)?.zones ?? const <String>[];
    final rule = bundle.alertFor(behavior.behavior, zones);
    if (rule == null) return;
    final lang = context.l10n.localeName;
    name ??= settings.cameras.where((c) => c.id == camera).firstOrNull?.name ?? camera;
    _alerts.raise(
      AlertNotice(
        id: '$from:$camera:${behavior.key ?? DateTime.now().microsecondsSinceEpoch}',
        title: rule.titleIn(lang),
        tone: rule.tone,
        code: rule.code,
        where: '$name · ${bundle.behaviorLabel(behavior.behavior, lang)}',
        detail: rule.suggestionIn(lang),
        camera: camera,
      ),
      key: '$camera|${rule.code}',
    );
  }

  @override
  void dispose() {
    // e.g. the session expired mid-tour: don't leave the tour over the sign-in page.
    if (_tourGroup != null && _intro.status.isOpen) _intro.dispose();
    _ask.dispose();
    _chat?.dispose();
    _live?.dispose();
    _recorded?.dispose();
    _feedAlerts?.dispose();
    _alerts.dispose();
    _videoFocus.dispose();
    super.dispose();
  }

  /// Starts the tour of [group] once this frame has registered its steps. If
  /// one is open in another group (navigation came or went), closes it first.
  // Steps register in post-frame callbacks added after this shell's, so start after all of them.
  void _startTour(String group) => WidgetsBinding.instance.addPostFrameCallback(
    (_) => scheduleMicrotask(() {
      if (!mounted || _tourGroup != group) return;
      final intro = Intro.of(context);
      if (!intro.status.isOpen) return intro.start(group: group, reset: true);
      void restart() {
        if (intro.status.isOpen) return;
        intro.statusNotifier.removeListener(restart);
        _startTour(group);
      }

      intro.statusNotifier.addListener(restart);
      intro.dispose();
    }),
  );

  /// [all] and [open] are for Home's `tab:` links and device details link.
  Widget _page(Screen screen, bool active, List<Screen> all, ValueChanged<Screen> open) => switch (screen) {
    Screen.home => OverviewTab(
      active: active,
      tabs: [for (final s in all) ?s.tab],
      onOpen: (t) => open(Screen.of(t)),
      onAsk: (q) {
        _ask.value = q;
        open(Screen.agent);
      },
    ),
    Screen.clients => ClientsTab(active: active),
    Screen.services => ServicesTab(active: active),
    Screen.edge => EdgeTab(active: active),
    Screen.agent => AgentTab(history: _chat!, ask: _ask),
    Screen.grafana => const GrafanaTab(),
    Screen.video => VideoTab(active: active, live: _live, recorded: _recorded, focus: _videoFocus),
    Screen.feed => FeedTab(active: active),
  };

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    final settings = SettingsScope.of(context);
    final l = context.l10n;
    final role = session.role!;
    final all = screensFor(role, brand, settings);
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final current = all.contains(_selected)
        ? _selected!
        // Admins and power users can pick their own (Settings → Appearance).
        : _start([if (role.technical) settings.myStartTab, ?settings.prefsFor(role).startTab], all);
    // A phone bottom bar fits five destinations; the rest open from the app
    // bar, the open one taking the bar's last place.
    final screens = wide || all.length <= 5 ? all : [...all.take(4), all.indexOf(current) >= 4 ? current : all[4]];
    final extra = all.where((s) => !screens.contains(s));
    final index = screens.indexOf(current);
    void select(int i) => setState(() => _selected = screens[i]);
    void open(Screen s) => setState(() => _selected = s);
    // An alert's toast opens its camera, else the feed it came from.
    // A feed alert names the edge's camera, which the Cameras tab may not
    // have (the Jetson's `cam-salon-01`): then it opens the feed.
    void openAlert(AlertNotice n) {
      final camera = all.contains(Screen.video)
          ? alertCamera(n.camera, videoCameras(settings, brand, view: role))
          : null;
      if (camera != null) {
        _videoFocus.value = camera;
        open(Screen.video);
      } else if (n.fromFeed && all.contains(Screen.feed)) {
        open(Screen.feed);
      } else if (n.camera != null && all.contains(Screen.video)) {
        open(Screen.video);
      }
    }

    // Navigation needs at least two destinations; a single-screen view gets none.
    final nav = screens.length > 1;

    // Normies get a tour of the shell the first time they sign in on a device
    // (not admins previewing their view). Its steps depend on [nav], so each
    // layout is a group of its own.
    final tour = session.signedInRole == Role.normie && !session.kioskLocked;
    // A kiosk keeps its theme and its sign-in: only an admin leaves it.
    final kiosk = session.kioskLocked;
    final tourSteps = [
      TourStep.welcome,
      if (nav) TourStep.navigation,
      TourStep.theme,
      TourStep.settings,
      TourStep.signOut,
    ];
    final tourGroup = 'shell-${identityHashCode(this)}${nav ? '' : '-solo'}';
    if (settings.tourSeen) {
      _tourGroup = null;
    } else if (tour && _tourGroup != tourGroup) {
      _startTour(_tourGroup = tourGroup);
    }
    Widget target(TourStep step, Widget child) =>
        tour ? TourTarget(group: tourGroup, step: step, steps: tourSteps, child: child) : child;
    // IndexedStack keeps every tab alive, the bar's or not; polling tabs pause via `active`.
    final tabs = IndexedStack(
      key: _tabs,
      index: all.indexOf(current),
      children: [for (final s in all) KeyedSubtree(key: ValueKey(s), child: _page(s, s == current, all, open))],
    );
    final body = AlertScope(
      center: _alerts,
      child: Stack(
        fit: StackFit.expand,
        children: [
          tabs,
          AlertToasts(center: _alerts, onOpen: openAlert),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: target(TourStep.welcome, const Wordmark()),
        actions: [
          if (wide) ...[
            if (role.technical) _ConnectionLabel(_connection(settings)),
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
          if (kiosk)
            IconButton(
              tooltip: l.leaveKiosk,
              icon: Icon(Icons.lock_outline, color: p4.muted),
              onPressed: () => showLeaveKioskDialog(context),
            )
          else
            target(TourStep.theme, _ThemeToggle(settings)),
          target(
            TourStep.settings,
            IconButton(
              tooltip: l.settingsTooltip,
              icon: Icon(Icons.tune, color: p4.muted),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          ),
          if (!kiosk)
            target(
              TourStep.signOut,
              IconButton(
                tooltip: l.signOutTooltip,
                icon: Icon(Icons.logout, color: p4.muted),
                onPressed: session.signOut,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _withBanners(
        session,
        settings.banner,
        wide && nav
            ? Row(
                children: [
                  target(
                    TourStep.navigation,
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
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide || !nav
          ? null
          : target(
              TourStep.navigation,
              NavigationBar(
                selectedIndex: index,
                onDestinationSelected: select,
                height: 64,
                destinations: [
                  for (final d in screens.map((s) => _dests[s]!))
                    NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label(l)),
                ],
              ),
            ),
    );
  }
}

/// The first of [names] (tab names, most wanted first) that this view has; else Home.
Screen _start(List<String> names, List<Screen> all) =>
    names.map((n) => Screen.values.asNameMap()[n]).nonNulls.where(all.contains).firstOrNull ?? Screen.home;

/// Above the tabs: the deployment's banner, if an admin put one up, and while
/// an admin previews another view, a banner that says so and leads back.
Widget _withBanners(Session session, DashboardBanner? banner, Widget body) {
  final message = banner != null && banner.showsAt(DateTime.now()) ? banner : null;
  final preview = session.preview;
  if (message == null && preview == null) return body;
  return Column(
    children: [
      if (message != null) _DeploymentBanner(message),
      if (preview != null) _PreviewBanner(preview, onExit: () => session.preview = null),
      Expanded(child: body),
    ],
  );
}

/// An admin's message to everyone on this deployment (Settings → Banner).
class _DeploymentBanner extends StatelessWidget {
  const _DeploymentBanner(this.banner);

  final DashboardBanner banner;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final (color, icon) = switch (banner.tone) {
      BannerTone.info => (p4.blue, Icons.campaign_outlined),
      BannerTone.warning => (p4.warn, Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        color: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  banner.text,
                  style: p4.body(size: 15, color: p4.text, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
