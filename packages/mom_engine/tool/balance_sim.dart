// Balance simulator: runs large batches of AI duels and reports duel-length
// and outcome statistics. Used to sanity-check element-effect balance changes
// (e.g. Photosynthesis decay, Fatigue tuning) beyond pass/fail tests.
//
//   dart run tool/balance_sim.dart [duelsPerConfig]
//
// ignore_for_file: avoid_print
import 'dart:math';

import 'package:mom_engine/mom_engine.dart';

/// Forces [inner]'s cycle-opening element to [element] — a mono-element mage.
class MonoElementAi implements DuelAi {
  final DuelAi inner;
  final MagicElement element;
  MonoElementAi(this.inner, this.element);

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) {
    final action = inner.chooseAction(self, enemy, rng);
    if (self.charge == 0) {
      if (action is ChargeAction) return ChargeAction(element);
      if (action is CastAction) return CastAction(action.spell, element);
    }
    return action;
  }
}

class Stats {
  final turns = <int>[];
  int wins1 = 0, wins2 = 0, draws = 0, unfinished = 0;
  int decidedPreFatigue = 0, decidedInFatigue = 0;

  void record(DuelEngine duel, int cap) {
    turns.add(duel.turnNumber);
    if (!duel.isOver) {
      unfinished++;
      return;
    }
    if (duel.turnNumber > DuelEngine.fatigueThreshold) {
      decidedInFatigue++;
    } else {
      decidedPreFatigue++;
    }
    if (duel.isDraw) {
      draws++;
    } else if (identical(duel.winner, duel.mage1)) {
      wins1++;
    } else {
      wins2++;
    }
  }

  String summary(int n) {
    final sorted = List.of(turns)..sort();
    int pct(double p) => sorted[(sorted.length * p).floor().clamp(0, n - 1)];
    final avg = turns.reduce((a, b) => a + b) / n;
    return 'avg ${avg.toStringAsFixed(1)}t  med ${pct(.5)}t  p90 ${pct(.9)}t  '
        'max ${sorted.last}t | pre-fatigue ${_pc(decidedPreFatigue, n)}  '
        'in-fatigue ${_pc(decidedInFatigue, n)}  '
        'unfinished ${_pc(unfinished, n)} | '
        'w1 ${_pc(wins1, n)}  w2 ${_pc(wins2, n)}  draws ${_pc(draws, n)}';
  }

  String _pc(int x, int n) => '${(100 * x / n).toStringAsFixed(1)}%';
}

void main(List<String> args) {
  final n = args.isNotEmpty ? int.parse(args[0]) : 500;
  const cap = 200;

  Stats run(
    String label,
    DuelAi Function() ai1,
    DuelAi Function() ai2, {
    required bool effects,
    int seed = 1,
  }) {
    final rng = Random(seed);
    final stats = Stats();
    for (var i = 0; i < n; i++) {
      final m1 = MageState(name: 'One');
      final m2 = MageState(name: 'Two');
      final duel = DuelEngine(m1, m2, rng: rng, elementEffects: effects);
      final a1 = ai1(), a2 = ai2();
      while (!duel.isOver && duel.turnNumber < cap) {
        duel.resolveTurn(
          a1.chooseAction(m1, m2, rng),
          a2.chooseAction(m2, m1, rng),
        );
      }
      stats.record(duel, cap);
    }
    print('${label.padRight(34)} ${stats.summary(n)}');
    return stats;
  }

  print('=== $n duels per config, cap $cap turns, '
      'fatigue from turn ${DuelEngine.fatigueThreshold + 1} ===\n');

  run('random vs random, effects OFF', RandomAi.new, RandomAi.new,
      effects: false);
  run('random vs random, effects ON', RandomAi.new, RandomAi.new,
      effects: true);
  print('');
  run('greedy vs greedy, effects OFF', GreedyAi.new, GreedyAi.new,
      effects: false);
  run('greedy vs greedy, effects ON', GreedyAi.new, GreedyAi.new,
      effects: true);
  print('');
  run(
      'FLORA mirror (greedy), ON',
      () => MonoElementAi(GreedyAi(), MagicElement.flora),
      () => MonoElementAi(GreedyAi(), MagicElement.flora),
      effects: true);
  run(
      'FLORA mirror (random), ON',
      () => MonoElementAi(RandomAi(), MagicElement.flora),
      () => MonoElementAi(RandomAi(), MagicElement.flora),
      effects: true);

  // Full mono-element round robin (greedy, effects on): win% of the ROW
  // element vs the COLUMN element. The three counter-triangles should show
  // as >50% cells for each element vs its prey.
  print('\n=== mono-element round robin (greedy, effects ON, '
      '${max(100, n ~/ 2)} duels/pair) — row win% vs column ===');
  final m = max(100, n ~/ 2);
  final names =
      MagicElement.values.map((e) => e.name.padRight(7).substring(0, 7));
  print('        ${names.join(' ')}');
  for (final row in MagicElement.values) {
    final cells = <String>[];
    for (final col in MagicElement.values) {
      if (row == col) {
        cells.add('   —   ');
        continue;
      }
      final rng = Random(row.index * 100 + col.index);
      var wins = 0, decisive = 0;
      for (var i = 0; i < m; i++) {
        final m1 = MageState(name: 'R');
        final m2 = MageState(name: 'C');
        final duel = DuelEngine(m1, m2, rng: rng);
        final a1 = MonoElementAi(GreedyAi(), row);
        final a2 = MonoElementAi(GreedyAi(), col);
        while (!duel.isOver && duel.turnNumber < cap) {
          duel.resolveTurn(
            a1.chooseAction(m1, m2, rng),
            a2.chooseAction(m2, m1, rng),
          );
        }
        if (duel.isOver && !duel.isDraw) {
          decisive++;
          if (identical(duel.winner, m1)) wins++;
        }
      }
      final pct = decisive == 0 ? 0 : (100 * wins / decisive).round();
      cells.add('${'$pct%'.padLeft(5)}  ');
    }
    print('${row.name.padRight(7)} ${cells.join(' ')}');
  }
}
