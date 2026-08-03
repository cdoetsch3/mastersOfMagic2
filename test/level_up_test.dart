import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/screens/level_up_screen.dart';

void main() {
  group('a level-up says what actually changed', () {
    test('there is always at least one gain', () {
      // ⚠️ The schedules are sparse, so most levels unlock nothing — but a
      // level-up that reports nothing reads as a hollow reward.
      for (var to = 2; to <= 60; to++) {
        expect(
          LevelUpScreen.gainsBetween(to - 1, to),
          isNotEmpty,
          reason: 'level ${to - 1} -> $to shows the player nothing',
        );
      }
    });

    test('health always grows, because the curve is geometric', () {
      for (var to = 2; to <= 60; to++) {
        final gains = LevelUpScreen.gainsBetween(to - 1, to);
        expect(gains.first.title, 'Health');
      }
    });

    test('an element unlock is reported on the level it happens', () {
      final level = Progression.elementUnlockLevels.first;
      final titles = LevelUpScreen.gainsBetween(
        level - 1,
        level,
      ).map((g) => g.title);
      expect(titles.any((t) => t.contains('element')), isTrue);
      // ...and not on the level before it.
      final earlier = LevelUpScreen.gainsBetween(
        level - 2,
        level - 1,
      ).map((g) => g.title);
      expect(earlier.any((t) => t.contains('element')), isFalse);
    });

    test("⭐ crossing two levels at once reports BOTH levels' gains", () {
      // A single fight can cross more than one level; reporting only the
      // last one would quietly swallow an unlock.
      final target = Progression.presetSlotUnlockLevels[1];
      final jumped = LevelUpScreen.gainsBetween(target - 2, target);
      expect(jumped.any((g) => g.title.contains('loadout')), isTrue);
    });

    test('gains are derived from Progression, not hand-listed', () {
      // If a schedule moves, this screen must follow without being edited.
      final at = Progression.spellUnlockLevels.first;
      final titles = LevelUpScreen.gainsBetween(at - 1, at).map((g) => g.title);
      expect(titles.any((t) => t.contains('spell')), isTrue);
    });
  });
}
