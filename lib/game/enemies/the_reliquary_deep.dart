/// The Reliquary Deep bestiary — Lv 52–56, Sanctus + Umbra
/// (ETHEREAL_CONTRACT §4.6).
///
/// ⭐ **Theme: two hands worked on this, and the second has not finished.**
/// From the arrival text — *"A corridor that someone consecrated and someone
/// else did not leave alone. It gets warmer the further you go, and the far
/// door has been shut for longer than the order that shut it lasted."*
/// ⭐ **The warmth in the middle is the tell** — the corridor is not empty.
///
/// ⭐⭐ **Both boss names are lifted straight from the arrival line, and the
/// elements split on the same seam** (ENEMIES §2e): *What Was Consecrated* is
/// Sanctus, the first hand; *What Did Not Leave It Alone* is Umbra, the
/// second. ⚠️ Do not "fix" the pair into a mirror — a Juggernaut of what was
/// made and a Tyrant of what is still unmaking it is the zone's whole
/// sentence, and the archetypes are the two halves of it.
///
/// ⚠️ **This zone assigns element per creature, not "both" by default**
/// (§4.6's roster table). Read the table before touching an element list:
/// the made things are Sanctus, the residues are Umbra, and only the two the
/// roster marks `sanctus + umbra` carry both.
///
/// ⚠️ **No Aspect here** (ENEMIES §2g, ETHEREAL §2.4) — and ⭐ Sanctus never
/// gets one anywhere in the game. A mutant that promotes either boss to
/// `Archetypes.aspect` still compiles; the zone test is what stops it.
///
/// ⚠️⚠️ **This zone has NO key.** The gate fragment `the_written_third` was
/// MOVED OUT to **The Collapsed Academy** at reconciliation (§3.4): the three
/// Ethereal Thirds fall in the quarter's three PURE zones, deriving the gate
/// the same way the Primal proofs and the Celestial essences derive theirs.
/// §4.6's `_bossDrops` block still shows the fragment on the `always` line
/// because it predates the move — ⭐ **the struck row in §4.6's catalogue
/// table is the current reading**, and neither boss below carries a key.
/// ⚠️ That also means §2e.1's "keys on BOTH bosses" rule simply does not
/// apply here: there is no key to double up.
///
/// ⚠️ **The `the Siphon` row in §4.6's drop table is a stale LABEL, not a
/// creature.** ENEMIES §2f cut the Siphon from this zone — *"this zone's idea
/// is unfinished work, not appetite"* — and Corridor Crawler is a
/// **Skirmisher**. The row's ids are still correct and are used verbatim;
/// only the role's name moved. ⭐ Nothing in this file lifesteals.
///
/// ⭐ **Corridor Crawler's `hide` role resolves to `reliquary_gold`** — §3.5
/// ruling 1: a `hide` in a zone that defines no hide item pays in the zone's
/// SECOND gatherable material. ⚠️ **This zone has no hide at all** (§3.1: the
/// only hybrid in either quarter with three gatherable materials) — *a
/// corridor someone made, in a mountain, with no animals in it.*
///
/// ⚠️ **Combat stats (§2.3) copy each archetype's row verbatim**, reaching
/// the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately blank (`EnemyCombatStats.none`, the field's own default):
/// §2.3 calls it the yardstick, and a yardstick with a thumb on the scale
/// stops being one.
///
/// ⭐ **Reliquary Colossus keeps the full Redoubt row, 35/30.** §2.3
/// *recommends* dropping this zone's Redoubt to 25/24 (EV 6.0%) — a dungeon
/// wall a player cannot retreat from — but the recommendation is conditional:
/// *"unless the fatigue clock has shipped."* ⭐ **It has** —
/// `DuelEngine.fatigueThreshold`/`fatiguePerTurn` are live, so the stalemate
/// the deviation guards against already terminates, and the condition is not
/// met. 📝 If the probe still finds the wall too long, 25/24 is the one-line
/// change §2.3 already wrote out.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_reliquary_deep_test
/// .dart` resolves every id against [ItemCatalogue] instead. ⚠️
/// **`sanctus_*` (Hallowmarch), `umbra_*` (The Umbral Wastes) and
/// `climbers_ration` (Hallowmarch) are cross-lane references** owned by
/// sibling Ethereal worktrees; they resolve once the merge coordinator lands
/// the lanes together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_reliquary_deep';
const _both = [MagicElement.sanctus, MagicElement.umbra];
const _sanctus = [MagicElement.sanctus];
const _umbra = [MagicElement.umbra];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.6's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('sanctus_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('umbra_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class ReliquaryDeepBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster — ENEMIES §2e: *"the yardstick, and the
  /// one thing in the corridor still doing the job it was left."*
  /// ⚠️ §2f moved it off Sentinel: a keeper that is still keeping fights you
  /// straight, it does not hide.
  static const reliquaryKeeper = EnemyDef(
    id: 'reliquary_keeper',
    name: 'Reliquary Keeper',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _sanctus,
    lore:
        'A robed figure of ordinary height that stands at one of the wall '
        'niches and does not look away from it, stepping aside only far '
        'enough to let a person past and then stepping back. Whatever the '
        'niche held is not in it.',
    moves: [
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'rd_keepthepost',
        name: 'Keep the Post',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'rd_turnthelock',
        name: 'Turn the Lock',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      Spell(
        id: 'rd_standthewatch',
        name: 'Stand the Watch',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: _materialACommon,
  );

  /// ⭐⭐ ENEMIES §2b: *spores, fumes, venom → Blighter.* A censer is smoke,
  /// and **Umbra's Creeping Dark is the status that hides the board** — the
  /// fiction and the passive are the same thing. ⚠️ §2f moved it off
  /// Glasswing to get here.
  static const censerWraith = EnemyDef(
    id: 'censer_wraith',
    name: 'Censer-Wraith',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _umbra,
    lore:
        'A column of standing smoke the height of a person, leaning out of '
        'one of the hanging censers without ever fully leaving it. It '
        'thickens toward the corridor and thins toward the censer, and it '
        'has been doing that long enough to have stained the ceiling.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      // ⭐ Both moves multi-hit (§1.3's per-archetype rule) — a Blighter wins
      // by out-lasting rather than out-hitting, and smoke arrives in wisps.
      Spell(
        id: 'rd_letthesmokein',
        name: 'Let the Smoke In',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'rd_fillthecorridor',
        name: 'Fill the Corridor',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: _materialBCommon,
  );

  /// ⭐ What did not leave: a residue with almost nothing to it, and
  /// everything behind it. ⚠️ 0.50 HP and 1.70 damage — the raws stay small
  /// **because the archetype multiplies them**.
  static const theUnleft = EnemyDef(
    id: 'the_unleft',
    name: 'The Unleft',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _umbra,
    lore:
        'A person-shaped absence in the dust of the floor, upright, that the '
        'eye reads as a figure only because the dust around it is '
        'undisturbed. There is more of it the longer it is looked at and '
        'none of it when it is not.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'rd_thinout',
        name: 'Thin Out',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'rd_showwhatisbehind',
        name: 'Show What Is Behind',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: _materialBCommon,
  );

  /// ⚠️ −8 accuracy and a five-charge swing: ENEMIES §2e gives this one the
  /// job of **reading the charge bar**. It is completely telegraphed and that
  /// is the lesson, not a weakness.
  static const boneReliquary = EnemyDef(
    id: 'bone_reliquary',
    name: 'Bone-Reliquary',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _sanctus,
    lore:
        'A gilt casket the size of a man, standing on end and walking on the '
        'stubs of its own carrying-poles, its lid swung back on one hinge. '
        'What is inside it is arranged, and arranged carefully, and it is '
        'not one person.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'rd_openthelid',
        name: 'Open the Lid',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'rd_spillthewholecasket',
        name: 'Spill the Whole Casket',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: _materialACommon,
  );

  /// ⭐ *It comes down the warm part of the corridor first* (ENEMIES §2e) —
  /// and a Skirmisher's whole teaching is that it acts before you do. ⚠️
  /// **Siphon cut** (§2f): this zone's idea is unfinished work, not appetite,
  /// so nothing here drinks. It is the roster's only creature carrying both
  /// elements among the commons.
  static const corridorCrawler = EnemyDef(
    id: 'corridor_crawler',
    name: 'Corridor Crawler',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _both,
    lore:
        'Long and low and about the length of two people, moving along the '
        'join between wall and floor rather than down the middle. It always '
        'arrives from the warm end, and it is warm itself to stand near.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      // ⚠️ Priority 5 (quick) on both — it beats aux and regular spells to
      // the board but never a shield. The tempo lean IS the cost band (§2.5).
      Spell(
        id: 'rd_comedownthewarmpart',
        name: 'Come Down the Warm Part',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'rd_reachyoufirst',
        name: 'Reach You First',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    // ⭐ §4.6's "the Siphon" row, verbatim — and its `hide` role pays in
    // `reliquary_gold`, the zone's SECOND gatherable material (§3.5 ruling 1).
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 20),
        DropEntry('reliquary_gold', weight: 65),
        DropEntry('censer_draught', weight: 15),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const antechoir = EnemyDef(
    id: 'antechoir',
    name: 'Antechoir',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _sanctus,
    lore:
        'The room before the choir, walking: a half-circle of carved stalls '
        'two people high, curved inward as though around a singer, with '
        'nobody in any of the seats. It keeps the shape of an audience.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'rd_takeupthefirstnote',
        name: 'Take Up the First Note',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'rd_closethehalfcircle',
        name: 'Close the Half-Circle',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'rd_singitallatonce',
        name: 'Sing It All at Once',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition — a wall that erodes you, in a dungeon you
  /// cannot retreat from. ⚠️ Keeps the full 35/30 row; see the library
  /// comment for why §2.3's conditional 25/24 deviation does not apply.
  static const reliquaryColossus = EnemyDef(
    id: 'reliquary_colossus',
    name: 'Reliquary Colossus',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _sanctus,
    lore:
        'A reliquary built to the scale of the corridor rather than of a '
        'hand, filling it wall to wall, gold-fitted over pale stone and '
        'moving at the pace of something that has never needed to hurry. '
        'Every face of it is a door and none of them opens.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'rd_leanonyou',
        name: 'Lean On You',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'rd_sealthepassage',
        name: 'Seal the Passage',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'rd_pressitshut',
        name: 'Press It Shut',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ *The one that did not leave it alone, and is quick about it*
  /// (ENEMIES §2e). ⚠️ Cost capped at 4 (§1.3): at L56 a mini five-charge raw
  /// lands well past the bar, and the archetype is a two-cast kill, not a
  /// one-shot.
  static const theSecondHand = EnemyDef(
    id: 'the_second_hand',
    name: 'The Second Hand',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _umbra,
    lore:
        'One arm and one shoulder, person-scaled, reaching out of the wall '
        'up to the elbow and working at something just beyond where it can '
        'reach. It has taken the gold off four feet of fitting on either '
        'side of itself and has not stopped.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'rd_prisethegoldoff',
        name: 'Prise the Gold Off',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⭐ The finisher rider: it is already most of the way through you.
      Spell(
        id: 'rd_finishthework',
        name: 'Finish the Work',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 25),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ **The tell from the arrival line, given a stat block.** The Hexer's
  /// signature is priority, not status: it always connects, it is ahead of
  /// the board, and one of its moves simply does not care about a wall.
  /// 📝 The engine has no creature-applied debuff yet, so the archetype is
  /// written with the levers that actually resolve.
  static const warmMiddle = EnemyDef(
    id: 'warm_middle',
    name: 'Warm Middle',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'No edge and no surface — a stretch of corridor perhaps thirty paces '
        'long that is blood-warm to stand in and cools from both ends '
        'inward. It is in a different part of the corridor each time anyone '
        'comes back.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'rd_warmthefloor',
        name: 'Warm the Floor',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'rd_bethereallalong',
        name: 'Be There All Along',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'rd_getinsidethestone',
        name: 'Get Inside the Stone',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// ⭐⭐ **The first hand, and the name is the arrival line's own.** Sanctus,
  /// a Juggernaut: what was made here is a mass, it is slow, and it is still
  /// doing the thing it was made to do. ⚠️ It does not win by damage — it
  /// wins by still being there.
  static const whatWasConsecrated = EnemyDef(
    id: 'what_was_consecrated',
    name: 'What Was Consecrated',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _sanctus,
    lore:
        'The far end of the corridor, arriving: floor, walls and ceiling '
        'together, pale stone banded in gold, moving toward the entrance at '
        'the speed of a slow walk and taking the corridor with it. There is '
        'no gap at any edge to go around.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'rd_holdwhatwasgiven',
        name: 'Hold What Was Given',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'rd_shutthefardoor',
        name: 'Shut the Far Door',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'rd_bringthewholerite',
        name: 'Bring the Whole Rite',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// ⭐⭐ **The second hand, and it has not finished.** Umbra, a Tyrant: the
  /// archetype whose threat is its *intelligence*, which is exactly the
  /// difference between the two bosses — the first is a weight, the second is
  /// a decision that keeps being taken. ⚠️ Not an Aspect (§2g), and not a
  /// mirror of its partner.
  static const whatDidNotLeaveItAlone = EnemyDef(
    id: 'what_did_not_leave_it_alone',
    name: 'What Did Not Leave It Alone',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _umbra,
    lore:
        'Whatever is standing there is the size of a person and is made out '
        'of what it has taken off the walls — gold, stone, cloth, and the '
        'marks of the work itself. It stops when it is watched and it is '
        'further along every time it is looked at again.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
    moves: [
      Spell(
        id: 'rd_workatit',
        name: 'Work at It',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'rd_undowhatwasdone',
        name: 'Undo What Was Done',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'rd_nevergetfinished',
        name: 'Never Get Finished',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// §4.6's **material-A common ×2** row — the two Sanctus commons that are
  /// made of something. ⭐ The `climbers_ration` bonus is the quarter's
  /// drop-only Ration (§3.3), owned by the Hallowmarch lane.
  static const _materialACommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 12),
      DropEntry('unleft_linen', weight: 74, min: 1, max: 3),
      DropEntry('sanctus_shard', weight: 5),
      DropEntry('sanctus_dust', weight: 9, min: 1, max: 2),
    ],
    bonus: [DropEntry('climbers_ration', chance: 0.02)],
  );

  /// §4.6's **material-B common ×2** row — the two Umbra commons. ⚠️ The
  /// roster's `drops` column says only `mote` for these two; §4.6's table is
  /// the id authority and puts `censer_resin` on the row as well. The roster
  /// names ROLES, the contract names IDS (§2e.1), so there is no conflict to
  /// resolve — the contract wins on ids.
  static const _materialBCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 15),
      DropEntry('censer_resin', weight: 72, min: 1, max: 2),
      DropEntry('umbra_shard', weight: 5, min: 1, max: 2),
      DropEntry('umbra_dust', weight: 8, min: 2, max: 3),
    ],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.6) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  /// ⭐ `censer_pendant` at weight 5 of 100 is the zone's Rare chase.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('sanctus_shard'),
      DropEntry('umbra_shard'),
      DropEntry('sanctus_dust', min: 1, max: 3),
      DropEntry('umbra_dust', min: 1, max: 3),
      DropEntry('sanctus_crystal', chance: 0.15),
      DropEntry('umbra_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('unleft_linen', weight: 35, min: 2, max: 4),
      DropEntry('censer_resin', weight: 30, min: 2, max: 4),
      DropEntry('reliquary_gold', weight: 30, min: 1, max: 2),
      DropEntry('censer_pendant', weight: 5),
    ],
  );

  /// ⚠️⚠️ **No key on this line.** §4.6's block shows `the_written_third ×1
  /// GUARANTEED` here; §3.4's reconciliation moved that fragment to The
  /// Collapsed Academy and §4.6's own catalogue table strikes it through.
  /// The Reliquary Deep is a dead-end dungeon, not a gate zone, and the
  /// doubled Crystal payout is the standard hybrid mote shape rather than a
  /// consolation for lacking one.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('sanctus_crystal', min: 1, max: 2),
      DropEntry('umbra_crystal', min: 1, max: 2),
      DropEntry('sanctus_shard', min: 1, max: 2),
      DropEntry('umbra_shard', min: 1, max: 2),
      DropEntry('sanctus_dust', min: 3, max: 6),
      DropEntry('umbra_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('unleft_linen', weight: 35, min: 4, max: 8),
      DropEntry('censer_resin', weight: 20, min: 3, max: 6),
      DropEntry('reliquary_gold', weight: 15, min: 2, max: 4),
      DropEntry('censer_pendant', weight: 20),
      DropEntry('the_unconsecrated', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    reliquaryKeeper,
    censerWraith,
    theUnleft,
    boneReliquary,
    corridorCrawler,
  ];

  static const minis = <EnemyDef>[
    antechoir,
    reliquaryColossus,
    theSecondHand,
    warmMiddle,
  ];

  static const bosses = <EnemyDef>[whatWasConsecrated, whatDidNotLeaveItAlone];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
