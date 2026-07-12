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

  group('action validation', () {
    test('charging from 0 requires an element', () {
      expect(
        () => duel.resolveTurn(
            const ChargeAction(), const ChargeAction(MagicElement.fire)),
        throwsArgumentError,
      );
    });

    test('cannot switch elements mid-cycle', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      expect(
        () => duel.resolveTurn(const ChargeAction(MagicElement.ice),
            const ChargeAction(MagicElement.fire)),
        throwsArgumentError,
      );
    });

    test('cannot charge past the cap', () {
      alice.charge = 5;
      alice.element = MagicElement.fire;
      expect(
        () => duel.resolveTurn(
            const ChargeAction(), const ChargeAction(MagicElement.fire)),
        throwsArgumentError,
      );
    });

    test('cannot cast an unaffordable spell', () {
      alice.charge = 1;
      alice.element = MagicElement.fire;
      expect(
        () => duel.resolveTurn(CastAction(Spellbook.cataclysm),
            const ChargeAction(MagicElement.water)),
        throwsArgumentError,
      );
    });

    test('casting at 0 charge requires an element', () {
      expect(
        () => duel.resolveTurn(CastAction(Spellbook.flick),
            const ChargeAction(MagicElement.water)),
        throwsArgumentError,
      );
    });
  });

  group('charge cycle', () {
    test('charging builds toward 5 and locks the element', () {
      duel.resolveTurn(const ChargeAction(MagicElement.fire),
          const ChargeAction(MagicElement.water));
      expect(alice.charge, 1);
      expect(alice.element, MagicElement.fire);
      duel.resolveTurn(const ChargeAction(), const ChargeAction());
      expect(alice.charge, 2);
      expect(alice.element, MagicElement.fire);
    });

    test('casting consumes ALL charge, even beyond the spell cost', () {
      alice.charge = 3;
      alice.element = MagicElement.fire;
      duel.resolveTurn(
          CastAction(Spellbook.bolt), const ChargeAction(MagicElement.water));
      expect(alice.charge, 0);
      expect(alice.element, isNull, reason: 'new cycle: element re-chosen');
      expect(bruno.hp, 100 - 12);
    });

    test('0-cost spells are castable immediately with a fresh element', () {
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.fire),
          const ChargeAction(MagicElement.water));
      expect(bruno.hp, 95);
      expect(alice.charge, 0);
    });
  });

  group('priority resolution', () {
    test('shields (3) go up before regular attacks (9) in the same turn', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      bruno.charge = 3;
      bruno.element = MagicElement.air;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.bulwark));
      expect(bruno.hp, 100, reason: 'the 42-point shield absorbs all 22');
      expect(bruno.shield!.remaining, 20);
    });

    test('quickened attacks (2) land before enemy shields (3)', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      duel.resolveTurn(
          CastAction(Spellbook.quicken), const ChargeAction(MagicElement.air));
      alice.charge = 2;
      alice.element = MagicElement.fire;
      bruno.charge = 3;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.bulwark));
      expect(bruno.hp, 100 - 22, reason: 'attack resolves before the shield');
      expect(bruno.shield!.remaining, 42, reason: 'shield up afterwards');
    });

    test('a mage killed at an earlier priority does not resolve later casts',
        () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      alice.quickenPriority = 2;
      bruno.charge = 2;
      bruno.element = MagicElement.water;
      bruno.hp = 20;
      duel.resolveTurn(
          CastAction(Spellbook.blast), CastAction(Spellbook.blast));
      expect(bruno.alive, isFalse);
      expect(alice.hp, 100, reason: "Bruno died before his regular attack");
      expect(duel.winner, alice);
    });

    test('equal-priority mutual kills are a draw', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      alice.hp = 10;
      bruno.charge = 2;
      bruno.element = MagicElement.water;
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
      alice.element = MagicElement.shadow;
      alice.hp = 50;
      duel.resolveTurn(
          CastAction(Spellbook.sap), const ChargeAction(MagicElement.air));
      expect(bruno.hp, 90);
      expect(alice.hp, 60);
    });

    test('lifesteal does not heal for damage soaked by shields', () {
      alice.charge = 1;
      alice.element = MagicElement.shadow;
      alice.hp = 50;
      bruno.shield = ActiveShield.elemental(MagicElement.air, 100);
      duel.resolveTurn(
          CastAction(Spellbook.sap), const ChargeAction(MagicElement.air));
      expect(bruno.hp, 100);
      expect(alice.hp, 50, reason: 'nothing reached health, nothing healed');
    });

    test('empower doubles the next offensive spell', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      duel.resolveTurn(
          CastAction(Spellbook.empower), const ChargeAction(MagicElement.air));
      alice.charge = 1;
      alice.element = MagicElement.fire;
      duel.resolveTurn(CastAction(Spellbook.bolt), const ChargeAction());
      expect(bruno.hp, 100 - 24);
      expect(alice.empowerMultiplier, isNull, reason: 'buff consumed');
    });

    test('phase makes the next offensive spell ignore shields', () {
      alice.charge = 2;
      alice.element = MagicElement.fire;
      bruno.shield = ActiveShield.elemental(MagicElement.air, 100);
      duel.resolveTurn(
          CastAction(Spellbook.phase), const ChargeAction(MagicElement.air));
      alice.charge = 1;
      alice.element = MagicElement.fire;
      duel.resolveTurn(CastAction(Spellbook.bolt), const ChargeAction());
      expect(bruno.hp, 100 - 12);
      expect(bruno.shield!.remaining, 100);
    });

    test('barrage scales with all charge spent', () {
      alice.charge = 4;
      alice.element = MagicElement.electric;
      duel.resolveTurn(
          CastAction(Spellbook.barrage), const ChargeAction(MagicElement.air));
      expect(bruno.hp, 100 - 44);
      expect(alice.charge, 0);
    });

    test('multi-hit spells strike separately', () {
      alice.charge = 3;
      alice.element = MagicElement.fire;
      bruno.shield = ActiveShield.elemental(MagicElement.air, 10);
      duel.resolveTurn(
          CastAction(Spellbook.volley), const ChargeAction(MagicElement.air));
      // Volley: 9 x4. Hit 1: 9 to shield (1 left). Hit 2: breaks it, 8 spills.
      // Hits 3-4: 18 to health.
      expect(bruno.shield, isNull);
      expect(bruno.hp, 100 - 8 - 18);
    });
  });

  group('duel lifecycle', () {
    test('a defeated mage ends the duel with a winner', () {
      bruno.hp = 5;
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.fire),
          const ChargeAction(MagicElement.water));
      expect(duel.isOver, isTrue);
      expect(duel.winner, alice);
      expect(duel.isDraw, isFalse);
    });

    test('resolving a turn after the duel ends throws', () {
      bruno.hp = 0;
      expect(
        () => duel.resolveTurn(const ChargeAction(MagicElement.fire),
            const ChargeAction(MagicElement.water)),
        throwsStateError,
      );
    });
  });
}
