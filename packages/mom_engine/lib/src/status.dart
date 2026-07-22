import 'element.dart';
import 'mage.dart';

/// The three resolution phases of a turn. **Start** and **End** each own a
/// separate priority lane (S1–S10 / E1–E10) that never mixes with **Main**
/// (committed spell priority) or with each other — see TYPE_EFFECTS_DESIGN.md
/// §5.1. Survivability-first: within a phase, heals resolve before damage
/// before bookkeeping, enforced by giving heals lower lane numbers.
enum TurnPhase { start, main, end }

/// Conventional lane bands within a start/end phase (1 = earliest). Heals
/// land early so a burning-but-regenerating mage heals before the tick.
abstract final class Lane {
  static const int heal = 2; // E1–E3 band
  static const int damage = 8; // E4–E8 band
  static const int bookkeeping = 9; // E9–E10 band (handled by expiry sweep)
}

/// A declarative operation a [TurnStatus] performs during a start/end phase.
/// The engine executes these so shield/heal/death logic stays centralized in
/// one place (and identical on both lockstep clients).
sealed class StatusOp {
  /// Lane priority within the phase (1 = earliest).
  final int lane;

  /// Short label for the emitted event (e.g. 'Ignite', 'Photosynthesis').
  final String source;

  const StatusOp(this.lane, this.source);
}

/// Damage the status's holder. [element] enables shield counter math (null =
/// element-agnostic, never counters); [bypassShield] skips shields entirely.
class StatusDamage extends StatusOp {
  final int amount;
  final MagicElement? element;
  final bool bypassShield;

  const StatusDamage(
    this.amount, {
    int lane = Lane.damage,
    String source = 'status',
    this.element,
    this.bypassShield = false,
  }) : super(lane, source);
}

/// Heal the status's holder by [amount] (clamped to max hp).
class StatusHeal extends StatusOp {
  final int amount;

  const StatusHeal(
    this.amount, {
    int lane = Lane.heal,
    String source = 'status',
  }) : super(lane, source);
}

/// Marker for statuses that can make the holder's offensive spells miss
/// (Sanctus's Blind — moves to Solar in Phase 3). The engine rolls [missChance] at each offensive cast; a
/// miss resolves to no effect (charge still spent). Multiple blinders use the
/// highest chance. See TYPE_EFFECTS_DESIGN.md §4.1.
abstract interface class Blinding {
  double get missChance;
}

/// A persistent status on a mage, resolved each turn's start and end phases.
///
/// Statuses are pure data + timing: they declare *what* they want to do via
/// [operationsFor]; the [DuelEngine] executes it (applying shields, deaths,
/// and the Haste tiebreak uniformly). Bookkeeping — advancing duration or
/// stacks and expiring — happens in [advanceAndCheckExpiry] after all ops in
/// the end phase.
abstract class TurnStatus {
  /// Stable id; also used to find/refresh an existing status of the same kind.
  String get id;

  /// Operations to perform in [phase] this turn, evaluated against the
  /// holder's current state. Empty for phases this status ignores.
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder);

  /// End-of-turn bookkeeping (runs after all end-phase ops): advance
  /// duration/stacks and return true when the status should be removed.
  /// [holder] enables activity-based decay (e.g. Photosynthesis de-stacks on
  /// turns without Flora activity — see [MageState.activeElementThisTurn]).
  bool advanceAndCheckExpiry(MageState holder);
}
