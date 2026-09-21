/// The adventure screen's answer to "I filled up on dust and can't drop
/// anything" (playtest ruling, 2026-09-21).
///
/// ⭐ Three panels between fights: Supplies drinks from **both** containers,
/// the Belt bay re-packs, and the Pack destroys. `quest_inventory_test.dart`
/// pins the rules; this file pins that the screen actually reaches them —
/// the same split `adventure_screen_test.dart` uses for the loot picker.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';
import 'package:masters_of_magic_2/ui/belt_bay.dart';

final _woods = World.byId('whispering_woods');

/// ⚠️ A ListView only builds what fits, and the Pack panel is the LAST thing
/// on this screen — on the default 800x600 viewport it is far below the fold.
Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: game,
        child: AdventureScreen(zone: _woods),
      ),
    ),
  );
}

Future<GameState> _onAdventure() async {
  final game = GameState(_Mem(), PlayerProfile.newPlayer());
  await game.beginAdventure(_woods, rng: Random(3));
  return game;
}

/// The dialog's own Drop, not the row button that opened it.
final _confirmDrop = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text('Drop'),
);

void main() {
  group('the pack panel', () {
    testWidgets('⭐ every carried slot is listed, with a way out of it', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'oak_log'))!
          .withAdded(const InventorySlot(defId: 'flora_crystal'))!;
      await _pump(tester, game);

      expect(
        find.textContaining('PACK'),
        findsOneWidget,
        reason:
            'without the panel the player is back to walking home to make '
            'room — the whole complaint',
      );
      expect(
        find.textContaining('2 / 20 SLOTS'),
        findsOneWidget,
        reason:
            'the pressure is the reason the panel exists; a header that does '
            'not count is a header that explains nothing',
      );
      expect(
        find.widgetWithText(TextButton, 'Drop'),
        findsNWidgets(2),
        reason:
            'one row, one Drop — a mutant drawing a single button for the '
            'whole panel drops whatever it feels like',
      );
    });

    testWidgets('⚠️ Drop asks once, and says nothing comes back', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'oak_log'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();

      expect(
        find.text('Drop Oak Log?'),
        findsOneWidget,
        reason: 'the confirm has to name what is about to be destroyed',
      );
      expect(
        find.text('It is destroyed. Nothing comes back.'),
        findsOneWidget,
        reason:
            'a destruction that reads as "put it down" is the one mistake '
            'this dialog exists to prevent',
      );
      expect(
        game.profile.backpack.countOf('oak_log'),
        1,
        reason: 'opening the dialog must not already have dropped it',
      );

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf('oak_log'),
        1,
        reason: 'Keep that drops anyway makes the dialog a lie',
      );
    });

    testWidgets('confirming actually empties the slot, and says so', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'oak_log'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmDrop);
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.countOf('oak_log'),
        0,
        reason: 'the screen never called GameState.discardFromBackpack',
      );
      expect(
        find.text('Oak Log'),
        findsNothing,
        reason:
            'a panel that keeps drawing the dropped row did not rebuild — '
            'the setState this screen needs after every pack mutation',
      );
      expect(
        find.text('Dropped Oak Log.'),
        findsOneWidget,
        reason:
            'an item leaving a twenty-slot grid is invisible; the banner is '
            'the only receipt',
      );
    });

    testWidgets('⚠️ the right slot is dropped, not the first one', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.itemInstances['inst-1'] = const ItemInstance(
        instanceId: 'inst-1',
        defId: 'heartwood_stave',
      );
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'oak_log'))!
          .withAdded(
            const InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
          )!;
      await _pump(tester, game);

      // The staff's row is the second one, so its Drop is the second button.
      await tester.tap(find.widgetWithText(TextButton, 'Drop').last);
      await tester.pumpAndSettle();
      await tester.tap(_confirmDrop);
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.countOf('heartwood_stave'),
        0,
        reason:
            'a mutant passing a constant index — or the def id — destroys '
            'the log the player meant to keep',
      );
      expect(game.profile.backpack.countOf('oak_log'), 1);
      expect(
        game.profile.itemInstances.containsKey('inst-1'),
        isFalse,
        reason: 'the instance leaks unless the screen went through GameState',
      );
    });
  });

  group('supplies from both containers', () {
    testWidgets('⭐ a belt potion is drinkable between fights', (tester) async {
      final game = await _onAdventure();
      // Nothing drinkable in the pack, so the one 'Use' on screen is the
      // belt's — the point of the test.
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      game.run!.playerHp = 40;
      await _pump(tester, game);

      expect(
        find.text('On your belt'),
        findsOneWidget,
        reason:
            'a belted potion the player cannot reach between fights is the '
            'second half of the complaint',
      );

      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      expect(
        game.profile.belt.loaded,
        isEmpty,
        reason:
            'the row must call useBeltItem — routing it at useItem refuses '
            '("You are not carrying that") for a potion in plain sight',
      );
      expect(
        game.run!.playerHp,
        greaterThan(40),
        reason: 'a Use that unloads without healing is theft',
      );
      expect(find.textContaining('You recover'), findsOneWidget);
    });

    testWidgets('⚠️ the panel stays put when there is nothing to drink', (
      tester,
    ) async {
      final game = await _onAdventure();
      await _pump(tester, game);

      expect(
        find.text('Nothing to drink.'),
        findsOneWidget,
        reason:
            'it used to vanish when empty, so drinking your last ration made '
            'the Belt and Pack panels jump up the screen mid-tap',
      );
      expect(
        // ⚠️ Not a bare 'Health' — the progress card says "Health carried in"
        // at the top of the same screen.
        find.textContaining('Health 100 / '),
        findsOneWidget,
        reason: 'the health line is the panel and must survive an empty pack',
      );
    });

    testWidgets('both containers are named when both hold something', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      game.run!.playerHp = 40;
      await _pump(tester, game);

      expect(find.text('From your pack'), findsOneWidget);
      expect(
        find.text('On your belt'),
        findsOneWidget,
        reason:
            'where a potion is decides what drinking it costs later, so the '
            'two groups are named rather than merged',
      );
      expect(
        find.widgetWithText(TextButton, 'Use'),
        findsNWidgets(2),
        reason: 'one Use per container — a merged list loses one of them',
      );
    });
  });

  group('the belt bay on the road', () {
    testWidgets('⭐ the town editor itself is on the screen', (tester) async {
      final game = await _onAdventure();
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      await _pump(tester, game);

      expect(
        find.byType(BeltBay),
        findsOneWidget,
        reason:
            'a hand-rolled second belt editor is the copy that drifts — the '
            'road uses the same widget the inventory tab does',
      );
      expect(find.textContaining('Belt — 1/'), findsOneWidget);
    });

    testWidgets('⚠️ a beltless character with nothing loaded sees no bay', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.belt = const Belt();
      await _pump(tester, game);
      expect(
        find.byType(BeltBay),
        game.beltCapacity > 0 ? findsOneWidget : findsNothing,
        reason:
            'the road uses the town\'s own condition — a mutant that '
            'always places the bay shows an unexplained "Belt — 0/0"',
      );
    });

    testWidgets('a beltable item in the pack can be hung on the belt', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.itemInstances['b'] = const ItemInstance(
        instanceId: 'b',
        defId: 'fawnhide_belt',
      );
      game.profile.equipped[EquipSlot.belt] = 'b';
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'sapwort_draught'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Belt'));
      await tester.pumpAndSettle();

      expect(
        game.profile.belt.loaded,
        ['sapwort_draught'],
        reason:
            're-loading between fights is the ruling\'s own words; a belt you '
            'can only empty on the road empties once and stays empty',
      );
      expect(
        game.profile.backpack.countOf('sapwort_draught'),
        0,
        reason: 'loading is a MOVE, not a copy (2026-08-17)',
      );
    });

    testWidgets('⚠️ with no belt worn, Belt is greyed rather than hidden', (
      tester,
    ) async {
      final game = await _onAdventure();
      // A fresh character wears no belt, so capacity is 0 (Carrying
      // .baseBeltSlots) — the draught is beltable and still cannot be belted.
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'sapwort_draught'))!
          .withAdded(const InventorySlot(defId: 'oak_log'))!;
      await _pump(tester, game);

      final belt = find.widgetWithText(TextButton, 'Belt');
      expect(
        belt,
        findsOneWidget,
        reason:
            'hiding it makes a capacity problem look like an unbeltable item '
            '— the 2026-08-17 greyed-with-the-reason rule',
      );
      expect(
        tester.widget<TextButton>(belt).onPressed,
        isNull,
        reason: 'a button that refuses on tap is worse than a dead one',
      );
      expect(
        game.profile.belt.loaded,
        isEmpty,
        reason: 'nothing was belted, and nothing should have been',
      );
    });

    testWidgets('a log never offers a belt at all', (tester) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'oak_log'),
      )!;
      await _pump(tester, game);

      expect(
        find.widgetWithText(TextButton, 'Belt'),
        findsNothing,
        reason:
            'a log was never Beltable — offering it teaches a rule that does '
            'not exist',
      );
      expect(find.widgetWithText(TextButton, 'Drop'), findsOneWidget);
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
