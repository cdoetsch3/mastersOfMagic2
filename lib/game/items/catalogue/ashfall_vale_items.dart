/// Everything Ashfall Vale can yield (Lv 10–14, Pyro + Flora).
///
/// ⭐ Hybrid zone: three materials, and the quarter's tier-2 wood. Birch is
/// a fire-successional pioneer — literally what regrows after a burn — which
/// is the whole zone in one tree (ITEMS §9b.6).
library;

import '../item_def.dart';

abstract final class AshfallValeItems {
  // ---- materials ------------------------------------------------------

  /// ✅ The wood ladder's tier 2 (ITEMS §9b.6).
  static const birchLog = MaterialDef(
    id: 'birch_log',
    properName: 'Birch Log',
    rarity: Rarity.common,
    lore:
        'First back after the burn, straight as a rule and pale as paper. '
        'The vale is a plantation nobody planted.',
    skill: CraftSkill.woodcarving,
    tier: 2,
  );

  /// The Tonic herb (§9b.8: form = mechanic, ingredient = magnitude).
  static const brookmint = MaterialDef(
    id: 'brookmint',
    properName: 'Brookmint',
    rarity: Rarity.common,
    lore:
        'Cold on the tongue even in this valley. It grows where the streams '
        'cut through the ash, greener than anything around it.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 2,
  );

  /// ⏳ Banks for Q2 (§9b.8): Forgeholm's furnaces eat charcoal, and the
  /// burned vale is where charcoal comes from. No Q1 recipe uses it.
  static const charcoal = MaterialDef(
    id: 'charcoal',
    properName: 'Charcoal',
    rarity: Rarity.common,
    lore:
        'The vale makes its own. Gathering it is not burning anything that '
        'was not already burned.',
    skill: CraftSkill.metalworking,
    tier: 2,
  );

  // ---- consumables ----------------------------------------------------

  /// ⭐ The Tonic form: heal over time, always (§9b.8). In a duel it pays
  /// out over three turns; between encounters it simply heals the total.
  static const brookmintTonic = BeltableDef(
    id: 'brookmint_tonic',
    properName: 'Brookmint Tonic',
    rarity: Rarity.common,
    lore:
        'Drink it and count. The cold goes down, turns around, and comes '
        'back up as warmth over the next little while.',
    effect: ItemEffect(healPerTurnPercent: 9, healTurns: 3),
    value: 25,
  );

  // ---- equipment: Birch weapons (Woodcarving, §9b.8) -------------------

  static const birchQuarterstaff = EquipmentDef(
    id: 'birch_quarterstaff',
    rarity: Rarity.common,
    lore: 'Springy where oak is stubborn. It gives, then gives back.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Birch',
    modifiers: ItemModifiers(damagePerCharge: 2, accuracyBonus: 6),
    salvage: [SalvageYield('birch_log', 1, 2)],
    equipLevel: 10,
    value: 90,
  );

  static const birchWand = EquipmentDef(
    id: 'birch_wand',
    rarity: Rarity.common,
    lore: 'Peels itself a little more each week, like it is in a hurry.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Birch',
    modifiers: ItemModifiers(damagePerCast: 3, accuracyBonus: 1),
    salvage: [SalvageYield('birch_log', 1, 1)],
    equipLevel: 10,
    value: 75,
  );

  static const birchKnot = EquipmentDef(
    id: 'birch_knot',
    rarity: Rarity.common,
    lore: 'A pale whorl with a dark centre. It warms in the hand it likes.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Birch',
    modifiers: ItemModifiers(accuracyBonus: 4),
    salvage: [SalvageYield('birch_log', 1, 1)],
    equipLevel: 10,
    value: 60,
  );

  /// ⭐⭐ **The Charlock — the quarter's only Epic.** Named for the fire-
  /// following wildflower; regrowth as a stat, off the boss that IS regrowth.
  /// ⚠️ The regrow tick must route through `TurnStatus` when wired (§4.2).
  /// ✅ Dropper: the boss table, authored for **The Rooting** — regrowth as a
  /// stat, off the boss that IS regrowth. The pool shares one table, per the
  /// Whispering Woods shape, so The Blackened Crown pays it too.
  static const theCharlock = EquipmentDef(
    id: 'the_charlock',
    properName: 'The Charlock',
    rarity: Rarity.epic,
    lore:
        'A seed case of black glass on a charred stem. Every morning it has '
        'flowered again, and every evening the flower is ash.',
    slot: EquipSlot.neck,
    form: 'Locket',
    material: 'Charlock',
    modifiers: ItemModifiers(regrowPercent: 2),
    tradability: Tradability.untradeable,
    equipLevel: 14,
    value: 700,
  );

  static const all = <ItemDef>[
    birchLog,
    brookmint,
    charcoal,
    brookmintTonic,
    birchQuarterstaff,
    birchWand,
    birchKnot,
    theCharlock,
  ];
}
