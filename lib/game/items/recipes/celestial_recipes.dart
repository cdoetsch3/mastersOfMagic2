/// Every recipe learnable in the Celestial quarter (CELESTIAL_CONTRACT §5).
///
/// ⭐ **Grouped by band, not by zone** — the same reason `primal_recipes.dart`
/// and `kinetic_recipes.dart` give: a recipe's inputs deliberately cross
/// zones, and three of this quarter's cross two *quarters*. The Ironwood
/// Quarterstaff is the Kiln Desert's log with a Thunderspire ferrule; both
/// ingots eat Charcoal banked in Ashfall Vale at L10. A per-zone recipe file
/// would be a fiction.
///
/// ✅ **28 recipes across five skills** (§5): Metalworking 2 · Woodcarving 9 ·
/// Tailoring 12 · Potions & Alchemy 4 · ⭐ **Enchanting 1 — the debut**.
/// 📝 28 is above the ~20–26 guide and the cause is canon, not sprawl: ITEMS
/// §9b.6 puts **three** wood tiers in this band (Ironwood, Bloodwood, Ebony)
/// where the Kinetic quarter had two, which is nine Woodcarving recipes
/// against six.
///
/// ⭐ **Enchanting debuts with exactly one recipe, and it is the gate**
/// (§3.4): `craft_celestial_totem`, the only `stationRequired: true` in this
/// quarter. ⚠️ Enchanting therefore does not *climb* this quarter, which is
/// deliberate — the skill's real ladder is ITEMS §6.2's **Transmute** verb,
/// which is not a `RecipeDef` and must not become twenty-four of them.
///
/// ⭐ **Metalworking keeps feeding, and the feed crosses a quarter boundary.**
/// #3 and #4 spend `iron_ingot`, a Kinetic intermediate; #1 and #2 spend
/// `charcoal`, banked in Ashfall Vale — the **third** quarter to spend it, and
/// §9b.6's "a concrete reason to revisit old zones" paid by the ore ladder
/// rather than the wood one.
///
/// 📝 **§5.2 names a fix this file deliberately does NOT take.** Metalworking
/// is the quarter's one grind (~28 Iron Ingots to reach gate 36) and §5.2's
/// remedy is a `craft_skysteel_fitting` at gate 20 with #6/#7/#9/#10
/// re-pointed at it. It is "named here rather than taken" because it also
/// rewrites four input lists — a designer's call, not a builder's.
///
/// ⚠️ **Motes appear in no recipe.** ECONOMY §14c makes them sell-only and
/// lossy against the refinement ladder; a mote in a gear recipe would make
/// refine-and-craft a second, unaudited arbitrage.
///
/// ⚠️ Skill levels gate who can MAKE, equip levels who can WEAR (§5). The two
/// never move together and conflating them kills the twink lane.
///
/// XP is `Σ input counts × (4 + 2 × gate)` (`Skills.xpForRecipe`) — computed,
/// never stored. Every value in this file's doc comments is the hand-worked
/// check against that formula, not a second source of truth.
library;

import '../../crafting/gesture.dart';
import '../item_def.dart';
import '../recipe_def.dart';

abstract final class CelestialRecipes {
  // ---- Metalworking -------------------------------------------------------
  //
  // ⭐ Still a pure feeder lane, exactly as it debuted: two recipes, four
  // downstream Woodcarving consumers, nothing crafted from an ingot except a
  // shaft. The script is Bronze's and Iron's — stoke, pour, quench — two
  // notches hotter.

  /// #1 — Starfall Basin's Skyiron plus ⏳ banked Ashfall Vale Charcoal.
  /// XP: (3+2) × (4+2×36) = 5 × 76 = **380**.
  static const skysteelIngot = RecipeDef(
    id: 'craft_skysteel_ingot',
    outputId: 'skysteel_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 36,
    inputs: [RecipeInput('skyiron_ore', 3), RecipeInput('charcoal', 2)],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke', complexity: 3),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 4),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 4),
    ],
  );

  /// #2 — the Shattered Orrery's scrap, remelted, plus the same Charcoal.
  /// XP: (3+2) × (4+2×44) = 5 × 92 = **460**.
  static const starbrassIngot = RecipeDef(
    id: 'craft_starbrass_ingot',
    outputId: 'starbrass_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 44,
    inputs: [RecipeInput('orrery_scrap', 3), RecipeInput('charcoal', 2)],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke', complexity: 4),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 5),
    ],
  );

  // ---- Woodcarving: Ironwood (The Kiln Desert) ----------------------------
  //
  // ⭐ Same shape as Oak/Birch/Yew/Rowan (chop → carve → sand), tier 5 — and
  // ⭐ the ferrule is `iron_ingot`, a Kinetic output. §6a.1's "many of those
  // outputs are inputs to other recipes," one quarter later.

  /// #3 — XP: (3+1) × (4+2×36) = 4 × 76 = **304**.
  static const ironwoodQuarterstaff = RecipeDef(
    id: 'craft_ironwood_quarterstaff',
    outputId: 'ironwood_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 36,
    inputs: [RecipeInput('ironwood_log', 3), RecipeInput('iron_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 6),
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 4),
    ],
  );

  /// #4 — XP: (2+1) × 76 = 3 × 76 = **228**.
  static const ironwoodWand = RecipeDef(
    id: 'craft_ironwood_wand',
    outputId: 'ironwood_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 36,
    inputs: [RecipeInput('ironwood_log', 2), RecipeInput('iron_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
    ],
  );

  /// #5 — XP: 2 × 76 = **152**.
  static const ironwoodKnot = RecipeDef(
    id: 'craft_ironwood_knot',
    outputId: 'ironwood_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 36,
    inputs: [RecipeInput('ironwood_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 4),
    ],
  );

  // ---- Woodcarving: Bloodwood (The Mirrormere) ---------------------------
  //
  // ⭐ Tier 6, and the first wood tier to take a Celestial ferrule: Skysteel,
  // not Iron. 📝 §5's own trim candidate if 28 ever has to become 26 — the
  // wand and the knot, since Bloodwood sits only five levels above Ironwood.

  /// #6 — XP: (3+1) × (4+2×40) = 4 × 84 = **336**.
  static const bloodwoodQuarterstaff = RecipeDef(
    id: 'craft_bloodwood_quarterstaff',
    outputId: 'bloodwood_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 40,
    inputs: [RecipeInput('bloodwood_log', 3), RecipeInput('skysteel_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 6),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 5),
    ],
  );

  /// #7 — XP: (2+1) × 84 = 3 × 84 = **252**.
  static const bloodwoodWand = RecipeDef(
    id: 'craft_bloodwood_wand',
    outputId: 'bloodwood_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 40,
    inputs: [RecipeInput('bloodwood_log', 2), RecipeInput('skysteel_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
    ],
  );

  /// #8 — XP: 2 × 84 = **168**.
  static const bloodwoodKnot = RecipeDef(
    id: 'craft_bloodwood_knot',
    outputId: 'bloodwood_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 40,
    inputs: [RecipeInput('bloodwood_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 5),
    ],
  );

  // ---- Woodcarving: Ebony (The Sunless Reach) ----------------------------
  //
  // ⭐ Tier 7 — the quarter's top wood, and the third main-hand tier that
  // §5.3 calls out as this quarter's one change to slot coverage.

  /// #9 — XP: (3+1) × (4+2×44) = 4 × 92 = **368**.
  static const ebonyQuarterstaff = RecipeDef(
    id: 'craft_ebony_quarterstaff',
    outputId: 'ebony_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 44,
    inputs: [RecipeInput('ebony_log', 3), RecipeInput('starbrass_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 7),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 6),
    ],
  );

  /// #10 — XP: (2+1) × 92 = 3 × 92 = **276**.
  static const ebonyWand = RecipeDef(
    id: 'craft_ebony_wand',
    outputId: 'ebony_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 44,
    inputs: [RecipeInput('ebony_log', 2), RecipeInput('starbrass_ingot', 1)],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 6),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
    ],
  );

  /// #11 — XP: 2 × 92 = **184**.
  static const ebonyKnot = RecipeDef(
    id: 'craft_ebony_knot',
    outputId: 'ebony_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 44,
    inputs: [RecipeInput('ebony_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 6),
    ],
  );

  // ---- Tailoring: the Mirrorflax set (The Mirrormere) --------------------
  //
  // ⭐ Same shape as Bindweed/Bogflax/Seawrack/Tussock (thread → stitch): five
  // slots, one material, no ingot. ⚠️ §5.5 records this set as Σ(inputs) =
  // output value exactly — ECONOMY §8.6's blessed boundary case, as
  // `seawrack_hood` already ships. That is a value fact, not a recipe one;
  // nothing here encodes it.

  /// #12 — XP: 3 × (4+2×36) = 3 × 76 = **228**.
  static const mirrorflaxHood = RecipeDef(
    id: 'craft_mirrorflax_hood',
    outputId: 'mirrorflax_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 36,
    inputs: [RecipeInput('mirrorflax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #13 — XP: 6 × 76 = **456**.
  static const mirrorflaxRobe = RecipeDef(
    id: 'craft_mirrorflax_robe',
    outputId: 'mirrorflax_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 36,
    inputs: [RecipeInput('mirrorflax', 6)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 6),
    ],
  );

  /// #14 — XP: 5 × 76 = **380**.
  static const mirrorflaxLeggings = RecipeDef(
    id: 'craft_mirrorflax_leggings',
    outputId: 'mirrorflax_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 36,
    inputs: [RecipeInput('mirrorflax', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #15 — XP: 3 × 76 = **228**.
  static const mirrorflaxBoots = RecipeDef(
    id: 'craft_mirrorflax_boots',
    outputId: 'mirrorflax_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 36,
    inputs: [RecipeInput('mirrorflax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #16 — XP: 3 × 76 = **228**.
  static const mirrorflaxGloves = RecipeDef(
    id: 'craft_mirrorflax_gloves',
    outputId: 'mirrorflax_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 36,
    inputs: [RecipeInput('mirrorflax', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  // ---- Tailoring: belts (hide + thread) ----------------------------------
  //
  // ⭐ Same shape as Fawnhide/Tuskhide/Rimepelt/Emberhide (cut → knot →
  // stitch). Belts are capacity, never power (§6b.2, §7.5); the recipe earns
  // its own gate only because the hide is kill-only (§9b.7b) — ⚠️ neither
  // `drownling_hide` nor `palimpsest_vellum` has a gather node, and §6 says
  // so on purpose.

  /// #17 — Tidewrack's kill-only Drownling Hide plus a Mirrorflax thread.
  /// XP: (2+1) × (4+2×38) = 3 × 80 = **240**.
  static const drownlingBelt = RecipeDef(
    id: 'craft_drownling_belt',
    outputId: 'drownling_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 38,
    inputs: [RecipeInput('drownling_hide', 2), RecipeInput('mirrorflax', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 4),
      GestureStep(GestureEngine.alignCommit, 'knot', complexity: 2),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 3),
    ],
  );

  // ---- Tailoring: the Wrackcotton set (Tidewrack Shoals) -----------------

  /// #18 — XP: 3 × (4+2×40) = 3 × 84 = **252**.
  static const wrackcottonHood = RecipeDef(
    id: 'craft_wrackcotton_hood',
    outputId: 'wrackcotton_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 40,
    inputs: [RecipeInput('wrackcotton', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #19 — XP: 6 × 84 = **504**.
  static const wrackcottonRobe = RecipeDef(
    id: 'craft_wrackcotton_robe',
    outputId: 'wrackcotton_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 40,
    inputs: [RecipeInput('wrackcotton', 6)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 6),
    ],
  );

  /// #20 — XP: 5 × 84 = **420**.
  static const wrackcottonLeggings = RecipeDef(
    id: 'craft_wrackcotton_leggings',
    outputId: 'wrackcotton_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 40,
    inputs: [RecipeInput('wrackcotton', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #21 — XP: 3 × 84 = **252**.
  static const wrackcottonBoots = RecipeDef(
    id: 'craft_wrackcotton_boots',
    outputId: 'wrackcotton_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 40,
    inputs: [RecipeInput('wrackcotton', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #22 — XP: 3 × 84 = **252**.
  static const wrackcottonGloves = RecipeDef(
    id: 'craft_wrackcotton_gloves',
    outputId: 'wrackcotton_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 40,
    inputs: [RecipeInput('wrackcotton', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #23 — the Glass Archive's kill-only Palimpsest Vellum (⚠️ "a palimpsest
  /// is a hide", §3.1) plus a Wrackcotton thread; the quarter's second belt
  /// and the top of the capacity ladder. XP: (2+1) × (4+2×44) = 3 × 92 =
  /// **276**.
  static const palimpsestBelt = RecipeDef(
    id: 'craft_palimpsest_belt',
    outputId: 'palimpsest_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [
      RecipeInput('palimpsest_vellum', 2),
      RecipeInput('wrackcotton', 1),
    ],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'knot', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  // ---- Potions & Alchemy --------------------------------------------------
  //
  // ⭐ Four rungs where the Kinetic quarter had one — §3.3 settling the
  // KINETIC §9 debt. The Draught/Tonic alternation of §5.4 is the whole
  // point: a Draught heals now, a Tonic pays over three turns, and the ladder
  // never gives two of the same form in a row.
  // ⚠️ The Ration lane (`pilgrims_ration`) is **drop-only** and therefore has
  // no recipe here — that is what makes it the floor a player can reach
  // without a Potions skill at all.

  /// #24 — XP: 2 × (4+2×34) = 2 × 72 = **144**.
  static const glasswortDraught = RecipeDef(
    id: 'craft_glasswort_draught',
    outputId: 'glasswort_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 34,
    inputs: [RecipeInput('glasswort', 2)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 3),
    ],
  );

  /// #25 — XP: 2 × (4+2×38) = 2 × 80 = **160**.
  static const duskcapTonic = RecipeDef(
    id: 'craft_duskcap_tonic',
    outputId: 'duskcap_tonic',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 38,
    inputs: [RecipeInput('duskcap', 2)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 4),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 3),
    ],
  );

  /// #26 — XP: 3 × (4+2×42) = 3 × 88 = **264**.
  static const arcsaltDraught = RecipeDef(
    id: 'craft_arcsalt_draught',
    outputId: 'arcsalt_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 42,
    inputs: [RecipeInput('arcsalt', 3)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 4),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 4),
    ],
  );

  /// #27 — XP: 3 × (4+2×44) = 3 × 92 = **276**.
  static const sunbleachTonic = RecipeDef(
    id: 'craft_sunbleach_tonic',
    outputId: 'sunbleach_tonic',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 44,
    inputs: [RecipeInput('sunbleach_lichen', 3)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 5),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 4),
    ],
  );

  // ---- Enchanting (DEBUT) -------------------------------------------------

  /// #28 ⭐ — **the Rimeholt gate, and the first Enchanting recipe in the
  /// game** (§3.4).
  ///
  /// ⭐ **The gate is a craft, not a collection.** KINETIC §8.6 rejected the
  /// Kinetic Sigil's collect-three-keys mechanism; this is not that. The
  /// player is shown **one object** at the barrier — `rimeholt.gateItemIds`
  /// is the single id `celestial_totem`, shown and not spent — and the three
  /// essences are its *recipe inputs*, consumed here.
  ///
  /// ⚠️ **Gate 1, and that is the whole design** (§5.2). Enchanting opens at
  /// Meridian (L36) with an empty book and nothing to climb from, so a gate
  /// above 1 would be a tier gate nobody could ever pass: there is no second
  /// Enchanting recipe to earn the XP on, and 📝 whether Transmute pays
  /// Enchanting XP is still an open ruling (§8.2). A level-1 enchanter must
  /// be able to make this the day the skill opens. ⭐ The cost is the three
  /// boss essences, not the gate — and the gesture script is forgiving for
  /// the same reason `craft_bronze_ingot`'s is.
  ///
  /// ⚠️ **`stationRequired: true`, the only one in this quarter.**
  /// `RecipeDef`'s doc asks every `true` to cite why: **a tier gate must not
  /// be craftable in the field.** The Totem is charged at the observatory
  /// that can see both Celestial elements' sky, or it is not charged.
  ///
  /// ⭐ It spends `hum_quartz`, paying the one Kinetic banking promise that
  /// had no named consumer.
  ///
  /// XP: (1+1+1+3+2) × (4+2×1) = 8 × 6 = **48**.
  static const celestialTotem = RecipeDef(
    id: 'craft_celestial_totem',
    outputId: 'celestial_totem',
    skill: CraftSkill.enchanting,
    skillLevel: 1,
    stationRequired: true,
    inputs: [
      RecipeInput('solar_essence', 1),
      RecipeInput('lunar_essence', 1),
      RecipeInput('astral_essence', 1),
      RecipeInput('hum_quartz', 3),
      RecipeInput('fallstone', 2),
    ],
    steps: [
      GestureStep(GestureEngine.trace, 'rune', complexity: 2),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 2),
      GestureStep(GestureEngine.releaseTiming, 'channel', reps: 2),
    ],
  );

  /// ⚠️ **Order is load-bearing.** Within each skill these ascend by gate, and
  /// `celestial_recipes_test` asserts it — that is what makes
  /// `Skills.allRecipesFor` read as a ladder rather than a bag.
  static const all = <RecipeDef>[
    skysteelIngot,
    starbrassIngot,
    ironwoodQuarterstaff,
    ironwoodWand,
    ironwoodKnot,
    bloodwoodQuarterstaff,
    bloodwoodWand,
    bloodwoodKnot,
    ebonyQuarterstaff,
    ebonyWand,
    ebonyKnot,
    mirrorflaxHood,
    mirrorflaxRobe,
    mirrorflaxLeggings,
    mirrorflaxBoots,
    mirrorflaxGloves,
    drownlingBelt,
    wrackcottonHood,
    wrackcottonRobe,
    wrackcottonLeggings,
    wrackcottonBoots,
    wrackcottonGloves,
    palimpsestBelt,
    glasswortDraught,
    duskcapTonic,
    arcsaltDraught,
    sunbleachTonic,
    celestialTotem,
  ];
}
