import 'element.dart';

/// A raised shield occupying the mage's (single, in v1) shield slot.
class ActiveShield {
  /// Null for barriers, which are element-less.
  final MagicElement? element;

  int remaining;

  final bool isBarrier;

  ActiveShield.elemental(MagicElement this.element, this.remaining)
      : isBarrier = false;

  ActiveShield.barrier()
      : element = null,
        remaining = 0,
        isBarrier = true;

  @override
  String toString() =>
      isBarrier ? 'Barrier' : '${element!.name} shield ($remaining)';
}

/// Mutable per-duel state of one combatant (player or monster — same rules).
class MageState {
  final String name;
  final int maxHp;
  int hp;

  /// 0–5. At 0 the mage must choose an element before (or while) acting.
  int charge = 0;

  /// The element of the current charging cycle. Null whenever charge is 0
  /// and no cast is in flight.
  MagicElement? element;

  ActiveShield? shield;

  // Pending aux buffs, consumed by the next offensive spell cast.
  int? empowerMultiplier;
  int? quickenPriority;
  bool phaseNext = false;

  MageState({required this.name, this.maxHp = 100}) : hp = maxHp;

  bool get alive => hp > 0;

  static const int maxCharge = 5;

  void takeHpDamage(int amount) {
    hp = (hp - amount).clamp(0, maxHp);
  }

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  /// Consumes and returns the pending offensive buffs.
  ({int multiplier, bool phase}) consumeOffensiveBuffs() {
    final result = (multiplier: empowerMultiplier ?? 1, phase: phaseNext);
    empowerMultiplier = null;
    phaseNext = false;
    return result;
  }
}
