/// The **special stances and the sustain line** — the half of the banked
/// generation that changes a RULE rather than a number
/// (TYPE_EFFECTS_DESIGN.md §7a): Steadfast, Composure, Death Wish, Reflect,
/// and the Mending line (Mend / Renewal). Bloodlust lives here too, and grants
/// the stat lane's Keen and Heavyhand.
///
/// ⭐ **The sibling of `bank_stances.dart`, and deliberately a separate file.**
/// Those five sets all do one thing — contribute a signed number to a
/// [CombatStat] — which is why they share a base class and a [StatModifier]
/// implementation. These do not: Composure rewrites how a crit resolves,
/// Reflect turns a deflect into damage, Mending ticks in the end phase, and
/// only Steadfast moves a number at all (and not one [CombatStat] models). They
/// share the *landing* rules, which is why they come through the same
/// [applyStance], and nothing else.
///
/// ⭐ **Every one is an ordinary [TurnStatus] with [StatusPolarity.buff]** —
/// law 3. They inherit the pip HUD, the lockstep serialization, the lane sort,
/// and (for free, the moment that spell lands) Dispel's strip list. Nothing
/// here writes a number into [MageState]: Steadfast contributes through
/// [ShieldStrengthModifier] and the engine re-adds the sum at every shield
/// roll.
///
/// ⭐ **Replace-on-cast, last cast wins** — law 5, enforced in one place for
/// both banked lanes by [applyStance], which removes any status of the granted
/// id before adding the new one. Magnitude and duration therefore always
/// travel together, and a same-spell recast is simply a refresh.
library;

import 'bank_stances.dart';
import 'combat_stats.dart';
import 'mage.dart';
import 'status.dart';

/// The shared shape of a special stance: a turn-timed, self-granted status that
/// runs its clock down and describes itself for the log.
///
/// ⚠️ **The clock decrements in the end phase of the turn the stance is cast**,
/// exactly like Ignite's three ticks and like [StatStanceStatus] — a 25-turn
/// stance covers the rest of this turn and 24 more. Every duration in §7a is
/// written against that cadence, and it is what lets a priority-7 stance shape
/// the priority-8 and -9 spells that follow it in the same turn.
abstract class BankedStance extends TurnStatus implements StanceDescribing {
  @override
  int turnsLeft;

  BankedStance(this.turnsLeft);

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  /// Most of these never tick: they are read, not run. Mending is the one
  /// exception, and overrides.
  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

// ---- Steadfast — own shield strength ------------------------------------

/// **Steadfast** (3c): shields this mage raises are `+percent`% stronger, 25
/// turns.
///
/// ⭐ **Ruled: the bonus applies at GAIN TIME, not continuously.** A shield's
/// strength is a *pool*, rolled and banked into [ActiveShield.remaining] the
/// moment it is raised; it is the one defensive number the engine stores rather
/// than derives, because hits spend it down. So Steadfast rides the same line
/// gear's [MageState.shieldStrengthPercent] already rides — into the roll, once
/// — and the pool it produces is thereafter just a pool.
///
/// The rejected alternative, scaling the *standing* pool while the buff is up,
/// is what "derivation, not mutation" is warning about rather than an example
/// of it: `remaining` is a running balance, so re-deriving it every hit would
/// have to reconstruct how much of the shield had already been spent, and the
/// buff falling off mid-fight would shrink a partly-spent shield by 20% of a
/// number that no longer means what it did when the multiplier was applied. It
/// also hands Steadfast a strictly better version of itself — cast the shield
/// first, the stance second, and get the bonus retroactively.
///
/// The consequence is the ledger entry: **Steadfast expiring leaves shields
/// already standing exactly as they were.** You bought stronger shields for 25
/// turns, not a temporary coat of paint on the one you have.
///
/// ⚠️ [ShieldStrengthModifier], not [StatModifier] — shield strength is a
/// percent multiplier on a rolled pool, applied once, where a [CombatStat]
/// promises a signed sum re-read at every roll. Same seam, same derivation
/// rule, different semantic; see combat_stats.dart.
class SteadfastStatus extends BankedStance implements ShieldStrengthModifier {
  /// Percent added to the strength of every shield raised while this is up.
  final int percent;

  SteadfastStatus({required this.percent, required int turns}) : super(turns);

  /// The 3-cost price point: +25% shield strength, 25 turns.
  static SteadfastStatus steadfast() =>
      SteadfastStatus(percent: 25, turns: 25);

  @override
  String get id => 'steadfast';

  @override
  int get shieldStrengthContribution => percent;

  @override
  String get grantLine => 'shields you raise are +$percent% stronger';
}

// ---- Composure — the crit blanket ---------------------------------------

/// Marker for anything that makes incoming crits resolve as normal hits.
///
/// ⚠️ An interface rather than an `is ComposureStatus` check in the engine, so
/// the rule reads as a rule. §7a's counter-web hangs the whole crit lane —
/// Keen, Heavyhand, Execute, Death Wish — on "blanked by Composure"; a second
/// source of that blanket (a relic, an enemy innate) should join by
/// implementing this, not by editing `_attack`.
abstract interface class CritBlanking {}

/// **Composure** (2c): incoming crits resolve as normal hits, 25 turns.
class ComposureStatus extends BankedStance implements CritBlanking {
  ComposureStatus({required int turns}) : super(turns);

  /// The 2-cost price point: 25 turns.
  static ComposureStatus composure() => ComposureStatus(turns: 25);

  @override
  String get id => 'composure';

  @override
  String get grantLine => 'incoming crits land as normal hits';
}

/// Whether [defender] blanks the crits aimed at them.
bool blanksIncomingCrits(MageState defender) =>
    defender.statuses.any((s) => s is CritBlanking);

// ---- Bloodlust — the licensed two-status exception -----------------------

/// Bloodlust's **Keen**: +20% crit chance for 12 turns.
///
/// ⭐ A price point on the stat lane's [KeenStatus], deliberately — not a
/// second crit-chance status of this lane's own. §7a licenses Bloodlust to
/// break one-status-per-axis by granting TWO statuses, not by inventing a
/// parallel axis; keeping the class shared is what makes the collision real, so
/// a standing Ardent (+25%) is genuinely overwritten by this weaker, shorter
/// burst. The exception buys a window, not a floor.
///
/// ⚠️ A top-level function so the tear-off is a constant expression and the
/// [Spell] can stay `const`.
KeenStatus bloodlustKeen() => KeenStatus(critChance: 20, turns: 12);

/// Bloodlust's **Heavyhand**: +40 crit damage for 12 turns. See
/// [bloodlustKeen] for why this lives here and grants the stat lane's class.
HeavyhandStatus bloodlustHeavyhand() =>
    HeavyhandStatus(critDamage: 40, turns: 12);

// ---- Death Wish — the desperation stance --------------------------------

/// Marker for anything that can make the holder's attacks crit without a roll.
abstract interface class GuaranteedCritSource {
  /// Whether the guarantee is live right now, for this [holder].
  bool guaranteesCritFor(MageState holder);
}

/// **Death Wish** (2c): while the holder's OWN health is below 15% of max,
/// every attack they land crits. 10 turns.
///
/// ⚠️ **Below, strictly** — at exactly 15% the guarantee is not yet on. Kept as
/// integer cross-multiplication (`hp * 100 < maxHp * 15`) rather than a double
/// ratio: both lockstep clients must agree on the boundary, and floating point
/// at 15.000000000000002% is not an agreement.
class DeathWishStatus extends BankedStance implements GuaranteedCritSource {
  /// The health threshold, in percent of max.
  static const int thresholdPercent = 15;

  DeathWishStatus({required int turns}) : super(turns);

  /// The 2-cost price point: 10 turns.
  static DeathWishStatus deathWish() => DeathWishStatus(turns: 10);

  @override
  String get id => 'deathWish';

  @override
  bool guaranteesCritFor(MageState holder) =>
      holder.hp * 100 < holder.maxHp * thresholdPercent;

  @override
  String get grantLine =>
      'your attacks always crit below $thresholdPercent% health';
}

/// Whether every hit [attacker] lands this instant is a crit before any roll.
bool attacksAlwaysCrit(MageState attacker) {
  for (final s in attacker.statuses) {
    if (s is GuaranteedCritSource &&
        (s as GuaranteedCritSource).guaranteesCritFor(attacker)) {
      return true;
    }
  }
  return false;
}

// ---- Reflect — the deflect mirror ---------------------------------------

/// Marker for anything that returns deflected damage to its sender.
abstract interface class DamageReflecting {
  /// Percent of the deflected amount that comes back.
  int get returnPercent;
}

/// **Reflect** (4c): when the holder deflects damage, 100% of what the deflect
/// REMOVED is dealt back to the attacker. 25 turns.
///
/// ⚠️ **A dead slot without a Divert-family source underneath it** — Reflect
/// multiplies a deflect, so with no deflect it is 4 charge for nothing. That is
/// the design (§7a calls it "the first status with a hard dependency"), and it
/// is why the spell is priced where it is rather than lower. [DivertStatus] is
/// the spell-lane source; gear and enemy innates are the others.
///
/// ⭐ **The return is DAMAGE, not a hit.** It resolves shield-first on the
/// attacker like any other damage, and that is all: no accuracy roll, no crit,
/// no procs — and, decisively, **it cannot itself be deflected**, so two mages
/// both holding Divert + Reflect cannot ping a hit back and forth forever. The
/// engine enforces that structurally by routing the return through the raw
/// damage door rather than through the attack pipeline; there is no re-reflect
/// branch to get the condition wrong in.
class ReflectStatus extends BankedStance implements DamageReflecting {
  ReflectStatus({required int turns}) : super(turns);

  /// The 4-cost price point: 25 turns.
  static ReflectStatus reflect() => ReflectStatus(turns: 25);

  @override
  String get id => 'reflect';

  /// Ruled 2026-08-26: the full deflected amount. With a Divert at 20/40 that
  /// is an expected 8% of incoming damage returned per hit; at the 90/90 clamps
  /// it is 81%, which is exactly why those clamps exist.
  @override
  int get returnPercent => 100;

  @override
  String get grantLine => 'damage you deflect is returned to its sender';
}

/// What [defender] sends back to their attacker having just deflected
/// [deflected] damage — 0 when nothing they hold reflects.
///
/// Integer arithmetic throughout, so both lockstep clients land on the same
/// number. Multiple reflectors would sum; there is only one today.
int reflectedAmount(MageState defender, int deflected) {
  if (deflected <= 0) return 0;
  var total = 0;
  for (final s in defender.statuses) {
    if (s is DamageReflecting) {
      total += deflected * (s as DamageReflecting).returnPercent ~/ 100;
    }
  }
  return total;
}

// ---- Mending — the spell lane's heal over time --------------------------

/// **Mending**: heals [percentPerTurn]% of max HP at the end of each turn.
/// Mend (2c) grants 3%/6 turns = 18% total; Renewal (4c) grants 5%/10 turns =
/// 50% total.
///
/// ⭐ **One Mending, in the SPELL lane** (law 4). A belt Tonic
/// ([HealOverTimeStatus]) and Flora's Photosynthesis are different lanes with
/// different ids, so all three tick side by side in the same end-phase heal
/// band — different currencies may pay twice. What may not happen twice is two
/// Mendings: Renewal cast over a running Mend replaces rate *and* duration
/// together, and never keeps the better half of each.
///
/// ⚠️ The one stance in this file that runs rather than being read, which is
/// why it overrides [operationsFor].
class MendingStatus extends BankedStance {
  /// Percent of max HP restored at the end of each remaining turn.
  final int percentPerTurn;

  MendingStatus({required this.percentPerTurn, required int turns})
      : super(turns);

  /// Mend, the 2-cost price point: 3%/turn for 6 turns (18% total).
  static MendingStatus mend() => MendingStatus(percentPerTurn: 3, turns: 6);

  /// Renewal, the 4-cost price point: 5%/turn for 10 turns (50% total).
  /// Retuned down at design time to sit just under the equivalent-cost
  /// shields — a heal that beats a wall makes the wall pointless.
  static MendingStatus renewal() =>
      MendingStatus(percentPerTurn: 5, turns: 10);

  @override
  String get id => 'mending';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    if (phase != TurnPhase.end || turnsLeft <= 0 || percentPerTurn <= 0) {
      return const [];
    }
    // ⭐ At least 1, matching Regrow and the Tonic: a heal that visibly does
    // nothing at low levels reads as a bug rather than as rounding.
    final heal = (holder.maxHp * percentPerTurn / 100).round();
    return [
      StatusHeal(heal < 1 ? 1 : heal, lane: Lane.heal, source: 'Mending')
    ];
  }

  @override
  String get grantLine => 'heals $percentPerTurn% of max health per turn';
}
