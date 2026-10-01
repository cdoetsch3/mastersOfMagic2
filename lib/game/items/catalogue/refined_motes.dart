/// The top of the mote ladder: **Core** and **Heart**, twelve of each
/// (ENCHANTING_DESIGN §3.1, ITEMS §6.0).
///
/// ⭐ **Made, never found.** §6.0 says a Heart is *"crafting only"* and a Core
/// *"possibly never"* drops, so neither belongs to a zone — they live here,
/// under `ItemCatalogue.byWorkshop['refined']`, not in any zone file. ⚠️ The
/// zone rule *"the mote lives with the zone that first yields it"* cannot
/// apply to something no zone yields; filing a Core under its element's
/// first zone would make `ItemCatalogue.zoneOf` answer a question about
/// geography with a fact about the alphabet.
///
/// 📝 The refine recipes that make these are lane 2 (§8.2). Until they land,
/// nothing in the game produces a Core or a Heart — the defs exist so the
/// enchant and gem tables have something to name.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class RefinedMotes {
  /// A Core's vendor value — ECONOMY §14c's *"Core 900g when it ships"*,
  /// and ⭐ LOSSY against its 12-Crystal refine (900 < 12 × 150), so
  /// refine-and-vendor never mints gold. Pinned by `value_conservation_test`.
  static const int coreValue = 900;

  /// A Heart's vendor value: ⚠️ **none.** ECONOMY §14c (✅ Christian,
  /// 2026-08-25): *"Hearts are the one exception: craft-only (§6.0) is
  /// load-bearing, so Hearts get no value, no vendor path, and Bound
  /// tradability when they ship."* ENCHANTING_DESIGN §3.1's **3,600 ❓** was a
  /// draft written past that ruling, not a reversal of it; 📝 if Christian
  /// rules 3,600 after all, this const and [heartTradability] are the change.
  static const int heartValue = 0;

  /// ⚠️ Bound, per the same §14c ruling — a Heart that could be traded would
  /// be a Heart that could be bought, and the 48-Crystal climb is the point.
  static const Tradability heartTradability = Tradability.bound;

  /// The Core for [element]. ⚠️ Ids are `<element>_core` / `<element>_heart`
  /// and are forever once a save holds one.
  static MoteDef coreOf(MagicElement element) =>
      all.firstWhere((m) => m.tier == MoteTier.core && m.element == element);

  /// The Heart for [element].
  static MoteDef heartOf(MagicElement element) =>
      all.firstWhere((m) => m.tier == MoteTier.heart && m.element == element);

  /// ⭐ Element-enum order, Core before Heart — the order the tests pin.
  /// 📝 Stack size needs no field: `MoteDef.stackSize` is 1 for every tier
  /// above Shard (ruling 2026-09-25), so a Core and a Heart each cost a slot.
  static const List<MoteDef> all = [
    MoteDef(
      id: 'aqua_core',
      properName: 'Aqua Core',
      rarity: Rarity.rare,
      lore: 'The weight of a lake, and it fits in one hand.',
      tier: MoteTier.core,
      element: MagicElement.aqua,
      value: coreValue,
    ),
    MoteDef(
      id: 'aqua_heart',
      properName: 'Aqua Heart',
      rarity: Rarity.epic,
      lore: 'Every tide that ever turned, turning once more in your palm.',
      tier: MoteTier.heart,
      element: MagicElement.aqua,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'pyro_core',
      properName: 'Pyro Core',
      rarity: Rarity.rare,
      lore: 'The middle of a fire, kept after the fire was put out.',
      tier: MoteTier.core,
      element: MagicElement.pyro,
      value: coreValue,
    ),
    MoteDef(
      id: 'pyro_heart',
      properName: 'Pyro Heart',
      rarity: Rarity.epic,
      lore: 'It burns because it decided to, and it has not changed its mind.',
      tier: MoteTier.heart,
      element: MagicElement.pyro,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'flora_core',
      properName: 'Flora Core',
      rarity: Rarity.rare,
      lore: 'It has a pulse if you hold it long enough to doubt it.',
      tier: MoteTier.core,
      element: MagicElement.flora,
      value: coreValue,
    ),
    MoteDef(
      id: 'flora_heart',
      properName: 'Flora Heart',
      rarity: Rarity.epic,
      lore: 'It beats, slowly, in the season it was made.',
      tier: MoteTier.heart,
      element: MagicElement.flora,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'electro_core',
      properName: 'Electro Core',
      rarity: Rarity.rare,
      lore: 'The moment before the strike, kept from ever arriving.',
      tier: MoteTier.core,
      element: MagicElement.electro,
      value: coreValue,
    ),
    MoteDef(
      id: 'electro_heart',
      properName: 'Electro Heart',
      rarity: Rarity.epic,
      lore: 'The storm is not around it. The storm is in it.',
      tier: MoteTier.heart,
      element: MagicElement.electro,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'aero_core',
      properName: 'Aero Core',
      rarity: Rarity.rare,
      lore: 'A wind that found the middle of itself and stayed there.',
      tier: MoteTier.core,
      element: MagicElement.aero,
      value: coreValue,
    ),
    MoteDef(
      id: 'aero_heart',
      properName: 'Aero Heart',
      rarity: Rarity.epic,
      lore: 'It weighs nothing, and it will not be let go of.',
      tier: MoteTier.heart,
      element: MagicElement.aero,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'geo_core',
      properName: 'Geo Core',
      rarity: Rarity.rare,
      lore: 'The part of the mountain the mountain stood on.',
      tier: MoteTier.core,
      element: MagicElement.geo,
      value: coreValue,
    ),
    MoteDef(
      id: 'geo_heart',
      properName: 'Geo Heart',
      rarity: Rarity.epic,
      lore: 'It does not move. Everything else is measured from it.',
      tier: MoteTier.heart,
      element: MagicElement.geo,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'solar_core',
      properName: 'Solar Core',
      rarity: Rarity.rare,
      lore: 'Noon, folded small enough to carry.',
      tier: MoteTier.core,
      element: MagicElement.solar,
      value: coreValue,
    ),
    MoteDef(
      id: 'solar_heart',
      properName: 'Solar Heart',
      rarity: Rarity.epic,
      lore: 'It is daylight, and it does not set.',
      tier: MoteTier.heart,
      element: MagicElement.solar,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'lunar_core',
      properName: 'Lunar Core',
      rarity: Rarity.rare,
      lore: 'Whichever way you turn it, you are looking at the far side.',
      tier: MoteTier.core,
      element: MagicElement.lunar,
      value: coreValue,
    ),
    MoteDef(
      id: 'lunar_heart',
      properName: 'Lunar Heart',
      rarity: Rarity.epic,
      lore: 'Every phase of the moon at once, and none of them for you.',
      tier: MoteTier.heart,
      element: MagicElement.lunar,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'astral_core',
      properName: 'Astral Core',
      rarity: Rarity.rare,
      lore: 'A chart of the sky with one star on it, and this is the star.',
      tier: MoteTier.core,
      element: MagicElement.astral,
      value: coreValue,
    ),
    MoteDef(
      id: 'astral_heart',
      properName: 'Astral Heart',
      rarity: Rarity.epic,
      lore: 'It is very far away, and it is also here.',
      tier: MoteTier.heart,
      element: MagicElement.astral,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'sanctus_core',
      properName: 'Sanctus Core',
      rarity: Rarity.rare,
      lore: 'It keeps a vigil, and you are inside it.',
      tier: MoteTier.core,
      element: MagicElement.sanctus,
      value: coreValue,
    ),
    MoteDef(
      id: 'sanctus_heart',
      properName: 'Sanctus Heart',
      rarity: Rarity.epic,
      lore: 'It forgives you for holding it.',
      tier: MoteTier.heart,
      element: MagicElement.sanctus,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'umbra_core',
      properName: 'Umbra Core',
      rarity: Rarity.rare,
      lore: 'The dark at the bottom of the dark, and it has edges.',
      tier: MoteTier.core,
      element: MagicElement.umbra,
      value: coreValue,
    ),
    MoteDef(
      id: 'umbra_heart',
      properName: 'Umbra Heart',
      rarity: Rarity.epic,
      lore: 'It is what the light was afraid of, and it is patient.',
      tier: MoteTier.heart,
      element: MagicElement.umbra,
      value: heartValue,
      tradability: heartTradability,
    ),
    MoteDef(
      id: 'arcane_core',
      properName: 'Arcane Core',
      rarity: Rarity.rare,
      lore: 'Everything it knows, and none of it said aloud.',
      tier: MoteTier.core,
      element: MagicElement.arcane,
      value: coreValue,
    ),
    MoteDef(
      id: 'arcane_heart',
      properName: 'Arcane Heart',
      rarity: Rarity.epic,
      lore: 'It is the answer, and it has forgotten the question.',
      tier: MoteTier.heart,
      element: MagicElement.arcane,
      value: heartValue,
      tradability: heartTradability,
    ),
  ];
}
