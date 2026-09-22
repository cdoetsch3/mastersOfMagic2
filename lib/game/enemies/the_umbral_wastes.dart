/// The Umbral Wastes bestiary — Lv 47–51, Umbra (ETHEREAL_CONTRACT §4.3).
///
/// ⭐ **Theme: the dark here is deliberate. Something decided its shape.**
/// From the arrival text — *"You round the shoulder and the light stops. Not
/// dusk — an absence with an edge to it. The ice here has never melted and
/// holds its shape like something that has been thought about."* Not absence —
/// **design**, and every creature is written as something that was *decided*
/// rather than something that happened.
///
/// ⚠️ **The deliberate rhyme with the Old Quarry (15–19) is not duplication
/// and must not be "fixed"** — ENEMIES §2f logged it on purpose: there
/// something was **removed** and the hole is animate; here dark was
/// **imposed** and given a shape. 📝 §2f's *"worth not making it a third
/// time"* still stands.
///
/// ⭐ **A pure zone** (ENEMIES §2e; ETHEREAL_CONTRACT §3.2) — every creature
/// is single-element Umbra and the whole roster pays in one mote ladder, the
/// `umbra_*` family this zone defines. ⚠️ No off-element move: §2e.2 names
/// four creatures in fifteen zones and none of them is here.
///
/// ⭐⭐ **Umbra's passive IS the zone's status tutor, and it costs no new
/// effect.** The engine grows **Creeping Dark** by one stack per point of
/// charge spent on any Umbra cast (`duel.dart`, `CreepingDarkStatus`), caps
/// at 15, and sheds one a turn without Umbra: at 5 it hides the element the
/// caster is charging, at 10 the charge and health, at 15 their own. That is
/// why Nightspill's kit is cheap and constant and What Was Thought About's
/// dear move is cost 4 — the same mechanic read at two volumes, one stacking
/// steadily and one arriving in a lump.
///
/// ⭐ **The boss pair is the theme's two halves** (ENEMIES §2e): Nightbringer
/// is *who made it dark* — a will, which is what §2g reserves the Tyrant for
/// — and What Was Thought About is *the shape it was given*, so an Aspect.
/// ⚠️ Not a mirror; do not "fix" either into the other's archetype to make
/// the pair symmetrical.
///
/// ⚠️ **The Aspect must be single-element** (ENEMIES §2.5) and its stat block
/// is ETHEREAL_CONTRACT §2.4's row verbatim: `crit 15/+70, defl 20/18`.
/// ⭐ **+70 crit damage is the largest number on any stat block in the game**
/// — a crit deals 220% — and it is deliberately paired with a *low* 15%
/// chance. The zone's premise is *deliberate* dark: it does not happen often,
/// and when it does it was decided.
///
/// ⚠️ **Combat stats (§2.2/§2.3) copy each archetype's row verbatim**,
/// reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats`, never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own default):
/// §2.3 calls it "the yardstick," and a yardstick with a thumb on the scale
/// stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression.
/// `test/the_umbral_wastes_test.dart` resolves every id against
/// [ItemCatalogue] instead.
///
/// ⭐ **The `hide` role has no hide item here and resolves to
/// `thoughtglass`** — the zone's SECOND gatherable material
/// (ETHEREAL_CONTRACT §3.5.1): *"everywhere else 'something died' pays in the
/// zone's stuff."* ⚠️ The one exception is the Siphon, whose row §4.3 writes
/// out by hand and pays in `umbralweave`; the contract's explicit table wins
/// over the general rule.
///
/// ⚠️ **Both bosses carry the gate part on `always`, never weighted**
/// (ENEMIES §2e.1). A run draws one boss of two; a `the_dark_third` that only
/// fell from the boss you did not draw would make a mandatory progression
/// item a coin flip.
///
/// 📝 **`climbers_ration` and `goldenrood_draught` are Hallowmarch's ids**
/// (ETHEREAL_CONTRACT §4.1) and are dropped but not defined here; until that
/// lane lands they are the only two unresolvable ids in this file, and the
/// zone test says so out loud rather than skipping the check.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_umbral_wastes';
const _umbra = [MagicElement.umbra];

/// ⭐ A pure zone pays one mote ladder at the full 0.75, the shipped shape
/// (ETHEREAL_CONTRACT §4.3's `_commonAlways`). A hybrid would pay two at half
/// each; this zone has only one element to pay in.
const _commonAlways = [DropEntry('umbra_dust', chance: 0.75, min: 1, max: 2)];

abstract final class UmbralWastesBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ **The zone's anchor name** (`World.opponentNameFor`), and ⭐ **one of
  /// the three zones the Siphon is kept in** (ENEMIES §2f): it is named for
  /// eating, and the dark here consumes by design. Its lesson is that chip
  /// damage never accumulates — it drinks back everything you trickle into
  /// it, so you commit to burst or you do not win.
  ///
  /// ⚠️ **No crit on the §2.3 Siphon row, deliberately** — a lifesteal crit
  /// heals for the crit too, and a 0.95-HP body that can double-heal off one
  /// roll is the stalemate ENEMIES §2.2 already fears.
  static const umbralDevourer = EnemyDef(
    id: 'umbral_devourer',
    name: 'Umbral Devourer',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _umbra,
    lore:
        'A mouth-shaped gap in the dark about the size of a person, with no '
        'creature around it and no edge to it anywhere except at the front. '
        'What it closes on is simply less than it was.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, dodge: 6),
    moves: [
      Spell(
        id: 'uw_openit',
        name: 'Open It',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8, lifesteal: 0.5),
      ),
      // ⭐ The burst it wants you to beat: dear, slow to reach, and it gives
      // back three quarters of whatever it takes.
      Spell(
        id: 'uw_taketherest',
        name: 'Take the Rest',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23, lifesteal: 0.75),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      // ⚠️ §4.3 writes this row out by hand — the Siphon pays in
      // `umbralweave`, not in the zone's second material, and the explicit
      // table outranks §3.5.1's general `hide` rule.
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('umbralweave', weight: 45),
        DropEntry('goldenrood_draught', weight: 15),
      ],
    ),
  );

  /// ⭐ **The yardstick**, and the strangest thing in the zone precisely
  /// because it is not strange: everything else here was decided into its
  /// shape, and this one walks the edge of the absence and fights you
  /// completely straight. ⚠️ Adept → `EnemyCombatStats.none`, deliberately.
  ///
  /// ⚠️ **Adept, re-banded from Skirmisher** (ENEMIES §2e, 2026-09-22) — the
  /// zone had no yardstick and a Skirmisher is the archetype the audit found
  /// least worth a slot at this band.
  static const edgewalker = EnemyDef(
    id: 'edgewalker',
    name: 'Edgewalker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _umbra,
    lore:
        'A person walking the exact line where the light stops, one boot lit '
        'and one boot not, at a pace that never varies. It has been keeping '
        'to that line long enough to have worn it.',
    moves: [
      Spell(
        id: 'uw_steptotheline',
        name: 'Step to the Line',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit. Nothing
      // clever, which is the point of a yardstick.
      Spell(
        id: 'uw_setyourfooting',
        name: 'Set Your Footing',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'uw_cutalongit',
        name: 'Cut Along It',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      // ⭐ The `hide` role, resolved to the zone's SECOND gatherable material
      // (§3.5.1) — this zone skins nothing.
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('thoughtglass', weight: 50, min: 1, max: 2),
        DropEntry('umbra_shard', weight: 8, min: 1, max: 2),
        DropEntry('umbra_dust', weight: 12, min: 2, max: 3),
      ],
    ),
  );

  /// ⭐ **One of the seven Sentinels kept** (ENEMIES §2f): ice that holds its
  /// shape **because it was decided** is a wall with a reason, which is the
  /// archetype's whole premise stated in one noun. It teaches shield-breaking
  /// — and the tell is that the wall is the expensive move, so it telegraphs.
  static const consideredIce = EnemyDef(
    id: 'considered_ice',
    name: 'Considered Ice',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _umbra,
    lore:
        'A standing slab of black ice twice a person\'s height with every '
        'face flat and every angle the same angle. Nothing has melted off it '
        'and nothing has been added to it since it was put there.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'uw_holdtheshape',
        name: 'Hold the Shape',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Cost 4 and priority 3 — slow on purpose (§2.5, tempo lean = cost
      // band): the wall is the dear move, so the charge bar is the warning.
      Spell(
        id: 'uw_decidetobeawall',
        name: 'Decide to Be a Wall',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      // ⭐ The `material` role, and therefore the headline material —
      // umbralweave comes off the ice, and this is the ice.
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('umbralweave', weight: 55, min: 1, max: 3),
        DropEntry('umbra_shard', weight: 7),
        DropEntry('umbra_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('climbers_ration', chance: 0.02)],
    ),
  );

  /// ⭐⭐ **The Creeping Dark tutor** (ENEMIES §2e: *"Umbra's passive is the
  /// only element status built to stack — this is the creature that teaches
  /// it"*). Both moves are cheap, constant and multi-hit — the §1.3 Blighter
  /// rule — and because the engine grows the stack by **charge spent**, a kit
  /// that never stops casting is a stack that never stops climbing.
  static const nightspill = EnemyDef(
    id: 'nightspill',
    name: 'Nightspill',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _umbra,
    lore:
        'Dark running downhill over the ice the way water would, ankle-deep '
        'and spreading, finding the low ground first. It arrives at you in '
        'the order the ground says it should.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'uw_seep',
        name: 'Seep',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'uw_findthelowground',
        name: 'Find the Low Ground',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('umbralweave', weight: 55, min: 1, max: 3),
        DropEntry('umbra_shard', weight: 7),
        DropEntry('umbra_dust', weight: 13, min: 1, max: 2),
      ],
      bonus: [DropEntry('climbers_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Killing fast beats playing safe — it is a shape somebody held in
  /// mind, and it has the substance of one. ⚠️ The Glasswing's 0.50 HP body
  /// against a 1.70 damage scale is the whole lesson: it will end you and a
  /// single committed cast ends it.
  static const thoughtform = EnemyDef(
    id: 'thoughtform',
    name: 'Thoughtform',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _umbra,
    lore:
        'A person-sized outline that is entirely edge and no interior, the '
        'ice behind it perfectly visible through the middle. Held still it '
        'is exact; move your head and part of it is not there.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'uw_cometomind',
        name: 'Come to Mind',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'uw_taketheshape',
        name: 'Take the Shape',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('thoughtglass', weight: 50, min: 1, max: 2),
        DropEntry('umbra_shard', weight: 8, min: 1, max: 2),
        DropEntry('umbra_dust', weight: 12, min: 2, max: 3),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each mini archetype, so the two drawn per run are always a
  // different pair of tactical roles (GAME_DESIGN §3d).

  /// ⭐ Champion — simply good at everything: a cheap opener, a wall, and a
  /// finisher it can actually afford.
  static const umbralKnight = EnemyDef(
    id: 'umbral_knight',
    name: 'Umbral Knight',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _umbra,
    lore:
        'Full plate a head taller than a person, matte black on every surface '
        'including the places armour is always bright. It keeps the dark in '
        'front of it the way a shield is kept in front.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'uw_advance',
        name: 'Advance',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'uw_closethevisor',
        name: 'Close the Visor',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'uw_bringthenightdown',
        name: 'Bring the Night Down',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ Redoubt — attrition, and the one lifesteal move §1.3 allows the
  /// archetype. An edge takes a part of everything that crosses it.
  static const theEdge = EnemyDef(
    id: 'the_edge',
    name: 'The Edge',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _umbra,
    lore:
        'The boundary of the dark itself, stood up on end and made to hold '
        'still — a flat vertical face as wide as the pass and only as thick '
        'as a line. Nothing goes round it because there is no round.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'uw_presenttheedge',
        name: 'Present the Edge',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'uw_betheboundary',
        name: 'Be the Boundary',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'uw_takewhatcrosses',
        name: 'Take What Crosses',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **The Executioner's cost cap stays at 4** (ETHEREAL_CONTRACT §1.3,
  /// inherited from KINETIC §1.3). At cost 5 the mini raw would land 884–1153
  /// at L60 against a 1012 HP bar — a one-shot with change. At 4 it lands the
  /// two-cast kill the archetype is for.
  /// ⭐⭐ `executeBelowPercent: 30` is the archetype's lesson written into the
  /// effect rather than into a bigger number: below a third it does not miss
  /// its chance, it takes it.
  static const voidStalker = EnemyDef(
    id: 'void_stalker',
    name: 'Void Stalker',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _umbra,
    lore:
        'Lean, long-limbed and taller than a person, built entirely of the '
        'absence rather than of anything in it. It picks one of a group at '
        'the start and afterwards there were never any others.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'uw_pickyouout',
        name: 'Pick You Out',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'uw_finishinthedark',
        name: 'Finish in the Dark',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 30),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects and
  /// its middle move lands ahead of everything on the board.
  /// 📝 The engine has no creature-applied debuff yet, so the archetype is
  /// written with the levers that actually resolve.
  static const eclipseWeaver = EnemyDef(
    id: 'eclipse_weaver',
    name: 'Eclipse Weaver',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _umbra,
    lore:
        'A low wide thing of many thin legs working across the face of the '
        'pass, drawing something behind it that the light does not come back '
        'through. It has covered a great deal of ground already.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'uw_drawthefirstthread',
        name: 'Draw the First Thread',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'uw_crossthelight',
        name: 'Cross the Light',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'uw_closetheweave',
        name: 'Close the Weave',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🌑 **Who made it dark.** ⭐ A **will**, which is exactly what ENEMIES
  /// §2g reserves the Tyrant for — *"a person, a will, something that
  /// decided"* — and this zone's whole premise is that something decided.
  /// ⚠️ Do not re-band it to Juggernaut: a Juggernaut is a mass, and a mass
  /// cannot have imposed anything.
  /// ⭐ The Tyrant's 1–5 cost band is the widest in the game and it uses all
  /// of it: the opener is a single charge and the finisher is five, so the
  /// charge bar is the only thing telling you which is coming.
  static const nightbringer = EnemyDef(
    id: 'nightbringer',
    name: 'Nightbringer',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _umbra,
    lore:
        'A tall robed figure that walks the pass at an unhurried pace, and '
        'the dark is not around it so much as arriving in the places it has '
        'decided on, slightly before it gets there.',
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
        id: 'uw_sayitisnight',
        name: 'Say It Is Night',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'uw_putthedarkwhereitgoes',
        name: 'Put the Dark Where It Goes',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'uw_bringitdownentire',
        name: 'Bring It Down Entire',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🌑 **The shape it was given — Creeping Dark taken to an extreme.**
  /// ⚠️ Single-element by rule (ENEMIES §2.5), and its stat block is
  /// ETHEREAL_CONTRACT §2.4's row verbatim: `crit 15/+70, defl 20/18`.
  /// ⭐⭐ **+70 crit damage is the largest number on any stat block in the
  /// game** — a crit deals 220% — and it is deliberately paired with a *low*
  /// 15% chance, because the premise is *deliberate* dark: it does not happen
  /// often, and when it does it was decided.
  ///
  /// ⭐ The kit climbs 1 → 2 → 4 because the engine grows Creeping Dark by
  /// **charge spent**: the dear move is a four-stack jump in one cast, which
  /// is the archetype's lesson (one element, taken further than the player
  /// has met it) expressed in charge cost rather than in a new effect.
  static const whatWasThoughtAbout = EnemyDef(
    id: 'what_was_thought_about',
    name: 'What Was Thought About',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _umbra,
    lore:
        'Not a figure in the dark but the dark holding one particular shape, '
        'about the size of a house and entirely deliberate about every part '
        'of its outline. Looking at it, you can tell it was chosen.',
    combatStats: EnemyCombatStats(
      critChance: 15,
      critDamage: 70,
      deflectChance: 20,
      deflectAmount: 18,
    ),
    moves: [
      Spell(
        id: 'uw_bethoughtof',
        name: 'Be Thought Of',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'uw_takeonanoutline',
        name: 'Take On an Outline',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'uw_bewhatwasdecided',
        name: 'Be What Was Decided',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ `umbra_crystal` appears here and on [_bossDrops] and nowhere else
  /// (ETHEREAL_CONTRACT §4.3) — the mote ladder's first real step is a fight
  /// the player chose.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('umbra_shard'),
      DropEntry('umbra_dust', min: 2, max: 4),
      DropEntry('umbra_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('umbralweave', weight: 40, min: 2, max: 4),
      DropEntry('thoughtglass', weight: 30, min: 2, max: 4),
      DropEntry('climbers_ration', weight: 25),
      DropEntry('the_considered_ring', weight: 5),
    ],
  );

  /// ⚠️ **`the_dark_third` is on the `always` line, not the weighted one**
  /// (ETHEREAL_CONTRACT §3.4, ENEMIES §2e.1). A tier gate that needs a 10%
  /// roll three times is a grind, not a gate — and because a run draws one
  /// boss of two, **both** bosses share this table.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('the_dark_third'),
      DropEntry('umbra_crystal', min: 1, max: 2),
      DropEntry('umbra_shard', min: 1, max: 2),
      DropEntry('umbra_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('umbralweave', weight: 45, min: 4, max: 8),
      DropEntry('thoughtglass', weight: 25, min: 3, max: 6),
      DropEntry('the_considered_ring', weight: 20),
      DropEntry('the_deliberate_dark', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    umbralDevourer,
    edgewalker,
    consideredIce,
    nightspill,
    thoughtform,
  ];

  static const minis = <EnemyDef>[
    umbralKnight,
    theEdge,
    voidStalker,
    eclipseWeaver,
  ];

  static const bosses = <EnemyDef>[nightbringer, whatWasThoughtAbout];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
