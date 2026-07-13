import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState attacker;
  late MageState defender;
  late DuelEngine duel;

  setUp(() {
    attacker = MageState(name: 'Attacker');
    defender = MageState(name: 'Defender');
    duel = DuelEngine(attacker, defender);
  });

  /// Charges [mage] up to [target] charge in [element] while the other mage
  /// charges air (a no-op filler action).
  void chargeUp(MageState mage, MagicElement element, int target) {
    while (mage.charge < target) {
      final filler = ChargeAction(
          (mage == attacker ? defender : attacker).charge == 0
              ? MagicElement.air
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
    defender.shield = ActiveShield.elemental(MagicElement.fire, 50);
    const waterAttack = Spell(
        id: 'test30', name: 'Test30', chargeCost: 0, priority: 9,
        effect: DamageEffect(30, 30));
    duel.resolveTurn(
      CastAction(waterAttack, MagicElement.water),
      ChargeAction(MagicElement.air),
    );
    expect(defender.shield, isNull, reason: 'shield shatters');
    expect(defender.hp, 95, reason: 'only 5 overflow reaches health');
  });

  test('non-countered attack hits the shield at normal rate', () {
    defender.shield = ActiveShield.elemental(MagicElement.fire, 50);
    const earthAttack = Spell(
        id: 'test30e', name: 'Test30e', chargeCost: 0, priority: 9,
        effect: DamageEffect(30, 30));
    duel.resolveTurn(
      CastAction(earthAttack, MagicElement.earth),
      ChargeAction(MagicElement.air),
    );
    expect(defender.shield!.remaining, 20);
    expect(defender.hp, 100);
  });

  test('air shields are never countered', () {
    defender.shield = ActiveShield.elemental(MagicElement.air, 30);
    for (final element in MagicElement.values) {
      expect(element.counters(MagicElement.air), isFalse);
    }
  });

  test('barrier blocks one hit entirely, then is gone', () {
    defender.shield = ActiveShield.barrier();
    duel.resolveTurn(
      CastAction(Spellbook.flick, MagicElement.fire),
      ChargeAction(MagicElement.air),
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
      CastAction(tripleHit, MagicElement.fire),
      ChargeAction(MagicElement.air),
    );
    expect(defender.shield, isNull);
    expect(defender.hp, 100 - 4 * 2, reason: 'hits 2 and 3 land');
  });

  test('shield persists across turns until depleted', () {
    const poke = Spell(
        id: 'test5', name: 'Test5', chargeCost: 0, priority: 9,
        effect: DamageEffect(5, 5));
    defender.shield = ActiveShield.elemental(MagicElement.earth, 40);
    duel.resolveTurn(
      CastAction(poke, MagicElement.fire),
      ChargeAction(MagicElement.air),
    );
    expect(defender.shield!.remaining, 35);
    duel.resolveTurn(
      CastAction(poke, MagicElement.fire),
      ChargeAction(),
    );
    expect(defender.shield!.remaining, 30);
  });

  test('casting a new shield replaces the old one', () {
    chargeUp(attacker, MagicElement.fire, 1);
    attacker.shield = ActiveShield.elemental(MagicElement.water, 3);
    duel.resolveTurn(
      CastAction(Spellbook.ward),
      ChargeAction(),
    );
    expect(attacker.shield!.element, MagicElement.fire);
    expect(attacker.shield!.remaining, inInclusiveRange(13, 17),
        reason: 'Ward rolls 13-17');
  });

  test('shield-ignoring damage goes straight to health', () {
    defender.shield = ActiveShield.elemental(MagicElement.earth, 999);
    const pierce = Spell(
        id: 'testp', name: 'TestPierce', chargeCost: 0, priority: 9,
        effect: DamageEffect(10, 10, ignoresShields: true));
    duel.resolveTurn(
      CastAction(pierce, MagicElement.fire),
      ChargeAction(MagicElement.air),
    );
    expect(defender.hp, 90);
    expect(defender.shield!.remaining, 999);
  });
}
