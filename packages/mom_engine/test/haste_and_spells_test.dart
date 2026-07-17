import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno);
  });

  void charge(MageState m, MagicElement e, int amount) {
    m.charge = amount;
    m.element = e;
  }

  group('Haste establishment (unheld)', () {
    test('the only caster grabs Haste; a channeler does not', () {
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.fire),
        const ChargeAction(MagicElement.water),
      );
      expect(duel.hasteHolder, alice);
    });

    test('when both cast different priorities, the faster caster grabs it', () {
      alice.charge = 0;
      bruno.charge = 2;
      bruno.element = MagicElement.water;
      // Flick (priority 5) vs Blast (priority 9) — Flick is faster.
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.fire),
        CastAction(Spellbook.blast),
      );
      expect(duel.hasteHolder, alice);
    });

    test('a same-priority pair leaves Haste unheld', () {
      charge(alice, MagicElement.fire, 2);
      charge(bruno, MagicElement.water, 2);
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(duel.hasteHolder, isNull);
    });

    test('channeling never establishes Haste', () {
      duel.resolveTurn(const ChargeAction(MagicElement.fire),
          const ChargeAction(MagicElement.water));
      expect(duel.hasteHolder, isNull);
    });
  });

  group('Haste transfer (established)', () {
    test('an ordinary spell does not move an established Haste', () {
      alice.hasHaste = true;
      charge(bruno, MagicElement.water, 2);
      duel.resolveTurn(const ChargeAction(MagicElement.fire),
          CastAction(Spellbook.blast));
      expect(duel.hasteHolder, alice);
    });

    test('a Haste-granting spell (Jolt) steals it', () {
      alice.hasHaste = true;
      charge(bruno, MagicElement.water, 2);
      duel.resolveTurn(const ChargeAction(MagicElement.fire),
          CastAction(Spellbook.jolt));
      expect(duel.hasteHolder, bruno);
    });

    test('a same-priority pair of Haste-grants FLIPS it to the opponent', () {
      // Alice holds it, so her Hasty resolves first and Bruno's lands last —
      // Bruno steals the initiative.
      alice.hasHaste = true;
      duel.resolveTurn(CastAction(Spellbook.hasty, MagicElement.fire),
          CastAction(Spellbook.hasty, MagicElement.water));
      expect(duel.hasteHolder, bruno);
    });

    test('the holder keeps it if the opponent also grants at same priority '
        'but the holder cast the LAST-resolving grant', () {
      // Different priorities: Bruno (holder) casts the slower Hasty (7),
      // Alice casts the faster Jolt (5). Hasty resolves last, so Bruno keeps.
      bruno.hasHaste = true;
      charge(alice, MagicElement.fire, 2);
      duel.resolveTurn(CastAction(Spellbook.jolt),
          CastAction(Spellbook.hasty, MagicElement.water));
      expect(duel.hasteHolder, bruno);
    });
  });

  group('Haste tiebreak', () {
    test('the holder wins a same-priority collision — no mutual kill', () {
      alice.hasHaste = true;
      charge(alice, MagicElement.fire, 2);
      charge(bruno, MagicElement.water, 2);
      alice.hp = 10;
      bruno.hp = 10;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(duel.isDraw, isFalse);
      expect(duel.winner, alice);
      expect(alice.hp, 10, reason: "Bruno died before his Blast landed");
    });
  });

  group('Hasty', () {
    test('grants Haste and deals no damage', () {
      duel.resolveTurn(CastAction(Spellbook.hasty, MagicElement.fire),
          const ChargeAction(MagicElement.water));
      expect(duel.hasteHolder, alice);
      expect(bruno.hp, 100);
    });
  });

  group('Discharge', () {
    test('wipes the opponent charge', () {
      charge(alice, MagicElement.fire, 3);
      charge(bruno, MagicElement.water, 4);
      duel.resolveTurn(const ChargeAction(),
          CastAction(Spellbook.discharge));
      expect(alice.charge, 0, reason: 'Bruno discharged Alice');
    });

    test('drains a channeler even after they finish channeling', () {
      // Channel (priority 4) resolves, then Discharge (priority 7) wipes it.
      charge(alice, MagicElement.fire, 2);
      charge(bruno, MagicElement.water, 3);
      duel.resolveTurn(
          const ChargeAction(), CastAction(Spellbook.discharge));
      expect(alice.charge, 0);
    });

    test('a same-turn Discharge fizzles a Barrage (7 beats 9)', () {
      charge(alice, MagicElement.fire, 3);
      charge(bruno, MagicElement.water, 3);
      duel.resolveTurn(
          CastAction(Spellbook.barrage), CastAction(Spellbook.discharge));
      expect(bruno.hp, 100, reason: 'Alice charge wiped before Barrage read it');
    });
  });

  group('Overload', () {
    test('deals ~8-12 per point of the enemy charge', () {
      charge(alice, MagicElement.fire, 2);
      charge(bruno, MagicElement.water, 3);
      // Bruno casts Bolt (priority 9, after Overload) so his charge reads 3.
      duel.resolveTurn(
          CastAction(Spellbook.overload), CastAction(Spellbook.bolt));
      expect(bruno.hp, inInclusiveRange(100 - 36, 100 - 24));
    });

    test('does nothing to a chargeless enemy', () {
      charge(alice, MagicElement.fire, 2);
      bruno.charge = 0;
      duel.resolveTurn(CastAction(Spellbook.overload),
          CastAction(Spellbook.flick, MagicElement.water));
      expect(bruno.hp, 100);
    });

    test('channeling before an Overload increases the hit (channel is faster)',
        () {
      charge(alice, MagicElement.fire, 2);
      charge(bruno, MagicElement.water, 2);
      // Bruno channels 2 -> 3 at priority 4, before Overload reads it at 7.
      duel.resolveTurn(
          CastAction(Spellbook.overload), const ChargeAction());
      expect(bruno.hp, inInclusiveRange(100 - 36, 100 - 24),
          reason: 'Overload read Bruno at 3 charge, not 2');
    });

    test('respects shields', () {
      charge(alice, MagicElement.fire, 2);
      bruno.charge = 3;
      bruno.element = MagicElement.water;
      bruno.shield = ActiveShield.elemental(MagicElement.air, 200);
      duel.resolveTurn(
          CastAction(Spellbook.overload), CastAction(Spellbook.bolt));
      expect(bruno.hp, 100, reason: 'the big air shield soaks Overload');
    });
  });

  test('Channel now has priority 4 (after shields, before quick attacks)', () {
    expect(DuelEngine.channelPriority, 4);
  });
}
