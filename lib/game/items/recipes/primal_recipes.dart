/// Every recipe learnable in the Primal quarter (ITEMS §9b.8).
///
/// ⭐ **Grouped by band, not by zone** (CONTENT_EXPORT §5): a recipe's inputs
/// deliberately cross zones — the Tuskhide Belt is Cinderpeak hide sewn with
/// Thornmire thread — so a per-zone file would be a fiction.
///
/// ✅ **T1 and T2 are single-material and cheap by ruling**: the first two
/// tiers of everything are fun and easy, and complexity arrives with the
/// later tiers, not here. The one deliberate exception is the belts' second
/// input — hide wants thread, and a two-line recipe is still easy.
///
/// ⚠️ Skill levels gate who can MAKE, equip levels who can WEAR (§9b.3).
/// The two-tier shape here: tier 1 at skill 1, tier 2 at skill 10, belts at
/// their equip levels.
library;

import '../../crafting/gesture.dart';
import '../item_def.dart';
import '../recipe_def.dart';

abstract final class PrimalRecipes {
  // ---- Woodcarving -----------------------------------------------------

  static const oakQuarterstaff = RecipeDef(
    id: 'craft_oak_quarterstaff',
    outputId: 'oak_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 1,
    inputs: [RecipeInput('oak_log', 3)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 2),
      GestureStep(GestureEngine.trace, 'carve', complexity: 1),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 1),
    ],
  );

  static const oakWand = RecipeDef(
    id: 'craft_oak_wand',
    outputId: 'oak_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 1,
    inputs: [RecipeInput('oak_log', 2)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 1),
      GestureStep(GestureEngine.trace, 'carve', complexity: 1),
    ],
  );

  static const oakKnot = RecipeDef(
    id: 'craft_oak_knot',
    outputId: 'oak_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 1,
    inputs: [RecipeInput('oak_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 1),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 1),
    ],
  );

  static const birchQuarterstaff = RecipeDef(
    id: 'craft_birch_quarterstaff',
    outputId: 'birch_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 10,
    inputs: [RecipeInput('birch_log', 3)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 3),
      GestureStep(GestureEngine.trace, 'carve', complexity: 2),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 2),
    ],
  );

  static const birchWand = RecipeDef(
    id: 'craft_birch_wand',
    outputId: 'birch_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 10,
    inputs: [RecipeInput('birch_log', 2)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 2),
      GestureStep(GestureEngine.trace, 'carve', complexity: 2),
    ],
  );

  static const birchKnot = RecipeDef(
    id: 'craft_birch_knot',
    outputId: 'birch_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 10,
    inputs: [RecipeInput('birch_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 2),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 2),
    ],
  );

  // ---- Tailoring: the Bindweed set ------------------------------------

  static const bindweedHood = RecipeDef(
    id: 'craft_bindweed_hood',
    outputId: 'bindweed_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 1,
    inputs: [RecipeInput('bindweed_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 1),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  static const bindweedRobe = RecipeDef(
    id: 'craft_bindweed_robe',
    outputId: 'bindweed_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 1,
    inputs: [RecipeInput('bindweed_fibre', 4)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 1),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  static const bindweedLeggings = RecipeDef(
    id: 'craft_bindweed_leggings',
    outputId: 'bindweed_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 1,
    inputs: [RecipeInput('bindweed_fibre', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 1),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  static const bindweedBoots = RecipeDef(
    id: 'craft_bindweed_boots',
    outputId: 'bindweed_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 1,
    inputs: [RecipeInput('bindweed_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 1),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  static const bindweedGloves = RecipeDef(
    id: 'craft_bindweed_gloves',
    outputId: 'bindweed_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 1,
    inputs: [RecipeInput('bindweed_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 1),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  // ---- Tailoring: belts (hide + thread) -------------------------------

  static const fawnhideBelt = RecipeDef(
    id: 'craft_fawnhide_belt',
    outputId: 'fawnhide_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 4,
    inputs: [RecipeInput('fawnhide', 2), RecipeInput('bindweed_fibre', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 1),
      GestureStep(GestureEngine.alignCommit, 'knot'),
    ],
  );

  static const tuskhideBelt = RecipeDef(
    id: 'craft_tuskhide_belt',
    outputId: 'tuskhide_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 11,
    inputs: [RecipeInput('tuskhide', 2), RecipeInput('bogflax_fibre', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 2),
      GestureStep(GestureEngine.alignCommit, 'knot'),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  // ---- Tailoring: the Bogflax set -------------------------------------

  static const bogflaxHood = RecipeDef(
    id: 'craft_bogflax_hood',
    outputId: 'bogflax_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 10,
    inputs: [RecipeInput('bogflax_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  static const bogflaxRobe = RecipeDef(
    id: 'craft_bogflax_robe',
    outputId: 'bogflax_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 10,
    inputs: [RecipeInput('bogflax_fibre', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  static const bogflaxLeggings = RecipeDef(
    id: 'craft_bogflax_leggings',
    outputId: 'bogflax_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 10,
    inputs: [RecipeInput('bogflax_fibre', 4)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  static const bogflaxBoots = RecipeDef(
    id: 'craft_bogflax_boots',
    outputId: 'bogflax_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 10,
    inputs: [RecipeInput('bogflax_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  static const bogflaxGloves = RecipeDef(
    id: 'craft_bogflax_gloves',
    outputId: 'bogflax_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 10,
    inputs: [RecipeInput('bogflax_fibre', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 2),
    ],
  );

  // ---- Potions & Alchemy ----------------------------------------------
  //
  // ⭐ The whole Q1 potion list, by ruling: one Draught, one Tonic. The
  // Antidote and the first offensive potion are Q2's to introduce.

  static const sapwortDraught = RecipeDef(
    id: 'craft_sapwort_draught',
    outputId: 'sapwort_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 1,
    inputs: [RecipeInput('sapwort', 2)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 2),
      GestureStep(GestureEngine.alignCommit, 'pour'),
    ],
  );

  static const brookmintTonic = RecipeDef(
    id: 'craft_brookmint_tonic',
    outputId: 'brookmint_tonic',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 10,
    inputs: [RecipeInput('brookmint', 2)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 2),
      GestureStep(GestureEngine.rateDrag, 'swirl', reps: 2),
      GestureStep(GestureEngine.bandKeeper, 'simmer'),
    ],
  );

  static const all = <RecipeDef>[
    oakQuarterstaff,
    oakWand,
    oakKnot,
    birchQuarterstaff,
    birchWand,
    birchKnot,
    bindweedHood,
    bindweedRobe,
    bindweedLeggings,
    bindweedBoots,
    bindweedGloves,
    fawnhideBelt,
    tuskhideBelt,
    bogflaxHood,
    bogflaxRobe,
    bogflaxLeggings,
    bogflaxBoots,
    bogflaxGloves,
    sapwortDraught,
    brookmintTonic,
  ];
}
