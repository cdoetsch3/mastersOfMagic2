/// Consumable potency — the belt's stat (ruling, Christian 2026-09-25).
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — the drink that ignores the belt, the Tonic that scales only its
/// first tick (or not at all), the potency that ADDS to healing received
/// instead of multiplying it, and the float rounding that drifts.
///
/// ⚠️ Numbers of the engine's own, like `belt_item_test`: the app's
/// `test/belt_potency_test.dart` pins the shipped belts and the Sapwort 30.
library;

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

const _draught = ConsumableEffect(name: 'Test Draught', healNow: 30);
const _tonic = ConsumableEffect(
  name: 'Test Tonic',
  healPerTurn: 10,
  hotTurns: 3,
);

UseItemAction _drink(ConsumableEffect effect) =>
    UseItemAction('some_potion', effect);

void main() {
  group('applyPotency', () {
    test('⭐ 30 at +16% is 35 — rounded, not truncated', () {
      expect(
        applyPotency(30, 16),
        35,
        reason: '30 × 1.16 = 34.8; a truncating ~/ reads 34',
      );
    });

    test('half rounds away from zero, in integers', () {
      expect(
        applyPotency(30, 15),
        35,
        reason:
            '30 × 1.15 = 34.5 exactly — the same round-half-away rule '
            'ItemModifiers.scaledBy uses; round-half-even would read 34',
      );
    });

    test('zero potency and a zero heal are both the identity', () {
      expect(applyPotency(30, 0), 30, reason: 'no belt, no change');
      expect(applyPotency(0, 48), 0, reason: 'potency never invents a heal');
    });

    test('📝 a negative potency never turns a heal into a bite', () {
      expect(
        applyPotency(30, -200),
        0,
        reason: 'a heal floors at 0 — only Blight is allowed to bite',
      );
    });
  });

  group('in a duel', () {
    late MageState alice;
    late MageState bruno;
    late DuelEngine duel;

    setUp(() {
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno');
      duel = DuelEngine(
        alice,
        bruno,
        elementEffects: false,
        baseMissPercent: 0,
      );
    });

    test('⭐ a Draught heals by the belt\'s potency', () {
      alice.hp = 40;
      alice.consumablePotencyPercent = 20;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.hp,
        76,
        reason:
            '30 × 1.20 = 36 — a drink that skipped applyPotency restores '
            'the bare 30 and reads 70',
      );
    });

    test('⭐ a belt Tonic ticks 10 → 12 with a +20 belt, every tick', () {
      alice.hp = 20;
      alice.consumablePotencyPercent = 20;
      final ticks = <int>[];
      for (var turn = 0; turn < 4; turn++) {
        final result = duel.resolveTurn(
          turn == 0 ? _drink(_tonic) : const ChargeAction(MagicElement.pyro),
          const ChargeAction(MagicElement.geo),
        );
        for (final e in result.events.whereType<EffectHealEvent>()) {
          if (e.source == 'Test Tonic') ticks.add(e.amount);
        }
      }
      expect(
        ticks,
        [12, 12, 12],
        reason:
            'each tick is 10 × 1.20 — an unscaled Tonic ticks 10s, and a '
            'Tonic that scaled only its first tick reads [12, 10, 10]',
      );
    });

    test('⭐ potency and healing received compose multiplicatively', () {
      alice.hp = 40;
      alice.consumablePotencyPercent = 16;
      alice.healingReceivedPercent = 10;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.hp - 40,
        39,
        reason:
            '30 → 35 (potency, rounded), then 35 × 1.10 = 38.5 → 39 '
            '(healing received, rounded). Summing the two percentages '
            '(30 × 1.26 = 37.8) reads 38',
      );
    });

    test('potency is the drinker\'s own — the opponent\'s belt is not', () {
      alice.hp = 40;
      bruno.consumablePotencyPercent = 50;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.hp,
        70,
        reason:
            'Bruno\'s belt must not strengthen Alice\'s potion — a drink '
            'reading the wrong mage heals 45',
      );
    });
  });
}
