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

    test('Tier 3 (Celestial): Solar → Lunar → Astral → Solar', () {
      expect(MagicElement.solar.counters(MagicElement.lunar), isTrue);
      expect(MagicElement.lunar.counters(MagicElement.astral), isTrue);
      expect(MagicElement.astral.counters(MagicElement.solar), isTrue);
    });

    test('Tier 4 (Ethereal): Sanctus → Umbra → Arcane → Sanctus', () {
      expect(MagicElement.sanctus.counters(MagicElement.umbra), isTrue);
      expect(MagicElement.umbra.counters(MagicElement.arcane), isTrue);
      expect(MagicElement.arcane.counters(MagicElement.sanctus), isTrue);
    });
  });

  group('the V2 roster', () {
    test('twelve elements in four tiers', () {
      expect(MagicElement.values.length, 12);
      expect(MagicTier.values.length, 4);
    });

    test('tier membership is exactly as designed', () {
      expect(
        MagicElement.values.where((e) => e.tier == MagicTier.celestial),
        [MagicElement.solar, MagicElement.lunar, MagicElement.astral],
      );
      expect(
        MagicElement.values.where((e) => e.tier == MagicTier.ethereal),
        [MagicElement.sanctus, MagicElement.umbra, MagicElement.arcane],
      );
    });

    test('"radiant" is gone — the name is now "sanctus"', () {
      expect(MagicElement.values.map((e) => e.name), isNot(contains('radiant')));
      expect(MagicElement.values.map((e) => e.name), contains('sanctus'));
    });
  });

  // TYPE_EFFECTS_DESIGN §0.3. The higher tier beats the one below it, and
  // Primal beats Ethereal — the anti-power-creep valve.
  group('macro-tier loop', () {
    test('the designed edges', () {
      expect(MagicTier.kinetic.countersTier(MagicTier.primal), isTrue);
      expect(MagicTier.celestial.countersTier(MagicTier.kinetic), isTrue);
      expect(MagicTier.ethereal.countersTier(MagicTier.celestial), isTrue);
      expect(MagicTier.primal.countersTier(MagicTier.ethereal), isTrue,
          reason: 'Primal beats Ethereal — the anti-power-creep valve');
    });

    test('every tier counters exactly one and is countered by one', () {
      for (final t in MagicTier.values) {
        expect(MagicTier.values.where(t.countersTier).length, 1,
            reason: '$t counters');
        expect(MagicTier.values.where((o) => o.countersTier(t)).length, 1,
            reason: '$t countered by');
      }
    });

    test('it is a single 4-cycle, not two 2-cycles', () {
      final visited = <MagicTier>{};
      var cur = MagicTier.primal;
      for (var i = 0; i < 4; i++) {
        visited.add(cur);
        cur = cur.beatsTier;
      }
      expect(cur, MagicTier.primal, reason: 'cycle should close');
      expect(visited.length, 4, reason: 'cycle should visit all four tiers');
    });

    test('no tier counters itself, and no mutual counters', () {
      for (final t in MagicTier.values) {
        expect(t.countersTier(t), isFalse);
        expect(t.beatsTier.countersTier(t), isFalse,
            reason: '$t and ${t.beatsTier} counter each other');
      }
    });

    test('beatenByTier is the inverse of beatsTier', () {
      for (final t in MagicTier.values) {
        expect(t.beatenByTier.beatsTier, t);
      }
    });

    test('opposite tiers are neutral both ways', () {
      expect(MagicTier.primal.isNeutralWith(MagicTier.celestial), isTrue);
      expect(MagicTier.celestial.isNeutralWith(MagicTier.primal), isTrue);
      expect(MagicTier.kinetic.isNeutralWith(MagicTier.ethereal), isTrue);
      expect(MagicTier.ethereal.isNeutralWith(MagicTier.kinetic), isTrue);
    });

    test('a tier is not "neutral" with itself — that is the element triangle',
        () {
      for (final t in MagicTier.values) {
        expect(t.isNeutralWith(t), isFalse);
      }
    });

    test('adjacent tiers are never neutral', () {
      for (final t in MagicTier.values) {
        expect(t.isNeutralWith(t.beatsTier), isFalse);
        expect(t.beatsTier.isNeutralWith(t), isFalse);
      }
    });
  });
}
