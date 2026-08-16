import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/recipe_book.dart';
import '../game/items/recipe_def.dart';
import '../game/skills.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import 'skills_screen.dart' show skillIcon;

/// The Workbench — every recipe, craftable-first, have/need honest.
///
/// ⭐ **A section, not a place** (ITEMS §9b.2): crafting works anywhere, so
/// this screen opens from the Inventory tab wherever the player stands.
/// Stations become a bonus layered on later, not a precondition.
///
/// 📝 **The craft button is a placeholder for the crafting act.** The planned
/// minigame (recipe gestures; execution quality → item quality) replaces the
/// button's instant result and feeds `GameState.craft(performance:)` — the
/// seam is already in place, so this screen changes locally when that lands.
class CraftScreen extends StatelessWidget {
  const CraftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);

    // Craftable now, then missing-materials, then skill-locked — the thing
    // you CAN do is never buried under the things you cannot.
    final recipes = RecipeBook.all.toList()
      ..sort((a, b) {
        int rank(RecipeDef r) {
          if (game.profile.skillLevel(r.skill.name) < r.skillLevel) return 2;
          for (final i in r.inputs) {
            if (game.profile.backpack.countOf(i.defId) < i.count) return 1;
          }
          return 0;
        }

        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        final bySkill = a.skill.index.compareTo(b.skill.index);
        if (bySkill != 0) return bySkill;
        return a.skillLevel.compareTo(b.skillLevel);
      });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Craft'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                'anywhere · stations later',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          children: [
            for (final r in recipes) _RecipeCard(game: game, recipe: r),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
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
                        color: locked ? AppColors.borderDim : AppColors.teal,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${Skills.displayName(recipe.skill.name)} '
                      '${recipe.skillLevel}',
                      style: TextStyle(
                        color: locked ? AppColors.textFaint : AppColors.teal,
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
                    ? Text(
                        'Locked — you are ${Skills.displayName(recipe.skill.name)} $skillLevel',
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11.5,
                        ),
                      )
                    : FilledButton(
                        onPressed: canCraft
                            ? () => _craft(context)
                            : null,
                        child: Text(
                          canCraft
                              ? 'Craft · +${Skills.xpForRecipe(recipe)} XP'
                              : 'Missing ${shortfalls.join(", ")}',
                        ),
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
