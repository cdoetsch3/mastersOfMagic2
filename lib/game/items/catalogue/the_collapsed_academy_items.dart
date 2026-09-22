/// Everything The Collapsed Academy can yield (Lv 50–54, Arcane —
/// ETHEREAL_CONTRACT §4.5).
///
/// ⭐ **The end of the Woodcarving ladder, nine tiers after Oak.** Aetherwood
/// is the last wood ITEMS §9b.6 names, and ⚠️ **it is the only wood in the
/// game that is not a tree**: `world.dart` puts the Ethereal band above the
/// tree line and the Academy beyond the Veil entirely. ⭐ Aetherwood is the
/// timber of the staircases that arrive at rooms nobody built — cut to a plan
/// that kept going, and there is more of it than there was ever material for.
///
/// ⚠️⚠️ **`arcane_*` is NOT here, and that is the single most surprising fact
/// about this file.** The Glass Archive (43–47) yields Arcane first and
/// therefore defines the family (CELESTIAL §3.2, ETHEREAL §4.5), seven levels
/// below this zone. ⭐ **This is the only pure zone in the game that defines
/// no mote family.** A builder looking for Arcane Dust here will not find it,
/// and must not add it.
///
/// ⭐ **`the_written_third` lives here** (§3.4's reconciliation, and ENEMIES
/// §2e.1): one `KeyDef` per **pure** Ethereal zone, dropped by BOTH bosses on
/// `always`. ⚠️ §4.6 prints its lore and icon under The Reliquary Deep, where
/// the contract's first draft had placed it; the reconciliation moved the id
/// and left the lore block where it was written, so the text below is §4.6's
/// verbatim rather than re-authored here.
/// ⚠️ **`the_eclipsed_citadel.gateItemIds` must be
/// `['the_kept_third', 'the_dark_third', 'the_written_third']` in
/// `world.dart`** or the last door in the game is unlocked (§7.1). 📝 That is
/// a shared-file, three-lane edit this zone did not make — see the build
/// report.
///
/// ⭐ **Two materials, because a pure zone gets two** (ITEMS §9b.8), plus one
/// intermediate good. Aetherwood feeds Woodcarving, Mana Slag feeds
/// Metalworking, and `aethersteel_ingot` is Metalworking's **output** — a
/// crafted good with no node and no drop table, which is why nothing in the
/// bestiary names it.
///
/// ⭐ **Three sockets on every Aetherwood piece** — the full count §9b.6's
/// range allows at this tier, and ITEMS §3.4's set Tier IV (L50, Legendary)
/// makes this the widest Phase 8 surface any zone in the game offers.
/// ⚠️ No `setId`, no `setTier`, no enchant field and no gem appears here:
/// every piece is a plain Common so Phase 8 can add sets *beside* them rather
/// than instead of them (§3.6).
library;

import '../item_def.dart';

abstract final class CollapsedAcademyItems {
  // ---- materials --------------------------------------------------------

  /// Woodcarving, tier 9 — the last rung of the wood ladder. ⭐ Gathered at
  /// `ca_aetherwood_stair` and dropped by the stair-and-chalk commons.
  static const aetherwoodLog = MaterialDef(
    id: 'aetherwood_log',
    properName: 'Aetherwood Log',
    rarity: Rarity.common,
    lore:
        'Cut for a staircase that arrives somewhere nobody built. There is '
        'more of it than there was ever material for.',
    skill: CraftSkill.woodcarving,
    tier: 9,
    value: 2780,
  );

  /// Metalworking, tier 9. ⭐ **The zone's SECOND gatherable material, and
  /// therefore what its `hide` drop role resolves to** (§3.5 rule 1): the
  /// Academy has no kill-only hide, so "something died" pays in the school's
  /// own spill.
  static const manaSlag = MaterialDef(
    id: 'mana_slag',
    properName: 'Mana Slag',
    rarity: Rarity.common,
    lore:
        'What ran out of the floor when the school stopped. It is still warm '
        'at the centre of the heap.',
    skill: CraftSkill.metalworking,
    tier: 9,
    value: 215,
  );

  /// ⭐ Metalworking's **output**, not its input — smelted from `mana_slag`
  /// and feeding four recipes (§5.1). ⚠️ It has no gather node and appears on
  /// no drop table by design: an intermediate good the player *makes*. It is
  /// still a [MaterialDef], because what it is for is being consumed by a
  /// recipe.
  static const aethersteelIngot = MaterialDef(
    id: 'aethersteel_ingot',
    properName: 'Aethersteel Ingot',
    rarity: Rarity.common,
    lore:
        'Smelted out of the spill. It rings for about four seconds longer '
        'than it should.',
    skill: CraftSkill.metalworking,
    tier: 9,
    value: 640,
  );

  // ---- the gate ---------------------------------------------------------

  /// ⭐ **One of the three Ethereal fragments** (§3.4), and the one the
  /// Academy owes: *the last thing anyone wrote down*. ⚠️ **Gates are SHOWN,
  /// not spent** (ruling, 2026-09-21) — `gateItemIds` plus
  /// `PlayerProfile.openedGates`, the shipped Pennycross mechanism.
  ///
  /// ⚠️ Dropped by **both** bosses on the `always` line, never weighted: a run
  /// draws one boss of two, and a gate part off the boss you did not draw
  /// would be a coin flip on a mandatory item (§2e.1).
  ///
  /// ⚠️ `KeyDef` forces Bound and `value: 0` by construction, so the fragment
  /// is exempt from §5.4's value conservation rather than failing it.
  static const theWrittenThird = KeyDef(
    id: 'the_written_third',
    properName: 'The Written Third',
    rarity: Rarity.rare,
    lore:
        'It is warmer in the middle than at either end, and this is the '
        'middle.',
    gates: 'the_eclipsed_citadel',
  );

  // ---- equipment: Woodcarving, Aetherwood (§9b.6, §4.5) ------------------

  /// ⭐ **The best crafted main hand in the game**, and only a point or two
  /// under the zone's Epic — §2.6 finding 2 at its sharpest: at the top of
  /// the ladder a Master-crafted Common is very nearly the Epic.
  /// ⚠️ **`properName` stays null**: this is crafted, so its name is composed
  /// from material + form by the §9b.5a grammar rather than written down here
  /// where it could drift.
  static const aetherwoodQuarterstaff = EquipmentDef(
    id: 'aetherwood_quarterstaff',
    rarity: Rarity.common,
    lore: 'The last wood. There is nothing after this and the carvers know it.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Aetherwood',
    twoHanded: true,
    modifiers: ItemModifiers(
      damagePerCharge: 9,
      accuracyBonus: 12,
      critChance: 8,
      critDamage: 18,
    ),
    socketCount: 3,
    salvage: [SalvageYield('aetherwood_log', 1, 2)],
    equipLevel: 50,
    value: 7200,
  );

  static const aetherwoodWand = EquipmentDef(
    id: 'aetherwood_wand',
    rarity: Rarity.common,
    lore: 'Short, squared, and it does not taper so much as stop.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Aetherwood',
    modifiers: ItemModifiers(
      damagePerCast: 10,
      accuracyBonus: 5,
      critChance: 9,
      critDamage: 16,
    ),
    socketCount: 3,
    salvage: [SalvageYield('aetherwood_log', 1, 2)],
    equipLevel: 50,
    value: 6200,
  );

  static const aetherwoodKnot = EquipmentDef(
    id: 'aetherwood_knot',
    rarity: Rarity.common,
    lore: 'There should not be a burl in wood that was never a tree. There is.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Aetherwood',
    modifiers: ItemModifiers(accuracyBonus: 7, critChance: 7),
    socketCount: 3,
    salvage: [SalvageYield('aetherwood_log', 1, 2)],
    equipLevel: 50,
    value: 5200,
  );

  /// ⭐ The mini pool's Rare chase. ⚠️ **`deflectAmount: 8` looks tiny and is
  /// deliberate** (§2.1b): amount is the scarce resource, and this ring is a
  /// **chance-heavy** piece meant to be worn *with* the Unleft gloves rather
  /// than instead of them — gloves 26 + signet 8 = 34, which leaves room for
  /// a hat under the cap. 📝 If it reads as a weak Rare modifier (ITEMS
  /// §9b.6a: *"weak Rare modifiers are a balance bug, not flavour"*), swap
  /// the 8 for `critDamage: 20` and drop the deflection entirely.
  static const chalklineSignet = EquipmentDef(
    id: 'chalkline_signet',
    properName: 'Chalkline Signet',
    rarity: Rarity.rare,
    lore:
        'The syllabus is still on the wall. This is the seal that approved '
        'it.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Aethersteel',
    modifiers: ItemModifiers(
      deflectChance: 18,
      deflectAmount: 8,
      critChance: 8,
    ),
    salvage: [SalvageYield('aethersteel_ingot', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 52,
    value: 4400,
  );

  /// ⚠️ **Only marginally better than the crafted Aetherwood staff** (+1 dpc,
  /// +1 acc, −2 critDamage) and §4.5 says so in as many words. ⭐ **Its real
  /// advantage is that it is the only main hand a player can get without
  /// Woodcarving 50**, which is exactly what ITEMS §9b.6a means by *"rarity
  /// buys capability, and only secondarily power."* 📝 Widen the gap if that
  /// reads thin.
  static const theUnbuiltStair = EquipmentDef(
    id: 'the_unbuilt_stair',
    properName: 'The Unbuilt Stair',
    rarity: Rarity.epic,
    lore:
        'It arrives. What it arrives at was never built, and it arrives '
        'there anyway.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Aetherwood',
    twoHanded: true,
    modifiers: ItemModifiers(
      damagePerCharge: 10,
      accuracyBonus: 13,
      critChance: 8,
      critDamage: 16,
    ),
    socketCount: 3,
    tradability: Tradability.untradeable,
    equipLevel: 54,
    value: 12000,
  );

  /// ✅ **9 defs** — §4.5's eight-row catalogue table plus `the_written_third`,
  /// which §3.4's reconciliation moved here from The Reliquary Deep's list.
  /// 📝 §7.1's per-zone count still reads 8 / 13; the quarter's total of 79 is
  /// unchanged, because the id moved rather than appeared.
  static const all = <ItemDef>[
    aetherwoodLog,
    manaSlag,
    aethersteelIngot,
    theWrittenThird,
    aetherwoodQuarterstaff,
    aetherwoodWand,
    aetherwoodKnot,
    chalklineSignet,
    theUnbuiltStair,
  ];
}
