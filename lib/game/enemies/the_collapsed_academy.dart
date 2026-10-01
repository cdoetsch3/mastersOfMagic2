/// The Collapsed Academy bestiary — Lv 50–54, Arcane
/// (ETHEREAL_CONTRACT §4.5, ENEMIES §2e).
///
/// ⭐ **Theme: it was not destroyed — it was continued past the point where
/// building makes sense.** From the arrival text — *"It is not ruined so much
/// as unfinished in the wrong direction. Staircases arrive at rooms that were
/// never built."* ⚠️ **Over-completion, not ruin**, and that distinction is
/// the whole zone: nothing here is broken, everything here is *too far*. A
/// creature written as rubble is written wrong.
///
/// ⚠️ **A pure zone, so every creature is Arcane** — with exactly one
/// licensed exception, below. There is no per-creature element choice to make
/// here the way a hybrid has one.
///
/// ⚠️⚠️ **The Fourth Item carries the zone's one off-element move** — astral
/// (§2e.2, four creatures in fifteen zones). Legal because Arcane is
/// countered by **Umbra**, and Astral is not Umbra: a boss that punishes
/// correct preparation is the version of this idea that makes players stop
/// preparing (§2h's one non-tunable row). 📝 The engine has no per-move
/// element — a cast takes the element the caster CHARGED — so an off-element
/// move can only be expressed as a second entry in `elements`. That is the
/// engine's floor, not a design choice, and the Glass Archive's Burnt Index
/// ships the same shape.
///
/// ⭐⭐ **The Archmage is a MAGE** (§3.4, and the roster row says so in as
/// many words: *"draws from `Spellbook`, not a creature kit"*). It is the
/// first creature in the game to set [EnemyDef.isMage], and everything that
/// follows from it — the exemptions, and the one law it owes in exchange —
/// is documented on the field rather than here, because the Citadel's
/// Procarius will be the second.
///
/// ⭐ **The boss pool is a mind and what it read, NOT a mirror.** The Archmage
/// is *who* read too far; The Last Three Items is *what they read*. ⚠️ Killing
/// the Archmage does not unwrite the syllabus and killing the syllabus does
/// not bring anyone back — do not "fix" the pair into a symmetry.
///
/// ⚠️ **Both bosses drop `the_written_third`, on `always`, never weighted**
/// (§2e.1, §3.4, §3.5 rule 3). A run draws one boss of two; a gate part that
/// came off the boss you did not draw would turn a mandatory progression item
/// into a coin flip. ⚠️ **The fragment's `KeyDef` is defined in this zone's
/// catalogue** even though ETHEREAL §4.6 prints its lore under The Reliquary
/// Deep — §3.4's reconciliation moved the id to the pure Arcane zone and left
/// the lore block where it was written.
///
/// ⚠️⚠️ **`arcane_*` is NOT defined in this quarter.** The Glass Archive
/// (43–47) yields Arcane first and therefore owns the family (CELESTIAL
/// §3.2), so this is ⭐ **the only pure zone in the game that defines no mote
/// family**. A builder will look for `arcane_dust` here and must not add one.
///
/// ⭐ **`hide` resolves to `mana_slag`** — the zone's SECOND gatherable
/// material (ETHEREAL §3.5 rule 1). The Academy has no kill-only hide, and
/// there is nothing here with a body worth skinning; "something died" pays in
/// the school's own spill instead.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression.
/// `test/the_collapsed_academy_test.dart` resolves every id against
/// [ItemCatalogue] instead. ⚠️ **`arcane_*` and `climbers_ration` are
/// cross-file references**: the motes belong to the Glass Archive (shipped),
/// and the Ration is owned by Hallowmarch, a parallel Ethereal worktree — it
/// resolves once the merge coordinator lands the lanes together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_collapsed_academy';
const _arcane = [MagicElement.arcane];

/// ⚠️ The zone's **one** off-element creature (§2e.2). Astral is not Arcane's
/// counter — Umbra is.
const _arcaneAndTheFourth = [MagicElement.arcane, MagicElement.astral];

/// ⚠️ A pure zone pays ONE mote ladder, at the shipped 0.75 (§4.5).
const _commonAlways = [DropEntry('arcane_dust', chance: 0.75, min: 1, max: 2)];

abstract final class CollapsedAcademyBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// zone's **Adept** — the honest fight, the yardstick everything else here
  /// is felt against. Its drops are §4.5's material-B row: the `hide` role
  /// with no hide to pay it in, settled into `mana_slag` (§3.5 rule 1).
  static const unfinishedScholar = EnemyDef(
    id: 'unfinished_scholar',
    name: 'Unfinished Scholar',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _arcane,
    lore:
        'A figure in a reader\'s gown at a lectern that is not there, working '
        'steadily through a passage with one hand out for the next page. It '
        'has not stopped to eat, or to look up, or to notice that the room '
        'around it ran out some time ago.',
    moves: [
      Spell(
        id: 'ca_readon',
        name: 'Read On',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ca_workitthrough',
        name: 'Work It Through',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'ca_setthemargin',
        name: 'Set the Margin',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('mana_slag', weight: 72, min: 1, max: 2),
        DropEntry('arcane_shard', weight: 5, min: 1, max: 2),
        DropEntry('arcane_dust', weight: 8, min: 2, max: 3),
      ],
    ),
  );

  /// ⭐ **A flight of stone that arrives where a room should be and keeps
  /// arriving** (§2e). ⚠️ **Bruiser, not Sentinel** (§2f's re-assignment) —
  /// the point of a stairhead is that you can see it coming and it comes
  /// anyway, which is the Bruiser's whole lesson: reading the charge bar.
  /// Its two moves are the same act at two prices, and the expensive one is
  /// the archetype.
  static const stairhead = EnemyDef(
    id: 'stairhead',
    name: 'Stairhead',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _arcane,
    lore:
        'The top four treads and the landing of a staircase, squared pale '
        'timber and stone, moving as one piece at about the speed somebody '
        'climbs. There is no lower flight under it and there is no room at '
        'the top, and neither of those has ever slowed it.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'ca_arrive',
        name: 'Arrive',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band) — five charge is
      // four turns of telegraph, which is the price the Bruiser pays.
      Spell(
        id: 'ca_keeparriving',
        name: 'Keep Arriving',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('aetherwood_log', weight: 74, min: 1, max: 3),
        DropEntry('arcane_shard', weight: 5),
        DropEntry('arcane_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('climbers_ration', chance: 0.02)],
    ),
  );

  /// ⭐ The zone's priority tutor (§2e): both of its moves are marks made on
  /// something, and the cheap one lands on the quick rung before the board
  /// has settled.
  static const chalkwraith = EnemyDef(
    id: 'chalkwraith',
    name: 'Chalkwraith',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _arcane,
    lore:
        'A loose person-shaped drift of chalk dust that holds together at '
        'roughly the height of somebody working at a board, one arm always '
        'raised. It writes continuously on whatever it is nearest, at the '
        'speed of somebody who has done this lecture many times.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'ca_underline',
        name: 'Underline',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ca_strikethrough',
        name: 'Strike Through',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('aetherwood_log', weight: 74, min: 1, max: 3),
        DropEntry('arcane_shard', weight: 5),
        DropEntry('arcane_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('climbers_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Both moves multi-hit (§1.3's per-archetype rule) — a Blighter wins by
  /// out-lasting rather than out-hitting, and a margin fills one small
  /// remark at a time until the remarks are longer than the page.
  static const marginalNote = EnemyDef(
    id: 'marginal_note',
    name: 'Marginal Note',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _arcane,
    lore:
        'A dense column of small handwriting standing upright in the air at '
        'about the width of a page margin and the height of a person, with '
        'no page beside it. More is added to it while you watch, in the same '
        'hand, at the same size.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'ca_annotate',
        name: 'Annotate',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ca_gloss',
        name: 'Gloss',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('mana_slag', weight: 72, min: 1, max: 2),
        DropEntry('arcane_shard', weight: 5, min: 1, max: 2),
        DropEntry('arcane_dust', weight: 8, min: 2, max: 3),
      ],
    ),
  );

  /// ⭐⭐ **An emeritus is someone still here past their time: brittle, and
  /// with one catastrophic thing left in them** (§2e). That sentence is the
  /// Glasswing's stat line in prose — 0.50 HP, 1.70 damage — which is why
  /// ⚠️ **the §2f re-assignment away from Drudge is load-bearing**: a Drudge
  /// at level 52 is a wasted encounter slot, and the name's joke survives the
  /// fix intact.
  ///
  /// ⚠️ It keeps §4.5's "the Drudge" drop row, because it *is* the creature
  /// that row was written for. Its `hide` role settles into `mana_slag` on
  /// the main table (§3.5 rule 1).
  static const emeritus = EnemyDef(
    id: 'emeritus',
    name: 'Emeritus',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _arcane,
    lore:
        'A very old reader, thin to the point of translucence, still seated '
        'in the chair the school gave them and still turned toward the front '
        'of a hall that no longer has a front. Everyone who could have told '
        'them to go home left a long time ago.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'ca_persist',
        name: 'Persist',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The one catastrophic thing. Spiky by stats, not by raws.
      Spell(
        id: 'ca_saythelastthing',
        name: 'Say the Last Thing',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 20),
        DropEntry('mana_slag', weight: 65),
        DropEntry('climbers_ration', weight: 15),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⚠️⚠️ **The zone's one off-element creature** (§2e.2) — one astral move,
  /// on a mini rather than a common, because §2h licenses the third element
  /// on minis and bosses only. ⭐ It is the right creature for it: the fourth
  /// item is the first one on the syllabus that is *not in any language you
  /// have*, so the one thing it does that you cannot read is the point of it.
  static const theFourthItem = EnemyDef(
    id: 'the_fourth_item',
    name: 'The Fourth Item',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _arcaneAndTheFourth,
    lore:
        'A line of writing about the length of a forearm, hanging at eye '
        'height with nothing holding it up, in a hand that matches the three '
        'lines above it on the wall. Reading the first three takes a moment. '
        'Reading this one does not finish.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'ca_enumerate',
        name: 'Enumerate',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      // ⚠️ The off-element one, and the only move in the zone that is not
      // Arcane. Astral because §2e.2 names astral: Arcane's counter is Umbra,
      // and a creature that punishes the player's correct counter-pick is the
      // one thing §2h says never to build.
      Spell(
        id: 'ca_readitanyway',
        name: 'Read It Anyway',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'ca_holdtheplace',
        name: 'Hold the Place',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition: it banks what it spills and gives it back
  /// slowly. Its wall goes up on priority 2 — ahead of the player's own
  /// shield, which is the whole difference between a wall and a delay.
  static const manaGolem = EnemyDef(
    id: 'mana_golem',
    name: 'Mana Golem',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _arcane,
    lore:
        'A broad seated figure half again the height of a person, built out '
        'of cooled grey-violet slag in poured layers, each one flowed over '
        'the last. It is warm to stand near. The heat is coming from '
        'somewhere near the middle of it and has not run out.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ca_drawitoff',
        name: 'Draw It Off',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'ca_bankthespill',
        name: 'Bank the Spill',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ca_vent',
        name: 'Vent',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap lowered from 5 to 4** (§1.3) — at L54 a mini five-charge
  /// raw lands far past a one-shot, and there is no reading of *"kills you in
  /// three turns if you misplay one"* that survives being killed in one.
  static const arcaneChimera = EnemyDef(
    id: 'arcane_chimera',
    name: 'Arcane Chimera',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _arcane,
    lore:
        'A four-limbed animal about the size of a large hound whose parts do '
        'not agree with each other — three different coats, two different '
        'gaits, a head that belongs to none of it. Every join is clean and '
        'deliberate. Somebody was very good at this and did not stop.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'ca_graft',
        name: 'Graft',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'ca_finishit',
        name: 'Finish It',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects, its
  /// cheap move lands ahead of the whole board, and one thing it throws goes
  /// straight through a wall. 📝 The engine has no creature-applied debuff
  /// yet, so the archetype is written with the levers that actually resolve.
  static const spellWeaver = EnemyDef(
    id: 'spell_weaver',
    name: 'Spell Weaver',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _arcane,
    lore:
        'A tall narrow figure standing at a loom taller than it is, working '
        'with both hands at a speed that is hard to watch. The cloth coming '
        'off the loom is already the width of the room and there is no sign '
        'of it being cut, or gathered, or wanted.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'ca_thread',
        name: 'Thread',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ca_tieoff',
        name: 'Tie Off',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ca_pullthethread',
        name: 'Pull the Thread',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🧙 **The zone's mage, and the game's first** — *who read too far*.
  /// ⭐⭐ [EnemyDef.isMage] is set here, which means this fight is the player's
  /// own spellbook pointed back at them: ten slots, all of them legal for a
  /// player at this level, and an intelligence-9 Tyrant brain spending them.
  ///
  /// ⭐ **Why these ten.** The five-rung damage ladder (Bolt → Cataclysm) so
  /// the charge bar reads exactly the way the player's own does; two shields
  /// so it can turtle a telegraph out; and three **knowledge** spells —
  /// Discharge, Overload and Dispel — because Arcane's whole identity is
  /// knowing what is coming (ITEMS §2.2, and the deflection lean of §2.4).
  /// ⚠️ Overload and Discharge together are the Archmage's real threat: it
  /// reads your charge bar, and it either takes it away or bills you for it.
  ///
  /// ⚠️ **Ten is the cap, not a choice** — `Loadout.maxSpellSlots` is 10 and
  /// `Progression.spellUnlockLevels` reaches ten at level 48, so a level-50
  /// player has exactly this many slots and no more. ✅ Every id's
  /// `plannedUnlockLevel` is 45 or lower, so the whole loadout is legal at
  /// the band floor rather than only at the ceiling.
  ///
  /// 📝 Its costs (1–5) happen to fall inside the Tyrant's own 1–5 band, so
  /// the mage exemption is doing nothing here except excusing the *count* and
  /// the Spellbook's player-priced raws. That is a coincidence worth keeping
  /// an eye on rather than a rule.
  static const theArchmage = EnemyDef(
    id: 'the_archmage',
    name: 'The Archmage',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _arcane,
    isMage: true,
    lore:
        'An old man in the plain grey of a working scholar rather than the '
        'robes of an office, standing in the middle of the floor with no '
        'book in his hands and no need of one. He is entirely willing to '
        'explain what he found, and the explanation is the problem.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
    moves: [
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.surge,
      Spellbook.ruin,
      Spellbook.cataclysm,
      Spellbook.aegis,
      Spellbook.bulwark,
      Spellbook.discharge,
      Spellbook.overload,
      Spellbook.dispel,
    ],
    drops: _bossDrops,
  );

  /// 📖 **The Aspect — Arcane taken to an extreme, and what they read.**
  /// ⚠️ Single-element by rule (ENEMIES §2.5), which costs nothing in a pure
  /// zone. §2.4's stat block verbatim: `defl 35 / 28` (EV 9.8%), `acc +10` —
  /// ⭐ deflection because knowing what is coming is how you take less of it,
  /// and a hair under the Redoubt's 10.5% on purpose.
  ///
  /// ⭐ **"It gets stronger every turn you let it live"** (§2e) is carried by
  /// the shape rather than by a ramp: a cost-1 opener it can always afford, a
  /// wall at priority 2 that buys the charge for the finisher, and a cost-4
  /// finisher that **executes** under 30% — so the longer the fight runs, the
  /// more of its kit is lethal rather than merely expensive.
  /// 📝 A literal per-turn ramp would want either a creature-side DoT (a new
  /// `StatusCatalog` id, a shared file this lane does not own) or
  /// `EmpowerEffect`, which `LadderAi` does not yet value and would therefore
  /// never cast. Both are worth doing; neither is worth a dead move.
  static const theLastThreeItems = EnemyDef(
    id: 'the_last_three_items',
    name: 'The Last Three Items',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _arcane,
    lore:
        'Three lines at the bottom of the syllabus still on the wall, in the '
        'same hand as the rest of it, standing out from the plaster far '
        'enough to cast a shadow. The first eleven items are a course of '
        'study. These are not, and they are what the course was for.',
    // ⚠️ §2.4's row, verbatim: defl 35/28 (EV 9.8%), acc +10.
    combatStats: EnemyCombatStats(
      accuracyBonus: 10,
      deflectChance: 35,
      deflectAmount: 28,
    ),
    moves: [
      Spell(
        id: 'ca_setthenextitem',
        name: 'Set the Next Item',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 2 — the syllabus is still on the wall before you decide
      // to put anything between you and it.
      Spell(
        id: 'ca_leaveitstanding',
        name: 'Leave It Standing',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      // ⭐ The execute rider IS the escalation: it is an ordinary big hit
      // until you are low, and after that it is the end of the fight.
      Spell(
        id: 'ca_finishthesyllabus',
        name: 'Finish the Syllabus',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38, executeBelowPercent: 30),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// §4.5's `_miniDrops`, transcribed, then leaned on 2026-09-30 (Crystal
  /// 0.25 → 0.15, Dust 2–4 → 1–3). ⭐ Crystal is where the mote
  /// ladder is first FELT, so it must come off a fight the player chose
  /// (ITEMS §8).
  static const _miniDrops = DropTable(
    always: [
      DropEntry('arcane_shard'),
      DropEntry('arcane_dust', min: 1, max: 3),
      DropEntry('arcane_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('aetherwood_log', weight: 40, min: 2, max: 4),
      DropEntry('mana_slag', weight: 30, min: 2, max: 4),
      DropEntry('climbers_ration', weight: 25),
      DropEntry('chalkline_signet', weight: 5),
    ],
  );

  /// §4.5's `_bossDrops`, plus the gate fragment §3.4 puts on **both** bosses.
  ///
  /// ⚠️⚠️ **`the_written_third` is on `always` with no `chance`**, which is
  /// what "guaranteed" means in this shape (§2e.1: *a mandatory progression
  /// item is never a coin flip*). Weighting it, or moving it to `main`, would
  /// make one of the three Ethereal fragments depend on which boss the run
  /// drew.
  ///
  /// 📝 **One epic, two bosses.** §2e.1 gives each boss a `unique`, and §4.5
  /// authors exactly one — `the_unbuilt_stair`. It therefore hangs off the
  /// shared table and both bosses can drop it, the shipped Frostfell shape.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('the_written_third'),
      DropEntry('arcane_crystal', min: 1, max: 2),
      DropEntry('arcane_shard', min: 1, max: 2),
      DropEntry('arcane_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('aetherwood_log', weight: 45, min: 4, max: 8),
      DropEntry('mana_slag', weight: 25, min: 3, max: 6),
      DropEntry('chalkline_signet', weight: 20),
      DropEntry('the_unbuilt_stair', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    unfinishedScholar,
    stairhead,
    chalkwraith,
    marginalNote,
    emeritus,
  ];

  static const minis = <EnemyDef>[
    theFourthItem,
    manaGolem,
    arcaneChimera,
    spellWeaver,
  ];

  static const bosses = <EnemyDef>[theArchmage, theLastThreeItems];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
