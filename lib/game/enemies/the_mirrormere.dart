/// The Mirrormere bestiary — Lv 32–37, Lunar (CELESTIAL_CONTRACT §4.2).
///
/// ⭐ **Theme: the reflection is bigger than the thing, and it is looking
/// back.** From the arrival text — *"the moon at a size the moon has no right
/// to be… you are careful not to look down for too long."* ⭐ **Which one is
/// real is the fight** (ENEMIES §2e).
///
/// ⭐ **A PURE zone** (§2.4): one element, every creature. Along with The Kiln
/// Desert and Starfall Basin this is one of the quarter's three pure regions,
/// so Lunar keeps exactly one region of its own — and that is why the
/// `lunar_*` mote family is **defined here** (§3.2, `the_mirrormere_items.dart`)
/// rather than imported.
///
/// ⚠️ **Undershine is a Glasswing, not a Siphon.** ENEMIES §2e's roster was
/// re-balanced on 2026-09-22 and cut the Siphon from this zone — *"nothing in
/// this zone drinks, it only reflects"* (§2f). CELESTIAL_CONTRACT §1.2 still
/// names Undershine as the quarter's Siphon; the roster is the later document
/// and wins on archetype. ⭐ The contract's drop row labelled *"the Siphon"*
/// still belongs to Undershine — the join is by **creature**, not by
/// archetype name — so its table is the one §4.2 authored for it.
///
/// ⚠️ **Nothing here lifesteals**, including the Redoubt's usual §1.3
/// exception. The zone's one-line premise is that it reflects rather than
/// drinks, and a lifesteal move would be the Siphon arriving by the back door.
///
/// ⚠️ **Both bosses carry the `key`** — `lunar_essence`, on the shared
/// `always` line and never weighted (ENEMIES §2e.1). A run draws one boss of
/// two, so a gate part on only one of them would make the Celestial Totem a
/// coin flip.
///
/// ⚠️ **Combat stats (CELESTIAL_CONTRACT §2.2/§2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`): §2.3 calls it "the
/// yardstick," and a yardstick with a thumb on the scale stops being one.
/// ⭐ Luna Plena's block is §2.4's row verbatim — **dodge at the ENEMIES §2.5
/// cap of 10**, and this is the one place the doc says the cap should be
/// spent: *"the moon in the water is not where the moon is."*
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_mirrormere_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`pilgrims_ration`
/// and `glasswort_draught` are cross-zone references**, defined in
/// `the_kiln_desert_items.dart`, a sibling Celestial builder's file — they
/// resolve once the merge coordinator lands the parallel worktrees together
/// (CELESTIAL_CONTRACT §7.3 lists them as this zone's only non-local ids).
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_mirrormere';
const _lunar = [MagicElement.lunar];

/// ⭐ A pure zone pays ONE mote ladder at the full 0.75 roll (§4.2's drop
/// table) — the hybrid half-chance shape does not apply here.
const _commonAlways = [DropEntry('lunar_dust', chance: 0.75, min: 1, max: 2)];

/// ⭐ §4.2's *material-A* row, paid by the two commons whose roster role is
/// the zone's wood. Weights sum to 100, so the percentages read straight off
/// the numbers.
const _materialAMain = [
  DropEntry.nothing(weight: 12),
  DropEntry('bloodwood_log', weight: 74, min: 1, max: 3),
  DropEntry('lunar_shard', weight: 5),
  DropEntry('lunar_dust', weight: 9, min: 1, max: 2),
];

/// ⭐ §4.2's *material-B* row. ⚠️ **This is where the `hide` role lands.**
/// The Mirrormere defines no kill-only hide, so per ETHEREAL_CONTRACT §3.5.1
/// the role resolves to the zone's **second gatherable material** —
/// `mirrorflax` — at the weight a hide would have carried.
const _materialBMain = [
  DropEntry.nothing(weight: 15),
  DropEntry('mirrorflax', weight: 72, min: 1, max: 2),
  DropEntry('lunar_shard', weight: 5, min: 1, max: 2),
  DropEntry('lunar_dust', weight: 8, min: 2, max: 3),
];

abstract final class MirrormereBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// zone's **Adept** — the yardstick. ⭐ It is also the theme stated first:
  /// the honest fight here is your own shape, which is the zone saying what
  /// it is before anything else gets a turn.
  static const mirrorWraith = EnemyDef(
    id: 'mirror_wraith',
    name: 'Mirror Wraith',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _lunar,
    lore:
        'A standing figure of lake-light with your own build and your own '
        'way of holding still, close enough that people stop walking to '
        'check. It never copies badly, and it never copies late.',
    moves: [
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'mm_mirrorthestep',
        name: 'Mirror the Step',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'mm_matchtheblow',
        name: 'Match the Blow',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      Spell(
        id: 'mm_takethesamestance',
        name: 'Take the Same Stance',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(always: _commonAlways, main: _materialBMain),
  );

  /// ⭐ **It does not hit you; it holds you, and what it holds it keeps.**
  /// The Blighter is the archetype that teaches what statuses actually do,
  /// and both its moves are multi-hit (§1.3's per-archetype rule) — a
  /// Blighter wins by out-lasting rather than out-hitting. 📝 The engine has
  /// no creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve.
  static const stillface = EnemyDef(
    id: 'stillface',
    name: 'Stillface',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _lunar,
    lore:
        'A flat oval of unbroken water held upright at head height, showing '
        'whoever is nearest at perfect rest however hard they are moving. '
        'Nobody has reported one letting go of a reflection afterwards.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'mm_holdyourgaze',
        name: 'Hold Your Gaze',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'mm_keepwhatitholds',
        name: 'Keep What It Holds',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(always: _commonAlways, main: _materialAMain),
  );

  /// ⭐ Light moving under the surface: brilliant, and one hit from gone.
  /// ⚠️ 0.50 HP and 1.70 damage — the raws stay **small because the
  /// archetype multiplies them**, and the dear move takes §1.4's Glasswing
  /// −35%: the common cost-3 row of 18–23 lands at 12–15.
  static const undershine = EnemyDef(
    id: 'undershine',
    name: 'Undershine',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _lunar,
    lore:
        'A moving brightness a hand\'s depth under the water, person-long '
        'and thinner than a person, travelling without disturbing the '
        'surface it travels beneath. It goes out all at once or not at all.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'mm_catchthelight',
        name: 'Catch the Light',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'mm_breakthesurface',
        name: 'Break the Surface',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 15),
      ),
    ],
    // ⚠️ §4.2's third common row, authored for this creature under its
    // pre-rebalance archetype name. `glasswort_draught` is a Kiln Desert id.
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 20),
        DropEntry('mirrorflax', weight: 65),
        DropEntry('glasswort_draught', weight: 15),
      ],
    ),
  );

  /// ⭐ Priority — it crosses the surface before you have finished looking at
  /// it. Both moves are quick (priority 5) and cheap, which is the whole
  /// archetype: it acts before you and you must plan around that.
  static const ripplecut = EnemyDef(
    id: 'ripplecut',
    name: 'Ripplecut',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _lunar,
    lore:
        'A single travelling line on an otherwise flat lake, arm-long, that '
        'reaches the far shore faster than the water it is crossing could '
        'carry it. The ripple arrives after the thing has already gone.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'mm_crossthesurface',
        name: 'Cross the Surface',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'mm_cutthereflection',
        name: 'Cut the Reflection',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: _materialAMain,
      // ⚠️ §4.2 hangs the ration off the material-A rows at 2%.
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Shields chip rather than shatter — the Lasher's lesson, and a shoal
  /// is the fiction that writes itself: damage arrives in pieces because the
  /// creature IS pieces. ⚠️ Crit chance up, crit damage down (§2.3): lots of
  /// small bites, one occasionally stinging.
  static const palefishShoal = EnemyDef(
    id: 'palefish_shoal',
    name: 'Palefish Shoal',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _lunar,
    lore:
        'Several hundred colourless fish the length of a finger, holding one '
        'loose shoal-shape about the size of a person just under the '
        'surface. They all turn at once, and the turn is what you feel.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'mm_turnalltogether',
        name: 'Turn All Together',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'mm_takeitinpieces',
        name: 'Take It in Pieces',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(always: _commonAlways, main: _materialBMain),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g). ⭐ The four are the moon's four
  // phases, which is the zone's premise told as a set rather than a creature.

  /// ⭐ The Champion — an Adept that is simply better at everything, and the
  /// theme at mini scale: the reflection has stopped being a reflection.
  static const theSecondYou = EnemyDef(
    id: 'the_second_you',
    name: 'The Second You',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _lunar,
    lore:
        'Your own shape walked up out of the shallows at your own height, '
        'dripping and entirely opaque, carrying what you are carrying. It '
        'has stopped waiting for you to move first.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'mm_doasyoudo',
        name: 'Do As You Do',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'mm_answerinkind',
        name: 'Answer in Kind',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'mm_guardthesameside',
        name: 'Guard the Same Side',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as accumulation — a wall that is bigger every night. ⚠️
  /// No lifesteal, unlike the shipped Redoubts: §1.3's "one lifesteal move"
  /// licence is declined here because this zone reflects and does not drink
  /// (ENEMIES §2f).
  static const heraldOfTheWaxing = EnemyDef(
    id: 'herald_of_the_waxing',
    name: 'Herald of the Waxing',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _lunar,
    lore:
        'A broad kneeling figure of pale stone at the waterline, one side '
        'of it finished and the other still rough, and the finished side is '
        'further round every time anyone comes back to look.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'mm_growbyanight',
        name: 'Grow by a Night',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'mm_fillthecircle',
        name: 'Fill the Circle',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'mm_waxwider',
        name: 'Wax Wider',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap 4, not 5** (§1.3's standing lowering) — a mini's cost-5
  /// raw would be a one-shot with change rather than a three-turn threat.
  /// ⭐ The execute rider is the new-moon fiction stated mechanically: it
  /// finishes what is already nearly dark.
  static const stalkerOfTheNewMoon = EnemyDef(
    id: 'stalker_of_the_new_moon',
    name: 'Stalker of the New Moon',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _lunar,
    lore:
        'A tall thin absence the shape of a walking person, visible only as '
        'the stars it is standing in front of going out in order. On the '
        'water it leaves no reflection at all, which is how it is found.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'mm_comeunseen',
        name: 'Come Unseen',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'mm_finishinthedark',
        name: 'Finish in the Dark',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 25),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects,
  /// and its cheap move lands ahead of everything on the board. 📝 The engine
  /// has no creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve — getting there first, and going through.
  static const theWaningWraith = EnemyDef(
    id: 'the_waning_wraith',
    name: 'The Waning Wraith',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _lunar,
    lore:
        'A person-shaped figure of thin silver light missing a clean curved '
        'bite from one side, and the bite is larger each time the eye comes '
        'back to it. Nobody has watched one long enough to see it end.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'mm_takeasliver',
        name: 'Take a Sliver',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'mm_alreadyless',
        name: 'Already Less',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'mm_wanetonothing',
        name: 'Wane to Nothing',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🌑 **The moon in the water — and it is looking back.** ⭐⭐ The pool is
  /// NOT a mirror in the §2f sense even though the zone is about mirrors: it
  /// is the reflection and the thing, and the roster's ruling is that **the
  /// reflection is the one with a mind.** ENEMIES §2g gives Tyrant to *"a
  /// person, a will, something that decided"* — this decided to look up.
  ///
  /// ⭐ Three attacks, one at each cost rung, and no wall. A Tyrant's threat
  /// is its intelligence-9 play, and `_affordable()` is the lever that lets
  /// it express one: it always has something to throw, so it never has to
  /// telegraph a charge it did not choose.
  static const theMoonBelow = EnemyDef(
    id: 'the_moon_below',
    name: 'The Moon Below',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _lunar,
    lore:
        'The moon\'s reflection, filling most of the lake, at a size nothing '
        'overhead accounts for. It holds still while the water moves, and '
        'it is oriented toward the shore rather than toward the sky.',
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
        id: 'mm_lookback',
        name: 'Look Back',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'mm_risetomeetyou',
        name: 'Rise to Meet You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'mm_pullyouunder',
        name: 'Pull You Under',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🌕 **The Aspect — the moon above, and Lunar taken to an extreme.**
  /// ⚠️ Single-element by rule (ENEMIES §2.5). ⭐ Lunar is **misdirection**:
  /// the moon in the water is not where the moon is, so §2.4 spends the
  /// ENEMIES §2.5 dodge cap here and nowhere else in the quarter.
  ///
  /// 💡 Banked (ENEMIES §2e): the roster wants this fightable only on a Full
  /// Moon turn. 📝 No calendar mechanic exists yet, so it draws from the boss
  /// pool like any other — the condition is fiction until TYPE_EFFECTS rules
  /// a Lunar phase clock.
  static const lunaPlena = EnemyDef(
    id: 'luna_plena_the_full_moon',
    name: 'Luna Plena, the Full Moon',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _lunar,
    lore:
        'The full moon at the size the water has been showing it, arrived '
        'above the lake instead of in it, close enough that the shore has '
        'two of every shadow. Looking straight at it is the mistake.',
    // ⚠️ §2.4's row, verbatim: dodge 10, defl 20/20 (EV 4.0%), acc 0.
    combatStats: EnemyCombatStats(
      dodge: 10,
      deflectChance: 20,
      deflectAmount: 20,
    ),
    moves: [
      Spell(
        id: 'mm_standwhereyouarenot',
        name: 'Stand Where You Are Not',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'mm_fillthewholesurface',
        name: 'Fill the Whole Surface',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'mm_showthewholeface',
        name: 'Show the Whole Face',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ Crystal is where the mote ladder is first FELT, so it hangs off a
  /// fight the player chose (§4.2).
  static const _miniDrops = DropTable(
    always: [
      DropEntry('lunar_shard'),
      DropEntry('lunar_dust', min: 1, max: 3),
      DropEntry('lunar_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('bloodwood_log', weight: 40, min: 2, max: 4),
      DropEntry('mirrorflax', weight: 30, min: 2, max: 4),
      DropEntry('pilgrims_ration', weight: 25),
      DropEntry('the_waning_charm', weight: 5),
    ],
  );

  /// ⭐ **`lunar_essence` is guaranteed, on BOTH bosses** (§3.4, ENEMIES
  /// §2e.1) — it is one of the three the Celestial Totem is crafted from at
  /// Meridian, and the gate must not turn on which boss the run drew.
  /// ⚠️ Never weighted, never on `main`: a `main` table draws exactly one
  /// entry, which would put the gate part in competition with a log.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('lunar_essence'),
      DropEntry('lunar_crystal', min: 1, max: 2),
      DropEntry('lunar_shard', min: 1, max: 2),
      DropEntry('lunar_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('bloodwood_log', weight: 45, min: 4, max: 8),
      DropEntry('mirrorflax', weight: 25, min: 3, max: 6),
      DropEntry('the_waning_charm', weight: 20),
      DropEntry('the_larger_reflection', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    mirrorWraith,
    stillface,
    undershine,
    ripplecut,
    palefishShoal,
  ];

  static const minis = <EnemyDef>[
    theSecondYou,
    heraldOfTheWaxing,
    stalkerOfTheNewMoon,
    theWaningWraith,
  ];

  static const bosses = <EnemyDef>[theMoonBelow, lunaPlena];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
