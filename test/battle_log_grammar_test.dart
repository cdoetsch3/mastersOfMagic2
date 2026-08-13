import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:mom_engine/mom_engine.dart';

/// The engine writes third-person log lines from each mage's name. The local
/// player is named "You", so those templates need person agreement fixed.
void main() {
  String fix(String s) => DuelController.toSecondPerson(s);

  group('battle log reads correctly for the player', () {
    test('third-person verbs become second person', () {
      expect(fix('You forfeits the turn'), 'You forfeit the turn');
      expect(fix('You casts pyro Bolt'), 'You cast pyro Bolt');
      expect(
        fix('You channels aqua (charge 2)'),
        'You channel aqua (charge 2)',
      );
      expect(fix('You raises Barrier'), 'You raise Barrier');
      expect(fix('You takes Bolt: 11 damage'), 'You take Bolt: 11 damage');
      expect(fix('You drains 5 health'), 'You drain 5 health');
      expect(
        fix('You seizes the initiative (Haste)'),
        'You seize the initiative (Haste)',
      );
      expect(
        fix('You suffers Ignite: 3 damage'),
        'You suffer Ignite: 3 damage',
      );
      expect(
        fix('You heals 2 from Photosynthesis'),
        'You heal 2 from Photosynthesis',
      );
    });

    test('the copula becomes "are"', () {
      expect(fix('You is defeated'), 'You are defeated');
      expect(
        fix('You is blinded — Bolt misses'),
        'You are blinded — Bolt misses',
      );
    });

    test('the possessive becomes "Your"', () {
      expect(
        fix("You's charge is drained (−1)"),
        'Your charge is drained (−1)',
      );
      expect(
        fix("You's Bolt fizzles (not enough charge at resolution)"),
        'Your Bolt fizzles (not enough charge at resolution)',
      );
    });

    test('the opponent is third person and left alone', () {
      expect(fix('Morwen forfeits the turn'), 'Morwen forfeits the turn');
      expect(fix('Morwen is defeated'), 'Morwen is defeated');
      expect(
        fix("Morwen's charge is drained (−1)"),
        "Morwen's charge is drained (−1)",
      );
    });

    test('a name merely starting with "You" is not mangled', () {
      expect(fix('Young Wick casts pyro Bolt'), 'Young Wick casts pyro Bolt');
    });
  });

  test('a shield-ignoring hit reads as one, in the second person', () {
    // ⭐ The Murmur's Say Your Name walks past a standing shield by design.
    // The whole complaint ("it hit through my shield") was that the log said
    // nothing about it — full damage, an untouched shield bar, and a line
    // indistinguishable from an ordinary hit on a defenceless mage.
    final you = MageState(name: 'You')
      ..shield = ActiveShield.elemental(MagicElement.geo, 40);
    const sayYourName = Spell(
        id: 'ww_sayyourname', name: 'Say Your Name', chargeCost: 3,
        priority: 2, effect: DamageEffect(14, 18, ignoresShields: true));
    final line = fix(
        DamageEvent(you, sayYourName, toShield: 0, toHp: 16,
                bypassedShield: true)
            .toString());
    expect(line, 'You take Say Your Name: 16 damage, ignores shields',
        reason: 'without the tag this line is "You take Say Your Name: 16 '
            'damage" next to a full shield bar, which reads as the shield '
            'having failed rather than having been bypassed');
  });
}
