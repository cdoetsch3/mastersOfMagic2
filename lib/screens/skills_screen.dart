import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/recipe_def.dart';
import '../game/skills.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';

/// The Ledger — every skill as a row: collapsed is a glance (icon, level,
/// bar), expanded is the story (what just opened, what opens next).
///
/// ⭐ **Three views by scale** (ruling, 2026-08-10): the row shows only what
/// is FRESH — "Recently unlocked" caps at five, because at skill 40 the full
/// unlocked list is a wall; "At level N" is the next gate only; and the
/// complete catalogue lives behind "View everything", a scrollable sheet
/// that needs no curation.
///
/// ⚠️ **Nothing here says where a material grows.** The world teaches that
/// organically; this screen names items and levels, full stop.
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  /// The one expanded row. Single-open keeps nine rows readable.
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Skills'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          children: [
            // ⭐ **Gathering leads** (designer, 2026-08-16). It is where the
            // loop actually starts — you cannot process what you have not
            // pulled out of the ground — and it is the shorter group, so the
            // three rows a new player can already earn XP in sit above the
            // fold instead of below six crafts they have no materials for.
            const SectionLabel('Gathering'),
            for (final s in GatherSkill.values)
              _SkillRow(
                game: game,
                skillKey: s.name,
                craftSkill: null,
                expanded: _expanded == s.name,
                onTap: () => setState(
                  () => _expanded = _expanded == s.name ? null : s.name,
                ),
              ),
            const SizedBox(height: 12),
            // 📝 Order WITHIN each group is the enum's own declaration order,
            // untouched by the swap — that ordering is content, not layout.
            const SectionLabel('Processing'),
            for (final s in CraftSkill.values)
              _SkillRow(
                game: game,
                skillKey: s.name,
                craftSkill: s,
                expanded: _expanded == s.name,
                onTap: () => setState(
                  () => _expanded = _expanded == s.name ? null : s.name,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData skillIcon(String key) => switch (key) {
  'woodcarving' => Icons.carpenter,
  'tailoring' => Icons.checkroom,
  'metalworking' => Icons.hardware,
  'potionsAndAlchemy' => Icons.science,
  'enchanting' => Icons.auto_awesome,
  'jewelry' => Icons.diamond_outlined,
  'felling' => Icons.forest,
  'foraging' => Icons.grass,
  'mining' => Icons.terrain,
  _ => Icons.build,
};

class _SkillRow extends StatelessWidget {
  final GameState game;
  final String skillKey;

  /// Null for gathering skills, which have no recipes to list.
  final CraftSkill? craftSkill;
  final bool expanded;
  final VoidCallback onTap;

  const _SkillRow({
    required this.game,
    required this.skillKey,
    required this.craftSkill,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final xp = game.profile.skillXp[skillKey] ?? 0;
    final level = Skills.levelForXp(xp);
    final into = Skills.xpIntoLevel(xp);
    final toNext = Skills.xpToNext(level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(skillIcon(skillKey), color: AppColors.teal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Skills.displayName(skillKey),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Skills.blurb(skillKey),
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Lv $level',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: toNext == 0 ? 1 : into / toNext,
                minHeight: 5,
                backgroundColor: AppColors.bg,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$into / $toNext XP',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 10),
            ),
            if (expanded) ...[
              const Divider(color: AppColors.borderDim, height: 18),
              if (craftSkill != null)
                _CraftDetail(game: game, skill: craftSkill!, level: level)
              else
                const Text(
                  // 📝 Gathering XP arrives with nodes; the ledger row exists
                  // first so the skill has somewhere to be seen from day one.
                  'Earned in the field. Gathering spots are found on '
                  'adventures.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CraftDetail extends StatelessWidget {
  final GameState game;
  final CraftSkill skill;
  final int level;

  const _CraftDetail({
    required this.game,
    required this.skill,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final recent = Skills.recentlyUnlocked(skill, level);
    final next = Skills.nextUnlock(skill, level);
    final all = Skills.allRecipesFor(skill);

    if (all.isEmpty) {
      return const Text(
        'Recipes for this craft are still being written.',
        style: TextStyle(color: AppColors.textDim, fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recent.isNotEmpty) ...[
          const _SmallLabel('Recently unlocked'),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [for (final r in recent) _ItemChip(recipe: r)],
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: 8),
          _SmallLabel('At level ${next.level}'),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final r in next.recipes) _ItemChip(recipe: r, locked: true),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showAll(context),
            child: Text('View everything (${all.length}) ›'),
          ),
        ),
      ],
    );
  }

  /// The full catalogue: every recipe this skill will ever hold, in unlock
  /// order, scrollable — the view that stays honest at level 40.
  void _showAll(BuildContext context) {
    final all = Skills.allRecipesFor(skill);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            Text(
              '${Skills.displayName(skill.name)} — everything',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (final r in all)
              _AllRow(recipe: r, unlocked: r.skillLevel <= level),
          ],
        ),
      ),
    );
  }
}

class _AllRow extends StatelessWidget {
  final RecipeDef recipe;
  final bool unlocked;

  const _AllRow({required this.recipe, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(recipe.outputId);
    final name = def == null
        ? recipe.outputId
        : ItemCatalogue.displayName(def);
    final colour = !unlocked
        ? AppColors.textFaint
        : def == null
        ? AppColors.text
        : rarityColour(def.rarity);
    return InkWell(
      onTap: def == null ? null : () => showItemDialog(context, def: def),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.check : Icons.lock_outline,
              size: 14,
              color: unlocked ? AppColors.teal : AppColors.textFaint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: colour, fontSize: 13),
              ),
            ),
            Text(
              'Lv ${recipe.skillLevel}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable item name. 📝 Becomes the item's sprite when icons exist —
/// the tap already opens the standardized dialog either way.
class _ItemChip extends StatelessWidget {
  final RecipeDef recipe;
  final bool locked;

  const _ItemChip({required this.recipe, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(recipe.outputId);
    final name = def == null
        ? recipe.outputId
        : ItemCatalogue.displayName(def);
    final colour = locked
        ? AppColors.textFaint
        : def == null
        ? AppColors.textDim
        : rarityColour(def.rarity);
    return InkWell(
      onTap: def == null ? null : () => showItemDialog(context, def: def),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(
            color: locked ? AppColors.borderDim : colour,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(name, style: TextStyle(color: colour, fontSize: 11)),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final String text;
  const _SmallLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 9.5,
        letterSpacing: 1.2,
      ),
    ),
  );
}
