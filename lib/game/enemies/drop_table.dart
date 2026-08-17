/// What an enemy leaves behind.
///
/// ⭐ **Three tiers, deliberately** — the shape makes rates auditable. With one
/// flat list of independent rolls it is easy to build a monster that quietly
/// drops five things, and impossible to answer "how much loot is a kill worth"
/// without simulating it.
library;

import 'package:flutter/foundation.dart';

@immutable
class DropEntry {
  /// The `ItemDef` id, or null for the "nothing" slot in a [DropTable.main].
  final String? defId;

  /// Relative weight within [DropTable.main]; ignored elsewhere.
  final int weight;

  /// Independent chance 0–1, honoured by [DropTable.always] and
  /// [DropTable.bonus] alike; ignored by [DropTable.main], which draws by
  /// [weight] instead.
  ///
  /// ⚠️ Defaults to 1, so an `always` entry that says nothing is genuinely
  /// guaranteed — but an `always` entry that *does* name a chance gets it.
  /// The two buckets differ in how many entries can pay (all of `always`,
  /// each of `bonus`), not in whether the number means anything.
  final double chance;

  final int min;
  final int max;

  const DropEntry(
    this.defId, {
    this.weight = 1,
    this.chance = 1,
    this.min = 1,
    this.max = 1,
  });

  /// ⭐ The "nothing" outcome. Giving it a real weight is what keeps a main
  /// table honest — otherwise every kill pays and the rare slots inflate.
  const DropEntry.nothing({required int weight})
    : this(null, weight: weight, chance: 1, min: 0, max: 0);
}

@immutable
class DropTable {
  /// Consulted every kill — ⭐ *every* entry gets its own roll, unlike [main]
  /// where exactly one wins. Motes and bulk materials live here. An entry is
  /// guaranteed only if it leaves [DropEntry.chance] at its default of 1.
  final List<DropEntry> always;

  /// ⭐ **Exactly one entry is drawn**, by weight. This is what bounds a kill's
  /// value and makes drop rates readable as percentages.
  final List<DropEntry> main;

  /// Rolled independently, on top. ⚠️ Reserve for genuinely rare things —
  /// every entry here is unbounded loot.
  final List<DropEntry> bonus;

  const DropTable({
    this.always = const [],
    this.main = const [],
    this.bonus = const [],
  });

  static const empty = DropTable();

  int get totalWeight => main.fold(0, (sum, e) => sum + e.weight);

  /// The chance [defId] comes out of [main], as a fraction.
  double mainChanceOf(String defId) {
    if (totalWeight == 0) return 0;
    final w = main
        .where((e) => e.defId == defId)
        .fold(0, (sum, e) => sum + e.weight);
    return w / totalWeight;
  }

  /// Every item id this table can yield, at any rate.
  Set<String> get possibleDrops => {
    for (final e in [...always, ...main, ...bonus])
      if (e.defId != null) e.defId!,
  };
}
