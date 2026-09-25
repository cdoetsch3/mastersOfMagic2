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

    // ================================================================
    // The read clamp (2026-09-25: "Hesper and Rook both ended up with only
    // 8 ELO, so when I beat him I got ±0").
    // ================================================================
    test('a doc stuck at 8 reads at the clamp floor, never at 8', () {
      final rook = LadderRoster.byId('rook');
      final standings = BotRatings.standingsFrom({
        'rook': {'ratingGeared': 8, 'winsGeared': 1},
      }, academy: false);
      expect(
        standings['rook']!.rating,
        rook.seedGeared - 300,
        reason:
            'a doc at 8 is clamped up to seed − 300 — a mutant that trusts '
            'the stored number verbatim shows an 8-rated Rook, and beating '
            'him is worth ±0',
      );
      expect(
        standings['rook']!.wins,
        1,
        reason: 'the clamp is on the rating only; the record reads as stored',
      );
    });

    test('a doc at 0 (or below) reads as the seed, not the floor', () {
      final rook = LadderRoster.byId('rook');
      for (final bad in [0, -40]) {
        final standings = BotRatings.standingsFrom({
          'rook': {'ratingGeared': bad},
        }, academy: false);
        expect(
          standings['rook']!.rating,
          rook.seedGeared,
          reason:
              'rating $bad is not a drifted value but a broken write — it '
              'reads as "never played" (the seed). A mutant that only '
              'clamps would give seed − 300 here',
        );
      }
    });

    test('a doc above 3000 reads as the seed, not the ceiling', () {
      final rook = LadderRoster.byId('rook');
      final standings = BotRatings.standingsFrom({
        'rook': {'ratingGeared': 9000},
      }, academy: false);
      expect(
        standings['rook']!.rating,
        rook.seedGeared,
        reason:
            'absurdly high is as broken as absurdly low — a mutant that '
            'only clamps would give seed + 300',
      );
    });

    test('an in-band doc still reads exactly as stored', () {
      final rook = LadderRoster.byId('rook');
      final standings = BotRatings.standingsFrom({
        'rook': {'ratingGeared': rook.seedGeared + 299},
      }, academy: false);
      expect(
        standings['rook']!.rating,
        rook.seedGeared + 299,
        reason:
            'the clamp must not touch a healthy rating — a mutant that '
            'snaps everything to the seed fails here',
      );
    });

    test('an out-of-band value above the seed reads at the ceiling', () {
      final rook = LadderRoster.byId('rook');
      final standings = BotRatings.standingsFrom({
        'rook': {'ratingAcademy': rook.seedAcademy + 500},
      }, academy: true);
      expect(
        standings['rook']!.rating,
        rook.seedAcademy + 300,
        reason:
            'the clamp is two-sided and per-ladder — a mutant that only '
            'raises the floor, or clamps against the geared seed, fails',
      );
    });

    test('isCorrupt: absent or out of band, and nothing else', () {
      const seed = 1407;
      expect(
        BotRatings.isCorrupt(null, seed: seed),
        isTrue,
        reason: 'a missing field is corrupt (increment-born docs lack one)',
      );
      expect(
        BotRatings.isCorrupt(8, seed: seed),
        isTrue,
        reason: 'Rook at 8 is the case this exists for',
      );
      expect(
        BotRatings.isCorrupt(seed - 300, seed: seed),
        isFalse,
        reason:
            'the band edge is still legal — a mutant using < instead of <= '
            'would "repair" a bot a grinder legitimately pinned at the floor',
      );
      expect(
        BotRatings.isCorrupt(seed + 301, seed: seed),
        isTrue,
        reason: 'one past the ceiling is out of band',
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

    // ================================================================
    // The write side (2026-09-25): the increment is never a doc's first
    // write, and a corrupt doc is repaired to its seed before it is moved.
    // ================================================================

    /// A mock Firestore that answers the create with [createStatus], the
    /// GET with [existing] (null = 404), and 200 to everything else, logging
    /// every request.
    List<http.Request> fakeFirestore({
      required int createStatus,
      Map<String, dynamic>? existing,
    }) {
      final requests = <http.Request>[];
      FirestoreRest.client = MockClient((request) async {
        requests.add(request);
        final url = request.url.toString();
        if (request.method == 'POST' && url.contains('documentId=')) {
          return http.Response('{}', createStatus);
        }
        if (request.method == 'GET') {
          if (existing == null) return http.Response('{}', 404);
          return http.Response(
            jsonEncode({'fields': FirestoreRest.encodeFields(existing)}),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      return requests;
    }

    bool isCommit(http.Request r) => r.url.toString().endsWith(':commit');

    test(
      'an existing doc at 8 is SET to the seed before the increment',
      () async {
        final rook = LadderRoster.byId('rook');
        final requests = fakeFirestore(
          createStatus: 409,
          existing: {
            'ratingGeared': 8,
            'ratingAcademy': rook.seedAcademy,
            'winsGeared': 1,
          },
        );

        await BotRatings.record(rook, academy: false, delta: 12, won: true);

        expect(
          requests.map((r) => r.method).toList(),
          ['POST', 'GET', 'PATCH', 'POST'],
          reason:
              'create (409) → read → repair → increment. A mutant that skips '
              'the read (or the repair) goes straight to the commit and leaves '
              'Rook at 8 + 12',
        );
        final repair = requests[2];
        expect(
          repair.url.queryParametersAll['updateMask.fieldPaths'],
          ['ratingGeared'],
          reason:
              'the repair touches exactly this ladder\'s rating — a mutant '
              'that rewrites the whole doc would reset the record too',
        );
        final fields =
            (jsonDecode(repair.body) as Map<String, dynamic>)['fields']
                as Map<String, dynamic>;
        expect(
          (fields['ratingGeared'] as Map<String, dynamic>)['integerValue'],
          '${rook.seedGeared}',
          reason:
              'the rules allow an out-of-band rating to be set to EXACTLY the '
              'seed — a mutant writing the clamp floor (seed − 300) would be '
              'refused',
        );
        expect(
          isCommit(requests.last),
          isTrue,
          reason: 'and only then the increment',
        );
      },
    );

    test(
      'an existing doc MISSING this ladder\'s rating is seeded first',
      () async {
        final rook = LadderRoster.byId('rook');
        final requests = fakeFirestore(
          createStatus: 409,
          existing: {'ratingGeared': rook.seedGeared},
        );

        await BotRatings.record(rook, academy: true, delta: -6, won: false);

        final repair = requests.firstWhere((r) => r.method == 'PATCH');
        final fields =
            (jsonDecode(repair.body) as Map<String, dynamic>)['fields']
                as Map<String, dynamic>;
        expect(
          (fields['ratingAcademy'] as Map<String, dynamic>)['integerValue'],
          '${rook.seedAcademy}',
          reason:
              'no ratingAcademy on the doc → the Academy increment would '
              'CREATE the field at −6. A mutant that only repairs a present '
              'field misses this',
        );
      },
    );

    test('a healthy existing doc is NOT rewritten', () async {
      final rook = LadderRoster.byId('rook');
      final requests = fakeFirestore(
        createStatus: 409,
        existing: {
          'ratingGeared': rook.seedGeared - 120,
          'ratingAcademy': rook.seedAcademy,
        },
      );

      await BotRatings.record(rook, academy: false, delta: 5, won: true);

      expect(
        requests.map((r) => r.method).toList(),
        ['POST', 'GET', 'POST'],
        reason:
            'an in-band rating is left alone — a mutant that always '
            'repairs would snap every bot back to its seed every match '
            '(and be refused by the rules for any drift > 40)',
      );
    });

    test('a create that FAILS aborts before any increment', () async {
      for (final status in [400, 403, 500]) {
        final requests = fakeFirestore(createStatus: status);
        await BotRatings.record(
          LadderRoster.byId('hesper'),
          academy: false,
          delta: 8,
          won: true,
        );
        expect(
          requests.where(isCommit),
          isEmpty,
          reason:
              'create answered $status — neither "created" nor "already '
              'exists" — so the doc may not exist, and an increment now '
              'would CREATE it at rating = 8. That is the bug; a mutant '
              'that increments anyway fails here',
        );
      }
    });

    test('"exists" but gone on read aborts before any increment', () async {
      final requests = fakeFirestore(createStatus: 409, existing: null);
      await BotRatings.record(
        LadderRoster.byId('hesper'),
        academy: false,
        delta: 8,
        won: true,
      );
      expect(
        requests.where(isCommit),
        isEmpty,
        reason:
            'a 404 after a 409 means the doc is not there to add to — a '
            'mutant that ignores the read result increments into nothing',
      );
    });

    test(
      'a network failure (not a FirestoreRestException) is swallowed too',
      () async {
        FirestoreRest.client = MockClient((request) async {
          throw http.ClientException('offline');
        });
        await expectLater(
          BotRatings.record(
            LadderRoster.byId('hesper'),
            academy: false,
            delta: 8,
            won: true,
          ),
          completes,
          reason:
              'a dropped connection must not crash the result card either — '
              'a mutant catching only FirestoreRestException rethrows this',
        );
      },
    );
  });
}
