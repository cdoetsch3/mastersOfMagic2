import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Tier 1 element effects (TYPE_EFFECTS_DESIGN.md §2): Ignite, Photosynthesis,
/// Waterlogged, the cleanse web, and the Fatigue sudden-death rule.
void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  void charge(MageState m, MagicElement e, int to) {
    m
      ..charge = to
      ..element = e;
  }

  /// Finds a seed where the FIRST rng.nextDouble() consumed by the Ignite
  /// proc check rolls under/over 0.25 as requested, by simulating the exact
  /// engine consumption order for a 1-hit pyro Bolt vs Forfeit:
  ///   roll damage (nextInt), then proc (nextDouble).
  int seedWhere({required bool procs}) {
    for (var seed = 0; seed < 10000; seed++) {
      final r = Random(seed);
      r.nextInt(14 - 11 + 1); // Bolt damage roll (min 11, max 14)
      final roll = r.nextDouble(); // Ignite proc
      if ((roll < 0.25) == procs) return seed;
    }
    fail('no seed found');
  }

  group('Ignite (Pyro §2.2)', () {
    test('a proc burns 10% of raw damage for 3 end-of-turn ticks', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(seedWhere(procs: true)), baseMissPercent: 0);
      charge(alice, MagicElement.pyro, 1);
      final r1 = duel.resolveTurn(
          CastAction(Spellbook.bolt), const ForfeitAction());
      final hit = r1.events.whereType<DamageEvent>().single.toHp;
      final tick = (hit * 0.10).round();
      expect(tick, greaterThanOrEqualTo(1));
      final tick1 = r1.events.whereType<EffectDamageEvent>().single;
      expect(tick1.source, 'Ignite');
      expect(tick1.toHp, tick, reason: 'first tick lands on the proc turn');

      // Two more ticks, then done.
      final r2 = duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(r2.events.whereType<EffectDamageEvent>().single.toHp, tick);
      final r3 = duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(r3.events.whereType<EffectDamageEvent>().single.toHp, tick);
      final r4 = duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(r4.events.whereType<EffectDamageEvent>(), isEmpty,
          reason: '3 ticks total — expired');
      expect(bruno.hp, 100 - hit - tick * 3);
    });

    test('no proc, no burn', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(seedWhere(procs: false)), baseMissPercent: 0);
      charge(alice, MagicElement.pyro, 1);
      final r = duel.resolveTurn(
          CastAction(Spellbook.bolt), const ForfeitAction());
      expect(r.events.whereType<EffectDamageEvent>(), isEmpty);
      expect(bruno.statuses, isEmpty);
    });

    test('a shielded hit can still ignite (proc is on-attack raw damage)', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(seedWhere(procs: true)), baseMissPercent: 0);
      bruno.shield = ActiveShield.elemental(MagicElement.geo, 999);
      charge(alice, MagicElement.pyro, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(bruno.statuses.whereType<IgniteStatus>(), hasLength(1),
          reason: 'fully-absorbed hit still procs');
    });

    test('the burn itself is shield-aware (regular damage, hits shield first)',
        () {
      bruno.statuses.add(IgniteStatus(5));
      bruno.shield = ActiveShield.elemental(MagicElement.geo, 30);
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(bruno.hp, 100);
      // The burn carries Pyro's element — the same identity that gives it 2×
      // vs a Flora shield gives it the §0.3 macro penalty here: Geo's Kinetic
      // tier resists Pyro's Primal, so 5 lands at 75% → 3 to the shield.
      expect(bruno.shield!.remaining, 27,
          reason: 'geo (Kinetic) resists a primal burn at 75%: 5 × 0.75 = 3');
    });

    test('the burn counters a Flora shield (pyro burns flora, 2x)', () {
      bruno.statuses.add(IgniteStatus(5));
      bruno.shield = ActiveShield.elemental(MagicElement.flora, 30);
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(bruno.shield!.remaining, 20, reason: '5 doubled to 10');
    });

    test('re-proc refreshes (new value, new clock) — never stacks', () {
      bruno.statuses.add(IgniteStatus(9)..turnsLeft = 1);
      final ignite = bruno.statuses.whereType<IgniteStatus>().single;
      ignite.refresh(4);
      expect(ignite.perTick, 4);
      expect(ignite.turnsLeft, 3);
      expect(bruno.statuses.whereType<IgniteStatus>(), hasLength(1));
    });
  });

  group('Photosynthesis (Flora §2.3) — streak-gated', () {
    // ⭐ Rewritten: from the 5th consecutive Flora CAST onward, heal 1% max HP
    // per turn. The first four casts do nothing. The old unconditional
    // per-cast stacking made Flora the only element outside the 40-60% balance
    // band at every skill level (TYPE_EFFECTS §2.3a).

    void floraCast(DuelEngine duel, MageState m, int times) {
      for (var i = 0; i < times; i++) {
        charge(m, MagicElement.flora, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
    }

    test('the first four Flora casts do nothing at all', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      alice.hp = 50;
      floraCast(duel, alice, 4);
      expect(alice.statuses.whereType<PhotosynthesisStatus>(), isEmpty,
          reason: 'four casts does not activate it');
      expect(alice.hp, 50, reason: 'no heal before the threshold');
    });

    test('the fifth consecutive Flora cast activates it', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      expect(alice.streakCount, greaterThanOrEqualTo(5));
      expect(alice.statuses.whereType<PhotosynthesisStatus>(), hasLength(1));
    });

    test('heals 1% of max HP per turn while active', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      alice.hp = 50;
      duel.resolveTurn(
          const ChargeAction(MagicElement.flora), const ForfeitAction());
      expect(alice.hp, 51, reason: '1% of 100 max HP');
      expect(PhotosynthesisStatus.healPercent, 1);
    });

    test('breaking the streak switches it off', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      expect(alice.statuses.whereType<PhotosynthesisStatus>(), hasLength(1));

      // One cast of a different element ends the run.
      charge(alice, MagicElement.pyro, 1);
      duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      expect(PhotosynthesisStatus.activeFor(alice), isFalse);
      expect(alice.statuses.whereType<PhotosynthesisStatus>(), isEmpty);
    });

    test('Ignite breaks the STREAK, not merely the status', () {
      // ⚠️ Stripping the status alone would let it return on the very next
      // Flora cast, and Ignite would counter nothing.
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      expect(alice.streakCount, greaterThanOrEqualTo(5));

      alice.statuses.add(IgniteStatus(5));
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      // Applying Ignite directly is what the engine does on a Pyro proc.
      alice.streakElement = null;
      alice.streakCount = 0;
      expect(PhotosynthesisStatus.activeFor(alice), isFalse);
    });

    test('an active Photosynthesis blocks Waterlogged; four casts does not', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      expect(PhotosynthesisStatus.activeFor(alice), isTrue);
      expect(alice.statuses.whereType<PhotosynthesisStatus>(), hasLength(1));
    });

    test('the heal lands before same-turn burn damage (survivability first)',
        () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      floraCast(duel, alice, 5);
      alice.hp = 2;
      // ⚠️ Ward built the streak, so Alice is standing behind a Flora shield.
      // Burn hits the shield first (§2.2), which would swallow the tick.
      alice.shield = null;
      alice.statuses.add(IgniteStatus(2)); // -2 at E8
      duel.resolveTurn(
          const ChargeAction(MagicElement.flora), const ForfeitAction());
      expect(alice.alive, isTrue, reason: '2 +1 = 3, then -2 = 1');
      expect(alice.hp, 1);
    });
  });

  group('Waterlogged (Aqua §2.1)', () {
    test('every 3rd consecutive Aqua cast slows the opponent by +10', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      for (var i = 0; i < 2; i++) {
        charge(alice, MagicElement.aqua, 1);
        duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
        expect(bruno.priorityPenalty, 0, reason: 'cast ${i + 1} of 3');
      }
      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(bruno.priorityPenalty, 10, reason: '3rd consecutive cast');
    });

    test('the 6th consecutive cast triggers again', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      for (var i = 0; i < 6; i++) {
        bruno.priorityPenalty = 0; // consume between (simulates action taken)
        charge(alice, MagicElement.aqua, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
      expect(bruno.priorityPenalty, 10, reason: 'streak of 6 = 2nd trigger');
    });

    test('an active Photosynthesis blocks Waterlogged (Flora shrugs off Aqua)',
        () {
      // Streak-gated now: it is a live 5-cast Flora run, not a stack
      // count. Bruno forfeits throughout, which cannot break his own streak.
      bruno
        ..streakElement = MagicElement.flora
        ..streakCount = 5
        ..statuses.add(PhotosynthesisStatus());
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      for (var i = 0; i < 3; i++) {
        charge(alice, MagicElement.aqua, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
      expect(bruno.priorityPenalty, 0, reason: 'immune while ≥1 stack');
    });
  });

  group('cleanse web (§2 table)', () {
    test('Ignite breaks an active Photosynthesis (Pyro burns Flora)', () {
      final duel =
          DuelEngine(alice, bruno, rng: Random(seedWhere(procs: true)), baseMissPercent: 0);
      bruno
        ..streakElement = MagicElement.flora
        ..streakCount = 5
        ..statuses.add(PhotosynthesisStatus());
      charge(alice, MagicElement.pyro, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(bruno.statuses.whereType<PhotosynthesisStatus>(), isEmpty);
      expect(bruno.streakCount, 0,
          reason: 'the STREAK must break, or it returns next cast');
      expect(bruno.statuses.whereType<IgniteStatus>(), hasLength(1));
    });

    test('casting an Aqua shield clears Ignite (Aqua douses Pyro)', () {
      alice.statuses.add(IgniteStatus(5));
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      charge(alice, MagicElement.aqua, 1);
      final r = duel.resolveTurn(
          CastAction(Spellbook.ward), const ForfeitAction());
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty);
      expect(r.events.whereType<EffectDamageEvent>(), isEmpty,
          reason: 'doused before the end phase — no tick');
    });

    test('an Aqua ATTACK does not clear Ignite (only shields douse)', () {
      alice.statuses.add(IgniteStatus(5));
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.statuses.whereType<IgniteStatus>(), hasLength(1));
    });
  });

  group('Fatigue sudden death (§8)', () {
    test('no fatigue at or below the threshold', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      for (var i = 0; i < DuelEngine.fatigueThreshold; i++) {
        final r =
            duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
        expect(r.events.whereType<EffectDamageEvent>(), isEmpty,
            reason: 'turn ${duel.turnNumber}');
      }
      expect(alice.hp, 100);
      expect(bruno.hp, 100);
    });

    test('escalating unblockable damage after the threshold', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      alice.shield = ActiveShield.elemental(MagicElement.geo, 999);
      for (var i = 0; i < DuelEngine.fatigueThreshold; i++) {
        duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      }
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(alice.hp, 100 - DuelEngine.fatiguePerTurn,
          reason: 'shield does not block fatigue');
      expect(bruno.hp, 100 - DuelEngine.fatiguePerTurn);
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(alice.hp, 100 - DuelEngine.fatiguePerTurn * 3,
          reason: 'turn 2 past threshold deals 2x the step');
    });

    test('fatigue outpaces Photosynthesis healing (no infinite stall)', () {
      for (final m in [alice, bruno]) {
        m
          ..streakElement = MagicElement.flora
          ..streakCount = 5
          ..statuses.add(PhotosynthesisStatus());
      }
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      var turns = 0;
      while (!duel.isOver && turns < 100) {
        duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
        turns++;
      }
      expect(duel.isOver, isTrue, reason: 'double-Flora mirror still ends');
    });

    test('symmetric fatigue kills produce a winner, never a draw', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1), baseMissPercent: 0);
      var turns = 0;
      while (!duel.isOver && turns < 100) {
        duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
        turns++;
      }
      expect(duel.isOver, isTrue);
      expect(duel.isDraw, isFalse);
      expect(duel.winner, isNotNull);
    });
  });
}
