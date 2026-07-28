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

/// A realistic loadout: ~5 elements and ~10 spells, drawn at random.
///
/// ⚠️ Simulating with the **whole** spellbook and every element measures a game
/// nobody plays — a real mage brings 15 slots (PROGRESSION §1), so every result
/// from an unconstrained sim overstates how much answer-to-everything a build
/// has. These are the numbers that correspond to an actual loadout.
class SimLoadout {
  final List<MagicElement> elements;
  final List<Spell> spells;
  SimLoadout(this.elements, this.spells);

  static SimLoadout random(Random rng, {int elementCount = 5, int spellCount = 10}) {
    final els = List.of(MagicElement.values)..shuffle(rng);
    final sp = List.of(Spellbook.all)..shuffle(rng);
    // A loadout with no way to deal damage is not a loadout; guarantee one.
    final picked = sp.take(spellCount).toList();
    if (!picked.any((s) => s.isOffensive)) {
      picked[0] = Spellbook.all.firstWhere((s) => s.isOffensive);
    }
    return SimLoadout(els.take(elementCount).toList(), picked);
  }
}

/// ⚠️ Kept only for brains that cannot choose an element themselves.
/// [LadderAi] takes its own `elements` pool, so level 5+ can counter-pick —
/// wrapping it here would take that competence away.
class LoadoutAi implements DuelAi {
  final DuelAi inner;
  final SimLoadout loadout;
  final Random rng;
  LoadoutAi(this.inner, this.loadout, this.rng);

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random r) {
    self.element ??= loadout.elements[r.nextInt(loadout.elements.length)];
    return inner.chooseAction(self, enemy, r);
  }
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

  run('i1 (random) vs i1, effects OFF', () => LadderAi(1), () => LadderAi(1),
      effects: false);
  run('i1 (random) vs i1, effects ON', () => LadderAi(1), () => LadderAi(1),
      effects: true);
  print('');
  run('i7 vs i7, effects OFF', () => LadderAi(7), () => LadderAi(7),
      effects: false);
  run('i7 vs i7, effects ON', () => LadderAi(7), () => LadderAi(7),
      effects: true);
  print('');
  run(
      'FLORA mirror (i7), ON',
      () => MonoElementAi(LadderAi(7), MagicElement.flora),
      () => MonoElementAi(LadderAi(7), MagicElement.flora),
      effects: true);
  run(
      'FLORA mirror (i1), ON',
      () => MonoElementAi(LadderAi(1), MagicElement.flora),
      () => MonoElementAi(LadderAi(1), MagicElement.flora),
      effects: true);

  // ---- The intelligence ladder, on realistic loadouts -----------------
  print('\n=== intelligence ladder — random ~5 element / ~10 spell loadouts, '
      'effects ON, $n duels/pair ===');
  print('row win% vs column');
  const rungs = [1, 3, 5, 7, 9, 10];
  print('        ${rungs.map((r) => 'i$r'.padRight(6)).join(' ')}');
  for (final row in rungs) {
    final cells = <String>[];
    for (final col in rungs) {
      if (row == col) {
        cells.add('  —   ');
        continue;
      }
      final rng = Random(row * 100 + col);
      var wins = 0, decisive = 0;
      for (var i = 0; i < n; i++) {
        final m1 = MageState(name: 'R');
        final m2 = MageState(name: 'C');
        final duel = DuelEngine(m1, m2, rng: rng, elementEffects: true);
        final l1 = SimLoadout.random(rng);
        final l2 = SimLoadout.random(rng);
        final a1 =
            LadderAi(row, spells: l1.spells, elements: l1.elements);
        final a2 =
            LadderAi(col, spells: l2.spells, elements: l2.elements);
        while (!duel.isOver && duel.turnNumber < cap) {
          duel.resolveTurn(
            a1.chooseAction(m1, m2, rng),
            a2.chooseAction(m2, m1, rng),
          );
        }
        if (duel.isOver && duel.winner != null) {
          decisive++;
          if (duel.winner == m1) wins++;
        }
      }
      final pct = decisive == 0 ? 50.0 : wins * 100 / decisive;
      cells.add('${pct.toStringAsFixed(0).padLeft(4)}% ');
    }
    print('i$row'.padRight(8) + cells.join(' '));
  }

  // ---- Mono-element round robin, at three points on the ladder --------
  //
  // ⚠️ Element is locked and skill is held constant, which is the *opposite*
  // of the ladder table above: to measure whether the counter wheel is
  // balanced you must hold skill fixed, and to measure skill you must not let
  // element matchups swamp the signal. Two questions, two sims.
  //
  // ⭐ Run at three intelligences on purpose. A matchup table is only true for
  // the skill it was measured at — an unaware brain cannot play Lunar timing,
  // Astral stacking or Sanctus streaks, so it systematically under-reads the
  // elements whose strength lives in planning. If an edge moves between i4 and
  // i10, that edge depends on competence rather than on raw numbers.
  void roundRobin(int intelligence, int duels) {
    print('\n=== mono-element round robin — INTELLIGENCE $intelligence, '
        'random ~10-spell loadouts, effects ON, $duels duels/pair ===');
    print('row win% vs column');
    final names =
        MagicElement.values.map((e) => e.name.padRight(7).substring(0, 7));
    print('        ${names.join(' ')}');
    final rowAvg = <MagicElement, double>{};
    for (final row in MagicElement.values) {
      final cells = <String>[];
      var sum = 0.0;
      var counted = 0;
      for (final col in MagicElement.values) {
        if (row == col) {
          cells.add('   —   ');
          continue;
        }
        final rng = Random(row.index * 100 + col.index + intelligence * 7919);
        var wins = 0, decisive = 0;
        for (var i = 0; i < duels; i++) {
          final m1 = MageState(name: 'R');
          final m2 = MageState(name: 'C');
          final duel = DuelEngine(m1, m2, rng: rng, elementEffects: true);
          // Elements are locked, but the SPELL BOOK is drawn — nobody plays
          // with all 25 spells, and pretending otherwise rewards a
          // charge-to-five pattern that a real loadout cannot always run.
          final a1 = MonoElementAi(
              LadderAi(intelligence, spells: SimLoadout.random(rng).spells),
              row);
          final a2 = MonoElementAi(
              LadderAi(intelligence, spells: SimLoadout.random(rng).spells),
              col);
          while (!duel.isOver && duel.turnNumber < cap) {
            duel.resolveTurn(
              a1.chooseAction(m1, m2, rng),
              a2.chooseAction(m2, m1, rng),
            );
          }
          if (duel.isOver && duel.winner != null) {
            decisive++;
            if (duel.winner == m1) wins++;
          }
        }
        final pct = decisive == 0 ? 50.0 : wins * 100 / decisive;
        sum += pct;
        counted++;
        cells.add('${pct.toStringAsFixed(0).padLeft(4)}%  ');
      }
      rowAvg[row] = counted == 0 ? 50 : sum / counted;
      print('${row.name.padRight(8)}${cells.join('')}');
    }
    print('  overall win% (target 40-60):');
    for (final e in MagicElement.values) {
      final v = rowAvg[e]!;
      final flag = (v < 40 || v > 60) ? '  <-- OUTSIDE' : '';
      print('    ${e.name.padRight(9)}${v.toStringAsFixed(1)}%$flag');
    }
  }

  // ⚠️ Full sample per pair, not a quarter. A round robin at 125 duels/pair
  // once read Geo at 62% and looked like a balance failure; at 500 it is
  // 59.7%. Two-point overshoots are not callable at low resolution, and this
  // is the table people make rulings from.
  for (final i in const [4, 7, 10]) {
    roundRobin(i, n);
  }
}
