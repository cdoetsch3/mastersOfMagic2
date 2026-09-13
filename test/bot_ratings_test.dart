/// The bot pool's shared Firestore state (LADDER_DESIGN §4, §4.1):
/// [BotRatings.standingsFrom]'s pure merge, and [BotRatings.fetch]/
/// [BotRatings.record]'s request shapes against a mocked [FirestoreRest].
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:masters_of_magic_2/game/firestore_rest.dart';
import 'package:masters_of_magic_2/game/ladder/bot_ratings.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';

void main() {
  group('BotRatings.standingsFrom — pure merge', () {
    test('a bot with no doc reads at its seed with a 0-0 record', () {
      final wick = LadderRoster.byId('wick');
      final standings = BotRatings.standingsFrom({}, academy: false);
      expect(
        standings['wick']!.rating,
        wick.seedGeared,
        reason:
            'a mutant that defaults a missing doc to 0 (or the Elo '
            'starting rating) instead of the bot\'s own seed would fail '
            'this',
      );
      expect(standings['wick']!.wins, 0, reason: 'never played = no wins');
      expect(standings['wick']!.losses, 0, reason: 'never played = no losses');
    });

    test('every roster bot gets an entry, doc or no doc', () {
      final standings = BotRatings.standingsFrom({}, academy: false);
      expect(
        standings.length,
        LadderRoster.all.length,
        reason:
            'a mutant that only emits entries for bots WITH a doc would '
            'shrink this map instead of covering the whole roster',
      );
    });

    test('an existing doc supplies its own numbers, not the seed', () {
      final docs = {
        'wick': {'ratingGeared': 1345, 'winsGeared': 6, 'lossesGeared': 2},
      };
      final standings = BotRatings.standingsFrom(docs, academy: false);
      expect(
        standings['wick']!.rating,
        1345,
        reason: 'the doc\'s own rating must win over the seed',
      );
      expect(
        standings['wick']!.wins,
        6,
        reason: 'the doc\'s own win count must win over the 0 default',
      );
      expect(
        standings['wick']!.losses,
        2,
        reason: 'the doc\'s own loss count must win over the 0 default',
      );
    });

    test('the Academy ladder reads Academy fields, never Geared ones', () {
      final docs = {
        'wick': {
          'ratingGeared': 1345,
          'winsGeared': 6,
          'lossesGeared': 2,
          'ratingAcademy': 990,
          'winsAcademy': 1,
          'lossesAcademy': 9,
        },
      };
      final geared = BotRatings.standingsFrom(docs, academy: false);
      final academy = BotRatings.standingsFrom(docs, academy: true);
      expect(
        academy['wick']!.rating,
        990,
        reason:
            'a mutant reading the Geared field for the Academy ladder '
            'would return 1345 here instead',
      );
      expect(
        academy['wick']!.wins,
        1,
        reason: 'winsAcademy, not winsGeared, on the Academy ladder',
      );
      expect(
        academy['wick']!.losses,
        9,
        reason: 'lossesAcademy, not lossesGeared, on the Academy ladder',
      );
      // And the two ladders must stay independent of each other.
      expect(
        geared['wick']!.rating,
        1345,
        reason:
            'reading the Academy standings above must not mutate or leak '
            'into the Geared ones',
      );
    });

    test('a doc missing THIS ladder\'s field falls back to the seed, even '
        'though the doc exists', () {
      // A doc that only ever recorded Geared results (never Academy).
      final docs = {
        'wick': {'ratingGeared': 1345, 'winsGeared': 6, 'lossesGeared': 2},
      };
      final wick = LadderRoster.byId('wick');
      final academy = BotRatings.standingsFrom(docs, academy: true);
      expect(
        academy['wick']!.rating,
        wick.seedAcademy,
        reason:
            'a mutant that reads a missing field as 0 rather than the '
            'seed would fail this',
      );
    });
  });

  group('BotRatings.fetch / .record — against a mocked FirestoreRest', () {
    final originalClient = FirestoreRest.client;
    final originalTokenProvider = FirestoreRest.tokenProvider;

    setUp(() {
      FirestoreRest.tokenProvider = () async => null;
    });

    tearDown(() {
      FirestoreRest.client = originalClient;
      FirestoreRest.tokenProvider = originalTokenProvider;
    });

    test('fetch lists bots/ and merges the docs via standingsFrom', () async {
      FirestoreRest.client = MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/documents/bots'),
          reason: 'fetch must list the bots/ collection, nothing else',
        );
        return http.Response(
          jsonEncode({
            'documents': [
              {
                'name':
                    'projects/mastersofmagic2/databases/(default)/documents/bots/wick',
                'fields': FirestoreRest.encodeFields({
                  'ratingGeared': 1350,
                  'winsGeared': 2,
                  'lossesGeared': 1,
                }),
              },
            ],
          }),
          200,
        );
      });

      final standings = await BotRatings.fetch(academy: false);
      expect(
        standings['wick']!.rating,
        1350,
        reason: 'the live doc\'s rating, not the seed',
      );
      expect(
        standings['pim']!.rating,
        LadderRoster.byId('pim').seedGeared,
        reason: 'a bot with no doc in this (short) list still reads at seed',
      );
    });

    test('fetch does NOT swallow a failure — callers decide the fallback', () {
      FirestoreRest.client = MockClient((request) async {
        return http.Response('nope', 500);
      });
      expect(
        () => BotRatings.fetch(academy: false),
        throwsA(isA<FirestoreRestException>()),
        reason:
            'BotRatings.record swallows FirestoreRestException; fetch must '
            'NOT — the search decides for itself whether to fall back to '
            'seeds',
      );
    });

    test('record seeds the doc (BOTH seed ratings + updatedAt only) before '
        'incrementing', () async {
      final requests = <http.Request>[];
      FirestoreRest.client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });

      final wick = LadderRoster.byId('wick');
      await BotRatings.record(wick, academy: false, delta: -7, won: false);

      expect(
        requests,
        hasLength(2),
        reason: 'createIfAbsent, then the commit increment',
      );
      expect(
        requests[0].url.toString(),
        isNot(endsWith(':commit')),
        reason:
            'the FIRST call must be the createIfAbsent seed, not the '
            'increment',
      );
      final seedBody = jsonDecode(requests[0].body) as Map<String, dynamic>;
      final seedFields = seedBody['fields'] as Map<String, dynamic>;
      expect(
        seedFields.keys.toSet(),
        {'ratingGeared', 'ratingAcademy', 'updatedAt'},
        reason:
            'the seed write names exactly BOTH seed ratings + updatedAt '
            '— a mutant that also seeds win/loss fields (or drops one '
            'rating) would fail this',
      );
      expect(
        (seedFields['ratingGeared'] as Map<String, dynamic>)['integerValue'],
        '${wick.seedGeared}',
        reason: 'the seed write carries WICK\'S OWN geared seed',
      );
      expect(
        (seedFields['ratingAcademy'] as Map<String, dynamic>)['integerValue'],
        '${wick.seedAcademy}',
        reason: 'the seed write carries WICK\'S OWN academy seed',
      );

      final incBody = jsonDecode(requests[1].body) as Map<String, dynamic>;
      final writes = incBody['writes'] as List<dynamic>;
      final transform =
          (writes.first as Map<String, dynamic>)['transform']
              as Map<String, dynamic>;
      final fieldTransforms = transform['fieldTransforms'] as List<dynamic>;
      final byPath = {
        for (final t in fieldTransforms.cast<Map<String, dynamic>>())
          t['fieldPath'] as String: t,
      };
      expect(
        (byPath['ratingGeared']!['increment']
            as Map<String, dynamic>)['integerValue'],
        '-7',
        reason: 'the (already-clamped) delta lands on the Geared field',
      );
      expect(
        byPath.containsKey('lossesGeared'),
        isTrue,
        reason: 'won:false must bump lossesGeared, not winsGeared',
      );
      expect(
        byPath.containsKey('winsGeared'),
        isFalse,
        reason: 'a mutant bumping both would double-count the record',
      );
    });

    test('record on the Academy ladder touches the Academy fields', () async {
      final requests = <http.Request>[];
      FirestoreRest.client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });

      final wick = LadderRoster.byId('wick');
      await BotRatings.record(wick, academy: true, delta: 12, won: true);

      final incBody = jsonDecode(requests[1].body) as Map<String, dynamic>;
      final writes = incBody['writes'] as List<dynamic>;
      final transform =
          (writes.first as Map<String, dynamic>)['transform']
              as Map<String, dynamic>;
      final fieldTransforms = transform['fieldTransforms'] as List<dynamic>;
      final byPath = {
        for (final t in fieldTransforms.cast<Map<String, dynamic>>())
          t['fieldPath'] as String: t,
      };
      expect(
        byPath.containsKey('ratingAcademy'),
        isTrue,
        reason: 'academy:true must touch ratingAcademy, not ratingGeared',
      );
      expect(
        byPath.containsKey('ratingGeared'),
        isFalse,
        reason: 'academy:true must never also touch ratingGeared',
      );
      expect(
        byPath.containsKey('winsAcademy'),
        isTrue,
        reason: 'won:true on the Academy ladder bumps winsAcademy',
      );
    });

    test('a FirestoreRestException from the write is swallowed — a rating '
        'write must never crash the end of a duel', () async {
      FirestoreRest.client = MockClient((request) async {
        return http.Response('forbidden', 403);
      });

      final wick = LadderRoster.byId('wick');
      await expectLater(
        BotRatings.record(wick, academy: false, delta: -7, won: false),
        completes,
        reason:
            'a mutant that rethrows would let a bot-write failure crash '
            'the duel result screen',
      );
    });
  });
}
