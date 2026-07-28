import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/screens/world_map_screen.dart';
import 'package:masters_of_magic_2/ui/world_map_painter.dart';

/// Regression guards for the map's tap-to-travel path.
///
/// ⚠️ These exist because the original implementation shipped with a **double
/// inversion**: `_toMap` applied the inverse view transform to a position that
/// Flutter's hit-testing had already un-transformed (the GestureDetector sits
/// inside the InteractiveViewer's subtree). Taps were ~43 px off at fit scale
/// and the responsive spot left the screen entirely when zoomed — and the only
/// widget test at the time asserted "paints without throwing", which cannot
/// see any of that. These taps land on *true* pin positions, derived from the
/// canvas's actual on-screen rect rather than re-implementing the fit math.
class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

void main() {
  Future<GameState> pumpMap(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
    await tester.pumpWidget(MaterialApp(home: WorldMapScreen(game: game)));
    await tester.pumpAndSettle();
    return game;
  }

  Finder canvasFinder() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is WorldMapPainter,
  );

  /// The true on-screen position of a place, read from the transformed canvas
  /// rect. This states the contract — *the world is contained in the box and
  /// centred* — rather than calling MapCamera, so the test cannot share a bug
  /// with the code under test.
  Offset screenPositionOf(WidgetTester tester, String id) {
    final rect = tester.getRect(canvasFinder());
    final b = WorldMapGeometry.bounds;
    final at = WorldMapGeometry.positions[id]!;
    // rect already includes the view transform, so this k is unit x scale.
    final k = min(rect.width / b.width, rect.height / b.height);
    return rect.center +
        Offset((at.dx - b.center.dx) * k, (at.dy - b.center.dy) * k);
  }

  /// Screen point -> map coordinates, from the canvas's real transformed rect.
  Offset mapPointAt(WidgetTester tester, Offset screen) {
    final rect = tester.getRect(canvasFinder());
    final b = WorldMapGeometry.bounds;
    final k = min(rect.width / b.width, rect.height / b.height);
    return b.center + (screen - rect.center) / k;
  }

  Future<void> dismissSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 100));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a pin at FIT scale opens its sheet', (tester) async {
    await pumpMap(tester, const Size(400, 800));

    await tester.tapAt(screenPositionOf(tester, 'aldermere'));
    await tester.pumpAndSettle();
    expect(
      find.text('You are already here'),
      findsOneWidget,
      reason: 'the tap must land on the pin the player is standing on',
    );
  });

  testWidgets('tapping a neighbour opens its sheet, and Travel moves you', (
    tester,
  ) async {
    final game = await pumpMap(tester, const Size(400, 800));

    await tester.tapAt(screenPositionOf(tester, 'whispering_woods'));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Whispering Woods'), findsOneWidget);

    await tester.tap(find.text('Travel to Whispering Woods'));
    await tester.pumpAndSettle();
    expect(game.profile.locationId, 'whispering_woods');
    expect(
      find.text('Whispering Woods'),
      findsWidgets,
      reason: 'the app bar follows the player',
    );
  });

  testWidgets('tapping the player works when ZOOMED IN', (tester) async {
    // ⚠️ The case the double inversion broke hardest: at 3x the position the
    // old code responded to was off-screen entirely.
    await pumpMap(tester, const Size(400, 800));

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    await tester.tapAt(screenPositionOf(tester, 'aldermere'));
    await tester.pumpAndSettle();
    expect(
      find.text('You are already here'),
      findsOneWidget,
      reason: 'zoomed taps must keep landing on the pins',
    );
  });

  testWidgets('the SOUTH of the map is tappable on a short-wide window', (
    tester,
  ) async {
    // ⚠️ The south of the world used to draw but not take taps on wide
    // windows: the child was a tall scale-to-width canvas, and the viewer
    // clamped its hit area to the viewport height while CustomPaint kept
    // painting past it. Containing the map removes the whole category.
    final game = await pumpMap(tester, const Size(1200, 800));

    // Walk south to Thornmire's neighbourhood so it is reachable.
    // aldermere -> thornmire are directly connected.
    await tester.tapAt(screenPositionOf(tester, 'thornmire'));
    await tester.pumpAndSettle();
    expect(
      find.text('Travel to Thornmire'),
      findsOneWidget,
      reason: 'a pin deep in the clamped zone must still take taps',
    );
    await dismissSheet(tester);

    // And the far south of the map — beyond any plausible clamp.
    await tester.tapAt(screenPositionOf(tester, 'glimmerbrook'));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Glimmerbrook'), findsOneWidget);
    expect(
      game.profile.locationId,
      'aldermere',
      reason: 'opening a sheet is not travelling',
    );
  });

  testWidgets('a tap on empty terrain opens nothing', (tester) async {
    await pumpMap(tester, const Size(400, 800));

    // Mid-ocean, west of the coastline: no pin within the tap radius.
    final b = WorldMapGeometry.bounds;
    final canvas = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is WorldMapPainter,
    );
    final rect = tester.getRect(canvas);
    final sea = Offset(
      rect.left + (60 - b.left) / b.width * rect.width,
      rect.top + (700 - b.top) / b.height * rect.height,
    );
    await tester.tapAt(sea);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('the map follows state changed from OUTSIDE the screen', (
    tester,
  ) async {
    // ⚠️ The screen used to take `game` and never subscribe. Travel appeared
    // to work only because GameState._mutate applies its change synchronously
    // before its first await, and the sheet's callback called setState right
    // after — accidental coupling to an implementation detail. Anything that
    // moves the player without going through the sheet (a travel timer
    // completing, a cloud sync, a cutscene) rendered nothing.
    final game = await pumpMap(tester, const Size(400, 800));
    expect(find.text('Aldermere'), findsWidgets);

    await game.travelTo('thornmire');
    await tester.pumpAndSettle();

    expect(
      find.text('Thornmire'),
      findsWidgets,
      reason: 'the screen must observe GameState, not snapshot it',
    );
    expect(find.text('Aldermere'), findsNothing);
  });

  testWidgets('tap targets stay a constant size on screen', (tester) async {
    // ⭐ The radius used to be a fixed 34 MAP units: ~10 px at desktop fit
    // scale (nearly untappable) and ~270 px at 8x (a tap anywhere near the
    // middle opened a pin from across the screen).
    await pumpMap(tester, const Size(1200, 800));

    // 20 screen px off Pennycross must still be Pennycross...
    final at = screenPositionOf(tester, 'pennycross');
    await tester.tapAt(at + const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Pennycross'), findsOneWidget);
    await dismissSheet(tester);

    // ...and 90 screen px off must not be anything. The direction is chosen
    // from the geometry rather than hard-coded: a fixed offset silently
    // becomes a hit the moment a neighbouring zone is moved on the map.
    final here = WorldMapGeometry.positions['pennycross']!;
    final away =
        [
              const Offset(90, 0),
              const Offset(-90, 0),
              const Offset(0, 90),
              const Offset(0, -90),
            ]
            .map((d) {
              final p = at + d;
              final nearest = WorldMapGeometry.positions.entries
                  .where((e) => e.key != 'pennycross')
                  .map((e) => (e.value - mapPointAt(tester, p)).distance)
                  .reduce(min);
              return (d, nearest);
            })
            .reduce((a, b) => a.$2 > b.$2 ? a : b);
    expect(
      away.$2,
      greaterThan(60),
      reason: 'no empty direction near ${here.dx},${here.dy}',
    );

    await tester.tapAt(at + away.$1);
    await tester.pumpAndSettle();
    expect(
      find.byType(BottomSheet),
      findsNothing,
      reason: 'a distant tap must not grab a pin',
    );
  });

  testWidgets('a drag from the OPENING view actually moves the map', (
    tester,
  ) async {
    // ⚠️ This is the "drawn but I cannot get to it" regression. The map used
    // to open fitted — whole world on screen — so InteractiveViewer refused
    // every drag, correctly, because there was nowhere to go. Everything was
    // visible and nothing responded, and on a wide window the world shrank to
    // a strip with two thirds of the space empty ocean.
    await pumpMap(tester, const Size(1200, 800));
    final viewer = tester.getRect(find.byType(InteractiveViewer));

    // It opens FILLING the window, not fitted inside it.
    final canvas = tester.getRect(canvasFinder());
    expect(canvas.width, greaterThanOrEqualTo(viewer.width - 0.5));
    expect(
      canvas.height,
      greaterThan(viewer.height + 50),
      reason: 'the long axis must overflow, or there is nothing to pan',
    );

    // It opens framed on the player, who lives in the south — so north is the
    // direction with room. Dragging must do something.
    final before = tester.getRect(canvasFinder()).top;
    await tester.dragFrom(viewer.center, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(canvasFinder()).top,
      greaterThan(before + 100),
      reason: 'dragging must move the map',
    );
  });

  testWidgets('the far SOUTH of the world can be panned to and tapped', (
    tester,
  ) async {
    await pumpMap(tester, const Size(1200, 800));
    final viewer = tester.getRect(find.byType(InteractiveViewer));

    // Walk south with repeated drags, the way a player would.
    for (var i = 0; i < 8; i++) {
      await tester.dragFrom(viewer.center, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    final south = screenPositionOf(tester, 'thornmire');
    expect(
      viewer.contains(south),
      isTrue,
      reason: 'the southernmost place must be reachable by panning',
    );

    await tester.tapAt(south);
    await tester.pumpAndSettle();
    expect(find.text('Travel to Thornmire'), findsOneWidget);
  });

  testWidgets('"Whole world" still gets back to everything at once', (
    tester,
  ) async {
    await pumpMap(tester, const Size(1200, 800));
    await tester.tap(find.byTooltip('Whole world'));
    await tester.pumpAndSettle();

    final viewer = tester.getRect(find.byType(InteractiveViewer));
    final canvas = tester.getRect(canvasFinder());
    expect(canvas.size.width, closeTo(viewer.width, 0.5));
    expect(
      canvas.center.dx,
      closeTo(viewer.center.dx, 0.5),
      reason: 'and it is centred, not pinned to the left edge',
    );

    for (final id in ['thornmire', 'aldermere', 'the_eclipsed_citadel']) {
      expect(viewer.contains(screenPositionOf(tester, id)), isTrue, reason: id);
    }
  });

  testWidgets('zooming in then out returns to the centred whole world', (
    tester,
  ) async {
    await pumpMap(tester, const Size(1200, 800));
    final viewport = tester.getRect(find.byType(InteractiveViewer));

    final opened = tester.getRect(canvasFinder()).width;
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(tester.getRect(canvasFinder()).width, greaterThan(opened));

    await tester.tap(find.byTooltip('Whole world'));
    await tester.pumpAndSettle();
    final back = tester.getRect(canvasFinder());
    expect(back.size.width, closeTo(viewport.width, 0.5));
    expect(back.center.dx, closeTo(viewport.center.dx, 0.5));
  });

  group('the Map tab card is the real map, not a preview', () {
    Future<GameState> pumpCard(
      WidgetTester tester, {
      VoidCallback? onExpand,
    }) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                WorldMapCard(game: game, onExpand: onExpand ?? () {}),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return game;
    }

    testWidgets('you can travel from the card without expanding it', (
      tester,
    ) async {
      // ⭐ The card used to be a picture with a tap-to-open overlay: every
      // interaction cost a screen transition first. It is now the same widget
      // as the full-screen map, so this whole flow happens in the tab.
      final game = await pumpCard(tester);

      // It opens framed on the player, so their own pin is under the middle.
      await tester.tapAt(screenPositionOf(tester, 'aldermere'));
      await tester.pumpAndSettle();
      expect(find.text('You are already here'), findsOneWidget);
      await dismissSheet(tester);

      // Zoom out to the whole world, then travel to a neighbour from here.
      await tester.tap(find.byTooltip('Whole world'));
      await tester.pumpAndSettle();
      await tester.tapAt(screenPositionOf(tester, 'whispering_woods'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel to Whispering Woods'));
      await tester.pumpAndSettle();

      expect(game.profile.locationId, 'whispering_woods');
    });

    testWidgets('the card zooms, and expanding is still offered', (
      tester,
    ) async {
      var expanded = false;
      await pumpCard(tester, onExpand: () => expanded = true);

      final before = tester.getRect(canvasFinder()).width;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(tester.getRect(canvasFinder()).width, greaterThan(before));

      await tester.tap(find.byTooltip('Open the full map'));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
    });

    testWidgets('the card is square', (tester) async {
      await pumpCard(tester);
      final rect = tester.getRect(find.byType(WorldMapCard));
      expect(rect.height, closeTo(rect.width, 0.5));
    });
  });

  group('the ways a player actually tries to move the map', () {
    testWidgets('a wheel / trackpad scroll PANS, it does not zoom out', (
      tester,
    ) async {
      // ⚠️ InteractiveViewer treats every scroll as zoom. Scrolling down — the
      // obvious way to move south — zoomed out instead, hit the whole-world
      // limit in three notches, and then did nothing at all. Measured: scale
      // 3.09 -> 1.0 and pinned. It reads as "I can't pan past here".
      await pumpMap(tester, const Size(1400, 800));
      final c = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final scaleBefore = c.value.storage[0];
      final dyBefore = c.value.storage[13];

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final centre = tester.getCenter(find.byType(InteractiveViewer));
      await tester.sendEventToBinding(pointer.hover(centre));
      // Scroll up: the view opens framed on the player in the south, so north
      // is the direction with room to move.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -160)));
      await tester.pumpAndSettle();

      expect(
        c.value.storage[0],
        closeTo(scaleBefore, 0.001),
        reason: 'scrolling must not change the zoom',
      );
      expect(
        c.value.storage[13],
        greaterThan(dyBefore + 100),
        reason: 'scrolling must move the map itself',
      );
    });

    testWidgets('holding a modifier still zooms with the wheel', (
      tester,
    ) async {
      await pumpMap(tester, const Size(1400, 800));
      final c = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final scaleBefore = c.value.storage[0];

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final centre = tester.getCenter(find.byType(InteractiveViewer));
      await tester.sendEventToBinding(pointer.hover(centre));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 160)));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(
        c.value.storage[0],
        lessThan(scaleBefore),
        reason: 'ctrl + scroll down should zoom out',
      );
    });
  });

  testWidgets('on the Map tab, a vertical drag pans the MAP, not the page', (
    tester,
  ) async {
    // ⚠️ The card used to live inside the tab's ListView, and a pannable map
    // inside a scrolling list cannot be panned vertically at all: the list's
    // drag recognizer wins the gesture arena every time. Measured before the
    // fix — a 250 px drag south scrolled the page 230 px and moved the map's
    // transform by exactly zero. The map now sits above the list.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
    await tester.pumpWidget(
      MaterialApp(
        home: GameStateScope(
          state: game,
          child: Scaffold(body: MapTab(onSelectTab: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final c = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final dyBefore = c.value.storage[13];

    final map = tester.getRect(find.byType(InteractiveViewer));
    await tester.dragFrom(map.center, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(
      c.value.storage[13],
      isNot(closeTo(dyBefore, 1)),
      reason: 'the drag must reach the map, not be eaten by the list',
    );
  });
}
