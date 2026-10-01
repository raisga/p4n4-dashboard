import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/core/brand.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/brands.dart';

Map<String, dynamic> _minimal([Map<String, dynamic> extra = const {}]) => {
  'id': 'test',
  'appName': 'Test',
  'wordmark': {'text': 'test'},
  ...extra,
};

void main() {
  for (final id in brandIds()) {
    test('brands/$id parses', () {
      final brand = loadBrand(id);
      expect(brand.id, id);
      expect(brand.tabs, isNotEmpty);
    });
  }

  for (final id in brandIds()) {
    test('brands/$id ships its fonts', () {
      final brand = loadBrand(id);
      for (final family in {brand.displayFont, brand.monoFont}) {
        final file = File('brands/$id/fonts/${family.replaceAll(' ', '')}-Regular.ttf');
        expect(file.existsSync(), isTrue, reason: 'run `dart run tool/brand.dart fonts $id`');
        final license = File('brands/$id/fonts/${family.replaceAll(' ', '')}-LICENSE.txt');
        expect(license.existsSync(), isTrue, reason: 'run `dart run tool/brand.dart fonts $id`');
      }
    });
  }

  testWidgets('the applied brand bundles its fonts, so they load offline', (tester) async {
    final manifest = (jsonDecode(await rootBundle.loadString('FontManifest.json')) as List).cast<Map>();
    for (final family in [P4Colors.displayFamily, P4Colors.monoFamily]) {
      final fonts = (manifest.firstWhere((f) => f['family'] == family)['fonts'] as List).cast<Map>();
      expect(fonts.map((f) => f['weight']), [400, 500, 600, 700, 800], reason: family);
      for (final f in fonts) {
        // Throws if `tool/brand.dart apply` didn't install the file.
        expect(
          (await rootBundle.load(f['asset'] as String)).lengthInBytes,
          greaterThan(10000),
          reason: '${f['asset']}',
        );
      }
    }
  });

  testWidgets('the applied brand\'s font licenses are on the licenses page', (tester) async {
    addTearDown(LicenseRegistry.reset);
    final brand = await Brand.load()
      ..registerFontLicenses();
    final entries = (await tester.runAsync(() => LicenseRegistry.licenses.toList()))!;
    for (final family in {brand.displayFont, brand.monoFont}) {
      final entry = entries.singleWhere((e) => e.packages.contains(family));
      expect(entry.paragraphs.map((p) => p.text).join('\n'), contains('License'), reason: family);
    }
  });

  test('the p4n4 brand is the built-in palette', () {
    final brand = loadBrand('p4n4');
    expect(brand.dark.accent, P4Colors.dark.accent);
    expect(brand.light.bg, P4Colors.light.bg);
    expect(brand.tabs, DashTab.values);
  });

  test('colour overrides apply per mode and leave other tokens alone', () {
    final brand = Brand.fromJson(
      _minimal({
        'colors': {
          'dark': {'accent': '#2DD4BF'},
        },
      }),
    );
    expect(brand.dark.accent, const Color(0xFF2DD4BF));
    expect(brand.dark.bg, P4Colors.dark.bg);
    expect(brand.light.accent, P4Colors.light.accent);
  });

  test('minimal brand gets defaults', () {
    final brand = Brand.fromJson(_minimal());
    expect(brand.platform, 'p4n4');
    expect(brand.wordmarkSuffix, '');
    expect(brand.displayFont, 'Plus Jakarta Sans');
    expect(brand.tabs, DashTab.values);
    expect(brand.logo, isNull);
  });

  test('tabs keep canonical order', () {
    final brand = Brand.fromJson(
      _minimal({
        'tabs': ['video', 'services'],
      }),
    );
    expect(brand.tabs, [DashTab.services, DashTab.video]);
  });

  test('invalid brand config is rejected', () {
    expect(() => Brand.fromJson(_minimal({'tabs': <String>[]})), throwsFormatException);
    expect(
      () => Brand.fromJson(
        _minimal({
          'tabs': ['radar'],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => Brand.fromJson(
        _minimal({
          'colors': {
            'light': {'accentt': '#000000'},
          },
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => Brand.fromJson(
        _minimal({
          'colors': {
            'light': {'accent': 'teal'},
          },
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => Brand.fromJson(
        _minimal({
          'fonts': {'mono': ''},
        }),
      ),
      throwsFormatException,
    );
  });

  test('brand defaults seed settings until the user changes them', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(
      defaults: {'host': 'edge.local', 'edgeDemo': true, 'themeMode': 'dark'},
      secrets: MemorySecretStore(),
    );
    expect(settings.host, 'edge.local');
    expect(settings.edgeDemo, isTrue);
    expect(settings.themeMode, ThemeMode.dark);
    settings.host = '10.0.0.2';
    expect(settings.host, '10.0.0.2');
  });

  test('a mistyped brand default fails loudly', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(defaults: {'edgeDemo': 'yes'}, secrets: MemorySecretStore());
    expect(() => settings.edgeDemo, throwsFormatException);
  });
}
