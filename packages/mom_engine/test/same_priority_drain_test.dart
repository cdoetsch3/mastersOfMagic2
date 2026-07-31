import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Charge drains landing against a cast at the SAME priority.
///
/// ⚠️ This whole file is the gap that shipped a regression. Every fizzle test
/// in the suite used *different* priorities — Flick(5)→Surge(9),
/// Discharge(7)→Ruin(9), Discharge(7)→Barrage(9) — and those all keep working,
/// because different-priority groups pay in priority order. Same-priority
/// casts pay *together* (so neither can read a bar the other has spent), and
/// in that window a drain found an already-zeroed bar and silently did
/// nothing: Static Feedback stopped stripping anything at all, and Discharge
/// drained zero. Reported from play as "his Bolt should have fizzled".
class _AlwaysProc implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0.0; // every proc fires
  @override
  bool nextBool() => false;
}

void main() {
  MageState mage(String name, MagicElement e, int charge) =>
      MageState(name: name)
        ..charge = charge
        ..element = e;

  test('Static Feedback still strips a same-priority caster', () {
    // Both cast at priority 9. Leech's Electro proc must reach Wick's charge
    // even though Wick has already committed it to Bolt.
    final you = mage('You', MagicElement.electro, 3);
    final wick = mage('Wick', MagicElement.umbra, 2);

    final r = DuelEngine(you, wick, rng: _AlwaysProc())
        .resolveTurn(CastAction(Spellbook.leech), CastAction(Spellbook.bolt));

    expect(r.events.whereType<ChargeDrainedEvent>(), hasLength(1),
        reason: 'the strip must actually happen, not silently no-op');
  });

  test('a same-priority strip FIZZLES an exactly-affordable spell', () {
    // Wick commits Bolt (cost 1) with exactly 1 charge. The strip takes it,
    // so Bolt can no longer be cast.
    final you = mage('You', MagicElement.electro, 3);
    final wick = mage('Wick', MagicElement.umbra, 1);

    final r = DuelEngine(you, wick, rng: _AlwaysProc())
        .resolveTurn(CastAction(Spellbook.leech), CastAction(Spellbook.bolt));

    expect(r.events.whereType<SpellFizzledEvent>(), hasLength(1),
        reason: 'Bolt lost the only charge it had');
    expect(you.hp, greaterThan(0));
    expect(r.events.whereType<SpellCastEvent>().length, 1,
        reason: 'only Leech went off');
  });

  test('a strip that leaves enough charge does NOT fizzle the spell', () {
    // ⭐ The case from the report: 2 charge, stripped by 1, Bolt costs 1 — so
    // Bolt correctly still goes off. Losing charge is not the same as losing
    // the spell.
    final you = mage('You', MagicElement.electro, 3);
    final wick = mage('Wick', MagicElement.umbra, 2);

    final r = DuelEngine(you, wick, rng: _AlwaysProc())
        .resolveTurn(CastAction(Spellbook.leech), CastAction(Spellbook.bolt));

    expect(r.events.whereType<SpellFizzledEvent>(), isEmpty);
    expect(r.events.whereType<SpellCastEvent>().length, 2,
        reason: '1 charge remained, and Bolt costs 1');
  });

  test('a same-priority Discharge empties a committed bar and fizzles it', () {
    final you = mage('You', MagicElement.electro, 2);
    final wick = mage('Wick', MagicElement.umbra, 4);

    // Discharge is priority 7; give Wick a priority-7 cast so they collide.
    final r = DuelEngine(you, wick, rng: Random(1))
        .resolveTurn(CastAction(Spellbook.discharge),
            CastAction(Spellbook.hasty, MagicElement.umbra));

    final drained = r.events.whereType<ChargeDrainedEvent>();
    expect(drained, isNotEmpty, reason: 'Discharge must take the committed bar');
    expect(wick.charge, 0);
  });

  test('a drain cannot reach a spell that ALREADY went off', () {
    // ⚠️ The inverse mistake: charge committed to a cast that has resolved is
    // spent, and a later strip in the same turn must not claw it back and
    // retroactively fizzle it.
    final you = mage('You', MagicElement.electro, 3);
    final wick = mage('Wick', MagicElement.umbra, 3);

    // Wick's Flick is priority 5 and resolves before the Electro Leech at 9.
    final r = DuelEngine(you, wick, rng: _AlwaysProc()).resolveTurn(
        CastAction(Spellbook.leech), CastAction(Spellbook.flick));

    expect(r.events.whereType<SpellFizzledEvent>(), isEmpty,
        reason: "Wick's Flick had already resolved when the strip landed");
  });
}
