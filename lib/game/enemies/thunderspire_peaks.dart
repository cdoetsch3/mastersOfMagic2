/// The Thunderspire Peaks bestiary — Lv 23–28, Electro + Aero hybrid
/// (KINETIC_CONTRACT §4.5).
///
/// ⭐ **Theme: you are inside the storm, and it is building to something.**
/// From the arrival text — *"the cloud is lit from within at intervals, and
/// the intervals are getting shorter."* The fusion is a storm as a **single
/// accelerating event** rather than weather.
///
/// ⚠️ **Deliberately distinct from Stormcliff Coast** — that zone is one
/// strike's warning, this one is a **countdown**. §4.2's warning holds both
/// ways: a builder of either zone should read both sections before touching
/// either roster. Stormcliff is *where* the lightning goes; Thunderspire is
/// *when* it comes.
///
/// ⭐ **`the_shortening` is the Hexer, and the assignment is load-bearing**
/// (ENEMIES §2g): the zone's premise is intervals getting shorter, and a
/// stacking status IS that premise. 📝 The engine has no creature-applied
/// stacking debuff yet (the same note every Kinetic Hexer carries), so the
/// acceleration is written into priority and move naming instead — each move
/// resolves faster than the last, closing the gap the way the zone's own
/// lightning does.
///
/// ⭐ **The boss pair:** *The Strike That Lands* is the arrival (Aspect —
/// Electro taken to an extreme); *The Storm That Passes* is the one that does
/// not (a mass that simply keeps going — Juggernaut).
///
/// ⚠️ **`stormcrest_roc` and `thunder_roc` are two rocs in one zone** —
/// deliberately kept: different sizes (common vs mini) *and* different
/// elements (Aero vs Electro). ✅ **RULED (§8.8): Thunder Roc keeps its
/// GAME_DESIGN §5 Electro assignment** — matching Stormcrest's Aero would
/// have made them read as one species at two sizes; Electro was always the
/// fix, not the risk.
///
/// ✅ **`ionwake` is Skirmisher → Adept, ruled (§8.4).** A cheap swap — the
/// zone's premise (a countdown) does not lean on it either way. Its stats are
/// deliberately blank, the yardstick every other archetype here is felt
/// against (§2.3).
///
/// ⚠️ **Combat stats (KINETIC_CONTRACT §2.2/§2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. ⚠️ **The Aspect
/// is the one exception**: The Strike That Lands is single-element (Electro)
/// and carries the zone-specific block §2.4 names — crit 30 / critDmg +50,
/// acc +10 — not the generic Aspect row (§2.3 leaves that row "per zone").
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression.
/// `test/thunderspire_peaks_test.dart` resolves every id against
/// [ItemCatalogue]. ⭐ **Hybrids define no motes** (§3.2) — every
/// `electro_*`/`aero_*` id here resolves against `stormcliff_coast_items.dart`
/// and `windward_steppe_items.dart` respectively.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'thunderspire_peaks';
const _electro = [MagicElement.electro];
const _aero = [MagicElement.aero];
const _both = [MagicElement.electro, MagicElement.aero];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each (§3.2), so
/// a kill's total mote yield stays comparable to a pure zone's while filling
/// two colours of drawer.
const _commonAlways = [
  DropEntry('electro_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('aero_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class ThunderspirePeaksBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor` — the roc
  /// that rides the up-draft ahead of the weather itself.
  static const stormcrestRoc = EnemyDef(
    id: 'stormcrest_roc',
    name: 'Stormcrest Roc',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _aero,
    lore:
        'A roc the size of a cart, wings storm-grey and ragged at the tips, '
        'riding the up-draft off the ridge without a single wingbeat wasted. '
        'It reads the cloud the way a sailor reads water and is always '
        'somewhere above the next flash before it happens.',
    moves: [
      Spell(
        id: 'tp_wingbeat',
        name: 'Wingbeat',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'tp_fulldive',
        name: 'Full Dive',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: -8, critChance: 8, critDamage: 25),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('rowan_log', weight: 55, min: 1, max: 3),
        DropEntry('electro_shard', weight: 7),
        DropEntry('electro_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('hardtack', chance: 0.02)],
    ),
  );

  /// ⭐ A standing vein of ore that hums audibly with trapped charge — the
  /// arrival text's *"metal hums"* in one creature, and a Sentinel armoured
  /// by carrying the charge rather than shedding it.
  static const hummingOre = EnemyDef(
    id: 'humming_ore',
    name: 'Humming Ore',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _electro,
    lore:
        'An outcrop of rust-veined rock that should be silent and is not — a '
        'low, steady hum runs through it that you feel in the teeth before '
        'you hear it. It does not move to defend itself. It has never needed '
        'to.',
    moves: [
      Spell(
        id: 'tp_resonate',
        name: 'Resonate',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'tp_lockthecharge',
        name: 'Lock the Charge',
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
        DropEntry('hum_quartz', weight: 40),
        DropEntry('electro_shard', weight: 8, min: 1, max: 2),
        DropEntry('electro_dust', weight: 17, min: 2, max: 3),
        DropEntry('hardtack', weight: 5),
      ],
    ),
  );

  /// ⚠️ Multi-hit only, both moves (§1.3's per-archetype rule) — small
  /// filaments that flick between rocks in a rapid, uneven stutter, counting
  /// the storm's own rhythm out ahead of it.
  static const flashcount = EnemyDef(
    id: 'flashcount',
    name: 'Flashcount',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _electro,
    lore:
        'A loose cluster of finger-length white filaments that arc between '
        'the rocks in a rapid, uneven stutter, never resting on one point '
        'twice in a row. It is not aiming. It is counting.',
    moves: [
      Spell(
        id: 'tp_quickcount',
        name: 'Quick Count',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'tp_racingcount',
        name: 'Racing Count',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    // ⭐ Negative crit damage on purpose (§2.3): the sting that occasionally
    // lands is weaker than an ordinary crit, not stronger.
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('iron_ore', weight: 50, min: 1, max: 2),
        DropEntry('electro_shard', weight: 5),
        DropEntry('electro_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the archetype
  /// multiplies them**.
  static const updraftWisp = EnemyDef(
    id: 'updraft_wisp',
    name: 'Updraft Wisp',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _aero,
    lore:
        'A hand-span knot of pale down and static, riding a thermal with no '
        'weight to speak of. It rides the same rising air the cloud does, '
        'and it goes wherever the air decides, which is occasionally through '
        'you.',
    moves: [
      Spell(
        id: 'tp_catchthedraft',
        name: 'Catch the Draft',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'tp_burstupdraft',
        name: 'Burst Updraft',
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
        DropEntry('rowan_log', weight: 45),
        DropEntry('aero_shard', weight: 7),
        DropEntry('aero_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ **`ionwake` is Skirmisher → Adept, ruled (§8.4)** — a cheap swap. The
  /// honest fight, and the yardstick every other archetype here is felt
  /// against (§2.3, deliberately blank).
  static const ionwake = EnemyDef(
    id: 'ionwake',
    name: 'Ionwake',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A compact, upright shape of charged wind and standing light, no '
        'taller than a person, moving with an even, deliberate gait against '
        'gusts that would stagger anything less certain of its footing. It '
        'trails a thin visible wake of disturbed air.',
    moves: [
      Spell(
        id: 'tp_trail',
        name: 'Trail',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'tp_closethegap',
        name: 'Close the Gap',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ Priority 3 — the Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'tp_holdtheline',
        name: 'Hold the Line',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('iron_ore', weight: 45),
        DropEntry('hum_quartz', weight: 15),
      ],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const crownFire = EnemyDef(
    id: 'crown_fire',
    name: 'Crown Fire',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _electro,
    lore:
        'A crackling halo of white-blue light that has settled on the '
        'highest point of a ridge and stayed, bright enough to read a map '
        'by, competent at everything a storm can do. It does not build to '
        'anything — it is simply always ready.',
    moves: [
      Spell(
        id: 'tp_arcover',
        name: 'Arc Over',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'tp_coronalstrike',
        name: 'Coronal Strike',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'tp_ringthecrown',
        name: 'Ring the Crown',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as a landmark rather than a creature — a rock formation
  /// shaped like an anvil that every strike in the range seems to find, and
  /// simply absorbs.
  static const anvilhead = EnemyDef(
    id: 'anvilhead',
    name: 'Anvilhead',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _both,
    lore:
        'A squat mass of storm-scarred stone shaped, almost too neatly, like '
        'an anvil — every strike the peak has taken for a hundred years '
        'seems to have found it and it has never once cracked. Wind piles up '
        'against it and goes nowhere.',
    moves: [
      Spell(
        id: 'tp_hammersquall',
        name: 'Hammer Squall',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'tp_setheanvil',
        name: 'Set the Anvil',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'tp_drawthestormdown',
        name: 'Draw the Storm Down',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    drops: _miniDrops,
  );

  /// ✅ **RULED (§8.8): Thunder Roc keeps its GAME_DESIGN §5 Electro
  /// assignment.** Matching Stormcrest Roc's Aero is what would have made the
  /// pair read as one species at two sizes; Electro was always the fix.
  static const thunderRoc = EnemyDef(
    id: 'thunder_roc',
    name: 'Thunder Roc',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _electro,
    lore:
        'A leaner, faster roc than the ridge-riders below, feathers dark and '
        'faintly branching with trapped white light down every barb. It '
        'circles once, high, and then there is no interval left at all '
        'before it stoops.',
    moves: [
      Spell(
        id: 'tp_stoop',
        name: 'Stoop',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⚠️ The Executioner's cost cap is lowered from 5 to 4 this quarter
      // (§1.3) — bring a shield.
      Spell(
        id: 'tp_fullstoop',
        name: 'Full Stoop',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 8, critChance: 12, critDamage: 40),
    drops: _miniDrops,
  );

  /// ⭐ **The zone's premise as a creature.** *"The intervals are getting
  /// shorter"* — the Hexer's signature priority tempo IS the countdown here,
  /// not merely borrowed from the archetype: each move resolves faster than
  /// the last, closing the gap on the board the way the storm closes it
  /// overhead. 📝 No creature-applied stacking debuff exists in the engine
  /// yet (the note every Kinetic Hexer carries), so the acceleration is
  /// written into priority and naming rather than a mechanical stack.
  static const theShortening = EnemyDef(
    id: 'the_shortening',
    name: 'The Shortening',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _electro,
    lore:
        'Not a body — an interval. A gap between flashes that keeps counting '
        'itself down, marked by a low floating knot of white sparks that '
        'brightens a fraction more each time the cloud lights. There is '
        'always less of it left than there was.',
    moves: [
      Spell(
        id: 'tp_countthegap',
        name: 'Count the Gap',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'tp_closing',
        name: 'Closing',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'tp_nogapleft',
        name: 'No Gap Left',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// 👑 **The Juggernaut — the constant, and what does not stop.** ⭐ A mass
  /// that simply keeps going, the counterweight to the Aspect's single
  /// arrival: while the Strike That Lands is the countdown reaching zero,
  /// this is the weather that was never going to stop for it.
  static const theStormThatPasses = EnemyDef(
    id: 'the_storm_that_passes',
    name: 'The Storm That Passes',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _both,
    lore:
        'A vast standing front of cloud and charged wind, three storeys of '
        'it, moving through the peaks at a slow, indifferent walking pace '
        'that nothing here has ever managed to turn aside. It was moving '
        'before you arrived and it will still be moving after.',
    moves: [
      Spell(
        id: 'tp_holdstill',
        name: 'Hold Still',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'tp_keepcoming',
        name: 'Keep Coming',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
      Spell(
        id: 'tp_passthrough',
        name: 'Pass Through',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    drops: _bossDrops,
  );

  /// ⚡ **The Aspect — Electro taken to an extreme, and the arrival the
  /// countdown was always counting toward.** ⭐ Every move leans on the same
  /// thing its stat block does (§2.4/§2.5): crit 30 / critDmg +50, acc +10 —
  /// the zone's single strongest crit block, because this IS the strike
  /// landing, not a warning of one.
  static const theStrikeThatLands = EnemyDef(
    id: 'the_strike_that_lands',
    name: 'The Strike That Lands',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _electro,
    lore:
        'Not yet a shape — a brightening. The cloud overhead has stopped '
        'flickering and started to hold its light a little longer each '
        'time, building toward a single column that has not come down yet. '
        'When it does, there will be nothing left to count.',
    moves: [
      Spell(
        id: 'tp_firstwarning',
        name: 'First Warning',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'tp_closer',
        name: 'Closer',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'tp_thestrikelands',
        name: 'The Strike Lands',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    // ⚠️ §2.4's zone-specific block, not the generic Aspect row (§2.3 leaves
    // the Aspect row "per zone" on purpose).
    combatStats: EnemyCombatStats(
      accuracyBonus: 10,
      critChance: 30,
      critDamage: 50,
    ),
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ A hybrid mini guarantees ONE Shard per ladder (half a chance apiece)
  /// where a pure zone's mini guarantees one outright — the split still pays
  /// one Shard on average, exactly the way it splits its Crystal chance.
  ///
  /// 📝 The Countstone Pendant's authored dropper is not singled out — the
  /// pool shares one table across all four minis, per the Whispering Woods
  /// shape.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('electro_shard'),
      DropEntry('aero_shard'),
      DropEntry('electro_dust', min: 2, max: 4),
      DropEntry('aero_dust', min: 2, max: 4),
      DropEntry('electro_crystal', chance: 0.25),
      DropEntry('aero_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('iron_ore', weight: 40, min: 2, max: 4),
      DropEntry('rowan_log', weight: 30, min: 2, max: 4),
      DropEntry('hum_quartz', weight: 25, min: 1, max: 2),
      DropEntry('countstone_pendant', weight: 5),
    ],
  );

  /// ⚠️ No essence — the Sigil's collect-three-keys mechanism is rejected
  /// (§3.3/§8.6). Nothing here is a gate item.
  ///
  /// ✅ **RULED (§8.7): Thunderspire gets an epic.** `groundfault_grips`
  /// drops off this pool alongside the other boss-table rewards; the doubled
  /// Crystal payout above is the standard hybrid shape, not a consolation for
  /// lacking one.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('electro_crystal', min: 1, max: 2),
      DropEntry('aero_crystal', min: 1, max: 2),
      DropEntry('electro_shard', min: 1, max: 2),
      DropEntry('aero_shard', min: 1, max: 2),
      DropEntry('electro_dust', min: 4, max: 8),
      DropEntry('aero_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('iron_ore', weight: 35, min: 4, max: 8),
      DropEntry('rowan_log', weight: 25, min: 3, max: 6),
      DropEntry('hum_quartz', weight: 15, min: 2, max: 4),
      DropEntry('countstone_pendant', weight: 15),
      DropEntry('groundfault_grips', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    stormcrestRoc,
    hummingOre,
    flashcount,
    updraftWisp,
    ionwake,
  ];

  static const minis = <EnemyDef>[
    crownFire,
    anvilhead,
    thunderRoc,
    theShortening,
  ];

  static const bosses = <EnemyDef>[theStormThatPasses, theStrikeThatLands];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
