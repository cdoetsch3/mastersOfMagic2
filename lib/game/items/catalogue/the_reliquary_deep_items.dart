/// Everything The Reliquary Deep can yield (Lv 52–56, Sanctus + Umbra —
/// ETHEREAL_CONTRACT §4.6).
///
/// ⭐⭐ **The only hybrid in either quarter whose three materials are all
/// gatherable and none is a hide** (§3.1) — *a corridor someone made, in a
/// mountain, with no animals in it.* Censer Resin feeds Potions, Reliquary
/// Gold feeds Jewelry, Unleft Linen feeds Tailoring, and §6 gives the zone
/// three nodes to match. ⚠️ A hide item must never be added here: the zone's
/// `hide` drop role already resolves to `reliquary_gold`, the second
/// gatherable material, by §3.5's ruling 1.
///
/// ⚠️⚠️ **This zone defines NO motes.** It pays in `sanctus_*` and `umbra_*`,
/// and both families live with the pure zone that first yields them (§3.2):
/// Sanctus in **Hallowmarch**, Umbra in **The Umbral Wastes**. A builder
/// looking for `sanctus_dust` in this file will not find it, and that is
/// correct — the same rule that put `arcane_*` in The Glass Archive rather
/// than The Collapsed Academy.
///
/// ⚠️⚠️ **This zone defines NO key.** §4.6's catalogue table lists
/// `the_written_third` struck through: §3.4's reconciliation moved the gate
/// fragment to **The Collapsed Academy**, because the three Ethereal Thirds
/// fall in the quarter's three PURE zones. ⭐ **So this file holds 12 defs,
/// not the 13 §7.1 counts** — §7.1's per-zone figure predates the move and is
/// the one number in the appendix the reconciliation invalidated. 📝 The
/// quarter's total drops 79 → 78 if nothing else absorbs it; the Academy's 8
/// becomes 9, so the quarter total is unchanged and only the two per-zone
/// figures swap.
///
/// ⭐ **`aetherglass_locket` is the odd one out**: crafted (§5.1 #29), Common,
/// and it spends the last Celestial banked gem — `aetherglass`, gathered in
/// The Glass Archive at 43–47 and finally set by a jeweller at Rimeholt. ⭐ It
/// deliberately carries **no deflection**, although Arcane's affinity is
/// deflection, because §2.1b's cap has no room left for a fourth slot.
///
/// ⭐ **Unleft Linen set total: 115 HP · 6 acc · 7 dodge · 18/26 deflect** —
/// **+15.0%** against the level-53 baseline of 769, the same proportion
/// Seawrack held at level 16, thirty-seven levels and four material tiers
/// later. ⭐ **It is the last armour set in the game**, and `unleft_gloves`'
/// `deflectAmount: 26` is the largest single deflect amount a player can
/// wear — §2.1b's whole budget is built around it. 📝 Move the 26 and that
/// proof moves with it.
///
/// ⚠️ **Every armour piece is a plain Common on purpose** (§3.6): ITEMS §3.4
/// puts set Tier III at L45 (Mythic) and Tier IV at L50 (Legendary), both
/// inside this band, so Phase 8 can add sets *beside* these rather than
/// instead of them. No `setId`, no `setTier`, no enchant field, no gem.
library;

// ⚠️ No `mom_engine` import, unlike every sibling catalogue: that import is
// there for `MagicElement` on a `MoteDef`, and this zone defines no motes.
import '../item_def.dart';

abstract final class ReliquaryDeepItems {
  // ---- materials --------------------------------------------------------

  /// Potions, tier 9 — `censer_draught`'s only input (§5.1 #24,
  /// `censer_resin` ×4).
  static const censerResin = MaterialDef(
    id: 'censer_resin',
    properName: 'Censer Resin',
    rarity: Rarity.common,
    lore:
        'Scraped out of the censers along the warm stretch. They have not '
        'been lit in four hundred years and the resin is not cold.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 9,
    value: 53,
  );

  /// ⚠️ Uncommon, which is the gem grade — `uncommon` survives on gem-grade
  /// materials and Crystal motes and nowhere else in this quarter. ⭐ It is
  /// the zone's **second** gatherable material, which is what makes it the
  /// resolution of the `hide` role Corridor Crawler carries (§3.5 ruling 1).
  static const reliquaryGold = MaterialDef(
    id: 'reliquary_gold',
    properName: 'Reliquary Gold',
    rarity: Rarity.uncommon,
    lore:
        'Off the fittings. Soft, pure, and somebody had a great deal of it '
        'to spare on a corridor.',
    skill: CraftSkill.jewelry,
    tier: 9,
    value: 340,
  );

  /// Tailoring, tier 9 — the last armour material in the game. ⚠️ **Not a
  /// hide**, despite being the cloth of a five-piece set: it was folded and
  /// left on an altar, so it has a node (`rd_altar_linen`) and always will.
  static const unleftLinen = MaterialDef(
    id: 'unleft_linen',
    properName: 'Unleft Linen',
    rarity: Rarity.common,
    lore:
        'Altar cloth. Still folded, still square, still on the altar. Nobody '
        'took it and nobody came back for it.',
    skill: CraftSkill.tailoring,
    tier: 9,
    value: 520,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Draught form: a lump, never over-time (§3.3's settled vocabulary —
  /// *Ration = 35% of the band floor's health · Draught = 40% · Tonic = 24%
  /// total*). 295 against a level-52 bar of 739 is 39.9%.
  /// ⚠️ **Value is not priced against the heal number** (the 2026-09-21
  /// ruling): 210 sits just under Σ(inputs) = 4 × 53 = 212 so
  /// buy→craft→vendor cannot profit (§5.5).
  static const censerDraught = BeltableDef(
    id: 'censer_draught',
    properName: 'Censer Draught',
    rarity: Rarity.common,
    lore:
        'Red-gold, resinous, and it goes down warm. It is the only thing '
        'anyone has ever taken out of here that helped.',
    effect: ItemEffect(heal: 295),
    value: 210,
  );

  // ---- the Unleft Linen set ---------------------------------------------
  //
  // ⭐ The last armour set in the game, crafted at Tailoring gate 48
  // (§5.1 #15–19). ⚠️ **`properName` stays null on all five**: crafted gear
  // composes its name from material + form by the §9b.5a grammar, and a
  // written name here is exactly the drift that grammar exists to prevent.

  static const unleftHood = EquipmentDef(
    id: 'unleft_hood',
    rarity: Rarity.common,
    lore:
        'Cut from altar cloth by somebody who needed a hood more than they '
        'needed the argument.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Unleft Linen',
    modifiers: ItemModifiers(accuracyBonus: 6),
    salvage: [SalvageYield('unleft_linen', 1, 2)],
    equipLevel: 53,
    value: 1560,
  );

  static const unleftRobe = EquipmentDef(
    id: 'unleft_robe',
    rarity: Rarity.common,
    lore:
        'Six layers of a cloth that was folded and left. It has never once '
        'been worn out of doors before now.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Unleft Linen',
    modifiers: ItemModifiers(maxHpBonus: 55),
    salvage: [SalvageYield('unleft_linen', 1, 2)],
    equipLevel: 53,
    value: 3120,
  );

  static const unleftLeggings = EquipmentDef(
    id: 'unleft_leggings',
    rarity: Rarity.common,
    lore:
        'Quilted through with the same cloth. It is warm, and nobody is '
        'coming to ask for it back.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Unleft Linen',
    modifiers: ItemModifiers(maxHpBonus: 38),
    salvage: [SalvageYield('unleft_linen', 1, 2)],
    equipLevel: 53,
    value: 2600,
  );

  static const unleftBoots = EquipmentDef(
    id: 'unleft_boots',
    rarity: Rarity.common,
    lore: 'Soft-soled, because the corridor is stone and the stone carries.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Unleft Linen',
    modifiers: ItemModifiers(maxHpBonus: 10, dodge: 7),
    salvage: [SalvageYield('unleft_linen', 1, 2)],
    equipLevel: 53,
    value: 1560,
  );

  /// ⚠️⚠️ **`deflectAmount: 26` is the largest single deflect amount a player
  /// can wear**, and §2.1b's entire budget is built around it: deflect
  /// *amount* sums across pieces, so only one piece of a set may carry it.
  /// 18/26 is an EV of 4.7% on its own. 📝 Moving the 26 moves the proof that
  /// the worst legal level-60 assembly lands on ITEMS §4.1a's cap of 50
  /// rather than over it.
  static const unleftGloves = EquipmentDef(
    id: 'unleft_gloves',
    rarity: Rarity.common,
    lore:
        'Palms quadrupled. Whatever the second hand was doing down here, it '
        'did it with its hands.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Unleft Linen',
    modifiers: ItemModifiers(
      maxHpBonus: 12,
      deflectChance: 18,
      deflectAmount: 26,
    ),
    salvage: [SalvageYield('unleft_linen', 1, 2)],
    equipLevel: 53,
    value: 1560,
  );

  // ---- jewelry ----------------------------------------------------------

  /// ⭐ **The last Celestial banked gem, finally spent** (§5.1 #29:
  /// `aetherglass` ×3 + `reliquary_gold` ×2). A player who ignored every jewel
  /// material from level 15 onward arrives at Rimeholt with an empty bag; this
  /// is the last of the seven bank-and-spend promises to close.
  /// ⚠️ **Crafted, so `properName` stays null** — "Aetherglass Locket" is
  /// composed, not written.
  static const aetherglassLocket = EquipmentDef(
    id: 'aetherglass_locket',
    rarity: Rarity.common,
    lore:
        'Archive glass, carried up the mountain, and finally set by somebody '
        'who could.',
    slot: EquipSlot.neck,
    form: 'Locket',
    material: 'Aetherglass',
    modifiers: ItemModifiers(
      maxHpBonus: 45,
      shieldStrengthPercent: 12,
      healingReceivedPercent: 10,
    ),
    salvage: [SalvageYield('aetherglass', 1, 2)],
    equipLevel: 53,
    value: 1300,
  );

  // ---- the two named pieces ---------------------------------------------

  /// ⭐⭐ **The zone in one item.** Sanctus's healing and shields from the hand
  /// that consecrated it; Umbra's crit damage from the hand that did not leave
  /// it alone (§2.5a). ⚠️ **It is the only piece in either contract that
  /// carries both halves of a hybrid's affinities and a third stat** — 📝 if
  /// that is one too many, cut the `critDamage: 20`.
  static const censerPendant = EquipmentDef(
    id: 'censer_pendant',
    properName: 'Censer Pendant',
    rarity: Rarity.rare,
    lore: 'Two hands made it. You can see where they disagreed.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Reliquary Gold',
    modifiers: ItemModifiers(
      healingReceivedPercent: 15,
      shieldStrengthPercent: 15,
      critDamage: 20,
    ),
    salvage: [SalvageYield('reliquary_gold', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 54,
    value: 5200,
  );

  /// ⭐ The zone's one Epic, off the boss table. Health to walk it, dodge to
  /// keep walking it, and healing received because the thing that consecrated
  /// the corridor never stopped offering.
  static const theUnconsecrated = EquipmentDef(
    id: 'the_unconsecrated',
    properName: 'The Unconsecrated',
    rarity: Rarity.epic,
    lore:
        'Somebody walked the whole corridor in these and was not permitted, '
        'and walked it anyway.',
    slot: EquipSlot.boots,
    form: 'Tread',
    material: 'Reliquary Gold',
    modifiers: ItemModifiers(
      maxHpBonus: 32,
      dodge: 6,
      healingReceivedPercent: 10,
    ),
    salvage: [SalvageYield('reliquary_gold', 1, 2)],
    tradability: Tradability.untradeable,
    equipLevel: 56,
    value: 14500,
  );

  /// ✅ **12 defs** — 3 materials + 1 consumable + 8 equipment. ⚠️ §7.1's
  /// per-zone figure says 13 and counts the key §3.4 moved to The Collapsed
  /// Academy; see this file's library comment.
  static const all = <ItemDef>[
    censerResin,
    reliquaryGold,
    unleftLinen,
    censerDraught,
    unleftHood,
    unleftRobe,
    unleftLeggings,
    unleftBoots,
    unleftGloves,
    aetherglassLocket,
    censerPendant,
    theUnconsecrated,
  ];
}
