/// Every recipe learnable in the Kinetic quarter (KINETIC_CONTRACT §5).
///
/// ⭐ **Grouped by band, not by zone** (mirrors `primal_recipes.dart` /
/// CONTENT_EXPORT §5): a recipe's inputs deliberately cross zones — Bronze
/// is Old Quarry's Tin plus Q1's banked Copper and Charcoal; the Yew
/// Quarterstaff is Windward Steppe's log with an Old Quarry ferrule — so a
/// per-zone recipe file would be a fiction exactly as the Primal comment
/// says.
///
/// ✅ **21 recipes across four skills** (Ruling 3): Metalworking 2 ·
/// Woodcarving 6 · Tailoring 12 · Potions & Alchemy 1. ⚠️ Jewelry does not
/// debut this quarter (§8.1 — its station and its learning both stay at
/// Rimeholt, L45) and the Antidote / offensive potion are deferred (§8.5) —
/// five recipes lighter than the original 26-recipe draft, renumbered 1–21
/// with no gaps.
///
/// ⭐ **Metalworking debuts here, and it is a pure feeder lane by design**
/// (§5's "Metalworking is a pure feeder lane" note): two recipes, four
/// downstream Woodcarving consumers, nothing crafted from an ingot except a
/// shaft. `craft_bronze_ingot` is also the payoff ITEMS §9b.8 promised when
/// it banked Copper (Cinderpeak) and Charcoal (Ashfall Vale) as "gatherable
/// now, spendable next quarter" — Tin is the missing half, and this is the
/// first recipe a Kinetic player should meet.
///
/// ⚠️ Skill levels gate who can MAKE, equip levels who can WEAR (§9b.3). The
/// two never move together and conflating them kills the twink lane.
///
/// XP is `Σ input counts × (4 + 2 × gate)` (`Skills.xpForRecipe`) — computed,
/// never stored. Every value in this file's doc comments is the hand-worked
/// check against that formula, not a second source of truth.
library;

import '../../crafting/gesture.dart';
import '../item_def.dart';
import '../recipe_def.dart';

abstract final class KineticRecipes {
  // ---- Metalworking (DEBUT) --------------------------------------------
  //
  // ⭐ The first Metalworking recipes in the game. `craft_bronze_ingot`
  // crosses all three gesture categories in one script — the same
  // tutorial-by-fiction `craft_oak_quarterstaff` used to introduce
  // Woodcarving in the Primal quarter (`gesture_and_nodes_test.dart`).

  /// #1 — copper (⏳ banked, Cinderpeak) + tin (Old Quarry) + charcoal (⏳
  /// banked, Ashfall Vale) → Bronze, at Forgeholm, the moment Metalworking
  /// opens at 15. XP: (2+1+1) × (4+2×1) = 4 × 6 = **24**.
  static const bronzeIngot = RecipeDef(
    id: 'craft_bronze_ingot',
    outputId: 'bronze_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 1,
    inputs: [
      RecipeInput('copper_ore', 2),
      RecipeInput('tin_ore', 1),
      RecipeInput('charcoal', 1),
    ],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke'),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 2),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 2),
    ],
  );

  /// #2 — Thunderspire's Iron Ore plus banked Charcoal. XP: (3+2) × (4+20)
  /// = 5 × 24 = **120**.
  static const ironIngot = RecipeDef(
    id: 'craft_iron_ingot',
    outputId: 'iron_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 10,
    inputs: [RecipeInput('iron_ore', 3), RecipeInput('charcoal', 2)],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke', complexity: 2),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 3),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 3),
    ],
  );

  // ---- Woodcarving: Yew (equip 20, Windward Steppe) ---------------------
  //
  // ⭐ Same shape as Oak/Birch (chop → carve → sand), one more tier up: the
  // wood ladder's tier 3, and the first wood recipe to eat a Metalworking
  // output (the ferrule, §5's fittings note).

  /// #3 — XP: (3+1) × (4+40) = 4 × 44 = **176**.
  static const yewQuarterstaff = RecipeDef(
    id: 'craft_yew_quarterstaff',
    outputId: 'yew_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 20,
    inputs: [RecipeInput('yew_log', 3), RecipeInput('bronze_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 4),
      GestureStep(GestureEngine.trace, 'carve', complexity: 3),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 3),
    ],
  );

  /// #4 — XP: (2+1) × 44 = 3 × 44 = **132**.
  static const yewWand = RecipeDef(
    id: 'craft_yew_wand',
    outputId: 'yew_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 20,
    inputs: [RecipeInput('yew_log', 2), RecipeInput('bronze_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 3),
      GestureStep(GestureEngine.trace, 'carve', complexity: 3),
    ],
  );

  /// #5 — XP: 2 × 44 = **88**.
  static const yewKnot = RecipeDef(
    id: 'craft_yew_knot',
    outputId: 'yew_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 20,
    inputs: [RecipeInput('yew_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 3),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 3),
    ],
  );

  // ---- Woodcarving: Rowan (equip 25, Thunderspire Peaks) -----------------
  //
  // ⭐ Tier 4: crafting's first crit (§2.5) and the wood ladder's first
  // socket, both on the ITEM side — this file only carries the recipe.

  /// #6 — XP: (3+1) × (4+60) = 4 × 64 = **256**.
  static const rowanQuarterstaff = RecipeDef(
    id: 'craft_rowan_quarterstaff',
    outputId: 'rowan_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 30,
    inputs: [RecipeInput('rowan_log', 3), RecipeInput('iron_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 4),
    ],
  );

  /// #7 — XP: (2+1) × 64 = 3 × 64 = **192**.
  static const rowanWand = RecipeDef(
    id: 'craft_rowan_wand',
    outputId: 'rowan_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 30,
    inputs: [RecipeInput('rowan_log', 2), RecipeInput('iron_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 4),
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
    ],
  );

  /// #8 — XP: 2 × 64 = **128**.
  static const rowanKnot = RecipeDef(
    id: 'craft_rowan_knot',
    outputId: 'rowan_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 30,
    inputs: [RecipeInput('rowan_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 4),
    ],
  );

  // ---- Tailoring: the Seawrack set (equip 16, Stormcliff Coast) ----------
  //
  // ⭐ Same shape as Bindweed/Bogflax (thread → stitch): the tailoring
  // ladder's tier 3, one skill gate ahead of Yew.

  /// #9 — XP: 2 × 44 = **88**.
  static const seawrackHood = RecipeDef(
    id: 'craft_seawrack_hood',
    outputId: 'seawrack_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 20,
    inputs: [RecipeInput('seawrack_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  /// #10 — XP: 5 × 44 = **220**.
  static const seawrackRobe = RecipeDef(
    id: 'craft_seawrack_robe',
    outputId: 'seawrack_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 20,
    inputs: [RecipeInput('seawrack_fibre', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #11 — XP: 4 × 44 = **176**.
  static const seawrackLeggings = RecipeDef(
    id: 'craft_seawrack_leggings',
    outputId: 'seawrack_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 20,
    inputs: [RecipeInput('seawrack_fibre', 4)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  /// #12 — XP: 2 × 44 = **88**.
  static const seawrackBoots = RecipeDef(
    id: 'craft_seawrack_boots',
    outputId: 'seawrack_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 20,
    inputs: [RecipeInput('seawrack_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  /// #13 — XP: 2 × 44 = **88**.
  static const seawrackGloves = RecipeDef(
    id: 'craft_seawrack_gloves',
    outputId: 'seawrack_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 20,
    inputs: [RecipeInput('seawrack_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  // ---- Tailoring: belts (hide + thread) ----------------------------------
  //
  // ⭐ Same shape as Fawnhide/Tuskhide (cut → knot → stitch): belts are
  // capacity, never power (§6b.2, §7.5) — the recipe only earns its own
  // gate because the hide is kill-only (§9b.7b), not because the item is
  // special.

  /// #14 — Frostfell's kill-only Rimepelt plus a Tussock thread. XP:
  /// (2+1) × (4+48) = 3 × 52 = **156**.
  static const rimepeltBelt = RecipeDef(
    id: 'craft_rimepelt_belt',
    outputId: 'rimepelt_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 24,
    inputs: [RecipeInput('rimepelt', 2), RecipeInput('tussock_flax', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 2),
      GestureStep(GestureEngine.alignCommit, 'knot'),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  /// #20 — Molten Deep's kill-only Emberhide plus a Tussock thread. XP:
  /// (2+1) × (4+68) = 3 × 72 = **216**. (Numbered #20 in §5.1's table —
  /// grouped here with the other belt for the same reason as Primal's
  /// Fawnhide/Tuskhide pair.)
  static const emberhideBelt = RecipeDef(
    id: 'craft_emberhide_belt',
    outputId: 'emberhide_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 34,
    inputs: [RecipeInput('emberhide', 2), RecipeInput('tussock_flax', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 3),
      GestureStep(GestureEngine.alignCommit, 'knot'),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  // ---- Tailoring: the Tussock set (equip 24, Windward Steppe) ------------

  /// #15 — XP: 3 × 64 = **192**.
  static const tussockHood = RecipeDef(
    id: 'craft_tussock_hood',
    outputId: 'tussock_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 30,
    inputs: [RecipeInput('tussock_flax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  /// #16 — XP: 6 × 64 = **384**.
  static const tussockRobe = RecipeDef(
    id: 'craft_tussock_robe',
    outputId: 'tussock_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 30,
    inputs: [RecipeInput('tussock_flax', 6)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #17 — XP: 5 × 64 = **320**.
  static const tussockLeggings = RecipeDef(
    id: 'craft_tussock_leggings',
    outputId: 'tussock_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 30,
    inputs: [RecipeInput('tussock_flax', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #18 — XP: 3 × 64 = **192**.
  static const tussockBoots = RecipeDef(
    id: 'craft_tussock_boots',
    outputId: 'tussock_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 30,
    inputs: [RecipeInput('tussock_flax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  /// #19 — XP: 3 × 64 = **192**.
  static const tussockGloves = RecipeDef(
    id: 'craft_tussock_gloves',
    outputId: 'tussock_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 30,
    inputs: [RecipeInput('tussock_flax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  // ---- Potions & Alchemy --------------------------------------------------
  //
  // ⭐ The Draught form again (Q1's Sapwort Draught), one skill gate later —
  // §8.5 defers the Antidote and the first offensive potion, so this is the
  // whole of Kinetic Potions.

  /// #21 — XP: 2 × 44 = **88**.
  static const saltwortDraught = RecipeDef(
    id: 'craft_saltwort_draught',
    outputId: 'saltwort_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 20,
    inputs: [RecipeInput('saltwort', 2)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 2),
    ],
  );

  static const all = <RecipeDef>[
    bronzeIngot,
    ironIngot,
    yewQuarterstaff,
    yewWand,
    yewKnot,
    rowanQuarterstaff,
    rowanWand,
    rowanKnot,
    seawrackHood,
    seawrackRobe,
    seawrackLeggings,
    seawrackBoots,
    seawrackGloves,
    rimepeltBelt,
    tussockHood,
    tussockRobe,
    tussockLeggings,
    tussockBoots,
    tussockGloves,
    emberhideBelt,
    saltwortDraught,
  ];
}
