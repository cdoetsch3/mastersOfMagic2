/// The Salvage sheet (ENCHANTING_DESIGN §6, §7): one pack piece, what comes
/// out of it, what is lost, and one button.
///
/// ⭐ **The refusal is `GameState.salvageRefusal`** — the same function
/// `salvageItem` refuses with — so the greyed button and a refused press can
/// never disagree. ⭐ **The yield is `GameState.salvageYieldOf`** (which is
/// `SalvageTable.yieldOfInstance`), so what the sheet promises is what the
/// write adds.
library;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/enchants.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import 'gear_work_actions.dart';

/// Opens the Salvage sheet over [context] for the pack piece [instanceId].
Future<void> showSalvageSheet(
  BuildContext context, {
  required GameState game,
  required String instanceId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.panel,
  builder: (_) => SalvageSheet(game: game, instanceId: instanceId),
);

/// The commit button's label.
const String salvageButtonLabel = 'Salvage';

/// The warning on a piece with no enchant.
const String salvageWarning = 'The piece is destroyed.';

/// The warning on an enchanted piece: 'The piece is destroyed. Its Charred
/// enchant goes with it.' ⚠️ The enchant's PREFIX, not its label — the tier
/// is already in the piece's name above it.
String salvageEnchantWarning(EnchantDef enchant) =>
    '$salvageWarning Its ${enchant.prefix} enchant goes with it.';

/// What a yield with nothing in it reads. 📝 No shipped piece reaches this
/// (every piece has a zone with elements, ENCHANTING §8.2); a workshop-made
/// piece with no sockets would.
const String salvageNothingOut = 'Nothing comes out.';

/// One line for [yield]: '1 Pyro Shard · 10 Pyro Dust · Lesser Aqua Gem'.
///
/// ⭐ Motes as 'count name' in the order `SalvageTable` returns them (the
/// biggest tier first); then gems by name, ⭐ a repeated gem once with '×2'
/// (the Socket sheet's count mark) rather than its name twice.
String salvageYieldText(List<InventorySlot> yield) {
  if (yield.isEmpty) return salvageNothingOut;
  final parts = <String>[];
  final gems = <String, int>{};
  for (final slot in yield) {
    final def = ItemCatalogue.tryById(slot.defId);
    final name = def == null ? slot.defId : ItemCatalogue.displayName(def);
    if (def is GemDef) {
      gems[name] = (gems[name] ?? 0) + slot.count;
    } else {
      parts.add('${slot.count} $name');
    }
  }
  for (final e in gems.entries) {
    parts.add(e.value == 1 ? e.key : '${e.key} ×${e.value}');
  }
  return parts.join(' · ');
}

class SalvageSheet extends StatelessWidget {
  final GameState game;
  final String instanceId;

  /// ⭐ Fixed: the yield and the warning each get two lines whether they
  /// need them or not, so nothing above the button can move it.
  static const double lineBoxHeight = 36;

  const SalvageSheet({super.key, required this.game, required this.instanceId});

  Future<void> _salvage(BuildContext context) async {
    final banner = appBannerOf(context);
    final navigator = Navigator.of(context);
    final no = await game.salvageItem(instanceId);
    if (no != null) {
      banner.show(no, color: AppColors.ember);
      return;
    }
    // ⭐ The piece is gone, so is the sheet's subject — close it. No banner:
    // the pack already shows the motes arriving (app_banner's first rule).
    await navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: game,
    builder: (context, _) {
      final instance = game.profile.itemInstances[instanceId];
      final def = instance == null
          ? null
          : ItemCatalogue.tryById(instance.defId);
      if (instance == null || def is! EquipmentDef) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'That item is gone.',
              style: TextStyle(color: AppColors.textDim),
            ),
          ),
        );
      }
      final enchant = Enchants.tryById(instance.enchantId);
      final no = game.salvageRefusal(instanceId);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ One line, as on the Enchant and Socket sheets.
              Text(
                ItemCatalogue.displayName(def, instance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: lineBoxHeight,
                child: Text(
                  salvageYieldText(game.salvageYieldOf(instanceId)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.teal, fontSize: 13),
                ),
              ),
              SizedBox(
                height: lineBoxHeight,
                child: Text(
                  enchant == null
                      ? salvageWarning
                      : salvageEnchantWarning(enchant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.ember, fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              ReservedActionRow(
                label: salvageButtonLabel,
                onPressed: no != null ? null : () => _salvage(context),
                note: no ?? '+${GameState.salvageXpFor(def)} Enchanting XP.',
              ),
            ],
          ),
        ),
      );
    },
  );
}
