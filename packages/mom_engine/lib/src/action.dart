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

/// What drinking one belt consumable does, as **pure data** (ITEMS §10.3b).
///
/// ⭐ The engine is handed the NUMBERS, never an id to look up. That is what
/// keeps `mom_engine` free of the app's item catalogue while both lockstep
/// clients still resolve the identical heal — the catalogue lookup happens on
/// the app side of [decodeAction], exactly once per client.
///
/// ⚠️ Percentages of the drinker's **max HP**, never flat numbers, for the
/// same reason [ItemEffect] is: one potion must not trivialise level 2 and
/// then be worthless by level 20.
class ConsumableEffect {
  /// The item's player-facing name. ⭐ Carried because the battle log says
  /// "drinks Sapwort Draught", not "drinks an item" — and the engine has no
  /// other way to learn it.
  final String name;

  /// Percent of max HP restored the instant it resolves.
  final int healNowPercent;

  /// The Tonic shape (ITEMS §9b.8): [hotPercentPerTurn] of max HP at the end
  /// of each of [hotTurns] turns, the first tick on the turn it is drunk.
  final int hotPercentPerTurn;
  final int hotTurns;

  const ConsumableEffect({
    required this.name,
    this.healNowPercent = 0,
    this.hotPercentPerTurn = 0,
    this.hotTurns = 0,
  });

  @override
  String toString() => name;
}

/// Drink a belt consumable — the Draught, the Tonic (ITEMS §10.3b).
///
/// ⭐ **It is your action for the turn.** That is the whole design: in a
/// simultaneous-turn duel a turn spent drinking is a turn not casting, and the
/// opponent committed blind — so a heal can be baited, and healing is a
/// decision rather than a tax.
///
/// ⚠️ [itemId] is all that crosses the wire; [effect] is resolved locally by
/// each client from its own catalogue. Never send the numbers — see
/// [encodeAction].
class UseItemAction extends MageAction {
  /// The catalogue def id — the app's key, opaque to the engine.
  final String itemId;

  final ConsumableEffect effect;

  const UseItemAction(this.itemId, this.effect);

  @override
  String toString() => 'use ${effect.name}';
}

/// Do nothing this turn — no charge, no cast, charge and element unchanged.
/// Submitted when a player runs out of time or is disconnected. Strictly
/// worse than channeling (you don't even gain charge).
class ForfeitAction extends MageAction {
  const ForfeitAction();

  @override
  String toString() => 'forfeit';
}
