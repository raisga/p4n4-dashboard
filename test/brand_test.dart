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
import 'package:p4n4_dashboard/widgets/common.dart';
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
    test('brand $id parses', () {
      final brand = loadBrand(id);
      expect(brand.id, id);
      expect(brand.tabs, isNotEmpty);
    });
  }

  for (final id in brandIds()) {
    test('brand $id ships its fonts', () {
      final brand = loadBrand(id);
      for (final family in {brand.displayFont, brand.monoFont}) {
        final file = File('${brandDir(id).path}/fonts/${family.replaceAll(' ', '')}-Regular.ttf');
        expect(file.existsSync(), isTrue, reason: 'run `dart run tool/brand.dart fonts $id`');
        final license = File('${brandDir(id).path}/fonts/${family.replaceAll(' ', '')}-LICENSE.txt');
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
    expect(brand.tabs, DashTab.defaults);
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
    expect(brand.tabs, DashTab.defaults);
    expect(brand.logo, isNull);
    expect(brand.logoFor(dark: true), isNull);
  });

  test('one logo serves both modes', () {
    final brand = Brand.fromJson(_minimal({'logo': 'logo.png'}));
    expect(brand.logoFor(dark: false), 'assets/brand/logo.png');
    expect(brand.logoFor(dark: true), 'assets/brand/logo.png');
  });

  test('a logo per mode', () {
    final brand = Brand.fromJson(
      _minimal({
        'logo': {'light': 'logo-light.png', 'dark': 'logo.png'},
      }),
    );
    expect(brand.logoFor(dark: false), 'assets/brand/logo-light.png');
    expect(brand.logoFor(dark: true), 'assets/brand/logo.png');
  });

  testWidgets('the wordmark shows the logo for the current mode', (tester) async {
    final brand = Brand.fromJson(
      _minimal({
        'logo': {'light': 'logo-light.png', 'dark': 'logo.png'},
      }),
    );
    for (final (colors, asset) in [(P4Colors.light, 'logo-light.png'), (P4Colors.dark, 'logo.png')]) {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _PixelBundle(),
          child: BrandScope(
            brand: brand,
            child: MaterialApp(theme: buildTheme(colors), home: const Wordmark()),
          ),
        ),
      );
      await tester.pumpAndSettle(); // the theme animates from the previous mode
      final image = tester.widget<Image>(find.byType(Image)).image as AssetImage;
      expect(image.assetName, 'assets/brand/$asset');
    }
  });

  test('the vision overlay\'s look: the dashboard\'s, or the brand\'s', () {
    final plain = Brand.fromJson(_minimal());
    expect(plain.vision.people, isNull);
    expect(plain.vision.objects, isEmpty);
    expect([plain.vision.showObjects, plain.vision.showTags, plain.vision.showKey], [true, true, true]);

    final styled = Brand.fromJson(
      _minimal({
        'video': {
          'overlay': {
            'people': '#FFFFFF',
            'objects': {'tops': '#7FD8BE'},
            'showTags': false,
          },
        },
      }),
    );
    expect(styled.vision.people, const Color(0xFFFFFFFF));
    expect(styled.vision.objects, {'tops': const Color(0xFF7FD8BE)});
    expect([styled.vision.showObjects, styled.vision.showTags, styled.vision.showKey], [true, false, true]);

    for (final bad in <Object>[
      'cyan',
      {'people': 'cyan'},
      {'people': 7},
      {'objects': '#FFFFFF'},
      {
        'objects': {'tops': 3},
      },
      {'showKey': 'no'},
    ]) {
      expect(
        () => Brand.fromJson(
          _minimal({
            'video': {'overlay': bad},
          }),
        ),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });

  test('a logo object needs both modes', () {
    expect(
      () => Brand.fromJson(
        _minimal({
          'logo': {'dark': 'logo.png'},
        }),
      ),
      throwsFormatException,
    );
  });

  test('tabs keep the default order', () {
    final brand = Brand.fromJson(
      _minimal({
        'tabs': ['video', 'services'],
      }),
    );
    expect(brand.tabs, [DashTab.video, DashTab.services]);
  });

  test('tour copy replaces steps per language, or in every language', () {
    final brand = Brand.fromJson(
      _minimal({
        'tour': {
          'welcome': {'en': 'Hi', 'es': 'Hola'},
          'signOut': 'Bye',
        },
      }),
    );
    expect(brand.tourText(TourStep.welcome, 'es'), 'Hola');
    expect(brand.tourText(TourStep.welcome, 'fr'), isNull);
    expect(brand.tourText(TourStep.signOut, 'es'), 'Bye');
    expect(brand.tourText(TourStep.theme, 'en'), isNull);
  });

  test('demo cameras play absolute URLs anywhere, and paths on the web app\'s origin', () {
    final brand = Brand.fromJson(
      _minimal({
        'video': {
          'demoCameras': [
            {'id': 'rack', 'name': 'Rack', 'url': 'https://cdn.example.com/rack.mp4'},
            {'id': 'fitting', 'name': 'Fitting room', 'url': 'demo/fitting.mp4'},
          ],
          'demoCredits': 'Example footage',
        },
      }),
    );
    expect([for (final c in brand.demoCamerasOn(null)) c.url], ['https://cdn.example.com/rack.mp4']);
    final web = brand.demoCamerasOn(Uri.parse('https://store.example.com/dash/index.html'));
    expect([for (final c in web) c.id], ['demo-rack', 'demo-fitting']);
    expect(web.last.url, 'https://store.example.com/dash/demo/fitting.mp4');
    expect(web.every((c) => c.isVideo), isTrue);
    expect(brand.demoCreditsFor('es'), 'Example footage');
    expect(Brand.fromJson(_minimal()).demoCamerasOn(Uri.parse('https://x/')), isEmpty);
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
    expect(
      () => Brand.fromJson(
        _minimal({
          'tour': {'tabs': 'Your tabs'},
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => Brand.fromJson(
        _minimal({
          'tour': {
            'welcome': {'en': 1},
          },
        }),
      ),
      throwsFormatException,
    );
    for (final video in [
      'cams',
      {'demoCameras': 'cam.mp4'},
      {
        'demoCameras': [
          {'id': 'a', 'name': 'A'},
        ],
      },
      {
        'demoCameras': [
          {'id': 'a', 'name': 'A', 'url': 'ftp://cam/a.mp4'},
        ],
      },
      {
        'demoCameras': [
          {'id': 'a', 'name': 'A', 'url': 'demo/a.mp4'},
          {'id': 'a', 'name': 'B', 'url': 'demo/b.mp4'},
        ],
      },
      {'demoCredits': 1},
    ]) {
      expect(() => Brand.fromJson(_minimal({'video': video})), throwsFormatException, reason: '$video');
    }
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

/// Serves a 1×1 transparent PNG for every asset but the manifest, since only
/// the applied brand's files are in the test asset bundle.
class _PixelBundle extends CachingAssetBundle {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async =>
      key.startsWith('AssetManifest') ? rootBundle.load(key) : ByteData.sublistView(_png);
}
