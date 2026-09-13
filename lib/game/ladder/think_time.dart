import 'dart:math';

/// LADDER §4.2 — how long a bot "thinks" per move, so it never answers
/// instantly. ⭐ A clamped normal: mean 3.0 s, σ 0.8, floor 1.0, ceiling 5.0,
/// redrawn every turn. ⚠️ Pure given the Random: the same rng sequence yields
/// the same durations (tests depend on this).
class ThinkTime {
  final double meanSeconds;
  final double sigmaSeconds;
  final double minSeconds;
  final double maxSeconds;

  const ThinkTime({
    this.meanSeconds = 3.0,
    this.sigmaSeconds = 0.8,
    this.minSeconds = 1.0,
    this.maxSeconds = 5.0,
  });

  static const standard = ThinkTime();

  /// Box–Muller on two `rng.nextDouble()` draws, clamped to
  /// [minSeconds, maxSeconds].
  ///
  /// ⚠️ Box–Muller's `log` blows up at `u1 == 0` (log(0) is -infinity), and
  /// `Random.nextDouble()` can return exactly 0.0 — so the draw used in the
  /// log is `1 - nextDouble()`, which ranges over (0, 1] instead of [0, 1).
  Duration next(Random rng) {
    final u1 = 1 - rng.nextDouble();
    final u2 = rng.nextDouble();
    final z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    final seconds = (meanSeconds + z0 * sigmaSeconds).clamp(
      minSeconds,
      maxSeconds,
    );
    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }
}
