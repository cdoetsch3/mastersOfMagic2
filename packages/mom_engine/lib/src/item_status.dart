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

/// A finite heal-over-time — the Tonic shape (ITEMS §9b.8: 9% × 3 turns).
///
/// 📝 Nothing in the duel APPLIES this yet: using a belt item as a turn
/// action is unbuilt. The primitive ships first so the belt work lands on a
/// tested tick instead of inventing one under UI pressure.
class HealOverTimeStatus extends TurnStatus {
  /// Percent of max HP restored at the end of each remaining turn.
  final int percentPerTurn;

  /// What granted it — the log line says the item's name, not "a status".
  final String source;

  int turnsLeft;

  HealOverTimeStatus({
    required this.percentPerTurn,
    required this.turnsLeft,
    this.source = 'Tonic',
  });

  @override
  String get id => 'healOverTime';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    if (phase != TurnPhase.end || turnsLeft <= 0 || percentPerTurn <= 0) {
      return const [];
    }
    final heal = (holder.maxHp * percentPerTurn / 100).round();
    return [StatusHeal(heal < 1 ? 1 : heal, lane: Lane.heal, source: source)];
  }

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}
