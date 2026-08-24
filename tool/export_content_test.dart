import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_export.dart';
import 'package:masters_of_magic_2/game/content_reference.dart';

/// Regenerates `docs/wiki/content.json` AND `docs/wiki/REFERENCE.md` — run
/// after any content change:
///
///     flutter test tool/export_content_test.dart
///
/// ⭐ Same pattern as the map plate: a test, because the export needs the real
/// game code, and `flutter test` is the cheapest place the real game code
/// runs. `test/content_export_test.dart` holds the actual guarantees; this
/// file only writes the artifacts.
///
/// ⭐ **One build, two renderings.** `ContentExport.build()` is called once;
/// its `counts` map is handed to [ContentReference.build] rather than let it
/// recompute its own, so the number at the top of the Markdown file and the
/// number at the top of the JSON file cannot read differently after a
/// content change that only one of the two generators noticed.
// ignore_for_file: avoid_print
void main() {
  test('regenerate the wiki export', () {
    final export = ContentExport.build();

    final jsonOut = File('docs/wiki/content.json')..parent.createSync();
    jsonOut.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(export),
    );

    final mdOut = File('docs/wiki/REFERENCE.md')..parent.createSync();
    mdOut.writeAsStringSync(
      ContentReference.build(export['counts']! as Map<String, Object?>),
    );

    print(
      'docs/wiki/content.json + docs/wiki/REFERENCE.md — '
      '${export['counts']}',
    );
  });
}
