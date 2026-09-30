import 'dart:convert';
import 'dart:io';

import 'package:p4n4_dashboard/core/brand.dart';

/// Reads `brands/<id>/brand.json` straight from disk, independent of whichever
/// brand is currently applied to assets/brand/. The logo is dropped because
/// only the applied brand's files are in the test asset bundle.
Brand loadBrand(String id) {
  final json = jsonDecode(File('brands/$id/brand.json').readAsStringSync()) as Map<String, dynamic>;
  return Brand.fromJson(json..remove('logo'));
}

List<String> brandIds() => [
  for (final d in Directory('brands').listSync().whereType<Directory>())
    d.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
]..sort();
