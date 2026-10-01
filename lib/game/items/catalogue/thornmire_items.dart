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
  /// `value: 28` — ECONOMY_CONTRACT §8.2.
  static const bogflaxFibre = MaterialDef(
    id: 'bogflax_fibre',
    properName: 'Bogflax Fibre',
    rarity: Rarity.common,
    lore:
        'Retted in the mire by the mire. Cloth of it never fully dries, and '
        'never quite burns either.',
    skill: CraftSkill.tailoring,
    tier: 2,
    value: 28,
  );

  /// ⏳ Banks for Q2's Antidote (§9b.8). Grows in the fen it is named for.
  /// `value: 8` — ECONOMY_CONTRACT §8.2 (no recipe consumer yet; priced by
  /// tier/rarity parity with its zone-mates, not by conservation).
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
    value: 8,
  );

  /// ⏳ Banks for Jewelry (§9b.8) — the classic fossil gem, found in bog oak.
  /// `value: 14` — ECONOMY_CONTRACT §8.2 (no recipe consumer yet).
  static const amber = MaterialDef(
    id: 'amber',
    properName: 'Amber',
    rarity: Rarity.uncommon,
    lore:
        'Light that went into a tree and never came back out. Sometimes '
        'there is a wing in it.',
    skill: CraftSkill.jewelry,
    tier: 2,
    value: 14,
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

  /// ⭐ `value: 120` — ECONOMY_CONTRACT §8.6/§14b.1's correction (was 85): the
  /// shipped value made this a 🔴 major conservation violation (Σ(inputs)=140
  /// against Ornate=102); the corrected value fits Standard 120 < Σ < Ornate
  /// 144. ⭐ This and its Leggings/Seawrack siblings are the recurring
  /// pattern §8.6 names: the highest-material-count Tailoring pieces (robe,
  /// leggings) are the ones a flat per-unit material price overshoots.
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
    value: 120,
  );

  /// ⭐ `value: 95` — ECONOMY_CONTRACT §8.6/§14b.1's correction (was 70): same
  /// 🔴 major-violation family as the robe (Σ(inputs)=112 against Ornate=84
  /// at the old value); corrected value fits Standard 95 < Σ < Ornate 114.
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
    value: 95,
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

  // ---- the Jewelry ladder, the Primal rungs (ENCHANTING §5.3) ----------
  //
  // ⭐ Jewelry 1 and 5: bronze wire around this mire's amber — §5.3's
  // "bronze → iron → skyiron", Primal's rung. All four live here because the
  // stone is the Primal part; the metal is not. ⚠️ **Bronze, not raw
  // copper**: Cinderpeak copper is banked for exactly ONE maker, the Bronze
  // Ingot (ITEMS §9b.8, pinned in `cinderpeak_test`), and a second consumer
  // nobody asked for would spend that promise. So the first rungs open once
  // a player has smelted bronze — the ladder's point is Jewelry XP before
  // Rimeholt (a Lesser cut wants Jewelry 10), not Primal-band gear.
  // ⭐ The ring carries the quarter's universal line (flat HP), the pendant
  // the stone's affinity: amber is Flora's, healing received (§2.5a).

  /// Jewelry 1. About half a Bogflax robe. Σ bronze ×1 (32) + amber ×1 (14)
  /// = **46**; `value: 42` (42 < 46 < 50.4, ECONOMY §8).
  static const amberBand = EquipmentDef(
    id: 'amber_band',
    rarity: Rarity.common,
    lore:
        'Bronze wire wound three times round a chip of amber. Somebody\'s '
        'first try, and it holds.',
    slot: EquipSlot.ring,
    form: 'Band',
    material: 'Amber',
    modifiers: ItemModifiers(maxHpBonus: 4),
    salvage: [SalvageYield('amber', 1, 1)],
    equipLevel: 8,
    value: 42,
  );

  /// Jewelry 1. Σ bronze ×1 (32) + amber ×2 (28) = **60**; `value: 54`
  /// (54 < 60 < 64.8).
  static const amberDrop = EquipmentDef(
    id: 'amber_drop',
    rarity: Rarity.common,
    lore:
        'One bead of amber on a bronze loop. Warm against the skin long after '
        'the fire is out.',
    slot: EquipSlot.neck,
    form: 'Drop',
    material: 'Amber',
    modifiers: ItemModifiers(healingReceivedPercent: 3),
    salvage: [SalvageYield('amber', 1, 1)],
    equipLevel: 8,
    value: 54,
  );

  /// ⭐ Jewelry 5 — the `amber_ring` KINETIC §8.1 cut when Jewelry was held at
  /// Rimeholt, returned as the Primal ladder's top rung. Σ bronze ×1 (32) +
  /// amber ×3 (42) = **74**; `value: 66` (66 < 74 < 79.2).
  static const amberRing = EquipmentDef(
    id: 'amber_ring',
    rarity: Rarity.common,
    lore:
        'A band of amber set in a bronze rim, cloudy on one side where the '
        'mire got into it first.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Amber',
    modifiers: ItemModifiers(maxHpBonus: 6),
    salvage: [SalvageYield('amber', 1, 2)],
    equipLevel: 12,
    value: 66,
  );

  /// Jewelry 5. Half the Wickerbound Ring's 10, a rung sooner. Σ bronze ×1
  /// (32) + amber ×4 (56) = **88**; `value: 80` (80 < 88 < 96).
  static const amberPendant = EquipmentDef(
    id: 'amber_pendant',
    rarity: Rarity.common,
    lore:
        'Three drops of amber on a bronze chain, the middle one with a wing '
        'in it. The wing is the part people ask about.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Amber',
    modifiers: ItemModifiers(healingReceivedPercent: 5),
    salvage: [SalvageYield('amber', 1, 2)],
    equipLevel: 12,
    value: 80,
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
    amberBand,
    amberDrop,
    amberRing,
    amberPendant,
  ];
}
