/// The loaded belt, as an editable row of slots.
///
/// ⭐ **One editor, two places** (ruling 2026-09-21). The belt is loaded in
/// town and re-loaded on the road between fights — a second, hand-rolled copy
/// on the adventure screen would be two things to keep in step, and the one
/// that drifted would be the one the player is standing in front of when it
/// matters. It lives in `lib/ui/` rather than in the inventory tab for exactly
/// that reason.
library;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import 'app_theme.dart';
import 'item_display.dart';
import 'item_icon.dart';

/// The belt equipment chip and the belt slots it grants, as one unit.
///
/// ⭐ **Adjacency is the whole point** (designer, 2026-08-17). Since belt
/// capacity now comes only from the worn belt (`Carrying.baseBeltSlots` is 0),
/// cause and effect have to be readable in one glance: an empty Belt chip
/// beside "No belt" explains itself, where an empty chip in a grid of ten and
/// a row of slot boxes twenty pixels lower did not. Wearing a Tuskhide Belt
/// fills the chip and grows the row beside it, in the same movement.
/// The loaded belt slots — shown only while a belt is worn (or an
/// over-capacity leftover exists); the wearable itself is a grid chip now.
/// ⭐ The old two-line lecture is gone (Option A ruling): an empty belt slot
/// grid explains carrying, and the turn cost is taught where it is paid —
/// on the duel's belt rail.
///
/// ⚠️ **Loading and unloading are run-blind**, deliberately: they go through
/// `GameState.loadOntoBelt` / `unloadFromBelt`, which are legal in town and on
/// the road alike — between fights re-packing the belt is free, and only
/// drinking from it mid-duel costs a turn (ITEMS §6b.2). ⚠️ **Drinking is
/// not**, and is the one thing here that reads the run — see [onDrink].
class BeltBay extends StatelessWidget {
  final GameState game;

  /// Drinks the belted [defId] between fights, and reports what happened.
  ///
  /// ⭐ **The road's drink door** (designer, 2026-09-21): the Pack got a Use
  /// button and the separate Supplies section went away with it, so a belted
  /// potion needed a way to be drunk that was not a second list. The slot
  /// itself is that way — tap it, and 'Drink' sits beside 'Take off belt'.
  ///
  /// ⚠️ Null in town, where there is no run to drink against. The slot then
  /// shows the action greyed with its reason rather than hiding it, so a
  /// player who learns the rule on the road does not find the belt mute at
  /// home. Non-null means "there is a screen here that owns a banner": the
  /// bay has none of its own, and an outcome nobody reports is a tap that
  /// looks broken.
  final Future<void> Function(String defId)? onDrink;

  const BeltBay({super.key, required this.game, this.onDrink});

  @override
  Widget build(BuildContext context) {
    final capacity = game.beltCapacity;
    final loaded = game.profile.belt.loaded;
    // ⚠️ Draws every loaded item even past capacity. An over-capacity belt is
    // a legal state (see GameState.settleBeltOverflow: a full pack on the road
    // leaves items belted), and an item the UI refuses to draw is an item the
    // player cannot unload — which is how "the game ate my potion" happens.
    final boxes = loaded.length > capacity ? loaded.length : capacity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.science, color: AppColors.teal, size: 16),
        const SizedBox(width: 8),
        Text(
          'Belt — ${loaded.length}/$capacity',
          style: const TextStyle(color: AppColors.text, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < boxes; i++)
                _BeltSlot(
                  defId: i < loaded.length ? loaded[i] : null,
                  game: game,
                  onDrink: onDrink,
                  overCapacity: i >= capacity,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One belt slot — empty, or a loaded item that can be drunk or taken off.
///
/// ⭐ **Tappable to unload**, using the same dialog the pack and the paper doll
/// use: the belt is the only container that had no way back, and a potion you
/// can load but never retrieve is a trap rather than a decision.
///
/// ⭐ **And tappable to drink**, between fights (ITEMS §6b.2 — free out of
/// combat; only the duel's belt rail costs a turn). A player who belted their
/// last two draughts used to have to unload one first to top up, which is the
/// belt punishing the player for using it.
class _BeltSlot extends StatelessWidget {
  final String? defId;
  final GameState game;

  /// See [BeltBay.onDrink].
  final Future<void> Function(String defId)? onDrink;

  /// True for a slot the belt no longer has room for — see [BeltBay].
  final bool overCapacity;

  const _BeltSlot({
    required this.defId,
    required this.game,
    required this.onDrink,
    this.overCapacity = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = defId == null ? null : ItemCatalogue.tryById(defId!);
    final colour = def == null
        ? AppColors.borderDim
        : (overCapacity ? AppColors.ember : rarityColour(def.rarity));
    final box = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colour),
      ),
      child: def == null
          ? null
          : Center(
              // ⭐ The icon REPLACES the initial rather than joining it — a
              // 34px box has room for one thing, and "S" for Sapwort Draught
              // was only ever standing in for a picture.
              child: ItemIcon(
                defId: def.id,
                size: 26,
                fallback: Text(
                  ItemCatalogue.displayName(def, null).substring(0, 1),
                  style: TextStyle(color: colour, fontSize: 13),
                ),
              ),
            ),
    );
    if (def == null) return box;
    // ⭐ Asks the interface, never the id — and asks the effect too, so a
    // belted trinket that heals nothing offers no drink.
    final drinkable = def is Usable && !(def as Usable).effect.isNothing;
    // ⚠️ The run, not the location: a finished run is already standing in town
    // in every way that matters, and `GameState.useBeltItem` would refuse it
    // with 'Not on an adventure.' — a refusal is not a menu item.
    final run = game.run;
    final canDrink = drinkable && onDrink != null && run != null && !run.isOver;
    return Tooltip(
      message: overCapacity
          // ⚠️ Names the state rather than hiding it: the item is safe, it just
          // does not fit any more.
          ? '${ItemCatalogue.displayName(def, null)} — no slot for this; '
                'take it off or wear a belt'
          : ItemCatalogue.displayName(def, null),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showItemDialog(
          context,
          def: def,
          actions: [
            // ⭐ Drinking first: it is the thing a belt is FOR, and the one
            // the player reached for the belt to do.
            if (canDrink)
              (
                label: 'Drink',
                // ⚠️ Always null: the outcome — success or refusal — is
                // reported by [BeltBay.onDrink]'s owner, which has a banner.
                // Returning the message here too would say it twice, and say
                // it in the refusal colour when the potion worked.
                run: () async {
                  await onDrink!(def.id);
                  return null;
                },
              ),
            (label: 'Take off belt', run: () => game.unloadFromBelt(def.id)),
          ],
          unavailable: [
            // ⚠️ Greyed with the reason rather than hidden (2026-08-17): a
            // 'Drink' that simply is not there in town teaches the player
            // that belted potions cannot be drunk at all.
            if (drinkable && !canDrink)
              (label: 'Drink', reason: 'Only between fights on the road.'),
          ],
        ),
        child: box,
      ),
    );
  }
}
