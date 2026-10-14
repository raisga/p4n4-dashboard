import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../api/camera.dart';
import 'theme.dart';

/// Tabs a brand can enable, in their default display order (after Home).
/// Admins reorder them in Settings; see [AppSettings.tabOrder].
enum DashTab {
  agent,
  grafana,
  video,
  edge,
  services,

  /// The project's live events and alerts (`.p4n4.json` `dashboard.feed`).
  /// Opt-in: a brand without a `tabs` list doesn't get it.
  feed;

  /// The tabs a brand gets when its brand.json lists none.
  static const defaults = [agent, grafana, video, edge, services];
}

/// Steps of the first-run tour of the shell that normies get, in order. Their
/// names are the keys of brand.json `tour`, which replaces their text.
enum TourStep { welcome, navigation, theme, settings, signOut }

class BrandLink {
  const BrandLink(this.label, this.url);

  final String label;
  final Uri url;
}

/// White-label configuration, loaded from `assets/brand/brand.json`.
///
/// That folder holds exactly one brand: `dart run tool/brand.dart <id>` copies
/// `brands/<id>/` into it and patches the native projects, so a build never
/// ships another client's branding. See `brands/README.md`.
class Brand {
  const Brand({
    required this.id,
    required this.appName,
    required this.wordmark,
    required this.wordmarkSuffix,
    required this.platform,
    required this.tagline,
    required this.displayFont,
    required this.monoFont,
    required this.light,
    required this.dark,
    required this.tabs,
    required this.links,
    required this.defaults,
    this.tour = const {},
    this.assistantSuggestions = const {},
    this.demoCameras = const [],
    this.demoCredits = const {},
    this.logo,
  });

  final String id;

  /// Window/task-switcher title, e.g. "p4n4 dashboard".
  final String appName;

  /// App-bar wordmark: [wordmark] in the accent colour + muted [wordmarkSuffix].
  final String wordmark;
  final String wordmarkSuffix;

  /// Replaces "p4n4" in stack and service names (`<platform>-iot`, `<platform>-api`).
  final String platform;
  final String tagline;

  /// Google Fonts family names from brand.json `fonts`. The app renders them
  /// through [P4Colors.displayFamily] and [P4Colors.monoFamily].
  final String displayFont;
  final String monoFont;
  final P4Colors light;
  final P4Colors dark;
  final List<DashTab> tabs;
  final List<BrandLink> links;

  /// Initial values for [AppSettings] keys (host, themeMode, videoUrl, …).
  final Map<String, Object> defaults;

  /// Tour text that replaces the built-in copy: step → language code (`*`
  /// for every language) → text.
  final Map<TourStep, Map<String, String>> tour;

  /// [step]'s text from the brand in [language], if it has any.
  String? tourText(TourStep step, String language) => tour[step]?[language] ?? tour[step]?['*'];

  /// Questions the Assistant tab offers to start a chat with, per language
  /// code (`*` for every language), from brand.json `assistant.suggestions`.
  /// Empty: the dashboard's own.
  final Map<String, List<String>> assistantSuggestions;

  /// The brand's starter questions in [language], or null to use the dashboard's.
  List<String>? suggestionsFor(String language) => assistantSuggestions[language] ?? assistantSuggestions['*'];

  /// The Video tab's demo cameras, from brand.json `video.demoCameras`, in
  /// place of the built-in [demoCameras] (camera.dart): each an http(s) `url`,
  /// or a path the web app resolves against its own page (the dashboard's
  /// container serves `/demo/` from `DASHBOARD_DEMO_DIR`). Empty: the built-in
  /// ones. Resolve them with [demoCamerasOn].
  final List<Camera> demoCameras;

  /// [demoCameras] that can play here: absolute URLs as they are, paths
  /// resolved against [page] (the web app's address; null on native, where
  /// they're left out). Ids get a `demo-` prefix, so they never collide with
  /// the deployment's own cameras.
  List<Camera> demoCamerasOn(Uri? page) => [
    for (final c in demoCameras)
      if (Camera.parseUrl(c.url) != null || page != null)
        Camera(
          id: 'demo-${c.id}',
          name: c.name,
          url: Camera.parseUrl(c.url) != null ? c.url : page!.resolve(c.url).toString(),
        ),
  ];

  /// The credit line under [demoCameras], per language code (`*` for every
  /// language), from brand.json `video.demoCredits`.
  final Map<String, String> demoCredits;

  /// The credit line for the brand's demo footage in [language], if it has one.
  String? demoCreditsFor(String language) => demoCredits[language] ?? demoCredits['*'];

  /// Asset path of an app-bar logo that replaces the text wordmark.
  final String? logo;

  static const assetDir = 'assets/brand';

  static Future<Brand> load() async {
    final json = jsonDecode(await rootBundle.loadString('$assetDir/brand.json')) as Map<String, dynamic>;
    return Brand.fromJson(json);
  }

  /// Adds the bundled fonts' licenses (installed by `tool/brand.dart apply`
  /// as `licenses/<role>.txt`) to the licenses page.
  void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (role, family) in [('display', displayFont), ('mono', monoFont)]) {
        if (role == 'mono' && family == displayFont) continue; // one family for both
        yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('$assetDir/licenses/$role.txt'));
      }
    });
  }

  factory Brand.fromJson(Map<String, dynamic> j) {
    final fonts = (j['fonts'] as Map?)?.cast<String, dynamic>() ?? const {};
    final colors = (j['colors'] as Map?)?.cast<String, dynamic>() ?? const {};
    final displayFont = _font(fonts['display'], 'Plus Jakarta Sans');
    final monoFont = _font(fonts['mono'], 'JetBrains Mono');
    final tabNames = (j['tabs'] as List?)?.cast<String>() ?? [for (final t in DashTab.defaults) t.name];
    final tabs = [
      for (final t in DashTab.values)
        if (tabNames.contains(t.name)) t,
    ];
    final unknown = tabNames.where((n) => !DashTab.values.any((t) => t.name == n));
    if (unknown.isNotEmpty) throw FormatException('Unknown tabs in brand.json: ${unknown.join(', ')}');
    if (tabs.isEmpty) throw const FormatException('brand.json must enable at least one tab');
    final logo = j['logo'] as String?;
    final video = switch (j['video']) {
      null => const <String, dynamic>{},
      Map m => m.cast<String, dynamic>(),
      _ => throw const FormatException('brand.json video must be an object'),
    };

    return Brand(
      id: j['id'] as String,
      appName: j['appName'] as String,
      wordmark: (j['wordmark'] as Map)['text'] as String,
      wordmarkSuffix: ((j['wordmark'] as Map)['suffix'] ?? '') as String,
      platform: (j['platform'] ?? 'p4n4') as String,
      tagline: (j['tagline'] ?? '') as String,
      displayFont: displayFont,
      monoFont: monoFont,
      light: P4Colors.light.withBrand(_colors(colors['light'])),
      dark: P4Colors.dark.withBrand(_colors(colors['dark'])),
      tabs: tabs,
      links: [
        for (final l in (j['links'] as List?) ?? const [])
          BrandLink((l as Map)['label'] as String, Uri.parse(l['url'] as String)),
      ],
      defaults: ((j['defaults'] as Map?) ?? const {}).cast<String, Object>(),
      tour: _tour(j['tour']),
      assistantSuggestions: _suggestions(((j['assistant'] as Map?) ?? const {})['suggestions']),
      demoCameras: _demoCameras(video['demoCameras']),
      demoCredits: _texts(video['demoCredits'], 'video.demoCredits'),
      logo: logo == null ? null : '$assetDir/$logo',
    );
  }

  /// Fonts are checked against Google Fonts by `tool/brand.dart`, which
  /// downloads and bundles them; here only the name is needed.
  static String _font(Object? name, String fallback) => switch (name) {
    null => fallback,
    String s when s.trim().isNotEmpty => s,
    _ => throw FormatException('Font "$name" must be a non-empty family name'),
  };

  /// brand.json `tour`: each step's text, or its text per language.
  static Map<TourStep, Map<String, String>> _tour(Object? raw) {
    final steps = TourStep.values.asNameMap();
    return {
      for (final MapEntry(:key, :value) in ((raw as Map?) ?? const {}).entries)
        steps[key] ?? (throw FormatException('Unknown tour step "$key" in brand.json')): _texts(value, 'tour.$key'),
    };
  }

  /// Text for every language, or {language: text}; empty when [raw] is null.
  static Map<String, String> _texts(Object? raw, String key) => switch (raw) {
    null => const {},
    String text => {'*': text},
    Map texts when texts.values.every((t) => t is String) => texts.cast<String, String>(),
    _ => throw FormatException('brand.json $key must be text or {language: text}'),
  };

  /// brand.json `video.demoCameras`: {id, name, url}, the url an http(s) URL
  /// or a path on the dashboard's own origin.
  static List<Camera> _demoCameras(Object? raw) {
    final cameras = [
      for (final c in switch (raw) {
        null => const [],
        List l => l,
        _ => throw const FormatException('brand.json video.demoCameras must be a list'),
      })
        switch (c) {
          {'id': final String id, 'name': final String name, 'url': final String url}
              when id.isNotEmpty &&
                  name.isNotEmpty &&
                  url.trim().isNotEmpty &&
                  (Camera.parseUrl(url) != null || !Uri.parse(url).hasScheme) =>
            Camera(id: id, name: name, url: url.trim()),
          _ => throw FormatException(
            'brand.json video.demoCameras: $c needs an id, a name and an http(s) url or a path',
          ),
        },
    ];
    if (cameras.map((c) => c.id).toSet().length != cameras.length) {
      throw const FormatException('brand.json video.demoCameras ids must be unique');
    }
    return cameras;
  }

  /// brand.json `assistant.suggestions`: a list for every language, or {language: list}.
  static Map<String, List<String>> _suggestions(Object? raw) {
    List<String> list(Object? v) => switch (v) {
      List l when l.isNotEmpty && l.every((q) => q is String && q.trim().isNotEmpty) => l.cast<String>(),
      _ => throw const FormatException('brand.json assistant.suggestions must be non-empty lists of questions'),
    };
    return switch (raw) {
      null => const {},
      List _ => {'*': list(raw)},
      Map m => {for (final e in m.entries) e.key as String: list(e.value)},
      _ => throw const FormatException('brand.json assistant.suggestions must be a list or {language: list}'),
    };
  }

  static Map<String, Color> _colors(Object? raw) => {
    for (final e in ((raw as Map?) ?? const {}).entries) e.key as String: parseHex(e.value as String),
  };

  /// `#RRGGBB` or `#AARRGGBB`.
  static Color parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h.length != 6 && h.length != 8) throw FormatException('Bad colour "$hex"');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

class BrandScope extends InheritedWidget {
  const BrandScope({super.key, required this.brand, required super.child});

  final Brand brand;

  static Brand of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BrandScope>()!.brand;

  @override
  bool updateShouldNotify(BrandScope old) => brand != old.brand;
}
