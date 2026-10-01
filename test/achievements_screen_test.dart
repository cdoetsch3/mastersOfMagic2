/// The Achievements screen — the "Ledger" (ACHIEVEMENTS §7.2, mockup A, with
/// Christian's filters and the 2026-10-01 Claim ruling) — and the Profile
/// row that opens it.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — a family drawn as one row per tier, a Claim that pays the top
/// tier first, a To claim view that drops a row as it is paid, a Claim all
/// that leaves its cell, a count of rows where entries were meant.
///
/// ⭐ **Mostly a synthetic catalogue** ([_catalogue], handed to the screen's
/// `catalogue`): the real one grows by ~160 entries and gains its families
/// in parallel, and a test pinned to its size or order would break on every
/// entry added. Claims against it go through [_Game], which pays from the
/// synthetic list the way `GameState` pays from the real one. The tests on
/// the real catalogue touch only Papers in Order — the first row there is —
/// and the real claim wiring.
///
/// 📝 `rowsFor`'s laws are pinned in `achievement_families_test`; the
/// catalogue and granting in `achievements_test`; paying in
/// `achievement_claim_test`.
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
import 'package:masters_of_magic_2/ui/app_banner.dart';
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

// ---- the synthetic catalogue -----------------------------------------------

AchievementProgress _gold(PlayerProfile p, int total) =>
    (done: p.goldEarned < total ? p.goldEarned : total, total: total);

AchievementDef _pyro(int tier, String numeral, int goal, int points) =>
    AchievementDef(
      id: 'pyro_$tier',
      name: 'Pyro Mastery $numeral',
      blurb: 'Pyro charged ${goal}x.',
      category: AchievementCategory.mastery,
      points: points,
      family: 'pyro',
      tier: tier,
      progress: (p) => _gold(p, goal),
    );

/// 25 points — pays 750 XP · 500 gold · 1 RP.
const _gate = AchievementDef(
  id: 'gate',
  name: 'The Gate',
  blurb: 'A gate opened.',
  category: AchievementCategory.campaign,
  points: 25,
);

final _roads = AchievementDef(
  id: 'roads',
  name: 'Roads',
  blurb: 'Ten duels won.',
  category: AchievementCategory.campaign,
  points: 10,
  progress: (p) => (done: p.duelsWon < 10 ? p.duelsWon : 10, total: 10),
);

const _quiet = AchievementDef(
  id: 'quiet',
  name: 'The Quiet Door',
  blurb: 'Found what nobody looks for.',
  category: AchievementCategory.world,
  points: 5,
  hidden: true,
);

/// Six entries, four rows: Campaign (gate, roads), Mastery (one 3-tier
/// family, 5 / 10 / 25 points at 1,000 / 5,000 / 10,000), World (one hidden).
final _catalogue = <AchievementDef>[
  _gate,
  _roads,
  _pyro(1, 'I', 1000, 5),
  _pyro(2, 'II', 5000, 10),
  _pyro(3, 'III', 10000, 25),
  _quiet,
];

/// A [GameState] that claims from [_catalogue] — what the real one does with
/// `Achievements.all` — and logs every id a row asked it to pay.
class _Game extends GameState {
  _Game(PlayerProfile profile) : super(_Mem(), profile);

  final claims = <String>[];

  @override
  Future<bool> claimAchievement(String id) async {
    claims.add(id);
    profile.claimedAchievements.add(id);
    notifyListeners();
    return true;
  }

  @override
  Future<AchievementReward> claimAllAchievements() async {
    final due = [
      for (final a in _catalogue)
        if (profile.achievements.contains(a.id) &&
            !profile.claimedAchievements.contains(a.id))
          a,
    ];
    claims.addAll(due.map((a) => a.id));
    profile.claimedAchievements.addAll(due.map((a) => a.id));
    notifyListeners();
    return Reward.sum(due.map((a) => a.reward));
  }
}

PlayerProfile _profile({
  int goldEarned = 0,
  int wins = 0,
  Set<String> earned = const {},
  Set<String> claimed = const {},
}) => PlayerProfile.newPlayer()
  ..goldEarned = goldEarned
  ..duelsWon = wins
  ..achievements.addAll(earned)
  ..claimedAchievements.addAll(claimed);

void _size(WidgetTester tester, double width) {
  // ⭐ Tall enough that every row is built — a ListView builds lazily, and a
  // row past the fold would read as "hidden" to find.text.
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The screen over [_catalogue], on a [_Game].
Future<_Game> _pumpSyn(
  WidgetTester tester,
  PlayerProfile profile, {
  double width = 420,
}) async {
  _size(tester, width);
  final game = _Game(profile);
  await tester.pumpWidget(
    GameStateScope(
      state: game,
      child: MaterialApp(home: AchievementsScreen(catalogue: _catalogue)),
    ),
  );
  return game;
}

/// [home] over the real catalogue and a real [GameState].
Future<void> _pump(
  WidgetTester tester,
  PlayerProfile profile,
  Widget home, {
  double width = 420,
}) async {
  _size(tester, width);
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

/// The whole chip [label] in the filter row, not just its text.
Rect _chip(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(
        of: find.descendant(
          of: find.byKey(AchievementsScreen.filterRowKey),
          matching: find.text(label),
        ),
        matching: find.byType(InkWell),
      )
      .first,
);

/// The keys of the rows on screen, top to bottom.
List<String> _rowKeys(WidgetTester tester) => [
  for (final e in find.byType(AchievementRow).evaluate())
    (e.widget as AchievementRow).row.key,
];

Finder _inRow(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey('row-$key')), matching: matching);

Finder _claimIn(String key) => find.descendant(
  of: find.byKey(AchievementRow.claimCellKey(key)),
  matching: find.text(AchievementsScreen.claimLabel),
);

Color? _colorOf(WidgetTester tester, Finder text) =>
    tester.widget<Text>(text).style?.color;

void main() {
  group('⭐ families collapse', () {
    testWidgets('a family is one row, at tier I while nothing is earned', (
      tester,
    ) async {
      await _pumpSyn(tester, _profile(goldEarned: 300));
      expect(
        _rowKeys(tester),
        ['gate', 'roads', 'pyro', 'quiet'],
        reason:
            'kills a list with one row per tier (six rows), and one that '
            'loses the family altogether',
      );
      expect(
        [
          find.text('Pyro Mastery I').evaluate().length,
          find.text('Pyro Mastery II').evaluate().length,
          find.text('Pyro Mastery III').evaluate().length,
        ],
        [1, 0, 0],
        reason: 'kills a family row named after a tier not reached',
      );
      expect(
        _inRow('pyro', find.text('300 / 1,000')),
        findsOneWidget,
        reason: 'kills a family row without its progress toward tier I',
      );
    });

    testWidgets('at its highest earned tier, counting toward the next', (
      tester,
    ) async {
      await _pumpSyn(
        tester,
        _profile(goldEarned: 4800, earned: {'pyro_1'}, claimed: {'pyro_1'}),
      );
      expect(
        _inRow('pyro', find.text('Pyro Mastery I')),
        findsOneWidget,
        reason: 'kills a row that jumps to the tier being worked toward',
      );
      expect(
        _inRow('pyro', find.text('4,800 / 5,000')),
        findsOneWidget,
        reason:
            'kills a family row that drops its bar once a tier is earned — '
            'the next tier is still something to do — and an ungrouped count',
      );
      expect(
        find.descendant(
          of: find.byKey(AchievementRow.claimCellKey('pyro')),
          matching: find.text(AchievementsScreen.claimedLabel),
        ),
        findsOneWidget,
        reason: 'kills a paid row with an empty cell where Claimed belongs',
      );
    });

    testWidgets('⭐ Claim on a family row pays the lowest unclaimed tier', (
      tester,
    ) async {
      final game = await _pumpSyn(
        tester,
        _profile(goldEarned: 5200, earned: {'pyro_1', 'pyro_2'}),
      );
      expect(
        _inRow('pyro', find.text('Pyro Mastery II')),
        findsOneWidget,
        reason: 'premise: the row is named after the highest earned tier',
      );
      expect(
        _inRow('pyro', find.text('+100 XP · +50 gold')),
        findsOneWidget,
        reason:
            "kills a reward line that prints tier II's reward while Claim "
            "would pay tier I's",
      );

      await tester.tap(_claimIn('pyro'));
      await tester.pump();
      expect(
        game.claims,
        ['pyro_1'],
        reason:
            'kills a Claim that pays the highest tier first, and one that '
            'pays the whole family at once',
      );
      expect(
        _inRow('pyro', find.text('+250 XP · +150 gold')),
        findsOneWidget,
        reason: 'kills a line that does not move on to the tier now waiting',
      );

      await tester.tap(_claimIn('pyro'));
      await tester.pump();
      expect(game.claims, [
        'pyro_1',
        'pyro_2',
      ], reason: 'kills a Claim that pays tier I twice');
      expect(
        _claimIn('pyro'),
        findsNothing,
        reason: 'kills a Claim left on a family with nothing owed',
      );
    });
  });

  group('rows', () {
    testWidgets('⭐ the three medals', (tester) async {
      await _pumpSyn(
        tester,
        _profile(
          goldEarned: 1000,
          earned: {'gate', 'pyro_1'},
          claimed: {'pyro_1'},
        ),
      );
      Finder icon(String key) => find.descendant(
        of: find.byKey(AchievementRow.medalKey(key)),
        matching: find.byIcon(Icons.check),
      );
      expect(
        tester.widget<Icon>(icon('gate')).color,
        AppColors.gold,
        reason:
            'kills a waiting medal drawn as paid — a gold ✓ in a ring, not '
            'on solid gold',
      );
      expect(
        tester.widget<Icon>(icon('pyro')).color,
        AppColors.bg,
        reason: 'kills a paid medal drawn as waiting',
      );
      expect(
        icon('roads'),
        findsNothing,
        reason: 'kills a ✓ on what has not been earned',
      );
      expect(
        find.descendant(
          of: find.byKey(AchievementRow.medalKey('roads')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
        reason: 'kills an unearned medal without its dashed ring',
      );
    });

    testWidgets('earned text is bright and gold-edged; unearned is dim', (
      tester,
    ) async {
      await _pumpSyn(tester, _profile(earned: {'gate'}));
      expect(
        [
          _colorOf(tester, find.text('The Gate')),
          _colorOf(tester, find.text('Roads')),
        ],
        [AppColors.text, AppColors.textFaint],
        reason: 'kills an earned name left dim, or an unearned one lit',
      );
      expect(
        tester
            .widget<GamePanel>(
              find.ancestor(
                of: find.text('The Gate'),
                matching: find.byType(GamePanel),
              ),
            )
            .borderColor,
        AppColors.gold,
        reason: "kills a mutant that drops the earned row's gold border",
      );
    });

    testWidgets('a counted one-shot loses its bar once earned', (tester) async {
      await _pumpSyn(tester, _profile(wins: 3));
      expect(
        _inRow('roads', find.text('3 / 10')),
        findsOneWidget,
        reason: 'kills a counted row without its count',
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              _inRow('roads', find.byType(LinearProgressIndicator)),
            )
            .value,
        closeTo(0.3, 1e-9),
        reason: 'kills a bar that does not follow the count',
      );
      expect(
        find.descendant(
          of: find.byKey(AchievementRow.medalKey('roads')),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: 'kills a medal ring that holds the count a second time',
      );

      await _pumpSyn(tester, _profile(wins: 10, earned: {'roads'}));
      expect(
        _inRow('roads', find.byType(LinearProgressIndicator)),
        findsNothing,
        reason: 'kills a bar left on an earned one-shot — the ✓ says it',
      );
    });

    testWidgets('⭐ a hidden entry is ??? until earned — no blurb', (
      tester,
    ) async {
      await _pumpSyn(tester, _profile());
      expect(
        _inRow('quiet', find.text(AchievementRow.hiddenName)),
        findsOneWidget,
        reason: 'kills a hidden entry that prints its name unearned',
      );
      expect(
        [
          find.text(_quiet.name).evaluate().length,
          find.text(_quiet.blurb).evaluate().length,
        ],
        [0, 0],
        reason: 'kills the spoiler: the name or blurb shown unearned',
      );
      expect(
        _inRow('quiet', find.text('+100 XP · +50 gold')),
        findsOneWidget,
        reason: 'kills a veil that hides the reward too — that is no spoiler',
      );

      await _pumpSyn(tester, _profile(earned: {'quiet'}));
      expect(
        [
          find.text(_quiet.name).evaluate().length,
          find.text(_quiet.blurb).evaluate().length,
          find.text(AchievementRow.hiddenName).evaluate().length,
        ],
        [1, 1, 0],
        reason: 'kills a hidden entry that stays veiled once earned',
      );
    });

    testWidgets('the name does not move when it is earned', (tester) async {
      await _pumpSyn(tester, _profile());
      final dim = tester.getTopLeft(find.text('The Gate'));
      final medal = find.byKey(AchievementRow.medalKey('roads'));
      final barred = tester.getTopLeft(medal);

      await _pumpSyn(
        tester,
        _profile(wins: 10, earned: {'gate', 'roads'}, claimed: {'gate'}),
      );
      expect(
        tester.getTopLeft(find.text('The Gate')),
        dim,
        reason: 'kills a mutant that sizes the medal cell to its glyph',
      );
      expect(
        tester.getTopLeft(medal),
        barred,
        reason:
            'kills a vertically centred row — the medal would hop up as the '
            'bar leaves',
      );
    });
  });

  group('⭐ the header', () {
    testWidgets('points in the pill; earned / total in the summary — tiers, '
        'not rows', (tester) async {
      await _pumpSyn(
        tester,
        _profile(
          goldEarned: 5000,
          earned: {'gate', 'pyro_1', 'pyro_2', 'gone'},
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('40 points'),
        ),
        findsOneWidget,
        reason:
            'kills an app bar without the points, and points summed over '
            'claimed only (0), or over an id the catalogue does not know',
      );
      expect(
        find.text('3 / 6'),
        findsOneWidget,
        reason:
            'kills a summary counting rows (2 / 4), or counting an unknown '
            'id (4 / 6)',
      );
      expect(
        find.text(AchievementsScreen.earnedLabel),
        findsOneWidget,
        reason: 'kills a summary count with nothing to say what it counts',
      );
      expect(
        find.textContaining('%'),
        findsNothing,
        reason: 'kills a percent beside the count — the same ratio, twice',
      );
    });

    testWidgets('⭐ section headings count entries in the whole category', (
      tester,
    ) async {
      await _pumpSyn(
        tester,
        _profile(goldEarned: 1000, earned: {'gate', 'pyro_1'}),
      );
      expect(
        [
          find.text('Campaign · 1 / 2').evaluate().length,
          find.text('Mastery · 1 / 3').evaluate().length,
          find.text('World · 0 / 1').evaluate().length,
        ],
        [1, 1, 1],
        reason:
            'kills a heading without its count, and Mastery counted in rows '
            '(1 / 1)',
      );

      // The Gate is finished and hidden; Roads is left in Campaign.
      await _tapChip(tester, 'Hide earned');
      expect(
        [
          find.text('Campaign · 1 / 2').evaluate().length,
          find.text('Mastery · 1 / 3').evaluate().length,
        ],
        [1, 1],
        reason:
            'kills a count over the rows the filters left (Campaign · 0 / 1) '
            '— the section still holds two',
      );
    });

    testWidgets('⭐ Claim all pays, says what it paid, and stays put — dim', (
      tester,
    ) async {
      final game = await _pumpSyn(
        tester,
        _profile(goldEarned: 5000, earned: {'gate', 'pyro_1', 'pyro_2'}),
      );
      final button = find.byKey(AchievementsScreen.claimAllKey);
      final before = tester.getRect(button);
      final firstRow = tester.getTopLeft(find.text('The Gate'));
      expect(
        find.text('+1,100 XP · +700 gold · +1 RP'),
        findsOneWidget,
        reason: 'kills a summary that does not say what Claim all would pay',
      );

      await tester.tap(button);
      await tester.pump();

      expect(game.claims.toSet(), {
        'gate',
        'pyro_1',
        'pyro_2',
      }, reason: 'kills a Claim all wired to nothing, or to one entry');
      expect(
        find.text('Claimed +1,100 XP · +700 gold · +1 RP'),
        findsOneWidget,
        reason:
            'kills a Claim all that pays in silence, or a banner that does '
            'not sum the tiers it paid',
      );
      expect(
        tester.getRect(button),
        before,
        reason:
            'kills a Claim all that leaves its cell once nothing waits — the '
            'whole list would jump',
      );
      expect(
        tester.getTopLeft(find.text('The Gate')),
        firstRow,
        reason: 'kills a summary that shrinks when its reward line empties',
      );
      expect(
        _colorOf(tester, find.text(AchievementsScreen.claimAllLabel)),
        AppColors.textFaint,
        reason: 'kills a Claim all still lit with nothing to claim',
      );
      expect(
        find.text(AchievementsScreen.claimLabel),
        findsNothing,
        reason: 'kills a row Claim that survives Claim all',
      );

      await tester.tap(button);
      await tester.pump();
      expect(
        game.claims.length,
        3,
        reason: 'kills a dim Claim all that still fires',
      );
      await tester.pump(kAppBannerHold + kAppBannerFade * 2);
    });
  });

  group('⭐ filters', () {
    testWidgets('a chip per category with entries; one lit at a time, no '
        'heading under it', (tester) async {
      await _pumpSyn(tester, _profile());
      expect(
        [
          for (final c in AchievementCategory.values)
            find
                .descendant(
                  of: find.byKey(AchievementsScreen.filterRowKey),
                  matching: find.text(c.label),
                )
                .evaluate()
                .length,
        ],
        [1, 1, 0, 0, 1, 0, 0],
        reason:
            'kills a chip over a category with nothing in it, and a missing '
            'chip for one that has',
      );

      await _tapChip(tester, 'Mastery');
      expect(_rowKeys(tester), [
        'pyro',
      ], reason: 'kills a chip that filters nothing, or the wrong category');
      expect(
        find.textContaining('Mastery ·'),
        findsNothing,
        reason: 'kills a heading repeated under its own chip',
      );

      await _tapChip(tester, 'World');
      expect(_rowKeys(tester), [
        'quiet',
      ], reason: 'kills chips that combine instead of replacing');

      await _tapChip(tester, AchievementsScreen.allLabel);
      expect(
        _rowKeys(tester).length,
        4,
        reason: 'kills an All chip that does not clear the filter',
      );
    });

    testWidgets('⭐ Hide earned drops what is finished, not a family part-way', (
      tester,
    ) async {
      await _pumpSyn(
        tester,
        _profile(goldEarned: 1000, earned: {'gate', 'pyro_1'}),
      );
      await _tapChip(tester, AchievementsScreen.hideEarnedLabel);
      expect(
        _rowKeys(tester),
        ['roads', 'pyro', 'quiet'],
        reason:
            'kills a Hide earned that hides nothing, and one that hides a '
            'family with tiers still to earn',
      );

      await _tapChip(tester, AchievementsScreen.hideEarnedLabel);
      expect(
        _rowKeys(tester).length,
        4,
        reason: 'kills a toggle that cannot be turned off',
      );

      await _pumpSyn(
        tester,
        _profile(goldEarned: 10000, earned: {'pyro_1', 'pyro_2', 'pyro_3'}),
      );
      await _tapChip(tester, AchievementsScreen.hideEarnedLabel);
      expect(_rowKeys(tester), [
        'gate',
        'roads',
        'quiet',
      ], reason: 'kills a finished family kept under Hide earned');
      expect(
        find.textContaining('Mastery ·'),
        findsNothing,
        reason: 'kills a heading left over an emptied section',
      );
    });

    testWidgets('⭐ To claim shows only rows with a reward waiting — and keeps '
        'a row once paid', (tester) async {
      final game = await _pumpSyn(
        tester,
        _profile(
          goldEarned: 1000,
          earned: {'gate', 'pyro_1', 'quiet'},
          claimed: {'quiet'},
        ),
      );
      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      expect(
        _rowKeys(tester),
        ['gate', 'pyro'],
        reason:
            'kills a To claim that filters nothing, one that shows a paid '
            'row (quiet), or one that hides a family with a tier waiting',
      );

      final next = find.byKey(AchievementRow.claimCellKey('pyro'));
      final nextAt = tester.getRect(next);
      final toggle = _chip(tester, AchievementsScreen.toClaimLabel);
      await tester.tap(_claimIn('gate'));
      await tester.pump();

      expect(game.claims, ['gate'], reason: 'premise: the gate is paid');
      expect(
        _rowKeys(tester),
        ['gate', 'pyro'],
        reason:
            'kills a To claim view re-asked every build — the paid row would '
            'vanish under the thumb',
      );
      expect(
        tester.getRect(next),
        nextAt,
        reason:
            "kills the same mutant by its effect: the next row's Claim would "
            'slide up into the spot just pressed',
      );
      expect(
        _chip(tester, AchievementsScreen.toClaimLabel),
        toggle,
        reason: 'kills a toggle that moves when a claim lands',
      );

      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      expect(_rowKeys(tester), [
        'pyro',
      ], reason: 'kills a snapshot that is never retaken');

      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      expect(
        _rowKeys(tester).length,
        4,
        reason: 'kills a To claim that cannot be turned off',
      );
    });

    testWidgets('⭐ everything filtered: the one empty line', (tester) async {
      await _pumpSyn(tester, _profile());
      expect(
        find.text(AchievementsScreen.emptyLine),
        findsNothing,
        reason: 'kills an empty line shown over a full list',
      );
      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      expect(
        [_rowKeys(tester), find.text('Nothing left in this view.').evaluate()],
        [isEmpty, hasLength(1)],
        reason: 'kills a blank view with nothing said',
      );
    });

    testWidgets('both toggles are in reach at the narrowest phone', (
      tester,
    ) async {
      await _pumpSyn(tester, _profile(), width: 360);
      for (final label in [
        AchievementsScreen.hideEarnedLabel,
        AchievementsScreen.toClaimLabel,
      ]) {
        expect(
          _chip(tester, label).right,
          lessThanOrEqualTo(360),
          reason:
              'kills $label scrolled along with the categories — at phone '
              'width it would sit past the fold, unfound',
        );
      }
      expect(
        tester.getSize(find.byKey(AchievementsScreen.filterRowKey)).height,
        AchievementsScreen.filterRowHeight,
        reason: 'kills a row that wraps taller when it runs out of width',
      );
    });

    testWidgets('⭐ press-stable: the filter row never changes size, and no '
        'chip moves', (tester) async {
      // Wide, so no chip needs scrolling to and any move is the layout's.
      await _pumpSyn(tester, _profile(earned: {'gate'}), width: 1000);
      final row = find.byKey(AchievementsScreen.filterRowKey);
      final before = tester.getRect(row);
      final labels = [
        'World',
        AchievementsScreen.hideEarnedLabel,
        AchievementsScreen.toClaimLabel,
      ];
      final at = {for (final l in labels) l: _chip(tester, l)};
      final firstRow = tester.getTopLeft(find.text('The Gate'));

      await _tapChip(tester, 'Mastery');
      await _tapChip(tester, AchievementsScreen.hideEarnedLabel);
      await _tapChip(tester, AchievementsScreen.toClaimLabel);

      expect(
        [tester.getRect(row), before.height],
        [before, AchievementsScreen.filterRowHeight],
        reason:
            'kills a filter row that sizes to its content — a lit chip or '
            'a wrapped label would push the list down',
      );
      for (final l in labels) {
        expect(
          _chip(tester, l),
          at[l],
          reason:
              'kills a lit chip that grows and shoves its neighbours, or a '
              'toggle whose icon appears only when lit ($l)',
        );
      }

      await _tapChip(tester, AchievementsScreen.toClaimLabel);
      await _tapChip(tester, AchievementsScreen.hideEarnedLabel);
      await _tapChip(tester, AchievementsScreen.allLabel);
      expect(
        tester.getTopLeft(find.text('The Gate')),
        firstRow,
        reason: 'kills a list that does not come back to where it was',
      );
    });

    testWidgets('⭐ press-stable: the claim cell keeps its rect through a '
        'claim, and is one width on every row', (tester) async {
      await _pumpSyn(tester, _profile(earned: {'gate'}));
      final cell = find.byKey(AchievementRow.claimCellKey('gate'));
      final before = tester.getRect(cell);
      final nameAt = tester.getTopLeft(find.text('The Gate'));

      await tester.tap(_claimIn('gate'));
      await tester.pump();

      expect(
        tester.getRect(cell),
        before,
        reason:
            'kills a claim cell that collapses once paid — the button '
            'pressed would take its row with it',
      );
      expect(
        tester.getTopLeft(find.text('The Gate')),
        nameAt,
        reason: 'kills a row that re-lays its text when Claim leaves',
      );
      expect(
        tester.getSize(find.byKey(AchievementRow.claimCellKey('roads'))).width,
        AchievementRow.claimCellWidth,
        reason:
            'kills a cell reserved only on claimable rows — the text column '
            'would run wider on some rows than others',
      );
    });
  });

  group('the real catalogue', () {
    const name = 'Papers in Order';

    testWidgets('an unearned entry is listed, dim; earned, it is lit and '
        'offers Claim, which pays', (tester) async {
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        const AchievementsScreen(),
      );
      expect(
        _colorOf(tester, find.text(name)),
        AppColors.textFaint,
        reason: 'kills a screen that hides, or lights, what is not earned',
      );

      final profile = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      await _pump(tester, profile, const AchievementsScreen());
      expect(
        _colorOf(tester, find.text(name)),
        AppColors.text,
        reason: 'kills a mutant that leaves an earned entry dim',
      );
      await tester.tap(_claimIn('papers_in_order'));
      await tester.pump();
      expect(
        profile.claimedAchievements,
        contains('papers_in_order'),
        reason: 'kills a Claim button wired to nothing in the real game',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byType(LevelUpScreen),
        findsOneWidget,
        reason:
            'kills a claim whose level-up waits, unseen, for the next duel '
            'to surface it',
      );
    });

    testWidgets('Claim all through the real GameState: the banner sums it', (
      tester,
    ) async {
      final profile = PlayerProfile.newPlayer()
        ..achievements.addAll({'papers_in_order', 'first_blood'});
      await _pump(tester, profile, const AchievementsScreen());
      await tester.tap(find.byKey(AchievementsScreen.claimAllKey));
      await tester.pump();
      expect(profile.claimedAchievements, {
        'papers_in_order',
        'first_blood',
      }, reason: 'kills a Claim all wired to nothing in the real game');
      expect(
        find.text('Claimed +350 XP · +200 gold'),
        findsOneWidget,
        reason: "kills a banner that is not the real claim's return",
      );
      await tester.pump(kAppBannerHold + kAppBannerFade * 2);
    });
  });

  test('the copy', () {
    expect(
      [
        rewardLabel(Reward.forPoints(100)),
        rewardLabel(Reward.forPoints(10)),
        pointsLabel(1240),
        progressLabel((done: 4800, total: 5000)),
        sectionLabel('Campaign', 19, 81),
        claimedBannerText((xp: 1250, gold: 800, rp: 6)),
      ],
      [
        '+5,000 XP · +5,000 gold · +25 RP',
        '+250 XP · +150 gold',
        '1,240 points',
        '4,800 / 5,000',
        'Campaign · 19 / 81',
        'Claimed +1,250 XP · +800 gold · +6 RP',
      ],
      reason:
          'kills ungrouped thousands (5000), an RP clause printed as +0 RP, '
          'and a count or banner in any other shape than §7.2 writes it',
    );
  });

  group('the Profile row', () {
    final total = Achievements.all.length;

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

    test('⭐ counts tiers, not families', () {
      final waiting = _profile(earned: {'pyro_1', 'pyro_2'});
      expect(
        achievementProfileTrailing(waiting, catalogue: _catalogue),
        '2 to claim',
        reason: 'kills a count of families waiting (1)',
      );
      expect(
        achievementProfileTrailing(
          waiting..claimedAchievements.addAll({'pyro_1', 'pyro_2'}),
          catalogue: _catalogue,
        ),
        '2 / 6',
        reason: 'kills a count of rows (1 / 4)',
      );
    });

    testWidgets('⭐ counts n / N off the profile', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const ProfileScreen());
      expect(
        find.text('0 / $total'),
        findsOneWidget,
        reason: 'kills a row with no count, or a count of something else',
      );

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
