/// The rendezvous rule that lets two simultaneous Quick Match presses find
/// each other instead of both timing out to an AI — plus the lobby menu
/// itself.
///
/// ⭐ Ruling 2026-09-21: the "Practice vs AI" roster is gone. The lobby now
/// says "AI" NOWHERE, and no persona is namable there. The widget group
/// below is mutation-verified against exactly that: every assertion names
/// the re-added section, the resurrected roster row, or the old dialog
/// promise it kills, and the Quick match / room-code panels are asserted
/// present so a deletion that took the whole menu with it cannot pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/matchmaking.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/matchmaking_screen.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// The geared lobby with no `AuthScope` above it — so there is no uid, which
/// is what makes the "Account needed" dialog reachable from a tap.
Future<void> _pumpLobby(WidgetTester tester) async {
  final profile = PlayerProfile.newPlayer();
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: GameState(_MemStorage(), profile),
        child: MatchmakingScreen(loadout: profile.activePreset.toLoadout()),
      ),
    ),
  );
  await tester.pump();
}

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
        theirUid: 'b',
        theirCreatedAt: t,
        myUid: 'a',
        myCreatedAt: t,
      );
      final bClaimsA = Matchmaking.ticketPrecedes(
        theirUid: 'a',
        theirCreatedAt: t,
        myUid: 'b',
        myCreatedAt: t,
      );
      expect(
        aClaimsB != bClaimsA,
        isTrue,
        reason: 'exactly one direction may claim',
      );
    });

    test('a ticket never precedes itself', () {
      const t = '2026-08-09T10:00:00.000Z';
      expect(
        Matchmaking.ticketPrecedes(
          theirUid: 'a',
          theirCreatedAt: t,
          myUid: 'a',
          myCreatedAt: t,
        ),
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

  group('the lobby menu — no practice roster (ruling 2026-09-21)', () {
    testWidgets('the Practice vs AI section is gone', (tester) async {
      await _pumpLobby(tester);

      expect(
        find.byWidgetPredicate(
          (w) => w is SectionLabel && w.text == 'Practice vs AI',
        ),
        findsNothing,
        reason:
            'a _menu() that still builds the section header would put this '
            'SectionLabel in the tree — the label is what the ruling removed',
      );
      // ⚠️ SectionLabel UPPERCASES its text, so `find.text('Practice vs AI')`
      // would pass even with the section restored. Assert what is drawn.
      expect(
        find.text('PRACTICE VS AI'),
        findsNothing,
        reason:
            'the rendered heading — a widget-predicate-only check would miss '
            'a heading rebuilt as a plain Text instead of a SectionLabel',
      );
      expect(
        find.textContaining('AI'),
        findsNothing,
        reason:
            'the lobby must say "AI" NOWHERE player-facing (LADDER §1 law 3, '
            'now absolute) — any re-added heading, subtitle or hint that '
            'spells it out fails here',
      );
    });

    testWidgets('no persona is namable on the lobby', (tester) async {
      await _pumpLobby(tester);

      for (final persona in AiRoster.all) {
        expect(
          find.textContaining(persona.name),
          findsNothing,
          reason:
              'a restored roster row renders "${persona.name} · Lv '
              '${persona.level}" — checking EVERY persona (not just Wick and '
              'Brightgale) also kills a partial deletion that left one card '
              'behind',
        );
      }
    });

    testWidgets('Quick match and the room-code panels survive', (tester) async {
      await _pumpLobby(tester);

      expect(
        find.text('Quick match'),
        findsOneWidget,
        reason:
            'a deletion that took the rated queue with the roster would drop '
            'this panel — the ruling removed one section, not the lobby',
      );
      expect(
        find.text('FRIENDLY DUEL'),
        findsOneWidget,
        reason:
            'the room-code SectionLabel (uppercased, like the removed one '
            'was) must outlive it',
      );
      expect(
        find.text('Create a room code'),
        findsOneWidget,
        reason: 'hosting a room is untouched by the ruling',
      );
      expect(
        find.text('Join'),
        findsOneWidget,
        reason: 'the join-by-code button is untouched by the ruling',
      );
    });

    testWidgets('the account dialog promises the Academy, not practice', (
      tester,
    ) async {
      await _pumpLobby(tester);
      // No AuthScope above the screen → no uid → Quick match opens the
      // "Account needed" dialog instead of searching.
      await tester.tap(find.text('Quick match'));
      await tester.pumpAndSettle();

      expect(
        find.text('Account needed'),
        findsOneWidget,
        reason:
            'the rest of this test is vacuous unless the dialog actually '
            'opened — a uid-less Quick match must reach _needAccount',
      );
      expect(
        find.textContaining('Practice duels'),
        findsNothing,
        reason:
            'the old sentence promised a practice mode that no longer '
            'exists — leaving it would advertise a dead feature',
      );
      expect(
        find.textContaining('The Academy is open to guests'),
        findsOneWidget,
        reason:
            'the sentence must still name something that works WITHOUT an '
            'account — a reword that merely deleted the clause would leave '
            'the dialog a flat refusal',
      );
    });
  });

  /// The loading-screen tips (ruling 2026-09-21: ten more, twenty in all).
  ///
  /// ⭐ The picker is `microsecondsSinceEpoch % searchTips.length`, so the
  /// list's SHAPE is the whole contract: a short list narrows the rotation, a
  /// duplicated title wastes a slot, and an over-long body overruns the panel
  /// in the ~10s a search lasts.
  group('the loading-screen tips', () {
    test('there are twenty of them', () {
      expect(
        searchTips.length,
        20,
        reason:
            'ten shipped tips plus the ten from the 2026-09-21 ruling — a '
            'paste that dropped an entry, or one that duplicated the old '
            'list instead of extending it, lands on a different count',
      );
    });

    test('every title is distinct', () {
      final titles = searchTips.map((t) => t.title).toList();
      expect(
        titles.toSet().length,
        titles.length,
        reason:
            'the picker indexes blind, so a repeated title is a tip the '
            'player sees twice as often and a subject they never see — '
            'kills a copy-paste that duplicated a record and edited only '
            'its body',
      );
    });

    test('no body runs past 160 characters', () {
      for (final tip in searchTips) {
        expect(
          tip.body.length,
          lessThanOrEqualTo(160),
          reason:
              'the panel shows one tip for a ~10s wait: "${tip.title}" is '
              '${tip.body.length} characters — kills a mutant that pasted a '
              'paragraph of rules text in as a tip',
        );
      }
    });

    test('every title and body actually says something', () {
      for (final tip in searchTips) {
        expect(
          tip.title.trim(),
          isNotEmpty,
          reason: 'an empty title renders a bare bulb icon and no heading',
        );
        expect(
          tip.body.trim().length,
          greaterThan(20),
          reason:
              '"${tip.title}" — a placeholder or truncated body would still '
              'satisfy the length cap above, so pin the floor too',
        );
      }
    });

    test('the mechanic is called a DoT, never a burn', () {
      for (final tip in searchTips) {
        expect(
          tip.body.toLowerCase(),
          isNot(contains('burn')),
          reason:
              '"${tip.title}" — ruling 2026-09-21: "burn" is Ignite\'s word '
              'alone, and no tip is about Ignite. A tip written in the old '
              'vocabulary would teach the confusion the ruling removes',
        );
      }
    });
  });
}
