/// What Salvage returns (ENCHANTING_DESIGN §6): one piece of equipment →
/// motes of **its zone's lead element**, by rarity, plus every gem that was
/// socketed in it, whole.
///
/// ⭐ **Pure, and the only answer.** A salvage recipe (`salvage_<rarity>`,
/// `EnchantingRecipes.salvage`) is a marker that gates and pays XP; its
/// `outputId` cannot name the yield because the yield depends on the INPUT.
/// `GameState.craft` (wired at merge) removes the chosen instance and adds
/// [yieldOfInstance] — nothing else decides what comes out.
///
/// ⚠️ **Not ITEMS §9b.4's component salvage.** `EquipmentDef.salvage`
/// (`SalvageYield`, e.g. Tuskhide Belt → tuskhide) is an older, separately
/// authored "break it back into components to reroll quality" verb that
/// nothing executes yet. §6 is the mote exit; whether one act ever pays both
/// is a ruling, not something this table decides by summing them.
library;

import 'package:mom_engine/mom_engine.dart';

import '../../world.dart';
import '../item_catalogue.dart';
import '../item_def.dart';
import '../item_instance.dart';
import 'enchanting_recipes.dart';

abstract final class SalvageTable {
  /// §6's table: (tier, count) lines per rarity, in the order they are
  /// returned. ⚠️ Mythic and legendary share a row — §6 writes them as one
  /// (❓ in the design, taken as written) and nothing in the game is either
  /// today.
  static const Map<Rarity, List<(MoteTier, int)>> byRarity = {
    Rarity.common: [(MoteTier.dust, 3)],
    Rarity.uncommon: [(MoteTier.dust, 8)],
    Rarity.rare: [(MoteTier.shard, 1), (MoteTier.dust, 10)],
    Rarity.epic: [(MoteTier.crystal, 1)],
    Rarity.mythic: [(MoteTier.crystal, 1), (MoteTier.shard, 1)],
    Rarity.legendary: [(MoteTier.crystal, 1), (MoteTier.shard, 1)],
  };

  /// The element [def] salvages into: the FIRST element of the zone whose
  /// catalogue defines it (`ItemCatalogue.zoneOf`), or null when there is
  /// none.
  ///
  /// ⚠️ **Null means "yields no motes"**: a made-not-found def (anything under
  /// `ItemCatalogue.byWorkshop`) has no zone, and a zone with no elements has
  /// no lead. 📝 The Eclipsed Citadel lists all twelve in enum order, so its
  /// pieces salvage to **Aqua** — mechanical, and flagged for a ruling rather
  /// than special-cased here.
  static MagicElement? elementOf(EquipmentDef def) {
    final zone = ItemCatalogue.zoneOf(def.id);
    if (zone == null) return null;
    // ⚠️ Not `World.byId`, which falls back to the first location for an
    // unknown id and would hand a stray piece Hearthwood's (empty) elements
    // by accident rather than by rule.
    for (final place in World.locations) {
      if (place.id == zone) {
        return place.elements.isEmpty ? null : place.elements.first;
      }
    }
    return null;
  }

  /// The motes salvaging [def] returns — empty when [elementOf] is null.
  /// ⭐ One slot per (tier, count) line; a Crystal line is always count 1,
  /// which `MoteDef.stackSize` (1 above Shard) requires.
  static List<InventorySlot> salvageYield(EquipmentDef def) {
    final element = elementOf(def);
    if (element == null) return const [];
    return [
      for (final (tier, count) in byRarity[def.rarity]!)
        InventorySlot(
          defId: EnchantingRecipes.moteOf(element, tier).id,
          count: count,
        ),
    ];
  }

  /// [salvageYield], plus one slot per gem in [socketed] (§6: *"gems come
  /// out whole — otherwise salvaging a socketed piece is a trap"*). ⚠️ Empty
  /// sockets ([ItemInstance.emptySocket]) are skipped, never returned as an
  /// id.
  static List<InventorySlot> yieldOf(
    EquipmentDef def, {
    List<String> socketed = const [],
  }) => [
    ...salvageYield(def),
    for (final gem in socketed)
      if (gem != ItemInstance.emptySocket) InventorySlot(defId: gem),
  ];

  /// [yieldOf] for a held instance — the call the crafter makes.
  static List<InventorySlot> yieldOfInstance(ItemInstance instance) {
    final def = ItemCatalogue.byId(instance.defId);
    if (def is! EquipmentDef) return const [];
    return yieldOf(def, socketed: instance.socketed);
  }

  /// The vendor value of [salvageYield] (not the gems — they were the
  /// player's before and are theirs after). ⚠️ §6's guard reads this: it must
  /// stay under the piece's own value, or the vendor stops being the
  /// better exit.
  static int moteValueOf(EquipmentDef def) => salvageYield(def).fold(
    0,
    (sum, slot) => sum + ItemCatalogue.byId(slot.defId).value * slot.count,
  );
}
