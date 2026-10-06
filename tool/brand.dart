// ignore_for_file: avoid_print
// White-label brand tool.
//
//   dart run tool/brand.dart list                      # installed brands
//   dart run tool/brand.dart check <id|path>           # validate a brand or theme directory only
//   dart run tool/brand.dart fonts <id|path>           # download its fonts into <dir>/fonts/
//   dart run tool/brand.dart install <path> [--apply]  # copy a theme into brands/<id>/
//   dart run tool/brand.dart remove <id>               # delete an installed brand
//   dart run tool/brand.dart apply <id>                # bundle brand + patch native projects
//
// `--web-only` (with `apply`, or `install --apply`) patches and generates
// icons for web/ only, leaving the native runners alone. The container
// build uses it, so its context needs no android/, ios/, … folders.
//
// Only brands/p4n4/ is committed. Client brands are *themes* that live with
// their p4n4 project (e.g. a template's `theme/`, named by `.p4n4.json`
// `dashboard.theme`); `install` takes the theme directory or the project
// directory, and installed brands are gitignored.
//
// `apply` fetches any missing fonts, copies brands/<id>/ into assets/brand/
// (so a build ships exactly one brand and works offline), rewrites the app name / bundle IDs in the Android, iOS, macOS,
// Windows and Linux runners, and regenerates launcher icons when the brand
// has an icon.png. Every patch is a regex over the current value, so applying
// brands repeatedly in any order is safe.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _tabs = ['services', 'edge', 'agent', 'grafana', 'video'];
const _tourSteps = ['welcome', 'navigation', 'theme', 'settings', 'signOut'];
const _tokens = [
  'bg', 'bg2', 'bg3', 'accent', 'accent2', 'onAccent', 'amber', 'blue', //
  'heading', 'text', 'muted', 'border', 'border2', 'ok', 'warn', 'err',
];

// Built-in palettes (lib/core/theme.dart), needed to contrast-check partial overrides.
const _base = {
  'light': {
    'bg': 'FAFAF9', 'bg2': 'FFFFFF', 'bg3': 'F5F5F4', 'accent': 'C2410C', 'accent2': '9A3412', //
    'onAccent': 'FFFFFF', 'amber': 'B45309', 'blue': '475569', 'heading': '0A0A0A', 'text': '1C1917',
    'muted': '57534E', 'border': 'E7E5E4', 'border2': 'D6D3D1', 'ok': '15803D', 'warn': 'A16207', 'err': 'B91C1C',
  },
  'dark': {
    'bg': '0A0A0A', 'bg2': '111111', 'bg3': '1A1A1A', 'accent': 'F97316', 'accent2': 'C2410C', //
    'onAccent': '0A0A0A', 'amber': 'FB923C', 'blue': '94A3B8', 'heading': 'FFFFFF', 'text': 'ECECEC',
    'muted': 'A8A8A8', 'border': '1F1F1F', 'border2': '2A2A2A', 'ok': '22C55E', 'warn': 'EAB308', 'err': 'EF4444',
  },
};

final _root = File.fromUri(Platform.script).parent.parent;
Directory get _brands => Directory('${_root.path}/brands');

/// The default brand: always installed, never removed or overwritten.
const _defaultBrand = 'p4n4';

/// [path] relative to the repository when it's inside it, for messages.
String _rel(String path) => path.startsWith('${_root.path}/') ? path.substring(_root.path.length + 1) : path;

Future<void> main(List<String> args) async {
  final webOnly = args.contains('--web-only');
  args = [...args.where((a) => a != '--web-only')];
  try {
    switch (args) {
      case ['list']:
        for (final d in _brands.listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path))) {
          print(d.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
        }
      case ['id', final arg]:
        // For scripts (make image THEME=…): the brand id a theme or project installs as.
        stdout.writeln(_validate(_resolve(arg))['id']);
      case ['check', final arg]:
        final dir = _resolve(arg);
        _validate(dir);
        print('✓ ${_rel(dir.path)} is valid');
      case ['fonts', final arg]:
        final dir = _resolve(arg);
        await _fonts(dir, _validate(dir), refresh: true);
      case ['install', final path] || ['install', final path, '--apply']:
        final id = await _installTheme(_resolve(path, installed: false));
        if (args.length == 3) {
          await _apply(id, webOnly: webOnly);
        } else {
          print('✓ Installed brand "$id". Apply it with: dart run tool/brand.dart apply $id');
        }
      case ['remove', final id]:
        _remove(id);
      case ['apply', final id]:
        await _apply(id, webOnly: webOnly);
      default:
        stderr.writeln(
          'usage: dart run tool/brand.dart list | id <path> | check <id|path> | fonts <id|path> | '
          'install <path> [--apply [--web-only]] | remove <id> | apply <id> [--web-only]',
        );
        exit(64);
    }
  } on FormatException catch (e) {
    stderr.writeln('✗ ${e.message}');
    exit(1);
  }
}

Future<void> _apply(String id, {bool webOnly = false}) async {
  final dir = Directory('${_brands.path}/$id');
  if (!dir.existsSync()) {
    throw FormatException(
      'No brand "$id" in brands/. Install its theme first: dart run tool/brand.dart install <path>',
    );
  }
  final brand = _validate(dir);
  await _fonts(dir, brand);
  _bundle(brand);
  if (webOnly) {
    _patchWeb(brand, (brand['native'] as Map)['displayName'] as String);
  } else {
    _patchNative(brand);
  }
  await _icons(brand, webOnly: webOnly);
  print('✓ Applied brand "$id"${webOnly ? ' (web only)' : ''}. Rebuild the app (flutter clean is not required).');
}

// ── themes ────────────────────────────────────────────────────────────────

/// A brand directory from [arg]: an installed brand id, a theme directory
/// (holding brand.json), or a p4n4 project whose `.p4n4.json` names its theme
/// in `dashboard.theme`. With [installed] false, only paths are accepted.
Directory _resolve(String arg, {bool installed = true}) {
  final installedDir = Directory('${_brands.path}/$arg');
  if (installed && !arg.contains('/') && installedDir.existsSync()) return installedDir;
  final dir = Directory(arg).absolute;
  if (File('${dir.path}/brand.json').existsSync()) return dir;
  final manifest = File('${dir.path}/.p4n4.json');
  if (manifest.existsSync()) {
    final dashboard = (jsonDecode(manifest.readAsStringSync()) as Map)['dashboard'];
    final theme = dashboard is Map ? dashboard['theme'] : null;
    if (theme is! String || theme.isEmpty) {
      throw FormatException('${manifest.path} has no dashboard.theme');
    }
    return Directory('${dir.path}/$theme');
  }
  throw FormatException(
    installed
        ? 'No brand "$arg" in brands/, and no brand.json or .p4n4.json at $arg'
        : 'No brand.json or .p4n4.json at $arg',
  );
}

/// Copies the theme in [src] to `brands/<id>/` (replacing an older install) and
/// fetches any fonts it doesn't ship. Returns the brand id.
Future<String> _installTheme(Directory src) async {
  final brand = _validate(src);
  final id = brand['id'] as String;
  if (id == _defaultBrand) throw FormatException('"$_defaultBrand" is the built-in brand; a theme needs its own id');
  final dest = Directory('${_brands.path}/$id');
  if (dest.absolute.path == src.absolute.path) throw FormatException('brands/$id is already installed');
  if (dest.existsSync()) dest.deleteSync(recursive: true);
  for (final f in src.listSync(recursive: true).whereType<File>()) {
    File('${dest.path}/${f.path.substring(src.path.length + 1)}')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(f.readAsBytesSync());
  }
  print('  brands/$id/ ← ${src.path}');
  await _fonts(dest, brand);
  return id;
}

void _remove(String id) {
  if (id == _defaultBrand) throw FormatException('"$_defaultBrand" is the built-in brand and can\'t be removed');
  final dir = Directory('${_brands.path}/$id');
  if (!dir.existsSync()) throw FormatException('No brand "$id" in brands/');
  dir.deleteSync(recursive: true);
  print('✓ Removed brands/$id');
  final applied = File('${_root.path}/assets/brand/brand.json');
  if (applied.existsSync() && (jsonDecode(applied.readAsStringSync()) as Map)['id'] == id) {
    print('! "$id" is still applied: run dart run tool/brand.dart apply $_defaultBrand');
  }
}

// ── validation ────────────────────────────────────────────────────────────

/// Validates the brand in [dir]. An installed brand's id must match its
/// folder; a theme elsewhere needs an id of its own (not the built-in one).
Map<String, dynamic> _validate(Directory dir) {
  final file = File('${dir.path}/brand.json');
  final where = _rel(file.path);
  if (!file.existsSync()) throw FormatException('No brand at $where');
  final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final errors = <String>[];
  final installed = dir.parent.absolute.path == _brands.absolute.path;
  final folder = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);

  String? str(Map m, String key, String path) {
    final v = m[key];
    if (v is String && v.trim().isNotEmpty) return v;
    errors.add('$path.$key must be a non-empty string');
    return null;
  }

  if (installed && j['id'] != folder) errors.add('id must be "$folder" (the folder name)');
  if (j['id'] is! String || !RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(j['id'] as String)) {
    errors.add('id must be lowercase letters, digits and dashes');
  } else if (!installed && j['id'] == _defaultBrand) {
    errors.add('id "$_defaultBrand" is reserved for the built-in brand');
  }
  str(j, 'appName', '');
  final wordmark = j['wordmark'];
  wordmark is Map ? str(wordmark, 'text', 'wordmark') : errors.add('wordmark must be an object');

  final logo = j['logo'];
  if (logo != null && !File('${dir.path}/$logo').existsSync()) errors.add('logo "$logo" not found');

  final tabs = (j['tabs'] as List?)?.cast<String>() ?? _tabs;
  for (final t in tabs) {
    if (!_tabs.contains(t)) errors.add('unknown tab "$t" (valid: ${_tabs.join(', ')})');
  }
  if (tabs.isEmpty) errors.add('tabs must enable at least one tab');

  final tour = j['tour'];
  if (tour != null && tour is! Map) errors.add('tour must be an object');
  // The dashboard's languages: one ARB file each in lib/l10n/.
  final languages = [
    for (final f in Directory('${_root.path}/lib/l10n').listSync())
      if (RegExp(r'app_(\w+)\.arb$').firstMatch(f.path) case final m?) m[1]!,
  ];
  for (final MapEntry(:key, :value) in ((tour as Map?) ?? const {}).entries) {
    if (!_tourSteps.contains(key)) {
      errors.add('unknown tour step "$key" (valid: ${_tourSteps.join(', ')})');
    } else if (value is Map) {
      for (final MapEntry(key: lang, value: text) in value.entries) {
        if (lang != '*' && !languages.contains(lang)) {
          errors.add('tour.$key.$lang is not a dashboard language (valid: ${languages.join(', ')}, or *)');
        }
        if (text is! String || text.trim().isEmpty) errors.add('tour.$key.$lang must be a non-empty string');
      }
    } else if (value is! String || value.trim().isEmpty) {
      errors.add('tour.$key must be text, or an object of language code → text');
    }
  }

  final native = j['native'];
  if (native is! Map) {
    errors.add('native must be an object');
  } else {
    str(native, 'displayName', 'native');
    final appId = str(native, 'applicationId', 'native');
    final bundleId = str(native, 'bundleId', 'native');
    // Android: segments start with a letter, [A-Za-z0-9_]. Apple: [A-Za-z0-9.-].
    if (appId != null && !RegExp(r'^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$').hasMatch(appId)) {
      errors.add('native.applicationId "$appId" is not a valid Android application ID');
    }
    if (bundleId != null && !RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$').hasMatch(bundleId)) {
      errors.add('native.bundleId "$bundleId" is not a valid Apple bundle ID');
    }
  }

  final colors = (j['colors'] as Map?) ?? const {};
  for (final mode in ['light', 'dark']) {
    final overrides = (colors[mode] as Map?) ?? const {};
    final palette = Map.of(_base[mode]!);
    for (final MapEntry(:key, :value) in overrides.entries) {
      if (!_tokens.contains(key)) {
        errors.add('colors.$mode.$key is not a colour token (valid: ${_tokens.join(', ')})');
      } else if (value is! String || !RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value)) {
        errors.add('colors.$mode.$key must be #RRGGBB or #AARRGGBB');
      } else {
        final hex = value.replaceFirst('#', '');
        palette[key as String] = hex.substring(hex.length - 6);
      }
    }
    _contrast(mode, palette);
  }

  if (errors.isNotEmpty) throw FormatException('$where:\n  - ${errors.join('\n  - ')}');
  return j;
}

/// Warns when text tokens miss WCAG AA (4.5:1) against the surfaces.
void _contrast(String mode, Map<String, String> p) {
  double lum(String hex) {
    final c = [0, 2, 4]
        .map((i) => int.parse(hex.substring(i, i + 2), radix: 16) / 255)
        .map((v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble());
    final [r, g, b] = c.toList();
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double ratio(String a, String b) {
    final (x, y) = (lum(a), lum(b));
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  final pairs = [
    for (final fg in ['heading', 'text', 'muted', 'accent', 'amber', 'blue', 'ok', 'warn', 'err'])
      for (final bg in ['bg', 'bg2', 'bg3']) (fg, bg),
    ('onAccent', 'accent'),
  ];
  for (final (fg, bg) in pairs) {
    final r = ratio(p[fg]!, p[bg]!);
    if (r < 4.5) stderr.writeln('! $mode: $fg on $bg is ${r.toStringAsFixed(2)}:1 (WCAG AA needs 4.5:1)');
  }
}

// ── fonts ─────────────────────────────────────────────────────────────────

/// Weights the app uses (lib/core/theme.dart, plus Material's w500 labels).
const _weights = {400: 'Regular', 500: 'Medium', 600: 'SemiBold', 700: 'Bold', 800: 'ExtraBold'};

/// The brand's font families by role, as the app's `BrandDisplay` /
/// `BrandMono` families in pubspec.yaml name them (lowercased).
Map<String, String> _families(Map<String, dynamic> brand) {
  final fonts = (brand['fonts'] as Map?) ?? const {};
  return {
    'display': (fonts['display'] ?? 'Plus Jakarta Sans') as String,
    'mono': (fonts['mono'] ?? 'JetBrains Mono') as String,
  };
}

String _fontFile(String family, int weight) => '${family.replaceAll(' ', '')}-${_weights[weight]}.ttf';

String _licenseFile(String family) => '${family.replaceAll(' ', '')}-LICENSE.txt';

/// Where google/fonts keeps a family's license, by license type.
List<Uri> _licenseUrls(String family) {
  final dir = family.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  return [
    for (final path in ['ofl/$dir/OFL.txt', 'apache/$dir/LICENSE.txt', 'ufl/$dir/UFL.txt'])
      Uri.https('raw.githubusercontent.com', '/google/fonts/main/$path'),
  ];
}

/// Downloads the brand's display and mono fonts from Google Fonts into
/// `<brandDir>/fonts/` as `<Family>-<Weight>.ttf`, plus each family's
/// license as `<Family>-LICENSE.txt` (shown on the app's licenses page).
/// Existing files are kept unless [refresh].
Future<void> _fonts(Directory brandDir, Map<String, dynamic> brand, {bool refresh = false}) async {
  final families = _families(brand).values.toSet();
  final dir = Directory('${brandDir.path}/fonts')..createSync(recursive: true);
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    for (final family in families) {
      for (final weight in _weights.keys) {
        final file = File('${dir.path}/${_fontFile(family, weight)}');
        if (file.existsSync() && !refresh) continue;
        // A non-browser user agent makes the CSS API return static TTF URLs.
        final css = Uri.https('fonts.googleapis.com', '/css2', {'family': '$family:wght@$weight'});
        final res = await (await http.getUrl(css)).close();
        final body = await res.transform(utf8.decoder).join();
        if (res.statusCode == 400) continue; // no such weight (or family; checked below)
        final url = RegExp(r'url\((https://[^)]+\.ttf)\)').firstMatch(body)?.group(1);
        if (res.statusCode != 200 || url == null) {
          throw FormatException('Could not fetch "$family" $weight from Google Fonts (HTTP ${res.statusCode})');
        }
        final ttf = await (await http.getUrl(Uri.parse(url))).close();
        if (ttf.statusCode != 200) throw FormatException('Could not download $url (HTTP ${ttf.statusCode})');
        file.writeAsBytesSync(await ttf.fold<List<int>>([], (a, b) => a..addAll(b)));
        print('  ${_rel(file.path)}');
      }
      if (!_weights.keys.any((w) => File('${dir.path}/${_fontFile(family, w)}').existsSync())) {
        throw FormatException('Font "$family" is not a Google Fonts family (brand.json `fonts`)');
      }
      final license = File('${dir.path}/${_licenseFile(family)}');
      if (!license.existsSync() || refresh) {
        String? text;
        for (final url in _licenseUrls(family)) {
          final res = await (await http.getUrl(url)).close();
          final body = await res.transform(utf8.decoder).join();
          if (res.statusCode == 200) {
            text = body;
            break;
          }
        }
        if (text == null) throw FormatException('No license found for "$family" in github.com/google/fonts');
        license.writeAsStringSync(text);
        print('  ${_rel(license.path)}');
      }
    }
  } on SocketException catch (e) {
    throw FormatException('Fonts need a network connection to download: ${e.message}');
  } finally {
    http.close();
  }
  // Drop fonts left over from a previous font choice.
  final prefixes = families.map((f) => '${f.replaceAll(' ', '')}-');
  for (final f in dir.listSync().whereType<File>()) {
    if (!prefixes.any(f.uri.pathSegments.last.startsWith)) f.deleteSync();
  }
}

// ── bundle ────────────────────────────────────────────────────────────────

void _bundle(Map<String, dynamic> brand) {
  final id = brand['id'] as String;
  final src = '${_brands.path}/$id';
  final dest = Directory('${_root.path}/assets/brand');
  if (dest.existsSync()) dest.deleteSync(recursive: true);
  dest.createSync(recursive: true);
  for (final f in Directory(src).listSync(recursive: true).whereType<File>()) {
    final rel = f.path.substring('$src/'.length);
    // icon.png is the launcher icon only; fonts are installed under fixed names below.
    if (rel == 'icon.png' || rel.startsWith('fonts/')) continue;
    File('${dest.path}/$rel')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(f.readAsBytesSync());
  }
  // pubspec.yaml declares BrandDisplay / BrandMono from `fonts/<role>-<weight>.ttf`
  // for every weight, so a weight the family lacks gets the nearest one it has.
  for (final MapEntry(key: role, value: family) in _families(brand).entries) {
    final have = [
      for (final w in _weights.keys)
        if (File('$src/fonts/${_fontFile(family, w)}').existsSync()) w,
    ];
    for (final w in _weights.keys) {
      final nearest = have.reduce((a, b) => (a - w).abs() <= (b - w).abs() ? a : b);
      File('$src/fonts/${_fontFile(family, nearest)}')
          .copySync((File('${dest.path}/fonts/$role-$w.ttf')..parent.createSync(recursive: true)).path);
    }
    File('$src/fonts/${_licenseFile(family)}')
        .copySync((File('${dest.path}/licenses/$role.txt')..parent.createSync(recursive: true)).path);
  }
  print('  assets/brand/ ← brands/$id/');
}

// ── native projects ───────────────────────────────────────────────────────

String _xml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
String _c(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

void _patchNative(Map<String, dynamic> brand) {
  final n = (brand['native'] as Map).cast<String, String>();
  final name = n['displayName']!;
  final appId = n['applicationId']!;
  final bundleId = n['bundleId']!;
  final company = n['company'] ?? name;
  final localNet = n['localNetworkUsage'] ?? 'Connects to services on your local network.';
  final year = DateTime.now().year;

  _patch('android/app/build.gradle.kts', [(RegExp(r'applicationId = "[^"]*"'), 'applicationId = "$appId"')]);
  _patch('android/app/src/main/AndroidManifest.xml', [
    (RegExp(r'android:label="[^"]*"'), 'android:label="${_xml(name)}"'),
  ]);
  _patch('ios/Runner/Info.plist', [
    (RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*'), '\$1${_xml(name)}'),
    (RegExp(r'(<key>NSLocalNetworkUsageDescription</key>\s*<string>)[^<]*'), '\$1${_xml(localNet)}'),
  ]);
  _patch('ios/Runner.xcodeproj/project.pbxproj', [
    (RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*\.RunnerTests;'), 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId.RunnerTests;'),
    (RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*\.RunnerTests;)[^;]*;'), 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;'),
  ]);
  _patch('macos/Runner/Configs/AppInfo.xcconfig', [
    (RegExp(r'^PRODUCT_NAME = .*$', multiLine: true), 'PRODUCT_NAME = $name'),
    (RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER = .*$', multiLine: true), 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId'),
    (
      RegExp(r'^PRODUCT_COPYRIGHT = .*$', multiLine: true),
      'PRODUCT_COPYRIGHT = Copyright © $year $company. All rights reserved.',
    ),
  ]);
  _patch('macos/Runner.xcodeproj/project.pbxproj', [
    (RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*\.RunnerTests;'), 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId.RunnerTests;'),
  ]);
  _patch('linux/CMakeLists.txt', [(RegExp(r'set\(APPLICATION_ID "[^"]*"\)'), 'set(APPLICATION_ID "$appId")')]);
  _patch('linux/runner/my_application.cc', [
    (
      RegExp(r'gtk_header_bar_set_title\(header_bar, "(?:[^"\\]|\\.)*"\)'),
      'gtk_header_bar_set_title(header_bar, "${_c(name)}")',
    ),
    (RegExp(r'gtk_window_set_title\(window, "(?:[^"\\]|\\.)*"\)'), 'gtk_window_set_title(window, "${_c(name)}")'),
  ]);
  _patchWeb(brand, name);
  _patch('windows/runner/main.cpp', [(RegExp(r'window\.Create\(L"(?:[^"\\]|\\.)*"'), 'window.Create(L"${_c(name)}"')]);
  _patch('windows/runner/Runner.rc', [
    for (final key in ['FileDescription', 'ProductName'])
      (RegExp('VALUE "$key", "(?:[^"\\\\]|\\\\.)*"'), 'VALUE "$key", "${_c(name)}"'),
    (RegExp(r'VALUE "CompanyName", "(?:[^"\\]|\\.)*"'), 'VALUE "CompanyName", "${_c(company)}"'),
    (
      RegExp(r'VALUE "LegalCopyright", "(?:[^"\\]|\\.)*"'),
      'VALUE "LegalCopyright", "Copyright (C) $year ${_c(company)}. All rights reserved."',
    ),
  ]);
}

/// The brand's light-mode [token] as `#RRGGBB`, falling back to the built-in palette.
String _lightColor(Map<String, dynamic> brand, String token) {
  final override = (((brand['colors'] as Map?)?['light'] as Map?)?[token]) as String?;
  final hex = (override ?? _base['light']![token]!).replaceFirst('#', '');
  return '#${hex.substring(hex.length - 6).toUpperCase()}';
}

/// Page title, home-screen name, description and colors of the web build.
void _patchWeb(Map<String, dynamic> brand, String displayName) {
  final appName = brand['appName'] as String;
  final tagline = (brand['tagline'] as String?)?.trim() ?? '';
  final description = tagline.isEmpty ? appName : tagline;
  _patch('web/index.html', [
    (RegExp(r'<title>[^<]*</title>'), '<title>${_xml(appName)}</title>'),
    (RegExp(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*'), '\$1${_xml(displayName)}'),
    (RegExp(r'(<meta name="description" content=")[^"]*'), '\$1${_xml(description)}'),
  ]);
  // JSON string values; the lookbehind keeps "name" from matching "short_name".
  String field(String key, String value) => '"$key": ${jsonEncode(value)}';
  _patch('web/manifest.json', [
    (RegExp(r'(?<!_)"name": "(?:[^"\\]|\\.)*"'), field('name', appName)),
    (RegExp(r'"short_name": "(?:[^"\\]|\\.)*"'), field('short_name', displayName)),
    (RegExp(r'"description": "(?:[^"\\]|\\.)*"'), field('description', description)),
    (RegExp(r'"theme_color": "[^"]*"'), field('theme_color', _lightColor(brand, 'accent'))),
    (RegExp(r'"background_color": "[^"]*"'), field('background_color', _lightColor(brand, 'bg'))),
  ]);
}

void _patch(String path, List<(RegExp, String)> edits, {bool quiet = false}) {
  final file = File('${_root.path}/$path');
  if (!file.existsSync()) {
    stderr.writeln('! skipped $path (not found)');
    return;
  }
  var s = file.readAsStringSync();
  for (final (re, replacement) in edits) {
    if (!re.hasMatch(s)) {
      if (!quiet) stderr.writeln('! $path: no match for ${re.pattern}');
      continue;
    }
    s = s.replaceAllMapped(re, (m) => replacement.replaceAllMapped(RegExp(r'\$(\d)'), (g) => m[int.parse(g[1]!)]!));
  }
  file.writeAsStringSync(s);
  if (!quiet) print('  patched $path');
}

// ── launcher icons ────────────────────────────────────────────────────────

Future<void> _icons(Map<String, dynamic> brand, {bool webOnly = false}) async {
  final id = brand['id'] as String;
  final icon = File('${_brands.path}/$id/icon.png');
  if (!icon.existsSync()) {
    print('  no icon.png in brands/$id; launcher icons left unchanged');
    return;
  }
  final config = File('${Directory.systemTemp.createTempSync('brand').path}/icons.yaml')
    ..writeAsStringSync('''
flutter_launcher_icons:
  image_path: "${icon.path}"
  android: ${!webOnly}
  ios: ${!webOnly}
  remove_alpha_ios: true
  web:
    generate: true
    image_path: "${icon.path}"
    background_color: "${_lightColor(brand, 'bg')}"
    theme_color: "${_lightColor(brand, 'accent')}"
  windows:
    generate: ${!webOnly}
    image_path: "${icon.path}"
    icon_size: 256
  macos:
    generate: ${!webOnly}
    image_path: "${icon.path}"
''');
  final r = await Process.run('dart', [
    'run',
    'flutter_launcher_icons',
    '-f',
    config.path,
  ], workingDirectory: _root.path);
  if (r.exitCode != 0) {
    stderr.writeln('! icon generation failed:\n${r.stdout}\n${r.stderr}');
  } else {
    print('  launcher icons ← brands/$id/icon.png (${webOnly ? 'web' : 'Android, iOS, macOS, Windows, web'})');
  }
  if (webOnly) {
    config.parent.deleteSync(recursive: true);
    return;
  }
  // flutter_launcher_icons 0.14 rewrites *every* ASSETCATALOG_* line in the
  // iOS project to the icon name, clobbering this boolean setting.
  _patch('ios/Runner.xcodeproj/project.pbxproj', [
    (
      RegExp(r'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = (?!YES;|NO;)[^;]*;'),
      'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;',
    ),
  ], quiet: true);
  config.parent.deleteSync(recursive: true);
}
