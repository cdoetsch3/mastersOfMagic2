import 'dart:async';
import 'dart:math';

import 'package:mom_engine/mom_engine.dart';

import 'ai_personas.dart';
import 'firestore_rest.dart';
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

  /// Tells the remote peer this player surrendered, so their duel ends
  /// immediately instead of waiting out move timeouts. No-op for local AI.
  Future<void> reportSurrender();

  /// Invokes [onSurrendered] (at most once) if the opponent surrenders,
  /// even while this player is idle at the move picker. No-op for local AI.
  void watchOpponentSurrender(void Function() onSurrendered);

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
  Future<void> reportSurrender() async {}

  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}

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

  Timer? _surrenderWatch;
  bool _theySurrendered = false;

  RemoteDuelDriver({
    required this.roomId,
    required this.isHost,
    required this.masterSeed,
    required this.opponentName,
  });

  String get _roomPath => 'duels/$roomId';
  String _turnPath(int turn) => '$_roomPath/turns/$turn';

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
    final path = _turnPath(turn);
    final myWire = encodeAction(playerAction);
    final myNonce =
        List.generate(4, (_) => _rng.nextInt(0x40000000).toRadixString(16))
            .join();

    // 1. Commit.
    await FirestoreRest.set(path, {'${_me}Commit': commitmentOf(myWire, myNonce)});

    // 2. Wait for their commitment (or declare a forfeit on timeout).
    var data = await _pollTurn(
        path, (d) => d['${_them}Commit'] != null, opponentTimeout);
    if (data == null) {
      await FirestoreRest.set(path, {'${_them}Forfeit': true});
      data = await FirestoreRest.get(path) ?? {};
    }
    final theirForfeit = data['${_them}Forfeit'] == true &&
        data['${_them}Commit'] == null;

    // 3. Reveal (safe now: both commitments are locked, or they forfeited).
    await FirestoreRest.set(path, {'${_me}Move': myWire, '${_me}Nonce': myNonce});

    String theirWire;
    if (theirForfeit) {
      theirWire = encodeAction(const ForfeitAction());
    } else {
      final revealed = await _pollTurn(
          path,
          (d) => d['${_them}Move'] != null && d['${_them}Nonce'] != null,
          opponentTimeout);
      if (revealed == null) {
        theirWire = encodeAction(const ForfeitAction());
      } else {
        theirWire = revealed['${_them}Move'] as String;
        final nonce = revealed['${_them}Nonce'] as String;
        final commit = revealed['${_them}Commit'] as String? ?? '';
        if (!verifyCommitment(commit, theirWire, nonce)) {
          theirWire = encodeAction(const ForfeitAction());
        }
      }
    }

    final seed = deriveTurnSeed(masterSeed, turn, myWire, theirWire);
    return TurnExchange(decodeAction(theirWire), seed);
  }

  /// Polls the turn doc until [ready] passes, or returns null on timeout
  /// (or as soon as the opponent is known to have surrendered — no point
  /// waiting out the clock for a move that will never come).
  Future<Map<String, dynamic>?> _pollTurn(String path,
      bool Function(Map<String, dynamic>) ready, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_theySurrendered) return null;
      try {
        final d = await FirestoreRest.get(path);
        if (d != null && ready(d)) return d;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return null;
  }

  @override
  Future<void> reportSurrender() async {
    try {
      await FirestoreRest.set(
          _roomPath, {'${_me}Surrendered': true, 'status': 'ended'});
    } catch (_) {
      // Best effort — the opponent's move timeouts still end the duel.
    }
  }

  @override
  void watchOpponentSurrender(void Function() onSurrendered) {
    _surrenderWatch?.cancel();
    _surrenderWatch =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final room = await FirestoreRest.get(_roomPath);
        if (room?['${_them}Surrendered'] == true) {
          _theySurrendered = true;
          timer.cancel();
          onSurrendered();
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> dispose() async {
    _surrenderWatch?.cancel();
  }
}
