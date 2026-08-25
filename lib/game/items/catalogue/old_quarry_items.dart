/// Everything the Old Quarry can yield (Lv 15–19, Geo — KINETIC_CONTRACT
/// §4.1).
///
/// ⭐ Pure zone: two materials. Tin is the missing half of Bronze — Cinderpeak
/// banked Copper and Ashfall Vale banked Charcoal, and this is where the
/// promise pays off: copper + tin + charcoal → Bronze at Forgeholm, level 15,
/// the moment Metalworking opens.
///
/// ⭐ **The Overseer's Seal is the game's first deflection source**, dropped
/// by its namesake — the player meets deflection on the Plumbline Sentry and
/// then gets to wear it.
///
/// ⚠️ **No `geo_essence` here.** The Kinetic Sigil's collect-three-keys
/// mechanism is rejected this quarter (§3.3/§8.6) — no essence item, no key,
/// no gate collectible.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class OldQuarryItems {
  // ---- materials ------------------------------------------------------

  /// `value: 9` — ECONOMY_CONTRACT §8.2.
  static const tinOre = MaterialDef(
    id: 'tin_ore',
    properName: 'Tin Ore',
    rarity: Rarity.common,
    lore:
        'Grey ore veined bright where a chisel caught it wrong, common '
        'enough that the diggers barely bent down to pick it up.',
    skill: CraftSkill.metalworking,
    tier: 3,
    value: 9,
  );

  /// ⏳ Banks until Jewelry unlocks at Rimeholt, L45 — Q2 only *finds* jewel
  /// materials this quarter, per ruling. `value: 15` — ECONOMY_CONTRACT §8.2
  /// (no recipe consumer yet).
  static const quarryJasper = MaterialDef(
    id: 'quarry_jasper',
    properName: 'Quarry Jasper',
    rarity: Rarity.uncommon,
    lore:
        'Red banding cut square through a terrace face, squarer than '
        'anything the mountain grows on its own.',
    skill: CraftSkill.jewelry,
    tier: 3,
    value: 15,
  );

  // ---- motes ------------------------------------------------------------
  //
  // ⭐ The Geo ladder — first of the three Kinetic mote families, and it lives
  // with the zone that first yields it.

  static const geoDust = MoteDef(
    id: 'geo_dust',
    properName: 'Geo Dust',
    rarity: Rarity.common,
    lore: 'What breaks off a standing stone before the stone itself gives way.',
    tier: MoteTier.dust,
    element: MagicElement.geo,
  );

  static const geoShard = MoteDef(
    id: 'geo_shard',
    properName: 'Geo Shard',
    rarity: Rarity.common,
    lore: 'Dust that held its shape long enough to grow edges.',
    tier: MoteTier.shard,
    element: MagicElement.geo,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Closes the crystal-lore
  /// triplet begun by Flora Crystal ("warm") and Pyro Crystal ("hot"): three
  /// sentences of the same shape, so the ladder reads as one object in three
  /// elements.
  static const geoCrystal = MoteDef(
    id: 'geo_crystal',
    properName: 'Geo Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is heavy, and it does not get lighter.',
    tier: MoteTier.crystal,
    element: MagicElement.geo,
  );

  // ---- consumables --------------------------------------------------------

  /// ⚠️ **Not Beltable** — a between-encounters item, drop-only.
  static const hardtack = ConsumableDef(
    id: 'hardtack',
    properName: 'Hardtack',
    rarity: Rarity.common,
    lore:
        'Baked hard enough to survive a quarry cart, and eaten the same '
        'way — in pieces, with effort.',
    effect: ItemEffect(healPercent: 35),
    value: 9,
  );

  // ---- intermediate goods -------------------------------------------------

  /// ⭐ **Feeds four recipes.** Copper (Cinderpeak) and Charcoal (Ashfall
  /// Vale) banked with no Q1 recipe; Tin is the missing half, and this is the
  /// first Kinetic recipe a player meets: copper + tin + charcoal → Bronze,
  /// at Forgeholm, the moment Metalworking opens at 15.
  /// `value: 32` — ECONOMY_CONTRACT §8.2. ⚠️ Never shop stock (§14b.3 — "no
  /// ingots stocked, smelting is Metalworking's reason to exist");
  /// vendorable, never on a shelf. ⚠️ Its own recipe (`craft_bronze_ingot`:
  /// copper_ore×2 + tin_ore×1 + charcoal×1 = 30) sits **under** this value —
  /// a documented, contract-blessed boundary case (§8.6: "Σ=output, zero
  /// headroom"), not a clean pass. See `test/value_conservation_test.dart`'s
  /// exemption list.
  static const bronzeIngot = MaterialDef(
    id: 'bronze_ingot',
    properName: 'Bronze Ingot',
    rarity: Rarity.common,
    lore:
        'Copper and tin gone into the crucible together and come out '
        'neither, holding an edge better than either one alone.',
    skill: CraftSkill.metalworking,
    tier: 3,
    value: 32,
  );

  // ---- equipment ------------------------------------------------------

  /// ⭐ **The item ITEMS §9b.8 ruling 9 explicitly deferred to this
  /// quarter, dropped by its namesake.** It is also the game's first
  /// deflection source, which is the right hand-off: the player meets
  /// deflection on the Plumbline Sentry and then gets to wear it.
  static const overseersSeal = EquipmentDef(
    id: 'overseers_seal',
    properName: "Overseer's Seal",
    rarity: Rarity.rare,
    lore:
        'A signet worn smooth in one groove and sharp everywhere else, '
        'exactly like something used to press its will into stone and '
        'nothing else.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Bronze',
    modifiers: ItemModifiers(deflectChance: 12, deflectAmount: 20),
    tradability: Tradability.untradeable,
    equipLevel: 18,
    value: 260,
  );

  /// ⭐ **The quarter's HP epic** — 30 flat HP is 15% of a level-19 player's
  /// bar, and its lore is the whole zone: the hole knows exactly what came
  /// out of it.
  static const theGivenWeight = EquipmentDef(
    id: 'the_given_weight',
    properName: 'The Given Weight',
    rarity: Rarity.epic,
    lore:
        'The precise mass the hole is missing, worn on a chain, and heavier '
        'than its size has any right to be.',
    slot: EquipSlot.neck,
    form: 'Locket',
    material: 'Quarrystone',
    modifiers: ItemModifiers(
      maxHpBonus: 30,
      deflectChance: 10,
      deflectAmount: 25,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 19,
    value: 720,
  );

  static const all = <ItemDef>[
    tinOre,
    quarryJasper,
    geoDust,
    geoShard,
    geoCrystal,
    hardtack,
    bronzeIngot,
    overseersSeal,
    theGivenWeight,
  ];
}
