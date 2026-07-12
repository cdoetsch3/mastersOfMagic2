import 'dart:math';

import 'action.dart';
import 'element.dart';
import 'mage.dart';
import 'spell.dart';
import 'spellbook.dart';

/// A duel decision-maker. Monsters, practice bots, and the balance simulator
/// all implement this.
abstract interface class DuelAi {
  MageAction chooseAction(MageState self, MageState enemy, Random rng);
}

/// Expected damage of [spell] cast by [self] against [enemy] right now,
/// accounting for the enemy's current shield. Shared AI helper.
int estimateDamage(Spell spell, MageState self, MageState enemy) {
  final element = self.element;
  int raw;
  switch (spell.effect) {
    case DamageEffect(:final amount, :final hits):
      raw = amount * hits * (self.empowerMultiplier ?? 1);
    case BarrageEffect(:final damagePerCharge):
      raw = damagePerCharge * self.charge * (self.empowerMultiplier ?? 1);
    default:
      return 0;
  }
  final shield = enemy.shield;
  if (shield == null || self.phaseNext) return raw;
  if (shield.isBarrier) return 0;
  final countered =
      element != null && shield.element != null && element.counters(shield.element!);
  final multiplier = countered ? 2 : 1;
  final effective = raw * multiplier;
  if (effective <= shield.remaining) return 0;
  return raw - (shield.remaining + multiplier - 1) ~/ multiplier;
}

List<Spell> _affordable(MageState self, List<Spell> spells) => [
      for (final s in spells)
        if (s.xCost ? self.charge >= 1 : s.chargeCost <= self.charge) s,
    ];

/// Picks any legal move uniformly. The baseline sparring partner.
class RandomAi implements DuelAi {
  final List<Spell> spells;

  RandomAi({this.spells = Spellbook.all});

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) {
    final element = self.element ??
        MagicElement.values[rng.nextInt(MagicElement.values.length)];
    final options = <MageAction>[
      if (self.charge < MageState.maxCharge)
        ChargeAction(self.charge == 0 ? element : null),
      for (final s in _affordable(self, spells))
        CastAction(s, self.charge == 0 ? element : null),
    ];
    return options[rng.nextInt(options.length)];
  }
}

/// A simple heuristic opponent: kills when it can, shields when threatened,
/// otherwise builds charge toward big spells.
class GreedyAi implements DuelAi {
  final List<Spell> spells;

  GreedyAi({this.spells = Spellbook.all});

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) {
    final element = self.element ??
        MagicElement.values[rng.nextInt(MagicElement.values.length)];
    MagicElement? elementArg() => self.charge == 0 ? element : null;
    final affordable = _affordable(self, spells);

    // Take a kill if one is on the board.
    for (final spell in affordable) {
      if (spell.isOffensive &&
          estimateDamage(spell, self, enemy) >= enemy.hp) {
        return CastAction(spell, elementArg());
      }
    }

    // At full charge, unleash the biggest hit.
    if (self.charge >= MageState.maxCharge) {
      final best = affordable.where((s) => s.isOffensive).reduce((a, b) =>
          estimateDamage(a, self, enemy) >= estimateDamage(b, self, enemy)
              ? a
              : b);
      return CastAction(best, elementArg());
    }

    // Shield up sometimes when the enemy is sitting on a big charge.
    if (enemy.charge >= 3 && self.shield == null && rng.nextDouble() < 0.5) {
      final shieldSpells = affordable
          .where((s) => s.effect is ShieldEffect || s.effect is BarrierEffect)
          .toList();
      if (shieldSpells.isNotEmpty) {
        shieldSpells.sort((a, b) => b.chargeCost.compareTo(a.chargeCost));
        return CastAction(shieldSpells.first, elementArg());
      }
    }

    // Mostly keep charging; occasionally poke.
    if (self.charge < MageState.maxCharge && rng.nextDouble() < 0.75) {
      return ChargeAction(elementArg());
    }
    final attacks = affordable.where((s) => s.isOffensive).toList();
    if (attacks.isEmpty) return ChargeAction(elementArg());
    attacks.sort((a, b) => estimateDamage(b, self, enemy)
        .compareTo(estimateDamage(a, self, enemy)));
    return CastAction(attacks.first, elementArg());
  }
}
