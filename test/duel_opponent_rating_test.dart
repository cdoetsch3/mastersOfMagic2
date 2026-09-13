/// The opponent's nameplate in the arena grows a ladder rating
/// (LADDER_DESIGN §7 item 5: "opponent card shows rating + record for
/// everyone").
///
/// ⭐ Mutation-verified: names the wrong implementation it kills — a rating
/// that never reaches the widget tree, and a driver default that silently
/// drops to 0 instead of the documented 1200 floor.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';

void main() {
  testWidgets("a bot's rating renders next to its name", (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          loadout: Loadout.starter,
          driver: LocalAiDriver(
            persona: AiRoster.all.first,
            rating: 1569,
            rng: Random(1),
          ),
          playerLevel: 5,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('1569'),
      findsOneWidget,
      reason:
          'opponentRating is plumbed from LocalAiDriver.rating through to '
          "the enemy nameplate — a widget that never reads driver."
          'opponentRating (or reads it from the wrong panel) would never '
          'show this number anywhere',
    );
  });

  test('OpponentDriver.opponentRating defaults to 1200', () {
    final driver = LocalAiDriver(persona: AiRoster.all.first, rng: Random(1));
    expect(
      driver.opponentRating,
      1200,
      reason:
          'campaign and practice callers never pass a rating — a driver '
          'that defaults to 0 (or omits the override entirely) would show '
          'an unrated-looking 0 next to every practice foe instead of the '
          'documented Academy-seed floor',
    );
  });
}
