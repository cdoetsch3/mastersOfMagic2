/// Pure scoring for the crafting act (ITEMS §9b.9) — every number a gesture
/// engine turns into an accuracy lives here, testable without a widget.
///
/// ⭐ **Engines measure, this file judges.** Each step widget reports raw
/// facts (where the release landed, how long the needle stayed in the band)
/// and these functions turn them into the 0–1 accuracies that
/// `CraftQuality.roll` consumes. Keeping judgment out of the widgets is what
/// lets the same engine be forgiving at tier 1 and exacting at tier 5
/// without a line of widget code changing.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

/// Accuracy of landing [value] on [target] given a tolerance [window]:
/// 1.0 dead-on, falling linearly to 0 at the window's edge.
///
/// ⭐ Linear, not cliff-edged — §9b.9b's cumulative-accuracy ruling wants a
/// near-miss to be worth most of a hit, so quality degrades instead of
/// pass/failing.
double closeness(double value, double target, double window) {
  if (window <= 0) return value == target ? 1 : 0;
  final miss = (value - target).abs();
  return (1 - miss / window).clamp(0.0, 1.0);
}

/// Accuracy of a regulation step: the fraction of its duration spent inside
/// the band. Straight ratio — time out of band is simply time not earning.
double bandFraction(double timeInBand, double total) =>
    total <= 0 ? 0 : (timeInBand / total).clamp(0.0, 1.0);

/// Accuracy of a trace: how much of the path was covered, discounted by how
/// much of the drag wandered off it.
///
/// ⚠️ Coverage dominates on purpose (70/30): stopping halfway is a worse
/// carve than a wobbly full pass, and a scorer that punishes wobble harder
/// than absence teaches players to draw tiny perfect segments and quit.
double traceScore({required double coverage, required double fidelity}) =>
    (coverage.clamp(0.0, 1.0) * 0.7 + fidelity.clamp(0.0, 1.0) * 0.3);

/// The act's grade: the mean of its step accuracies.
///
/// 📝 Unweighted for now. If later tiers want the finishing step to matter
/// most, weights belong here — not in the widgets.
double gradeOf(List<double> stepScores) => stepScores.isEmpty
    ? 0
    : stepScores.reduce((a, b) => a + b) / stepScores.length;

/// The words the result panel uses for a grade. One writer, so the act
/// screen and any future toast can never disagree about what 0.83 is called.
String gradeLabel(double grade) {
  if (grade >= 0.85) return 'Flawless';
  if (grade >= 0.65) return 'Fine work';
  if (grade >= 0.40) return 'Clean';
  if (grade >= 0.15) return 'Rough work';
  return 'Botched';
}

/// Below this grade the attempt FAILS: §9b.9c's ruling — the craft aborts,
/// materials are returned, time and the moment are the only loss.
///
/// ⭐ Margin forgives here too: past the §9b.9d floor threshold (+5) an
/// attempt cannot fail at all — a veteran does not ruin oak.
double failThreshold(int margin) => margin >= 5 ? 0 : 0.15;

/// Uniform description of one step's live tuning, derived from the margin
/// (levers 4–6 computed, never authored — §9b.9c).
@immutable
class StepTuning {
  /// Multiplies every target window / band height. ≥ 1; bigger = easier.
  final double window;

  /// Divides sweep/oscillation speeds. ≥ 1; bigger = slower = easier.
  final double tempo;

  const StepTuning({required this.window, required this.tempo});

  /// The one derivation. [ease] is `CraftQuality.windowScale(margin)`.
  factory StepTuning.fromEase(double ease) =>
      StepTuning(window: ease, tempo: ease);
}

/// Shared oscillator: a value ping-ponging 0→1→0 with period [period]
/// seconds. Pure so tests can pin exact positions at exact times.
double pingPong(double tSeconds, double period) {
  if (period <= 0) return 0;
  final phase = (tSeconds / period) % 2.0;
  return phase <= 1.0 ? phase : 2.0 - phase;
}

/// Distance from point ([px],[py]) to the polyline [xs]/[ys] — the trace
/// engine's fidelity measure. O(n) per sample, n is tiny.
double distanceToPolyline(
  double px,
  double py,
  List<double> xs,
  List<double> ys,
) {
  assert(xs.length == ys.length && xs.length >= 2);
  var best = double.infinity;
  for (var i = 0; i < xs.length - 1; i++) {
    final d = _segmentDistance(px, py, xs[i], ys[i], xs[i + 1], ys[i + 1]);
    if (d < best) best = d;
  }
  return best;
}

double _segmentDistance(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final abx = bx - ax, aby = by - ay;
  final lenSq = abx * abx + aby * aby;
  var t = lenSq == 0 ? 0.0 : ((px - ax) * abx + (py - ay) * aby) / lenSq;
  t = t.clamp(0.0, 1.0);
  final cx = ax + abx * t, cy = ay + aby * t;
  return sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}
