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

/// Expected (average) damage of [spell] cast by [self] against [enemy] right
/// now, accounting for the enemy's current shield. Shared AI helper.
int estimateDamage(Spell spell, MageState self, MageState enemy) {
  final element = self.element;
  int raw;
  switch (spell.effect) {
    case DamageEffect(:final minAmount, :final maxAmount, :final hits):
      raw = ((minAmount + maxAmount) * hits ~/ 2) * (self.empowerMultiplier ?? 1);
    case BarrageEffect(:final minPerCharge, :final maxPerCharge):
      raw = ((minPerCharge + maxPerCharge) * self.charge ~/ 2) *
          (self.empowerMultiplier ?? 1);
    case OverloadEffect(:final minPerCharge, :final maxPerCharge):
      raw = ((minPerCharge + maxPerCharge) * enemy.charge ~/ 2) *
          (self.empowerMultiplier ?? 1);
    default:
      return 0;
  }
  final shield = enemy.shield;
  if (shield == null || self.phaseNext) return raw;
  if (shield.isBarrier) return 0;
  // Mirror the engine's §0.3 shield math so the AI values a hit correctly.
  final pct = shieldMultiplierPercent(element, shield.element!);
  final effective = raw * pct ~/ 100;
  if (effective <= shield.remaining) return 0;
  return raw - (shield.remaining * 100 + pct - 1) ~/ pct;
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

/// A parameterized heuristic brain for AI personas of different skill.
///
/// Behaves like [GreedyAi] at its sharpest, but every instinct is a dial:
///  - [mistakeChance]: odds of playing a random legal move instead of
///    thinking (the main difficulty dial — novices blunder, masters don't).
///  - [aggression]: odds of attacking instead of continuing to charge.
///  - [caution]: odds of shielding when the enemy sits on a big charge.
class TunableAi implements DuelAi {
  final List<Spell> spells;
  final double mistakeChance;
  final double aggression;
  final double caution;

  TunableAi({
    this.spells = Spellbook.all,
    this.mistakeChance = 0.25,
    this.aggression = 0.3,
    this.caution = 0.4,
  });

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) {
    final element = self.element ??
        MagicElement.values[rng.nextInt(MagicElement.values.length)];
    MagicElement? elementArg() => self.charge == 0 ? element : null;
    final affordable = _affordable(self, spells);

    // A blunder: play anything legal, without thinking.
    if (rng.nextDouble() < mistakeChance) {
      final options = <MageAction>[
        if (self.charge < MageState.maxCharge) ChargeAction(elementArg()),
        for (final s in affordable) CastAction(s, elementArg()),
      ];
      return options[rng.nextInt(options.length)];
    }

    // Take a kill if one is on the board.
    for (final spell in affordable) {
      if (spell.isOffensive &&
          estimateDamage(spell, self, enemy) >= enemy.hp) {
        return CastAction(spell, elementArg());
      }
    }

    // At full charge, unleash the biggest hit.
    if (self.charge >= MageState.maxCharge) {
      final offense = affordable.where((s) => s.isOffensive).toList();
      if (offense.isNotEmpty) {
        offense.sort((a, b) => estimateDamage(b, self, enemy)
            .compareTo(estimateDamage(a, self, enemy)));
        return CastAction(offense.first, elementArg());
      }
    }

    // Shield when threatened (enemy sitting on a big charge).
    if (enemy.charge >= 3 &&
        self.shield == null &&
        rng.nextDouble() < caution) {
      final shieldSpells = affordable
          .where((s) => s.effect is ShieldEffect || s.effect is BarrierEffect)
          .toList();
      if (shieldSpells.isNotEmpty) {
        shieldSpells.sort((a, b) => b.chargeCost.compareTo(a.chargeCost));
        return CastAction(shieldSpells.first, elementArg());
      }
    }

    // Otherwise: mostly charge toward bigger spells, sometimes strike now.
    final attacks = affordable.where((s) => s.isOffensive).toList();
    final canCharge = self.charge < MageState.maxCharge;
    if (attacks.isNotEmpty &&
        (!canCharge || rng.nextDouble() < aggression)) {
      attacks.sort((a, b) => estimateDamage(b, self, enemy)
          .compareTo(estimateDamage(a, self, enemy)));
      if (estimateDamage(attacks.first, self, enemy) > 0) {
        return CastAction(attacks.first, elementArg());
      }
    }
    if (canCharge) return ChargeAction(elementArg());
    if (attacks.isNotEmpty) return CastAction(attacks.first, elementArg());
    // Full charge with nothing offensive in the book — cast anything legal.
    if (affordable.isNotEmpty) {
      return CastAction(affordable.last, elementArg());
    }
    return const ForfeitAction();
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
