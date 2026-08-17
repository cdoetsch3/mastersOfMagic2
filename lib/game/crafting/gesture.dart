/// The gesture vocabulary: what a crafting (or gathering) act is made of.
///
/// ⭐ **Nine engines carry all 28 catalogued mechanics** (ITEMS §9b.9b). An
/// engine is an INPUT contract the UI implements once; a skin is the fantasy
/// painted over it (sanding wood vs polishing gems shares `rateDrag`). The
/// script stored on a recipe is levers 1–3 of the difficulty model
/// (§9b.9c): WHICH steps, HOW MANY, and their base size. Levers 4–6
/// (sensitivity, complexity scaling, tempo) are computed at craft time from
/// the margin — deliberately NOT stored here.
library;

/// The three feels (ITEMS §9b.9a). A good chain crosses categories.
enum GestureCategory { timing, precision, regulation }

/// The input contracts. ⚠️ Adding one here means building a UI engine — the
/// catalogue's other 19 mechanics are SKINS of these, not new entries.
enum GestureEngine {
  /// Hold, release at the right moment (chop, quench, channel, etch).
  releaseTiming(GestureCategory.timing),

  /// Act as a marker crosses a window (hammer, distil, weave).
  sweetSpot(GestureCategory.timing),

  /// Reproduce a shown sequence under time pressure (feed the flame).
  callResponse(GestureCategory.timing),

  /// Follow a path without leaving its bounds (carve, rune, knot, peel).
  trace(GestureCategory.precision),

  /// Line something up, commit once (gem set, facet, pour, tune, stamp).
  alignCommit(GestureCategory.precision),

  /// Choose WHERE — judgment of spacing, not motor skill (crystal seeding).
  placement(GestureCategory.precision),

  /// Keep a rate steady (saw, sand, wire, swirl, grind).
  rateDrag(GestureCategory.regulation),

  /// Keep a value inside a drifting band (bellows, simmer, glass-blowing).
  bandKeeper(GestureCategory.regulation),

  /// Continuous micro-correction against wobble (balancing).
  stabilizer(GestureCategory.regulation);

  final GestureCategory category;
  const GestureEngine(this.category);
}

/// One authored step of a crafting act.
///
/// ⭐ **[skin] drives copy and art only, never behaviour** — 'chop' and
/// 'quench' are both [GestureEngine.releaseTiming] to the input code. Keeping
/// behaviour out of the skin is what makes 28 fantasies cost 9 engines.
class GestureStep {
  final GestureEngine engine;

  /// The fantasy: 'chop', 'carve', 'stitch', 'grind', 'pour'…
  final String skin;

  /// Lever 3 — repetitions within the step (taps, passes, folds).
  final int reps;

  /// Lever 4's authored half — base pattern intricacy, 1 (a straight cut)
  /// to 5 (a twisty sigil). Margin scales the EFFECTIVE difficulty; this is
  /// the recipe's own contribution.
  final int complexity;

  const GestureStep(
    this.engine,
    this.skin, {
    this.reps = 1,
    this.complexity = 1,
  }) : assert(reps > 0),
       assert(complexity >= 1 && complexity <= 5);
}
