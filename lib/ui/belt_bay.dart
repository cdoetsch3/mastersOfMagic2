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
/// ⚠️ **Deliberately run-blind.** Loading and unloading go through
/// `GameState.loadOntoBelt` / `unloadFromBelt`, which are legal in town and on
/// the road alike — between fights re-packing the belt is free, and only
/// drinking from it mid-duel costs a turn (ITEMS §6b.2).
class BeltBay extends StatelessWidget {
  final GameState game;

  const BeltBay({super.key, required this.game});

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
                  overCapacity: i >= capacity,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One belt slot — empty, or a loaded item that can be taken off again.
///
/// ⭐ **Tappable to unload**, using the same dialog the pack and the paper doll
/// use: the belt is the only container that had no way back, and a potion you
/// can load but never retrieve is a trap rather than a decision.
class _BeltSlot extends StatelessWidget {
  final String? defId;
  final GameState game;

  /// True for a slot the belt no longer has room for — see [BeltBay].
  final bool overCapacity;

  const _BeltSlot({
    required this.defId,
    required this.game,
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
            (label: 'Take off belt', run: () => game.unloadFromBelt(def.id)),
          ],
        ),
        child: box,
      ),
    );
  }
}
