/// The Enchant…, Socket… and Salvage… entries an owned piece of gear offers in
/// its item dialog (ENCHANTING_DESIGN §6, §7), and the one button row the
/// three sheets share.
///
/// ⭐ **One builder for every dialog that shows owned gear** — the paper doll
/// and the backpack both call [gearWorkActions], so a piece cannot be
/// enchantable from one and not the other.
library;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import '../ui/app_theme.dart';
import 'enchant_sheet.dart';
import 'salvage_sheet.dart';
import 'socket_sheet.dart';

/// What `showItemDialog` takes as one live action.
typedef GearAction = ({String label, Future<String?> Function() run});

/// What `showItemDialog` takes as one greyed action and its reason.
typedef GearUnavailable = ({String label, String reason});

/// The label of the item dialog's enchant action.
const String enchantActionLabel = 'Enchant…';

/// The label of the item dialog's socket action.
const String socketActionLabel = 'Socket…';

/// The label of the item dialog's salvage action.
const String salvageActionLabel = 'Salvage…';

/// Enchant… on every owned piece of gear, Socket… on one with sockets, and
/// Salvage… on every one (last — the act that destroys the piece).
///
/// ⭐ **Away from the station, greyed with the reason — never hidden**
/// (2026-08-17's rule): a missing Enchant… teaches the player that gear cannot
/// be enchanted; a dead one reading 'Needs the Meridian station.' teaches them
/// where to go. The reason is `GameState.stationRefusal`, the same words
/// `enchantItem` / `socketGem` refuse with.
///
/// ⚠️ Only the STATION greys the dialog's entry. The level, the motes and the
/// gems are the sheet's to explain, row by row — a dialog that greyed Enchant…
/// for want of Pyro Shards would hide the eleven other elements the player
/// can afford.
///
/// ⚠️ Nothing for a def with no [instance] (a shop shelf, a Workbench
/// preview): there is no piece to rewrite.
({List<GearAction> actions, List<GearUnavailable> unavailable}) gearWorkActions(
  BuildContext context,
  GameState game,
  ItemDef def,
  ItemInstance? instance,
) {
  final actions = <GearAction>[];
  final unavailable = <GearUnavailable>[];
  if (def is! EquipmentDef || instance == null) {
    return (actions: actions, unavailable: unavailable);
  }
  final id = instance.instanceId;
  final enchantNo = game.stationRefusal(CraftSkill.enchanting);
  if (enchantNo == null) {
    actions.add((
      label: enchantActionLabel,
      run: () async {
        // ⚠️ Runs after the item dialog has popped, on the screen's context.
        if (context.mounted) {
          await showEnchantSheet(context, game: game, instanceId: id);
        }
        return null;
      },
    ));
  } else {
    unavailable.add((label: enchantActionLabel, reason: enchantNo));
  }
  // ⭐ Only a piece with sockets offers Socket… at all — a greyed Socket… on
  // a hat with none would promise something no visit to Rimeholt can give.
  if (def.socketCount > 0) {
    final socketNo = game.stationRefusal(CraftSkill.jewelry);
    if (socketNo == null) {
      actions.add((
        label: socketActionLabel,
        run: () async {
          if (context.mounted) {
            await showSocketSheet(context, game: game, instanceId: id);
          }
          return null;
        },
      ));
    } else {
      unavailable.add((label: socketActionLabel, reason: socketNo));
    }
  }
  // ⭐ Salvage is field-craftable (§6): no station, so the only thing that
  // greys the entry is where the PIECE is — worn ('Take it off first.') or
  // stored. ⚠️ Room is the sheet's to explain, beside the yield it would not
  // fit: a dialog greyed 'No room …' would hide what the piece is worth.
  final salvageNo = game.salvageWhereRefusal(id);
  if (salvageNo == null) {
    actions.add((
      label: salvageActionLabel,
      run: () async {
        if (context.mounted) {
          await showSalvageSheet(context, game: game, instanceId: id);
        }
        return null;
      },
    ));
  } else {
    unavailable.add((label: salvageActionLabel, reason: salvageNo));
  }
  return (actions: actions, unavailable: unavailable);
}

/// One button and the line beside it — the commit row of every gear sheet.
///
/// ⭐ **Press-stable** (house rule): the button sits in a fixed-width cell and
/// the [note] in a fixed-height one, so a refusal arriving, changing or
/// clearing rewrites text and never moves the button. ⭐ A greyed button
/// always carries its reason: [onPressed] null ⇒ [note] is the refusal.
class ReservedActionRow extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// The refusal when [onPressed] is null; otherwise what the press will
  /// change ('Replaces Charred (Lesser).'), or empty.
  final String note;

  /// The button's cell width — wide enough for the longest label any sheet
  /// uses, so swapping 'Put in' for 'Take out' moves nothing either.
  static const double buttonWidth = 112;

  /// Two lines of 12px text.
  static const double height = 40;

  const ReservedActionRow({
    super.key,
    required this.label,
    required this.onPressed,
    required this.note,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: [
        SizedBox(
          width: buttonWidth,
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onPressed == null ? AppColors.ember : AppColors.textDim,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
