import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_export.dart';

/// Regenerates `docs/wiki/content.json` — run after any content change:
///
///     flutter test tool/export_content_test.dart
///
/// ⭐ Same pattern as the map plate: a test, because the export needs the real
/// game code, and `flutter test` is the cheapest place the real game code
/// runs. `test/content_export_test.dart` holds the actual guarantees; this
/// file only writes the artifact.
// ignore_for_file: avoid_print
void main() {
  test('regenerate the wiki export', () {
    final out = File('docs/wiki/content.json')..parent.createSync();
    out.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(ContentExport.build()),
    );
    final counts = ContentExport.build()['counts'];
    print('docs/wiki/content.json — $counts');
  });
}
