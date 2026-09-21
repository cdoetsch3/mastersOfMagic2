/// Statuses granted by ITEMS rather than elements (ITEMS §9b.8).
///
/// ⭐ Same [TurnStatus] machinery as the element statuses — the lane sort,
/// the haste tiebreak and lockstep determinism all come for free, which is
/// the whole reason gear routes through statuses instead of ad-hoc hooks.
library;

import 'mage.dart';
import 'status.dart';

/// A permanent end-of-turn heal from worn gear — The Charlock's stat.
///
/// ⚠️ **Never expires on its own**: it exists because an item is worn, and
/// the wearer cannot change clothes mid-duel. Healing received bonuses apply
/// on top (they live in [MageState.heal]).
class RegrowStatus extends TurnStatus {
  /// Percent of max HP restored at the end of every turn.
  final int percentPerTurn;

  RegrowStatus(this.percentPerTurn);

  // ⚠️ Deliberately NOT [TurnTimed]: it has no clock to extend. Meditate must
  // find nothing here — a worn item's heal is already permanent, and "+5 turns"
  // on a thing that never ends is either a no-op or a bug.

  /// ⚠️ Genuinely ambiguous, ruled **buff**: polarity answers "is this good for
  /// the holder", and it plainly is. Whether Dispel may strip a status the
  /// wearer's *gear* is generating is a separate question — a lane question,
  /// for the Dispel spell to answer when it lands — and encoding "unstrippable"
  /// as `neutral` here would also hide it from every future spell that reads
  /// polarity for a non-strip reason.
  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  String get id => 'regrow';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    if (phase != TurnPhase.end || percentPerTurn <= 0) return const [];
    // ⭐ At least 1, matching ItemEffect.healFor — a stat that visibly does
    // nothing at low levels reads as a bug.
    final heal = (holder.maxHp * percentPerTurn / 100).round();
    return [StatusHeal(heal < 1 ? 1 : heal, lane: Lane.heal, source: 'Regrow')];
  }

  @override
  bool advanceAndCheckExpiry(MageState holder) => false;
}

/// A finite heal-over-time — the Tonic shape (ITEMS §9b.8: 10 health × 3
/// turns).
///
/// ⭐ **Flat health per turn, not a percentage** (ruling 2026-09-21). The only
/// thing that grants this is a belt consumable, and a potion is a fixed object
/// — so unlike [RegrowStatus] (worn gear) and `MendingStatus` (a spell), which
/// stay percentages of the holder, this one carries the bottle's own number.
/// ⚠️ That asymmetry is the ruling, not an oversight: the three lanes are
/// priced against different things.
class HealOverTimeStatus extends TurnStatus implements TurnTimed {
  /// Health restored at the end of each remaining turn.
  final int healPerTurn;

  /// What granted it — the log line says the item's name, not "a status".
  final String source;

  @override
  int turnsLeft;

  HealOverTimeStatus({
    required this.healPerTurn,
    required this.turnsLeft,
    this.source = 'Tonic',
  });

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  void extendTurns(int turns) => turnsLeft += turns;

  @override
  String get id => 'healOverTime';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    if (phase != TurnPhase.end || turnsLeft <= 0 || healPerTurn <= 0) {
      return const [];
    }
    // ⚠️ No max-HP term and so no 1-HP floor: the tick IS the number, and a
    // catalogue shipping a positive rate has already promised at least 1.
    return [StatusHeal(healPerTurn, lane: Lane.heal, source: source)];
  }

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}
