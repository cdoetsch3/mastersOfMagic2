/// Jewelry's two new lanes (ENCHANTING_DESIGN §5.1, §5.3, §8.2): **Cut** ×36
/// — a stone and a refined mote into a gem — and the **ladder below
/// Rimeholt** ×12, a ring and a pendant at each of six rungs.
///
/// ⚠️ **The ladder reverses a standing ruling, by design ruling.** KINETIC §8.1
/// and ITEMS §9b.8 ruling 9 kept Jewelry's station *and learning* at
/// Rimeholt (L45) and cut `amber_ring`, `jasper_pendant` and `obsidian_ring`
/// for it; ENCHANTING §5.3 (scope ruling 2, 2026-10-01: "all four verbs plus
/// gems") brings a ladder from level 1 back. Those three ids return here as
/// the pieces they were planned to be. 📝 Nothing in code gates learning a
/// skill, so the ladder is craftable the moment it ships.
library;

import 'package:mom_engine/mom_engine.dart';

import '../../crafting/gesture.dart';
import '../catalogue/gems.dart';
import '../enchants.dart';
import '../item_def.dart';
import '../recipe_def.dart';
import 'enchanting_recipes.dart';

abstract final class JewelryRecipes {
  // ---- Cut (§5.1) ----------------------------------------------------------

  /// ⭐ **One cut stone per element**, each from a zone that carries that
  /// element (the lead element wherever a stone exists in such a zone),
  /// all twelve distinct. The full reasoning is ENCHANTING §8.2's table.
  ///
  /// ⚠️ Aero has no stone in an Aero-LED zone (Windward Steppe yields none),
  /// so it takes Frostfell Pass's **everice** — Aqua + Aero, a pass is where
  /// the wind goes — and Aqua takes Tidewrack's **nacre** (Lunar + Aqua,
  /// shell off the sea floor), whose own lore already promises *"someone at
  /// Rimeholt will"* know what to do with it. Lunar takes the Sunless Reach's
  /// **eclipse opal** (*"light on one face, dark on the other"*), Solar the
  /// Glass Archive's **aetherglass** (Solar-led), Arcane the Unwritten
  /// Library's **colophon stone** (no Arcane-led zone yields a stone).
  /// 📝 `hum_quartz` is tagged Enchanting, not Jewelry, but it is Thunderspire's
  /// (Electro-led) only stone and quartz that holds a note is the Electro gem.
  static const Map<MagicElement, String> stoneFor = {
    MagicElement.aqua: 'nacre',
    MagicElement.pyro: 'obsidian',
    MagicElement.flora: 'amber',
    MagicElement.electro: 'hum_quartz',
    MagicElement.aero: 'everice',
    MagicElement.geo: 'quarry_jasper',
    MagicElement.solar: 'aetherglass',
    MagicElement.lunar: 'eclipse_opal',
    MagicElement.astral: 'sidereal_glass',
    MagicElement.sanctus: 'reliquary_gold',
    MagicElement.umbra: 'thoughtglass',
    MagicElement.arcane: 'colophon_stone',
  };

  /// The refined mote each gem tier is cut with, and the Jewelry level that
  /// opens it (§5.1): Lesser = Crystal at 10, Standard = Core at 25,
  /// Greater = Heart at 40.
  static const Map<EnchantTier, ({MoteTier mote, int level})> cutTiers = {
    EnchantTier.lesser: (mote: MoteTier.crystal, level: 10),
    EnchantTier.standard: (mote: MoteTier.core, level: 25),
    EnchantTier.greater: (mote: MoteTier.heart, level: 40),
  };

  /// `cut_<element>_<tier>`.
  static String cutId(MagicElement element, EnchantTier tier) =>
      'cut_${element.name}_${tier.name}';

  static const Map<EnchantTier, List<GestureStep>> _cutSteps = {
    EnchantTier.lesser: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 2),
      GestureStep(GestureEngine.rateDrag, 'polish', reps: 2),
      GestureStep(GestureEngine.bandKeeper, 'charge'),
    ],
    EnchantTier.standard: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 3),
      GestureStep(GestureEngine.rateDrag, 'polish', reps: 3),
      GestureStep(GestureEngine.bandKeeper, 'charge', complexity: 2),
    ],
    EnchantTier.greater: [
      GestureStep(GestureEngine.alignCommit, 'facet', complexity: 4),
      GestureStep(GestureEngine.rateDrag, 'polish', reps: 3),
      GestureStep(GestureEngine.bandKeeper, 'charge', complexity: 3),
      GestureStep(GestureEngine.alignCommit, 'set', complexity: 4),
    ],
  };

  /// 36 recipes: element-enum order, then Lesser → Standard → Greater —
  /// [Gems.all]'s order, so cut *n* makes gem *n*.
  ///
  /// ⭐ **`stationRequired: true`, citing §5.1** — gems are *"cut at
  /// Rimeholt"*, a tier gate on a socket. ⚠️ The flag is enforced by nothing
  /// today (§4.2); the real gate is lane 3's `World.byId(location).station`,
  /// and this flag is the data it can read.
  static final List<RecipeDef> cut = List.unmodifiable([
    for (final element in MagicElement.values)
      for (final tier in cutTiers.entries)
        RecipeDef(
          id: cutId(element, tier.key),
          outputId: Gems.idFor(element, tier.key),
          skill: CraftSkill.jewelry,
          skillLevel: tier.value.level,
          stationRequired: true,
          inputs: [
            RecipeInput(stoneFor[element]!, 1),
            RecipeInput(
              EnchantingRecipes.moteOf(element, tier.value.mote).id,
              1,
            ),
          ],
          steps: _cutSteps[tier.key]!,
        ),
  ]);

  // ---- The ladder below Rimeholt (§5.3) -------------------------------------
  //
  // ⭐ **Two rungs per quarter, a ring and a pendant at each**, Jewelry 1 / 5
  // (Primal) · 12 / 18 (Kinetic) · 24 / 30 (Celestial). Each is one metal and
  // one of the quarter's stones; ⭐ the ring carries the quarter's universal
  // line (flat HP), the pendant the stone's affinity (CELESTIAL §2.5a).
  // ⭐ The metals are §5.3's verbatim: **bronze → iron → skyiron** (skysteel,
  // the ingot skyiron makes), one per quarter. ⚠️ Not raw copper for Primal,
  // even though bronze needs Kinetic tin: copper is banked for exactly one
  // maker (ITEMS §9b.8, `cinderpeak_test`). Every recipe clean-passes ECONOMY
  // §8 (`Standard < Σ inputs < Ornate`); the sums are on each piece's def.

  static const _wireAndSet = [
    GestureStep(GestureEngine.rateDrag, 'wire', reps: 2),
    GestureStep(GestureEngine.alignCommit, 'set'),
  ];

  static const _facetWireSet = [
    GestureStep(GestureEngine.alignCommit, 'facet', complexity: 2),
    GestureStep(GestureEngine.rateDrag, 'wire', reps: 2),
    GestureStep(GestureEngine.alignCommit, 'set', complexity: 2),
  ];

  static const _facetWireSetFine = [
    GestureStep(GestureEngine.alignCommit, 'facet', complexity: 3),
    GestureStep(GestureEngine.rateDrag, 'wire', reps: 3),
    GestureStep(GestureEngine.alignCommit, 'set', complexity: 3),
  ];

  /// Jewelry 1 — the first thing the skill makes. XP: 2 × 6 = **12**.
  static const amberBand = RecipeDef(
    id: 'craft_amber_band',
    outputId: 'amber_band',
    skill: CraftSkill.jewelry,
    skillLevel: 1,
    inputs: [RecipeInput('bronze_ingot', 1), RecipeInput('amber', 1)],
    steps: _wireAndSet,
  );

  /// Jewelry 1. XP: 3 × 6 = **18**.
  static const amberDrop = RecipeDef(
    id: 'craft_amber_drop',
    outputId: 'amber_drop',
    skill: CraftSkill.jewelry,
    skillLevel: 1,
    inputs: [RecipeInput('bronze_ingot', 1), RecipeInput('amber', 2)],
    steps: _wireAndSet,
  );

  /// Jewelry 5 — ⭐ the cut `amber_ring` (KINETIC §8.1), returned. XP: 4 × 14
  /// = **56**.
  static const amberRing = RecipeDef(
    id: 'craft_amber_ring',
    outputId: 'amber_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 5,
    inputs: [RecipeInput('bronze_ingot', 1), RecipeInput('amber', 3)],
    steps: _wireAndSet,
  );

  /// Jewelry 5. XP: 5 × 14 = **70**.
  static const amberPendant = RecipeDef(
    id: 'craft_amber_pendant',
    outputId: 'amber_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 5,
    inputs: [RecipeInput('bronze_ingot', 1), RecipeInput('amber', 4)],
    steps: _wireAndSet,
  );

  /// Jewelry 12. XP: 3 × 28 = **84**.
  static const jasperRing = RecipeDef(
    id: 'craft_jasper_ring',
    outputId: 'jasper_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 12,
    inputs: [RecipeInput('iron_ingot', 1), RecipeInput('quarry_jasper', 2)],
    steps: _facetWireSet,
  );

  /// Jewelry 12 — ⭐ the cut `jasper_pendant` (KINETIC §8.1), returned. XP:
  /// 4 × 28 = **112**.
  static const jasperPendant = RecipeDef(
    id: 'craft_jasper_pendant',
    outputId: 'jasper_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 12,
    inputs: [RecipeInput('iron_ingot', 1), RecipeInput('quarry_jasper', 3)],
    steps: _facetWireSet,
  );

  /// Jewelry 18 — ⭐ the cut `obsidian_ring` (KINETIC §8.1), returned. XP:
  /// 3 × 40 = **120**.
  static const obsidianRing = RecipeDef(
    id: 'craft_obsidian_ring',
    outputId: 'obsidian_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 18,
    inputs: [RecipeInput('iron_ingot', 1), RecipeInput('obsidian', 2)],
    steps: _facetWireSet,
  );

  /// Jewelry 18. XP: 4 × 40 = **160**.
  static const obsidianPendant = RecipeDef(
    id: 'craft_obsidian_pendant',
    outputId: 'obsidian_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 18,
    inputs: [RecipeInput('iron_ingot', 1), RecipeInput('obsidian', 3)],
    steps: _facetWireSet,
  );

  /// Jewelry 24. XP: 3 × 52 = **156**.
  static const opalRing = RecipeDef(
    id: 'craft_opal_ring',
    outputId: 'opal_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 24,
    inputs: [RecipeInput('skysteel_ingot', 1), RecipeInput('eclipse_opal', 2)],
    steps: _facetWireSetFine,
  );

  /// Jewelry 24. XP: 4 × 52 = **208**.
  static const opalPendant = RecipeDef(
    id: 'craft_opal_pendant',
    outputId: 'opal_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 24,
    inputs: [RecipeInput('skysteel_ingot', 1), RecipeInput('eclipse_opal', 3)],
    steps: _facetWireSetFine,
  );

  /// Jewelry 30. XP: 3 × 64 = **192**.
  static const siderealRing = RecipeDef(
    id: 'craft_sidereal_ring',
    outputId: 'sidereal_ring',
    skill: CraftSkill.jewelry,
    skillLevel: 30,
    inputs: [
      RecipeInput('skysteel_ingot', 1),
      RecipeInput('sidereal_glass', 2),
    ],
    steps: _facetWireSetFine,
  );

  /// Jewelry 30. XP: 4 × 64 = **256**.
  static const siderealPendant = RecipeDef(
    id: 'craft_sidereal_pendant',
    outputId: 'sidereal_pendant',
    skill: CraftSkill.jewelry,
    skillLevel: 30,
    inputs: [
      RecipeInput('skysteel_ingot', 1),
      RecipeInput('sidereal_glass', 3),
    ],
    steps: _facetWireSetFine,
  );

  /// The twelve, rung order (ring before pendant within a rung).
  static const List<RecipeDef> ladder = [
    amberBand,
    amberDrop,
    amberRing,
    amberPendant,
    jasperRing,
    jasperPendant,
    obsidianRing,
    obsidianPendant,
    opalRing,
    opalPendant,
    siderealRing,
    siderealPendant,
  ];

  /// Cut then the ladder — what `RecipeBook.all` registers (48).
  static final List<RecipeDef> all = List.unmodifiable([...cut, ...ladder]);
}
