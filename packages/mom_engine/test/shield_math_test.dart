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

  test('a truly neutral attack hits the shield at normal rate', () {
    // Kinetic vs Ethereal is the opposite-tier (neutral) macro matchup — the
    // only cross-tier pairing that is still 100%. (Geo vs a Primal shield is
    // now 150%, since Kinetic beats Primal — see the macro-tier group below.)
    defender.shield = ActiveShield.elemental(MagicElement.umbra, 50);
    const geoAttack = Spell(
        id: 'test30e', name: 'Test30e', chargeCost: 0, priority: 9,
        effect: DamageEffect(30, 30));
    duel.resolveTurn(
      CastAction(geoAttack, MagicElement.geo),
      ChargeAction(MagicElement.aero),
    );
    expect(defender.shield!.remaining, 20, reason: '30 at 100%');
    expect(defender.hp, 100);
  });

  // TYPE_EFFECTS_DESIGN §0.3 — the full six-relationship table, asserted on
  // the pure helper (exhaustive) and then spot-checked through a real turn.
  group('§0.3 shield multiplier table', () {
    test('within-tier: counter 200, countered 50, mirror 100', () {
      // Primal triangle: pyro → flora → aqua → pyro.
      expect(shieldMultiplierPercent(MagicElement.pyro, MagicElement.flora),
          200); // you counter their shield
      expect(shieldMultiplierPercent(MagicElement.flora, MagicElement.pyro),
          50); // their shield counters you
      expect(shieldMultiplierPercent(MagicElement.pyro, MagicElement.pyro),
          100); // same element
    });

    test('macro-tier: your tier wins 150, their tier wins 75', () {
      // Kinetic beats Primal; Primal beats Ethereal.
      expect(shieldMultiplierPercent(MagicElement.geo, MagicElement.pyro),
          150); // kinetic attacker into primal shield
      expect(shieldMultiplierPercent(MagicElement.pyro, MagicElement.geo),
          75); // primal attacker into kinetic shield
    });

    test('opposite tiers are neutral both ways (100)', () {
      // Primal↔Celestial and Kinetic↔Ethereal.
      expect(shieldMultiplierPercent(MagicElement.pyro, MagicElement.solar),
          100);
      expect(shieldMultiplierPercent(MagicElement.solar, MagicElement.pyro),
          100);
      expect(shieldMultiplierPercent(MagicElement.geo, MagicElement.umbra),
          100);
    });

    test('element-agnostic damage never counters (100)', () {
      expect(shieldMultiplierPercent(null, MagicElement.pyro), 100);
    });

    test('the two layers never stack — only one rule ever applies', () {
      // Every ordered pair lands on exactly one of the five legal values.
      for (final a in MagicElement.values) {
        for (final s in MagicElement.values) {
          expect(shieldMultiplierPercent(a, s), isIn([50, 75, 100, 150, 200]),
              reason: '${a.name} vs ${s.name}');
        }
      }
    });

    test('the resist edge (50%) chips a shield at half rate', () {
      // Flora attacking into a Pyro shield: Pyro counters Flora → 50%.
      defender.shield = ActiveShield.elemental(MagicElement.pyro, 50);
      const floraAttack = Spell(
          id: 't50', name: 'T50', chargeCost: 0, priority: 9,
          effect: DamageEffect(30, 30));
      duel.resolveTurn(
        CastAction(floraAttack, MagicElement.flora),
        ChargeAction(MagicElement.aero),
      );
      expect(defender.shield!.remaining, 35, reason: '30 × 50% = 15 to shield');
      expect(defender.hp, 100);
    });

    test('the macro edge (150%) overflows across a tier boundary', () {
      // Geo (Kinetic) into a Pyro (Primal) shield: Kinetic beats Primal → 150%.
      // 30 × 150% = 45 effective vs a 30-point shield → shatters, and the
      // overflow reaches health at the normal 1× rate.
      defender.shield = ActiveShield.elemental(MagicElement.pyro, 30);
      const geoAttack = Spell(
          id: 't150', name: 'T150', chargeCost: 0, priority: 9,
          effect: DamageEffect(30, 30));
      duel.resolveTurn(
        CastAction(geoAttack, MagicElement.geo),
        ChargeAction(MagicElement.aero),
      );
      expect(defender.shield, isNull, reason: 'shield shatters');
      // 30 shield absorbed at 150% = 20 raw consumed; 10 raw overflows to hp.
      expect(defender.hp, 90);
    });

    test('the 75% edge lets a weak attacker through slowly', () {
      // Pyro (Primal) into a Geo (Kinetic) shield: Kinetic beats Primal, so
      // the attacker is the weaker tier → 75%.
      defender.shield = ActiveShield.elemental(MagicElement.geo, 40);
      const pyroAttack = Spell(
          id: 't75', name: 'T75', chargeCost: 0, priority: 9,
          effect: DamageEffect(40, 40));
      duel.resolveTurn(
        CastAction(pyroAttack, MagicElement.pyro),
        ChargeAction(MagicElement.aero),
      );
      // 40 × 75% = 30 to a 40-point shield → 10 remaining, nothing to hp.
      expect(defender.shield!.remaining, 10);
      expect(defender.hp, 100);
    });
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
      // The live shield really did take the hit. The exact chip depends on the
      // §0.3 multiplier (the poke is Aero into a Flora shield — Kinetic beats
      // Primal, so 150%); this test is about the *snapshot*, not the multiplier,
      // so derive the chip from the reported event rather than hardcoding it.
      final chip = result.events
          .whereType<DamageEvent>()
          .where((e) => e.target == attacker)
          .fold(0, (sum, e) => sum + e.toShield);
      expect(attacker.shield!.remaining, raised.strength - chip);
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
