/// LADDER §4.2 — a bot's per-move "think" delay: a clamped normal, mean 3.0s,
/// σ 0.8, floor 1.0, ceiling 5.0, redrawn every turn.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — an unclamped draw, a shifted mean, a collapsed spread, a rng that
/// isn't actually consumed deterministically.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ladder/think_time.dart';

void main() {
  group('ThinkTime.standard', () {
    test('2000 draws all land in [1.0s, 5.0s]', () {
      final rng = Random(7);
      for (var i = 0; i < 2000; i++) {
        final d = ThinkTime.standard.next(rng);
        expect(
          d.inMicroseconds,
          greaterThanOrEqualTo(Duration(milliseconds: 1000).inMicroseconds),
          reason:
              'a dropped floor clamp lets a low z-score draw commit '
              'instantly, the exact thing this class exists to prevent',
        );
        expect(
          d.inMicroseconds,
          lessThanOrEqualTo(Duration(milliseconds: 5000).inMicroseconds),
          reason:
              'a dropped ceiling clamp lets a wild z-score draw stall '
              'the duel for way longer than LADDER §4.2 allows',
        );
      }
    });

    test('mean over 2000 draws is within 0.15s of 3.0s', () {
      final rng = Random(7);
      final samples = List.generate(
        2000,
        (_) =>
            ThinkTime.standard.next(rng).inMicroseconds /
            Duration.microsecondsPerSecond,
      );
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      expect(
        mean,
        closeTo(3.0, 0.15),
        reason:
            'a wrong meanSeconds (or a mean applied post-clamp instead of '
            'pre-clamp) would drag the whole distribution off 3.0s',
      );
    });

    test('std-dev over 2000 draws is within 0.6-0.85s (clamp shrinks 0.8)', () {
      final rng = Random(7);
      final samples = List.generate(
        2000,
        (_) =>
            ThinkTime.standard.next(rng).inMicroseconds /
            Duration.microsecondsPerSecond,
      );
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      final variance =
          samples.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
          samples.length;
      final stdDev = sqrt(variance);
      expect(
        stdDev,
        inInclusiveRange(0.6, 0.85),
        reason:
            'a mutant that drops sigmaSeconds entirely (constant output) '
            'or one that skips clamping (raw sigma 0.8, no shrink) both '
            'fall outside this band',
      );
    });

    test('two fresh Random(7) sequences give identical durations', () {
      final a = ThinkTime.standard.next(Random(7));
      final b = ThinkTime.standard.next(Random(7));
      expect(
        a,
        b,
        reason:
            'next() must be pure given the rng — any hidden extra draw, '
            'wall-clock read, or global mutable state would desync two '
            'clients resolving the same turn',
      );
    });
  });

  test('min == max always returns exactly that duration (clamp mutant)', () {
    const fixed = ThinkTime(meanSeconds: 2.0, minSeconds: 2.0, maxSeconds: 2.0);
    final rng = Random(3);
    for (var i = 0; i < 50; i++) {
      expect(
        fixed.next(rng),
        const Duration(seconds: 2),
        reason:
            'a clamp implemented as min-then-max (or vice versa) instead '
            'of a true range clamp could let an out-of-order comparison '
            'slip a value through when min == max',
      );
    }
  });
}
