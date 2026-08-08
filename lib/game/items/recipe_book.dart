/// Every recipe in the game, one list per zone-or-band file, same shape as
/// [ItemCatalogue].
///
/// ⚠️ **Every recipe catalogue must be listed in [all].** An unlisted one
/// compiles fine and simply never resolves — the exact silent failure the
/// export test's referential check exists to catch.
library;

import 'item_def.dart';
import 'recipe_def.dart';

abstract final class RecipeBook {
  /// 📝 Empty until the Primal recipe set is ruled on (ITEMS §9b) — the four
  /// open rulings are Q1 ore, metal-free Oak/Birch, drop-only jewelry, and
  /// the tier-2 material names. The shape ships first so the export contract
  /// and the wiki can build against it.
  static const List<RecipeDef> all = <RecipeDef>[];

  static final Map<String, RecipeDef> _byId = {for (final r in all) r.id: r};

  /// Null when nothing owns [id] — a bug, not a missing recipe.
  static RecipeDef? tryById(String id) => _byId[id];

  /// The recipes a given skill can make, in [all] order.
  static List<RecipeDef> forSkill(CraftSkill skill) =>
      [for (final r in all) if (r.skill == skill) r];
}
