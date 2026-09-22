/// Everything The Sunless Reach can yield (Lv 38–42, Solar + Lunar).
///
/// ⭐ Hybrid zone: three materials (CELESTIAL_CONTRACT §3.1, ITEMS §9b.8
/// ruling 7). Ebony Log feeds Woodcarving, Duskcap feeds Potions & Alchemy,
/// Eclipse Opal feeds Jewelry. ⚠️ **None of the three is a hide** — this zone
/// has no kill-only material at all, so all three get a gather node and the
/// roster's `hide` drop role resolves to the zone's SECOND gatherable
/// material, `duskcap` (ETHEREAL_CONTRACT §3.5.1).
///
/// ⭐ **No motes defined here.** A hybrid's mote families live with whichever
/// zone first yielded them (§3.2) — `solar_*` ships with The Kiln Desert and
/// `lunar_*` with The Mirrormere. The Sunless Reach drops both families and
/// defines neither. ⚠️ `pilgrims_ration` and `glasswort_draught` are likewise
/// the Kiln Desert's; this file authors only the Duskcap Tonic.
///
/// ⏳ **`eclipse_opal` banks until Rimeholt (L45)** — Jewelry's station and
/// learning stay there (§3.1, §8.1 of KINETIC re-confirmed). It is gatherable
/// across 38–42 and spendable from 45, which is the shortest banking window
/// any quarter has had. ⚠️ A test must assert it has no Celestial consumer.
///
/// ⭐ **Nine defs** (§4.5, §7.1): three materials, one tonic, three crafted
/// Ebony pieces, one rare ring and one epic wand.
///
/// ⭐ Ebony is ITEMS §9b.6's wood here and §9b.6 already resolved its retheme:
/// *"black wood grown where the sun does not reach. Sunless/lightless, not
/// void-touched."* ⚠️ The weapon is simply an **Ebony Quarterstaff** — no
/// adjective — because §9b.5a took adjectives out of base names, and because
/// crafted equipment must leave `properName` null so the name composes from
/// material + form.
///
/// 📝 **Phase 8 hook.** The one place a **dual enchant** would make sense, if
/// Phase 8 ever allows one. Ebony's §9b.6 range is 1–2 sockets; this contract
/// spends 1.
library;

import '../item_def.dart';

abstract final class SunlessReachItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ The band's third wood (Ironwood 30 · Bloodwood 35 · **Ebony 40**),
  /// named by ITEMS §9b.6 for this zone specifically.
  static const ebonyLog = MaterialDef(
    id: 'ebony_log',
    properName: 'Ebony Log',
    rarity: Rarity.common,
    lore:
        'Grown on the dark side. It sinks, it will not take a nail, and it '
        'polishes like stone.',
    skill: CraftSkill.woodcarving,
    tier: 7,
    value: 810,
  );

  /// ⭐ The zone's SECOND gatherable material, which is also what the roster's
  /// `hide` role resolves to here (§3.5.1) — nothing in the Reach is
  /// kill-only, so "something died" pays in the zone's own stuff.
  static const duskcap = MaterialDef(
    id: 'duskcap',
    properName: 'Duskcap',
    rarity: Rarity.common,
    lore:
        'It fruits along the line where the light stops and nowhere else. '
        'Boiled, it is the best thing in the valley.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 6,
    value: 36,
  );

  /// ⏳ Banks until Jewelry opens at Rimeholt (L45, §3.1) — the same shape
  /// Everice and Nacre follow, one quarter on.
  static const eclipseOpal = MaterialDef(
    id: 'eclipse_opal',
    properName: 'Eclipse Opal',
    rarity: Rarity.uncommon,
    lore:
        'Light on one face, dark on the other, and the line between them '
        'does not move when you turn it.',
    skill: CraftSkill.jewelry,
    tier: 7,
    value: 130,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Tonic shape (§3.3): heal-over-time rather than a lump, so drinking
  /// it is a bet on surviving three more turns. ⚠️ `BeltableDef`, not
  /// `ConsumableDef` — a tonic is drunk mid-duel, and that is a type, not a
  /// flag someone can forget to check (ITEMS §6b.3).
  static const duskcapTonic = BeltableDef(
    id: 'duskcap_tonic',
    properName: 'Duskcap Tonic',
    rarity: Rarity.common,
    lore: 'Drink it and count to three. Each count is worth something.',
    effect: ItemEffect(healPerTurn: 34, healTurns: 3),
    value: 70,
  );

  // ---- equipment: Woodcarving, Ebony (§9b.6, §2.5) -----------------------

  static const ebonyQuarterstaff = EquipmentDef(
    id: 'ebony_quarterstaff',
    rarity: Rarity.common,
    lore: 'It weighs what a bar of iron weighs and it is wood.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Ebony',
    twoHanded: true,
    modifiers: ItemModifiers(
      damagePerCharge: 7,
      accuracyBonus: 11,
      critChance: 6,
      critDamage: 14,
    ),
    socketCount: 1,
    salvage: [SalvageYield('ebony_log', 1, 2)],
    equipLevel: 40,
    value: 2100,
  );

  static const ebonyWand = EquipmentDef(
    id: 'ebony_wand',
    rarity: Rarity.common,
    lore: 'A short black line that the eye keeps sliding off.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Ebony',
    modifiers: ItemModifiers(
      damagePerCast: 8,
      accuracyBonus: 5,
      critChance: 7,
      critDamage: 12,
    ),
    socketCount: 1,
    salvage: [SalvageYield('ebony_log', 1, 2)],
    equipLevel: 40,
    value: 1800,
  );

  static const ebonyKnot = EquipmentDef(
    id: 'ebony_knot',
    rarity: Rarity.common,
    lore: 'The only pale thing on it is where it was cut.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Ebony',
    modifiers: ItemModifiers(accuracyBonus: 6, critChance: 5),
    socketCount: 1,
    salvage: [SalvageYield('ebony_log', 1, 2)],
    equipLevel: 40,
    value: 1500,
  );

  /// ⭐ **The zone in one item:** Solar's accuracy and Lunar's dodge, equal and
  /// opposed, on a ring named for the line between them (§2.5a). It is the
  /// only piece in either quarter that carries both sides of an affinity
  /// pair, and it is the right zone for it — ENEMIES §2f calls the two-Aspect
  /// doubling here *"the one place doubling says something."*
  static const crestlineRing = EquipmentDef(
    id: 'crestline_ring',
    properName: 'Crestline Ring',
    rarity: Rarity.rare,
    lore:
        'Worn on the hand you reach with. Half the band has been in the sun '
        'and half has not, and they do not match.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Eclipse Opal',
    modifiers: ItemModifiers(accuracyBonus: 5, dodge: 5, maxHpBonus: 20),
    salvage: [SalvageYield('eclipse_opal', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 40,
    value: 1300,
  );

  /// ⭐ **The quarter's wand epic** and the best-in-slot main hand at L47
  /// (§2.6) — the Uplight role one tier up. ⚠️ Equip level 42, the top of the
  /// band, so it is a chase rather than a mid-zone upgrade.
  static const theDividingLine = EquipmentDef(
    id: 'the_dividing_line',
    properName: 'The Dividing Line',
    rarity: Rarity.epic,
    lore: 'Hold it up along the crest and it disappears.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Ebony',
    modifiers: ItemModifiers(
      damagePerCast: 12,
      accuracyBonus: 6,
      critChance: 10,
      critDamage: 20,
    ),
    socketCount: 1,
    salvage: [SalvageYield('ebony_log', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 42,
    value: 3700,
  );

  static const all = <ItemDef>[
    ebonyLog,
    duskcap,
    eclipseOpal,
    duskcapTonic,
    ebonyQuarterstaff,
    ebonyWand,
    ebonyKnot,
    crestlineRing,
    theDividingLine,
  ];
}
