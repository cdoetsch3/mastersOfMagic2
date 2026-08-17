/// Everything Thornmire can yield (Lv 8–13, Flora + Aqua).
///
/// ⭐ Hybrid zone, so THREE materials (§9b.8) — the extra two are both ⏳
/// banking materials: Fenroot for Q2's Antidote, Amber for Jewelry a long
/// way up. The hybrid bonus is the future arriving early.
library;

import '../item_def.dart';

abstract final class ThornmireItems {
  // ---- materials ------------------------------------------------------

  /// The tier-2 fibre — the Bogflax set and the Tuskhide Belt's thread.
  static const bogflaxFibre = MaterialDef(
    id: 'bogflax_fibre',
    properName: 'Bogflax Fibre',
    rarity: Rarity.common,
    lore:
        'Retted in the mire by the mire. Cloth of it never fully dries, and '
        'never quite burns either.',
    skill: CraftSkill.tailoring,
    tier: 2,
  );

  /// ⏳ Banks for Q2's Antidote (§9b.8). Grows in the fen it is named for.
  static const fenroot = MaterialDef(
    id: 'fenroot',
    properName: 'Fenroot',
    rarity: Rarity.common,
    lore:
        'Bitter enough to make your eyes water at arm\'s length. The '
        'herbalists of Galehaven buy every scrap and boil it with the '
        'windows open.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 2,
  );

  /// ⏳ Banks for Jewelry (§9b.8) — the classic fossil gem, found in bog oak.
  static const amber = MaterialDef(
    id: 'amber',
    properName: 'Amber',
    rarity: Rarity.uncommon,
    lore:
        'Light that went into a tree and never came back out. Sometimes '
        'there is a wing in it.',
    skill: CraftSkill.jewelry,
    tier: 2,
  );

  // ---- equipment: the Bogflax set (Tailoring, §9b.8) -------------------

  static const bogflaxHood = EquipmentDef(
    id: 'bogflax_hood',
    rarity: Rarity.common,
    lore: 'Keeps the rain out. The mire finds another way in.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Bogflax',
    modifiers: ItemModifiers(accuracyBonus: 2),
    salvage: [SalvageYield('bogflax_fibre', 1, 1)],
    equipLevel: 10,
    value: 55,
  );

  static const bogflaxRobe = EquipmentDef(
    id: 'bogflax_robe',
    rarity: Rarity.common,
    lore: 'Heavy when wet, and it is always wet. You stop noticing.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Bogflax',
    modifiers: ItemModifiers(maxHpBonus: 10),
    salvage: [SalvageYield('bogflax_fibre', 2, 4)],
    equipLevel: 10,
    value: 85,
  );

  static const bogflaxLeggings = EquipmentDef(
    id: 'bogflax_leggings',
    rarity: Rarity.common,
    lore: 'Mud to the knee is the local dye lot.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Bogflax',
    modifiers: ItemModifiers(maxHpBonus: 7),
    salvage: [SalvageYield('bogflax_fibre', 1, 3)],
    equipLevel: 10,
    value: 70,
  );

  static const bogflaxBoots = EquipmentDef(
    id: 'bogflax_boots',
    rarity: Rarity.common,
    lore: 'The mire keeps boots. These are the kind it gives back.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Bogflax',
    modifiers: ItemModifiers(maxHpBonus: 2),
    salvage: [SalvageYield('bogflax_fibre', 1, 1)],
    equipLevel: 10,
    value: 45,
  );

  static const bogflaxGloves = EquipmentDef(
    id: 'bogflax_gloves',
    rarity: Rarity.common,
    lore: 'Waxed against the wet. Grip first, apologise later.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Bogflax',
    modifiers: ItemModifiers(maxHpBonus: 2),
    salvage: [SalvageYield('bogflax_fibre', 1, 1)],
    equipLevel: 10,
    value: 45,
  );

  /// ⭐ Drop-only jewelry (§9b.8). Multiplies every Draught and Tonic — the
  /// Flora answer to a fight you cannot end quickly. ✅ Dropper: the mini
  /// table, authored for the **Fenmother**; the pool shares one table, per the
  /// Whispering Woods shape.
  static const wickerboundRing = EquipmentDef(
    id: 'wickerbound_ring',
    properName: 'Wickerbound Ring',
    rarity: Rarity.rare,
    lore:
        'Willow withies in a knot that took someone a whole winter. Cut it '
        'and it grows closed by morning.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Wicker',
    modifiers: ItemModifiers(healingReceivedPercent: 10),
    tradability: Tradability.untradeable,
    equipLevel: 12,
    value: 240,
  );

  static const all = <ItemDef>[
    bogflaxFibre,
    fenroot,
    amber,
    bogflaxHood,
    bogflaxRobe,
    bogflaxLeggings,
    bogflaxBoots,
    bogflaxGloves,
    wickerboundRing,
  ];
}
