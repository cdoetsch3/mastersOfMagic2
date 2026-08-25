// GREEDY-BOT ECONOMY PROBE — a deterministic, seeded, headless simulation of
// optimal exploitation strategies against the real shop economy
// (`ECONOMY_CONTRACT.md` §10, the anti-exploit probe, and §9's 2,400 g/day
// sanity ceiling). Same shape as `tool/balance_probe_test.dart`: lives in
// tool/, CI-fast by default, a deep run behind an env flag, and the printed
// report IS the deliverable a maintainer reads.
//
//   flutter test tool/economy_probe_test.dart                 (CI-fast)
//   ECONOMY_PROBE_DEEP=1 flutter test tool/economy_probe_test.dart  (deep)
//
// ⭐ **Built through the real production seam, never re-derived.** Every
// price this file prints comes from [ShopPricing]'s actual marginal-walk
// arithmetic, every stock number from [ShopState]'s actual nightly
// resupply/event machinery, every catalogue fact from [ShopCatalogue] and
// [ItemCatalogue], every craft from the real [RecipeBook] and
// [CraftQuality.roll]. Nothing here reimplements a formula the game already
// owns — a bot's "optimal" choice is just a search over real quotes.
//
// ⚠️ **Four isolated bots, four isolated profiles.** Per §1.1, shop stock is
// personal — two characters see independently-draining shelves. Each
// strategy below gets its OWN [_BotShop] (its own per-town
// [TownShopState] map), exactly as if it were a different save file; they
// never share stock, never see each other's trades.
//
// 📝 **First-pass modelling calls, flagged rather than silently picked**
// (the same discipline `balance_probe_test.dart` uses for its sanity
// bands):
//  - A "player-day" is one nightly UTC reset cycle. Days are injected as a
//    sequential integer counter (0, 1, 2, ...), never `DateTime.now()` —
//    [ShopState.resolve]/[ShopState.eventsFor] only care about the
//    difference between "today" and "last reset", so this reproduces
//    exactly and needs no real calendar.
//  - The honest-income baseline (Strategy 4) and the "does a sustained
//    session fit in a day" question both anchor on §8.7's own ✅ canon
//    number — **80 duels, a sustained dedicated session** — rather than
//    inventing a second one.
//  - The hauler's travel-time variant treats one "day" as 1440 minutes (the
//    UTC reset cadence itself, §6.1) and asks whether a chosen route's
//    round-trip travel fits inside it. Under the **currently shipped**
//    [TravelTimes.perLegSeconds] (10s — the file's own doc says this is a
//    testing placeholder, "put this back to 3*60 before anyone plays for
//    real"), every route fits easily; see the report's own flagged finding.
//  - The §8.7/§9/§10 ~2,400g/day sanity ceiling is HARD-asserted only
//    against the three exploit strategies (round-tripper, hauler, crafter).
//    §8.7 derives 2,400g purely from duel gold (~80 duels × 30g flat) and
//    never counts gathered-material sale proceeds — so the gatherer-vendor
//    honest baseline (Strategy 4), which stacks BOTH honestly, is left
//    FLAGGED rather than hard-failed when it clears that duels-only number;
//    see Decision 4 (§8.7/end) for why that gap is a maintainer call, not a
//    probe defect.
library;
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart' show commonsPerSectionFor;
import 'package:masters_of_magic_2/game/crafting/craft_quality.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/world.dart';

// =========================================================================
// Shared facts, read from the real code — never hand-copied.
// =========================================================================

/// ✅ The five open towns (§14b.2 — the other four are closed this season).
/// Derived from [ShopCatalogue.status], not hand-typed, so a future town
/// opening flows in automatically.
final List<String> openTowns = [
  for (final e in ShopCatalogue.status.entries)
    if (e.value == ShopStatus.open) e.key,
];

/// §5.1's category → E lookup, read through [ShopCatalogue.categoryFor] so
/// the native/imported/consumable judgment itself is never re-derived here.
int equilibriumOf(String town, String item) =>
    switch (ShopCatalogue.categoryFor(town, item)) {
      ShopItemCategory.nativeMaterial => 60,
      ShopItemCategory.importedMaterial => 20,
      ShopItemCategory.consumable => 30,
    };

int baseValueOf(String item) => ItemCatalogue.byId(item).value;

double locationModOf(String town, String item) =>
    ShopCatalogue.locationModFor(town, item);

/// Shortest hop-count between two [World] locations (town or zone), walking
/// the real travel graph ([GameLocation.connections]) — used only to decide
/// how many [TravelTimes] legs a hauler's route costs, never to re-derive
/// adjacency the game already owns.
int hopsBetween(String a, String b) {
  if (a == b) return 0;
  final visited = <String>{a};
  var frontier = <String>[a];
  var depth = 0;
  while (frontier.isNotEmpty) {
    depth++;
    final next = <String>[];
    for (final id in frontier) {
      for (final n in World.byId(id).connections) {
        if (n == b) return depth;
        if (visited.add(n)) next.add(n);
      }
    }
    frontier = next;
  }
  throw StateError('no path from $a to $b — the town graph is disconnected');
}

// =========================================================================
// A bot's personal shop state — one per strategy, mirroring §1.1.
// =========================================================================

/// One bot's own view of every open town's shop: its own stock, its own
/// nightly resolution, its own daily events. Nothing here is shared between
/// bots, exactly as two characters' saves never share a shelf.
class _BotShop {
  final Map<String, TownShopState?> _state = {};
  final Map<String, Map<String, double>> _eventsToday = {};

  /// Resolves every open town's stock to [today] (§6.1's closed-form
  /// catch-up, walked one day at a time here since the bot visits every
  /// day) and rolls that day's deterministic events (§6.2).
  void beginDay(int today) {
    for (final town in openTowns) {
      final items = ShopCatalogue.stockFor(town);
      _state[town] = ShopState.resolve(
        state: _state[town],
        today: today,
        itemIds: items,
        equilibriumOf: (id) => equilibriumOf(town, id),
      );
      _eventsToday[town] = ShopState.eventsFor(
        shopId: town,
        today: today,
        candidateItemIds: items,
      );
    }
  }

  int stockOf(String town, String item) =>
      _state[town]?.stockOf(item) ?? equilibriumOf(town, item);

  double eventOf(String town, String item) => _eventsToday[town]?[item] ?? 1.0;

  ShopQuote quoteBuy(String town, String item, int n, {int? stockOverride}) =>
      ShopPricing.buyQuote(
        n: n,
        base: baseValueOf(item),
        equilibrium: equilibriumOf(town, item),
        stock: stockOverride ?? stockOf(town, item),
        locationMod: locationModOf(town, item),
        eventMod: eventOf(town, item),
      );

  ShopQuote quoteSell(String town, String item, int n, {int? stockOverride}) =>
      ShopPricing.sellQuote(
        n: n,
        base: baseValueOf(item),
        equilibrium: equilibriumOf(town, item),
        stock: stockOverride ?? stockOf(town, item),
        locationMod: locationModOf(town, item),
        eventMod: eventOf(town, item),
      );

  void _setStock(String town, String item, int newStock) {
    final cur = _state[town];
    if (cur == null) return;
    _state[town] = TownShopState(
      stock: {...cur.stock, item: newStock},
      lastResetDay: cur.lastResetDay,
    );
  }

  /// Buys [n] of [item] at [town], mutating this bot's own stock down, and
  /// returns the gold spent.
  int applyBuy(String town, String item, int n) {
    final q = quoteBuy(town, item, n);
    _setStock(town, item, q.newStock);
    return q.totalGold;
  }

  /// Sells [n] of [item] at [town], mutating this bot's own stock up, and
  /// returns the gold received.
  int applySell(String town, String item, int n) {
    final q = quoteSell(town, item, n);
    _setStock(town, item, q.newStock);
    return q.totalGold;
  }
}

// =========================================================================
// Strategy results and the shared report shape.
// =========================================================================

class _StrategyRun {
  final String label;
  final List<int> dailyGold;
  final List<String> notes;
  const _StrategyRun(this.label, this.dailyGold, [this.notes = const []]);

  double get meanPerDay =>
      dailyGold.isEmpty ? 0 : dailyGold.reduce((a, b) => a + b) / dailyGold.length;
  int get maxDay => dailyGold.isEmpty ? 0 : dailyGold.reduce(max);
  int get minDay => dailyGold.isEmpty ? 0 : dailyGold.reduce(min);
  int get total => dailyGold.fold(0, (a, b) => a + b);
}

// =========================================================================
// Strategy 1 — Round-tripper
// =========================================================================
//
// ⭐ **Buy N of the best item at the best town, sell the same N straight
// back, same day, same town.** §14b's "no backpack constraint locally" rule
// means quantity is bounded only by what the shop itself will absorb — so
// the search sweeps a spread of candidate N (never N=0; the bot commits to
// SOME trade every day, which is the whole point of testing whether trying
// harder ever turns this profitable) and reports the least-bad outcome
// found. `shop_pricing_test.dart`'s own swept invariant already proves this
// can never turn a genuine profit; this run demonstrates it holds through
// the catalogue's real values, real E, real location/event mods, and real
// day-to-day stock drift, not just the formula in isolation.

const _roundTripCandidateNs = [1, 2, 3, 5, 8, 13, 20, 30, 50];

_StrategyRun _runRoundTripper(int days) {
  final bot = _BotShop();
  final daily = <int>[];
  final worstOffenders = <String, int>{}; // 'town/item' -> best profit seen
  for (var d = 0; d < days; d++) {
    bot.beginDay(d);
    var bestProfit = 1 << 62;
    bestProfit = -bestProfit; // negative-infinity sentinel, avoids double math
    String? bestTown, bestItem;
    var bestN = 0;
    for (final town in openTowns) {
      for (final item in ShopCatalogue.stockFor(town)) {
        for (final n in _roundTripCandidateNs) {
          final buy = bot.quoteBuy(town, item, n);
          final sell = bot.quoteSell(town, item, n, stockOverride: buy.newStock);
          final profit = sell.totalGold - buy.totalGold;
          if (profit > bestProfit) {
            bestProfit = profit;
            bestTown = town;
            bestItem = item;
            bestN = n;
          }
        }
      }
    }
    if (bestTown != null) {
      // Apply for state continuity across days — buy then sell the same N.
      final buy = bot.applyBuy(bestTown, bestItem!, bestN);
      final sell = bot.applySell(bestTown, bestItem, bestN);
      final realized = sell - buy;
      daily.add(realized);
      final key = '$bestTown/$bestItem';
      if (!worstOffenders.containsKey(key) || realized > worstOffenders[key]!) {
        worstOffenders[key] = realized;
      }
    } else {
      daily.add(0);
    }
  }
  final closest = worstOffenders.entries.isEmpty
      ? null
      : worstOffenders.entries.reduce((a, b) => a.value > b.value ? a : b);
  final notes = [
    if (closest != null)
      'closest-to-profitable round trip found: ${closest.key} '
          '(${closest.value} g on its best day)',
  ];
  return _StrategyRun('round-tripper', daily, notes);
}

// =========================================================================
// Strategy 2 — Hauler
// =========================================================================
//
// ⭐ **One leg a day: cheapest-mod town to highest-mod town, quantity-optimal
// against BOTH curves, capped at [Carrying.backpackSlots] per §14b** — the
// "optimal daily circuit" collapses to picking the single best (item, buy
// town, sell town, N) triple once the 20-slot cap is the binding constraint
// (§14b's own "carry capacity is the arbitrage governor" ruling), which is
// why this searches the extremes of [ShopCatalogue.locationModFor] per item
// rather than every town pair — the spec's own phrasing ("cheapest-mod...
// highest-mod").

const _dayLengthMinutes = 1440; // one UTC reset cycle (§6.1), the travel budget.

Map<String, List<String>> _itemToStockingTowns() {
  final map = <String, List<String>>{};
  for (final town in openTowns) {
    for (final item in ShopCatalogue.stockFor(town)) {
      (map[item] ??= []).add(town);
    }
  }
  return map;
}

class _HaulRun {
  final _StrategyRun ignoreTravel;
  final _StrategyRun withTravel;
  final List<String> notes;
  const _HaulRun(this.ignoreTravel, this.withTravel, this.notes);
}

_HaulRun _runHauler(int days) {
  final bot = _BotShop();
  final itemTowns = _itemToStockingTowns()..removeWhere((k, v) => v.length < 2);
  final dailyA = <int>[]; // ignoring travel time
  final dailyB = <int>[]; // charging TravelTimes
  var maxHopsSeen = 0;
  var minHopsSeen = 1 << 30;
  var anyMultiDayRoute = false;

  for (var d = 0; d < days; d++) {
    bot.beginDay(d);
    var bestProfit = -(1 << 62);
    String? bItem, bBuy, bSell;
    var bN = 0;
    for (final entry in itemTowns.entries) {
      final item = entry.key;
      final towns = entry.value;
      // ⭐ Cheapest-mod / highest-mod extremes, per the spec's own phrasing —
      // not every town pair, since the 20-slot cap already governs how much
      // of any one spread is worth carrying.
      var buyTown = towns.first;
      var sellTown = towns.first;
      for (final t in towns) {
        if (locationModOf(t, item) < locationModOf(buyTown, item)) buyTown = t;
        if (locationModOf(t, item) > locationModOf(sellTown, item)) sellTown = t;
      }
      if (buyTown == sellTown) continue;
      for (var n = 1; n <= Carrying.backpackSlots; n++) {
        final buy = bot.quoteBuy(buyTown, item, n);
        final sell = bot.quoteSell(sellTown, item, n);
        final profit = sell.totalGold - buy.totalGold;
        if (profit > bestProfit) {
          bestProfit = profit;
          bItem = item;
          bBuy = buyTown;
          bSell = sellTown;
          bN = n;
        }
      }
    }

    if (bItem == null) {
      dailyA.add(0);
      dailyB.add(0);
      continue;
    }

    final cost = bot.applyBuy(bBuy!, bItem, bN);
    final revenue = bot.applySell(bSell!, bItem, bN);
    final profitA = revenue - cost;
    dailyA.add(profitA);

    final hops = hopsBetween(bBuy, bSell);
    maxHopsSeen = max(maxHopsSeen, hops);
    minHopsSeen = min(minHopsSeen, hops);
    final legMinutes = TravelTimes.between(bBuy, bSell); // flat per leg, real API
    final roundTripMinutes = hops * legMinutes * 2;
    final daysNeeded = (roundTripMinutes / _dayLengthMinutes).ceil().clamp(1, 1 << 30);
    if (daysNeeded > 1) anyMultiDayRoute = true;
    final profitB = daysNeeded <= 1 ? profitA : (profitA / daysNeeded).round();
    dailyB.add(profitB);
  }

  final notes = [
    'route hop counts observed: ${minHopsSeen == 1 << 30 ? 0 : minHopsSeen}'
        '-$maxHopsSeen legs, at ${TravelTimes.between('a', 'b')} min/leg '
        '(the CURRENTLY shipped TravelTimes.perLegSeconds=${TravelTimes.perLegSeconds}s — '
        "the file's own doc calls this a testing placeholder, "
        '"put this back to 3*60 before anyone plays for real")',
    if (!anyMultiDayRoute)
      '📝 no observed route needed more than one day of travel budget under '
          'the SHIPPED travel time — hauling-with-travel-time and '
          'hauling-ignoring-travel-time land within rounding of each other '
          'below. If/when perLegSeconds is restored to its intended 180s, '
          'this variant would meaningfully diverge from the no-travel-time '
          'one; today it does not.',
  ];
  return _HaulRun(
    _StrategyRun('hauler (ignore travel time)', dailyA),
    _StrategyRun('hauler (shipped travel time)', dailyB),
    notes,
  );
}

// =========================================================================
// Strategy 3 — Crafter
// =========================================================================
//
// ⭐ **Two margins named in the brief — +5 (the skill-ceiling-unlocks-Master
// line, `CraftQuality.skillCeiling`) and +15 (the floor-lifts-to-Ornate
// line, `CraftQuality.floor`)** — evaluated at a flawless execution
// (`grade: 1.0`), since an "optimal exploitation" bot is assumed to nail the
// gesture act every time; the roll's own weighting is what still caps it.
//
// ⭐ **Equipment sale value is day-independent (a flat 0.6× vendor sink,
// §2.4 ruling 3 — gear is never shop stock) but material/consumable output
// sale value is NOT** (it rides the real marginal sell curve when the
// output happens to be shop stock, e.g. a crafted potion) — so the quality
// distribution's EV is precomputed ONCE per (recipe, margin) via a seeded
// Monte Carlo over the REAL [CraftQuality.roll], and only the input-cost and
// non-equipment-output sides are re-evaluated per day against the bot's own
// drifting stock.

const _qualityMcSamples = 4000;

class _EquipEval {
  final double meanSaleGold;
  final double pMaster;
  final int masterSaleGold;
  const _EquipEval(this.meanSaleGold, this.pMaster, this.masterSaleGold);
}

int _equipmentSaleValue(EquipmentDef def, Quality q) {
  final scaled = def.value * q.statPercent / 100.0;
  return ShopPricing.vendorPrice(ShopPricing.roundGold(scaled));
}

/// Precomputes every equipment recipe's quality-roll EV at [margin], once,
/// via a seeded [Random] — pure function of margin and the recipe's output
/// def, never of the day or any shop's stock.
Map<String, _EquipEval> _precomputeEquipmentEvals(int margin, int seedBase) {
  final out = <String, _EquipEval>{};
  final skillCeiling = CraftQuality.skillCeiling(margin);
  var seed = seedBase;
  for (final recipe in RecipeBook.all) {
    final outputDef = ItemCatalogue.byId(recipe.outputId);
    if (outputDef is! EquipmentDef) continue;
    final rng = Random(seed++);
    var sumSale = 0.0;
    var masterCount = 0;
    for (var i = 0; i < _qualityMcSamples; i++) {
      final q = CraftQuality.roll(
        grade: 1.0,
        margin: margin,
        rng: rng,
        skillCeiling: skillCeiling,
      );
      sumSale += _equipmentSaleValue(outputDef, q);
      if (q == Quality.master) masterCount++;
    }
    out[recipe.id] = _EquipEval(
      sumSale / _qualityMcSamples,
      masterCount / _qualityMcSamples,
      _equipmentSaleValue(outputDef, Quality.master),
    );
  }
  return out;
}

/// The cheapest town to buy [input] at, given [bot]'s CURRENT stock — null
/// if no open town stocks it at all.
({String town, int cost})? _cheapestBuy(_BotShop bot, RecipeInput input) {
  String? bestTown;
  var bestCost = 1 << 30;
  for (final town in openTowns) {
    if (!ShopCatalogue.stockFor(town).contains(input.defId)) continue;
    final q = bot.quoteBuy(town, input.defId, input.count);
    if (q.totalGold < bestCost) {
      bestCost = q.totalGold;
      bestTown = town;
    }
  }
  return bestTown == null ? null : (town: bestTown, cost: bestCost);
}

/// The best-selling town for a non-equipment recipe output, marginal-priced
/// — falls back to the flat vendor sink if no open town's catalogue stocks
/// it (e.g. bronze/iron ingot, §14b.3).
({String? town, int gold}) _bestSell(_BotShop bot, String itemId, int n, int base) {
  String? bestTown;
  var bestGold = -1;
  for (final town in openTowns) {
    if (!ShopCatalogue.stockFor(town).contains(itemId)) continue;
    final q = bot.quoteSell(town, itemId, n);
    if (q.totalGold > bestGold) {
      bestGold = q.totalGold;
      bestTown = town;
    }
  }
  return bestTown == null ? (town: null, gold: ShopPricing.vendorPrice(base)) : (town: bestTown, gold: bestGold);
}

class _CrafterDayPick {
  final RecipeDef recipe;
  final Map<String, String> inputTowns;
  const _CrafterDayPick(this.recipe, this.inputTowns);
}

class _CrafterRun {
  final _StrategyRun run;
  final String bestRecipeSummary;
  final String masterLotterySummary;
  const _CrafterRun(this.run, this.bestRecipeSummary, this.masterLotterySummary);
}

_CrafterRun _runCrafter(int days, int margin, Map<String, _EquipEval> equipEvals) {
  final bot = _BotShop();
  final daily = <int>[];
  const maxCraftsPerDay = 40;
  RecipeDef? overallBest;
  var overallBestProfit = double.negativeInfinity;

  for (var d = 0; d < days; d++) {
    bot.beginDay(d);

    // ---- pick today's best recipe (evaluate, no mutation yet) ----------
    _CrafterDayPick? pick;
    var bestProfit = double.negativeInfinity;
    for (final recipe in RecipeBook.all) {
      var totalCost = 0;
      final inputTowns = <String, String>{};
      var feasible = true;
      for (final input in recipe.inputs) {
        final buy = _cheapestBuy(bot, input);
        if (buy == null) {
          feasible = false;
          break;
        }
        totalCost += buy.cost;
        inputTowns[input.defId] = buy.town;
      }
      if (!feasible) continue;
      final outputDef = ItemCatalogue.byId(recipe.outputId);
      final double saleValue;
      if (outputDef is EquipmentDef) {
        saleValue = equipEvals[recipe.id]!.meanSaleGold;
      } else {
        saleValue = _bestSell(
          bot,
          recipe.outputId,
          recipe.outputCount,
          outputDef.value,
        ).gold.toDouble();
      }
      final profit = saleValue - totalCost;
      if (profit > bestProfit) {
        bestProfit = profit;
        pick = _CrafterDayPick(recipe, inputTowns);
      }
      if (profit > overallBestProfit) {
        overallBestProfit = profit;
        overallBest = recipe;
      }
    }

    // ---- execute repeated crafts of the day's best recipe, mutating ----
    var dayGold = 0;
    if (pick != null) {
      final recipe = pick.recipe;
      final outputDef = ItemCatalogue.byId(recipe.outputId);
      for (var c = 0; c < maxCraftsPerDay; c++) {
        var cost = 0;
        var feasible = true;
        for (final input in recipe.inputs) {
          final town = pick.inputTowns[input.defId]!;
          if (!ShopCatalogue.stockFor(town).contains(input.defId)) {
            feasible = false;
            break;
          }
          cost += bot.quoteBuy(town, input.defId, input.count).totalGold;
        }
        if (!feasible) break;
        final double marginalSale;
        if (outputDef is EquipmentDef) {
          marginalSale = equipEvals[recipe.id]!.meanSaleGold;
        } else {
          marginalSale = _bestSell(
            bot,
            recipe.outputId,
            recipe.outputCount,
            outputDef.value,
          ).gold.toDouble();
        }
        if (marginalSale - cost <= 0) break;

        var actualCost = 0;
        for (final input in recipe.inputs) {
          final town = pick.inputTowns[input.defId]!;
          actualCost += bot.applyBuy(town, input.defId, input.count);
        }
        int actualSale;
        if (outputDef is EquipmentDef) {
          actualSale = ShopPricing.roundGold(equipEvals[recipe.id]!.meanSaleGold);
        } else {
          final sell = _bestSell(
            bot,
            recipe.outputId,
            recipe.outputCount,
            outputDef.value,
          );
          actualSale = sell.town == null
              ? ShopPricing.vendorPrice(outputDef.value)
              : bot.applySell(sell.town!, recipe.outputId, recipe.outputCount);
        }
        dayGold += actualSale - actualCost;
      }
    }
    daily.add(dayGold);
  }

  final bestSummary = overallBest == null
      ? 'no craftable recipe found (margin $margin)'
      : '${overallBest.id} (profit/craft ~${overallBestProfit.toStringAsFixed(1)}g at margin $margin)';

  var lotterySummary = 'n/a';
  if (overallBest != null) {
    final outputDef = ItemCatalogue.byId(overallBest.outputId);
    if (outputDef is EquipmentDef) {
      final eval = equipEvals[overallBest.id]!;
      // Recompute the input cost at fresh (day-zero) prices for a stable,
      // reportable single-craft baseline.
      final freshBot = _BotShop()..beginDay(0);
      var cost = 0;
      for (final input in overallBest.inputs) {
        cost += _cheapestBuy(freshBot, input)?.cost ?? 0;
      }
      final lotteryEv = eval.pMaster * eval.masterSaleGold - cost;
      lotterySummary =
          '${overallBest.id}: P(Master)=${(eval.pMaster * 100).toStringAsFixed(1)}%, '
          'Master sale=${eval.masterSaleGold}g, input cost=$cost g, '
          'lottery EV=${lotteryEv.toStringAsFixed(1)}g '
          '(vs blended EV=${(eval.meanSaleGold - cost).toStringAsFixed(1)}g)';
    }
  }

  return _CrafterRun(
    _StrategyRun('crafter (margin +$margin)', daily),
    bestSummary,
    lotterySummary,
  );
}

// =========================================================================
// Strategy 4 — Gatherer-vendor (the honest baseline)
// =========================================================================
//
// ⭐ **duels + gather-node yields, all-wins, sold at the best open town** —
// the non-exploit comparison point every other strategy is measured
// against. Runs/day derives from §8.7's own ✅ canon "sustained dedicated
// session ~80 duels", never a separately-invented number.
//
// 📝 **Simplification, flagged:** the gathered-material sale does not mutate
// this bot's own stock (unlike every other strategy here) — it is an
// honest-income YARDSTICK, not itself under exploit scrutiny, and the three
// harvests/run are small enough (a handful of units) that stock depletion
// from this alone would never be the interesting story. Nightly resupply and
// daily EVENTS still apply for real (via [_BotShop.beginDay]), so the
// baseline still breathes day to day.

_StrategyRun _runGatherer(int days, String zoneId) {
  final bot = _BotShop();
  final zone = World.byId(zoneId);
  final tier = zone.tier;
  final duelsPerRun = commonsPerSectionFor(tier) * 3 + 2 + 1; // 2 minis + 1 boss
  const dailyDuelBudget = 80; // ✅ ECONOMY_CONTRACT §8.7
  final runsPerDay = (dailyDuelBudget / duelsPerRun).floor().clamp(1, 1 << 30);
  final nodeDefs = GatherNodes.forZone(zoneId);
  final daily = <int>[];

  for (var d = 0; d < days; d++) {
    bot.beginDay(d);
    var dayGold = runsPerDay * duelsPerRun * 30; // ✅ flat Progression.winGold
    for (var r = 0; r < runsPerDay; r++) {
      for (var harvest = 0; harvest < 3; harvest++) {
        // one gather node per section (adventure.dart) — EV across the
        // zone's possible node defs, since the actual one is a random draw.
        if (nodeDefs.isEmpty) continue;
        var sumGold = 0.0;
        for (final node in nodeDefs) {
          final qty = ((node.min + node.max) / 2.0).round();
          if (qty <= 0) continue;
          final sell = _bestSell(bot, node.yieldsDefId, qty, baseValueOf(node.yieldsDefId));
          sumGold += sell.gold;
        }
        dayGold += (sumGold / nodeDefs.length).round();
      }
    }
    daily.add(dayGold);
  }
  final label = 'gatherer-vendor (${zone.name}, ${tier?.name ?? "?"}, '
      '$duelsPerRun duels/run, $runsPerDay runs/day)';
  return _StrategyRun(label, daily);
}

// =========================================================================
// Report assembly
// =========================================================================

class ProbeReport {
  final String table;
  final List<String> warnings;
  const ProbeReport(this.table, this.warnings);
}

const double _sanityCeilingGoldPerDay = 2400; // ✅ ECONOMY_CONTRACT §8.7/§9/§10

ProbeReport runEconomyProbe(int days) {
  final buf = StringBuffer();
  final warnings = <String>[];

  final roundTrip = _runRoundTripper(days);
  final haul = _runHauler(days);
  final equip5 = _precomputeEquipmentEvals(5, 1000);
  final equip15 = _precomputeEquipmentEvals(15, 2000);
  final craft5 = _runCrafter(days, 5, equip5);
  final craft15 = _runCrafter(days, 15, equip15);
  final gatherPrimal = _runGatherer(days, 'whispering_woods');
  final gatherKinetic = _runGatherer(days, 'old_quarry');

  // The bool marks whether this strategy's max-day gold is HARD-asserted
  // against [_sanityCeilingGoldPerDay] in the test below. The gatherer-
  // vendor rows are the honest baseline (duel gold §8.7 derives 2,400g
  // from, PLUS honestly-vendored gathered materials §8.7 never counted) —
  // exceeding the duels-only sanity number is a maintainer-facing finding,
  // not evidence of exploitability, so it is flagged in the table/warnings
  // below but never hard-asserted.
  final rows = <(_StrategyRun, bool hardCeiling)>[
    (roundTrip, true),
    (haul.ignoreTravel, true),
    (haul.withTravel, true),
    (craft5.run, true),
    (craft15.run, true),
    (gatherPrimal, false),
    (gatherKinetic, false),
  ];

  buf.writeln(
    'ECONOMY PROBE — $days player-day(s), ${openTowns.length} open towns '
    '(${openTowns.join(", ")})',
  );
  buf.writeln(
    '${'strategy'.padRight(72)}${'mean g/day'.padRight(12)}'
    '${'min'.padRight(9)}${'max'.padRight(9)}flag',
  );
  for (final (row, hardCeiling) in rows) {
    final overCeiling = row.maxDay > _sanityCeilingGoldPerDay;
    final flag = !overCeiling
        ? ''
        : hardCeiling
            ? 'WARN >2400g/day'
            : 'FLAG >2400g/day (honest baseline, not hard-asserted)';
    buf.writeln(
      row.label.padRight(72) +
          row.meanPerDay.toStringAsFixed(1).padRight(12) +
          '${row.minDay}'.padRight(9) +
          '${row.maxDay}'.padRight(9) +
          flag,
    );
    if (overCeiling) {
      warnings.add(
        hardCeiling
            ? '${row.label}: max day ${row.maxDay}g exceeds the §8.7/§9/§10 '
                '~2,400g/day sanity ceiling'
            : '📝 ${row.label}: max day ${row.maxDay}g exceeds the duels-only '
                '~2,400g/day sanity number once honestly-vendored gathered '
                'materials are added — Decision 4 (§8.7/end) territory, not '
                'hard-asserted here',
      );
    }
  }

  buf.writeln();
  buf.writeln('Round-tripper: ${roundTrip.notes.join("; ")}');
  buf.writeln('Hauler: ${haul.notes.join("; ")}');
  buf.writeln('Crafter +5:  best recipe: ${craft5.bestRecipeSummary}');
  buf.writeln('             master lottery: ${craft5.masterLotterySummary}');
  buf.writeln('Crafter +15: best recipe: ${craft15.bestRecipeSummary}');
  buf.writeln('             master lottery: ${craft15.masterLotterySummary}');

  // ---- Assertions-adjacent comparisons, printed either way -------------
  final honestBest = max(gatherPrimal.meanPerDay, gatherKinetic.meanPerDay);
  if (honestBest > 0) {
    final haulMultiple = haul.withTravel.meanPerDay / honestBest;
    buf.writeln();
    buf.writeln(
      'Hauling-with-travel (${haul.withTravel.meanPerDay.toStringAsFixed(1)}g/day) '
      'vs honest baseline (${honestBest.toStringAsFixed(1)}g/day): '
      '${haulMultiple.toStringAsFixed(2)}x',
    );
    if (haulMultiple > 3) {
      warnings.add(
        '📝 hauling-with-travel-time runs '
        '${haulMultiple.toStringAsFixed(2)}x the honest gatherer+duel baseline '
        '— flagged for the maintainer\'s tuning pass, not hard-asserted '
        '(§10\'s own "sane multiple" language is a knob, not a number)',
      );
    }
  }

  if (roundTrip.total > 0) {
    warnings.add(
      '🔴 round-tripper netted a positive total (${roundTrip.total}g) across '
      'the run — the marginal-pricing invariant may be broken',
    );
  }

  return ProbeReport(buf.toString(), warnings);
}

// =========================================================================
// main()
// =========================================================================

void main() {
  final deep = Platform.environment['ECONOMY_PROBE_DEEP'] == '1';
  // 📝 CI-fast default: a handful of player-days, seconds to run. The deep
  // run — what the maintainer actually reads gold/day figures from — is
  // 1,000 player-days and takes minutes; opt-in via ECONOMY_PROBE_DEEP=1,
  // exactly like the balance probe's own BALANCE_PROBE_DEEP.
  final days = deep ? 1000 : 5;

  test(
    'economy probe: greedy-bot exploitation strategies stay bounded',
    () {
      final report = runEconomyProbe(days);
      print(report.table);
      if (report.warnings.isEmpty) {
        print('\nNo warnings — every strategy stayed inside its sanity bounds.');
      } else {
        print('\nWARN:');
        for (final w in report.warnings) {
          print('  - $w');
        }
      }

      // ---- HARD assertions (§10) -----------------------------------
      final roundTrip = _runRoundTripper(days);
      expect(
        roundTrip.total,
        lessThanOrEqualTo(0),
        reason: 'round-tripping (buy then sell straight back, same town, '
            'same day) must never net positive across the run — §10\'s '
            'first required assertion',
      );

      final haul = _runHauler(days);
      final craft5 = _runCrafter(days, 5, _precomputeEquipmentEvals(5, 1000));
      final craft15 = _runCrafter(days, 15, _precomputeEquipmentEvals(15, 2000));
      // 📝 The 2,400g/day ceiling is hard-asserted only against the three
      // EXPLOIT strategies (round-tripper, hauler, crafter), not the
      // gatherer-vendor honest baseline. §8.7 derives 2,400g purely from
      // duel gold (~80 duels × 30g) and never accounts for the gathered
      // materials an honest, fully-engaged session also vendors along the
      // way — so a baseline that stacks BOTH honestly exceeding a
      // duels-only sanity number is not itself an exploit finding; it is
      // the reference other strategies are measured against. The report
      // table above still prints and WARN-flags it when it happens (see
      // the printed table's own flag column) so the maintainer sees it —
      // per Decision 4 (§8.7/end), whether the flat-duel-gold ruling still
      // holds against gathered-material income is exactly the kind of
      // "normal vs. exploit accumulation" call this probe is meant to
      // surface, not silently resolve by hard-failing the honest baseline.
      for (final run in [
        roundTrip,
        haul.ignoreTravel,
        haul.withTravel,
        craft5.run,
        craft15.run,
      ]) {
        expect(
          run.maxDay,
          lessThanOrEqualTo(_sanityCeilingGoldPerDay.round()),
          reason: '${run.label}: no strategy may exceed the §8.7/§9/§10 '
              '~2,400g/day sanity ceiling on any single day',
        );
      }

      // Hauling-with-travel must at least beat round-tripping (trivially
      // true since round-trip nets ≤ 0, but stated as its own assertion so
      // a future change to either strategy's shape cannot silently invert
      // it without a visible failure here).
      expect(
        haul.withTravel.meanPerDay,
        greaterThanOrEqualTo(roundTrip.meanPerDay),
        reason: 'hauling must beat round-tripping — §10\'s comparison, '
            'hard because it follows directly from the round-trip ≤ 0 proof',
      );
    },
    timeout: Timeout(Duration(minutes: deep ? 15 : 2)),
  );

  test('deterministic: two tiny runs print byte-identical reports', () {
    final a = runEconomyProbe(3);
    final b = runEconomyProbe(3);
    expect(
      a.table,
      b.table,
      reason: 'the report must be a pure function of its injected day '
          'indices — no wall clock, no unseeded rng',
    );
    expect(a.warnings, b.warnings);
  });

  group('probe machinery', () {
    test(
      "kills the probe-drifts-from-shop mutant: Hearthwood's day-zero "
      'oak_log price matches ShopPricing directly, not a re-derived number',
      () {
        // §5.2's own anchor item, at its native town, fresh stock (=E, so
        // multiplier is exactly 1.0), no event that day.
        const item = 'oak_log';
        const town = 'hearthwood';
        final base = baseValueOf(item);
        expect(base, 13, reason: '§14b.1 — the audit-derived shipped value');
        final eq = equilibriumOf(town, item);
        expect(eq, 60, reason: 'native material at its own town, §5.1');
        final loc = locationModOf(town, item);
        expect(loc, ShopCatalogue.nativeMod, reason: "Hearthwood IS oak_log's native town");

        final probePrice = ShopPricing.price(
          base: base,
          equilibrium: eq,
          stock: eq, // day-zero, fresh, = E
          locationMod: loc,
        );
        final directPrice = ShopPricing.price(
          base: 13,
          equilibrium: 60,
          stock: 60,
          locationMod: 0.75,
        );
        expect(probePrice, directPrice);
        expect(
          probePrice,
          closeTo(9.75, 0.001),
          reason: '13 × 1.0 (stock==E) × 0.75 (native) × 1.0 (no event)',
        );
      },
    );

    test(
      'kills the batch-pricing mutant: the exact round trip this probe '
      'finds acceptable-loss WOULD turn a profit under batch-at-'
      'starting-stock pricing (§3.2) — proving the marginal walk is what '
      'protects the economy, not luck in the numbers chosen',
      () {
        // Reuses shop_pricing_test.dart's own batch-mutant shape, applied
        // to one of the round-tripper's own candidate Ns (§10's round-tripper
        // sweeps [_roundTripCandidateNs], and this is deliberately one of
        // them) — a moderate trade at a well-stocked native town, exactly
        // like the exploit worked table in §3.2. n=20 was tried first but
        // rejected: at this exact (item, town, stock) the rounded batch buy
        // and batch sell totals land on the SAME gold value (215==215), a
        // coincidental tie that makes `greaterThan` fail without disproving
        // the exploit — n=30 clears that tie with margin to spare.
        const item = 'oak_log';
        const town = 'hearthwood';
        const n = 30;
        final base = baseValueOf(item);
        final eq = equilibriumOf(town, item);
        final loc = locationModOf(town, item);

        final correctBuy = ShopPricing.buyQuote(
          n: n,
          base: base,
          equilibrium: eq,
          stock: eq,
          locationMod: loc,
        );
        final correctSell = ShopPricing.sellQuote(
          n: n,
          base: base,
          equilibrium: eq,
          stock: correctBuy.newStock,
          locationMod: loc,
        );
        expect(
          correctSell.totalGold,
          lessThanOrEqualTo(correctBuy.totalGold),
          reason: 'the real marginal implementation never profits on this trip',
        );

        int batchBuyTotal(int stock) => ShopPricing.roundGold(
              ShopPricing.buyPrice(
                base: base,
                equilibrium: eq,
                stock: stock,
                locationMod: loc,
              ) *
                  n,
            );
        int batchSellTotal(int stock) => ShopPricing.roundGold(
              ShopPricing.sellPrice(
                base: base,
                equilibrium: eq,
                stock: stock,
                locationMod: loc,
              ) *
                  n,
            );

        final wrongBuyTotal = batchBuyTotal(eq);
        final wrongStockAfterBuy = max(0, eq - n);
        final wrongSellTotal = batchSellTotal(wrongStockAfterBuy);

        expect(
          wrongSellTotal,
          greaterThan(wrongBuyTotal),
          reason: '⚠️ THE EXPLOIT: batch-priced-at-current-stock turns this '
              'exact same round trip profitable — buy=$wrongBuyTotal '
              'sell=$wrongSellTotal — exactly the failure mode §3.2 names '
              'and ShopPricing.buyQuote/sellQuote structurally prevent by '
              'walking unit-by-unit instead',
        );
      },
    );

    test('openTowns is exactly the five §14b.2 towns', () {
      expect(
        openTowns.toSet(),
        {'hearthwood', 'pennycross', 'forgeholm', 'galehaven', 'concordance'},
      );
    });

    test('hopsBetween finds the real town-to-town paths', () {
      expect(hopsBetween('hearthwood', 'hearthwood'), 0);
      expect(hopsBetween('hearthwood', 'pennycross'), 1, reason: 'a direct road');
      expect(
        hopsBetween('hearthwood', 'forgeholm'),
        greaterThan(1),
        reason: 'Forgeholm is reached only through Old Quarry — no shortcut',
      );
    });
  });
}
