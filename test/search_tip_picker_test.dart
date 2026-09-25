/// The quick-match tip picker (ruling 2026-09-25: "the tip picker always
/// shows Haste").
///
/// ⚠️ What shipped was `DateTime.now().microsecondsSinceEpoch % 20`. On web
/// the clock has millisecond precision, so that number is always a multiple
/// of 1000 — and 1000 % 20 == 0, so every search in the browser showed tip 0,
/// Haste. The fix draws from a [Random], injected so these tests can seed it.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a picker that ignores the injected Random, and one that still
/// lands on index 0.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/screens/matchmaking_screen.dart';

Future<void> _pumpSearching(WidgetTester tester, Random random) async {
  // ⭐ Both times pinned, and the view rebuilt under a fresh key, so each pump
  // builds a new State — and so draws a new tip — rather than reusing the
  // previous one's `late final` pick.
  final startedAt = DateTime.utc(2026, 9, 25, 12);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: KeyedSubtree(
          key: UniqueKey(),
          child: searchingViewForTest(
            startedAt: startedAt,
            matchedAt: startedAt,
            random: random,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a seeded Random shows the tip it picks', (tester) async {
    // Random(1).nextInt(20) is 4 on the Dart VM.
    await _pumpSearching(tester, Random(1));

    expect(
      find.text('Tip · ${searchTips[4].title}'),
      findsOneWidget,
      reason:
          'the view must draw its tip from the INJECTED Random — a picker '
          'that ignored it (a fresh Random(), or the old clock modulo) would '
          'show some other tip here',
    );
    expect(
      find.text('Tip · ${searchTips[0].title}'),
      findsNothing,
      reason:
          'the shipped defect: every search showed tip 0 (Haste) — a picker '
          'that still lands on index 0 is exactly what this ruling fixed',
    );
  });

  testWidgets('two different seeds show two different tips', (tester) async {
    // ⚠️ Precondition, so the assertion below cannot pass vacuously: the two
    // seeds really do pick different indices.
    final a = Random(1).nextInt(searchTips.length);
    final b = Random(2).nextInt(searchTips.length);
    expect(
      a,
      isNot(b),
      reason:
          'seeds 1 and 2 must pick different tips for this test to mean '
          'anything — choose other seeds if the list length changes',
    );

    await _pumpSearching(tester, Random(1));
    final first = searchTips.firstWhere(
      (t) => find.text('Tip · ${t.title}').evaluate().isNotEmpty,
    );

    await _pumpSearching(tester, Random(2));
    final second = searchTips.firstWhere(
      (t) => find.text('Tip · ${t.title}').evaluate().isNotEmpty,
    );

    expect(
      second.title,
      isNot(first.title),
      reason:
          'a picker that does not vary — a constant index, or the web '
          "clock's always-a-multiple-of-1000 modulo — shows the same tip "
          'for every search',
    );
    expect(
      [first.title, second.title],
      [searchTips[a].title, searchTips[b].title],
      reason: 'each view shows the tip its own Random picked',
    );
  });
}
