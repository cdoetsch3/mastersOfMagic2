/// Applying one finished rated duel (LADDER_DESIGN §2): the pure Elo math,
/// then the I/O that banks it — the player's profile always, and a bot's
/// `bots/{id}` doc when the opponent was one.
library;

import 'package:mom_engine/mom_engine.dart';

import '../game_state.dart';
import '../opponent_driver.dart';
import '../player_profile.dart';
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

/// What the duel screen is told about the ladder once a finished duel has
/// been banked (Christian, 2026-09-21): enough to print the Ranking row on
/// the result card and nothing more.
///
/// ⭐ **Three states, not two.** `rated: false` is a duel that finished and
/// deliberately moved no rating (a room code, a practice persona) — the card
/// says "unrated". A *null* settlement is the different claim that there is
/// nothing to report at all (a fled duel, or a screen built with no
/// settler), and the card keeps its own counsel. Collapsing the two would
/// make a room-code duel look like a bug.
class DuelSettlement {
  /// Whether this duel moved a ladder rating at all.
  final bool rated;

  /// The points won or lost, signed. Null exactly when [rated] is false.
  final int? ratingDelta;

  /// The rating the player now holds on that ladder. Null exactly when
  /// [rated] is false.
  final int? newRating;

  const DuelSettlement({required this.rated, this.ratingDelta, this.newRating});

  /// A duel that finished and rated nothing.
  static const unrated = DuelSettlement(rated: false);

  /// The rated case, read straight off the Elo exchange that was banked — so
  /// the card can only ever show the number the profile actually took.
  DuelSettlement.of(RatedOutcome outcome)
    : rated = true,
      ratingDelta = outcome.playerDelta,
      newRating = outcome.newPlayerRating;
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

/// The rating [profile] plays at on [academy]'s ladder (LADDER_DESIGN §2):
/// the banked one, or — before a first rated match on that ladder — the seed
/// it WILL be rated from (Academy: [Elo.startingRating]; Geared: the level
/// seed, [LadderSeeds.gearedPlayer]).
///
/// ⭐ **The one resolution.** [settleRatedDuel] rates from it and the duel
/// header prints it (2026-09-25), so the number beside the player's name is
/// always the number the result is measured from — a first-timer's header
/// reads their seed, not a blank.
int playerRatingOn(PlayerProfile profile, {required bool academy}) => academy
    ? profile.ratingAcademy ?? Elo.startingRating
    : profile.ratingGeared ?? LadderSeeds.gearedPlayer(level: profile.level);

/// Whether a duel against [driver] moves a rating at all (LADDER §2, §3): a
/// ladder bot, or a `quickMatch` human ([RemoteDuelDriver.rated]). A
/// room-code duel, a practice persona and every campaign foe are unrated.
///
/// ⭐ The same test `launchDuel` applies before settling — the duel header
/// uses it to decide whether ratings belong on the nameplates at all.
bool isRatedDuel(OpponentDriver driver) => driver is RemoteDuelDriver
    ? driver.rated
    : _ladderBotBehind(driver) != null;

/// Finds the [LadderBot] a [LocalAiDriver] is standing in for, or null when
/// [driver] isn't one. ⭐ Keyed on [LocalAiDriver.ladderBot], never on the
/// persona id alone — a practice bout against Wick shares his id with the
/// ladder's Wick and must never move a rating.
LadderBot? _ladderBotBehind(OpponentDriver driver) {
  if (driver is! LocalAiDriver || !driver.ladderBot) return null;
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
///
/// ⭐ **Returns the very [RatedOutcome] it banked**, so the result card can
/// print the change (Christian, 2026-09-21) without recomputing the Elo and
/// risking a number that disagrees with the profile. Null is the unrated
/// no-op above — nothing happened, so there is nothing to report.
Future<RatedOutcome?> settleRatedDuel(
  GameState game, {
  required OpponentDriver driver,
  required bool academy,
  required bool won,
  required int opponentRating,
}) async {
  if (driver is RemoteDuelDriver && !driver.rated) return null;

  final profile = game.profile;
  final playerRating = playerRatingOn(profile, academy: academy);
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

  // ⭐ The decided-game floor (2026-09-25) already lives in [Elo.delta], so
  // the PLAYER always moves by at least 1 — and the bot's raw delta is
  // floored the same way. The clamp below may still cut the bot's write to 0
  // (a bot pinned at its band edge); that is the clamp doing its job, and
  // the only place a decided game is allowed to move a rating by nothing.
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

  return outcome;
}
