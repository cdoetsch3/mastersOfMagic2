import 'package:flutter/material.dart';

import '../game/crafting/craft_quality.dart';
import '../game/crafting/gesture.dart';
import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/recipe_def.dart';
import '../game/skills.dart';
import '../ui/app_theme.dart';
import '../ui/crafting/precision_steps.dart';
import '../ui/crafting/regulation_steps.dart';
import '../ui/crafting/scoring.dart';
import '../ui/crafting/timing_steps.dart';
import '../ui/item_display.dart';

/// The crafting act (ITEMS §9b.9): the recipe's gesture script, played.
///
/// ⭐ **The screen orchestrates; the engines measure; scoring judges.** Each
/// step widget runs its engine and reports one 0–1 accuracy; the mean is the
/// grade; the grade feeds `GameState.craft(performance:)` — which today
/// mints a plain item (quality lands with quality-affects-stats), so the
/// grade's visible payoff is the label and the fail line. The seam is
/// already the real one.
///
/// ⚠️ **Failure aborts with materials returned** (§9b.9c): craft() is simply
/// never called below the fail threshold, so nothing was consumed. From
/// margin +5 the threshold is zero — a veteran cannot ruin oak.
class CraftingActScreen extends StatefulWidget {
  final RecipeDef recipe;

  const CraftingActScreen({super.key, required this.recipe});

  @override
  State<CraftingActScreen> createState() => _CraftingActScreenState();
}

class _CraftingActScreenState extends State<CraftingActScreen> {
  final List<double> _scores = [];
  CraftOutcome? _outcome;
  double? _grade;
  var _failed = false;

  int get _stepIndex => _scores.length;
  bool get _finished => _grade != null;

  /// One margin, one tuning — levers 4–6 computed here and nowhere else.
  late final int _margin = CraftQuality.margin(
    skillLevel: GameStateScope.read(
      context,
    ).profile.skillLevel(widget.recipe.skill.name),
    recipeGate: widget.recipe.skillLevel,
  );
  late final StepTuning _tuning = StepTuning.fromEase(
    CraftQuality.windowScale(_margin),
  );

  Future<void> _onStepDone(double accuracy) async {
    setState(() => _scores.add(accuracy));
    if (_scores.length < widget.recipe.steps.length) return;

    final grade = gradeOf(_scores);
    if (grade < failThreshold(_margin)) {
      // The attempt fails: nothing was consumed, nothing is paid.
      setState(() {
        _grade = grade;
        _failed = true;
      });
      return;
    }
    final game = GameStateScope.read(context);
    final outcome = await game.craft(widget.recipe, performance: grade);
    if (!mounted) return;
    setState(() {
      _grade = grade;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(widget.recipe.outputId);
    final name = def == null
        ? widget.recipe.outputId
        : ItemCatalogue.displayName(def);
    final steps = widget.recipe.steps;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: Text('Crafting — $name'),
      ),
      body: SafeArea(
        child: _finished
            ? _Result(
                recipe: widget.recipe,
                grade: _grade!,
                failed: _failed,
                outcome: _outcome,
              )
            : Column(
                children: [
                  const SizedBox(height: 10),
                  _StepDots(count: steps.length, done: _stepIndex),
                  const SizedBox(height: 4),
                  Text(
                    _skinTitle(steps[_stepIndex].skin),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Expanded(
                    // ⚠️ Keyed by index so each step gets a FRESH engine —
                    // reusing state across steps of the same engine type is
                    // how a second chop would inherit the first one's meter.
                    child: KeyedSubtree(
                      key: ValueKey(_stepIndex),
                      child: _engineFor(steps[_stepIndex]),
                    ),
                  ),
                  if (_scores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        _scores.map(gradeLabel).join('  ·  '),
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _engineFor(GestureStep step) => switch (step.engine) {
    GestureEngine.releaseTiming => ReleaseTimingStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    GestureEngine.sweetSpot => SweetSpotStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    GestureEngine.trace => TraceStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    GestureEngine.rateDrag => RateDragStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    GestureEngine.bandKeeper => BandKeeperStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    GestureEngine.alignCommit => AlignCommitStep(
      step: step,
      tuning: _tuning,
      onDone: _onStepDone,
    ),
    // 📝 The three engines no Q1 recipe uses yet. Falling back to an
    // instant pass keeps a future recipe playable before its engine ships —
    // and the fallback is loud in the code, silent in the hand.
    GestureEngine.callResponse ||
    GestureEngine.placement ||
    GestureEngine.stabilizer => _UnbuiltEngine(onDone: _onStepDone),
  };

  static String _skinTitle(String skin) => switch (skin) {
    'chop' => 'CHOP',
    'carve' => 'CARVE',
    'sand' => 'SAND',
    'thread' => 'THREAD',
    'stitch' => 'STITCH',
    'cut' => 'CUT',
    'knot' => 'KNOT',
    'pour' => 'POUR',
    'grind' => 'GRIND',
    'swirl' => 'SWIRL',
    'simmer' => 'SIMMER',
    'pull' => 'PULL',
    _ => skin.toUpperCase(),
  };
}

class _UnbuiltEngine extends StatefulWidget {
  final ValueChanged<double> onDone;
  const _UnbuiltEngine({required this.onDone});

  @override
  State<_UnbuiltEngine> createState() => _UnbuiltEngineState();
}

class _UnbuiltEngineState extends State<_UnbuiltEngine> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onDone(0.75),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _StepDots extends StatelessWidget {
  final int count;
  final int done;
  const _StepDots({required this.count, required this.done});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < done ? AppColors.gold : AppColors.bg,
            border: Border.all(
              color: i == done ? AppColors.gold : AppColors.borderDim,
            ),
          ),
        ),
    ],
  );
}

class _Result extends StatelessWidget {
  final RecipeDef recipe;
  final double grade;
  final bool failed;
  final CraftOutcome? outcome;

  const _Result({
    required this.recipe,
    required this.grade,
    required this.failed,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(recipe.outputId);
    final name = def == null
        ? recipe.outputId
        : ItemCatalogue.displayName(def);
    final made = outcome?.succeeded == true;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            failed ? 'The attempt fails' : gradeLabel(grade),
            style: TextStyle(
              color: failed ? AppColors.ember : AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grade ${(grade * 100).round()}%',
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (failed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                // ⚠️ Say the safety rule out loud — a player who thinks a
                // failed craft ate their logs will never craft again.
                'The piece comes apart on the bench. Your materials are '
                'unspent — only the attempt is lost.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            )
          else if (made) ...[
            InkWell(
              onTap: def == null
                  ? null
                  : () => showItemDialog(context, def: def),
              child: Text(
                name,
                style: TextStyle(
                  color: def == null
                      ? AppColors.text
                      : rarityColour(def.rarity),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              outcome!.leveledTo != null
                  ? '${Skills.displayName(outcome!.skillKey!)} is now '
                        'level ${outcome!.leveledTo}!'
                  : '+${outcome!.xp} ${Skills.displayName(outcome!.skillKey!)} '
                        'XP',
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            ),
          ] else
            Text(
              // The craft itself refused (materials vanished mid-act, etc.).
              outcome?.refusal ?? 'Nothing was made.',
              style: const TextStyle(color: AppColors.ember, fontSize: 13),
            ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to the bench'),
          ),
        ],
      ),
    );
  }
}
