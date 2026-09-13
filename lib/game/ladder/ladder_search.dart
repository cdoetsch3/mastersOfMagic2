/// LADDER_DESIGN §3 — the widening-band schedule and the bot pick, pulled
/// out of [Matchmaking.quickMatch] as pure, clock/rng-free functions so the
/// schedule's boundaries and the weighting can be tested exhaustively
/// without sleeping or touching Firestore.
library;

import 'dart:math';

import 'ladder_bots.dart';

/// The widening human-only band schedule (LADDER §3's table) and the bot
/// pick that follows it once the patience runs out.
abstract final class LadderSearch {
  const LadderSearch._();

  /// The claim band at [elapsed] since the search began (LADDER §3):
  /// ±100 until 3 s, ±200 until 6 s, ±400 from 6 s on (which also covers the
  /// 6–10 s phase and anything past it — phase 4 stops consulting this and
  /// picks a bot instead).
  ///
  /// ⚠️ **Boundaries are inclusive on the early side, exclusive on the late
  /// side** — `elapsed < 3s` is phase 1, so exactly 3000 ms is already phase
  /// 2. A mutant flipping `<` to `<=` moves the boundary by one instant and
  /// is exactly what the exhaustive ms-boundary tests catch.
  static int bandAt(Duration elapsed) {
    if (elapsed < const Duration(seconds: 3)) return 100;
    if (elapsed < const Duration(seconds: 6)) return 200;
    return 400;
  }

  /// The rating the search holds [bot] at: its LIVE `bots/*` standing when
  /// the read succeeded, else its seed. ⭐ One answer for the pick weights,
  /// the duel header and the settlement, so they can never disagree.
  static int ratingOf(
    LadderBot bot, {
    required Map<String, int> liveRatings,
    required bool academy,
  }) => liveRatings[bot.id] ?? (academy ? bot.seedAcademy : bot.seedGeared);

  /// Picks a bot for [rating] on the given ladder (LADDER §3 phase 4):
  /// candidates start at band 100 and the band doubles until at least one
  /// bot (other than [excludeBotId]) qualifies, then one is drawn weighted
  /// by closeness — `weight = 1 / (1 + |theirRating - rating|)` — using
  /// [rng].
  ///
  /// ⭐ [liveRatings] is the LIVE `bots/*` standing for a bot id, read once by
  /// the caller via `BotRatings.fetch` (LADDER §4.1: "the rating it read at
  /// match start"). A bot missing from the map — including every bot when
  /// the fetch itself failed — weighs off its SEED instead
  /// ([LadderBot.seedGeared]/[LadderBot.seedAcademy]), which is always a
  /// safe fallback because a bot's live rating starts there.
  ///
  /// ⚠️ **[excludeBotId] is filtered before the band check, not after** — a
  /// band that (before exclusion) contained only the previous opponent must
  /// keep doubling rather than returning an empty pick.
  static LadderBot pickBot(
    int rating, {
    required bool academy,
    String? excludeBotId,
    Random? rng,
    Map<String, int> liveRatings = const {},
  }) {
    final random = rng ?? Random();
    var band = 100;
    var candidates = <LadderBot>[];
    // ⭐ The roster is finite (27 bots) and every seed is a bounded int, so a
    // band wide enough to cover the whole roster always exists — this loop
    // terminates by construction. The upper guard only protects against a
    // pathological caller (e.g. an empty roster) ever spinning forever.
    while (candidates.isEmpty && band < 1 << 20) {
      candidates = LadderRoster.withinBand(
        rating,
        band: band,
        academy: academy,
      ).where((b) => b.id != excludeBotId).toList();
      if (candidates.isEmpty) band *= 2;
    }
    if (candidates.isEmpty) {
      // Defensive fallback only — unreachable with the real 27-bot roster.
      candidates = LadderRoster.all.where((b) => b.id != excludeBotId).toList();
    }

    final weights = [
      for (final b in candidates)
        1.0 /
            (1.0 +
                (ratingOf(b, liveRatings: liveRatings, academy: academy) -
                        rating)
                    .abs()),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var draw = random.nextDouble() * total;
    for (var i = 0; i < candidates.length; i++) {
      draw -= weights[i];
      if (draw <= 0) return candidates[i];
    }
    return candidates.last; // floating-point rounding safety net.
  }
}
