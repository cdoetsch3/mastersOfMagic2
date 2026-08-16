/// The nine skills: what they are, how their XP climbs, and what a level
/// unlocks (ITEMS §6a — structure settled there, numbers first pinned here).
///
/// ⭐ **Skill levels live OUTSIDE character level.** A level-40 mage with
/// Woodcarving 3 whittles like a beginner; the two ladders never trade XP.
///
/// ⚠️ **The UI never says where a material grows** (ruling, 2026-08-10). The
/// world teaches that organically; a second source of truth here would rot
/// the moment a zone's yields moved. Unlock lists name items and levels only.
library;

import 'items/item_def.dart';
import 'items/recipe_book.dart';
import 'items/recipe_def.dart';

/// The three taking-from-the-world skills (ITEMS §6a). Kept apart from
/// [CraftSkill] because materials name the skill that CONSUMES them — mixing
/// the enums would let a recipe claim to be made "with Felling".
enum GatherSkill { felling, foraging, mining }

abstract final class Skills {
  /// Stable ledger keys, one per skill — [CraftSkill.name] and
  /// [GatherSkill.name] never collide, and saves key on these strings.
  static List<String> get allKeys => [
    for (final s in CraftSkill.values) s.name,
    for (final s in GatherSkill.values) s.name,
  ];

  static String displayName(String key) => switch (key) {
    'woodcarving' => 'Woodcarving',
    'tailoring' => 'Tailoring',
    'metalworking' => 'Metalworking',
    'potionsAndAlchemy' => 'Potions & Alchemy',
    'enchanting' => 'Enchanting',
    'jewelry' => 'Jewelry',
    'felling' => 'Felling',
    'foraging' => 'Foraging',
    'mining' => 'Mining',
    _ => key,
  };

  /// One line of identity for the ledger row — what the skill DOES, never
  /// where its materials come from (see the library ⚠️).
  static String blurb(String key) => switch (key) {
    'woodcarving' => 'Staves, wands and knots',
    'tailoring' => 'Robes, hoods and belts',
    'metalworking' => 'Ingots and fittings for other makers',
    'potionsAndAlchemy' => 'Draughts and tonics',
    'enchanting' => 'The element axis, laid onto gear',
    'jewelry' => 'Pendants and rings',
    'felling' => 'Wood, taken standing',
    'foraging' => 'Fibres, herbs and hides',
    'mining' => 'Ore and gems',
    _ => '',
  };

  static bool isGathering(String key) =>
      GatherSkill.values.any((s) => s.name == key);

  // ---- the ladder --------------------------------------------------------

  /// XP to go from [level] to the next. 📝 **Tunable, deliberately gentle**:
  /// linear like the character curve (100 + 50·(n−1)) but a quarter the
  /// height, so the first session of crafting visibly moves the bar and the
  /// tier-2 gate (~10) is a real climb, not a wall. ~2 dozen tier-1 crafts
  /// reach it.
  static int xpToNext(int level) => 20 + 5 * (level - 1);

  static int levelForXp(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (remaining >= xpToNext(level)) {
      remaining -= xpToNext(level);
      level++;
    }
    return level;
  }

  static int xpIntoLevel(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (remaining >= xpToNext(level)) {
      remaining -= xpToNext(level);
      level++;
    }
    return remaining;
  }

  /// What one craft of [recipe] pays. ⭐ Scales with the recipe's own gate, so
  /// tier-2 work out-earns spamming tier-1 — the same shape the character
  /// curve uses for opponent level.
  static int xpForRecipe(RecipeDef recipe) => 10 + 5 * recipe.skillLevel;

  // ---- what a level means (the Ledger's three views) ---------------------

  /// Everything [skill] can ever make, unlock order then name — the
  /// "view all" sheet, scrollable past level 40 without curation.
  static List<RecipeDef> allRecipesFor(CraftSkill skill) =>
      RecipeBook.forSkill(skill)
        ..sort((a, b) {
          final byLevel = a.skillLevel.compareTo(b.skillLevel);
          return byLevel != 0 ? byLevel : a.outputId.compareTo(b.outputId);
        });

  /// The last few things [level] has already opened, newest first.
  ///
  /// ⭐ **Capped, because "unlocked" is unbounded** — at skill 40 the full
  /// list is a wall, and the ledger row only owes the player what is fresh.
  /// The complete history lives in [allRecipesFor]'s sheet.
  static List<RecipeDef> recentlyUnlocked(
    CraftSkill skill,
    int level, {
    int cap = 5,
  }) {
    final open = allRecipesFor(
      skill,
    ).where((r) => r.skillLevel <= level).toList();
    return open.reversed.take(cap).toList();
  }

  /// The next tier: every recipe at the LOWEST yet-unreached gate, plus that
  /// gate's level. Null when the skill has nothing further authored.
  static ({int level, List<RecipeDef> recipes})? nextUnlock(
    CraftSkill skill,
    int level,
  ) {
    final locked = allRecipesFor(
      skill,
    ).where((r) => r.skillLevel > level).toList();
    if (locked.isEmpty) return null;
    final gate = locked.first.skillLevel;
    return (
      level: gate,
      recipes: locked.where((r) => r.skillLevel == gate).toList(),
    );
  }
}
