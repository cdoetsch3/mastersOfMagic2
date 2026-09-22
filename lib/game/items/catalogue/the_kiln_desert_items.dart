/// Everything The Kiln Desert can yield (Lv 30–34, Solar).
///
/// ⭐ **A pure zone: two materials** (ITEMS §9b.8 ruling 7) — Ironwood feeds
/// Woodcarving, Glasswort feeds Potions & Alchemy. ⚠️ **There is no cloth and
/// no hide here, deliberately** (CELESTIAL_CONTRACT §4.1): ITEMS §9b.6 assigns
/// this band's three woods to the Kiln Desert, the Mirrormere and the Sunless
/// Reach by name, and *"there is no cloth in the Kiln Desert because nothing
/// here is soft."* The roster's `hide` drop role therefore resolves to
/// `glasswort`, the zone's **second** gatherable material
/// (ETHEREAL_CONTRACT §3.5.1, which governs both quarters).
///
/// ⭐ **This file DEFINES the `solar_*` mote family** (§3.2 — the mote lives
/// with the zone that first yields it). The Sunless Reach and The Glass
/// Archive both drop `solar_*` and ⚠️ **must not re-define it**, exactly as
/// Frostfell imports `aqua_*` rather than authoring it.
///
/// ⭐ **`solar_essence` is a gate part, not crafting stock** (§3.4). Bound,
/// rare, kill-only, no node, guaranteed on the boss pool's `always` line, and
/// spent once by `craft_celestial_totem` at Meridian. ⚠️ It does **not** count
/// against the 2-per-pure-zone material budget — the `proof_of_the_woods`
/// precedent. 📝 `ComponentDef` is the arguably truer kind; ITEMS §3.5 defines
/// components as Tier III/IV set parts (L45+) and a level-30 gate essence is
/// not one. If Phase 8 broadens `ComponentDef`, move this.
///
/// ⭐ **`pilgrims_ration` and `glasswort_draught` are the quarter's shared
/// consumables and both live here** (§3.3) — the ration drops in all seven
/// Celestial zones on the `hardtack` pattern, and the draught is crafted #24
/// and drops from four of them. ⚠️ Sibling Celestial catalogues reference both
/// by id; this file is where they resolve.
///
/// ⚠️ **`ironwood_quarterstaff` lives here although its ferrule is Kinetic**
/// (§3.5) — a cross-zone crafted output belongs to the file for the zone
/// supplying its **headline** material.
///
/// 📝 **Phase 8 hook** (§3.6): the Kiln Desert is the obvious home for a
/// Solar accuracy enchant and for the first gem cut that fills the Ironwood
/// socket. ⚠️ No `setId`, no `setTier` and no gem item appears here — SYSTEMS
/// §3 has not ruled Phase 8, and `socketCount: 1` is a shipped field with a
/// shipped meaning, not a promise this file is making.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class KilnDesertItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ ITEMS §9b.6's wood for this zone, and it needs no reinterpretation —
  /// desert ironwood is a real Sonoran tree. Tier 5, Woodcarving, `equipLevel`
  /// left at the default: a log has no level.
  static const ironwoodLog = MaterialDef(
    id: 'ironwood_log',
    properName: 'Ironwood Log',
    rarity: Rarity.common,
    lore:
        'It does not float, it turns a saw, and it has been standing here '
        'since before the water left.',
    skill: CraftSkill.woodcarving,
    tier: 5,
    value: 240,
  );

  /// ⭐ A real salt-flat succulent, and the only wet thing for a day's walk —
  /// which is exactly what a first-aid herb should be here. ⚠️ It is also the
  /// zone's SECOND material and therefore what every `hide` role in this
  /// roster pays out (ETHEREAL_CONTRACT §3.5.1).
  static const glasswort = MaterialDef(
    id: 'glasswort',
    properName: 'Glasswort',
    rarity: Rarity.common,
    lore:
        'It holds one mouthful of water and gives it up bitter. Nobody who '
        'crosses here has ever said it tasted like anything but living.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 5,
    value: 28,
  );

  /// ⚠️ **Kill-only, no node, and not a crafting material** — the Rimeholt
  /// gate's Solar third (§3.4). Guaranteed on BOTH bosses' `always` line, so
  /// the boss a run happens to draw never decides whether progression is
  /// possible. `value: 0` because it is Bound and never vendorable.
  static const solarEssence = MaterialDef(
    id: 'solar_essence',
    properName: 'Solar Essence',
    rarity: Rarity.rare,
    lore: 'What is left of the sun after something has finished being it.',
    skill: CraftSkill.enchanting,
    tier: 6,
    tradability: Tradability.bound,
    value: 0,
  );

  // ---- motes ----------------------------------------------------------
  // ⭐ Values are ECONOMY §14c's, one per TIER and uniform across every
  // element: Dust 2 · Shard 25 · Crystal 150. ⚠️ Deliberately LOSSY against
  // the refinement ladder (a Shard vendors for less than its 50 Dust cost) so
  // refine-and-vendor can never profit.

  static const solarDust = MoteDef(
    id: 'solar_dust',
    properName: 'Solar Dust',
    rarity: Rarity.common,
    lore: 'Bright enough that you look at your hand and not at it.',
    tier: MoteTier.dust,
    element: MagicElement.solar,
    value: 2,
  );

  static const solarShard = MoteDef(
    id: 'solar_shard',
    properName: 'Solar Shard',
    rarity: Rarity.common,
    lore: 'Dust that held its shape long enough to cast a shadow.',
    tier: MoteTier.shard,
    element: MagicElement.solar,
    value: 25,
  );

  /// ⚠️ **Uncommon — mini-bosses and bosses only.** `uncommon` survives on
  /// Crystal motes and gem-grade materials and nowhere in equipment
  /// (CELESTIAL_CONTRACT §0.2 ruling 2).
  static const solarCrystal = MoteDef(
    id: 'solar_crystal',
    properName: 'Solar Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is bright, and it does not stop being bright.',
    tier: MoteTier.crystal,
    element: MagicElement.solar,
    value: 150,
  );

  // ---- consumables ----------------------------------------------------

  /// ⚠️ **`ConsumableDef`, NOT `BeltableDef`** — a Ration is not usable in a
  /// fight (ITEMS §9b.8 ruling 6). ⭐ Drop-only across all seven Celestial
  /// zones, the `hardtack` pattern; §3.3's ladder puts a Ration at 35% of the
  /// band floor's health, and 110 is 35.3% of a level-30 bar.
  static const pilgrimsRation = ConsumableDef(
    id: 'pilgrims_ration',
    properName: "Pilgrim's Ration",
    rarity: Rarity.common,
    lore:
        'Salt, fat and flour, pressed into a brick and wrapped in cloth. It '
        'is not food so much as an argument that you are not dead.',
    effect: ItemEffect(heal: 110),
    value: 16,
  );

  /// ⭐ **Draught = a flat heal that costs your turn**, so it beats a Ration
  /// (§3.3's ordering ruling): 125 is 40.1% of a level-30 bar. ⚠️ Its `value`
  /// is priced against §5.5's value conservation, **not** against the heal
  /// number — the 2026-09-21 `sapwort_draught` ruling says so explicitly.
  static const glasswortDraught = BeltableDef(
    id: 'glasswort_draught',
    properName: 'Glasswort Draught',
    rarity: Rarity.common,
    lore:
        'Green, saline and shockingly cold in a place with no cold in it. '
        'Pilgrims drink it standing, because sitting down out here is how it '
        'starts.',
    effect: ItemEffect(heal: 125),
    value: 55,
  );

  // ---- equipment --------------------------------------------------------
  // ⭐ The Woodcarving ladder, §4.1a: Ironwood is the rung above Rowan.
  // ⚠️ **The accuracy column stops climbing and the knot's goes DOWN**
  // (Rowan 6 → Ironwood 5) — §2.1a found that `hitChance` caps at 100, so
  // against a 0-dodge defender every point past +20 does nothing. The table
  // restores ITEMS §9b.8 ruling 2 (staff ≥ wand + knot) at every tier while
  // holding the crafted maximum to staff 12 + hood 6 = 18.
  // ⚠️ `socketCount: 1` — the BOTTOM of §9b.6's 0–1 range, floored at Rowan's
  // count. Gems are Phase 8 and an empty socket is still a promise; 📝 if
  // Phase 8 slips again, drop every socketCount in the quarter to 0 in one
  // edit, because nothing else depends on it.
  // ⚠️ Crafted equipment leaves `properName` null so the material+form
  // grammar composes the name (§3.5, and a test enforces it).

  static const ironwoodQuarterstaff = EquipmentDef(
    id: 'ironwood_quarterstaff',
    rarity: Rarity.common,
    lore:
        'Cut, cured and shod. It is heavier than it looks and it will be '
        'heavier still at the end of the day.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Ironwood',
    modifiers: ItemModifiers(
      damagePerCharge: 5,
      accuracyBonus: 9,
      critChance: 4,
      critDamage: 10,
    ),
    twoHanded: true,
    socketCount: 1,
    salvage: [SalvageYield('ironwood_log', 1, 2)],
    equipLevel: 30,
    value: 620,
  );

  static const ironwoodWand = EquipmentDef(
    id: 'ironwood_wand',
    rarity: Rarity.common,
    lore: 'Short, light, and shaped to be pointed rather than swung.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Ironwood',
    modifiers: ItemModifiers(
      damagePerCast: 6,
      accuracyBonus: 4,
      critChance: 5,
      critDamage: 8,
    ),
    socketCount: 1,
    salvage: [SalvageYield('ironwood_log', 1, 2)],
    equipLevel: 30,
    value: 530,
  );

  static const ironwoodKnot = EquipmentDef(
    id: 'ironwood_knot',
    rarity: Rarity.common,
    lore:
        'A burl left whole, because the grain in a burl goes every way at '
        'once and that turns out to matter.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Ironwood',
    modifiers: ItemModifiers(accuracyBonus: 5, critChance: 3),
    socketCount: 1,
    salvage: [SalvageYield('ironwood_log', 1, 2)],
    equipLevel: 30,
    value: 440,
  );

  /// ⭐ **The mini pool's rare chase.** Solar's gear affinity is accuracy
  /// (§2.5a), paired here with flat HP so the piece is legible without
  /// spending a stat the clamp has already eaten. ⚠️ No salvage: Kilnglass is
  /// a description, not a material this zone defines.
  static const theShadelessBand = EquipmentDef(
    id: 'the_shadeless_band',
    properName: 'The Shadeless Band',
    rarity: Rarity.rare,
    lore:
        'Worn by people who walked this in daylight on purpose. The inside '
        'is polished; the outside never has been.',
    slot: EquipSlot.ring,
    form: 'Band',
    material: 'Kilnglass',
    modifiers: ItemModifiers(accuracyBonus: 6, maxHpBonus: 18),
    tradability: Tradability.untradeable,
    equipLevel: 32,
    value: 620,
  );

  /// ⭐ **The zone's epic, boss-only** — and the quarter's opening statement
  /// about where weapon lines go: it is an Ironwood quarterstaff that beats
  /// the crafted one on every axis without leaving the ladder's shape.
  /// ⚠️ Its `accuracyBonus: 11` is two points over the crafted staff and
  /// still under §2.1a's useful ceiling; §7.5 budgets a full best-in-slot
  /// loadout to ≤ 30 accuracy and this is the piece that spends the most.
  static const theHardestEdge = EquipmentDef(
    id: 'the_hardest_edge',
    properName: 'The Hardest Edge',
    rarity: Rarity.epic,
    lore:
        'Your shadow is the hardest-edged thing you have ever seen, and '
        'someone has put a handle on it.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Ironwood',
    modifiers: ItemModifiers(
      damagePerCharge: 7,
      accuracyBonus: 11,
      critChance: 8,
      critDamage: 18,
    ),
    twoHanded: true,
    socketCount: 1,
    salvage: [SalvageYield('ironwood_log', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 34,
    value: 1750,
  );

  static const all = <ItemDef>[
    ironwoodLog,
    glasswort,
    solarEssence,
    solarDust,
    solarShard,
    solarCrystal,
    pilgrimsRation,
    glasswortDraught,
    ironwoodQuarterstaff,
    ironwoodWand,
    ironwoodKnot,
    theShadelessBand,
    theHardestEdge,
  ];
}
