import 'dart:math';

import 'ai_personas.dart';
import 'firestore_rest.dart';
import 'items/item_def.dart';
import 'opponent_driver.dart';

/// The result of any matchmaking path: either a remote driver (human found)
/// or an AI persona to stand in. The duel itself treats both identically.
class MatchResult {
  final RemoteDuelDriver? remote;
  final AiPersona? persona;

  const MatchResult.human(RemoteDuelDriver this.remote) : persona = null;
  const MatchResult.ai(AiPersona this.persona) : remote = null;

  bool get isHuman => remote != null;
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
      );

  /// Searches the queue for a waiting player. Joins them if found; otherwise
  /// posts a ticket and waits [patience] to be claimed — ⭐ **while also
  /// re-scanning the queue**, because two players who press the button at
  /// the same moment both see it empty, both post, and would otherwise both
  /// sit out the timeout and get an AI (the exact reported bug). If nobody
  /// shows up, falls back to the AI persona nearest [level].
  static Future<MatchResult> quickMatch({
    required String uid,
    required String name,
    required int level,
    // ⭐ Travels beside [level] at every step below — ticket, claim, room doc
    // — because both are inputs to the mage the OTHER client has to build.
    // ⚠️ Required, like [level]: a caller that forgets it would put a naked
    // mage on the opponent's screen and a geared one on ours.
    required ItemModifiers gear,
    Duration patience = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Claim someone already waiting (oldest first).
      final waiting = await FirestoreRest.query(
        _queue,
        orderBy: 'createdAt',
        limit: 5,
      );
      for (final ticket in waiting) {
        if (ticket.id == uid) continue;
        if (ticket.data['claimedBy'] != null) continue;
        if (await _claim(
          ticket,
          uid: uid,
          name: name,
          level: level,
          gear: gear,
        )) {
          return MatchResult.human(_joinTicket(ticket.data));
        }
      }

      // 2. Post a ticket, then alternate between "was I claimed?" and
      // "did someone else post before me?" until the patience runs out.
      final code = _newCode();
      final seed = _newSeed();
      final createdAt = _now();
      await FirestoreRest.set('$_queue/$uid', {
        'uid': uid,
        'name': name,
        'level': level,
        // ⭐ Whoever claims this ticket builds their enemy from these two
        // fields alone, so both must be here before anyone can claim it.
        'gear': gear.toJson(),
        'roomId': code,
        'masterSeed': seed,
        'createdAt': createdAt,
      });
      final deadline = DateTime.now().add(patience);
      while (DateTime.now().isBefore(deadline)) {
        // a. Someone claimed my ticket — I host.
        final mine = await FirestoreRest.get('$_queue/$uid');
        final by = mine?['claimedBy'];
        if (by is String) {
          await FirestoreRest.set('$_duels/$code', {
            'status': 'active',
            'hostUid': uid,
            'hostName': name,
            'hostLevel': level,
            'hostGear': gear.toJson(),
            'guestUid': by,
            'guestName': mine?['claimedByName'] as String? ?? 'Rival',
            'guestLevel': (mine?['claimedByLevel'] as num?)?.toInt() ?? 1,
            'guestGear': _gearFrom(mine?['claimedByGear']).toJson(),
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
            ),
          );
        }

        // b. A ticket that precedes mine — I claim it and I am the guest.
        // ⚠️ Strict precedence only (ticketPrecedes), or two simultaneous
        // searchers would claim each other and open two half-empty rooms.
        final others = await FirestoreRest.query(
          _queue,
          orderBy: 'createdAt',
          limit: 5,
        );
        for (final ticket in others) {
          if (ticket.id == uid) continue;
          if (ticket.data['claimedBy'] != null) continue;
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
          )) {
            await FirestoreRest.delete('$_queue/$uid');
            return MatchResult.human(_joinTicket(ticket.data));
          }
        }

        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
      await FirestoreRest.delete('$_queue/$uid');
    } catch (_) {
      // Fall through to the AI stand-in below.
    }

    // 3. No human found: an AI persona stands in.
    return MatchResult.ai(AiRoster.nearestToLevel(level));
  }

  // ---- Friendly duels (room codes) --------------------------------------

  static Future<({String code, int seed})> createRoom({
    required String uid,
    required String name,
    required int level,
    required ItemModifiers gear,
  }) async {
    final code = _newCode();
    final seed = _newSeed();
    await FirestoreRest.set('$_duels/$code', {
      'status': 'waiting',
      'hostUid': uid,
      'hostName': name,
      // ⭐ Levels AND gear cross the wire in BOTH directions, or the two
      // clients simulate two different duels (the level desync of 2026-08-09,
      // then the gear desync it turned out to share a shape with).
      'hostLevel': level,
      'hostGear': gear.toJson(),
      'masterSeed': seed,
      'createdAt': _now(),
    });
    return (code: code, seed: seed);
  }

  /// Host side: resolves with a driver when a guest joins (null on timeout).
  static Future<RemoteDuelDriver?> waitForGuest({
    required String code,
    required int seed,
    Duration patience = const Duration(minutes: 5),
  }) async {
    final guest = await _poll<({String name, int level, ItemModifiers gear})>(
      '$_duels/$code',
      (d) => d?['guestUid'] != null
          ? (
              name: d?['guestName'] as String? ?? 'Rival mage',
              level: (d?['guestLevel'] as num?)?.toInt() ?? 1,
              gear: _gearFrom(d?['guestGear']),
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
    );
  }

  /// Guest side: join a friend's room by code.
  static Future<RemoteDuelDriver> joinRoom({
    required String code,
    required String uid,
    required String name,
    required int level,
    required ItemModifiers gear,
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
      'status': 'active',
    });
    return RemoteDuelDriver(
      roomId: roomCode,
      isHost: false,
      masterSeed: (data['masterSeed'] as num).toInt(),
      opponentName: data['hostName'] as String? ?? 'Rival mage',
      opponentLevel: (data['hostLevel'] as num?)?.toInt() ?? 1,
      opponentGear: _gearFrom(data['hostGear']),
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
