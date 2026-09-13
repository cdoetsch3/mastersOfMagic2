/// LADDER_DESIGN §3's narration table: the quick-match screen's status line
/// must never let the player tell a bot match from a human one by timing it.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a boundary that's off by one millisecond, a phase read against
/// the wrong anchor (search start vs. match found), and a status line that
/// never ticks at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/ui/search_narration.dart';

void main() {
  group('phaseAt — unmatched (elapsed since search started)', () {
    test('5999ms is still searching', () {
      expect(
        phaseAt(const Duration(milliseconds: 5999), matched: false),
        SearchPhase.searching,
        reason:
            'a boundary of "<= 6s" (instead of "< 6s") would flip this exact '
            'millisecond to almostThere one tick early',
      );
    });

    test('6000ms becomes almost there', () {
      expect(
        phaseAt(const Duration(milliseconds: 6000), matched: false),
        SearchPhase.almostThere,
        reason:
            'a boundary of "< 6s" applied the wrong direction (or "<= 6s") '
            'would keep exactly 6000ms at searching, one tick late',
      );
    });
  });

  group('phaseAt — matched (elapsed since the match was found)', () {
    test('+0ms is found', () {
      expect(
        phaseAt(Duration.zero, matched: true),
        SearchPhase.found,
        reason:
            'a driver that reads found off the wrong anchor (or defaults to '
            'loading) would skip the found banner the instant a match lands',
      );
    });

    test('+1199ms is still found', () {
      expect(
        phaseAt(const Duration(milliseconds: 1199), matched: true),
        SearchPhase.found,
        reason:
            'a hold shorter than 1200ms (e.g. ">= 1199ms => loading") would '
            'let a bot\'s instant driver build race ahead of a human '
            'handshake — exactly the leak LADDER §3 forbids',
      );
    });

    test('+1200ms becomes loading', () {
      expect(
        phaseAt(const Duration(milliseconds: 1200), matched: true),
        SearchPhase.loading,
        reason:
            'a hold longer than 1200ms (e.g. "> 1200ms => loading") would '
            'never actually advance past found at the promised mark',
      );
    });
  });

  group('SearchStatusLine', () {
    testWidgets('a search started 7s ago reads Almost there…', (tester) async {
      final startedAt = DateTime.now().subtract(const Duration(seconds: 7));
      await tester.pumpWidget(
        MaterialApp(home: SearchStatusLine(startedAt: startedAt)),
      );
      await tester.pump();

      expect(
        find.text('Almost there…'),
        findsOneWidget,
        reason:
            'a widget that reads phaseAt against DateTime.now() instead of '
            'the injected startedAt (or never ticks after first build) would '
            'still show the 0s-elapsed "Searching for an opponent…" label',
      );
    });

    testWidgets('a fresh search reads Searching for an opponent…', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchStatusLine(startedAt: DateTime.now())),
      );
      await tester.pump();

      expect(
        find.text('Searching for an opponent…'),
        findsOneWidget,
        reason:
            'the very first frame of a search must not already read '
            'Almost there… — that would mean the 6s threshold is broken or '
            'inverted',
      );
      expect(
        find.text('If no mage answers, a rival steps in.'),
        findsNothing,
        reason:
            'LADDER §1 law 3: nothing player-facing may disclose that a bot '
            'can stand in — this deleted subtitle must not have come back',
      );
    });
  });
}
