/// The 'Cleared' mark on zones (ruling 2026-09-25: "a clearer 'Cleared'
/// mark"): a green check and the word on the Map tab's travel card, ahead of
/// the level band, and a green check badge on the world map's node.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a mark on every card, a mark on none, a cell that only exists when
/// cleared (so the band jumps the day the boss falls), and a badge painted on
/// the wrong node or on none.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:masters_of_magic_2/ui/world_map_painter.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// A new player in Hearthwood, whose roads lead to both Whispering Woods and
/// Glimmerbrook — the one cleared, the other not.
Future<void> _pumpMapTab(WidgetTester tester, PlayerProfile profile) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: GameState(_MemStorage(), profile),
        child: Scaffold(body: MapTab(onSelectTab: (_) {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The travel card whose title is [name].
Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(GamePanel)).first;

Finder _inCard(String name, Finder f) =>
    find.descendant(of: _card(name), matching: f);

void main() {
  final woods = World.byId('whispering_woods');
  final brook = World.byId('glimmerbrook');

  setUpAll(() {
    // ⚠️ Precondition: both are roads out of the starting town, so a new
    // player sees both travel cards side by side.
    final start = World.byId(World.startLocationId);
    expect(
      start.connections,
      containsAll([woods.id, brook.id]),
      reason: 'the test needs both cards on the Map tab at the start',
    );
  });

  group('the travel card', () {
    testWidgets("a cleared zone's card says Cleared; an uncleared one's does "
        'not', (tester) async {
      final profile = PlayerProfile.newPlayer()..zoneClears[woods.id] = 1;
      await _pumpMapTab(tester, profile);

      expect(
        _inCard(woods.name, find.text('Cleared')),
        findsOneWidget,
        reason:
            'the Whispering Woods boss is down — a card that never reads '
            'hasCleared (or reads the wrong id) shows no mark',
      );
      final check = tester.widget<Icon>(
        _inCard(woods.name, find.byIcon(Icons.check_circle)),
      );
      expect(
        check.color,
        AppColors.green,
        reason: 'the mark is a GREEN check_circle, not a neutral glyph',
      );
      expect(
        _inCard(brook.name, find.text('Cleared')),
        findsNothing,
        reason:
            'Glimmerbrook has never been cleared — a mark drawn on every '
            'zone card (ignoring `cleared`) fails here',
      );
      expect(
        _inCard(brook.name, find.byIcon(Icons.check_circle)),
        findsNothing,
        reason: 'no check on an uncleared zone either',
      );
    });

    testWidgets('the mark sits before the level band', (tester) async {
      final profile = PlayerProfile.newPlayer()..zoneClears[woods.id] = 1;
      await _pumpMapTab(tester, profile);

      final mark = tester.getRect(_inCard(woods.name, find.text('Cleared')));
      final band = tester.getRect(
        _inCard(woods.name, find.text(woods.enemyBandLabel)),
      );
      expect(
        mark.right <= band.left && (mark.center.dy - band.center.dy).abs() < 2,
        isTrue,
        reason:
            'ruled: "Cleared" BEFORE the level band, on its line — a mark '
            'appended after the band, or on a line of its own, fails here',
      );
    });

    testWidgets('the level band does not move when the zone is cleared', (
      tester,
    ) async {
      // ⭐ Press-stability: the cell is reserved whether or not it is filled,
      // so the day the boss falls nothing on the card reflows.
      await _pumpMapTab(tester, PlayerProfile.newPlayer());
      final before = tester.getTopLeft(
        _inCard(woods.name, find.text(woods.enemyBandLabel)),
      );
      final brookBand = tester.getTopLeft(
        _inCard(brook.name, find.text(brook.enemyBandLabel)),
      );

      await _pumpMapTab(
        tester,
        PlayerProfile.newPlayer()..zoneClears[woods.id] = 1,
      );
      final after = tester.getTopLeft(
        _inCard(woods.name, find.text(woods.enemyBandLabel)),
      );

      expect(
        after.dx,
        before.dx,
        reason:
            'a cell that only exists when cleared pushes the band right by '
            'its width the moment the zone is cleared',
      );
      expect(
        brookBand.dx,
        before.dx,
        reason:
            'every zone card reserves the same cell, so the bands line up '
            'down the list, cleared or not',
      );
    });
  });

  group('the world map', () {
    /// The centres of every green circle the painter draws.
    ///
    /// ⚠️ Compared as ARGB ints, not `Color ==`: a `Paint` stores its colour
    /// as 32-bit floats, and the `Color` it hands back is not `==` to the
    /// double-precision constant it was given — so a plain equality finds no
    /// badge even when one is drawn.
    List<Offset> greenCircles(WorldMapPainter painter) {
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, const Size(400, 600));
      return [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawCircle &&
              (call.invocation.positionalArguments[2] as Paint).color
                      .toARGB32() ==
                  AppColors.green.toARGB32())
            call.invocation.positionalArguments[0] as Offset,
      ];
    }

    testWidgets('a cleared zone gets a green check badge on its node', (
      tester,
    ) async {
      final circles = greenCircles(
        WorldMapPainter(currentId: 'hearthwood', cleared: {woods.id}),
      );

      expect(
        circles,
        [
          WorldMapPainter.clearedBadgeCentre(
            WorldMapGeometry.positions[woods.id]!,
            12,
          ),
        ],
        reason:
            'exactly one badge, on the Whispering Woods node — a painter '
            'that ignores `cleared` draws none, one that badges every zone '
            'draws dozens, one keyed on the wrong id draws it elsewhere',
      );
    });

    testWidgets('nothing cleared, no badge', (tester) async {
      expect(
        greenCircles(WorldMapPainter(currentId: 'hearthwood')),
        isEmpty,
        reason:
            'a new character has cleared nothing — a badge drawn '
            'unconditionally would claim otherwise',
      );
    });

    test('clearing a zone repaints the map', () {
      final before = WorldMapPainter(cleared: {woods.id});
      expect(
        before.shouldRepaint(WorldMapPainter(cleared: {woods.id, brook.id})),
        isTrue,
        reason:
            'a shouldRepaint that forgot `cleared` keeps the stale map — no '
            'badge until something else happens to move',
      );
      expect(
        before.shouldRepaint(WorldMapPainter(cleared: {woods.id})),
        isFalse,
        reason: 'set equality, not identity',
      );
    });
  });
}
