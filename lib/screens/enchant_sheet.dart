/// The Enchant… picker (ENCHANTING_DESIGN §4, §7): choose an element and a
/// tier, see what it costs against what you hold and what it grants, and lay
/// it onto one owned piece.
///
/// ⭐ **Every number here is read, never typed**: the cost and the level from
/// `EnchantingCosts`, the stat from `Equipping.describe` over the enchant's
/// own modifiers, the proc from `Equipping.procLine`, the refusal from
/// `GameState.enchantRefusal` — the exact function `enchantItem` refuses
/// with, so the greyed button and a refused press say one thing.
library;

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/game_state.dart';
import '../game/items/enchants.dart';
import '../game/items/equipping.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_naming.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import 'gear_work_actions.dart';

/// Opens the Enchant sheet over [context] for the owned piece [instanceId].
Future<void> showEnchantSheet(
  BuildContext context, {
  required GameState game,
  required String instanceId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.panel,
  builder: (_) => EnchantSheet(game: game, instanceId: instanceId),
);

/// The commit button's label.
const String enchantButtonLabel = 'Enchant';

class EnchantSheet extends StatefulWidget {
  final GameState game;
  final String instanceId;

  const EnchantSheet({super.key, required this.game, required this.instanceId});

  @override
  State<EnchantSheet> createState() => _EnchantSheetState();
}

class _EnchantSheetState extends State<EnchantSheet> {
  late MagicElement _element;
  late EnchantTier _tier;

  @override
  void initState() {
    super.initState();
    // ⭐ Opens on what the piece already is — its enchant, else its drop's
    // aspect — so a re-enchant starts from the thing being replaced.
    final instance = widget.game.profile.itemInstances[widget.instanceId];
    final current = Enchants.tryById(instance?.enchantId);
    _element =
        current?.element ?? instance?.aspect ?? MagicElement.values.first;
    _tier = current?.tier ?? EnchantTier.lesser;
  }

  Future<void> _commit(EnchantDef enchant) async {
    final no = await widget.game.enchantItem(widget.instanceId, enchant);
    // ⚠️ The button was live, so a refusal here is a race (the pack changed
    // under the sheet). Say it rather than look broken.
    if (no != null && mounted) {
      showAppBanner(context, no, color: AppColors.ember);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // ⭐ Live: an enchant moves the 'current' mark and the 'have' counts in
    // place, which is the confirmation — no notice restating it.
    listenable: widget.game,
    builder: (context, _) {
      final game = widget.game;
      final instance = game.profile.itemInstances[widget.instanceId];
      final def = instance == null
          ? null
          : ItemCatalogue.tryById(instance.defId);
      if (instance == null || def == null) {
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
      final current = Enchants.tryById(instance.enchantId);
      final chosen = Enchants.of(_element, _tier);
      final no = game.enchantRefusal(widget.instanceId, chosen);
      // ⭐ What the press will change, in the cell the refusal uses: a
      // re-enchant pays in full (§4.3), so the player is told what goes.
      final replaces = current != null
          ? 'Replaces ${current.label}.'
          : instance.aspect != null
          ? 'Replaces ${aspectPrefixes[instance.aspect!.name]}.'
          : '';
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ One line: an enchant RENAMES the piece (Charred …), and a title
              // that wrapped would push every row and the button below it down.
              Text(
                ItemCatalogue.displayName(def, instance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in MagicElement.values)
                    _ElementChip(
                      element: e,
                      selected: e == _element,
                      worn: current?.element == e,
                      onTap: () => setState(() => _element = e),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final tier in EnchantTier.values)
                _TierRow(
                  enchant: Enchants.of(_element, tier),
                  selected: tier == _tier,
                  current: current?.id == Enchants.idFor(_element, tier),
                  have: game.materialCount(
                    EnchantingCosts.of(Enchants.of(_element, tier)).defId,
                  ),
                  onTap: () => setState(() => _tier = tier),
                ),
              const SizedBox(height: 12),
              ReservedActionRow(
                label: enchantButtonLabel,
                onPressed: no == null ? () => _commit(chosen) : null,
                note: no ?? replaces,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// One element: its aspect prefix large, the element's name under it
/// (§9b.5b) — so the player learns that Charred means Pyro.
class _ElementChip extends StatelessWidget {
  final MagicElement element;
  final bool selected;

  /// The piece's current enchant is of this element.
  final bool worn;
  final VoidCallback onTap;

  /// ⭐ Fixed, so the Wrap breaks at the same places for every selection and
  /// no chip ever shifts when another is chosen.
  static const double width = 92;

  const _ElementChip({
    required this.element,
    required this.selected,
    required this.worn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.panelHi : AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? AppColors.teal
              : worn
              ? AppColors.gold
              : AppColors.borderDim,
        ),
      ),
      child: Column(
        children: [
          Text(
            aspectPrefixes[element.name]!,
            style: TextStyle(
              color: selected ? AppColors.text : AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            element.displayName,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

/// One tier of the chosen element: its name, its cost against what you hold,
/// what it grants, and at Greater the proc.
///
/// ⭐ **Same height for every element** without a hard number: every line is
/// `maxLines: 1`, and the proc line is a fact of the TIER (Greater has it on
/// all twelve), so switching chips never changes the sheet's height and never
/// moves the Enchant button below the rows. ⚠️ A fixed pixel height was
/// tried and overflowed under a larger font — the structure is the reserve.
class _TierRow extends StatelessWidget {
  final EnchantDef enchant;
  final bool selected;

  /// The piece wears exactly this enchant now.
  final bool current;

  /// How many of the cost's mote are to hand (pack + this town's Storeroom).
  final int have;
  final VoidCallback onTap;

  const _TierRow({
    required this.enchant,
    required this.selected,
    required this.current,
    required this.have,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cost = EnchantingCosts.of(enchant);
    final mote = ItemCatalogue.tryById(cost.defId);
    final moteName = mote == null
        ? cost.defId
        : ItemCatalogue.displayName(mote);
    final enough = have >= cost.count;
    final proc = enchant.procElement;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.panelHi : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.borderDim,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? AppColors.teal : AppColors.textFaint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ⚠️ Both halves flexible and single-line, so a long
                      // mote name or a large font ellipsizes instead of
                      // overflowing the row.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                enchant.tier.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (current)
                              const Text(
                                ' · current',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ⭐ Right-aligned in its own half, so the 'current'
                      // mark appearing beside the tier name never pushes it.
                      Flexible(
                        child: Text.rich(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$have',
                                style: TextStyle(
                                  color: enough
                                      ? AppColors.teal
                                      : AppColors.ember,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' / ${cost.count} $moteName'
                                    '${cost.count == 1 ? '' : 's'}',
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Equipping.describe(enchant.modifiers).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.teal, fontSize: 12),
                  ),
                  if (proc != null)
                    Text(
                      Equipping.procLine(proc),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
