import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The base crit (ruling, Christian, playtest 2026-09-30, note 10): "Base crit
/// chance should be 5%, base crit damage should be 100% (doubling)."
///
/// ⭐ Every other engine test that asserts exact damage pins `critChance = 0`
/// so a base crit cannot flake it. This file is the one that leaves the base
/// alone and proves it is really there, at the ruled numbers, in a real duel.

/// Counts `nextInt` draws over a real [Random], so a test can see whether the
/// crit roll happened at all.
class _CountingRandom implements Random {
  final Random _inner;
  var intCalls = 0;
  _CountingRandom(int seed) : _inner = Random(seed);
  @override
  int nextInt(int max) {
    intCalls++;
    return _inner.nextInt(max);
  }

  @override
  double nextDouble() => _inner.nextDouble();
  @override
  bool nextBool() => _inner.nextBool();
}

Spell _dmg(int amount) => Spell(
  id: 'dmg$amount',
  name: 'Dmg$amount',
  chargeCost: 0,
  priority: 9,
  effect: DamageEffect(amount, amount),
);

void main() {
  /// One 20-damage hit from a DEFAULT mage (no crit gear, nothing pinned)
  /// into a defender, on [rng]. Returns whether it crit and what is left.
  (bool, int) hitOnce(Random rng) {
    final alice = MageState(name: 'Alice')..element = MagicElement.flora;
    final bruno = MageState(name: 'Bruno');
    final duel = DuelEngine(
      alice,
      bruno,
      rng: rng,
      elementEffects: false,
      baseMissPercent: 0,
    );
    final r = duel.resolveTurn(
      CastAction(_dmg(20), MagicElement.flora),
      const ForfeitAction(),
    );
    return (r.events.whereType<DamageEvent>().single.crit, bruno.hp);
  }

  group('a fresh mage', () {
    test('⭐ starts at 5% crit chance and +100% crit damage', () {
      final m = MageState(name: 'Fresh');
      expect(
        m.critChance,
        5,
        reason:
            '⚠️ kills the pre-ruling default of 0 — crits existed only '
            'through gear before 2026-09-30',
      );
      expect(
        m.critDamage,
        100,
        reason: '⚠️ kills the pre-ruling +50 (a crit dealt 150%, not 200%)',
      );
      expect(
        [MageState.baseCritChance, MageState.baseCritDamage],
        [m.critChance, m.critDamage],
        reason:
            'the field defaults read the consts — kills a const retuned '
            'without the field following it (or vice versa)',
      );
      expect(
        [m.effectiveCritChance, m.effectiveCritDamage],
        [5, 100],
        reason: 'and the derived figures the duel reads start there too',
      );
    });
  });

  group('the base crit in a real duel', () {
    test('⭐ seed 1: a gearless hit crits at the base and deals exactly 2×', () {
      // ⭐ Found by search (2026-09-30): seed 1 is the first seed whose crit
      // roll lands under 5 for this hit. Seed 0, the control below, does not.
      final (crit, hp) = hitOnce(Random(1));
      expect(
        crit,
        isTrue,
        reason:
            '⚠️ kills a base chance of 0: the roll is skipped and the hit '
            'can never crit',
      );
      expect(
        hp,
        100 - 40,
        reason:
            '⚠️ kills the old +50 base: 20 × 1.5 = 30 leaves hp 70. The '
            'ruling doubles it: 20 × 2 = 40',
      );
    });

    test('seed 0: the same hit without the crit lands flat', () {
      final (crit, hp) = hitOnce(Random(0));
      expect(
        crit,
        isFalse,
        reason:
            '⚠️ kills a base that crits every hit (critChance 100) — the '
            'seed-1 crit is the 5% roll, not a guarantee',
      );
      expect(hp, 80, reason: 'an ordinary 20, unmultiplied');
    });

    test('over 4000 seeded hits the base crits about 1 in 20', () {
      final alice = MageState(name: 'Alice', maxHp: 1 << 30)
        ..element = MagicElement.flora;
      final bruno = MageState(name: 'Bruno', maxHp: 1 << 30);
      final duel = DuelEngine(
        alice,
        bruno,
        rng: Random(42),
        elementEffects: false,
        baseMissPercent: 0,
      );
      var crits = 0;
      for (var i = 0; i < 4000; i++) {
        final r = duel.resolveTurn(
          CastAction(_dmg(20), MagicElement.flora),
          const ForfeitAction(),
        );
        if (r.events.whereType<DamageEvent>().single.crit) crits++;
      }
      // 📝 Seed 42 measures 218 / 4000 = 5.45%.
      expect(
        crits * 100 / 4000,
        closeTo(5.0, 1.0),
        reason:
            '⚠️ kills a base of 0 (0%) and a base read as a fraction or '
            'doubled (10%) — the rate IS the ruled 5%',
      );
    });

    test('⚠️ every default hit draws a crit roll; a pinned 0 draws none', () {
      // The trap the base opens: the engine's guard skips the crit draw only
      // at 0, so a default mage now consumes one more RNG value per hit than
      // the pre-ruling engine did. Lockstep is safe (both clients build the
      // same mages), but a seeded test asserting exact damage must pin 0.
      int drawsFor({required bool pinned}) {
        final rng = _CountingRandom(0);
        final alice = MageState(name: 'Alice')..element = MagicElement.flora;
        if (pinned) alice.critChance = 0;
        final duel = DuelEngine(
          alice,
          MageState(name: 'Bruno'),
          rng: rng,
          elementEffects: false,
          baseMissPercent: 0,
        );
        duel.resolveTurn(
          CastAction(_dmg(20), MagicElement.flora),
          const ForfeitAction(),
        );
        return rng.intCalls;
      }

      expect(
        drawsFor(pinned: false) - drawsFor(pinned: true),
        1,
        reason:
            '⚠️ kills a base of 0 (no extra draw) and a crit roll that '
            'ignores the guard (a pinned 0 would draw too, difference 0)',
      );
    });
  });
}
