/// The one seam between the item catalogue and the duel engine (ITEMS
/// §10.3b).
library;

import 'package:mom_engine/mom_engine.dart';

import 'item_catalogue.dart';
import 'item_def.dart';

/// What drinking the belt consumable [defId] does, in the engine's vocabulary
/// — or null when nothing answers to that id, it is not [Beltable], or it does
/// nothing at all.
///
/// ⭐ **Read here and nowhere else.** The duel controller and the wire decoder
/// both come through this function, which is what makes "the numbers on the
/// Draught" a single fact: the two clients of a lockstep duel exchange a def
/// id and each looks the effect up locally, so neither can be handed a heal
/// the catalogue does not actually sell.
///
/// ⚠️ **The bottle's own numbers, never the drinker's belt.** Consumable
/// potency (ruling 2026-09-25) is applied by the engine from
/// `MageState.consumablePotencyPercent` via `applyPotency` — an effect built
/// here with THIS player's potency baked in would be decoded by the opponent's
/// client without it, and the lockstep would split on the first drink.
///
/// ⚠️ Reads the def's own [ItemEffect] rather than restating it. A duplicated
/// "30" here would silently disagree with the tooltip the moment either is
/// tuned — which is the same reason [ItemEffect.describe] exists.
ConsumableEffect? consumableEffectFor(String defId) {
  final def = ItemCatalogue.tryById(defId);
  // ⚠️ Not `Usable`: a field ration is usable and is deliberately NOT belt
  // legal (§6b.3). The type is the gate, so a plain consumable can never be
  // drunk mid-duel by coming through this door.
  if (def is! BeltableDef) return null;
  final effect = def.effect;
  if (effect.isNothing) return null;
  return ConsumableEffect(
    name: ItemCatalogue.displayName(def),
    healNow: effect.heal,
    healPerTurn: effect.healPerTurn,
    hotTurns: effect.healTurns,
  );
}
