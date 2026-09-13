/// Applying one finished rated duel (LADDER_DESIGN §2): the pure Elo math,
/// then the I/O that banks it — the player's profile always, and a bot's
/// `bots/{id}` doc when the opponent was one.
library;

import 'package:mom_engine/mom_engine.dart';

import '../game_state.dart';
import '../opponent_driver.dart';
import 'bot_ratings.dart';
import 'ladder_bots.dart';

/// One rated result, pure: both sides' deltas and the rated side's new
/// rating. [opponentDelta] is informational for a human (nobody writes it —
/// they update their own profile on their own client) and is what
/// [settleRatedDuel] clamps and writes for a bot.
class RatedOutcome {
  final int playerDelta;
  final int opponentDelta;
  final int newPlayerRating;
  const RatedOutcome({
    required this.playerDelta,
    required this.opponentDelta,
    required this.newPlayerRating,
  });
}

/// LADDER_DESIGN §2's Elo, applied to one duel. ⭐ No draws exist (a duel
/// always ends with one mage at 0), so the two scores are always `1 - 0` or
/// `0 - 1` and [Elo.kFor] is looked up independently per side — the schedule
/// depends on each side's OWN rated-games/peak, not the opponent's.
RatedOutcome rate({
  required int playerRating,
  required int playerRatedGames,
  required int playerPeak,
  required int opponentRating,
  required int opponentRatedGames,
  required int opponentPeak,
  required bool won,
}) {
  final playerK = Elo.kFor(
    ratedGames: playerRatedGames,
    peakRating: playerPeak,
  );
  final opponentK = Elo.kFor(
    ratedGames: opponentRatedGames,
    peakRating: opponentPeak,
  );
  final playerScore = won ? 1.0 : 0.0;
  final opponentScore = won ? 0.0 : 1.0;
  final playerDelta = Elo.delta(
    rating: playerRating,
    opponentRating: opponentRating,
    score: playerScore,
    k: playerK,
  );
  final opponentDelta = Elo.delta(
    rating: opponentRating,
    opponentRating: playerRating,
    score: opponentScore,
    k: opponentK,
  );
  return RatedOutcome(
    playerDelta: playerDelta,
    opponentDelta: opponentDelta,
    newPlayerRating: playerRating + playerDelta,
  );
}

/// Finds the [LadderBot] a [LocalAiDriver] is standing in for, or null when
/// [driver] isn't one (a practice-roster persona happens to share an id with
/// a borrowed bot, e.g. Wick — this still resolves it, which is fine: the
/// CALLER decides whether this was a rated match at all).
LadderBot? _ladderBotBehind(OpponentDriver driver) {
  if (driver is! LocalAiDriver) return null;
  for (final bot in LadderRoster.all) {
    if (bot.id == driver.persona.id) return bot;
  }
  return null;
}

/// Settles one finished rated duel (LADDER_DESIGN §2, §4.1): resolves the
/// player's current rating on [academy]'s ladder (or its seed, on a first
/// rated match), applies [rate], and banks the result.
///
/// ⭐ **The profile write goes through [GameState.applyRatedResult]**, which
/// wraps `ladder_record.applyRatedResult` in `_mutate` exactly like every
/// other profile change — so it persists and notifies like anything else.
///
/// ⭐ **A bot's write is additive and clamped.** [opponentRating] is the
/// rating this client read for the opponent at match time — LIVE for a bot
/// (LADDER §4.1: "the rating it read at match start"), from whichever human
/// the wire says for a person. When the opponent is a [LadderBot], the
/// [RatedOutcome.opponentDelta] `rate` computed off that same rating is
/// clamped to the bot's seed band (`Elo.clampToSeed`) and only the CLAMPED
/// remainder is written, via [BotRatings.record] — never the raw delta.
///
/// ⚠️ **A human opponent gets no write here at all.** They update their own
/// profile on their own client; this function only ever writes the LOCAL
/// player's profile plus, for a bot, the shared `bots/{id}` doc.
///
/// ⚠️ **Room-code duels are unrated** (LADDER §3): a [RemoteDuelDriver] whose
/// [RemoteDuelDriver.rated] is false is a no-op, full stop — nothing is read
/// from the profile and nothing is written. Only `Matchmaking.quickMatch`'s
/// human path sets `rated: true`.
Future<void> settleRatedDuel(
  GameState game, {
  required OpponentDriver driver,
  required bool academy,
  required bool won,
  required int opponentRating,
}) async {
  if (driver is RemoteDuelDriver && !driver.rated) return;

  final profile = game.profile;
  final playerRating = academy
      ? profile.ratingAcademy ?? Elo.startingRating
      : profile.ratingGeared ?? LadderSeeds.gearedPlayer(level: profile.level);
  final playerRatedGames = academy
      ? profile.ratedGamesAcademy
      : profile.ratedGamesGeared;
  final playerPeak = academy ? profile.peakAcademy : profile.peakGeared;

  final bot = _ladderBotBehind(driver);
  // ⭐ A bot is "treated as having played their 30" (LADDER §2) — always
  // K = 20 — and its peak for the 2400 rule is its seed, since a bot's own
  // rating is clamped near its seed by construction and never meaningfully
  // exceeds it. A human opponent's K/peak are never read (see the doc
  // comment above), so any value is fine here.
  final opponentRatedGames = bot != null ? 30 : 0;
  final opponentPeak = bot == null
      ? opponentRating
      : (academy ? bot.seedAcademy : bot.seedGeared);

  final outcome = rate(
    playerRating: playerRating,
    playerRatedGames: playerRatedGames,
    playerPeak: playerPeak > playerRating ? playerPeak : playerRating,
    opponentRating: opponentRating,
    opponentRatedGames: opponentRatedGames,
    opponentPeak: opponentPeak,
    won: won,
  );

  await game.applyRatedResult(
    academy: academy,
    newRating: outcome.newPlayerRating,
    won: won,
  );

  if (bot != null) {
    final seed = academy ? bot.seedAcademy : bot.seedGeared;
    final clamped = Elo.clampToSeed(
      opponentRating + outcome.opponentDelta,
      seed: seed,
    );
    await BotRatings.record(
      bot,
      academy: academy,
      delta: clamped - opponentRating,
      // The bot's own result is the mirror of the player's.
      won: !won,
    );
  }
}
