/// The bank's **DoT engine and debuff suite** — TYPE_EFFECTS_DESIGN.md §7a.
///
/// Eleven spells in one lane: two DoT attacks (Agony, Torment), the two
/// instants that feed and collect them (Fester, Scour), the anti-accuracy and
/// anti-heal sets (Murk/Miasma, Wither/Atrophy, Blight), and the two strippers
/// (Dispel, Shatter).
///
/// ⭐ **Element-agnostic, by law** (§7a law 1). Nothing here names a status:
/// Fester and Scour act on [DamageOverTime], Dispel on [StatusPolarity.buff],
/// Shatter on whatever contributes to the Divert stats. Ignite therefore joined
/// all three the moment it declared the interface, and so will the next burn
/// anyone writes.
///
/// ⚠️ **Why these effects subclass shipped ones.** [SpellEffect] is `sealed`,
/// so a new direct subtype can only be declared in `spell.dart` — and every
/// exhaustive `switch (spell.effect)` in the app would stop compiling the
/// moment one appeared. The bank's damage riders therefore extend
/// [DamageEffect] and its no-damage enemy-facing spells extend
/// [DischargeEffect] — the shipped "harmful, deals no damage, targets the
/// enemy" shape they genuinely are a generation of, and one that already sits
/// at [SpellPriority.auxOffense]. Presentation reads them as the shipped kinds
/// until the app lane gives the bank its own copy.
library;

import 'combat_stats.dart';
import 'mage.dart';
import 'spell.dart';
import 'status.dart';

// ===========================================================================
// STATUSES
// ===========================================================================

/// Common shape for the bank's timed debuffs: a turn counter that starts on
/// the turn the status lands (the same "applies now, counts now" cadence
/// Ignite and Regrow already follow) and winds down in the end phase's
/// bookkeeping band.
abstract class TimedDebuffStatus extends TurnStatus {
  int turnsLeft;

  TimedDebuffStatus(this.turnsLeft);

  @override
  StatusPolarity get polarity => StatusPolarity.debuff;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

/// A spell-lane damage-over-time: [damagePerTick] at the end of each of
/// [ticksLeft] turns, the first of them being the turn it lands (Ignite's
/// convention).
///
/// ⭐ **One class, several statuses.** Agony and Torment differ only in id,
/// name and numbers, and every rule that matters — replace-on-recast, ticking
/// concurrently with each other and with Ignite, being fed by Fester and
/// collected by Scour — is a rule about DoTs, not about either of them. A
/// third one costs a row in the spellbook and nothing else.
class BankDotStatus extends TimedDebuffStatus implements DamageOverTime {
  @override
  final String id;

  /// Player-facing name, used as the tick's log source ('Agony').
  final String name;

  @override
  final int damagePerTick;

  BankDotStatus({
    required this.id,
    required this.name,
    required this.damagePerTick,
    required int ticks,
  }) : super(ticks);

  @override
  int get ticksLeft => turnsLeft;

  @override
  void addTicks(int count) => turnsLeft += count;

  /// ⚠️ Element-agnostic damage (`element: null`): the burn belongs to no
  /// element, so shield counter maths never applies to it — only the raw
  /// shield. The spell that applied it took the caster's element; the bleed it
  /// leaves behind is just a bleed.
  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.end
          ? [StatusDamage(damagePerTick, lane: Lane.damage, source: name)]
          : const [];
}

/// **Murk** — the holder's own accuracy is reduced while it lasts. One status
/// for the whole set (Murk 1c, Miasma 3c): last cast wins, magnitude and
/// duration together (§7a law 5).
///
/// ⭐ A [StatModifier] with a NEGATIVE contribution, which is the whole reason
/// contributions are signed: it stacks across lanes with the element lane's
/// Blind and with a Truesight buff, all summed into one hit roll and clamped
/// once at the output.
class MurkStatus extends TimedDebuffStatus implements StatModifier {
  /// Negative — accuracy points removed.
  final int accuracyPercent;

  MurkStatus({required this.accuracyPercent, required int turns})
      : super(turns);

  @override
  String get id => 'murk';

  @override
  int contributionTo(CombatStat stat) =>
      stat == CombatStat.accuracy ? accuracyPercent : 0;
}

/// **Wither** — healing this mage receives is taxed by [healingReceivedPercent]
/// (always −50 by ruling: the tier 2, Atrophy, buys triple duration and never
/// more depth). Applies to every heal in the game, because they all walk
/// through [MageState.heal].
class WitherStatus extends TimedDebuffStatus implements HealingModifier {
  /// Always [witherPercent] today; carried as a field so a future tier can be
  /// priced without a new status.
  @override
  final int healingReceivedPercent;

  /// The ruled magnitude: −50%, at every price point.
  static const int witherPercent = -50;

  WitherStatus({this.healingReceivedPercent = witherPercent, required int turns})
      : super(turns);

  @override
  String get id => 'wither';
}

/// **Blight** — binary: the holder's heals deal DAMAGE instead of healing.
/// HoTs, potions, Regrow, Photosynthesis, and the lifesteal heal-back (the
/// drain's damage still lands; its heal bites its caster).
///
/// ⭐ Supersedes Wither entirely while both are up — see [MageState.heal].
class BlightStatus extends TimedDebuffStatus implements HealInverting {
  BlightStatus({required int turns}) : super(turns);

  @override
  String get id => 'blight';
}

// ===========================================================================
// SPELL EFFECTS
// ===========================================================================

/// An attack that also applies a DoT: full damage on the hit (normal to-hit
/// and crit rules), then the burn. The rider is a debuff, so Grace blocks it —
/// but never the damage, which is not.
class DotAttackEffect extends DamageEffect {
  final String dotId;
  final String dotName;
  final int damagePerTick;
  final int ticks;

  const DotAttackEffect(
    super.minAmount,
    super.maxAmount, {
    required this.dotId,
    required this.dotName,
    required this.damagePerTick,
    required this.ticks,
  });
}

/// Base of the **aux-offense** lane ([SpellPriority.auxOffense]): spells that
/// target the enemy but are not attacks.
///
/// ⭐ **No to-hit roll.** Aux-offense resolves or it does not; if it resolves,
/// its statuses land, subject only to Grace. Dodge, accuracy and Blind are the
/// attack lane's currency, and a 1-charge debuff that whiffed against a dodge
/// build would simply never be cast. The engine skips the hit gate for
/// anything extending this.
class AuxOffenseEffect extends DischargeEffect {
  const AuxOffenseEffect();
}

/// Which debuff a [DebuffGrantEffect] grants. Data, not a constructor
/// reference, so the whole spellbook stays `const`.
enum BankDebuff { murk, wither, blight }

/// Applies one of the bank's timed debuffs to the enemy. Replace-on-cast:
/// magnitude and duration together, last cast wins.
class DebuffGrantEffect extends AuxOffenseEffect {
  final BankDebuff debuff;

  /// The status's headline number (Murk's accuracy points, Wither's healing
  /// percent — both negative). 0 for binary debuffs like Blight.
  final int magnitude;

  final int turns;

  const DebuffGrantEffect(this.debuff,
      {this.magnitude = 0, required this.turns});

  TimedDebuffStatus buildStatus() => switch (debuff) {
        BankDebuff.murk =>
          MurkStatus(accuracyPercent: magnitude, turns: turns),
        BankDebuff.wither =>
          WitherStatus(healingReceivedPercent: magnitude, turns: turns),
        BankDebuff.blight => BlightStatus(turns: turns),
      };
}

/// **Fester** — a small hit, then every DoT on the target gains [bonusTicks].
/// Never names a status: it iterates DoT-ness, so Ignite and anything future
/// are fed for free.
class FesterEffect extends AuxOffenseEffect {
  final int damage;
  final int bonusTicks;

  const FesterEffect({required this.damage, required this.bonusTicks});
}

/// **Scour** — every DoT on the target pays out all its remaining ticks NOW,
/// as ONE combined packet, and the statuses are consumed. One packet means one
/// shield interaction and one deflection roll.
class ScourEffect extends AuxOffenseEffect {
  const ScourEffect();
}

/// **Dispel** — strips every strippable buff-polarity status from the target,
/// plus the pending next-attack riders it carries as fields.
class DispelEffect extends AuxOffenseEffect {
  const DispelEffect();
}

/// **Shatter** — no damage. Clears the target's shield, every Barrier point,
/// and the Divert family of statuses. The turtle-breaker.
class ShatterEffect extends AuxOffenseEffect {
  const ShatterEffect();
}

/// Whether [status] is a member of the **Divert family** — anything granting
/// deflection, by contribution rather than by name. Shatter's target list, and
/// the one place that definition lives.
bool isDivertFamily(TurnStatus status) =>
    status is StatModifier &&
    ((status as StatModifier).contributionTo(CombatStat.deflectActivation) !=
            0 ||
        (status as StatModifier).contributionTo(CombatStat.deflectAmount) != 0);
