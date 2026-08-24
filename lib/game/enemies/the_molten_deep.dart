/// The Molten Deep bestiary — Lv 25–29, Pyro + Geo hybrid
/// (KINETIC_CONTRACT §4.6).
///
/// ⭐ **Theme: the stone is a liquid and has been the whole time.** The fusion
/// is Geo revealed as Pyro's slow state — the ground you trusted was only
/// cool. Nothing here should read as two elements sharing a room; it should
/// read as one substance at two temperatures.
///
/// 📝 **Deferred structure.** The 🏰 marker in ENEMIES §2e and
/// `LocationKind.dungeon` in `world.dart` both stand, but this zone ships as
/// a **standard three-section adventure** this quarter — nothing in this
/// file may assume a descending-dungeon structure (KINETIC_CONTRACT §4.6,
/// ruling 4). That shape is deferred, not built here.
///
/// ⭐ **The boss pair is the premise's two sides:** Efreet is what BURNS (a
/// will — Tyrant), The Slow Stone is what has NOT melted yet (a mass —
/// Juggernaut). Both re-homed Pyro roster names finally land at a scale that
/// fits (ENEMIES §2c) — an Efreet wants a volcano, not foothills.
///
/// ✅ **`slagswimmer` is Skirmisher → Adept**, ruled (§8.4) — the last of the
/// quarter's three swaps, and it carries no [EnemyCombatStats]: the Adept row
/// is deliberately blank, the yardstick every other archetype is felt
/// against (§2.3).
///
/// ⚠️ **The Pyroclast collision with Old Quarry's Obsidian Golem is
/// resolved** (ENEMIES §2f) — Pyroclast stays here, in The Molten Deep.
///
/// ⚠️ **1080 HP (The Slow Stone at L29) is the largest number in the
/// quarter by 4%** (§1.2) — transcribed verbatim from the contract's worked
/// table, not invented: `round(scaledMaxHp(29) * Archetypes.juggernaut.hpScale)`
/// = `round(300 * 3.60)` = `1080`. `test/molten_deep_test.dart` pins it
/// through the statline math so a coefficient drift is caught, not just the
/// literal.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/molten_deep_test.dart`
/// resolves every id against [ItemCatalogue] instead.
///
/// ⚠️ **Hybrids define no motes.** Every drop here references the existing
/// `pyro_*` (Cinderpeak) and `geo_*` (Old Quarry) mote families — this zone
/// and Frostfell Pass are the first places Q1's motes get a new source.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_molten_deep';
const _pyro = [MagicElement.pyro];
const _geo = [MagicElement.geo];
const _both = [MagicElement.pyro, MagicElement.geo];

/// ⭐ Both are Q1 mote families — this zone and Frostfell are the first
/// places old motes get a new source (KINETIC_CONTRACT §3.2, §4.6).
const _commonAlways = [
  DropEntry('pyro_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('geo_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class TheMoltenDeepBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`. A Sentinel
  /// is the right first impression for a place where the ground itself is
  /// the thing standing between you and the melt.
  static const moltenWarden = EnemyDef(
    id: 'molten_warden',
    name: 'Molten Warden',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _both,
    lore:
        'A standing plate of crust gone thick enough to hold its shape, '
        'hinged at nothing, planted over whatever is moving underneath it. '
        'It does not attack so much as refuse to be somewhere else.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'md_pressback',
        name: 'Press Back',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'md_holdthecrust',
        name: 'Hold the Crust',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('emberhide', weight: 40),
        DropEntry('pyro_shard', weight: 8, min: 1, max: 2),
        DropEntry('pyro_dust', weight: 17, min: 2, max: 3),
        DropEntry('hardtack', weight: 5),
      ],
    ),
  );

  /// ✅ Skirmisher → Adept, the smallest swap (§8.4). ⭐ **Deliberately
  /// blank** stat block — the yardstick every other archetype here is felt
  /// against (§2.3).
  static const slagswimmer = EnemyDef(
    id: 'slagswimmer',
    name: 'Slagswimmer',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _pyro,
    lore:
        'A long low body that moves through rock the way an eel moves '
        'through water, parting stone that is only pretending to be solid '
        'and closing again behind it, unhurried.',
    moves: [
      Spell(
        id: 'md_lap',
        name: 'Lap',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'md_surgeunder',
        name: 'Surge Under',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ Priority 3 — the Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'md_skinover',
        name: 'Skin Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('firesalt', weight: 45),
        DropEntry('pyro_shard', weight: 7),
        DropEntry('pyro_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ A Bruiser is completely telegraphed — the charge bar is the whole
  /// tell, same as every other Q1/Kinetic Bruiser.
  static const crustwalker = EnemyDef(
    id: 'crustwalker',
    name: 'Crustwalker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _geo,
    lore:
        'Something the size and shape of a boulder, walking on legs it grew '
        'for the occasion, its underside always a shade darker than the '
        'top — the part that has not finished cooling yet.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'md_crackforward',
        name: 'Crack Forward',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'md_breakthecrust',
        name: 'Break the Crust',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('emberhide', weight: 55, min: 1, max: 3),
        DropEntry('geo_shard', weight: 7),
        DropEntry('geo_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
  );

  /// ⚠️ Both moves multi-hit — the Blighter wins by out-lasting, never by any
  /// single hit being frightening.
  static const emberVent = EnemyDef(
    id: 'ember_vent',
    name: 'Ember Vent',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _pyro,
    lore:
        'A split in the floor no wider than a hand, breathing heat in slow '
        'irregular pulses. It has no body to speak of — only the vent, and '
        'what comes out of it.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'md_spitcinder',
        name: 'Spit Cinder',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'md_flareup',
        name: 'Flare Up',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('firesalt', weight: 45),
        DropEntry('obsidian', weight: 15),
      ],
    ),
  );

  /// ⭐ **The theme's sharpest edge.** The only thing down here that has
  /// stopped moving is the one thing that shatters.
  static const coolingThing = EnemyDef(
    id: 'cooling_thing',
    name: 'Cooling Thing',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _geo,
    lore:
        'A slick black skin over something that used to move, gone still '
        'long enough to hold an edge. Everything else down here is still '
        'liquid; this is what liquid looks like once it loses the argument.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'md_crack',
        name: 'Crack',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'md_shatter',
        name: 'Shatter',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('obsidian', weight: 50, min: 1, max: 2),
        DropEntry('geo_shard', weight: 5),
        DropEntry('geo_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each mini archetype, so the two drawn per run are always a
  // different pair of tactical roles.

  static const theFloor = EnemyDef(
    id: 'the_floor',
    name: 'The Floor',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'Not a creature standing on the floor — the floor itself, for as far '
        'as the light reaches, moving the way water moves when nobody is '
        'watching it closely enough to call it solid.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'md_giveunderfoot',
        name: 'Give Underfoot',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'md_openbeneathyou',
        name: 'Open Beneath You',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'md_firmup',
        name: 'Firm Up',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  static const magmaBehemoth = EnemyDef(
    id: 'magma_behemoth',
    name: 'Magma Behemoth',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _pyro,
    lore:
        'A mass the size of a house, moving at the speed a house should '
        'move, its whole hide a slow tide of black crust cracking open on '
        'bright orange and closing over it again a step later.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'md_pushtheflow',
        name: 'Push the Flow',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'md_crustover',
        name: 'Crust Over',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'md_reclaim',
        name: 'Reclaim',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **The Executioner's cost cap is lowered from 5 to 4 for this
  /// quarter** (KINETIC_CONTRACT §1.3) — Pyroclast must never carry a
  /// five-charge move.
  static const pyroclast = EnemyDef(
    id: 'pyroclast',
    name: 'Pyroclast',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _pyro,
    lore:
        'A tight, fast-moving knot of molten rock thrown clear of whatever '
        'is boiling below, still airborne more often than not. It does not '
        'so much attack as arrive, all at once.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'md_buildpressure',
        name: 'Build Pressure',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'md_blow',
        name: 'Blow',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects,
  /// and its cheap move lands ahead of everything on the board.
  /// 📝 The engine has no creature-applied debuff yet, so the archetype is
  /// written with the levers that actually resolve.
  static const firstmelt = EnemyDef(
    id: 'firstmelt',
    name: 'Firstmelt',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'The first place the floor gave way, still soft at the centre long '
        'after everything around it set. It knows exactly where every other '
        'weak point is, because it used to be one.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'md_findtheseam',
        name: 'Find the Seam',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'md_readtheheat',
        name: 'Read the Heat',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'md_meltthrough',
        name: 'Melt Through',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// ⛰️ **The mass boss** — what has NOT melted yet. A Juggernaut pays for
  /// its size by being predictable. ⚠️ 1080 HP at L29 is the largest number
  /// in the quarter by 4% (§1.2) — the top of a fifteen-level quarter is
  /// somewhere the Primal-band Juggernaut coefficient has never been fought.
  static const theSlowStone = EnemyDef(
    id: 'the_slow_stone',
    name: 'The Slow Stone',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _geo,
    lore:
        'The one part of the floor that never joined the rest, holding its '
        'shape long after everything around it went liquid. It has had a '
        'very long time to decide it is not going to be told otherwise.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'md_advance',
        name: 'Advance',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'md_coolthesurface',
        name: 'Cool the Surface',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'md_comedown',
        name: 'Come Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 👑 **The mind boss** — what BURNS. No weakness to exploit: a one-charge
  /// wall it can always afford, a mid-cost hit that lands ahead of the
  /// player's own shield, and a finisher. The threat is not the statline; it
  /// is that it plays well.
  static const efreet = EnemyDef(
    id: 'efreet',
    name: 'Efreet',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _pyro,
    lore:
        'A shape that holds itself upright out of pure insistence, fire '
        'wearing the idea of a body rather than needing one. It has opinions '
        'about who is allowed down here, and it is standing on all of them.',
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
        id: 'md_bankthecoals',
        name: 'Bank the Coals',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(12, 18),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      // A Tyrant is the archetype that knows what that is worth.
      Spell(
        id: 'md_stepthrough',
        name: 'Step Through',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'md_erupt',
        name: 'Erupt',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ `firstmelt_loop` appears here and nowhere below — the mote ladder's
  /// first real step is a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('pyro_shard'),
      DropEntry('geo_shard'),
      DropEntry('pyro_dust', min: 2, max: 4),
      DropEntry('geo_dust', min: 2, max: 4),
      DropEntry('pyro_crystal', chance: 0.25),
      DropEntry('geo_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('emberhide', weight: 35, min: 2, max: 4),
      DropEntry('obsidian', weight: 30, min: 2, max: 4),
      DropEntry('firesalt', weight: 30, min: 2, max: 4),
      DropEntry('firstmelt_loop', weight: 5),
    ],
  );

  /// ⚠️ **No Sigil essence in this table** — the collect-three-keys mechanism
  /// is rejected this quarter (§3.3/§8.6). Neither boss drops one, and the
  /// catalogue defines none.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('pyro_crystal', min: 1, max: 2),
      DropEntry('geo_crystal', min: 1, max: 2),
      DropEntry('pyro_shard', min: 1, max: 2),
      DropEntry('geo_shard', min: 1, max: 2),
      DropEntry('pyro_dust', min: 4, max: 8),
      DropEntry('geo_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('emberhide', weight: 35, min: 4, max: 8),
      DropEntry('obsidian', weight: 25, min: 3, max: 6),
      DropEntry('firstmelt_loop', weight: 25),
      DropEntry('the_long_cooling', weight: 15),
    ],
  );

  static const commons = <EnemyDef>[
    moltenWarden,
    slagswimmer,
    crustwalker,
    emberVent,
    coolingThing,
  ];

  static const minis = <EnemyDef>[
    theFloor,
    magmaBehemoth,
    pyroclast,
    firstmelt,
  ];

  static const bosses = <EnemyDef>[theSlowStone, efreet];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
