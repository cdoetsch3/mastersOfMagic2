/// Enchanting's mote verbs as recipes (ENCHANTING_DESIGN §3, §6, §8.2):
/// **Refine** ×48, **Transmute** ×36, and the six **Salvage** markers.
///
/// ⭐ **Generated, not written out.** Twelve elements × four rungs is a table,
/// and a table typed out 84 times is 84 places for one ratio to drift. The
/// loops below read the ratios from [refineRatios] and the elements from
/// [MagicElement.values], so the §6.0 ladder is stated exactly once.
///
/// ⭐ **Field-craftable** (`stationRequired: false`, §2): refining is the
/// ingot of the mote economy, done wherever the motes are. ⚠️ Enchant itself
/// is the station-bound verb (§4.2), and it is an item-dialog action, not a
/// recipe — it lives in lane 3, not here.
///
/// ⚠️ **Refine and Transmute destroy value on purpose** (§3.1: 50 Dust = 100g
/// in, 25g out). `value_conservation_test` holds them in a dated sink bucket
/// that asserts the loss rather than exempting them from the law.
///
/// ⚠️ **Ids are forever once a save or a wiki link holds one**:
/// `refine_<element>_<tier made>`, `transmute_<target element>_<tier>`,
/// `salvage_<rarity>`.
library;

import 'package:mom_engine/mom_engine.dart';

import '../../crafting/gesture.dart';
import '../../skills.dart';
import '../item_catalogue.dart';
import '../item_def.dart';
import '../recipe_def.dart';

abstract final class EnchantingRecipes {
  // ---- Refine (§3.1) -------------------------------------------------------

  /// The §6.0 ladder: inputs of the tier below per one of [MoteTier] out,
  /// and the Enchanting level that opens the rung. ⭐ ITEMS §6.0's 50 / 20 /
  /// 12 / 4 and ENCHANTING §3.1's 1 / 10 / 25 / 40 — the only place either
  /// number is written in code.
  static const Map<MoteTier, ({int ratio, int level})> refineRatios = {
    MoteTier.shard: (ratio: 50, level: 1),
    MoteTier.crystal: (ratio: 20, level: 10),
    MoteTier.core: (ratio: 12, level: 25),
    MoteTier.heart: (ratio: 4, level: 40),
  };

  /// `refine_<element>_<tier>` — named for what it MAKES.
  static String refineId(MagicElement element, MoteTier made) =>
      'refine_${element.name}_${made.name}';

  /// The crafting act for each rung. ⚠️ Gate 1 holds the §9b.9c ruling (2–3
  /// forgiving steps); nothing exceeds 4 (`gesture_and_nodes_test`).
  static const Map<MoteTier, List<GestureStep>> _refineSteps = {
    MoteTier.shard: [
      GestureStep(GestureEngine.placement, 'seed'),
      GestureStep(GestureEngine.bandKeeper, 'channel'),
    ],
    MoteTier.crystal: [
      GestureStep(GestureEngine.placement, 'seed', complexity: 2),
      GestureStep(GestureEngine.bandKeeper, 'channel', reps: 2),
      GestureStep(GestureEngine.alignCommit, 'fuse', complexity: 2),
    ],
    MoteTier.core: [
      GestureStep(GestureEngine.placement, 'seed', complexity: 3),
      GestureStep(GestureEngine.bandKeeper, 'channel', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'fuse', complexity: 3),
    ],
    MoteTier.heart: [
      GestureStep(GestureEngine.placement, 'seed', complexity: 4),
      GestureStep(GestureEngine.bandKeeper, 'channel', reps: 3),
      GestureStep(GestureEngine.alignCommit, 'fuse', complexity: 4),
      GestureStep(GestureEngine.releaseTiming, 'seal', reps: 2),
    ],
  };

  /// 48 recipes: element-enum order, then Shard → Crystal → Core → Heart.
  ///
  /// 📝 The Heart rung outputs a 0g Bound item (ECONOMY §14c) — four 900g
  /// Cores in, nothing a vendor will pay for out. That is the ruling working:
  /// a Heart is the 48-Crystal climb, and it is never money.
  static final List<RecipeDef> refine = List.unmodifiable([
    for (final element in MagicElement.values)
      for (final rung in refineRatios.entries)
        RecipeDef(
          id: refineId(element, rung.key),
          outputId: moteOf(element, rung.key).id,
          skill: CraftSkill.enchanting,
          skillLevel: rung.value.level,
          inputs: [
            RecipeInput(
              moteOf(element, MoteTier.values[rung.key.index - 1]).id,
              rung.value.ratio,
            ),
          ],
          steps: _refineSteps[rung.key]!,
        ),
  ]);

  // ---- Transmute (§3.2) ----------------------------------------------------

  /// The tiers transmute works at: Dust, Shard, Crystal (§3.2's
  /// `transmute_dust` / `_shard` / `_crystal`). ⚠️ Not Core — the design names
  /// three — and never Heart, which is Bound and must not change element by
  /// any door but the 48-Crystal climb.
  static const List<MoteTier> transmuteTiers = [
    MoteTier.dust,
    MoteTier.shard,
    MoteTier.crystal,
  ];

  /// `transmute_<target element>_<tier>` — named for what it MAKES.
  static String transmuteId(MagicElement target, MoteTier tier) =>
      'transmute_${target.name}_${tier.name}';

  /// The element whose mote stands as a transmute recipe's exemplar input:
  /// the one after [target] in enum order, wrapping.
  ///
  /// 📝 **The matcher reads only the exemplar's TIER** (see [RecipeInput]).
  /// ⚠️ It is chosen ≠ [target] so that a reader which has not learned
  /// [RecipeInput.anyElement] — the wiki export, today's unwired crafter —
  /// still sees a legal fixed-source transmute (4 Pyro Dust → 1 Flora Dust)
  /// rather than a 4 : 1 self-loss.
  static MagicElement exemplarFor(MagicElement target) =>
      MagicElement.values[(target.index + 1) % MagicElement.values.length];

  static const Map<MoteTier, List<GestureStep>> _transmuteSteps = {
    MoteTier.dust: [
      GestureStep(GestureEngine.bandKeeper, 'dissolve'),
      GestureStep(GestureEngine.placement, 'reseed'),
    ],
    MoteTier.shard: [
      GestureStep(GestureEngine.bandKeeper, 'dissolve', complexity: 2),
      GestureStep(GestureEngine.placement, 'reseed', complexity: 2),
    ],
    MoteTier.crystal: [
      GestureStep(GestureEngine.bandKeeper, 'dissolve', complexity: 3),
      GestureStep(GestureEngine.placement, 'reseed', complexity: 3),
      GestureStep(GestureEngine.alignCommit, 'fuse', complexity: 2),
    ],
  };

  /// 36 recipes, one per (target element, tier): element-enum order, then
  /// Dust → Shard → Crystal.
  ///
  /// ⭐ **Gate 1 for every tier** — the curve is the progression (4 : 1 at 1,
  /// 2 : 1 at 45), not the gate. The input line carries the level-1 count (4)
  /// and [RecipeInput.anyElement]; `GameState.craft` must consume
  /// [RecipeInput.countAt] the crafter's level via [RecipeDef.drawFrom].
  static final List<RecipeDef> transmute = List.unmodifiable([
    for (final target in MagicElement.values)
      for (final tier in transmuteTiers)
        RecipeDef(
          id: transmuteId(target, tier),
          outputId: moteOf(target, tier).id,
          skill: CraftSkill.enchanting,
          skillLevel: 1,
          inputs: [
            RecipeInput(
              moteOf(exemplarFor(target), tier).id,
              Skills.transmuteInputsAt(1),
              anyElement: true,
            ),
          ],
          steps: _transmuteSteps[tier]!,
        ),
  ]);

  // ---- Salvage markers (§6) ------------------------------------------------

  /// `salvage_<rarity>`.
  static String salvageId(Rarity rarity) => 'salvage_${rarity.name}';

  /// ⚠️ **The output a salvage marker names — resolves to nothing, on
  /// purpose.** The yield depends on the INPUT piece (its zone's lead
  /// element, its rarity, its sockets), which a fixed [RecipeDef.outputId]
  /// cannot say; `SalvageTable.yieldOf` is the answer. An unwired reader that
  /// resolves this fails loudly instead of minting a wrong mote.
  static const String salvageOutputId = '*salvage_yield';

  /// One marker per [Rarity], in enum order: Enchanting 1, one equipment
  /// input, so it pays `Skills.xpForRecipe` = 1 × (4 + 2 × 1) = **6 XP**
  /// (§6: "Enchanting XP as a 1-input recipe").
  ///
  /// ⚠️ **Deliberately NOT in `RecipeBook.all`.** Their input is an instance
  /// and their output is input-dependent, so every reader of the book that
  /// resolves ids literally — the conservation audit, the economy probe, the
  /// wiki export, the Workbench list — would misread them. They join the book
  /// when `GameState.craft` learns [RecipeDef.accepts] and the salvage picker
  /// exists (lane 3 / merge).
  static final List<RecipeDef> salvage = List.unmodifiable([
    for (final rarity in Rarity.values)
      RecipeDef(
        id: salvageId(rarity),
        outputId: salvageOutputId,
        skill: CraftSkill.enchanting,
        skillLevel: 1,
        inputs: [RecipeInput.anyEquipmentOfRarity(rarity)],
        steps: const [
          GestureStep(GestureEngine.rateDrag, 'unpick'),
          GestureStep(GestureEngine.bandKeeper, 'distil'),
        ],
      ),
  ]);

  /// Refine then Transmute — what `RecipeBook.all` registers (84).
  static final List<RecipeDef> all = List.unmodifiable([
    ...refine,
    ...transmute,
  ]);

  /// The [MoteDef] for [element] at [tier], through the catalogue. ⚠️ Looked
  /// up rather than spelled `'${element}_$tier'`, so a mote whose id ever
  /// broke the pattern would fail here, by name, at load.
  static MoteDef moteOf(MagicElement element, MoteTier tier) =>
      ItemCatalogue.ofKind<MoteDef>().firstWhere(
        (m) => m.element == element && m.tier == tier,
      );
}
