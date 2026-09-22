/// Everything Hallowmarch can yield (Lv 45–49, Sanctus) —
/// ETHEREAL_CONTRACT §4.1.
///
/// ⭐ **A pure zone: two materials** (ITEMS §9b.8 ruling 7) — Spiritwood feeds
/// Woodcarving, Goldenrood feeds Potions & Alchemy. ⚠️ **There is no hide
/// here, deliberately**: the roster's `hide` drop role therefore resolves to
/// `goldenrood`, the zone's **SECOND** gatherable material (§3.5.1, which
/// governs both quarters).
///
/// ⭐ **This file DEFINES the `sanctus_*` mote family** (§3.2 — the mote lives
/// with the zone that first yields it). The Sealed Garden and The Reliquary
/// Deep both drop `sanctus_*` and ⚠️ **must not re-define it**, exactly as
/// Frostfell imports `aqua_*` rather than authoring it.
///
/// ⭐⭐ **`the_kept_third` is defined HERE**, and it is the one item §4.1's
/// own catalogue table forgot: §3.4's reconciliation moved the three Ethereal
/// fragments onto the quarter's three PURE zones, and §4.4's table still
/// carries the struck-through row (*"⚠️ moved to Hallowmarch"*) that this one
/// never grew. So this file ships **13** defs where §4.1 and §7.1 both say
/// 12 — see the build report.
///
/// ⭐ **`climbers_ration` and `goldenrood_draught` are the quarter's shared
/// consumables and both live here** (§3.3) — the Ration is **drop-only**
/// across all eight Ethereal zones, on the `hardtack` pattern, and the
/// Draught is crafted #22. ⚠️ Sibling Ethereal catalogues reference both by
/// id; this file is where they resolve.
///
/// ⭐⭐ **Spiritwood is the first two-socket rung of the crafted wood
/// ladder.** Every crafted wood before it carried 0 or 1 (ITEMS §9b.6's
/// range), and the three Spiritwood weapons below are where the range's top
/// is first spent — and the first whole weapon SET to spend it.
/// ⚠️ **§4.1a of CELESTIAL overstates this as "the first two-socket item in
/// the game", and the shipped catalogue disagrees**: `heartwood_stave`, the
/// Whispering Woods' level-5 epic boss unique, has carried two sockets since
/// Q1. The numbers here are the contract's; only the claim is corrected, and
/// `test/hallowmarch_test.dart` pins the two-socket set by name so a fourth
/// one sends a human back to §4.1a.
/// ⚠️ An empty socket is still a promise: `socketCount` is a shipped field
/// with a shipped meaning, not a claim this file makes about Phase 8.
///
/// ⭐ **Sanctus's affinity arrives complete, on the first two items a player
/// finds here** (§2.5a): shield strength % **and** healing received %, the
/// support pair no element owned alone — Aqua's and Flora's leans at once.
/// ⚠️ `shieldStrengthPercent` now has four sources in the game: Brookstone
/// Pendant 10, The Holdfast 15, and these at 18 and 20. 📝 A player wearing
/// the neck epic *and* a shield-strength spell stance sums on
/// `effectiveShieldStrengthPercent`; SYSTEMS §2 says gear % and spell %
/// already share that seam, and **nobody has measured the top of it**.
///
/// ⚠️ **`votive_pendant` and `the_maintained_road` are the same slot** — a
/// rare→epic ladder inside one zone, as Starfall Basin has. 📝 §4.1 offers
/// moving the rare to `ring` for a sidegrade instead; the contract's own
/// table is followed here, so both are `neck`.
///
/// 📝 **Phase 8 hook** (§3.6): Hallowmarch is where a **Sanctus enchant** and
/// ITEMS §3.4's **set Tier III (L45, Mythic)** would both land, and
/// Spiritwood's two sockets are the zone's Phase 8 surface. ⚠️ No `setId`, no
/// `setTier`, no enchant field and no gem item appears here — the two
/// rarities Phase 8 will need are exactly the two this contract is forbidden
/// to use, so every piece below is a plain Common that Phase 8 can add sets
/// *beside* rather than *instead of*.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class HallowmarchItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ ITEMS §9b.6's wood for this zone — *"hallowed ground, hallowed wood."*
  /// Tier 8, Woodcarving, `equipLevel` left at the default: a log has no
  /// level. 📝 The contract flags the **1500** as a value to red-pen; it is
  /// transcribed rather than adjusted, because the recipe lane prices against
  /// it.
  static const spiritwoodLog = MaterialDef(
    id: 'spiritwood_log',
    properName: 'Spiritwood Log',
    rarity: Rarity.common,
    lore:
        'It grew beside the road, which means someone planted it, which '
        'means someone expected to come back.',
    skill: CraftSkill.woodcarving,
    tier: 8,
    value: 1500,
  );

  /// ⭐ The herb out of the meltwater channel that runs beside the road the
  /// whole way — the one detail of the arrival text that is about being
  /// looked after. ⚠️ It is also the zone's SECOND material and therefore
  /// what every `hide` role in this roster pays out (§3.5.1).
  static const goldenrood = MaterialDef(
    id: 'goldenrood',
    properName: 'Goldenrood',
    rarity: Rarity.common,
    lore:
        'Yellow, waist-high, and it grows in the channel and nowhere else on '
        'the mountain. Somebody cut that channel.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 8,
    value: 47,
  );

  // ---- motes ----------------------------------------------------------
  // ⭐ Values are ECONOMY §14c's, one per TIER and uniform across every
  // element: Dust 2 · Shard 25 · Crystal 150. ⚠️ Deliberately LOSSY against
  // the refinement ladder (a Shard vendors for less than its 50 Dust cost) so
  // refine-and-vendor can never profit.
  // ⚠️ **No Core and no Heart in this quarter** (§3.2) — and that is where it
  // bites hardest, because `world.dart` gates Zenith on twelve Cores. A known
  // gap, recorded in §3.4a, not an oversight here.

  static const sanctusDust = MoteDef(
    id: 'sanctus_dust',
    properName: 'Sanctus Dust',
    rarity: Rarity.common,
    lore: 'Warm on the palm, and it stays where you put it.',
    tier: MoteTier.dust,
    element: MagicElement.sanctus,
    value: 2,
  );

  /// ⚠️ §4.1's lore line is *"Dust that was kept."* — nineteen characters,
  /// and `whispering_woods_test.dart` requires every item's lore to clear
  /// twenty. ⭐ The contract's sentence is kept verbatim as the opening and
  /// finished rather than replaced, so the epigram survives the floor.
  static const sanctusShard = MoteDef(
    id: 'sanctus_shard',
    properName: 'Sanctus Shard',
    rarity: Rarity.common,
    lore: 'Dust that was kept, and kept together.',
    tier: MoteTier.shard,
    element: MagicElement.sanctus,
    value: 25,
  );

  /// ⚠️ **Uncommon — mini-bosses and bosses only.** `uncommon` survives on
  /// Crystal motes and gem-grade materials and nowhere in equipment
  /// (§0.2 ruling 2).
  static const sanctusCrystal = MoteDef(
    id: 'sanctus_crystal',
    properName: 'Sanctus Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is looked after, and it does not stop being looked after.',
    tier: MoteTier.crystal,
    element: MagicElement.sanctus,
    value: 150,
  );

  // ---- consumables ----------------------------------------------------

  /// ⚠️ **`ConsumableDef`, NOT `BeltableDef`** — a Ration is not usable in a
  /// fight (ITEMS §9b.8 ruling 6). ⭐ Drop-only across all eight Ethereal
  /// zones, the `hardtack` pattern; §3.3's ladder puts a Ration at 35% of the
  /// band floor's health, and 195 is 34.7% of a level-45 bar.
  /// ⭐ **The Ration's last rung is named for the mountain, not the herb** —
  /// Rimeholt is basecamp, and this is what everything you kill up here is
  /// carrying.
  static const climbersRation = ConsumableDef(
    id: 'climbers_ration',
    properName: "Climber's Ration",
    rarity: Rarity.common,
    lore:
        'Hard cheese, harder bread, and a strip of something salted. '
        'Rimeholt sells it by the week and nobody argues about the price.',
    effect: ItemEffect(heal: 195),
    value: 30,
  );

  /// ⭐ **Draught = a flat heal that costs your turn**, so it beats a Ration
  /// (§3.3's ordering ruling): 225 is 40.0% of a level-45 bar. ⚠️ Its `value`
  /// is priced against §5.4's value conservation, **not** against the heal
  /// number — the 2026-09-21 `sapwort_draught` ruling says so explicitly.
  static const goldenroodDraught = BeltableDef(
    id: 'goldenrood_draught',
    properName: 'Goldenrood Draught',
    rarity: Rarity.common,
    lore:
        'Gold, faintly sweet, and it works before you have finished '
        'swallowing. The markers on the road are the same colour.',
    effect: ItemEffect(heal: 225),
    value: 140,
  );

  // ---- the gate fragment ------------------------------------------------

  /// ⚠️ **Kill-only, no node, and not a crafting material** — one of the
  /// three Ethereal fragments that open The Eclipsed Citadel (§3.4).
  /// Guaranteed on BOTH bosses' `always` line, so the boss a run happens to
  /// draw never decides whether progression is possible.
  ///
  /// ⚠️ **Gates are SHOWN, not spent** (ruling, 2026-09-21) — `gateItemIds`
  /// plus `PlayerProfile.openedGates`, the mechanism Pennycross shipped with.
  /// ⚠️ **`the_eclipsed_citadel.gateItemIds` must be
  /// `['the_kept_third', 'the_dark_third', 'the_written_third']` in
  /// `world.dart`** or the last door in the game is unlocked and the whole of
  /// §3.4 is a lore line. 📝 That is a shared-file edit this lane did not
  /// make, and the other two ids belong to sibling lanes; see the build
  /// report.
  ///
  /// ⚠️ `KeyDef` forces Bound and `value: 0` by construction, so this is
  /// exempt from §5.4's value conservation rather than failing it.
  static const theKeptThird = KeyDef(
    id: 'the_kept_third',
    properName: 'The Kept Third',
    rarity: Rarity.rare,
    lore:
        'The vow, kept. Whoever still walks this road was given a third of '
        'something to hold, and has held it.',
    gates: 'the_eclipsed_citadel',
  );

  // ---- equipment --------------------------------------------------------
  // ⭐ The Woodcarving ladder: Spiritwood is the rung above Ebony.
  // ⚠️ Crafted equipment leaves `properName` null so the material+form
  // grammar composes the name (ITEMS §9b.5a, and a test enforces it).
  // ⭐⭐ `socketCount: 2` — the top of §9b.6's range rather than the bottom,
  // and the crafted ladder's first pair (§4.1a of CELESTIAL; see the library
  // comment for what that section overstates).

  static const spiritwoodQuarterstaff = EquipmentDef(
    id: 'spiritwood_quarterstaff',
    rarity: Rarity.common,
    lore:
        'Cut from beside the road and shod at Rimeholt. It is lighter than '
        'it should be for how hard it hits.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Spiritwood',
    modifiers: ItemModifiers(
      damagePerCharge: 8,
      accuracyBonus: 12,
      critChance: 7,
      critDamage: 16,
    ),
    twoHanded: true,
    socketCount: 2,
    salvage: [SalvageYield('spiritwood_log', 1, 2)],
    equipLevel: 45,
    value: 3900,
  );

  static const spiritwoodWand = EquipmentDef(
    id: 'spiritwood_wand',
    rarity: Rarity.common,
    lore: 'Short, pale, and it does not warm to the hand the way wood does.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Spiritwood',
    modifiers: ItemModifiers(
      damagePerCast: 9,
      accuracyBonus: 5,
      critChance: 8,
      critDamage: 14,
    ),
    socketCount: 2,
    salvage: [SalvageYield('spiritwood_log', 1, 2)],
    equipLevel: 45,
    value: 3350,
  );

  static const spiritwoodKnot = EquipmentDef(
    id: 'spiritwood_knot',
    rarity: Rarity.common,
    lore:
        'A burl off a tree somebody was tending. It is the only part they '
        'did not straighten.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Spiritwood',
    modifiers: ItemModifiers(accuracyBonus: 7, critChance: 6),
    socketCount: 2,
    salvage: [SalvageYield('spiritwood_log', 1, 2)],
    equipLevel: 45,
    value: 2800,
  );

  /// ⭐ **The mini pool's rare chase, and the first half of Sanctus's
  /// affinity** (§2.5a): shield strength and healing received, together, on
  /// the first piece the player can find here.
  static const votivePendant = EquipmentDef(
    id: 'votive_pendant',
    properName: 'Votive Pendant',
    rarity: Rarity.rare,
    lore:
        'Left at a marker and taken by nobody for four hundred years, which '
        'is its own argument.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Spiritwood',
    modifiers: ItemModifiers(
      shieldStrengthPercent: 18,
      healingReceivedPercent: 12,
    ),
    salvage: [SalvageYield('spiritwood_log', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 47,
    value: 2400,
  );

  /// ⭐ **The zone's epic, boss-only**, and the same slot as the rare — a
  /// rare→epic ladder inside one zone. It adds flat HP to the support pair
  /// rather than a fourth axis, so the piece stays legible.
  /// ⚠️ **20% shield strength is the largest such number a player can wear.**
  static const theMaintainedRoad = EquipmentDef(
    id: 'the_maintained_road',
    properName: 'The Maintained Road',
    rarity: Rarity.epic,
    lore:
        'Whoever is doing the upkeep has not been seen, has not been '
        'thanked, and has not stopped.',
    slot: EquipSlot.neck,
    form: 'Icon',
    material: 'Spiritwood',
    modifiers: ItemModifiers(
      maxHpBonus: 45,
      shieldStrengthPercent: 20,
      healingReceivedPercent: 15,
    ),
    salvage: [SalvageYield('spiritwood_log', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 49,
    value: 6800,
  );

  /// ⚠️ **13 defs, where §4.1's table lists 12** — 2 materials + 3 motes +
  /// 2 consumables + **1 key** + 5 equipment. The key is the row §3.4 moved
  /// here and §4.1 never grew; see the library comment.
  static const all = <ItemDef>[
    spiritwoodLog,
    goldenrood,
    sanctusDust,
    sanctusShard,
    sanctusCrystal,
    climbersRation,
    goldenroodDraught,
    theKeptThird,
    spiritwoodQuarterstaff,
    spiritwoodWand,
    spiritwoodKnot,
    votivePendant,
    theMaintainedRoad,
  ];
}
