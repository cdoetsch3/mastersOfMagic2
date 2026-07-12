import 'element.dart';
import 'spell.dart';

/// One mage's chosen move for a turn. Both mages submit simultaneously;
/// the engine resolves them together.
sealed class MageAction {
  const MageAction();
}

/// Spend the turn charging: +1 charge, no attack or defense.
/// [element] is required when starting a new cycle (charge == 0).
class ChargeAction extends MageAction {
  final MagicElement? element;

  const ChargeAction([this.element]);

  @override
  String toString() =>
      element == null ? 'charge' : 'charge (${element!.name})';
}

/// Cast [spell]. Consumes ALL current charge and ends the cycle.
/// [element] is required when casting with charge == 0 (0-cost spells).
class CastAction extends MageAction {
  final Spell spell;
  final MagicElement? element;

  const CastAction(this.spell, [this.element]);

  @override
  String toString() => 'cast ${spell.name}';
}
