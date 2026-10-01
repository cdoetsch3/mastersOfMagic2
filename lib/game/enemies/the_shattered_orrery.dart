/// The Shattered Orrery bestiary — Lv 40–44, Astral + Electro hybrid
/// (CELESTIAL_CONTRACT §4.6).
///
/// ⭐ **Theme: a broken machine still computing, and nobody knows what
/// toward.** The fusion is **the heavens as mechanism** — Electro is the
/// power, Astral is what it is modelling. Nothing here should read as a storm
/// in an observatory; it should read as one apparatus, half of it fallen, all
/// of it still running.
///
/// 📝 **Deferred structure.** The 🏰 marker in ENEMIES §2e and
/// `LocationKind.dungeon` in `world.dart` both stand, but this zone ships as a
/// **standard adventure**, exactly as The Molten Deep did — KINETIC ruling 4,
/// re-affirmed by CELESTIAL_CONTRACT §4.6: *"nothing here may assume a
/// descending structure."* ⚠️ Nothing in this file may grow a floor count.
///
/// ⭐⭐ **The archetypes ARE the premise** (ENEMIES §2g), and the elements say
/// it too: **The Calculation** is the Juggernaut — *the process*, electro, the
/// power — and **The Answer** is the Tyrant — *the result*, astral, what the
/// power was for. ⚠️ Not a mirror: one is a grinding and one is a conclusion,
/// and drawing The Answer means it **finished**. Do not "fix" the pair into a
/// symmetry.
///
/// ⭐ **`orrery_automaton` is Sentinel → Adept, ruled (ENEMIES §2e)** — the
/// zone's anchor name and its yardstick. *A machine executing a correct
/// program is the definition of a straight, competent game*; the yardstick was
/// always standing here, it was only labelled a wall. It therefore carries no
/// [EnemyCombatStats]: §2.3 leaves the Adept row deliberately blank, and a
/// yardstick with a thumb on the scale stops being one.
///
/// ⚠️ **This zone assigns element per creature, not "both" by default**
/// (§4.6's roster table) — five creatures are pure Astral, four pure Electro,
/// and only the Automaton and Long Division carry both. Read the roster table
/// before touching an element list.
///
/// ⚠️ **No off-element move.** ENEMIES §2e.2 names the only four creatures in
/// fifteen zones that carry one, and none of them is here.
///
/// ⚠️ **No `key`.** The Celestial gate is supplied by the quarter's three
/// **pure** zones (ENEMIES §2e.1) — Kiln Desert, Mirrormere, Starfall Basin. A
/// hybrid never carried one.
///
/// ⚠️ **Hybrids define no motes.** Every mote here references the existing
/// `astral_*` (Starfall Basin, this quarter) and `electro_*` (Stormcliff
/// Coast, **Q2**) families — CELESTIAL_CONTRACT §3.2. ⭐ The Orrery is one of
/// only two places in the quarter that hands a level-40 player a reason to
/// care about a mote family they stopped seeing twenty levels ago.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_shattered_orrery_test
/// .dart` resolves every id against [ItemCatalogue] instead. ⚠️ `astral_*`
/// lands with the **Starfall Basin** lane and `pilgrims_ration` with **The
/// Kiln Desert** lane, both building in parallel; the resolution law is
/// written and `skip:`ped until the merge coordinator lands them.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_shattered_orrery';
const _astral = [MagicElement.astral];
const _electro = [MagicElement.electro];
const _both = [MagicElement.astral, MagicElement.electro];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.6's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('astral_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('electro_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class ShatteredOrreryBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name (`World.opponentNameFor`) and the only **Adept**
  /// in this roster — the honest fight, running its program correctly while
  /// everything around it has come apart.
  ///
  /// ⚠️ Its drop table is §4.6's **Sentinel row**, which the contract names by
  /// the archetype this creature carried before the re-band. It is the one
  /// common that yields `sidereal_glass`, and the only one that pays a
  /// draught.
  static const orreryAutomaton = EnemyDef(
    id: 'orrery_automaton',
    name: 'Orrery Automaton',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A brass figure the height of a person that walks a fixed circuit '
        'between the standing rings, stopping at the same seven places every '
        'time and adjusting something at each. It has never once been seen '
        'to stop at an eighth.',
    moves: [
      Spell(
        id: 'so_takethereading',
        name: 'Take the Reading',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'so_advancethecount',
        name: 'Advance the Count',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'so_closethehousing',
        name: 'Close the Housing',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('sidereal_glass', weight: 64),
        DropEntry('astral_shard', weight: 5, min: 1, max: 2),
        DropEntry('astral_dust', weight: 11, min: 2, max: 3),
        DropEntry('arcsalt_draught', weight: 5),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the archetype
  /// multiplies them** (the shipped Glasswing shape) — pure Astral, a motion
  /// the machine still makes with the part that used to make it gone.
  static const gearGhost = EnemyDef(
    id: 'gear_ghost',
    name: 'Gear-Ghost',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _astral,
    lore:
        'The turning of a gear with no gear in it, holding its diameter in '
        'the air at about the width of a cartwheel. The teeth are visible '
        'only where they would be meshing, and they mesh on time.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'so_slipthetooth',
        name: 'Slip the Tooth',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'so_meshwithnothing',
        name: 'Mesh With Nothing',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 17),
        DropEntry('arcsalt', weight: 73, min: 1, max: 2),
        DropEntry('astral_shard', weight: 3),
        DropEntry('astral_dust', weight: 7, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ The zone's charge-bar tutor — pure Electro. It spends a long time
  /// winding up to one number, and the number is worth waiting out or not,
  /// depending on what the player did with those four turns.
  static const armature = EnemyDef(
    id: 'armature',
    name: 'Armature',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _electro,
    lore:
        'A single support arm off one of the great rings, torn loose at the '
        'hub and upright on its own, half again the height of a person. The '
        'windings along its length brighten steadily and then do not.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'so_swingthearm',
        name: 'Swing the Arm',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band) — the whole lesson
      // is that you can see this one coming.
      Spell(
        id: 'so_dumpthecharge',
        name: 'Dump the Charge',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('orrery_scrap', weight: 74, min: 1, max: 3),
        DropEntry('electro_shard', weight: 5),
        DropEntry('electro_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Both moves multi-hit — *"shields chip rather than shatter"* is the
  /// Lasher's whole lesson (§2.5), and a flock is how a charge arrives when
  /// it has nowhere it particularly wants to be.
  static const arcflock = EnemyDef(
    id: 'arcflock',
    name: 'Arcflock',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _electro,
    lore:
        'Two dozen small discharges keeping loose formation about head height '
        'and moving together the way birds do, each one lasting no longer '
        'than a spark and replaced before it is missed.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'so_scatterthearc',
        name: 'Scatter the Arc',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'so_earthitthroughyou',
        name: 'Earth It Through You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 17),
        DropEntry('arcsalt', weight: 73, min: 1, max: 2),
        DropEntry('astral_shard', weight: 3),
        DropEntry('astral_dust', weight: 7, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Priority is the lesson (§2.5) — both its moves land at 5, ahead of an
  /// ordinary attack, which is the shipped Skirmisher shape. Pure Astral: it
  /// came loose a long time ago and has not stopped.
  static const errantRing = EnemyDef(
    id: 'errant_ring',
    name: 'Errant Ring',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _astral,
    lore:
        'A ring off the mechanism about the width of a doorway, rolling on '
        'its edge along a path it has worn into the floor. It corrects '
        'itself whenever it starts to fall, and it has been correcting '
        'itself for a very long time.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'so_comeloose',
        name: 'Come Loose',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'so_keepturning',
        name: 'Keep Turning',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('orrery_scrap', weight: 74, min: 1, max: 3),
        DropEntry('electro_shard', weight: 5),
        DropEntry('electro_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const siderealFault = EnemyDef(
    id: 'sidereal_fault',
    name: 'Sidereal Fault',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _astral,
    lore:
        'A seam in the air where the modelled sky and the real one do not '
        'agree, tall as the standing rings and no thicker than a held '
        'breath. Looking through it shows the same stars in the wrong '
        'places.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'so_openthefault',
        name: 'Open the Fault',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'so_disagreewiththesky',
        name: 'Disagree With the Sky',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'so_holdthemeridian',
        name: 'Hold the Meridian',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, pure Electro — an escapement is the part
  /// that **holds** and then lets exactly one measure through, which is the
  /// archetype written as a machine part.
  static const escapement = EnemyDef(
    id: 'escapement',
    name: 'Escapement',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _electro,
    lore:
        'A toothed wheel and its pallet, mounted alone on a frame twice the '
        'height of a person, catching and releasing with a report you feel '
        'through the floor. Between the reports it does not move at all.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'so_tickover',
        name: 'Tick Over',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'so_lockthetrain',
        name: 'Lock the Train',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'so_releaseonemeasure',
        name: 'Release One Measure',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ Cost cap stays at 4 (§1.3) — at cost 5 a mini Executioner's raw would
  /// be a one-shot with change against a level-44 bar.
  ///
  /// ⭐ The only creature in the roster besides the Automaton to carry both
  /// elements, and the only one to carry an **execute**: long division is the
  /// operation that keeps going until there is nothing left to bring down.
  static const longDivision = EnemyDef(
    id: 'long_division',
    name: 'Long Division',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _both,
    lore:
        'A column of worked figures hanging in the air at the height of a '
        'wall, each line shorter than the one above it, resolving downward '
        'at about the speed of a walking pace. The bottom line is never '
        'visible from where you are standing.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'so_dividethrough',
        name: 'Divide Through',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⭐ The archetype's own clause, spelled as arithmetic: below a quarter
      // of the bar there is nothing left to carry down, and it knows it.
      Spell(
        id: 'so_bringdownthelast',
        name: 'Bring Down the Last',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 25),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects, and
  /// its dear move goes through a wall. 📝 The engine has no creature-applied
  /// debuff yet, so the archetype is written with the levers that resolve.
  static const theRemainder = EnemyDef(
    id: 'the_remainder',
    name: 'The Remainder',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _astral,
    lore:
        'The part of a figure that would not go in, kept to one side of the '
        'working and grown to about the size of a person while it waited. '
        'It is still being carried, and it is still owed.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'so_setasidethepart',
        name: 'Set Aside the Part',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'so_stilloweditback',
        name: 'Still Owed It Back',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'so_itneverwentin',
        name: 'It Never Went In',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// ⚙️ **The process — what the power is doing.** Electro, Juggernaut: a mass
  /// rather than a mind (§2g gives the Tyrant to *"a person, a will, something
  /// that decided"*, and a calculation decides nothing, it only continues).
  /// ⭐⭐ It grinds, and it has been grinding.
  static const theCalculation = EnemyDef(
    id: 'the_calculation',
    name: 'The Calculation',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _electro,
    lore:
        'The whole working of the machine seen at once, filling the chamber '
        'from floor to broken roof, every surviving ring turning in it at a '
        'different rate. It does not notice being interrupted and it does '
        'not lose its place.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'so_grindthecolumn',
        name: 'Grind the Column',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'so_closetheloop',
        name: 'Close the Loop',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'so_runittocompletion',
        name: 'Run It to Completion',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✴️ **The result — what the power was for.** Astral, Tyrant: the one thing
  /// in this zone that *decided*. ⭐⭐ Drawing The Answer means it **finished**
  /// — and the pair is therefore a process and its conclusion, never a mirror.
  /// ⚠️ Nothing the player does here un-finishes it.
  static const theAnswer = EnemyDef(
    id: 'the_answer',
    name: 'The Answer',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _astral,
    lore:
        'A single arrangement of light standing at the centre where the rings '
        'used to cross, about the size of a person and entirely still. It '
        'was not there on any previous visit, and it is complete.',
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
        id: 'so_statetheresult',
        name: 'State the Result',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'so_itwasalwaysthis',
        name: 'It Was Always This',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'so_giveitinfull',
        name: 'Give It In Full',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.6) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('astral_shard'),
      DropEntry('electro_shard'),
      DropEntry('astral_dust', min: 1, max: 3),
      DropEntry('electro_dust', min: 1, max: 3),
      DropEntry('astral_crystal', chance: 0.15),
      DropEntry('electro_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('orrery_scrap', weight: 40, min: 2, max: 4),
      DropEntry('arcsalt', weight: 30, min: 2, max: 4),
      DropEntry('sidereal_glass', weight: 25, min: 1, max: 2),
      DropEntry('sidereal_signet', weight: 5),
    ],
  );

  /// ⚠️ **No `key` on either boss.** The Celestial Totem's three essences come
  /// from the quarter's three **pure** zones (ENEMIES §2e.1); a hybrid has
  /// never carried a gate part, and adding one here would give the gate a
  /// fourth supplier it was never designed to have.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('astral_crystal', min: 1, max: 2),
      DropEntry('electro_crystal', min: 1, max: 2),
      DropEntry('astral_shard', min: 1, max: 2),
      DropEntry('electro_shard', min: 1, max: 2),
      DropEntry('astral_dust', min: 3, max: 6),
      DropEntry('electro_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('orrery_scrap', weight: 35, min: 4, max: 8),
      DropEntry('arcsalt', weight: 20, min: 3, max: 6),
      DropEntry('sidereal_glass', weight: 15, min: 2, max: 4),
      DropEntry('sidereal_signet', weight: 20),
      DropEntry('the_running_count', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    orreryAutomaton,
    gearGhost,
    armature,
    arcflock,
    errantRing,
  ];

  static const minis = <EnemyDef>[
    siderealFault,
    escapement,
    longDivision,
    theRemainder,
  ];

  static const bosses = <EnemyDef>[theCalculation, theAnswer];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
