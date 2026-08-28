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

/// Resolve **Absolution** on the holder (Sanctus — TYPE_EFFECTS §4c). Runs in
/// the heal band (E1–E3) so a purged burn never gets its E8 tick. The engine
/// handles it (it needs the shared RNG for the random purge, and the opponent
/// for the Creeping-Dark strip), so this op carries no data of its own.
class StatusPurge extends StatusOp {
  const StatusPurge({int lane = Lane.heal, String source = 'Absolution'})
      : super(lane, source);
}

/// Marker for statuses that can make the holder's offensive spells miss
/// (Blind — Solar in the V2 roster). The engine rolls [missChance] at each
/// offensive cast; a miss resolves to no effect (charge still spent). Multiple
/// blinders use the highest chance. See TYPE_EFFECTS_DESIGN.md §4b.1.
abstract interface class Blinding {
  double get missChance;
}

/// Whether a status is good for its holder, bad for them, or neither.
///
/// ⭐ **The hook the whole counter-web hangs off** (TYPE_EFFECTS §7a law 3).
/// Dispel strips [buff]s, Cleanse and Purify remove [debuff]s, Absolution
/// purges a random [debuff], and Grace blocks the next [debuff] to land. None
/// of those spells knows what a Lightfoot or an Agony *is* — they ask polarity
/// and act, which is why a new status joins the web for free.
///
/// ⚠️ It replaced a bare `Debuff` marker interface. A marker could only say
/// "bad"; the third state has to be sayable, because "neither" is a real answer
/// (see [PendingAbsolutionStatus]) and a status that silently defaults to
/// strippable is a balance bug nobody sees until a Dispel eats it.
enum StatusPolarity {
  /// Good for whoever holds it. Dispel's pool.
  buff,

  /// Bad for whoever holds it. Cleanse/Purify/Absolution's pool; Grace
  /// prevents these.
  debuff,

  /// Neither — scaffolding, markers, and bookkeeping that no polarity-driven
  /// spell should be able to touch in either direction.
  neutral,
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

  /// Good for the holder, bad for them, or neither — see [StatusPolarity].
  ///
  /// ⚠️ **Abstract on purpose, with no default.** A default of `neutral` would
  /// let every future status opt out of the counter-web by forgetting a line,
  /// and the failure mode is silent: Dispel and Purify would simply never find
  /// it. Making the compiler ask the question is the cheapest possible guard.
  StatusPolarity get polarity;

  /// Operations to perform in [phase] this turn, evaluated against the
  /// holder's current state. Empty for phases this status ignores.
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder);

  /// End-of-turn bookkeeping (runs after all end-phase ops): advance
  /// duration/stacks and return true when the status should be removed.
  /// [holder] enables activity-based decay (e.g. Creeping Dark sheds a stack
  /// on turns without Umbra activity — see [MageState.activeElementThisTurn])
  /// and streak-gated expiry (Photosynthesis ends when the run breaks).
  bool advanceAndCheckExpiry(MageState holder);
}
