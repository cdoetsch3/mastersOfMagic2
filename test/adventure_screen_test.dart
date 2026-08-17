/// The two things the adventure screen owes the player between fights: a way
/// to eat, and a say in what comes home.
///
/// ⭐ Both come from real playtest reports — "no way to eat a ration" and a
/// rare lost to a silent overflow. `loot_picker_test.dart` pins the rules; this
/// file pins that the screen actually reaches them.
///
/// ⚠️ Since the 2026-08-17 ruling the say happens **after every fight**, not at
/// the end of the run, and dying costs the whole backpack — so the panels this
/// file drives are the victory picker and the defeat notice.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';

final _woods = World.byId('whispering_woods');

/// ⚠️ A ListView only builds what fits, and both panels under test sit below
/// the fold on the default 800x600 viewport.
Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
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

void main() {
  group('supplies between fights', () {
    testWidgets('a carried ration is listed, with the health it heals against', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.run!.playerHp = 40;
      await _pump(tester, game);

      expect(find.text("Forager's Ration"), findsOneWidget);
      expect(
        find.textContaining('Restores 25% health'),
        findsOneWidget,
        reason: 'the row must say what using it does, built from the effect',
      );
      expect(
        find.textContaining('Health 40 / ${game.maxHp}'),
        findsOneWidget,
        reason:
            'without the pool it heals against, "25%" is half an answer and a '
            'refusal at full health looks like a broken button',
      );
    });

    testWidgets('tapping Use actually heals, from this screen', (tester) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      game.run!.playerHp = 40;
      await _pump(tester, game);

      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      expect(
        game.run!.playerHp,
        greaterThan(40),
        reason: 'the screen never called GameState.useItem — the whole bug',
      );
      expect(
        game.profile.backpack.countOf('foragers_ration'),
        0,
        reason: 'a heal that does not spend the ration duplicates it',
      );
      expect(find.textContaining('You recover'), findsOneWidget);
    });

    testWidgets('⚠️ a refusal is said out loud, not swallowed', (tester) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'foragers_ration'),
      )!;
      await _pump(tester, game); // full health

      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already at full health'),
        findsOneWidget,
        reason: 'a silent no-op reads as the game being broken',
      );
      expect(game.profile.backpack.countOf('foragers_ration'), 1);
    });
  });

  group('the victory picker', () {
    /// Wins a fight whose drops are [loot], the way `winEncounter` leaves the
    /// run: parked, unanswered, and the screen's problem now.
    void justWon(GameState game, List<InventorySlot> loot) {
      game.run!.recordVictory(
        loot: loot,
        instances: const {
          'inst-1': ItemInstance(
            instanceId: 'inst-1',
            defId: 'heartwood_stave',
          ),
        },
        remainingHp: 90,
      );
    }

    testWidgets('⭐ the rarest drop is listed first, whatever order it fell in',
        (tester) async {
      final game = await _onAdventure();
      justWon(game, const [
        InventorySlot(defId: 'oak_log'),
        InventorySlot(defId: 'flora_crystal'),
        InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
      ]);
      await _pump(tester, game);

      final rows = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where(
            (s) => const [
              'Oak Log',
              'Flora Crystal',
              'Heartwood Staff',
            ].contains(s),
          )
          .toList();
      expect(
        rows,
        ['Heartwood Staff', 'Flora Crystal', 'Oak Log'],
        reason:
            'rendering in drop order buries the epic under a log — the row '
            'that decides the choice has to be the one on top',
      );
    });

    testWidgets('a win opens the picker, defaulting to the epic', (
      tester,
    ) async {
      final game = await _onAdventure();
      var pack = game.profile.backpack;
      for (var i = 0; i < Carrying.backpackSlots - 1; i++) {
        pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
      }
      game.profile.backpack = pack;
      justWon(game, const [
        InventorySlot(defId: 'oak_log'),
        InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
      ]);

      await _pump(tester, game);

      expect(
        find.textContaining('Taking 1 of 2 — 1 slot free'),
        findsOneWidget,
        reason: 'the live counter is what makes the greyed-out row explicable',
      );
      expect(
        find.text('no room'),
        findsOneWidget,
        reason: 'the item that does not fit has to say why it cannot be picked',
      );

      await tester.tap(find.text('Take 1'));
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.countOf('heartwood_stave'),
        1,
        reason: 'the default kept the log and abandoned the epic',
      );
      expect(
        game.profile.itemInstances.containsKey('inst-1'),
        isTrue,
        reason: 'a claimed staff with no instance behind it is a nameless husk',
      );
      expect(
        find.textContaining('left behind: Oak Log'),
        findsOneWidget,
        reason: 'the confirmation has to name what the choice cost',
      );
      expect(
        find.textContaining('Taking'),
        findsNothing,
        reason: 'an answered picker that stays on screen can be answered twice',
      );
    });

    testWidgets('⚠️ nothing else is offered until the picker is answered', (
      tester,
    ) async {
      final game = await _onAdventure();
      justWon(game, const [InventorySlot(defId: 'oak_log')]);
      await _pump(tester, game);

      expect(
        find.text('Fight'),
        findsNothing,
        reason:
            'walking into the next fight past an unanswered picker leaves the '
            'drops to be merged into the next batch — one question at a time',
      );
      expect(find.text('Return to town'), findsNothing);
      expect(find.text('Use'), findsNothing,
          reason: 'the supplies panel is a second decision competing with the '
              'one where something can be lost');

      await tester.tap(find.text('Take 1'));
      await tester.pumpAndSettle();
      expect(
        find.text('Fight'),
        findsOneWidget,
        reason: 'answering the picker has to give the run back',
      );
    });

    testWidgets('⚠️ a cleared run keeps its exit shut until loot is answered', (
      tester,
    ) async {
      final game = await _onAdventure();
      final run = game.run!;
      while (!run.isFinished) {
        run.recordVictory(loot: const [], instances: const {}, remainingHp: 70);
      }
      run.unclaimed.add(const InventorySlot(defId: 'flora_crystal'));
      await _pump(tester, game);

      expect(
        find.text('Back to the map'),
        findsNothing,
        reason:
            'leaving mid-choice strands a finished run holding loot the '
            'player believes they already took',
      );
      await tester.tap(find.text('Take 1'));
      await tester.pumpAndSettle();
      expect(
        find.text('Back to the map'),
        findsOneWidget,
        reason: 'the door has to open again once the choice is made',
      );
    });

    testWidgets('nothing dropped means no picker', (tester) async {
      final game = await _onAdventure();
      justWon(game, const []);
      await _pump(tester, game);
      expect(
        find.textContaining('Taking'),
        findsNothing,
        reason: 'a picker with no rows is a button that asks for nothing',
      );
      expect(find.text('Fight'), findsOneWidget);
    });
  });

  group('the defeat notice', () {
    testWidgets('⚠️ death says the pack is gone, and what survived', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'oak_log'),
      )!;
      await game.loseEncounter();
      await _pump(tester, game);

      expect(
        find.textContaining('backpack'),
        findsOneWidget,
        reason:
            'the 2026-08-17 penalty is the whole inventory — a player who is '
            'not told has to work it out from an empty pack later',
      );
      expect(
        find.textContaining('belt'),
        findsOneWidget,
        reason:
            'the exemptions are the panel\'s promise: gear and belt came back',
      );
      expect(find.textContaining('Taking'), findsNothing);
      expect(
        find.text('Back to the map'),
        findsOneWidget,
        reason: 'death forfeits the loot, so there is nothing to choose from',
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
