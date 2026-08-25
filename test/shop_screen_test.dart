/// The town Shop (`ECONOMY_CONTRACT.md` §2/§3/§6/§14b) — the designer's
/// ruled basket-settle transaction model: every stepper on Buy and Sell
/// edits one in-memory basket, nothing debits/credits/persists until Settle
/// fires ONE atomic mutation.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a stepper that debits gold on tap, a settle that charges a
/// different number than it showed, a sell that skips the Storeroom, a
/// basket that survives leaving the screen, a bound item that sells anyway.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/shop_screen.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

// ---- fixtures ---------------------------------------------------------
//
// Hearthwood (the starting town) is open, and its native stock spans four
// zones. `oak_log` and `bindweed_fibre` — the contract's own worked example
// ("buy 5 oak ... sell 10 bindweed") — are both native here (E=60,
// locationMod 0.75), so a fresh visit always starts them at stock 60. Values
// come straight off the catalogue (13 and 10) rather than being restated,
// so a content edit cannot make this suite pass while quoting the wrong
// number.

const _townId = 'hearthwood';
const _oak = 'oak_log';
const _bindweed = 'bindweed_fibre';
const _belt = 'tuskhide_belt'; // EquipmentDef, tradeable, value 110.
const _boundKey = 'proof_of_the_woods'; // KeyDef — always Tradability.bound.

String _name(String defId) => ItemCatalogue.displayName(ItemCatalogue.byId(defId));

DateTime _atEpochDay(int day) =>
    DateTime.utc(1970, 1, 1).add(Duration(days: day));

/// ⭐ Derived, not hardcoded: probed once (see the build notes) that day
/// 19004 is a day `oak_log` draws Hearthwood's daily event (+20%, a spike)
/// and 19000 is a day it does not — but re-deriving here means a change to
/// the deterministic hash still leaves this suite meaningful instead of
/// quietly testing the wrong day.
int _dayWith({required bool event, required String itemId}) {
  for (var d = 19000; d < 19400; d++) {
    final has = ShopState.eventsFor(
      shopId: _townId,
      today: d,
      candidateItemIds: ShopCatalogue.stockFor(_townId),
    ).containsKey(itemId);
    if (has == event) return d;
  }
  throw StateError('no matching day found in range');
}

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  int saveCount = 0;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async {
    saved = profile;
    saveCount++;
  }

  @override
  Future<void> clear() async => saved = null;
}

GameState _game(
  _MemStorage storage, {
  int gold = 1000,
  String locationId = _townId,
  Map<String, int> storeroomStacks = const {},
  List<String> storeroomInstanceIds = const [],
  Map<String, ItemInstance> instances = const {},
  DateTime? now,
}) {
  final profile = PlayerProfile.newPlayer()
    ..gold = gold
    ..locationId = locationId;
  if (storeroomStacks.isNotEmpty || storeroomInstanceIds.isNotEmpty) {
    profile.storerooms[_townId] = Storeroom(
      stacks: storeroomStacks,
      instanceIds: storeroomInstanceIds,
    );
  }
  profile.itemInstances.addAll(instances);
  return GameState(storage, profile, now: now == null ? null : () => now);
}

Finder _rowFor(String itemId) => find.widgetWithText(GamePanel, _name(itemId));

Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: game,
        child: const ShopScreen(townId: _townId),
      ),
    ),
  );
  // The nightly-resupply resolve fires on the next frame (initState's
  // postFrameCallback) — pump past it before trusting any price on screen.
  await tester.pump();
  await tester.pump();
}

Future<void> _tapStepper(
  WidgetTester tester,
  String itemId,
  IconData icon, {
  int times = 1,
}) async {
  for (var i = 0; i < times; i++) {
    final button = find.descendant(of: _rowFor(itemId), matching: find.byIcon(icon));
    await tester.tap(button);
    await tester.pump();
  }
}

Future<void> _switchToSell(WidgetTester tester) async {
  await tester.tap(find.text('Sell').first);
  await tester.pump();
}

/// Parses 'Settle +10g' / 'Settle -3g' off the settle bar's own button —
/// reading the number the screen displays rather than a hand-derived one,
/// so the later gold-delta assertion is checked against what the player
/// actually saw, not what the test author expected them to see.
int _displayedNet(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.textContaining('Settle '))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('Settle '));
  final m = RegExp(r'Settle ([+-]\d+)g').firstMatch(text);
  if (m == null) throw StateError('no settle total found in "$text"');
  return int.parse(m.group(1)!);
}

void main() {
  group('nothing persists before Settle', () {
    testWidgets(
      '⭐ staging buys and sells changes no gold, stock, or Storeroom',
      (tester) async {
        final storage = _MemStorage();
        final game = _game(storage, storeroomStacks: {_bindweed: 20});
        await _pump(tester, game);

        // Baseline AFTER the open-time resolve (§6.1's own persist, not the
        // basket) — the number the rest of this test must not move from.
        final baselineGold = game.profile.gold;
        final baselineStock = game.profile.shopStock[_townId]!.stock;
        final baselineRoom = game.profile.storerooms[_townId]!.stacks;
        final savesAfterResolve = storage.saveCount;

        await _tapStepper(tester, _oak, Icons.add, times: 3);
        await _switchToSell(tester);
        await _tapStepper(tester, _bindweed, Icons.add, times: 4);

        expect(
          game.profile.gold,
          baselineGold,
          reason: 'a stepper tap is a basket edit, never a debit',
        );
        expect(
          game.profile.shopStock[_townId]!.stock,
          baselineStock,
          reason: 'stock only moves at Settle, never while browsing',
        );
        expect(
          game.profile.storerooms[_townId]!.stacks,
          baselineRoom,
          reason: 'the Storeroom is untouched until Settle commits',
        );
        expect(
          storage.saveCount,
          savesAfterResolve,
          reason: 'staging a basket must not write to disk at all',
        );
      },
    );
  });

  group('Settle is one atomic mutation, exact to the displayed net', () {
    testWidgets(
      '⭐ charges EXACTLY the number the settle bar showed, both directions '
      'at once',
      (tester) async {
        final storage = _MemStorage();
        final game = _game(storage, gold: 1000, storeroomStacks: {_bindweed: 20});
        await _pump(tester, game);

        await _tapStepper(tester, _oak, Icons.add, times: 5);
        await _switchToSell(tester);
        await _tapStepper(tester, _bindweed, Icons.add, times: 10);

        // The exact marginal totals the pricing engine itself would quote —
        // computed independently of the screen, so this test does not just
        // check the screen agrees with itself.
        final buyTotal = ShopPricing.buyQuote(
          n: 5,
          base: ItemCatalogue.byId(_oak).value,
          equilibrium: 60,
          stock: 60,
          locationMod: ShopCatalogue.locationModFor(_townId, _oak),
        ).totalGold;
        final sellTotal = ShopPricing.sellQuote(
          n: 10,
          base: ItemCatalogue.byId(_bindweed).value,
          equilibrium: 60,
          stock: 60,
          locationMod: ShopCatalogue.locationModFor(_townId, _bindweed),
        ).totalGold;
        final expectedNet = sellTotal - buyTotal;

        final shown = _displayedNet(tester);
        expect(
          shown,
          expectedNet,
          reason: 'the bar must show the same net the pricing engine quotes',
        );

        await tester.tap(find.textContaining('Settle '));
        await tester.pump();
        await tester.pump();

        expect(
          game.profile.gold,
          1000 + shown,
          reason: '⭐ the mutant this test exists to kill: Settle charging '
              'something other than what it displayed',
        );
        expect(game.profile.storerooms[_townId]!.stacks[_oak], 5,
            reason: 'bought goods land in the Storeroom, not the backpack');
        expect(
          game.profile.storerooms[_townId]!.stacks[_bindweed],
          10,
          reason: 'sold from a Storeroom stack of 20, 10 remain',
        );
        expect(
          game.profile.shopStock[_townId]!.stockOf(_oak),
          60 - 5,
          reason: 'buying drains the shelf',
        );

        // The basket clears and the bar disappears.
        expect(find.textContaining('Settle '), findsNothing);
        expect(find.text('Settled — netted ${shown}g.'), findsOneWidget);
      },
    );

    testWidgets('the save seam receives exactly what Settle produced', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage, storeroomStacks: {_bindweed: 20});
      await _pump(tester, game);

      await _switchToSell(tester);
      await _tapStepper(tester, _bindweed, Icons.add, times: 3);
      await tester.tap(find.textContaining('Settle '));
      await tester.pump();
      await tester.pump();

      expect(
        storage.saved!.gold,
        game.profile.gold,
        reason: 'Settle must persist through the same _mutate/save seam '
            'every other GameState write uses',
      );
      expect(
        storage.saved!.storerooms[_townId]!.stacks[_bindweed],
        game.profile.storerooms[_townId]!.stacks[_bindweed],
      );
    });
  });

  group('selling floods stock and credits gold', () {
    testWidgets('a big sell walks the marginal price down and raises stock', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage, storeroomStacks: {_bindweed: 20});
      await _pump(tester, game);

      await _switchToSell(tester);
      await _tapStepper(tester, _bindweed, Icons.add, times: 15);
      final shown = _displayedNet(tester);

      final expected = ShopPricing.sellQuote(
        n: 15,
        base: ItemCatalogue.byId(_bindweed).value,
        equilibrium: 60,
        stock: 60,
        locationMod: ShopCatalogue.locationModFor(_townId, _bindweed),
      );
      expect(shown, expected.totalGold);

      await tester.tap(find.textContaining('Settle '));
      await tester.pump();
      await tester.pump();

      expect(
        game.profile.shopStock[_townId]!.stockOf(_bindweed),
        expected.newStock,
        reason: 'stock after a sell walk must match the marginal walk exactly',
      );
      expect(
        game.profile.shopStock[_townId]!.stockOf(_bindweed),
        greaterThan(60),
        reason: 'selling floods the shelf above equilibrium',
      );
      expect(game.profile.gold, 1000 + expected.totalGold);
    });
  });

  group('non-stocked gear sells at the flat vendor price, labeled plainly', () {
    testWidgets('⭐ never the marginal walk — gear is never shop stock', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(
        storage,
        storeroomInstanceIds: ['inst-belt'],
        instances: {
          'inst-belt': const ItemInstance(instanceId: 'inst-belt', defId: _belt),
        },
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      final expectedVendor = ShopPricing.vendorPrice(ItemCatalogue.byId(_belt).value);
      expect(
        find.descendant(
          of: _rowFor(_belt),
          matching: find.text('${expectedVendor}g · vendor (flat)'),
        ),
        findsOneWidget,
        reason: 'the row must say plainly this is the flat sink, not a quote',
      );

      await tester.tap(
        find.descendant(of: _rowFor(_belt), matching: find.text('Sell')),
      );
      await tester.pump();

      expect(_displayedNet(tester), expectedVendor);

      await tester.tap(find.textContaining('Settle '));
      await tester.pump();
      await tester.pump();

      expect(game.profile.gold, 1000 + expectedVendor);
      expect(game.profile.storerooms[_townId]!.instanceIds, isEmpty);
      expect(game.profile.itemInstances.containsKey('inst-belt'), isFalse);
      expect(
        game.profile.shopStock[_townId],
        isNot(isNull),
        reason: 'a resolve happened, but gear must not appear in its stock',
      );
      expect(
        game.profile.shopStock[_townId]!.stock.containsKey(_belt),
        isFalse,
        reason: 'gear never enters the stock map at all',
      );
    });
  });

  group('a Bound item refuses to sell', () {
    testWidgets('the row is disabled and cannot enter the basket', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage, storeroomStacks: {_boundKey: 1});
      await _pump(tester, game);
      await _switchToSell(tester);

      expect(
        find.descendant(
          of: _rowFor(_boundKey),
          matching: find.text('Bound — cannot be sold.'),
        ),
        findsOneWidget,
      );
      // No stepper control reaches +1 for a bound row.
      final plus = find.descendant(
        of: _rowFor(_boundKey),
        matching: find.byIcon(Icons.add),
      );
      expect(_isDisabledStepper(tester, plus), isTrue);
    });

    test('⭐ settleShopBasket refuses even if a caller bypasses the UI', () async {
      final storage = _MemStorage();
      final game = _game(storage, storeroomStacks: {_boundKey: 1});
      final today = ShopState.epochDayOf(game.now());
      await game.resolveShop(_townId, today);

      final outcome = await game.settleShopBasket(
        townId: _townId,
        today: today,
        buy: const {},
        sellStacks: const {_boundKey: 1},
        sellInstances: const {},
      );

      expect(outcome.succeeded, isFalse);
      expect(outcome.refusal, 'Bound — cannot be sold.');
      expect(
        game.profile.storerooms[_townId]!.stacks[_boundKey],
        1,
        reason: 'a refused settle must change nothing',
      );
    });
  });

  group('insufficient gold disables Settle with a reason', () {
    testWidgets('the button is disabled and nothing is charged', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage, gold: 3); // Cannot afford 5 oak (~55g).
      await _pump(tester, game);

      await _tapStepper(tester, _oak, Icons.add, times: 5);

      expect(find.text('Not enough gold.'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.onPressed,
        isNull,
        reason: 'a disabled Settle must not be tappable at all',
      );
      expect(game.profile.gold, 3, reason: 'nothing was ever charged');
    });
  });

  group('a buy exceeding stock disables Settle with a reason', () {
    testWidgets('re-validated at Settle time, not just clamped in the UI', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage);
      await _pump(tester, game);

      await _tapStepper(tester, _oak, Icons.add, times: 5);

      // Simulate the shelf changing out from under a staged basket (the
      // guard [GameState.settleShopBasket] re-checks for) — directly, since
      // nothing in a single session can otherwise move stock outside Settle.
      final before = game.profile.shopStock[_townId]!;
      game.profile.shopStock[_townId] = TownShopState(
        stock: {...before.stock, _oak: 2},
        lastResetDay: before.lastResetDay,
      );
      game.notifyListeners();
      await tester.pump();

      expect(find.text('Not enough in stock.'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Confirms the block is real, not just cosmetic.
      final outcome = await game.settleShopBasket(
        townId: _townId,
        today: ShopState.epochDayOf(game.now()),
        buy: const {_oak: 5},
        sellStacks: const {},
        sellInstances: const {},
      );
      expect(outcome.succeeded, isFalse);
      expect(outcome.refusal, 'Not enough in stock.');
      expect(game.profile.gold, 1000, reason: 'a refused settle charges nothing');
    });
  });

  group('the event chip only shows on an event day', () {
    // ⚠️ Two separate `testWidgets`, deliberately — each gets its own fresh
    // `WidgetTester`. Reusing one tester across two `pumpWidget` calls with
    // the same widget shape (a keyless `ShopScreen` in the same tree
    // position) makes Flutter update the SAME `State` rather than remount
    // it, so a second `_today` would never actually take — this bit a first
    // draft of this test, not the screen.
    testWidgets(
      '⭐ the day the deterministic hash picks this item, the chip shows',
      (tester) async {
        final eventDay = _dayWith(event: true, itemId: _oak);
        final onEvent = _game(_MemStorage(), now: _atEpochDay(eventDay));
        await _pump(tester, onEvent);
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.textContaining('Price spike'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('on a day it does not pick this item, the row shows no chip', (
      tester,
    ) async {
      final quietDay = _dayWith(event: false, itemId: _oak);
      final quiet = _game(_MemStorage(), now: _atEpochDay(quietDay));
      await _pump(tester, quiet);
      expect(
        find.descendant(
          of: _rowFor(_oak),
          matching: find.textContaining('Price spike'),
        ),
        findsNothing,
        reason: 'a quiet day must show no event chip on this row at all',
      );
    });
  });

  group('a closed town shows no Shop entry', () {
    testWidgets('the Inventory tab offers no Shop button, only the season line', (
      tester,
    ) async {
      final storage = _MemStorage();
      final game = _game(storage, locationId: 'meridian');
      expect(
        ShopCatalogue.isOpen('meridian'),
        isFalse,
        reason: 'this fixture only means what it says while meridian is closed',
      );
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: GameStateScope(state: game, child: const InventoryTab())),
      );
      await tester.pump();

      expect(find.text('Shop'), findsNothing);
      expect(
        find.textContaining(ShopCatalogue.closedFlavor),
        findsOneWidget,
        reason: '"closed towns surface the season line if anything"',
      );
    });

    testWidgets('a direct route to a closed town reads the same closed door', (
      tester,
    ) async {
      final game = _game(_MemStorage());
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: const ShopScreen(townId: 'meridian'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(ShopCatalogue.closedFlavor), findsOneWidget);
      expect(find.text('Buy'), findsNothing);
      expect(find.text('Sell'), findsNothing);
    });
  });

  group('leaving with an unsettled basket discards it silently', () {
    testWidgets('popping the route changes nothing persisted', (tester) async {
      final storage = _MemStorage();
      final game = _game(storage, storeroomStacks: {_bindweed: 20});
      final navKey = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(900, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        GameStateScope(
          state: game,
          child: MaterialApp(navigatorKey: navKey, home: const SizedBox()),
        ),
      );
      navKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ShopScreen(townId: _townId)),
      );
      // ⚠️ pumpAndSettle, not counted pumps: the push TRANSITION must finish
      // before tapping — mid-slide the whole page is translated and a tap at
      // the stepper's laid-out position hits nothing (found the day the
      // stepper moved to the row's right edge). The shop has no perpetual
      // animations, so settling terminates.
      await tester.pumpAndSettle();

      final baselineGold = game.profile.gold;
      final baselineStock = Map.of(game.profile.shopStock[_townId]!.stock);
      final baselineRoom = Map.of(game.profile.storerooms[_townId]!.stacks);

      await _tapStepper(tester, _oak, Icons.add, times: 4);
      expect(find.textContaining('Settle '), findsOneWidget);

      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(game.profile.gold, baselineGold);
      expect(game.profile.shopStock[_townId]!.stock, baselineStock);
      expect(game.profile.storerooms[_townId]!.stacks, baselineRoom);
    });
  });

  group('the 2026-08-25 UI pass', () {
    testWidgets("the total chip reads 'N for Xg' and the subline shows the "
        'next marginal price', (tester) async {
      final game = _game(_MemStorage());
      await _pump(tester, game);
      // 20, not a handful: the next-unit note only appears once rounding
      // actually MOVES the marginal price (5 oak leaves 11g → 11g, hidden
      // on purpose — showing 'next 11g' beside '11g each' would be noise).
      await _tapStepper(tester, _oak, Icons.add, times: 20);

      final quote = game.priceShopBasket(
        townId: _townId,
        today: ShopState.epochDayOf(game.now()),
        buy: const {_oak: 20},
        sellStacks: const {},
        sellInstances: const {},
      );
      expect(
        find.text('20 for ${quote.buyGoldOf[_oak]}g'),
        findsOneWidget,
        reason: "⭐ point 2: '3g each' × 5 ≠ total is the marginal walk — the "
            "chip must SAY 'N for Xg' or the mismatch reads as a bug",
      );
      expect(
        find.textContaining('· next '),
        findsWidgets,
        reason: '⚠️ the mutant this kills: a chip that explains the total but '
            'hides where the NEXT unit is priced',
      );
    });

    test('tierOf maps all five multipliers to five distinct labelled colours',
        () {
      final tiers = [
        ShopCatalogue.nativeMod,
        ShopCatalogue.regionalMod,
        ShopCatalogue.baselineMod,
        ShopCatalogue.oneTierMod,
        ShopCatalogue.exoticMod,
      ].map(tierOf).toList();
      expect(tiers.map((t) => t.$1).toSet().length, 5,
          reason: 'five tiers, five words — the colour-blind half of point 3');
      expect(tiers.map((t) => t.$2).toSet().length, 5,
          reason: 'five DISTINCT colours — the ruled bright-green→red code');
      expect(tiers.first.$1, contains('Native'));
      expect(tiers.last.$1, contains('Exotic'));
    });

    testWidgets('tapping the quantity edits it in place, clamped to stock',
        (tester) async {
      final game = _game(_MemStorage());
      await _pump(tester, game);
      await _tapStepper(tester, _oak, Icons.add);
      await tester.tap(
        find.descendant(of: _rowFor(_oak), matching: find.text('1')),
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(of: _rowFor(_oak), matching: find.byType(TextField)),
        '999',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final stock =
          game.profile.shopStock[_townId]!.stockOf(_oak);
      expect(
        find.text('$stock for '
            '${game.priceShopBasket(townId: _townId, today: ShopState.epochDayOf(game.now()), buy: {_oak: stock}, sellStacks: const {}, sellInstances: const {}).buyGoldOf[_oak]}g'),
        findsOneWidget,
        reason: '⚠️ the mutant this kills: an in-place edit that trusts raw '
            'input — 999 must clamp to the stock ceiling, not overbuy it',
      );
    });

    testWidgets('the settle summary speaks in counts, and the basket review '
        'prunes lines', (tester) async {
      final game = _game(
        _MemStorage(),
        storeroomStacks: const {'sapwort': 4},
      );
      await _pump(tester, game);
      await _tapStepper(tester, _oak, Icons.add, times: 2);
      await tester.tap(find.text('Sell').first);
      await tester.pump();
      await _tapStepper(tester, 'sapwort', Icons.add, times: 3);

      expect(
        find.textContaining('Buying 2 items −'),
        findsOneWidget,
        reason: "point 5: 'buy 2 2 kinds' read like a typo; counts + signed "
            'gold do not',
      );
      expect(find.textContaining('Selling 3 items +'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Buy 2 × Oak Log'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Buying 2 items'),
        findsNothing,
        reason: '⚠️ the mutant this kills: a review sheet whose remove button '
            'repaints the sheet but never reaches the basket',
      );
    });
  });
}

/// A `+` stepper button reads as disabled when its icon is painted
/// `AppColors.textFaint` (see `_StepButton`) — the same signal a sighted
/// player reads, rather than reaching into private state.
bool _isDisabledStepper(WidgetTester tester, Finder plus) {
  final icon = tester.widget<Icon>(plus.first);
  return icon.color == AppColors.textFaint;
}
