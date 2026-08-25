/// Everything the Frostfell Pass can yield (Lv 21–26, Aqua + Aero).
///
/// ⭐ Hybrid zone: three materials (KINETIC_CONTRACT §3.1, §9b.8 ruling 7).
/// Rimepelt feeds Tailoring, Hoarlichen feeds Potions & Alchemy, Everice
/// feeds Jewelry. ⚠️ Rimepelt is a **hide, kill-only, no node** — the same
/// rule Cinderpeak's Tuskhide and The Molten Deep's Emberhide follow.
/// Hoarlichen and Everice both ⏳ **bank**: Hoarlichen until the Antidote
/// ships (§8.5/§9 fast-follow), Everice until Jewelry opens at Rimeholt
/// (L45, §8.1).
///
/// ⭐ **No motes defined here.** A hybrid's mote families live with whichever
/// zone first yielded them (§3.2) — this quarter that is Old Quarry (Geo),
/// Stormcliff Coast (Electro) and Windward Steppe (Aero); Aqua's motes ship
/// with Glimmerbrook, in Q1. Frostfell drops `aqua_*` and `aero_*` and
/// defines neither family.
///
/// ⭐ **Still 6 defs, but the set changed** (§4.4, §8.7). `hoarlichen_antidote`
/// is cut — no `ItemEffect` vocabulary exists to write it against (§8.5) —
/// and `the_holdfast` is added: Frostfell's epic, ruled onto the boss pool
/// after the original "doubled Crystals instead of an epic" substitution was
/// rejected (§8.7). The count is coincidentally the same as the earlier
/// draft's.
library;

import '../item_def.dart';

abstract final class FrostfellPassItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ `value: 95` — ECONOMY_CONTRACT §8.2/§8.4/§14b.1's correction (was the
  /// shipped 12): `craft_rimepelt_belt` (rimepelt×2 + tussock_flax×1) at the
  /// old value was the audit's **worst offender** — Σ=61 against Standard
  /// 220, a risk-free buy-craft-vendor loop nearly four times over, in an
  /// already-authored material. At 95, the same recipe's Σ=227 lands inside
  /// [220, 264].
  static const rimepelt = MaterialDef(
    id: 'rimepelt',
    properName: 'Rimepelt',
    rarity: Rarity.common,
    lore:
        'Thick fur gone white and stiff with frost that never fully thaws, '
        'even carried indoors. It holds the cold the way it once held in '
        'the warmth.',
    skill: CraftSkill.tailoring,
    tier: 4,
    value: 95,
  );

  /// ⏳ Banks until the Antidote ships (§8.5, §9 fast-follow) — no
  /// `ItemEffect` vocabulary exists yet to spend it against. `value: 11` kept
  /// as shipped — ECONOMY_CONTRACT §8.2 (no recipe consumer, ground truth).
  static const hoarlichen = MaterialDef(
    id: 'hoarlichen',
    properName: 'Hoarlichen',
    rarity: Rarity.common,
    lore:
        'Grey-green scale grown flat against black rock, the only living '
        'colour in the pass. It keeps growing at temperatures that should '
        'have finished it.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 4,
    value: 11,
  );

  /// ⏳ Banks until Jewelry opens at Rimeholt (L45, §8.1) — the Q1-ore-before-
  /// Metalworking pattern, one skill later. `value: 26` kept as shipped —
  /// ECONOMY_CONTRACT §8.2 (no recipe consumer, ground truth).
  static const everice = MaterialDef(
    id: 'everice',
    properName: 'Everice',
    rarity: Rarity.uncommon,
    lore:
        'Ice caught inside the rock itself, clear as glass and never once '
        'warmed by anything the black walls have done since. It comes free '
        'in one clean piece or not at all.',
    skill: CraftSkill.jewelry,
    tier: 5,
    value: 26,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ Belt capacity ladder: Fawnhide 1 → Tuskhide 2 → Rimepelt 3 →
  /// Emberhide 4. ⚠️ Belts carry `beltSlots` and nothing else — the Q1
  /// ruling; §6b.2's whole point is that capacity is the one axis that is
  /// *not* combat power.
  static const rimepeltBelt = EquipmentDef(
    id: 'rimepelt_belt',
    rarity: Rarity.common,
    lore:
        'Three loops stitched into rimepelt gone stiff enough to hold its '
        'shape on its own. Cold to the touch, always, no matter how long '
        'it has been worn.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Rimepelt',
    modifiers: ItemModifiers(beltSlots: 3),
    salvage: [SalvageYield('rimepelt', 1, 2)],
    equipLevel: 23,
    value: 220,
  );

  /// ⭐ The mini-pool's rare chase — a small, legible combination of the
  /// quarter's two defensive lines (§2.5): deflect off Everice's Geo-adjacent
  /// hardness, a point of dodge for the Aero half of the zone.
  static const rimeboundRing = EquipmentDef(
    id: 'rimebound_ring',
    properName: 'Rimebound Ring',
    rarity: Rarity.rare,
    lore:
        'A band of clear ice-shot stone that has never once cracked, worn '
        'by people who swore the cold in it was doing something for them. '
        'They may have been right.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Everice',
    modifiers: ItemModifiers(
      deflectChance: 10,
      deflectAmount: 20,
      dodge: 3,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 24,
    value: 290,
  );

  /// ✅ **RULED — Frostfell's epic (§8.7).** `shieldStrengthPercent: 15`,
  /// lowered from an initial 25; the only shipped shield-strength item is
  /// Brookstone Pendant at 10 (Glimmerbrook), so 15 is the next rung up, not
  /// a leap. ⭐ Slot and lore lean on the zone's own metaphor: a holdfast is
  /// the anchor kelp grips stone with, and *"everything that moves through
  /// here gets held"* is the zone's premise stated as an item.
  static const theHoldfast = EquipmentDef(
    id: 'the_holdfast',
    properName: 'The Holdfast',
    rarity: Rarity.epic,
    lore:
        'A grip of stone-grey rimestone worn at the throat, cut the shape '
        'kelp uses to anchor itself against a current that would otherwise '
        'take it. Whatever it is holding onto, it has not let go yet.',
    slot: EquipSlot.neck,
    form: 'Anchor',
    material: 'Rimestone',
    modifiers: ItemModifiers(shieldStrengthPercent: 15),
    tradability: Tradability.untradeable,
    equipLevel: 25,
    value: 760,
  );

  static const all = <ItemDef>[
    rimepelt,
    hoarlichen,
    everice,
    rimepeltBelt,
    rimeboundRing,
    theHoldfast,
  ];
}
