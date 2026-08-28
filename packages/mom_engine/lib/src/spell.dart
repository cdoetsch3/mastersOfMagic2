/// Spell definitions.
///
/// Spells are element-agnostic: a spell takes on the element the caster is
/// currently charged with. Priority is 1–10; lower priority acts earlier in
/// the turn — see [SpellPriority] for the named ladder.
library;

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

  const DamageEffect(
    this.minAmount,
    this.maxAmount, {
    this.hits = 1,
    this.lifesteal = 0,
    this.ignoresShields = false,
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
