/// The home tab's XP card grows a second line for ladder ratings
/// (LADDER_DESIGN §7 item 5 / §8 item 6: the home tab, not only the
/// profile).
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a null rating rendered as blank instead of an em dash, and the
/// two ladders' numbers swapped or conflated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/tabs/home_tab.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

Future<void> _pumpHomeTab(WidgetTester tester, PlayerProfile profile) async {
  final game = GameState(_MemStorage(), profile);
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: game,
        child: Scaffold(body: HomeTab(onSelectTab: (_) {})),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'a geared rating with no Academy rating shows Ladder N · Academy —',
    (tester) async {
      final profile = PlayerProfile.newPlayer()
        ..ratingGeared = 1420
        ..ratingAcademy = null;

      await _pumpHomeTab(tester, profile);

      expect(
        find.text('Ladder 1420 · Academy —'),
        findsOneWidget,
        reason:
            'a card that only checks ratingGeared for null (or renders the '
            'em dash for BOTH fields whenever either is null) would print '
            'the wrong string here — ratingGeared must print its real '
            'number while ratingAcademy alone falls back to —',
      );
    },
  );

  testWidgets('a brand-new player (both ratings null) shows both dashes', (
    tester,
  ) async {
    final profile = PlayerProfile.newPlayer();
    expect(profile.ratingGeared, isNull);
    expect(profile.ratingAcademy, isNull);

    await _pumpHomeTab(tester, profile);

    expect(
      find.text('Ladder — · Academy —'),
      findsOneWidget,
      reason:
          'a card that only renders the ratings line when at least one '
          'rating exists would leave a brand-new player with no line at '
          'all — the row must always render (press-stability: constant '
          'card height) even at 0 rated games',
    );
  });

  testWidgets('both ratings present show both real numbers', (tester) async {
    final profile = PlayerProfile.newPlayer()
      ..ratingGeared = 1550
      ..ratingAcademy = 1200;

    await _pumpHomeTab(tester, profile);

    expect(
      find.text('Ladder 1550 · Academy 1200'),
      findsOneWidget,
      reason:
          'a card that swapped the ladder/academy fields would print '
          '"Ladder 1200 · Academy 1550" here instead',
    );
  });

  // ⭐ Ruling 2026-09-21: the daily/weekly goal cards were placeholders that
  // counted nothing, and the feature "will be implemented at a much later
  // date". They are gone from the tab — the section label with them, since a
  // 'Today' heading over nothing is worse than either.
  testWidgets('the Today goals section is gone, Continue stays', (
    tester,
  ) async {
    await _pumpHomeTab(tester, PlayerProfile.newPlayer());

    // ⚠️ UPPERCASE on purpose: `SectionLabel` renders `text.toUpperCase()`,
    // so asserting find.text('Today') would pass against a tab that still
    // shows the heading — a vacuous green.
    expect(
      find.text('TODAY'),
      findsNothing,
      reason:
          'a removal that deletes the two _QuestCards but leaves '
          "SectionLabel('Today') behind would strand an empty heading "
          'between the XP card and Continue',
    );
    expect(
      find.text('Win 3 duels'),
      findsNothing,
      reason:
          'the daily card itself — a mutant that only removes the weekly '
          "('Reach level 3') card still shows this one",
    );
    expect(
      find.text('Reach level 3'),
      findsNothing,
      reason:
          'the weekly card — the mirror mutant, removing only the daily one',
    );
    expect(
      find.textContaining('quest'),
      findsNothing,
      reason:
          "'Daily quest · reward 50 gold' / 'Weekly quest · unlocks a 2nd "
          "loadout' were the cards' sublines; a removal that kept a subline "
          '(or re-added the cards under new titles) fails here',
    );
    expect(
      find.text('CONTINUE'),
      findsOneWidget,
      reason:
          'the section BELOW the goals must survive — an over-eager deletion '
          'that took the Continue label with the Today one is the mutant '
          'this kills',
    );
  });

  // ⭐ Ruling 2026-09-21: Skills lives in the new Profile screen, which every
  // tab reaches from the header's name pill. The home tab's shortcut to it is
  // the duplicate, so it goes — but 'Continue' still has the map and loadout
  // cards under it, so the label stays.
  testWidgets('the Continue → Skills card is gone, the label stays', (
    tester,
  ) async {
    await _pumpHomeTab(tester, PlayerProfile.newPlayer());

    expect(
      find.text('Skills'),
      findsNothing,
      reason:
          'the card moved to the Profile — a tab that still lists it gives '
          'the same screen two doors, which is the drift this ruling closed',
    );
    expect(
      find.byIcon(Icons.handyman),
      findsNothing,
      reason:
          "the card's icon: a removal that deleted only the 'Skills' label "
          'would leave a tappable, wordless row behind',
    );
    expect(
      find.text('CONTINUE'),
      findsOneWidget,
      reason:
          'this is NOT the empty-heading case — the map and loadout cards '
          'still sit under Continue, so a removal that took the label with '
          'the card strands them under nothing',
    );
    expect(
      find.textContaining('Open the map to travel'),
      findsOneWidget,
      reason:
          'the card directly below the deleted one must survive — an '
          'over-eager deletion that swallowed its neighbour is the mutant '
          'this kills',
    );
  });
}
