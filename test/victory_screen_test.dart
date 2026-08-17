import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

/// A duel stream whose next double is always 0 — every escape roll succeeds.
/// ⭐ Pins the campaign route to this card at 100%, where the real chance tops
/// out at 95%.
class _AlwaysEscapes extends ReseedableRandom {
  _AlwaysEscapes() : super(1);

  @override
  double nextDouble() => 0.0;
}

void main() {
  test('⚠️ the XP a win is worth is NOT the flat base', () {
    // The victory screen used to display Progression.winXp while GameState
    // banked xpForDuel — so beating a level-5 foe said "+30 XP" and paid 55.
    // (Numbers are post-2026-08-10 halving; the bug is rate-independent.)
    expect(
      Progression.xpForDuel(won: true, opponentLevel: 5),
      isNot(Progression.winXp),
    );
    expect(
      Progression.xpForDuel(won: true, opponentLevel: 5),
      greaterThan(Progression.xpForDuel(won: true, opponentLevel: 1)),
    );
  });

  test('a loss is flat, whoever beat you', () {
    expect(
      Progression.xpForDuel(won: false, opponentLevel: 1),
      Progression.xpForDuel(won: false, opponentLevel: 60),
    );
  });

  // ======================================================================
  // "Again" is a practice affordance, not a campaign one
  // ======================================================================
  group('the rematch button', () {
    /// Builds the arena, then bows out on purpose — the shortest honest route
    /// to the end-of-duel card.
    ///
    /// ⚠️ The two modes leave by different doors since the 2026-08-17 flee
    /// ruling: PvP surrenders flat, while a campaign fight ROLLS to escape. So
    /// the campaign route forces a winning roll ([_AlwaysEscapes]) rather than
    /// tapping a button that no longer ends anything by itself.
    Future<void> playToTheEnd(WidgetTester tester,
        {required bool campaign}) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: DuelScreen(
          loadout: Loadout.starter,
          campaign: campaign,
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
      ));
      await tester.pump();
      // The campaign button carries its live odds ("Flee (70%)"), so match on
      // the prefix rather than pinning a number this test does not care about.
      final leave = campaign
          ? find.textContaining('Flee (')
          : find.text('Surrender');
      await tester.tap(leave.first);
      // ⚠️ Never pumpAndSettle here: the arena runs a per-move countdown, so
      // the tree never goes quiet and settling times out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      // The confirmation dialog repeats the verb; the second one is its button.
      await tester.tap(leave.last);
      // ⚠️ Never pumpAndSettle here: the arena runs a per-move countdown, so
      // the tree never goes quiet and settling times out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('a campaign encounter offers no rematch', (tester) async {
      await playToTheEnd(tester, campaign: true);
      expect(find.text('Leave'), findsOneWidget,
          reason: 'the end-of-duel card should be showing');
      expect(find.text('Again'), findsNothing,
          reason: '⚠️ the encounter is already settled — XP, loot and the '
              "run's carried health were banked the moment it ended, so a "
              'rematch pays the whole thing out a second time');
    });

    testWidgets('a practice duel still offers one', (tester) async {
      await playToTheEnd(tester, campaign: false);
      expect(find.text('Again'), findsOneWidget,
          reason: 'a local persona duel banks nothing that a rematch could '
              'duplicate — excluding it here would be a plain regression');
    });
  });
}
