/// What a player can make, from what, with which skill.
///
/// ⭐ **A recipe is data, not code** — the same definitions-in-code model as
/// [ItemDef] (ITEMS §10.1): the Dart const is canonical, instances of the
/// *output* live in the DB, and the wiki reads the export, never a hand-typed
/// table.
///
/// ⚠️ **A recipe names ids, not defs.** Holding an `ItemDef` here would let a
/// recipe compile against an item no catalogue lists; ids force resolution
/// through [ItemCatalogue], and `content_export_test` fails on any id nothing
/// owns.
library;

import 'package:flutter/foundation.dart';

import '../crafting/gesture.dart';
import 'item_def.dart';

/// One input line: [count] of the fungible material [defId].
///
/// ⚠️ **Inputs are always fungible items** (materials, motes, components).
/// A recipe that consumed a non-fungible — a specific instance, with a
/// quality roll on it — would need instance selection UI and provenance
/// tracking that nothing else in crafting has. Salvage is the verb that eats
/// instances; crafting eats stacks.
@immutable
class RecipeInput {
  final String defId;
  final int count;

  const RecipeInput(this.defId, this.count);
}

/// A craftable.
///
/// The quality roll (Rough → Standard → Ornate → Master, ITEMS §9b.4) is
/// ⭐ **not on the recipe** — it belongs to the crafting *act* (attended vs
/// passive, at a station vs not, §9b.4b). Every equipment recipe rolls it;
/// no consumable does. Nothing here needs to say so.
@immutable
class RecipeDef {
  final String id;

  /// What comes out, and how many. [outputId] resolves via [ItemCatalogue].
  final String outputId;
  final int outputCount;

  /// The skill that makes it, and the skill level that unlocks it.
  ///
  /// ⚠️ Skill level, not player level. The output's own [ItemDef.equipLevel]
  /// governs who can *wear* it; a recipe gates who can *make* it. Conflating
  /// the two would kill the twink lane §9b.3 deliberately keeps open.
  final CraftSkill skill;
  final int skillLevel;

  /// ⚠️ **False for almost everything** (§9b.2): stations are convenience —
  /// faster, better quality odds, passive bulk — not gates. True is reserved
  /// for certain high-tier recipes, and every `true` should cite why.
  final bool stationRequired;

  final List<RecipeInput> inputs;

  /// The crafting act (ITEMS §9b.9c levers 1–3): which gestures, in order,
  /// with their reps and base complexity. ⭐ **Authored content, like the
  /// inputs** — levers 4–6 (windows, tempo, thresholds) are computed at
  /// craft time from the margin and are deliberately NOT stored.
  /// ⚠️ Empty = no act authored yet; the Workbench falls back to the plain
  /// button. Tier-1 scripts hold to the ruling: 2–3 forgiving steps.
  final List<GestureStep> steps;

  const RecipeDef({
    required this.id,
    required this.outputId,
    required this.skill,
    required this.skillLevel,
    required this.inputs,
    this.steps = const [],
    this.outputCount = 1,
    this.stationRequired = false,
    // ⚠️ No `inputs.length` assert — list members are not const-evaluable.
    // "A recipe with no inputs is a faucet" is enforced by
    // `content_export_test` instead, where it can name the offender.
  }) : assert(outputCount > 0);
}
