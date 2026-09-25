/// The town Shop (`ECONOMY_CONTRACT.md` §2/§3/§6/§14b) — the designer's
/// ruled basket-settle transaction model: every stepper on Buy and Sell
/// edits one in-memory basket, nothing debits/credits/persists until Settle
/// fires ONE atomic mutation.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a stepper that debits gold on tap, a settle that charges a
/// different number than it showed, a sell that skips the Storeroom, a
/// basket that survives leaving the screen, a bound item that sells anyway.
///
/// ⭐ The 2026-08-26 UX pass adds three more: the item tooltip opening from a
/// row without touching the basket, the tooltip's Value line (and its silence
/// at value 0), and the filter/sort band — including the layout-stability
/// assertions that are this screen's own house rule written as a test.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/shop_screen.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';
import 'package:masters_of_magic_2/ui/app_banner.dart';
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
const _sapwort = 'sapwort'; // MaterialDef, value 7 — cheaper than oak.
const _ration = 'foragers_ration'; // ConsumableDef, value 4.
const _draught = 'sapwort_draught'; // BeltableDef, value 12.
const _belt = 'tuskhide_belt'; // EquipmentDef, tradeable, value 110.
const _boundKey = 'proof_of_the_woods'; // KeyDef — always Tradability.bound.

String _name(String defId) =>
    ItemCatalogue.displayName(ItemCatalogue.byId(defId));

DateTime _atEpochDay(int day) =>
    DateTime.utc(1970, 1, 1).add(Duration(days: day));

/// A day whose Hearthwood daily events touch NONE of [itemIds] — derived,
/// not hardcoded, same reasoning as the event tests' probed days.
///
/// ⚠️ Exists because three tests here once ran on the WALL CLOCK: they
/// passed for days, then UTC midnight rolled the deterministic event seed
/// onto oak and bindweed and their hand-computed expectations (no eventMod)
/// went stale overnight — a date-sensitive test suite for a shop whose
/// whole design is date-determinism. Every hand-computed expectation now
/// pins a derived quiet day.
DateTime _quietDayFor(List<String> itemIds) {
  for (var day = 19000; day < 19400; day++) {
    final events = ShopState.eventsFor(
      shopId: _townId,
      today: day,
      candidateItemIds: ShopCatalogue.stockFor(_townId),
    );
    if (itemIds.every((id) => (events[id] ?? 1.0) == 1.0)) {
      return _atEpochDay(day);
    }
  }
  throw StateError('no quiet day in 400 — the event hash changed radically');
}

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

/// The row for a gear instance carrying [quality] — ⚠️ **its composed name,
/// not the def's.** `ItemCatalogue.displayName` prefixes the quality tier
/// ("Master Tuskhide Belt"), so [_rowFor] matches nothing for a qualified
/// piece and every descendant assertion under it would pass vacuously.
Finder _rowForInstance(String defId, Quality quality) => find.widgetWithText(
  GamePanel,
  ItemCatalogue.displayName(
    ItemCatalogue.byId(defId),
    ItemInstance(instanceId: 'x', defId: defId, quality: quality),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  GameState game, {
  double width = 900,
  String? fontFamily,
}) async {
  // ⚠️ The VIEW size, not `setSurfaceSize`: the latter resizes the layout
  // but `MediaQuery.sizeOf` keeps reporting the default 800 dp, so a
  // width-keyed breakpoint (`shopChipsFit`) would never fire in a test.
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      // ⚠️ Null unless a test asks for real glyph metrics ([_roboto]) — every
      // other test keeps the default theme it was written against.
      theme: fontFamily == null ? null : ThemeData(fontFamily: fontFamily),
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

/// Real Roboto — the face Flutter web draws this game in — registered under
/// a private family name, for the tests that are ABOUT how many characters
/// fit (ruling 2026-09-25: 'names render in full on a phone').
///
/// ⚠️ **Why not the test font.** `flutter_test`'s FlutterTest face draws
/// every glyph a full em wide — 'Forager's Ration' is 220 px there against
/// ~102 in Roboto — so a truncation test in it measures nothing a player sees.
/// The files ship inside the Flutter SDK (`material_fonts`), so no asset is
/// vendored; ⚠️ a private family name, never 'Roboto', so loading it cannot
/// change the metrics of any other test sharing this isolate.
const _roboto = 'ShopRoboto';
var _robotoLoaded = false;

Future<void> _loadRoboto(WidgetTester tester) async {
  if (_robotoLoaded) return;
  // `FLUTTER_ROOT` is exported by the `flutter` launcher; the fallback walks
  // up from `flutter_tester` itself (…/bin/cache/artifacts/engine/…).
  final exe = Platform.resolvedExecutable;
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      exe.substring(0, exe.indexOf('/bin/cache/'));
  final dir = '$root/bin/cache/artifacts/material_fonts';
  await tester.runAsync(() async {
    final loader = FontLoader(_roboto);
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      final file = File('$dir/Roboto-$weight.ttf');
      if (!file.existsSync()) {
        throw StateError(
          'Roboto not found at ${file.path} — the SDK layout moved',
        );
      }
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });
  _robotoLoaded = true;
}

/// The row's name as laid out — for asking whether it was cut short.
RenderParagraph _nameParagraph(WidgetTester tester, String itemId) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: _rowFor(itemId), matching: find.text(_name(itemId))),
    );

/// The PRICE cell of a row: the one text in it that is nothing but 'Ng'.
Finder _priceCellOf(String itemId) => find.descendant(
  of: _rowFor(itemId),
  matching: find.byWidgetPredicate(
    (w) => w is Text && RegExp(r'^\d+g$').hasMatch(w.data ?? ''),
  ),
);

Future<void> _tapStepper(
  WidgetTester tester,
  String itemId,
  IconData icon, {
  int times = 1,
}) async {
  for (var i = 0; i < times; i++) {
    final button = find.descendant(
      of: _rowFor(itemId),
      matching: find.byIcon(icon),
    );
    await tester.tap(button);
    await tester.pump();
  }
}

Future<void> _switchToSell(WidgetTester tester) async {
  await tester.tap(find.text('Sell').first);
  await tester.pump();
}

// ---- 2026-08-26 UX pass helpers ---------------------------------------

/// Taps a row's LEFT/info region the way a player does — on the item's NAME,
/// never on a stepper, a quantity or a Sell toggle. ⭐ Deliberately not a
/// `byType(_InfoTap)` reach-in: the ruling is about where a finger lands.
Future<void> _tapRowInfo(WidgetTester tester, Finder row, String label) async {
  await tester.tap(find.descendant(of: row, matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> _closeItemDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Close'));
  await tester.pumpAndSettle();
}

/// The vertical position of a row, for order assertions — reading the LAID
/// OUT shelf rather than any list the screen keeps privately.
double _rowY(WidgetTester tester, String itemId) =>
    tester.getTopLeft(_rowFor(itemId)).dy;

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _chooseSort(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.sort));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
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
        final game = _game(
          storage,
          gold: 1000,
          storeroomStacks: {_bindweed: 20},
          // ⭐ Pinned quiet day: the expectations below omit eventMod on
          // purpose, so the fixture must guarantee no event touches them.
          now: _quietDayFor(const [_oak, _bindweed]),
        );
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
          reason:
              '⭐ the mutant this test exists to kill: Settle charging '
              'something other than what it displayed',
        );
        expect(
          game.profile.storerooms[_townId]!.stacks[_oak],
          5,
          reason: 'bought goods land in the Storeroom, not the backpack',
        );
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
        // ⭐ **The one notice that survived the REMOVE rule here** (notice
        // ruling, 2026-08-26). Gold and stock both move on screen, but the
        // NET across a mixed basket is arithmetic nothing states — so it
        // stays, as a TOP banner, off the settle bar it used to cover.
        expect(find.byType(AppBanner), findsOneWidget);
        expect(find.text('Settled — netted ${shown}g.'), findsOneWidget);
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason:
              '⚠️ this screen is the ruling\'s worst case — the Settle '
              'bar lives at the bottom, exactly where a SnackBar lands',
        );
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
        reason:
            'Settle must persist through the same _mutate/save seam '
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
      final game = _game(
        storage,
        storeroomStacks: {_bindweed: 20},
        now: _quietDayFor(const [_bindweed]),
      );
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
          'inst-belt': const ItemInstance(
            instanceId: 'inst-belt',
            defId: _belt,
          ),
        },
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      final expectedVendor = ShopPricing.vendorPrice(
        ItemCatalogue.byId(_belt).value,
      );
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

    testWidgets(
      '⭐ §14d.1: quality scales the price, and the ROW and SETTLE agree',
      (tester) async {
        // ⚠️ **The two-computations mutant, killed end to end.** The Shop
        // screen renders this row's price and `priceShopBasket` computes what
        // Settle pays; before §14d.1 those were two independent
        // `vendorPrice(def.value)` expressions. This test walks the real UI:
        // it reads the number the row PRINTS, watches the settle bar, and then
        // checks the gold that actually moved. A change that teaches only one
        // of the three about quality fails here, whichever one it is.
        final storage = _MemStorage();
        final game = _game(
          storage,
          storeroomInstanceIds: ['inst-master'],
          instances: {
            'inst-master': const ItemInstance(
              instanceId: 'inst-master',
              defId: _belt,
              quality: Quality.master,
            ),
          },
        );
        await _pump(tester, game);
        await _switchToSell(tester);

        // ⚠️ A qualified piece renders under its COMPOSED name ("Master
        // Tuskhide Belt"), not the bare def name — find the row the way the
        // screen names it, or the finder silently matches nothing and every
        // assertion below becomes vacuous.
        final row = _rowForInstance(_belt, Quality.master);
        final base = ItemCatalogue.byId(_belt).value;
        final expected = ShopPricing.vendorPrice((base * 140 + 50) ~/ 100);
        expect(
          expected,
          greaterThan(ShopPricing.vendorPrice(base)),
          reason:
              'the fixture must actually exercise the ladder — a Master '
              'piece that priced like a Standard one would make the rest of '
              'this test vacuous',
        );

        expect(
          find.descendant(
            of: row,
            matching: find.text('${expected}g · vendor (flat)'),
          ),
          findsOneWidget,
          reason:
              'the ROW must print the quality-scaled price — a display '
              'path still reading def.value shows ${ShopPricing.vendorPrice(base)}g',
        );

        await tester.tap(find.descendant(of: row, matching: find.text('Sell')));
        await tester.pump();

        expect(
          _displayedNet(tester),
          expected,
          reason: 'the SETTLE BAR must quote the same number the row showed',
        );

        await tester.tap(find.textContaining('Settle '));
        await tester.pump();
        await tester.pump();

        expect(
          game.profile.gold,
          1000 + expected,
          reason:
              'the gold that MOVED must equal the number displayed — a '
              'settle that recomputed without quality pays less than the '
              'player was shown, which is the whole point of the one seam',
        );
      },
    );

    testWidgets('a Rough piece is worth strictly less than a Master one', (
      tester,
    ) async {
      // Kills a seam that scales in the right direction for one rung only, or
      // that reads `quality != null` as a flat bonus.
      final storage = _MemStorage();
      final game = _game(
        storage,
        storeroomInstanceIds: ['inst-rough'],
        instances: {
          'inst-rough': const ItemInstance(
            instanceId: 'inst-rough',
            defId: _belt,
            quality: Quality.rough,
          ),
        },
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      final base = ItemCatalogue.byId(_belt).value;
      final rough = ShopPricing.vendorPrice((base * 80 + 50) ~/ 100);
      expect(
        find.descendant(
          of: _rowForInstance(_belt, Quality.rough),
          matching: find.text('${rough}g · vendor (flat)'),
        ),
        findsOneWidget,
        reason: 'Rough must price BELOW the plain vendor price, not above it',
      );
      expect(rough, lessThan(ShopPricing.vendorPrice(base)));
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

    test(
      '⭐ settleShopBasket refuses even if a caller bypasses the UI',
      () async {
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
      },
    );
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
      expect(
        game.profile.gold,
        1000,
        reason: 'a refused settle charges nothing',
      );
    });

    testWidgets(
      '⭐ a basket refused mid-settle STOPS the player with a dialog',
      (tester) async {
        // ⭐ The DIALOG case of the notice ruling (2026-08-26) — the only kind
        // of refusal the designer let escalate past a banner. Everywhere else a
        // missed notice costs one tap to retry; here the player staged a whole
        // basket across two tabs, the basket SURVIVES the refusal, and a notice
        // they blink past leaves them re-tapping a Settle button that silently
        // does nothing.
        final storage = _MemStorage();
        final game = _game(storage);
        await _pump(tester, game);

        await _tapStepper(tester, _oak, Icons.add, times: 5);

        // ⚠️ The shelf moves WITHOUT `notifyListeners`, which is the whole
        // point: the Settle button is still enabled from the last frame, so
        // this is the one path that reaches the refusal branch through the UI
        // rather than by calling the engine directly.
        final before = game.profile.shopStock[_townId]!;
        game.profile.shopStock[_townId] = TownShopState(
          stock: {...before.stock, _oak: 2},
          lastResetDay: before.lastResetDay,
        );

        await tester.tap(find.textContaining('Settle '));
        await tester.pumpAndSettle();

        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason:
              '⭐ THE dialog case — a banner here could be missed at the '
              'cost of the whole basket',
        );
        expect(find.text('The trade did not go through'), findsOneWidget);
        expect(
          find.text('Not enough in stock.'),
          findsWidgets,
          reason: 'the engine\'s own words, not a paraphrase',
        );
        expect(
          find.byType(AppBanner),
          findsNothing,
          reason:
              '⚠️ escalation REPLACES the banner — a refusal worth stopping '
              'for must not merely flash past instead',
        );
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.text('Right'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(
          game.profile.gold,
          1000,
          reason: 'a refused settle charges nothing',
        );
        expect(
          find.textContaining('Settle '),
          findsOneWidget,
          reason:
              '⭐ the basket survives the refusal — which is exactly why '
              'the player is owed a reason they cannot miss',
        );
      },
    );
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
    testWidgets(
      'the Inventory tab offers no Shop button, only the season line',
      (tester) async {
        final storage = _MemStorage();
        final game = _game(storage, locationId: 'meridian');
        expect(
          ShopCatalogue.isOpen('meridian'),
          isFalse,
          reason:
              'this fixture only means what it says while meridian is closed',
        );
        await tester.binding.setSurfaceSize(const Size(900, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: GameStateScope(state: game, child: const InventoryTab()),
          ),
        );
        await tester.pump();

        expect(find.text('Shop'), findsNothing);
        expect(
          find.textContaining(ShopCatalogue.closedFlavor),
          findsOneWidget,
          reason: '"closed towns surface the season line if anything"',
        );
      },
    );

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
        MaterialPageRoute<void>(
          builder: (_) => const ShopScreen(townId: _townId),
        ),
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
    testWidgets('the TOTAL column carries the quote and PRICE shows the '
        'NEXT unit, live', (tester) async {
      final game = _game(_MemStorage(), now: _quietDayFor(const [_oak]));
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
        find.descendant(
          of: _rowFor(_oak),
          matching: find.text('${quote.buyGoldOf[_oak]}g'),
        ),
        findsOneWidget,
        reason:
            '⭐ the TOTAL column must show the marginal-walk total from '
            'the one shared quote — a per-row recompute is the mutant',
      );
      // ⭐ Round-3 ruling: the PRICE column shows the (qty+1)th unit's
      // marginal price — with 20 pending, the column must read the price at
      // stock − 20, not the sticker.
      final game2 = GameStateScope.of(tester.element(find.byType(ShopScreen)));
      final stock = game2.profile.shopStock[_townId]!.stockOf(_oak);
      final expectedNext = ShopPricing.roundGold(
        ShopPricing.buyPrice(
          base: ItemCatalogue.byId(_oak).value,
          equilibrium: game2.shopEquilibriumFor(_townId, _oak),
          stock: stock - 20,
          locationMod: game2.shopLocationModFor(_townId, _oak),
        ),
      );
      expect(
        find.descendant(
          of: _rowFor(_oak),
          matching: find.text('${expectedNext}g'),
        ),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: a PRICE column frozen at the '
            'sticker while the marginal walk moves on without it',
      );
    });

    test(
      'tierOf maps all five multipliers to five distinct labelled colours',
      () {
        final tiers = [
          ShopCatalogue.nativeMod,
          ShopCatalogue.regionalMod,
          ShopCatalogue.baselineMod,
          ShopCatalogue.oneTierMod,
          ShopCatalogue.exoticMod,
        ].map(tierOf).toList();
        expect(
          tiers.map((t) => t.$1).toSet().length,
          5,
          reason: 'five tiers, five words — the colour-blind half of point 3',
        );
        expect(
          tiers.map((t) => t.$2).toSet().length,
          5,
          reason: 'five DISTINCT colours — the ruled bright-green→red code',
        );
        expect(tiers.first.$1, contains('Native'));
        expect(tiers.last.$1, contains('Exotic'));
      },
    );

    testWidgets('tapping the quantity edits it in place, clamped to stock', (
      tester,
    ) async {
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

      final stock = game.profile.shopStock[_townId]!.stockOf(_oak);
      expect(
        find.descendant(
          of: _rowFor(_oak),
          matching: find.text(
            '${game.priceShopBasket(townId: _townId, today: ShopState.epochDayOf(game.now()), buy: {_oak: stock}, sellStacks: const {}, sellInstances: const {}).buyGoldOf[_oak]}g',
          ),
        ),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: an in-place edit that trusts raw '
            'input — 999 must clamp to the stock ceiling, not overbuy it',
      );
    });

    testWidgets('leaving the quantity field commits it — no Enter required', (
      tester,
    ) async {
      final game = _game(_MemStorage());
      await _pump(tester, game);
      await _tapStepper(tester, _oak, Icons.add);
      await tester.tap(
        find.descendant(of: _rowFor(_oak), matching: find.text('1')),
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(of: _rowFor(_oak), matching: find.byType(TextField)),
        '7',
      );
      // ⭐ The ruling: LEAVE the control, never press Enter. Unfocus is the
      // canonical departure every exit path (tab, tap elsewhere) reduces to.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      final quote = game.priceShopBasket(
        townId: _townId,
        today: ShopState.epochDayOf(game.now()),
        buy: const {_oak: 7},
        sellStacks: const {},
        sellInstances: const {},
      );
      expect(
        find.descendant(
          of: _rowFor(_oak),
          matching: find.text('${quote.buyGoldOf[_oak]}g'),
        ),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: a commit wired only to '
            'onSubmitted — typing 7 and clicking away must not quietly '
            'revert to 1',
      );
      expect(find.textContaining('Buying 7 items'), findsOneWidget);
    });

    testWidgets('the settle summary speaks in counts, and the basket review '
        'prunes lines', (tester) async {
      final game = _game(_MemStorage(), storeroomStacks: const {'sapwort': 4});
      await _pump(tester, game);
      await _tapStepper(tester, _oak, Icons.add, times: 2);
      await tester.tap(find.text('Sell').first);
      await tester.pump();
      await _tapStepper(tester, 'sapwort', Icons.add, times: 3);

      expect(
        find.textContaining('Buying 2 items −'),
        findsOneWidget,
        reason:
            "point 5: 'buy 2 2 kinds' read like a typo; counts + signed "
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
        reason:
            '⚠️ the mutant this kills: a review sheet whose remove button '
            'repaints the sheet but never reaches the basket',
      );
    });
  });

  // ---- the 2026-08-26 UX pass -----------------------------------------

  group('the item tooltip opens FROM the shop', () {
    testWidgets('⭐ tapping a Buy row\'s name opens THAT item, with its worth', (
      tester,
    ) async {
      final game = _game(_MemStorage());
      await _pump(tester, game);

      await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(_name(_oak))),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: a row whose tap opens the tooltip '
            'for whatever item the LIST happened to hand it last',
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Value: ${ItemCatalogue.byId(_oak).value}g'),
        ),
        findsOneWidget,
        reason:
            'ruling #2: the base value off the catalogue, not a shop '
            'quote — the tooltip is met from six screens, only one of which '
            'has a shelf behind it',
      );
    });

    testWidgets('a Sell row opens it too, gear instance and all', (
      tester,
    ) async {
      final game = _game(
        _MemStorage(),
        storeroomStacks: {_bindweed: 5},
        storeroomInstanceIds: ['inst-belt'],
        instances: {
          'inst-belt': const ItemInstance(
            instanceId: 'inst-belt',
            defId: _belt,
          ),
        },
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      await _tapRowInfo(tester, _rowFor(_bindweed), _name(_bindweed));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_name(_bindweed)),
        ),
        findsOneWidget,
      );
      await _closeItemDialog(tester);

      await _tapRowInfo(tester, _rowFor(_belt), _name(_belt));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_name(_belt)),
        ),
        findsOneWidget,
        reason:
            'ruling #1 names BOTH tabs — a Sell shelf you cannot inspect '
            'is the shelf you most need to inspect before parting with it',
      );
    });

    testWidgets(
      '⭐ the basket is EXACTLY as it was after the dialog is dismissed',
      (tester) async {
        final storage = _MemStorage();
        final game = _game(storage, gold: 1000);
        await _pump(tester, game);

        await _tapStepper(tester, _oak, Icons.add, times: 3);
        final netBefore = _displayedNet(tester);
        final savesBefore = storage.saveCount;

        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));
        await _closeItemDialog(tester);

        expect(
          find.textContaining('Buying 3 items'),
          findsOneWidget,
          reason:
              '⚠️ the mutant this kills: an info tap that also reaches the '
              'basket — clearing it, or bumping the row it opened',
        );
        expect(_displayedNet(tester), netBefore);
        expect(game.profile.gold, 1000, reason: 'looking is never spending');
        expect(
          storage.saveCount,
          savesBefore,
          reason: 'opening a tooltip must not write to disk at all',
        );
      },
    );

    testWidgets(
      '⚠️ a row tap is INERT while its quantity is being edited in place',
      (tester) async {
        final game = _game(_MemStorage());
        await _pump(tester, game);
        await _tapStepper(tester, _oak, Icons.add);

        // Open the in-place editor, exactly as the UI-pass test does.
        // ⚠️ pumpAndSettle, not a counted pump: the field's `autofocus` has
        // to actually LAND before this test means anything — an unfocused
        // TextField wires no `onTapOutside`, so the tap below would prove the
        // guard while the commit path it races was never armed.
        await tester.tap(
          find.descendant(of: _rowFor(_oak), matching: find.text('1')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);

        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));
        expect(
          find.byType(AlertDialog),
          findsNothing,
          reason:
              '⚠️ the mutant this kills: an info tap guarded by a check '
              'INSIDE its handler — the field unfocuses on the pointer-down '
              'that precedes the tap, so by then the guard sees nothing to '
              'guard and the dialog lands on top of a half-typed quantity',
        );
        expect(
          find.byType(TextField),
          findsNothing,
          reason:
              'that tap did its real job and only that job: it LEFT the '
              'field, which is how this screen commits an inline edit',
        );
        expect(find.textContaining('Buying 1 item'), findsOneWidget);

        // ⭐ And the door is not wedged shut — the NEXT tap opens it.
        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );
  });

  group('the tooltip shows what an item is worth', () {
    testWidgets('⭐ an item worth nothing shows NO value line', (tester) async {
      expect(
        ItemCatalogue.byId(_boundKey).value,
        0,
        reason:
            'this fixture only means what it says while a quest key is '
            'worth nothing (KeyDef fixes value at 0)',
      );
      final game = _game(_MemStorage(), storeroomStacks: {_boundKey: 1});
      await _pump(tester, game);
      await _switchToSell(tester);

      await _tapRowInfo(tester, _rowFor(_boundKey), _name(_boundKey));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Value:'),
        findsNothing,
        reason:
            "⚠️ the mutant this kills: an unconditional line — 'Value: 0g' "
            'reads as a bug report, not as "this is not merchandise"',
      );
    });

    testWidgets(
      '⭐ an Ornate instance shows the quality-scaled worth beside the base',
      (tester) async {
        final base = ItemCatalogue.byId(_belt).value;
        // Derived from the ladder itself (80/100/120/140), not from the
        // screen's helper — this must fail if the helper starts disagreeing
        // with the ruling's percentages.
        final scaled = (base * Quality.ornate.statPercent / 100).round();
        expect(scaled, isNot(base), reason: 'Ornate must actually MOVE 110g');

        final game = _game(
          _MemStorage(),
          storeroomInstanceIds: ['inst-ornate', 'inst-plain'],
          instances: {
            'inst-ornate': const ItemInstance(
              instanceId: 'inst-ornate',
              defId: _belt,
              quality: Quality.ornate,
            ),
            'inst-plain': const ItemInstance(
              instanceId: 'inst-plain',
              defId: _belt,
            ),
          },
        );
        await _pump(tester, game);
        await _switchToSell(tester);

        final ornateName = ItemCatalogue.displayName(
          ItemCatalogue.byId(_belt),
          game.profile.itemInstances['inst-ornate'],
        );
        await _tapRowInfo(
          tester,
          find.widgetWithText(GamePanel, ornateName),
          ornateName,
        );
        expect(
          find.text('Value: ${base}g (Ornate ${scaled}g)'),
          findsOneWidget,
          reason:
              '⚠️ the mutant this kills: a value line that quotes the '
              "DEFINITION while the row beside it is a roll that isn't the "
              'definition — the exact disagreement item_display.dart exists '
              'to prevent for stats',
        );
        await _closeItemDialog(tester);

        // ⭐ …and the un-rolled twin says the number ONCE.
        await _tapRowInfo(tester, _rowFor(_belt), _name(_belt));
        expect(find.text('Value: ${base}g'), findsOneWidget);
        expect(
          find.textContaining('Value: ${base}g ('),
          findsNothing,
          reason:
              '⚠️ the mutant this kills: a parenthetical that always '
              "rides along — 'Value: 110g (Standard 110g)' teaches that "
              'quality moves worth by restating the same number',
        );
      },
    );
  });

  group('filter chips and the sort control', () {
    testWidgets('⭐ a filter narrows the shelf to its kind', (tester) async {
      final game = _game(_MemStorage());
      await _pump(tester, game);

      expect(_rowFor(_oak), findsOneWidget);
      await _tapChip(tester, 'Consumables');

      expect(_rowFor(_ration), findsOneWidget);
      expect(
        _rowFor(_draught),
        findsOneWidget,
        reason:
            'both consumable KINDS answer one chip — a belt-legal '
            'draught and a plain ration are one shelf to a shopper',
      );
      expect(
        _rowFor(_oak),
        findsNothing,
        reason:
            '⚠️ the mutant this kills: a chip row that lights up and '
            'filters nothing',
      );

      await _tapChip(tester, 'All');
      expect(_rowFor(_oak), findsOneWidget, reason: 'All puts it all back');
    });

    testWidgets('the Sell tab filters gear apart from stacks', (tester) async {
      final game = _game(
        _MemStorage(),
        storeroomStacks: {_bindweed: 5},
        storeroomInstanceIds: ['inst-belt'],
        instances: {
          'inst-belt': const ItemInstance(
            instanceId: 'inst-belt',
            defId: _belt,
          ),
        },
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      await _tapChip(tester, 'Gear');
      expect(_rowFor(_belt), findsOneWidget);
      expect(_rowFor(_bindweed), findsNothing);

      await _tapChip(tester, 'Materials');
      expect(_rowFor(_bindweed), findsOneWidget);
      expect(
        _rowFor(_belt),
        findsNothing,
        reason:
            'the Gear chip and the Materials chip must partition the '
            'shelf, not overlap on it',
      );
    });

    testWidgets('⭐ sorting by price reorders — WITHIN the current filter', (
      tester,
    ) async {
      final game = _game(
        _MemStorage(),
        // Pinned quiet day: the order asserted below is the plain
        // location-modified sticker order, with no daily event on either row.
        now: _quietDayFor(const [_oak, _sapwort]),
      );
      await _pump(tester, game);
      await _tapChip(tester, 'Materials');

      expect(
        _rowY(tester, _oak),
        lessThan(_rowY(tester, _sapwort)),
        reason:
            "the default IS the shelf's own catalogue order — oak_log is "
            'authored before sapwort',
      );

      await _chooseSort(tester, 'Price');

      expect(
        _rowY(tester, _sapwort),
        lessThan(_rowY(tester, _oak)),
        reason:
            '⚠️ the mutant this kills: a sort control that repaints its '
            'own label and leaves the shelf exactly as it found it (sapwort '
            'is 7g base to oak_log\'s 13g — ascending puts it first)',
      );
      expect(
        _rowFor(_ration),
        findsNothing,
        reason:
            '⚠️ the mutant this kills: a sort that re-reads the whole '
            'catalogue and quietly serves the filter back with it',
      );
    });

    testWidgets('sorting by Have puts the deepest pile first', (tester) async {
      final game = _game(
        _MemStorage(),
        storeroomStacks: {_bindweed: 2, _sapwort: 40},
      );
      await _pump(tester, game);
      await _switchToSell(tester);

      expect(
        _rowY(tester, _bindweed),
        lessThan(_rowY(tester, _sapwort)),
        reason: "the Sell default IS alphabetical — Bindweed before Sapwort",
      );

      await _chooseSort(tester, 'Have');

      expect(
        _rowY(tester, _sapwort),
        lessThan(_rowY(tester, _bindweed)),
        reason:
            '⚠️ the mutant this kills: a quantity sort that ascends like '
            'the other two — "how many have I got" is asked by a player '
            'looking for the deep pile, never the last two of something',
      );
    });

    testWidgets('a filter matching nothing says so, quietly', (tester) async {
      final game = _game(_MemStorage(), storeroomStacks: {_bindweed: 5});
      await _pump(tester, game);
      await _switchToSell(tester);

      await _tapChip(tester, 'Gear');
      expect(
        find.text('Nothing here matches this filter.'),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: silence — an empty shelf that does '
            'not name the filter reads as "you own no gear at all"',
      );
      expect(
        find.textContaining('Storeroom and pack are empty'),
        findsNothing,
        reason:
            'the empty-pockets line is a DIFFERENT fact, and it is false '
            'here',
      );
    });

    testWidgets(
      '⭐ the controls hold their positions across filter and sort changes',
      (tester) async {
        final game = _game(_MemStorage());
        await _pump(tester, game);

        double headerY() => tester.getTopLeft(find.text('ITEM')).dy;
        Rect tabRect() => tester.getRect(find.text('Buy'));
        Rect sortRect() => tester.getRect(find.byIcon(Icons.sort));

        final header = headerY();
        final tab = tabRect();
        final sort = sortRect();

        await _tapChip(tester, 'Consumables');
        expect(
          headerY(),
          header,
          reason:
              '⚠️ the mutant this kills: a Wrap that grows a second chip '
              'line and shoves the whole shelf down',
        );
        expect(tabRect(), tab);
        expect(sortRect(), sort);

        // ⭐ The press-stability rule at its sharpest: the control whose LABEL
        // just changed from 'Default order' to 'Price' must not have moved.
        await _chooseSort(tester, 'Price');
        expect(
          sortRect(),
          sort,
          reason:
              '⚠️ the mutant this kills: a sort button sized to its own '
              'label, which walks out from under the finger that pressed it',
        );
        expect(headerY(), header);
        expect(tabRect(), tab);
      },
    );
  });

  group(
    'phone layout (ruling 2026-09-21: chips hidden under the measured line)',
    () {
      testWidgets('at 390 wide the tier chip is gone, the price stays', (
        tester,
      ) async {
        final eventDay = _dayWith(event: true, itemId: _oak);
        final game = _game(_MemStorage(), now: _atEpochDay(eventDay));
        await _pump(tester, game, width: 390);
        expect(
          find.textContaining('Native'),
          findsNothing,
          reason:
              'a mutant that ignores the breakpoint keeps the tier chip '
              'colliding with STOCK on a phone',
        );
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.textContaining('Price spike'),
          ),
          findsNothing,
          reason:
              'the event chip hides with the tier chip — it is the one that '
              'overlapped the stock number in the screenshot',
        );
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.textContaining('g'),
          ),
          findsWidgets,
          reason:
              'the price column is the number the chips explained and must '
              'survive the hide',
        );
        expect(
          find.text('Default order'),
          findsNothing,
          reason:
              'the sort box is icon-only on a phone — the worded box is what '
              'overflowed the toolbar row',
        );
        expect(
          tester.takeException(),
          isNull,
          reason:
              'no RenderFlex overflow anywhere on a 390 dp phone — rows and '
              'toolbar both fit once the compact gaps and padding apply',
        );
      });

      // ⭐ Ruling 2026-09-21 (the other half of the phone ruling): the row may
      // hide the words, but the ITEM DIALOG must carry them — otherwise a
      // phone player has no way left to learn why the price is what it is.
      testWidgets('on a phone the tier chip lives in the item dialog', (
        tester,
      ) async {
        final eventDay = _dayWith(event: true, itemId: _oak);
        final game = _game(_MemStorage(), now: _atEpochDay(eventDay));
        await _pump(tester, game, width: 390);

        // The row is silent — the premise of this test.
        expect(find.textContaining('Native'), findsNothing);

        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));

        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Native −25%'),
          ),
          findsOneWidget,
          reason:
              'a mutant that passes `tags` only when the chips already FIT '
              '(reusing shopChipsFit at the call site) leaves the phone '
              'player with no explanation of the price anywhere on screen',
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('Price spike'),
          ),
          findsOneWidget,
          reason:
              'the event chip travels with the tier chip — a mutant passing '
              'only [_TierChip] drops the one that MOVED the price today',
        );
        await _closeItemDialog(tester);
      });

      testWidgets('the dialog carries the tags on a wide screen too', (
        tester,
      ) async {
        final eventDay = _dayWith(event: true, itemId: _oak);
        final game = _game(_MemStorage(), now: _atEpochDay(eventDay));
        await _pump(tester, game, width: 900);

        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));

        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Native −25%'),
          ),
          findsOneWidget,
          reason:
              'the inverse mutant — tags passed only BELOW the breakpoint — '
              'would make the dialog inconsistent with itself between two '
              'window sizes; the ruling is that it always shows them',
        );
        await _closeItemDialog(tester);
      });

      testWidgets('at 760 wide (the line itself) the chips are back', (
        tester,
      ) async {
        // The hardest row: name + tier chip + EVENT chip + four columns.
        final eventDay = _dayWith(event: true, itemId: _oak);
        final game = _game(_MemStorage(), now: _atEpochDay(eventDay));
        await _pump(tester, game, width: chipBreakpoint);
        expect(
          find.textContaining('Native'),
          findsWidgets,
          reason:
              'the breakpoint is inclusive — a mutant using > instead of >= '
              'hides them at exactly the line',
        );
        expect(
          find.text('Default order'),
          findsOneWidget,
          reason: 'the worded sort box returns with the chips at the same line',
        );
        expect(
          tester.takeException(),
          isNull,
          reason:
              'at the line itself the worded layout — chips, event chip and '
              'all four columns — must fit without overflow; this is what set '
              'chipBreakpoint',
        );
      });

      // ---- ruling 2026-09-25 (mockup option A): the name gets its width back

      // ⭐ Christian's screenshot named 'Bindweed Tangle' — that is the GATHER
      // NODE; the shelf item it drops is 'Bindweed Fibre', and that is the row
      // that truncated. Both names are read off the catalogue, not typed.
      testWidgets("⭐ names render in full on a 390 dp phone — Bindweed Fibre, "
          "Forager's Ration", (tester) async {
        await _loadRoboto(tester);
        final game = _game(_MemStorage());
        await _pump(tester, game, width: 390, fontFamily: _roboto);
        for (final id in const [_bindweed, _ration]) {
          expect(
            _nameParagraph(tester, id).didExceedMaxLines,
            isFalse,
            reason:
                '${_name(id)} must render in full (no …) — the mutant that '
                'keeps the STOCK and TOTAL cells on a phone leaves the name '
                '4 px and ellipsizes every row on the shelf',
          );
        }
        expect(
          tester.takeException(),
          isNull,
          reason: 'no RenderFlex overflow in real glyph metrics either',
        );
      });

      testWidgets('every shelf name fits a phone row, with room to ~22 '
          'characters', (tester) async {
        await _loadRoboto(tester);
        final game = _game(_MemStorage());
        await _pump(tester, game, width: 390, fontFamily: _roboto);
        // ⚠️ Measured in the name's OWN resolved style (theme letter-spacing
        // included), so the probe and the row cannot disagree about the font.
        final name = find.descendant(
          of: _rowFor(_oak),
          matching: find.text(_name(_oak)),
        );
        final style = DefaultTextStyle.of(
          tester.element(name),
        ).style.merge(tester.widget<Text>(name).style);
        double widthOf(String s) {
          final probe = TextPainter(
            text: TextSpan(text: s, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          final w = probe.width;
          probe.dispose();
          return w;
        }

        final box = _nameParagraph(tester, _oak).constraints.maxWidth;
        // ⭐ Every OPEN shelf, derived — a name authored tomorrow joins this
        // check on its own, the same reasoning that computes town stock.
        final names = {
          for (final town in ShopCatalogue.status.keys)
            if (ShopCatalogue.isOpen(town))
              for (final id in ShopCatalogue.stockFor(town)) _name(id),
        };
        for (final n in names) {
          expect(
            widthOf(n),
            lessThanOrEqualTo(box),
            reason: '"$n" is on a shelf and must never ellipsize at 390 dp',
          );
        }
        // "~22 characters" read against the shelf's own AVERAGE glyph (~6.9
        // px — short, capital-heavy names), not a hand-picked thin string.
        // ⚠️ 148 px holds 21.3 of those: the "~" in the ruling. A true 22
        // needs ~5 px more, which only the panel's padding could give — an
        // unruled visual change, left to the designer.
        final chars = names.fold<int>(0, (a, n) => a + n.length);
        final glyphs = names.fold<double>(0, (a, n) => a + widthOf(n));
        expect(
          box,
          greaterThanOrEqualTo(21 * glyphs / chars),
          reason:
              '~22 characters before the ellipsis (ruling 2026-09-25) — the '
              'mutant that keeps the wide 10/8 px gaps on a phone leaves '
              '142 px, under 21 characters',
        );
      });

      testWidgets('⭐ the stock is a dim subline — and a consumable says what '
          'it does', (tester) async {
        final game = _game(_MemStorage());
        await _pump(tester, game, width: 390);
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.text('60 in stock'),
          ),
          findsOneWidget,
          reason:
              'the STOCK column became the name\'s subline on a phone — a '
              'mutant that only deletes the column loses the number entirely',
        );
        final rationStock = game.profile.shopStock[_townId]!.stockOf(_ration);
        final heal = (ItemCatalogue.byId(_ration) as ConsumableDef).effect.heal;
        expect(
          find.descendant(
            of: _rowFor(_ration),
            matching: find.text('$rationStock in stock · restores $heal'),
          ),
          findsOneWidget,
          reason:
              'a consumable\'s subline carries its effect off ItemEffect — a '
              'mutant that skips Usable, or types the number, fails here',
        );
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.textContaining('restores'),
          ),
          findsNothing,
          reason: 'a material does nothing when used and says nothing of it',
        );
      });

      testWidgets('the Sell subline says what is left to sell, and a bound '
          'stack is only held', (tester) async {
        final game = _game(
          _MemStorage(),
          storeroomStacks: {_bindweed: 6, _boundKey: 1},
        );
        // ⚠️ Roboto, not the test font: the Sell toolbar's FOUR chips are
        // ~60 px over 390 dp in the em-wide FlutterTest face and fit in the
        // face players actually see — the overflow check below is only
        // meaningful in the latter.
        await _loadRoboto(tester);
        await _pump(tester, game, width: 390, fontFamily: _roboto);
        await _switchToSell(tester);
        expect(
          find.descendant(
            of: _rowFor(_bindweed),
            matching: find.text('6 to sell'),
          ),
          findsOneWidget,
          reason: 'HAVE became the subline on Sell — the available count',
        );
        await _tapStepper(tester, _bindweed, Icons.add, times: 2);
        expect(
          find.descendant(
            of: _rowFor(_bindweed),
            matching: find.text('4 to sell'),
          ),
          findsOneWidget,
          reason:
              'live, like the column it replaces — a mutant printing '
              '`available` instead of `available − qty` still reads 6',
        );
        expect(
          find.descendant(
            of: _rowFor(_boundKey),
            matching: find.text('1 held'),
          ),
          findsOneWidget,
          reason:
              'a bound stack is never \'to sell\' — the word would contradict '
              'the line under it',
        );
        expect(
          find.descendant(
            of: _rowFor(_boundKey),
            matching: find.text('Bound — cannot be sold.'),
          ),
          findsOneWidget,
          reason: 'the phone row keeps the wide row\'s reason it is disabled',
        );
        expect(
          find.text('HAVE'),
          findsNothing,
          reason: 'the Sell header drops its HAVE column on a phone too',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'no overflow on the Sell tab at 390 dp',
        );
      });

      testWidgets('⭐ the phone header reads ITEM · PRICE, over the price', (
        tester,
      ) async {
        final game = _game(_MemStorage());
        await _pump(tester, game, width: 390);
        for (final gone in const ['STOCK', 'TOTAL']) {
          expect(
            find.text(gone),
            findsNothing,
            reason: '$gone heads a column the phone row no longer has',
          );
        }
        for (final kept in const ['ITEM', 'PRICE']) {
          expect(
            find.text(kept),
            findsOneWidget,
            reason: '$kept still heads a real cell on a phone',
          );
        }
        expect(
          tester.getTopRight(find.text('PRICE')).dx,
          tester.getTopRight(_priceCellOf(_oak)).dx,
          reason:
              'aligned to the cell it heads — the wide header\'s 118 px '
              'inset on a phone lands PRICE ~60 px left of the prices',
        );
        expect(
          find.descendant(of: _rowFor(_oak), matching: find.text('60')),
          findsNothing,
          reason: 'no bare QTY cell left behind in the phone row',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'no RenderFlex overflow on the phone Buy tab',
        );
      });

      testWidgets('at 900 dp the four headers and the qty/total cells are '
          'back', (tester) async {
        final game = _game(_MemStorage(), now: _quietDayFor(const [_oak]));
        await _pump(tester, game, width: 900);
        for (final h in const ['ITEM', 'STOCK', 'PRICE', 'TOTAL']) {
          expect(
            find.text(h),
            findsOneWidget,
            reason:
                'the wide header is untouched by the phone ruling — a mutant '
                'keyed on anything but chipBreakpoint drops $h here',
          );
        }
        expect(
          find.textContaining('in stock'),
          findsNothing,
          reason: 'no subline on a wide row — the STOCK column says it',
        );
        await _tapStepper(tester, _oak, Icons.add);
        final quote = game.priceShopBasket(
          townId: _townId,
          today: ShopState.epochDayOf(game.now()),
          buy: const {_oak: 1},
          sellStacks: const {},
          sellInstances: const {},
        );
        expect(
          find.descendant(of: _rowFor(_oak), matching: find.text('59')),
          findsOneWidget,
          reason: 'the QTY cell is back and live on a wide screen',
        );
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.text('${quote.buyGoldOf[_oak]}g'),
          ),
          findsWidgets,
          reason: 'the TOTAL cell is back and carries the quote',
        );
      });

      testWidgets('⭐ the stepper never moves — 2-digit vs 1-digit stock, and '
          'across a stock change', (tester) async {
        final game = _game(_MemStorage());
        await _pump(tester, game, width: 390);
        double plusX(String id) => tester
            .getTopLeft(
              find.descendant(
                of: _rowFor(id),
                matching: find.byIcon(Icons.add),
              ),
            )
            .dx;
        final rationStock = game.profile.shopStock[_townId]!.stockOf(_ration);
        expect(
          rationStock,
          lessThan(10),
          reason: 'the fixture: the ration shelf is 1-digit, oak\'s is 60',
        );
        final oakBefore = plusX(_oak);
        expect(
          plusX(_ration),
          oakBefore,
          reason:
              'rows with a 1-digit and a 2-digit subline put the stepper at '
              'the same x — the mutant that lets the name block size to its '
              'text (Flexible loose + no Expanded) walks it',
        );

        // Take oak from '60 in stock' to '9 in stock' in one edit.
        await tester.tap(
          find.descendant(of: _rowFor(_oak), matching: find.text('0')),
        );
        await tester.pump();
        await tester.enterText(
          find.descendant(of: _rowFor(_oak), matching: find.byType(TextField)),
          '51',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(
          find.descendant(of: _rowFor(_oak), matching: find.text('9 in stock')),
          findsOneWidget,
          reason: 'the premise: the subline really changed width',
        );
        expect(
          plusX(_oak),
          oakBefore,
          reason:
              'pressing must never move what was pressed — the + stays put '
              'when its row\'s subline shrinks a digit',
        );
      });

      testWidgets('buying 3 Oak Log on a phone updates the footer total', (
        tester,
      ) async {
        final game = _game(_MemStorage(), now: _quietDayFor(const [_oak]));
        await _pump(tester, game, width: 390);
        await _tapStepper(tester, _oak, Icons.add, times: 3);
        final quote = game.priceShopBasket(
          townId: _townId,
          today: ShopState.epochDayOf(game.now()),
          buy: const {_oak: 3},
          sellStacks: const {},
          sellInstances: const {},
        );
        expect(
          find.text('Buying 3 items −${quote.buyGold}g'),
          findsOneWidget,
          reason:
              'the row lost its TOTAL cell on a phone; the settle bar is '
              'where the basket total lives now, and it must still move',
        );
        expect(
          _displayedNet(tester),
          quote.net,
          reason: 'the Settle button charges the same live total',
        );
        expect(
          find.descendant(
            of: _rowFor(_oak),
            matching: find.text('57 in stock'),
          ),
          findsOneWidget,
          reason: 'and the subline counts down with the basket',
        );
      });

      testWidgets('the stock number is one tap away, as a dialog chip', (
        tester,
      ) async {
        final game = _game(_MemStorage(), storeroomStacks: {_bindweed: 6});
        // Roboto for the Sell tab's four-chip toolbar — see the Sell test.
        await _loadRoboto(tester);
        await _pump(tester, game, width: 390, fontFamily: _roboto);
        await _tapRowInfo(tester, _rowFor(_oak), _name(_oak));
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('60 in stock'),
          ),
          findsOneWidget,
          reason:
              'the dialog tags carry the full count — a subline that '
              'ellipsizes must not be the only place the number lives',
        );
        await _closeItemDialog(tester);

        await _switchToSell(tester);
        await _tapRowInfo(tester, _rowFor(_bindweed), _name(_bindweed));
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('6 to sell'),
          ),
          findsOneWidget,
          reason: 'the Sell row\'s dialog carries its count the same way',
        );
        await _closeItemDialog(tester);
      });
    },
  );
}

/// A `+` stepper button reads as disabled when its icon is painted
/// `AppColors.textFaint` (see `_StepButton`) — the same signal a sighted
/// player reads, rather than reaching into private state.
bool _isDisabledStepper(WidgetTester tester, Finder plus) {
  final icon = tester.widget<Icon>(plus.first);
  return icon.color == AppColors.textFaint;
}
