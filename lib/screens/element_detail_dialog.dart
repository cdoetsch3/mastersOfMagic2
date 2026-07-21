import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/element_lore.dart';
import '../game/element_style.dart';
import '../ui/app_theme.dart';

/// The "B2 · stat sheet" element detail: identity + tier, the effect rules,
/// and both counter layers (shield ×2 and the effect interaction) as side-by
/// -side BEATS / WEAK TO cards.
Future<void> showElementDetail(BuildContext context, MagicElement element) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ElementDetailDialog(element: element),
  );
}

class _ElementDetailDialog extends StatelessWidget {
  final MagicElement element;
  const _ElementDetailDialog({required this.element});

  @override
  Widget build(BuildContext context) {
    final style = element.style;
    final lore = elementLore[element]!;
    final beats = element.strongAgainst.first;
    final weakTo = element.counteredBy;

    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.borderDim)),
              ),
              child: Row(
                children: [
                  _elementAvatar(element, 36),
                  const SizedBox(width: 12),
                  Text(style.label,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  _tierTag(element.tier),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('Effect', lore.effectName, valueStrong: true),
                    _kv('Trigger', lore.trigger),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(lore.description,
                          style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12.5,
                              height: 1.4)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _counterCard(
                            heading: 'BEATS',
                            headingColor: AppColors.green,
                            other: beats,
                            lines: ['×2 vs their shields', lore.beatsEffect],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _counterCard(
                            heading: 'WEAK TO',
                            headingColor: AppColors.ember,
                            other: weakTo,
                            lines: ['×2 vs your shields', lore.weakEffect],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _doneBar(context),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value, {bool valueStrong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight:
                        valueStrong ? FontWeight.w700 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _counterCard({
    required String heading,
    required Color headingColor,
    required MagicElement other,
    required List<String> lines,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDim),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading,
              style: TextStyle(
                  color: headingColor,
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              _elementAvatar(other, 20),
              const SizedBox(width: 7),
              Text(other.style.label,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line,
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 11, height: 1.35)),
            ),
        ],
      ),
    );
  }

  Widget _doneBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderDim)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

Widget _elementAvatar(MagicElement element, double size) {
  final style = element.style;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
    child: Icon(style.icon, size: size * 0.55, color: AppColors.bg),
  );
}

Widget _tierTag(MagicTier tier) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.borderDim,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(tierLabels[tier]!.toUpperCase(),
        style: const TextStyle(
            color: AppColors.gold,
            fontSize: 10.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600)),
  );
}
