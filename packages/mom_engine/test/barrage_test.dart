import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Barrage fires one hit per charge spent (the Volley shape) rather than a
/// single scaled roll. The damage band is unchanged; what changes is that
/// every bolt meets the defences on its own.
void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  void charge(int n, [MagicElement e = MagicElement.pyro]) {
    alice
      ..charge = n
      ..element = e;
  }

  test('fires one hit per point of charge', () {
    final duel = DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
    charge(4);
    final r = duel.resolveTurn(
        CastAction(Spellbook.barrage), const ForfeitAction());
    expect(r.events.whereType<DamageEvent>(), hasLength(4));
  });

  test('a single charge is a single hit', () {
    final duel = DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
    charge(1);
    final r = duel.resolveTurn(
        CastAction(Spellbook.barrage), const ForfeitAction());
    expect(r.events.whereType<DamageEvent>(), hasLength(1));
  });

  test('the total still lands in the old band', () {
    // 7-10 per point; at 4 charge that is 28-40. Barrage is deliberately
    // weaker per hit than a committed attack: it ignores shields and can be
    // thrown at any charge, and that flexibility is what it pays for.
    for (var seed = 0; seed < 25; seed++) {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      final duel = DuelEngine(a, b, rng: Random(seed), elementEffects: false, baseMissPercent: 0);
      a
        ..charge = 4
        ..element = MagicElement.pyro;
      duel.resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction());
      expect(100 - b.hp, inInclusiveRange(28, 40), reason: 'seed $seed');
    }
  });

  test('each bolt rolls on its own, so totals cluster', () {
    // Four independent rolls of 10-12 almost never all land on an extreme.
    // One roll of 40-48 hits its own extremes far more often. Sampling both
    // ends is enough to show the rolls are separate.
    final totals = <int>{};
    for (var seed = 0; seed < 40; seed++) {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      final duel = DuelEngine(a, b, rng: Random(seed), elementEffects: false, baseMissPercent: 0);
      a
        ..charge = 4
        ..element = MagicElement.pyro;
      duel.resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction());
      totals.add(100 - b.hp);
    }
    expect(totals.length, greaterThan(1), reason: 'damage varies');
    // The all-minimum (40) and all-maximum (48) outcomes each need four
    // independent rolls to agree, so they should be rare-to-absent here.
    expect(totals.where((t) => t == 40 || t == 48).length,
        lessThan(totals.length),
        reason: 'independent rolls should not pin the extremes');
  });

  group('against defences, each bolt counts separately', () {
    test('it burns one Barrier point per bolt', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
      bruno.barrierPoints = 3;
      charge(5);
      duel.resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction());
      expect(bruno.barrierPoints, 0, reason: 'three bolts spent three points');
      expect(bruno.hp, lessThan(100),
          reason: 'bolts four and five got through');
    });

    test('a 2-charge Barrage cannot break more than two points', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
      bruno.barrierPoints = 3;
      charge(2);
      duel.resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction());
      expect(bruno.barrierPoints, 1);
      expect(bruno.hp, 100, reason: 'both bolts were absorbed');
    });

    test('each bolt is chipped by the shield separately', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
      // Solar is neutral to Pyro (opposite tiers), so the shield takes the
      // bolts at face value and the arithmetic stays clean.
      bruno.shield = ActiveShield.elemental(MagicElement.solar, 200);
      charge(3);
      final r = duel.resolveTurn(
          CastAction(Spellbook.barrage), const ForfeitAction());
      final hits = r.events.whereType<DamageEvent>().toList();
      expect(hits, hasLength(3));
      expect(hits.every((h) => h.toShield > 0 && h.toHp == 0), isTrue);
      expect(bruno.shield!.remaining, 200 - hits.fold(0, (a, h) => a + h.toShield));
    });
  });

  test('a same-turn Discharge still fizzles it outright', () {
    // Discharge (priority 7) beats Barrage (9) and empties the charge the
    // spell reads live, so there is nothing to fire.
    final duel = DuelEngine(alice, bruno, rng: Random(3), elementEffects: false, baseMissPercent: 0);
    charge(4);
    bruno
      ..charge = 2
      ..element = MagicElement.aqua;
    final r = duel.resolveTurn(
        CastAction(Spellbook.barrage), CastAction(Spellbook.discharge));
    expect(r.events.whereType<SpellFizzledEvent>(), hasLength(1));
    expect(r.events.whereType<DamageEvent>(), isEmpty);
  });
}
