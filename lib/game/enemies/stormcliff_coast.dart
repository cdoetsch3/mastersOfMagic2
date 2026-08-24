/// The Stormcliff Coast bestiary — Lv 17–22, Electro (KINETIC_CONTRACT §4.2).
///
/// ⭐ **Theme: everything here is a path to the ground, including you.** The
/// coast is not a target, it is a **conductor** — from the arrival text,
/// *"the cliffs take the whole weight of it... the rock is scorched in long
/// vertical lines."* Things are charged in passing rather than struck.
///
/// ⚠️ **Stormcliff is *where* the lightning goes; Thunderspire is *when* it
/// comes** (§4.2's 2026-08-02 retheme). The split is space vs time and it
/// lives in the moves and the lore, not in the statlines — a builder of
/// either zone should read both sections before touching either roster.
///
/// ⭐ **The only Kinetic zone with an Adept**, and it is the anchor name kept
/// from `World.opponentNameFor`: the Stormcliff Tidecaller. Five of six
/// Kinetic zones have no yardstick creature at all (§8.4); this is the one
/// exception.
///
/// ⭐⭐ **The boss pair is the premise's two directions:** Storm Lord is
/// **what comes down** (a mind that arrives — Tyrant); The Return Stroke is
/// **what goes back up** — the bright half of a real lightning bolt travels
/// *upward*, the ground answering the sky (the element itself, taken to an
/// extreme — Aspect). ⚠️ **The Return Stroke's element was RULED Electro**
/// alongside Thunder Roc's (§8.8) — both hold; this zone's Aspect was never in
/// question.
///
/// ⚠️ **Combat stats (KINETIC_CONTRACT §2.2/§2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own default):
/// §2.3 calls it "the yardstick," and a yardstick with a thumb on the scale
/// stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/stormcliff_coast_test.dart`
/// resolves every id against [ItemCatalogue]. ⚠️ **`hardtack` is a cross-zone
/// reference**: it is defined in `old_quarry_items.dart` (a sibling Kinetic
/// builder's file), not this one — it will not resolve until that catalogue is
/// merged alongside this zone's. See the zone test for how that gap is
/// handled in isolation.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'stormcliff_coast';
const _electro = [MagicElement.electro];

/// Motes and bulk fall from everything; the main table is what varies.
/// ✅ Dust routine, Shards uncommon (the Q1 ruling this quarter inherits).
const _commonAlways = [DropEntry('electro_dust', chance: 0.75, min: 1, max: 2)];

abstract final class StormcliffCoastBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in the whole Kinetic quarter — the honest fight, the
  /// yardstick every other archetype here is felt against (§2.7).
  static const stormcliffTidecaller = EnemyDef(
    id: 'stormcliff_tidecaller',
    name: 'Stormcliff Tidecaller',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _electro,
    lore:
        'A tall, narrow figure of wet black rock standing where the spray '
        'lands hardest, hairline cracks of white light running down its '
        'front like the cliff behind it. It does not so much move as arrive, '
        'a half-second after the flash.',
    moves: [
      Spell(
        id: 'sc_arc',
        name: 'Arc',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sc_runtoearth',
        name: 'Run to Earth',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ Priority 3 — the Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'sc_holdthecharge',
        name: 'Hold the Charge',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('saltwort', weight: 45),
        DropEntry('hardtack', weight: 15),
      ],
    ),
  );

  /// ⭐ *Fulgurite is the glass left where lightning passed through sand* —
  /// the Sentinel is armoured by having been struck, which is the theme in
  /// one creature.
  static const fulguriteCrawler = EnemyDef(
    id: 'fulgurite_crawler',
    name: 'Fulgurite Crawler',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _electro,
    lore:
        'Knee-high and many-legged, its whole carapace fused glass, dark and '
        'faintly branching like a root system frozen mid-growth. It picks '
        'across broken rock without a single wasted step and draws in tight '
        'the moment the air starts to hum.',
    moves: [
      Spell(
        id: 'sc_pincer',
        name: 'Pincer',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'sc_setinglass',
        name: 'Set in Glass',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('seawrack_fibre', weight: 40),
        DropEntry('electro_shard', weight: 8, min: 1, max: 2),
        DropEntry('electro_dust', weight: 17, min: 2, max: 3),
        DropEntry('saltwort_draught', weight: 5),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the archetype
  /// multiplies them** — a Glasswing written at Bruiser numbers deletes a
  /// level-17 player from full health.
  static const sparkwing = EnemyDef(
    id: 'sparkwing',
    name: 'Sparkwing',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _electro,
    lore:
        'A hand-span of translucent wing over a body no bigger than a '
        'knuckle, riding the up-draught off the cliff face. A line of white '
        'light runs the length of each wing vein and brightens just before '
        'it lets go of the air entirely.',
    moves: [
      Spell(
        id: 'sc_flicker',
        name: 'Flicker',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'sc_flashover',
        name: 'Flash Over',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('saltwort', weight: 45),
        DropEntry('electro_shard', weight: 7),
        DropEntry('electro_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⚠️ Multi-hit only, both moves (§1.3's per-archetype rule) — *"lots of
  /// small bites, one occasionally stings"* (§2.3), and it rolls per hit.
  static const staticShoal = EnemyDef(
    id: 'static_shoal',
    name: 'Static Shoal',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _electro,
    lore:
        'A loose drift of finger-length eels, pale and nearly transparent, '
        'moving as one shape in the wash at the cliff\'s foot. Touch any '
        'part of the shoal and the whole thing answers at once.',
    moves: [
      Spell(
        id: 'sc_needle',
        name: 'Needle',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'sc_swarmthecurrent',
        name: 'Swarm the Current',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    // ⭐ Negative crit damage on purpose (§2.3): the sting that occasionally
    // lands is *weaker* than an ordinary crit, not stronger — the surprise is
    // that it lands at all, never that it hurts.
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('seawrack_fibre', weight: 50, min: 1, max: 2),
        DropEntry('electro_shard', weight: 5),
        DropEntry('electro_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
  /// ⭐ **`sc_earththrough` is the zone's grounding move** — the whole premise
  /// (§4.2's id-convention example) belongs to the creature that IS the path
  /// to the ground.
  static const groundling = EnemyDef(
    id: 'groundling',
    name: 'Groundling',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _electro,
    lore:
        'Low, quick and close to the rock, a shape like a lizard cast in wet '
        'slate. It crosses open ground in short bursts timed to the flash, '
        'never caught mid-stride when the light comes back down.',
    moves: [
      Spell(
        id: 'sc_dash',
        name: 'Dash',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sc_earththrough',
        name: 'Earth Through',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('seawrack_fibre', weight: 55, min: 1, max: 3),
        DropEntry('electro_shard', weight: 7),
        DropEntry('electro_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const brinecharge = EnemyDef(
    id: 'brinecharge',
    name: 'Brinecharge',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _electro,
    lore:
        'Man-tall and built like a breaking wave that never finished '
        'breaking, a churn of white water and standing light. It comes on '
        'at an even pace across open rock, balanced, entirely unhurried.',
    moves: [
      Spell(
        id: 'sc_surge',
        name: 'Surge',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sc_overrun',
        name: 'Overrun',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'sc_seawall',
        name: 'Sea Wall',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition — a current that does not let go, planted
  /// across the whole width of a gully and in no hurry to be anywhere else.
  static const theLongLine = EnemyDef(
    id: 'the_long_line',
    name: 'The Long Line',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _electro,
    lore:
        'A single unbroken run of white light down a wet gully wall, wide '
        'as a road and taller than a man, never quite going dark between '
        'flashes. There is no head, no front — only more of it, further up.',
    moves: [
      Spell(
        id: 'sc_undertow',
        name: 'Undertow',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'sc_bracethecurrent',
        name: 'Brace the Current',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'sc_drawdown',
        name: 'Draw Down',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    drops: _miniDrops,
  );

  static const voltgeist = EnemyDef(
    id: 'voltgeist',
    name: 'Voltgeist',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _electro,
    lore:
        'A standing shape of pure white afterimage, roughly a man\'s size '
        'and gone before the eye settles on it, only to be standing exactly '
        'where it was a moment later. It puts everything into the one blow '
        'it is clearly building toward.',
    moves: [
      Spell(
        id: 'sc_snap',
        name: 'Snap',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⚠️ The Executioner's cost cap is lowered from 5 to 4 this quarter
      // (§1.3) — bring a shield.
      Spell(
        id: 'sc_fullcharge',
        name: 'Full Charge',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 8, critChance: 12, critDamage: 40),
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority, not status**: it always
  /// connects, and its cheap move lands ahead of everything on the board.
  /// 📝 Same note as every Hexer in the quarter — the engine has no
  /// creature-applied debuff yet, so the archetype is written with the levers
  /// that actually resolve.
  static const stormShaman = EnemyDef(
    id: 'storm_shaman',
    name: 'Storm Shaman',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _electro,
    lore:
        'A stooped, robed shape at the very edge of the cliff, arms raised '
        'to a sky that is already answering. Wet rock, wet cloth, and a '
        'crown of small floating sparks that never quite go out.',
    moves: [
      Spell(
        id: 'sc_crackle',
        name: 'Crackle',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'sc_callthebolt',
        name: 'Call the Bolt',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sc_throughthewards',
        name: 'Through the Wards',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// 👑 **The Tyrant — the mind, and what comes down.** ⭐ No weakness to
  /// exploit: a one-charge wall it can always afford, a fast mid-cost hit
  /// that lands **ahead of the player's shield**, and a finisher. The threat
  /// is not the statline; it is that it plays well.
  static const stormLord = EnemyDef(
    id: 'storm_lord',
    name: 'Storm Lord',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _electro,
    lore:
        'A vast standing figure built entirely of falling and rising light, '
        'never the same shape twice and never less than man-height at the '
        'shoulder. It watches the whole cliff at once and answers whatever '
        'it decides is a threat first.',
    moves: [
      Spell(
        id: 'sc_gathercharge',
        name: 'Gather Charge',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(12, 18),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      // A Tyrant is the archetype that knows what that is worth.
      Spell(
        id: 'sc_choosethemoment',
        name: 'Choose the Moment',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'sc_thefullbolt',
        name: 'The Full Bolt',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
    drops: _bossDrops,
  );

  /// ⚡ **The Aspect — the element itself, and what goes back up.** ⭐ The
  /// bright half of a real lightning bolt travels *upward*; the ground
  /// answering the sky is the whole creature. Every move leans on the same
  /// thing its stat block does (§2.4): Electro's affinity is crit chance, so
  /// this is one enormous flash, over and over.
  static const theReturnStroke = EnemyDef(
    id: 'the_return_stroke',
    name: 'The Return Stroke',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _electro,
    lore:
        'Not a body at all — a standing column of light the width of a man, '
        'rooted in the scorched rock and reaching up out of sight into the '
        'weather. It does not move to attack. The whole coast is already '
        'wired to it, and the strike simply arrives.',
    moves: [
      Spell(
        id: 'sc_firstlight',
        name: 'First Light',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sc_climbing',
        name: 'Climbing',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'sc_thereturn',
        name: 'The Return',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      critChance: 25,
      critDamage: 45,
    ),
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ Crystal appears here and nowhere below — the mote ladder's first real
  /// step is a mini-boss reward (ITEMS §8).
  ///
  /// 📝 The Fulgurite Pendant's authored dropper is not singled out the way
  /// the Cinder Loop is — the pool shares one table across all four minis, per
  /// the Whispering Woods shape.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('electro_shard'),
      DropEntry('electro_dust', min: 2, max: 4),
      DropEntry('electro_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('seawrack_fibre', weight: 40, min: 2, max: 4),
      DropEntry('saltwort', weight: 30, min: 2, max: 4),
      DropEntry('saltwort_draught', weight: 25),
      DropEntry('fulgurite_pendant', weight: 5),
    ],
  );

  /// ⚠️ No essence — the Sigil's collect-three-keys mechanism is rejected
  /// (§3.3/§8.6). Nothing here is a gate item.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('electro_crystal', min: 1, max: 2),
      DropEntry('electro_shard', min: 1, max: 2),
      DropEntry('electro_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('seawrack_fibre', weight: 45, min: 4, max: 8),
      DropEntry('saltwort', weight: 25, min: 3, max: 6),
      DropEntry('fulgurite_pendant', weight: 20),
      DropEntry('uplight', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    stormcliffTidecaller,
    fulguriteCrawler,
    sparkwing,
    staticShoal,
    groundling,
  ];

  static const minis = <EnemyDef>[
    brinecharge,
    theLongLine,
    voltgeist,
    stormShaman,
  ];

  static const bosses = <EnemyDef>[stormLord, theReturnStroke];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
