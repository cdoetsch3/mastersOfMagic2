import 'element.dart';
import 'mage.dart';
import 'spell.dart';

/// Things that happened during a turn, in resolution order. The UI renders
/// these; tests assert on them; the simulator can print them as a log.
sealed class DuelEvent {
  const DuelEvent();
}

class ChargedEvent extends DuelEvent {
  final MageState mage;
  final MagicElement element;
  final int newCharge;

  const ChargedEvent(this.mage, this.element, this.newCharge);

  @override
  String toString() =>
      '${mage.name} channels ${element.name} (charge $newCharge)';
}

class SpellCastEvent extends DuelEvent {
  final MageState caster;
  final Spell spell;
  final MagicElement element;

  const SpellCastEvent(this.caster, this.spell, this.element);

  @override
  String toString() =>
      '${caster.name} casts ${element.name} ${spell.name}';
}

/// A shield went up. Carries an immutable **snapshot** of the shield as raised
/// — never the live [ActiveShield] — because events are replayed after the
/// whole turn has resolved, by which point the real shield may already have
/// been chipped or shattered by damage that landed later in the same turn.
class ShieldRaisedEvent extends DuelEvent {
  final MageState mage;

  /// Null for a Barrier, which is element-less.
  final MagicElement? element;
  final bool isBarrier;

  /// Strength at the moment it was raised.
  final int strength;

  const ShieldRaisedEvent(
    this.mage, {
    required this.element,
    required this.isBarrier,
    required this.strength,
  });

  @override
  String toString() => isBarrier
      ? '${mage.name} raises Barrier'
      : '${mage.name} raises ${element!.name} shield ($strength)';
}

class DamageEvent extends DuelEvent {
  final MageState target;
  final Spell spell;
  final int toShield;
  final int toHp;

  /// The attack's element countered the shield's element (2× vs shield).
  final bool countered;

  final bool shieldBroken;

  const DamageEvent(
    this.target,
    this.spell, {
    required this.toShield,
    required this.toHp,
    this.countered = false,
    this.shieldBroken = false,
  });

  @override
  String toString() {
    final parts = <String>[
      if (toShield > 0)
        '$toShield to shield${countered ? ' (countered, 2x)' : ''}',
      if (toHp > 0) '$toHp damage',
      if (toShield == 0 && toHp == 0) 'no effect',
      if (shieldBroken) 'shield shattered',
    ];
    return '${target.name} takes ${spell.name}: ${parts.join(', ')}';
  }
}

class HealedEvent extends DuelEvent {
  final MageState mage;
  final int amount;

  const HealedEvent(this.mage, this.amount);

  @override
  String toString() => '${mage.name} drains $amount health';
}

class BuffAppliedEvent extends DuelEvent {
  final MageState mage;
  final String description;

  const BuffAppliedEvent(this.mage, this.description);

  @override
  String toString() => '${mage.name}: $description';
}

class DefeatedEvent extends DuelEvent {
  final MageState mage;

  const DefeatedEvent(this.mage);

  @override
  String toString() => '${mage.name} is defeated';
}

/// The Haste initiative token changed hands. [holder] is null when Haste
/// becomes contested (nobody holds it).
class HasteChangedEvent extends DuelEvent {
  final MageState? holder;

  const HasteChangedEvent(this.holder);

  @override
  String toString() => holder == null
      ? 'Haste is contested — nobody holds the initiative'
      : '${holder!.name} seizes the initiative (Haste)';
}

class ChargeDrainedEvent extends DuelEvent {
  final MageState mage;
  final int amount;

  const ChargeDrainedEvent(this.mage, this.amount);

  @override
  String toString() => "${mage.name}'s charge is drained (−$amount)";
}

/// A mage forfeited the turn (ran out of time or disconnected) and did nothing.
class ForfeitedEvent extends DuelEvent {
  final MageState mage;

  const ForfeitedEvent(this.mage);

  @override
  String toString() => '${mage.name} forfeits the turn';
}

/// A committed spell that did not cast because the caster's charge was pulled
/// below its cost before it resolved (Static Feedback, or a same-turn
/// Discharge). Behaves like a charge — no streak change, no penalty.
class SpellFizzledEvent extends DuelEvent {
  final MageState caster;
  final Spell spell;

  const SpellFizzledEvent(this.caster, this.spell);

  @override
  String toString() => "${caster.name}'s ${spell.name} fizzles (not enough "
      'charge at resolution)';
}

/// A committed offensive spell that missed (Blind). Charge is spent; the spell
/// has no effect. Does not advance the cast streak.
class SpellMissedEvent extends DuelEvent {
  final MageState caster;
  final Spell spell;

  const SpellMissedEvent(this.caster, this.spell);

  @override
  String toString() => '${caster.name} is blinded — ${spell.name} misses';
}

/// Damage dealt by a status effect during a start/end phase (a DoT tick like
/// Ignite), rather than by a cast spell. [source] names the status.
class EffectDamageEvent extends DuelEvent {
  final MageState target;
  final String source;
  final int toShield;
  final int toHp;
  final bool countered;
  final bool shieldBroken;

  const EffectDamageEvent(
    this.target,
    this.source, {
    required this.toShield,
    required this.toHp,
    this.countered = false,
    this.shieldBroken = false,
  });

  @override
  String toString() {
    final parts = <String>[
      if (toShield > 0) '$toShield to shield${countered ? ' (2x)' : ''}',
      if (toHp > 0) '$toHp damage',
      if (toShield == 0 && toHp == 0) 'no effect',
      if (shieldBroken) 'shield shattered',
    ];
    return '${target.name} suffers $source: ${parts.join(', ')}';
  }
}

/// A status effect healed its holder during a start/end phase. [source] names
/// the status (e.g. 'Photosynthesis').
class EffectHealEvent extends DuelEvent {
  final MageState mage;
  final String source;
  final int amount;

  const EffectHealEvent(this.mage, this.source, this.amount);

  @override
  String toString() => '${mage.name} heals $amount from $source';
}
