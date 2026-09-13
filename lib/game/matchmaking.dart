import 'dart:math';

import 'package:mom_engine/mom_engine.dart';

import 'academy.dart';
import 'ai_personas.dart';
import 'firestore_rest.dart';
import 'items/item_def.dart';
import 'ladder/bot_ratings.dart';
import 'ladder/ladder_bots.dart';
import 'ladder/ladder_search.dart';
import 'opponent_driver.dart';

/// The result of any matchmaking path: either a remote driver (human found)
/// or a ladder bot to stand in. The duel itself treats both identically.
class MatchResult {
  final RemoteDuelDriver? remote;
  final LadderBot? bot;

  /// ⭐ The rating the search held [bot] at — live when `bots/*` answered,
  /// else its seed (LADDER §4.1: "the rating it read at match start"). The
  /// duel header shows it and the settlement measures against it. 0 for a
  /// human, whose rating rides on the driver instead.
  final int botRating;

  const MatchResult.human(RemoteDuelDriver this.remote)
    : bot = null,
      botRating = 0;
  const MatchResult.ai(LadderBot this.bot, {required this.botRating})
    : remote = null;

  bool get isHuman => remote != null;

  /// ⭐ Convenience for callers that only want the practice-roster shape —
  /// `LocalAiDriver`/`launchAiDuel`'s [AiPersona] path — without caring that
  /// a LADDER bot is a body (level/kit/gear) with a persona bolted on.
  AiPersona? get persona => bot?.toPersona();
}

/// Matchmaking is deliberately separate from dueling: these functions find
/// (or fabricate) an opponent and hand back a driver — nothing more. All
/// Firestore access goes through [FirestoreRest] (the SDK is broken on web).
class Matchmaking {
  static final Random _random = Random.secure();

  static const String _queue = 'matchmaking';
  static const String _duels = 'duels';

  /// Unambiguous room-code alphabet (no 0/O/1/I/L).
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String _newCode([int length = 6]) => List.generate(
    length,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();

  static int _newSeed() => _random.nextInt(0x40000000);

  // ISO-8601 UTC sorts chronologically as a string.
  static String _now() => DateTime.now().toUtc().toIso8601String();

  /// Polls [test] on [path] every [interval] until it returns non-null or
  /// [timeout] elapses.
  static Future<T?> _poll<T>(
    String path,
    T? Function(Map<String, dynamic>? data) test, {
    required Duration timeout,
    Duration interval = const Duration(milliseconds: 900),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final data = await FirestoreRest.get(path);
        final result = test(data);
        if (result != null) return result;
      } catch (_) {}
      await Future<void>.delayed(interval);
    }
    return null;
  }

  // ---- Quick match ------------------------------------------------------

  /// Whether [their] ticket strictly precedes [mine] in claim order.
  ///
  /// ⭐ **The rendezvous rule**: while waiting to be claimed, each searcher
  /// re-scans the queue and may claim only tickets that precede their own —
  /// by createdAt (ISO strings sort chronologically), uid as the tiebreak.
  /// Strict precedence means two simultaneous searchers can never claim each
  /// other: exactly one of them precedes, and only the OTHER may act.
  /// Public and pure for the test.
  static bool ticketPrecedes({
    required String theirUid,
    required String theirCreatedAt,
    required String myUid,
    required String myCreatedAt,
  }) {
    final byTime = theirCreatedAt.compareTo(myCreatedAt);
    if (byTime != 0) return byTime < 0;
    return theirUid.compareTo(myUid) < 0;
  }

  /// Whether a queue ticket belongs to [mode]'s queue.
  ///
  /// ⭐ One collection, two queues: the Academy (academy.dart) and geared
  /// PvP share `matchmaking/` but never match each other — a ticket is only
  /// claimable by a searcher in the same mode. ⚠️ A ticket with NO mode is
  /// geared: it was written by a client from before the Academy existed, and
  /// that client is fighting geared whatever we call it. Public and pure for
  /// the test.
  static bool ticketInMode(Map<String, dynamic> ticket, String mode) =>
      (ticket['mode'] as String? ?? Academy.gearedMode) == mode;

  /// Tries to claim [ticket] for [uid]. True only if OUR claim stuck.
  ///
  /// ⚠️ Firestore REST has no transactions here, so the claim is
  /// write-then-verify: last write wins the doc, and the read-back tells the
  /// loser to walk away instead of both joining the same room.
  static Future<bool> _claim(
    ({String id, Map<String, dynamic> data}) ticket, {
    required String uid,
    required String name,
    required int level,
    required ItemModifiers gear,
    required int rating,
  }) async {
    try {
      await FirestoreRest.set('$_queue/${ticket.id}', {
        'claimedBy': uid,
        'claimedByName': name,
        // ⭐ The claimer's level rides the claim, so the ticket owner can
        // build the SAME two-level duel we do (the desync fix).
        'claimedByLevel': level,
        // ⭐ …and their gear, for the same reason: PvP counts equipment
        // (ITEMS §7.4), so the ticket owner needs our totals to build the
        // same two mages. Trusted as claimed — server validation is later.
        'claimedByGear': gear.toJson(),
        // ⭐ …and OUR rating (LADDER §2), so the ticket owner's client can
        // resolve OUR rating for the rated write at duel end without a
        // second round trip.
        'claimedByRating': rating,
      });
      final check = await FirestoreRest.get('$_queue/${ticket.id}');
      return check?['claimedBy'] == uid;
    } catch (_) {
      return false;
    }
  }

  /// Reads a gear map written by [ItemModifiers.toJson] back out of a doc.
  ///
  /// ⚠️ Anything that is not a map — a missing field, a room doc written by a
  /// client from before gear crossed the wire — reads as **unequipped**. A
  /// throw here would take down matchmaking itself, and "no gear" is both the
  /// old behaviour and the safe direction.
  static ItemModifiers _gearFrom(Object? field) => ItemModifiers.fromJson(
    field is Map ? field.map((k, v) => MapEntry('$k', v)) : null,
  );

  static RemoteDuelDriver _joinTicket(Map<String, dynamic> ticket) =>
      RemoteDuelDriver(
        roomId: ticket['roomId'] as String,
        isHost: false,
        masterSeed: (ticket['masterSeed'] as num).toInt(),
        opponentName: ticket['name'] as String? ?? 'Rival mage',
        opponentLevel: (ticket['level'] as num?)?.toInt() ?? 1,
        opponentGear: _gearFrom(ticket['gear']),
        // ⚠️ A ticket from a client older than LADDER has no `rating` — read
        // that as the Elo starting rating, never as an unset/zero rating.
        opponentRating:
            (ticket['rating'] as num?)?.toInt() ?? Elo.startingRating,
        academy: ticketInMode(ticket, Academy.mode),
        // ⭐ Every path through quickMatch's human branch is rated (LADDER
        // §3) — a ticket only ever exists inside quickMatch.
        rated: true,
      );

  /// Searches the queue for a waiting player within the current widening
  /// band (LADDER_DESIGN §3), joining them if found; otherwise posts a
  /// ticket and keeps searching — ⭐ **while also re-scanning the queue**,
  /// because two players who press the button at the same moment both see
  /// it empty, both post, and would otherwise both sit out the timeout and
  /// get a bot (the original reported bug). At [patience] (jittered ±1.5 s
  /// so a bot's exact timing is never a tell — LADDER §3's no-leak rule), a
  /// ladder bot weighted toward [rating] stands in.
  static Future<MatchResult> quickMatch({
    required String uid,
    required String name,
    required int level,
    // ⭐ Travels beside [level] at every step below — ticket, claim, room doc
    // — because both are inputs to the mage the OTHER client has to build.
    // ⚠️ Required, like [level]: a caller that forgets it would put a naked
    // mage on the opponent's screen and a geared one on ours.
    required ItemModifiers gear,
    // ⭐ The player's rating on THIS queue's ladder (LADDER §2) — the screen
    // resolves it (profile rating, or the seed on a first rated match) and
    // hands it in, so this file never has to know the seed formulas' inputs
    // beyond the rating itself.
    required int rating,
    // The queue to search and post in (academy.dart) — geared by default.
    String mode = Academy.gearedMode,
    Duration patience = const Duration(seconds: 10),
    // ⭐ The bot this player last fought (LADDER §3) — excluded from the
    // phase-4 pick so two matches in a row don't repeat the same face.
    String? excludeBotId,
    Random? random,
    DateTime Function()? now,
  }) async {
    final rng = random ?? _random;
    final clock = now ?? DateTime.now;
    final academy = mode == Academy.mode;
    final searchStart = clock();
    // ⭐ LADDER §3's no-leak rule (c): the bot's own "found" moment is
    // jittered ±1.5 s around [patience] so it never reads as a metronome.
    final botDeadline = searchStart
        .add(patience)
        .add(Duration(milliseconds: (rng.nextDouble() * 3000).round() - 1500));

    bool inBand(Map<String, dynamic> ticket, int band) {
      final theirRating =
          (ticket['rating'] as num?)?.toInt() ?? Elo.startingRating;
      return (theirRating - rating).abs() <= band;
    }

    try {
      // 1. Claim someone already waiting (oldest first) — in OUR queue and
      // within OUR current band.
      var band = LadderSearch.bandAt(clock().difference(searchStart));
      final waiting = await FirestoreRest.query(
        _queue,
        orderBy: 'createdAt',
        limit: 5,
      );
      for (final ticket in waiting) {
        if (ticket.id == uid) continue;
        if (ticket.data['claimedBy'] != null) continue;
        if (!ticketInMode(ticket.data, mode)) continue;
        if (!inBand(ticket.data, band)) continue;
        if (await _claim(
          ticket,
          uid: uid,
          name: name,
          level: level,
          gear: gear,
          rating: rating,
        )) {
          return MatchResult.human(_joinTicket(ticket.data));
        }
      }

      // 2. Post a ticket, then alternate between "was I claimed?" and
      // "did someone else post before me?" until the bot phase begins.
      final code = _newCode();
      final seed = _newSeed();
      final createdAt = _now();
      await FirestoreRest.set('$_queue/$uid', {
        'uid': uid,
        'name': name,
        'level': level,
        // ⭐ Whoever claims this ticket builds their enemy from these three
        // fields alone, so all must be here before anyone can claim it.
        'gear': gear.toJson(),
        'rating': rating,
        'mode': mode,
        'roomId': code,
        'masterSeed': seed,
        'createdAt': createdAt,
      });
      while (clock().isBefore(botDeadline)) {
        // a. Someone claimed my ticket — I host.
        final mine = await FirestoreRest.get('$_queue/$uid');
        final by = mine?['claimedBy'];
        if (by is String) {
          final guestRating =
              (mine?['claimedByRating'] as num?)?.toInt() ?? Elo.startingRating;
          await FirestoreRest.set('$_duels/$code', {
            'status': 'active',
            'hostUid': uid,
            'hostName': name,
            'hostLevel': level,
            'hostGear': gear.toJson(),
            'hostRating': rating,
            'guestUid': by,
            'guestName': mine?['claimedByName'] as String? ?? 'Rival',
            'guestLevel': (mine?['claimedByLevel'] as num?)?.toInt() ?? 1,
            'guestGear': _gearFrom(mine?['claimedByGear']).toJson(),
            'guestRating': guestRating,
            'mode': mode,
            'masterSeed': seed,
            'createdAt': _now(),
          });
          await FirestoreRest.delete('$_queue/$uid');
          return MatchResult.human(
            RemoteDuelDriver(
              roomId: code,
              isHost: true,
              masterSeed: seed,
              opponentName: mine?['claimedByName'] as String? ?? 'Rival',
              opponentLevel: (mine?['claimedByLevel'] as num?)?.toInt() ?? 1,
              // ⚠️ The claimer's OWN totals, read straight back off the claim
              // — never ours. Each side wears its own wardrobe and simulates
              // the other's.
              opponentGear: _gearFrom(mine?['claimedByGear']),
              opponentRating: guestRating,
              academy: academy,
              rated: true,
            ),
          );
        }

        // b. A ticket that precedes mine, in band — I claim it and I am
        // the guest. ⚠️ Strict precedence only (ticketPrecedes), or two
        // simultaneous searchers would claim each other and open two
        // half-empty rooms.
        band = LadderSearch.bandAt(clock().difference(searchStart));
        final others = await FirestoreRest.query(
          _queue,
          orderBy: 'createdAt',
          limit: 5,
        );
        for (final ticket in others) {
          if (ticket.id == uid) continue;
          if (ticket.data['claimedBy'] != null) continue;
          if (!ticketInMode(ticket.data, mode)) continue;
          if (!inBand(ticket.data, band)) continue;
          if (!ticketPrecedes(
            theirUid: ticket.id,
            theirCreatedAt: ticket.data['createdAt'] as String? ?? '',
            myUid: uid,
            myCreatedAt: createdAt,
          )) {
            continue;
          }
          if (await _claim(
            ticket,
            uid: uid,
            name: name,
            level: level,
            gear: gear,
            rating: rating,
          )) {
            await FirestoreRest.delete('$_queue/$uid');
            return MatchResult.human(_joinTicket(ticket.data));
          }
        }

        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
      await FirestoreRest.delete('$_queue/$uid');
    } catch (_) {
      // Fall through to the bot stand-in below.
    }

    // 3. No human found: a ladder bot stands in, weighted toward [rating]
    // (LADDER §3 phase 4). ⭐ The pick uses each bot's LIVE rating when the
    // read succeeds, falling back to seeds when it throws — a live read is
    // strictly better, never required.
    var liveRatings = const <String, int>{};
    try {
      final standings = await BotRatings.fetch(academy: academy);
      liveRatings = {
        for (final entry in standings.entries) entry.key: entry.value.rating,
      };
    } catch (_) {
      // Seeds only — see the doc comment above.
    }
    final bot = LadderSearch.pickBot(
      rating,
      academy: academy,
      excludeBotId: excludeBotId,
      rng: rng,
      liveRatings: liveRatings,
    );
    return MatchResult.ai(
      bot,
      botRating: LadderSearch.ratingOf(
        bot,
        liveRatings: liveRatings,
        academy: academy,
      ),
    );
  }

  // ---- Friendly duels (room codes) --------------------------------------

  static Future<({String code, int seed})> createRoom({
    required String uid,
    required String name,
    required int level,
    required ItemModifiers gear,
    // ⭐ Rooms are UNRATED (LADDER §3) — this never feeds Elo — but the
    // lobby card still shows a rating for both sides, so it rides along
    // exactly like level and gear do.
    required int rating,
    String mode = Academy.gearedMode,
  }) async {
    final code = _newCode();
    final seed = _newSeed();
    await FirestoreRest.set('$_duels/$code', {
      'status': 'waiting',
      // ⭐ The HOST picks the mode; a guest joining by code adopts it.
      'mode': mode,
      'hostUid': uid,
      'hostName': name,
      // ⭐ Levels AND gear cross the wire in BOTH directions, or the two
      // clients simulate two different duels (the level desync of 2026-08-09,
      // then the gear desync it turned out to share a shape with).
      'hostLevel': level,
      'hostGear': gear.toJson(),
      'hostRating': rating,
      'masterSeed': seed,
      'createdAt': _now(),
    });
    return (code: code, seed: seed);
  }

  /// Host side: resolves with a driver when a guest joins (null on timeout).
  static Future<RemoteDuelDriver?> waitForGuest({
    required String code,
    required int seed,
    String mode = Academy.gearedMode,
    Duration patience = const Duration(minutes: 5),
  }) async {
    final guest =
        await _poll<({String name, int level, ItemModifiers gear, int rating})>(
          '$_duels/$code',
          (d) => d?['guestUid'] != null
              ? (
                  name: d?['guestName'] as String? ?? 'Rival mage',
                  level: (d?['guestLevel'] as num?)?.toInt() ?? 1,
                  gear: _gearFrom(d?['guestGear']),
                  rating:
                      (d?['guestRating'] as num?)?.toInt() ??
                      Elo.startingRating,
                )
              : null,
          timeout: patience,
        );
    if (guest == null) return null;
    return RemoteDuelDriver(
      roomId: code,
      isHost: true,
      masterSeed: seed,
      opponentName: guest.name,
      opponentLevel: guest.level,
      opponentGear: guest.gear,
      opponentRating: guest.rating,
      academy: mode == Academy.mode,
      // ⭐ Room codes are unrated (LADDER §3) — the default `rated: false`.
    );
  }

  /// Guest side: join a friend's room by code.
  static Future<RemoteDuelDriver> joinRoom({
    required String code,
    required String uid,
    required String name,
    required int level,
    required ItemModifiers gear,
    required int rating,
  }) async {
    final roomCode = code.toUpperCase().trim();
    final data = await FirestoreRest.get('$_duels/$roomCode');
    if (data == null) throw Exception('No duel found for that code.');
    if (data['hostUid'] == uid) throw Exception("That's your own room code.");
    if (data['guestUid'] != null) throw Exception('That duel already started.');
    await FirestoreRest.set('$_duels/$roomCode', {
      'guestUid': uid,
      'guestName': name,
      'guestLevel': level,
      // ⭐ Written before the driver is built, so the host's waitForGuest poll
      // never sees a guest without their wardrobe.
      'guestGear': gear.toJson(),
      'guestRating': rating,
      'status': 'active',
    });
    return RemoteDuelDriver(
      roomId: roomCode,
      isHost: false,
      masterSeed: (data['masterSeed'] as num).toInt(),
      opponentName: data['hostName'] as String? ?? 'Rival mage',
      opponentLevel: (data['hostLevel'] as num?)?.toInt() ?? 1,
      opponentGear: _gearFrom(data['hostGear']),
      opponentRating:
          (data['hostRating'] as num?)?.toInt() ?? Elo.startingRating,
      // The room's mode, not ours: whoever joins by code fights the host's
      // duel. The screen re-resolves its loadout off this flag.
      academy: ticketInMode(data, Academy.mode),
      // ⭐ Room codes are unrated (LADDER §3) — the default `rated: false`.
    );
  }

  /// Cancels a waiting room / removes any queue ticket (best effort).
  static Future<void> cancel({required String uid, String? roomCode}) async {
    try {
      await FirestoreRest.delete('$_queue/$uid');
    } catch (_) {}
    if (roomCode != null) {
      try {
        await FirestoreRest.delete('$_duels/$roomCode');
      } catch (_) {}
    }
  }
}
