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
      // broke the day the north road went in between them.
      final edge = World.byId('pennycross').edgeTo('the_bellows_gap')!;
      final r = Travel.route('pennycross', 'the_bellows_gap')!;
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
}
