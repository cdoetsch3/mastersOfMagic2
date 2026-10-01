import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_result.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:mom_engine/mom_engine.dart';

/// The Ranking row on the end-of-duel card (Christian, 2026-09-21): the card
/// used to promise "coming soon" on a ladder that has existed for weeks. It
/// now prints the points the duel actually moved, in the colour of the news.
///
/// ⭐ Every case here drives the REAL card — surrender (or a forced escape
/// roll for the campaign route), then read what the row says — rather than
/// calling a formatter, because the bug being pinned is a widget that never
/// asked the settler anything.

/// A duel stream whose next double is always 0 — every escape roll succeeds.
/// Pins the campaign route to the end card at 100%, where the real chance
/// tops out at 95%.
class _AlwaysEscapes extends ReseedableRandom {
  _AlwaysEscapes() : super(1);

  @override
  double nextDouble() => 0.0;
}

void main() {
  /// Builds the arena with [onResult] and bows out on purpose — the shortest
  /// honest route to the end-of-duel card.
  ///
  /// ⚠️ Never `pumpAndSettle`: the arena runs a per-move countdown, so the
  /// tree never goes quiet and settling times out.
  Future<void> playToTheEnd(
    WidgetTester tester, {
    required Future<DuelSettlement?> Function(DuelOutcome)? onResult,
    bool campaign = false,
    bool academy = false,
  }) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          loadout: Loadout.starter,
          campaign: campaign,
          academy: academy,
          // The charge tally is not this file's subject.
          onResult: onResult == null ? null : (o, _) => onResult(o),
          rng: campaign ? _AlwaysEscapes() : null,
          driver: LocalAiDriver(
            persona: const EnemyEncounter(
              def: WhisperingWoodsBestiary.sporecapShambler,
              level: 3,
            ).toPersona(),
            enemy: WhisperingWoodsBestiary.sporecapShambler,
            rng: Random(1),
          ),
        ),
      ),
    );
    await tester.pump();
    // The campaign button carries its live odds ("Flee (70%)"), so match on
    // the prefix rather than pinning a number this test does not care about.
    final leave = campaign
        ? find.textContaining('Flee (')
        : find.text('Surrender');
    await tester.tap(leave.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // The confirmation dialog repeats the verb; the second one is its button.
    await tester.tap(leave.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// The Ranking row's value cell — the only rich [Text] in the row whose
  /// label reads 'Ranking'. Scoped to that row on purpose: matching the first
  /// rich Text on the card would silently start reading some other widget the
  /// day one is added above it.
  Text rankingCell(WidgetTester tester) => tester.widget<Text>(
    find.descendant(
      of: find
          .ancestor(of: find.text('Ranking'), matching: find.byType(Row))
          .first,
      matching: find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
    ),
  );

  String rankingText(WidgetTester tester) =>
      rankingCell(tester).textSpan!.toPlainText();

  /// The colour of the DELTA, which is the leading span — the rating beside
  /// it is deliberately dimmer and must not be what a colour check reads.
  Color? deltaColour(WidgetTester tester) =>
      (rankingCell(tester).textSpan! as TextSpan).style?.color;

  Future<DuelSettlement?> settled(int delta, int rating) async =>
      DuelSettlement(rated: true, ratingDelta: delta, newRating: rating);

  testWidgets('a rated win shows the gain in green, with the new rating', (
    tester,
  ) async {
    await playToTheEnd(tester, onResult: (_) => settled(12, 1432));

    expect(
      find.text('+12 · 1432', findRichText: true),
      findsOneWidget,
      reason:
          'the row must print the points AND where they landed — a mutant '
          'that renders only the delta would leave the player guessing '
          'what their rating now is',
    );
    expect(
      rankingText(tester),
      '+12 · 1432',
      reason:
          'a mutant that keeps the old "coming soon" placeholder, or one '
          'that never awaits onResult, would leave this at the awaiting '
          'ellipsis instead',
    );
    expect(
      deltaColour(tester),
      AppColors.green,
      reason:
          'green is the palette\'s positive colour (bonusColour uses the '
          'same one) — a mutant that colours every delta gold like the '
          'XP/gold rows above would fail here',
    );
  });

  testWidgets('a rated loss shows a real minus sign, in ember', (tester) async {
    await playToTheEnd(tester, onResult: (_) => settled(-8, 1180));

    expect(
      rankingText(tester),
      '−8 · 1180',
      reason:
          'U+2212 MINUS SIGN, not a hyphen — a mutant that interpolates '
          'the signed int directly would render "-8" with a hyphen-minus '
          'and fail this exact-string check',
    );
    expect(
      deltaColour(tester),
      AppColors.ember,
      reason:
          'a loss is red — a mutant that drops the sign test and always '
          'takes the green branch would fail here',
    );
  });

  testWidgets('a rated duel that moved nothing reads ±0, neither colour', (
    tester,
  ) async {
    await playToTheEnd(tester, onResult: (_) => settled(0, 1200));

    expect(
      rankingText(tester),
      '±0 · 1200',
      reason:
          'zero is its own case — a mutant with only a `delta > 0 ? + : −` '
          'ternary would print "−0" here',
    );
    expect(
      deltaColour(tester),
      AppColors.textDim,
      reason:
          'no gain and no loss earns neither colour — a mutant that lumps '
          'zero in with the loss branch would paint this ember',
    );
  });

  testWidgets('an unrated duel says so rather than showing a number', (
    tester,
  ) async {
    await playToTheEnd(tester, onResult: (_) async => DuelSettlement.unrated);

    expect(
      rankingText(tester),
      'unrated',
      reason:
          'a room code or a practice persona moves no rating — a mutant '
          'that reads ratingDelta without checking `rated` would render '
          'the null as "±0 · null" here',
    );
    expect(
      deltaColour(tester),
      AppColors.textDim,
      reason: 'dim: it is a fact about the duel, not a result to celebrate',
    );
  });

  testWidgets('no settler at all still reads unrated, never a stray number', (
    tester,
  ) async {
    await playToTheEnd(tester, onResult: null);

    expect(
      rankingText(tester),
      'unrated',
      reason:
          'a DuelScreen built directly (as most tests do) has nobody to '
          'ask — a mutant that showed the awaiting ellipsis forever would '
          'leave a card that never resolves',
    );
  });

  testWidgets('a campaign encounter has no Ranking row at all', (tester) async {
    await playToTheEnd(
      tester,
      campaign: true,
      onResult: (_) => settled(12, 1432),
    );

    expect(
      find.text('Leave'),
      findsOneWidget,
      reason: 'the end-of-duel card should be showing',
    );
    expect(
      find.text('Ranking'),
      findsNothing,
      reason:
          'a campaign fight has no ladder — a mutant that relaxed the '
          'campaign guard along with the academy one would put a rating '
          'row on a bear',
    );
  });

  testWidgets('an Academy bout rates, and says so beside its own row', (
    tester,
  ) async {
    await playToTheEnd(
      tester,
      academy: true,
      onResult: (_) => settled(12, 1432),
    );

    expect(
      find.text('nothing gained, nothing lost'),
      findsOneWidget,
      reason:
          'the Academy row is about XP and gold and stays exactly as it '
          'was — the ruling adds a row, it does not replace one',
    );
    expect(
      rankingText(tester),
      '+12 · 1432',
      reason:
          'the Academy IS a rated ladder (LADDER §1 law 4) — the old '
          '`!academy` guard hid the one row that was true there',
    );
  });

  testWidgets('the row waits with an ellipsis, and nothing below it moves', (
    tester,
  ) async {
    final pending = Completer<DuelSettlement?>();
    await playToTheEnd(tester, onResult: (_) => pending.future);

    expect(
      rankingText(tester),
      '…',
      reason:
          '"we have not heard yet" is not "you gained nothing" — a mutant '
          'that rendered the unresolved future as ±0 would tell the player '
          'something untrue for as long as the write takes',
    );

    // ⚠️ The press-stability contract: the value cell is fixed-width, so the
    // buttons the player is already reaching for cannot slide out from under
    // their thumb when the rating lands.
    final homeBefore = tester.getTopLeft(find.text('Home'));
    final againBefore = tester.getTopLeft(find.text('Again'));

    pending.complete(
      const DuelSettlement(rated: true, ratingDelta: 12, newRating: 1432),
    );
    await tester.pump();

    expect(
      rankingText(tester),
      '+12 · 1432',
      reason: 'the future resolving must actually reach the card',
    );
    expect(
      tester.getTopLeft(find.text('Home')),
      homeBefore,
      reason:
          'a mutant that let the value cell size itself would widen the '
          'row from "…" to "+12 · 1432" and shift the buttons under a '
          'finger already on its way down',
    );
    expect(
      tester.getTopLeft(find.text('Again')),
      againBefore,
      reason: 'the same promise for the rematch button beside it',
    );
  });
}
