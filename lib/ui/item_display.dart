/// The one way an item is shown anywhere in the app.
///
/// ⭐ **Standardized on purpose** (ruling, 2026-08-10): the Ledger, the
/// Workbench, the backpack, the paper doll and the loot picker all open THIS
/// dialog, so an item reads identically wherever it is met. Stats come from
/// the same writers the duel uses (`Equipping.describe`, `effect.describe`),
/// so no screen can disagree with the game. ✅ The name line grows a sprite
/// when item icons exist (CONTENT_CHECKLIST col 15b) — wired, and a no-op
/// until `assets/items/` has PNGs in it (see [ItemIcon]).
library;

import 'package:flutter/material.dart';

import '../game/items/equipping.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import 'app_theme.dart';
import 'item_icon.dart';

/// One dialog for every item interaction — what it is, what it does, and
/// what you can do with it here. [actions] whose `run` returns a refusal
/// string surface it; null means done.
///
/// [unavailable] holds actions that exist for this item but cannot be taken
/// here. ⭐ **Shown greyed with the reason, not hidden** (2026-08-17): a
/// "Load onto belt" that vanishes when the belt is full teaches the player
/// nothing, and they conclude the item is not beltable. A dead button plus
/// "Your belt is full." teaches them the rule and where to fix it.
Future<void> showItemDialog(
  BuildContext context, {
  required ItemDef def,
  ItemInstance? instance,
  List<({String label, Future<String?> Function() run})> actions = const [],
  List<({String label, String reason})> unavailable = const [],
}) async {
  // ⚠️ **The instance's numbers, not the definition's** — quality scales
  // stats (ruling 2026-08-18), and a tooltip quoting the base while the duel
  // uses the roll is the disagreement this file exists to prevent. With no
  // instance (a Workbench preview of a thing not yet made) the base is the
  // honest answer.
  final lines = def is EquipmentDef
      ? Equipping.describe(Equipping.modifiersOf(def, instance))
      : (def is Usable ? [(def as Usable).effect.describe] : const <String>[]);
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.panel,
      // ⭐ The sprite the header line was always going to grow. ⚠️ It carries
      // its own trailing gap ([ItemIcon.gap]) so the title sits exactly where
      // it sits today while `assets/items/` is empty — a reserved 32px of
      // nothing in front of every item name would be the opposite of a no-op.
      title: Row(
        children: [
          ItemIcon(
            defId: def.id,
            size: 26,
            gap: 8,
            fallback: const SizedBox.shrink(),
          ),
          Expanded(
            child: Text(
              ItemCatalogue.displayName(def, instance),
              style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
            ),
          ),
        ],
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
          // ⚠️ The reason is text in the body, not only a tooltip on the dead
          // button — there is no hover on a phone, and a greyed button whose
          // reason cannot be reached is worse than no button.
          for (final u in unavailable)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${u.label}: ${u.reason}',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                ),
              ),
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
        for (final u in unavailable)
          Tooltip(
            message: u.reason,
            child: TextButton(onPressed: null, child: Text(u.label)),
          ),
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
