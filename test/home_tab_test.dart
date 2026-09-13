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
}
