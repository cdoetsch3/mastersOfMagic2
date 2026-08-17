/// The Workbench's shelf controls, and the copy on a locked row.
///
/// ⭐ **Born from a real playtest report**: a player hunting for a belt found
/// none and concluded belts were unimplemented. The Fawnhide Belt existed,
/// was locked at Tailoring 4, and therefore sat at the very bottom of a
/// hard craftability sort. Nothing crashed; the content was simply
/// unreachable by looking.
///
/// ⚠️ These tests pin the two halves of that fix separately — that the player
/// can REORDER and NARROW the shelf, and that a locked row says what would
/// open it. A screen could pass one and still ship the bug.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/craft_screen.dart';

/// ⚠️ Derived from the catalogue, never typed out. A test that hardcodes
/// 'Fawnhide Belt' keeps passing after a rename and stops testing the row it
/// was written for.
String _nameOf(String recipeId) {
  final recipe = RecipeBook.tryById(recipeId)!;
  return ItemCatalogue.displayName(ItemCatalogue.tryById(recipe.outputId)!);
}

RecipeDef _recipe(String id) => RecipeBook.tryById(id)!;

/// ⚠️ Every recipe must be built for the order/visibility assertions to mean
/// anything, and a ListView only builds what fits.
Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 6000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(state: game, child: const CraftScreen()),
    ),
  );
  await tester.pump();
}

GameState _fresh() => GameState(_Mem(), PlayerProfile.newPlayer());

void main() {
  // A fresh player is level 1 in everything and carries nothing, so the
  // fixtures below are provably locked / provably missing.
  final belt = _recipe('craft_fawnhide_belt');
  final staff = _recipe('craft_oak_quarterstaff');

  setUpAll(() {
    expect(
      belt.skill,
      CraftSkill.tailoring,
      reason: 'the belt is this suite\'s tailoring fixture',
    );
    expect(
      belt.skillLevel,
      greaterThan(1),
      reason: 'a fresh player must be BELOW this gate or "locked" is untested',
    );
    expect(
      staff.skill,
      CraftSkill.woodcarving,
      reason: 'the staff is this suite\'s woodcarving fixture',
    );
  });

  group('the shelf shows everything until asked not to', () {
    testWidgets('⭐ the locked belt is visible on arrival', (tester) async {
      await _pump(tester, _fresh());

      expect(
        find.text(_nameOf('craft_fawnhide_belt')),
        findsOneWidget,
        reason: 'this is the reported bug itself — a locked recipe that the '
            'player cannot see is a recipe they conclude does not exist',
      );
    });

    testWidgets('both hide-toggles start OFF', (tester) async {
      await _pump(tester, _fresh());

      // Locked (belt) and merely-unaffordable (staff) rows are both present,
      // which is only true when neither toggle defaults to on.
      expect(find.text(_nameOf('craft_fawnhide_belt')), findsOneWidget);
      expect(
        find.text(_nameOf('craft_oak_quarterstaff')),
        findsOneWidget,
        reason: 'a fresh player has no oak logs; hiding missing-material rows '
            'by default would empty the Workbench on first open',
      );
    });
  });

  group('filtering by skill', () {
    testWidgets('⭐ a skill chip shows only that skill\'s recipes', (
      tester,
    ) async {
      await _pump(tester, _fresh());
      // Both skills on screen before the filter, so the disappearance below
      // is caused by the tap and not by the row never having been there.
      expect(find.text(_nameOf('craft_fawnhide_belt')), findsOneWidget);
      expect(find.text(_nameOf('craft_oak_quarterstaff')), findsOneWidget);

      await tester.tap(find.text('Woodcarving'));
      await tester.pumpAndSettle();

      expect(
        find.text(_nameOf('craft_oak_quarterstaff')),
        findsOneWidget,
        reason: 'the chosen skill keeps its recipes',
      );
      expect(
        find.text(_nameOf('craft_fawnhide_belt')),
        findsNothing,
        reason: 'a tailoring recipe has no business under a woodcarving filter',
      );
    });

    testWidgets('All brings the other skills back', (tester) async {
      await _pump(tester, _fresh());
      await tester.tap(find.text('Woodcarving'));
      await tester.pumpAndSettle();
      expect(find.text(_nameOf('craft_fawnhide_belt')), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(
        find.text(_nameOf('craft_fawnhide_belt')),
        findsOneWidget,
        reason: 'a filter the player cannot clear is a trap',
      );
    });

    testWidgets('⚠️ only skills that own recipes get a chip', (tester) async {
      await _pump(tester, _fresh());

      expect(
        find.text('Tailoring'),
        findsOneWidget,
        reason: 'tailoring owns recipes, so it must offer a chip',
      );
      expect(
        RecipeBook.all.any((r) => r.skill == CraftSkill.metalworking),
        isFalse,
        reason: 'the assertion below is only meaningful while this holds',
      );
      expect(
        find.text('Metalworking'),
        findsNothing,
        reason: 'a chip whose filter can only ever show an empty shelf '
            'teaches the player the screen is broken',
      );
    });
  });

  group('hide locked', () {
    testWidgets('⭐ it removes the locked rows and keeps the rest', (
      tester,
    ) async {
      await _pump(tester, _fresh());
      expect(find.text(_nameOf('craft_fawnhide_belt')), findsOneWidget);

      await tester.tap(find.text('Hide locked'));
      await tester.pumpAndSettle();

      expect(
        find.text(_nameOf('craft_fawnhide_belt')),
        findsNothing,
        reason: 'the belt is gated above a fresh player, so it is locked',
      );
      expect(
        find.text(_nameOf('craft_oak_quarterstaff')),
        findsOneWidget,
        reason: 'hide-LOCKED must not also eat rows that are merely '
            'missing materials — they are different complaints',
      );
    });

    testWidgets('hide missing materials empties a fresh, unstocked shelf', (
      tester,
    ) async {
      await _pump(tester, _fresh());

      await tester.tap(find.text('Hide missing materials'));
      await tester.pumpAndSettle();

      expect(
        find.text(_nameOf('craft_oak_quarterstaff')),
        findsNothing,
        reason: 'a fresh player owns no oak logs',
      );
      expect(
        find.text('No recipes match these filters.'),
        findsOneWidget,
        reason: 'an empty list must blame the filters; silence here reads as '
            '"the game has no recipes", which is the original bug again',
      );
    });
  });

  group('the locked row names its unlock level', () {
    testWidgets('⭐ requirement first, current level second', (tester) async {
      await _pump(tester, _fresh());

      // Derived from the recipe so a re-gate of the belt updates the
      // expectation instead of silently falsifying it.
      final gate = 'Tailoring ${belt.skillLevel}';

      expect(
        find.text('Unlocks at $gate'),
        findsOneWidget,
        reason: 'the chip must lead with WHAT opens the row, not with the '
            'level the player already knows they are',
      );
      expect(
        find.textContaining('Unlocks at $gate · you are Tailoring 1'),
        findsOneWidget,
        reason: 'the footer names the gate and the gap in one line',
      );
      expect(
        find.textContaining('Locked — you are'),
        findsNothing,
        reason: 'the old copy buried the requirement it existed to state',
      );
    });
  });

  group('sorting', () {
    testWidgets('⭐ by skill level puts a low gate above a high one, across '
        'skills', (tester) async {
      final game = _fresh();
      await _pump(tester, game);

      final birch = _recipe('craft_birch_quarterstaff');
      expect(
        belt.skillLevel,
        lessThan(birch.skillLevel),
        reason: 'the fixtures must straddle a gate boundary, in different '
            'skills, or this test proves nothing about the ordering',
      );

      final beltFinder = find.text(_nameOf('craft_fawnhide_belt'));
      final birchFinder = find.text(_nameOf('craft_birch_quarterstaff'));

      // Craftability (default): both are locked, so they fall to the
      // tie-break — woodcarving before tailoring, i.e. birch ABOVE belt.
      expect(
        tester.getTopLeft(birchFinder).dy,
        lessThan(tester.getTopLeft(beltFinder).dy),
        reason: 'the default order groups by craftability, not by gate',
      );

      await tester.tap(find.text('Craftable first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By skill level').last);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(beltFinder).dy,
        lessThan(tester.getTopLeft(birchFinder).dy),
        reason: 'gate ascending must cross skills — a Tailoring 4 belt above '
            'a Woodcarving 10 staff is the whole point of this sort, and '
            'grouping by skill first would rebury the belt',
      );
    });

    testWidgets('the sort control reports the order in force', (tester) async {
      await _pump(tester, _fresh());

      expect(
        find.text('Craftable first'),
        findsOneWidget,
        reason: 'the default order must be named on screen, or the player '
            'cannot tell there is another one',
      );

      await tester.tap(find.text('Craftable first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By skill level').last);
      await tester.pumpAndSettle();

      expect(find.text('By skill level'), findsOneWidget);
      expect(
        find.text('Craftable first'),
        findsNothing,
        reason: 'a control that still shows the old order is a lie',
      );
    });
  });
}

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}
