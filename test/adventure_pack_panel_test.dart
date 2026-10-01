/// The adventure screen's answer to "I filled up on dust and can't drop
/// anything" (playtest ruling, 2026-09-21).
///
/// ⭐ Two panels between fights since the same day's amendment ("just add a
/// 'Use' button to the 'Pack', no need for a separate 'Supplies' section"):
/// the **Pack** uses, belts and destroys, and the **Belt bay** re-packs and
/// drinks. `quest_inventory_test.dart` pins the rules; this file pins that
/// the screen actually reaches them — the same split
/// `adventure_screen_test.dart` uses for the loot picker.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:masters_of_magic_2/ui/belt_bay.dart';
import 'package:masters_of_magic_2/ui/item_icon.dart';

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

/// The loaded belt slot, by the initial its box falls back to while
/// `assets/items/` is empty — 'S' for Sapwort Draught, as `loop_ui_test` taps
/// it. Scoped to the bay so a pack row starting with S cannot stand in.
/// The belted Draught's slot — found by its [ItemIcon], which is there
/// whether the slot draws the PNG (every item has one since the 2026-10-01
/// bulk art pass) or the 'S' initial it used to fall back to.
final _beltSlot = find.descendant(
  of: find.byType(BeltBay),
  matching: find.byWidgetPredicate(
    (w) => w is ItemIcon && w.defId == 'sapwort_draught',
  ),
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
      // ⚠️ Green, not a log: since the 2026-09-21 threshold ruling a common
      // has no dialog left to test (see 'the drop that does not ask').
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'flora_crystal'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();

      expect(
        find.text('Drop Flora Crystal?'),
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
        game.profile.backpack.countOf('flora_crystal'),
        1,
        reason: 'opening the dialog must not already have dropped it',
      );

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf('flora_crystal'),
        1,
        reason: 'Keep that drops anyway makes the dialog a lie',
      );
    });

    testWidgets('confirming actually empties the slot, and says so', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'flora_crystal'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmDrop);
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.countOf('flora_crystal'),
        0,
        reason: 'the screen never called GameState.discardFromBackpack',
      );
      expect(
        find.text('Flora Crystal'),
        findsNothing,
        reason:
            'a panel that keeps drawing the dropped row did not rebuild — '
            'the setState this screen needs after every pack mutation',
      );
      expect(
        find.text('Dropped Flora Crystal.'),
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

  /// ⭐ "When dropping an item during the campaign, if it's less than green
  /// rarity, you don't need to confirm the drop." (Christian, 2026-09-21.)
  group('the drop that does not ask', () {
    testWidgets('⭐ a common is destroyed on the tap, with no dialog at all', (
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
        find.text('It is destroyed. Nothing comes back.'),
        findsNothing,
        reason:
            'a mutant that still confirms every drop is the ruling not '
            'landing — a pack of dust is cleared one dialog at a time again',
      );
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'no dialog of ANY wording: a reworded confirm is still a confirm',
      );
      expect(
        game.profile.backpack.countOf('oak_log'),
        0,
        reason:
            'skipping the ask must skip to the DROP — a mutant that returns '
            'early instead makes Drop do nothing for commons',
      );
      expect(
        find.text('Dropped Oak Log.'),
        findsOneWidget,
        reason:
            'the ask goes, the receipt stays: an item leaving a twenty-slot '
            'grid with no banner reads as a lost save',
      );
    });

    testWidgets('⚠️ green and above still stop to ask', (tester) async {
      final game = await _onAdventure();
      // ⚠️ Uncommon IS the threshold, so this is the row that pins which side
      // of it green falls on — a mutant using `>` drops a crystal outright.
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'flora_crystal'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();

      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason:
            'the threshold is "less than green"; a mutant that lets uncommon '
            'through destroys a 150g crystal on a stray tap',
      );

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf('flora_crystal'),
        1,
        reason: 'Keep that drops anyway makes the surviving dialog a lie',
      );
    });

    testWidgets('⚠️ an epic asks too — the rule is a floor, not a band', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.itemInstances['inst-1'] = const ItemInstance(
        instanceId: 'inst-1',
        defId: 'heartwood_stave',
      );
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
      )!;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();

      expect(
        find.text('Drop Heartwood Staff?'),
        findsOneWidget,
        reason:
            'a mutant comparing for equality with uncommon would wave the '
            'boss drop straight through',
      );
      expect(game.profile.backpack.countOf('heartwood_stave'), 1);
    });
  });

  /// ⭐ "Pack should include base prices of items, same when deciding what to
  /// keep or leave." (Christian, 2026-09-21.)
  group('what a row is worth', () {
    testWidgets('⭐ every pack row prints its base value in gold', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'oak_log'))!
          .withAdded(const InventorySlot(defId: 'foragers_ration'))!
          .withAdded(const InventorySlot(defId: 'sapwort_draught'))!;
      await _pump(tester, game);

      // ⚠️ Built from the catalogue, never typed out: a test holding its own
      // copy of 13 passes forever after the economy retunes the log.
      for (final id in const [
        'oak_log',
        'foragers_ration',
        'sapwort_draught',
      ]) {
        expect(
          find.text('${ItemCatalogue.byId(id).value}g'),
          findsOneWidget,
          reason:
              'the player decides what a slot is worth on this panel, and '
              '$id is the row that has to answer it — a mutant printing the '
              'quality-scaled or vendor figure prints a different number',
        );
      }
    });

    testWidgets("⚠️ a valueless item shows '—', never '0g'", (tester) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'proof_of_the_woods'),
      )!;
      await _pump(tester, game);

      expect(
        ItemCatalogue.byId('proof_of_the_woods').value,
        0,
        reason: 'the fixture stops being a fixture if the proof is ever priced',
      );
      expect(
        find.text('0g'),
        findsNothing,
        reason:
            "'0g' on a quest gate reads as a bug report rather than as 'this "
            "is not merchandise' — the call showItemDialog already makes",
      );
      expect(
        find.text('—'),
        findsOneWidget,
        reason:
            'the cell is reserved either way; a blank one would let the row '
            'look like the price simply failed to load',
      );
    });

    testWidgets('⚠️ the price holds its column whatever the name is', (
      tester,
    ) async {
      final game = await _onAdventure();
      // ⚠️ Different name lengths AND different digit counts — a cell sized
      // to its own text moves for either of those.
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'oak_log'))!
          .withAdded(const InventorySlot(defId: 'foragers_ration'))!;
      await _pump(tester, game);

      expect(
        tester.getTopLeft(find.text('4g')).dx,
        tester.getTopLeft(find.text('13g')).dx,
        reason:
            "the ration's price is one digit and the log's is two, so an "
            'unreserved cell puts them in different columns — the number '
            'wanders down the list and stops reading as a price at all',
      );
    });
  });

  group('one list, not two', () {
    testWidgets('⭐ a carried ration is listed ONCE, with Use on its row', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.run!.playerHp = 40;
      await _pump(tester, game);

      expect(
        find.text("Forager's Ration"),
        findsOneWidget,
        reason:
            'the Supplies section printed every drinkable a second time, so '
            "the player's pack read as a list of its own echoes — the "
            "designer's whole note",
      );
      expect(
        find.textContaining('SUPPLIES'),
        findsNothing,
        reason: 'a section header left behind is a section left behind',
      );
      for (final gone in const [
        'From your pack',
        'On your belt',
        'Nothing to drink.',
      ]) {
        expect(
          find.text(gone),
          findsNothing,
          reason:
              '"$gone" only ever labelled the two supply groups; with one '
              'list there is nothing left for it to tell apart',
        );
      }
      expect(
        find.widgetWithText(TextButton, 'Use'),
        findsOneWidget,
        reason:
            'the ration is drinkable, so its own row carries the verb — a '
            'Pack without Use sends the player to a panel that is gone',
      );
      expect(
        find.textContaining('Restores 25 health'),
        findsOneWidget,
        reason:
            'the effect line came along with the button; a mutant that drops '
            'it leaves "Use" meaning nothing in particular',
      );
    });

    testWidgets('tapping the row Use heals, and empties the slot', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.run!.playerHp = 40;
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Use'));
      await tester.pumpAndSettle();

      expect(
        game.run!.playerHp,
        greaterThan(40),
        reason: 'the row never called GameState.useItem — the whole point',
      );
      expect(
        game.profile.backpack.countOf('foragers_ration'),
        0,
        reason: 'a heal that does not spend the ration duplicates it',
      );
      expect(
        find.text("Forager's Ration"),
        findsNothing,
        reason:
            'a Pack still drawing the drunk row did not rebuild, and the '
            'next tap would drink a ration that is already gone',
      );
      expect(find.textContaining('You recover'), findsOneWidget);
    });

    /// ⭐ The health line lived here for exactly one day (2026-09-21, morning)
    /// before the same day's mockup ruling moved it into the Next-fight card.
    /// `adventure_screen_test.dart` pins where it went; this pins that it did
    /// not stay behind as well — printing the pool twice on one screen is what
    /// the ruling was written to stop.
    testWidgets('⭐ the Pack prints no health of its own any more', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.run!.playerHp = 40;
      await _pump(tester, game);

      // The Pack's own body — the GamePanel under its section label, not the
      // Column that merely holds both.
      final packBody = find.descendant(
        of: find
            .ancestor(
              of: find.textContaining('PACK ·'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(GamePanel),
      );
      expect(packBody, findsOneWidget);
      expect(
        find.descendant(
          of: packBody,
          matching: find.textContaining('Health 40 / ${game.maxHp}'),
        ),
        findsNothing,
        reason:
            'a mutant that reverts the move leaves the pool stated twice on '
            'one screen, which is the duplication the mockup deleted',
      );
      expect(
        find.descendant(
          of: packBody,
          matching: find.textContaining('nothing to heal'),
        ),
        findsNothing,
        reason:
            'the full-health note belongs beside the bar on the Next-fight '
            'card; a copy here is a second reading to keep in step',
      );
      expect(
        find.descendant(
          of: packBody,
          matching: find.textContaining('/ ${game.maxHp}'),
        ),
        findsNothing,
        reason:
            'nothing on this panel quotes the pool now, however it is worded '
            '— a mutant that keeps the reading and only drops the word '
            '"Health" would slip past a check on that word alone',
      );
    });

    testWidgets('⚠️ an empty pack keeps its panel', (tester) async {
      final game = await _onAdventure();
      await _pump(tester, game);

      expect(
        find.text('Your pack is empty.'),
        findsOneWidget,
        reason:
            'a panel that vanishes when empty makes the Belt bay under it '
            'jump up the screen mid-tap',
      );
    });

    testWidgets('⚠️ a row missing a button still reserves its cell', (
      tester,
    ) async {
      final game = await _onAdventure();
      // Three shapes of row, on purpose: the draught is Usable AND Beltable,
      // the ration is Usable only, the log is neither.
      game.profile.backpack = game.profile.backpack
          .withAdded(const InventorySlot(defId: 'sapwort_draught'))!
          .withAdded(const InventorySlot(defId: 'foragers_ration'))!
          .withAdded(const InventorySlot(defId: 'oak_log'))!;
      await _pump(tester, game);

      final uses = find.widgetWithText(TextButton, 'Use');
      final drops = find.widgetWithText(TextButton, 'Drop');
      expect(drops, findsNWidgets(3));
      expect(
        uses,
        findsNWidgets(2),
        reason:
            'a log is not Usable, and a Use on its row would be a button '
            'whose only outcome is a refusal',
      );
      expect(
        find.widgetWithText(TextButton, 'Belt'),
        findsOneWidget,
        reason: 'only the draught is Beltable',
      );
      expect(
        tester.getTopLeft(uses.at(1)).dx,
        tester.getTopLeft(uses.at(0)).dx,
        reason:
            "the ration has no Belt button, so unless its row reserves that "
            'cell its Use slides a whole column right — and the Use the '
            'player aimed at on the row above is now a Belt',
      );
      // ⚠️ The name cell is Expanded, so it swallows any cell a row fails to
      // reserve: where the trailing block STARTS is the only thing that says
      // whether the columns really line up.
      double trailingStartsAt(String name) => tester
          .getTopRight(
            find
                .ancestor(of: find.text(name), matching: find.byType(Column))
                .first,
          )
          .dx;
      expect(
        trailingStartsAt('Oak Log'),
        trailingStartsAt('Sapwort Draught'),
        reason:
            'a log row that reserves neither Use nor Belt gives its name 148 '
            'extra pixels and starts its buttons there — the columns stop '
            'being columns, which is the press-stability rule',
      );
      expect(
        tester.getTopLeft(drops.at(2)).dx,
        tester.getTopLeft(drops.at(0)).dx,
        reason:
            'Drop is the one button on every row; a per-row action width '
            'would move it under the finger between rows',
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

    testWidgets('⭐ a belted potion is drunk from its own slot', (tester) async {
      final game = await _onAdventure();
      // ⚠️ A worn belt, so the bay survives the drink: with capacity 0 the
      // whole bay is gone the moment the last slot empties (the town's own
      // condition) and "did it rebuild?" has nothing left to ask.
      game.profile.itemInstances['b'] = const ItemInstance(
        instanceId: 'b',
        defId: 'fawnhide_belt',
      );
      game.profile.equipped[EquipSlot.belt] = 'b';
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      game.run!.playerHp = 40;
      await _pump(tester, game);

      await tester.tap(_beltSlot);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextButton, 'Drink'),
        findsOneWidget,
        reason:
            'with Supplies gone the slot IS the door — a belted potion with '
            'no way to drink it between fights is the ruling half-done',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Drink'));
      await tester.pumpAndSettle();

      expect(
        game.profile.belt.loaded,
        isEmpty,
        reason:
            'the action must call useBeltItem — routed at useItem it refuses '
            '("You are not carrying that") for a potion in plain sight',
      );
      expect(
        game.run!.playerHp,
        greaterThan(40),
        reason: 'a Drink that unloads without healing is theft',
      );
      expect(
        find.textContaining('Belt — 0/'),
        findsOneWidget,
        reason: 'the bay that still draws the drunk potion never rebuilt',
      );
      expect(
        find.textContaining('You recover'),
        findsOneWidget,
        reason:
            'the bay owns no banner, so a screen that does not report the '
            'outcome leaves the tap looking like nothing happened',
      );
    });

    testWidgets('⚠️ a full-health Drink is refused out loud, not swallowed', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      await _pump(tester, game); // full health

      await tester.tap(_beltSlot);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Drink'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already at full health'),
        findsOneWidget,
        reason: 'a silent no-op reads as the game being broken',
      );
      expect(game.profile.belt.loaded, [
        'sapwort_draught',
      ], reason: 'a refusal that still empties the slot drinks it for you');
    });
  });

  group('the belt bay in town', () {
    testWidgets('⚠️ Drink is greyed with the reason, never hidden', (
      tester,
    ) async {
      // No run at all — the inventory tab's belt, not the road's.
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      game.profile.belt = const Belt(loaded: ['sapwort_draught']);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BeltBay(game: game)),
        ),
      );

      await tester.tap(_beltSlot);
      await tester.pumpAndSettle();

      final drink = find.widgetWithText(TextButton, 'Drink');
      expect(
        drink,
        findsOneWidget,
        reason:
            'a Drink that is simply absent in town teaches the player that '
            'belted potions cannot be drunk at all — the 2026-08-17 rule',
      );
      expect(
        tester.widget<TextButton>(drink).onPressed,
        isNull,
        reason:
            'useBeltItem with no run answers "Not on an adventure." — a '
            'refusal is not a menu item',
      );
      expect(
        find.textContaining('Only between fights'),
        findsOneWidget,
        reason: 'the reason has to be readable without a hover',
      );
      expect(
        find.text('Take off belt'),
        findsOneWidget,
        reason: 'the unload the town dialog always had must survive',
      );
      expect(game.profile.belt.loaded, ['sapwort_draught']);
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
