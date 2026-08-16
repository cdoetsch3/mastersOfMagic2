/// The one way an item is shown anywhere in the app.
///
/// ⭐ **Standardized on purpose** (ruling, 2026-08-10): the Ledger, the
/// Workbench, the backpack, the paper doll and the loot picker all open THIS
/// dialog, so an item reads identically wherever it is met. Stats come from
/// the same writers the duel uses (`Equipping.describe`, `effect.describe`),
/// so no screen can disagree with the game. 📝 The name line grows a sprite
/// when item icons exist (CONTENT_CHECKLIST col 15b).
library;

import 'package:flutter/material.dart';

import '../game/items/equipping.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import 'app_theme.dart';

/// One dialog for every item interaction — what it is, what it does, and
/// what you can do with it here. [actions] whose `run` returns a refusal
/// string surface it; null means done.
Future<void> showItemDialog(
  BuildContext context, {
  required ItemDef def,
  ItemInstance? instance,
  List<({String label, Future<String?> Function() run})> actions = const [],
}) async {
  final lines = def is EquipmentDef
      ? Equipping.describe(def.modifiers)
      : (def is Usable ? [(def as Usable).effect.describe] : const <String>[]);
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(
        ItemCatalogue.displayName(def, instance),
        style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (def is EquipmentDef)
            Text(
              'Level ${def.equipLevel}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          for (final line in lines)
            Text(
              line,
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            ),
          const SizedBox(height: 8),
          Text(
            def.lore,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        for (final a in actions)
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final no = await a.run();
              // ⚠️ A refusal the player never sees is a button that looks
              // broken. Every rule speaks here.
              if (no != null) {
                messenger.showSnackBar(SnackBar(content: Text(no)));
              }
            },
            child: Text(a.label),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// ⭐ The standard ARPG ladder (ITEMS §8), so players read rank on sight.
/// ⚠️ Legendary wants a gradient treatment, not a flat colour — it degrades to
/// gold here until that widget exists.
Color rarityColour(Rarity r) => switch (r) {
  Rarity.common => const Color(0xFFCFD8DC),
  Rarity.uncommon => const Color(0xFF6BBF59),
  Rarity.rare => const Color(0xFF4A90D9),
  Rarity.epic => const Color(0xFFA96BD8),
  Rarity.mythic => const Color(0xFFE08A3C),
  Rarity.legendary => const Color(0xFFE8C547),
};
