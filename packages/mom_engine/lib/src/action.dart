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
  String toString() => element == null ? 'charge' : 'charge (${element!.name})';
}

/// Cast [spell]. Consumes ALL current charge and ends the cycle.
/// [element] is required when casting with charge == 0 (0-cost spells).
class CastAction extends MageAction {
  final Spell spell;
  final MagicElement? element;

  /// The **status this cast is aimed at**, by id — Cleanse's "one debuff of
  /// your choice" (TYPE_EFFECTS §7a INSTANTS).
  ///
  /// ⭐ It rides on the ACTION, not on the spell, because it is a decision the
  /// player makes at submission time about a board that only exists then. That
  /// puts it on the wire (`S|<spellId>|<element>|<statusId>`) and therefore
  /// inside the commitment hash, which is the whole point: both lockstep
  /// clients resolve the same removal, and nobody can change which debuff they
  /// shed after seeing the reveal.
  ///
  /// ⚠️ Null is **legal and normal**, not an error path — it means "you pick",
  /// and the engine then applies a documented deterministic default (the debuff
  /// with the most turns left). The AI, and any UI that has not grown its
  /// pick-a-status sheet yet, both ride that; both clients compute the
  /// identical answer from the identical board rather than sending it.
  ///
  /// ⚠️ Ignored by every spell that isn't asking a question. A `statusChoice`
  /// on a Bolt is inert, not invalid.
  final String? statusChoice;

  const CastAction(this.spell, [this.element, this.statusChoice]);

  @override
  String toString() => statusChoice == null
      ? 'cast ${spell.name}'
      : 'cast ${spell.name} ($statusChoice)';
}

/// What drinking one belt consumable does, as **pure data** (ITEMS §10.3b).
///
/// ⭐ The engine is handed the NUMBERS, never an id to look up. That is what
/// keeps `mom_engine` free of the app's item catalogue while both lockstep
/// clients still resolve the identical heal — the catalogue lookup happens on
/// the app side of [decodeAction], exactly once per client.
///
/// ⚠️ **Flat health, never a percentage of the drinker** (ruling 2026-09-21).
/// A potion is a fixed object: it holds what it holds, and a bigger potion is
/// a later zone's potion. The engine therefore needs no max-HP term to resolve
/// a drink — only the cap at full health, which [MageState.heal] already owns.
class ConsumableEffect {
  /// The item's player-facing name. ⭐ Carried because the battle log says
  /// "drinks Sapwort Draught", not "drinks an item" — and the engine has no
  /// other way to learn it.
  final String name;

  /// Health restored the instant it resolves.
  final int healNow;

  /// The Tonic shape (ITEMS §9b.8): [healPerTurn] health at the end of each of
  /// [hotTurns] turns, the first tick on the turn it is drunk.
  final int healPerTurn;
  final int hotTurns;

  const ConsumableEffect({
    required this.name,
    this.healNow = 0,
    this.healPerTurn = 0,
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
