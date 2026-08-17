/// The Glimmerbrook bestiary — Lv 3–8, Aqua (ENEMIES_DESIGN §2d).
///
/// ⭐ **Theme: everything here is holding still, and that is the wrong thing
/// for water to do.** Taken from the arrival text — *"fish hang in the current
/// without swimming; the water is colder than the season should allow."* It is
/// the only zone theme in the quarter built on an element behaving **wrongly**,
/// and it is deliberately the quarter's unanswered question (GAME_DESIGN §5).
///
/// ⚠️ **Nothing here may read as fast.** The Chill Eel is a Skirmisher and
/// still gets *poised*, not darting — a zone whose premise is stillness cannot
/// field a roster of quick little animals. Where an archetype demands tempo,
/// it is bought with **priority**, not with prose.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects.** Dart
/// forbids field access in a const expression, so `GlimmerbrookItems.fawnhide.id`
/// cannot appear here. `test/glimmerbrook_test.dart` resolves every id against
/// [ItemCatalogue] instead — a typo fails the suite, not the player.
///
/// ⚠️ **Move names are held to the strict Primal standard** (§3.3): nothing
/// below would look at home in a Pokédex; everything would look at home in a
/// field notebook.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_def.dart';

const _zone = 'glimmerbrook';
const _aqua = [MagicElement.aqua];

/// Motes and bulk fall from everything; the main table is what varies.
///
/// ⭐ **Dust routine, Shards uncommon** (ruling, 2026-08-17 — the reasoning is
/// written out once, on `whispering_woods.dart`). Every `*_shard` weight below
/// is a third of what it was and the freed weight went to `aqua_dust` in the
/// same table, so the mains still sum to 100.
const _commonAlways = [DropEntry('aqua_dust', chance: 0.75, min: 1, max: 2)];

abstract final class GlimmerbrookBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and an
  /// **Adept** — the yardstick every other archetype in the zone is felt
  /// against (§2.7). It is the honest fight: one cheap hit, one big one, one
  /// shield, and no trick at all.
  static const brookNaiad = EnemyDef(
    id: 'brook_naiad',
    name: 'Brook Naiad',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _aqua,
    lore:
        'A child-sized figure of clear water with pale stones hanging inside '
        'it where organs should be. Its edge is sharp, not misty, which is '
        'the detail that stops it looking like weather.',
    moves: [
      Spell(
        id: 'gb_ripple',
        name: 'Ripple',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'gb_pourover',
        name: 'Pour Over',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      Spell(
        id: 'gb_glassover',
        name: 'Glass Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('sapwort', weight: 45),
        DropEntry('foragers_ration', weight: 15),
      ],
    ),
  );

  /// ⭐ The Lasher's lesson in one creature: forty small bites, so a shield
  /// **chips** rather than shatters and a Barrier point is spent on almost
  /// nothing.
  static const shiverfishShoal = EnemyDef(
    id: 'shiverfish_shoal',
    name: 'Shiverfish Shoal',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _aqua,
    lore:
        'Forty fish holding one shape, too rigidly to be natural. It casts a '
        'single shadow, and I have not yet seen a fish leave it.',
    moves: [
      // ⭐ Every Lasher move is multi-hit. That is the archetype expressed
      // where the player can feel it: each hit meets the wall on its own.
      Spell(
        id: 'gb_nip',
        name: 'Nip',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(2, 3, hits: 3),
      ),
      Spell(
        id: 'gb_turnasone',
        name: 'Turn As One',
        chargeCost: 3,
        priority: 5,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('sapwort', weight: 50, min: 1, max: 2),
        DropEntry('aqua_shard', weight: 5),
        DropEntry('aqua_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage — the raw numbers stay small **because the
  /// archetype multiplies them**. A Glasswing written at Bruiser raws is a
  /// one-shot machine, and that is the easiest way to break this zone.
  static const glassfleckWisp = EnemyDef(
    id: 'glassfleck_wisp',
    name: 'Glassfleck Wisp',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _aqua,
    lore:
        'Made of the light off the water rather than of the water. It throws '
        'the brightness back at you in pieces, and looks as though touching '
        'it would end the argument.',
    moves: [
      Spell(
        id: 'gb_splinter',
        name: 'Splinter',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'gb_throwitback',
        name: 'Throw It Back',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('sapwort', weight: 40),
        // ⭐ Still the zone's mote-richest common — it just pays in Dust now.
        DropEntry('aqua_shard', weight: 8, min: 1, max: 2),
        DropEntry('aqua_dust', weight: 17, min: 2, max: 3),
        DropEntry('sapwort_draught', weight: 5),
      ],
    ),
  );

  /// ⭐ The Sentinel is the zone's shield tutor: it puts up a wall bigger than
  /// anything the player owns at level 5, and the answer is to break it rather
  /// than to out-damage it.
  static const siltbackCrawler = EnemyDef(
    id: 'siltback_crawler',
    name: 'Siltback Crawler',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _aqua,
    lore:
        'A crayfish crossed with a boulder, low to the riverbed and crusted '
        'over with weed. Two eyes on stalks, set close, and both of them on '
        'you the whole time.',
    moves: [
      Spell(
        id: 'gb_beardown',
        name: 'Bear Down',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 16),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band): four charges of
      // wall means four turns of telegraph, which is what it pays for it.
      Spell(
        id: 'gb_siltover',
        name: 'Silt Over',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('fawnhide', weight: 55, min: 1, max: 3),
        DropEntry('aqua_shard', weight: 7),
        DropEntry('aqua_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
  /// ⚠️ Note what that buys the zone — the eel is *first*, never *fast*. The
  /// theme survives because tempo lives in the priority field, not the prose.
  static const chillEel = EnemyDef(
    id: 'chill_eel',
    name: 'Chill Eel',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _aqua,
    lore:
        'Bone-white and nearly clear, held straight rather than coiled. Frost '
        'forms on the water around it while it is doing nothing whatsoever.',
    moves: [
      Spell(
        id: 'gb_snapto',
        name: 'Snap To',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'gb_runcold',
        name: 'Run Cold',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(10, 14),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('fawnhide', weight: 50, min: 2, max: 3),
        DropEntry('aqua_shard', weight: 7),
        DropEntry('aqua_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const weirkeeper = EnemyDef(
    id: 'weirkeeper',
    name: 'Weirkeeper',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _aqua,
    lore:
        'A man built out of the beams of an old weir, wet timber and river '
        'stone, water pouring steadily through the gaps in its chest. It '
        'carries nothing, because it does not need to.',
    moves: [
      Spell(
        id: 'gb_sluice',
        name: 'Sluice',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 16),
      ),
      Spell(
        id: 'gb_openthegates',
        name: 'Open the Gates',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 33),
      ),
      Spell(
        id: 'gb_holdback',
        name: 'Hold Back',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition: it would rather wait than win, and every
  /// move it has is about **not letting go**.
  static const theHeldBreath = EnemyDef(
    id: 'the_held_breath',
    name: 'The Held Breath',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _aqua,
    lore:
        'One bubble of air taller than a man, held under and refusing to rise. '
        'There is a curled shape inside it. I have written down twice that it '
        'is a thing being kept, not a thing swimming.',
    moves: [
      Spell(
        id: 'gb_press',
        name: 'Press',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'gb_holdunder',
        name: 'Hold Under',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(32, 40),
      ),
      Spell(
        id: 'gb_surfacing',
        name: 'Surfacing',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(22, 28),
      ),
    ],
    drops: _miniDrops,
  );

  static const paleCoil = EnemyDef(
    id: 'pale_coil',
    name: 'Pale Coil',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _aqua,
    lore:
        'An eel as thick as a man\'s waist and three times his length, coiled '
        'once with the head up. Blind. The water around it is noticeably '
        'clearer than the rest, which I would rather not think about.',
    moves: [
      Spell(
        id: 'gb_takewhole',
        name: 'Take Whole',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⚠️ The Executioner's whole contract: five charges of telegraph, and
      // then a number that ends an unshielded player outright.
      Spell(
        id: 'gb_downandunder',
        name: 'Down and Under',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(46, 60),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature here is **priority, not status**: it always
  /// connects, and one of its moves lands ahead of everything on the board.
  /// 📝 The engine has no debuff a creature can apply yet (§4.2 is unbuilt),
  /// so the archetype is expressed with the levers that do resolve — odd
  /// priorities and a hit that ignores the wall.
  static const frostgleamNaiad = EnemyDef(
    id: 'frostgleam_naiad',
    name: 'Frostgleam Naiad',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _aqua,
    lore:
        'A Brook Naiad grown up and half frozen — ice blooming across her '
        'shoulders and brow while the rest of her still runs. She is not in '
        'any hurry, and the stones inside her have stopped moving.',
    moves: [
      Spell(
        id: 'gb_gleam',
        name: 'Gleam',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'gb_holdstill',
        name: 'Hold Still',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(9, 12),
      ),
      Spell(
        id: 'gb_frostover',
        name: 'Frost Over',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(14, 18, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// ⛰️ **The endurance boss.** Enormous, slow, and it has been down there the
  /// whole time — a Juggernaut pays for its size by being predictable.
  static const theColdBelow = EnemyDef(
    id: 'the_cold_below',
    name: 'The Cold Below',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _aqua,
    lore:
        'Broad, flat and wider than a house, seen through water that should '
        'not be deep enough to hold it. Only part of it is ever visible. The '
        'rest goes down into black and keeps going.',
    moves: [
      Spell(
        id: 'gb_comeup',
        name: 'Come Up',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 52),
      ),
      Spell(
        id: 'gb_deepcold',
        name: 'Deep Cold',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'gb_takeyoudown',
        name: 'Take You Down',
        chargeCost: 3,
        priority: 6,
        effect: DamageEffect(20, 26),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✨ **The trick boss.** Aqua taken to an extreme the player has not seen:
  /// ⭐ it re-walls itself for a single charge, every turn, forever — so chip
  /// damage is worthless — and its own attacks go **through** the player's
  /// wall. The lesson is that a shielding war against water is unwinnable.
  static const stillwater = EnemyDef(
    id: 'stillwater',
    name: 'Stillwater',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _aqua,
    lore:
        'Three storeys of standing pool, mirror-flat on every face, with no '
        'features of any kind. It reflects whoever is in front of it. Nothing '
        'inside it moves, and that is the entire horror of the thing.',
    moves: [
      // ⭐ One charge for a real wall. Nothing else in the quarter can do this,
      // and it is the whole shape of the fight.
      Spell(
        id: 'gb_mirror',
        name: 'Mirror',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(20, 26),
      ),
      Spell(
        id: 'gb_closeover',
        name: 'Close Over',
        chargeCost: 2,
        priority: 7,
        effect: DamageEffect(13, 17, ignoresShields: true),
      ),
      Spell(
        id: 'gb_standup',
        name: 'Stand Up',
        chargeCost: 4,
        priority: 6,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ Crystal appears here and nowhere below — the mote ladder's first real
  /// step is a mini-boss reward (ITEMS §8).
  ///
  /// 📝 The Brookstone Pendant's authored dropper is the **Frostgleam Naiad**
  /// (`glimmerbrook_items.dart`). The pool shares one table, per the Whispering
  /// Woods shape, so it hangs off all four minis at the chase weight; narrowing
  /// it to one creature is a per-creature table, which no zone has yet.
  static const _miniDrops = DropTable(
    always: [
      // ⭐ One guaranteed Shard, not 1–3: this bucket was ~90% of the zone's
      // Shard income (see `whispering_woods.dart`'s _miniDrops). The Dust is
      // new — elevated ranks never dropped any.
      DropEntry('aqua_shard'),
      DropEntry('aqua_dust', min: 2, max: 4),
      DropEntry('aqua_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('fawnhide', weight: 40, min: 2, max: 4),
      DropEntry('sapwort', weight: 30, min: 2, max: 4),
      DropEntry('foragers_ration', weight: 25),
      DropEntry('brookstone_pendant', weight: 5),
    ],
  );

  /// ⚠️ Glimmerbrook has **no Epic** — the quarter's only one is Ashfall
  /// Vale's Charlock. The slot Whispering Woods spends on the Heartwood Staff
  /// goes back into bulk here rather than being filled for symmetry's sake.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('aqua_crystal', min: 1, max: 2),
      DropEntry('aqua_shard', min: 1, max: 2),
      DropEntry('aqua_dust', min: 4, max: 8),
      // ⭐ The gate item. The second of Hearthwood's "three ordinary proofs".
      DropEntry('proof_of_the_brook'),
    ],
    main: [
      DropEntry('fawnhide', weight: 45, min: 4, max: 8),
      DropEntry('sapwort', weight: 25, min: 3, max: 6),
      DropEntry('brookstone_pendant', weight: 20),
      DropEntry('foragers_ration', weight: 10, min: 1, max: 2),
    ],
  );

  static const commons = <EnemyDef>[
    brookNaiad,
    shiverfishShoal,
    glassfleckWisp,
    siltbackCrawler,
    chillEel,
  ];

  static const minis = <EnemyDef>[
    weirkeeper,
    theHeldBreath,
    paleCoil,
    frostgleamNaiad,
  ];

  static const bosses = <EnemyDef>[theColdBelow, stillwater];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
