import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno, elementEffects: false);
  });

  group('action validation', () {
    test('charging from 0 requires an element', () {
      expect(
        () => duel.resolveTurn(
            const ChargeAction(), const ChargeAction(MagicElement.pyro)),
        throwsArgumentError,
      );
    });

    test('cannot switch elements mid-cycle', () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      expect(
        () => duel.resolveTurn(const ChargeAction(MagicElement.arcane),
            const ChargeAction(MagicElement.pyro)),
        throwsArgumentError,
      );
    });

    test('cannot charge past the cap', () {
      alice.charge = 5;
      alice.element = MagicElement.pyro;
      expect(
        () => duel.resolveTurn(
            const ChargeAction(), const ChargeAction(MagicElement.pyro)),
        throwsArgumentError,
      );
    });

    test('cannot cast an unaffordable spell', () {
      alice.charge = 1;
      alice.element = MagicElement.pyro;
      expect(
        () => duel.resolveTurn(CastAction(Spellbook.cataclysm),
            const ChargeAction(MagicElement.aqua)),
        throwsArgumentError,
      );
    });

    test('casting at 0 charge requires an element', () {
      expect(
        () => duel.resolveTurn(CastAction(Spellbook.flick),
            const ChargeAction(MagicElement.aqua)),
        throwsArgumentError,
      );
    });
  });

  group('charge cycle', () {
    test('charging builds toward 5 and locks the element', () {
      duel.resolveTurn(const ChargeAction(MagicElement.pyro),
          const ChargeAction(MagicElement.aqua));
      expect(alice.charge, 1);
      expect(alice.element, MagicElement.pyro);
      duel.resolveTurn(const ChargeAction(), const ChargeAction());
      expect(alice.charge, 2);
      expect(alice.element, MagicElement.pyro);
    });

    test('casting consumes ALL charge, even beyond the spell cost', () {
      alice.charge = 3;
      alice.element = MagicElement.pyro;
      duel.resolveTurn(
          CastAction(Spellbook.bolt), const ChargeAction(MagicElement.aqua));
      expect(alice.charge, 0);
      expect(alice.element, isNull, reason: 'new cycle: element re-chosen');
      expect(bruno.hp, inInclusiveRange(86, 89), reason: 'Bolt rolls 11-14');
    });

    test('0-cost spells are castable immediately with a fresh element', () {
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.pyro),
          const ChargeAction(MagicElement.aqua));
      expect(bruno.hp, inInclusiveRange(94, 96), reason: 'Flick rolls 4-6');
      expect(alice.charge, 0);
    });
  });

  group('priority resolution', () {
    test('shields (3) go up before regular attacks (9) in the same turn', () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      bruno.charge = 3;
      bruno.element = MagicElement.aero;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.bulwark));
      expect(bruno.hp, 100, reason: 'a 3-charge shield absorbs any Blast');
      expect(bruno.shield!.remaining, inInclusiveRange(39 - 26, 51 - 20));
    });

    test('quickened attacks (2) land before enemy shields (3)', () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      duel.resolveTurn(
          CastAction(Spellbook.quicken), const ChargeAction(MagicElement.aero));
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      bruno.charge = 3;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.bulwark));
      expect(bruno.hp, inInclusiveRange(74, 80),
          reason: 'attack resolves before the shield');
      expect(bruno.shield!.remaining, inInclusiveRange(39, 51),
          reason: 'shield up afterwards, untouched');
    });

    test('a mage killed at an earlier priority does not resolve later casts',
        () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      alice.quickenPriority = 2;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      bruno.hp = 20;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(bruno.alive, isFalse);
      expect(alice.hp, 100, reason: "Bruno died before his regular attack");
      expect(duel.winner, alice);
    });

    test('equal-priority mutual kills are a draw', () {
      alice.charge = 2;
      alice.element = MagicElement.pyro;
      alice.hp = 10;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      bruno.hp = 10;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(duel.isOver, isTrue);
      expect(duel.isDraw, isTrue);
      expect(duel.winner, isNull);
    });
  });

  group('spell effects', () {
    test('lifesteal heals for damage dealt to health', () {
      alice.charge = 1;
      alice.element = MagicElement.umbra;
      alice.hp = 50;
      duel.resolveTurn(
          CastAction(Spellbook.sap), const ChargeAction(MagicElement.aero));
      expect(bruno.hp, inInclusiveRange(89, 91));
      expect(alice.hp - 50, 100 - bruno.hp,
          reason: 'heals exactly the damage dealt');
    });

    test('lifesteal does not heal for damage soaked by shields', () {
      alice.charge = 1;
      alice.element = MagicElement.umbra;
      alice.hp = 50;
      bruno.shield = ActiveShield.elemental(MagicElement.aero, 100);
      duel.resolveTurn(
          CastAction(Spellbook.sap), const ChargeAction(MagicElement.aero));
      expect(bruno.hp, 100);
      expect(alice.hp, 50, reason: 'nothing reached health, nothing healed');
    });

    test('empower doubles the next offensive spell', () {
      // Geo, not pyro: a pyro attack can randomly Ignite and skew the hp.
      alice.charge = 3;
      alice.element = MagicElement.geo;
      duel.resolveTurn(
          CastAction(Spellbook.empower), const ChargeAction(MagicElement.aero));
      alice.charge = 1;
      alice.element = MagicElement.geo;
      duel.resolveTurn(CastAction(Spellbook.bolt), const ChargeAction());
      expect(bruno.hp, inInclusiveRange(72, 78), reason: '2x Bolt is 22-28');
      expect(alice.empowerMultiplier, isNull, reason: 'buff consumed');
    });

    test('phase makes the next offensive spell ignore shields', () {
      alice.charge = 3;
      alice.element = MagicElement.pyro;
      bruno.shield = ActiveShield.elemental(MagicElement.aero, 100);
      duel.resolveTurn(
          CastAction(Spellbook.phase), const ChargeAction(MagicElement.aero));
      alice.charge = 1;
      alice.element = MagicElement.pyro;
      duel.resolveTurn(CastAction(Spellbook.bolt), const ChargeAction());
      expect(bruno.hp, inInclusiveRange(86, 89));
      expect(bruno.shield!.remaining, 100);
    });

    test('barrage scales with all charge spent', () {
      alice.charge = 4;
      alice.element = MagicElement.electro;
      duel.resolveTurn(
          CastAction(Spellbook.barrage), const ChargeAction(MagicElement.aero));
      expect(bruno.hp, inInclusiveRange(52, 60),
          reason: '4 charges at 10-12 per charge is 40-48');
      expect(alice.charge, 0);
    });

    test('multi-hit spells strike separately', () {
      alice.charge = 3;
      alice.element = MagicElement.pyro;
      bruno.shield = ActiveShield.elemental(MagicElement.aero, 10);
      duel.resolveTurn(
          CastAction(Spellbook.volley), const ChargeAction(MagicElement.aero));
      // Volley rolls 8-11 x4 (32-44 total); the 10-point shield absorbs 10
      // raw, everything past it strikes health.
      expect(bruno.shield, isNull);
      expect(bruno.hp, inInclusiveRange(66, 78));
    });
  });

  group('duel lifecycle', () {
    test('a defeated mage ends the duel with a winner', () {
      bruno.hp = 4;
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.pyro),
          const ChargeAction(MagicElement.aqua));
      expect(duel.isOver, isTrue);
      expect(duel.winner, alice);
      expect(duel.isDraw, isFalse);
    });

    test('conceding ends the duel as a loss for the conceder', () {
      duel.concede(alice);
      expect(duel.isOver, isTrue);
      expect(duel.winner, bruno);
      expect(alice.hp, 0);
    });

    test('conceding a finished duel throws', () {
      bruno.hp = 0;
      expect(() => duel.concede(alice), throwsStateError);
    });

    test('resolving a turn after the duel ends throws', () {
      bruno.hp = 0;
      expect(
        () => duel.resolveTurn(const ChargeAction(MagicElement.pyro),
            const ChargeAction(MagicElement.aqua)),
        throwsStateError,
      );
    });
  });
}
