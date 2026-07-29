import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// When charge is spent, and who can still see it.
///
/// ⚠️ These exist because charge used to be swept up **after** the whole turn
/// resolved. A mage who committed their bar to a shield at priority 3 still
/// showed a full bar to an Overload later in the turn — so Overload punished
/// charge that had already been spent. Reported from play: "Al'Dorian casts
/// Bulwark ... You cast Overload ... 48 to shield", off a bar that was gone.
void main() {
  DuelEngine duel(MageState a, MageState b, {int seed = 1}) =>
      DuelEngine(a, b, rng: Random(seed), elementEffects: false);

  void charged(MageState m, MagicElement e, int n) {
    m
      ..charge = n
      ..element = e;
  }

  group('a spent bar cannot be punished', () {
    test('a shield cast first leaves nothing for Overload to read', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.arcane, 4);
      charged(b, MagicElement.astral, 4);

      // Bulwark is priority 3; Overload is 9. B commits their bar first.
      duel(a, b).resolveTurn(
        CastAction(Spellbook.overload),
        CastAction(Spellbook.bulwark),
      );

      expect(b.charge, 0, reason: 'B spent their bar on the shield');
      expect(
        b.shield,
        isNotNull,
        reason: 'the shield went up before Overload landed',
      );
      expect(
        b.shield!.remaining,
        greaterThan(0),
        reason: 'Overload found no charge to punish, so the shield survives',
      );
      expect(b.hp, 100);
    });

    test('a quick attack first also empties the bar', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.arcane, 4);
      charged(b, MagicElement.pyro, 4);

      // Flick is a quick attack (priority 5), ahead of Overload's 9.
      duel(a, b).resolveTurn(
        CastAction(Spellbook.overload),
        CastAction(Spellbook.flick),
      );
      expect(b.hp, 100, reason: 'Overload punished an already-spent bar');
    });

    test('charge the enemy HOLDS is punished in full', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.arcane, 2);
      charged(b, MagicElement.pyro, 4);

      // ⭐ Overload sits at priority 9 with the other regular attacks, so it
      // reads the board after the turn's shields and quick spells have landed.
      // What is left to punish is charge its owner chose to keep — here, by
      // charging again instead of spending.
      duel(a, b).resolveTurn(
        CastAction(Spellbook.overload),
        const ChargeAction(),
      );
      expect(100 - b.hp, inInclusiveRange(35, 55), reason: '5 x 7-11');
    });
  });

  group('simultaneous casts cannot read each other', () {
    test('two Overloads both find nothing to punish', () {
      // ⭐ With no Haste there is no "first", so neither may read a bar the
      // other has already committed. Both fizzle to nothing.
      for (var seed = 0; seed < 10; seed++) {
        final a = MageState(name: 'A');
        final b = MageState(name: 'B');
        charged(a, MagicElement.arcane, 4);
        charged(b, MagicElement.astral, 4);

        duel(a, b, seed: seed).resolveTurn(
          CastAction(Spellbook.overload),
          CastAction(Spellbook.overload),
        );
        expect(a.hp, 100, reason: 'seed $seed');
        expect(b.hp, 100, reason: 'seed $seed');
      }
    });

    test('two Discharges both end on zero', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.electro, 4);
      charged(b, MagicElement.geo, 5);

      duel(a, b).resolveTurn(
        CastAction(Spellbook.discharge),
        CastAction(Spellbook.discharge),
      );
      expect(a.charge, 0);
      expect(b.charge, 0);
    });
  });

  group('Haste decides who reads the board first', () {
    test('the holder Overloads a full bar; the other finds it empty', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.arcane, 4);
      charged(b, MagicElement.astral, 4);
      a.hasHaste = true;

      duel(a, b).resolveTurn(
        CastAction(Spellbook.overload),
        CastAction(Spellbook.overload),
      );

      expect(
        b.hp,
        lessThan(100),
        reason: 'the Haste holder paid first and read a full enemy bar',
      );
      expect(
        a.hp,
        100,
        reason: "the slower Overload found the holder's bar already spent",
      );
    });
  });

  group('what a fizzle keeps', () {
    test('a Discharged caster keeps the charge their spell never used', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.electro, 5);
      charged(b, MagicElement.pyro, 3);

      // Discharge (7) empties A before their Cataclysm (9) can go off.
      duel(a, b).resolveTurn(
        CastAction(Spellbook.cataclysm),
        CastAction(Spellbook.discharge),
      );
      expect(b.hp, 100, reason: 'the Cataclysm never went off');
      expect(
        a.charge,
        0,
        reason: 'Discharge took the bar; the fizzle gives back only what was '
            'there at the moment of casting, which was nothing',
      );
    });

    test('a Barrage still scales with what it actually paid', () {
      final a = MageState(name: 'A');
      final b = MageState(name: 'B');
      charged(a, MagicElement.pyro, 4);

      duel(a, b).resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction());
      expect(
        100 - b.hp,
        inInclusiveRange(28, 40),
        reason: '4 hits of 7-10 — the caster reads the bar it paid, not the '
            'zero left behind by paying it',
      );
    });
  });
}
