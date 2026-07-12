import 'dart:math';

import 'package:mom_engine/mom_engine.dart';

/// AI-vs-AI balance simulator.
///
///   dart run mom_engine:simulate [duels] [seed]
///
/// Runs seeded matchups and prints win rates and duel lengths. Pass --verbose
/// to print a full turn-by-turn log of a single duel instead.
void main(List<String> args) {
  if (args.contains('--verbose')) {
    _verboseDuel(seed: 7);
    return;
  }
  final duels = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final seed = args.length > 1 ? int.parse(args[1]) : 42;

  _matchup('Greedy', GreedyAi(), 'Random', RandomAi(), duels, seed);
  _matchup('Greedy', GreedyAi(), 'Greedy', GreedyAi(), duels, seed);
  _matchup('Random', RandomAi(), 'Random', RandomAi(), duels, seed);
}

const _turnCap = 200;

void _matchup(String name1, DuelAi ai1, String name2, DuelAi ai2, int duels,
    int seed) {
  final rng = Random(seed);
  var wins1 = 0, wins2 = 0, draws = 0, timeouts = 0, totalTurns = 0;
  for (var i = 0; i < duels; i++) {
    final m1 = MageState(name: name1);
    final m2 = MageState(name: name2);
    final duel = DuelEngine(m1, m2);
    while (!duel.isOver && duel.turnNumber < _turnCap) {
      duel.resolveTurn(
        ai1.chooseAction(m1, m2, rng),
        ai2.chooseAction(m2, m1, rng),
      );
    }
    totalTurns += duel.turnNumber;
    if (!duel.isOver) {
      timeouts++;
    } else if (duel.isDraw) {
      draws++;
    } else if (duel.winner == m1) {
      wins1++;
    } else {
      wins2++;
    }
  }
  String pct(int n) => '${(n * 100 / duels).toStringAsFixed(1)}%';
  print('$name1 vs $name2 ($duels duels): '
      '$name1 ${pct(wins1)} | $name2 ${pct(wins2)} | draws ${pct(draws)}'
      '${timeouts > 0 ? ' | timeouts ${pct(timeouts)}' : ''} | '
      'avg ${(totalTurns / duels).toStringAsFixed(1)} turns');
}

void _verboseDuel({required int seed}) {
  final rng = Random(seed);
  final m1 = MageState(name: 'Aldric');
  final m2 = MageState(name: 'Morwen');
  final ai1 = GreedyAi();
  final ai2 = GreedyAi();
  final duel = DuelEngine(m1, m2);
  while (!duel.isOver && duel.turnNumber < _turnCap) {
    final result = duel.resolveTurn(
      ai1.chooseAction(m1, m2, rng),
      ai2.chooseAction(m2, m1, rng),
    );
    print('— Turn ${result.turn} '
        '(${m1.name} ${m1.hp}hp, ${m2.name} ${m2.hp}hp)');
    print(result);
  }
  print(duel.isDraw
      ? 'Draw!'
      : '${duel.winner!.name} wins on turn ${duel.turnNumber}.');
}
