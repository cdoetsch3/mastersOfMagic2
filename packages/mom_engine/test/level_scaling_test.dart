import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Level scales BOTH health and damage, geometrically (4%/level compounding).
///
/// ⚠️ The damage half once shipped missing while the health half worked: a
/// level-60 boss had 683 HP and still hit for level-1 numbers. Health and
/// damage are scaled in different files, so they must be asserted separately —
/// checking the constant, or the formula, or max HP proves nothing about what
/// a spell actually does.
void main() {
  /// Total damage a level-[level] mage deals with one Bolt, averaged over
  /// enough seeds that the roll range cannot mask a missing multiplier.
  double averageBoltDamage(int level) {
    var total = 0;
    const trials = 400;
    for (var seed = 0; seed < trials; seed++) {
      final a = MageState(name: 'A', level: level);
      final b = MageState(name: 'B', maxHp: 100000);
      a
        ..charge = 1
        ..element = MagicElement.pyro;
      DuelEngine(a, b, rng: Random(seed), elementEffects: false)
          .resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      total += 100000 - b.hp;
    }
    return total / trials;
  }

  test('health scales geometrically with level', () {
    expect(MageState(name: 'x').maxHp, 100);
    expect(MageState(name: 'x', level: 3).maxHp, 108); // 1.04^2
    expect(MageState(name: 'x', level: 60).maxHp,
        MageState.scaledMaxHp(60));
    expect(MageState(name: 'x', level: 60).maxHp, greaterThan(900));
  });

  test('DAMAGE scales geometrically with level too', () {
    final atOne = averageBoltDamage(1);
    final atTwentyFive = averageBoltDamage(25);
    final atSixty = averageBoltDamage(60);

    expect(atTwentyFive, greaterThan(atOne * 2),
        reason: 'level 25 is 1.04^24 = ~2.56x a level 1');
    expect(atSixty, greaterThan(atOne * 8),
        reason: 'level 60 is 1.04^59 = ~10x a level 1');

    // And it tracks the same curve health uses, not some other multiplier.
    final expected = atOne * MageState(name: 'x', level: 60).levelScale;
    expect(atSixty, closeTo(expected, expected * 0.08));
  });

  test('an even-level duel is unchanged, which is what keeps balance valid',
      () {
    // Same level on both sides -> the ratio of damage to health is identical
    // at every level, so every figure tuned at level 1 still holds.
    for (final level in [1, 10, 30, 60]) {
      final m = MageState(name: 'x', level: level);
      expect(averageBoltDamage(level) / m.maxHp,
          closeTo(averageBoltDamage(1) / 100, 0.02),
          reason: 'level $level shifted the damage-to-health ratio');
    }
  });

  test('SHIELDS scale geometrically with level too', () {
    // ⚠️ Asserted separately from damage. Shields are rolled in their own
    // branch, so "damage scales" proves nothing about them — and an unscaled
    // shield quietly stops being a defence as levels climb.
    int shieldAt(int level) {
      final a = MageState(name: 'A', level: level);
      final b = MageState(name: 'B');
      a
        ..charge = 2
        ..element = MagicElement.aqua;
      DuelEngine(a, b, rng: Random(4), elementEffects: false)
          .resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      return a.shield!.remaining;
    }

    final atOne = shieldAt(1);
    final atSixty = shieldAt(60);
    expect(atSixty, greaterThan(atOne * 8), reason: '1.04^59 is ~10x');
    expect(
      atSixty,
      closeTo(atOne * MageState(name: 'x', level: 60).levelScale, atOne * 0.5),
      reason: 'shields must ride the SAME curve as health and damage',
    );
  });

  test('Ignite breaks the whole Flora streak, not just Photosynthesis', () {
    // ⚠️ Stripping only the Photosynthesis status would let it return on the
    // very next Flora cast, so Ignite would counter nothing.
    final a = MageState(name: 'A');
    final b = MageState(name: 'B');
    final duel = DuelEngine(a, b, rng: Random(3));

    for (var i = 0; i < 3; i++) {
      a
        ..charge = 1
        ..element = MagicElement.aqua;
      b
        ..charge = 1
        ..element = MagicElement.flora;
      duel.resolveTurn(
        const ChargeAction(MagicElement.aqua),
        CastAction(Spellbook.flick),
      );
    }
    expect(b.streakElement, MagicElement.flora);
    expect(b.streakCount, 3);

    a
      ..charge = 3
      ..element = MagicElement.pyro;
    b
      ..charge = 1
      ..element = MagicElement.flora;
    duel.resolveTurn(
      CastAction(Spellbook.surge),
      const ChargeAction(MagicElement.flora),
    );

    expect(b.statuses.whereType<IgniteStatus>(), isNotEmpty);
    expect(b.streakElement, isNull, reason: 'the whole streak is broken');
    expect(b.streakCount, 0);
  });
}
