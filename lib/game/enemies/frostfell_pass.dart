/// The Frostfell Pass bestiary — Lv 21–26, Aqua + Aero (KINETIC_CONTRACT
/// §4.4).
///
/// ⭐ **Theme: everything that moves through here gets held.** From the
/// arrival text — *"your breath goes up and does not come down. The road is
/// under here somewhere, and other people have been sure of that too."* The
/// fusion is **breath frozen mid-air** — Aero stopped by Aqua — and the
/// second sentence is the threat: the confident dead are still here.
///
/// ⚠️ **This zone assigns element per creature, not "both" by default**
/// (§4.4's roster table) — some creatures are pure Aqua, some pure Aero, and
/// only the ones the contract marks `aqua + aero` carry both. Read the
/// roster table before touching an element list.
///
/// ⭐ **`rime_stalker` is Skirmisher → Adept, ruled (§8.4)** — the zone's
/// anchor name and the cheapest of the quarter's three swaps. A stalker that
/// fights honestly is believable.
///
/// ⭐⭐ **The boss pool is NOT a mirror — it is a boss and its cause**
/// (ENEMIES §2f's deliberate break). The Road Under is what is BURIED; The
/// White Corridor is what BURIED it. ⚠️ Killing the Corridor does not free
/// the Road — nothing done here digs anyone out. Do not "fix" this into a
/// symmetry.
///
/// ⚠️ **The Aspect must be single-element** (ENEMIES §2.5) — Aqua's
/// Waterlogged, taken to an extreme, is the only reading of The Road Under
/// that works. Its stat block is copied verbatim from §2.4: `defl 30/30, acc
/// 0`.
///
/// ⚠️ **Combat stats (KINETIC_CONTRACT §2.2/§2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own
/// default): §2.3 calls it "the yardstick," and a yardstick with a thumb on
/// the scale stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/frostfell_pass_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`hardtack` is a
/// cross-zone reference**, defined in `old_quarry_items.dart`, a sibling
/// Kinetic builder's file — it resolves once the merge coordinator lands all
/// three parallel worktrees together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'frostfell_pass';
const _both = [MagicElement.aqua, MagicElement.aero];
const _aqua = [MagicElement.aqua];
const _aero = [MagicElement.aero];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.4's drop table, the shipped Thornmire shape).
const _commonAlways = [
  DropEntry('aqua_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('aero_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class FrostfellPassBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster (§8.4) — the honest fight, the yardstick
  /// the rest of the pass is felt against.
  static const rimeStalker = EnemyDef(
    id: 'rime_stalker',
    name: 'Rime Stalker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A tall, frost-whitened figure that walks the road at an even pace, '
        'never hurrying and never stopping, the way someone certain of the '
        'route walks it. Its breath hangs in the air a beat longer than '
        'anyone else\'s would.',
    moves: [
      Spell(
        id: 'ff_stepthrough',
        name: 'Step Through',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ff_breakthedrift',
        name: 'Break the Drift',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'ff_bracethewind',
        name: 'Brace the Wind',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('rimepelt', weight: 45),
        DropEntry('aqua_shard', weight: 7),
        DropEntry('aqua_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ The zone's shield tutor, unchanged in kind from Old Quarry's — pure
  /// Aqua, because it is the thing that holds still and lets the cold do the
  /// work.
  static const hoarbound = EnemyDef(
    id: 'hoarbound',
    name: 'Hoarbound',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _aqua,
    lore:
        'A heavy shape bound in white rime from the ground up, thicker each '
        'season it stands here, until the frost is doing as much of the '
        'holding as the creature underneath it.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'ff_closein',
        name: 'Close In',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'ff_setlikeice',
        name: 'Set Like Ice',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('rimepelt', weight: 40),
        DropEntry('aqua_shard', weight: 8, min: 1, max: 2),
        DropEntry('aqua_dust', weight: 17, min: 2, max: 3),
        DropEntry('hardtack', weight: 5),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the
  /// archetype multiplies them** — pure Aero, the breath itself losing its
  /// footing.
  static const breathfrost = EnemyDef(
    id: 'breathfrost',
    name: 'Breathfrost',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _aero,
    lore:
        'A visible held breath, person-sized, that never quite disperses. '
        'It rises the way breath does in the cold and simply never comes '
        'back down, thinning at the edges into wing shapes that beat once '
        'in a while, out of habit more than need.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'ff_catchtheupdraft',
        name: 'Catch the Updraft',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'ff_fallstill',
        name: 'Fall Still',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('hoarlichen', weight: 50, min: 1, max: 2),
        DropEntry('aero_shard', weight: 5),
        DropEntry('aero_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Both moves multi-hit (§1.3's per-archetype rule) — a Blighter wins by
  /// out-lasting rather than out-hitting, and a cairn is built one small
  /// stone at a time.
  static const cairnwight = EnemyDef(
    id: 'cairnwight',
    name: 'Cairnwight',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _both,
    lore:
        'A standing pile of trail-stones with just enough shape to be a '
        'person, added to by everyone who passed and did not make it the '
        'rest of the way. It never stops being added to.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'ff_addastone',
        name: 'Add a Stone',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ff_buildthecairn',
        name: 'Build the Cairn',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('hoarlichen', weight: 45),
        DropEntry('everice', weight: 15),
      ],
    ),
  );

  /// ⚠️ −10 accuracy — its incompetence is in the number too (§2.3). Pure
  /// Aero: it has stopped fighting the wind and just goes where it takes it.
  static const snowblindWanderer = EnemyDef(
    id: 'snowblind_wanderer',
    name: 'Snowblind Wanderer',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.drudge,
    elements: _aero,
    lore:
        'A muffled shape that walks in a shallow curve rather than a '
        'straight line, wrapped past recognizing, following a road it can '
        'no longer see and has stopped trying to.',
    combatStats: EnemyCombatStats(accuracyBonus: -10),
    moves: [
      Spell(
        id: 'ff_wanderintoit',
        name: 'Wander Into It',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(4, 7),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('everice', weight: 55, min: 1, max: 3),
        DropEntry('aero_shard', weight: 7),
        DropEntry('aero_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const theLastCairn = EnemyDef(
    id: 'the_last_cairn',
    name: 'The Last Cairn',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'Taller than the trail-markers it grew from, stones bound together '
        'with ice instead of intent, still gaining height the way the '
        'smaller ones do. Nobody added the top of it on purpose.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'ff_addanothermarker',
        name: 'Add Another Marker',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ff_bringthewholeweight',
        name: 'Bring the Whole Weight',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'ff_stackhigher',
        name: 'Stack Higher',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, pure Aqua — a cold that does not let go and
  /// takes the warmth it stops.
  static const hoarking = EnemyDef(
    id: 'hoarking',
    name: 'Hoarking',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _aqua,
    lore:
        'A crowned shape of packed rime, seated rather than standing, that '
        'has been in the same drift long enough for the drift to have '
        'stopped moving around it instead.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ff_pressthecoldin',
        name: 'Press the Cold In',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'ff_freezesolid',
        name: 'Freeze Solid',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ff_takethewarmth',
        name: 'Take the Warmth',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ Cost cap lowered from 5 to 4 this quarter (§1.3) — bring a shield.
  static const coldsnap = EnemyDef(
    id: 'coldsnap',
    name: 'Coldsnap',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _aqua,
    lore:
        'The temperature dropping fast enough to notice, given a shape just '
        'long enough to close the distance. It is gone again before the '
        'cold it left behind finishes registering.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'ff_dropthetemperature',
        name: 'Drop the Temperature',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'ff_allatonce',
        name: 'All at Once',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects,
  /// and its cheap move lands ahead of everything on the board. 📝 The
  /// engine has no creature-applied debuff yet, so the archetype is written
  /// with the levers that actually resolve.
  static const theCertainRoad = EnemyDef(
    id: 'the_certain_road',
    name: 'The Certain Road',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'A low, worn track visible only when the light is wrong, that a '
        'traveler will swear they remember walking before. It has never '
        'once been wrong about where it leads.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'ff_marktheway',
        name: 'Mark the Way',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ff_alreadydecided',
        name: 'Already Decided',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ff_theroaddoesnotask',
        name: 'The Road Does Not Ask',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🧊 **The mass boss — what buried it.** ⭐⭐ Killing this does not free
  /// The Road Under; nothing down here digs anyone out. The pool reads as
  /// futility, which suits a pass whose arrival text is about people who
  /// were also sure.
  static const theWhiteCorridor = EnemyDef(
    id: 'the_white_corridor',
    name: 'The White Corridor',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _both,
    lore:
        'A wall of packed white that fills the whole cut from side to side, '
        'as tall as the pass itself and moving at the speed the pass '
        'accumulates snow — which is to say, always, and without hurrying.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'ff_grindthrough',
        name: 'Grind Through',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'ff_packthewalls',
        name: 'Pack the Walls',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'ff_bringitalldown',
        name: 'Bring It All Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🌊 **The Aspect — Aqua taken to an extreme, and what is buried.**
  /// ⚠️ Single-element by rule (ENEMIES §2.5) — Waterlogged, the thing that
  /// slows and holds, is the whole creature. Every move here is patient
  /// rather than sudden: it does not need to be fast, because nothing gets
  /// past it either way.
  static const theRoadUnder = EnemyDef(
    id: 'the_road_under',
    name: 'The Road Under',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _aqua,
    lore:
        'Not a body — the road itself, still exactly where it was laid, '
        'simply no longer on top. Everything that has ever tried to cross '
        'it is somewhere in the layers between here and the surface.',
    // ⚠️ §2.4's row, verbatim: defl 30/30 (EV 9.0%), acc 0.
    combatStats: EnemyCombatStats(deflectChance: 30, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ff_underfoot',
        name: 'Underfoot',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ff_deeperthanitlooks',
        name: 'Deeper Than It Looks',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'ff_everythinggetsheld',
        name: 'Everything Gets Held',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.4) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('aqua_shard'),
      DropEntry('aero_shard'),
      DropEntry('aqua_dust', min: 2, max: 4),
      DropEntry('aero_dust', min: 2, max: 4),
      DropEntry('aqua_crystal', chance: 0.25),
      DropEntry('aero_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('rimepelt', weight: 40, min: 2, max: 4),
      DropEntry('hoarlichen', weight: 30, min: 2, max: 4),
      DropEntry('everice', weight: 25, min: 1, max: 2),
      DropEntry('rimebound_ring', weight: 5),
    ],
  );

  /// ✅ **RULED — Frostfell gets an epic (§8.7).** `the_holdfast` drops off
  /// this table alongside the other boss-table rewards; the doubled Crystal
  /// payout above is the standard hybrid mote shape, not a consolation for
  /// lacking one. ⚠️ No essence — the Sigil's collect-three-keys mechanism
  /// is rejected (§3.3/§8.6), and a hybrid never carried one anyway.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('aqua_crystal', min: 1, max: 2),
      DropEntry('aero_crystal', min: 1, max: 2),
      DropEntry('aqua_shard', min: 1, max: 2),
      DropEntry('aero_shard', min: 1, max: 2),
      DropEntry('aqua_dust', min: 4, max: 8),
      DropEntry('aero_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('rimepelt', weight: 35, min: 4, max: 8),
      DropEntry('hoarlichen', weight: 20, min: 3, max: 6),
      DropEntry('everice', weight: 15, min: 2, max: 4),
      DropEntry('rimebound_ring', weight: 20),
      DropEntry('the_holdfast', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    rimeStalker,
    hoarbound,
    breathfrost,
    cairnwight,
    snowblindWanderer,
  ];

  static const minis = <EnemyDef>[
    theLastCairn,
    hoarking,
    coldsnap,
    theCertainRoad,
  ];

  static const bosses = <EnemyDef>[theWhiteCorridor, theRoadUnder];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
