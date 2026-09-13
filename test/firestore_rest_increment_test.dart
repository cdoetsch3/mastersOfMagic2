/// [FirestoreRest.increment] — the LADDER §4.1 field-transform commit that
/// lets two clients finishing against the same bot both land their Δ.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:masters_of_magic_2/game/firestore_rest.dart';

void main() {
  final originalClient = FirestoreRest.client;
  final originalTokenProvider = FirestoreRest.tokenProvider;

  setUp(() {
    // No Firebase app exists in this test run, so the real [tokenProvider]
    // would throw `[core/no-app]` before the mock client ever sees the
    // request. Every test here cares about the commit body, not auth.
    FirestoreRest.tokenProvider = () async => null;
  });

  tearDown(() {
    // ⚠️ Every test swaps the static client/token seams; restore them so a
    // later test (or a later file, since they're statics) never inherits a
    // stale mock.
    FirestoreRest.client = originalClient;
    FirestoreRest.tokenProvider = originalTokenProvider;
  });

  test('posts to the :commit endpoint, not a plain document path', () async {
    late http.Request captured;
    FirestoreRest.client = MockClient((request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await FirestoreRest.increment('bots/wick', {'ratingGeared': -7});

    expect(
      captured.url.toString(),
      endsWith('documents:commit'),
      reason:
          'mutant that posts to the plain document path instead of '
          ':commit would break the field-transform semantics',
    );
    expect(
      captured.url.toString(),
      'https://firestore.googleapis.com/v1/projects/mastersofmagic2/'
      'databases/(default)/documents:commit',
      reason: 'the exact REST shape from LADDER §4.1',
    );
  });

  test('body carries a transform naming the full document path', () async {
    late http.Request captured;
    FirestoreRest.client = MockClient((request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await FirestoreRest.increment('bots/wick', {'ratingGeared': -7});

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final writes = body['writes'] as List<dynamic>;
    expect(
      writes,
      hasLength(1),
      reason:
          'no [set] was given, so only the transform write should be '
          'sent — a mutant that always appends a second write would fail '
          'this',
    );
    final transform =
        (writes.first as Map<String, dynamic>)['transform']
            as Map<String, dynamic>;
    expect(
      transform['document'],
      'projects/mastersofmagic2/databases/(default)/documents/bots/wick',
      reason: 'the fully-qualified document name the transform targets',
    );
  });

  test(
    'each delta becomes a fieldTransform with a string integerValue',
    () async {
      late http.Request captured;
      FirestoreRest.client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });

      await FirestoreRest.increment('bots/wick', {
        'ratingGeared': -7,
        'lossesGeared': 1,
      });

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final writes = body['writes'] as List<dynamic>;
      final transform =
          (writes.first as Map<String, dynamic>)['transform']
              as Map<String, dynamic>;
      final fieldTransforms = transform['fieldTransforms'] as List<dynamic>;
      expect(
        fieldTransforms,
        hasLength(2),
        reason:
            'one fieldTransform per delta key — a mutant that drops or '
            'merges deltas would change this count',
      );

      final byPath = {
        for (final t in fieldTransforms.cast<Map<String, dynamic>>())
          t['fieldPath'] as String: t,
      };
      expect(
        (byPath['ratingGeared']!['increment']
            as Map<String, dynamic>)['integerValue'],
        '-7',
        reason:
            'integerValue must be a STRING in Firestore REST JSON, and '
            'the sign must survive — a mutant using num instead of a string, '
            'or dropping the negative, would fail this',
      );
      expect(
        (byPath['lossesGeared']!['increment']
            as Map<String, dynamic>)['integerValue'],
        '1',
        reason: 'a second, independent delta in the same call',
      );
    },
  );

  test(
    'an optional [set] arrives as a second write with an updateMask',
    () async {
      late http.Request captured;
      FirestoreRest.client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });

      await FirestoreRest.increment(
        'bots/wick',
        {'ratingGeared': -7},
        set: {'updatedAt': 'now'},
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final writes = body['writes'] as List<dynamic>;
      expect(
        writes,
        hasLength(2),
        reason:
            'set fields ride in a second write, not folded into the '
            'transform — a mutant that drops [set] would leave one write',
      );
      final update =
          (writes[1] as Map<String, dynamic>)['update'] as Map<String, dynamic>;
      expect(
        update['name'],
        'projects/mastersofmagic2/databases/(default)/documents/bots/wick',
        reason:
            'the plain update must target the same document as the '
            'transform',
      );
      final fields = update['fields'] as Map<String, dynamic>;
      expect(
        (fields['updatedAt'] as Map<String, dynamic>)['stringValue'],
        'now',
        reason:
            'set fields are encoded the normal FirestoreRest.encodeValue '
            'way',
      );
      final mask =
          (writes[1] as Map<String, dynamic>)['updateMask']
              as Map<String, dynamic>;
      expect(
        mask['fieldPaths'],
        ['updatedAt'],
        reason:
            'the updateMask must name exactly the set fields, or the '
            'commit would touch the whole document',
      );
    },
  );

  test('no [set] means no second write at all', () async {
    late http.Request captured;
    FirestoreRest.client = MockClient((request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await FirestoreRest.increment('bots/wick', {'ratingGeared': -7});

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final writes = body['writes'] as List<dynamic>;
    expect(
      writes,
      hasLength(1),
      reason: 'omitting [set] must not send an empty/garbage second write',
    );
  });

  test('a non-200 response throws FirestoreRestException', () async {
    FirestoreRest.client = MockClient((request) async {
      return http.Response('forbidden', 403);
    });

    expect(
      () => FirestoreRest.increment('bots/wick', {'ratingGeared': -7}),
      throwsA(isA<FirestoreRestException>()),
      reason:
          'a mutant that swallows non-200 statuses would let a failed '
          'write pass silently',
    );
  });
}
