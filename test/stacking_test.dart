/// Dust stacks to 25 in a backpack slot, Shards to 5, and nothing else stacks
/// (ruling, Christian 2026-09-25, mockup option A).
///
/// ⭐ **Every "how many" is summed across stacks; every "is there room" asks
/// the pack.** The ruling touches the backpack's arithmetic and then every
/// reader of it — crafting, the shop, the loot picker, Drop, the Storeroom and
/// the repair sweep — so this file walks each of them once, with the mutant
/// each assertion kills named in its reason.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:masters_of_magic_2/ui/stack_count_badge.dart';

const _dust = 'pyro_dust';
const _shard = 'pyro_shard';
const _crystal = 'pyro_crystal';

/// The counts of every [defId] slot, in slot order.
List<int> _stacks(Backpack pack, String defId) => [
  for (final s in pack.contents)
    if (s.defId == defId) s.count,
];

/// A pack of [n] slots, [n] Oak Logs — a common that never stacks, to fill
/// room without touching the Dust arithmetic under test.
List<InventorySlot> _logs(int n) => [
  for (var i = 0; i < n; i++) const InventorySlot(defId: 'oak_log'),
];

final _woods = World.byId('whispering_woods');

Future<GameState> _onAdventure() async {
  final game = GameState(_Mem(), PlayerProfile.newPlayer());
  await game.beginAdventure(_woods, rng: Random(3));
  return game;
}

/// ⚠️ A ListView only builds what fits; the Pack panel sits at the bottom.
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

void main() {
  group('the caps', () {
    test('⭐ Dust 25, Shard 5, and everything else 1', () {
      expect(
        ItemCatalogue.byId(_dust).stackSize,
        25,
        reason: 'the ruled Dust cap',
      );
      expect(
        ItemCatalogue.byId(_shard).stackSize,
        5,
        reason: 'the ruled Shard cap — a mutant giving shards 25 fails here',
      );
      expect(
        ItemCatalogue.byId(_crystal).stackSize,
        1,
        reason:
            '⚠️ ONLY dust and shards stack — a mutant keying on MoteDef '
            'alone stacks crystals too',
      );
      for (final id in ['oak_log', 'sapwort_draught']) {
        expect(
          ItemCatalogue.byId(id).stackSize,
          1,
          reason:
              '$id is fungible and still one per slot — a mutant keying '
              'stacking on isFungible makes a gathering run unbounded',
        );
      }
    });
  });

  group('the backpack', () {
    test('⭐ 30 Dust into an empty pack is two slots: 25 + 5', () {
      final pack = Backpack.empty().withAdded(
        const InventorySlot(defId: _dust, count: 30),
      )!;
      expect(_stacks(pack, _dust), [
        25,
        5,
      ], reason: 'a mutant without the cap puts 30 in one slot');
      expect(
        pack.countOf(_dust),
        30,
        reason: 'countOf must SUM counts — a slot-counting mutant says 2',
      );
      expect(
        pack.stacksOf(_dust),
        2,
        reason: 'stacksOf is the UI\'s slot count, not the item count',
      );
      expect(
        pack.free,
        Carrying.backpackSlots - 2,
        reason: 'free is about SLOTS: 30 Dust costs two of them, not thirty',
      );
    });

    test('⭐ one Dust tops a 24-stack to 25 before opening a slot', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 24),
      ]).withAdded(const InventorySlot(defId: _dust))!;
      expect(_stacks(pack, _dust), [
        25,
      ], reason: 'a mutant that always opens a new slot yields [24, 1]');
      expect(pack.used, 1);
    });

    test('⚠️ stacks are topped up lowest-count first', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 20),
        const InventorySlot(defId: _dust, count: 10),
      ]).withAdded(const InventorySlot(defId: _dust, count: 3))!;
      expect(
        _stacks(pack, _dust),
        [20, 13],
        reason:
            'the ruled order — a mutant topping the fullest first yields '
            '[23, 10]',
      );
    });

    test('⭐ Shards cap at 5', () {
      final pack = Backpack.empty().withAdded(
        const InventorySlot(defId: _shard, count: 7),
      )!;
      expect(_stacks(pack, _shard), [
        5,
        2,
      ], reason: 'a mutant reading the Dust cap for every mote yields [7]');
    });

    test('⚠️ a Crystal never stacks', () {
      final pack = Backpack.empty()
          .withAdded(const InventorySlot(defId: _crystal))!
          .withAdded(const InventorySlot(defId: _crystal))!;
      expect(
        _stacks(pack, _crystal),
        [1, 1],
        reason:
            'crystals are one per slot — a stacking-every-mote mutant '
            'yields [2]',
      );
    });

    test('⚠️ all-or-nothing: no room for the whole remainder adds nothing', () {
      final full = Backpack.of([
        ..._logs(Carrying.backpackSlots - 1),
        const InventorySlot(defId: _dust, count: 20),
      ]);
      expect(
        full.withAdded(const InventorySlot(defId: _dust, count: 6)),
        isNull,
        reason:
            'only 5 fit — a mutant that tops up and then reports success '
            'silently destroys the sixth',
      );
      expect(
        full.withAdded(const InventorySlot(defId: _dust, count: 5)),
        isNotNull,
        reason: 'exactly the headroom fits with no free slot',
      );
      expect(full.roomFor(_dust), 5, reason: 'room is the headroom here');
      expect(
        full.roomFor('oak_log'),
        0,
        reason: 'a non-stacker has room only in free slots',
      );
    });

    test('⭐ removing 3 by def from [25, 5] leaves [25, 2]', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 25),
        const InventorySlot(defId: _dust, count: 5),
      ]).withRemovedFirst(_dust, n: 3);
      expect(
        _stacks(pack, _dust),
        [25, 2],
        reason:
            'smallest stack first — a first-slot mutant yields [22, 5], and '
            'the old whole-slot removal yields [25] or []',
      );
    });

    test('⭐ removing past a stack empties it and moves on', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 25),
        const InventorySlot(defId: _dust, count: 5),
      ]).withRemovedFirst(_dust, n: 7);
      expect(_stacks(pack, _dust), [
        23,
      ], reason: 'the 5-stack goes to 0 and its slot empties, then 2 more');
      expect(pack.used, 1, reason: 'a 0-count slot must not linger');
    });

    test('⚠️ withRemovedAt drops the WHOLE stack', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 12),
      ]).withRemovedAt(0);
      expect(
        pack.countOf(_dust),
        0,
        reason:
            'Drop and Stow take the slot — a decrement-by-one mutant '
            'leaves 11',
      );
    });
  });

  group('JSON', () {
    test('⭐ a stack round-trips, and a legacy slot reads as 1', () {
      final pack = Backpack.of([
        const InventorySlot(defId: _dust, count: 12),
        const InventorySlot(defId: 'oak_log'),
      ]);
      final back = Backpack.fromJson(pack.toJson());
      expect(
        back.slots.first!.count,
        12,
        reason: 'a save that drops `count` turns 12 Dust into 1',
      );
      expect(
        pack.toJson()[1],
        {'defId': 'oak_log'},
        reason:
            'count is written only when > 1 — every single-item slot keeps '
            'the exact shape it had before stacking',
      );
      expect(
        InventorySlot.fromJson(const {'defId': _dust}).count,
        1,
        reason: 'every pre-stacking save must load unchanged',
      );
    });
  });

  group('the readers', () {
    test('⭐ crafting 30 Dust from [25, 5] leaves nothing', () async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: _dust, count: 25),
        const InventorySlot(defId: _dust, count: 5),
      ]);
      const refine = RecipeDef(
        id: 'zz_test_refine',
        outputId: _shard,
        skill: CraftSkill.enchanting,
        skillLevel: 1,
        inputs: [RecipeInput(_dust, 30)],
      );
      final outcome = await game.craft(refine, rng: Random(1));
      expect(
        outcome.refusal,
        isNull,
        reason: 'a slot-counting gate sees 2 Dust and refuses',
      );
      expect(
        game.profile.backpack.countOf(_dust),
        0,
        reason: 'the craft consumes by count across both stacks',
      );
      expect(game.profile.backpack.countOf(_shard), 1);
    });

    test('⚠️ crafting 3 Dust from [25, 5] leaves [25, 2]', () async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: _dust, count: 25),
        const InventorySlot(defId: _dust, count: 5),
      ]);
      const pinch = RecipeDef(
        id: 'zz_test_pinch',
        outputId: _shard,
        skill: CraftSkill.enchanting,
        skillLevel: 1,
        inputs: [RecipeInput(_dust, 3)],
      );
      await game.craft(pinch, rng: Random(1));
      expect(
        _stacks(game.profile.backpack, _dust),
        [25, 2],
        reason:
            'a craft that removes whole slots eats the 5-stack for a '
            'recipe asking 3',
      );
    });

    test('⭐ selling a 12-stack pays 12× the unit price', () async {
      const town = 'hearthwood';
      final game = GameState(_Mem(), PlayerProfile.newPlayer()..gold = 0)
        ..profile.locationId = town;
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: _dust, count: 12),
      ]);
      expect(
        ShopCatalogue.stockFor(town),
        isNot(contains(_dust)),
        reason:
            'precondition: an unstocked item sells at the flat vendor '
            'price, so 12× is exact',
      );
      final today = ShopState.epochDayOf(game.now());
      final outcome = await game.settleShopBasket(
        townId: town,
        today: today,
        buy: const {},
        sellStacks: const {_dust: 12},
        sellInstances: const {},
      );
      expect(
        outcome.refusal,
        isNull,
        reason: 'a slot-counting `available` says you hold 1 and refuses',
      );
      final unit = ShopPricing.vendorPrice(ItemCatalogue.byId(_dust).value);
      expect(unit, greaterThan(0), reason: 'precondition: dust is worth gold');
      expect(
        game.profile.gold,
        12 * unit,
        reason: 'the whole stack is sold, one unit price each',
      );
      expect(game.profile.backpack.countOf(_dust), 0);
    });

    test('⚠️ selling 3 of a 12-stack leaves 9 in the slot', () async {
      const town = 'hearthwood';
      final game = GameState(_Mem(), PlayerProfile.newPlayer())
        ..profile.locationId = town;
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: _dust, count: 12),
      ]);
      await game.settleShopBasket(
        townId: town,
        today: ShopState.epochDayOf(game.now()),
        buy: const {},
        sellStacks: const {_dust: 3},
        sellInstances: const {},
      );
      expect(
        game.profile.backpack.countOf(_dust),
        9,
        reason:
            'the sell walk removes by count — a whole-slot removal sells '
            '3 and destroys the other 9',
      );
    });

    test(
      '⭐ the Storeroom moves whole stacks, and the pack re-forms them',
      () async {
        const town = 'hearthwood';
        final game = GameState(_Mem(), PlayerProfile.newPlayer())
          ..profile.locationId = town;
        game.profile.backpack = Backpack.of([
          const InventorySlot(defId: _dust, count: 12),
        ]);
        await game.deposit(town, 0);
        expect(
          game.profile.storerooms[town]!.stacks[_dust],
          12,
          reason: 'stowing a stack stores its count — a +1 mutant loses 11',
        );
        game.profile.storerooms[town] = const Storeroom(stacks: {_dust: 40});
        final moved = await game.takeAllFromStoreroom(town, _dust);
        expect(moved, 40);
        expect(_stacks(game.profile.backpack, _dust), [
          25,
          15,
        ], reason: 'withdrawn Dust forms stacks, not forty slots');
      },
    );

    test('⚠️ a full pack still takes Dust onto a short stack', () async {
      const town = 'hearthwood';
      final game = GameState(_Mem(), PlayerProfile.newPlayer())
        ..profile.locationId = town;
      game.profile.backpack = Backpack.of([
        ..._logs(Carrying.backpackSlots - 1),
        const InventorySlot(defId: _dust, count: 20),
      ]);
      game.profile.storerooms[town] = const Storeroom(stacks: {_dust: 9});
      final ok = await game.withdraw(town, const InventorySlot(defId: _dust));
      expect(
        ok,
        isTrue,
        reason: 'a free-slot gate refuses a pack with headroom on its stack',
      );
      expect(game.profile.backpack.countOf(_dust), 21);
    });

    test('⭐ repair clamps a count of 40 to 25, and counts it', () {
      final p = PlayerProfile.newPlayer()
        ..backpack = Backpack.of([
          const InventorySlot(defId: _dust, count: 40),
          const InventorySlot(defId: 'oak_log', count: 3),
          const InventorySlot(defId: _shard, count: 4),
        ]);
      final repaired = p.repairContainers();
      expect(
        p.backpack.slots[0]!.count,
        25,
        reason: 'a 40-stack is items the pack never paid room for',
      );
      expect(
        p.backpack.slots[1]!.count,
        1,
        reason: 'a count on a non-stacker is clamped to its cap of 1',
      );
      expect(
        p.backpack.slots[2]!.count,
        4,
        reason: 'an in-range stack is left alone',
      );
      expect(
        repaired,
        2,
        reason: 'each clamp counts as a repair — a silent fix is a mutant',
      );
    });
  });

  group('the loot picker', () {
    test('⭐ a drop of n Dust is one row', () async {
      final game = await _onAdventure();
      game.run!.recordVictory(
        loot: [
          for (var i = 0; i < 7; i++) const InventorySlot(defId: _dust),
          const InventorySlot(defId: 'oak_log'),
          const InventorySlot(defId: 'oak_log'),
        ],
        instances: const {},
        remainingHp: 90,
      );
      final rows = game.run!.unclaimed;
      expect(
        [for (final r in rows) (r.defId, r.count)],
        [(_dust, 7), ('oak_log', 1), ('oak_log', 1)],
        reason:
            'Dust collapses to one row; logs (which do not stack) stay a '
            'row each',
      );
    });

    testWidgets(
      "⭐ 'Pyro Dust ×7' lands in a stack with headroom and no free slot",
      (tester) async {
        final game = await _onAdventure();
        game.profile.backpack = Backpack.of([
          ..._logs(Carrying.backpackSlots - 1),
          const InventorySlot(defId: _dust, count: 18),
        ]);
        game.run!.recordVictory(
          loot: [for (var i = 0; i < 7; i++) const InventorySlot(defId: _dust)],
          instances: const {},
          remainingHp: 90,
        );
        await _pump(tester, game);

        expect(
          find.text('Pyro Dust ×7'),
          findsOneWidget,
          reason: 'the drop is ONE row naming its count',
        );
        expect(
          find.text('no room'),
          findsNothing,
          reason:
              'the stack has 7 headroom — a free-slot mutant says no room '
              'on a pack that can take it',
        );
        expect(
          find.text('Take 1'),
          findsOneWidget,
          reason:
              'the opening tick asks the pack too — a `take(free)` default '
              'opens this picker on "Leave it all behind"',
        );

        // ⚠️ Untick and re-tick: the row's own gate is only consulted while
        // it is unticked, so this is what pins it.
        await tester.tap(find.text('Pyro Dust ×7'));
        await tester.pump();
        expect(
          find.text('no room'),
          findsNothing,
          reason:
              'an unticked Dust row with headroom is still takeable — a '
              'picker gating on `picked >= free` locks it at 0 free slots',
        );
        await tester.tap(find.text('Pyro Dust ×7'));
        await tester.pump();

        await tester.tap(find.text('Take 1'));
        await tester.pumpAndSettle();
        expect(_stacks(game.profile.backpack, _dust), [
          25,
        ], reason: 'the claim tops the carried stack rather than refusing');
        expect(
          find.text('7 into your pack.'),
          findsOneWidget,
          reason: 'the receipt counts items, not rows',
        );
      },
    );
  });

  group('drop and the badge', () {
    testWidgets('⚠️ Drop on a 12-stack of common Dust asks, naming 12', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = Backpack.empty().withAdded(
        const InventorySlot(defId: _dust, count: 12),
      )!;
      expect(
        ItemCatalogue.byId(_dust).rarity,
        Rarity.common,
        reason: 'precondition: a common, which alone would skip the ask',
      );
      await _pump(tester, game);

      await tester.tap(find.widgetWithText(TextButton, 'Drop'));
      await tester.pumpAndSettle();
      expect(
        find.text('Drop all 12 Pyro Dust?'),
        findsOneWidget,
        reason:
            'a stack always asks — the commons skip is for a count of 1, '
            'and one tap must not destroy twelve',
      );
      expect(find.text('It is destroyed. Nothing comes back.'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Drop'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf(_dust),
        0,
        reason: 'Drop takes the whole stack',
      );
    });

    testWidgets('⭐ the pack row wears the count; a full stack turns gold', (
      tester,
    ) async {
      final game = await _onAdventure();
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: _dust, count: 12),
        const InventorySlot(defId: _shard, count: 5),
        const InventorySlot(defId: 'oak_log'),
      ]);
      await _pump(tester, game);

      Color colourOf(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;
      expect(
        colourOf('×12'),
        AppColors.text,
        reason: 'below the cap the badge is plain text colour',
      );
      expect(
        colourOf('×5'),
        AppColors.gold,
        reason:
            'a full Shard stack (5) is gold — a mutant comparing against '
            'the Dust cap never lights a shard',
      );
      expect(
        find.text('×1'),
        findsNothing,
        reason: 'a single item carries no badge at all',
      );
    });

    testWidgets('⚠️ the badge is a fixed cell, and gold only at the cap', (
      tester,
    ) async {
      Future<Size> sizeOf(int count) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: StackCountBadge(count: count, cap: 25)),
          ),
        );
        return tester.getSize(find.byType(StackCountBadge));
      }

      final small = await sizeOf(2);
      final full = await sizeOf(25);
      expect(
        full,
        small,
        reason:
            'a pill sized to its text would reflow the tile as the count '
            'grows — press-stability',
      );
      expect(
        tester.widget<Text>(find.text('×25')).style!.color,
        AppColors.gold,
        reason: 'a full Dust stack is gold',
      );
      await sizeOf(24);
      expect(
        tester.widget<Text>(find.text('×24')).style!.color,
        AppColors.text,
        reason: 'one short of the cap is not full — an off-by-one mutant',
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
