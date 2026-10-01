/// Everything The Molten Deep can yield (Lv 25–29, Pyro + Geo hybrid —
/// KINETIC_CONTRACT §4.6).
///
/// ⭐ Hybrid zone: three materials, per ITEMS §9b.8 ruling 7. ⚠️ **No motes
/// defined here** — every drop references the existing `pyro_*` (Cinderpeak)
/// and `geo_*` (Old Quarry) mote families instead; this zone and Frostfell
/// Pass are the first places Q1's motes get a new source (§3.2).
///
/// ⚠️ **Was 8; two were cut.** `obsidian_ring` was a Jewelry recipe output
/// with no other source — cut with its recipe (§8.1). `firesalt_flask` was
/// the quarter's offensive potion — cut with the Antidote (§8.5). Neither
/// Molten Deep zone has an epic gap to fill (§8.7 only touches Frostfell and
/// Thunderspire), so nothing replaces them. 📝 **2026-10-01: `obsidian_ring`
/// is back**, with an `obsidian_pendant` beside it — the Jewelry ladder below
/// Rimeholt (ENCHANTING §5.3) reversed §8.1's hold, and its Jewelry-18 rung
/// is defined here.
///
/// ⏳ `firesalt` banks until the offensive-potion vocabulary ships (§8.5, §9
/// Fast-follow). `obsidian` no longer banks: the ladder spends it from
/// Jewelry 18, and the Pyro gem cut (ENCHANTING §5.1) at Rimeholt.
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
  /// `value: 20` — ECONOMY_CONTRACT §8.2 (no recipe consumer yet).
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
    value: 20,
  );

  /// ⏳ Banks until the offensive-potion vocabulary ships (§8.5, §9
  /// Fast-follow). `value: 15` — ECONOMY_CONTRACT §8.2 (no recipe consumer
  /// yet).
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
    value: 15,
  );

  /// ⚠️ **Kill-only, no node** — a hide (§3.1/§6). ⭐ `value: 190` —
  /// ECONOMY_CONTRACT §8.2/§8.5: looks wildly out of step with `firesalt`
  /// (15) at the same tier, but it is not a mistake — this hide feeds only
  /// `emberhide_belt` (Standard 380, the top belt in the game), and it is
  /// kill-only, same scarcity class as `rimepelt`/`tuskhide`. A hide priced
  /// to conserve against an already-high, already-shipped belt value is the
  /// formula working correctly, not a formula artifact.
  static const emberhide = MaterialDef(
    id: 'emberhide',
    properName: 'Emberhide',
    rarity: Rarity.common,
    lore:
        'A hide that never fully cooled, dull orange still showing through '
        'the black in a scatter of hairline cracks whenever it flexes.',
    skill: CraftSkill.tailoring,
    tier: 5,
    value: 190,
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
    // ⭐ Tier 3: potency 5 × 3 + 5 (ruling 2026-09-25).
    modifiers: ItemModifiers(beltSlots: 4, consumablePotencyPercent: 20),
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

  // ---- the Jewelry ladder, rung 4 (ENCHANTING §5.3) ---------------------
  //
  // ⭐ Jewelry 18: iron around the Deep's obsidian. The `obsidian_ring` KINETIC
  // §8.1 cut returns here — and with it the sidegrade that cut left
  // unexpressed: steady crafted stats beside the Firstmelt Loop's gamble.

  /// Flat HP, the ring's line — half a Tussock robe. Σ iron ×1 (52) +
  /// obsidian ×2 (40) = **92**; `value: 84` (84 < 92 < 100.8).
  static const obsidianRing = EquipmentDef(
    id: 'obsidian_ring',
    rarity: Rarity.common,
    lore:
        'Black glass ground into a band and pinned with iron. It took the '
        'heat once and kept the shape.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Obsidian',
    modifiers: ItemModifiers(maxHpBonus: 10),
    salvage: [SalvageYield('obsidian', 1, 1)],
    equipLevel: 27,
    value: 84,
  );

  /// Pyro's crit damage — ⭐ legal on crafted gear from equip 25 (KINETIC
  /// §2.5: Rowan is where crafting gets crit). Σ iron ×1 (52) + obsidian ×3
  /// (60) = **112**; `value: 100` (100 < 112 < 120).
  static const obsidianPendant = EquipmentDef(
    id: 'obsidian_pendant',
    rarity: Rarity.common,
    lore:
        'An obsidian flake knapped to a point and hung on iron. The edge is '
        'still the sharpest thing you own.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Obsidian',
    modifiers: ItemModifiers(critDamage: 8),
    salvage: [SalvageYield('obsidian', 1, 2)],
    equipLevel: 27,
    value: 100,
  );

  static const all = <ItemDef>[
    obsidian,
    firesalt,
    emberhide,
    emberhideBelt,
    firstmeltLoop,
    theLongCooling,
    obsidianRing,
    obsidianPendant,
  ];
}
