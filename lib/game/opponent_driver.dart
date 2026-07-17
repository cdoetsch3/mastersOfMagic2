import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_engine/mom_engine.dart';

import 'ai_personas.dart';
import 'mage_apparel.dart';

/// What one turn's exchange produced: the opponent's action, plus (for
/// networked duels) the seed both clients must use to resolve the turn.
class TurnExchange {
  final MageAction opponentAction;
  final int? turnSeed;

  const TurnExchange(this.opponentAction, [this.turnSeed]);
}

/// The seam that makes every duel identical once it starts: the duel screen
/// talks to a driver, and the driver is a local AI persona, a matchmade
/// human, or a friend — the combat logic never knows the difference.
abstract interface class OpponentDriver {
  String get opponentName;
  MageApparel get opponentApparel;

  /// Whether the local player is "host" (engine mage1). Remote duels assign
  /// sides; local duels always make the player the host.
  bool get playerIsHost;

  /// Whether "Duel again" makes sense (true for AI; false for remote rooms).
  bool get supportsRematch;

  /// Exchanges this turn's moves: sends [playerAction], returns the
  /// opponent's. For AI this is instant; for remote play it performs the
  /// commit-reveal round trip (and may report the opponent as forfeiting if
  /// they time out or disconnect).
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction);

  /// Tear down listeners/rooms.
  Future<void> dispose();
}

/// An AI persona behind the same interface. The controller [bind]s the live
/// mage states after constructing the engine.
class LocalAiDriver implements OpponentDriver {
  final AiPersona persona;
  final Random rng;
  late final DuelAi _brain = persona.buildBrain();

  MageState? _player;
  MageState? _enemy;

  LocalAiDriver({required this.persona, Random? rng}) : rng = rng ?? Random();

  void bind(MageState player, MageState enemy) {
    _player = player;
    _enemy = enemy;
  }

  @override
  String get opponentName => persona.name;

  @override
  MageApparel get opponentApparel => persona.apparel;

  @override
  bool get playerIsHost => true;

  @override
  bool get supportsRematch => true;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async {
    return TurnExchange(_brain.chooseAction(_enemy!, _player!, rng));
  }

  @override
  Future<void> dispose() async {}
}

/// Commit-reveal duel over a Firestore room. Both clients:
///  1. write `sha256(move|nonce)` to the turn doc,
///  2. once both commitments exist, write the (move, nonce) reveal,
///  3. verify the opponent's reveal against their commitment,
///  4. resolve the turn locally with a seed derived from both moves.
/// An opponent that hasn't committed within [opponentTimeout] forfeits the
/// move (also how disconnects are handled — they forfeit until they lose).
class RemoteDuelDriver implements OpponentDriver {
  final String roomId;
  final bool isHost;
  final int masterSeed;
  @override
  final String opponentName;

  static const opponentTimeout = Duration(seconds: 25);

  final _rng = Random.secure();

  RemoteDuelDriver({
    required this.roomId,
    required this.isHost,
    required this.masterSeed,
    required this.opponentName,
  });

  DocumentReference<Map<String, dynamic>> get _room =>
      FirebaseFirestore.instance.collection('duels').doc(roomId);

  DocumentReference<Map<String, dynamic>> _turnDoc(int turn) =>
      _room.collection('turns').doc('$turn');

  String get _me => isHost ? 'host' : 'guest';
  String get _them => isHost ? 'guest' : 'host';

  @override
  MageApparel get opponentApparel =>
      isHost ? MageApparel.duskWitch : MageApparel.apprenticeBlue;

  @override
  bool get playerIsHost => isHost;

  @override
  bool get supportsRematch => false;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async {
    final doc = _turnDoc(turn);
    final myWire = encodeAction(playerAction);
    final myNonce =
        List.generate(4, (_) => _rng.nextInt(1 << 32).toRadixString(16))
            .join();

    // 1. Commit.
    await doc.set({'${_me}Commit': commitmentOf(myWire, myNonce)},
        SetOptions(merge: true));

    // 2. Wait for their commitment (or declare a forfeit on timeout).
    var data = await _waitFor(doc, (d) => d['${_them}Commit'] != null,
        timeout: opponentTimeout);
    if (data == null) {
      await doc.set({'${_them}Forfeit': true}, SetOptions(merge: true));
      data = (await doc.get()).data() ?? {};
    }
    final theirForfeit = data['${_them}Forfeit'] == true &&
        data['${_them}Commit'] == null;

    // 3. Reveal (safe now: both commitments are locked, or they forfeited).
    await doc.set({'${_me}Move': myWire, '${_me}Nonce': myNonce},
        SetOptions(merge: true));

    String theirWire;
    if (theirForfeit) {
      theirWire = encodeAction(const ForfeitAction());
    } else {
      final revealed = await _waitFor(
          doc, (d) => d['${_them}Move'] != null && d['${_them}Nonce'] != null,
          timeout: opponentTimeout);
      if (revealed == null) {
        // Committed but never revealed (disconnected mid-turn): forfeit.
        theirWire = encodeAction(const ForfeitAction());
      } else {
        theirWire = revealed['${_them}Move'] as String;
        final nonce = revealed['${_them}Nonce'] as String;
        final commit = revealed['${_them}Commit'] as String;
        if (!verifyCommitment(commit, theirWire, nonce)) {
          // Tampered reveal — treat as a forfeited move.
          theirWire = encodeAction(const ForfeitAction());
        }
      }
    }

    final seed = deriveTurnSeed(masterSeed, turn, myWire, theirWire);
    return TurnExchange(decodeAction(theirWire), seed);
  }

  /// Resolves with the doc data once [ready] passes, or null on timeout.
  Future<Map<String, dynamic>?> _waitFor(
    DocumentReference<Map<String, dynamic>> doc,
    bool Function(Map<String, dynamic>) ready, {
    required Duration timeout,
  }) async {
    final completer = Completer<Map<String, dynamic>?>();
    late final StreamSubscription sub;
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    sub = doc.snapshots().listen((snap) {
      final d = snap.data();
      if (d != null && ready(d) && !completer.isCompleted) {
        completer.complete(d);
      }
    }, onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    final result = await completer.future;
    timer.cancel();
    await sub.cancel();
    return result;
  }

  /// Marks the duel finished (best effort).
  Future<void> finish(String winnerSide) async {
    try {
      await _room.set(
          {'status': 'done', 'winner': winnerSide}, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {}
}
