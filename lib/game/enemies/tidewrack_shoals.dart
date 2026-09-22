/// The Tidewrack Shoals bestiary — Lv 36–40, Lunar + Aqua (CELESTIAL_CONTRACT
/// §4.4, ENEMIES §2e).
///
/// ⭐ **Theme: the sea is on a schedule it did not choose, and it keeps
/// uncovering things.** From the arrival text — *"the water goes out further
/// than seems survivable and comes back faster. What it uncovers has been
/// down there a long time. Everything is timed to something overhead."* The
/// fusion is **obedience**: Aqua doing what Lunar says.
///
/// ⚠️ **Element is assigned per creature, not "both" by default** — ENEMIES
/// §2e's roster table names each one. Read the table before touching an
/// element list; three creatures here are the only ones that carry both.
///
/// ⭐⭐ **The boss pool is the hybrid's two elements, one each** (ENEMIES §2h's
/// hybrid rule): the **Kraken** is Aqua — *what the tide uncovers*, a mass
/// from the deep — and **The Undertow** is Lunar — *what it takes back*.
/// ⚠️ **The Undertow is LUNAR, and that is the whole point.** ENEMIES §2h
/// states it twice: *"Tidewrack's Kraken is Aqua and its Undertow is Lunar,
/// because the undertow is not the water — it is the pull."* 📝
/// CELESTIAL_CONTRACT §2.4's row calls it Aqua; that row was written against
/// `ae9743c`, before the roster was finalised, and only its **stat block** is
/// taken from it (defl 30/30, dodge 4). Do not "reconcile" the element back.
///
/// ⚠️ **No `key` on either boss.** Tidewrack is a hybrid; the Celestial
/// Totem's three essences come from the three PURE Celestial zones (ENEMIES
/// §2e.1, CELESTIAL_CONTRACT §4.4) — *"NO essence — hybrid."*
///
/// ⭐ **`lowwater_thing` is Blighter, not Siphon** (ENEMIES §2e's roster,
/// final 2026-09-22): *"Siphon cut — the zone's idea is a schedule, not an
/// appetite (§2f)."* 📝 CELESTIAL_CONTRACT §1.2/§2.3 added a Siphon row
/// expecting this creature to use it; the roster is the later document and
/// the drop row it still calls "the Siphon" is joined by ROLE, not by
/// archetype (ETHEREAL_CONTRACT §3.5).
///
/// ⚠️ **Combat stats copy each archetype's §2.3 row verbatim**, reaching the
/// duel through `EnemyDef.combatStats` / `OpponentDriver.opponentCombatStats`
/// — never through gear. The Adept is deliberately blank
/// (`EnemyCombatStats.none`): §2.3 calls it *"the yardstick,"* and a
/// yardstick with a thumb on the scale stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression; `test/tidewrack_shoals_test
/// .dart` resolves every id against [ItemCatalogue] instead. ⚠️ **`aqua_*`
/// are a Q1 cross-quarter reference** (`glimmerbrook_items.dart`) and are
/// already on main; **`lunar_*`** come from `the_mirrormere` and
/// **`pilgrims_ration` / `glasswort_draught`** from `the_kiln_desert`, both
/// being authored in parallel worktrees — they resolve once the merge
/// coordinator lands the wave.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'tidewrack_shoals';

/// ⚠️ Lunar first, matching `World.byId('tidewrack_shoals').elements`.
const _both = [MagicElement.lunar, MagicElement.aqua];
const _lunar = [MagicElement.lunar];
const _aqua = [MagicElement.aqua];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so a
/// hybrid kill hands over about as much mote as a pure one but in two
/// ledgers (§4.4's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('lunar_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('aqua_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class TidewrackShoalsBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster — the yardstick the rest of the shoals is
  /// felt against. ⚠️ **Was a Drudge** (§2f): *"a Drudge at level 38 was a
  /// wasted encounter slot; the drowned still fight the way they fought,
  /// which is worse."* So the kit is a drill — advance, press, close ranks.
  static const tidewrackDrowned = EnemyDef(
    id: 'tidewrack_drowned',
    name: 'Tidewrack Drowned',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'They come up the flats at a walking pace, spaced evenly, keeping a '
        'line nobody has dressed for them in a very long time. Whatever they '
        'were drilled to do, they are still doing it, and they are still '
        'good at it.',
    moves: [
      Spell(
        id: 'tw_wadein',
        name: 'Wade In',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'tw_pressforward',
        name: 'Press Forward',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'tw_closeranks',
        name: 'Close Ranks',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: _hideCommonDrops,
  );

  /// ⭐ The zone's shield tutor — a shell is §2b's own worked example, and
  /// this is one of the seven Sentinels the pass kept. Pure Aqua: it is the
  /// thing that shuts and waits the six hours out.
  static const wrackcrab = EnemyDef(
    id: 'wrackcrab',
    name: 'Wrackcrab',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _aqua,
    lore:
        'Broad as a cartwheel and almost flat, carrying a shell crusted over '
        'with the same weed the flats are named for. It does not retreat to '
        'water when the tide goes; it simply shuts, and waits for the water '
        'to come back to it.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'tw_shear',
        name: 'Shear',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band) — and the whole
      // lesson: you have to get through the shell, not out-wait it.
      Spell(
        id: 'tw_closetheshell',
        name: 'Close the Shell',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: _materialCommonDrops,
  );

  /// ⭐ What the tide leaves standing in the warm shallow. Both moves
  /// multi-hit (§1.3's per-archetype rule) — a Blighter wins by out-lasting
  /// rather than out-hitting, and standing water does its work an inch at a
  /// time.
  static const lowwaterThing = EnemyDef(
    id: 'lowwater_thing',
    name: 'Lowwater Thing',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _aqua,
    lore:
        'A shallow spreading body of water that stayed behind when the rest '
        'of the sea left, warm enough to be unpleasant and deep enough to be '
        'a problem. It has an edge, and the edge moves.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'tw_seepin',
        name: 'Seep In',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'tw_settleover',
        name: 'Settle Over',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    // ⚠️ §4.4's "the Siphon" row, joined by ROLE — this creature is the one
    // the contract meant, whatever archetype the roster settled on.
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('nacre', weight: 45),
        DropEntry('glasswort_draught', weight: 15),
      ],
    ),
  );

  /// ⭐ **Lunar, not Aqua** — the flock is *timed to something overhead*,
  /// which is the whole theme stated in one creature. Damage in pieces, the
  /// Lasher's lesson: one bite occasionally stings.
  static const gullboneFlock = EnemyDef(
    id: 'gullbone_flock',
    name: 'Gullbone Flock',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _lunar,
    lore:
        'Two dozen long-winged birds working the same stretch of flat, all '
        'turning together on nothing anyone on the ground can see. They are '
        'never out over the water early and never out over it late.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'tw_harry',
        name: 'Harry',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'tw_stoop',
        name: 'Stoop',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _hideCommonDrops,
  );

  /// ⭐ §2b: *darts, skims, flits → Skirmisher.* Spray off a wave top
  /// literally skims, so the archetype was read off the creature rather than
  /// assigned to it. ⚠️ **Was a Glasswing**, and the change is the honest
  /// one — spindrift is fast, not fragile-and-lethal.
  static const spindrift = EnemyDef(
    id: 'spindrift',
    name: 'Spindrift',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _aqua,
    lore:
        'A person-sized sheet of spray torn off a wave top that keeps going '
        'after the wave has finished, travelling flat and fast a hand above '
        'the sand. It is only ever there for as long as the gust is.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      // ⭐ Priority 5 — the Skirmisher's tempo lean is quick, and quick means
      // a cheap move that lands ahead of the board.
      Spell(
        id: 'tw_skim',
        name: 'Skim',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'tw_breakover',
        name: 'Break Over',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: _materialCommonDrops,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each mini archetype, so the two drawn per run are always a
  // different pair of tactical roles (ENEMIES §2g).

  /// ⭐ The only mini carrying both elements — the obedience stated as a
  /// person: she does not make the water do anything, she tells it when.
  static const tidalEmpress = EnemyDef(
    id: 'tidal_empress',
    name: 'Tidal Empress',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'A tall crowned figure standing out on the flats with the water '
        'gathered behind her at a height it has no business holding. She '
        'does not appear to be making it do that. She appears to be waiting '
        'with it.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'tw_callitin',
        name: 'Call It In',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'tw_bringthehigh',
        name: 'Bring the High',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'tw_raisethewater',
        name: 'Raise the Water',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, pure Aqua — a mass you cannot get through
  /// that takes what it stops. ⚠️ Its finisher is the zone's **only**
  /// lifesteal (§1.3's one-per-Redoubt allowance); nothing else here heals
  /// off you.
  static const leviathan = EnemyDef(
    id: 'leviathan',
    name: 'Leviathan',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _aqua,
    lore:
        'A back the length of a jetty breaking the shallow water and not '
        'finishing — there is more of it behind, and more again. It was '
        'never meant to be seen from above, and at low water there is '
        'nowhere else to see it from.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'tw_shoulderthrough',
        name: 'Shoulder Through',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'tw_rollover',
        name: 'Roll Over',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'tw_swallowwhole',
        name: 'Swallow Whole',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ Cost cap lowered from 5 to 4 (§1.3) — at this band a mini
  /// five-charge raw would be a one-shot with change. Bring a shield.
  static const maelstromHorror = EnemyDef(
    id: 'maelstrom_horror',
    name: 'Maelstrom Horror',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _aqua,
    lore:
        'A turning column of water standing in the channel between two bars, '
        'wide enough at the top to take a boat and narrow enough at the '
        'bottom to be a throat. Things that go into it do not come back down '
        'the channel.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'tw_spinunder',
        name: 'Spin Under',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'tw_pullapart',
        name: 'Pull Apart',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The moment the tide changes — a Hexer's clock, stated as fiction.
  /// Its signature is **priority**, not status: the cheap move lands ahead of
  /// everything, and the dear one goes through a wall. 📝 The engine has no
  /// creature-applied debuff yet, so the archetype is written with the levers
  /// that actually resolve.
  static const theTurning = EnemyDef(
    id: 'the_turning',
    name: 'The Turning',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _lunar,
    lore:
        'Not water and not weather — the instant itself, standing still on '
        'the flat while everything around it reverses. Anyone caught out '
        'past the bars learns to feel it coming and still does not leave in '
        'time.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'tw_runout',
        name: 'Run Out',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before
      // anything. It is the clock; it does not queue.
      Spell(
        id: 'tw_turnwithoutwarning',
        name: 'Turn Without Warning',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'tw_takethehour',
        name: 'Take the Hour',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🐙 **What the tide uncovers** — a mass from the deep, and Aqua's half of
  /// the pool. ⭐ GAME_DESIGN §5 named the Kraken as Aqua's boss and ENEMIES
  /// §2c moved it here from Glimmerbrook: *"a Kraken in a brook a level-5
  /// character can walk to is absurd, and it spends a great name on a fight
  /// nobody remembers."*
  static const kraken = EnemyDef(
    id: 'kraken',
    name: 'Kraken',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _aqua,
    lore:
        'Uncovered rather than arrived — the low water simply stops being '
        'deep enough to hide it, and then there is a great deal of it lying '
        'across the flats between you and anywhere. It has been down there '
        'the entire time.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'tw_haul',
        name: 'Haul',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'tw_coil',
        name: 'Coil',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'tw_dragdown',
        name: 'Drag Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🌑 **The Aspect — what it takes back**, and Lunar's half of the pool.
  /// ⚠️ **Single-element by rule** (ENEMIES §2.5), and ⭐⭐ **the element is
  /// Lunar**: *the undertow is not the water, it is the pull — and the pull
  /// is the moon.* Lunar taken to an extreme is the moon deciding when you
  /// may act.
  ///
  /// 📝 Its stat block is CELESTIAL_CONTRACT §2.4's row verbatim — defl 30/30
  /// (EV 9.0%), dodge 4 — deliberately the same shape as Frostfell's *The
  /// Road Under*, one tier up. ⚠️ That row also labels the creature Aqua;
  /// see the library note. Stats from the contract, element from the roster.
  static const theUndertow = EnemyDef(
    id: 'the_undertow',
    name: 'The Undertow',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _lunar,
    lore:
        'There is nothing to look at. The water around your knees is going '
        'out the way it has gone out every day since before the shoals had a '
        'name, and it is taking the sand from under you while it goes, and '
        'it will not be hurried and cannot be argued with.',
    combatStats: EnemyCombatStats(
      deflectChance: 30,
      deflectAmount: 30,
      dodge: 4,
    ),
    moves: [
      // ⭐ The one quick move: the water leaves first, and it leaves early.
      Spell(
        id: 'tw_drawback',
        name: 'Draw Back',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'tw_undermine',
        name: 'Undermine',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'tw_takeitback',
        name: 'Take It Back',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ §4.4's **hide common** row, carried by the two commons the roster
  /// marks `hide` — the Drowned and the Flock. `drownling_hide` is the
  /// zone's kill-only material (§3.1), so this table is the only way to it.
  static const _hideCommonDrops = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 30),
      DropEntry('drownling_hide', weight: 40),
      DropEntry('aqua_shard', weight: 8, min: 1, max: 2),
      DropEntry('aqua_dust', weight: 17, min: 2, max: 3),
      DropEntry('pilgrims_ration', weight: 5),
    ],
  );

  /// ⭐ §4.4's **material-A common** row, carried by the Wrackcrab and the
  /// Spindrift. 📝 The roster lists Spindrift's drops as `mote` only; the
  /// contract's role table asks for **two** material-A commons and the zone
  /// has exactly one other common left, so Spindrift fills it. The join is
  /// by zone + role (§0.4), and the role count is the contract's side of it.
  static const _materialCommonDrops = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 25),
      DropEntry('wrackcotton', weight: 55, min: 1, max: 3),
      DropEntry('lunar_shard', weight: 7),
      DropEntry('lunar_dust', weight: 13, min: 1, max: 2),
    ],
    bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.4) — a Crystal from either
  /// family, the ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('lunar_shard'),
      DropEntry('aqua_shard'),
      DropEntry('lunar_dust', min: 2, max: 4),
      DropEntry('aqua_dust', min: 2, max: 4),
      DropEntry('lunar_crystal', chance: 0.25),
      DropEntry('aqua_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('drownling_hide', weight: 35, min: 2, max: 4),
      DropEntry('wrackcotton', weight: 30, min: 2, max: 4),
      DropEntry('nacre', weight: 30, min: 1, max: 2),
      DropEntry('the_turning_tide', weight: 5),
    ],
  );

  /// ⚠️ **No essence, and no key.** The three gate parts are the three PURE
  /// Celestial zones' (§4.4, ENEMIES §2e.1) — the same rule NARRATIVE used
  /// for the Kinetic Sigil, and the reason those three are the ones that must
  /// be cleared. A hybrid never carried one.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('lunar_crystal', min: 1, max: 2),
      DropEntry('aqua_crystal', min: 1, max: 2),
      DropEntry('lunar_shard', min: 1, max: 2),
      DropEntry('aqua_shard', min: 1, max: 2),
      DropEntry('lunar_dust', min: 4, max: 8),
      DropEntry('aqua_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('drownling_hide', weight: 35, min: 4, max: 8),
      DropEntry('wrackcotton', weight: 25, min: 3, max: 6),
      DropEntry('nacre', weight: 15, min: 2, max: 4),
      DropEntry('the_turning_tide', weight: 15),
      DropEntry('lowwater_tread', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    tidewrackDrowned,
    wrackcrab,
    lowwaterThing,
    gullboneFlock,
    spindrift,
  ];

  static const minis = <EnemyDef>[
    tidalEmpress,
    leviathan,
    maelstromHorror,
    theTurning,
  ];

  static const bosses = <EnemyDef>[kraken, theUndertow];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
