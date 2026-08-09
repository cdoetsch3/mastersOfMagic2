/// The rendezvous rule that lets two simultaneous Quick Match presses find
/// each other instead of both timing out to an AI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/matchmaking.dart';

void main() {
  group('ticketPrecedes — the strict claim ordering', () {
    test('an older ticket precedes a newer one', () {
      expect(
        Matchmaking.ticketPrecedes(
          theirUid: 'b',
          theirCreatedAt: '2026-08-09T10:00:00.000Z',
          myUid: 'a',
          myCreatedAt: '2026-08-09T10:00:01.000Z',
        ),
        isTrue,
      );
    });

    test('⭐ two simultaneous searchers can never claim each other', () {
      // Identical timestamps — the uid tiebreak must make exactly ONE of the
      // two precede the other. If both saw true (or both false), both would
      // claim (or neither), and the reported bug returns.
      const t = '2026-08-09T10:00:00.000Z';
      final aClaimsB = Matchmaking.ticketPrecedes(
        theirUid: 'b', theirCreatedAt: t, myUid: 'a', myCreatedAt: t);
      final bClaimsA = Matchmaking.ticketPrecedes(
        theirUid: 'a', theirCreatedAt: t, myUid: 'b', myCreatedAt: t);
      expect(aClaimsB != bClaimsA, isTrue,
          reason: 'exactly one direction may claim');
    });

    test('a ticket never precedes itself', () {
      const t = '2026-08-09T10:00:00.000Z';
      expect(
        Matchmaking.ticketPrecedes(
          theirUid: 'a', theirCreatedAt: t, myUid: 'a', myCreatedAt: t),
        isFalse,
      );
    });

    test('createdAt outranks uid — time first, tiebreak second', () {
      // 'z' > 'a' as a uid, but the z ticket is OLDER, so it precedes.
      expect(
        Matchmaking.ticketPrecedes(
          theirUid: 'z',
          theirCreatedAt: '2026-08-09T09:59:59.000Z',
          myUid: 'a',
          myCreatedAt: '2026-08-09T10:00:00.000Z',
        ),
        isTrue,
      );
    });
  });
}
