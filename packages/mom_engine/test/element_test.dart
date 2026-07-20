import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  group('counter-triangle invariants', () {
    test('every element counters exactly one and is countered by one', () {
      for (final e in MagicElement.values) {
        expect(e.strongAgainst.length, 1, reason: '${e.name} strengths');
        expect(e.weakAgainst.length, 1, reason: '${e.name} weaknesses');
        expect(e.volatility, 1, reason: '${e.name} volatility');
      }
    });

    test('no element counters itself', () {
      for (final e in MagicElement.values) {
        expect(e.counters(e), isFalse);
      }
    });

    test('no mutual counters (proper 3-cycles)', () {
      for (final a in MagicElement.values) {
        for (final b in a.strongAgainst) {
          expect(b.counters(a), isFalse,
              reason: '${a.name} and ${b.name} counter each other');
        }
      }
    });

    test('counteredBy is the inverse of counters', () {
      for (final e in MagicElement.values) {
        expect(e.counteredBy.counters(e), isTrue,
            reason: '${e.counteredBy.name} should counter ${e.name}');
      }
    });

    test('counters never cross tiers', () {
      for (final a in MagicElement.values) {
        for (final b in a.strongAgainst) {
          expect(b.tier, a.tier,
              reason: '${a.name} counters ${b.name} across tiers');
        }
      }
    });
  });

  group('tiers', () {
    test('three elements per tier', () {
      for (final tier in MagicTier.values) {
        final members =
            MagicElement.values.where((e) => e.tier == tier).toList();
        expect(members.length, 3, reason: '$tier');
      }
    });

    test('each tier forms a single closed 3-cycle', () {
      for (final tier in MagicTier.values) {
        final start = MagicElement.values.firstWhere((e) => e.tier == tier);
        // Walking the "counters" edge 3 times must return to the start,
        // visiting all three members (a proper cycle, not a degenerate one).
        final visited = <MagicElement>{};
        var cur = start;
        for (var i = 0; i < 3; i++) {
          visited.add(cur);
          cur = cur.strongAgainst.single;
        }
        expect(cur, start, reason: '$tier cycle should close');
        expect(visited.length, 3, reason: '$tier cycle should visit all 3');
      }
    });
  });

  group('designed triangles', () {
    test('Tier 1 (Primal): Pyro → Flora → Aqua → Pyro', () {
      expect(MagicElement.pyro.counters(MagicElement.flora), isTrue);
      expect(MagicElement.flora.counters(MagicElement.aqua), isTrue);
      expect(MagicElement.aqua.counters(MagicElement.pyro), isTrue);
    });

    test('Tier 2 (Kinetic): Electro → Aero → Geo → Electro', () {
      expect(MagicElement.electro.counters(MagicElement.aero), isTrue);
      expect(MagicElement.aero.counters(MagicElement.geo), isTrue);
      expect(MagicElement.geo.counters(MagicElement.electro), isTrue);
    });

    test('Tier 3 (Ethereal): Radiant → Umbra → Arcane → Radiant', () {
      expect(MagicElement.radiant.counters(MagicElement.umbra), isTrue);
      expect(MagicElement.umbra.counters(MagicElement.arcane), isTrue);
      expect(MagicElement.arcane.counters(MagicElement.radiant), isTrue);
    });
  });

}
