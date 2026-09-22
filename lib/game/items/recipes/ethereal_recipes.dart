/// Every recipe learnable in the Ethereal quarter (ETHEREAL_CONTRACT §5).
///
/// ⭐ **Grouped by band, not by zone** — the same reason `primal_recipes.dart`,
/// `kinetic_recipes.dart` and `celestial_recipes.dart` give: a recipe's inputs
/// deliberately cross zones, and this quarter's Jewelry ladder crosses three
/// *quarters*. The Everice Band is made of a stone from Old Quarry (L15) and
/// a stone from Frostfell Pass (L21) set in a Buried Sky garnet. A per-zone
/// recipe file would be a fiction.
///
/// ✅ **32 recipes across five skills** (§7.1): Tailoring 13 · Woodcarving 6 ·
/// ⭐ **Jewelry 7 — the debut** · Potions & Alchemy 4 · Metalworking 2 ·
/// ⚠️ **Enchanting 0**.
/// 📝 32 is above the ~20–26 guide and §5 names the cause: seven of the
/// thirty-two are the first Jewelry recipes in the game and they exist to
/// spend seven gems banked across three quarters. ⚠️ §0.2 rules that nothing
/// may be left unspent, so the cheap trim (`craft_nacre_pendant`,
/// `craft_eclipse_signet` → 30) would strand a banked material and is refused.
///
/// ⭐⭐ **Jewelry debuts as a complete seven-rung ladder, 1 → 10 → 20 → 30 →
/// 35 → 44 → 50**, which no other skill has ever been given (§5.2). ⚠️ That is
/// the right shape for a skill debuting fifteen levels from the cap:
/// Metalworking debuted at L15 with two recipes and a gate at 10, and
/// CELESTIAL §5.2 already flagged the resulting 28-craft grind. Jewelry does
/// not repeat it.
///
/// ⭐⭐ **§6a.1's *"every slot has a maker"* becomes true in this file**, sixty
/// levels in (§5.3). Neck and Ring were drop-only from the Whispering Woods to
/// The Glass Archive; the seven Jewelry recipes close both at once — three
/// Neck (Nacre Pendant, Aetherglass Locket, Corona Torc) and four Ring
/// (Everice Band, Eclipse Signet, Orchard Loop, Eclipse Ring).
///
/// ⭐ **#1 and #2 spend `charcoal` — the fourth quarter to do so.** Ashfall
/// Vale (L10–14) is a zone a level-60 player still has a reason to visit, and
/// §9b.6's "a concrete reason to revisit old zones" is paid by the ore ladder
/// for the fourth time running.
///
/// ⚠️ **Enchanting gets nothing this quarter** (§5.2). CELESTIAL §8.2's ❓ —
/// does Transmute pay XP? — is still open and this contract cannot close it.
/// A recipe added here to "fix" that would be a builder overruling a designer.
///
/// ⚠️ **Motes appear in no recipe.** ECONOMY §14c makes them sell-only and
/// lossy against the refinement ladder; a mote in a gear recipe would make
/// refine-and-craft a second, unaudited arbitrage.
///
/// ⚠️ Skill levels gate who can MAKE, equip levels who can WEAR (§5). The two
/// never move together and conflating them kills the twink lane — ⭐ and
/// `everice_band` is this quarter's sharpest example: gate **1**, equip level
/// **45**.
///
/// 📝 **§5.4's audit is carried in `test/value_conservation_test.dart`, not
/// here.** Eighteen of these thirty-two are Σ(inputs) == output value or over
/// Ornate, which the contract measured and left unpatched for Christian's
/// §8.7 ruling. Those are *value* facts about the catalogues; nothing in this
/// file encodes them.
///
/// XP is `Σ input counts × (4 + 2 × gate)` (`Skills.xpForRecipe`) — computed,
/// never stored. Every value in this file's doc comments is the hand-worked
/// check against that formula, not a second source of truth.
library;

import '../../crafting/gesture.dart';
import '../item_def.dart';
import '../recipe_def.dart';

abstract final class EtherealRecipes {
  // ---- Metalworking -------------------------------------------------------
  //
  // ⭐ Still a pure feeder lane, exactly as it debuted and exactly as Celestial
  // kept it: two recipes, downstream consumers in Woodcarving and — ⭐ new
  // this quarter — in Jewelry. The script is Bronze's and Iron's and
  // Skysteel's — stoke, pour, quench — two notches hotter again, and the
  // complexity dial is now pinned at its 5 ceiling.

  /// #1 — the Buried Sky's Deepstratum Ore plus ⏳ banked Ashfall Vale
  /// Charcoal. XP: (3+2) × (4+2×46) = 5 × 96 = **480**.
  static const deepsteelIngot = RecipeDef(
    id: 'craft_deepsteel_ingot',
    outputId: 'deepsteel_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 46,
    inputs: [RecipeInput('deepstratum_ore', 3), RecipeInput('charcoal', 2)],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 6),
    ],
  );

  /// #2 — the Collapsed Academy's Mana Slag, remelted, plus the same Charcoal.
  /// ⭐ The game's last ingot. XP: (3+2) × (4+2×50) = 5 × 104 = **520**.
  static const aethersteelIngot = RecipeDef(
    id: 'craft_aethersteel_ingot',
    outputId: 'aethersteel_ingot',
    skill: CraftSkill.metalworking,
    skillLevel: 50,
    inputs: [RecipeInput('mana_slag', 3), RecipeInput('charcoal', 2)],
    steps: [
      GestureStep(GestureEngine.bandKeeper, 'stoke', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
      GestureStep(GestureEngine.releaseTiming, 'quench', reps: 7),
    ],
  );

  // ---- Woodcarving: Spiritwood (Hallowmarch) ------------------------------
  //
  // ⭐ Same shape as Oak/Birch/Yew/Rowan/Ironwood/Bloodwood/Ebony (chop →
  // carve → sand), tier 8. ⚠️ **Two wood tiers this quarter, not three** —
  // which is why Woodcarving is 6 here against Celestial's 9, and why the
  // quarter still lands at 32 despite Jewelry's seven.

  /// #3 — XP: (3+1) × (4+2×46) = 4 × 96 = **384**.
  static const spiritwoodQuarterstaff = RecipeDef(
    id: 'craft_spiritwood_quarterstaff',
    outputId: 'spiritwood_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 46,
    inputs: [
      RecipeInput('spiritwood_log', 3),
      RecipeInput('deepsteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 7),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 7),
    ],
  );

  /// #4 — XP: (2+1) × 96 = 3 × 96 = **288**.
  static const spiritwoodWand = RecipeDef(
    id: 'craft_spiritwood_wand',
    outputId: 'spiritwood_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 46,
    inputs: [
      RecipeInput('spiritwood_log', 2),
      RecipeInput('deepsteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 6),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
    ],
  );

  /// #5 — XP: 2 × 96 = **192**.
  static const spiritwoodKnot = RecipeDef(
    id: 'craft_spiritwood_knot',
    outputId: 'spiritwood_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 46,
    inputs: [RecipeInput('spiritwood_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 7),
    ],
  );

  // ---- Woodcarving: Aetherwood (The Collapsed Academy) --------------------
  //
  // ⭐ Tier 9 — the game's last wood, and the last main hand anyone will ever
  // carve. Its ferrule is Aethersteel, the game's last ingot.

  /// #6 — XP: (3+1) × (4+2×50) = 4 × 104 = **416**.
  static const aetherwoodQuarterstaff = RecipeDef(
    id: 'craft_aetherwood_quarterstaff',
    outputId: 'aetherwood_quarterstaff',
    skill: CraftSkill.woodcarving,
    skillLevel: 50,
    inputs: [
      RecipeInput('aetherwood_log', 3),
      RecipeInput('aethersteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 8),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 8),
    ],
  );

  /// #7 — XP: (2+1) × 104 = 3 × 104 = **312**.
  static const aetherwoodWand = RecipeDef(
    id: 'craft_aetherwood_wand',
    outputId: 'aetherwood_wand',
    skill: CraftSkill.woodcarving,
    skillLevel: 50,
    inputs: [
      RecipeInput('aetherwood_log', 2),
      RecipeInput('aethersteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.releaseTiming, 'chop', reps: 7),
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
    ],
  );

  /// #8 — XP: 2 × 104 = **208**.
  static const aetherwoodKnot = RecipeDef(
    id: 'craft_aetherwood_knot',
    outputId: 'aetherwood_knot',
    skill: CraftSkill.woodcarving,
    skillLevel: 50,
    inputs: [RecipeInput('aetherwood_log', 2)],
    steps: [
      GestureStep(GestureEngine.trace, 'carve', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'sand', reps: 8),
    ],
  );

  // ---- Tailoring: the Umbralweave set (The Umbral Wastes) ----------------
  //
  // ⭐ Same shape as every set since Bindweed (thread → stitch): five slots,
  // one material, no ingot. ⚠️ §5.4 records this set as Σ(inputs) = output
  // value exactly — a value fact, carried by `value_conservation_test`'s
  // `_pendingRuling`; nothing here encodes it.

  /// #9 — XP: 3 × (4+2×44) = 3 × 92 = **276**.
  static const umbralweaveHood = RecipeDef(
    id: 'craft_umbralweave_hood',
    outputId: 'umbralweave_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [RecipeInput('umbralweave', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #10 — XP: 6 × 92 = **552**.
  static const umbralweaveRobe = RecipeDef(
    id: 'craft_umbralweave_robe',
    outputId: 'umbralweave_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [RecipeInput('umbralweave', 6)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 6),
    ],
  );

  /// #11 — XP: 5 × 92 = **460**.
  static const umbralweaveLeggings = RecipeDef(
    id: 'craft_umbralweave_leggings',
    outputId: 'umbralweave_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [RecipeInput('umbralweave', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #12 — XP: 3 × 92 = **276**.
  static const umbralweaveBoots = RecipeDef(
    id: 'craft_umbralweave_boots',
    outputId: 'umbralweave_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [RecipeInput('umbralweave', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #13 — XP: 3 × 92 = **276**.
  static const umbralweaveGloves = RecipeDef(
    id: 'craft_umbralweave_gloves',
    outputId: 'umbralweave_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 44,
    inputs: [RecipeInput('umbralweave', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  // ---- Tailoring: belts (hide + thread) ----------------------------------
  //
  // ⭐ Same shape as every belt since Fawnhide (cut → knot → stitch), and
  // ⭐ **three of them this quarter**, the ladder's last three rungs: 7, 8, 9
  // belt slots. Belts are capacity, never power (§6b.2, §7.5); each earns its
  // own gate only because the hide is kill-only (§9b.7b) — ⚠️ none of
  // `corebiter_hide`, `thornpenitent_hide` or `blankspine_vellum` has a gather
  // node, and §6 says so on purpose.

  /// #14 — the Buried Sky's kill-only Corebiter Hide plus an Umbralweave
  /// thread. XP: (2+1) × (4+2×46) = 3 × 96 = **288**.
  static const corebiterBelt = RecipeDef(
    id: 'craft_corebiter_belt',
    outputId: 'corebiter_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 46,
    inputs: [RecipeInput('corebiter_hide', 2), RecipeInput('umbralweave', 1)],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'knot', complexity: 3),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  // ---- Tailoring: the Unleft set (The Reliquary Deep) --------------------
  //
  // ⭐ The game's last cloth set, and the only one whose bolt is not gathered
  // from a plant — `unleft_linen` comes off the Reliquary's altars.

  /// #15 — XP: 3 × (4+2×48) = 3 × 100 = **300**.
  static const unleftHood = RecipeDef(
    id: 'craft_unleft_hood',
    outputId: 'unleft_hood',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [RecipeInput('unleft_linen', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #16 — ⭐ the ladder's best single XP award. XP: 6 × 100 = **600**.
  static const unleftRobe = RecipeDef(
    id: 'craft_unleft_robe',
    outputId: 'unleft_robe',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [RecipeInput('unleft_linen', 6)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 7),
    ],
  );

  /// #17 — XP: 5 × 100 = **500**.
  static const unleftLeggings = RecipeDef(
    id: 'craft_unleft_leggings',
    outputId: 'unleft_leggings',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [RecipeInput('unleft_linen', 5)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 6),
    ],
  );

  /// #18 — XP: 3 × 100 = **300**.
  static const unleftBoots = RecipeDef(
    id: 'craft_unleft_boots',
    outputId: 'unleft_boots',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [RecipeInput('unleft_linen', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #19 — XP: 3 × 100 = **300**.
  static const unleftGloves = RecipeDef(
    id: 'craft_unleft_gloves',
    outputId: 'unleft_gloves',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [RecipeInput('unleft_linen', 3)],
    steps: [
      GestureStep(GestureEngine.trace, 'thread', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  /// #20 — the Sealed Garden's kill-only Thornpenitent Hide, still threaded
  /// with Umbralweave. ⚠️ **Not with `unleft_linen`, though the gate matches**
  /// — §5.1's input table is canon and the Garden sits a zone before the
  /// Reliquary. XP: (2+1) × (4+2×48) = 3 × 100 = **300**.
  static const penitentBelt = RecipeDef(
    id: 'craft_penitent_belt',
    outputId: 'penitent_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 48,
    inputs: [
      RecipeInput('thornpenitent_hide', 2),
      RecipeInput('umbralweave', 1),
    ],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'knot', complexity: 4),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 4),
    ],
  );

  /// #21 — the Unwritten Library's kill-only Blankspine Vellum (⚠️ "a
  /// palimpsest is a hide" one more time, §3.1) plus an Unleft thread. ⭐ The
  /// last belt in the game and the top of the capacity ladder at nine slots.
  /// XP: (2+1) × (4+2×50) = 3 × 104 = **312**.
  static const blankspineBelt = RecipeDef(
    id: 'craft_blankspine_belt',
    outputId: 'blankspine_belt',
    skill: CraftSkill.tailoring,
    skillLevel: 50,
    inputs: [
      RecipeInput('blankspine_vellum', 2),
      RecipeInput('unleft_linen', 1),
    ],
    steps: [
      GestureStep(GestureEngine.trace, 'cut', complexity: 5),
      GestureStep(GestureEngine.alignCommit, 'knot', complexity: 5),
      GestureStep(GestureEngine.sweetSpot, 'stitch', reps: 5),
    ],
  );

  // ---- Potions & Alchemy --------------------------------------------------
  //
  // ⭐ Four rungs again, and §3.3's Draught/Tonic alternation runs to the end:
  // a Draught heals now, a Tonic pays over three turns, and the ladder never
  // gives two of the same form in a row.
  // ⚠️ The Ration lane stays **drop-only** and therefore has no recipe here —
  // the floor a player can reach without a Potions skill at all.

  /// #22 — XP: 3 × (4+2×46) = 3 × 96 = **288**.
  static const goldenroodDraught = RecipeDef(
    id: 'craft_goldenrood_draught',
    outputId: 'goldenrood_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 46,
    inputs: [RecipeInput('goldenrood', 3)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 5),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
    ],
  );

  /// #23 — XP: 3 × (4+2×48) = 3 × 100 = **300**.
  static const worldrootTonic = RecipeDef(
    id: 'craft_worldroot_tonic',
    outputId: 'worldroot_tonic',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 48,
    inputs: [RecipeInput('worldroot', 3)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 6),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
    ],
  );

  /// #24 — XP: 4 × 100 = **400**.
  static const censerDraught = RecipeDef(
    id: 'craft_censer_draught',
    outputId: 'censer_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 48,
    inputs: [RecipeInput('censer_resin', 4)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 6),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
    ],
  );

  /// #25 — ⭐ the strongest potion in the game, and still weaker than a
  /// same-tier cast (§3.3). XP: 4 × (4+2×50) = 4 × 104 = **416**.
  static const nightinkDraught = RecipeDef(
    id: 'craft_nightink_draught',
    outputId: 'nightink_draught',
    skill: CraftSkill.potionsAndAlchemy,
    skillLevel: 50,
    inputs: [RecipeInput('nightink', 4)],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'grind', reps: 7),
      GestureStep(GestureEngine.alignCommit, 'pour', complexity: 5),
    ],
  );

  // ---- Jewelry (DEBUT) ----------------------------------------------------
  //
  // ⭐⭐ **The seven recipes that close §6a.1.** Read them with §5.1's banking
  // table: `quarry_jasper` (Old Quarry, Q2, L15–19) and `everice` (Frostfell
  // Pass, Q2, L21–26) feed #26; `obsidian` (The Molten Deep, Q2) and `nacre`
  // (Tidewrack Shoals, Q3) feed #27; `eclipse_opal` (The Sunless Reach, Q3)
  // and `sidereal_glass` (The Shattered Orrery, Q3) feed #28; `aetherglass`
  // (The Glass Archive, Q3) feeds #29. ⚠️ **All seven, nothing left.**
  //
  // ⚠️ **A player who ignored every jewel material from level 15 onward
  // arrives at Rimeholt with an empty bag and a maker they cannot feed.** 📝
  // That is the intended lesson and it is a harsh one — ⚠️ all seven are still
  // gatherable, so it is a walk back, not a lockout.
  //
  // ⭐ **The gesture script is this skill's, invented here**: `facet`
  // (alignCommit — line the stone up and commit once, exactly the engine's own
  // "gem set, facet" example), `wire` (rateDrag — keep the draw steady) and
  // `set` (alignCommit again, the seating). It climbs with the gate rather
  // than with the tier, because the ladder IS the tier here.
  //
  // ⚠️ **No `stationRequired: true` anywhere in this file.** §9b.2 makes
  // stations convenience, not gates; Rimeholt teaches Jewelry, it does not own
  // every subsequent craft.

  /// #26 ⭐ — **the first Jewelry recipe in the game**, and the debut rung.
  ///
  /// ⭐ **Gate 1 is the whole design** (§5.2), the same role `craft_bronze_
  /// ingot` played for Metalworking: cheap, immediate, and made of something
  /// the player already has. A player learns Jewelry at Rimeholt with zero
  /// XP and is therefore level 1; a gate above 1 would be a tier gate nobody
  /// could pass on the day the skill opens.
  ///
  /// ⭐⭐ Two of its three materials were banked two quarters ago under KINETIC
  /// §8.1's promise *"gatherable now, spendable at Rimeholt"* — this recipe is
  /// that promise being paid. ⚠️ Its output's equip level is **45**, one below
  /// the Buried Sky's band floor, deliberately: a player should be able to
  /// wear the first thing they make before they walk anywhere.
  ///
  /// ⚠️ Gate 1 also makes it the quarter's cheapest XP despite closing a
  /// three-quarter promise — deliberate, since nothing levels off it.
  /// XP: (2+2+1) × (4+2×1) = 5 × 6 = **30**.
  static const evericeBand = RecipeDef(
    id: 'craft_everice_band',
    outputId: 'everice_band',
    skill: CraftSkill.jewelry,
    skillLevel: 1,
    inputs: [
      RecipeInput('everice', 2),
      RecipeInput('quarry_jasper', 2),
      RecipeInput('nadir_garnet', 1),
    ],
    steps: [
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 2),
      GestureStep(GestureEngine.alignCommit, 'set'),
    ],
  );

  /// #27 ⭐ — the Neck slot's first maker in sixty levels (§5.3), spending
  /// `obsidian` banked in Q2 and `nacre` banked in Q3 around a Deepsteel
  /// mount. XP: (3+2+1) × (4+2×10) = 6 × 24 = **144**.
  static const nacrePendant = RecipeDef(
    id: 'craft_nacre_pendant',
    outputId: 'nacre_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 10,
    inputs: [
      RecipeInput('nacre', 3),
      RecipeInput('obsidian', 2),
      RecipeInput('deepsteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 2),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 2),
    ],
  );

  /// #28 ⭐ — the last two Celestial banked gems spent at once, set in Umbral
  /// Thoughtglass. ⭐ The widest input list in the quarter at seven pieces.
  /// XP: (3+2+2) × (4+2×20) = 7 × 44 = **308**.
  static const eclipseSignet = RecipeDef(
    id: 'craft_eclipse_signet',
    outputId: 'eclipse_signet',
    skill: CraftSkill.jewelry,
    skillLevel: 20,
    inputs: [
      RecipeInput('eclipse_opal', 3),
      RecipeInput('sidereal_glass', 2),
      RecipeInput('thoughtglass', 2),
    ],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 3),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 3),
    ],
  );

  /// #29 ⭐ — the seventh and last banked gem, `aetherglass` from The Glass
  /// Archive, in Reliquary Gold. **After this recipe nothing is left
  /// unspent** (§0.2). XP: (3+2) × (4+2×30) = 5 × 64 = **320**.
  static const aetherglassLocket = RecipeDef(
    id: 'craft_aetherglass_locket',
    outputId: 'aetherglass_locket',
    skill: CraftSkill.jewelry,
    skillLevel: 30,
    inputs: [RecipeInput('aetherglass', 3), RecipeInput('reliquary_gold', 2)],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 3),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 4),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 4),
    ],
  );

  /// #30 — ⭐ the first rung made entirely of this quarter's own stones, and
  /// the second place Metalworking feeds Jewelry.
  /// XP: (3+1+1) × (4+2×35) = 5 × 74 = **370**.
  static const orchardLoop = RecipeDef(
    id: 'craft_orchard_loop',
    outputId: 'orchard_loop',
    skill: CraftSkill.jewelry,
    skillLevel: 35,
    inputs: [
      RecipeInput('orchard_amber', 3),
      RecipeInput('reliquary_gold', 1),
      RecipeInput('aethersteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 4),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 4),
    ],
  );

  /// #31 — ⭐ Corona Pearl is ⚠️ **kill-only and nodeless** (§3.1: the
  /// Eclipsed Citadel has no gather nodes at all), so the last Neck piece is
  /// earned in the Citadel and nowhere else.
  /// XP: (2+2+1) × (4+2×44) = 5 × 92 = **460**.
  static const coronaTorc = RecipeDef(
    id: 'craft_corona_torc',
    outputId: 'corona_torc',
    skill: CraftSkill.jewelry,
    skillLevel: 44,
    inputs: [
      RecipeInput('corona_pearl', 2),
      RecipeInput('colophon_stone', 2),
      RecipeInput('aethersteel_ingot', 1),
    ],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 5),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 5),
    ],
  );

  /// #32 — ⭐⭐ **the last recipe in the game.** Eclipse Iron is the other
  /// kill-only Citadel material; its output is one of the three level-60
  /// items, and the only crafted one.
  /// XP: (3+2) × (4+2×50) = 5 × 104 = **520**.
  static const eclipseRing = RecipeDef(
    id: 'craft_eclipse_ring',
    outputId: 'eclipse_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 50,
    inputs: [RecipeInput('eclipse_iron', 3), RecipeInput('colophon_stone', 2)],
    steps: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 5),
      GestureStep(GestureEngine.rateDrag, 'wire', reps: 5),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 5),
    ],
  );

  /// ⚠️ **Order is load-bearing.** Within each skill these ascend by gate, and
  /// `ethereal_recipes_test` asserts it — that is what makes
  /// `Skills.allRecipesFor` read as a ladder rather than a bag.
  static const all = <RecipeDef>[
    deepsteelIngot,
    aethersteelIngot,
    spiritwoodQuarterstaff,
    spiritwoodWand,
    spiritwoodKnot,
    aetherwoodQuarterstaff,
    aetherwoodWand,
    aetherwoodKnot,
    umbralweaveHood,
    umbralweaveRobe,
    umbralweaveLeggings,
    umbralweaveBoots,
    umbralweaveGloves,
    corebiterBelt,
    unleftHood,
    unleftRobe,
    unleftLeggings,
    unleftBoots,
    unleftGloves,
    penitentBelt,
    blankspineBelt,
    goldenroodDraught,
    worldrootTonic,
    censerDraught,
    nightinkDraught,
    evericeBand,
    nacrePendant,
    eclipseSignet,
    aetherglassLocket,
    orchardLoop,
    coronaTorc,
    eclipseRing,
  ];
}
