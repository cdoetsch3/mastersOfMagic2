/// Settling one rated duel (LADDER_DESIGN §2, §4.1): [rate]'s pure Elo math,
/// then [settleRatedDuel]'s I/O against a mocked [FirestoreRest] and an
/// in-memory [ProfileStorage] (the same seams `firestore_rest_increment_test`
/// and the crafting-act tests already use).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/firestore_rest.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_result.dart';
import 'package:masters_of_magic_2/game/ladder/think_time.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

/// Pulls the LAST `:commit` write's `fieldTransforms` into a `{fieldPath:
/// request}` map, so a test can read one delta or record bump by name.
Map<String, dynamic> _lastIncrementTransforms(List<http.Request> requests) {
  final commit = requests.lastWhere(
    (r) => r.url.toString().endsWith(':commit'),
  );
  final body = jsonDecode(commit.body) as Map<String, dynamic>;
  final writes = body['writes'] as List<dynamic>;
  final transform =
      (writes.first as Map<String, dynamic>)['transform']
          as Map<String, dynamic>;
  final fieldTransforms = transform['fieldTransforms'] as List<dynamic>;
  return {
    for (final t in fieldTransforms.cast<Map<String, dynamic>>())
      t['fieldPath'] as String: t,
  };
}

void main() {
  group('rate() — the pure Elo exchange', () {
    test('equal 1200s: a new player (K40) beats a bot (K20)', () {
      final outcome = rate(
        playerRating: 1200,
        playerRatedGames: 0,
        playerPeak: 0,
        opponentRating: 1200,
        opponentRatedGames: 30,
        opponentPeak: 1200,
        won: true,
      );
      expect(
        outcome.playerDelta,
        20,
        reason: 'K40 * (1 - 0.5) = 20 — the player\'s own side of the win',
      );
      expect(
        outcome.opponentDelta,
        -10,
        reason: 'K20 * (0 - 0.5) = -10 — the bot\'s side of the same result',
      );
      expect(
        outcome.newPlayerRating,
        1220,
        reason: 'newPlayerRating is playerRating + playerDelta, 1200 + 20',
      );
    });

    test('equal 1200s: the same player LOSES to the same bot', () {
      final outcome = rate(
        playerRating: 1200,
        playerRatedGames: 0,
        playerPeak: 0,
        opponentRating: 1200,
        opponentRatedGames: 30,
        opponentPeak: 1200,
        won: false,
      );
      expect(
        outcome.playerDelta,
        -20,
        reason: 'a mutant that reuses the win branch\'s sign would fail this',
      );
      expect(
        outcome.opponentDelta,
        10,
        reason: 'the mirror image of the win case above',
      );
      expect(outcome.newPlayerRating, 1180, reason: '1200 + (-20)');
    });

    test('a player who has ever reached 2400 plays at K10, not K40', () {
      final outcome = rate(
        playerRating: 2400,
        playerRatedGames: 5, // far under 30 — K40 territory on games alone
        playerPeak: 2450, // but the peak has crossed 2400
        opponentRating: 2400,
        opponentRatedGames: 30,
        opponentPeak: 2400,
        won: true,
      );
      expect(
        outcome.playerDelta,
        5,
        reason:
            'K10 * (1 - 0.5) = 5 — a mutant reading ratedGames instead of '
            'peak for the K schedule would get 20 (K40) here',
      );
    });

    test('zero-sum when both sides share the same K', () {
      final outcome = rate(
        playerRating: 1300,
        playerRatedGames: 40,
        playerPeak: 1300,
        opponentRating: 1250,
        opponentRatedGames: 40,
        opponentPeak: 1250,
        won: true,
      );
      expect(
        outcome.playerDelta + outcome.opponentDelta,
        0,
        reason:
            'equal K, and scores that always sum to 1 (no draws), makes '
            'the exchange zero-sum — a mutant that drops the opponent K '
            'lookup (using the player\'s K for both) would break this the '
            'moment the two ratings differ',
      );
    });
  });

  group('settleRatedDuel — I/O against mocked FirestoreRest', () {
    final originalClient = FirestoreRest.client;
    final originalTokenProvider = FirestoreRest.tokenProvider;

    setUp(() {
      FirestoreRest.tokenProvider = () async => null;
    });

    tearDown(() {
      FirestoreRest.client = originalClient;
      FirestoreRest.tokenProvider = originalTokenProvider;
    });

    test(
      'geared: first rated match seeds from LEVEL, then applies the delta',
      () async {
        FirestoreRest.client = MockClient(
          (request) async => http.Response('{}', 200),
        );
        final profile = PlayerProfile.newPlayer(); // level 1, xp 0
        final game = GameState(_Mem(), profile);
        final driver = RemoteDuelDriver(
          roomId: 'room',
          isHost: true,
          masterSeed: 1,
          opponentName: 'Rival',
          opponentLevel: 5,
          opponentGear: ItemModifiers.none,
          opponentRating: 1200,
          rated: true,
        );

        await settleRatedDuel(
          game,
          driver: driver,
          academy: false,
          won: true,
          opponentRating: 1200,
        );

        final seed = LadderSeeds.gearedPlayer(level: profile.level);
        final expectedDelta = Elo.delta(
          rating: seed,
          opponentRating: 1200,
          score: 1.0,
          k: 40, // first-ever rated match: 0 games played
        );
        expect(
          profile.ratingGeared,
          seed + expectedDelta,
          reason:
              'a mutant that seeds from Elo.startingRating (1200) instead '
              'of the level-derived seed would fail this whenever the '
              'seed differs from 1200',
        );
        expect(
          profile.ratedGamesGeared,
          1,
          reason: 'the first rated match bumps the counter from 0 to 1',
        );
      },
    );

    test(
      'academy: first rated match seeds from 1200, then applies the delta',
      () async {
        FirestoreRest.client = MockClient(
          (request) async => http.Response('{}', 200),
        );
        final profile = PlayerProfile.newPlayer();
        final game = GameState(_Mem(), profile);
        final driver = RemoteDuelDriver(
          roomId: 'room',
          isHost: true,
          masterSeed: 1,
          opponentName: 'Rival',
          opponentLevel: 50,
          opponentGear: ItemModifiers.none,
          opponentRating: 1200,
          academy: true,
          rated: true,
        );

        await settleRatedDuel(
          game,
          driver: driver,
          academy: true,
          won: false,
          opponentRating: 1200,
        );

        final expectedDelta = Elo.delta(
          rating: Elo.startingRating,
          opponentRating: 1200,
          score: 0.0,
          k: 40,
        );
        expect(
          profile.ratingAcademy,
          Elo.startingRating + expectedDelta,
          reason:
              'the Academy always seeds at 1200 — level plays no part on '
              'this ladder',
        );
        expect(
          profile.ratedGamesAcademy,
          1,
          reason: 'the first rated Academy match bumps the counter to 1',
        );
        expect(
          profile.ratingGeared,
          null,
          reason: 'an Academy result must never touch the Geared rating',
        );
      },
    );

    test(
      'a bot\'s record write carries the CLAMPED delta, never the raw one',
      () async {
        final requests = <http.Request>[];
        FirestoreRest.client = MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        });

        final wick = LadderRoster.byId('wick');
        // ⭐ Wick's live rating sits at seed+295 — only 5 points of headroom
        // under the +300 clamp ceiling. Equal player/opponent ratings make
        // the raw K20 upset delta +10 (round(20 * (1 - 0.5))): comfortably
        // enough to overshoot the ceiling and force the clamp.
        final live = wick.seedGeared + 295;
        final profile = PlayerProfile.newPlayer()..ratingGeared = live;
        final game = GameState(_Mem(), profile);
        // ⭐ thinkTime set — exactly what marks this as a LADDER bot driver
        // rather than a practice-roster persona (see duel_launcher.dart).
        final driver = LocalAiDriver(
          persona: wick.toPersona(),
          gear: wick.gearModifiers,
          thinkTime: ThinkTime.standard,
        );

        // The BOT wins this duel (won: false — the player lost).
        await settleRatedDuel(
          game,
          driver: driver,
          academy: false,
          won: false,
          opponentRating: live,
        );

        final byPath = _lastIncrementTransforms(requests);
        expect(
          (byPath['ratingGeared']!['increment']
              as Map<String, dynamic>)['integerValue'],
          '5',
          reason:
              'the raw delta here is +10, but seed+295 only has 5 points '
              'of headroom before Elo.clampToSeed\'s +300 ceiling — a '
              'mutant that writes the raw opponentDelta instead of the '
              'clamped remainder would write 10 here',
        );
        expect(
          byPath.containsKey('winsGeared'),
          isTrue,
          reason: 'the bot won, so its OWN record bumps winsGeared',
        );
      },
    );

    test('a room-code (rated: false) driver writes nothing at all', () async {
      var networkCalls = 0;
      FirestoreRest.client = MockClient((request) async {
        networkCalls++;
        return http.Response('{}', 200);
      });
      final profile = PlayerProfile.newPlayer();
      final game = GameState(_Mem(), profile);
      final driver = RemoteDuelDriver(
        roomId: 'room',
        isHost: true,
        masterSeed: 1,
        opponentName: 'Friend',
        opponentLevel: 5,
        opponentGear: ItemModifiers.none,
        opponentRating: 1600,
        // rated defaults to false — exactly what createRoom/joinRoom send.
      );

      await settleRatedDuel(
        game,
        driver: driver,
        academy: false,
        won: true,
        opponentRating: 1600,
      );

      expect(
        profile.ratingGeared,
        null,
        reason:
            'a room-code duel must never seed or move the rating — a '
            'mutant that drops the `rated` guard would set this to '
            'seed+delta instead of leaving it null',
      );
      expect(
        profile.ratedGamesGeared,
        0,
        reason: 'the counter must not move for an unrated duel either',
      );
      expect(
        networkCalls,
        0,
        reason: 'no Firestore call of any kind for an unrated duel',
      );
    });
  });
}
