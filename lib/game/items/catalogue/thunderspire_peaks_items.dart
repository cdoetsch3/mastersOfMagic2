/// Everything Thunderspire Peaks can yield (Lv 23–28, Electro + Aero hybrid —
/// KINETIC_CONTRACT §4.5).
///
/// ⭐ Hybrid zone: **three** materials (§3.1, §9b.8 ruling 7) — Rowan Log
/// feeds Woodcarving, Iron Ore feeds Metalworking, Hum Quartz feeds
/// Enchanting and banks until Meridian (L36). ⚠️ **No motes are defined
/// here** — a hybrid drops its parents' mote families rather than owning any
/// of its own (§3.2); every `electro_*`/`aero_*` id this zone's drop tables
/// name resolves against `stormcliff_coast_items.dart` and
/// `windward_steppe_items.dart`.
///
/// ⭐ **Rowan is where crafting gets crit, and where sockets arrive** (§2.5,
/// §9b.6). Yew (Windward Steppe, equip 20) carries no crit at all — this is
/// the first *crafted* crit in the game, one quarter after the player first
/// *meets* crit on an enemy. Every Rowan piece also carries the wood ladder's
/// first gem socket, left empty on purpose (§6d gems are not this quarter).
///
/// ✅ **RULED — this zone gets an epic too (§8.7).** `groundfault_grips`,
/// named by Christian (2026-08-20), drops off the boss pool at equip 28.
library;

import '../item_def.dart';

abstract final class ThunderspirePeaksItems {
  // ---- materials ------------------------------------------------------

  /// ✅ §9b.6 — the wood ladder's tier-4 log; Rowan equips at 25.
  /// `value: 120` — ECONOMY_CONTRACT §8.2.
  static const rowanLog = MaterialDef(
    id: 'rowan_log',
    properName: 'Rowan Log',
    rarity: Rarity.common,
    lore:
        'Mountain ash above the treeline, which should not be possible — and '
        'yet here it stands, twisted hard by the wind and pale under the '
        'bark, one of the only living things taller than a person this high '
        'up.',
    skill: CraftSkill.woodcarving,
    tier: 4,
    value: 120,
  );

  /// `value: 12` — ECONOMY_CONTRACT §8.2.
  static const ironOre = MaterialDef(
    id: 'iron_ore',
    properName: 'Iron Ore',
    rarity: Rarity.common,
    lore:
        'Rust-red rock that the storm has been finding for a very long time '
        '— every vein runs true to where the last strike landed, and the '
        'next one will find it again.',
    skill: CraftSkill.metalworking,
    tier: 4,
    value: 12,
  );

  /// ⏳ Banks until Enchanting unlocks at Meridian, L36 — seeding Q3 exactly
  /// on schedule, the only Kinetic material that banks for that reason alone.
  /// `value: 20` — ECONOMY_CONTRACT §8.2 (no recipe consumer yet).
  static const humQuartz = MaterialDef(
    id: 'hum_quartz',
    properName: 'Hum Quartz',
    rarity: Rarity.uncommon,
    lore:
        'Quartz with a note in it. Strike it wrong and the note stops; '
        'strike it right and it rings on for longer than seems reasonable, '
        'held somewhere inside the crystal rather than in the air.',
    skill: CraftSkill.enchanting,
    tier: 4,
    value: 20,
  );

  // ---- intermediate goods -----------------------------------------------

  /// ⭐ Metalworking's tier-4 output, feeding the Rowan weapon recipes
  /// (§5.1) exactly as Bronze fed the Yew ones. `value: 52` — ECONOMY_CONTRACT
  /// §8.2. ⚠️ Never shop stock (§14b.3); vendorable, never on a shelf. ⚠️ Its
  /// own recipe (`craft_iron_ingot`: iron_ore×3 + charcoal×2 = 50) sits
  /// **under** this value — the same documented, contract-blessed boundary
  /// case as Bronze Ingot (§8.6). See `test/value_conservation_test.dart`.
  static const ironIngot = MaterialDef(
    id: 'iron_ingot',
    properName: 'Iron Ingot',
    rarity: Rarity.common,
    lore:
        'Ore gone into the crucible and come out true, holding a straighter '
        'edge than the rock it was cut from ever promised.',
    skill: CraftSkill.metalworking,
    tier: 4,
    value: 52,
  );

  // ---- equipment: Woodcarving, Rowan (§9b.6, §2.5) -----------------------
  //
  // ⭐ The first crafted crit in the game, and the wood ladder's first gem
  // socket — left empty on purpose, a promise the Celestial quarter keeps.

  static const rowanQuarterstaff = EquipmentDef(
    id: 'rowan_quarterstaff',
    rarity: Rarity.common,
    lore:
        'Cut from wood that spent its whole life arguing with the wind and '
        'never lost. Lighter than Yew, and it holds an edge of white light '
        'along the grain after a strike that takes a moment to fade.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Rowan',
    modifiers: ItemModifiers(
      damagePerCharge: 4,
      accuracyBonus: 8,
      critChance: 3,
      critDamage: 8,
    ),
    socketCount: 1,
    salvage: [SalvageYield('rowan_log', 1, 2)],
    equipLevel: 25,
    value: 330,
  );

  static const rowanWand = EquipmentDef(
    id: 'rowan_wand',
    rarity: Rarity.common,
    lore:
        'Trimmed thin and true from a straight run of grain, still faintly '
        'warm from wherever it was standing. The first wand in the game with '
        'somewhere to set a gem.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Rowan',
    modifiers: ItemModifiers(
      damagePerCast: 5,
      accuracyBonus: 3,
      critChance: 4,
      critDamage: 6,
    ),
    socketCount: 1,
    salvage: [SalvageYield('rowan_log', 1, 1)],
    equipLevel: 25,
    value: 280,
  );

  static const rowanKnot = EquipmentDef(
    id: 'rowan_knot',
    rarity: Rarity.common,
    lore:
        'A burl grown tight and hard where the tree fought a bad lean for '
        'years. Carved smooth on one face; the socket is cut into the other, '
        'where the grain runs deepest.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Rowan',
    modifiers: ItemModifiers(accuracyBonus: 6, critChance: 2),
    socketCount: 1,
    salvage: [SalvageYield('rowan_log', 1, 1)],
    equipLevel: 25,
    value: 230,
  );

  // ---- equipment: the chase -----------------------------------------------

  /// ⭐ **Its name is the zone** — it counts the intervals, and the intervals
  /// are getting shorter. Drop-only jewelry, the mini-boss chase.
  static const countstonePendant = EquipmentDef(
    id: 'countstone_pendant',
    properName: 'Countstone Pendant',
    rarity: Rarity.rare,
    lore:
        'A finger of Hum Quartz on a plaited cord that has never once gone '
        'quiet, its note quickening the closer the cloud overhead gets to '
        'lighting again. You learn to time your breathing to it.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Hum Quartz',
    modifiers: ItemModifiers(critChance: 10, critDamage: 12),
    tradability: Tradability.untradeable,
    equipLevel: 26,
    value: 300,
  );

  /// ⭐ **Thunderspire's epic, added by ruling (§8.7)**, named Groundfault
  /// Grips by Christian (2026-08-20). 📝 `accuracyBonus: 5, damagePerCast: 4`
  /// — the Electro identity is on-hit damage plus the accuracy to land it,
  /// in-band with the quarter's other epics. Dropper: the boss pool, equip
  /// 28, zone max, matching the other epics' top-of-band placement.
  static const groundfaultGrips = EquipmentDef(
    id: 'groundfault_grips',
    properName: 'Groundfault Grips',
    rarity: Rarity.epic,
    lore:
        'Gloves worn by whoever stood closest to the ground the last time it '
        'took the whole charge at once. The seams still carry a hairline of '
        'live white light, and they have never once let a strike through to '
        'the hand.',
    slot: EquipSlot.gloves,
    form: 'Grips',
    material: 'Groundfault',
    modifiers: ItemModifiers(accuracyBonus: 5, damagePerCast: 4),
    tradability: Tradability.untradeable,
    equipLevel: 28,
    value: 790,
  );

  static const all = <ItemDef>[
    rowanLog,
    ironOre,
    humQuartz,
    ironIngot,
    rowanQuarterstaff,
    rowanWand,
    rowanKnot,
    countstonePendant,
    groundfaultGrips,
  ];
}
