import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/element_style.dart';
import '../ui/app_theme.dart';

/// The "C1 · spellbook page" spell detail: flavor, the vitals as chips, the
/// numbers, and how the status systems touch this spell (element proc, the
/// damage-modifier order, fizzle, Blind, streaks).
Future<void> showSpellDetail(BuildContext context, Spell spell) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SpellDetailDialog(spell: spell),
  );
}

({String label, Color color}) _category(Spell spell) => switch (spell.effect) {
  DamageEffect() ||
  BarrageEffect() ||
  OverloadEffect() => (label: 'damaging', color: AppColors.ember),
  ShieldEffect() || BarrierEffect() => (label: 'shield', color: AppColors.sky),
  DischargeEffect() => (label: 'control', color: AppColors.gem),
  _ => (label: 'aux', color: AppColors.gold),
};

/// The headline figure — kept short so it never crowds the label beside it.
String _numbers(Spell spell) => switch (spell.effect) {
  DamageEffect(:final minAmount, :final maxAmount, :final hits) =>
    hits > 1 ? '$minAmount–$maxAmount ×$hits' : '$minAmount–$maxAmount',
  BarrageEffect(:final minPerCharge, :final maxPerCharge) =>
    '$minPerCharge–$maxPerCharge ×X',
  OverloadEffect(:final minPerCharge, :final maxPerCharge) =>
    '$minPerCharge–$maxPerCharge',
  ShieldEffect(:final minStrength, :final maxStrength) =>
    '$minStrength–$maxStrength',
  BarrierEffect() => '+1 pt',
  EmpowerEffect(:final multiplier) => '×$multiplier',
  // These headline figures are all short labels, so they all capitalise —
  // mixing 'Haste' with 'pierce' read as a bug.
  QuickenEffect() => 'Faster',
  PhaseEffect() => 'Pierce',
  HasteEffect() => 'Haste',
  DischargeEffect() => 'All',
  HallowEffect() => 'Grace',
};

/// The qualifier beside the figure — carries the prose, and is free to wrap.
String _numbersLabel(Spell spell) => switch (spell.effect) {
  DamageEffect(:final lifesteal) =>
    lifesteal > 0
        ? 'damage — heals you for ${(lifesteal * 100).round()}% of what '
              'reaches their health'
        : 'damage, rolled on cast',
  BarrageEffect() => 'damage, one hit per charge spent',
  OverloadEffect() => "damage per point of the enemy's charge",
  ShieldEffect() => 'shield in your element',
  BarrierEffect() => 'of Barrier (max 3) — each point blocks one whole hit',
  EmpowerEffect() => 'damage on your next offensive spell',
  QuickenEffect() => 'your next offensive spell resolves sooner',
  PhaseEffect() => 'your next offensive spell ignores shields',
  HasteEffect() => 'seized — you win same-speed ties',
  DischargeEffect() => "of the enemy's charge, wiped",
  HallowEffect() => 'banked — it blocks the next debuff applied to you',
};

List<String> _systemsRules(Spell spell) {
  final isDamaging =
      spell.effect is DamageEffect ||
      spell.effect is BarrageEffect ||
      spell.effect is OverloadEffect;
  final isHarmful = isDamaging || spell.effect is DischargeEffect;
  final isShield =
      spell.effect is ShieldEffect || spell.effect is BarrierEffect;
  return [
    // The element line only earns its place where the element actually does
    // something: it drives side-effect procs on an attack and the shield's
    // own element on a shield. On a pure aux spell it explains nothing, so it
    // is omitted rather than saying "counter math" about a spell that neither
    // deals damage nor raises a shield.
    if (isDamaging)
      'Takes on your charged element — its side-effect can proc (Ignite, '
          'Static Feedback, Blind…).',
    if (spell.effect is ShieldEffect)
      'The shield takes your charged element, which sets how hard each attack '
          'hits it — from ½× up to 2×.',
    if (isDamaging)
      'Damage order: additive first (Arcane Knowledge 5%/stack, a Full Moon '
          'on a Lunar spell), then multipliers (Empower ×2, Stagger ×½).',
    if (isHarmful)
      'While Blinded, 50% chance to miss (the charge is still spent).',
    if (isDamaging || isShield || isHarmful)
      'Advances your element streak. Misses and fizzles don\'t.',
  ];
}

class _SpellDetailDialog extends StatelessWidget {
  final Spell spell;
  const _SpellDetailDialog({required this.spell});

  @override
  Widget build(BuildContext context) {
    final cat = _category(spell);
    final flavor = spellDescriptions[spell.id];

    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header + vitals
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderDim)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.panelHi,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          spellIcons[spell.id] ?? Icons.auto_fix_high,
                          size: 20,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spell.name,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (flavor != null)
                              Text(
                                flavor,
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(
                        spell.xCost ? 'X charge' : '${spell.chargeCost} charge',
                        leadColor: AppColors.sky,
                      ),
                      _chip(
                        'priority ${spell.priority} · '
                        '${priorityLabel(spell.priority)}',
                      ),
                      _chip(
                        cat.label,
                        borderColor: cat.color,
                        textColor: cat.color,
                      ),
                      if (spell.grantsHaste && spell.effect is! HasteEffect)
                        _chip(
                          'seizes Haste',
                          borderColor: AppColors.teal,
                          textColor: AppColors.teal,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _numbers(spell),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _numbersLabel(spell),
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'HOW THE SYSTEMS TOUCH IT',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 10.5,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final rule in _systemsRules(spell)) _bullet(rule),
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 8),
            child: Icon(Icons.circle, size: 5, color: AppColors.gold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text, {
    Color? borderColor,
    Color? textColor,
    Color? leadColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.panelHi,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? AppColors.borderDim),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? leadColor ?? AppColors.textDim,
          fontSize: 11.5,
        ),
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
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
