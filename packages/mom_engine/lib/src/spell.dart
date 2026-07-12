/// Spell definitions.
///
/// Spells are element-agnostic: a spell takes on the element the caster is
/// currently charged with. Priority is 1–10; lower priority acts earlier in
/// the turn (1 = instant attacks, 3 = shields, 5 = quick attacks,
/// 7 = aux/other defensive, 9 = regular spells).
library;

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

  final SpellEffect effect;

  const Spell({
    required this.id,
    required this.name,
    required this.chargeCost,
    required this.priority,
    required this.effect,
    this.xCost = false,
  });

  bool get isOffensive =>
      effect is DamageEffect || effect is BarrageEffect;

  @override
  String toString() => name;
}

sealed class SpellEffect {
  const SpellEffect();
}

/// Deals [amount] damage per hit, [hits] times. Lifesteal heals the caster
/// for damage dealt to the enemy's health (never for damage soaked by
/// shields). [ignoresShields] bypasses shields entirely.
class DamageEffect extends SpellEffect {
  final int amount;
  final int hits;
  final double lifesteal;
  final bool ignoresShields;

  const DamageEffect(
    this.amount, {
    this.hits = 1,
    this.lifesteal = 0,
    this.ignoresShields = false,
  });
}

/// X-cost damage: deals [damagePerCharge] × (charge consumed).
class BarrageEffect extends SpellEffect {
  final int damagePerCharge;

  const BarrageEffect(this.damagePerCharge);
}

/// Raises an elemental shield of [strength] in the caster's charged element.
/// Replaces any existing shield. Persists across turns until depleted or
/// replaced (players have one shield slot in v1).
class ShieldEffect extends SpellEffect {
  final int strength;

  const ShieldEffect(this.strength);
}

/// Blocks 100% of one incoming hit, then disappears. Element-less: never
/// takes counter damage. (Multi-hit spells: only the first hit is absorbed.)
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

/// Caster's next offensive spell ignores shields.
class PhaseEffect extends SpellEffect {
  const PhaseEffect();
}
