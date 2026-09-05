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
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: SpellDetailCard(spell: spell),
    ),
  );
}

({String label, Color color}) _category(Spell spell) => switch (spell.effect) {
  DamageEffect() ||
  BarrageEffect() ||
  OverloadEffect() => (label: 'damaging', color: AppColors.ember),
  ShieldEffect() || BarrierEffect() => (label: 'shield', color: AppColors.sky),
  // The aux split (2026-08-29): the Discharge family is the whole §7a
  // aux-offense lane; every other non-damaging effect is aimed at yourself.
  DischargeEffect() => (label: 'aux-offense', color: AppColors.gem),
  _ => (label: 'aux-self', color: AppColors.gold),
};

/// The headline figure — kept short so it never crowds the label beside it.
String _numbers(Spell spell) => switch (spell.effect) {
  // ⚠️ Subtype arms before their parents — the bank's effects extend shipped
  // ones, and a sealed switch matches in order.
  DotAttackEffect(
    :final minAmount,
    :final maxAmount,
    :final damagePerTick,
    :final ticks,
  ) =>
    '$minAmount–$maxAmount +$damagePerTick×$ticks',
  DebuffGrantEffect(:final debuff, :final magnitude, :final turns) =>
    switch (debuff) {
      BankDebuff.blight => '$turns turns',
      _ => '$magnitude${debuff == BankDebuff.wither ? '%' : ''}',
    },
  FesterEffect(:final bonusTicks) => '+$bonusTicks',
  ScourEffect() => 'All ticks',
  DispelEffect() => 'Buffs',
  ShatterEffect() => 'Defences',
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
  // ⚠️ The headline for each rider is its own name, not a shared 'Pierce' —
  // that label predated the spell actually called Pierce (§7a).
  PhaseEffect(:final bypass) => switch (bypass) {
    AttackBypass.shields => 'Phase',
    AttackBypass.deflection => 'Pierce',
    AttackBypass.evasion => 'Unerring',
  },
  HasteEffect() => 'Haste',
  DischargeEffect() => 'All',
  HallowEffect() => 'Grace',
  // The banked self-instants (§7a). Sealed switch: these arms are not optional.
  CleanseEffect(:final all) => all ? 'All' : 'One',
  MeditateEffect(:final bonusTurns) => '+$bonusTurns',
  // A banked stance (TYPE_EFFECTS §7a): the headline is the COMMITMENT,
  // because that is what separates a set's two price points — the magnitudes
  // are close, the clocks are not. ⚠️ [SpellEffect] is sealed, so this arm is
  // not optional.
  StanceEffect(:final grants) => '${_stanceTurns(grants)} turns',
};

/// Turns the stance [grants] would land for — 0 for a grant that cannot
/// describe itself (nothing in the bank, but the type allows it).
///
/// ⚠️ The LONGEST of them, for the one spell that grants more than one
/// (Bloodlust). Its two grants share a clock today; the max is what keeps the
/// headline honest if they ever stop.
int _stanceTurns(List<StanceGrant> grants) => grants.fold(0, (longest, g) {
  final granted = g.build();
  final turns = granted is StanceDescribing
      ? (granted as StanceDescribing).turnsLeft
      : 0;
  return turns > longest ? turns : longest;
});

/// The qualifier beside the figure — carries the prose, and is free to wrap.
String _numbersLabel(Spell spell) => switch (spell.effect) {
  // ⚠️ Subtype arms before their parents, same as [_numbers].
  DotAttackEffect(:final dotName, :final ticks) =>
    'damage now, then the $dotName bleed at the end of each of your next '
        '$ticks turns. Recasting refreshes it — burns never stack',
  DebuffGrantEffect(:final debuff, :final turns) => switch (debuff) {
    BankDebuff.murk => 'to their accuracy for $turns turns — stacks with '
        'Blind, which is a different source',
    BankDebuff.wither =>
      'to all healing they receive for $turns turns — potions, heals over '
          'time and lifesteal alike',
    BankDebuff.blight =>
      'of their heals landing as DAMAGE instead — and it overrides Wither '
          'entirely while both are up',
  },
  FesterEffect(:final damage) =>
    'ticks added to every burn on them, behind a $damage-damage hit — '
        'Ignite included, and it catches a burn on its final tick',
  ScourEffect() =>
    'paid out at once as ONE hit — one shield to meet, one deflect roll — '
        'and the burns are consumed',
  DispelEffect() =>
    'stripped from them — stances, pending riders and Grace alike. Arcane '
        'Knowledge is never stripped',
  ShatterEffect() =>
    'destroyed at once: their shield, every Barrier point and their Divert '
        'stance. Gear deflection survives; no damage is dealt',
  DamageEffect(:final lifesteal, :final executeBelowPercent) =>
    '${lifesteal > 0
        // 📝 "health they lose", not "damage that reaches their health" —
        // overkill pays nothing (playtest ruling), so a killing blow heals
        // for the sliver they had left, and the copy must not promise more.
        ? 'damage — heals you for ${(lifesteal * 100).round()}% of the '
              'health they actually lose'
        : 'damage, rolled on cast'}'
        '${executeBelowPercent > 0 ? ' — and always a crit while they are below $executeBelowPercent% health' : ''}',
  BarrageEffect() => 'damage, one hit per charge spent',
  OverloadEffect() => "damage per point of the enemy's charge",
  ShieldEffect() => 'shield in your element',
  BarrierEffect() => 'of Barrier (max 3) — each point blocks one whole hit',
  EmpowerEffect() => 'damage on your next offensive spell',
  QuickenEffect() => 'your next offensive spell resolves sooner',
  PhaseEffect(:final bypass) => switch (bypass) {
    AttackBypass.shields => 'your next offensive spell ignores shields',
    AttackBypass.deflection =>
      "banked — your next offensive spell cannot be deflected; the enemy's "
          'Divert does not roll against it',
    AttackBypass.evasion =>
      'banked — your next offensive spell cannot miss, whatever the dodge',
  },
  HasteEffect() => 'seized — you win same-speed ties',
  DischargeEffect() => "of the enemy's charge, wiped",
  HallowEffect() => 'banked — it blocks the next debuff applied to you',
  CleanseEffect(:final all) => all
      ? 'debuff removed from you at once — buffs and stances are untouched'
      : 'debuff of your choice, removed from you',
  MeditateEffect() => 'turns added to every buff of yours that runs on a clock',
  final StanceEffect stance => _stanceLabel(stance),
};

/// The prose beside a stance's headline: which status it grants, at what
/// numbers, what the cast also clears, and — the rule players most need told —
/// that the set's other price point would replace it (§7a law 5).
String _stanceLabel(StanceEffect effect) {
  final each = effect.grants.map((g) {
    final granted = g.build();
    final numbers = granted is StanceDescribing
        ? ': ${(granted as StanceDescribing).grantLine}'
        : '';
    return '${_statusName(g.statusId)}$numbers';
  }).join(', and ');
  final cleanses = effect.cleanses;
  final cleared = cleanses == null
      ? ''
      : ', and the cast clears ${_statusName(cleanses.statusId)}';
  return 'of $each$cleared. Casting another granter of the same stance '
      'replaces it';
}

String _statusName(String statusId) =>
    StatusCatalog.byId(statusId)?.name ?? statusId;

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

/// The spell detail card — the same panel whether it opens as the ⓘ dialog
/// or floats on hover over a Spellbook tile (designer's ask, 2026-08-29: the
/// Material tooltip's black-on-white text was a second, poorer version of
/// this). [showDone] adds the dialog's Done bar; a hover card has no button
/// to press, so it omits it. [note] is an extra line under the flavor text
/// (the locked preview's "Unlocks at level N").
class SpellDetailCard extends StatelessWidget {
  final Spell spell;
  final bool showDone;
  final String? note;
  const SpellDetailCard({
    super.key,
    required this.spell,
    this.showDone = true,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final cat = _category(spell);
    final flavor = spellDescriptions[spell.id];

    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
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
                            if (note != null)
                              Text(
                                note!,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11.5,
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
                    // The rules follow the numbers with no heading — the
                    // "HOW THE SYSTEMS TOUCH IT" label explained nothing to
                    // the designer, and a list needs no announcement.
                    const SizedBox(height: 10),
                    for (final rule in _systemsRules(spell)) _bullet(rule),
                  ],
                ),
              ),
            ),
            if (showDone) _doneBar(context),
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
