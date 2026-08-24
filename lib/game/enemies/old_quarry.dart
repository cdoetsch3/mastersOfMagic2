/// The Old Quarry bestiary — Lv 15–19, Geo (KINETIC_CONTRACT §4.1).
///
/// ⭐ **Theme: the hole remembers what filled it.** The threat is the
/// **absence**, not the stone — negative space gone solid. Whatever was
/// quarried out of here left a shape, and the shape has started to move.
///
/// ⚠️ **The deliberate rhyme with The Umbral Wastes is not duplication and
/// must not be "fixed"**: here something was **removed** and the hole is
/// animate; there dark was **imposed** and given a shape.
///
/// ⭐ **The boss pair is the premise's two sides:** Mountain Heart is what was
/// TAKEN (a mass — Juggernaut), The Empty Course is the shape of what is
/// GONE, walking (a thing that decided — Tyrant).
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/old_quarry_test.dart`
/// resolves every id against [ItemCatalogue] instead.
///
/// ⚠️ **Combat stats are copied verbatim from KINETIC_CONTRACT §2.3's
/// per-archetype table** — this is the first zone to carry [EnemyCombatStats],
/// and every non-Adept, non-Aspect archetype in this roster gets its row.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'old_quarry';
const _geo = [MagicElement.geo];

/// Motes and bulk fall from everything; the main table is what varies.
/// ⭐ Dust routine, Shard and Crystal are the chase — the same shape every
/// Primal zone already uses, extended to Geo.
const _commonAlways = [DropEntry('geo_dust', chance: 0.75, min: 1, max: 2)];

abstract final class OldQuarryBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`. A Bruiser
  /// is the right first impression for a zone about pressure held in stone:
  /// completely telegraphed, and the charge bar is the whole tell.
  static const quarryGolem = EnemyDef(
    id: 'quarry_golem',
    name: 'Quarry Golem',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _geo,
    lore:
        'Stacked terrace stone that never settled after it was cut, holding '
        'roughly the shape of what used to stand there. It moves like '
        'something remembering how to walk.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'oq_pressin',
        name: 'Press In',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Expensive and slow on purpose — the Bruiser must charge, and the
      // charge bar is the tell. That telegraph is what it pays for its stats.
      Spell(
        id: 'oq_bringitdown',
        name: 'Bring It Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('tin_ore', weight: 55, min: 1, max: 3),
        DropEntry('geo_shard', weight: 7),
        DropEntry('geo_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
  );

  /// ⚠️ −10 accuracy — its incompetence is in the number too.
  static const tailingsDrudge = EnemyDef(
    id: 'tailings_drudge',
    name: 'Tailings Drudge',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.drudge,
    elements: _geo,
    lore:
        'Loose spoil piled by hands that stopped caring where it went, '
        'shuffling in slow circles because nobody ever told it the digging '
        'was over.',
    combatStats: EnemyCombatStats(accuracyBonus: -10),
    moves: [
      Spell(
        id: 'oq_giveway',
        name: 'Give Way',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(4, 7),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('tin_ore', weight: 45),
        DropEntry('hardtack', weight: 15),
      ],
    ),
  );

  /// ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
  static const chiselback = EnemyDef(
    id: 'chiselback',
    name: 'Chiselback',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _geo,
    lore:
        'Fist-sized and quick, its shell scored with the same parallel '
        'grooves a chisel leaves in a cut face. It moves before the tool '
        'marks finish settling.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'oq_scuttle',
        name: 'Scuttle',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'oq_chipaway',
        name: 'Chip Away',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('quarry_jasper', weight: 45),
        DropEntry('geo_shard', weight: 7),
        DropEntry('geo_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ The Lasher's lesson in one creature: dozens of small bites, so a
  /// shield chips rather than shatters.
  static const gravelswarm = EnemyDef(
    id: 'gravelswarm',
    name: 'Gravelswarm',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _geo,
    lore:
        'Not one thing but hundreds of loose stones holding a single shape '
        'between them, shifting and re-forming with every stride like scree '
        'that decided to walk uphill.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      // ⭐ Every Lasher move is multi-hit. That is the archetype expressed
      // where the player can feel it: each hit meets the wall on its own.
      Spell(
        id: 'oq_patter',
        name: 'Patter',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'oq_tumblethrough',
        name: 'Tumble Through',
        chargeCost: 3,
        priority: 5,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('tin_ore', weight: 50, min: 1, max: 2),
        DropEntry('geo_shard', weight: 5),
        DropEntry('geo_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ The zone's shield tutor: hung dead vertical and never leaning,
  /// regardless of what strikes it.
  static const plumblineSentry = EnemyDef(
    id: 'plumbline_sentry',
    name: 'Plumbline Sentry',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _geo,
    lore:
        'A slab hung dead vertical on nothing, exactly the way a mason\'s '
        'plumbline hangs, and it does not lean no matter what strikes it.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'oq_holdtheline',
        name: 'Hold the Line',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'oq_squareoff',
        name: 'Square Off',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('quarry_jasper', weight: 40),
        DropEntry('geo_shard', weight: 8, min: 1, max: 2),
        DropEntry('geo_dust', weight: 17, min: 2, max: 3),
        DropEntry('hardtack', weight: 5),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles.

  /// ⚠️ Was a name collision with The Molten Deep, already resolved — the
  /// Deep took Pyroclast. Keep it resolved.
  static const obsidianGolem = EnemyDef(
    id: 'obsidian_golem',
    name: 'Obsidian Golem',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _geo,
    lore:
        'Black glass where the quarry face sheared clean, taller than a man '
        'and balanced without effort, both fists a different size because '
        'nothing made them match.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'oq_swingwide',
        name: 'Swing Wide',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'oq_bringtheweight',
        name: 'Bring the Weight',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'oq_settle',
        name: 'Settle',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition — a weight the terraces gave up, planted
  /// wherever it stops as if the ground always meant to be that shape.
  static const earthTitan = EnemyDef(
    id: 'earth_titan',
    name: 'Earth Titan',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _geo,
    lore:
        'Three terraces\' worth of stone gathered into one standing weight, '
        'planted wherever it stops as if the ground had always meant to be '
        'that shape.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'oq_grindforward',
        name: 'Grind Forward',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'oq_rootin',
        name: 'Root In',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'oq_takeitback',
        name: 'Take It Back',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **The Executioner's cost cap is lowered from 5 to 4 for this
  /// quarter** (KINETIC_CONTRACT §1.3) — at the mini five-charge raw it is a
  /// literal one-shot at the top of the band. At cost 4 it lands two casts,
  /// exactly the ratio Q1's Hollow Stag has at level 5.
  static const deadweight = EnemyDef(
    id: 'deadweight',
    name: 'Deadweight',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _geo,
    lore:
        'A slab shaped for hauling, still moving the way something on a '
        'sledge moves — slow, then all at once, and it does not stop where '
        'a person would.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      // ⚠️ TRIMMED from the §2.3 Executioner row (12/+40) by the same
      // 2026-08-20 ruling as Mountain Heart — the entry band meets crit
      // at Bruiser strength (8/+25); later Executioners keep 12/+40.
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'oq_leanin',
        name: 'Lean In',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'oq_dropitsweight',
        name: 'Drop Its Weight',
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
  static const theOverseer = EnemyDef(
    id: 'the_overseer',
    name: 'The Overseer',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _geo,
    lore:
        'Wears the old measuring marks cut into the rock as though they '
        'were its own joints, and it corrects anything that has drifted out '
        'of true, including itself.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'oq_markit',
        name: 'Mark It',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'oq_takemeasure',
        name: 'Take Measure',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'oq_striketheline',
        name: 'Strike the Line',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// ⛰️ **The mass boss** — what was taken. A Juggernaut pays for its size by
  /// being predictable, and this one wears its own crater like a chest
  /// cavity.
  static const mountainHeart = EnemyDef(
    id: 'mountain_heart',
    name: 'Mountain Heart',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _geo,
    lore:
        'The mass the quarry gave up, wearing its own crater like a chest '
        'cavity. Whatever was carried out of this mountain, it remembers '
        'carrying it.',
    // ⚠️ HALVED from the §2.3 Juggernaut row (25/35) by ruling 2026-08-20:
    // the balance probe measured 1 crafted win in 500 — an entry-band boss
    // teaching deflection must not also wield it at full strength. The Slow
    // Stone (Molten Deep, quarter ceiling) keeps the full block.
    combatStats: EnemyCombatStats(deflectChance: 12, deflectAmount: 18),
    moves: [
      Spell(
        id: 'oq_grindon',
        name: 'Grind On',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'oq_settledeeper',
        name: 'Settle Deeper',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'oq_collapseinward',
        name: 'Collapse Inward',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 👑 **The mind boss** — the shape of what is gone, walking. It is the
  /// only boss in the zone with no weakness to exploit: a one-charge wall it
  /// can always afford, a mid-cost hit that lands ahead of the player's own
  /// shield, and a finisher. The threat is not the statline; it is that it
  /// plays well.
  static const theEmptyCourse = EnemyDef(
    id: 'the_empty_course',
    name: 'The Empty Course',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _geo,
    lore:
        'A hollow the exact shape of what is missing, walking upright '
        'because the missing thing once did. It has no face, only the place '
        'a face was cut from.',
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
        id: 'oq_holdstill',
        name: 'Hold Still',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(12, 18),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      // A Tyrant is the archetype that knows what that is worth.
      Spell(
        id: 'oq_takethestep',
        name: 'Take the Step',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'oq_fillthespace',
        name: 'Fill the Space',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ `geo_crystal` appears here and nowhere below — the mote ladder's
  /// first real step is a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('geo_shard'),
      DropEntry('geo_dust', min: 2, max: 4),
      DropEntry('geo_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('tin_ore', weight: 40, min: 2, max: 4),
      DropEntry('quarry_jasper', weight: 30, min: 2, max: 4),
      DropEntry('hardtack', weight: 25),
      DropEntry('overseers_seal', weight: 5),
    ],
  );

  /// ⚠️ **No Sigil essence in this table** — the collect-three-keys mechanism
  /// is rejected this quarter (KINETIC_CONTRACT §3.3/§8.6). Neither boss
  /// drops one, and the catalogue defines none.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('geo_crystal', min: 1, max: 2),
      DropEntry('geo_shard', min: 1, max: 2),
      DropEntry('geo_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('tin_ore', weight: 45, min: 4, max: 8),
      DropEntry('quarry_jasper', weight: 25, min: 3, max: 6),
      DropEntry('overseers_seal', weight: 20),
      DropEntry('the_given_weight', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    quarryGolem,
    tailingsDrudge,
    chiselback,
    gravelswarm,
    plumblineSentry,
  ];

  static const minis = <EnemyDef>[
    obsidianGolem,
    earthTitan,
    deadweight,
    theOverseer,
  ];

  static const bosses = <EnemyDef>[mountainHeart, theEmptyCourse];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
