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

  test('forfeiting does nothing — charge and element are unchanged', () {
    alice.charge = 3;
    alice.element = MagicElement.fire;
    duel.resolveTurn(
        const ForfeitAction(), const ChargeAction(MagicElement.water));
    expect(alice.charge, 3, reason: 'no charge gained or lost');
    expect(alice.element, MagicElement.fire);
    expect(alice.hp, 100);
  });

  test('forfeiting is strictly worse than channeling (no +1 charge)', () {
    alice.charge = 1;
    alice.element = MagicElement.fire;
    duel.resolveTurn(
        const ForfeitAction(), const ChargeAction(MagicElement.water));
    expect(alice.charge, 1);
    expect(bruno.charge, 1, reason: 'Bruno channeled to 1');
  });

  test('the opponent still resolves their move against a forfeiter', () {
    bruno.charge = 2;
    bruno.element = MagicElement.water;
    duel.resolveTurn(const ForfeitAction(), CastAction(Spellbook.blast));
    expect(alice.hp, lessThan(100), reason: 'Blast still lands');
  });

  test('forfeiting never grants Haste (like channeling)', () {
    duel.resolveTurn(
        const ForfeitAction(), const ChargeAction(MagicElement.water));
    expect(duel.hasteHolder, isNull);
  });

  test('a forfeiter is ground down to defeat over repeated turns', () {
    bruno.charge = 2;
    bruno.element = MagicElement.fire;
    var guard = 0;
    while (!duel.isOver && guard++ < 100) {
      // Bruno keeps Blasting (re-charging when spent); Alice always forfeits.
      final brunoMove = bruno.charge >= 2
          ? CastAction(Spellbook.blast)
          : ChargeAction(bruno.charge == 0 ? MagicElement.fire : null);
      duel.resolveTurn(const ForfeitAction(), brunoMove);
    }
    expect(duel.winner, bruno);
    expect(alice.alive, isFalse);
  });
}
