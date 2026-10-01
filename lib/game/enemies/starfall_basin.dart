/// The Starfall Basin bestiary — Lv 34–39, Astral (CELESTIAL_CONTRACT §4.3).
///
/// ⭐ **Theme: things fell here, and the sky is still aiming.** From the
/// arrival text — *"Bowl after bowl in the pale ground, each with something at
/// the bottom that is not from here. Nothing has grown over them because
/// nothing grows. At night the sky is so clear it looks like a threat."* The
/// second sentence is the whole zone: this is not a place where something
/// happened once.
///
/// ⭐ **A PURE zone** (ENEMIES §2e, CELESTIAL_CONTRACT §2.4): every creature
/// is Astral and only Astral. ⚠️ Unlike Frostfell Pass there is no
/// per-creature element assignment to read — the roster table gives `astral`
/// on all eleven rows, and a second element anywhere here would cost the
/// quarter one of its three pure regions.
///
/// ⭐ **`crater_revenant` is Bruiser → Adept, ruled** (ENEMIES §2e roster) —
/// the zone's anchor name, and *a person who came back*. It is deliberately
/// the honest fight in a zone where everything else arrived at terminal
/// velocity.
///
/// ⭐⭐ **The boss pool is NOT a mirror — it is the same thing at two scales**
/// (ENEMIES §2f). *What Landed* is small, clever and already at the bottom of
/// a crater; *The Next One* is enormous and still inbound. ⚠️ **Drawing the
/// small one is a warning about the big one.** Do not "fix" this into a
/// symmetry, and do not give them the same archetype: the Tyrant's
/// intelligence and the Juggernaut's mass are what make the two scales read
/// as two scales.
///
/// ⚠️ **Both bosses carry the key** (`astral_essence`, on `always`, never
/// weighted) — the roster's ruling, adopted by ETHEREAL_CONTRACT §3.5.3. It
/// is the Celestial Totem's Astral charge, so a player who beats this zone
/// can never be left unable to open Rimeholt because the wrong boss was
/// drawn.
///
/// ⚠️ **No off-element move.** ENEMIES §2e.2 names the **four** creatures in
/// the fifteen late zones that carry one, and none of them is here.
///
/// ⚠️ **Combat stats (CELESTIAL_CONTRACT §2.3) copy each archetype's row
/// verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own
/// default): §2.3 calls it "the yardstick," and a yardstick with a thumb on
/// the scale stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/starfall_basin_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`pilgrims_ration`
/// and `glasswort_draught` are cross-zone references**, defined in
/// `the_kiln_desert_items.dart` (CELESTIAL_CONTRACT §7.3) — a sibling
/// builder's file in a parallel worktree. They resolve once the merge
/// coordinator lands the quarter together; until then the zone test names
/// them as a closed exemption list rather than skipping the check.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'starfall_basin';

/// ⭐ Pure zone: one element, on every creature (§2.4's audit — the three
/// Celestial elements each keep exactly one pure region).
const _astral = [MagicElement.astral];

/// ⭐ A pure zone pays a **single** mote currency at the full 0.75 roll, where
/// a hybrid splits the same payout across two families at 0.5 each (§4.3's
/// drop table, the shipped Frostfell shape read the other way round).
const _commonAlways = [DropEntry('astral_dust', chance: 0.75, min: 1, max: 2)];

abstract final class StarfallBasinBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster — the honest fight, the yardstick the rest
  /// of the basin is felt against.
  ///
  /// ⚠️ **Its `hide` role has no hide to pay in.** Starfall Basin defines no
  /// hide item — nothing here has skin — so per ETHEREAL_CONTRACT §3.5.1 the
  /// role resolves to the zone's **second gatherable material**, `fallstone`,
  /// at the weight a hide would have carried. ⭐ It reads correctly too: what
  /// a revenant is carrying is what it was buried with.
  static const craterRevenant = EnemyDef(
    id: 'crater_revenant',
    name: 'Crater Revenant',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _astral,
    lore:
        'A person, recognisably, standing in the bottom of a bowl they did '
        'not walk into. They fight the way someone trained fights — '
        'economically, without flourish, and without any apparent interest '
        'in stopping.',
    moves: [
      Spell(
        id: 'sb_getupagain',
        name: 'Get Up Again',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sb_rememberthelanding',
        name: 'Remember the Landing',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield. ⚠️ And the
      // shield is what it learned here — it is bracing for the next one.
      Spell(
        id: 'sb_braceforthenext',
        name: 'Brace for the Next',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('fallstone', weight: 69),
        DropEntry('astral_shard', weight: 5, min: 1, max: 2),
        DropEntry('astral_dust', weight: 11, min: 2, max: 3),
      ],
    ),
  );

  /// ⭐ One of the seven Sentinels ENEMIES §2b kept, and the easiest of them
  /// to justify: **it is literally iron.** The zone's shield tutor, and the
  /// only common with a drop row of its own (§4.3) — it is the one thing here
  /// made of both materials at once.
  static const skyIronHusk = EnemyDef(
    id: 'sky_iron_husk',
    name: 'Sky-Iron Husk',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _astral,
    lore:
        'A hollow shell of pitted dark metal standing upright in the shape '
        'of whatever it was wrapped around on the way down. The inside is '
        'empty and has been for a long time. The outside is still cooling.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'sb_ringlikeiron',
        name: 'Ring Like Iron',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band): a Sentinel that
      // could raise its wall cheaply would never have to choose.
      Spell(
        id: 'sb_setthecrust',
        name: 'Set the Crust',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('skyiron_ore', weight: 55, min: 1, max: 2),
        DropEntry('fallstone', weight: 20),
        DropEntry('glasswort_draught', weight: 10),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay **small because the archetype
  /// multiplies them** — a Glasswing authored at the table's face value would
  /// land nearly double what §1.4 budgets for it. §1.4's own row prices the
  /// Glasswing's dear move at roughly −35% of the single-target band.
  static const fallpoint = EnemyDef(
    id: 'fallpoint',
    name: 'Fallpoint',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _astral,
    lore:
        'The last instant of something\'s descent, still happening, held at '
        'the spot where it met the ground. Looking directly at it is like '
        'looking at a sound. It is thin, it is bright, and it is not slowing '
        'down.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'sb_comedownfast',
        name: 'Come Down Fast',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'sb_arrive',
        name: 'Arrive',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 15),
        DropEntry('fallstone', weight: 69),
        DropEntry('astral_shard', weight: 5, min: 1, max: 2),
        DropEntry('astral_dust', weight: 11, min: 2, max: 3),
      ],
    ),
  );

  /// ⭐ Both moves multi-hit — the Lasher's whole lesson is *why a big shield
  /// is not always the answer*, and a shield spends itself against the first
  /// hit of four. ⚠️ Its §2.3 row is the only **negative** crit damage in the
  /// game: it crits often and each crit is worth less, which is chip damage
  /// stated as a stat block.
  static const scatterling = EnemyDef(
    id: 'scatterling',
    name: 'Scatterling',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _astral,
    lore:
        'One arrival that did not stay one thing, now a loose spread of '
        'fragments keeping rough company at about waist height. No piece of '
        'it is dangerous. All of it at once is a different question.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'sb_scatterwide',
        name: 'Scatter Wide',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'sb_comedowninpieces',
        name: 'Come Down in Pieces',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('skyiron_ore', weight: 74, min: 1, max: 3),
        DropEntry('astral_shard', weight: 5),
        DropEntry('astral_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Priority, which is the Skirmisher's whole teaching — and the roster's
  /// note says why it earns it: *it was already moving.* Ejecta does not
  /// decide to attack; it was thrown before the player arrived.
  static const coldEjecta = EnemyDef(
    id: 'cold_ejecta',
    name: 'Cold Ejecta',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _astral,
    lore:
        'Debris thrown clear of a crater that has long since stopped being '
        'hot, still travelling on the push it was given. It has never once '
        'changed direction and it has never once come to rest.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      // ⭐ Priority 5, the shipped "quick" rung (Old Quarry's Chiselback) —
      // ahead of a player's attack, behind a genuine Quickened strike.
      Spell(
        id: 'sb_landfirst',
        name: 'Land First',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sb_keepgoing',
        name: 'Keep Going',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('skyiron_ore', weight: 74, min: 1, max: 3),
        DropEntry('astral_shard', weight: 5),
        DropEntry('astral_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const theZodiacAscendant = EnemyDef(
    id: 'the_zodiac_ascendant',
    name: 'The Zodiac Ascendant',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _astral,
    lore:
        'A wheel of twelve figures turning slowly on edge above the basin '
        'floor, each one a constellation drawn in hard white points. '
        'Whichever figure is at the top is the one that comes down, and the '
        'wheel is always turning.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'sb_taketheascendant',
        name: 'Take the Ascendant',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sb_bringthewholewheel',
        name: 'Bring the Whole Wheel',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'sb_turnthecircle',
        name: 'Turn the Circle',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, and §1.3's **one** sanctioned lifesteal move
  /// outside the Siphon archetype — the precedent is Frostfell's Hoarking.
  /// ⚠️ A constellation that takes your light back is the fiction; the
  /// mechanic is the archetype's, not the zone's, and nothing else here
  /// lifesteals.
  static const constellationWarden = EnemyDef(
    id: 'constellation_warden',
    name: 'Constellation Warden',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _astral,
    lore:
        'A figure outlined in fixed points of light, standing between the '
        'craters in a posture that has not altered in living memory. It is '
        'not guarding any one bowl. It is keeping the pattern of them.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'sb_pressthepattern',
        name: 'Press the Pattern',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'sb_holdtheformation',
        name: 'Hold the Formation',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'sb_takebackthelight',
        name: 'Take Back the Light',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap lowered from 5 to 4** (§1.3, unchanged from the Kinetic
  /// ruling): a mini five-charge raw at this band lands close to a whole
  /// player bar. At cost 4 it lands the ratio the archetype is supposed to
  /// have. Bring a shield.
  static const riftWalker = EnemyDef(
    id: 'rift_walker',
    name: 'Rift Walker',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _astral,
    lore:
        'Something tall that treats the distance between two places as a '
        'formality. It is at the far rim of the bowl, and then it is not, '
        'and nothing covered the ground in between.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'sb_openthegap',
        name: 'Open the Gap',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'sb_crossinonestep',
        name: 'Cross in One Step',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority, not status**: it always connects,
  /// and its middle move lands ahead of everything on the board. 📝 The engine
  /// has no creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve — priority 1, and one move that goes
  /// through a wall.
  static const echoOfTheBetween = EnemyDef(
    id: 'echo_of_the_between',
    name: 'Echo of the Between',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _astral,
    lore:
        'The repetition of something that has not happened here yet, arriving '
        'out of the empty distance the craters were aimed across. It is '
        'quieter than the thing it is repeating, and it is earlier.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'sb_answerfirst',
        name: 'Answer First',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before
      // anything. An echo that arrives before its own sound is the zone's
      // one genuinely Quickened strike.
      Spell(
        id: 'sb_arrivebeforethesound',
        name: 'Arrive Before the Sound',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sb_reachthroughit',
        name: 'Reach Through It',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// ☄️ **The large scale — enormous, and still inbound.** ⭐⭐ The Juggernaut
  /// half of a pool that is *the same thing at two scales* (ENEMIES §2f):
  /// this is what [whatLanded] was, before it arrived. Its kit is the
  /// archetype's own honesty — it pays for its size by being completely
  /// telegraphed, and the player watches the charge bar fill for `Land`.
  static const theNextOne = EnemyDef(
    id: 'the_next_one',
    name: 'The Next One',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _astral,
    lore:
        'A mass overhead large enough to have an underside, lit along one '
        'edge and growing at a rate that can be measured against the horizon '
        'without instruments. Everything on the ground here is a record of '
        'the last one.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'sb_closethedistance',
        name: 'Close the Distance',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      // ⭐ The wall is ablative rather than defensive in fiction — what is
      // burning is its own outside — but mechanically it is a Juggernaut's
      // required wall (§2.5: an attrition archetype without one is only a
      // bigger HP number).
      Spell(
        id: 'sb_burnthroughtheair',
        name: 'Burn Through the Air',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'sb_land',
        name: 'Land',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🕳️ **The small scale — and already at the bottom of a crater.** ⭐⭐ The
  /// Tyrant half: not a mass but an intelligence, compact, arrived, and
  /// patient. ⚠️ Its §2.3 row is the widest stat block in the game — a little
  /// of everything — which is what *"the intelligence is the threat"* reads
  /// as when written as numbers.
  static const whatLanded = EnemyDef(
    id: 'what_landed',
    name: 'What Landed',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _astral,
    lore:
        'Something the size of a curled person at the centre of the deepest '
        'bowl, unmarked by the journey and oriented, very precisely, towards '
        'whoever has just come over the rim. It has been waiting the way a '
        'thing waits when waiting costs it nothing.',
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
        id: 'sb_settle',
        name: 'Settle',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sb_pullitdown',
        name: 'Pull It Down',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'sb_finishtheapproach',
        name: 'Finish the Approach',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ One guaranteed Shard, a handful of Dust, and a **15% chance** (a
  /// quarter until the 2026-09-30 lean) at
  /// the zone's first Crystal — the mote ladder's first real step, and it is
  /// a fight the player chose (ITEMS §8). ⚠️ `zodiac_pendant` is the rare
  /// chase and sits at weight 5 of 100: rare enough to be a chase, common
  /// enough that four different minis can eventually hand it over.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('astral_shard'),
      DropEntry('astral_dust', min: 1, max: 3),
      DropEntry('astral_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('skyiron_ore', weight: 40, min: 2, max: 4),
      DropEntry('fallstone', weight: 30, min: 2, max: 4),
      DropEntry('pilgrims_ration', weight: 25),
      DropEntry('zodiac_pendant', weight: 5),
    ],
  );

  /// ⚠️ **`astral_essence` is guaranteed, on BOTH bosses, and never
  /// weighted** (§3.4 and ETHEREAL_CONTRACT §3.5.3). It is the Celestial
  /// Totem's Astral charge and therefore the Rimeholt gate: putting it in
  /// `main` would mean a player could clear the zone's boss and still be
  /// locked out of the next town by a dice roll. ⭐ Both bosses carry it
  /// because the adventure draws **one** of the two.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('astral_essence'),
      DropEntry('astral_crystal', min: 1, max: 2),
      DropEntry('astral_shard', min: 1, max: 2),
      DropEntry('astral_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('skyiron_ore', weight: 45, min: 4, max: 8),
      DropEntry('fallstone', weight: 25, min: 3, max: 6),
      DropEntry('zodiac_pendant', weight: 20),
      DropEntry('the_aimed_sky', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    craterRevenant,
    skyIronHusk,
    fallpoint,
    scatterling,
    coldEjecta,
  ];

  static const minis = <EnemyDef>[
    theZodiacAscendant,
    constellationWarden,
    riftWalker,
    echoOfTheBetween,
  ];

  static const bosses = <EnemyDef>[theNextOne, whatLanded];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
