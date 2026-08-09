import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Regression: the element-streak pip lagged a full turn behind.
///
/// The streak used to be recorded AFTER all of a cast's events were emitted,
/// so no status frame captured it. A plain Aero Bolt emits nothing afterwards
/// (Tailwind only fires from the 3rd cast), so the new count did not surface
/// until some later turn happened to emit an event — the reported "Aero 2
/// appears after the next charge, not after the Bolt".
void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  int streakIn(StatusSnapshot s) => s['streak']?.stacks ?? 0;

  test('the streak is visible in the same turn the cast lands', () {
    final duel = DuelEngine(alice, bruno, rng: Random(7), baseMissPercent: 0);

    // Turn 1 — Aero Flick. Streak becomes 1.
    alice.element = MagicElement.aero;
    var r = duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.aero), const ForfeitAction());
    expect(streakIn(r.frames.last.mage1), 1,
        reason: 'the first cast shows a streak of 1 on its own turn');

    // Turn 2 — charge Aero. The streak does not advance on a charge.
    r = duel.resolveTurn(
        const ChargeAction(MagicElement.aero), const ForfeitAction());
    expect(streakIn(r.frames.last.mage1), 1, reason: 'charging never advances');

    // Turn 3 — Aero Bolt. This is the one that used to lag.
    r = duel.resolveTurn(CastAction(Spellbook.bolt), const ForfeitAction());
    expect(streakIn(r.frames.last.mage1), 2,
        reason: 'the Bolt turn must show 2, not wait for the next charge');
  });

  test('the new count is carried by the cast event itself, not a later one',
      () {
    final duel = DuelEngine(alice, bruno, rng: Random(7), baseMissPercent: 0);
    alice.element = MagicElement.aero;
    final r = duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.aero), const ForfeitAction());

    final castIdx = r.events.indexWhere((e) => e is SpellCastEvent);
    expect(castIdx, greaterThanOrEqualTo(0));
    expect(streakIn(r.frames[castIdx].mage1), 1,
        reason: 'the pip lands with the cast, not at end of turn');
  });

  test('a fizzle or miss still leaves the streak alone', () {
    final duel = DuelEngine(alice, bruno, rng: Random(7), baseMissPercent: 0);
    alice.element = MagicElement.aero;
    var r = duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.aero), const ForfeitAction());
    expect(streakIn(r.frames.last.mage1), 1);

    // A real fizzle: Alice commits a Bolt she can afford, but Bruno's
    // Discharge (priority 7) resolves first and wipes her charge, so the
    // priority-9 Bolt has nothing left to cast.
    alice
      ..charge = 1
      ..element = MagicElement.aero;
    bruno
      ..charge = 2
      ..element = MagicElement.pyro;
    r = duel.resolveTurn(
        CastAction(Spellbook.bolt), CastAction(Spellbook.discharge));
    expect(r.events.whereType<SpellFizzledEvent>(), hasLength(1),
        reason: 'the Bolt fizzled');
    expect(streakIn(r.frames.last.mage1), 1,
        reason: 'a fizzle behaves like a charge — no streak change');
  });
}
