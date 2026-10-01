/// The one way an item is shown anywhere in the app.
///
/// ⭐ **Standardized on purpose** (ruling, 2026-08-10): the Ledger, the
/// Workbench, the backpack, the paper doll and the loot picker all open THIS
/// dialog, so an item reads identically wherever it is met. Stats come from
/// the same writers the duel uses (`Equipping.describe`, `effect.describe`),
/// so no screen can disagree with the game. ⭐ Since 2026-08-26 the Shop's own
/// rows open this dialog too, which is why the body carries a **Value** line:
/// the one dialog is now met most often from a screen made of prices.
/// ✅ The name line grows a sprite when item icons exist (CONTENT_CHECKLIST
/// col 15b) — wired, and a no-op until `assets/items/` has PNGs in it (see
/// [ItemIcon]).
library;

import 'package:flutter/material.dart';

import '../game/items/equipping.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import '../game/items/item_naming.dart';
import '../game/provenance.dart';
import '../game/economy/quality_value.dart';
import 'app_banner.dart';
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
///
/// [tags] are small chips the CALLING screen contributes — the Shop's tier
/// and spike/sale chips today. ⭐ **Widgets, not data** (ruling 2026-09-21):
/// the chips already exist as private widgets on the screen that understands
/// them, and this dialog has no business knowing what a location tier is. It
/// gives them a row and nothing else.
Future<void> showItemDialog(
  BuildContext context, {
  required ItemDef def,
  ItemInstance? instance,
  List<({String label, Future<String?> Function() run})> actions = const [],
  List<({String label, String reason})> unavailable = const [],
  List<Widget> tags = const [],
}) async {
  // ⚠️ **The instance's numbers, not the definition's** — quality scales
  // stats (ruling 2026-08-18), and a tooltip quoting the base while the duel
  // uses the roll is the disagreement this file exists to prevent. With no
  // instance (a Workbench preview of a thing not yet made) the base is the
  // honest answer.
  final worn = Equipping.modifiersOf(def, instance);
  // ⭐ An OWNED piece reads through `describeInstance` (ENCHANTING §7): the
  // def's lines as quality made them, then 'Enchant: Charred (Standard) ·
  // +8% crit damage' (or a drop's 'Aspect: …'), then one line per socket.
  // ⚠️ With no instance — a Workbench preview, a shop shelf — there is no
  // enchant or socket to speak of, and the base lines are the honest answer.
  final lines = def is EquipmentDef
      ? (instance == null
            ? Equipping.describe(worn)
            : Equipping.describeInstance(def, instance))
      : (def is Usable ? [(def as Usable).effect.describe] : const <String>[]);
  // ⭐ One worked example under a belt (ruling 2026-09-25) — null for
  // anything without potency, so a hat never grows the sentence.
  final potencyExample = Equipping.potencyExample(worn);
  // ⚠️ Captured BEFORE the dialog, because the refusal is reported after it
  // pops — at which point `dialogContext` is gone.
  final banner = appBannerOf(context);
  // ⭐ **The worth line** (ruling 2026-08-26 #2): the shop is not the only
  // place an item's price matters, and a tooltip that describes what a thing
  // DOES while staying silent about what it is WORTH sends the player back to
  // the shelf to find out. ⚠️ Value 0 (every [KeyDef] — quest gates are worth
  // nothing by construction) prints NO line: 'Value: 0g' reads as a bug
  // report, not as "this is not merchandise".
  final scaledValue = qualityValue(def, instance);
  final foundIn = Provenance.foundInLine(def);
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
          // ⭐ **Directly under the name, above everything the item IS**
          // (ruling 2026-09-21): the tags qualify the thing itself — on a
          // phone the Shop's rows hide their chips for want of width, and
          // this dialog is where 'Native −25%' has to be readable instead.
          // ⚠️ A [Wrap], not a Row: two chips plus a long rarity name would
          // overflow a narrow dialog, and the point of moving them here was
          // that they no longer have to fit on one line.
          if (tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(spacing: 6, runSpacing: 4, children: tags),
            ),
          ],
          // ⭐ **Where it goes, before what it does** — and for a two-hander
          // that line is 'Main hand · two-handed' (ruling 2026-09-21), so the
          // player meets the rule on the staff rather than on the refusal
          // when they try to keep their knot. `Equipping.slotLabel` is the
          // one writer for both words.
          if (def is EquipmentDef)
            Text(
              '${Equipping.slotLabel(def)} · Level ${def.equipLevel}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          for (final line in lines)
            Text(
              line,
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            ),
          // ⚠️ Dim, under the stats: it explains a number, it is not one.
          if (potencyExample != null)
            Text(
              potencyExample,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          // ⭐ Below the stats, above the lore — the same descending ladder
          // the rest of this dialog reads in: what it is, what it does, what
          // it is worth, then the flavour nobody needs. ⚠️ The quality-scaled
          // figure only rides along when it actually DIFFERS: a Standard
          // instance printing 'Value: 13g (Standard 13g)' teaches the player
          // that quality moves worth by restating the same number, which is
          // the opposite of what it would mean.
          if (def.value > 0) ...[
            const SizedBox(height: 6),
            Text(
              scaledValue == def.value
                  ? 'Value: ${def.value}g'
                  : 'Value: ${def.value}g '
                        '(${qualityWord(instance!.quality!)} ${scaledValue}g)',
              style: const TextStyle(color: AppColors.gold, fontSize: 12.5),
            ),
          ],
          // 📝 Ruling 2026-09-30 (note 3): where to go for more, under what
          // it is worth. Read off the gather nodes and drop tables
          // ([Provenance.sourcesOf]); an item that is only ever crafted
          // prints nothing. ⚠️ ONE soft-wrapping [Text], never a Row of
          // place chips — Climber's Ration is found in eight places, and a
          // row of eight would overflow a phone-width dialog.
          if (foundIn != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                foundIn,
                softWrap: true,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
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
                banner.show(no, color: AppColors.ember);
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
