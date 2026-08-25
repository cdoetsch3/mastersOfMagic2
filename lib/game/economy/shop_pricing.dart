import 'dart:math' as math;

/// The general shop's pricing curve (`ECONOMY_CONTRACT.md` §3) — pure
/// arithmetic, no Flutter, no item catalogue, no config fetching. This file
/// owns *only* the formula; the config sibling wires `config/economy` into
/// [locationMod]/[eventMod]/[resupplyRate] and the catalogue sibling supplies
/// each item's `base` (`ItemDef.value`) and `equilibrium` (§5). Every knob
/// here is a parameter, never a global, so those two owners can swap live
/// values in without touching this file.
///
/// ⭐ **The one invariant this whole file exists to protect (§3.2):** a trade
/// of N units is N separate unit prices, each computed against the stock
/// level as it stands *after* the previous unit in the same transaction —
/// never the whole batch priced once at the stock level the transaction
/// started at. [ShopPricing.buyQuote] and [ShopPricing.sellQuote] are the
/// only sanctioned way to price a multi-unit trade; nothing else in this file
/// should ever be asked to price more than one unit at a time.
abstract final class ShopPricing {
  /// §3.1's clamp bounds on the scarcity multiplier `(E/stock)^0.5`.
  static const double minMultiplier = 0.4;
  static const double maxMultiplier = 2.5;

  /// ✅ Ruled spread (§3.1): the player pays `price × buySpread` to buy and
  /// receives `price × sellSpread` to sell. A same-day, same-stock round
  /// trip loses `1 − sellSpread / buySpread ≈ 18%` — see [buyQuote]/
  /// [sellQuote] doc for why a *walked* round trip is not exactly this
  /// number, only close to it.
  static const double buySpread = 1.10;
  static const double sellSpread = 0.90;

  /// ✅ Ruled flat vendor-sink rate (§2.4, ruling 3): items that are never
  /// shop stock — gear, and anything else not in the fungible pool — can
  /// still be sold *to* a shop at this flat fraction of `base`, with no
  /// stock tracking and no buy side at all. A pure sink, not part of the
  /// stock curve above.
  static const double vendorSinkRate = 0.6;

  /// The scarcity multiplier `clamp((equilibrium / stock)^0.5, 0.4, 2.5)`.
  ///
  /// ⚠️ **§3.3's zero-stock guard.** `equilibrium / stock` is undefined at
  /// `stock == 0` (and `stock` should never be negative, but a caller who
  /// hands one over is guarded identically) — rather than divide by zero,
  /// treat it as already at the clamp's own ceiling: an empty shelf is
  /// maximum scarcity, exactly what the formula already means at its cap.
  static double multiplier({required int equilibrium, required int stock}) {
    if (stock <= 0) return maxMultiplier;
    final raw = math.sqrt(equilibrium / stock);
    if (raw < minMultiplier) return minMultiplier;
    if (raw > maxMultiplier) return maxMultiplier;
    return raw;
  }

  /// `price(item) = base × clamp((E/stock)^0.5, 0.4, 2.5) × locationMod ×
  /// eventMod` — §3.1, exactly, and deliberately returned as an unrounded
  /// `double`.
  ///
  /// ⭐ **Why this stays a double.** §5.2's worked price tables pin fractional
  /// values cell by cell (`61.24`, not `61`) — this function is what those
  /// tests pin. Rounding to whole gold only happens where a real transaction
  /// actually changes hands: per unit, inside [buyQuote]/[sellQuote].
  static double price({
    required int base,
    required int equilibrium,
    required int stock,
    double locationMod = 1.0,
    double eventMod = 1.0,
  }) =>
      base *
      multiplier(equilibrium: equilibrium, stock: stock) *
      locationMod *
      eventMod;

  /// The unrounded buy price for one unit at the given stock — `price ×
  /// 1.10`. See [price] for why this is a double, not gold.
  static double buyPrice({
    required int base,
    required int equilibrium,
    required int stock,
    double locationMod = 1.0,
    double eventMod = 1.0,
  }) =>
      price(
        base: base,
        equilibrium: equilibrium,
        stock: stock,
        locationMod: locationMod,
        eventMod: eventMod,
      ) *
      buySpread;

  /// The unrounded sell price for one unit — `price × 0.90`.
  static double sellPrice({
    required int base,
    required int equilibrium,
    required int stock,
    double locationMod = 1.0,
    double eventMod = 1.0,
  }) =>
      price(
        base: base,
        equilibrium: equilibrium,
        stock: stock,
        locationMod: locationMod,
        eventMod: eventMod,
      ) *
      sellSpread;

  /// Rounds a gold amount **half away from zero** — the rule this contract's
  /// build brief names explicitly for per-unit transaction gold.
  ///
  /// ⚠️ Every price in this file is `>= 0`, where "half away from zero" and
  /// "half up" (`.round()`'s own behaviour) coincide — this is spelled out as
  /// its own function anyway, rather than inlined as `.round()`, so a mutant
  /// that swaps in `.floor()`/`.ceil()` has a single, obviously-named target
  /// to fail against instead of hiding behind a builtin.
  static int roundGold(double value) =>
      value >= 0 ? (value + 0.5).floor() : -((-value + 0.5).floor());

  /// The flat vendor-sink price for a non-stocked item (§2.4, ruling 3) —
  /// `base × 0.6`, rounded to gold. No stock, no location/event modifier: a
  /// pure "turn this into gold" sink, independent of any shop's stock curve.
  static int vendorPrice(int base) => roundGold(base * vendorSinkRate);

  /// ⭐ **The marginal buy walk (§3.2).** Prices [n] units one at a time:
  /// unit `i` is priced against the stock level as it stood *after* unit
  /// `i − 1` of THIS SAME transaction (unit 1 prices at the stock the
  /// transaction started with, exactly as §3.2's worked example states) —
  /// buying drains the shop, so stock strictly decreases as the walk
  /// proceeds, and each later unit is priced into a scarcer shelf than the
  /// one before it.
  ///
  /// ⚠️ **Never batch-prices.** The named exploit this guards against: pricing
  /// all `n` units once, at the stock level the transaction *started* at
  /// (§3.2's worked table — 50 units of a nearly-sold-out potion, priced as
  /// if the shop still had only 2, comes out ~4.75× too cheap for the buyer
  /// or, symmetrically, ~4.75× too generous for the shop). Every unit here is
  /// its own call into [buyPrice], rounded to gold via [roundGold]
  /// individually and summed — never a single multiplication by `n`.
  ///
  /// [equilibrium] is fixed across the walk (it is a fact about the item, not
  /// the transaction); [stock] is the starting point. §3.3's zero-stock floor
  /// applies mid-walk too — stock never drops below 0, so once a buy run
  /// empties the shelf, every remaining unit prices at the clamp ceiling
  /// rather than diverging.
  static ShopQuote buyQuote({
    required int n,
    required int base,
    required int equilibrium,
    required int stock,
    double locationMod = 1.0,
    double eventMod = 1.0,
  }) {
    var s = stock;
    var total = 0;
    for (var i = 0; i < n; i++) {
      total += roundGold(
        buyPrice(
          base: base,
          equilibrium: equilibrium,
          stock: s,
          locationMod: locationMod,
          eventMod: eventMod,
        ),
      );
      if (s > 0) s -= 1; // §3.3: the shelf never goes negative.
    }
    return ShopQuote(totalGold: total, newStock: s);
  }

  /// ⭐ **The marginal sell walk (§3.2)**, symmetric with [buyQuote]: unit `i`
  /// prices at the stock level after unit `i − 1` of this transaction, and
  /// selling *floods* the shop, so stock strictly increases as the walk
  /// proceeds — the first units sold into a scarce shop fetch the best price,
  /// and later units in the same dump price progressively lower, exactly the
  /// worked exploit table in §3.2 (the correct column, not the batch one).
  static ShopQuote sellQuote({
    required int n,
    required int base,
    required int equilibrium,
    required int stock,
    double locationMod = 1.0,
    double eventMod = 1.0,
  }) {
    var s = stock;
    var total = 0;
    for (var i = 0; i < n; i++) {
      total += roundGold(
        sellPrice(
          base: base,
          equilibrium: equilibrium,
          stock: s,
          locationMod: locationMod,
          eventMod: eventMod,
        ),
      );
      s += 1;
    }
    return ShopQuote(totalGold: total, newStock: s);
  }
}

/// The result of walking a marginal trade (§3.2): the total gold that
/// changed hands, and the stock the shop is left at afterward.
class ShopQuote {
  final int totalGold;
  final int newStock;

  const ShopQuote({required this.totalGold, required this.newStock});

  @override
  String toString() => 'ShopQuote(totalGold: $totalGold, newStock: $newStock)';

  @override
  bool operator ==(Object other) =>
      other is ShopQuote &&
      other.totalGold == totalGold &&
      other.newStock == newStock;

  @override
  int get hashCode => Object.hash(totalGold, newStock);
}
