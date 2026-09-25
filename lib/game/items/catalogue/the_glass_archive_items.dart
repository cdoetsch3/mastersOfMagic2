/// Everything The Glass Archive can yield (Lv 43–47, Solar + Arcane —
/// CELESTIAL_CONTRACT §4.7).
///
/// ⭐ **Two firsts live in this file** (§4.7's own heading).
///
/// 1. ⭐⭐ **This is the game's first Arcane zone, so `arcane_*` is DEFINED
///    HERE** (§3.2) — not in the Ethereal quarter's pure Arcane zone. The
///    Glass Archive is 43–47; The Collapsed Academy is 50–54, seven levels
///    later. The shipped rule is *"the mote lives with the zone that first
///    yields it"*, and it lands the Arcane family in a Celestial dungeon.
///    ⚠️ **The Ethereal contract must not re-define `arcane_*`** — it imports
///    them, exactly as Frostfell imports `aqua_*`. A builder looking for
///    Arcane Dust in the Ethereal quarter will not find it, and that is
///    correct.
/// 2. ⭐ **`celestial_totem` is defined here** even though it is *charged* at
///    Meridian by Enchanting (§3.4). `world.dart` says in a comment that this
///    zone is *"where a player grinds out the Celestial Totem that gets them
///    past"* the Rimeholt barrier, so the Totem belongs to the zone the
///    player earns it in. ⚠️ It is **not** a drop — no boss table carries it.
///    The gate is a *craft*, deliberately, and that is what KINETIC §8.6's
///    rejection of collect-three-keys bought.
///
/// ⭐ **Three materials, because a hybrid gets three** (ITEMS §9b.8 ruling 7).
/// Sunbleach Lichen feeds Potions, Aetherglass feeds Jewelry, Palimpsest
/// Vellum feeds Tailoring. ⚠️ **The vellum is a hide** (§3.1's own note —
/// *"A palimpsest is a hide"*): kill-only, no node, the same rule Rimepelt and
/// Drownling Hide follow. ⏳ Aetherglass **banks** until Jewelry opens at
/// Rimeholt (L45).
///
/// ⚠️ **`the_noon_hour` is the whole Celestial quarter's ONE deflect drop**
/// (§2.1b). Arcane's gear affinity is deflection (§2.5a), which is why it is
/// here and nowhere else. The `deflectAmount: 14` is not a taste number: with
/// the Wrackcotton gloves' 24 it sums to **exactly 38**, and 50 is the hard
/// player cap (ITEMS §4.1a) that the worst legal level-60 assembly across
/// both quarters must land on rather than exceed. 📝 Moving the 14 moves that
/// proof.
///
/// ⚠️ **`palimpsest_belt` equips at 45, not 43** — the top of this band and
/// the floor of the Ethereal one (§4.7). It is the last Celestial item a
/// player puts on and the first thing Rimeholt sees them wearing.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class GlassArchiveItems {
  // ---- materials --------------------------------------------------------

  /// Potions, tier 8 — the band's own reagent, and `sunbleach_tonic`'s only
  /// input (§5.1 #27, `sunbleach_lichen` ×3).
  static const sunbleachLichen = MaterialDef(
    id: 'sunbleach_lichen',
    properName: 'Sunbleach Lichen',
    rarity: Rarity.common,
    lore:
        'It grows in the one strip the lenses never sweep. Dried and '
        'steeped, it is what the readers drank.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 8,
    value: 37,
  );

  /// ⏳ **Banks until Rimeholt (L45)**, where Jewelry finally opens — the
  /// Q1-ore-before-Metalworking pattern, two skills later. ⚠️ Uncommon, which
  /// is the gem grade; `uncommon` survives on gem-grade materials and Crystal
  /// motes and nowhere else in this quarter (§0.2 ruling 2).
  static const aetherglass = MaterialDef(
    id: 'aetherglass',
    properName: 'Aetherglass',
    rarity: Rarity.uncommon,
    lore:
        'Archive glass, cut out of a roof. Held at the right angle it is '
        'still holding a word.',
    skill: CraftSkill.jewelry,
    tier: 8,
    value: 210,
  );

  /// ⚠️ **A hide, and therefore kill-only** (§3.1; ITEMS §9b.7b). It has no
  /// gather node and must not acquire one — a node for a hide is a second
  /// source that contradicts its own fiction. ⭐ It is also the zone's `hide`
  /// drop role, which lands on the two Arcane commons (Palimpsest and
  /// Readerless) rather than on anything the lenses made.
  static const palimpsestVellum = MaterialDef(
    id: 'palimpsest_vellum',
    properName: 'Palimpsest Vellum',
    rarity: Rarity.common,
    lore:
        'Scraped clean and written on again, and again. The first thing on '
        'it is still there and still legible if you stop trying.',
    skill: CraftSkill.tailoring,
    tier: 7,
    value: 480,
  );

  // ---- motes ------------------------------------------------------------
  //
  // ⭐⭐ The Arcane family, defined here because this zone yields it first
  // (§3.2). ✅ Values 2 / 25 / 150, uniform across every element
  // (ECONOMY §14c) and LOSSY against the refinement ladder, so
  // refine-and-vendor can never profit.
  // ✅ Rarity from ITEMS §8: Dust and Shard Common, Crystal Uncommon.
  // ⚠️ No Core and no Heart — this quarter ships neither (§3.2), a knowing
  // departure from ITEMS §9's band table rather than an oversight.

  static const arcaneDust = MoteDef(
    id: 'arcane_dust',
    properName: 'Arcane Dust',
    rarity: Rarity.common,
    lore: 'You are certain, afterwards, that you knew something.',
    tier: MoteTier.dust,
    element: MagicElement.arcane,
    value: 2,
  );

  static const arcaneShard = MoteDef(
    id: 'arcane_shard',
    properName: 'Arcane Shard',
    rarity: Rarity.common,
    lore: 'Dust that made up its mind.',
    tier: MoteTier.shard,
    element: MagicElement.arcane,
    value: 25,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Crystal is where the mote
  /// ladder is first FELT, so it must be a fight the player chose (ITEMS §8).
  static const arcaneCrystal = MoteDef(
    id: 'arcane_crystal',
    properName: 'Arcane Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is known, and it does not stop being known.',
    tier: MoteTier.crystal,
    element: MagicElement.arcane,
    value: 150,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Tonic form: over-time, never a lump (§3.3's settled vocabulary —
  /// *Ration = 35% of the band floor's health · Draught = 40% · Tonic = 24%
  /// total*). 42×3 = 126 against a level-43 bar of 519 is 24.3%. ⚠️ A Tonic
  /// pays least because it pays late, and that ordering is the ruling; the
  /// percentages themselves are knobs.
  /// ⚠️ **Value is not priced against the heal number** (the 2026-09-21
  /// ruling): 110 sits just under Σ(inputs) = 3 × 37 = 111 so
  /// buy→craft→vendor cannot profit (§5.5).
  static const sunbleachTonic = BeltableDef(
    id: 'sunbleach_tonic',
    properName: 'Sunbleach Tonic',
    rarity: Rarity.common,
    lore:
        'Pale, bitter, and it works on the way down rather than all at '
        'once. The readers took it at dawn and finished the day.',
    effect: ItemEffect(healPerTurn: 42, healTurns: 3),
    value: 110,
  );

  // ---- the gate ---------------------------------------------------------

  /// ⭐ **The Rimeholt gate, and it is one object rather than three** (§3.4).
  /// The three essences are its recipe *inputs*, consumed at Meridian by
  /// Enchanting; the player does not carry three tokens to a guard, they make
  /// a thing and carry the thing. ⚠️ That is precisely what KINETIC §8.6
  /// rejected the Kinetic Sigil's collect-three-keys mechanism for.
  ///
  /// ⚠️ **Gates are SHOWN, not spent** (ruling, 2026-09-21) — `gateItemIds`
  /// plus `PlayerProfile.openedGates`. ⚠️ **`rimeholt.gateItemIds` must be
  /// `['celestial_totem']` in `world.dart`** or the gate checks nothing and
  /// the whole of §3.4 is a lore line. 📝 That one-line edit is a shared-file
  /// change this lane did not make; see this zone's build report.
  ///
  /// ⚠️ `KeyDef` forces Bound and `value: 0` by construction, so the Totem
  /// is exempt from §5.5's value conservation rather than failing it.
  static const celestialTotem = KeyDef(
    id: 'celestial_totem',
    properName: 'Celestial Totem',
    rarity: Rarity.rare,
    lore:
        'Three essences and a socket cut to hold all three. The guard above '
        'Rimeholt does not take it off you; he looks, and then he steps '
        'aside.',
    gates: 'rimeholt',
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The belt-capacity ladder's Celestial rung: Fawnhide 1 → Tuskhide 2 →
  /// Rimepelt 3 → Emberhide 4 → … → Palimpsest **6**. ⚠️ Belts carry
  /// `beltSlots` and consumable potency (ruling 2026-09-25) and nothing
  /// else — the belt is the one slot that is deliberately *not* combat
  /// power (ITEMS §6b.2).
  /// ⚠️ **`properName` stays null**: this is crafted (§5.1 #23), so its name
  /// is composed from material + form by the §9b.5a grammar rather than
  /// written down here where it could drift.
  static const palimpsestBelt = EquipmentDef(
    id: 'palimpsest_belt',
    rarity: Rarity.common,
    lore:
        'Six loops of scraped hide. Someone\'s handwriting runs under the '
        'stitching and does not stop at the seam.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Palimpsest',
    // ⭐ Tier 4: potency 5 × 4 + 5 (ruling 2026-09-25).
    modifiers: ItemModifiers(beltSlots: 6, consumablePotencyPercent: 25),
    salvage: [SalvageYield('palimpsest_vellum', 1, 2)],
    equipLevel: 45,
    value: 1110,
  );

  /// ⭐ The mini pool's Rare chase. A legible three-line combination and
  /// nothing exotic: health to survive the read, accuracy because Solar's
  /// affinity is accuracy (§2.5a), and crit damage for the one page that
  /// mattered.
  static const theLastReading = EquipmentDef(
    id: 'the_last_reading',
    properName: 'The Last Reading',
    rarity: Rarity.rare,
    lore:
        'Whoever was here at the end took one page with them and it is this '
        'one.',
    slot: EquipSlot.neck,
    form: 'Locket',
    material: 'Aetherglass',
    modifiers: ItemModifiers(maxHpBonus: 30, accuracyBonus: 5, critDamage: 20),
    tradability: Tradability.untradeable,
    equipLevel: 45,
    value: 2000,
  );

  /// ⚠️⚠️ **The Celestial quarter's ONE deflect drop** (§2.1b). No other
  /// Celestial item carries `deflectAmount`, and that scarcity is the design:
  /// deflection is the stat a quarter can only spend once.
  ///
  /// ⭐ **Why 12 / 14 exactly.** 12% × 14 is an EV of 1.7% mitigation on its
  /// own — small. With the Wrackcotton gloves it reaches 26 / 38 (EV 9.9%),
  /// and 38 is chosen so the worst legal assembly a level-60 player can make
  /// across the Celestial and Ethereal quarters lands on **exactly the 50**
  /// that ITEMS §4.1a caps players at. 📝 Move the 14 and that proof moves
  /// with it.
  static const theNoonHour = EquipmentDef(
    id: 'the_noon_hour',
    properName: 'The Noon Hour',
    rarity: Rarity.epic,
    lore:
        'For about forty minutes a day it is the most useful object in the '
        'world. It is worn the other twenty-three hours anyway.',
    slot: EquipSlot.hat,
    form: 'Circlet',
    material: 'Aetherglass',
    modifiers: ItemModifiers(
      maxHpBonus: 55,
      deflectChance: 12,
      deflectAmount: 14,
      critDamage: 20,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 47,
    value: 5600,
  );

  /// ✅ **11 defs** — §7.1's count for this zone: 3 materials + 3 motes +
  /// 1 consumable + 1 key + 3 equipment.
  static const all = <ItemDef>[
    sunbleachLichen,
    aetherglass,
    palimpsestVellum,
    arcaneDust,
    arcaneShard,
    arcaneCrystal,
    sunbleachTonic,
    celestialTotem,
    palimpsestBelt,
    theLastReading,
    theNoonHour,
  ];
}
