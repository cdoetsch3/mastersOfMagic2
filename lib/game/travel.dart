import 'world.dart';

/// A worked-out route across the road network.
///
/// ⭐ Travel is **point-to-point between any two towns** (WORLD_DESIGN §4b.2):
/// you pick a destination and pay the summed duration, rather than hopping
/// town by town. That is what makes the cost of a trip a property of the
/// *route* rather than of any one edge — and why the network is solved as a
/// whole rather than read one hop at a time.
class TravelRoute {
  /// Every location passed through, starting with the origin and ending with
  /// the destination. A trip to where you already are is a single stop.
  final List<String> stops;

  /// The legs walked, in order. One shorter than [stops].
  final List<TravelEdge> legs;

  const TravelRoute(this.stops, this.legs);

  /// Base seconds on foot, before any mount multiplier.
  ///
  /// ⭐ Summed from the **stops**, since [TravelTimes] reads the pair a leg
  /// joins rather than anything stored on the leg. ⭐ Seconds rather than
  /// minutes so a short test-build duration is expressible at all.
  int get seconds {
    var total = 0;
    for (var i = 0; i + 1 < stops.length; i++) {
      total += TravelTimes.secondsBetween(stops[i], stops[i + 1]);
    }
    return total;
  }

  /// Whole minutes, rounded up. ⚠️ Prefer [label] for anything a player reads.
  ///
  /// ⚠️ **Zero stays zero.** The floor of 1 exists so a short leg never reads
  /// as free — but a trip to where you already are genuinely costs nothing,
  /// and rounding that up to a minute is a lie.
  int get minutes =>
      seconds == 0 ? 0 : ((seconds / 60).ceil()).clamp(1, 1 << 30);

  /// What to show the player — "10s", "4 min".
  String get label => TravelTimes.label(seconds);

  String get from => stops.first;
  String get to => stops.last;

  bool get isTrivial => legs.isEmpty;

  /// The towns passed through on the way, excluding the origin.
  ///
  /// ⭐ A Journey stops at each of these to heal (§4b.2), which is what breaks
  /// a long road into survivable stages. This is the reason the network stores
  /// routes and not just durations: a table of times cannot say where you stop.
  List<String> get townStops => [
    for (final id in stops.skip(1))
      if (World.byId(id).isTown) id,
  ];

  /// True if any leg crosses water or the Veil rather than following a road.
  ///
  /// ⚠️ Not a mount rule — §4b.3 is explicit that mounts have **no terrain
  /// rules** and multiply everything equally. This is for passage and for
  /// drawing: WORLD_DESIGN §2.5 makes the sea crossing design-significant.
  bool get needsPassage => legs.any((l) => l.kind != TravelEdgeKind.road);

  @override
  String toString() => '${stops.join(' -> ')} (${minutes}m)';
}

/// Route planning over the world graph.
///
/// ⭐ **The whole network is solved once, into a table.** With 32 locations
/// there are only ~500 pairs, so every trip's duration and next hop are
/// computed on first use (Floyd–Warshall, ~32k steps) and read back in
/// constant time after that. Searching per-request would also have been fast
/// enough; a table is simply easier to reason about, and it means
/// [reachableFrom] is a lookup rather than 32 separate searches.
///
/// ⚠️ The table is **derived from [GameLocation.edges], never authored.** A
/// hand-written matrix would be ~500 numbers that must all be revisited
/// whenever any one of the 47 roads changes, and a stale entry looks entirely
/// plausible. Edges stay the single source of truth.
///
/// ⚠️ Reads [World] only through its edges. Nothing here knows where anything
/// is *drawn* — the graph/geometry seam that `world_map_test.dart` guards in
/// both directions stays intact, so the map can be redrawn without changing a
/// single travel time.
abstract final class Travel {
  static Map<String, Map<String, _Hop>>? _table;

  /// Solve every pair at once. Cheap enough to do lazily on first use.
  static Map<String, Map<String, _Hop>> get _solved {
    final cached = _table;
    if (cached != null) return cached;

    final ids = [for (final l in World.locations) l.id];
    final table = {for (final id in ids) id: <String, _Hop>{}};

    for (final id in ids) {
      table[id]![id] = const _Hop(0, null);
      for (final e in World.byId(id).edges) {
        // ⚠️ Cost comes from [TravelTimes], the active policy — NOT from
        // e.minutes, which holds the authored durations kept for tuning.
        table[id]![e.to] = _Hop(TravelTimes.secondsBetween(id, e.to), e.to);
      }
    }
    // Floyd–Warshall: allow each location in turn to be a waypoint.
    for (final via in ids) {
      for (final from in ids) {
        final toVia = table[from]![via];
        if (toVia == null) continue;
        for (final to in ids) {
          final onward = table[via]![to];
          if (onward == null) continue;
          final total = toVia.minutes + onward.minutes;
          final current = table[from]![to];
          if (current == null || total < current.minutes) {
            table[from]![to] = _Hop(total, toVia.next);
          }
        }
      }
    }
    return _table = table;
  }

  /// Discard the solved table. Only needed if the graph ever becomes mutable.
  static void invalidate() => _table = null;

  /// The quickest route between two locations, or null if none exists.
  static TravelRoute? route(String fromId, String toId) {
    if (!World.exists(fromId) || !World.exists(toId)) return null;
    if (fromId == toId) return TravelRoute([fromId], const []);
    if (_solved[fromId]![toId] == null) return null;

    final stops = <String>[fromId];
    final legs = <TravelEdge>[];
    var at = fromId;
    while (at != toId) {
      final next = _solved[at]![toId]!.next!;
      legs.add(World.byId(at).edgeTo(next)!);
      stops.add(next);
      at = next;
    }
    return TravelRoute(stops, legs);
  }

  /// Minutes on foot between two locations, or null if unreachable.
  /// Seconds between two places, or null if unreachable.
  static int? secondsBetween(String fromId, String toId) {
    if (!World.exists(fromId) || !World.exists(toId)) return null;
    return _solved[fromId]![toId]?.minutes;
  }

  /// Whole minutes, rounded up. ⚠️ Prefer [labelBetween] for display.
  static int? minutesBetween(String fromId, String toId) {
    final s = secondsBetween(fromId, toId);
    if (s == null) return null;
    return s == 0 ? 0 : ((s / 60).ceil()).clamp(1, 1 << 30);
  }

  /// What to show the player for a trip — "10s", "4 min".
  static String? labelBetween(String fromId, String toId) {
    final s = secondsBetween(fromId, toId);
    return s == null ? null : TravelTimes.label(s);
  }

  /// Every location reachable from [fromId], with the cost of getting there.
  static Map<String, int> reachableFrom(String fromId) => {
    if (World.exists(fromId))
      for (final e in _solved[fromId]!.entries) e.key: e.value.minutes,
  };
}

/// One cell of the solved table: what the trip costs, and the first step of it.
class _Hop {
  final int minutes;

  /// The next location on the way. Null only for a trip to yourself.
  final String? next;

  const _Hop(this.minutes, this.next);
}
