import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/game/world.dart';

/// Phase 5b, step one: roads are objects that cost time, and a trip is a
/// route over them rather than a single hop.
void main() {
  group('the road network', () {
    test('every road runs both ways, and costs the same both ways', () {
      // ⚠️ A road quicker one way than the other is a design decision nobody
      // has made. Adjacency symmetry was already guarded; duration symmetry
      // is new and just as easy to break by editing one end of a pair.
      for (final loc in World.locations) {
        for (final edge in loc.edges) {
          final back = World.byId(edge.to).edgeTo(loc.id);
          expect(
            back,
            isNotNull,
            reason: '${loc.id} -> ${edge.to} has no way back',
          );
          expect(
            back!.minutes,
            edge.minutes,
            reason: '${loc.id} <-> ${edge.to} disagree on duration',
          );
          expect(
            back.kind,
            edge.kind,
            reason: '${loc.id} <-> ${edge.to} disagree on kind',
          );
        }
      }
    });

    test('every road takes real time', () {
      // ⭐ Duration is the resource the trade economy is built on (§4b.1). A
      // zero-minute edge is a free teleport hiding in the graph.
      for (final loc in World.locations) {
        for (final edge in loc.edges) {
          expect(
            edge.minutes,
            greaterThan(0),
            reason: '${loc.id} -> ${edge.to} is instant',
          );
          expect(edge.minutes, lessThanOrEqualTo(20), reason: 'absurdly long');
        }
      }
    });

    test('connections stay in step with edges, because they are derived', () {
      for (final loc in World.locations) {
        expect(loc.connections, [for (final e in loc.edges) e.to]);
      }
    });

    test('the sea passage is not a road', () {
      // WORLD_DESIGN §2.5: Galehaven–Tidewrack is a crossing, and every edge
      // drawing as the same dashed line is what hid that.
      final leg = World.byId('galehaven').edgeTo('tidewrack_shoals');
      expect(leg, isNotNull);
      expect(leg!.kind, TravelEdgeKind.sea);
    });

    test('crossing the Veil is its own kind of leg', () {
      for (final loc in World.locations) {
        for (final edge in loc.edges) {
          final crosses = loc.plane != World.byId(edge.to).plane;
          expect(
            edge.kind == TravelEdgeKind.veil,
            crosses,
            reason: '${loc.id} -> ${edge.to}',
          );
        }
      }
    });
  });

  group('routes', () {
    test('going nowhere costs nothing', () {
      final r = Travel.route('hearthwood', 'hearthwood')!;
      // ⚠️ Zero, not the one-minute floor. A short leg must never read as
      // free; a trip you do not take genuinely is.
      expect(r.seconds, 0);
      expect(r.minutes, 0);
      expect(r.isTrivial, isTrue);
      expect(r.stops, ['hearthwood']);
    });

    test('a leg costs what the policy says, not what the edge says', () {
      // ⚠️ Two durations exist on purpose: TravelEdge.minutes holds the
      // hand-authored value kept for tuning, and TravelTimes is what travel
      // actually charges. This pins which one wins.
      // ⚠️ Must be an ADJACENT pair. This used to be pennycross→forgeholm and
      // broke the day the Old Quarry went in between them.
      final edge = World.byId('pennycross').edgeTo('old_quarry')!;
      final r = Travel.route('pennycross', 'old_quarry')!;
      expect(r.seconds, TravelTimes.perLegSeconds);
      expect(
        World.locations.expand((l) => l.edges).map((e) => e.minutes).toSet(),
        isNot(hasLength(1)),
        reason:
            'the authored durations vary; the policy does not — that is '
            'the whole point of keeping them apart',
      );
      expect(r.legs, [edge]);
    });

    test('stops and legs line up', () {
      final r = Travel.route('hearthwood', 'rimeholt')!;
      expect(r.legs.length, r.stops.length - 1);
      for (var i = 0; i < r.legs.length; i++) {
        expect(
          World.byId(r.stops[i]).edgeTo(r.stops[i + 1]),
          r.legs[i],
          reason: 'leg $i does not join its stops',
        );
      }
      expect(
        r.seconds,
        r.legs.length * TravelTimes.perLegSeconds,
        reason: 'cost comes from TravelTimes, not from leg.minutes',
      );
    });

    test('the route is the QUICKEST, not the one with fewest stops', () {
      // Dijkstra, not breadth-first. Verified against every simple path of a
      // reasonable length rather than against another shortest-path routine,
      // so the test cannot share a bug with the code under test.
      int? bruteForce(String from, String to, Set<String> seen, int depth) {
        if (from == to) return 0;
        if (depth == 0) return null;
        int? best;
        for (final e in World.byId(from).edges) {
          if (seen.contains(e.to)) continue;
          final rest = bruteForce(e.to, to, {...seen, e.to}, depth - 1);
          if (rest == null) continue;
          final total = rest + TravelTimes.secondsBetween(from, e.to);
          if (best == null || total < best) best = total;
        }
        return best;
      }

      for (final pair in [
        ['hearthwood', 'concordance'],
        ['galehaven', 'meridian'],
        ['pennycross', 'thunderspire_peaks'],
        ['forgeholm', 'the_kiln_desert'],
      ]) {
        final route = Travel.route(pair[0], pair[1])!;
        final truth = bruteForce(pair[0], pair[1], {pair[0]}, 9);
        expect(
          route.seconds,
          truth,
          reason: '${pair[0]} -> ${pair[1]} is not the quickest route',
        );
      }
    });

    test('the trip costs the same in both directions', () {
      for (final a in World.towns) {
        for (final b in World.towns) {
          expect(
            Travel.minutesBetween(a.id, b.id),
            Travel.minutesBetween(b.id, a.id),
            reason: '${a.id} <-> ${b.id}',
          );
        }
      }
    });

    test('every place can be reached from the starting town', () {
      for (final loc in World.locations) {
        expect(
          Travel.route('hearthwood', loc.id),
          isNotNull,
          reason: '${loc.id} is stranded',
        );
      }
    });

    test('a Journey up the world stops at towns to heal', () {
      // §4b.2: Journey stops at each town on the way, which is what breaks a
      // long road into survivable stages.
      final r = Travel.route('hearthwood', 'rimeholt')!;
      expect(r.townStops, isNotEmpty);
      for (final id in r.townStops) {
        expect(World.byId(id).isTown, isTrue);
      }
      expect(r.townStops, isNot(contains('hearthwood')));
    });

    test('reaching Zenith needs passage the road cannot give', () {
      final r = Travel.route('hearthwood', 'zenith')!;
      expect(
        r.needsPassage,
        isTrue,
        reason: 'the route crosses the Veil, which is not a road',
      );
      final overland = Travel.route('hearthwood', 'concordance')!;
      expect(overland.needsPassage, isFalse);
    });

    test('nowhere is not a place', () {
      expect(Travel.route('hearthwood', 'atlantis'), isNull);
      expect(Travel.route('atlantis', 'hearthwood'), isNull);
    });
  });

  group('the shape of the world, in minutes', () {
    // 📝 **One knob**: TravelTimes.perLegSeconds, currently 10 for testing.
    // ⚠️ A "1 minute a leg, 3 between towns" rule was tried and parked — two
    // ordinary legs undercut one town leg, so cutting through a zone beat the
    // direct road and the town cost almost never applied.
    test('every leg costs the same', () {
      for (final l in World.locations) {
        for (final e in l.edges) {
          expect(
            TravelTimes.secondsBetween(l.id, e.to),
            TravelTimes.perLegSeconds,
          );
        }
      }
    });

    test('a route costs its length', () {
      for (final pair in [
        ['hearthwood', 'whispering_woods'],
        ['hearthwood', 'pennycross'],
        ['hearthwood', 'rimeholt'],
      ]) {
        final r = Travel.route(pair[0], pair[1])!;
        expect(r.seconds, r.legs.length * TravelTimes.perLegSeconds);
      }
    });

    test('the longest journey is still the longest', () {
      // ⚠️ Relative, not absolute — the duration is a test-build value and
      // pinning a number here would fail the moment it is tuned.
      final short = Travel.secondsBetween('hearthwood', 'whispering_woods')!;
      final long = Travel.secondsBetween('hearthwood', 'zenith')!;
      expect(long, greaterThan(short * 5));
    });

    test('⚠️ a leg never reads as free, however short', () {
      // A 10-second leg must not display "0 min".
      expect(TravelTimes.label(10), '10s');
      expect(TravelTimes.label(180), '3 min');
      expect(TravelTimes.label(3900), '1h 05m');
      expect(TravelTimes.between('a', 'b'), greaterThanOrEqualTo(1));
    });
  });

  // ⭐ Ruling (Christian, 2026-09-30, playtest note 12): chained travel. A
  // route is planned per character — never THROUGH an uncleared zone — and
  // cut short at a shut gate.
  //
  // ⚠️ Another change is removing roads from the world. These tests lean on
  // Hearthwood – Pennycross – Old Quarry – Forgeholm only, and check every
  // other claim against a brute-force search of whatever roads exist.
  group('routeFor — the roads one character may walk', () {
    const chain = ['hearthwood', 'pennycross', 'old_quarry', 'forgeholm'];

    /// Every simple path from [from] to [to] of at most [depth] legs, whose
    /// middle [passable] allows — the same contract as routeFor, written as
    /// an exhaustive search so the two cannot share a bug.
    List<List<String>> allPaths(
      String from,
      String to,
      bool Function(String) passable,
      int depth,
    ) {
      final found = <List<String>>[];
      void walk(List<String> path) {
        final at = path.last;
        if (at == to) {
          found.add(path);
          return;
        }
        if (path.length > depth) return;
        if (at != from && !passable(at)) return;
        for (final e in World.byId(at).edges) {
          if (path.contains(e.to)) continue;
          walk([...path, e.to]);
        }
      }

      walk([from]);
      return found;
    }

    int secondsOf(List<String> stops) {
      var total = 0;
      for (var i = 0; i + 1 < stops.length; i++) {
        total += TravelTimes.secondsBetween(stops[i], stops[i + 1]);
      }
      return total;
    }

    /// The path the tie-break rule picks: quickest, fewest stops, then ids.
    List<String>? bestOf(List<List<String>> paths) {
      List<String>? best;
      for (final p in paths) {
        if (best == null) {
          best = p;
          continue;
        }
        final a = secondsOf(p), b = secondsOf(best);
        if (a != b) {
          if (a < b) best = p;
          continue;
        }
        if (p.length != best.length) {
          if (p.length < best.length) best = p;
          continue;
        }
        final current = best;
        for (var i = 0; i < p.length; i++) {
          final c = p[i].compareTo(current[i]);
          if (c < 0) best = p;
          if (c != 0) break;
        }
      }
      return best;
    }

    const pairs = [
      ['hearthwood', 'forgeholm'],
      ['pennycross', 'thunderspire_peaks'],
      ['hearthwood', 'concordance'],
      ['forgeholm', 'meridian'],
      ['old_quarry', 'thornmire'],
    ];

    test('with every road open it is the quickest route, ties broken '
        'by fewest stops then ids', () {
      for (final pair in pairs) {
        final r = Travel.routeFor(pair[0], pair[1], passable: (_) => true)!;
        expect(
          r.seconds,
          Travel.secondsBetween(pair[0], pair[1]),
          reason:
              '${pair[0]} -> ${pair[1]}: kills a mutant that is not the '
              'quickest (breadth-first on a weighted graph, or an early '
              'return before the destination is settled)',
        );
        expect(
          r.stops,
          bestOf(allPaths(pair[0], pair[1], (_) => true, 9)),
          reason:
              '${pair[0]} -> ${pair[1]}: kills a mutant whose tie-break is '
              'map order rather than fewest stops, then ids',
        );
        expect(
          r.legs.length,
          r.stops.length - 1,
          reason: 'kills a mutant that builds stops without their legs',
        );
      }
    });

    test('⭐ the Hearthwood – Forgeholm road is the four-stop chain', () {
      expect(
        Travel.routeFor(
          'hearthwood',
          'forgeholm',
          passable: (_) => true,
        )!.stops,
        chain,
        reason:
            'kills a mutant that detours — and pins the premise of every '
            'chained-travel test below',
      );
    });

    test('⭐ never THROUGH an impassable place', () {
      expect(
        Travel.routeFor(
          'hearthwood',
          'forgeholm',
          passable: (id) => id != 'old_quarry',
        ),
        isNull,
        reason:
            'kills the filter-dropped mutant: every road from the starting '
            'valley to Forgeholm runs through Old Quarry, so with every '
            'other place open the quarry alone still shuts it',
      );
      // Any blocked set, any pair: no route uses a blocked place as a
      // waypoint, and a route exists exactly when the brute force finds one.
      bool towns(String id) => World.byId(id).isTown;
      for (final pair in pairs) {
        final r = Travel.routeFor(pair[0], pair[1], passable: towns);
        final truth = bestOf(allPaths(pair[0], pair[1], towns, 9));
        expect(
          r?.stops,
          truth,
          reason:
              '${pair[0]} -> ${pair[1]} through towns only: kills a mutant '
              'that ignores passable, or refuses a route that exists',
        );
      }
    });

    test('⭐ a route may END in an impassable place', () {
      final r = Travel.routeFor(
        'hearthwood',
        'old_quarry',
        passable: (id) => World.byId(id).isTown,
      );
      expect(
        r?.stops,
        ['hearthwood', 'pennycross', 'old_quarry'],
        reason:
            'kills a mutant that filters the destination too — ending in an '
            'uncleared zone is how you go and clear it',
      );
    });

    test('the origin is always passable', () {
      expect(
        Travel.routeFor(
          'old_quarry',
          'forgeholm',
          passable: (id) => id != 'old_quarry',
        )?.stops,
        ['old_quarry', 'forgeholm'],
        reason: 'kills a mutant that filters the place you stand in',
      );
    });

    test('going nowhere, and nowhere at all', () {
      expect(
        Travel.routeFor(
          'pennycross',
          'pennycross',
          passable: (_) => false,
        )!.stops,
        ['pennycross'],
        reason: 'kills a mutant that treats a trip to yourself as no route',
      );
      expect(
        Travel.routeFor('hearthwood', 'atlantis', passable: (_) => true),
        isNull,
        reason: 'kills a mutant that throws on an unknown id',
      );
    });
  });

  group('TripPlan — a shut gate ends the trip there', () {
    final route = Travel.route('hearthwood', 'forgeholm')!;

    test('⭐ cut at the first shut gate after the origin', () {
      final plan = TripPlan.of(route, isShutGate: (id) => id == 'pennycross');
      expect(plan.walked.stops, [
        'hearthwood',
        'pennycross',
      ], reason: 'kills the not-truncated mutant: it walks past the gate');
      expect(
        plan.walked.legs.length,
        1,
        reason: 'kills a mutant that cuts the stops but not the legs',
      );
      expect(
        plan.gateId,
        'pennycross',
        reason: 'kills a mutant that forgets which gate stopped it',
      );
      expect(
        plan.route.stops,
        route.stops,
        reason: 'kills a mutant that loses the stops after the gate',
      );
    });

    test('a trip TO a shut gate says it stops there', () {
      final plan = TripPlan.of(
        Travel.route('hearthwood', 'pennycross')!,
        isShutGate: (id) => id == 'pennycross',
      );
      expect(
        plan.gateId,
        'pennycross',
        reason: 'kills a mutant that only looks at the middle of the route',
      );
    });

    test('⚠️ never the origin — the way back from a gate is open', () {
      final plan = TripPlan.of(
        Travel.route('pennycross', 'hearthwood')!,
        isShutGate: (id) => id == 'pennycross',
      );
      expect(
        plan.gateId,
        isNull,
        reason:
            'kills a mutant that checks stop 0: turning back would end '
            'where it starts',
      );
      expect(plan.walked.stops, [
        'pennycross',
        'hearthwood',
      ], reason: 'kills a mutant that truncates with no gate on the way');
    });
  });
}
