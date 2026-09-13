/// The bot pool's shared, mutable state (LADDER_DESIGN §4, §4.1):
/// `bots/{id}` holds exactly six fields per bot — a rating and a win/loss
/// count per ladder, plus `updatedAt` — and nothing else. Everything else
/// about a bot ([LadderBot]) is a definition in code.
library;

import '../firestore_rest.dart';
import 'ladder_bots.dart';

/// One bot's live standing on one ladder, read from `bots/{id}`.
class BotStanding {
  final int rating;
  final int wins;
  final int losses;
  const BotStanding({
    required this.rating,
    required this.wins,
    required this.losses,
  });
}

abstract final class BotRatings {
  const BotRatings._();

  static const String collection = 'bots';

  // ⭐ Field names — MUST match firestore.rules' `bots/{botId}` block
  // exactly, or a live write is rejected by the rules rather than by a test.
  static const String _ratingGeared = 'ratingGeared';
  static const String _ratingAcademy = 'ratingAcademy';
  static const String _winsGeared = 'winsGeared';
  static const String _lossesGeared = 'lossesGeared';
  static const String _winsAcademy = 'winsAcademy';
  static const String _lossesAcademy = 'lossesAcademy';
  static const String _updatedAt = 'updatedAt';

  /// Pure merge of the roster with whatever `bots/*` docs exist: a bot with
  /// no doc yet — or a doc missing this ladder's rating field — reads at its
  /// SEED with a 0–0 record, exactly what a bot that has never played looks
  /// like. [docs] is `{botId: fields}`, e.g. straight off [FirestoreRest.list].
  static Map<String, BotStanding> standingsFrom(
    Map<String, Map<String, dynamic>> docs, {
    required bool academy,
  }) {
    final ratingField = academy ? _ratingAcademy : _ratingGeared;
    final winsField = academy ? _winsAcademy : _winsGeared;
    final lossesField = academy ? _lossesAcademy : _lossesGeared;
    return {
      for (final bot in LadderRoster.all)
        bot.id: BotStanding(
          rating:
              (docs[bot.id]?[ratingField] as num?)?.toInt() ??
              (academy ? bot.seedAcademy : bot.seedGeared),
          wins: (docs[bot.id]?[winsField] as num?)?.toInt() ?? 0,
          losses: (docs[bot.id]?[lossesField] as num?)?.toInt() ?? 0,
        ),
    };
  }

  /// Reads every bot doc and returns the merged standings for one ladder.
  ///
  /// ⚠️ Deliberately does NOT swallow a failure — callers that only want a
  /// best-effort live read (LADDER §3's bot pick) catch it themselves and
  /// fall back to seeds; a caller that actually needs the live pool should
  /// see the error rather than silently getting seeds.
  static Future<Map<String, BotStanding>> fetch({required bool academy}) async {
    final docs = await FirestoreRest.list(collection);
    return standingsFrom(docs, academy: academy);
  }

  /// Seeds `bots/{bot.id}` if it does not exist yet, then applies one rated
  /// result: [delta] added to this ladder's rating, the win or loss counter
  /// bumped by one, `updatedAt` refreshed (LADDER §4.1's additive, lock-free
  /// write — two clients finishing against the same bot at once both land).
  ///
  /// ⭐ **[delta] arrives already clamped.** `Elo.clampToSeed` is the
  /// caller's job (`settleRatedDuel`) — this method only ever writes the
  /// number it is given.
  ///
  /// ⚠️ **Best-effort.** A rating write must never crash the end of a duel:
  /// a [FirestoreRestException] here is swallowed, not rethrown.
  static Future<void> record(
    LadderBot bot, {
    required bool academy,
    required int delta,
    required bool won,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await FirestoreRest.createIfAbsent(collection, bot.id, {
        _ratingGeared: bot.seedGeared,
        _ratingAcademy: bot.seedAcademy,
        _updatedAt: now,
      });
      final ratingField = academy ? _ratingAcademy : _ratingGeared;
      final recordField = won
          ? (academy ? _winsAcademy : _winsGeared)
          : (academy ? _lossesAcademy : _lossesGeared);
      await FirestoreRest.increment(
        '$collection/${bot.id}',
        {ratingField: delta, recordField: 1},
        set: {_updatedAt: now},
      );
    } on FirestoreRestException {
      // Best-effort — see the doc comment above.
    }
  }
}
