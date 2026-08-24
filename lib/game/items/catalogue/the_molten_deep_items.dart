/// Everything The Molten Deep can yield (Lv 25–29, Pyro + Geo hybrid —
/// KINETIC_CONTRACT §4.6).
///
/// ⭐ Hybrid zone: three materials, per ITEMS §9b.8 ruling 7. ⚠️ **No motes
/// defined here** — every drop references the existing `pyro_*` (Cinderpeak)
/// and `geo_*` (Old Quarry) mote families instead; this zone and Frostfell
/// Pass are the first places Q1's motes get a new source (§3.2).
///
/// ⚠️ **Was 8; two are cut.** `obsidian_ring` was a Jewelry recipe output
/// with no other source — cut with its recipe (§8.1). `firesalt_flask` was
/// the quarter's offensive potion — cut with the Antidote (§8.5). Neither
/// Molten Deep zone has an epic gap to fill (§8.7 only touches Frostfell and
/// Thunderspire), so nothing replaces them.
///
/// ⏳ **Two materials bank rather than spend.** `obsidian` banks until
/// Jewelry unlocks at Rimeholt, L45 (§8.1); `firesalt` banks until the
/// offensive-potion vocabulary ships (§8.5, §9 Fast-follow).
///
/// ⚠️ **`emberhide` is kill-only** — a hide, and it has no gather node
/// (§3.1/§6).
///
/// ⚠️ **No `pyro_essence` or `geo_essence` here.** The Kinetic Sigil's
/// collect-three-keys mechanism is rejected this quarter (§3.3/§8.6) — no
/// essence item, no key, no gate collectible.
library;

import '../item_def.dart';

abstract final class TheMoltenDeepItems {
  // ---- materials ------------------------------------------------------

  /// ⏳ Banks until Jewelry unlocks at Rimeholt, L45 — Q2 only *finds* jewel
  /// materials this quarter, per ruling (§8.1).
  static const obsidian = MaterialDef(
    id: 'obsidian',
    properName: 'Obsidian',
    rarity: Rarity.uncommon,
    lore:
        'Black glass where the floor sheared clean and cooled too fast to '
        'crystallise, sharp along every broken edge and sharper than it '
        'looks.',
    skill: CraftSkill.jewelry,
    tier: 4,
  );

  /// ⏳ Banks until the offensive-potion vocabulary ships (§8.5, §9
  /// Fast-follow).
  static const firesalt = MaterialDef(
    id: 'firesalt',
    properName: 'Firesalt',
    rarity: Rarity.common,
    lore:
        'A crust of pale mineral left behind at a vent\'s lip, where the '
        'heat leaves something solid on its way out. Bitter, and warm long '
        'after it is pocketed.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 5,
  );

  /// ⚠️ **Kill-only, no node** — a hide (§3.1/§6).
  static const emberhide = MaterialDef(
    id: 'emberhide',
    properName: 'Emberhide',
    rarity: Rarity.common,
    lore:
        'A hide that never fully cooled, dull orange still showing through '
        'the black in a scatter of hairline cracks whenever it flexes.',
    skill: CraftSkill.tailoring,
    tier: 5,
  );

  // ---- equipment ------------------------------------------------------

  /// ⭐ Crafted (Tailoring, from Emberhide) — `properName` stays null so the
  /// material + form grammar composes the name (§3.4).
  static const emberhideBelt = EquipmentDef(
    id: 'emberhide_belt',
    rarity: Rarity.common,
    lore:
        'A wide strap of Emberhide worn low, four loops sewn into it and '
        'still faintly warm to the touch no matter how long it has hung on '
        'a peg.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Emberhide',
    modifiers: ItemModifiers(beltSlots: 4),
    equipLevel: 27,
    value: 380,
  );

  /// ⭐ **The Deep's crit ring**, standing alone since `obsidian_ring` was
  /// cut with Jewelry (§8.1) — ITEMS §4.1a's "low-chance/high-crit-damage
  /// glass cannon vs high-accuracy consistent" axis has no second ring to
  /// express it against until Jewelry opens at Rimeholt.
  static const firstmeltLoop = EquipmentDef(
    id: 'firstmelt_loop',
    properName: 'Firstmelt Loop',
    rarity: Rarity.rare,
    lore:
        'A ring cast in one motion from rock that was still moving when it '
        'set, its band never quite closing into a true circle. Warm, and '
        'unwilling to let go of a grip once it has one.',
    slot: EquipSlot.ring,
    form: 'Loop',
    material: 'Firstmelt',
    modifiers: ItemModifiers(critChance: 5, critDamage: 25),
    tradability: Tradability.untradeable,
    equipLevel: 28,
    value: 360,
  );

  /// ⭐ **The quarter's closing epic.** ⚠️ Competes with `tussock_hood` — the
  /// same break-your-set decision as `the_long_lean`, at the other end of
  /// the quarter.
  static const theLongCooling = EquipmentDef(
    id: 'the_long_cooling',
    properName: 'The Long Cooling',
    rarity: Rarity.epic,
    lore:
        'A circlet of polished obsidian, worn smooth in one groove around '
        'the brow and still sharp everywhere else. It is still cooling; it '
        'will always still be cooling.',
    slot: EquipSlot.hat,
    form: 'Circlet',
    material: 'Obsidian',
    modifiers: ItemModifiers(
      maxHpBonus: 22,
      deflectChance: 12,
      deflectAmount: 25,
      critDamage: 15,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 29,
    value: 820,
  );

  static const all = <ItemDef>[
    obsidian,
    firesalt,
    emberhide,
    emberhideBelt,
    firstmeltLoop,
    theLongCooling,
  ];
}
