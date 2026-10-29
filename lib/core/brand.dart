import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../api/camera.dart';
import 'role.dart';
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
  const BrandLink(this.labels, this.urls);

  /// By language code (`*`: every language); see [brandText].
  final Map<String, String> labels;
  final Map<String, Uri> urls;

  String get label => brandText(labels, 'en')!;
  Uri get url => brandText(urls, 'en')!;
  String labelIn(String language) => brandText(labels, language)!;
  Uri urlIn(String language) => brandText(urls, language)!;
}

/// A brand's [texts] (or files, or links) by language code, in [language] (a
/// code such as `es`, or a locale name such as `pt_BR`): that language's, else
/// the one for every language (`*`), else English, else any. Null when empty.
T? brandText<T>(Map<String, T> texts, String language) {
  if (texts.isEmpty) return null;
  final code = language.split(RegExp('[_-]')).first.toLowerCase();
  return texts[language] ?? texts[code] ?? texts['*'] ?? texts['en'] ?? texts.values.first;
}

/// Who people can contact when something's wrong, from brand.json `support`:
/// any of an email address, a phone number and a web page. The dashboard
/// offers it where viewers would otherwise be stuck (nothing answering, the
/// assistant down).
class BrandSupport {
  const BrandSupport({this.email, this.phone, this.url});

  /// From `{"email": …, "phone": …, "url": …}`; null when it names none.
  static BrandSupport? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) throw const FormatException('brand.json support must be an object');
    String? field(String key) => switch (raw[key]) {
      null => null,
      final String v when v.trim().isNotEmpty => v.trim(),
      _ => throw FormatException('brand.json support.$key must be a non-empty string'),
    };
    final url = field('url');
    if (url != null &&
        !(Uri.tryParse(url)?.isScheme('https') ?? false) &&
        !(Uri.tryParse(url)?.isScheme('http') ?? false)) {
      throw const FormatException('brand.json support.url must be an http(s) URL');
    }
    final support = BrandSupport(email: field('email'), phone: field('phone'), url: url);
    return support.email == null && support.phone == null && support.url == null ? null : support;
  }

  final String? email;
  final String? phone;
  final String? url;

  /// The ways to get in touch, in the order they're offered: the page, then email, then phone.
  List<Uri> get contacts => [
    if (url != null) Uri.parse(url!),
    if (email != null) Uri(scheme: 'mailto', path: email),
    if (phone != null) Uri(scheme: 'tel', path: phone!.replaceAll(RegExp(r'[^\d+]'), '')),
  ];
}

/// White-label configuration, loaded from `assets/brand/brand.json`.
///
/// That folder holds exactly one brand: `dart run tool/brand.dart <id>` copies
/// `brands/<id>/` into it and patches the native projects, so a build never
/// ships another client's branding. See `brands/README.md`.
class Brand {
  const Brand({
    required this.id,
    required this.appNames,
    required this.wordmark,
    required this.wordmarkSuffix,
    required this.platform,
    this.taglines = const {},
    required this.displayFont,
    required this.monoFont,
    required this.light,
    required this.dark,
    required this.tabs,
    required this.links,
    required this.defaults,
    this.support,
    this.tour = const {},
    this.assistantSuggestions = const {},
    this.assistantViewSuggestions = const {},
    this.demoCameras = const [],
    this.demoCameraNames = const {},
    this.demoCameraCredits = const {},
    this.demoCredits = const {},
    this.logos = const {},
    this.logosDark = const {},
    this.vision = VisionStyle.standard,
  });

  final String id;

  /// Window/task-switcher title, e.g. "p4n4 dashboard", by language code
  /// (brand.json `appName`: text, or {language: text}); see [appNameIn].
  final Map<String, String> appNames;

  /// [appNames] in the brand's own language (its `locale` default, else English).
  String get appName => appNameIn(_language);

  String appNameIn(String language) => brandText(appNames, language) ?? '';

  /// What the dashboard says when it doesn't know the reader's language: the brand's default `locale`.
  String get _language => defaults['locale'] is String ? defaults['locale'] as String : 'en';

  /// App-bar wordmark: [wordmark] in the accent colour + muted [wordmarkSuffix].
  final String wordmark;
  final String wordmarkSuffix;

  /// Replaces "p4n4" in stack and service names (`<platform>-iot`, `<platform>-api`).
  final String platform;

  /// Under the wordmark on sign-in and in Settings → About, by language code.
  final Map<String, String> taglines;

  String taglineIn(String language) => brandText(taglines, language) ?? '';

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

  /// Who to contact when something's wrong; null when the brand names nobody.
  final BrandSupport? support;

  /// Tour text that replaces the built-in copy: step → language code (`*`
  /// for every language) → text.
  final Map<TourStep, Map<String, String>> tour;

  /// [step]'s text from the brand in [language], if it has any.
  String? tourText(TourStep step, String language) => tour[step]?[language] ?? tour[step]?['*'];

  /// Questions the Assistant tab offers to start a chat with, per language
  /// code (`*` for every language), from brand.json `assistant.suggestions`.
  /// Empty: the dashboard's own.
  final Map<String, List<String>> assistantSuggestions;

  /// Questions for one view in place of [assistantSuggestions] (e.g. the
  /// coaches' on the normie view, the analysts' on power), per view and then
  /// per language code, from brand.json `assistant.suggestionsByView`.
  final Map<Role, Map<String, List<String>>> assistantViewSuggestions;

  /// The brand's starter questions in [language] for [view] (its own, else
  /// every view's), or null to use the dashboard's.
  List<String>? suggestionsFor(String language, {Role? view}) {
    final own = assistantViewSuggestions[view];
    return own?[language] ?? own?['*'] ?? assistantSuggestions[language] ?? assistantSuggestions['*'];
  }

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
  /// [language]: the names' (brand.json `name`: text, or {language: text}).
  List<Camera> demoCamerasOn(Uri? page, {String? language}) => [
    for (final c in demoCameras)
      if (Camera.parseUrl(c.url) != null || page != null)
        Camera(
          id: 'demo-${c.id}',
          name: brandText(demoCameraNames[c.id] ?? const {}, language ?? _language) ?? c.name,
          credit: brandText(demoCameraCredits[c.id] ?? const {}, language ?? _language),
          url: Camera.parseUrl(c.url) != null ? c.url : page!.resolve(c.url).toString(),
        ),
  ];

  /// Each demo camera's name by language code, by its id.
  final Map<String, Map<String, String>> demoCameraNames;

  /// A demo camera's credit (whose footage, its licence) by language code, by
  /// its id, from brand.json `video.demoCameras[].credit`: drawn over its
  /// video, as an open licence like CC BY asks, beside [demoCredits]' caption.
  final Map<String, Map<String, String>> demoCameraCredits;

  /// The credit line under [demoCameras], per language code (`*` for every
  /// language), from brand.json `video.demoCredits`.
  final Map<String, String> demoCredits;

  /// The credit line for the brand's demo footage in [language], if it has one.
  String? demoCreditsFor(String language) => demoCredits[language] ?? demoCredits['*'];

  /// How the Video tab's vision overlay looks, from brand.json `video.overlay`.
  final VisionStyle vision;

  /// Asset paths of an app-bar logo that replaces the text wordmark, by
  /// language code (a logo with words in it has one per language): the ones
  /// for light mode, and for both when the brand has no [logosDark].
  final Map<String, String> logos;

  /// Asset paths of the logo for dark mode, from brand.json
  /// `logo: {"light": …, "dark": …}`, so a logo drawn for one background
  /// stays visible on the other. Empty: [logos] in both.
  final Map<String, String> logosDark;

  /// The logo for a [dark] or light background in [language], if the brand has one.
  String? logoFor({required bool dark, String? language}) =>
      brandText(dark && logosDark.isNotEmpty ? logosDark : logos, language ?? _language);

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
    // A file (or {language: file}), or one for each background
    final (logo, logoDark) = switch (j['logo']) {
      null => (const <String, String>{}, const <String, String>{}),
      {'light': final light, 'dark': final dark} => (_texts(light, 'logo.light'), _texts(dark, 'logo.dark')),
      Map m when m.containsKey('light') || m.containsKey('dark') => throw const FormatException(
        'brand.json logo must be a file, or {"light": file, "dark": file} (each a file or {language: file})',
      ),
      final other => (_texts(other, 'logo'), const <String, String>{}),
    };
    final video = switch (j['video']) {
      null => const <String, dynamic>{},
      Map m => m.cast<String, dynamic>(),
      _ => throw const FormatException('brand.json video must be an object'),
    };

    return Brand(
      id: j['id'] as String,
      appNames: switch (_texts(j['appName'], 'appName')) {
        final names when names.isNotEmpty => names,
        _ => throw const FormatException('brand.json appName is required'),
      },
      wordmark: (j['wordmark'] as Map)['text'] as String,
      wordmarkSuffix: ((j['wordmark'] as Map)['suffix'] ?? '') as String,
      platform: (j['platform'] ?? 'p4n4') as String,
      taglines: _texts(j['tagline'], 'tagline'),
      displayFont: displayFont,
      monoFont: monoFont,
      light: P4Colors.light.withBrand(_colors(colors['light'])),
      dark: P4Colors.dark.withBrand(_colors(colors['dark'])),
      tabs: tabs,
      links: [
        for (final l in (j['links'] as List?) ?? const [])
          BrandLink(_texts((l as Map)['label'], 'links.label'), {
            for (final MapEntry(:key, :value) in _texts(l['url'], 'links.url').entries) key: Uri.parse(value),
          }),
      ],
      defaults: ((j['defaults'] as Map?) ?? const {}).cast<String, Object>(),
      support: BrandSupport.fromJson(j['support']),
      tour: _tour(j['tour']),
      assistantSuggestions: _suggestions(((j['assistant'] as Map?) ?? const {})['suggestions']),
      assistantViewSuggestions: {
        for (final MapEntry(:key, :value)
            in ((((j['assistant'] as Map?) ?? const {})['suggestionsByView'] as Map?) ?? const {}).entries)
          ?Role.named(key): _suggestions(value),
      },
      demoCameras: _demoCameras(video['demoCameras']),
      demoCameraNames: {
        for (final c in (video['demoCameras'] as List?) ?? const [])
          if (c case {'id': final String id, 'name': final Map _}) id: _texts(c['name'], 'video.demoCameras.name'),
      },
      demoCameraCredits: {
        for (final c in (video['demoCameras'] as List?) ?? const [])
          if (c case {'id': final String id, 'credit': final Object credit})
            id: _texts(credit, 'video.demoCameras.credit'),
      },
      demoCredits: _texts(video['demoCredits'], 'video.demoCredits'),
      logos: {for (final MapEntry(:key, :value) in logo.entries) key: '$assetDir/$value'},
      logosDark: {for (final MapEntry(:key, :value) in logoDark.entries) key: '$assetDir/$value'},
      vision: VisionStyle.fromJson(video['overlay']),
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
          {'id': final String id, 'name': final Object name, 'url': final String url}
              when id.isNotEmpty &&
                  _texts(name, 'video.demoCameras.name').values.every((n) => n.isNotEmpty) &&
                  _texts(name, 'video.demoCameras.name').isNotEmpty &&
                  url.trim().isNotEmpty &&
                  (Camera.parseUrl(url) != null || !Uri.parse(url).hasScheme) =>
            Camera(id: id, name: brandText(_texts(name, 'video.demoCameras.name'), 'en')!, url: url.trim()),
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

/// How the Video tab's vision overlay looks (brand.json `video.overlay`), so
/// each client's demo can have its own: the people's colour, each kind of
/// object's (by its id in the project's vision file, e.g. a garment
/// category), and which parts show. What a brand leaves out is the
/// dashboard's own look (vision_overlay.dart).
class VisionStyle {
  const VisionStyle({
    this.people,
    this.objects = const {},
    this.showObjects = true,
    this.showTags = true,
    this.showKey = true,
  });

  static const standard = VisionStyle();

  factory VisionStyle.fromJson(Object? raw) {
    if (raw == null) return standard;
    if (raw is! Map) throw const FormatException('brand.json video.overlay must be an object');
    bool flag(String key) => switch (raw[key]) {
      null => true,
      final bool b => b,
      _ => throw FormatException('brand.json video.overlay.$key must be true or false'),
    };
    return VisionStyle(
      people: switch (raw['people']) {
        null => null,
        final String hex => Brand.parseHex(hex),
        _ => throw const FormatException('brand.json video.overlay.people must be a colour'),
      },
      objects: switch (raw['objects']) {
        null => const {},
        final Map m => {
          for (final MapEntry(:key, :value) in m.entries)
            '$key': switch (value) {
              final String hex => Brand.parseHex(hex),
              _ => throw FormatException('brand.json video.overlay.objects.$key must be a colour'),
            },
        },
        _ => throw const FormatException('brand.json video.overlay.objects must be {kind: colour}'),
      },
      showObjects: flag('showObjects'),
      showTags: flag('showTags'),
      showKey: flag('showKey'),
    );
  }

  /// People's boxes and tags, and the HUD's corners; null: the dashboard's cyan.
  final Color? people;

  /// Object kind id → its colour; a kind not here takes the dashboard's palette.
  final Map<String, Color> objects;

  /// Whether objects (garments, bags) are boxed at all, or only people.
  final bool showObjects;

  /// Whether a camera on its own names its boxes (track, confidence, kind).
  final bool showTags;

  /// Whether a camera on its own has a key to the colours.
  final bool showKey;
}

class BrandScope extends InheritedWidget {
  const BrandScope({super.key, required this.brand, required super.child});

  final Brand brand;

  static Brand of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BrandScope>()!.brand;

  /// The brand, where there is one (widgets that also work without, as in tests).
  static Brand? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BrandScope>()?.brand;

  @override
  bool updateShouldNotify(BrandScope old) => brand != old.brand;
}
