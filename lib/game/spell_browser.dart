/// How the Spellbook shelf is organised: the lane a spell belongs to, the
/// orders it can be read in, and the two filters that narrow it.
///
/// ⭐ **Pure, and deliberately outside the widget.** The book is on its way
/// from 25 spells to ~59, which is the size at which "which lane is this?"
/// and "what order am I reading?" stop being obvious by eye. Every rule
/// below is a function over [Spell] alone — no [BuildContext], no profile —
/// so the shelf's behaviour is pinned by unit tests rather than inferred
/// from a widget tree.
library;

import 'package:mom_engine/mom_engine.dart';

/// The five shelves of the book.
///
/// ⭐ **Declaration order IS section order**, and it is the engine's own
/// priority ladder: shields (3) resolve before quick attacks (5), which
/// resolve before self-aux (7), which resolve before enemy-aux (8), which
/// resolve before the regular attacks (9). So reading the ungrouped book top
/// to bottom is reading a turn in the order it actually happens — the same
/// direction [SpellSort.speed] sorts in.
///
/// ⭐ **Aux is two shelves, not one** (designer's ruling, 2026-08-29): what
/// you do to YOURSELF (stances, riders, cleanses, Grace, initiative) and what
/// you do to THEM without a damage roll (debuffs, strips, Discharge). They
/// are different decisions — one is preparation, the other is pressure —
/// and the §7a lanes give them different clocks, so one header for both
/// hid the difference the engine makes.
///
/// ⚠️ [offense] is this shelf's word for what `priorityLabel` (element_style)
/// calls the *regular* band. The engine names a timing slot; the shelf names
/// what the spell is FOR, and a player scanning for damage does not scan for
/// "regular".
enum SpellKind {
  shields('Shields'),
  quick('Quick'),
  auxSelf('Aux-self'),
  auxOffense('Aux-offense'),
  offense('Offense');

  final String label;
  const SpellKind(this.label);
}

/// Which lane [spell] belongs to.
///
/// The rules, in the order they are applied — and the order matters:
///
///  1. **A wall is a shield wherever it sits.** [ShieldEffect] and
///     [BarrierEffect] answer to the Shields chip on effect alone, so a
///     future off-band ward cannot go missing from the one section a player
///     hunting for defence will look in.
///  2. **Priority 3 is the shield band by definition** (`spell.dart`'s own
///     library doc). A priority-3 spell that is not literally a wall is still
///     something you cast at wall speed, and it files with the walls.
///  3. **A spell that deals no damage is aux**, and WHO it is aimed at
///     splits the shelf: harmful-but-not-damaging (`isHarmful` without
///     `isOffensive` — the Discharge family, which is the whole §7a
///     aux-offense lane) is [auxOffense]; everything else that deals no
///     damage — buffs, initiative, cleanses, Grace — is [auxSelf].
///     ⚠️ Derived from what the spell DOES, not its priority number, so a
///     future enemy-facing aux on an odd clock still files under pressure,
///     and a heal on the priority-9 clock never files under "Offense" — a
///     lie told by a section header.
///  4. What is left deals damage, and the band splits it: 1–6 is [quick]
///     (instants and quick attacks — they beat aux and regular spells to the
///     punch), 7 and up is [offense].
SpellKind spellKindOf(Spell spell) {
  final effect = spell.effect;
  if (effect is ShieldEffect ||
      effect is BarrierEffect ||
      spell.priority == 3) {
    return SpellKind.shields;
  }
  if (!spell.isOffensive) {
    return spell.isHarmful ? SpellKind.auxOffense : SpellKind.auxSelf;
  }
  return spell.priority <= 6 ? SpellKind.quick : SpellKind.offense;
}

/// The label a kind chip carries. `null` is the unfiltered shelf.
String spellKindFilterLabel(SpellKind? kind) => kind?.label ?? 'All';

/// The charge-cost chips.
///
/// ⭐ **A partition, not three hand-picked bands** (the Shop's rule): every
/// non-negative cost lands in exactly one of [cheap], [mid], [heavy], so no
/// spell can be unreachable from every chip. A book the player can only
/// half-see teaches them the other half does not exist.
enum SpellCostFilter {
  any('Any cost'),
  cheap('Cost 0-1'),
  mid('Cost 2-3'),
  heavy('Cost 4+');

  final String label;
  const SpellCostFilter(this.label);

  /// ⚠️ **X-cost spells are filed by their MINIMUM** (Barrage: 1, so it is
  /// cheap). That minimum is the only number an X spell is honest about
  /// before it is cast — filing it under "4+" on the strength of what it
  /// *might* consume would hide it from the player shopping for something
  /// they can afford this turn.
  bool accepts(Spell spell) => switch (this) {
    SpellCostFilter.any => true,
    SpellCostFilter.cheap => spell.chargeCost <= 1,
    SpellCostFilter.mid => spell.chargeCost == 2 || spell.chargeCost == 3,
    SpellCostFilter.heavy => spell.chargeCost >= 4,
  };
}

/// How the shelf is ordered.
///
/// ⭐ [book] is a real, re-selectable member rather than an implicit starting
/// state (the Shop's ruling, applied here): the authored order is
/// information — the shields read ward → sanctuary as a ladder of size — and
/// a player who sorts by name must be able to get the ladder back without
/// leaving the screen.
enum SpellSort {
  book('Book order'),
  name('Name'),
  cost('Charge cost'),
  speed('Speed');

  final String label;
  const SpellSort(this.label);
}

/// [spells] re-ordered for [sort]. Never mutates its argument.
///
/// ⚠️ **Every order tie-breaks on NAME.** Sorting by cost and back again must
/// not shuffle rows the player had just learned the position of, and the book
/// ships six spells at cost 3 alone.
///
/// ⚠️ [SpellSort.speed] is **ASCENDING priority**, i.e. fastest first, because
/// lower priority acts earlier (`spell.dart`). The tempting mutant — sorting
/// descending because the bigger number looks like the faster spell — puts
/// the slowest attacks at the top of a list whose control says "Speed".
List<Spell> sortSpells(List<Spell> spells, SpellSort sort) {
  final out = List<Spell>.of(spells);
  // The given order IS the answer here: the caller's own sequence, untouched.
  if (sort == SpellSort.book) return out;
  int byName(Spell a, Spell b) => a.name.compareTo(b.name);
  out.sort(switch (sort) {
    SpellSort.book => byName, // unreachable — guarded above.
    SpellSort.name => byName,
    SpellSort.cost => (a, b) {
      final c = a.chargeCost.compareTo(b.chargeCost);
      return c != 0 ? c : byName(a, b);
    },
    SpellSort.speed => (a, b) {
      final c = a.priority.compareTo(b.priority);
      return c != 0 ? c : byName(a, b);
    },
  });
  return out;
}

/// True when any filter is narrowing the shelf.
bool spellFilterActive({
  required SpellKind? kind,
  required SpellCostFilter cost,
  String query = '',
}) => kind != null || cost != SpellCostFilter.any || query.trim().isNotEmpty;

/// [F] Name search: case-insensitive substring on the spell's name. An empty
/// or whitespace query matches everything, so the box at rest is not a filter.
bool spellMatchesQuery(Spell spell, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty || spell.name.toLowerCase().contains(q);
}

/// The flat shelf: [source] narrowed by every filter, then ordered.
///
/// ⚠️ Filter first, sort second — the sort must only ever see rows that
/// survived, or "sort within the current filter" quietly becomes "sort the
/// whole catalogue and serve it back".
List<Spell> filterSpells(
  List<Spell> source, {
  required SpellKind? kind,
  required SpellCostFilter cost,
  required SpellSort sort,
  String query = '',
}) {
  final kept = source
      .where((s) => kind == null || spellKindOf(s) == kind)
      .where(cost.accepts)
      .where((s) => spellMatchesQuery(s, query))
      .toList();
  return sortSpells(kept, sort);
}

/// [F] How many spells each kind chip would show under the OTHER active
/// filters — so a chip's count is a promise about what tapping it does, not
/// a fact about the whole book. `null` keys the All chip.
Map<SpellKind?, int> spellKindCounts(
  List<Spell> source, {
  required SpellCostFilter cost,
  String query = '',
}) {
  final visible = source
      .where(cost.accepts)
      .where((s) => spellMatchesQuery(s, query))
      .toList();
  return {
    null: visible.length,
    for (final k in SpellKind.values)
      k: visible.where((s) => spellKindOf(s) == k).length,
  };
}

/// One section of the grouped, unfiltered shelf.
class SpellGroup {
  final SpellKind kind;
  final List<Spell> spells;
  const SpellGroup(this.kind, this.spells);
}

/// [source] split into its lanes, each lane ordered by [sort].
///
/// Sections come back in [SpellKind] declaration order (see there), and an
/// **empty lane yields no group at all** — ⚠️ a section header standing over
/// nothing reads as a loading bug, not as an empty category.
///
/// [B] The cost and search filters narrow each lane IN PLACE rather than
/// flattening the book: a player shopping for "cheap" still wants to know
/// which of the cheap ones are shields — only the kind chip, which already
/// names one lane, collapses the sections.
List<SpellGroup> groupSpells(
  List<Spell> source, {
  required SpellSort sort,
  SpellCostFilter cost = SpellCostFilter.any,
  String query = '',
}) {
  final groups = <SpellGroup>[];
  for (final kind in SpellKind.values) {
    final lane = source
        .where((s) => spellKindOf(s) == kind)
        .where(cost.accepts)
        .where((s) => spellMatchesQuery(s, query))
        .toList();
    if (lane.isEmpty) continue;
    groups.add(SpellGroup(kind, sortSpells(lane, sort)));
  }
  return groups;
}
