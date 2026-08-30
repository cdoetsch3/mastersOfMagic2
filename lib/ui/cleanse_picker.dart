import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import 'app_theme.dart';

/// The player's answer from the Cleanse picker.
///
/// ⚠️ Three states, deliberately: a popped-without-choosing dialog returns
/// plain `null` (the CAST is cancelled — tapping away must never spend 2
/// charge), while `CleanseChoice(null)` means "cast, and let the engine pick"
/// (the documented default: the debuff with the most turns left).
class CleanseChoice {
  /// The chosen debuff's status id, or null for the engine's default pick.
  final String? statusId;
  const CleanseChoice(this.statusId);
}

/// Modal picker for Cleanse's "one debuff of your choice" (TYPE_EFFECTS §7a).
///
/// Shown only when the choice is real (two or more debuffs) — with zero or
/// one, the engine's default already does the only sensible thing and the
/// cast goes straight through. Names and turn counts come from the same
/// [debuffsOn] pool the engine itself will cleanse from, so the list can
/// never offer something the spell cannot remove.
class CleansePickerDialog extends StatelessWidget {
  /// `(id, turnsLeft)` per removable debuff — [RemovableDebuff] flattened so
  /// tests need no live MageState.
  final List<({String id, int turnsLeft})> debuffs;

  const CleansePickerDialog({super.key, required this.debuffs});

  /// Convenience: show over [context] for a live mage.
  static Future<CleanseChoice?> show(BuildContext context, MageState mage) =>
      showDialog<CleanseChoice>(
        context: context,
        builder: (_) => CleansePickerDialog(debuffs: [
          for (final d in debuffsOn(mage)) (id: d.id, turnsLeft: d.turnsLeft),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('Cleanse which affliction?'),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final d in debuffs)
              ListTile(
                dense: true,
                leading:
                    const Icon(Icons.cleaning_services, color: AppColors.gem),
                title: Text(StatusCatalog.byId(d.id)?.name ?? d.id),
                // 0 turns = an untimed debuff (Waterlogged, Stagger): it has
                // no clock to show, not a clock at zero.
                trailing: d.turnsLeft > 0
                    ? Text('${d.turnsLeft} turns',
                        style: const TextStyle(color: AppColors.textDim))
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(CleanseChoice(d.id)),
              ),
            const Divider(height: 12),
            ListTile(
              dense: true,
              leading: const Icon(Icons.auto_awesome, color: AppColors.gold),
              title: const Text('Whichever runs longest'),
              subtitle: const Text('Let the spell decide',
                  style: TextStyle(color: AppColors.textDim, fontSize: 11)),
              onTap: () =>
                  Navigator.of(context).pop(const CleanseChoice(null)),
            ),
          ],
        ),
      ),
    );
  }
}
