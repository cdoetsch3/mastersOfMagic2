/// Everything The Eclipsed Citadel can yield (Lv 58–60, all twelve —
/// ETHEREAL_CONTRACT §4.8).
///
/// ⭐ **Three rulings shape this file, and they are all one idea: an
/// obstruction is not a landscape.**
///
/// 1. ⚠️⚠️ **Two materials, both kill-only, and the zone has NO gather node**
///    (§3.1). Ruling 7 would read *"all twelve, therefore hybrid, therefore
///    three materials"* — but ruling 7 counts **what the ground holds**, and
///    the Citadel is not ground. ⭐ Nothing grows on an obstruction, nothing is
///    mined out of it, and there is no seam to work; what it yields, it yields
///    because you took it off the thing standing in the door. ⚠️ **No entry
///    here may ever acquire a `GatherNodeDef`** — the zone suite asserts it.
/// 2. ⭐⭐ **No mote family.** The Citadel defines none and pays in **all
///    twelve** (§3.5.2), which is the only mechanical statement available for
///    *"all twelve at once"* that does not require twelve new items. ⚠️ A
///    builder looking for a `citadel_dust` will not find one, and that is
///    correct.
/// 3. ⭐ **Two epics, not one.** Every other zone in four quarters gets exactly
///    one. The Citadel gets two because it is the last content in the game and
///    because its two materials are each the headline of one of them. ⚠️ They
///    occupy different slots, so a player who clears it enough times wears
///    both — the choice is **which one first**, and it will be the last gear
///    decision anyone makes.
///
/// ⭐ **`eclipse_ring`, `the_last_thing_in_the_way` and `the_corona` are the
/// only equipLevel-60 items in the game.** Everything else a level-60 mage
/// wears was made or found lower down; these three are the only things that
/// require the cap itself.
///
/// ⚠️ **No key, and no gate item.** §3.4's three fragments open the Citadel;
/// the Citadel's own exit leads to Zenith, whose gate is out of scope (§3.4a)
/// and whose Concordant Crown is blocked on Core/Heart motes (§3.2). ⭐ The
/// last zone in the game therefore defines the **fewest** kinds of thing of
/// any zone: two materials and five pieces of gear.
///
/// 📝 **Phase 8 hook — everything, and that is the point.** This is where ITEMS
/// §3.4's set Tier IV (Legendary) would be earned and where the Crown's twelve
/// gems would be set. ⚠️ **This file ships neither Mythic nor Legendary**, and
/// the two epics below are written so that a Legendary can be added *above*
/// them without re-tuning anything underneath.
library;

import '../item_def.dart';

abstract final class EclipsedCitadelItems {
  // ---- materials --------------------------------------------------------
  //
  // ⚠️ **Both kill-only, both Jewelry tier 10, and neither has a node.** They
  // are also the zone's two drop ROLES (§3.5.2): `material` → eclipse_iron,
  // `hide` → corona_pearl. ⭐ §3.5.1's "a hide role with no hide item falls
  // back to the zone's second gatherable material" does not apply, because
  // there is no gatherable material here at all — the pearl IS the fallback,
  // and it is taken off the same body.

  /// ⭐ The `material` role, and the headline of both eclipse-iron epics.
  /// ⚠️ Uncommon, which is the gem grade — `uncommon` survives on gem-grade
  /// materials and Crystal motes and nowhere else in this quarter (§0.2).
  static const eclipseIron = MaterialDef(
    id: 'eclipse_iron',
    properName: 'Eclipse Iron',
    rarity: Rarity.uncommon,
    lore:
        'Off the thing in the door. It is cold in a way iron is not and it '
        'does not take a shine.',
    skill: CraftSkill.jewelry,
    tier: 10,
    value: 1000,
  );

  /// ⭐ The `hide` role — *"it came off the same thing"* — resolved to a
  /// material rather than a hide, because the Citadel has nothing to skin.
  static const coronaPearl = MaterialDef(
    id: 'corona_pearl',
    properName: 'Corona Pearl',
    rarity: Rarity.uncommon,
    lore:
        'The ring of light around a thing that is in the way. It came off '
        'the same thing.',
    skill: CraftSkill.jewelry,
    tier: 10,
    value: 900,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ **The end of the Jewelry ladder, and it is a Common** — ITEMS §9b.6a's
  /// lattice at its clearest: maxed flat stats, and structurally unable to
  /// carry a modifier. ⚠️ **`properName` stays null**: this is crafted (§5),
  /// so its name composes from material + form by the §9b.5a grammar rather
  /// than being written down here where it could drift.
  static const coronaTorc = EquipmentDef(
    id: 'corona_torc',
    rarity: Rarity.common,
    lore:
        'A neck ring, open at the front, because a torc is a thing you are '
        'given rather than a thing you buy.',
    slot: EquipSlot.neck,
    form: 'Torc',
    material: 'Corona Pearl',
    modifiers: ItemModifiers(maxHpBonus: 45, critChance: 5, accuracyBonus: 3),
    salvage: [SalvageYield('corona_pearl', 1, 2)],
    equipLevel: 58,
    value: 3400,
  );

  /// ⭐ **The last thing anybody in this world learned how to make**, and the
  /// first of the three items that require level 60 itself. ⚠️ Crafted, so
  /// `properName` is null for the same reason as the torc.
  static const eclipseRing = EquipmentDef(
    id: 'eclipse_ring',
    rarity: Rarity.common,
    lore:
        'Plain, black, and it is the last thing anybody in this world '
        'learned how to make.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Eclipse Iron',
    modifiers: ItemModifiers(damagePerCast: 7, critChance: 6, critDamage: 12),
    salvage: [SalvageYield('eclipse_iron', 1, 2)],
    equipLevel: 60,
    value: 3950,
  );

  /// ⭐ The mini pool's Rare chase, and the boss table's consolation. A
  /// legible three-line combination and nothing exotic.
  static const theEclipsedBand = EquipmentDef(
    id: 'the_eclipsed_band',
    properName: 'The Eclipsed Band',
    rarity: Rarity.rare,
    lore:
        'It has been between something and something else for a very long '
        'time.',
    slot: EquipSlot.ring,
    form: 'Band',
    material: 'Eclipse Iron',
    modifiers: ItemModifiers(maxHpBonus: 60, dodge: 6, critChance: 8),
    tradability: Tradability.untradeable,
    equipLevel: 58,
    value: 7800,
  );

  /// ⭐⭐ **The offensive half of the last gear decision in the game** — the
  /// whole offensive budget of the fight in one slot. ⚠️ It is not much
  /// stronger in raw numbers than the Commons beside it (§2.6 finding 2); it
  /// is better because **rarity buys capability**, not size.
  static const theLastThingInTheWay = EquipmentDef(
    id: 'the_last_thing_in_the_way',
    properName: 'The Last Thing in the Way',
    rarity: Rarity.epic,
    lore: 'It stopped everyone. Then it stopped.',
    slot: EquipSlot.gloves,
    form: 'Gauntlets',
    material: 'Eclipse Iron',
    modifiers: ItemModifiers(
      damagePerCast: 14,
      accuracyBonus: 6,
      critChance: 10,
      critDamage: 10,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 60,
    value: 22000,
  );

  /// ⭐⭐ The defensive half, and the other end of the same choice.
  ///
  /// ⚠️⚠️ **`deflectAmount: 14` is not a free number.** §2.1b: the worst legal
  /// assembly across all four quarters is `unleft_gloves` 26 + a deflect hat 14
  /// + `bedrock_greaves` 10 = **exactly 50**, which is ITEMS §4.1a's player
  /// cap. **Raising this by one breaks a design invariant thirty levels away.**
  static const theCorona = EquipmentDef(
    id: 'the_corona',
    properName: 'The Corona',
    rarity: Rarity.epic,
    lore:
        'You see it from below, all the way up the mountain, and you take '
        'it off the thing that was wearing it.',
    slot: EquipSlot.hat,
    form: 'Coronet',
    material: 'Corona Pearl',
    modifiers: ItemModifiers(
      maxHpBonus: 70,
      deflectChance: 16,
      deflectAmount: 14,
      shieldStrengthPercent: 12,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 60,
    value: 24000,
  );

  /// ✅ **7 defs** — §4.8's count for this zone: 2 materials + 5 equipment.
  /// ⚠️ No motes, no consumables, no key: see the library note.
  static const all = <ItemDef>[
    eclipseIron,
    coronaPearl,
    coronaTorc,
    eclipseRing,
    theEclipsedBand,
    theLastThingInTheWay,
    theCorona,
  ];
}
