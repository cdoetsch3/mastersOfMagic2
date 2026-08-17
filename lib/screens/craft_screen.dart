import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/recipe_book.dart';
import '../game/items/recipe_def.dart';
import '../game/skills.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import 'crafting_act_screen.dart';
import 'skills_screen.dart' show skillIcon;

/// How the Workbench orders its shelf.
///
/// ⭐ **Two orders, because the list answers two different questions.**
/// "What can I make right now?" wants craftability; "what am I working
/// toward?" wants the gate ladder. One order cannot serve both, and the
/// player who asks the second question while looking at the first concludes
/// the content does not exist (see the class ⚠️).
enum CraftSort {
  craftability('Craftable first'),
  skillLevel('By skill level');

  final String label;
  const CraftSort(this.label);
}

/// The Workbench — every recipe, craftable-first, have/need honest.
///
/// ⭐ **A section, not a place** (ITEMS §9b.2): crafting works anywhere, so
/// this screen opens from the Inventory tab wherever the player stands.
/// Stations become a bonus layered on later, not a precondition.
///
/// ⭐ **Craft opens the act** (crafting_act_screen.dart) when the recipe has
/// a gesture script; **Quick craft** stays as the instant path — the bulk
/// lane §9b.9b promised, so twenty draughts is never twenty minigames.
/// 📝 Quick craft will cap quality at Standard once quality affects stats.
///
/// ⚠️ **A hard craftability sort hid the game's own content.** A playtester
/// looking for a belt found none and concluded belts were unimplemented —
/// the Fawnhide Belt was real, locked, and therefore last. Hence the sort and
/// filter band: the fix is not to un-bury one recipe but to let the player
/// ask the question whose answer it is.
///
/// ⚠️ **Every toggle defaults to showing MORE, never less.** Hide-locked and
/// hide-missing both start OFF, so a fresh Workbench still lists everything —
/// a filter that hides content by default reproduces the exact bug above.
/// State is ephemeral by ruling: a stale saved filter would do the same.
class CraftScreen extends StatefulWidget {
  const CraftScreen({super.key});

  @override
  State<CraftScreen> createState() => _CraftScreenState();
}

class _CraftScreenState extends State<CraftScreen> {
  var _sort = CraftSort.craftability;

  /// Null is "All" — deliberately not a sentinel enum member, so the chip row
  /// and the predicate cannot drift apart about what "no filter" means.
  CraftSkill? _skill;

  var _hideLocked = false;
  var _hideMissing = false;

  /// ⭐ **Derived, never hardcoded.** Only skills that actually own a recipe
  /// get a chip, in [CraftSkill] declaration order — so authoring the first
  /// Metalworking recipe grows the row on its own, and a skill whose recipes
  /// are all deleted stops offering a chip that could only ever show nothing.
  static final List<CraftSkill> _skillsWithRecipes = [
    for (final s in CraftSkill.values)
      if (RecipeBook.all.any((r) => r.skill == s)) s,
  ];

  bool _isLocked(GameState game, RecipeDef r) =>
      game.profile.skillLevel(r.skill.name) < r.skillLevel;

  bool _isMissing(GameState game, RecipeDef r) {
    for (final i in r.inputs) {
      if (game.profile.backpack.countOf(i.defId) < i.count) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);

    final recipes = RecipeBook.all
        .where((r) => _skill == null || r.skill == _skill)
        .where((r) => !_hideLocked || !_isLocked(game, r))
        .where((r) => !_hideMissing || !_isMissing(game, r))
        .toList();

    // ⚠️ Both orders tie-break identically (skill, then gate, then id) so the
    // shelf is stable: re-sorting and sorting back must not shuffle rows the
    // player had just learned the position of.
    int tieBreak(RecipeDef a, RecipeDef b) {
      final bySkill = a.skill.index.compareTo(b.skill.index);
      if (bySkill != 0) return bySkill;
      final byGate = a.skillLevel.compareTo(b.skillLevel);
      if (byGate != 0) return byGate;
      return a.id.compareTo(b.id);
    }

    recipes.sort(switch (_sort) {
      // Craftable now, then missing-materials, then skill-locked — the thing
      // you CAN do is never buried under the things you cannot.
      CraftSort.craftability => (a, b) {
        int rank(RecipeDef r) => _isLocked(game, r)
            ? 2
            : _isMissing(game, r)
            ? 1
            : 0;

        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : tieBreak(a, b);
      },
      // ⭐ Gate ascending across ALL skills — this is the "what's next for me"
      // ladder, so a Tailoring 4 belt must be able to sit above a
      // Woodcarving 10 staff. Grouping by skill first would rebuild the very
      // burial this sort exists to undo.
      CraftSort.skillLevel => (a, b) {
        final byGate = a.skillLevel.compareTo(b.skillLevel);
        return byGate != 0 ? byGate : tieBreak(a, b);
      },
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Craft'),
            Text(
              'anywhere · stations later',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<CraftSort>(
            initialValue: _sort,
            tooltip: 'Sort recipes',
            color: AppColors.panel,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in CraftSort.values)
                PopupMenuItem(
                  value: s,
                  child: Text(
                    s.label,
                    style: const TextStyle(color: AppColors.text),
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16, color: AppColors.teal),
                  const SizedBox(width: 5),
                  Text(
                    _sort.label,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterBand(
              skills: _skillsWithRecipes,
              selected: _skill,
              hideLocked: _hideLocked,
              hideMissing: _hideMissing,
              onSkill: (s) => setState(() => _skill = s),
              onHideLocked: (v) => setState(() => _hideLocked = v),
              onHideMissing: (v) => setState(() => _hideMissing = v),
            ),
            Expanded(
              child: recipes.isEmpty
                  // ⚠️ An empty list must confess it is empty BECAUSE of the
                  // filters. Silence here is the original bug wearing a
                  // different hat: the player reads "no recipes" as "no
                  // content" rather than "no matches".
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No recipes match these filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                      children: [
                        for (final r in recipes)
                          _RecipeCard(game: game, recipe: r),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The skill chips and the two hide-toggles, above the shelf.
class _FilterBand extends StatelessWidget {
  final List<CraftSkill> skills;
  final CraftSkill? selected;
  final bool hideLocked;
  final bool hideMissing;
  final ValueChanged<CraftSkill?> onSkill;
  final ValueChanged<bool> onHideLocked;
  final ValueChanged<bool> onHideMissing;

  const _FilterBand({
    required this.skills,
    required this.selected,
    required this.hideLocked,
    required this.hideMissing,
    required this.onSkill,
    required this.onHideLocked,
    required this.onHideMissing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Chip(
                label: 'All',
                on: selected == null,
                onTap: () => onSkill(null),
              ),
              for (final s in skills)
                _Chip(
                  label: Skills.displayName(s.name),
                  icon: skillIcon(s.name),
                  on: selected == s,
                  onTap: () => onSkill(s),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Chip(
                label: 'Hide locked',
                on: hideLocked,
                onTap: () => onHideLocked(!hideLocked),
              ),
              _Chip(
                label: 'Hide missing materials',
                on: hideMissing,
                onTap: () => onHideMissing(!hideMissing),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ⚠️ Hand-rolled rather than [FilterChip]: Material's chip carries its own
/// light-theme surface and ripple, and every other pill on this screen is the
/// bordered teal-on-panel shape. A themed FilterChip cost more lines than
/// this does.
class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool on;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.bg : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? AppColors.teal : Colors.transparent,
          border: Border.all(color: on ? AppColors.teal : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(color: fg, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final GameState game;
  final RecipeDef recipe;

  const _RecipeCard({required this.game, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(recipe.outputId);
    final name = def == null
        ? recipe.outputId
        : ItemCatalogue.displayName(def);
    final skillLevel = game.profile.skillLevel(recipe.skill.name);
    final locked = skillLevel < recipe.skillLevel;
    final shortfalls = <String>[];
    var haveAll = true;
    for (final i in recipe.inputs) {
      if (game.profile.backpack.countOf(i.defId) < i.count) {
        haveAll = false;
        final inputDef = ItemCatalogue.tryById(i.defId);
        shortfalls.add(
          inputDef == null ? i.defId : ItemCatalogue.displayName(inputDef),
        );
      }
    }
    final canCraft = !locked && haveAll;
    // One string, two places — the chip and the footer must never disagree
    // about which level opens this row.
    final gateLabel =
        '${Skills.displayName(recipe.skill.name)} ${recipe.skillLevel}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        // ⚠️ 0.75, not the old 0.55 — a locked row is a goal, and a goal you
        // can barely read is the bug this screen was fixed for.
        opacity: locked ? 0.75 : 1,
        child: GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    skillIcon(recipe.skill.name),
                    size: 18,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      // ⭐ The standardized item dialog, same as everywhere.
                      onTap: def == null
                          ? null
                          : () => showItemDialog(context, def: def),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: def == null
                              ? AppColors.text
                              : rarityColour(def.rarity),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: locked
                            ? AppColors.gold.withValues(alpha: 0.6)
                            : AppColors.teal,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    // ⭐ Locked reads as a promise, not a shrug. 'Tailoring 4'
                    // alone is ambiguous on a dimmed row — is that what it
                    // needs, or what I have? Naming the verb ("Unlocks at")
                    // puts the requirement first and makes the row a goal.
                    child: Text(
                      locked
                          ? 'Unlocks at $gateLabel'
                          : gateLabel,
                      style: TextStyle(
                        color: locked ? AppColors.gold : AppColors.teal,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final i in recipe.inputs) _NeedRow(game: game, input: i),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: locked
                    // ⚠️ Requirement first, current level second. The old copy
                    // ('Locked — you are Tailoring 2') told the player only
                    // what they already knew and buried the number they
                    // needed, which is how a real recipe read as absent.
                    ? Text(
                        'Unlocks at $gateLabel · you are '
                        '${Skills.displayName(recipe.skill.name)} $skillLevel',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canCraft && recipe.steps.isNotEmpty)
                            TextButton(
                              onPressed: () => _craft(context),
                              child: const Text('Quick craft'),
                            ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: canCraft
                                ? () => recipe.steps.isEmpty
                                      ? _craft(context)
                                      : Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => CraftingActScreen(
                                              recipe: recipe,
                                            ),
                                          ),
                                        )
                                : null,
                            child: Text(
                              canCraft
                                  ? 'Craft · +${Skills.xpForRecipe(recipe)} XP'
                                  : 'Missing ${shortfalls.join(", ")}',
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _craft(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await game.craft(recipe);
    // ⚠️ Both halves speak: a silent success reads as a dead button, and a
    // silent refusal reads as a broken one.
    if (!outcome.succeeded) {
      messenger.showSnackBar(SnackBar(content: Text(outcome.refusal!)));
      return;
    }
    final def = ItemCatalogue.tryById(outcome.defId!);
    final name = def == null
        ? outcome.defId!
        : ItemCatalogue.displayName(def);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome.leveledTo != null
              ? 'Crafted $name — ${Skills.displayName(outcome.skillKey!)} '
                    'is now level ${outcome.leveledTo}!'
              : 'Crafted $name · +${outcome.xp} '
                    '${Skills.displayName(outcome.skillKey!)} XP',
        ),
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  final GameState game;
  final RecipeInput input;

  const _NeedRow({required this.game, required this.input});

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(input.defId);
    final have = game.profile.backpack.countOf(input.defId);
    final enough = have >= input.count;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              def == null ? input.defId : ItemCatalogue.displayName(def),
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ),
          Text(
            '$have / ${input.count}${enough ? ' ✓' : ''}',
            style: TextStyle(
              color: enough ? AppColors.teal : AppColors.ember,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
