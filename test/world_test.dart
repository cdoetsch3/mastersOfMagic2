import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// Guards the world graph rebuilt from Plate I-b (WORLD_DESIGN.md).
///
/// Most of these catch the same class of bug: a hand-authored graph that looks
/// fine in the source but strands a player, or drifts away from the design doc
/// one edit at a time.
void main() {
  final byId = {for (final l in World.locations) l.id: l};

  group('graph integrity', () {
    test('ids are unique and every connection resolves', () {
      final ids = World.locations.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate location id');

      for (final l in World.locations) {
        for (final c in l.connections) {
          expect(byId, contains(c),
              reason: '${l.id} connects to "$c", which does not exist');
          expect(c, isNot(l.id), reason: '${l.id} connects to itself');
        }
        expect(l.connections.toSet().length, l.connections.length,
            reason: '${l.id} lists a duplicate connection');
      }
    });

    test('walkable connections are bidirectional', () {
      // Travel is `location.connections.contains(target)`, so a one-way edge
      // is a trap: you walk in and cannot walk out.
      for (final l in World.locations) {
        for (final c in l.connections) {
          expect(byId[c]!.connections, contains(l.id),
              reason: '${l.id} -> $c is one-way; $c must list ${l.id} back');
        }
      }
    });

    test('every location is reachable on foot from Aldermere', () {
      final seen = <String>{World.startLocationId};
      final queue = <String>[World.startLocationId];
      while (queue.isNotEmpty) {
        for (final c in byId[queue.removeLast()]!.connections) {
          if (seen.add(c)) queue.add(c);
        }
      }
      final unreachable = byId.keys.toSet().difference(seen);
      expect(unreachable, isEmpty,
          reason: 'stranded location(s): ${unreachable.join(", ")}');
    });

    test('teleports point at real towns and only Zenith has them', () {
      for (final l in World.locations) {
        if (l.id == 'zenith') continue;
        expect(l.teleportsTo, isEmpty,
            reason: '${l.id} should not be a teleport hub');
      }
      final zenith = byId['zenith']!;
      for (final t in zenith.teleportsTo) {
        expect(byId[t]?.isTown, isTrue, reason: '$t is not a town');
      }
      // Every town except Zenith itself.
      expect(zenith.teleportsTo.toSet(),
          World.townIds.toSet().difference({'zenith'}));
    });
  });

  group('the finale — one world, one crossing', () {
    test('the summit is never climbed: no walk from Vespergate to Zenith', () {
      expect(byId['vespergate']!.connections, isNot(contains('zenith')),
          reason: 'the last pitch is impassable (WORLD_DESIGN §1.3)');
    });

    test('the Citadel is the only way into Zenith', () {
      final intoZenith = World.locations
          .where((l) => l.connections.contains('zenith'))
          .map((l) => l.id)
          .toList();
      expect(intoZenith, ['the_eclipsed_citadel'],
          reason: 'Zenith is entered from above, through the Citadel');
    });

    test('the Veil is crossed at exactly two places', () {
      final doors = <String>{};
      for (final l in World.locations) {
        for (final c in l.connections) {
          if (l.plane != byId[c]!.plane) doors.add('${l.id}->$c');
        }
      }
      // Vespergate is the way OUT; the summit is the way BACK IN, through the
      // Citadel. Both read twice because walkable edges are bidirectional —
      // and the Zenith side staying open is what lets the Citadel be re-run at
      // scaling difficulty (GAME_DESIGN §3c).
      expect(doors, {
        'vespergate->the_collapsed_academy',
        'the_collapsed_academy->vespergate',
        'the_eclipsed_citadel->zenith',
        'zenith->the_eclipsed_citadel',
      });

      // The two doors are distinct places, and neither is a shortcut past the
      // other: you cannot reach the summit-side door without the Citadel.
      expect(byId['zenith']!.connections, ['the_eclipsed_citadel']);
    });

    test('the Empyrean stays small — three places, not a tier', () {
      final empyrean =
          World.locations.where((l) => l.plane == WorldPlane.empyrean);
      expect(empyrean.map((l) => l.id).toSet(), {
        'the_collapsed_academy',
        'the_unwritten_library',
        'the_eclipsed_citadel',
      });
      for (final l in empyrean) {
        expect(l.hasMoon, isFalse, reason: 'no moon above the Veil');
      }
    });

    test('only Arcane left the world', () {
      // Every Arcane place is above the Veil; nothing else is.
      final arcaneZones =
          World.withElement(MagicElement.arcane).where((l) => !l.isTown);
      for (final l in arcaneZones) {
        expect(l.plane, WorldPlane.empyrean, reason: '${l.id} carries Arcane');
      }
      // Sanctus and Umbra stayed on the mountain.
      for (final e in [MagicElement.sanctus, MagicElement.umbra]) {
        final onTheVault = World.withElement(e)
            .where((l) => l.plane == WorldPlane.world && l.id != 'the_eclipsed_citadel');
        expect(onTheVault, isNotEmpty, reason: '$e should still be terrain');
      }
    });
  });

  group('elements and tiers', () {
    test('all twelve elements appear somewhere', () {
      for (final e in MagicElement.values) {
        expect(World.withElement(e), isNotEmpty,
            reason: '${e.name} has no home in the world');
      }
    });

    test('every element has exactly one pure zone', () {
      for (final e in MagicElement.values) {
        final pure = World.locations
            .where((l) => l.elements.length == 1 && l.elements.single == e);
        expect(pure.length, 1,
            reason: '${e.name} should have exactly one pure zone, '
                'found ${pure.map((l) => l.id).toList()}');
      }
    });

    test('a zone\'s elements belong to its own tier, or an adjacent one', () {
      // Hybrids may pair across tiers (Frostfell is Aqua+Aero); a *pure* zone
      // must sit in its element's own tier.
      for (final l in World.locations.where((l) => l.elements.length == 1)) {
        expect(l.tier, l.elements.single.tier,
            reason: '${l.id} is a pure ${l.elements.single.name} zone but '
                'sits in the ${l.tier?.name} band');
      }
    });

    test('the Citadel is a hybrid of all twelve', () {
      expect(byId['the_eclipsed_citadel']!.elements.toSet(),
          MagicElement.values.toSet());
    });

    test('towns have no bestiary and no adventure', () {
      for (final t in World.towns) {
        expect(t.elements, isEmpty, reason: '${t.id} is a town');
        expect(t.hasAdventure, isFalse);
        expect(t.minLevel, 0);
        expect(t.maxLevel, 0);
      }
      expect(World.towns.map((t) => t.id).toList(), World.townIds);
    });
  });

  group('the two deliberate exceptions to the climb', () {
    // 📝 Altitude is no longer tracked as data — the terrain carries it. But
    // the design intent behind these two places is not about numbers, and if
    // either is ever "tidied" onto the main road the point is lost.

    test('Tidewrack Shoals is a late zone reached by SEA, not by climbing', () {
      final tidewrack = byId['tidewrack_shoals']!;
      expect(tidewrack.minLevel, greaterThan(35),
          reason: 'it is Celestial-band content');
      expect(tidewrack.connections, contains('galehaven'),
          reason: 'the sea passage is what gives the port an endgame purpose');
    });

    test('the Molten Deep is reached by going DOWN through the quarry', () {
      final molten = byId['the_molten_deep']!;
      expect(molten.kind, LocationKind.dungeon,
          reason: 'it is an interior, not open ground');
      expect(molten.connections,
          containsAll(<String>['old_quarry', 'cinderpeak_foothills']),
          reason: 'the descent runs under both');
    });

    test('Thin Air covers the Celestial shelf and nothing else', () {
      for (final l in World.locations) {
        expect(l.hasThinAir, l.tier == MagicTier.celestial,
            reason: '${l.id}: Thin Air is Celestial-only (WORLD_DESIGN §4.1)');
      }
    });
  });

  group('player-facing content', () {
    test('every place has a blurb and arrival text', () {
      for (final l in World.locations) {
        expect(l.blurb.trim(), isNotEmpty, reason: l.id);
        expect(l.arrival.trim().length, greaterThan(40),
            reason: '${l.id} arrival text looks like a stub');
      }
    });

    test('every zone has a themed opponent, not the fallback', () {
      for (final l in World.locations.where((l) => l.hasAdventure)) {
        expect(World.opponentNameFor(l), isNot('Wandering Mage'),
            reason: '${l.id} has no themed opponent');
      }
    });

    test('crafting is decentralised — one station per town, six skills', () {
      final stationed =
          World.towns.where((t) => t.station != null && t.id != 'zenith');
      final names = stationed.map((t) => t.station!).toList();
      expect(names.toSet().length, names.length,
          reason: 'two towns claim the same station');
      expect(names.length, 6, reason: 'six making-skills across the towns');
      // Concordance and Pennycross are civic on purpose.
      expect(byId['concordance']!.station, isNull);
      expect(byId['pennycross']!.station, isNull);
      // Zenith alone has everything.
      expect(byId['zenith']!.station, isNotNull);
    });

    test('each tier gate is recorded on the place that enforces it', () {
      for (final id in [
        'aldermere',
        'concordance',
        'rimeholt',
        'the_eclipsed_citadel',
        'zenith',
      ]) {
        expect(byId[id]!.gate, isNotNull, reason: '$id is a gate');
      }
    });
  });

}
