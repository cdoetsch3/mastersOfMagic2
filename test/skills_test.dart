/// The skill ladder and the Ledger's three views (ITEMS §6a / §9b.9).
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/skills.dart';

void main() {
  group('the ladder', () {
    test('level 1 starts empty and the first rung costs 20', () {
      expect(Skills.levelForXp(0), 1);
      expect(Skills.levelForXp(19), 1);
      expect(Skills.levelForXp(20), 2, reason: 'xpToNext(1) is 20');
    });

    test('xpIntoLevel and levelForXp agree about the same total', () {
      // 20 + 25 = 45 spent reaching level 3; 5 left over.
      expect(Skills.levelForXp(50), 3);
      expect(Skills.xpIntoLevel(50), 5,
          reason: 'a second, drifting copy of the walk is the bug this kills');
    });

    test('recipe XP scales with the recipe gate', () {
      // ⚠️ Kills a flat-XP implementation: spamming tier-1 must not be the
      // best way to climb past 10.
      final t1 = Skills.xpForRecipe(
          const RecipeDef(
            id: 'a',
            outputId: 'x',
            skill: CraftSkill.woodcarving,
            skillLevel: 1,
            inputs: [RecipeInput('oak_log', 1)],
          ));
      final t2 = Skills.xpForRecipe(
          const RecipeDef(
            id: 'b',
            outputId: 'y',
            skill: CraftSkill.woodcarving,
            skillLevel: 10,
            inputs: [RecipeInput('birch_log', 1)],
          ));
      expect(t2, greaterThan(t1));
    });

    test('every skill key resolves to a name and the two enums never collide',
        () {
      final keys = Skills.allKeys;
      expect(keys.length, 9);
      expect(keys.toSet().length, 9, reason: 'a collision would merge ledgers');
      for (final k in keys) {
        expect(Skills.displayName(k), isNot(k),
            reason: '$k has no display name');
        expect(Skills.blurb(k), isNotEmpty);
      }
    });
  });

  group("the Ledger's three views", () {
    test('recently unlocked is capped and newest-first', () {
      final recent = Skills.recentlyUnlocked(CraftSkill.tailoring, 11);
      expect(recent.length, lessThanOrEqualTo(5),
          reason: 'uncapped, level 40 renders a wall — the exact complaint');
      expect(recent.first.skillLevel,
          greaterThanOrEqualTo(recent.last.skillLevel),
          reason: 'newest unlock leads');
    });

    test('next unlock is the lowest unreached gate, whole tier at once', () {
      final next = Skills.nextUnlock(CraftSkill.woodcarving, 7);
      expect(next, isNotNull);
      expect(next!.level, 10, reason: 'Birch is the next Woodcarving gate');
      expect(next.recipes.map((r) => r.outputId),
          containsAll(['birch_quarterstaff', 'birch_wand', 'birch_knot']));
      expect(next.recipes.every((r) => r.skillLevel == 10), isTrue,
          reason: 'a later gate leaking in would promise the wrong level');
    });

    test('a maxed skill has no next unlock', () {
      expect(Skills.nextUnlock(CraftSkill.woodcarving, 99), isNull);
    });

    test('view-everything is complete and in unlock order', () {
      final all = Skills.allRecipesFor(CraftSkill.tailoring);
      expect(all.length, 12, reason: '5 Bindweed + 5 Bogflax + 2 belts');
      for (var i = 1; i < all.length; i++) {
        expect(all[i].skillLevel, greaterThanOrEqualTo(all[i - 1].skillLevel),
            reason: 'the sheet scrolls the ladder, not the authoring order');
      }
    });
  });

  group('the profile ledger', () {
    test('skill XP survives a save round trip; old saves read level 1', () {
      final p = PlayerProfile.newPlayer();
      p.skillXp['woodcarving'] = 45;
      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.skillLevel('woodcarving'), 3);
      // An old save has no skillXp key at all.
      final old = PlayerProfile.fromJson({'name': 'Old Timer'});
      expect(old.skillLevel('woodcarving'), 1,
          reason: 'absent must read as unpractised, never crash');
    });
  });
}
