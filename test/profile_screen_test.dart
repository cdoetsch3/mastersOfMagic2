/// The Profile screen and the header pill that opens it (ruling 2026-09-21,
/// mockup option A): the name/level line is a button on every tab, and what
/// it opens is the character's own screen — hero, ratings, one menu.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a pill that only looks tappable, a hero that drops a field, a
/// null rating rendered blank, rows in the wrong order, and a placeholder
/// wired to the wrong destination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/coming_soon_screen.dart';
import 'package:masters_of_magic_2/screens/gameplay_guide_screen.dart';
import 'package:masters_of_magic_2/screens/home_shell.dart';
import 'package:masters_of_magic_2/screens/profile_screen.dart';
import 'package:masters_of_magic_2/screens/skills_screen.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// ⚠️ The scope wraps the **MaterialApp**, not its home: the rows here push
/// routes (Skills reads [GameState]), and a scope below the Navigator would
/// be invisible to everything they push.
Future<void> _pump(WidgetTester tester, PlayerProfile profile, Widget home) {
  return tester.pumpWidget(
    GameStateScope(
      state: GameState(_MemStorage(), profile),
      child: MaterialApp(home: home),
    ),
  );
}

/// [width] narrows the header to a phone column — the size at which a long
/// name actually has to give way.
Future<void> _pumpHeader(
  WidgetTester tester,
  PlayerProfile profile, {
  double width = 400,
}) => _pump(
  tester,
  profile,
  Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: const PlayerHeader(title: 'Home'),
      ),
    ),
  ),
);

Future<void> _pumpProfile(WidgetTester tester, PlayerProfile profile) =>
    _pump(tester, profile, const ProfileScreen());

void main() {
  group('the header pill', () {
    testWidgets('tapping the name opens the Profile screen', (tester) async {
      final profile = PlayerProfile.newPlayer(name: 'Wilhelmina');
      await _pumpHeader(tester, profile);

      expect(find.byType(ProfileScreen), findsNothing);

      await tester.tap(find.text('Wilhelmina'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Profile'),
        findsOneWidget,
        reason:
            'the header line must be a BUTTON, not a caption — a pill that '
            'is styled like a control but has no onTap (or one wired to '
            'something other than ProfileScreen) leaves the tab exactly '
            'where it was, with no Profile AppBar on screen',
      );
    });

    testWidgets('the pill shows the name and the level', (tester) async {
      // 100 XP buys level 2 (xpToNext(1)); the other 30 sit inside it.
      final profile = PlayerProfile.newPlayer(name: 'Wilhelmina')..xp = 130;
      expect(profile.level, 2);

      await _pumpHeader(tester, profile);

      expect(
        find.text('Wilhelmina'),
        findsOneWidget,
        reason:
            'a pill that dropped the name for just the avatar initial would '
            'leave the player unable to read who they are playing',
      );
      expect(
        find.text('Lv 2'),
        findsOneWidget,
        reason:
            'the level still shows beside the name — a pill that kept only '
            'the name (or printed the raw XP total, 130, instead of the '
            'derived level) fails here',
      );
    });

    testWidgets('the header height is pinned whatever the name', (
      tester,
    ) async {
      await _pumpHeader(tester, PlayerProfile.newPlayer(name: 'Al'));
      final short = tester.getSize(find.byType(PlayerHeader)).height;

      // ⚠️ Phone width on purpose: this name has to be *too wide* for the
      // pill, or nothing is asked of the ellipsis.
      await _pumpHeader(
        tester,
        PlayerProfile.newPlayer(
          name: 'Bartholomew Ashgrove of the Long Vale III',
        ),
        width: 320,
      );
      final long = tester.getSize(find.byType(PlayerHeader)).height;

      expect(
        short,
        PlayerHeader.height,
        reason:
            'press-stability: a header that measures its own content grew '
            'when the plain text line became a pill, pushing every tab\'s '
            'first control down — the SizedBox that pins it is what this '
            'kills',
      );
      expect(
        long,
        short,
        reason:
            'a pill whose name Text can wrap (no Flexible / no ellipsis) '
            'makes a long name a second line and a taller header — the tab '
            'below would shift per character name',
      );
    });
  });

  group('the Profile hero', () {
    testWidgets('shows the name, the level line, and the XP totals', (
      tester,
    ) async {
      // 100 XP buys level 2 (xpToNext(1)); 30 of the 150 level-2 costs.
      final profile = PlayerProfile.newPlayer(name: 'Wilhelmina')..xp = 130;

      await _pumpProfile(tester, profile);

      expect(
        find.text('Wilhelmina'),
        findsOneWidget,
        reason:
            'a hero that renders only the avatar disc never names the '
            'character whose profile this is',
      );
      expect(
        find.text('Level 2 · 30 / 150 XP'),
        findsOneWidget,
        reason:
            'a hero that printed the cumulative xp (130) instead of '
            'xpIntoLevel, or xpForThisLevel from the wrong level (100, the '
            'level-1 cost), would print a different line here',
      );
    });

    testWidgets('a rating the character has not earned shows an em dash', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()
        ..ratingGeared = 1420
        ..ratingAcademy = null
        ..duelsWon = 7
        ..duelsLost = 3;

      await _pumpProfile(tester, profile);

      expect(
        find.text('Ladder 1420'),
        findsOneWidget,
        reason:
            'a chip row that falls back to the em dash for BOTH ratings '
            'whenever either is null would hide the real geared rating',
      );
      expect(
        find.text('Academy —'),
        findsOneWidget,
        reason:
            'an unrated Academy prints —, not a blank chip and not 0: 0 is a '
            'rating a player could hold, and a missing chip changes the '
            "row's layout the moment a first Academy match lands",
      );
      expect(
        find.text('Record 7–3'),
        findsOneWidget,
        reason:
            'the record chip — a row that swapped won/lost would print '
            '"Record 3–7" here',
      );
    });
  });

  group('the Profile menu', () {
    const rows = [
      'Skills',
      'Achievements',
      'Bestiary',
      'Item library',
      'How dueling works',
      'Account',
    ];

    testWidgets('has the six rows, top to bottom, in the ruled order', (
      tester,
    ) async {
      await _pumpProfile(tester, PlayerProfile.newPlayer());

      var previous = -1.0;
      for (final row in rows) {
        expect(
          find.text(row),
          findsOneWidget,
          reason:
              "'$row' is one of the six ruled rows — a menu missing it (or "
              'showing it twice) fails here',
        );
        final dy = tester.getTopLeft(find.text(row)).dy;
        expect(
          dy,
          greaterThan(previous),
          reason:
              "'$row' must sit below the row before it — a menu that lists "
              'the same six labels in any other order (e.g. Account or the '
              'rules above the placeholders) is what this kills',
        );
        previous = dy;
      }
    });

    testWidgets('the two library rows carry the dim placeholder count', (
      tester,
    ) async {
      await _pumpProfile(tester, PlayerProfile.newPlayer());

      expect(
        find.text('0 seen'),
        findsNWidgets(2),
        reason:
            'exactly the Bestiary and Item library rows show a trailing '
            'count — a row builder that put the trailing text on every row '
            '(6) or dropped it (0) fails here',
      );
    });

    testWidgets('Skills opens the existing Skills screen', (tester) async {
      await _pumpProfile(tester, PlayerProfile.newPlayer());

      await tester.tap(find.text('Skills'));
      await tester.pumpAndSettle();

      expect(
        find.byType(SkillsScreen),
        findsOneWidget,
        reason:
            'Skills moved here from the home tab and must still reach the '
            'real Ledger — a row wired to ComingSoonScreen like its '
            'neighbours would strand a screen that already exists',
      );
    });

    testWidgets('Bestiary opens the shared placeholder, titled Bestiary', (
      tester,
    ) async {
      await _pumpProfile(tester, PlayerProfile.newPlayer());

      await tester.tap(find.text('Bestiary'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is ComingSoonScreen && w.title == 'Bestiary',
        ),
        findsOneWidget,
        reason:
            'the placeholder must carry the row that opened it — a menu that '
            'passes a constant title (or Achievements\' title, the row '
            'above) lands the player on a screen naming somewhere else',
      );
      expect(
        find.text('Not built yet — it is on the list.'),
        findsOneWidget,
        reason:
            'the placeholder says so plainly; a blank body leaves the player '
            'wondering whether the screen failed to load',
      );
    });

    testWidgets('How dueling works opens the existing guide', (tester) async {
      await _pumpProfile(tester, PlayerProfile.newPlayer());

      await tester.tap(find.text('How dueling works'));
      await tester.pumpAndSettle();

      expect(
        find.byType(GameplayGuideScreen),
        findsOneWidget,
        reason:
            'the rules screen already exists — a row pointing at '
            'ComingSoonScreen would hide it behind a placeholder',
      );
    });
  });
}
