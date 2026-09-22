/// Everything Starfall Basin can yield (Lv 34–39, Astral).
///
/// ⭐ **The zone with no cloth, no wood and no herb, and that is the design**
/// (CELESTIAL_CONTRACT §4.3). Everything here came down; nothing grew. Both
/// materials are mined out of craters, which makes this the only zone in the
/// game with **two Mining nodes and nothing else**, and it is why the zone's
/// own consumable is imported rather than brewed — there is no herb to brew
/// it from.
///
/// ⭐ **This file DEFINES the `astral_*` mote family** (§3.2) — the mote lives
/// with the zone that first yields it, and Starfall Basin is where a player
/// first meets Astral. ⚠️ **No other zone may re-define `astral_*`.** The
/// Shattered Orrery (Astral + Electro) *imports* these three exactly as
/// Frostfell imports `aqua_*`; a second definition would resolve by id and
/// silently give the family two owners, two icons and two vendor values.
///
/// ⭐ **Both drops are Astral and both are crit** (§2.5a, §4.3). Starfall
/// Basin is where a player learns that Astral is the crit element, and it
/// teaches it twice: [zodiacPendant] is pure crit, [theAimedSky] adds the
/// damage that makes a crit worth landing. ⚠️ **They are the same slot** —
/// deliberately a rare→epic ladder inside one zone, which no Kinetic zone
/// offered. 📝 §4.3 offers moving the rare to `ring` if a sidegrade is wanted
/// instead of a ladder.
///
/// ⚠️ **`astral_essence` is a gate part, not crafting stock** (§3.4). It is
/// Bound, kill-only, has no node, and is guaranteed on the boss pool's
/// `always` line. It does NOT count against §9b.8 ruling 7's two-materials-
/// per-pure-zone budget — the precedent is Q1's three `proof_of_the_*`.
/// 📝 `ComponentDef` is the arguably truer kind and §3.4 says why it is not
/// used: ITEMS §3.5 defines components as Tier III/IV set parts (L45+).
///
/// ⭐ **`fallstone` is the first Enchanting material with a consumer in the
/// same quarter it drops in** (§3.1), and it settles an older debt too:
/// `craft_celestial_totem` spends Hum Quartz ×3 and Fallstone ×2 at Meridian,
/// which is the only thing in the game that spends the Kinetic quarter's
/// banked Hum Quartz. ⚠️ If that recipe moves, the Kinetic banking clause
/// breaks with it.
///
/// 📝 The recipes themselves are **not** authored here — the quarter's recipe
/// file is a separate lane that lands after all seven zones (§5).
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class StarfallBasinItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ Metalworking t5, and the zone's headline material — every piece of
  /// equipment here salvages back into it.
  static const skyironOre = MaterialDef(
    id: 'skyiron_ore',
    properName: 'Sky-Iron Ore',
    rarity: Rarity.common,
    lore:
        'Iron that arrived rather than formed. It rusts differently and '
        'nobody local will say how.',
    skill: CraftSkill.metalworking,
    tier: 5,
    value: 26,
  );

  /// ⭐ **Enchanting's first in-quarter material** (§3.1). ⚠️ Uncommon, and
  /// that rarity is load-bearing on the common drop tables: a common may
  /// hand out Uncommon but never Rare, so this is the ceiling of what the
  /// zone's ordinary fights pay.
  static const fallstone = MaterialDef(
    id: 'fallstone',
    properName: 'Fallstone',
    rarity: Rarity.uncommon,
    lore:
        'Whatever is at the bottom of each bowl. It weighs what it should '
        'and nothing else about it does.',
    skill: CraftSkill.enchanting,
    tier: 5,
    value: 60,
  );

  /// ⭐ Metalworking t5 **output**, not a gathered material — it feeds two of
  /// the quarter's recipes (§4.3). ⚠️ It lives in *this* file although it is
  /// smelted rather than mined, because §3.5's rule is that a crafted output
  /// belongs to the zone supplying its **headline** material.
  static const skysteelIngot = MaterialDef(
    id: 'skysteel_ingot',
    properName: 'Skysteel Ingot',
    rarity: Rarity.common,
    lore:
        'Smelted with charcoal, because nothing else here burns. It takes an '
        'edge that should not be possible.',
    skill: CraftSkill.metalworking,
    tier: 5,
    value: 110,
  );

  /// ⚠️ **A gate part** (§3.4) — one of the three essences the Celestial
  /// Totem is charged with at Meridian, and therefore the thing that opens
  /// Rimeholt. Bound, `value: 0`, **kill-only with no node**, and guaranteed
  /// on BOTH bosses' `always` line so the zone can never be finished without
  /// yielding one.
  static const astralEssence = MaterialDef(
    id: 'astral_essence',
    properName: 'Astral Essence',
    rarity: Rarity.rare,
    lore: 'The last of whatever was aiming.',
    skill: CraftSkill.enchanting,
    tier: 6,
    tradability: Tradability.bound,
    value: 0,
  );

  // ---- motes ----------------------------------------------------------
  //
  // ⭐ The Astral ladder, defined here because this is the zone that first
  // yields it (§3.2) — the shipped rule, the same one that put `aqua_*` in
  // Glimmerbrook and `aero_*` in Windward Steppe. ✅ Rarity from ITEMS §8
  // (Dust and Shard common, Crystal uncommon) and values from ECONOMY §14c
  // (2 / 25 / 150, uniform across every element).
  //
  // ⚠️ **No Core and no Heart** (§3.2). That is a knowing departure from
  // ITEMS §9's band table, flagged rather than hidden: Core's only consumers
  // are a Phase 8 gem and a Zenith crown, so a Core that drops essentially
  // never and buys nothing would be noise rather than a ladder rung.

  static const astralDust = MoteDef(
    id: 'astral_dust',
    value: 2,
    properName: 'Astral Dust',
    rarity: Rarity.common,
    lore: 'It scatters, and then it is in a pattern.',
    tier: MoteTier.dust,
    element: MagicElement.astral,
  );

  static const astralShard = MoteDef(
    id: 'astral_shard',
    value: 25,
    properName: 'Astral Shard',
    rarity: Rarity.common,
    lore: 'Cold sparks with corners on them.',
    tier: MoteTier.shard,
    element: MagicElement.astral,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Crystal is where the mote
  /// ladder is first *felt*, so it must come off a fight the player chose
  /// (ITEMS §8); a common that handed one out would flatten the whole ladder.
  static const astralCrystal = MoteDef(
    id: 'astral_crystal',
    value: 150,
    properName: 'Astral Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is far away, and holding it does not change that.',
    tier: MoteTier.crystal,
    element: MagicElement.astral,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The mini pool's rare chase, and the first half of the zone's lesson:
  /// **Astral is the crit element** (§2.5a). Pure crit, no damage line —
  /// which is exactly what makes [theAimedSky] feel like an upgrade rather
  /// than a bigger number.
  static const zodiacPendant = EquipmentDef(
    id: 'zodiac_pendant',
    properName: 'Zodiac Pendant',
    rarity: Rarity.rare,
    lore:
        'Twelve marks around the rim, and the one at the top is not one of '
        'the twelve.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Sky-Iron',
    modifiers: ItemModifiers(critChance: 10, critDamage: 12),
    tradability: Tradability.untradeable,
    salvage: [SalvageYield('skyiron_ore', 1, 2)],
    equipLevel: 37,
    value: 900,
  );

  /// ⭐ The boss pool's epic, and the second half of the lesson: the damage
  /// that makes a crit worth landing. ⚠️ **Same slot as [zodiacPendant]** —
  /// the rare→epic ladder inside one zone (§4.3), not a sidegrade.
  static const theAimedSky = EquipmentDef(
    id: 'the_aimed_sky',
    properName: 'The Aimed Sky',
    rarity: Rarity.epic,
    lore:
        'It is not a map of where things are. It is a map of where they are '
        'going.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Sky-Iron',
    modifiers: ItemModifiers(damagePerCast: 9, critChance: 10, critDamage: 18),
    tradability: Tradability.untradeable,
    salvage: [SalvageYield('skyiron_ore', 1, 2)],
    equipLevel: 39,
    value: 2600,
  );

  /// ⚠️ **Every def must be listed here.** An unlisted one compiles fine and
  /// simply never resolves through [ItemCatalogue] — the silent failure the
  /// id tests exist to catch.
  static const all = <ItemDef>[
    skyironOre,
    fallstone,
    skysteelIngot,
    astralEssence,
    astralDust,
    astralShard,
    astralCrystal,
    zodiacPendant,
    theAimedSky,
  ];
}
