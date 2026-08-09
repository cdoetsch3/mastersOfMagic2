/// Every recipe in the game, one list per zone-or-band file, same shape as
/// [ItemCatalogue].
///
/// ⚠️ **Every recipe catalogue must be listed in [all].** An unlisted one
/// compiles fine and simply never resolves — the exact silent failure the
/// export test's referential check exists to catch.
library;

import 'item_def.dart';
import 'recipe_def.dart';
import 'recipes/primal_recipes.dart';

abstract final class RecipeBook {
  static const List<RecipeDef> all = <RecipeDef>[...PrimalRecipes.all];

  static final Map<String, RecipeDef> _byId = {for (final r in all) r.id: r};

  /// Null when nothing owns [id] — a bug, not a missing recipe.
  static RecipeDef? tryById(String id) => _byId[id];

  /// The recipes a given skill can make, in [all] order.
  static List<RecipeDef> forSkill(CraftSkill skill) =>
      [for (final r in all) if (r.skill == skill) r];
}
