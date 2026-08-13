/// The two things the adventure screen owes the player between fights: a way
/// to eat, and a say in what comes home.
///
/// ⭐ Both come from real playtest reports — "no way to eat a ration" and a
/// rare lost to a silent overflow. `loot_picker_test.dart` pins the rules; this
/// file pins that the screen actually reaches them.
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

  group('the take-home step', () {
    testWidgets('walking out opens the picker, defaulting to the epic', (
      tester,
    ) async {
      final game = await _onAdventure();
      var pack = game.profile.backpack;
      for (var i = 0; i < Carrying.backpackSlots - 1; i++) {
        pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
      }
      game.profile.backpack = pack;
      game.run!
        ..pendingLoot.addAll(const [
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
        ])
        ..pendingInstances['inst-1'] = const ItemInstance(
          instanceId: 'inst-1',
          defId: 'heartwood_stave',
        );

      await _pump(tester, game);
      await tester.tap(find.text('Return to town'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Take 1 home'));
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.countOf('heartwood_stave'),
        1,
        reason: 'the default kept the log and abandoned the epic',
      );
      expect(
        find.textContaining('Left behind'),
        findsOneWidget,
        reason: 'the receipt has to name what the choice cost',
      );
      expect(
        find.text('Back to the map'),
        findsOneWidget,
        reason: 'the way out stays shut once the haul is answered for',
      );
    });

    testWidgets('⚠️ the exit is barred while loot is still unclaimed', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.run!.pendingLoot.add(const InventorySlot(defId: 'oak_log'));
      await game.leaveAdventure();
      await _pump(tester, game);

      final exit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Back to the map'),
      );
      expect(
        exit.onPressed,
        isNull,
        reason:
            'leaving mid-choice strands a finished run holding loot the '
            'player believes they already took',
      );
    });

    testWidgets('a run that died shows no picker at all', (tester) async {
      final game = await _onAdventure();
      game.run!.pendingLoot.add(const InventorySlot(defId: 'oak_log'));
      await game.loseEncounter();
      await _pump(tester, game);

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
