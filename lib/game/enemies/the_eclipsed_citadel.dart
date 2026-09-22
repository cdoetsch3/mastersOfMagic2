/// The Eclipsed Citadel bestiary — Lv 58–60, **all twelve elements**
/// (ETHEREAL_CONTRACT §4.8, ENEMIES §2e).
///
/// ⭐ **Theme: the last thing in the way.** From the arrival text — *"Below it,
/// through a gap in nothing, is the summit of the mountain you could not
/// climb. The Citadel is between you and it."* ⚠️ **Not a place — an
/// obstruction.** Nothing grows on it, nothing is mined out of it, and it has
/// **no gather node** (§3.1's ruling); what it yields, it yields because you
/// took it off the thing standing in the door.
///
/// ⭐⭐ **The twelve, three times.** §2e keeps the 5/4/2 template and carries
/// the twelve elements *inside* it, by making each rank spend them a different
/// way — so the roster laws all still hold and the zone needs no bespoke shape:
///
/// - **Commons** — the macro-tier loop walked once (`element.dart`: Kinetic ▸
///   Primal ▸ Ethereal ▸ Celestial ▸ Kinetic). Four commons carry one macro
///   edge each, one element from either side; the fifth, the Adept, carries the
///   four left over, **one per tier** — the Concordant Crown in miniature.
/// - **Minis** — the four quarters the player walked, by their gazetteer names:
///   the basin, the range, the high shelf, the climb. Three elements each, one
///   quarter each, and one of each mini archetype.
/// - **Bosses** — the eclipse. One body covering, one light covered.
///
/// Twelve, twelve, twelve. ⚠️ **Read the roster table before touching an
/// element list** — there is no formula here, only the table.
///
/// ⭐⭐ **The two bosses are a SEQUENCE, not a pool** ([bossSequence]) — §2e's
/// ruling, and the one place the shipped adventure shape needed a code change.
/// Every other zone draws one boss of two so a clear is a coin flip; a finale
/// that ends on a coin flip has no ending, and half the players would never
/// meet the game's named antagonist. `Bestiary.bossSequenceFor` is the general
/// mechanism and `adventure.dart` reads it; the zone counts as cleared only
/// once the LAST name in the list falls.
///
/// ⚠️ **Procarius is a MAGE** (`isMage: true`, ENEMIES §3.4). His moves are
/// not creature moves at all — they are the exact `Spellbook` loadout of
/// `AiRoster.byId('procarius')`, his elements are that persona's elements, and
/// his intelligence is the persona's **10** rather than the Tyrant's 9
/// ([EnemyDef.intelligenceOverride]). ⭐ *"The creatures act, the mage casts"*
/// — that grammatical split (§3.3a: verbs everywhere else, `Spellbook` nouns
/// here) is the last thing the game says.
///
/// ⚠️ **No key drops in this zone, and no gate item.** §2e.1 puts `key` on both
/// bosses of a gate zone and §3.5.3 makes it `always`, but the Citadel is the
/// gate's *destination*: its own exit leads to Zenith. Procarius's `key` role
/// is the **Concordant Crown frame**, which has no item yet — the Crown is
/// blocked on Core/Heart motes (§3.2/§3.4a) — so this lane drops nothing for
/// it and leaves the 📝 on [procariusTheEclipsed].
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression; `test/the_eclipsed_citadel_test
/// .dart` resolves every id against [ItemCatalogue] instead. ⚠️ **`sanctus_*`
/// (Hallowmarch), `umbra_*` (The Umbral Wastes), `climbers_ration`
/// (Hallowmarch) and `nightink_draught` (The Unwritten Library) are cross-lane
/// references** owned by parallel Ethereal worktrees; they resolve once the
/// merge coordinator lands the lanes together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_eclipsed_citadel';

/// ⭐ The four macro-tier edges, one per common, one element from each side of
/// the loop `element.dart` describes: Kinetic ▸ Primal ▸ Ethereal ▸ Celestial ▸
/// Kinetic. ⚠️ Order inside each pair is the edge's own direction — the winner
/// first — so a reader can walk the loop down the file.
const _kineticToPrimal = [MagicElement.geo, MagicElement.flora];
const _primalToEthereal = [MagicElement.pyro, MagicElement.umbra];
const _etherealToCelestial = [MagicElement.sanctus, MagicElement.solar];
const _celestialToKinetic = [MagicElement.lunar, MagicElement.electro];

/// ⭐⭐ The four the loop left over — **one from each tier**, which is the
/// Concordant Crown in miniature and the reason the yardstick of the last zone
/// is a person trying to do exactly what the player is trying to do.
const _oneFromEachTier = [
  MagicElement.aqua,
  MagicElement.aero,
  MagicElement.astral,
  MagicElement.arcane,
];

// ⭐ The four quarters, by the names the gazetteer gave them. Each mini is one
// quarter's three elements, so the four minis between them are the twelve
// again — this time sorted by TIER rather than by counter edge.
const _primalQuarter = [
  MagicElement.flora,
  MagicElement.aqua,
  MagicElement.pyro,
];
const _kineticQuarter = [
  MagicElement.geo,
  MagicElement.electro,
  MagicElement.aero,
];
const _celestialQuarter = [
  MagicElement.solar,
  MagicElement.lunar,
  MagicElement.astral,
];
const _etherealQuarter = [
  MagicElement.sanctus,
  MagicElement.umbra,
  MagicElement.arcane,
];

/// ⭐ **Totality carries all twelve** — the mechanical statement of *"no
/// five-slot loadout counters everything."* ⚠️ Deliberately
/// `MagicElement.values` rather than a written-out list: `world.dart` gives the
/// Citadel its elements the same way, and the two must never disagree about
/// what "all twelve" means. The zone suite pins the length at 12, so a
/// thirteenth element appended to the enum fails here loudly instead of
/// joining a shipped boss's kit quietly.
const _allTwelve = MagicElement.values;

/// ⚠️ **Procarius's elements are the PERSONA's**, in the persona's own order
/// (`ai_personas.dart`, `_archmage`): Arcane, Umbra, Lunar, Electro, Pyro.
/// Written out const rather than read off `AiRoster` because an `EnemyDef` is
/// const and a `Loadout` is not; the zone suite asserts the two agree.
const _procariusElements = [
  MagicElement.arcane,
  MagicElement.umbra,
  MagicElement.lunar,
  MagicElement.electro,
  MagicElement.pyro,
];

/// ⭐⭐ **The zone pays in all twelve mote families, and defines none of them**
/// (§3.5.2, §8.4's chosen option). Every other zone pays one or two; this one
/// pays everything, which is the only mechanical statement available for *"all
/// twelve at once"* that does not require twelve new items.
///
/// ⚠️ **Twelve rows at `chance: 0.12`, not a `DropEntry.oneOf`.** §4.8 offered
/// both and recommended this one: it needs no engine change, it reads correctly
/// in the loot log (a kill that paid Aero Dust *says* Aero Dust), and it yields
/// ~1.4 dusts per kill across a random spread of families. ⚠️ **Whichever was
/// chosen had to be chosen once** — the mini and boss tables below have the
/// same shape.
const _commonAlways = [
  DropEntry('aqua_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('pyro_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('flora_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('electro_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('aero_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('geo_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('solar_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('lunar_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('astral_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('sanctus_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('umbra_dust', chance: 0.12, min: 1, max: 2),
  DropEntry('arcane_dust', chance: 0.12, min: 1, max: 2),
];

abstract final class EclipsedCitadelBestiary {
  // ---- commons ----------------------------------------------------------
  //
  // ⭐ The macro-tier loop, walked once. Four edges, four commons, and the
  // Adept holding the remainder.

  /// ⭐ The macro edge **Kinetic ▸ Primal**, in one object: stone shut long
  /// enough for root to grow into the seam, so that the rock and the green are
  /// now one fitting. A Sentinel, because a door that has been held is the
  /// shield-break lesson stated as a noun.
  static const theHeldDoor = EnemyDef(
    id: 'the_held_door',
    name: 'The Held Door',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _kineticToPrimal,
    lore:
        'Stone that has been shut long enough for root to grow into the '
        'seam, so that the rock and the green are now one fitting. Nothing '
        'has come through it in a very long time and it has stopped '
        'expecting anything to.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'ec_setthejamb',
        name: 'Set the Jamb',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ A Sentinel without a wall is only a bigger HP number (§2.2).
      Spell(
        id: 'ec_holditshut',
        name: 'Hold It Shut',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: _echoPool,
  );

  /// ⭐⭐ **The only creature in the game stacking Ignite and Creeping Dark
  /// together** (§2e) — a fire that gives off heat, and smoke, and no light
  /// whatsoever. The macro edge **Primal ▸ Ethereal**, and the Blighter's
  /// *"what statuses actually do"* taken to its conclusion.
  ///
  /// ⚠️ **Both moves are `DotAttackEffect`, and this is the first bestiary in
  /// the game to use one** — §2e authored the kit that way and the numbers are
  /// its own. ⭐ The impact halves stay inside §1.3's common column (5–8 at
  /// cost 1, 11–15 at cost 2 would be the single rows; a Blighter at 0.60
  /// damage authors *under* them because the burn is the payload). The burn
  /// itself is not raw damage and is not bounded by §1.3's per-charge ceiling —
  /// it is bounded by being survivable, which at 6×6 against a 1,012 HP bar it
  /// plainly is.
  static const ashlight = EnemyDef(
    id: 'ashlight',
    name: 'Ashlight',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _primalToEthereal,
    lore:
        'A fire that gives off heat, and smoke, and no light whatsoever, '
        'burning in a sconce nobody lit. Standing close to it is exactly as '
        'warm as standing close to a fire and exactly as dark as standing '
        'in a cellar.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'ec_takethelightout',
        name: 'Take the Light Out',
        chargeCost: 1,
        priority: 9,
        effect: DotAttackEffect(
          3,
          5,
          dotId: 'ec_afterburn',
          dotName: 'Afterburn',
          damagePerTick: 5,
          ticks: 3,
        ),
      ),
      Spell(
        id: 'ec_burnwithoutshowing',
        name: 'Burn Without Showing',
        chargeCost: 2,
        priority: 9,
        effect: DotAttackEffect(
          4,
          6,
          dotId: 'ec_afterburn',
          dotName: 'Afterburn',
          damagePerTick: 6,
          ticks: 6,
        ),
      ),
    ],
    drops: _echoPool,
  );

  /// ⭐ The macro edge **Ethereal ▸ Celestial**, and the Bruiser's lesson —
  /// reading the charge bar. It is completely telegraphed and it does not
  /// matter, because the thing it is winding up is the whole building.
  static const theKeptWatch = EnemyDef(
    id: 'the_kept_watch',
    name: 'The Kept Watch',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _etherealToCelestial,
    lore:
        'Still on post, still in the armour, still facing the direction it '
        'was told to face, which is not the direction you came from. It '
        'turns to deal with you and you can see the effort that costs it.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'ec_challenge',
        name: 'Challenge',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'ec_bringthewholeofficedown',
        name: 'Bring the Whole Office Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: _echoPool,
  );

  /// ⭐ The macro edge **Celestial ▸ Kinetic** — moonlight arriving along the
  /// ironwork the way current arrives along a wire. The Lasher's lesson, *"why
  /// a big shield is not always the answer"*, said as a fact about wiring:
  /// every strand meets the wall on its own.
  static const nightcurrent = EnemyDef(
    id: 'nightcurrent',
    name: 'Nightcurrent',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _celestialToKinetic,
    lore:
        'Moonlight arriving along the ironwork the way current arrives '
        'along a wire, and reaching the floor at the same time you do. '
        'Every rail in the hall carries a little of it and none of them '
        'carries all of it.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      // ⚠️ §1.3 has **no cost-1 ×3 row** — its cheap multi row is 3–5 ×2. §2e
      // asks for three hits here, so the per-charge ceiling governs instead:
      // 3–4 ×3 averages 10.5 on one charge, under the ≤12 raw/charge cap. A
      // 3–5 ×3 would land on exactly 12 and make this the most efficient
      // opener in the game, which is not what a Lasher is for.
      Spell(
        id: 'ec_runtheline',
        name: 'Run the Line',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 4, hits: 3),
      ),
      Spell(
        id: 'ec_comeinoneverywire',
        name: 'Come In on Every Wire',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _echoPool,
  );

  /// ⭐⭐ **The yardstick, and the last honest fight in the game.** Somebody
  /// else who came all this way to be let back in, and who is still here, and
  /// who is still asking. Its four elements are **one from each tier** — the
  /// Concordant Crown in miniature — and it carries no [EnemyCombatStats] on
  /// purpose: §2.3 calls the Adept row the yardstick, and a yardstick with a
  /// thumb on the scale stops being one.
  static const theLastApplicant = EnemyDef(
    id: 'the_last_applicant',
    name: 'The Last Applicant',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _oneFromEachTier,
    lore:
        'Somebody else who came all this way to be let back in, and who is '
        'still here, and who is still asking. The case it is making is a '
        'good one, and it has been making it for long enough that the '
        'making is all that is left.',
    moves: [
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit.
      Spell(
        id: 'ec_presenttheclaim',
        name: 'Present the Claim',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ec_standonthethreshold',
        name: 'Stand on the Threshold',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'ec_argueitproperly',
        name: 'Argue It Properly',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: _echoPool,
  );

  // ---- mini-bosses --------------------------------------------------------
  //
  // ⭐ The four quarters the player walked, arriving again with everything they
  // taught and none of the patience — and one of each mini archetype, so the
  // two drawn per run are always a different pair of tactical roles (§2g).

  /// ⭐ The Primal quarter: **a clean skill check**, because the basin is where
  /// the player learned to fight straight. A Champion says that without
  /// needing a gimmick.
  static const theBasin = EnemyDef(
    id: 'the_basin',
    name: 'The Basin',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _primalQuarter,
    lore:
        'The first ground, arriving with everything it taught you and none '
        'of the patience. It fights the way the woods fought and it is no '
        'longer interested in whether you are ready.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'ec_startagain',
        name: 'Start Again',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ec_closethecanopy',
        name: 'Close the Canopy',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ec_everythingyoulearnedhere',
        name: 'Everything You Learned Here',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _basinDrops,
  );

  /// ⭐ The Kinetic quarter: **attrition**, because that quarter was weight.
  /// The rock you crossed, standing across the way again, in no hurry at all.
  static const theRange = EnemyDef(
    id: 'the_range',
    name: 'The Range',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _kineticQuarter,
    lore:
        'The rock you crossed, standing across the way again, in no hurry '
        'at all. It does not chase and it does not need to; the distance '
        'between you and it is the whole of its argument.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ec_standintheroad',
        name: 'Stand in the Road',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 17),
      ),
      // 📝 §1.3 has no **mini cost-4 shield** row — the mini ladder stops at
      // cost 3 (30–40) and the boss's cost-3 row is 40–52. §2e puts this wall
      // at cost 4, so the number is the mini row scaled by 4/3 and rounded onto
      // the nearest authored pair. ⚠️ Priority 3 per §2e, not the Aperture's 2:
      // the Range does not race the player's shield, it simply outlasts it.
      Spell(
        id: 'ec_putthemountaininfront',
        name: 'Put the Mountain in Front',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'ec_grinditout',
        name: 'Grind It Out',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33, lifesteal: 0.4),
      ),
    ],
    drops: _rangeDrops,
  );

  /// ⭐⭐ The Celestial quarter: **one misplay ends you** — *Thin Air is the
  /// Celestial band's own mechanic, returning as a fight.* The high air, which
  /// never had enough in it, and which now has none.
  ///
  /// ⚠️ **The Executioner's cost cap stays at 4, against §2e's own kit
  /// sketch.** The sketch gives *Step Off the Edge* cost 5; §1.3 — the damage
  /// authoring table, which is this contract's own and is explicit about this
  /// band — rules the cap back to 4: at L60 a mini five-charge raw lands
  /// **884–1153 against a 1,012 HP bar**, which is not a two-cast kill but a
  /// one-shot with change. At cost 4 it lands 500–653, the ratio the archetype
  /// is for. ⭐ The roster wins creature facts (§0.1); the contract wins
  /// numbers, and a charge cost is a number.
  static const theShelf = EnemyDef(
    id: 'the_shelf',
    name: 'The Shelf',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _celestialQuarter,
    lore:
        'The high air, which never had enough in it, and which now has '
        'none. It is a flat ledge of nothing standing upright, and the '
        'drop on the far side of it is the part that is paying attention.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'ec_thintheair',
        name: 'Thin the Air',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⭐ The execute rider, and the only one in the zone: below 35% every hit
      // is a guaranteed crit, on top of the Executioner's +40 crit damage.
      Spell(
        id: 'ec_stepofftheedge',
        name: 'Step Off the Edge',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 35),
      ),
    ],
    drops: _shelfDrops,
  );

  /// ⭐⭐ The Ethereal quarter: **it punishes a bad loadout**, which is
  /// precisely what that quarter does — *gear closes the gap, not XP* (§2.6a).
  /// The last stretch, which was always above your level and was always
  /// answered with what you were carrying.
  ///
  /// ⭐ The Hexer's signature is priority, not status: its cheap move lands
  /// ahead of the whole board and one thing it throws goes straight through a
  /// wall. ⭐ *"Nothing You Brought Is Enough"* — the move name is the lesson.
  static const theClimb = EnemyDef(
    id: 'the_climb',
    name: 'The Climb',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _etherealQuarter,
    lore:
        'The last stretch, which was always above your level and was always '
        'answered with what you were carrying. It is still above your level '
        'and it would like to know what you brought this time.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'ec_weighthepack',
        name: 'Weigh the Pack',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ec_keepgoingup',
        name: 'Keep Going Up',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ec_nothingyoubroughtisenough',
        name: 'Nothing You Brought Is Enough',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _climbDrops,
  );

  // ---- bosses -------------------------------------------------------------
  //
  // ⭐⭐ The eclipse: one body covering, one light covered. ⚠️ Fought in the
  // order [bossSequence] names them, every clear — see the library note.

  /// ⛰️ **The covering.** Not a creature standing in the door — the door,
  /// having decided to be a creature. A Juggernaut, because endurance is the
  /// shape of *"no five-slot loadout counters everything"*: it shields and
  /// attacks in a different element almost every turn, and it carries **all
  /// twelve** so that it can.
  static const totality = EnemyDef(
    id: 'totality',
    name: 'Totality',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _allTwelve,
    lore:
        'The moment the light is completely covered, standing upright and '
        'taking up the doorway from jamb to jamb. There is no gap around '
        'it and there is no expression on it, and the dark it is making is '
        'the only dark in the hall with an edge.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'ec_coverit',
        name: 'Cover It',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'ec_closeover',
        name: 'Close Over',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'ec_nothinggetspast',
        name: 'Nothing Gets Past',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _totalityDrops,
  );

  /// 👑 **The covered — the one the Citadel was built around, and the reason
  /// the name is in the passive voice.** The game's named antagonist, its only
  /// level-60 persona, and the `opponentNameFor` anchor for this zone, which no
  /// other zone spends on a boss: ⭐ the map names the Citadel after the man,
  /// not after a common.
  ///
  /// ⚠️⚠️ **Three things here are deliberate exceptions. Do not "fix" them.**
  ///
  /// 1. ⭐ **`isMage: true`, so [moves] is a `Spellbook` loadout, not a
  ///    creature kit** (§3.4). It is `AiRoster.byId('procarius').loadout.spells`
  ///    *verbatim* — Jolt · Blast · Ruin · Cataclysm · Barrage · Drain ·
  ///    Sanctuary · Barrier · Overload · Discharge — and `elements` is that
  ///    persona's five. The Tyrant's `moveCount: 3` describes a creature kit
  ///    and does not apply; the zone suite exempts mages from the move-count
  ///    law and asserts the loadout instead.
  /// 2. ⭐ **Intelligence 10, overriding the Tyrant's 9**
  ///    ([EnemyDef.intelligenceOverride]). The persona is the older, shipped
  ///    record and the ladder has always run him at 10.
  /// 3. ⚠️ **The loadout is written out rather than read off the persona.**
  ///    `AiRoster.all` is `static final` and a `Loadout` is not const, so a
  ///    const `EnemyDef` cannot reach `.loadout.spells` — and every other
  ///    creature in the game being const is worth more than saving ten lines
  ///    (it is what keeps `Bestiary.all` const and the duel deterministic).
  ///    ⭐ The copy is kept honest by assertion, not by hope: the zone suite
  ///    compares these ten spells and these five elements against
  ///    `AiRoster.byId('procarius')` and fails the moment the persona moves.
  ///
  /// 📝 **His `key` drop role has no item and therefore drops nothing.** §2e.1
  /// makes it the **Concordant Crown frame** that gates Zenith; §3.4a says the
  /// Crown is unbuildable until Core/Heart motes ship, so there is no id to
  /// name. ⚠️ This is a known, deliberate gap — when the Crown frame lands it
  /// goes on `always` here, and on Totality too (§3.5.3: keys drop from BOTH
  /// bosses of a gate zone, never weighted).
  static const procariusTheEclipsed = EnemyDef(
    id: 'procarius_the_eclipsed',
    name: 'Procarius, the Eclipsed',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _procariusElements,
    isMage: true,
    intelligenceOverride: 10,
    lore:
        'A tall man in dark robes standing in the last of the hall with '
        'nothing behind him, waiting without impatience for you to finish '
        'getting here. Everything else in the Citadel was between you and '
        'him; he is between you and the door.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
    // ⚠️ `_archmage`, in the persona's own order. Nouns, not verbs — the
    // battle log reads *"Procarius casts Arcane Cataclysm"* while everything
    // else in the zone does something to you (§3.3a).
    moves: [
      Spellbook.jolt,
      Spellbook.blast,
      Spellbook.ruin,
      Spellbook.cataclysm,
      Spellbook.barrage,
      Spellbook.drain,
      Spellbook.sanctuary,
      Spellbook.barrier,
      Spellbook.overload,
      Spellbook.discharge,
    ],
    drops: _procariusDrops,
  );

  /// ⭐⭐ **The finale is a SEQUENCE, and this list is its definition** (§2e's
  /// ruling, §4.1's exception). `Bestiary.bossSequenceFor` exposes it to
  /// `adventure.dart`, which appends **every** name here to the run in order
  /// instead of drawing one — and `AdventureRun.atFinalBoss` is what makes the
  /// zone count as cleared only after the LAST of them falls.
  ///
  /// ⚠️ **Order is load-bearing and it is the zone's name.** Totality is the
  /// covering; Procarius is the covered. You fight the Citadel, and then you
  /// fight the thing standing in the door. Reversing this list would put the
  /// game's named antagonist in front of the obstruction he is behind.
  ///
  /// ⚠️ **Every other zone must keep an EMPTY sequence** — one boss drawn of
  /// two is what makes a zone worth running twice (§3d, §4.1), and a sequence
  /// anywhere else quietly deletes that.
  static const bossSequence = <String>['totality', 'procarius_the_eclipsed'];

  // ---- shared tables --------------------------------------------------
  //
  // ⭐ §3.5.2's join, and it is the shortest one in the game: `material` →
  // `eclipse_iron`, `hide` → `corona_pearl`. ⚠️ **Both are kill-only and
  // neither has a gather node** (§3.1) — not because a hide never does, but
  // because nothing grows on an obstruction and there is no seam to work. The
  // roster gives four of the five commons a `material` or `hide` role and all
  // five a `mote`; §4.8 answers with ONE common row for the whole zone, so the
  // roles land on a single pool rather than splitting by element the way a
  // hybrid's do. ⭐ That is the Citadel: one pool, everything in it.

  /// ⭐ §4.8's *"echo-pool encounter"* row, shared by all five commons.
  /// ⚠️ `climbers_ration` rides `bonus` at 5% — the quarter's drop-only ration,
  /// carried by all eight Ethereal zones (§3.3), and everything on this
  /// mountain is carrying one when you kill it.
  static const _echoPool = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 30),
      DropEntry('eclipse_iron', weight: 35),
      DropEntry('corona_pearl', weight: 25),
      DropEntry('nightink_draught', weight: 10),
    ],
    bonus: [DropEntry('climbers_ration', chance: 0.05)],
  );

  /// The mini `main` table — §4.8 verbatim, and the same for all four.
  /// ⭐ `the_eclipsed_band` at 5 of 100 is the Rare chase.
  static const _miniMain = [
    DropEntry('eclipse_iron', weight: 40, min: 2, max: 4),
    DropEntry('corona_pearl', weight: 35, min: 2, max: 4),
    DropEntry('nightink_draught', weight: 20),
    DropEntry('the_eclipsed_band', weight: 5),
  ];

  /// ⭐ §4.8's mini `always` is *"any 2 of the twelve shards · the same 2 dusts
  /// · a matching crystal"*. ⚠️ **"Any 2" is resolved as the first two of the
  /// mini's OWN three elements** — so a mini pays in what it is made of, and
  /// the four minis between them cover eight distinct families rather than
  /// rolling the same two every run. The crystal matches the first.
  static const _rangeDrops = DropTable(
    always: [
      DropEntry('geo_shard'),
      DropEntry('electro_shard'),
      DropEntry('geo_dust', min: 2, max: 4),
      DropEntry('electro_dust', min: 2, max: 4),
      DropEntry('geo_crystal', chance: 0.25),
    ],
    main: _miniMain,
  );

  static const _basinDrops = DropTable(
    always: [
      DropEntry('flora_shard'),
      DropEntry('aqua_shard'),
      DropEntry('flora_dust', min: 2, max: 4),
      DropEntry('aqua_dust', min: 2, max: 4),
      DropEntry('flora_crystal', chance: 0.25),
    ],
    main: _miniMain,
  );

  static const _shelfDrops = DropTable(
    always: [
      DropEntry('solar_shard'),
      DropEntry('lunar_shard'),
      DropEntry('solar_dust', min: 2, max: 4),
      DropEntry('lunar_dust', min: 2, max: 4),
      DropEntry('solar_crystal', chance: 0.25),
    ],
    main: _miniMain,
  );

  static const _climbDrops = DropTable(
    always: [
      DropEntry('sanctus_shard'),
      DropEntry('umbra_shard'),
      DropEntry('sanctus_dust', min: 2, max: 4),
      DropEntry('umbra_dust', min: 2, max: 4),
      DropEntry('sanctus_crystal', chance: 0.25),
    ],
    main: _miniMain,
  );

  /// ⭐ The boss `main` table — §4.8 verbatim, shared by both bosses.
  ///
  /// 📝 **It pays an epic at 20 combined weight — one clear in five**, where
  /// KINETIC's best was 15 on a single epic. ⚠️ Deliberate: it is the last
  /// fight and there are two chases, so a player who beats the sequence five
  /// times sees roughly one of each. 📝 Flatten both to 8 if that reads as too
  /// generous — the knob is here and nowhere else.
  static const _bossMain = [
    DropEntry('eclipse_iron', weight: 35, min: 4, max: 8),
    DropEntry('corona_pearl', weight: 30, min: 4, max: 8),
    DropEntry('the_eclipsed_band', weight: 15),
    DropEntry('the_last_thing_in_the_way', weight: 10),
    DropEntry('the_corona', weight: 10),
  ];

  /// ⭐ **The richest always-line in the game** (§4.8): three crystals, three
  /// shards and three dusts, guaranteed. ⚠️ *"Any 3 of the twelve"* is resolved
  /// per boss. **Totality's three are the eclipse itself** — the light, the
  /// thing that covers it, and the dark that is left — which is the only
  /// principled way to pick three out of a creature that carries all twelve.
  static const _totalityDrops = DropTable(
    always: [
      DropEntry('solar_crystal', min: 1, max: 2),
      DropEntry('lunar_crystal', min: 1, max: 2),
      DropEntry('umbra_crystal', min: 1, max: 2),
      DropEntry('solar_shard', min: 1, max: 2),
      DropEntry('lunar_shard', min: 1, max: 2),
      DropEntry('umbra_shard', min: 1, max: 2),
      DropEntry('solar_dust', min: 4, max: 8),
      DropEntry('lunar_dust', min: 4, max: 8),
      DropEntry('umbra_dust', min: 4, max: 8),
    ],
    main: _bossMain,
  );

  /// ⚠️ **Procarius's three are the first three of his PERSONA's elements** —
  /// Arcane, Umbra, Lunar — so the man pays in what he casts. 📝 **No `key`
  /// entry**: see [procariusTheEclipsed] for why the Crown frame has no id yet.
  static const _procariusDrops = DropTable(
    always: [
      DropEntry('arcane_crystal', min: 1, max: 2),
      DropEntry('umbra_crystal', min: 1, max: 2),
      DropEntry('lunar_crystal', min: 1, max: 2),
      DropEntry('arcane_shard', min: 1, max: 2),
      DropEntry('umbra_shard', min: 1, max: 2),
      DropEntry('lunar_shard', min: 1, max: 2),
      DropEntry('arcane_dust', min: 4, max: 8),
      DropEntry('umbra_dust', min: 4, max: 8),
      DropEntry('lunar_dust', min: 4, max: 8),
    ],
    main: _bossMain,
  );

  static const commons = <EnemyDef>[
    theHeldDoor,
    ashlight,
    theKeptWatch,
    nightcurrent,
    theLastApplicant,
  ];

  static const minis = <EnemyDef>[theBasin, theRange, theShelf, theClimb];

  /// ⚠️ **Not a pool.** The list is the rank's membership; [bossSequence] is
  /// the order they are actually met in, and both of them are met every clear.
  static const bosses = <EnemyDef>[totality, procariusTheEclipsed];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
