/// Everything The Umbral Wastes can yield (Lv 47–51, Umbra).
///
/// ⭐ **Theme: the dark here is deliberate. Something decided its shape**
/// (ENEMIES §2e; ETHEREAL_CONTRACT §4.3). Not absence — **design**. Every
/// lore line below is written to that: nothing here happened, everything here
/// was *decided*.
///
/// ⭐ **A pure zone**, so two materials (§3.1, ITEMS §9b.8 ruling 7):
/// `umbralweave` feeds Tailoring and `thoughtglass` feeds Jewelry, both
/// tier 8, and ⚠️ **neither is kill-only** — both get a gather node (§6), so
/// the roster's `hide` drop role resolves to the zone's SECOND gatherable
/// material, `thoughtglass` (ETHEREAL_CONTRACT §3.5.1).
///
/// ⭐⭐ **The `umbra_*` mote family is defined HERE** (§3.2) — this is the
/// first Umbra zone in the game, so it owns the ladder that The Reliquary
/// Deep, The Unwritten Library and The Eclipsed Citadel all spend later.
/// ⚠️ Three of the four zones that pay in Umbra do not define it; only this
/// file may.
///
/// ⚠️ **`climbers_ration` and `goldenrood_draught` are Hallowmarch's**
/// (§4.1) and are deliberately NOT defined here even though this zone drops
/// both — a second definition of either id would shadow the first and make
/// `ItemCatalogue.zoneOf` answer the wrong zone for an icon that already
/// exists.
///
/// ⭐ **`the_dark_third` is the zone's gate part** — one of the three Ethereal
/// fragments the Eclipsed Citadel asks for (§3.4), dropped by **both** bosses
/// on their `always` line. ⚠️ **`the_eclipsed_citadel.gateItemIds` must be
/// `['the_kept_third', 'the_dark_third', 'the_written_third']` in
/// `world.dart`** or the last door in the game is unlocked; that is a
/// shared-file edit this lane did not make — see the build report.
///
/// ⭐ **Thirteen defs**: two materials, three motes, one key, five armour
/// pieces and two rings. 📝 ETHEREAL_CONTRACT §4.3's header says *"12 defs"*
/// and its table lists twelve **without the key**, while §7.1 counts the
/// three Thirds inside the same 79 — the key is the thirteenth, and the
/// contract's own arithmetic needs it here.
///
/// 📝 **Phase 8 hook.** The **Umbra enchant**, and the Voidcaller archetype's
/// natural home (SYSTEMS §3.2). Umbralweave is the obvious Tier III set base,
/// which is exactly why every piece below is a plain Common (§3.6).
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class UmbralWastesItems {
  // ---- materials --------------------------------------------------------

  /// ⭐ The zone's headline material and the band's Tailoring stock. ⚠️ Not
  /// ice, and not cloth anybody wove — it is what comes off a decided thing.
  static const umbralweave = MaterialDef(
    id: 'umbralweave',
    properName: 'Umbralweave',
    rarity: Rarity.common,
    lore:
        'It comes off the ice in sheets, and it is not ice. Pull it in the '
        'dark or it comes apart in your hands.',
    skill: CraftSkill.tailoring,
    tier: 8,
    value: 290,
  );

  /// ⭐ The zone's **second** gatherable material, and therefore where the
  /// roster's `hide` role lands (§3.5.1) — The Umbral Wastes defines no
  /// kill-only hide, so *"something died"* pays in the zone's own stuff.
  /// ⚠️ Uncommon: it is a gem-grade material, not bulk.
  static const thoughtglass = MaterialDef(
    id: 'thoughtglass',
    properName: 'Thoughtglass',
    rarity: Rarity.uncommon,
    lore:
        'Ice that has held one shape for longer than ice can. Cut it and the '
        'new face is the same shape.',
    skill: CraftSkill.jewelry,
    tier: 8,
    value: 200,
  );

  // ---- motes ------------------------------------------------------------
  //
  // ⭐⭐ The Umbra family, defined here because this zone yields it first
  // (§3.2). ✅ Values 2 / 25 / 150, uniform across every element
  // (ECONOMY §14c) and LOSSY against the refinement ladder, so
  // refine-and-vendor can never profit.
  // ✅ Rarity from ITEMS §8: Dust and Shard Common, Crystal Uncommon.
  // ⚠️ No Core and no Heart — this quarter ships neither (§3.2), which is
  // also why the Concordant Crown is unbuildable (§3.4a).

  static const umbraDust = MoteDef(
    id: 'umbra_dust',
    properName: 'Umbra Dust',
    rarity: Rarity.common,
    lore: 'It does not settle so much as decide where to be.',
    tier: MoteTier.dust,
    element: MagicElement.umbra,
    value: 2,
  );

  static const umbraShard = MoteDef(
    id: 'umbra_shard',
    properName: 'Umbra Shard',
    rarity: Rarity.common,
    lore: 'Dust with an opinion.',
    tier: MoteTier.shard,
    element: MagicElement.umbra,
    value: 25,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Crystal is where the mote
  /// ladder is first FELT, so it must be a fight the player chose (ITEMS §8).
  static const umbraCrystal = MoteDef(
    id: 'umbra_crystal',
    properName: 'Umbra Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is decided, and it does not stop being decided.',
    tier: MoteTier.crystal,
    element: MagicElement.umbra,
    value: 150,
  );

  // ---- the gate ---------------------------------------------------------

  /// ⭐ **The second of the three Ethereal fragments** (§3.4): the Kept Third
  /// comes off Hallowmarch, the Written Third off The Collapsed Academy, and
  /// this one off here — *dark given a shape*.
  ///
  /// ⚠️ **Both bosses guarantee it on their `always` line, never weighted**
  /// (ENEMIES §2e.1): a run draws one boss of two, so a gate part behind the
  /// boss you did not draw would make mandatory progression a coin flip.
  ///
  /// ⚠️ **Gates are SHOWN, not spent** (ruling, 2026-09-21) — `gateItemIds`
  /// plus `PlayerProfile.openedGates`, the mechanism Pennycross already ships.
  /// ⚠️ `KeyDef` forces Bound and `value: 0` by construction, so the Third is
  /// exempt from §5.4's value-conservation audit rather than failing it.
  static const theDarkThird = KeyDef(
    id: 'the_dark_third',
    properName: 'The Dark Third',
    rarity: Rarity.rare,
    lore:
        'A third of something that was broken on purpose, into three, by '
        'someone who wanted all three carried a long way apart.',
    gates: 'the_eclipsed_citadel',
  );

  // ---- equipment: the Umbralweave set (Tailoring) ------------------------
  //
  // ⭐ **Set total: 88 HP · 6 acc · 6 dodge · 16/22 deflect** (§4.3). Against
  // the level-48 baseline of 632 HP that is +13.9% health — the flat-modifier
  // decay KINETIC §2.6 note 3 predicted, still inside the ±2% band the other
  // three Ethereal sets hold.
  // ⚠️ Every piece is a plain **Common** on purpose (§3.6): ITEMS §3.4 puts
  // set Tier III at L45 and Tier IV at L50, both inside this band, so Phase 8
  // adds sets BESIDE these rather than instead of them.

  /// ⭐ Accuracy lives on the hood, every quarter (§2.5).
  static const umbralweaveHood = EquipmentDef(
    id: 'umbralweave_hood',
    rarity: Rarity.common,
    lore:
        'The brim is straight because a straight brim is a line you can aim '
        'along in no light at all.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Umbralweave',
    modifiers: ItemModifiers(accuracyBonus: 6),
    salvage: [SalvageYield('umbralweave', 1, 2)],
    equipLevel: 48,
    value: 870,
  );

  static const umbralweaveRobe = EquipmentDef(
    id: 'umbralweave_robe',
    rarity: Rarity.common,
    lore:
        'Six layers of a cloth that gives nothing back. It is the warmest '
        'thing on the north face.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Umbralweave',
    modifiers: ItemModifiers(maxHpBonus: 42),
    salvage: [SalvageYield('umbralweave', 3, 4)],
    equipLevel: 48,
    value: 1740,
  );

  static const umbralweaveLeggings = EquipmentDef(
    id: 'umbralweave_leggings',
    rarity: Rarity.common,
    lore:
        'Quilted through. Nothing on this face has melted in living memory '
        'and neither will you.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Umbralweave',
    modifiers: ItemModifiers(maxHpBonus: 29),
    salvage: [SalvageYield('umbralweave', 2, 3)],
    equipLevel: 48,
    value: 1450,
  );

  /// ⭐ Dodge lives on the boots (§2.5), and the fiction agrees: a sole cut
  /// not to print in the ice is the whole stat.
  static const umbralweaveBoots = EquipmentDef(
    id: 'umbralweave_boots',
    rarity: Rarity.common,
    lore: 'Soft, black, and the sole is cut so it does not print in the ice.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Umbralweave',
    modifiers: ItemModifiers(maxHpBonus: 8, dodge: 6),
    salvage: [SalvageYield('umbralweave', 1, 2)],
    equipLevel: 48,
    value: 870,
  );

  /// ⭐ EV 3.5% — deflect chance × amount, the §2.1b reading. The glove is
  /// the piece you put in the way, and it is the quarter's Tailoring lane
  /// (§2.5): chance and amount always travel together.
  static const umbralweaveGloves = EquipmentDef(
    id: 'umbralweave_gloves',
    rarity: Rarity.common,
    lore:
        'Palms tripled. Out here the thing you put in the way is your hand '
        'and then it is your whole arm.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Umbralweave',
    modifiers: ItemModifiers(
      maxHpBonus: 9,
      deflectChance: 16,
      deflectAmount: 22,
    ),
    salvage: [SalvageYield('umbralweave', 1, 2)],
    equipLevel: 48,
    value: 870,
  );

  // ---- the chases -------------------------------------------------------
  //
  // ⭐⭐ **Both drops are crit DAMAGE** — Umbra's affinity (§2.5a), inherited
  // from Pyro — and ⚠️ **they are deliberately NOT a ladder.** The rare is
  // 8/+34; the epic is 6/+28 with 20 HP, so the **epic has strictly lower
  // crit than the rare**.
  // ✅ That is ITEMS §4.1a's *"low-chance/high-crit-damage glass cannon vs
  // high-accuracy consistent"* axis with both ends finally built: the rare is
  // the gamble, the epic is the version you can survive wearing.
  // 📝 **This is the most likely row in either contract to read as a bug.**
  // It is not; it is the one place the rarity ladder buys *safety* rather
  // than power, and ITEMS §9b.6a's lattice permits it because an Epic's
  // advantage is *capability* first.
  // ⚠️ **They are both rings and cannot be worn together**, which is what
  // makes the choice a choice.

  /// ⭐ **Rare — the mini-boss chase.** The gamble half of the pair.
  static const theConsideredRing = EquipmentDef(
    id: 'the_considered_ring',
    properName: 'The Considered Ring',
    rarity: Rarity.rare,
    lore:
        'It was made to fit one finger and it fits every finger. Somebody '
        'thought about that.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Thoughtglass',
    modifiers: ItemModifiers(critChance: 8, critDamage: 34),
    salvage: [SalvageYield('thoughtglass', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 49,
    value: 3100,
  );

  /// ⭐ **Epic — the boss chase**, and ⚠️ **lower crit than the Rare above
  /// it, on purpose.** Read the block comment before "fixing" these numbers.
  static const theDeliberateDark = EquipmentDef(
    id: 'the_deliberate_dark',
    properName: 'The Deliberate Dark',
    rarity: Rarity.epic,
    lore:
        'Not an absence. A decision, worn on the hand of whoever agrees with '
        'it.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Thoughtglass',
    modifiers: ItemModifiers(critChance: 6, critDamage: 28, maxHpBonus: 20),
    salvage: [SalvageYield('thoughtglass', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 51,
    value: 8800,
  );

  static const all = <ItemDef>[
    umbralweave,
    thoughtglass,
    umbraDust,
    umbraShard,
    umbraCrystal,
    theDarkThird,
    umbralweaveHood,
    umbralweaveRobe,
    umbralweaveLeggings,
    umbralweaveBoots,
    umbralweaveGloves,
    theConsideredRing,
    theDeliberateDark,
  ];
}
