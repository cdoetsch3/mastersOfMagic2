/// The Windward Steppe bestiary — Lv 19–24, Aero (KINETIC_CONTRACT §4.3).
///
/// ⭐ **Theme: one direction, forever — everything here has stopped
/// resisting.** ✅ *"The wind does not gust; it simply blows, and has been
/// blowing since before there was anyone to notice."* Not violence.
/// **Relentlessness**, which no other Aero zone claims.
///
/// ⚠️ **This zone deliberately has no Adept** (§8.4's thematic-absence
/// ruling) — a roster this uniformly wind-worn does not need a fast or
/// fragile yardstick creature to feel complete. And it ships **two real
/// bosses**; the "empty arena" idea some earlier design pass floated for
/// this zone is dead, not deferred (§8.3) — do not add a third encounter.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/windward_steppe_test.dart`
/// resolves every id against [ItemCatalogue] instead (except `hardtack`,
/// which is Old Quarry's — see that test file's note).
///
/// ⭐ **Combat stats are authored per KINETIC_CONTRACT §2.3** — every def
/// below copies its archetype's row from that table exactly, unmodified for
/// this zone. Aero leans dodge: the Skirmisher (Steppe Harrier, dodge 8) and
/// the Hexer (Wind Wraith, dodge 10) are two of the only two creatures in the
/// entire Kinetic quarter allowed near the dodge cap of 10 (§2.3's warning).
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'windward_steppe';
const _aero = [MagicElement.aero];

/// Motes and bulk fall from everything; the main table is what varies.
const _commonAlways = [DropEntry('aero_dust', chance: 0.75, min: 1, max: 2)];

abstract final class WindwardSteppeBestiary {
  // ---- commons --------------------------------------------------------

  /// ✅ The zone's anchor name, kept from `World.opponentNameFor`. A
  /// Skirmisher is the honest first read of this steppe: fast, low, gone
  /// before you can answer it.
  static const steppeHarrier = EnemyDef(
    id: 'steppe_harrier',
    name: 'Steppe Harrier',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _aero,
    lore:
        'Wings held stiff and angled, it does not flap so much as let the '
        'wind carry it low over the grass, correcting by inches. It strikes '
        'from the same glide it was already holding.',
    moves: [
      Spell(
        id: 'ws_wingover',
        name: 'Wingover',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ws_stoop',
        name: 'Stoop',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('tussock_flax', weight: 45),
        DropEntry('aero_shard', weight: 7),
        DropEntry('aero_dust', weight: 13, min: 1, max: 2),
      ],
    ),
    // Skirmisher (KINETIC_CONTRACT §2.3): dodge 8 — one of only two
    // creatures in the quarter allowed this close to the cap of 10.
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
  );

  /// ⭐ The zone's shield tutor, same role Slagshell Tortoise plays in
  /// Cinderpeak — a standing stone worn to a permanent lean, planted, and
  /// entirely willing to wait you out.
  static const leanstone = EnemyDef(
    id: 'leanstone',
    name: 'Leanstone',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _aero,
    lore:
        'A standing stone worn to a permanent lean, the windward face '
        'smoothed to nothing and the leeward face still sharp. It has not '
        'moved in longer than anyone has been counting, and it is not going '
        'to start for you.',
    moves: [
      Spell(
        id: 'ws_lean_in',
        name: 'Lean In',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'ws_root_down',
        name: 'Root Down',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('yew_log', weight: 40),
        DropEntry('aero_shard', weight: 8, min: 1, max: 2),
        DropEntry('aero_dust', weight: 17, min: 2, max: 3),
        DropEntry('hardtack', weight: 5),
      ],
    ),
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
  );

  /// ⭐ A moving mass of blown husk and stalk rather than one animal — the
  /// Lasher's "lots of small bites" read as a swarm the wind is dragging
  /// sideways across the grass.
  static const chaff = EnemyDef(
    id: 'chaff',
    name: 'Chaff',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _aero,
    lore:
        'Threshed stalk and seed husk, blown into a moving mass that holds '
        'its shape only because the wind keeps refilling it from behind. It '
        'stings in passing and is already somewhere else.',
    moves: [
      Spell(
        id: 'ws_scatter',
        name: 'Scatter',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ws_windrow',
        name: 'Windrow',
        chargeCost: 3,
        priority: 7,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('tussock_flax', weight: 50, min: 1, max: 2),
        DropEntry('aero_shard', weight: 5),
        DropEntry('aero_dust', weight: 10, min: 1, max: 2),
      ],
    ),
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
  );

  /// ⭐ **The zone's thesis in one creature.** §4.3: a Drudge this close to
  /// the edge of "wasted encounter slot" survives here because a husk that
  /// barely fights **is** *"everything has stopped resisting."*
  static const tumblehusk = EnemyDef(
    id: 'tumblehusk',
    name: 'Tumblehusk',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.drudge,
    elements: _aero,
    lore:
        'A hollow dried-out husk of something that used to root, rolling '
        'end over end because it stopped holding on. It only ever hits you '
        'by having been in the way.',
    moves: [
      // ⭐ −20% raw (§1.3's per-archetype table) — the incompetence is in
      // the number too.
      Spell(
        id: 'ws_bump',
        name: 'Bump',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(4, 7),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('tussock_flax', weight: 45),
        DropEntry('hardtack', weight: 15),
      ],
    ),
    combatStats: EnemyCombatStats(accuracyBonus: -10),
  );

  /// ⚠️ 0.50 HP and 1.70 damage, same trap as every Glasswing — the raws
  /// stay small because the archetype multiplies them.
  static const kitewing = EnemyDef(
    id: 'kitewing',
    name: 'Kitewing',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _aero,
    lore:
        'A membrane of wing stretched over hollow bone, kite-shaped and '
        'paper-thin, held up entirely by the wind it flies in. It looks one '
        'gust from tearing, which is also how it kills you.',
    moves: [
      Spell(
        id: 'ws_flit',
        name: 'Flit',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'ws_last_gust',
        name: 'Last Gust',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('yew_log', weight: 55, min: 1, max: 3),
        DropEntry('aero_shard', weight: 7),
        DropEntry('aero_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ The one thing on the steppe that does not give way — the Champion is
  /// a clean skill check, and here that reads as the exception to the
  /// zone's whole thesis: a lean grown old enough to have become a stance.
  static const oldLean = EnemyDef(
    id: 'old_lean',
    name: 'Old Lean',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _aero,
    lore:
        'The oldest lean on the steppe, grown into something like a '
        'person-shape out of wind-scoured rock and root. Everything else '
        'here gave way a long time ago. This did not.',
    moves: [
      Spell(
        id: 'ws_shoulder_it',
        name: 'Shoulder It',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ws_full_lean',
        name: 'Full Lean',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'ws_brace',
        name: 'Brace',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
  );

  /// ✅✅ Re-homed anchor name — a towering column of compressed wind, roughly
  /// human-shaped, that rebuilds itself as fast as it is worn down.
  static const skyTitan = EnemyDef(
    id: 'sky_titan',
    name: 'Sky Titan',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _aero,
    lore:
        'A standing column of wind compressed hard enough to hold a shape, '
        'roughly a person twice over. Take a piece off it and the wind '
        'behind simply fills the gap.',
    moves: [
      Spell(
        id: 'ws_gust_slap',
        name: 'Gust Slap',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'ws_stand_fast',
        name: 'Stand Fast',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 38),
      ),
      // ⭐ Redoubt's lifesteal move (§1.3's "one attack, one shield, one
      // lifesteal") — it draws the fight's own force back into itself.
      Spell(
        id: 'ws_draw_breath',
        name: 'Draw Breath',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(9, 12, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
  );

  /// ✅✅ Re-homed anchor name. ⚠️ **The Executioner's cost cap is lowered
  /// from 5 to 4 this quarter** (KINETIC_CONTRACT §1.3) — its second move
  /// uses the mini cost-4 raw (26–34) rather than the archetype's usual
  /// cost-5 finisher, so a level-24 Gale Serpent lands two casts rather than
  /// one, matching the ratio Q1's Hollow Stag holds at level 5.
  static const galeSerpent = EnemyDef(
    id: 'gale_serpent',
    name: 'Gale Serpent',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _aero,
    lore:
        'A rope of visibly moving air, coiled tight before it strikes and '
        'sinuous the rest of the time. It has no body to speak of, only the '
        'shape the wind is currently making.',
    moves: [
      Spell(
        id: 'ws_coil',
        name: 'Coil',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'ws_uncoil',
        name: 'Uncoil',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
  );

  /// ✅✅ Re-homed anchor name. ⭐ Hexer (KINETIC_CONTRACT §2.3): dodge 10 —
  /// the other of the quarter's two creatures allowed this close to the cap.
  /// 📝 Same note as every Hexer in the quarter — the engine has no
  /// creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve.
  static const windWraith = EnemyDef(
    id: 'wind_wraith',
    name: 'Wind Wraith',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _aero,
    lore:
        'A shape the wind makes and unmakes without ever quite finishing '
        'it, always at the edge of where you are looking. It has never once '
        'been seen arriving.',
    moves: [
      Spell(
        id: 'ws_whisper',
        name: 'Whisper',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ws_keening',
        name: 'Keening',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(3, 4, hits: 4),
      ),
      Spell(
        id: 'ws_through_the_seam',
        name: 'Through the Seam',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(14, 18, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
  );

  // ---- bosses ---------------------------------------------------------

  /// ⛰️ **The endurance boss — the constant.** ✅ §4.3: the two-boss pair is
  /// the premise's two sides; this is the force that has not stopped since
  /// before there was anyone to notice.
  static const theUnbrokenBlow = EnemyDef(
    id: 'the_unbroken_blow',
    name: 'The Unbroken Blow',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _aero,
    lore:
        'Not a shape so much as a direction, huge and featureless and '
        'entirely without hurry. It has been blowing across this exact '
        'stretch of ground longer than the ground has been ground, and it '
        'shows no sign of having noticed you.',
    moves: [
      Spell(
        id: 'ws_the_blow',
        name: 'The Blow',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
      Spell(
        id: 'ws_hold_the_line',
        name: 'Hold the Line',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'ws_steady_press',
        name: 'Steady Press',
        chargeCost: 4,
        priority: 5,
        effect: DamageEffect(11, 14, hits: 2),
      ),
    ],
    drops: _bossDrops,
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
  );

  /// 👑 **The Tyrant — the gust, the exception.** ⭐ §4.3: where The Unbroken
  /// Blow is the constant, this is the one gust among endless wind that
  /// decided to be something. The threat is not the statline; it is that it
  /// plays well.
  static const tempestMonarch = EnemyDef(
    id: 'tempest_monarch',
    name: 'Tempest Monarch',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _aero,
    lore:
        'Regal only in that it holds a shape at all — a single decided gust '
        'standing apart from the wind that made it, watching, in no hurry to '
        'spend what it is clearly saving.',
    moves: [
      Spell(
        id: 'ws_bide',
        name: 'Bide',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(12, 16),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      Spell(
        id: 'ws_choose_the_gust',
        name: 'Choose the Gust',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 30),
      ),
      Spell(
        id: 'ws_the_gust_itself',
        name: 'The Gust Itself',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 52),
      ),
    ],
    drops: _bossDrops,
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
  );

  // ---- shared tables --------------------------------------------------

  static const _miniDrops = DropTable(
    always: [
      DropEntry('aero_shard'),
      DropEntry('aero_dust', min: 2, max: 4),
      DropEntry('aero_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('yew_log', weight: 40, min: 2, max: 4),
      DropEntry('tussock_flax', weight: 30, min: 2, max: 4),
      DropEntry('hardtack', weight: 25),
      DropEntry('leanstone_charm', weight: 5),
    ],
  );

  /// ⚠️ NO essence — the Sigil's collect-three-keys mechanism is rejected
  /// (§8.6); no Kinetic boss drops a gate item this quarter.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('aero_crystal', min: 1, max: 2),
      DropEntry('aero_shard', min: 1, max: 2),
      DropEntry('aero_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('yew_log', weight: 45, min: 4, max: 8),
      DropEntry('tussock_flax', weight: 25, min: 3, max: 6),
      DropEntry('leanstone_charm', weight: 20),
      DropEntry('the_long_lean', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    steppeHarrier,
    leanstone,
    chaff,
    tumblehusk,
    kitewing,
  ];

  static const minis = <EnemyDef>[oldLean, skyTitan, galeSerpent, windWraith];

  static const bosses = <EnemyDef>[theUnbrokenBlow, tempestMonarch];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
