import 'dart:math';

import 'ai_personas.dart';
import 'firestore_rest.dart';
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
      length, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();

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

  /// Searches the queue for a waiting player. Joins them if found; otherwise
  /// posts a ticket and waits [patience] to be claimed. If nobody shows up,
  /// falls back to the AI persona nearest [level].
  static Future<MatchResult> quickMatch({
    required String uid,
    required String name,
    required int level,
    Duration patience = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Claim someone already waiting (oldest first).
      final waiting =
          await FirestoreRest.query(_queue, orderBy: 'createdAt', limit: 5);
      for (final ticket in waiting) {
        if (ticket.id == uid) continue;
        if (ticket.data['claimedBy'] != null) continue;
        final ok = await FirestoreRest.set(
          '$_queue/${ticket.id}',
          {'claimedBy': uid, 'claimedByName': name},
        ).then((_) => true).catchError((_) => false);
        if (ok) {
          return MatchResult.human(RemoteDuelDriver(
            roomId: ticket.data['roomId'] as String,
            isHost: false,
            masterSeed: (ticket.data['masterSeed'] as num).toInt(),
            opponentName: ticket.data['name'] as String? ?? 'Rival mage',
          ));
        }
      }

      // 2. Post a ticket and wait to be claimed.
      final code = _newCode();
      final seed = _newSeed();
      await FirestoreRest.set('$_queue/$uid', {
        'uid': uid,
        'name': name,
        'level': level,
        'roomId': code,
        'masterSeed': seed,
        'createdAt': _now(),
      });
      final claimer = await _poll<({String uid, String name})>(
        '$_queue/$uid',
        (d) {
          final by = d?['claimedBy'];
          if (by is String) {
            return (uid: by, name: d?['claimedByName'] as String? ?? 'Rival');
          }
          return null;
        },
        timeout: patience,
      );
      if (claimer != null) {
        await FirestoreRest.set('$_duels/$code', {
          'status': 'active',
          'hostUid': uid,
          'hostName': name,
          'guestUid': claimer.uid,
          'guestName': claimer.name,
          'masterSeed': seed,
          'createdAt': _now(),
        });
        await FirestoreRest.delete('$_queue/$uid');
        return MatchResult.human(RemoteDuelDriver(
          roomId: code,
          isHost: true,
          masterSeed: seed,
          opponentName: claimer.name,
        ));
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
  }) async {
    final code = _newCode();
    final seed = _newSeed();
    await FirestoreRest.set('$_duels/$code', {
      'status': 'waiting',
      'hostUid': uid,
      'hostName': name,
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
    final name = await _poll<String>(
      '$_duels/$code',
      (d) => d?['guestUid'] != null
          ? (d?['guestName'] as String? ?? 'Rival mage')
          : null,
      timeout: patience,
    );
    if (name == null) return null;
    return RemoteDuelDriver(
      roomId: code,
      isHost: true,
      masterSeed: seed,
      opponentName: name,
    );
  }

  /// Guest side: join a friend's room by code.
  static Future<RemoteDuelDriver> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) async {
    final roomCode = code.toUpperCase().trim();
    final data = await FirestoreRest.get('$_duels/$roomCode');
    if (data == null) throw Exception('No duel found for that code.');
    if (data['hostUid'] == uid) throw Exception("That's your own room code.");
    if (data['guestUid'] != null) throw Exception('That duel already started.');
    await FirestoreRest.set('$_duels/$roomCode', {
      'guestUid': uid,
      'guestName': name,
      'status': 'active',
    });
    return RemoteDuelDriver(
      roomId: roomCode,
      isHost: false,
      masterSeed: (data['masterSeed'] as num).toInt(),
      opponentName: data['hostName'] as String? ?? 'Rival mage',
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
