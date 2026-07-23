/// Spell definitions.
///
/// Spells are element-agnostic: a spell takes on the element the caster is
/// currently charged with. Priority is 1–10; lower priority acts earlier in
/// the turn (1 = instant attacks, 3 = shields, 4 = channel, 5 = quick attacks,
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

  const DamageEffect(
    this.minAmount,
    this.maxAmount, {
    this.hits = 1,
    this.lifesteal = 0,
    this.ignoresShields = false,
  });

  int get averageTotal => ((minAmount + maxAmount) * hits) ~/ 2;
}

/// X-cost damage: deals [minPerCharge]–[maxPerCharge] × (charge consumed),
/// rolled once.
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

/// A full attack (respects shields, benefits from Empower/Phase) whose damage
/// is a single roll of [minPerCharge]–[maxPerCharge] multiplied by the
/// **target's** charge at the moment of resolution (Overload). Deals 0 if the
/// target has no charge.
class OverloadEffect extends SpellEffect {
  final int minPerCharge;
  final int maxPerCharge;

  const OverloadEffect(this.minPerCharge, this.maxPerCharge);
}
