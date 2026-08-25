/// Everything the Windward Steppe can yield (Lv 19–24, Aero).
///
/// ⭐ Pure zone: two materials, per KINETIC_CONTRACT §3.1/§4.3. ⚠️ **Yew
/// equips at 20 here** — the weapon ladder's tier-3 wood (§9b.6) — and
/// **no crit anywhere in this catalogue**: crit stays off the crafted
/// tier-3 (Yew/Seawrack) entirely this quarter, arriving instead on Rowan
/// (equip 25, Thunderspire) per §2.5.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class WindwardSteppeItems {
  // ---- materials ------------------------------------------------------

  /// ✅ §9b.6 — the wood ladder's tier-3 log; Yew equips at 20.
  /// `value: 58` — ECONOMY_CONTRACT §8.2.
  static const yewLog = MaterialDef(
    id: 'yew_log',
    properName: 'Yew Log',
    rarity: Rarity.common,
    lore:
        'The only trees on the steppe, and every one of them leaning the '
        'same way. Cut with the lean, not against it, or the grain fights '
        'you the whole way through.',
    skill: CraftSkill.woodcarving,
    tier: 3,
    value: 58,
  );

  /// `value: 37` — ECONOMY_CONTRACT §8.2.
  static const tussockFlax = MaterialDef(
    id: 'tussock_flax',
    properName: 'Tussock Flax',
    rarity: Rarity.common,
    lore:
        'Wiry stalk grown low and dense, in tussocks that have learned to '
        'grow around each other rather than up. Tough as rope once it is '
        'stripped and dried.',
    skill: CraftSkill.tailoring,
    tier: 4,
    value: 37,
  );

  // ---- motes ----------------------------------------------------------
  //
  // ⭐ The Aero ladder, defined here per §3.2's rule — the mote lives with
  // the zone that first yields it. ⚠️ Frostfell Pass and Thunderspire Peaks
  // both drop these too: a hybrid yields both its parents' motes, so these
  // ids resolve catalogue-wide rather than zone-locally.

  static const aeroDust = MoteDef(
    id: 'aero_dust',
    properName: 'Aero Dust',
    rarity: Rarity.common,
    lore: 'What a moving thing leaves when the wind gets there first.',
    tier: MoteTier.dust,
    element: MagicElement.aero,
  );

  static const aeroShard = MoteDef(
    id: 'aero_shard',
    properName: 'Aero Shard',
    rarity: Rarity.common,
    lore: 'Dust that caught on something and stopped moving, briefly.',
    tier: MoteTier.shard,
    element: MagicElement.aero,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Closes the triplet begun
  /// by Flora Crystal ("warm") and Aqua Crystal ("cold") and continued by
  /// Pyro Crystal ("hot"): one sentence of the same shape, so the ladder
  /// reads as one object in every element rather than unrelated rocks.
  static const aeroCrystal = MoteDef(
    id: 'aero_crystal',
    properName: 'Aero Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is moving, and it does not stop.',
    tier: MoteTier.crystal,
    element: MagicElement.aero,
  );

  // ---- equipment: Woodcarving, Yew (§9b.6) -----------------------------

  static const yewQuarterstaff = EquipmentDef(
    id: 'yew_quarterstaff',
    rarity: Rarity.common,
    lore:
        'Straight-grained where the tree was not, because the carver chose '
        'the one branch that never learned to lean. Heavier than it looks.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Yew',
    modifiers: ItemModifiers(damagePerCharge: 3, accuracyBonus: 7),
    salvage: [SalvageYield('yew_log', 1, 2)],
    equipLevel: 20,
    value: 160,
  );

  static const yewWand = EquipmentDef(
    id: 'yew_wand',
    rarity: Rarity.common,
    lore:
        'Trimmed thin enough to whip in the wind and not break, which is '
        'the whole test a Yew wand has to pass before it is sold.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Yew',
    modifiers: ItemModifiers(damagePerCast: 4, accuracyBonus: 2),
    salvage: [SalvageYield('yew_log', 1, 1)],
    equipLevel: 20,
    value: 135,
  );

  static const yewKnot = EquipmentDef(
    id: 'yew_knot',
    rarity: Rarity.common,
    lore:
        'A burl carved from a lean-side branch, where the grain knots up '
        'from decades of holding against the same wind.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Yew',
    modifiers: ItemModifiers(accuracyBonus: 5),
    salvage: [SalvageYield('yew_log', 1, 1)],
    equipLevel: 20,
    value: 110,
  );

  // ---- equipment: the Tussock set (Tailoring) --------------------------
  //
  // ⭐ **The dodge/deflect debut, on the boots and gloves respectively** —
  // ITEMS §4.1a's affinity, Aero on boots (§2.5). ⭐ Tussock set total: 42 HP
  // · 4 acc · 3 dodge · 8/20 deflect (EV 1.6%).

  static const tussockHood = EquipmentDef(
    id: 'tussock_hood',
    rarity: Rarity.common,
    lore: 'Woven tight enough that the wind whistles instead of getting in.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Tussock',
    modifiers: ItemModifiers(accuracyBonus: 4),
    salvage: [SalvageYield('tussock_flax', 1, 2)],
    equipLevel: 24,
    value: 110,
  );

  static const tussockRobe = EquipmentDef(
    id: 'tussock_robe',
    rarity: Rarity.common,
    lore: 'Layered flax against the chest, thick enough to break a gust.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Tussock',
    modifiers: ItemModifiers(maxHpBonus: 20),
    salvage: [SalvageYield('tussock_flax', 3, 4)],
    equipLevel: 24,
    value: 170,
  );

  static const tussockLeggings = EquipmentDef(
    id: 'tussock_leggings',
    rarity: Rarity.common,
    lore: 'Cut long, so the hem does not catch and drag you sideways.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Tussock',
    modifiers: ItemModifiers(maxHpBonus: 14),
    salvage: [SalvageYield('tussock_flax', 2, 3)],
    equipLevel: 24,
    value: 140,
  );

  /// ⭐ **The game's first dodge (Tailoring boots).** ITEMS §4.1a's affinity:
  /// Aero is dodge, and boots are the slot the fantasy asks for (§2.5).
  static const tussockBoots = EquipmentDef(
    id: 'tussock_boots',
    rarity: Rarity.common,
    lore:
        'Soled thick and laced tight. Standing still in them still feels '
        'like leaning into something.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Tussock',
    modifiers: ItemModifiers(maxHpBonus: 4, dodge: 3),
    salvage: [SalvageYield('tussock_flax', 1, 2)],
    equipLevel: 24,
    value: 100,
  );

  /// ⭐ **The game's first crafted deflect (Tailoring gloves).** ITEMS
  /// §4.1a's affinity puts deflection on Geo, but a glove is still the
  /// piece you put in the way (§2.5) — Tussock carries the Aero set's own
  /// small taste of it.
  static const tussockGloves = EquipmentDef(
    id: 'tussock_gloves',
    rarity: Rarity.common,
    lore: 'Palms toughened from bracing against things that keep moving.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Tussock',
    modifiers: ItemModifiers(
      maxHpBonus: 4,
      deflectChance: 8,
      deflectAmount: 20,
    ),
    salvage: [SalvageYield('tussock_flax', 1, 2)],
    equipLevel: 24,
    value: 100,
  );

  // ---- the chases -------------------------------------------------------

  /// ⭐ **Rare — the mini-boss chase.** Dodge and a splash of accuracy,
  /// the same lane the Tussock boots teach.
  static const leanstoneCharm = EquipmentDef(
    id: 'leanstone_charm',
    properName: 'Leanstone Charm',
    rarity: Rarity.rare,
    lore:
        'A finger-length sliver worn from the windward face of a leaning '
        'stone. Held loosely, it wants to point the same direction every '
        'time.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Leanstone',
    modifiers: ItemModifiers(dodge: 6, accuracyBonus: 2),
    tradability: Tradability.untradeable,
    equipLevel: 22,
    value: 270,
  );

  /// ⭐ **Epic — the boss chase**, and the quarter's dodge epic (§2.5's
  /// distribution rule: dodge lives on the Aero jewelry and the Aero epic).
  /// ⚠️ **Competes with `tussock_robe` for the same slot**, deliberately —
  /// the epic is the reason to break your set, the shape Sporecap Mantle
  /// established in Q1.
  static const theLongLean = EquipmentDef(
    id: 'the_long_lean',
    properName: 'The Long Lean',
    rarity: Rarity.epic,
    lore:
        'Windgrass grown thick and combed flat, worn over the shoulders '
        'like the steppe itself decided to stop resisting for you instead. '
        'It has been leaning the same way since it was cut.',
    slot: EquipSlot.robeTop,
    form: 'Mantle',
    material: 'Windgrass',
    modifiers: ItemModifiers(maxHpBonus: 24, dodge: 8, accuracyBonus: 3),
    tradability: Tradability.untradeable,
    equipLevel: 24,
    value: 740,
  );

  static const all = <ItemDef>[
    yewLog,
    tussockFlax,
    aeroDust,
    aeroShard,
    aeroCrystal,
    yewQuarterstaff,
    yewWand,
    yewKnot,
    tussockHood,
    tussockRobe,
    tussockLeggings,
    tussockBoots,
    tussockGloves,
    leanstoneCharm,
    theLongLean,
  ];
}
