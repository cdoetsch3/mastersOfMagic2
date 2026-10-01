import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    // ⚠️ critChance pinned to 0 throughout this file: every mage now starts
    // at MageState.baseCritChance (5%, ruling 2026-09-30), and these tests
    // assert exact damage — an unpinned base crit is a 1-in-20 flake per hit.
    // A test about crits sets its own chance after construction.
    alice = MageState(name: 'Alice')..critChance = 0;
    bruno = MageState(name: 'Bruno')..critChance = 0;
    duel = DuelEngine(alice, bruno, elementEffects: false, baseMissPercent: 0);
  });

  test('forfeiting does nothing — charge and element are unchanged', () {
    alice.charge = 3;
    alice.element = MagicElement.pyro;
    duel.resolveTurn(
      const ForfeitAction(),
      const ChargeAction(MagicElement.aqua),
    );
    expect(alice.charge, 3, reason: 'no charge gained or lost');
    expect(alice.element, MagicElement.pyro);
    expect(alice.hp, 100);
  });

  test('forfeiting is strictly worse than channeling (no +1 charge)', () {
    alice.charge = 1;
    alice.element = MagicElement.pyro;
    duel.resolveTurn(
      const ForfeitAction(),
      const ChargeAction(MagicElement.aqua),
    );
    expect(alice.charge, 1);
    expect(bruno.charge, 1, reason: 'Bruno channeled to 1');
  });

  test('the opponent still resolves their move against a forfeiter', () {
    bruno.charge = 2;
    bruno.element = MagicElement.aqua;
    duel.resolveTurn(const ForfeitAction(), CastAction(Spellbook.blast));
    expect(alice.hp, lessThan(100), reason: 'Blast still lands');
  });

  test('forfeiting never grants Haste (like channeling)', () {
    duel.resolveTurn(
      const ForfeitAction(),
      const ChargeAction(MagicElement.aqua),
    );
    expect(duel.hasteHolder, isNull);
  });

  test('a forfeiter is ground down to defeat over repeated turns', () {
    bruno.charge = 2;
    bruno.element = MagicElement.pyro;
    var guard = 0;
    while (!duel.isOver && guard++ < 100) {
      // Bruno keeps Blasting (re-charging when spent); Alice always forfeits.
      final brunoMove = bruno.charge >= 2
          ? CastAction(Spellbook.blast)
          : ChargeAction(bruno.charge == 0 ? MagicElement.pyro : null);
      duel.resolveTurn(const ForfeitAction(), brunoMove);
    }
    expect(duel.winner, bruno);
    expect(alice.alive, isFalse);
  });
}
