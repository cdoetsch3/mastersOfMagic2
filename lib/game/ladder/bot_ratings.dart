/// The bot pool's shared, mutable state (LADDER_DESIGN §4, §4.1):
/// `bots/{id}` holds exactly six fields per bot — a rating and a win/loss
/// count per ladder, plus `updatedAt` — and nothing else. Everything else
/// about a bot ([LadderBot]) is a definition in code.
library;

import 'package:mom_engine/mom_engine.dart';

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
  ///
  /// ⭐ **Every live rating goes through [saneRating]** (2026-09-25): a doc is
  /// shared, client-written state, and Hesper and Rook were found sitting at
  /// 8. The read never trusts a stored number verbatim — see there.
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
          rating: saneRating(
            docs[bot.id]?[ratingField],
            seed: academy ? bot.seedAcademy : bot.seedGeared,
          ),
          wins: (docs[bot.id]?[winsField] as num?)?.toInt() ?? 0,
          losses: (docs[bot.id]?[lossesField] as num?)?.toInt() ?? 0,
        ),
    };
  }

  /// The rating a bot is HELD at, given whatever its doc stores for this
  /// ladder and its [seed] (LADDER §2's ±300 anti-farm band, applied on read).
  ///
  /// - Missing, not a number, ≤ 0 or > 3000 → the [seed]. Those values are
  ///   not a rating that drifted, they are a write that never happened or
  ///   went wrong; the honest reading is "has not played".
  /// - Anything else → `Elo.clampToSeed(stored, seed: seed)`.
  ///
  /// ⚠️ **Why clamp on read when the write already clamps:** the write-side
  /// clamp only ever sees a doc that started sane. A doc born at 8 (an
  /// increment that landed before any seed — see [record]) is outside the
  /// band forever, every later write from it is refused by the rules'
  /// |Δ| ≤ 40, and the search kept showing an 8-rated opponent that a win
  /// against was worth ±0. A corrupt doc must read as a plausible bot the
  /// moment it is fetched, not after a repair lands.
  static int saneRating(Object? stored, {required int seed}) {
    if (stored is! num) return seed;
    final value = stored.toInt();
    if (value <= 0 || value > _absurdAbove) return seed;
    return Elo.clampToSeed(value, seed: seed);
  }

  /// Past this a stored rating is noise, not a drifted value — no seed is
  /// within 1000 of it (the ceiling the create rule used to allow).
  static const int _absurdAbove = 3000;

  /// Whether a stored rating is CORRUPT — absent, not a number, or outside
  /// the ±300 seed band that no legitimate sequence of clamped writes can
  /// leave. ⭐ Exactly the condition firestore.rules' `outOfBand` uses to
  /// permit a repair write, so the client never attempts a repair the server
  /// will refuse, nor skips one it would allow.
  static bool isCorrupt(Object? stored, {required int seed}) {
    if (stored is! num) return true;
    final value = stored.toInt();
    return Elo.clampToSeed(value, seed: seed) != value;
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

  /// Seeds `bots/{bot.id}` if it does not exist yet, repairs it if it exists
  /// but is corrupt, then applies one rated result: [delta] added to this
  /// ladder's rating, the win or loss counter bumped by one, `updatedAt`
  /// refreshed (LADDER §4.1's additive, lock-free write — two clients
  /// finishing against the same bot at once both land).
  ///
  /// ⭐ **[delta] arrives already clamped.** `Elo.clampToSeed` is the
  /// caller's job (`settleRatedDuel`) — this method only ever writes the
  /// number it is given.
  ///
  /// ⭐ **The increment is never a doc's first write** (2026-09-25). A
  /// Firestore field transform on a missing document CREATES it, with the
  /// transformed field set to the delta itself — which is how Hesper and
  /// Rook were born at 8. So:
  /// 1. [FirestoreRest.createIfAbsent] with both seeds. It throws on anything
  ///    but "created" or "already exists" — and a throw aborts the record.
  /// 2. If it already existed, READ it. Gone (404) → abort. This ladder's
  ///    rating [isCorrupt] → `set` that one field to the seed first (the
  ///    repair write firestore.rules allows only for an out-of-band value,
  ///    and only to exactly the seed).
  /// 3. Only then the increment.
  ///
  /// ⚠️ **Best-effort.** A rating write must never crash the end of a duel:
  /// any exception here (a rules refusal, a dropped connection) is
  /// swallowed, not rethrown — and it is swallowed BEFORE the increment
  /// whenever the doc's existence is in doubt. Skipping one bot's result is
  /// harmless; creating a bot at `rating = delta` is not.
  static Future<void> record(
    LadderBot bot, {
    required bool academy,
    required int delta,
    required bool won,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final ratingField = academy ? _ratingAcademy : _ratingGeared;
    final seed = academy ? bot.seedAcademy : bot.seedGeared;
    final path = '$collection/${bot.id}';
    try {
      final created = await FirestoreRest.createIfAbsent(collection, bot.id, {
        _ratingGeared: bot.seedGeared,
        _ratingAcademy: bot.seedAcademy,
        _updatedAt: now,
      });
      if (!created) {
        final existing = await FirestoreRest.get(path);
        // ⚠️ "Exists" a moment ago and missing now: never let the increment
        // be the write that brings it back.
        if (existing == null) return;
        if (isCorrupt(existing[ratingField], seed: seed)) {
          await FirestoreRest.set(
            path,
            {ratingField: seed},
            updateOnly: [ratingField],
          );
        }
      }
      final recordField = won
          ? (academy ? _winsAcademy : _winsGeared)
          : (academy ? _lossesAcademy : _lossesGeared);
      await FirestoreRest.increment(
        path,
        {ratingField: delta, recordField: 1},
        set: {_updatedAt: now},
      );
    } on Exception {
      // Best-effort — see the doc comment above.
    }
  }
}
