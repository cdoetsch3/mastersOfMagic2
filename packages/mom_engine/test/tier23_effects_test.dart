import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// A Random whose `nextDouble` returns scripted values (then 0.99 forever) so
/// proc rolls are deterministic. `nextInt` returns 0 (all damage rolls are
/// minimums), keeping arithmetic exact.
class ScriptedRandom implements Random {
  final List<double> doubles;
  var _i = 0;

  ScriptedRandom(this.doubles);

  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

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

  group('Tier 2 — Static Feedback (Electro §3.1)', () {
    test('a proc strips one charge from the target', () {
      // Roll order for the Flick cast: damage roll uses nextInt (scripted 0),
      // then Static rolls nextDouble: 0.1 < 0.20 procs.
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom([0.1]));
      charge(bruno, MagicElement.geo, 3);
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.electro),
        const ForfeitAction(),
      );
      expect(bruno.charge, 2, reason: '3 − 1 static strip');
    });

    test('no proc at 0.20 or above (20% chance)', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.20]));
      charge(bruno, MagicElement.geo, 3);
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.electro),
        const ForfeitAction(),
      );
      expect(bruno.charge, 3);
    });

    test('a standing Geo shield grounds the proc entirely', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      charge(bruno, MagicElement.geo, 3);
      bruno.shield = ActiveShield.elemental(MagicElement.geo, 999);
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.electro),
        const ForfeitAction(),
      );
      expect(bruno.charge, 3, reason: 'grounded by the Geo shield');
    });

    test('static strip fizzles an exactly-affordable committed spell '
        '(and the caster keeps the remaining charge)', () {
      // Bruno commits Surge (cost 3) with exactly 3 charge. Alice's Electro
      // Flick (P5) resolves before Surge (P9), procs static (0.0), stripping
      // to 2 — Surge fizzles, Bruno keeps 2 charge.
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      charge(bruno, MagicElement.geo, 3);
      final result = duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.electro),
        CastAction(Spellbook.surge),
      );
      expect(result.events.whereType<SpellFizzledEvent>(), hasLength(1));
      expect(alice.hp, 100, reason: 'Surge never resolved');
      expect(bruno.charge, 2,
          reason: 'fizzle keeps the remaining charge (the §3.1 ruling)');
    });

    test('an Electro attack scatters the Tailwind streak but not held Haste',
        () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.99]));
      bruno
        ..streakElement = MagicElement.aero
        ..streakCount = 4
        ..hasHaste = true;
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.electro),
        const ForfeitAction(),
      );
      expect(bruno.streakCount, 0, reason: 'streak wiped');
      expect(bruno.streakElement, isNull);
      expect(bruno.hasHaste, isTrue, reason: 'held Haste is kept');
    });
  });

  group('Tier 2 — Tailwind (Aero §3.2)', () {
    test('the 3rd consecutive Aero cast steals Haste from its holder', () {
      // Bruno holds the token; ordinary spells can never move an established
      // Haste — only Tailwind (or a grantsHaste spell) can take it from him.
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      bruno.hasHaste = true;
      for (var i = 0; i < 2; i++) {
        charge(alice, MagicElement.aero, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
      expect(bruno.hasHaste, isTrue, reason: 'streak of 2 — not yet');
      charge(alice, MagicElement.aero, 1);
      duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      expect(alice.hasHaste, isTrue, reason: '3rd consecutive cast grabs it');
      expect(bruno.hasHaste, isFalse);
    });

    test('Tailwind overrides the normal last-grant Haste transfer', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      alice
        ..streakElement = MagicElement.aero
        ..streakCount = 2;
      bruno.hasHaste = true;
      // Bruno casts Hasty (grantsHaste, would normally keep/reclaim the
      // token); Alice's 3rd Aero cast tailwind-grabs it anyway.
      charge(alice, MagicElement.aero, 1);
      duel.resolveTurn(
        CastAction(Spellbook.ward),
        CastAction(Spellbook.hasty, MagicElement.geo),
      );
      expect(alice.hasHaste, isTrue, reason: 'the wind takes the token');
      expect(bruno.hasHaste, isFalse);
    });
  });

  group('Tier 2 — Stagger (Geo §3.3)', () {
    test('every 4th consecutive Geo cast halves the next offensive spell', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      for (var i = 0; i < 4; i++) {
        charge(alice, MagicElement.geo, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
      expect(bruno.nextOffensiveDamageScale, 0.5);
    });

    test('a Tailwind streak of 3+ is immune (Aero weathers Geo)', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      bruno
        ..streakElement = MagicElement.aero
        ..streakCount = 3;
      for (var i = 0; i < 4; i++) {
        charge(alice, MagicElement.geo, 1);
        duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      }
      expect(bruno.nextOffensiveDamageScale, 1.0, reason: 'whiffed');
    });
  });

  group('Tier 4 — Blind (Sanctus §4.1)', () {
    test('proc chance is 10% per charge spent', () {
      // 4 charge spent → 40%: a 0.39 roll procs...
      var duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.39]));
      charge(alice, MagicElement.sanctus, 4);
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      expect(bruno.statuses.whereType<BlindStatus>(), hasLength(1));

      // ...and a 0.41 roll does not.
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno');
      duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.41]));
      charge(alice, MagicElement.sanctus, 4);
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      expect(bruno.statuses.whereType<BlindStatus>(), isEmpty);
    });

    test('a 0-cost attack can never blind', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.sanctus),
        const ForfeitAction(),
      );
      expect(bruno.statuses.whereType<BlindStatus>(), isEmpty);
    });

    test('blind takes effect NEXT turn, lasts 3 turns, then expires', () {
      // Turn 1: Alice blinds Bruno (0.0 procs at 40%).
      // Bruno then attacks each turn; miss rolls scripted to always miss
      // (0.4 < 0.5) while blind is active.
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom([0.0, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4]));
      charge(alice, MagicElement.sanctus, 4);
      duel.resolveTurn(
        CastAction(Spellbook.ruin),
        CastAction(Spellbook.flick, MagicElement.geo), // same turn: no miss
      );
      final afterTurn1 = alice.hp;
      expect(afterTurn1, lessThan(100),
          reason: 'same-turn cast is not affected by the fresh blind');

      // Turns 2-4: all Bruno's attacks miss.
      for (var t = 0; t < 3; t++) {
        duel.resolveTurn(
          const ForfeitAction(),
          CastAction(Spellbook.flick, MagicElement.geo),
        );
      }
      expect(alice.hp, afterTurn1, reason: 'three blinded turns, three misses');

      // Turn 5: blind expired — the attack lands again.
      duel.resolveTurn(
        const ForfeitAction(),
        CastAction(Spellbook.flick, MagicElement.geo),
      );
      expect(alice.hp, lessThan(afterTurn1));
      expect(bruno.statuses.whereType<BlindStatus>(), isEmpty);
    });

    test('Arcane spells never miss while blinded', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0, 0.0]));
      bruno.statuses.add(BlindStatus()..advanceAndCheckExpiry(bruno));
      duel.resolveTurn(
        const ForfeitAction(),
        CastAction(Spellbook.flick, MagicElement.arcane),
      );
      expect(alice.hp, lessThan(100), reason: 'Arcane is exempt from Blind');
    });

    test('a Blind proc burns away the Creeping Dark', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      bruno.statuses.add(CreepingDarkStatus(12));
      bruno.concealed = true;
      charge(alice, MagicElement.sanctus, 4);
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      expect(bruno.statuses.whereType<CreepingDarkStatus>(), isEmpty);
      expect(bruno.concealed, isFalse);
    });
  });

  group('Tier 3 — Creeping Dark (Umbra §4.2)', () {
    test('stacks grow by charge spent; charging pauses decay', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      charge(alice, MagicElement.umbra, 5);
      duel.resolveTurn(CastAction(Spellbook.cataclysm), const ForfeitAction());
      expect(alice.statuses.whereType<CreepingDarkStatus>().single.stacks, 5);
      expect(alice.concealed, isTrue, reason: 'Shadow at 5+');

      // Charging Umbra pauses decay.
      duel.resolveTurn(
          const ChargeAction(MagicElement.umbra), const ForfeitAction());
      expect(alice.statuses.whereType<CreepingDarkStatus>().single.stacks, 5);

      // A non-Umbra turn decays one stack — and Shadow lifts below 5.
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(alice.statuses.whereType<CreepingDarkStatus>().single.stacks, 4);
      expect(alice.concealed, isFalse);
    });

    test('stacks cap at 15 (Midnight)', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      for (var i = 0; i < 4; i++) {
        bruno.hp = 100; // survive the repeated Cataclysms — not under test
        charge(alice, MagicElement.umbra, 5);
        duel.resolveTurn(
            CastAction(Spellbook.cataclysm), const ForfeitAction());
      }
      final dark = alice.statuses.whereType<CreepingDarkStatus>().single;
      expect(dark.stacks, 15);
      expect(dark.midnight, isTrue);
    });

    test('threshold getters: 5 shadow, 10 dusk, 15 midnight', () {
      expect(CreepingDarkStatus(4).shadow, isFalse);
      expect(CreepingDarkStatus(5).shadow, isTrue);
      expect(CreepingDarkStatus(9).dusk, isFalse);
      expect(CreepingDarkStatus(10).dusk, isTrue);
      expect(CreepingDarkStatus(14).midnight, isFalse);
      expect(CreepingDarkStatus(15).midnight, isTrue);
    });
  });

  group('Tier 3 — Arcane Knowledge (Arcane §4.3)', () {
    test('a 4+ charge Arcane cast earns a stack (+5% each, max 5)', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      for (var i = 0; i < 6; i++) {
        bruno.hp = 100; // survive the repeated Ruins — not under test
        charge(alice, MagicElement.arcane, 4);
        duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      }
      final ak = alice.statuses.whereType<ArcaneKnowledgeStatus>().single;
      expect(ak.stacks, 5, reason: 'capped');
      expect(alice.bonusDamagePercent, 25);
    });

    test('a cheap Arcane spell cast at 4 charge still counts (spent ≥ 4)', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      charge(alice, MagicElement.arcane, 4);
      duel.resolveTurn(
          CastAction(Spellbook.bolt), const ForfeitAction()); // cost 1, spends 4
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), hasLength(1));
    });

    test('a 3-charge Arcane cast earns nothing', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      charge(alice, MagicElement.arcane, 3);
      duel.resolveTurn(CastAction(Spellbook.surge), const ForfeitAction());
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), isEmpty);
    });

    test('stacks persist across other-element casts (permanent)', () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      charge(alice, MagicElement.arcane, 4);
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      charge(alice, MagicElement.pyro, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), hasLength(1));
      expect(alice.bonusDamagePercent, 5);
    });

    test('gaining is blocked under the opponent Dusk (Umbra corrupts Arcane)',
        () {
      final duel = DuelEngine(alice, bruno, rng: Random(1));
      bruno.statuses.add(CreepingDarkStatus(10)); // Dusk
      charge(alice, MagicElement.arcane, 4);
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), isEmpty,
          reason: 'no AK gain under Dusk');
    });
  });
}
