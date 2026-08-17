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

  /// What one craft of [recipe] pays: **total ingredients × (4 + 2 × gate)**.
  ///
  /// ⭐ **Within a tier, the ratio IS the ingredient count** (designer ruling,
  /// 2026-08-17). A Quarterstaff eats three logs and a Wand eats two, so the
  /// staff must pay 3:2 — under the old flat `10 + 5·gate` both paid 15, which
  /// made the cheapest recipe in every tier the only rational way to grind and
  /// turned the ladder into a materials-efficiency puzzle instead of a record
  /// of work done. Counting inputs is the only term that tracks the work.
  ///
  /// ⭐ **The gate multiplier preserves the tier-2-out-earns ruling**: the
  /// per-ingredient rate climbs 6 → 24 from gate 1 to gate 10, so a tier-2
  /// craft still beats spamming tier-1 even though tier-1 recipes are cheaper
  /// per unit. ⚠️ Both terms are load-bearing — drop the count and the 3:2 dies,
  /// drop the gate and tier-1 spam wins again.
  ///
  /// 📝 Worked examples the ruling pinned: Oak Quarterstaff (3 logs, gate 1)
  /// → 3 × 6 = 18; Oak Wand and Oak Knot (2 logs, gate 1) → 2 × 6 = 12.
  static int xpForRecipe(RecipeDef recipe) =>
      recipe.inputs.fold<int>(0, (sum, i) => sum + i.count) *
      (4 + 2 * recipe.skillLevel);

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
