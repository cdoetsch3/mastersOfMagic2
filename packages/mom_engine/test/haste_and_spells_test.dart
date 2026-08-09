import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno, elementEffects: false, baseMissPercent: 0);
  });

  void charge(MageState m, MagicElement e, int amount) {
    m.charge = amount;
    m.element = e;
  }

  group('Haste establishment (unheld)', () {
    test('the only caster grabs Haste; a channeler does not', () {
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.pyro),
        const ChargeAction(MagicElement.aqua),
      );
      expect(duel.hasteHolder, alice);
    });

    test('when both cast different priorities, the faster caster grabs it', () {
      alice.charge = 0;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      // Flick (priority 5) vs Blast (priority 9) — Flick is faster.
      duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.pyro),
        CastAction(Spellbook.blast),
      );
      expect(duel.hasteHolder, alice);
    });

    test('a same-priority pair leaves Haste unheld', () {
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 2);
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(duel.hasteHolder, isNull);
    });

    test('channeling never establishes Haste', () {
      duel.resolveTurn(const ChargeAction(MagicElement.pyro),
          const ChargeAction(MagicElement.aqua));
      expect(duel.hasteHolder, isNull);
    });
  });

  group('Haste transfer (established)', () {
    test('an ordinary spell does not move an established Haste', () {
      alice.hasHaste = true;
      charge(bruno, MagicElement.aqua, 2);
      duel.resolveTurn(const ChargeAction(MagicElement.pyro),
          CastAction(Spellbook.blast));
      expect(duel.hasteHolder, alice);
    });

    test('a Haste-granting spell (Jolt) steals it', () {
      alice.hasHaste = true;
      charge(bruno, MagicElement.aqua, 2);
      duel.resolveTurn(const ChargeAction(MagicElement.pyro),
          CastAction(Spellbook.jolt));
      expect(duel.hasteHolder, bruno);
    });

    test('a same-priority pair of Haste-grants FLIPS it to the opponent', () {
      // Alice holds it, so her Hasty resolves first and Bruno's lands last —
      // Bruno steals the initiative.
      alice.hasHaste = true;
      duel.resolveTurn(CastAction(Spellbook.hasty, MagicElement.pyro),
          CastAction(Spellbook.hasty, MagicElement.aqua));
      expect(duel.hasteHolder, bruno);
    });

    test('the holder keeps it if the opponent also grants at same priority '
        'but the holder cast the LAST-resolving grant', () {
      // Different priorities: Bruno (holder) casts the slower Hasty (7),
      // Alice casts the faster Jolt (5). Hasty resolves last, so Bruno keeps.
      bruno.hasHaste = true;
      charge(alice, MagicElement.pyro, 2);
      duel.resolveTurn(CastAction(Spellbook.jolt),
          CastAction(Spellbook.hasty, MagicElement.aqua));
      expect(duel.hasteHolder, bruno);
    });
  });

  group('Haste tiebreak', () {
    test('the holder wins a same-priority collision — no mutual kill', () {
      alice.hasHaste = true;
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 2);
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
      duel.resolveTurn(CastAction(Spellbook.hasty, MagicElement.pyro),
          const ChargeAction(MagicElement.aqua));
      expect(duel.hasteHolder, alice);
      expect(bruno.hp, 100);
    });
  });

  group('Discharge', () {
    test('wipes the opponent charge', () {
      charge(alice, MagicElement.pyro, 3);
      charge(bruno, MagicElement.aqua, 4);
      duel.resolveTurn(const ChargeAction(),
          CastAction(Spellbook.discharge));
      expect(alice.charge, 0, reason: 'Bruno discharged Alice');
    });

    test('drains a channeler even after they finish channeling', () {
      // Channel (priority 4) resolves, then Discharge (priority 7) wipes it.
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 3);
      duel.resolveTurn(
          const ChargeAction(), CastAction(Spellbook.discharge));
      expect(alice.charge, 0);
    });

    test('a same-turn Discharge fizzles a Barrage (7 beats 9)', () {
      charge(alice, MagicElement.pyro, 3);
      charge(bruno, MagicElement.aqua, 3);
      duel.resolveTurn(
          CastAction(Spellbook.barrage), CastAction(Spellbook.discharge));
      expect(bruno.hp, 100, reason: 'Alice charge wiped before Barrage read it');
    });
  });

  group('Overload', () {
    test('deals ~7-11 per point of the charge the enemy HOLDS', () {
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 3);
      // Bruno holds his charge (forfeits), so Overload punishes all 3 of it.
      duel.resolveTurn(
          CastAction(Spellbook.overload), const ForfeitAction());
      expect(bruno.hp, inInclusiveRange(100 - 33, 100 - 21));
    });

    test('a same-priority enemy cast spends the charge before Overload reads it',
        () {
      // ⚠️ TIE BEHAVIOUR, FLAGGED FOR A RULING. With no Haste, same-priority
      // casts pay simultaneously — so Bruno's Bolt commits his charge in the
      // same instant, and Overload finds nothing to punish. This makes two
      // mutual Overloads both fizzle (each sees the other already empty), which
      // is the stated intent — but it also means Overload does NOT out-speed a
      // tied attack, which the spec's other line wanted. The two cannot both
      // hold; this is the version that keeps the mutual-Overload rule.
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 3);
      duel.resolveTurn(
          CastAction(Spellbook.overload), CastAction(Spellbook.bolt));
      expect(bruno.hp, 100, reason: 'Bruno spent his charge casting Bolt');
    });

    test('does nothing to a chargeless enemy', () {
      charge(alice, MagicElement.pyro, 2);
      bruno.charge = 0;
      duel.resolveTurn(CastAction(Spellbook.overload),
          CastAction(Spellbook.flick, MagicElement.aqua));
      expect(bruno.hp, 100);
    });

    test('channeling before an Overload increases the hit (channel is faster)',
        () {
      charge(alice, MagicElement.pyro, 2);
      charge(bruno, MagicElement.aqua, 2);
      // Bruno channels 2 -> 3 at priority 4, before Overload reads it at 7.
      duel.resolveTurn(
          CastAction(Spellbook.overload), const ChargeAction());
      // 7-11 per point of the target's charge: 3 charge is 21-33.
      expect(bruno.hp, inInclusiveRange(100 - 33, 100 - 21),
          reason: 'Overload read Bruno at 3 charge, not 2');
    });

    test('respects shields', () {
      charge(alice, MagicElement.pyro, 2);
      bruno.charge = 3;
      bruno.element = MagicElement.aqua;
      bruno.shield = ActiveShield.elemental(MagicElement.aero, 200);
      duel.resolveTurn(
          CastAction(Spellbook.overload), CastAction(Spellbook.bolt));
      expect(bruno.hp, 100, reason: 'the big air shield soaks Overload');
    });
  });

  test('Channel now has priority 4 (after shields, before quick attacks)', () {
    expect(DuelEngine.channelPriority, 4);
  });

  // Note 22 — a Haste transfer is reported immediately after the cast that
  // seized it, not appended at end of turn (where it read as an unexplained
  // extra beat after all the damage).
  group('Haste is reported at the moment it is seized', () {
    test('the transfer lands right after the granting cast, before later casts',
        () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      bruno.charge = 2;
      bruno.element = MagicElement.solar;
      // Jolt (priority 5, grants Haste) resolves before Blast (priority 9).
      final result = duel.resolveTurn(
          CastAction(Spellbook.jolt), CastAction(Spellbook.blast));
      final events = result.events;
      final haste = events.indexWhere((e) => e is HasteChangedEvent);
      final jolt = events.indexWhere(
          (e) => e is SpellCastEvent && e.spell == Spellbook.jolt);
      final blast = events.indexWhere(
          (e) => e is SpellCastEvent && e.spell == Spellbook.blast);

      expect(haste, greaterThan(jolt), reason: 'after the Jolt that seized it');
      expect(haste, lessThan(blast),
          reason: 'and before the later cast — not at the end of the turn');
    });

    test('it still sits after its own cast damage', () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      final result =
          duel.resolveTurn(CastAction(Spellbook.jolt), const ForfeitAction());
      final events = result.events;
      final haste = events.indexWhere((e) => e is HasteChangedEvent);
      final damage = events.indexWhere((e) => e is DamageEvent);
      expect(damage, greaterThanOrEqualTo(0), reason: 'the Jolt hit');
      expect(haste, greaterThan(damage),
          reason: 'the cast fully resolves, then the initiative is reported');
    });
  });
}
