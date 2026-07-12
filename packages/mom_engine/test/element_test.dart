import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  group('counter wheel invariants', () {
    test('every element is balanced: strengths == weaknesses', () {
      for (final e in MagicElement.values) {
        expect(e.strongAgainst.length, e.weakAgainst.length,
            reason: '${e.name} must have equal strengths and weaknesses');
      }
    });

    test('no element counters itself', () {
      for (final e in MagicElement.values) {
        expect(e.counters(e), isFalse);
      }
    });

    test('no mutual counters', () {
      for (final a in MagicElement.values) {
        for (final b in a.strongAgainst) {
          expect(b.counters(a), isFalse,
              reason: '${a.name} and ${b.name} counter each other');
        }
      }
    });
  });

  group('designed volatilities', () {
    test('air is the untouchable wind (0/0)', () {
      expect(MagicElement.air.volatility, 0);
      expect(MagicElement.air.weakAgainst, isEmpty);
    });

    test('light and shadow are the volatile elements (3/3)', () {
      expect(MagicElement.light.volatility, 3);
      expect(MagicElement.shadow.volatility, 3);
    });

    test('classic elements are 2/2', () {
      for (final e in [
        MagicElement.fire,
        MagicElement.water,
        MagicElement.earth,
        MagicElement.electric,
        MagicElement.ice,
      ]) {
        expect(e.volatility, 2, reason: e.name);
      }
    });
  });

  group('flavor spot checks', () {
    test('water douses fire', () {
      expect(MagicElement.water.counters(MagicElement.fire), isTrue);
    });

    test('light banishes shadow, but shadow does not banish light', () {
      expect(MagicElement.light.counters(MagicElement.shadow), isTrue);
      expect(MagicElement.shadow.counters(MagicElement.light), isFalse);
    });

    test('light outshines the other light sources', () {
      expect(MagicElement.light.strongAgainst,
          {MagicElement.shadow, MagicElement.fire, MagicElement.electric});
    });

    test('shadow claims the dark places', () {
      expect(MagicElement.shadow.strongAgainst,
          {MagicElement.water, MagicElement.earth, MagicElement.ice});
    });
  });
}
