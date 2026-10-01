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
  ///
  /// ⚠️ **The healing half of §4b.2 is unimplemented as of 2026-09-30.**
  /// Health lives only on an adventure run (`AdventureRun.playerHp`) and every
  /// run starts full, so no town — passed through or arrived at — heals
  /// anything; the place sheet's "Heals at each town on the way." line was
  /// dropped for that reason (ruling 2026-09-30). `GameState.settleTravel`
  /// marks where the heal would go.
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

  /// The route as far as [stopIndex] inclusive — what is walked when the trip
  /// ends early at a shut gate ([TripPlan]).
  TravelRoute truncatedAt(int stopIndex) =>
      TravelRoute(stops.sublist(0, stopIndex + 1), legs.sublist(0, stopIndex));

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

  /// The quickest route from [fromId] to [toId] that only passes THROUGH
  /// places [passable] allows, or null when there is none.
  ///
  /// ⭐ **Per character, so not from the table.** The passage ruling
  /// (Christian, 2026-09-21) shuts every uncleared zone to through-traffic,
  /// and which zones are cleared differs per save — a single solved table
  /// cannot answer that. The table stays for the questions that really are
  /// the same for everyone ([labelBetween], [reachableFrom]).
  ///
  /// ⭐ [passable] is asked about the **middle** of the route only. The origin
  /// is where you stand, and the destination may be anything — ending in an
  /// uncleared zone is how you go and clear it. An impassable place is a dead
  /// end: it can be the last stop, never a waypoint.
  ///
  /// ⭐ **Deterministic tie-break**: quickest, then fewest stops, then the
  /// stop ids compared in order. Every leg costs the same today
  /// ([TravelTimes.perLegSeconds]), so ties are the common case, and a tie
  /// settled by map iteration order would make tests pin luck. 📝 While every
  /// leg costs the same, equal time already means equal stops — the
  /// fewest-stops rule only starts to bite once legs are priced apart.
  ///
  /// 📝 Dijkstra over [GameLocation.edges] with [TravelTimes] costs — a
  /// plain scan for the next node is quick enough for ~36 places.
  static TravelRoute? routeFor(
    String fromId,
    String toId, {
    required bool Function(String id) passable,
  }) {
    if (!World.exists(fromId) || !World.exists(toId)) return null;
    if (fromId == toId) return TravelRoute([fromId], const []);

    final best = <String, _Path>{
      fromId: _Path(0, [fromId]),
    };
    final settled = <String>{};
    while (true) {
      String? at;
      _Path? path;
      for (final e in best.entries) {
        if (settled.contains(e.key)) continue;
        if (path == null || e.value.compareTo(path) < 0) {
          at = e.key;
          path = e.value;
        }
      }
      if (at == null || path == null) return null;
      if (at == toId) return _routeAlong(path.stops);
      settled.add(at);
      // ⚠️ Reached, but not walked through — see the doc above.
      if (at != fromId && !passable(at)) continue;
      for (final e in World.byId(at).edges) {
        if (settled.contains(e.to)) continue;
        final next = _Path(
          path.seconds + TravelTimes.secondsBetween(at, e.to),
          [...path.stops, e.to],
        );
        final current = best[e.to];
        if (current == null || next.compareTo(current) < 0) best[e.to] = next;
      }
    }
  }

  static TravelRoute _routeAlong(List<String> stops) => TravelRoute(stops, [
    for (var i = 0; i + 1 < stops.length; i++)
      World.byId(stops[i]).edgeTo(stops[i + 1])!,
  ]);
}

/// A route as one character will actually walk it: the whole way to where
/// they asked to go, and where it ends early if a shut gate stands on it.
///
/// ⭐ **A shut gate ends the trip AT the gate** (ruling, Christian
/// 2026-09-30, building on 2026-09-25's mockup B). The road to a gate is
/// never refused; a longer trip through one simply stops there, and arrival
/// lands on the gate screen exactly as a trip *to* the gate does — the same
/// `PlayerProfile.shutGateHere` seam, not a second one.
class TripPlan {
  /// The whole route to the place asked for.
  final TravelRoute route;

  /// Index into [route]'s stops of the shut gate the trip stops at, or null
  /// when nothing stops it. ⚠️ May be the last stop: a trip *to* a shut gate
  /// stops at it too, and says so.
  final int? gateIndex;

  const TripPlan(this.route, this.gateIndex);

  /// Plans [route], stopping at the first place after the origin that
  /// [isShutGate] names. ⚠️ Never the origin — standing at a shut gate,
  /// the way back must not stop where it starts.
  factory TripPlan.of(
    TravelRoute route, {
    required bool Function(String id) isShutGate,
  }) {
    for (var i = 1; i < route.stops.length; i++) {
      if (isShutGate(route.stops[i])) return TripPlan(route, i);
    }
    return TripPlan(route, null);
  }

  /// What is actually walked: [route], or [route] cut at the gate.
  TravelRoute get walked =>
      gateIndex == null ? route : route.truncatedAt(gateIndex!);

  /// The shut gate the trip stops at, or null.
  String? get gateId => gateIndex == null ? null : route.stops[gateIndex!];
}

/// A candidate path in [Travel.routeFor], ordered by the tie-break rule.
class _Path implements Comparable<_Path> {
  final int seconds;
  final List<String> stops;
  const _Path(this.seconds, this.stops);

  @override
  int compareTo(_Path other) {
    if (seconds != other.seconds) return seconds.compareTo(other.seconds);
    if (stops.length != other.stops.length) {
      return stops.length.compareTo(other.stops.length);
    }
    for (var i = 0; i < stops.length; i++) {
      final c = stops[i].compareTo(other.stops[i]);
      if (c != 0) return c;
    }
    return 0;
  }
}

/// One cell of the solved table: what the trip costs, and the first step of it.
class _Hop {
  final int minutes;

  /// The next location on the way. Null only for a trip to yourself.
  final String? next;

  const _Hop(this.minutes, this.next);
}
