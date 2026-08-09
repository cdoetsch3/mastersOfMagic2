/// The gear stats task #2 added to the engine (ITEMS §9b.8): the 80% base
/// hit chance, shield strength %, healing received %, Regrow, and the
/// heal-over-time primitive.
///
/// ⭐ Mutation-verified: each test names the wrong implementation it kills.
library;

import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// `nextDouble` returns scripted values then 0.99 forever; `nextInt` 0, so
/// damage rolls take their minimum and guarded chance rolls fire.
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

Spell dmg(int amount) => Spell(
    id: 'dmg$amount',
    name: 'Dmg$amount',
    chargeCost: 0,
    priority: 9,
    effect: DamageEffect(amount, amount));

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

  group('the 80% base hit chance', () {
    test('a default cast misses on a roll under 20', () {
      // 0.19 → 19 < 20 → miss. ⚠️ Kills the old always-hit default.
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.19]));
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 100, reason: 'one cast in five whiffs, ruled §9b.8');
    });

    test('the same roll at 20+ hits', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.20]));
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 80);
    });

    test('+20 accuracy gear restores certainty', () {
      alice.accuracyBonus = 20;
      // 0.0 would miss at base — with the gap closed nothing can.
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 80, reason: 'gear closes the gap, the whole point');
    });

    test('⚠️ Astral pays the base too — it slips evasion, not the world', () {
      // Astral is exempt from dodge and Blind (§4b), and that must NOT
      // quietly extend to the universal base or Astral is 25% more accurate
      // than every element for free.
      bruno.dodge = 40;
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.19, 0.21]));
      cast(duel, dmg(20), MagicElement.astral);
      expect(bruno.hp, 100, reason: '19 < 20: the base still applies');
      cast(duel, dmg(20), MagicElement.astral);
      expect(bruno.hp, 80, reason: '21 ≥ 20: dodge was rightly ignored');
    });
  });

  group('shield strength %', () {
    test('a shield rolls stronger for its caster, and only its caster', () {
      alice.shieldStrengthPercent = 10;
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      const shield = Spell(
          id: 'sh',
          name: 'Shield',
          chargeCost: 1,
          priority: 5,
          effect: ShieldEffect(20, 20));
      alice
        ..charge = 1
        ..element = MagicElement.aqua;
      duel.resolveTurn(
          const CastAction(shield, MagicElement.aqua), const ForfeitAction());
      expect(alice.shield?.remaining, 22, reason: '20 × 1.10');
      expect(bruno.shield, isNull);
    });
  });

  group('healing received %', () {
    test('lifesteal heals more through the one door, and the event tells '
        'the truth', () {
      alice.healingReceivedPercent = 10;
      alice.hp = 50;
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      const drain = Spell(
          id: 'drain',
          name: 'Drain',
          chargeCost: 0,
          priority: 9,
          effect: DamageEffect(20, 20, lifesteal: 0.5));
      final result = duel.resolveTurn(
          const CastAction(drain, MagicElement.flora), const ForfeitAction());
      // 20 damage → 10 lifesteal → ×1.10 → 11.
      expect(alice.hp, 61, reason: '⚠️ kills applying the % outside heal()');
      final healed = result.events.whereType<HealedEvent>().single;
      expect(healed.amount, 11,
          reason: 'the event must report what actually happened');
    });
  });

  group('Regrow (The Charlock)', () {
    test('ticks at end of every turn and never expires', () {
      alice
        ..hp = 50
        ..statuses.add(RegrowStatus(2));
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      cast(duel, dmg(1), MagicElement.flora);
      expect(alice.hp, 52, reason: '2% of 100');
      cast(duel, dmg(1), MagicElement.flora);
      expect(alice.hp, 54, reason: '⚠️ kills a one-shot implementation');
      expect(alice.statuses.whereType<RegrowStatus>(), isNotEmpty,
          reason: 'worn gear does not expire');
    });

    test('healing received % multiplies the tick', () {
      alice
        ..hp = 50
        ..healingReceivedPercent = 50
        ..statuses.add(RegrowStatus(2));
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      cast(duel, dmg(1), MagicElement.flora);
      expect(alice.hp, 53, reason: '2 × 1.5 — all healing walks one door');
    });
  });

  group('heal over time (the Tonic shape)', () {
    test('ticks for its duration, then leaves', () {
      alice
        ..hp = 50
        ..statuses
            .add(HealOverTimeStatus(percentPerTurn: 9, turnsLeft: 3));
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      for (var t = 0; t < 3; t++) {
        cast(duel, dmg(1), MagicElement.flora);
      }
      expect(alice.hp, 50 + 27, reason: '9 × 3 ticked (the caster is unhit)');
      cast(duel, dmg(1), MagicElement.flora);
      expect(alice.hp, 50 + 27,
          reason: '⚠️ a fourth tick means expiry never ran');
      expect(alice.statuses.whereType<HealOverTimeStatus>(), isEmpty);
    });
  });
}
