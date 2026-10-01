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
import '../skills.dart';
import 'item_catalogue.dart';
import 'item_def.dart';

/// One input line: [count] of the fungible material [defId] — or, for the two
/// enchanting shapes, a line that names a CLASS of item rather than one id.
///
/// ⚠️ **Inputs are always fungible items** (materials, motes, components),
/// with exactly one exception: [anyEquipmentOfRarity]. A recipe that consumed
/// a non-fungible — a specific instance, with a quality roll on it — needs
/// instance selection UI and provenance tracking that nothing else in
/// crafting has, and Salvage (ENCHANTING_DESIGN §6) is the one verb that
/// pays that price; every other recipe eats stacks.
///
/// ⭐ **The matcher semantics, stated once** (ENCHANTING_DESIGN §3.2, §6).
/// `GameState.craft` must call [RecipeDef.drawFrom] / [RecipeDef.accepts]
/// instead of reading [defId] × [count] literally whenever [isExact] is
/// false:
///
/// - **exact** (the default): [count] of [defId], nothing else counts.
/// - **[anyElement]** (Transmute): [defId] is an EXEMPLAR mote and only its
///   [MoteTier] is read. Any element's mote of that tier satisfies the line,
///   ⚠️ **except the recipe's own output element** (4 Pyro Dust → 1 Pyro Dust
///   is a pure loss no player means), and one craft may fill the line from
///   several elements at once. ⭐ The count consumed is **not** [count]: it
///   is [countAt] the crafter's Enchanting level — the transmute curve,
///   [Skills.transmuteInputsAt]. [count] holds the level-1 rung so every
///   reader that has not learned the flag still sees the worst case. Draw
///   order: the element held in the largest quantity first, ties in
///   [MagicElement] enum order — the player spends the surplus they banked,
///   and the same pack always yields the same draw. 📝 A UI that lets the
///   player pick the source element passes [RecipeDef.drawFrom] a counts map
///   holding only that element; the matcher needs no second mode.
/// - **[anyEquipmentOfRarity]** (Salvage): one equipment INSTANCE whose def
///   has exactly that rarity. [defId] is [anyEquipmentDefId], resolves to
///   nothing on purpose, and no stack count can satisfy it — the crafter
///   takes the chosen piece and asks [RecipeDef.accepts]. The yield is
///   `SalvageTable.yieldOf`, never [RecipeDef.outputId].
@immutable
class RecipeInput {
  final String defId;
  final int count;

  /// Transmute's "any element of [defId]'s tier". See the class doc.
  final bool anyElement;

  /// Salvage's "one piece of equipment of this rarity". See the class doc.
  final Rarity? anyEquipmentOfRarity;

  const RecipeInput(this.defId, this.count, {this.anyElement = false})
    : anyEquipmentOfRarity = null;

  /// One piece of equipment of [rarity] — the salvage input.
  const RecipeInput.anyEquipmentOfRarity(Rarity rarity)
    : defId = anyEquipmentDefId,
      count = 1,
      anyElement = false,
      anyEquipmentOfRarity = rarity;

  /// ⚠️ The [defId] an equipment line carries. Resolves to nothing on
  /// purpose: an unwired reader that looks it up fails loudly rather than
  /// consuming some real item by accident.
  static const String anyEquipmentDefId = '*equipment';

  /// True for an ordinary line — the only kind a reader may take literally.
  bool get isExact => !anyElement && anyEquipmentOfRarity == null;

  /// How many this line consumes for a crafter at [skillLevel]. ⭐ Only an
  /// [anyElement] line varies (the transmute curve); every other line is
  /// [count] at every level.
  int countAt(int skillLevel) =>
      anyElement ? Skills.transmuteInputsAt(skillLevel) : count;
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

  /// The stacks this recipe consumes from [counts] (def id → how many the
  /// crafter may count on — `GameState.materialCount`'s answer) at
  /// [skillLevel], or null when anything is short.
  ///
  /// ⭐ **The one pure matcher** for every input kind (see [RecipeInput]):
  /// exact lines draw first, then [RecipeInput.anyElement] lines fill from
  /// what is left. [RecipeInput.anyEquipmentOfRarity] lines draw no stack —
  /// [accepts] judges the piece. ⚠️ The result is a plan, not a mutation:
  /// the crafter removes exactly these counts and nothing else.
  Map<String, int>? drawFrom(Map<String, int> counts, {int skillLevel = 1}) {
    final left = Map<String, int>.of(counts);
    final draw = <String, int>{};
    void take(String id, int n) {
      left[id] = (left[id] ?? 0) - n;
      draw[id] = (draw[id] ?? 0) + n;
    }

    for (final input in inputs.where((i) => i.isExact)) {
      if ((left[input.defId] ?? 0) < input.count) return null;
      take(input.defId, input.count);
    }
    for (final input in inputs.where((i) => i.anyElement)) {
      var need = input.countAt(skillLevel);
      final candidates = _anyElementCandidates(input)
        ..sort((a, b) {
          final byHeld = (left[b.id] ?? 0).compareTo(left[a.id] ?? 0);
          return byHeld != 0 ? byHeld : a.element!.index - b.element!.index;
        });
      for (final mote in candidates) {
        if (need == 0) break;
        final have = left[mote.id] ?? 0;
        if (have <= 0) continue;
        final n = have < need ? have : need;
        take(mote.id, n);
        need -= n;
      }
      if (need > 0) return null;
    }
    return draw;
  }

  /// Whether [counts] covers every stack line at [skillLevel] and, when the
  /// recipe eats a piece of equipment, [piece] is one it [accepts].
  bool satisfiedBy(
    Map<String, int> counts, {
    int skillLevel = 1,
    EquipmentDef? piece,
  }) {
    if (drawFrom(counts, skillLevel: skillLevel) == null) return false;
    final wantsPiece = inputs.any((i) => i.anyEquipmentOfRarity != null);
    return !wantsPiece || (piece != null && accepts(piece));
  }

  /// Whether [piece] satisfies every [RecipeInput.anyEquipmentOfRarity] line.
  /// ⚠️ Exact rarity, never "at least": a rare piece salvaged on the common
  /// marker would pay the common yield and silently lose the difference.
  bool accepts(EquipmentDef piece) => inputs
      .where((i) => i.anyEquipmentOfRarity != null)
      .every((i) => i.anyEquipmentOfRarity == piece.rarity);

  /// The motes an [RecipeInput.anyElement] line may draw: [RecipeInput.defId]'s
  /// tier, every element but the output's.
  List<MoteDef> _anyElementCandidates(RecipeInput input) {
    final exemplar = ItemCatalogue.tryById(input.defId);
    if (exemplar is! MoteDef) return [];
    final output = ItemCatalogue.tryById(outputId);
    final excluded = output is MoteDef ? output.element : null;
    return [
      for (final m in ItemCatalogue.ofKind<MoteDef>())
        if (m.tier == exemplar.tier &&
            m.element != null &&
            m.element != excluded)
          m,
    ];
  }
}
