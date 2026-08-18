/// The LOGIN content-version gate: any mismatch between this build and the
/// server's `config/content` blocks play, but every *failure* of the check
/// lets the player through.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_version.dart';
import 'package:masters_of_magic_2/screens/content_gate_screen.dart';

void main() {
  /// A fake REST layer. Never touches the network; records what was asked for.
  ContentDocReader reader(
    Map<String, dynamic>? fields, {
    Object? throws,
    Duration delay = Duration.zero,
    List<String>? asked,
  }) {
    return (path) async {
      asked?.add(path);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (throws != null) throw throws;
      return fields;
    };
  }

  group('the gate rule', () {
    test('equal versions pass', () {
      expect(
        contentGateDecision(7, clientVersion: 7),
        ContentGateDecision.pass,
        reason: 'an agreeing client must play; a gate that blocks on equality '
            'locks everyone out on every launch',
      );
    });

    test('a NEWER server version gates — the ordinary deploy case', () {
      expect(
        contentGateDecision(8, clientVersion: 7),
        ContentGateDecision.blocked,
        reason: 'the stale client is the whole reason the gate exists',
      );
    });

    test('⭐ an OLDER server version gates too — any difference, not just <', () {
      // A server behind the client means a rollback or a half-finished
      // deploy. Kills `serverVersion > clientVersion` and `client < server`:
      // a client running AHEAD of the content everyone else resolves against
      // desyncs a lockstep duel exactly the same way.
      expect(
        contentGateDecision(6, clientVersion: 7),
        ContentGateDecision.blocked,
        reason: 'a less-than compare would wave a client running ahead of the '
            'server straight into a desynced duel',
      );
    });

    test('⚠️ an unknown server version passes — the gate fails OPEN', () {
      expect(
        contentGateDecision(null, clientVersion: 7),
        ContentGateDecision.pass,
        reason: 'null means our outage, not the player\'s skew; treating it as '
            'a mismatch would take the whole game down with Firestore',
      );
    });

    test('blocks is the decision, not a second opinion', () {
      expect(ContentGateDecision.blocked.blocks, isTrue);
      expect(ContentGateDecision.pass.blocks, isFalse);
    });
  });

  group('checkContentVersion — reading the server document', () {
    test('reads config/content and compares its version field', () async {
      final asked = <String>[];
      final decision = await checkContentVersion(
        read: reader({'version': 4}, asked: asked),
        clientVersion: 4,
      );
      expect(
        asked,
        ['config/content'],
        reason: 'a wrong path would 404 forever and silently disable the gate',
      );
      expect(decision, ContentGateDecision.pass);
    });

    test('a differing server version blocks', () async {
      expect(
        await checkContentVersion(
          read: reader({'version': 5}),
          clientVersion: 4,
        ),
        ContentGateDecision.blocked,
        reason: 'the end-to-end path must gate, not just the pure rule',
      );
    });

    test('⚠️ a thrown fetch (offline, rules, 500) passes', () async {
      expect(
        await checkContentVersion(
          read: reader(null, throws: Exception('offline')),
          clientVersion: 4,
        ),
        ContentGateDecision.pass,
        reason: 'an uncaught throw here would either crash boot or, if caught '
            'as a mismatch, gate every player whenever the network blinks',
      );
    });

    test('⚠️ a fetch that never returns passes once the timeout elapses', () async {
      expect(
        await checkContentVersion(
          read: reader({'version': 99}, delay: const Duration(seconds: 30)),
          clientVersion: 4,
          timeout: const Duration(milliseconds: 20),
        ),
        ContentGateDecision.pass,
        reason: 'without the timeout the player waits at the boot spinner '
            'forever; with a timeout that gates, a slow phone is unplayable',
      );
    });

    test('⚠️ a missing document passes — the server may not be seeded yet', () async {
      expect(
        await checkContentVersion(read: reader(null), clientVersion: 4),
        ContentGateDecision.pass,
        reason: 'FirestoreRest.get returns null for a 404; treating an absent '
            'doc as version 0 would gate everyone before the first deploy',
      );
    });

    test('⚠️ a missing or non-numeric field passes rather than gating', () async {
      expect(
        await checkContentVersion(read: reader({}), clientVersion: 4),
        ContentGateDecision.pass,
        reason: 'a doc without the field must not read as a mismatch',
      );
      expect(
        await checkContentVersion(
          read: reader({'version': 'four'}),
          clientVersion: 4,
        ),
        ContentGateDecision.pass,
        reason: 'a hand-typed string in the console must not lock the game; '
            'an unguarded cast would throw and (correctly) fail open anyway, '
            'but this pins the intent',
      );
    });

    test('a double still gates — a console edit must not disable the gate', () async {
      // Typing the version into the Firebase console produces a double, not an
      // integer. An `is int` narrowing would read that as "unknown", fail open,
      // and silently switch the gate off for every player.
      expect(
        await checkContentVersion(
          read: reader({'version': 5.0}),
          clientVersion: 4,
        ),
        ContentGateDecision.blocked,
        reason: 'an `is int` test would drop a console-entered double on the '
            'floor and wave every stale client through',
      );
      expect(
        await checkContentVersion(
          read: reader({'version': 4.0}),
          clientVersion: 4,
        ),
        ContentGateDecision.pass,
        reason: '4.0 and 4 are the same version — comparing the raw values '
            'would gate everyone on a doc that is actually correct',
      );
    });

    test('the shipped default compares against ContentVersion.current', () async {
      expect(
        await checkContentVersion(
          read: reader({'version': ContentVersion.current}),
        ),
        ContentGateDecision.pass,
        reason: 'clientVersion must default to the constant this build ships, '
            'not to a literal that drifts when the constant is bumped',
      );
      expect(
        await checkContentVersion(
          read: reader({'version': ContentVersion.current + 1}),
        ),
        ContentGateDecision.blocked,
      );
    });
  });

  group('the blocking screen', () {
    testWidgets('explains itself and offers Refresh', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(
        MaterialApp(home: ContentGateScreen(onRefresh: () => refreshed++)),
      );

      expect(find.text('A new version is out'), findsOneWidget);
      expect(
        find.textContaining('Refresh to load the current version'),
        findsOneWidget,
        reason: 'a bare error code leaves the player with nothing to do',
      );

      final refresh = find.widgetWithText(FilledButton, 'Refresh');
      expect(refresh, findsOneWidget);
      await tester.tap(refresh);
      await tester.pump();
      expect(
        refreshed,
        1,
        reason: 'a disabled or unwired button would strand the player on the '
            'one screen with no way out (the reload itself is not tested)',
      );
    });

    testWidgets('⭐ offers no way to dismiss it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ContentGateScreen(onRefresh: () {})),
      );
      expect(
        find.byType(BackButton),
        findsNothing,
        reason: 'any escape hatch defeats the gate — a mismatched client must '
            'not reach the game',
      );
      expect(find.text('Continue'), findsNothing);
      expect(
        tester
            .widget<PopScope<Object?>>(
              find.descendant(
                of: find.byType(ContentGateScreen),
                matching: find.byType(PopScope<Object?>),
              ),
            )
            .canPop,
        isFalse,
        reason: 'system back must not pop the gate off the stack',
      );
    });

    testWidgets('lays out on a very narrow phone without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: ContentGateScreen(onRefresh: () {})),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
