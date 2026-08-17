/// The skill ladder and the Ledger's three views (ITEMS §6a / §9b.9).
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/skills.dart';

/// A throwaway recipe with only the two things [Skills.xpForRecipe] reads.
RecipeDef _recipe({required int gate, required List<int> counts}) => RecipeDef(
      id: 'probe',
      outputId: 'oak_wand',
      skill: CraftSkill.woodcarving,
      skillLevel: gate,
      inputs: [for (final c in counts) RecipeInput('oak_log', c)],
    );

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
      // ⚠️ Kills a count-only implementation: spamming tier-1 must not be the
      // best way to climb past 10. Same single ingredient either side, so the
      // gate is the only thing that can move the number.
      final t1 = Skills.xpForRecipe(_recipe(gate: 1, counts: [1]));
      final t2 = Skills.xpForRecipe(_recipe(gate: 10, counts: [1]));
      expect(t1, 6, reason: '1 × (4 + 2×1)');
      expect(t2, 24, reason: '1 × (4 + 2×10)');
      expect(t2, greaterThan(t1));
    });

    test('⭐ within a tier, XP is in the ratio of the ingredient counts', () {
      // 🚫 Kills the flat `10 + 5·gate` this replaced, under which a 3-log
      // Quarterstaff and a 2-log Wand both paid 15 — making the cheapest
      // recipe in every tier the only rational grind (ruling, 2026-08-17).
      final three = Skills.xpForRecipe(_recipe(gate: 1, counts: [3]));
      final two = Skills.xpForRecipe(_recipe(gate: 1, counts: [2]));
      expect(three / two, closeTo(3 / 2, 1e-9),
          reason: 'the within-tier ratio must be exactly the ingredient count');
    });

    test('the designer\'s worked examples hold, on the shipped recipes', () {
      // ⚠️ Read off `PrimalRecipes`, not retyped fixtures — a recipe whose
      // input line drifted would silently keep a fixture-based test green.
      expect(Skills.xpForRecipe(PrimalRecipes.oakQuarterstaff), 18,
          reason: '3 oak, gate 1 → 3 × 6');
      expect(Skills.xpForRecipe(PrimalRecipes.oakWand), 12,
          reason: '2 oak, gate 1 → 2 × 6');
      expect(Skills.xpForRecipe(PrimalRecipes.oakKnot), 12,
          reason: '2 oak, gate 1 → 2 × 6');
    });

    test('a multi-line recipe counts every line, not the line count', () {
      // 🚫 Kills `inputs.length` in place of the summed counts: the Belt is
      // two lines but three items, so the two implementations differ.
      expect(Skills.xpForRecipe(PrimalRecipes.fawnhideBelt), 3 * (4 + 2 * 4),
          reason: '2 fawnhide + 1 fibre = 3 ingredients at gate 4');
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
