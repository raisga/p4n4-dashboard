import 'dart:convert';
import 'dart:io';

import 'package:p4n4_dashboard/core/brand.dart';

/// Where brand folders live: the committed `brands/` (just p4n4, plus any
/// installed themes) and test fixtures such as `acme`, which exercises every
/// brand option without being shipped.
const _roots = ['brands', 'test/fixtures/brands'];

/// The folder holding brand [id].
Directory brandDir(String id) => _roots
    .map((root) => Directory('$root/$id'))
    .firstWhere((d) => File('${d.path}/brand.json').existsSync(), orElse: () => throw ArgumentError('No brand "$id"'));

/// Reads `<brandDir>/brand.json` straight from disk, independent of whichever
/// brand is currently applied to assets/brand/. The logo is dropped because
/// only the applied brand's files are in the test asset bundle.
Brand loadBrand(String id) {
  final json = jsonDecode(File('${brandDir(id).path}/brand.json').readAsStringSync()) as Map<String, dynamic>;
  return Brand.fromJson(json..remove('logo'));
}

List<String> brandIds() => [
  for (final root in _roots)
    for (final d in Directory(root).listSync().whereType<Directory>())
      if (File('${d.path}/brand.json').existsSync()) d.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
]..sort();
