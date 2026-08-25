import 'dart:math' as math;

/// Per-character shop state — nightly resupply catch-up and deterministic
/// daily events (`ECONOMY_CONTRACT.md` §6, §11). Pure Dart, no Flutter, no
/// item catalogue, no config fetching: the catalogue sibling supplies each
/// town's item ids and equilibrium values, the config sibling supplies live
/// `resupplyRate`/event tunables from `config/economy`, and the caller
/// supplies "today" — this file never calls `DateTime.now()` itself, exactly
/// so a resolved day is reproducible from its inputs alone.

/// One town's shop state for one character (§11.1). Keyed externally by town
/// id on `PlayerProfile.shopStock`, mirroring `Storeroom`'s own per-town map.
class TownShopState {
  /// itemId -> current stock count.
  final Map<String, int> stock;

  /// UTC epoch day (§6.1) this town's stock was last resolved to. One clock
  /// per town, not per item — see [ShopState.resolve].
  final int lastResetDay;

  const TownShopState({this.stock = const {}, required this.lastResetDay});

  /// ⚠️ Mirrors `Storeroom.isEmpty` — an entry with no stock recorded is
  /// indistinguishable from "never visited" and should not be written to
  /// disk (see `PlayerProfile.toJson`'s sparse-write pattern for
  /// `storerooms`, which `shopStock` copies verbatim).
  bool get isEmpty => stock.isEmpty;

  /// Current stock of [itemId], or `0` if this town's saved state has never
  /// recorded it. ⚠️ This is a raw accessor, not the contract's "absent =
  /// fresh from E" rule — that rule is about a whole *town* being absent
  /// from the profile's `shopStock` map (or an item never having been
  /// resolved into this town's `stock` map yet), and is applied by
  /// [ShopState.resolve], not here.
  int stockOf(String itemId) => stock[itemId] ?? 0;

  Map<String, dynamic> toJson() => {
    if (stock.isNotEmpty) 'stock': stock,
    'lastResetDay': lastResetDay,
  };

  factory TownShopState.fromJson(Map<String, dynamic>? json) =>
      TownShopState(
        stock:
            (json?['stock'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            const {},
        lastResetDay: (json?['lastResetDay'] as num?)?.toInt() ?? 0,
      );
}

/// Nightly resupply catch-up (§6.1) and deterministic daily events (§6.2).
abstract final class ShopState {
  /// 📝 The contract's default `RESUPPLY_RATE` (`config/economy`'s own
  /// default; the config sibling may override per §7). Named here so a
  /// caller who has not yet wired the config path still gets the ruled
  /// default rather than an arbitrary one.
  static const double defaultResupplyRate = 0.5;

  /// 📝 §6.2's defaults: ~2 affected items per shop per day, ±20%.
  static const int defaultEventItemsPerDay = 2;
  static const double defaultEventMagnitudePercent = 20;

  /// UTC epoch day (days since 1970-01-01 UTC) for [date] — the shared clock
  /// unit both [resolve] and [eventsFor] key off.
  ///
  /// ⚠️ Always normalises through UTC first: a local `DateTime` passed
  /// in must not shift which day a reset or event falls on for a player in
  /// a different time zone than another player looking at the same shop the
  /// same instant — §6.2 requires every client to agree.
  static int epochDayOf(DateTime date) {
    final u = date.toUtc();
    return DateTime.utc(
      u.year,
      u.month,
      u.day,
    ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// §6.1's nightly resupply, resolved in **closed form** — a character who
  /// returns after `n` days away resolves all `n` applications of
  /// `stock += (E − stock) × rate` in one step, never a loop that replays
  /// every missed midnight:
  ///
  /// ```
  /// stock_n = E − (E − stock_0)(1 − rate)^n
  /// ```
  ///
  /// [state] is the character's saved state for this town, or `null` if
  /// they have never visited it. [itemIds] is this shop's *current*
  /// catalogue (the catalogue sibling's list — content that adds an item to
  /// a town's shelf after this character's last visit needs no migration,
  /// per §11.1 it just resolves at equilibrium, exactly like a brand-new
  /// item on a first-ever visit).
  ///
  /// ⚠️ **§11.1's "absent = fresh from E" rule, both levels of absence:** a
  /// `null` [state] (never visited this town) and a `state` whose `stock`
  /// map is simply missing one of [itemIds] (an item newer than the
  /// character's last visit) are treated identically — `stock_0 = E`, which
  /// collapses the recurrence to `stock_n = E` for any `n`. There is
  /// deliberately no special-cased branch for this; it falls out of the
  /// formula for free once `stock_0` is read as `equilibriumOf(id)` rather
  /// than `0` in the absent case.
  static TownShopState resolve({
    required TownShopState? state,
    required int today,
    required Iterable<String> itemIds,
    required int Function(String itemId) equilibriumOf,
    double resupplyRate = defaultResupplyRate,
  }) {
    final elapsedDays = state == null
        ? 0
        : math.max(0, today - state.lastResetDay);
    // (1 - rate)^n — computed once, reused per item. rate==1.0 collapses this
    // to 0 for any elapsedDays >= 1 (pow(0, positive) == 0), which is exactly
    // "fully resupplied by the next reset", the documented rate==1.0 case.
    final decay = math.pow(1 - resupplyRate, elapsedDays).toDouble();
    final next = <String, int>{};
    for (final id in itemIds) {
      final equilibrium = equilibriumOf(id);
      final stock0 = state?.stock.containsKey(id) == true
          ? state!.stock[id]!.toDouble()
          : equilibrium.toDouble(); // absent → already at E, see doc above.
      final resolved = equilibrium - (equilibrium - stock0) * decay;
      next[id] = _roundStock(resolved);
    }
    return TownShopState(stock: next, lastResetDay: today);
  }

  /// Stock is a count, never fractional and never negative — round half away
  /// from zero (the house rounding rule) and floor at 0.
  static int _roundStock(double value) =>
      value <= 0 ? 0 : (value + 0.5).floor();

  /// §6.2's deterministic daily events: picks up to [itemsPerDay] of
  /// [candidateItemIds] (this shop's catalogue) for [today] and assigns each
  /// a `±magnitudePercent%` `eventMod` — `1.0 + 0.20` or `1.0 - 0.20` at the
  /// defaults. Everything not picked is absent from the returned map (read
  /// that as `eventMod = 1.0`, no effect).
  ///
  /// ⭐ **Seeded ONLY from `(shopId, today, itemId)`** — the same three
  /// facts every client already agrees on (§1.1) — so every player sees the
  /// identical spike/glut days with zero writes and zero server round trip.
  /// Two different shops, or the same shop on two different days, are
  /// independent draws; the *same* `(shopId, today)` always reproduces the
  /// identical pick and directions.
  ///
  /// ⚠️ **Deliberately does not use `Random()` at all, seeded or not, and
  /// does not use `String.hashCode`.** `String.hashCode` is explicitly
  /// unspecified/platform-dependent by the Dart language (only guaranteed
  /// consistent *within* one isolate's lifetime, not across the VM vs
  /// dart2js/dartdevc web compilers this game ships to) — using it here
  /// would silently desync exactly the clients §6.2 requires to agree.
  /// [_stableHash] is a hand-rolled, fully-specified hash instead.
  static Map<String, double> eventsFor({
    required String shopId,
    required int today,
    required Iterable<String> candidateItemIds,
    int itemsPerDay = defaultEventItemsPerDay,
    double magnitudePercent = defaultEventMagnitudePercent,
  }) {
    // Dedupe + sort first: the result must not depend on the iteration order
    // of whatever collection the caller happened to hand over.
    final ids = candidateItemIds.toSet().toList()..sort();
    if (ids.isEmpty || itemsPerDay <= 0) return const {};
    final ranked = [
      for (final id in ids) MapEntry(id, _stableHash('$shopId|$today|$id')),
    ]..sort((a, b) {
      final byHash = a.value.compareTo(b.value);
      return byHash != 0 ? byHash : a.key.compareTo(b.key);
    });
    final picked = ranked.take(
      itemsPerDay > ids.length ? ids.length : itemsPerDay,
    );
    return {
      for (final e in picked)
        e.key:
            1 +
            (_stableHash('$shopId|$today|${e.key}|dir').isEven ? 1 : -1) *
                magnitudePercent /
                100,
    };
  }

  /// A hand-rolled 31-bit polynomial hash (the shape of Java's
  /// `String.hashCode`, masked to `0x7FFFFFFF` at every step so it never
  /// exceeds JS's 53-bit safe-integer range on web) — see [eventsFor]'s doc
  /// for why this exists instead of the built-in `String.hashCode`.
  static int _stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }
}
