/// Quality resolution (ITEMS §9b.9c/d): margin in, ceiling and floor out,
/// and a weighted roll between them.
///
/// ⭐ **Every number in here is a 📝 placeholder** awaiting the tuning pass
/// that lands when quality affects stats. The SHAPE is the ruling and the
/// tests pin the shape: the grade is a ceiling never a guarantee, the floor
/// rides the margin, and at-level perfection can still roll Rough.
///
/// ⚠️ Client-local. Crafting never touches the lockstep duel engine, so an
/// unseeded Random here is safe (tests inject their own).
library;

import 'dart:math';

import '../items/item_def.dart';

abstract final class CraftQuality {
  /// The one axis (§9b.9c): level past the gate, plus bench, plus tool.
  static int margin({
    required int skillLevel,
    required int recipeGate,
    int benchBonus = 0,
    int toolBonus = 0,
  }) => skillLevel - recipeGate + benchBonus + toolBonus;

  /// Lever 6 as a scalar: >1 means wider timing windows / slower tempo.
  /// The gesture engines multiply their windows by this.
  static double windowScale(int margin) =>
      (1 + 0.05 * margin).clamp(1.0, 1.8);

  /// The best quality this execution can yield (§9b.9d step 2).
  ///
  /// ⚠️ The caller clamps by the SKILL ceiling too — the attempt's true cap
  /// is the lower of hands and level.
  static Quality executionCeiling(double grade) {
    if (grade >= 0.85) return Quality.master;
    if (grade >= 0.65) return Quality.ornate;
    if (grade >= 0.40) return Quality.standard;
    return Quality.rough;
  }

  /// The worst quality this execution can yield (§9b.9d floor ruling).
  ///
  /// ⭐ **Scales with MARGIN, not grade alone**: at-level (margin < 5) even a
  /// perfect grade can roll Rough — the material fights back at the edge of
  /// your ability. From margin ≥ 5 a nailed craft escapes Rough; deeper
  /// margin keeps lifting the floor.
  static Quality floor(double grade, int margin) {
    if (grade < 0.85) return Quality.rough;
    if (margin >= 15) return Quality.ornate;
    if (margin >= 5) return Quality.standard;
    return Quality.rough;
  }

  /// The full §9b.9d pipeline: weighted roll in [floor..ceiling].
  ///
  /// [skillCeiling] is the level-derived cap for the recipe's tier (null =
  /// uncapped). ⭐ Weights lean low and are tilted upward by margin — "better
  /// odds at higher skill" (§9b.4) lives here, as weight-shaping.
  static Quality roll({
    required double grade,
    required int margin,
    required Random rng,
    Quality? skillCeiling,
  }) {
    var ceiling = executionCeiling(grade);
    if (skillCeiling != null && skillCeiling.index < ceiling.index) {
      ceiling = skillCeiling;
    }
    var lo = floor(grade, margin);
    if (lo.index > ceiling.index) lo = ceiling;

    // Base weights fall off fast above the floor; margin flattens the
    // fall-off so deep margin makes the top of the band likelier.
    final falloff = (3.0 - 0.1 * margin).clamp(1.4, 3.0);
    final options = [
      for (var q = lo.index; q <= ceiling.index; q++) Quality.values[q],
    ];
    final weights = [
      for (var i = 0; i < options.length; i++) pow(falloff, -i).toDouble(),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var pick = rng.nextDouble() * total;
    for (var i = 0; i < options.length; i++) {
      pick -= weights[i];
      // weights[0] is the heaviest and belongs to the BOTTOM of the band —
      // the roll leans low, and margin is what flattens the lean.
      if (pick <= 0) return options[i];
    }
    return options.first;
  }
}
