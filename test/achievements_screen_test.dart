/// The Achievements screen — the "Ledger" (ruling, Christian playtest
/// 2026-09-30 note 7, mockup A) — and the Profile row that opens it: a count
/// in the app bar, a summary, category chips and Hide earned, grouped rows
/// with a medal cell and, for counted entries, a bar.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — an unearned entry hidden, an earned one drawn dim, a filter that
/// filters nothing, a filter row that grows when pressed, a count that
/// counts nothing, and a row still wired to the placeholder.
///
/// 📝 The catalogue itself and granting are pinned in `achievements_test`;
/// rewards and claiming in `achievement_claim_test`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/achievements_screen.dart';
import 'package:masters_of_magic_2/screens/coming_soon_screen.dart';
import 'package:masters_of_magic_2/screens/level_up_screen.dart';
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

Future<void> _pump(
  WidgetTester tester,
  PlayerProfile profile,
  Widget home, {
  double width = 420,
}) async {
  // ⭐ Tall enough that every row is built — a ListView builds lazily, and a
  // row past the fold would read as "hidden" to find.text.
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GameStateScope(
      state: GameState(_Mem(), profile),
      child: MaterialApp(home: home),
    ),
  );
}

/// Taps a filter chip — scrolling the chip row to it first, as a thumb
/// would, since at phone width the last category sits past the fold.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byKey(AchievementsScreen.filterRowKey),
    matching: find.text(label),
  );
  await tester.ensureVisible(chip);
  await tester.pump();
  await tester.tap(chip);
  await tester.pump();
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

/// Every catalogue name on screen right now, in catalogue order.
List<String> _namesShown() => [
  for (final a in Achievements.all)
    if (find.text(a.name).evaluate().isNotEmpty) a.name,
];

List<String> _names(AchievementCategory c) => [
  for (final a in Achievements.inCategory(c)) a.name,
];

void main() {
  const name = 'Papers in Order';
  final total = Achievements.all.length;

  group('AchievementsScreen', () {
    testWidgets('⭐ unearned: listed, dim, no ✓', (tester) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );

      expect(
        _namesShown(),
        [for (final a in Achievements.all) a.name],
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
        find.byIcon(Icons.check),
        findsNothing,
        reason: 'kills a mutant that ticks what has not been earned',
      );
    });

    testWidgets('⭐ earned: text colour, a ✓ and the gold edge', (tester) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      await _pump(tester, profile, const AchievementsScreen());

      expect(
        _colorOf(tester, name),
        AppColors.text,
        reason: 'kills a mutant that leaves an earned entry dim',
      );
      expect(
        find.byIcon(Icons.check),
        findsOneWidget,
        reason: 'kills a mutant that forgets the ✓ on an earned entry',
      );
      final panel = tester.widget<GamePanel>(
        find.ancestor(of: find.text(name), matching: find.byType(GamePanel)),
      );
      expect(
        panel.borderColor,
        AppColors.gold,
        reason: "kills a mutant that drops the earned row's gold border",
      );
    });

    testWidgets('the name does not move when it is earned', (tester) async {
      // Press-stability's cousin: the medal cell is fixed, so the list does
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
        reason: 'kills a mutant that sizes the medal cell to its glyph',
      );

      // A counted entry loses its bar when earned, so its text shortens.
      final medal = find.byKey(AchievementRow.medalKey('tenfold'));
      final met = PlayerProfile.newPlayer()..duelsWon = 10;
      await _pump(tester, met, const AchievementsScreen());
      final barred = tester.getTopLeft(medal);
      final barredName = tester.getTopLeft(find.text('Tenfold'));
      await _pump(
        tester,
        met..achievements.add('tenfold'),
        const AchievementsScreen(),
      );
      expect(
        tester.getTopLeft(medal),
        barred,
        reason:
            'kills a vertically centred row — the medal would hop up as the '
            'bar leaves',
      );
      expect(
        tester.getTopLeft(find.text('Tenfold')),
        barredName,
        reason: 'the name stays put through the same change',
      );
    });

    testWidgets('⭐ the app-bar count and the summary', (tester) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'first_blood', 'gone'});
      await _pump(tester, profile, const AchievementsScreen());

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('2 / $total'),
        ),
        findsOneWidget,
        reason:
            'kills an app bar with no count, and one counting an id the '
            'catalogue does not know (3 / $total)',
      );
      expect(
        find.text('Earned'),
        findsOneWidget,
        reason: 'kills a summary panel with no heading',
      );
      expect(
        find.textContaining('of $total'),
        findsNothing,
        reason:
            'kills a summary that restates the pill\'s number — one number, '
            'said once',
      );
      expect(
        find.text('${200 ~/ total}%'),
        findsOneWidget,
        reason: 'kills a percent that rounds up, or is not there',
      );
    });

    testWidgets('a counted entry shows its count and a bar until earned', (
      tester,
    ) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer()..duelsWon = 3,
        const AchievementsScreen(),
      );
      expect(
        find.text('3/10'),
        findsOneWidget,
        reason:
            'kills a Tenfold row without its count beside the bar, and a '
            'second copy of it in the medal ring',
      );
      expect(
        find.descendant(
          of: find.byKey(AchievementRow.medalKey('tenfold')),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: 'kills a medal ring that still holds text',
      );
      final bar = find.descendant(
        of: find.ancestor(
          of: find.text('Tenfold'),
          matching: find.byType(AchievementRow),
        ),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(
        tester.widget<LinearProgressIndicator>(bar).value,
        closeTo(0.3, 1e-9),
        reason: 'kills a bar that does not follow the count',
      );

      final done = PlayerProfile.newPlayer()
        ..duelsWon = 10
        ..achievements.add('tenfold');
      await _pump(tester, done, const AchievementsScreen());
      expect(
        find.text('10/10'),
        findsNothing,
        reason: 'kills a count left on an earned entry — the ✓ says it',
      );
    });

    group('⭐ filters', () {
      testWidgets('All shows every section; a category shows only its own, '
          'without a heading', (tester) async {
        await _pump(
          tester,
          PlayerProfile.newPlayer(),
          const AchievementsScreen(),
        );
        for (final c in AchievementCategory.values) {
          final empty = Achievements.inCategory(c).isEmpty;
          expect(
            find.text(c.label.toUpperCase()),
            empty ? findsNothing : findsOneWidget,
            reason: empty
                ? 'kills a heading over a category with nothing in it yet'
                : 'kills an All view with no ${c.label} heading',
          );
        }

        await _tapChip(tester, 'Dueling');
        expect(
          _namesShown(),
          _names(AchievementCategory.duelling),
          reason:
              'kills a Duelling chip that filters nothing, or filters the '
              'wrong category',
        );
        expect(
          find.text('DUELLING'),
          findsNothing,
          reason: 'kills a heading repeated under its own chip',
        );

        await _tapChip(tester, 'Ladder');
        expect(
          _namesShown(),
          _names(AchievementCategory.ladder),
          reason: 'kills chips that combine instead of replacing — one lit',
        );

        await _tapChip(tester, 'All');
        expect(
          _namesShown().length,
          total,
          reason: 'kills an All chip that does not clear the filter',
        );
      });

      testWidgets('Hide earned hides Papers in Order, and only it', (
        tester,
      ) async {
        final profile = PlayerProfile.newPlayer()
          ..achievements.add('papers_in_order');
        await _pump(tester, profile, const AchievementsScreen());
        expect(find.text(name), findsOneWidget, reason: 'premise: shown');

        await _tapChip(tester, 'Hide earned');
        expect(
          find.text(name),
          findsNothing,
          reason: 'kills a Hide earned that hides nothing',
        );
        expect(
          _namesShown().length,
          total - 1,
          reason: 'kills a Hide earned that hides the unearned too',
        );

        await _tapChip(tester, 'Hide earned');
        expect(
          find.text(name),
          findsOneWidget,
          reason: 'kills a toggle that cannot be turned off',
        );
      });

      testWidgets('a section with nothing left loses its heading too', (
        tester,
      ) async {
        final profile = PlayerProfile.newPlayer()
          ..achievements.addAll(
            Achievements.inCategory(AchievementCategory.craft).map((a) => a.id),
          );
        await _pump(tester, profile, const AchievementsScreen());
        await _tapChip(tester, 'Hide earned');
        expect(
          find.text('CRAFT'),
          findsNothing,
          reason: 'kills a heading left over an empty section',
        );
        expect(
          find.text('CAMPAIGN'),
          findsOneWidget,
          reason: 'kills a mutant that drops every heading',
        );
      });

      testWidgets('Hide earned is in reach at the narrowest phone', (
        tester,
      ) async {
        await _pump(
          tester,
          PlayerProfile.newPlayer(),
          const AchievementsScreen(),
          width: 360,
        );
        final hide = tester.getRect(find.text('Hide earned'));
        expect(
          hide.right,
          lessThanOrEqualTo(360),
          reason:
              'kills a toggle scrolled along with the categories — at phone '
              'width it would sit past the fold, unfound',
        );
        expect(
          tester.getSize(find.byKey(AchievementsScreen.filterRowKey)).height,
          AchievementsScreen.filterRowHeight,
          reason: 'kills a row that wraps taller when it runs out of width',
        );
      });

      testWidgets('⭐ everything hidden: the one empty line', (tester) async {
        final profile = PlayerProfile.newPlayer()
          ..achievements.addAll(
            Achievements.inCategory(
              AchievementCategory.ladder,
            ).map((a) => a.id),
          );
        await _pump(tester, profile, const AchievementsScreen());
        expect(
          find.text(AchievementsScreen.emptyLine),
          findsNothing,
          reason: 'kills an empty line shown over a full list',
        );

        await _tapChip(tester, 'Ladder');
        await _tapChip(tester, 'Hide earned');
        expect(
          _namesShown(),
          isEmpty,
          reason: 'premise: every Ladder entry is earned and hidden',
        );
        expect(
          find.text('Nothing left in this view.'),
          findsOneWidget,
          reason: 'kills a blank view with nothing said',
        );
      });

      testWidgets('⭐ press-stable: the filter row never changes size, and '
          'no chip moves', (tester) async {
        // Wide, so no chip needs scrolling to and any move is the layout's.
        await _pump(
          tester,
          PlayerProfile.newPlayer(),
          const AchievementsScreen(),
          width: 1000,
        );
        final row = find.byKey(AchievementsScreen.filterRowKey);
        // ⚠️ The whole chip, not its text: the pinned toggle is
        // right-aligned, so a chip growing leftward leaves its text put.
        Rect chip(String label) => tester.getRect(
          find
              .ancestor(
                of: find.descendant(of: row, matching: find.text(label)),
                matching: find.byType(InkWell),
              )
              .first,
        );
        final before = tester.getRect(row);
        final hide = chip('Hide earned');
        final ladder = chip('Ladder');
        final firstRow = tester.getTopLeft(find.text(name));

        await _tapChip(tester, 'Craft');
        await _tapChip(tester, 'Hide earned');

        expect(
          tester.getRect(row),
          before,
          reason:
              'kills a filter row that sizes to its content — a lit chip or '
              'a wrapped label would push the list down',
        );
        expect(
          before.height,
          AchievementsScreen.filterRowHeight,
          reason: 'kills a filter row with no fixed height',
        );
        expect(
          chip('Hide earned'),
          hide,
          reason: 'kills a toggle whose icon appears only when lit',
        );
        expect(
          chip('Ladder'),
          ladder,
          reason: 'kills a lit chip that grows and shoves its neighbours',
        );

        await _tapChip(tester, 'Hide earned');
        await _tapChip(tester, 'All');
        expect(
          tester.getTopLeft(find.text(name)),
          firstRow,
          reason: 'kills a list that does not come back to where it was',
        );
      });
    });
  });

  group('⭐ Claim (ruling 2026-10-01)', () {
    Finder claimIn(String id) => find.descendant(
      of: find.byKey(AchievementRow.claimCellKey(id)),
      matching: find.text(AchievementsScreen.claimLabel),
    );

    testWidgets('an earned, unclaimed row offers Claim; pressing it pays', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'first_blood'})
        ..claimedAchievements.add('first_blood');
      await _pump(tester, profile, const AchievementsScreen());

      expect(
        claimIn('papers_in_order'),
        findsOneWidget,
        reason: 'kills an earned, unclaimed row with no Claim',
      );
      expect(
        claimIn('first_blood'),
        findsNothing,
        reason: 'kills a Claim left on a row already paid',
      );
      expect(
        claimIn('tenfold'),
        findsNothing,
        reason: 'kills a Claim on a row not yet earned',
      );

      await tester.tap(claimIn('papers_in_order'));
      await tester.pump();
      expect(
        profile.claimedAchievements,
        contains('papers_in_order'),
        reason: 'kills a Claim button wired to nothing',
      );
      expect(
        claimIn('papers_in_order'),
        findsNothing,
        reason: 'kills a Claim that stays after paying',
      );
    });

    testWidgets('⭐ press-stable: the claim cell is on every row, one width', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      await _pump(tester, profile, const AchievementsScreen());
      final cell = find.byKey(AchievementRow.claimCellKey('papers_in_order'));
      final before = tester.getRect(cell);
      final nameAt = tester.getTopLeft(find.text(name));
      final width = tester
          .getSize(find.byKey(AchievementRow.claimCellKey('tenfold')))
          .width;

      await tester.tap(claimIn('papers_in_order'));
      await tester.pump();

      expect(
        tester.getRect(cell),
        before,
        reason:
            'kills a claim cell that collapses once paid — the button '
            'pressed would take its row with it',
      );
      expect(
        tester.getTopLeft(find.text(name)),
        nameAt,
        reason: 'kills a row that re-lays its text when Claim leaves',
      );
      expect(
        width,
        AchievementRow.claimCellWidth,
        reason:
            'kills a cell reserved only on claimable rows — the text column '
            'would run wider on some rows than others',
      );
    });

    testWidgets('⭐ Claim all and the total points, in the summary', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.addAll({'first_blood', 'tenfold', 'centurion'})
        ..claimedAchievements.add('tenfold');
      await _pump(tester, profile, const AchievementsScreen());

      expect(
        find.text('40 points'),
        findsOneWidget,
        reason: 'kills a summary with no total, or one over claimed only',
      );
      expect(
        find.byKey(AchievementsScreen.claimAllKey),
        findsOneWidget,
        reason: 'kills a summary with no Claim all while rewards wait',
      );
      final firstRow = tester.getTopLeft(find.text(name));

      await tester.tap(find.text(AchievementsScreen.claimAllLabel));
      await tester.pump();

      expect(profile.claimedAchievements, {
        'tenfold',
        'first_blood',
        'centurion',
      }, reason: 'kills a Claim all wired to nothing, or to one entry');
      expect(
        find.byKey(AchievementsScreen.claimAllKey),
        findsNothing,
        reason: 'kills a Claim all still offered with nothing to claim',
      );
      expect(
        find.text(AchievementsScreen.claimLabel),
        findsNothing,
        reason: 'kills a row Claim that survives Claim all',
      );
      expect(
        tester.getTopLeft(find.text(name)),
        firstRow,
        reason:
            'kills a claim row that collapses when Claim all leaves — the '
            'whole list would jump up',
      );
    });

    testWidgets('no Claim all when nothing waits', (tester) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );
      expect(
        find.byKey(AchievementsScreen.claimAllKey),
        findsNothing,
        reason: 'kills a Claim all drawn over an empty pile',
      );
      expect(
        find.text('0 points'),
        findsOneWidget,
        reason: 'kills a total hidden at zero',
      );
    });

    testWidgets('⭐ every row prints its reward line', (tester) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );
      int count(int points) =>
          Achievements.all.where((a) => a.points == points).length;
      expect(
        find.text('+100 XP · +50 gold'),
        findsNWidgets(count(5)),
        reason: 'kills a 5-point row without its line, or with RP on it',
      );
      expect(
        find.text('+250 XP · +150 gold'),
        findsNWidgets(count(10)),
        reason: 'kills a 10-point row without its line',
      );
      expect(
        find.text('+750 XP · +500 gold · +1 RP'),
        findsNWidgets(count(25)),
        reason: 'kills a 25-point line that drops its RP',
      );
    });

    test('the copy: reward lines group thousands; points read as points', () {
      expect(
        rewardLabel(Reward.forPoints(100)),
        '+5,000 XP · +5,000 gold · +25 RP',
        reason: 'kills a line printing 5000 where §6 writes 5,000',
      );
      expect(
        rewardLabel(Reward.forPoints(10)),
        '+250 XP · +150 gold',
        reason: 'kills an RP clause printed as +0 RP',
      );
      expect(
        pointsLabel(1240),
        '1,240 points',
        reason: 'kills a total without its thousands comma',
      );
    });

    testWidgets('⭐ a hidden entry is ??? until earned — no blurb', (
      tester,
    ) async {
      const secret = AchievementDef(
        id: 'zz_secret',
        name: 'The Quiet Door',
        blurb: 'Found what nobody looks for.',
        category: AchievementCategory.world,
        points: 25,
        hidden: true,
      );
      Future<void> row({required bool earned}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementRow(def: secret, earned: earned),
          ),
        ),
      );

      await row(earned: false);
      expect(
        find.text(AchievementRow.hiddenName),
        findsOneWidget,
        reason: 'kills a hidden entry that prints its name unearned',
      );
      expect(
        find.text(secret.name),
        findsNothing,
        reason: 'kills the spoiler: the name shown before it is earned',
      );
      expect(
        find.text(secret.blurb),
        findsNothing,
        reason: 'kills the spoiler: the blurb shown before it is earned',
      );

      await row(earned: true);
      expect(
        [
          find.text(secret.name).evaluate().length,
          find.text(secret.blurb).evaluate().length,
          find.text(AchievementRow.hiddenName).evaluate().length,
        ],
        [1, 1, 0],
        reason: 'kills a hidden entry that stays veiled once earned',
      );
    });

    testWidgets('a claim that crosses a level shows the level-up', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()..achievements.add('tenfold');
      await _pump(tester, profile, const AchievementsScreen());
      await tester.tap(claimIn('tenfold'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byType(LevelUpScreen),
        findsOneWidget,
        reason:
            'kills a claim whose level-up waits, unseen, for the next duel '
            'to surface it',
      );
    });
  });

  group('the Profile row', () {
    testWidgets('⭐ n to claim while rewards wait', (tester) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'first_blood', 'tenfold'})
        ..claimedAchievements.add('tenfold');
      await _pump(tester, profile, const ProfileScreen());
      expect(
        find.text('2 to claim'),
        findsOneWidget,
        reason:
            'kills a row that still reads n / N while rewards wait, and one '
            'that counts the claimed (3) or the earned',
      );
      expect(
        achievementProfileTrailing(
          profile
            ..claimedAchievements.addAll({'papers_in_order', 'first_blood'}),
        ),
        '3 / $total',
        reason: 'kills a row stuck on "0 to claim" once all is claimed',
      );
    });

    testWidgets('⭐ counts n / N off the profile', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const ProfileScreen());
      expect(
        find.text('0 / $total'),
        findsOneWidget,
        reason: 'kills a row with no count, or a count of something else',
      );

      // Claimed, so the row is back to its count (see 'n to claim' below).
      final earned = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'retired_or_future_id'})
        ..claimedAchievements.add('papers_in_order');
      await _pump(tester, earned, const ProfileScreen());
      expect(
        find.text('1 / $total'),
        findsOneWidget,
        reason:
            'kills a count that ignores the profile, and one that counts an '
            'id the catalogue does not know (2 / $total)',
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
