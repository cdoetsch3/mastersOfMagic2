/// One release, one number (ruling 2026-08-25).
///
/// ⭐ The day this test was written, the repo held THREE version numbers and
/// two had already drifted: app_version.dart said 0.12.0 (26), pubspec said
/// 0.13.0+27, the live content version was 2. A "keep in sync" comment is a
/// wish; a failing test is a rule.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/app_version.dart';
import 'package:masters_of_magic_2/game/content_version.dart';

void main() {
  test('pubspec version is exactly $appVersion+${ContentVersion.current}', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final v = line.split(':')[1].trim();
    expect(
      v,
      '$appVersion+${ContentVersion.current}',
      reason: 'the build number IS the content version (the number the login '
          'gate compares and the About panel shows) — bump ContentVersion'
          '.current, pubspec\'s +N, and the server doc together, every '
          'release. ⚠️ The mutant this kills: any of the three moving alone.',
    );
  });
}
