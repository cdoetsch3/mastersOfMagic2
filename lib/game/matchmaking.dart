import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_personas.dart';
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
/// (or fabricate) an opponent and hand back a driver — nothing more.
class Matchmaking {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static final Random _random = Random.secure();

  static const String _queue = 'matchmaking';
  static const String _duels = 'duels';

  /// Unambiguous room-code alphabet (no 0/O/1/I/L).
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String _newCode([int length = 6]) => List.generate(
      length, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();

  static int _newSeed() => _random.nextInt(1 << 31);

  // ---- Quick match ------------------------------------------------------

  /// Searches the queue for a waiting player. Joins them if found; otherwise
  /// posts a ticket and waits [patience] for someone to claim it. If nobody
  /// shows up, falls back to the AI persona nearest [level].
  static Future<MatchResult> quickMatch({
    required String uid,
    required String name,
    required int level,
    Duration patience = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Try to claim someone already waiting (oldest first).
      final waiting = await _db
          .collection(_queue)
          .orderBy('createdAt')
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 5));
      for (final ticket in waiting.docs) {
        if (ticket.data()['uid'] == uid) continue;
        final claimed = await _claimTicket(ticket.reference,
            claimerUid: uid, claimerName: name);
        if (claimed != null) return MatchResult.human(claimed);
      }

      // 2. Nobody to claim — post a ticket and wait to be claimed.
      final code = _newCode();
      final seed = _newSeed();
      final myTicket = _db.collection(_queue).doc(uid);
      await myTicket.set({
        'uid': uid,
        'name': name,
        'level': level,
        'roomId': code,
        'masterSeed': seed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final claimer = await _waitForClaim(myTicket, patience);
      if (claimer != null) {
        // The claimer created the room from our ticket; we are the host.
        await _db.collection(_duels).doc(code).set({
          'status': 'active',
          'hostUid': uid,
          'hostName': name,
          'guestUid': claimer.uid,
          'guestName': claimer.name,
          'masterSeed': seed,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return MatchResult.human(RemoteDuelDriver(
          roomId: code,
          isHost: true,
          masterSeed: seed,
          opponentName: claimer.name,
        ));
      }
      await myTicket.delete().catchError((_) {});
    } catch (_) {
      // Firestore unreachable (offline, rules, etc.) — AI will stand in.
    }

    // 3. No human found: an AI persona stands in.
    return MatchResult.ai(AiRoster.nearestToLevel(level));
  }

  /// Atomically claims [ticket]; returns a guest-side driver on success.
  static Future<RemoteDuelDriver?> _claimTicket(
    DocumentReference<Map<String, dynamic>> ticket, {
    required String claimerUid,
    required String claimerName,
  }) async {
    try {
      return await _db.runTransaction((tx) async {
        final snap = await tx.get(ticket);
        final data = snap.data();
        if (data == null || data['claimedBy'] != null) return null;
        tx.update(ticket, {
          'claimedBy': claimerUid,
          'claimedByName': claimerName,
        });
        return RemoteDuelDriver(
          roomId: data['roomId'] as String,
          isHost: false,
          masterSeed: (data['masterSeed'] as num).toInt(),
          opponentName: data['name'] as String? ?? 'Rival mage',
        );
      });
    } catch (_) {
      return null;
    }
  }

  static Future<({String uid, String name})?> _waitForClaim(
    DocumentReference<Map<String, dynamic>> ticket,
    Duration patience,
  ) async {
    final completer = Completer<({String uid, String name})?>();
    final timer = Timer(patience, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    final sub = ticket.snapshots().listen((snap) {
      final d = snap.data();
      if (d != null && d['claimedBy'] != null && !completer.isCompleted) {
        completer.complete((
          uid: d['claimedBy'] as String,
          name: d['claimedByName'] as String? ?? 'Rival mage',
        ));
      }
    }, onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    final result = await completer.future;
    timer.cancel();
    await sub.cancel();
    return result;
  }

  // ---- Friendly duels (room codes) --------------------------------------

  /// Creates a room and returns its code; the host then waits for a friend
  /// to join via [waitForGuest].
  static Future<({String code, int seed})> createRoom({
    required String uid,
    required String name,
  }) async {
    final code = _newCode();
    final seed = _newSeed();
    await _db.collection(_duels).doc(code).set({
      'status': 'waiting',
      'hostUid': uid,
      'hostName': name,
      'masterSeed': seed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return (code: code, seed: seed);
  }

  /// Host side: resolves with a driver when a guest joins (null on timeout).
  static Future<RemoteDuelDriver?> waitForGuest({
    required String code,
    required int seed,
    Duration patience = const Duration(minutes: 5),
  }) async {
    final room = _db.collection(_duels).doc(code);
    final completer = Completer<RemoteDuelDriver?>();
    final timer = Timer(patience, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    final sub = room.snapshots().listen((snap) {
      final d = snap.data();
      if (d != null && d['guestUid'] != null && !completer.isCompleted) {
        completer.complete(RemoteDuelDriver(
          roomId: code,
          isHost: true,
          masterSeed: seed,
          opponentName: d['guestName'] as String? ?? 'Rival mage',
        ));
      }
    }, onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    final result = await completer.future;
    timer.cancel();
    await sub.cancel();
    return result;
  }

  /// Guest side: join a friend's room by code. Throws with a friendly
  /// message if the code is bad or the room is taken.
  static Future<RemoteDuelDriver> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) async {
    final room = _db.collection(_duels).doc(code.toUpperCase().trim());
    return _db.runTransaction((tx) async {
      final snap = await tx.get(room);
      final d = snap.data();
      if (d == null) throw Exception('No duel found for that code.');
      if (d['hostUid'] == uid) throw Exception("That's your own room code.");
      if (d['guestUid'] != null) throw Exception('That duel already started.');
      tx.update(room, {
        'guestUid': uid,
        'guestName': name,
        'status': 'active',
      });
      return RemoteDuelDriver(
        roomId: room.id,
        isHost: false,
        masterSeed: (d['masterSeed'] as num).toInt(),
        opponentName: d['hostName'] as String? ?? 'Rival mage',
      );
    });
  }

  /// Cancels a waiting room / removes any queue ticket (best effort).
  static Future<void> cancel({required String uid, String? roomCode}) async {
    try {
      await _db.collection(_queue).doc(uid).delete();
    } catch (_) {}
    if (roomCode != null) {
      try {
        await _db.collection(_duels).doc(roomCode).delete();
      } catch (_) {}
    }
  }
}
