import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Deterministic RNG: `nextDouble` returns scripted values then 0.99 forever;
/// `nextInt` returns 0 (so a guarded crit/deflect chance always fires when it
/// is > 0, and damage rolls take their minimum).
class ScriptedRandom implements Random {
  final List<double> doubles;
  var _i = 0;
  ScriptedRandom([this.doubles = const []]);
  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

Spell dmg(int amount, {int hits = 1}) => Spell(
    id: 'dmg$amount', name: 'Dmg$amount', chargeCost: 0, priority: 9,
    effect: DamageEffect(amount, amount, hits: hits));

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  void cast(DuelEngine d, Spell s, MagicElement e) {
    alice
      ..charge = s.chargeCost
      ..element = e;
    d.resolveTurn(CastAction(s, e), const ForfeitAction());
  }

  // ======================================================================
  // Accuracy & dodge — a single unified hit roll (§5.2 step 3)
  // ======================================================================
  group('accuracy & dodge', () {
    test('default stats always hit', () {
      // 100 accuracy, 0 dodge → the full 20 lands. (That the default path
      // draws *no* RNG isn't proven here — a missPercent of 0 never rolls
      // regardless — but by the sim staying byte-identical to Phase 3.)
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 80, reason: '100 accuracy, 0 dodge → always lands');
    });

    test('dodge subtracts from accuracy, creating a miss chance', () {
      bruno.dodge = 30; // 100 − 30 = 70 hit → 30 miss
      // 0.2 → 20 < 30 → miss.
      var duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.2]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100, reason: 'rolled a miss');

      // 0.5 → 50 < 30 is false → hit.
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno')..dodge = 30;
      duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.5]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 80, reason: 'rolled a hit');
    });

    test('accuracy above 100 claws back dodge (120 − 30 = 90 hit)', () {
      // With +20 gear accuracy the miss chance is only 10%, not 30%.
      bruno.dodge = 30;
      alice.accuracyBonus = 20;
      // 0.2 → 20 < 10 is false → hits (a 100-accuracy attacker would miss here).
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.2]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 80, reason: 'the extra accuracy turned a miss into a hit');
    });

    test('accuracy above 100 is not clamped — a miss chance can still exist',
        () {
      bruno.dodge = 30;
      alice.accuracyBonus = 20; // 90 hit → 10 miss
      // 0.05 → 5 < 10 → still a miss: 120 accuracy does not fully cancel dodge.
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.05]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100);
    });

    test('Blind is exactly a flat −50 accuracy penalty', () {
      // Unblinded 100-accuracy attacker never misses...
      var duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.4]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 80);

      // ...but with Blind active (−50 → 50 hit / 50 miss), 0.4 misses.
      alice = MageState(name: 'Alice')
        ..statuses.add(BlindStatus()..advanceAndCheckExpiry(alice));
      bruno = MageState(name: 'Bruno');
      duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.4]));
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100, reason: '0.4 < 0.5 → the blinded attack misses');
    });
  });

  // ======================================================================
  // Crit — per hit (§5.2 step 4/5)
  // ======================================================================
  group('crit', () {
    test('a crit multiplies damage by (1 + critDamage)', () {
      alice
        ..critChance = 100
        ..critDamage = 50; // ×1.5
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 70, reason: '20 × 1.5 = 30');
    });

    test('crit is emitted on the DamageEvent', () {
      alice.critChance = 100;
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final r = duel.resolveTurn(
          CastAction(dmg(20), MagicElement.pyro), const ForfeitAction());
      expect(r.events.whereType<DamageEvent>().single.crit, isTrue);
    });

    test('crit rolls per hit — a whole multi-hit spell crits together here',
        () {
      alice
        ..critChance = 100
        ..critDamage = 50;
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      cast(duel, dmg(4, hits: 3), MagicElement.pyro); // 4×1.5 = 6, ×3 = 18
      expect(bruno.hp, 82);
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final r = duel.resolveTurn(
          CastAction(dmg(4, hits: 3), MagicElement.pyro), const ForfeitAction());
      expect(r.events.whereType<DamageEvent>().where((e) => e.crit).length, 3);
    });
  });

  // ======================================================================
  // Deflection — defender side, per hit (§5.2 step 6). Pure reduction.
  // ======================================================================
  group('deflection', () {
    test('a deflect removes a percent of the incoming hit', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 40;
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 88, reason: '40% of 20 = 8 removed, 12 lands');
    });

    test('the removed amount is reported, and is reduction not reflection', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 40;
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final r = duel.resolveTurn(
          CastAction(dmg(20), MagicElement.pyro), const ForfeitAction());
      expect(r.events.whereType<DamageEvent>().single.deflected, 8);
      expect(alice.hp, 100, reason: 'nothing is bounced back to the attacker');
    });

    test('deflectAmount is clamped to 100 — damage never goes negative', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 120; // engine clamps to 100 (50% player cap is gear)
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100, reason: 'all removed, not negative');
    });
  });

  // ======================================================================
  // Interaction: crit then deflect on the same hit (order matters)
  // ======================================================================
  test('crit raises the hit, then deflection reduces the crit', () {
    alice
      ..critChance = 100
      ..critDamage = 50; // 20 → 30
    bruno
      ..deflectChance = 100
      ..deflectAmount = 50; // 30 → 15 removed, 15 lands
    final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
    cast(duel, dmg(20), MagicElement.pyro);
    expect(bruno.hp, 85, reason: '20 ×1.5 = 30, then −50% = 15 lands');
  });
}
