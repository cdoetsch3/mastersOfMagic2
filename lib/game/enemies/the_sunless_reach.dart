/// The Sunless Reach bestiary — Lv 38–42, Solar + Lunar (CELESTIAL_CONTRACT
/// §4.5, ENEMIES §2e).
///
/// ⭐⭐ **Theme: identical ground, opposite worlds, one line between them.**
/// From the arrival text — *"You come over the crest out of glare into a
/// valley that has never been lit. The rock is the same rock. The desert is a
/// thousand feet away and on the other side of the world."* ⚠️ **The fusion
/// is a boundary, not a blend**: a creature here is almost always on one side
/// or the other, and the handful that carry both elements are the ones that
/// *are* the line.
///
/// ⚠️ **This zone assigns element per creature, not "both" by default**
/// (§4.5's roster table) — five are pure Solar or pure Lunar, and only
/// `eclipse_herald`, `the_crest` and `both_sided_thing` carry both. Read the
/// roster table before touching an element list.
///
/// ⭐⭐ **The only zone in the game with TWO Aspects, and it is deliberate**
/// (ENEMIES §2f/§2g). Its premise is identical ground on two sides of a line,
/// so *the same archetype in two elements* **is** the mechanical statement of
/// the theme. ⚠️ **They must not share a stat block** (CELESTIAL §2.4) or the
/// doubling says nothing: The Last Light is the bright, accurate, spiky half
/// (acc +20, crit 20/+25); The First Dark is the half you cannot find or hurt
/// (dodge 10, defl 25/25). Do not "fix" this into one boss and a mirror.
///
/// ⚠️ **Both Aspects are single-element** (ENEMIES §2.5) — an Aspect *is* one
/// element's passive taken to an extreme, so the Solar one may not carry
/// Lunar and vice versa. That is also why the pair can stand as a pair.
///
/// ⚠️ **Combat stats (CELESTIAL_CONTRACT §2.2/§2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own
/// default): §2.3 calls it "the yardstick," and a yardstick with a thumb on
/// the scale stops being one.
///
/// ⭐ **Crestline Warden is Sentinel → Bruiser, ruled (ENEMIES §2e).** *"It
/// does not hold the line, it shoves you back over it"* — a boundary zone's
/// premise expressed as a stat block. ⚠️ It still draws the contract's **"the
/// Sentinel" drop row** (§4.5), which is keyed to the role the slot plays,
/// not to the archetype the rebalance landed on.
///
/// ⚠️ **No off-element move anywhere in this zone.** ENEMIES §2e.2 names the
/// four creatures in the whole game that carry one, and none of them is here.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_sunless_reach_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`solar_*`,
/// `lunar_*` and `pilgrims_ration` are cross-zone references** — the mote
/// families live with the zone that first yields them (§3.2), which is The
/// Kiln Desert (Solar) and The Mirrormere (Lunar), and the ration is the Kiln
/// Desert's. All three are sibling Celestial builders' files and resolve once
/// the merge coordinator lands the parallel worktrees together.
///
/// ⚠️ **A `hide` role in a zone with no hide item resolves to the zone's
/// SECOND gatherable material** (ETHEREAL_CONTRACT §3.5.1) — here `duskcap`,
/// which is exactly the contract's "material-B" row. Nothing in the Sunless
/// Reach is kill-only.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_sunless_reach';
const _both = [MagicElement.solar, MagicElement.lunar];
const _solar = [MagicElement.solar];
const _lunar = [MagicElement.lunar];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.5's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('solar_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('lunar_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class SunlessReachBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster — the yardstick, and *"the only thing here
  /// that stands on both sides"* (§4.5's roster note). It is the one common
  /// whose elements are both.
  static const eclipseHerald = EnemyDef(
    id: 'eclipse_herald',
    name: 'Eclipse Herald',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A robed shape that walks the crest itself rather than either side '
        'of it, lit hard along one flank and entirely unlit along the '
        'other, with no softening anywhere between the two. It never steps '
        'off the line in either direction.',
    moves: [
      Spell(
        id: 'sr_crossthecrest',
        name: 'Cross the Crest',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit.
      Spell(
        id: 'sr_standinboth',
        name: 'Stand in Both',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'sr_readthedivision',
        name: 'Read the Division',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('duskcap', weight: 50, min: 1, max: 2),
        DropEntry('solar_shard', weight: 5),
        DropEntry('solar_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Sentinel → **Bruiser** (ENEMIES §2e): it does not hold the line, it
  /// shoves you back over it. ⚠️ −8 accuracy and +25 crit damage (§2.3) —
  /// it hits like a truck and sometimes whiffs entirely, and its cost band
  /// (2–5) is the archetype's "slow" tempo lean stated as charge (§2.5).
  /// ⚠️ It keeps the contract's **"the Sentinel" drop row** — the eclipse
  /// opal slot — because the drop table is keyed by role, not archetype.
  static const crestlineWarden = EnemyDef(
    id: 'crestline_warden',
    name: 'Crestline Warden',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _solar,
    lore:
        'A broad, sun-scoured figure that patrols the lit side of the ridge '
        'and never once descends the other. It moves people the way a gate '
        'moves them: in one direction, and without discussion.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'sr_shoveback',
        name: 'Shove Back',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band) — a cost-5 move
      // means it must charge, which means it telegraphs.
      Spell(
        id: 'sr_putyouoverit',
        name: 'Put You Over It',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('eclipse_opal', weight: 40),
        DropEntry('solar_shard', weight: 8, min: 1, max: 2),
        DropEntry('solar_dust', weight: 17, min: 2, max: 3),
        DropEntry('duskcap_tonic', weight: 5),
      ],
    ),
  );

  /// ⭐⭐ Solar's passive is **Blind**, and a glare that follows you into a
  /// valley that has never been lit is the purest version of it (§4.5).
  /// ⚠️ Both moves multi-hit (§1.3's per-archetype rule) — a Blighter wins by
  /// out-lasting rather than out-hitting.
  static const nightglare = EnemyDef(
    id: 'nightglare',
    name: 'Nightglare',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _solar,
    lore:
        'A knot of hard white light about the size of a head that holds its '
        'position relative to a traveler no matter which way they turn, well '
        'down inside a valley that has never had a sun in it. Looking away '
        'does not help and looking at it helps less.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'sr_findyouanyway',
        name: 'Find You Anyway',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'sr_holdyouinit',
        name: 'Hold You in It',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('ebony_log', weight: 55, min: 1, max: 3),
        DropEntry('lunar_shard', weight: 7),
        DropEntry('lunar_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Damage in pieces (§4.5) — the Lasher's lesson, and a swarm of cold
  /// light is the fiction that states it. ⚠️ +15 crit chance, −20 crit
  /// damage (§2.3): lots of small bites, one of which occasionally stings.
  static const coldlightSwarm = EnemyDef(
    id: 'coldlight_swarm',
    name: 'Coldlight Swarm',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _lunar,
    lore:
        'A loose cloud of pale motes the size of a large dog when it is '
        'gathered, each one bright enough to see by and none of them warm. '
        'It comes apart and reassembles constantly, so nothing about it '
        'stays in one place long enough to be struck.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'sr_settleonyou',
        name: 'Settle On You',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'sr_comeapart',
        name: 'Come Apart',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('ebony_log', weight: 55, min: 1, max: 3),
        DropEntry('lunar_shard', weight: 7),
        DropEntry('lunar_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Priority (§4.5) — the Skirmisher's lesson, and both its moves resolve
  /// at the quick rung (5) rather than the attack rung, which is the shipped
  /// Skirmisher shape.
  static const shadowpitchStalker = EnemyDef(
    id: 'shadowpitch_stalker',
    name: 'Shadowpitch Stalker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _lunar,
    lore:
        'A low four-limbed shape a little longer than a person is tall, so '
        'black against black rock that it is only ever seen as an absence '
        'crossing something paler. It keeps entirely to the unlit side and '
        'closes the last of the distance faster than the rest of it.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'sr_closefromthedark',
        name: 'Close From the Dark',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sr_getthereahead',
        name: 'Get There Ahead',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('duskcap', weight: 50, min: 1, max: 2),
        DropEntry('solar_shard', weight: 5),
        DropEntry('solar_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ The lit side's own champion — pure Solar, and simply good at
  /// everything (§2.3: acc +6, crit 10).
  static const solarArchon = EnemyDef(
    id: 'solar_archon',
    name: 'Solar Archon',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _solar,
    lore:
        'A tall armoured figure half again the height of a person, its plate '
        'polished to the point where the desert behind it is legible in the '
        'surface. It stands on the crest facing outward, as though the '
        'valley below were something it had been posted against.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'sr_comeoverthecrest',
        name: 'Come Over the Crest',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sr_raisetheglare',
        name: 'Raise the Glare',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
      Spell(
        id: 'sr_bringthewholenoon',
        name: 'Bring the Whole Noon',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The ridge itself — **the only creature that IS the line** (§4.5), and
  /// the reason it carries both elements while the pure minis beside it carry
  /// one. ⚠️ Its wall goes up at priority 2, ahead of the player's own shield
  /// at 3: a Redoubt that shields *after* being hit is only a bigger HP bar.
  static const theCrest = EnemyDef(
    id: 'the_crest',
    name: 'The Crest',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _both,
    lore:
        'A length of ridge perhaps thirty feet of it, standing up off the '
        'ground as a single slab and moving at the pace a shadow moves. The '
        'lit face and the unlit face meet along its top edge in a line with '
        'no gradient in it at all.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'sr_holdtheline',
        name: 'Hold the Line',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'sr_standastheedge',
        name: 'Stand as the Edge',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'sr_bringtheridgedown',
        name: 'Bring the Ridge Down',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap 4, not 5** (§1.3's Executioner ruling) — at this band a
  /// five-charge mini raw would be a one-shot with change. ⭐ Its finisher
  /// carries the execute rider: the thing that is both halves at once is what
  /// arrives when you are already down to one of them.
  static const bothSidedThing = EnemyDef(
    id: 'both_sided_thing',
    name: 'Both-Sided Thing',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _both,
    lore:
        'A person-sized figure split top to bottom down its exact centre, '
        'one half bleached the colour of the desert floor and the other the '
        'flat black of the valley, with nothing blended along the seam. '
        'Whichever half is turned toward you is the one doing the work.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'sr_turnthedarkhalf',
        name: 'Turn the Dark Half',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'sr_showyouboth',
        name: 'Show You Both',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 25),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects, and
  /// its cheap move lands ahead of everything on the board. 📝 The engine has
  /// no creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve — the earliest priorities in the zone, and
  /// the one move here that walks through a shield.
  static const duskmarch = EnemyDef(
    id: 'duskmarch',
    name: 'Duskmarch',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _lunar,
    lore:
        'The shadow line itself, walking the valley floor at the pace the '
        'day sets and never varying from it. Anything standing where it has '
        'already passed finds the ground colder than the ground a stride '
        'behind them.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'sr_marktheshadow',
        name: 'Mark the Shadow',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      // The line arrives when the line arrives.
      Spell(
        id: 'sr_arriveontime',
        name: 'Arrive on Time',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sr_passoveryou',
        name: 'Pass Over You',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------
  //
  // ⭐⭐ **Two Aspects, and the pair IS the theme** (ENEMIES §2f/§2g, the one
  // blessed doubling in the game). ⚠️ Same archetype, opposite elements,
  // deliberately different stat blocks and deliberately different kits — the
  // Solar half is all edge and no wall, the Lunar half is all wall and no
  // edge. Do not fold them into a boss-and-its-cause pair; that is Frostfell's
  // shape, and this zone is making a different argument.

  /// ☀️ **The Solar Aspect — the bright, accurate, spiky half** (§2.4: acc
  /// +20, crit 20 / +25). ⚠️ Single-element by rule (ENEMIES §2.5): Solar's
  /// Blind, taken to an extreme, is the whole creature. ⭐ It carries **no
  /// shield at all** — light does not take cover.
  static const theLastLight = EnemyDef(
    id: 'the_last_light',
    name: 'The Last Light',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _solar,
    lore:
        'The final hand-width of sun on the top of the crest, held there '
        'long after the angle should have taken it, and about as tall as the '
        'ridge it is standing on. It does not descend into the valley and it '
        'has never needed to.',
    // ⚠️ §2.4's row, verbatim: acc +20, crit 20 / +25.
    combatStats: EnemyCombatStats(
      accuracyBonus: 20,
      critChance: 20,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'sr_catchtheeye',
        name: 'Catch the Eye',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sr_narrowtolast',
        name: 'Narrow to Last',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'sr_gooutallatonce',
        name: 'Go Out All at Once',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🌑 **The Lunar Aspect — the half you cannot find or hurt** (§2.4: dodge
  /// 10, defl 25 / 25, EV 6.3%). ⚠️ Single-element by rule, and ⚠️ **its stat
  /// block must never be copied from The Last Light's** — the doubling is
  /// only worth keeping while the two read as opposites. ⭐ Where the Solar
  /// half is three attacks, this one spends its middle rung on a wall: the
  /// dark is the thing you cannot get through.
  static const theFirstDark = EnemyDef(
    id: 'the_first_dark',
    name: 'The First Dark',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _lunar,
    lore:
        'The whole unlit side of the valley, standing up. It has the height '
        'of the scarp and no edges anywhere on it, and the only way to know '
        'where it is at any moment is by what has stopped being visible.',
    // ⚠️ §2.4's row, verbatim: dodge 10, defl 25 / 25.
    combatStats: EnemyCombatStats(
      dodge: 10,
      deflectChance: 25,
      deflectAmount: 25,
    ),
    moves: [
      Spell(
        id: 'sr_reachthefloorfirst',
        name: 'Reach the Floor First',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sr_closeoverit',
        name: 'Close Over It',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'sr_keepwhatitcovers',
        name: 'Keep What It Covers',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.5) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('solar_shard'),
      DropEntry('lunar_shard'),
      DropEntry('solar_dust', min: 2, max: 4),
      DropEntry('lunar_dust', min: 2, max: 4),
      DropEntry('solar_crystal', chance: 0.25),
      DropEntry('lunar_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('ebony_log', weight: 40, min: 2, max: 4),
      DropEntry('duskcap', weight: 30, min: 2, max: 4),
      DropEntry('eclipse_opal', weight: 25, min: 1, max: 2),
      DropEntry('crestline_ring', weight: 5),
    ],
  );

  /// ⚠️ **NO essence, and no key** — a gate part rides the boss pool of a
  /// **pure** zone only (ENEMIES §2e.1), and the Celestial Totem is supplied
  /// by The Kiln Desert, The Mirrormere and Starfall Basin. A hybrid has
  /// never carried one. ⭐ Both bosses share this table, so which of the two
  /// a run draws never changes what the run is worth.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('solar_crystal', min: 1, max: 2),
      DropEntry('lunar_crystal', min: 1, max: 2),
      DropEntry('solar_shard', min: 1, max: 2),
      DropEntry('lunar_shard', min: 1, max: 2),
      DropEntry('solar_dust', min: 4, max: 8),
      DropEntry('lunar_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('ebony_log', weight: 35, min: 4, max: 8),
      DropEntry('duskcap', weight: 20, min: 3, max: 6),
      DropEntry('eclipse_opal', weight: 15, min: 2, max: 4),
      DropEntry('crestline_ring', weight: 20),
      DropEntry('the_dividing_line', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    eclipseHerald,
    crestlineWarden,
    nightglare,
    coldlightSwarm,
    shadowpitchStalker,
  ];

  static const minis = <EnemyDef>[
    solarArchon,
    theCrest,
    bothSidedThing,
    duskmarch,
  ];

  static const bosses = <EnemyDef>[theLastLight, theFirstDark];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
