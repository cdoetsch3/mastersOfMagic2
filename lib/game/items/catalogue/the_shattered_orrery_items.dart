/// Everything The Shattered Orrery can yield (Lv 40–44, Astral + Electro).
///
/// ⭐ **The only zone in either quarter whose materials are all salvage**
/// (CELESTIAL_CONTRACT §4.6). Nothing grew here and nothing fell here — it was
/// *built*, and then it broke. Orrery Scrap feeds Metalworking, Arcsalt feeds
/// Potions & Alchemy, Sidereal Glass feeds Jewelry, all at tier 7.
///
/// ⭐ **The quarter's smallest catalogue, at 7, and that is correct.** The
/// Orrery has no wood, no cloth and no hide; it is a machine being scavenged.
/// Frostfell Pass and The Molten Deep shipped 6 each for the same reason.
///
/// ⭐ **No motes defined here.** A hybrid never defines a mote family (§3.2)
/// and both of this one's parents already have theirs — `astral_*` lives with
/// Starfall Basin, `electro_*` with Stormcliff Coast, a **Q2** file. The
/// Orrery drops both and defines neither.
///
/// ⏳ **`sidereal_glass` banks until Rimeholt (L45)**, where Jewelry opens —
/// the same shape Frostfell's Everice has, one quarter later. It is one of the
/// four materials §7.4 names as deliberately unconsumed in this quarter.
///
/// 📝 **Phase 8 hook.** The Orrery is where a **socket** should first be
/// something other than a promise: the mechanism is already full of set
/// stones. ⚠️ No `socketCount` is authored here — the hook is a note, not a
/// definition (§3.6).
library;

import '../item_def.dart';

abstract final class ShatteredOrreryItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ The zone's headline material and the input to `starbrass_ingot`.
  /// Mined off the fallen rings at `so_scrap_ring` and shed by everything
  /// made of the mechanism.
  static const orreryScrap = MaterialDef(
    id: 'orrery_scrap',
    properName: 'Orrery Scrap',
    rarity: Rarity.common,
    lore:
        'A tooth off a gear the size of a door. Whatever it was counting, it '
        'is one short now.',
    skill: CraftSkill.metalworking,
    tier: 7,
    value: 48,
  );

  /// ⭐ Foraged rather than mined, and the one thing in the zone that is not
  /// metal — it is what four centuries of earthing left behind.
  static const arcsalt = MaterialDef(
    id: 'arcsalt',
    properName: 'Arcsalt',
    rarity: Rarity.common,
    lore:
        'White crust where the machine has been earthing itself for four '
        'hundred years. It tastes like a held breath.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 7,
    value: 32,
  );

  /// ⏳ Banks until Jewelry opens at Rimeholt (L45, §7.4) — ⚠️ **deliberately
  /// unconsumed this quarter**, alongside `nacre`, `eclipse_opal` and
  /// `aetherglass`, and a test asserts all four stay that way.
  static const siderealGlass = MaterialDef(
    id: 'sidereal_glass',
    properName: 'Sidereal Glass',
    rarity: Rarity.uncommon,
    lore:
        'A lens out of a fallen ring. It still focuses. On what, nobody has '
        'stood in front of long enough to say.',
    skill: CraftSkill.jewelry,
    tier: 7,
    value: 160,
  );

  /// ⭐ Remelted mechanism — the zone's intermediate good, and the material
  /// both of its named drops are made of. ⚠️ Its recipe belongs to the
  /// quarter's recipe lane, not to this file.
  static const starbrassIngot = MaterialDef(
    id: 'starbrass_ingot',
    properName: 'Starbrass Ingot',
    rarity: Rarity.common,
    lore:
        'Remelted mechanism. It takes a finer thread than anything you could '
        'buy in Concordance.',
    skill: CraftSkill.metalworking,
    tier: 7,
    value: 200,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Draught form, same shape as every tonic and draught below it — a
  /// turn spent drinking is a turn not casting, so a heal can be baited.
  /// ⚠️ Drop-only from the Automaton's table and craftable by the recipe
  /// lane; it is the Glass Archive's draught too (§7.3).
  static const arcsaltDraught = BeltableDef(
    id: 'arcsalt_draught',
    properName: 'Arcsalt Draught',
    rarity: Rarity.common,
    lore:
        'Sharp, metallic, and it makes your teeth ring. Whatever it is doing, '
        'it does it fast.',
    effect: ItemEffect(heal: 185),
    value: 95,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The mini pool's rare chase. Accuracy and crit on a signet is the
  /// Astral half of the zone stated as gear: the machine does not miss, and
  /// when it lands it lands on the number it meant.
  /// ⚠️ `properName` is set — drop-only jewelry keeps its own name (§3.5).
  static const siderealSignet = EquipmentDef(
    id: 'sidereal_signet',
    properName: 'Sidereal Signet',
    rarity: Rarity.rare,
    lore:
        'A seal for something that has not needed sealing in a long time. The '
        'face is a date.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Starbrass',
    modifiers: ItemModifiers(critChance: 10, accuracyBonus: 4),
    tradability: Tradability.untradeable,
    equipLevel: 42,
    value: 1600,
  );

  /// ⭐ The zone's epic, boss-pool only. `damagePerCast` is the Orrery's own
  /// metaphor as a stat line — a count that goes up every time you act, and
  /// never resets.
  static const theRunningCount = EquipmentDef(
    id: 'the_running_count',
    properName: 'The Running Count',
    rarity: Rarity.epic,
    lore:
        'Put them on and you know what number it is on. You do not know what '
        'it is counting.',
    slot: EquipSlot.gloves,
    form: 'Gauntlets',
    material: 'Starbrass',
    modifiers: ItemModifiers(
      accuracyBonus: 5,
      damagePerCast: 10,
      critChance: 8,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 44,
    value: 4500,
  );

  static const all = <ItemDef>[
    orreryScrap,
    arcsalt,
    siderealGlass,
    starbrassIngot,
    arcsaltDraught,
    siderealSignet,
    theRunningCount,
  ];
}
