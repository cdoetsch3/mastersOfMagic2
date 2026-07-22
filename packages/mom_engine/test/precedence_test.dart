import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// A test-double blinder: makes the holder's harmful spells miss with a fixed
/// chance for [turnsLeft] turns. (Phase 4 built the real Blind on the
/// same [Blinding] marker.)
class _Blind extends TurnStatus implements Blinding {
  @override
  final double missChance;
  int turnsLeft;
  _Blind(this.missChance, this.turnsLeft);

  @override
  String get id => 'blind';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno, elementEffects: false);
  });

  void charge(MageState m, MagicElement e, int to) {
    m
      ..charge = to
      ..element = e;
  }

  group('streak tracking (§5.4)', () {
    test('consecutive same-element casts advance the streak', () {
      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(
          CastAction(Spellbook.ward), const ForfeitAction());
      expect(alice.streakElement, MagicElement.aqua);
      expect(alice.streakCount, 1);

      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(
          CastAction(Spellbook.ward), const ForfeitAction());
      expect(alice.streakCount, 2);
    });

    test('casting a different element resets the streak to 1', () {
      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.streakCount, 1);
      charge(alice, MagicElement.geo, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.streakElement, MagicElement.geo);
      expect(alice.streakCount, 1);
    });

    test('charging between casts does not break the streak', () {
      charge(alice, MagicElement.aqua, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.streakCount, 1);
      // A charge turn (no cast) — streak must be untouched.
      duel.resolveTurn(
          const ChargeAction(MagicElement.aqua), const ForfeitAction());
      expect(alice.streakCount, 1, reason: 'charging leaves the streak alone');
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.streakCount, 2, reason: 'the two Aqua casts are consecutive');
    });

    test('a non-damaging cast still advances the streak', () {
      charge(alice, MagicElement.aqua, 3);
      duel.resolveTurn(CastAction(Spellbook.discharge), const ForfeitAction());
      expect(alice.streakElement, MagicElement.aqua);
      expect(alice.streakCount, 1);
    });
  });

  group('fizzle (charge stripped below cost)', () {
    test('a spell whose charge is drained below cost fizzles and keeps charge',
        () {
      // Alice commits a 4-cost Ruin at 4 charge; Bruno Discharges (P7) first,
      // wiping her charge — Ruin (P9) can no longer be cast.
      charge(alice, MagicElement.geo, 4);
      charge(bruno, MagicElement.aqua, 3);
      final r = duel.resolveTurn(
          CastAction(Spellbook.ruin), CastAction(Spellbook.discharge));
      expect(r.events.whereType<SpellFizzledEvent>(), hasLength(1));
      expect(bruno.hp, 100, reason: 'Ruin never landed');
      // Fizzle keeps charge (Static Feedback: "you'd still have 3 charge").
      expect(alice.charge, 0,
          reason: 'Discharge wiped it to 0 — nothing to keep, but not spent by a cast');
    });

    test('fizzled casts do not advance the streak', () {
      charge(alice, MagicElement.geo, 4);
      charge(bruno, MagicElement.aqua, 3);
      duel.resolveTurn(
          CastAction(Spellbook.ruin), CastAction(Spellbook.discharge));
      expect(alice.streakCount, 0, reason: 'a fizzle is like a charge');
    });

    // Partial-charge retention (Static Feedback's "you'd still have 3 charge")
    // needs a single-charge strip that resolves before a priority-9 spell —
    // that arrives with Electro in Phase 4 and is tested there. Discharge
    // wipes ALL charge, so it can only ever leave 0 behind.
  });

  group('miss (Blind)', () {
    test('a guaranteed miss makes a harmful spell do nothing but spend charge',
        () {
      charge(alice, MagicElement.geo, 2);
      alice.statuses.add(_Blind(1.0, 3)); // 100% miss
      final r = duel.resolveTurn(
          CastAction(Spellbook.blast), const ForfeitAction());
      expect(r.events.whereType<SpellMissedEvent>(), hasLength(1));
      expect(bruno.hp, 100, reason: 'Blast missed');
      expect(alice.charge, 0, reason: 'charge is still spent on a miss');
      expect(alice.streakCount, 0, reason: 'a miss advances no streak');
    });

    test('a guaranteed miss also nullifies Discharge (harmful, non-damaging)',
        () {
      charge(alice, MagicElement.geo, 3);
      charge(bruno, MagicElement.aqua, 4);
      alice.statuses.add(_Blind(1.0, 3));
      duel.resolveTurn(
          CastAction(Spellbook.discharge), const ForfeitAction());
      expect(bruno.charge, 4, reason: 'a missed Discharge wipes nothing');
    });

    test('a 0% blind never misses; defensive casts are never blinded', () {
      charge(alice, MagicElement.aqua, 2);
      alice.statuses.add(_Blind(0.0, 3));
      duel.resolveTurn(CastAction(Spellbook.aegis), const ForfeitAction());
      expect(alice.shield, isNotNull, reason: 'shields cannot miss');
    });
  });

  group('priority penalty (Waterlogged)', () {
    test('+10 priority makes an action resolve after an unmodified one', () {
      // Alice Bolt (P9) + Bruno Bolt (P9) normally trade; slow Bruno so
      // Alice resolves first. Give Alice lethal setup to prove ordering.
      alice.hp = 100;
      bruno.hp = 8;
      charge(alice, MagicElement.geo, 1);
      charge(bruno, MagicElement.geo, 1);
      bruno.priorityPenalty = 10; // Bruno's Bolt now resolves at 19
      alice.hasHaste = false;
      duel.resolveTurn(CastAction(Spellbook.bolt), CastAction(Spellbook.bolt));
      // Alice's Bolt (11-14) kills Bruno (8hp) before his slowed Bolt fires.
      expect(duel.winner, alice);
      expect(alice.hp, 100, reason: "Bruno's Bolt never resolved");
    });

    test('the penalty is consumed after one action', () {
      charge(alice, MagicElement.aqua, 1);
      alice.priorityPenalty = 10;
      duel.resolveTurn(CastAction(Spellbook.ward), const ForfeitAction());
      expect(alice.priorityPenalty, 0);
    });
  });

  group('damage modifiers (§5.2 step 4)', () {
    test('Arcane-Knowledge bonus is additive (+5%/stack)', () {
      // 5 stacks = +25%. Bolt 11-14 -> 13.75-17.5 -> rounds 14-18.
      charge(alice, MagicElement.geo, 1);
      alice.bonusDamagePercent = 25;
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(100 - bruno.hp, inInclusiveRange(14, 18));
    });

    test('the AK bonus is not consumed (persists across casts)', () {
      alice.bonusDamagePercent = 25;
      charge(alice, MagicElement.geo, 1);
      duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
      expect(alice.bonusDamagePercent, 25);
    });

    test('Stagger halves the next harmful spell and is then consumed', () {
      charge(alice, MagicElement.geo, 2);
      alice.nextOffensiveDamageScale = 0.5;
      duel.resolveTurn(CastAction(Spellbook.blast), const ForfeitAction());
      // Blast 20-26 halved -> 10-13.
      expect(100 - bruno.hp, inInclusiveRange(10, 13));
      expect(alice.nextOffensiveDamageScale, 1.0, reason: 'consumed');
    });

    test('order: additive then multiplicative (AK, then Empower, then Stagger)',
        () {
      // base 20-26; ×(1.25) AK; ×2 Empower; ×0.5 Stagger  => ×1.25 net.
      charge(alice, MagicElement.geo, 2);
      alice
        ..bonusDamagePercent = 25
        ..empowerMultiplier = 2
        ..nextOffensiveDamageScale = 0.5;
      duel.resolveTurn(CastAction(Spellbook.blast), const ForfeitAction());
      // 20-26 × 1.25 = 25-32.5 -> 25-33.
      expect(100 - bruno.hp, inInclusiveRange(25, 33));
    });

    test('Discharge consumes Stagger harmlessly (the stagger-eater)', () {
      charge(alice, MagicElement.geo, 3);
      charge(bruno, MagicElement.aqua, 2);
      alice.nextOffensiveDamageScale = 0.5;
      duel.resolveTurn(
          CastAction(Spellbook.discharge), const ForfeitAction());
      expect(alice.nextOffensiveDamageScale, 1.0, reason: 'eaten by Discharge');
    });
  });
}
