/// Everything the Cinderpeak Foothills can yield (Lv 6–11, Pyro).
///
/// ⭐ Pure zone: two materials. Copper is the first ⏳ **banking material**
/// (§9b.8) — gatherable from level 6, spendable when Forgeholm's
/// Metalworking opens at 15. The signposting matters: "you will want this
/// later" is a promise, not a tax.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class CinderpeakItems {
  // ---- materials ------------------------------------------------------

  /// ⏳ Banks for Q2. ⚠️ No Q1 recipe consumes it — by ruling, not omission.
  static const copperOre = MaterialDef(
    id: 'copper_ore',
    properName: 'Copper Ore',
    rarity: Rarity.common,
    lore:
        'The hills here rust green. Forgeholm pays for it by the sack and '
        'does not say what the hurry is.',
    skill: CraftSkill.metalworking,
    tier: 2,
  );

  /// The tier-2 hide.
  static const tuskhide = MaterialDef(
    id: 'tuskhide',
    properName: 'Tuskhide',
    rarity: Rarity.common,
    lore:
        'Scarred, singed, and thicker than a door. Whatever wears it walks '
        'through embers on purpose.',
    skill: CraftSkill.tailoring,
    tier: 2,
  );

  // ---- motes ----------------------------------------------------------
  //
  // ⭐ The Pyro ladder — the third element to get one, and the last of the
  // Primal three. ⚠️ Ashfall Vale drops these as well: a hybrid yields both
  // its parents' motes, so these ids resolve catalogue-wide rather than
  // zone-locally.

  static const pyroDust = MoteDef(
    id: 'pyro_dust',
    properName: 'Pyro Dust',
    rarity: Rarity.common,
    lore: 'What a burning thing leaves when it is put out before it finished.',
    tier: MoteTier.dust,
    element: MagicElement.pyro,
  );

  static const pyroShard = MoteDef(
    id: 'pyro_shard',
    properName: 'Pyro Shard',
    rarity: Rarity.common,
    lore: 'Dust that banked itself and went on quietly burning.',
    tier: MoteTier.shard,
    element: MagicElement.pyro,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Its lore closes the triplet
  /// begun by Flora Crystal ("warm") and Aqua Crystal ("cold"): three
  /// sentences of the same shape, which is what makes the ladder read as one
  /// object in three elements rather than three unrelated rocks.
  static const pyroCrystal = MoteDef(
    id: 'pyro_crystal',
    properName: 'Pyro Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is hot, and it does not cool.',
    tier: MoteTier.crystal,
    element: MagicElement.pyro,
  );

  // ---- equipment ------------------------------------------------------

  static const tuskhideBelt = EquipmentDef(
    id: 'tuskhide_belt',
    rarity: Rarity.common,
    lore: 'Two bottles and room for a third. The buckle outweighs the knife.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Tuskhide',
    modifiers: ItemModifiers(beltSlots: 2),
    salvage: [SalvageYield('tuskhide', 1, 2)],
    equipLevel: 11,
    value: 110,
  );

  /// ⭐ **The game's only crafted-adjacent crit source in Q1** (§9b.8): base
  /// crit is +50% damage, each crit-damage point adds one — this ring alone
  /// is a 5% chance of 155%. A preview of a Q2 mechanic, sold early by a
  /// mini-boss. ✅ Dropper: the mini table, authored for **The Emberqueen**;
  /// the pool shares one table, per the Whispering Woods shape.
  static const cinderLoop = EquipmentDef(
    id: 'cinder_loop',
    properName: 'Cinder Loop',
    rarity: Rarity.rare,
    lore:
        'A ring of char that never quite goes out. Wearing it feels like the '
        'moment before a pot boils over.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Cinder',
    modifiers: ItemModifiers(critChance: 5, critDamage: 5),
    tradability: Tradability.untradeable,
    equipLevel: 9,
    value: 220,
  );

  // ---- the gate ------------------------------------------------------

  /// ⭐ **The third and last of the *"three ordinary proofs"*.** With this one
  /// defined, Hearthwood's north road is a gate a player can actually open —
  /// one boss kill in each Primal pure zone, in any order.
  static const proofOfTheFoothills = KeyDef(
    id: 'proof_of_the_foothills',
    properName: 'Proof of the Foothills',
    rarity: Rarity.rare,
    lore:
        'A plate of black glass with the heat still somewhere inside it. The '
        'guard on the north road holds each one up to the light before he '
        'nods.',
    gates: 'hearthwood',
  );

  static const all = <ItemDef>[
    copperOre,
    tuskhide,
    pyroDust,
    pyroShard,
    pyroCrystal,
    tuskhideBelt,
    cinderLoop,
    proofOfTheFoothills,
  ];
}
