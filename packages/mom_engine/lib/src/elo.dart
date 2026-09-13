import 'dart:math';

/// Chess Elo (LADDER_DESIGN §2). ⭐ One formula for humans and bots alike.
abstract final class Elo {
  const Elo._();

  /// Both ladders start every player here (LADDER_DESIGN §2).
  static const int startingRating = 1200;

  /// FIDE K schedule: 40 for the first 30 rated games, 20 after, 10 once the
  /// player has EVER reached 2400 on this ladder (LADDER_DESIGN §2).
  ///
  /// ⭐ The 2400 check is on [peakRating], not the current rating — a player
  /// who touched 2400 and fell back still plays at K = 10. That's the whole
  /// point of a *peak* field on the profile.
  static int kFor({required int ratedGames, required int peakRating}) {
    if (peakRating >= 2400) return 10;
    return ratedGames < 30 ? 40 : 20;
  }

  /// Win probability for the rated side: `1 / (1 + 10^((b-a)/400))`.
  static double expected(int rating, int opponentRating) {
    return 1 / (1 + pow(10, (opponentRating - rating) / 400));
  }

  /// Rounded delta for the rated side. [score] is 1.0 (won) or 0.0 (lost).
  ///
  /// ⚠️ Rounds to nearest int with `.round()` — half-away-from-zero, not
  /// truncation. A mutant that floors instead of rounds will under-award.
  static int delta({
    required int rating,
    required int opponentRating,
    required double score,
    required int k,
  }) {
    final e = expected(rating, opponentRating);
    return (k * (score - e)).round();
  }

  /// Clamp a bot's rating to ±[band] of its [seed] (§2, the anti-farm guard).
  static int clampToSeed(int rating, {required int seed, int band = 300}) {
    final floor = seed - band;
    final ceiling = seed + band;
    if (rating < floor) return floor;
    if (rating > ceiling) return ceiling;
    return rating;
  }
}

/// Seed formulas for ladder bots and first-time player ratings
/// (LADDER_DESIGN §2, §5).
abstract final class LadderSeeds {
  const LadderSeeds._();

  /// Geared ladder bot seed: `1080 + 12*level + 15*intelligence + gearTerm`.
  ///
  /// [gearTerm] is Bare 0 · Worn 15 · Kitted 30 · Prized 45 · Peak 60
  /// (LADDER_DESIGN §4 gear tiers) — callers pass the resolved int.
  static int gearedBot({
    required int level,
    required int intelligence,
    required int gearTerm,
  }) {
    return 1080 + 12 * level + 15 * intelligence + gearTerm;
  }

  /// Geared ladder first-rated-match seed for a PLAYER: the bot formula at
  /// intelligence 5 with no gear term (`1080 + 12*level + 75`).
  static int gearedPlayer({required int level}) {
    return 1080 + 12 * level + 75;
  }

  /// Academy bot seed: `1200 + 60*(intelligence - 5)`. Players start at
  /// [Elo.startingRating] — level and gear don't exist on this ladder.
  static int academyBot({required int intelligence}) {
    return 1200 + 60 * (intelligence - 5);
  }
}
