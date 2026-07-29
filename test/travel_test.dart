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
      final r = Travel.route('aldermere', 'aldermere')!;
      expect(r.minutes, 0);
      expect(r.isTrivial, isTrue);
      expect(r.stops, ['aldermere']);
    });

    test('a neighbour costs exactly its edge', () {
      final edge = World.byId('aldermere').edgeTo('pennycross')!;
      final r = Travel.route('aldermere', 'pennycross')!;
      expect(r.minutes, edge.minutes);
      expect(r.legs, [edge]);
      expect(r.stops, ['aldermere', 'pennycross']);
    });

    test('stops and legs line up', () {
      final r = Travel.route('aldermere', 'rimeholt')!;
      expect(r.legs.length, r.stops.length - 1);
      for (var i = 0; i < r.legs.length; i++) {
        expect(
          World.byId(r.stops[i]).edgeTo(r.stops[i + 1]),
          r.legs[i],
          reason: 'leg $i does not join its stops',
        );
      }
      expect(r.minutes, r.legs.fold<int>(0, (a, l) => a + l.minutes));
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
          final total = rest + e.minutes;
          if (best == null || total < best) best = total;
        }
        return best;
      }

      for (final pair in [
        ['aldermere', 'concordance'],
        ['galehaven', 'meridian'],
        ['pennycross', 'thunderspire_peaks'],
        ['forgeholm', 'the_kiln_desert'],
      ]) {
        final route = Travel.route(pair[0], pair[1])!;
        final truth = bruteForce(pair[0], pair[1], {pair[0]}, 9);
        expect(
          route.minutes,
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
          Travel.route('aldermere', loc.id),
          isNotNull,
          reason: '${loc.id} is stranded',
        );
      }
    });

    test('a Journey up the world stops at towns to heal', () {
      // §4b.2: Journey stops at each town on the way, which is what breaks a
      // long road into survivable stages.
      final r = Travel.route('aldermere', 'rimeholt')!;
      expect(r.townStops, isNotEmpty);
      for (final id in r.townStops) {
        expect(World.byId(id).isTown, isTrue);
      }
      expect(r.townStops, isNot(contains('aldermere')));
    });

    test('reaching Zenith needs passage the road cannot give', () {
      final r = Travel.route('aldermere', 'zenith')!;
      expect(
        r.needsPassage,
        isTrue,
        reason: 'the route crosses the Veil, which is not a road',
      );
      final overland = Travel.route('aldermere', 'concordance')!;
      expect(overland.needsPassage, isFalse);
    });

    test('nowhere is not a place', () {
      expect(Travel.route('aldermere', 'atlantis'), isNull);
      expect(Travel.route('atlantis', 'aldermere'), isNull);
    });
  });

  group('the shape of the world, in minutes', () {
    // ⚠️ These pin what the current graph actually costs, so a change to any
    // edge shows up as a changed *journey* rather than a changed number in a
    // file nobody reads. WORLD_DESIGN §4b.1's worked example predicted ~30
    // minutes for Aldermere -> Rimeholt; the real chain is 8 legs, not the ~6
    // the example assumed, so it is 39 at the design's own 5-minute baseline.
    test('the long climb costs what the design intends per leg', () {
      final r = Travel.route('aldermere', 'rimeholt')!;
      expect(r.legs.length, 8);
      expect(r.minutes, 39);
      expect(r.minutes / r.legs.length, closeTo(5, 1));
    });

    test('the first town hop is short, the campaign traverse is not', () {
      expect(Travel.minutesBetween('aldermere', 'pennycross'), 3);
      expect(Travel.minutesBetween('aldermere', 'zenith'), greaterThan(60));
    });
  });
}
