// LADDER PROBE — a seeded, headless bot-vs-bot round robin that measures
// whether the roster's HAND-WRITTEN seeds (LADDER_DESIGN.md §2, §5) line up
// with how the bots actually play each other, the free telemetry §6
// describes: "the sim harness should gain a `--ladder` mode that plays
// every bot against every bot 200× and prints implied ratings, so the seeds
// can be sanity-checked *before* players do it for us."
//
// It is the ladder's answer to `tool/balance_probe_test.dart` — same shape,
// same reason for living in test/tool land rather than as a bare `main()`:
// it needs the real Flutter-side game code (the 27-bot roster, item
// catalogue, `DuelController`), and `flutter test` is the cheapest place
// that runs headless.
//
//   flutter test tool/ladder_probe_test.dart              (CI-fast default)
//   LADDER_PROBE_DEEP=1 flutter test tool/ladder_probe_test.dart  (full report)
//
// ⭐ **Engine and production code untouched.** Every duel is built through
// the real seam — `LadderBot.toPersona()` → `LocalAiDriver` → `DuelController`
// (the same chain `test/local_ai_driver_test.dart` and the roster tests pin)
// — so gear application, level scaling and brain construction can never
// drift from what a real ladder match does. Both sides are driven by their
// OWN `LadderAi` (`toPersona().buildBrain()`, at the bot's own archetype
// intelligence) rather than a fixed rung, because unlike the balance probe
// this file's whole point IS to compare bots of different skill against
// each other. ⚠️ Neither side is given a `thinkTime` — this probe must
// never sleep — so both mages are driven straight off `DuelEngine`, exactly
// the way `balance_probe_test.dart`'s own `_DuelRig` bypasses
// `driver.exchangeTurn` for the same reason.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/academy.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:mom_engine/mom_engine.dart';

/// Turn cap mirroring `balance_probe_test.dart` — belt-and-braces only;
/// `DuelEngine.fatigueThreshold` guarantees termination long before this.
const int _turnCap = 200;

/// LADDER_DESIGN §6's fixed-point solver: a small K applied over many
/// sweeps, so the numbers converge to a stable implied rating rather than
/// bouncing on the last handful of games.
const double _k = 8.0;
const int _sweeps = 300;

/// ⚠️ The self-correction threshold this probe flags — §6's "a bot sitting
/// 200 above its seed" example, rounded down to a slightly more sensitive
/// 150 so the report catches a drifting bot before it reaches that example.
const int _driftWarnThreshold = 150;

// ---------------------------------------------------------------------
// One duel, built exactly as a real ladder match builds it
// ---------------------------------------------------------------------

/// Builds one bot-vs-bot duel through the real seam. [playerBot] is built
/// straight (`DuelController.loadout`/`playerLevel`/`playerGear`);
/// [enemyBot] rides the `LocalAiDriver` seam a human opponent would use —
/// there is no third, hand-rolled path.
class _Rig {
  final MageState player;
  final MageState enemy;
  final DuelEngine engine;
  const _Rig(this.player, this.enemy, this.engine);

  factory _Rig.build({
    required LadderBot playerBot,
    required LadderBot enemyBot,
    required bool academy,
    required int seed,
  }) {
    final playerGear = academy ? ItemModifiers.none : playerBot.gearModifiers;
    final enemyGear = academy ? ItemModifiers.none : enemyBot.gearModifiers;
    final controller = DuelController(
      loadout: playerBot.loadout,
      driver: LocalAiDriver(
        persona: enemyBot.toPersona(),
        // ⭐ LADDER_DESIGN §1 law 5 / academy.dart: the Academy plays
        // everyone at the level cap with nothing worn — never a thinkTime,
        // never a rating, both of which this probe has no use for.
        levelOverride: academy ? Academy.level : null,
        gear: enemyGear,
        rng: Random(seed),
      ),
      playerLevel: academy ? Academy.level : playerBot.level,
      playerGear: playerGear,
      rng: ReseedableRandom(seed),
    );
    return _Rig(controller.player, controller.enemy, controller.engine);
  }
}

class _Outcome {
  final bool decided; // engine.isOver — false only if the turn cap was hit
  final bool playerWon;
  final bool isDraw;
  const _Outcome({
    required this.decided,
    required this.playerWon,
    required this.isDraw,
  });
}

_Outcome _playDuel({
  required LadderBot playerBot,
  required LadderBot enemyBot,
  required bool academy,
  required int seed,
}) {
  final rig = _Rig.build(
    playerBot: playerBot,
    enemyBot: enemyBot,
    academy: academy,
    seed: seed,
  );
  // ⭐ One shared rng stream for engine resolution AND both brains'
  // decisions — same convention as `balance_probe_test.dart`, and why two
  // probe runs at the same seed reproduce the same duel bit-for-bit.
  final rng = rig.engine.rng;
  // ⭐ Each bot's OWN brain — archetype intelligence, own spells/elements —
  // unlike the balance probe's fixed rung: this probe exists to compare
  // skill, not to hold it constant. Same brain on both ladders; only the
  // BODY (level, gear) changes for Academy (see [_Rig.build]).
  final playerAi = playerBot.toPersona().buildBrain();
  final enemyAi = enemyBot.toPersona().buildBrain();
  while (!rig.engine.isOver && rig.engine.turnNumber < _turnCap) {
    rig.engine.resolveTurn(
      playerAi.chooseAction(rig.player, rig.enemy, rng),
      enemyAi.chooseAction(rig.enemy, rig.player, rng),
    );
  }
  return _Outcome(
    decided: rig.engine.isOver,
    playerWon: rig.engine.isOver && identical(rig.engine.winner, rig.player),
    isDraw: rig.engine.isOver && rig.engine.isDraw,
  );
}

// ---------------------------------------------------------------------
// Implied-rating solver (LADDER_DESIGN §6)
// ---------------------------------------------------------------------

/// One recorded result: [scoreA] is 1.0 (won), 0.5 (drew, or the duel hit
/// the turn cap undecided) or 0.0 (lost), from [a]'s perspective.
class _Game {
  final String a;
  final String b;
  final double scoreA;
  const _Game(this.a, this.b, this.scoreA);
}

/// ⭐ LADDER_DESIGN §6's fixed-point solver. Starting every bot at its own
/// seed and repeatedly nudging each pairing toward the outcome
/// `Elo.expected` predicted — `delta = k * (score - Elo.expected(a, b))`,
/// applied to both sides — converges to a Bradley–Terry-like implied rating:
/// a bot that keeps outperforming what its rating predicts gets pulled up
/// every sweep, one that keeps underperforming gets pulled down, and the
/// process settles once every pairwise expectation matches the long-run
/// score. Anchoring the mean back to the seed mean after every sweep is
/// what stops the whole population drifting up or down together — Elo only
/// has a relative scale, never an absolute one, so without an anchor a
/// closed pool with no external opponent has nothing to pin it down.
///
/// ⚠️ [Elo.expected] takes INT ratings — every lookup rounds the live
/// double accumulator first, so the fixed point solved here is the same one
/// two real ladder games would move toward, not a higher-precision fiction
/// the real K=40/20/10 schedule could never reach.
Map<String, int> _impliedRatings({
  required List<String> ids,
  required Map<String, int> seeds,
  required List<_Game> games,
  int sweeps = _sweeps,
  double k = _k,
}) {
  final rating = {for (final id in ids) id: seeds[id]!.toDouble()};
  final meanSeed = seeds.values.reduce((x, y) => x + y) / seeds.length;
  for (var s = 0; s < sweeps; s++) {
    for (final g in games) {
      final ra = rating[g.a]!;
      final rb = rating[g.b]!;
      final expectedA = Elo.expected(ra.round(), rb.round());
      final delta = k * (g.scoreA - expectedA);
      rating[g.a] = ra + delta;
      rating[g.b] = rb - delta;
    }
    // ⭐ Re-anchor every sweep, not just at the end — keeps the population
    // mean pinned to the seed mean throughout, rather than letting 300
    // sweeps of unanchored drift accumulate before a single correction.
    final meanImplied = rating.values.reduce((x, y) => x + y) / rating.length;
    final shift = meanSeed - meanImplied;
    for (final id in ids) {
      rating[id] = rating[id]! + shift;
    }
  }
  return {for (final id in ids) id: rating[id]!.round()};
}

// ---------------------------------------------------------------------
// Spearman rank correlation (hand-rolled — no package)
// ---------------------------------------------------------------------

/// Average-rank vector for [values] — ties share the mean of the ranks they
/// would occupy, 1-indexed. Needed because several bots can land on the
/// exact same implied rating after rounding.
List<double> _ranks(List<double> values) {
  final n = values.length;
  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => values[a].compareTo(values[b]));
  final ranks = List<double>.filled(n, 0);
  var i = 0;
  while (i < n) {
    var j = i;
    while (j + 1 < n && values[order[j + 1]] == values[order[i]]) {
      j++;
    }
    // Ranks at sorted positions i..j (0-indexed) tie — share the average of
    // the 1-indexed positions they span.
    final avgRank = (i + 1 + j + 1) / 2;
    for (var m = i; m <= j; m++) {
      ranks[order[m]] = avgRank;
    }
    i = j + 1;
  }
  return ranks;
}

double _pearson(List<double> x, List<double> y) {
  final n = x.length;
  final meanX = x.reduce((a, b) => a + b) / n;
  final meanY = y.reduce((a, b) => a + b) / n;
  var num = 0.0;
  var denX = 0.0;
  var denY = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = x[i] - meanX;
    final dy = y[i] - meanY;
    num += dx * dy;
    denX += dx * dx;
    denY += dy * dy;
  }
  if (denX == 0 || denY == 0) return 0;
  return num / sqrt(denX * denY);
}

/// ⭐ Spearman's rho, computed by hand: the Pearson correlation of the RANK
/// vectors (ties broken by average rank). Deliberately not the textbook
/// `1 - 6*Σd²/(n*(n²-1))` shortcut — that formula is only valid with no
/// ties, and rounded implied ratings tie often enough that the shortcut
/// would quietly misreport this exact report's own numbers.
double spearmanCorrelation(List<double> x, List<double> y) {
  assert(x.length == y.length && x.isNotEmpty);
  return _pearson(_ranks(x), _ranks(y));
}

// ---------------------------------------------------------------------
// Aggregation + report
// ---------------------------------------------------------------------

class _BotStat {
  int games = 0;
  int wins = 0;
  double get winPct => games == 0 ? 0 : wins * 100 / games;
}

class _LadderReport {
  final String table;
  final double maxAbsDrift;
  final double spearman;
  const _LadderReport(this.table, this.maxAbsDrift, this.spearman);
}

/// Plays [roster] round robin ([gamesPerPair] games per unordered pair,
/// sides alternated so neither bot always moves first), solves implied
/// ratings, and renders one ladder's table + one-line summary.
///
/// [master] is consumed for every duel's seed, in a fixed nested loop order
/// (i, then j, then game index) — that fixed order, not wall-clock or a
/// fresh `Random()`, is what makes two runs byte-identical.
_LadderReport _runLadder({
  required String label,
  required List<LadderBot> roster,
  required bool academy,
  required int gamesPerPair,
  required Random master,
}) {
  final ids = [for (final b in roster) b.id];
  final byId = {for (final b in roster) b.id: b};
  final seeds = {
    for (final b in roster) b.id: academy ? b.seedAcademy : b.seedGeared,
  };
  final stats = {for (final id in ids) id: _BotStat()};
  final games = <_Game>[];
  var undecided = 0;

  for (var i = 0; i < roster.length; i++) {
    for (var j = i + 1; j < roster.length; j++) {
      for (var g = 0; g < gamesPerPair; g++) {
        // Alternate who moves first (host) across the pair's games, so a
        // pair played more than once at LADDER_PROBE_DEEP=1 doesn't always
        // hand the same bot first move.
        final swapped = g.isOdd;
        final playerBot = swapped ? roster[j] : roster[i];
        final enemyBot = swapped ? roster[i] : roster[j];
        final seed = master.nextInt(1 << 30);
        final outcome = _playDuel(
          playerBot: playerBot,
          enemyBot: enemyBot,
          academy: academy,
          seed: seed,
        );
        stats[playerBot.id]!.games++;
        stats[enemyBot.id]!.games++;
        double scoreForPlayer;
        if (!outcome.decided || outcome.isDraw) {
          if (!outcome.decided) undecided++;
          scoreForPlayer = 0.5;
        } else if (outcome.playerWon) {
          scoreForPlayer = 1.0;
          stats[playerBot.id]!.wins++;
        } else {
          scoreForPlayer = 0.0;
          stats[enemyBot.id]!.wins++;
        }
        games.add(_Game(playerBot.id, enemyBot.id, scoreForPlayer));
      }
    }
  }

  final implied = _impliedRatings(ids: ids, seeds: seeds, games: games);

  final rows = [
    for (final id in ids)
      (
        bot: byId[id]!,
        seed: seeds[id]!,
        implied: implied[id]!,
        drift: implied[id]! - seeds[id]!,
        winPct: stats[id]!.winPct,
      ),
  ].toList()..sort((a, b) => a.drift.compareTo(b.drift));

  final duelCount = ids.length * (ids.length - 1) ~/ 2 * gamesPerPair;
  final buf = StringBuffer();
  buf.writeln(
    '$label LADDER — $gamesPerPair game(s)/pair, ${roster.length} bots, '
    '$duelCount duels',
  );
  buf.writeln(
    '${'name'.padRight(14)}${'lvl'.padRight(5)}${'int'.padRight(5)}'
    '${'gear'.padRight(8)}${'seed'.padRight(7)}${'implied'.padRight(9)}'
    '${'drift'.padRight(8)}${'win%'.padRight(8)}flag',
  );
  for (final r in rows) {
    final flag = r.drift.abs() > _driftWarnThreshold ? '⚠️' : '';
    buf.writeln(
      r.bot.name.padRight(14) +
          '${r.bot.level}'.padRight(5) +
          '${r.bot.intelligence}'.padRight(5) +
          r.bot.gearTier.name.padRight(8) +
          '${r.seed}'.padRight(7) +
          '${r.implied}'.padRight(9) +
          '${r.drift}'.padRight(8) +
          '${r.winPct.toStringAsFixed(1)}%'.padRight(8) +
          flag,
    );
  }
  if (undecided > 0) {
    buf.writeln(
      '  ($undecided/${games.length} duels hit the $_turnCap-turn cap '
      'without deciding — scored as a draw)',
    );
  }

  final maxAbsDrift = rows.map((r) => r.drift.abs()).reduce(max).toDouble();
  final spearman = spearmanCorrelation(
    [for (final r in rows) r.seed.toDouble()],
    [for (final r in rows) r.implied.toDouble()],
  );
  final summary =
      '$label summary — max |drift|: ${maxAbsDrift.toStringAsFixed(0)}, '
      'Spearman(seed, implied): ${spearman.toStringAsFixed(3)}';
  buf.writeln(summary);

  return _LadderReport(buf.toString(), maxAbsDrift, spearman);
}

// ---------------------------------------------------------------------
// Default-N roster sizing
// ---------------------------------------------------------------------

/// 📝 If a future roster grows past what a ~15s CI budget affords at the
/// default N=1 (measured when this file was written: the full 27-bot round
/// robin at N=1, both ladders, comfortably cleared that budget — see the
/// wall-clock note in this file's own test run), flip this to `true` and
/// the default drops to 9 evenly-spaced bots instead of silently getting
/// slower every time a bot is added to the roster.
const bool _useSubsetByDefault = false;

/// 9 bots spread evenly across [full] (weakest to strongest, as the roster
/// is already ordered) rather than the first/strongest 9 — a subset should
/// still sanity-check the whole rating curve, not just one end of it.
List<LadderBot> _evenSubset(List<LadderBot> full, int n) {
  final step = full.length / n;
  return [
    for (var i = 0; i < n; i++)
      full[(i * step).floor().clamp(0, full.length - 1)],
  ];
}

void main() {
  final deep = Platform.environment['LADDER_PROBE_DEEP'] == '1';
  final fullRoster = LadderRoster.all;
  final usingSubset = !deep && _useSubsetByDefault;
  final roster = usingSubset ? _evenSubset(fullRoster, 9) : fullRoster;
  final gamesPerPair = deep ? 20 : 1;

  test('ladder probe', () {
    if (usingSubset) {
      print(
        'NOTE: default pass uses a subset of ${roster.length} bots '
        '(LADDER_PROBE_DEEP=1 runs the full ${fullRoster.length}-bot roster).',
      );
    }
    // ⭐ Seeded from one fixed Random(1234) (the brief's own instruction),
    // consumed across BOTH ladders in a fixed order (geared, then
    // academy) — that, plus the fixed nested pairing loop in
    // [_runLadder], is the entire determinism story.
    final master = Random(1234);
    final geared = _runLadder(
      label: 'GEARED',
      roster: roster,
      academy: false,
      gamesPerPair: gamesPerPair,
      master: master,
    );
    final academy = _runLadder(
      label: 'ACADEMY',
      roster: roster,
      academy: true,
      gamesPerPair: gamesPerPair,
      master: master,
    );
    print(geared.table);
    print('');
    print(academy.table);
  }, timeout: Timeout(Duration(minutes: deep ? 15 : 2)));

  test('deterministic: two runs at a tiny N print byte-identical reports', () {
    final subset = fullRoster.take(4).toList();
    final a = _runLadder(
      label: 'GEARED',
      roster: subset,
      academy: false,
      gamesPerPair: 1,
      master: Random(1234),
    );
    final b = _runLadder(
      label: 'GEARED',
      roster: subset,
      academy: false,
      gamesPerPair: 1,
      master: Random(1234),
    );
    expect(
      a.table,
      b.table,
      reason: 'the report must be a pure function of its seed',
    );
  });

  group('implied rating solver', () {
    test('A always beats B always beats C yields implied A > B > C '
        '(kills a sign-flipped delta mutant)', () {
      const ids = ['A', 'B', 'C'];
      const seeds = {'A': 1200, 'B': 1200, 'C': 1200};
      final games = <_Game>[
        for (var i = 0; i < 20; i++) const _Game('A', 'B', 1.0),
        for (var i = 0; i < 20; i++) const _Game('B', 'C', 1.0),
        for (var i = 0; i < 20; i++) const _Game('A', 'C', 1.0),
      ];
      final implied = _impliedRatings(ids: ids, seeds: seeds, games: games);
      expect(
        implied['A']! > implied['B']!,
        isTrue,
        reason:
            'A always beats B — a mutant that flips the delta sign would '
            'pull A down and B up instead, inverting this',
      );
      expect(
        implied['B']! > implied['C']!,
        isTrue,
        reason:
            'B always beats C — same sign-flip mutant would invert this too',
      );
      expect(
        implied['A']! > implied['C']!,
        isTrue,
        reason: 'A always beats C directly as well',
      );
    });

    test('a matrix of all 50/50 results leaves every implied rating at the '
        'seed mean (anchor test)', () {
      const ids = ['A', 'B', 'C'];
      const seeds = {'A': 1000, 'B': 1200, 'C': 1600};
      final games = <_Game>[
        for (var i = 0; i < 10; i++) const _Game('A', 'B', 0.5),
        for (var i = 0; i < 10; i++) const _Game('A', 'C', 0.5),
        for (var i = 0; i < 10; i++) const _Game('B', 'C', 0.5),
      ];
      final implied = _impliedRatings(ids: ids, seeds: seeds, games: games);
      const meanSeed = (1000 + 1200 + 1600) / 3;
      for (final id in ids) {
        expect(
          (implied[id]! - meanSeed).abs() <= 1,
          isTrue,
          reason:
              '$id: an all-50/50 matrix carries no signal to separate '
              'ratings, so the anchor step must park every bot within '
              'rounding of the seed mean ($meanSeed) instead of leaving '
              'it near its own seed (${seeds[id]}) — a mutant that skips '
              'or breaks the re-anchor would leave $id un-pulled',
        );
      }
    });
  });

  group('spearman rank correlation', () {
    test('identical orderings correlate at 1.0', () {
      final rho = spearmanCorrelation(
        const [1, 2, 3, 4, 5].map((e) => e.toDouble()).toList(),
        const [10, 20, 30, 40, 50].map((e) => e.toDouble()).toList(),
      );
      expect(
        rho,
        closeTo(1.0, 1e-9),
        reason:
            'two vectors in the same relative order must correlate perfectly',
      );
    });

    test('reversed orderings correlate at -1.0', () {
      final rho = spearmanCorrelation(
        const [1, 2, 3, 4, 5].map((e) => e.toDouble()).toList(),
        const [50, 40, 30, 20, 10].map((e) => e.toDouble()).toList(),
      );
      expect(
        rho,
        closeTo(-1.0, 1e-9),
        reason: 'exact opposite orderings must correlate perfectly negatively',
      );
    });
  });
}
