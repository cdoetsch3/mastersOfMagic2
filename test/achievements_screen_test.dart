/// The Achievements screen and the Profile row that opens it (ruling,
/// Christian 2026-09-25): every catalogue entry listed, earned in text colour
/// with a ✓, unearned dim; the row counts 'n / N'.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — an unearned entry hidden, an earned one drawn dim, a count that
/// counts nothing, and a row still wired to the placeholder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/achievements_screen.dart';
import 'package:masters_of_magic_2/screens/coming_soon_screen.dart';
import 'package:masters_of_magic_2/screens/profile_screen.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

Future<void> _pump(WidgetTester tester, PlayerProfile profile, Widget home) =>
    tester.pumpWidget(
      GameStateScope(
        state: GameState(_Mem(), profile),
        child: MaterialApp(home: home),
      ),
    );

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  const name = 'Papers in Order';

  test('the catalogue: one entry, as ruled', () {
    expect(Achievements.all.map((a) => a.id), [
      'papers_in_order',
    ], reason: 'kills a catalogue that grew, or lost, an entry unruled');
    expect(
      Achievements.papersInOrder.blurb,
      'Pennycross unlocked. The proofs stay with the guard.',
      reason: 'the ruled blurb, verbatim',
    );
  });

  group('AchievementsScreen', () {
    testWidgets('⭐ unearned: listed, dim, no ✓', (tester) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );

      expect(
        find.text(name),
        findsOneWidget,
        reason:
            'kills a screen that hides what is not earned yet — the list '
            'says what there is to do',
      );
      expect(
        _colorOf(tester, name),
        AppColors.textFaint,
        reason: 'kills a mutant that draws an unearned entry as earned',
      );
      expect(
        find.byIcon(Icons.check_circle),
        findsNothing,
        reason: 'kills a mutant that ticks what has not been earned',
      );
    });

    testWidgets('⭐ earned: text colour and a ✓', (tester) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      await _pump(tester, profile, const AchievementsScreen());

      expect(
        _colorOf(tester, name),
        AppColors.text,
        reason: 'kills a mutant that leaves an earned entry dim',
      );
      expect(
        find.byIcon(Icons.check_circle),
        findsOneWidget,
        reason: 'kills a mutant that forgets the ✓ on an earned entry',
      );
    });

    testWidgets('the name does not move when it is earned', (tester) async {
      // Press-stability's cousin: the icon cell is fixed, so the list does
      // not re-lay the day an entry is earned.
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );
      final dim = tester.getTopLeft(find.text(name));

      final earned = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      await _pump(tester, earned, const AchievementsScreen());

      expect(
        tester.getTopLeft(find.text(name)),
        dim,
        reason: 'kills a mutant that sizes the icon cell to its glyph',
      );
    });
  });

  group('the Profile row', () {
    testWidgets('⭐ counts n / N off the profile', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const ProfileScreen());
      expect(
        find.text('0 / 1'),
        findsOneWidget,
        reason: 'kills a row with no count, or a count of something else',
      );

      final earned = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'retired_or_future_id'});
      await _pump(tester, earned, const ProfileScreen());
      expect(
        find.text('1 / 1'),
        findsOneWidget,
        reason:
            'kills a count that ignores the profile, and one that counts an '
            'id the catalogue does not know (2 / 1)',
      );
    });

    testWidgets('opens the real screen, not the placeholder', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const ProfileScreen());

      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      expect(
        find.byType(AchievementsScreen),
        findsOneWidget,
        reason: 'kills a row still wired to ComingSoonScreen',
      );
      expect(
        find.byType(ComingSoonScreen),
        findsNothing,
        reason: 'the placeholder is gone for this row',
      );
    });
  });
}
