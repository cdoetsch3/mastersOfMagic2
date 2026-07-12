import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Seeded end-to-end sanity: full duels between AIs must run legally to
/// completion, and the heuristic AI must beat the random one.
void main() {
  const turnCap = 200;

  ({int wins1, int wins2, int draws, int unfinished}) run(
      DuelAi ai1, DuelAi ai2, int duels, int seed) {
    final rng = Random(seed);
    var wins1 = 0, wins2 = 0, draws = 0, unfinished = 0;
    for (var i = 0; i < duels; i++) {
      final m1 = MageState(name: 'One');
      final m2 = MageState(name: 'Two');
      final duel = DuelEngine(m1, m2);
      while (!duel.isOver && duel.turnNumber < turnCap) {
        duel.resolveTurn(
          ai1.chooseAction(m1, m2, rng),
          ai2.chooseAction(m2, m1, rng),
        );
      }
      if (!duel.isOver) {
        unfinished++;
      } else if (duel.isDraw) {
        draws++;
      } else if (duel.winner == m1) {
        wins1++;
      } else {
        wins2++;
      }
    }
    return (wins1: wins1, wins2: wins2, draws: draws, unfinished: unfinished);
  }

  test('AI duels run legally to completion', () {
    final result = run(RandomAi(), RandomAi(), 200, 1);
    expect(result.unfinished, lessThan(10),
        reason: 'almost all random duels should end within the cap');
  });

  test('greedy AI convincingly beats random AI', () {
    final result = run(GreedyAi(), RandomAi(), 200, 2);
    expect(result.wins1, greaterThan(result.wins2 * 2));
  });

  test('greedy mirror match is roughly fair', () {
    final result = run(GreedyAi(), GreedyAi(), 300, 3);
    final decisive = result.wins1 + result.wins2;
    expect(decisive, greaterThan(0));
    final ratio = result.wins1 / decisive;
    expect(ratio, closeTo(0.5, 0.15),
        reason: 'neither seat should have a large structural advantage');
  });
}
