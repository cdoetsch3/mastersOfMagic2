/// Everything The Sealed Garden can yield (Lv 49–53, Flora + Sanctus —
/// ETHEREAL_CONTRACT §4.4).
///
/// ⭐ **This zone is the proof of §2.5a's affinity structure.** Flora's lean
/// is healing and Sanctus's is healing plus shields, and ⭐ **both of this
/// zone's drops carry healing**. If the structure is wrong, this is the file
/// that has to be rewritten; if it is right, this is the file that says so.
///
/// ⚠️ **No mote family is defined here.** A hybrid normally names one, but
/// both of this zone's families belong elsewhere: ⭐⭐ `flora_*` is
/// `whispering_woods_items.dart`, the **level 1–5** catalogue — the deepest
/// cross-quarter mote reference in the game (§7.3) — and `sanctus_*` is
/// Hallowmarch's. The shipped rule is *"the mote lives with the zone that
/// first yields it"*, and the game's first element is exactly where the game
/// started.
///
/// ⚠️ **Nine defs, not §7.1's ten.** §4.4's catalogue table lists
/// `the_kept_third` struck through: §3.5's reconciliation moved the gate
/// fragment to **Hallowmarch**, so the Garden's count is 3 materials + 1
/// consumable + 5 equipment. §7.1's per-zone tally was written before that
/// ruling and has not been re-added; the reconciliation is the later
/// document. 📝 Hallowmarch is 13, not 12, for the same reason.
///
/// ⭐ **Three materials, because a hybrid gets three** (ITEMS §9b.8 ruling 7).
/// Worldroot feeds Potions, Orchard Amber feeds Jewelry, Thornpenitent Hide
/// feeds Tailoring. ⚠️ **The hide is kill-only** (§3.1): no node, and it must
/// never acquire one — a node for a hide is a second source that contradicts
/// its own fiction.
///
/// ⚠️⚠️ **`regrowPercent` had exactly one source in the shipped game — The
/// Charlock, at 2 — and this zone triples the count.** ITEMS §4.2 flags it as
/// needing to route through `TurnStatus`; SYSTEMS §2 says the seam exists.
/// 📝 **`regrowPercent: 3` on a 1,264 HP bar is 38 HP a turn, every turn,
/// forever** — the single most tunable number in either contract, and the one
/// a long duel will find first.
///
/// ⚠️ **`orchard_loop` and `the_gardeners_loop` are both rings and both
/// Loops**, so a player chooses between +15%/1% with 25 HP and +18%/2% with
/// 25 HP. That is a 3-point and a 1-point step for a whole rarity tier, which
/// is ITEMS §9b.6a's *"Rare ≈ Master, Epic marginally stronger"* read
/// literally. 📝 If a Rare should feel bigger than that, widen it here.
///
/// ⚠️ **No `setId`, no `setTier`, no socket and no gem** (§3.6): ITEMS §3.4
/// puts set Tier III at L45 and Tier IV at L50, both inside this band, so
/// every armour piece here is a deliberate plain Common that Phase 8 can add
/// sets *beside* rather than *instead of*.
library;

// ⚠️ No `mom_engine` import: every other catalogue in the quarter needs it for
// `MagicElement` on a `MoteDef`, and this one defines no mote family at all.
import '../item_def.dart';

abstract final class SealedGardenItems {
  // ---- materials --------------------------------------------------------

  /// Potions, tier 9 — the band's reagent, and `worldroot_tonic`'s only input
  /// (§5.1 #23, `worldroot` ×3).
  ///
  /// ⭐ Dug from **outside** the wall, which is the detail that carries the
  /// zone: the garden has been reaching out this whole time and nobody has
  /// been let in.
  static const worldroot = MaterialDef(
    id: 'worldroot',
    properName: 'Worldroot',
    rarity: Rarity.common,
    lore:
        'Dug from under the wall, on the outside. Whatever is in there has '
        'been sending something out this whole time.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 9,
    value: 55,
  );

  /// ⚠️ Uncommon, which is the gem grade — `uncommon` survives on gem-grade
  /// materials and Crystal motes and nowhere else in this quarter.
  static const orchardAmber = MaterialDef(
    id: 'orchard_amber',
    properName: 'Orchard Amber',
    rarity: Rarity.uncommon,
    lore:
        'Sap off a tree nobody has pruned in four hundred years, and it is '
        'still the right shape.',
    skill: CraftSkill.jewelry,
    tier: 9,
    value: 260,
  );

  /// ⚠️ **A hide, and therefore kill-only** (§3.1). It has no gather node and
  /// must not acquire one. ⭐ It is also the zone's `hide` drop role, which
  /// lands on the two Flora commons — the Whisperling and the Thornpenitent
  /// the hide is named for.
  static const thornpenitentHide = MaterialDef(
    id: 'thornpenitent_hide',
    properName: 'Thornpenitent Hide',
    rarity: Rarity.common,
    lore:
        'Off something that was let in and did not leave. The thorns grew '
        'through it rather than into it.',
    skill: CraftSkill.tailoring,
    tier: 9,
    value: 950,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Tonic form: over-time, never a lump (§3.3's settled vocabulary —
  /// *Ration = 35% of the band floor's health · Draught = 40% · Tonic = 24%
  /// total*). 53×3 = 159 against a level-49 bar of 657 is 24.2%.
  ///
  /// ⚠️ **The quarter's last Tonic, and there is no Tonic above 49** (§3.3):
  /// a Tonic is a *tempo* item that pays after the opponent's read, and past
  /// level 52 a three-turn payout is often three turns the fight does not
  /// have.
  ///
  /// 📝 **Value is 165 verbatim from §3.3/§4.4, and Σ(inputs) is also 165**
  /// (`worldroot` ×3 at 55). That is the ECONOMY §8.6 *boundary* case — zero
  /// headroom rather than a violation — and it is the recipe lane's to log,
  /// not this one's to "fix" by moving a published number.
  static const worldrootTonic = BeltableDef(
    id: 'worldroot_tonic',
    properName: 'Worldroot Tonic',
    rarity: Rarity.common,
    lore:
        'Earthy, sweet at the back, and it keeps working. Three mouthfuls in '
        'one bottle and the bottle knows the order.',
    effect: ItemEffect(healPerTurn: 53, healTurns: 3),
    value: 165,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The belt-capacity ladder's Ethereal rung: … Corebiter 7 → Penitent
  /// **8**. ⚠️ Belts carry `beltSlots` and nothing else — capacity is the one
  /// axis that is deliberately *not* combat power (ITEMS §6b.2).
  /// ⚠️ **`properName` stays null**: this is crafted (§5.1 #20), so its name
  /// is composed from material + form by the §9b.5a grammar rather than
  /// written down here where it could drift.
  static const penitentBelt = EquipmentDef(
    id: 'penitent_belt',
    rarity: Rarity.common,
    lore:
        'Eight loops. The thorns are on the inside, which whoever made it '
        'will have meant.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Thornpenitent',
    modifiers: ItemModifiers(beltSlots: 8),
    salvage: [SalvageYield('thornpenitent_hide', 1, 2)],
    equipLevel: 52,
    value: 2190,
  );

  /// ⭐ The four-line crit ring, and ⚠️ **the one item in this file that is
  /// not about healing** — it is cut from Sunless Reach opal at Rimeholt
  /// (§5.1 #28), so it is the garden's only genuinely imported piece.
  /// ⚠️ Crafted, so `properName` stays null.
  static const eclipseSignet = EquipmentDef(
    id: 'eclipse_signet',
    rarity: Rarity.common,
    lore:
        'Sunless Reach opal, cut at Rimeholt into the only shape that keeps '
        'the line.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Eclipse Opal',
    modifiers: ItemModifiers(
      accuracyBonus: 3,
      dodge: 3,
      critChance: 6,
      critDamage: 10,
    ),
    salvage: [SalvageYield('eclipse_opal', 1, 2)],
    equipLevel: 50,
    value: 1100,
  );

  /// ⭐ **The game's best craftable ring for a support build** (§4.4), and the
  /// Common half of the pair: +15% healing received, 1% regrow, 25 HP.
  /// ⚠️ Crafted (§5.1 #30), so `properName` stays null and the grammar
  /// composes *Orchard Amber Loop*.
  static const orchardLoop = EquipmentDef(
    id: 'orchard_loop',
    rarity: Rarity.common,
    lore:
        'Garden amber in a plain band. It is warm, and it does not stop '
        'being warm.',
    slot: EquipSlot.ring,
    form: 'Loop',
    material: 'Orchard Amber',
    modifiers: ItemModifiers(
      maxHpBonus: 25,
      healingReceivedPercent: 15,
      regrowPercent: 1,
    ),
    salvage: [SalvageYield('orchard_amber', 1, 2)],
    equipLevel: 54,
    value: 1750,
  );

  /// ⭐ The mini pool's Rare chase, and the Rare version of exactly the same
  /// idea as [orchardLoop] — ⚠️ **same slot, same form**, so the player picks
  /// one. The step is +3 healing received and +1 regrow for a whole rarity
  /// tier, which is ITEMS §9b.6a read literally.
  static const theGardenersLoop = EquipmentDef(
    id: 'the_gardeners_loop',
    properName: "The Gardener's Loop",
    rarity: Rarity.rare,
    lore:
        'Whoever was last in there took nothing and left this on the '
        'gatepost.',
    slot: EquipSlot.ring,
    form: 'Loop',
    material: 'Orchard Amber',
    modifiers: ItemModifiers(
      maxHpBonus: 25,
      healingReceivedPercent: 18,
      regrowPercent: 2,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 51,
    value: 3800,
  );

  /// ⭐ The zone's Epic, and the arrival text worn as a garment — *"inside,
  /// everything is in leaf and in season at once."* ⚠️ It carries
  /// **`regrowPercent: 3`**, the largest in the game: 38 HP a turn on a
  /// best-in-slot level-60 bar, forever. 📝 That is the tuning knob the whole
  /// §4.4 note is about.
  static const theSeasonAtOnce = EquipmentDef(
    id: 'the_season_at_once',
    properName: 'The Season At Once',
    rarity: Rarity.epic,
    lore:
        'Inside, everything is in leaf and in season at once. Somebody wove '
        'that.',
    slot: EquipSlot.robeTop,
    form: 'Vestment',
    material: 'Worldroot',
    modifiers: ItemModifiers(
      maxHpBonus: 60,
      healingReceivedPercent: 15,
      regrowPercent: 3,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 53,
    value: 10500,
  );

  /// ✅ **9 defs** — 3 materials + 1 consumable + 5 equipment, and no mote and
  /// no key. See the library note for why that is nine rather than §7.1's ten.
  static const all = <ItemDef>[
    worldroot,
    orchardAmber,
    thornpenitentHide,
    worldrootTonic,
    penitentBelt,
    eclipseSignet,
    orchardLoop,
    theGardenersLoop,
    theSeasonAtOnce,
  ];
}
