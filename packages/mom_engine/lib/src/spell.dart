/// Spell definitions.
///
/// Spells are element-agnostic: a spell takes on the element the caster is
/// currently charged with. Priority is 1–10; lower priority acts earlier in
/// the turn — see [SpellPriority] for the named ladder.
library;

import 'status.dart';

/// The priority ladder, named. Lower acts first; 1–10 is the whole range.
///
/// ⭐ **Aux splits into two lanes** (TYPE_EFFECTS §7a, ruled 2026-08-26). The
/// shipped ladder had one aux rung at 7 for everything that wasn't a shield or
/// an attack. It now splits by *who you are pointing at*:
///
///  - [auxDefense] (7) — you act on yourself. Stances, next-attack riders,
///    cleanses, initiative.
///  - [auxOffense] (8) — you act on the ENEMY without dealing damage. Debuff
///    granters, enemy-status surgery, charge control.
///
/// The consequence, and the reason for the split: **your debuff lands before
/// their attack resolves, and their self-stance lands before your debuff
/// does.** Committing to a stance is rewarded over reacting to one, and a
/// debuff still beats the attack it is meant to blunt.
///
/// ⚠️ These are constants, not an enum, because [Spell.priority] is an `int`
/// that Quicken overrides to 2 and Waterlogged raises by 10 — the ladder is a
/// number line with named rungs, not a closed set.
abstract final class SpellPriority {
  /// Instants and a Quickened attack (2) — ahead of shields.
  static const int instant = 1;

  static const int shield = 3;

  static const int channel = 4;

  /// Quick attacks: beat aux and regular spells, but not shields.
  static const int quick = 5;

  /// Self-targeting aux: Empower, Quicken, Phase, Hasty, Hallow — and the
  /// banked stances (Lightfoot, Truesight, Keen, Composure, Meditate…).
  static const int auxDefense = 7;

  /// Enemy-targeting aux that deals no damage: Discharge — and the banked
  /// debuff granters and status surgery (Murk, Wither, Blight, Dispel,
  /// Fester, Scour, Shatter).
  static const int auxOffense = 8;

  /// Regular attacks, including Overload.
  static const int attack = 9;
}

class Spell {
  final String id;
  final String name;

  /// Charge required to cast. Casting always consumes ALL current charge.
  final int chargeCost;

  /// X-cost spells (Barrage) require at least 1 charge and scale with the
  /// full amount consumed. [chargeCost] is the minimum (1) for these.
  final bool xCost;

  /// 1–10, lower acts first.
  final int priority;

  /// Whether casting this spell grants the caster the **Haste** initiative
  /// token (see DuelEngine). Once Haste is established, only Haste-granting
  /// spells move it.
  final bool grantsHaste;

  /// Base accuracy in percent (GAME_DESIGN §1 "Combat stats"). 100 = always
  /// hits before dodge; may exceed 100 to out-pace a dodge build. Every
  /// shipped spell is 100 — low-accuracy spells are a later, deliberate design
  /// lever, never retrofitted onto the current roster.
  final int accuracy;

  final SpellEffect effect;

  const Spell({
    required this.id,
    required this.name,
    required this.chargeCost,
    required this.priority,
    required this.effect,
    this.xCost = false,
    this.grantsHaste = false,
    this.accuracy = 100,
  });

  /// Deals damage. Drives Haste establishment, Quicken eligibility, and
  /// same-priority ordering (offense before support).
  bool get isOffensive =>
      effect is DamageEffect ||
      effect is BarrageEffect ||
      effect is OverloadEffect;

  /// Negatively impacts the opponent — the design doc's "offensive spell"
  /// (TYPE_EFFECTS_DESIGN.md §1). Broader than [isOffensive]: also includes
  /// Discharge. Drives Blind misses and Stagger consumption.
  bool get isHarmful => isOffensive || effect is DischargeEffect;

  @override
  String toString() => name;
}

sealed class SpellEffect {
  const SpellEffect();
}

/// Deals [minAmount]–[maxAmount] damage per hit (rolled independently for
/// each of the [hits] hits, ~10–15% variance by design). Lifesteal heals the
/// caster for damage dealt to the enemy's health (never for damage soaked by
/// shields). [ignoresShields] bypasses shields entirely.
class DamageEffect extends SpellEffect {
  final int minAmount;
  final int maxAmount;
  final int hits;
  final double lifesteal;
  final bool ignoresShields;

  /// **Execute's finisher rider** (TYPE_EFFECTS §7a "ATTACKS"): while the
  /// target sits *strictly below* this percentage of their max HP **at impact
  /// time**, every hit of this spell is a guaranteed critical. 0 disables it,
  /// which is every other spell in the book.
  ///
  /// ⭐ A field on the damage effect rather than an effect of its own: Execute
  /// IS an attack — same band, same shields, same deflection — carrying one
  /// extra clause. A parallel class would have duplicated [DamageEffect] whole
  /// to add a single int.
  ///
  /// ⚠️ A guarantee on the ATTACKER's side, not a new kind of damage. It goes
  /// through the ordinary crit door, so Heavyhand's crit damage rides it and
  /// the defender's Composure will blank it exactly like any other crit.
  final int executeBelowPercent;

  const DamageEffect(
    this.minAmount,
    this.maxAmount, {
    this.hits = 1,
    this.lifesteal = 0,
    this.ignoresShields = false,
    this.executeBelowPercent = 0,
  });

  int get averageTotal => ((minAmount + maxAmount) * hits) ~/ 2;
}

/// X-cost multi-hit: fires **one hit per point of charge consumed**, each
/// rolling [minPerCharge]–[maxPerCharge] independently. Same total band as a
/// single big roll, but every hit is its own event — so each meets the shield,
/// spends its own Barrier point, and rolls its own crit and deflection.
class BarrageEffect extends SpellEffect {
  final int minPerCharge;
  final int maxPerCharge;

  const BarrageEffect(this.minPerCharge, this.maxPerCharge);
}

/// Raises an elemental shield of [minStrength]–[maxStrength] (rolled) in the
/// caster's charged element. Replaces any existing shield. Persists across
/// turns until depleted or replaced (players have one shield slot in v1).
class ShieldEffect extends SpellEffect {
  final int minStrength;
  final int maxStrength;

  const ShieldEffect(this.minStrength, this.maxStrength);
}

/// Adds one **Barrier point** (max 3). Each point blocks one incoming hit
/// whole, then is spent — so a multi-hit spell burns one point per hit and the
/// excess hits land. Element-less: anything pops a point, so counter maths
/// never applies.
class BarrierEffect extends SpellEffect {
  const BarrierEffect();
}

/// Caster's next offensive spell deals [multiplier]× damage.
class EmpowerEffect extends SpellEffect {
  final int multiplier;

  const EmpowerEffect([this.multiplier = 2]);
}

/// Caster's next offensive spell resolves at [priorityOverride] — e.g. 2 puts
/// it ahead of enemy shields (priority 3).
class QuickenEffect extends SpellEffect {
  final int priorityOverride;

  const QuickenEffect([this.priorityOverride = 2]);
}

/// The defensive layer a next-attack rider walks the caster's next offensive
/// spell straight through — TYPE_EFFECTS §7a, "one clean trio, one bypass
/// each".
enum AttackBypass {
  /// **Phase** (shipped): shields and Barriers.
  shields,

  /// **Pierce**: the target's Divert — deflection never even rolls.
  deflection,

  /// **Unerring**: the to-hit roll itself. Not "more accurate" — *unrolled*,
  /// so dodge, accuracy debuffs and the base miss all stop existing for one
  /// attack. ⚠️ This is the one thing in the game that gets past
  /// [CombatClamps.hitChanceFloorPercent] from the other side: the floor
  /// guarantees a defender is never unhittable, and Unerring guarantees an
  /// attacker never misses. They do not contradict, because Unerring never
  /// reaches the expression the floor clamps.
  evasion,
}

/// Caster's next offensive spell ignores one defensive layer — [bypass].
///
/// ⭐ Shipped **Phase** already was this shape, so Pierce and Unerring join it
/// as DATA rather than as new machinery (§7a: they were drafted as attacks and
/// re-ruled into riders precisely because riders combo with any attack in the
/// book — Unerring + Cataclysm is the payoff fantasy). All three persist until
/// an offensive attack consumes them; shields, aux casts and channels walk past
/// without spending them.
///
/// ⭐ Holding two riders at once is the intended combo, not a collision: law 5
/// is about a granter replacing its own status, and these are three different
/// bypasses. One attack spends every rider it is holding.
///
/// ⚠️ **The class keeps the name `PhaseEffect`.** Widening the member that
/// already models the pattern beat adding two 95%-identical siblings, and it
/// keeps the app's four sealed-switch arms as edits rather than additions.
/// `NextAttackEffect` is the name it should carry whenever the HUD lane is
/// touching those arms anyway.
class PhaseEffect extends SpellEffect {
  final AttackBypass bypass;

  const PhaseEffect([this.bypass = AttackBypass.shields]);
}

/// Removes debuffs from the caster — **Cleanse** (one, of their choice) and
/// **Purify** (all of them), TYPE_EFFECTS §7a "INSTANTS".
///
/// ⭐ One effect with a flag, not two classes: they are the same rite at two
/// price points, differing only in how much they take. Which debuff a Cleanse
/// takes is NOT here — it is a decision about a board that only exists at
/// submission time, so it rides [CastAction.statusChoice] and the wire.
///
/// ⚠️ Neither grants a status. These are the counter-web's *subtraction* side:
/// buffs and neutrals are never touched, and casting with nothing to remove is
/// a legal, resolved, entirely wasted turn.
class CleanseEffect extends SpellEffect {
  /// False = Cleanse (exactly one). True = Purify (every debuff at once).
  final bool all;

  const CleanseEffect({this.all = false});
}

/// **Meditate** (§7a): every TURN-TIMED buff the caster holds gains
/// [bonusTurns] turns.
///
/// ⚠️ **The boundary is the spell** (ruled 2026-08-26). It reaches a status
/// only if that status is both a [StatusPolarity.buff] and [TurnTimed] — so the
/// stat stances deepen, a running Tonic deepens, and the next-attack riders
/// (Phase, Pierce, Unerring) and Empower gain nothing at all, because they have
/// no clock to move. Without that second half a 2-charge spell starts banking
/// Empowers.
class MeditateEffect extends SpellEffect {
  final int bonusTurns;

  const MeditateEffect([this.bonusTurns = 5]);
}

/// Pure initiative spell: does nothing on resolve; its only effect is the
/// [Spell.grantsHaste] flag (used by Hasty).
class HasteEffect extends SpellEffect {
  const HasteEffect();
}

/// Removes ALL of the target's charge (Discharge). No damage.
class DischargeEffect extends SpellEffect {
  const DischargeEffect();
}

/// Grants the caster **Grace**: the next debuff applied to them is blocked
/// (Hallow — element-neutral, TYPE_EFFECTS §4c.4). Max 1, persists until used.
class HallowEffect extends SpellEffect {
  const HallowEffect();
}

/// One status a [StanceEffect] lands on its caster.
///
/// ⭐ **[statusId] is the collision key, and it is what makes a set a set.**
/// Two spells granting the same [statusId] are two price points on ONE status,
/// so casting either replaces whatever the other left behind — law 5, and the
/// reason this carries an id rather than letting each spell own a status.
///
/// ⚠️ [build] makes a FRESH status per cast rather than the grant holding an
/// instance: a `const` [Spell] holding a mutable status would share one ticking
/// clock across every mage in every duel in the process.
class StanceGrant {
  /// The id of the status this lands — see the class doc.
  final String statusId;

  /// Builds the status this cast lands. A `const` tear-off, one per price
  /// point (e.g. `LightfootStatus.twinkleToes`).
  final TurnStatus Function() build;

  const StanceGrant(this.statusId, this.build);
}

/// Grants the caster one or more banked **stances** — named statuses held for a
/// fixed number of turns (TYPE_EFFECTS_DESIGN.md §7a). The status classes and
/// the landing logic live in `bank_stances.dart` (`applyStance`) and
/// `bank_specials.dart`; this is only the seam the spell table and the engine's
/// effect switch meet across.
///
/// ⭐ **One effect for the whole banked generation, unified 2026-08-28.** Two
/// lanes built this shape independently — the stat stances needed a cleanse
/// rider (Truesight and Hawkeye clear Blind on cast), the special stances
/// needed more than one grant (Bloodlust is §7a's licensed exception to
/// one-status-per-axis: Keen AND Heavyhand from a single 5-charge cast). Both
/// needs are structural, neither subsumes the other, and two near-identical
/// sealed effect types would have cost every switch in the codebase a second
/// arm that meant almost the same thing. A list plus an optional rider covers
/// both, and the single-grant case — nearly every spell in the bank — is still
/// one line.
///
/// ⚠️ Grants land in list order, after the cleanse. Order matters only for the
/// log, but the log is what a player reads to learn the rule.
class StanceEffect extends SpellEffect {
  /// The statuses this cast lands, in order.
  final List<StanceGrant> grants;

  /// A status this cast also strips, and the moment logged when it does —
  /// `(statusId: 'blind', momentId: 'blindLifted')` for the Truesight set.
  ///
  /// ⭐ The cleanse lives on the SPELL, not on the status it accompanies: it is
  /// a thing the cast does once, and a mage Blinded a turn later is Blind again
  /// with their Truesight still running. On the status it would quietly become
  /// a Blind immunity, which is a different spell.
  ///
  /// ⚠️ One record rather than two nullable fields, because the pair must
  /// travel together: a cleanse with no moment id logs nothing and a moment id
  /// with nothing to cleanse fires on empty air.
  final ({String statusId, String momentId})? cleanses;

  const StanceEffect(this.grants, {this.cleanses});
}

/// A full attack (respects shields, benefits from Empower/Phase) whose damage
/// is a single roll of [minPerCharge]–[maxPerCharge] multiplied by the
/// **target's** charge at the moment of resolution (Overload). Deals 0 if the
/// target has no charge.
class OverloadEffect extends SpellEffect {
  final int minPerCharge;
  final int maxPerCharge;

  const OverloadEffect(this.minPerCharge, this.maxPerCharge);
}
