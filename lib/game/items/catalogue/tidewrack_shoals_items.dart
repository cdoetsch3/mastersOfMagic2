/// Everything the Tidewrack Shoals can yield (Lv 36–40, Lunar + Aqua).
///
/// ⭐ Hybrid zone, three materials (CELESTIAL_CONTRACT §3.1, ITEMS §9b.8
/// ruling 7). **Wrackcotton** feeds Tailoring, **Nacre** feeds Jewelry, and
/// **Drownling Hide** feeds Tailoring as well. ⚠️ **Drownling Hide is a
/// hide — kill-only, no node** (§9b.7b), the same rule Frostfell's Rimepelt
/// and The Molten Deep's Emberhide follow. ⏳ **Nacre banks** until Jewelry's
/// station and learning open at Rimeholt (L45, §3.1) — ⭐ the shortest
/// banking window any quarter has had, because Rimeholt is the very next
/// town.
///
/// ⭐ **No motes defined here.** A mote family lives with whichever zone
/// first yielded it (§3.2): Tidewrack pays in `lunar_*` (The Mirrormere) and
/// Q1's `aqua_*` (Glimmerbrook) and defines neither. ⚠️ **`aqua_*` is a
/// deliberate cross-quarter reference** — one of two in the quarter, and it
/// hands a player a reason to care about a mote family they stopped seeing
/// twenty levels ago.
///
/// ⭐ **11 defs** (§4.4, §7.1's count). The zone is reached **by sea from
/// Galehaven**, so it is the one Celestial zone a player can arrive at
/// without passing Concordance — which is why its consumables are imported
/// (`pilgrims_ration`, `glasswort_draught`, both Kiln Desert's) and its gear
/// starts a fresh armour tier rather than continuing one.
///
/// ⭐ **Both drops mix Lunar's dodge with Aqua's shield strength** (§2.5a) —
/// the hybrid stated as a stat block: the tide obeys, and obedience is a
/// defence.
library;

import '../item_def.dart';

abstract final class TidewrackShoalsItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ Tailoring t6, and 📝 the obvious Tier I set base if Phase 8's L30 set
  /// lands on this band's fibre rather than the Kiln Desert's (§3.6).
  static const wrackcotton = MaterialDef(
    id: 'wrackcotton',
    properName: 'Wrackcotton',
    rarity: Rarity.common,
    lore:
        'It grows on the flats and is only there for six hours a day. '
        'Everything about harvesting it is the clock.',
    skill: CraftSkill.tailoring,
    tier: 6,
    value: 150,
  );

  /// ⏳ Banks until Rimeholt (L45) — Jewelry's station and learning stay
  /// there (§3.1, re-confirming KINETIC §8.1). The ETHEREAL contract's §5 is
  /// what finally spends it.
  static const nacre = MaterialDef(
    id: 'nacre',
    properName: 'Nacre',
    rarity: Rarity.uncommon,
    lore:
        'Shell-lining, prised off in whole plates. Nobody in Concordance '
        'knows what to do with it yet. Someone at Rimeholt will.',
    skill: CraftSkill.jewelry,
    tier: 6,
    value: 95,
  );

  /// ⚠️ **Kill-only, no node** (§3.1, ITEMS §9b.7b) — it exists only because
  /// something died, so a gather node for it would be a second source that
  /// contradicts its own fiction. The hide commons, the minis and the bosses
  /// are the whole supply.
  static const drownlingHide = MaterialDef(
    id: 'drownling_hide',
    properName: 'Drownling Hide',
    rarity: Rarity.common,
    lore:
        'Off something the tide uncovered. It has never been dry and it is '
        'not wet.',
    skill: CraftSkill.tailoring,
    tier: 6,
    value: 300,
  );

  // ---- the Wrackcotton set ----------------------------------------------
  //
  // ⭐ **Set total: 67 HP · 5 acc · 5 dodge · 14/24 deflect.** Against the
  // level-39 baseline (444 HP) that is +15.1% — the proportion §2.6 holds to.
  // ⚠️ Crafted equipment leaves `properName` null: the name composes from
  // material + form (ITEMS §9b.5a), and a test enforces it.

  static const wrackcottonHood = EquipmentDef(
    id: 'wrackcotton_hood',
    rarity: Rarity.common,
    lore:
        'Salt-stiffened and cut with a flat brim, the way everyone here cuts '
        'everything.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Wrackcotton',
    // ⭐ Accuracy lives on the hood — §2.5's distribution rule, unchanged
    // through four quarters. ⚠️ And it now stops climbing (§2.1a).
    modifiers: ItemModifiers(accuracyBonus: 5),
    salvage: [SalvageYield('wrackcotton', 1, 2)],
    equipLevel: 39,
    value: 450,
  );

  static const wrackcottonRobe = EquipmentDef(
    id: 'wrackcotton_robe',
    rarity: Rarity.common,
    lore:
        'Six layers. It is the warmest thing on the shoals and it still '
        'takes an hour to dry.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Wrackcotton',
    modifiers: ItemModifiers(maxHpBonus: 32),
    salvage: [SalvageYield('wrackcotton', 1, 2)],
    equipLevel: 39,
    value: 900,
  );

  static const wrackcottonLeggings = EquipmentDef(
    id: 'wrackcotton_leggings',
    rarity: Rarity.common,
    lore:
        'Quilted to the knee and plain below it, because below the knee is '
        'underwater twice a day.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Wrackcotton',
    modifiers: ItemModifiers(maxHpBonus: 22),
    salvage: [SalvageYield('wrackcotton', 1, 2)],
    equipLevel: 39,
    value: 750,
  );

  /// ⭐ Dodge lives on the boots (§2.5), and Lunar's affinity IS dodge
  /// (§2.5a) — so the zone's half-Lunar identity arrives on the one piece
  /// the shipped distribution already wanted it on.
  static const wrackcottonBoots = EquipmentDef(
    id: 'wrackcotton_boots',
    rarity: Rarity.common,
    lore: 'High, soft and laced at the back so you can get out of them fast.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Wrackcotton',
    modifiers: ItemModifiers(maxHpBonus: 6, dodge: 5),
    salvage: [SalvageYield('wrackcotton', 1, 2)],
    equipLevel: 39,
    value: 450,
  );

  /// ⚠️ Deflect chance **and** amount, on the gloves and nowhere else in the
  /// set (§2.5, §2.1b) — 14/24 is EV 3.4%, and §2.1b's finding is that
  /// deflect *amount* sums across pieces, so only one piece may carry it.
  static const wrackcottonGloves = EquipmentDef(
    id: 'wrackcotton_gloves',
    rarity: Rarity.common,
    lore:
        'Palms tripled. You put your hands out here, or the shoals put them '
        'out for you.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Wrackcotton',
    modifiers: ItemModifiers(
      maxHpBonus: 7,
      deflectChance: 14,
      deflectAmount: 24,
    ),
    salvage: [SalvageYield('wrackcotton', 1, 2)],
    equipLevel: 39,
    value: 450,
  );

  // ---- drownling gear -----------------------------------------------------

  /// ⭐ Belt capacity ladder: Fawnhide 1 → Tuskhide 2 → Rimepelt 3 →
  /// Emberhide 4 → **Drownling 5** → Palimpsest 6. `Carrying.maxBeltSlots`
  /// is 10. ⚠️ **Belts carry `beltSlots` and consumable potency and
  /// nothing else** — the Q1 ruling, widened 2026-09-25; the belt is the
  /// one slot that is deliberately *not* combat power (ITEMS §6b.2). Do
  /// not add combat stats to a belt.
  static const drownlingBelt = EquipmentDef(
    id: 'drownling_belt',
    rarity: Rarity.common,
    lore: 'Five loops of hide that has never taken a dye.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Drownling',
    // ⭐ Tier 4: potency 5 × 4 + 5 (ruling 2026-09-25).
    modifiers: ItemModifiers(beltSlots: 5, consumablePotencyPercent: 25),
    salvage: [SalvageYield('drownling_hide', 1, 2)],
    equipLevel: 38,
    value: 750,
  );

  /// ⭐ The mini pool's Rare chase. 📝 `shieldStrengthPercent` is Aqua's
  /// affinity and `dodge` is Lunar's (§2.5a) — the hybrid written as one
  /// item, which is why this is the drop the zone is remembered by.
  static const theTurningTide = EquipmentDef(
    id: 'the_turning_tide',
    properName: 'The Turning Tide',
    rarity: Rarity.rare,
    lore:
        'It is heavy at the low and light at the high. Sailors swear that is '
        'the shell and not them.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Nacre',
    modifiers: ItemModifiers(dodge: 6, shieldStrengthPercent: 12),
    tradability: Tradability.untradeable,
    salvage: [SalvageYield('nacre', 1, 2)],
    equipLevel: 38,
    value: 1050,
  );

  /// ⭐ The zone's epic, boss-only. Same two lines as the Rare, one rung up
  /// and with the band's flat HP under them — ⚠️ a **second** boots item, so
  /// it competes with the set's own boots rather than the Rare's neck.
  static const lowwaterTread = EquipmentDef(
    id: 'lowwater_tread',
    properName: 'Lowwater Tread',
    rarity: Rarity.epic,
    lore:
        'Made for the six hours. Whoever wore them out here came back, which '
        'is more than most.',
    slot: EquipSlot.boots,
    form: 'Tread',
    material: 'Drownling',
    modifiers: ItemModifiers(
      maxHpBonus: 24,
      dodge: 7,
      shieldStrengthPercent: 10,
    ),
    tradability: Tradability.untradeable,
    salvage: [SalvageYield('drownling_hide', 1, 2)],
    equipLevel: 40,
    value: 3000,
  );

  static const all = <ItemDef>[
    wrackcotton,
    nacre,
    drownlingHide,
    wrackcottonHood,
    wrackcottonRobe,
    wrackcottonLeggings,
    wrackcottonBoots,
    wrackcottonGloves,
    drownlingBelt,
    theTurningTide,
    lowwaterTread,
  ];
}
