import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The base crit (ruling, Christian, playtest 2026-09-30, note 10): "Base crit
/// chance should be 5%, base crit damage should be 100% (doubling)." —
/// ✅ CORRECTED 2026-10-02 (a miscommunication): "I want the base crit damage
/// to do 50% additional damage, which would be 150% as a base, not 200%. With
/// no gear stats, I'd expect a 10 damage crit to do 15 damage." The 5% chance
/// stands; the damage base is +50.
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
  /// One [amount]-damage hit (20 unless told) from a DEFAULT mage (no crit
  /// gear, nothing pinned) into a defender, on [rng]. Returns whether it crit
  /// and what is left.
  (bool, int) hitOnce(Random rng, {int amount = 20}) {
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
      CastAction(_dmg(amount), MagicElement.flora),
      const ForfeitAction(),
    );
    return (r.events.whereType<DamageEvent>().single.crit, bruno.hp);
  }

  group('a fresh mage', () {
    test('⭐ starts at 5% crit chance and +50% crit damage', () {
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
        50,
        reason:
            '⚠️ kills the 2026-09-30 +100 (a crit dealt 200%) — ruling '
            '2026-10-02: a gearless crit deals 150%',
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
        [5, 50],
        reason:
            'and the derived figures the duel reads start there too (the '
            '150% base of ruling 2026-10-02) — kills a seam that drops or '
            'doubles the base',
      );
    });
  });

  group('the base crit in a real duel', () {
    test('⭐ seed 1: a gearless hit crits at the base and deals exactly '
        '1.5×', () {
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
        100 - 30,
        reason:
            '⚠️ kills the 2026-09-30 +100 base: 20 × 2 = 40 leaves hp 60. '
            'Ruling 2026-10-02: a gearless crit deals 150%, 20 × 1.5 = 30',
      );
    });

    test('⭐ the ruling\'s own example: a gearless 10-damage crit deals 15', () {
      // Christian, 2026-10-02: "With no gear stats, I'd expect a 10 damage
      // crit to do 15 damage." Seed 1 crits this hit too (same draw order).
      final (crit, hp) = hitOnce(Random(1), amount: 10);
      expect(
        crit,
        isTrue,
        reason: '⚠️ kills a seed that stopped critting — the pin below is moot',
      );
      expect(
        hp,
        100 - 15,
        reason:
            '⚠️ the ruling verbatim (2026-10-02, 150%): kills the 2026-09-30 '
            'doubling (20, hp 80) and a crit that adds nothing (10, hp 90)',
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
