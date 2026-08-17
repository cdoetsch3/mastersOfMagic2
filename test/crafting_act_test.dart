/// The crafting act: scoring math, and the act played end to end.
///
/// ⭐ Mutation-verified where it matters — and the widget tests genuinely
/// PLAY the minigame with synthetic gestures against real tickers, because
/// an act screen that only renders is not an act.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/crafting/craft_quality.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/crafting_act_screen.dart';
import 'package:masters_of_magic_2/ui/crafting/scoring.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

GameState _gameWithLogs(int logs) => GameState(
  _Mem(),
  PlayerProfile.newPlayer()
    ..backpack = Backpack.of([
      for (var i = 0; i < logs; i++) const InventorySlot(defId: 'oak_log'),
    ]),
);

Widget _wrap(GameState game, Widget child) => MaterialApp(
  home: GameStateScope(state: game, child: child),
);

void main() {
  group('scoring', () {
    test('closeness is 1 dead-on, linear to 0 at the window edge', () {
      expect(closeness(0.8, 0.8, 0.1), 1);
      expect(closeness(0.85, 0.8, 0.1), closeTo(0.5, 1e-9));
      expect(closeness(0.91, 0.8, 0.1), 0,
          reason: 'outside the window is a miss, not negative');
    });

    test('trace coverage dominates fidelity 70/30', () {
      // ⚠️ Kills a scorer that rewards tiny perfect segments: half the line
      // drawn perfectly must lose to the whole line drawn wobbly.
      final halfPerfect = traceScore(coverage: 0.5, fidelity: 1.0);
      final wholeWobbly = traceScore(coverage: 1.0, fidelity: 0.5);
      expect(wholeWobbly, greaterThan(halfPerfect));
    });

    test('gradeLabel bands match CraftQuality ceilings at the edges', () {
      // The words and the roll read the same grade: 0.85 is where both
      // 'Flawless' and the Master ceiling begin.
      expect(gradeLabel(0.85), 'Flawless');
      expect(CraftQuality.executionCeiling(0.85).name, 'master');
      expect(gradeLabel(0.4), 'Clean');
      expect(CraftQuality.executionCeiling(0.4).name, 'standard');
    });

    test('the fail threshold vanishes at margin 5', () {
      expect(failThreshold(0), greaterThan(0));
      expect(failThreshold(5), 0,
          reason: 'a veteran does not ruin oak — §9b.9c');
    });

    test('pingPong is deterministic and bounces', () {
      expect(pingPong(0, 1), 0);
      expect(pingPong(0.5, 1), 0.5);
      expect(pingPong(1, 1), 1);
      expect(pingPong(1.5, 1), 0.5, reason: 'coming back down');
    });

    test('distanceToPolyline clamps to segment ends', () {
      final d = distanceToPolyline(0, 10, [0, 10], [0, 0]);
      expect(d, 10, reason: 'nearest point is the segment start, not beyond');
    });
  });

  group('the act, played', () {
    testWidgets('a played oak-wand act crafts the wand and shows the grade',
        (tester) async {
      final game = _gameWithLogs(3);
      await tester.pumpWidget(
        _wrap(game, CraftingActScreen(recipe: PrimalRecipes.oakWand)),
      );

      // Step 1: CHOP — hold to ~the target (0.82 of a 1.1s ping-pong climb),
      // then release inside the gold band.
      expect(find.text('CHOP'), findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CraftingActScreen)),
      );
      await tester.pump(const Duration(milliseconds: 900)); // ≈0.82 up-leg
      await gesture.up();
      await tester.pump();

      // Step 2: CARVE — drag the arc end to end. The path is deterministic
      // (300×220 canvas, arc peaking 55px above centre), so walk it.
      expect(find.text('CARVE'), findsOneWidget);
      final box = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 300,
        ),
      );
      Offset pathPoint(double t) => Offset(
        box.left + 20 + t * 260,
        box.top + 110 + -55 * math.sin(math.pi * t),
      );
      final drag = await tester.startGesture(pathPoint(0));
      for (var i = 1; i <= 20; i++) {
        await drag.moveTo(pathPoint(i / 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await drag.up();
      await tester.pumpAndSettle();

      // The result panel, and the wand genuinely minted.
      expect(find.textContaining('Grade'), findsOneWidget);
      expect(game.profile.backpack.countOf('oak_wand'), 1,
          reason: 'the act must end in a real craft, not a display');
      expect(game.profile.backpack.countOf('oak_log'), 1,
          reason: 'materials consumed by the real craft() path');
      expect(game.profile.skillXp['woodcarving'], isNotNull);
    });

    testWidgets('a botched act fails and consumes nothing', (tester) async {
      final game = _gameWithLogs(3);
      await tester.pumpWidget(
        _wrap(game, CraftingActScreen(recipe: PrimalRecipes.oakWand)),
      );

      // Botch the chop: release instantly, meter ~0 → accuracy 0.
      final g1 = await tester.startGesture(
        tester.getCenter(find.byType(CraftingActScreen)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await g1.up();
      await tester.pump();

      // Botch the carve: a real stroke, but along the canvas bottom — 90px
      // from the arc, so coverage and fidelity are both ~0. (⚠️ It must be a
      // REAL pan: a sub-slop wiggle never fires onPanEnd and the act would
      // simply wait forever.)
      expect(find.text('CARVE'), findsOneWidget);
      final box = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 300,
        ),
      );
      final g2 = await tester.startGesture(
        Offset(box.left + 40, box.top + 200),
      );
      for (var i = 1; i <= 5; i++) {
        await g2.moveBy(const Offset(15, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g2.up();
      await tester.pumpAndSettle();

      expect(find.text('The attempt fails'), findsOneWidget);
      expect(find.textContaining('unspent'), findsOneWidget,
          reason: 'the safety rule must be said out loud');
      // ⚠️ The whole §9b.9c abort ruling: nothing consumed, nothing paid.
      expect(game.profile.backpack.countOf('oak_log'), 3,
          reason: 'a failed act must never eat materials');
      expect(game.profile.backpack.countOf('oak_wand'), 0);
      expect(game.profile.skillXp['woodcarving'], isNull,
          reason: 'no XP for an aborted attempt');
    });
  });
}
