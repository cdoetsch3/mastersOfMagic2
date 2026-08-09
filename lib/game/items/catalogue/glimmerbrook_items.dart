/// Everything Glimmerbrook can yield (Lv 3–8, Aqua).
///
/// ⭐ Pure zone, so exactly TWO materials (ITEMS §9b.8): the quarter's hide
/// and its Draught herb both start here. ⚠️ The zone's roster is unbuilt —
/// nothing drops these yet, and the obtainability test arrives with the
/// bestiary, per the Whispering Woods template.
library;

import '../item_def.dart';

abstract final class GlimmerbrookItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ Leather. Belts are a Tailoring product (ITEMS §10.3d), and this is
  /// where the line starts.
  static const fawnhide = MaterialDef(
    id: 'fawnhide',
    properName: 'Fawnhide',
    rarity: Rarity.common,
    lore:
        'Thin, and it takes a dye better than anything else this close to '
        'the water. Nobody in Hearthwood will say where they get it.',
    skill: CraftSkill.tailoring,
    tier: 1,
  );

  /// The Draught herb (§9b.8's potion grammar: ingredient = magnitude).
  static const sapwort = MaterialDef(
    id: 'sapwort',
    properName: 'Sapwort',
    rarity: Rarity.common,
    lore:
        'Grows with its feet in the brook and its head in the sun, and tastes '
        'of neither.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 1,
  );

  // ---- consumables ----------------------------------------------------

  /// ⭐ Beltable, so it can be drunk mid-duel — at the cost of the turn.
  /// The Draught form: a flat heal, always (§9b.8).
  static const sapwortDraught = BeltableDef(
    id: 'sapwort_draught',
    properName: 'Sapwort Draught',
    rarity: Rarity.common,
    lore:
        'Tastes like the underside of a leaf. Apprentices carry two and use '
        'neither, which is its own kind of lesson.',
    // ⚠️ Weaker than a ration on purpose: this one costs a TURN, and the
    // opponent committed blind, so its value is the timing, not the number.
    effect: ItemEffect(healPercent: 20),
    value: 12,
  );

  // ---- equipment ------------------------------------------------------

  /// ⭐ The first belt in the game (ITEMS §10.3d) — capacity, nothing else.
  static const fawnhideBelt = EquipmentDef(
    id: 'fawnhide_belt',
    rarity: Rarity.common,
    lore: 'Soft enough to sleep in. It will hold a bottle where you can '
        'reach it, which is worth more than it sounds.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Fawnhide',
    modifiers: ItemModifiers(beltSlots: 1),
    salvage: [SalvageYield('fawnhide', 1, 2)],
    equipLevel: 4,
    value: 40,
  );

  /// ⭐ **Drop-only jewelry** (§9b.8): no maker until Rimeholt, so the mini
  /// pool is the only source. 📝 Dropper: the Frostgleam Naiad, when the
  /// roster is built.
  static const brookstonePendant = EquipmentDef(
    id: 'brookstone_pendant',
    properName: 'Brookstone Pendant',
    rarity: Rarity.rare,
    lore:
        'A river pebble with a hole worn through it, strung on gut. Looking '
        'through the hole shows the same world, calmer.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Brookstone',
    modifiers: ItemModifiers(shieldStrengthPercent: 10),
    tradability: Tradability.untradeable,
    equipLevel: 6,
    value: 200,
  );

  static const all = <ItemDef>[
    fawnhide,
    sapwort,
    sapwortDraught,
    fawnhideBelt,
    brookstonePendant,
  ];
}
