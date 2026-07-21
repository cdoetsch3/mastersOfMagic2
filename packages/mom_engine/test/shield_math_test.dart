import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState attacker;
  late MageState defender;
  late DuelEngine duel;

  setUp(() {
    attacker = MageState(name: 'Attacker');
    defender = MageState(name: 'Defender');
    duel = DuelEngine(attacker, defender, elementEffects: false);
  });

  /// Charges [mage] up to [target] charge in [element] while the other mage
  /// charges air (a no-op filler action).
  void chargeUp(MageState mage, MagicElement element, int target) {
    while (mage.charge < target) {
      final filler = ChargeAction(
          (mage == attacker ? defender : attacker).charge == 0
              ? MagicElement.aero
              : null);
      final action = ChargeAction(mage.charge == 0 ? element : null);
      duel.resolveTurn(
        mage == attacker ? action : filler,
        mage == attacker ? filler : action,
      );
    }
  }

  test('design doc example: 30 water attack vs 50 fire shield', () {
    // "a 50 point fire shield, I could cast a 30 damage water attack, and it
    //  would deal 25 of its 30 damage against the shield that was double
    //  damage, and the remaining 5 damage to the enemy user."
    defender.shield = ActiveShield.elemental(MagicElement.pyro, 50);
    const waterAttack = Spell(
        id: 'test30', name: 'Test30', chargeCost: 0, priority: 9,
        effect: DamageEffect(30, 30));
    duel.resolveTurn(
      CastAction(waterAttack, MagicElement.aqua),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.shield, isNull, reason: 'shield shatters');
    expect(defender.hp, 95, reason: 'only 5 overflow reaches health');
  });

  test('non-countered attack hits the shield at normal rate', () {
    defender.shield = ActiveShield.elemental(MagicElement.pyro, 50);
    const earthAttack = Spell(
        id: 'test30e', name: 'Test30e', chargeCost: 0, priority: 9,
        effect: DamageEffect(30, 30));
    duel.resolveTurn(
      CastAction(earthAttack, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.shield!.remaining, 20);
    expect(defender.hp, 100);
  });

  test('cross-tier attacks never counter a shield', () {
    // With the three closed triangles, countering only happens within a tier.
    for (final shield in MagicElement.values) {
      for (final attack in MagicElement.values) {
        if (attack.tier != shield.tier) {
          expect(attack.counters(shield), isFalse,
              reason: '${attack.name} should not counter ${shield.name}');
        }
      }
    }
  });

  test('barrier blocks one hit entirely, then is gone', () {
    defender.shield = ActiveShield.barrier();
    duel.resolveTurn(
      CastAction(Spellbook.flick, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.hp, 100);
    expect(defender.shield, isNull);
  });

  test('multi-hit vs barrier: first hit absorbed, later hits land', () {
    const tripleHit = Spell(
        id: 'test3x4', name: 'Test3x4', chargeCost: 0, priority: 9,
        effect: DamageEffect(4, 4, hits: 3));
    defender.shield = ActiveShield.barrier();
    duel.resolveTurn(
      CastAction(tripleHit, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.shield, isNull);
    expect(defender.hp, 100 - 4 * 2, reason: 'hits 2 and 3 land');
  });

  group('ShieldRaisedEvent snapshots the shield as raised', () {
    // Regression: the event used to hold the LIVE ActiveShield, so a shield
    // chipped later in the same turn reported its post-damage value. The UI
    // then subtracted that damage a second time and drove the displayed
    // shield negative.
    test('reports full strength even when chipped later the same turn', () {
      chargeUp(attacker, MagicElement.flora, 1);
      const poke = Spell(
          id: 'testpoke', name: 'Poke', chargeCost: 0, priority: 9,
          effect: DamageEffect(6, 6));
      // Ward (priority 3) goes up, then the priority-9 poke chips it.
      final result = duel.resolveTurn(
        CastAction(Spellbook.ward),
        CastAction(poke),
      );
      final raised =
          result.events.whereType<ShieldRaisedEvent>().single;
      expect(raised.strength, inInclusiveRange(13, 17),
          reason: 'Ward rolls 13-17 — never the post-damage remainder');
      expect(raised.element, MagicElement.flora);
      expect(raised.isBarrier, isFalse);
      // The live shield really did take the hit.
      expect(attacker.shield!.remaining, raised.strength - 6);
    });

    test('replaying the events never drives a shield below zero', () {
      // Mirrors how the UI rebuilds its display copy: start from the raised
      // strength, then subtract each reported toShield.
      chargeUp(attacker, MagicElement.flora, 1);
      const poke = Spell(
          id: 'testpoke2', name: 'Poke2', chargeCost: 0, priority: 9,
          effect: DamageEffect(6, 6));
      final result = duel.resolveTurn(
        CastAction(Spellbook.ward),
        CastAction(poke),
      );
      var shown = 0;
      for (final e in result.events) {
        if (e is ShieldRaisedEvent) shown = e.strength;
        if (e is DamageEvent && e.target == attacker) shown -= e.toShield;
      }
      expect(shown, greaterThanOrEqualTo(0));
      expect(shown, attacker.shield!.remaining);
    });

    test('a Barrier reports as element-less', () {
      chargeUp(attacker, MagicElement.flora, 2);
      final result = duel.resolveTurn(
        CastAction(Spellbook.barrier),
        const ChargeAction(MagicElement.aero),
      );
      final raised = result.events.whereType<ShieldRaisedEvent>().single;
      expect(raised.isBarrier, isTrue);
      expect(raised.element, isNull);
    });
  });

  test('shield persists across turns until depleted', () {
    const poke = Spell(
        id: 'test5', name: 'Test5', chargeCost: 0, priority: 9,
        effect: DamageEffect(5, 5));
    defender.shield = ActiveShield.elemental(MagicElement.geo, 40);
    duel.resolveTurn(
      CastAction(poke, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.shield!.remaining, 35);
    duel.resolveTurn(
      CastAction(poke, MagicElement.geo),
      ChargeAction(),
    );
    expect(defender.shield!.remaining, 30);
  });

  test('casting a new shield replaces the old one', () {
    chargeUp(attacker, MagicElement.geo, 1);
    attacker.shield = ActiveShield.elemental(MagicElement.aqua, 3);
    duel.resolveTurn(
      CastAction(Spellbook.ward),
      ChargeAction(),
    );
    expect(attacker.shield!.element, MagicElement.geo);
    expect(attacker.shield!.remaining, inInclusiveRange(13, 17),
        reason: 'Ward rolls 13-17');
  });

  test('shield-ignoring damage goes straight to health', () {
    defender.shield = ActiveShield.elemental(MagicElement.geo, 999);
    const pierce = Spell(
        id: 'testp', name: 'TestPierce', chargeCost: 0, priority: 9,
        effect: DamageEffect(10, 10, ignoresShields: true));
    duel.resolveTurn(
      CastAction(pierce, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.hp, 90);
    expect(defender.shield!.remaining, 999);
  });
}
