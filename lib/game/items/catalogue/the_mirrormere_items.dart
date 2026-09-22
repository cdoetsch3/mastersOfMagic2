/// Everything The Mirrormere can yield (Lv 32–37, Lunar) —
/// CELESTIAL_CONTRACT §4.2.
///
/// ⭐ **The quarter's largest catalogue (16 defs)**, because this zone carries
/// **both** a wood tier and an armour set — the same shape Windward Steppe
/// had.
///
/// ⭐ **The `lunar_*` mote family is DEFINED here** (§3.2): the mote lives
/// with the zone that first yields it, and The Mirrormere is Lunar's one pure
/// region. ⚠️ Tidewrack Shoals and The Sunless Reach both pay in `lunar_*`
/// and must **import** them, exactly as Frostfell imports `aqua_*`.
///
/// ⭐ **Bloodwood is ITEMS §9b.6's wood here** — *"deep red heartwood under a
/// blood moon, mirrored in the lake."* Its §9b.6 socket range is 1–2 and
/// §4.1a spends **1**: a crafted common takes the bottom of its wood's range,
/// floored at the previous tier's count. ⚠️ Gems are Phase 8 and an empty
/// socket is still a promise, which is why the count stays flat at Rowan's.
///
/// ⭐ **Mirrorflax is the quarter's first armour fibre**, retted in the lake —
/// the only way to get a flax that shows you yourself. Set total: **49 HP · 5
/// acc · 4 dodge · 10/20 deflect**, which against the level-34 baseline is
/// +13.4% health.
///
/// ⚠️ **`lunar_essence` is a gate part, not crafting stock** (§3.4). Bound,
/// kill-only, no node, guaranteed on both bosses, and ⚠️ it does **not** count
/// against §9b.8 ruling 7's two-materials-per-pure-zone budget — the same
/// exemption the Q1 proofs hold.
///
/// ⭐ **Lunar's gear affinity is dodge (§2.5a) and both drop-only pieces carry
/// it**, which is how a player learns the element's identity without reading a
/// table.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class MirrormereItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ Woodcarving tier 6, the third rung of ITEMS §9b.6's five-wood ladder
  /// for this band (Ironwood 30 → **Bloodwood 35** → Ebony 40).
  static const bloodwoodLog = MaterialDef(
    id: 'bloodwood_log',
    properName: 'Bloodwood Log',
    rarity: Rarity.common,
    lore:
        'Cut it at noon and it is brown. Cut it when the moon is on the '
        'water and it is not.',
    skill: CraftSkill.woodcarving,
    tier: 6,
    value: 450,
  );

  /// ⭐ The zone's **second** gatherable material, which is also where the
  /// roster's `hide` role lands (ETHEREAL_CONTRACT §3.5.1) — The Mirrormere
  /// defines no kill-only hide, so "something died" pays in the zone's stuff.
  static const mirrorflax = MaterialDef(
    id: 'mirrorflax',
    properName: 'Mirrorflax',
    rarity: Rarity.common,
    lore:
        'Retted in the lake and dried on the shore. Held up, a hank of it '
        'shows you the back of your own head.',
    skill: CraftSkill.tailoring,
    tier: 5,
    value: 88,
  );

  /// ⚠️ **Bound, kill-only, no node** — one of the three essences the
  /// Celestial Totem is crafted from at Meridian (§3.4). `value: 0`: a gate
  /// part is shown at Rimeholt and spent by a recipe, never sold.
  static const lunarEssence = MaterialDef(
    id: 'lunar_essence',
    properName: 'Lunar Essence',
    rarity: Rarity.rare,
    lore: 'Something down there finished being the moon and this stayed.',
    skill: CraftSkill.enchanting,
    tier: 6,
    tradability: Tradability.bound,
  );

  // ---- motes: the Lunar family, defined here (§3.2) --------------------

  static const lunarDust = MoteDef(
    id: 'lunar_dust',
    // ⭐ Ruled 2026-08-25: one vendor value per TIER, uniform across all
    // elements, LOSSY against the refinement ladder (a Shard vendors for
    // less than its 50 Dust cost) so refine-and-vendor can never profit.
    value: 2,
    properName: 'Lunar Dust',
    rarity: Rarity.common,
    lore: 'Cold, and it lies flat however you pour it.',
    tier: MoteTier.dust,
    element: MagicElement.lunar,
  );

  static const lunarShard = MoteDef(
    id: 'lunar_shard',
    value: 25,
    properName: 'Lunar Shard',
    rarity: Rarity.common,
    lore: 'You can see the room in it, slightly further away than the room is.',
    tier: MoteTier.shard,
    element: MagicElement.lunar,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Keeps the Crystal
  /// one-sentence shape the ladder has held since Flora ("warm") and Aqua
  /// ("cold"), so the rung reads as one object in every element.
  static const lunarCrystal = MoteDef(
    id: 'lunar_crystal',
    value: 150,
    properName: 'Lunar Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is cold, and it does not stop being cold.',
    tier: MoteTier.crystal,
    element: MagicElement.lunar,
  );

  // ---- equipment: Woodcarving, Bloodwood (§9b.6, §4.1a) ----------------
  //
  // ⭐ The ladder's accuracy column is restored at this tier: staff 10 ≥ wand
  // 4 + knot 6, which is §9b.8 ruling 2's *"the staff out-accurates wand and
  // knot combined"* — the shipped Rowan broke it and §4.1a puts it back.

  static const bloodwoodQuarterstaff = EquipmentDef(
    id: 'bloodwood_quarterstaff',
    rarity: Rarity.common,
    lore: 'Heavy, dark, and warm to hold for no reason anyone has explained.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Bloodwood',
    twoHanded: true,
    modifiers: ItemModifiers(
      damagePerCharge: 6,
      accuracyBonus: 10,
      critChance: 5,
      critDamage: 12,
    ),
    socketCount: 1,
    salvage: [SalvageYield('bloodwood_log', 1, 2)],
    equipLevel: 35,
    value: 1150,
  );

  static const bloodwoodWand = EquipmentDef(
    id: 'bloodwood_wand',
    rarity: Rarity.common,
    lore: 'A finger\'s length of heartwood and nothing else.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Bloodwood',
    modifiers: ItemModifiers(
      damagePerCast: 7,
      accuracyBonus: 4,
      critChance: 6,
      critDamage: 10,
    ),
    socketCount: 1,
    salvage: [SalvageYield('bloodwood_log', 1, 1)],
    equipLevel: 35,
    value: 990,
  );

  static const bloodwoodKnot = EquipmentDef(
    id: 'bloodwood_knot',
    rarity: Rarity.common,
    lore: 'Where a branch tried to leave and the tree said no.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Bloodwood',
    modifiers: ItemModifiers(accuracyBonus: 6, critChance: 4),
    socketCount: 1,
    salvage: [SalvageYield('bloodwood_log', 1, 1)],
    equipLevel: 35,
    value: 820,
  );

  // ---- equipment: the Mirrorflax set (Tailoring) -----------------------

  static const mirrorflaxHood = EquipmentDef(
    id: 'mirrorflax_hood',
    rarity: Rarity.common,
    lore:
        'Cut straight, sewn straight, and the brim is a dead level line on '
        'purpose.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(accuracyBonus: 5),
    salvage: [SalvageYield('mirrorflax', 1, 2)],
    equipLevel: 34,
    value: 265,
  );

  static const mirrorflaxRobe = EquipmentDef(
    id: 'mirrorflax_robe',
    rarity: Rarity.common,
    lore: 'Layered four deep. In still air it hangs like water.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(maxHpBonus: 23),
    salvage: [SalvageYield('mirrorflax', 3, 4)],
    equipLevel: 34,
    value: 530,
  );

  static const mirrorflaxLeggings = EquipmentDef(
    id: 'mirrorflax_leggings',
    rarity: Rarity.common,
    lore: 'Quilted, because the shore is stone and the stone is cold.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(maxHpBonus: 16),
    salvage: [SalvageYield('mirrorflax', 2, 3)],
    equipLevel: 34,
    value: 440,
  );

  /// ⭐ **Lunar's affinity is dodge (§2.5a)**, and the set's taste of it sits
  /// on the boots — the slot the fantasy asks for, the same placement the
  /// Tussock set established for Aero.
  static const mirrorflaxBoots = EquipmentDef(
    id: 'mirrorflax_boots',
    rarity: Rarity.common,
    lore:
        'Soft-soled. You will not hear yourself and neither will anything '
        'else.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(maxHpBonus: 5, dodge: 4),
    salvage: [SalvageYield('mirrorflax', 1, 2)],
    equipLevel: 34,
    value: 265,
  );

  /// ⭐ EV 2.0% — deflect chance × amount, the §2.1b reading. A glove is the
  /// piece you put in the way.
  static const mirrorflaxGloves = EquipmentDef(
    id: 'mirrorflax_gloves',
    rarity: Rarity.common,
    lore: 'Palms doubled. The hand is the piece you put in the way.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(
      maxHpBonus: 5,
      deflectChance: 10,
      deflectAmount: 20,
    ),
    salvage: [SalvageYield('mirrorflax', 1, 2)],
    equipLevel: 34,
    value: 265,
  );

  // ---- the chases -------------------------------------------------------

  /// ⭐ **Rare — the mini-boss chase**, and Lunar's dodge stated plainly.
  /// ⚠️ Merestone is the charm's material, not a craftable one: this is
  /// drop-only jewelry, so it sets `properName` (§3.5).
  static const theWaningCharm = EquipmentDef(
    id: 'the_waning_charm',
    properName: 'The Waning Charm',
    rarity: Rarity.rare,
    lore:
        'It was a full ring once. Everyone who has owned it says so and none '
        'of them can say when it stopped.',
    slot: EquipSlot.ring,
    form: 'Charm',
    material: 'Merestone',
    modifiers: ItemModifiers(dodge: 9, maxHpBonus: 16),
    tradability: Tradability.untradeable,
    equipLevel: 35,
    value: 780,
  );

  /// ⭐ **Epic — the boss chase.** ⚠️ **Competes with `mirrorflax_robe` for
  /// the same slot, deliberately** — the epic is the reason to break your
  /// set, the shape Sporecap Mantle established in Q1 and The Long Lean
  /// continued in Q2.
  static const theLargerReflection = EquipmentDef(
    id: 'the_larger_reflection',
    properName: 'The Larger Reflection',
    rarity: Rarity.epic,
    lore:
        'It fits. It has always fitted. In the water it is a size larger and '
        'it fits there too.',
    slot: EquipSlot.robeTop,
    form: 'Mantle',
    material: 'Mirrorflax',
    modifiers: ItemModifiers(maxHpBonus: 40, dodge: 6),
    tradability: Tradability.untradeable,
    equipLevel: 37,
    value: 2200,
  );

  static const all = <ItemDef>[
    bloodwoodLog,
    mirrorflax,
    lunarEssence,
    lunarDust,
    lunarShard,
    lunarCrystal,
    bloodwoodQuarterstaff,
    bloodwoodWand,
    bloodwoodKnot,
    mirrorflaxHood,
    mirrorflaxRobe,
    mirrorflaxLeggings,
    mirrorflaxBoots,
    mirrorflaxGloves,
    theWaningCharm,
    theLargerReflection,
  ];
}
