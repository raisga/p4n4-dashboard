// ignore_for_file: avoid_print
// White-label brand tool.
//
//   dart run tool/brand.dart list            # available brands
//   dart run tool/brand.dart check <id>      # validate brands/<id>/ only
//   dart run tool/brand.dart apply <id>      # install brand + patch native projects
//
// `apply` copies brands/<id>/ into assets/brand/ (so a build ships exactly one
// brand), rewrites the app name / bundle IDs in the Android, iOS, macOS,
// Windows and Linux runners, and regenerates launcher icons when the brand
// has an icon.png. Every patch is a regex over the current value, so applying
// brands repeatedly in any order is safe.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _tabs = ['services', 'edge', 'agent', 'grafana', 'video'];
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

Future<void> main(List<String> args) async {
  try {
    switch (args) {
      case ['list']:
        for (final d in _brands.listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path))) {
          print(d.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
        }
      case ['check', final id]:
        _validate(id);
        print('✓ brands/$id is valid');
      case ['apply', final id]:
        final brand = _validate(id);
        _install(id);
        _patchNative(brand);
        await _icons(id);
        print('✓ Applied brand "$id". Rebuild the app (flutter clean is not required).');
      default:
        stderr.writeln('usage: dart run tool/brand.dart list | check <id> | apply <id>');
        exit(64);
    }
  } on FormatException catch (e) {
    stderr.writeln('✗ ${e.message}');
    exit(1);
  }
}

// ── validation ────────────────────────────────────────────────────────────

Map<String, dynamic> _validate(String id) {
  final file = File('${_brands.path}/$id/brand.json');
  if (!file.existsSync()) throw FormatException('No brand at brands/$id/brand.json');
  final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final errors = <String>[];

  String? str(Map m, String key, String path) {
    final v = m[key];
    if (v is String && v.trim().isNotEmpty) return v;
    errors.add('$path.$key must be a non-empty string');
    return null;
  }

  if (j['id'] != id) errors.add('id must be "$id" (the folder name)');
  str(j, 'appName', '');
  final wordmark = j['wordmark'];
  wordmark is Map ? str(wordmark, 'text', 'wordmark') : errors.add('wordmark must be an object');

  final logo = j['logo'];
  if (logo != null && !File('${_brands.path}/$id/$logo').existsSync()) errors.add('logo "$logo" not found');

  final tabs = (j['tabs'] as List?)?.cast<String>() ?? _tabs;
  for (final t in tabs) {
    if (!_tabs.contains(t)) errors.add('unknown tab "$t" (valid: ${_tabs.join(', ')})');
  }
  if (tabs.isEmpty) errors.add('tabs must enable at least one tab');

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

  if (errors.isNotEmpty) throw FormatException('brands/$id/brand.json:\n  - ${errors.join('\n  - ')}');
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

// ── install ───────────────────────────────────────────────────────────────

void _install(String id) {
  final dest = Directory('${_root.path}/assets/brand');
  if (dest.existsSync()) dest.deleteSync(recursive: true);
  dest.createSync(recursive: true);
  for (final f in Directory('${_brands.path}/$id').listSync(recursive: true).whereType<File>()) {
    final rel = f.path.substring('${_brands.path}/$id/'.length);
    if (rel == 'icon.png') continue; // launcher icon only, not a runtime asset
    File('${dest.path}/$rel')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(f.readAsBytesSync());
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

Future<void> _icons(String id) async {
  final icon = File('${_brands.path}/$id/icon.png');
  if (!icon.existsSync()) {
    print('  no icon.png in brands/$id; launcher icons left unchanged');
    return;
  }
  final config = File('${Directory.systemTemp.createTempSync('brand').path}/icons.yaml')
    ..writeAsStringSync('''
flutter_launcher_icons:
  image_path: "${icon.path}"
  android: true
  ios: true
  remove_alpha_ios: true
  web:
    generate: false
  windows:
    generate: true
    image_path: "${icon.path}"
    icon_size: 256
  macos:
    generate: true
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
    print('  launcher icons ← brands/$id/icon.png (Android, iOS, macOS, Windows)');
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
