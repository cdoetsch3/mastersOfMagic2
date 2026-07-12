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

class ShieldRaisedEvent extends DuelEvent {
  final MageState mage;
  final ActiveShield shield;

  const ShieldRaisedEvent(this.mage, this.shield);

  @override
  String toString() => '${mage.name} raises $shield';
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
