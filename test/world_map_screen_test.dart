import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
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

  /// The true on-screen position of a place, read from the transformed canvas
  /// rect — no fit-math duplication, so the test cannot share a bug with the
  /// code under test.
  Offset screenPositionOf(WidgetTester tester, String id) {
    final canvas = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is WorldMapPainter,
    );
    final rect = tester.getRect(canvas);
    final b = WorldMapGeometry.bounds;
    final at = WorldMapGeometry.positions[id]!;
    // rect already includes the view transform: its width is the child width
    // times the current scale.
    return Offset(
      rect.left + (at.dx - b.left) / b.width * rect.width,
      rect.top + (at.dy - b.top) / b.height * rect.height,
    );
  }

  Future<void> dismissSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 100));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a pin at FIT scale opens its sheet', (tester) async {
    await pumpMap(tester, const Size(400, 800));

    await tester.tapAt(screenPositionOf(tester, 'aldermere'));
    await tester.pumpAndSettle();
    expect(find.text('You are already here'), findsOneWidget,
        reason: 'the tap must land on the pin the player is standing on');
  });

  testWidgets('tapping a neighbour opens its sheet, and Travel moves you',
      (tester) async {
    final game = await pumpMap(tester, const Size(400, 800));

    await tester.tapAt(screenPositionOf(tester, 'whispering_woods'));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Whispering Woods'), findsOneWidget);

    await tester.tap(find.text('Travel to Whispering Woods'));
    await tester.pumpAndSettle();
    expect(game.profile.locationId, 'whispering_woods');
    expect(find.text('Whispering Woods'), findsWidgets,
        reason: 'the app bar follows the player');
  });

  testWidgets('tapping the player works when ZOOMED IN', (tester) async {
    // ⚠️ The case the double inversion broke hardest: at 3x the position the
    // old code responded to was off-screen entirely.
    await pumpMap(tester, const Size(400, 800));

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    await tester.tapAt(screenPositionOf(tester, 'aldermere'));
    await tester.pumpAndSettle();
    expect(find.text('You are already here'), findsOneWidget,
        reason: 'zoomed taps must keep landing on the pins');
  });

  testWidgets('the LOWER map is tappable on a short-wide window',
      (tester) async {
    // ⚠️ Guards constrained: false. With the default (constrained: true) the
    // child was clamped to the viewport height on wide windows: the canvas
    // still painted below the clamp — CustomPaint does not clip — but the hit
    // area stopped, so the south of the world drew and could not be tapped.
    final game = await pumpMap(tester, const Size(1200, 800));

    // Walk south to Thornmire's neighbourhood so it is reachable.
    // aldermere -> thornmire are directly connected.
    await tester.tapAt(screenPositionOf(tester, 'thornmire'));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Thornmire'), findsOneWidget,
        reason: 'a pin deep in the clamped zone must still take taps');
    await dismissSheet(tester);

    // And the far south of the map — beyond any plausible clamp.
    await tester.tapAt(screenPositionOf(tester, 'glimmerbrook'));
    await tester.pumpAndSettle();
    expect(find.text('Travel to Glimmerbrook'), findsOneWidget);
    expect(game.profile.locationId, 'aldermere',
        reason: 'opening a sheet is not travelling');
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
}
