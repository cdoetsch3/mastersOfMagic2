/// The Buried Sky bestiary — Lv 46–50, Geo + Astral hybrid
/// (ETHEREAL_CONTRACT §4.2, ENEMIES_DESIGN §2e).
///
/// ⭐ **Theme: the rock remembers a sky that no longer exists.** The Vault is
/// the highest rock in the world, so its exposed strata are the oldest
/// anywhere — and you climb to the top of everything in order to go **down**.
/// Each band you break through holds a scatter of light set in it, and none
/// of the patterns match what is overhead now.
///
/// ⭐ **Why the hybrid is a hybrid.** Geo supplies the **layers**, Astral
/// supplies the **heavens**, and the idea only exists when the two are read
/// together — §2d's bar for a fused premise. ⭐ Its claim is **SCALE**: *this
/// has all happened before, and the record is in the rock.* ⚠️ Deliberately
/// the opposite of The Glass Archive (43–47) — stone that keeps everything
/// against light that keeps nothing. Stated in both places so nobody "fixes"
/// the overlap later.
///
/// 📝 **Deferred structure.** The 🏰 marker in ENEMIES §2e and
/// `LocationKind.dungeon` in `world.dart` both stand, but this zone ships as
/// a **standard adventure**, exactly as The Molten Deep and The Shattered
/// Orrery did (KINETIC ruling 4). ⚠️ Nothing in this file may grow a floor
/// count.
///
/// ⭐⭐ **The boss pool is the premise's two sides** (§2d, now the rule for
/// every hybrid), and the elements carry it: **The Overburden** is Geo — *what
/// buries* — and **The Buried Constellation** is Astral — *what survives*.
/// ⚠️ Not a mirror: one is a weight and one is a pattern, and which you draw
/// says whether the zone was about burial or about persistence.
///
/// ⭐ **`deadreckoner` is the Adept** — the zone's yardstick and the honest
/// fight, run on out-of-date information. It therefore carries **no**
/// [EnemyCombatStats]: §2.3 leaves the Adept row deliberately blank, and a
/// yardstick with a thumb on the scale stops being one. ⚠️ The zone's anchor
/// name (`World.opponentNameFor`) is the **Stratum Warden**, not the Adept —
/// this is one of the zones where those two are different creatures.
///
/// ⚠️ **Element is assigned PER CREATURE, not "both" by default** (§2e's
/// roster table): four are pure Geo, three pure Astral, and only the
/// Deadreckoner and the Stonefall Herald carry both. Read the roster table
/// before touching an element list.
///
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

/// ✅ **No off-element creature.** §2e.2 once granted The Long Count a lunar
/// move on the reasoning "Astral is countered by Solar; Lunar is neither" —
/// but `element.dart`'s tier-3 wheel runs Solar → Lunar → Astral → Solar, so
/// `astral.counteredBy` IS lunar, and §2h's law (never a counter of the
/// zone's own elements) wins. The grant was withdrawn at merge (build
/// manager, 2026-09-22) and §2e.2 corrected; the zone test pins the wheel so
/// the reasoning cannot drift back.
const _zone = 'the_buried_sky';
const _geo = [MagicElement.geo];
const _astral = [MagicElement.astral];
const _both = [MagicElement.geo, MagicElement.astral];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.2's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('geo_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('astral_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class BuriedSkyBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name (`World.opponentNameFor`) and its clock: you get
  /// through it **one age at a time**, which is what the whole shaft is.
  /// ⚠️ Slow on purpose — the Sentinel's shield is its *expensive* move, so
  /// the wall is telegraphed and Barrage feels good against it (§2.5).
  ///
  /// ⚠️ Carries §4.2's **material-A** row: the ore is the band it is made of.
  static const stratumWarden = EnemyDef(
    id: 'stratum_warden',
    name: 'Stratum Warden',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _geo,
    lore:
        'Stone laid down in bands, each one a different colour and a '
        'different age, standing across the shaft in the order it was made. '
        'It does not move out of the way, and it does not come apart '
        'anywhere except at a seam.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'bs_laydownanotherband',
        name: 'Lay Down Another Band',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'bs_bedin',
        name: 'Bed In',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: _materialDrops,
  );

  /// ⭐ Both moves multi-hit — *"why a big shield is not always the answer"* is
  /// the Lasher's whole lesson (§2.5), and a scatter is what a figure looks
  /// like before anyone has finished counting it.
  ///
  /// ⚠️ **`Scatter` is the one place the kit sketch and §1.3 pull apart.** The
  /// sketch says `hits: 3` at cost 1; §1.3's cost-1 multi row is `3–5 ×2`. The
  /// shape is the sketch's and the amounts are the table's, which lands it at
  /// exactly 12 raw per charge — §1.3's ceiling, with no headroom. 📝 Drop to
  /// `hits: 2` if the ceiling is ever meant to be an open interval.
  static const constellate = EnemyDef(
    id: 'constellate',
    name: 'Constellate',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _astral,
    lore:
        'A scatter of star-points holding a loose shape about the size of a '
        'person, none of them still long enough to be counted twice. It '
        'arrives before you have finished counting it, and it arrives in '
        'pieces.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'bs_scatter',
        name: 'Scatter',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 3),
      ),
      Spell(
        id: 'bs_drawthefigure',
        name: 'Draw the Figure',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _materialDrops,
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the archetype
  /// multiplies them** (the shipped Glasswing shape). ⭐ *Killing fast beats
  /// playing safe* — it is already gone and it can still end you, and
  /// **Arrive Late** is the name doing the physics.
  static const fadelight = EnemyDef(
    id: 'fadelight',
    name: 'Fadelight',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _astral,
    lore:
        'The last light of a star that went out before any of this rock was '
        'laid down, still arriving and still exactly on time. There is '
        'nothing left of it to kill, and it can still end you.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'bs_flicker',
        name: 'Flicker',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'bs_arrivelate',
        name: 'Arrive Late',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: _hideDrops,
  );

  /// ⭐ The zone's charge-bar tutor. Nothing cheap in the kit, so it **must**
  /// charge and is therefore completely telegraphed (§2.5's tempo lean = cost
  /// band).
  ///
  /// ⚠️ **Siphon cut, Bruiser instead** (§2f): it eats rock, not you. The
  /// contract still labels this creature's drop table *"the Siphon"* — the
  /// archetype it carried before the re-band, exactly as The Shattered
  /// Orrery's contract names the Automaton's row *"the Sentinel"*. It is the
  /// only common that yields the garnet or a draught.
  static const corebiter = EnemyDef(
    id: 'corebiter',
    name: 'Corebiter',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _geo,
    lore:
        'A blunt, patient thing that goes through a seam the way water goes '
        'through a crack, only slower and with teeth. It has never been seen '
        'to hurry, and it has never been seen to stop.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'bs_borein',
        name: 'Bore In',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'bs_takethewholeseam',
        name: 'Take the Whole Seam',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('nadir_garnet', weight: 45),
        DropEntry('goldenrood_draught', weight: 15),
      ],
    ),
  );

  /// ⭐ The yardstick — the honest fight, run on out-of-date information. Its
  /// kit is the Adept's own: cheap hit, big hit, one shield. ⚠️ **No
  /// [EnemyCombatStats]** — §2.3 leaves the Adept row blank on purpose.
  ///
  /// ⚠️ The zone's **hide** creature (§2e.1): it is the one common here with a
  /// body worth taking something off, and `corebiter_hide` is what comes off
  /// anything that lives this far down.
  static const deadreckoner = EnemyDef(
    id: 'deadreckoner',
    name: 'Deadreckoner',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'It navigates by stars that no longer exist and is still mostly '
        'right, which is worse than being wrong. Every bearing it takes is '
        'honest, and every bearing it takes is out of date.',
    moves: [
      Spell(
        id: 'bs_sightit',
        name: 'Sight It',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'bs_holdthebearing',
        name: 'Hold the Bearing',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      Spell(
        id: 'bs_setthemark',
        name: 'Set the Mark',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: _hideDrops,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ A clean skill check: a cheap strike that beats an ordinary attack to
  /// the board, one wall, and one swing that takes the face away.
  static const stonefallHerald = EnemyDef(
    id: 'stonefall_herald',
    name: 'Stonefall Herald',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'It arrives a little before the rock does, every time, and has never '
        'once been early for anything else. By the time you have understood '
        'what it is announcing, the face is already coming away.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'bs_callitdown',
        name: 'Call It Down',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'bs_bringthefaceaway',
        name: 'Bring the Face Away',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
      Spell(
        id: 'bs_bracetheshaft',
        name: 'Brace the Shaft',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ Attrition, with nothing to go around. The Redoubt's heal is written
  /// with the lever the engine actually has — `lifesteal` on a damage move —
  /// rather than a heal effect creatures do not own.
  ///
  /// ⚠️ **Deflect is 25/24 (EV 6.0%), NOT §2.3's standard Redoubt 35/30.**
  /// The contract names this zone by name: a 2.20 HP body at 10.5% EV
  /// deflection inside a **dungeon**, where a player cannot retreat between
  /// sections, is the fight the balance probe will flag. 📝 Restore 35/30 the
  /// day the fatigue clock ships — nothing in `lib/` implements one today.
  ///
  /// ⚠️ **Cost-4 shield has no row in §1.3.** Mini shields are authored at c2
  /// (18–24) and c3 (30–40) only. 40–52 is §1.3's own boss c3 shield row,
  /// which sits between the mini c3 rung and the boss c4 rung (44–56) — the
  /// nearest authored number rather than an invented one.
  static const bedrockColossus = EnemyDef(
    id: 'bedrock_colossus',
    name: 'Bedrock Colossus',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _geo,
    lore:
        'The last layer, the one with nothing under it, standing up. There '
        'is no going around it, because there is nothing beside it to go '
        'around into.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 24),
    moves: [
      Spell(
        id: 'bs_settle',
        name: 'Settle',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'bs_taketheweight',
        name: 'Take the Weight',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'bs_closetheseam',
        name: 'Close the Seam',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33, lifesteal: 0.4),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐⭐ The Executioner's lesson written into the effect: below a third of
  /// the bar there is nothing left of the descent to finish.
  ///
  /// ⚠️ **The cost cap stays at 4** (§1.3, lowered by KINETIC and not raised
  /// back) even though the kit sketch says 5. At L50 a mini five-charge raw
  /// lands 460–600 against a 632 HP bar — a one-shot with change, not the
  /// two-cast kill the archetype is for.
  static const nadir = EnemyDef(
    id: 'nadir',
    name: 'Nadir',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _geo,
    lore:
        'The lowest point of the shaft, which is a place and is also looking '
        'at you. Everything in this zone has been falling toward it since '
        'the rock was laid down.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'bs_bottomout',
        name: 'Bottom Out',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'bs_finishthedescent',
        name: 'Finish the Descent',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 30),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority**, not status: it lands before your
  /// shield does, and its dear move goes through the wall anyway. 📝 The
  /// engine has no creature-applied debuff yet, so the archetype is written
  /// with the levers that resolve.
  ///
  /// ✅ Pure Astral: the lunar grant §2e.2 once made here was withdrawn — it
  /// was Astral's own counter (see the library note).
  static const theLongCount = EnemyDef(
    id: 'the_long_count',
    name: 'The Long Count',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _astral,
    lore:
        'A tally kept in a notation nobody now reads, still being added to, '
        'and the number is about you. It has been counting moons since long '
        'before there was anyone here to miss one.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'bs_marktheage',
        name: 'Mark the Age',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      // ⚠️ The off-element one.
      Spell(
        id: 'bs_countback',
        name: 'Count Back',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'bs_olderthanthesky',
        name: 'Older Than the Sky',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🪨 **What buries.** Geo, Juggernaut — endurance, and it does not need to
  /// be fast. *Overburden* is a real mining term for the rock sitting on top
  /// of a seam, and it happens to mean exactly the right thing.
  static const theOverburden = EnemyDef(
    id: 'the_overburden',
    name: 'The Overburden',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _geo,
    lore:
        'The whole weight of rock that sits on top of a seam, arrived at the '
        'bottom of the shaft and standing up in it. It is not fast, it has '
        'never needed to be, and nothing it settles onto comes back up.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'bs_pressdown',
        name: 'Press Down',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'bs_packtheroof',
        name: 'Pack the Roof',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'bs_bringthewholecolumn',
        name: 'Bring the Whole Column',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✴️ **What survives.** Astral, and the quarter's Astral **Aspect** (§2.4)
  /// — single-element by law, because an Aspect leans entirely on its own
  /// element's passive. Astral's lean is crit **chance**: a constellation in
  /// the rock is a pattern that was *already complete*, and a crit is the
  /// same statement.
  ///
  /// ⭐⭐ **Astral Alignment taken to an extreme: the whole kit walks through
  /// shields.** By the end of the fight the shield you are holding is not
  /// where the damage is going, which is further than the player has ever met
  /// this element.
  ///
  /// ⚠️ **`The Pattern Holds` has no §1.3 row** — the table authors no boss
  /// multi-hit at any cost. 10–13 ×3 totals 34.5 average, which is the boss
  /// c4 **single** row (30–38) split three ways, and lands at 8.6 raw per
  /// charge, well inside the shared ceiling.
  static const theBuriedConstellation = EnemyDef(
    id: 'the_buried_constellation',
    name: 'The Buried Constellation',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _astral,
    lore:
        'An old pattern of light still alight down here, entire, in an '
        'arrangement that matches nothing overhead. It refuses to be past '
        'tense, and where you put your guard is not where it lands.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      critChance: 25,
      critDamage: 45,
    ),
    moves: [
      Spell(
        id: 'bs_stillalight',
        name: 'Still Alight',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'bs_risewhereitshouldnot',
        name: 'Rise Where It Should Not',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19, ignoresShields: true),
      ),
      Spell(
        id: 'bs_thepatternholds',
        name: 'The Pattern Holds',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(10, 13, hits: 3, ignoresShields: true),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// §4.2's **material-A** row — the ore, and the Astral half of the mote
  /// ladder. ⚠️ `climbers_ration` rides `bonus` at 2%: everything on this
  /// mountain is carrying one.
  static const _materialDrops = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 25),
      DropEntry('deepstratum_ore', weight: 55, min: 1, max: 3),
      DropEntry('astral_shard', weight: 7),
      DropEntry('astral_dust', weight: 13, min: 1, max: 2),
    ],
    bonus: [DropEntry('climbers_ration', chance: 0.02)],
  );

  /// §4.2's **hide** row — the kill-only hide, and the Geo half of the mote
  /// ladder.
  ///
  /// ⚠️ **Which two commons carry it is a choice this lane made**, and it is
  /// worth saying so. §4.2 splits five common tables 2 / 2 / 1 but names only
  /// the Siphon's; ENEMIES §2e.1 gives `hide` to the **Deadreckoner** alone
  /// and `material` to the Stratum Warden and the Corebiter. Joining the two:
  /// the Deadreckoner must carry the hide, the Warden must carry a gatherable
  /// material, the Corebiter is the Siphon row — which leaves the Constellate
  /// and the Fadelight one seat each. 📝 They are interchangeable; the
  /// Fadelight sits here because the hide row pays the **Geo** motes and a
  /// light older than the rock belongs to the rock's half of the ladder.
  static const _hideDrops = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 30),
      DropEntry('corebiter_hide', weight: 40),
      DropEntry('geo_shard', weight: 8, min: 1, max: 2),
      DropEntry('geo_dust', weight: 17, min: 2, max: 3),
      DropEntry('climbers_ration', weight: 5),
    ],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.2) — Crystal from either
  /// family, the ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('geo_shard'),
      DropEntry('astral_shard'),
      DropEntry('geo_dust', min: 2, max: 4),
      DropEntry('astral_dust', min: 2, max: 4),
      DropEntry('geo_crystal', chance: 0.25),
      DropEntry('astral_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('corebiter_hide', weight: 35, min: 2, max: 4),
      DropEntry('deepstratum_ore', weight: 30, min: 2, max: 4),
      DropEntry('nadir_garnet', weight: 30, min: 1, max: 2),
      DropEntry('stonefall_signet', weight: 5),
    ],
  );

  /// ⚠️ **No gate part on either boss.** §4.2's drop table still shows
  /// `the_dark_third` here; §3.4's reconciliation moved it to The Umbral
  /// Wastes, the catalogue row strikes it out, and §7.3 lists no key among
  /// this zone's ids. A fourth supplier would silently loosen the Citadel's
  /// door.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('geo_crystal', min: 1, max: 2),
      DropEntry('astral_crystal', min: 1, max: 2),
      DropEntry('geo_shard', min: 1, max: 2),
      DropEntry('astral_shard', min: 1, max: 2),
      DropEntry('geo_dust', min: 4, max: 8),
      DropEntry('astral_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('corebiter_hide', weight: 35, min: 4, max: 8),
      DropEntry('deepstratum_ore', weight: 20, min: 3, max: 6),
      DropEntry('nadir_garnet', weight: 15, min: 2, max: 4),
      DropEntry('stonefall_signet', weight: 20),
      DropEntry('bedrock_greaves', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    stratumWarden,
    constellate,
    fadelight,
    corebiter,
    deadreckoner,
  ];

  static const minis = <EnemyDef>[
    stonefallHerald,
    bedrockColossus,
    nadir,
    theLongCount,
  ];

  static const bosses = <EnemyDef>[theOverburden, theBuriedConstellation];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
