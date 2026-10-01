/// Where things come from: what a zone yields, and where an item is found.
///
/// 📝 Ruling (Christian, playtest 2026-09-30, note 3): *"The summaries for the
/// locations should contain more info about the drops and resources available
/// so I can more easily search for a place that has Rowan logs or iron ore."*
/// The Map tab's location cards, the world map's place sheet and the item
/// dialog all read this file.
///
/// ⭐ **Derived from the tables, never authored.** Every answer here is read
/// off [GatherNodes.all] and the creatures' [DropTable]s in [Bestiary.all], so
/// a node added, a drop moved or a creature retired changes what the player is
/// told with no second record to forget. A hand-written "found in" list would
/// be the first thing to drift.
///
/// ⭐ **Built lazily, once, and cached.** The Map tab rebuilds on every travel
/// tick, and the index is a full walk of every creature's tables — cheap, but
/// not something to redo per frame. The tables are `const`, so the cache can
/// never go stale inside a running app.
library;

import 'enemies/bestiary.dart';
import 'enemies/drop_table.dart';
import 'gathering/gather_node.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'world.dart';

/// One place an item can be found, and how.
typedef ItemSource = ({GameLocation location, bool gathered, bool dropped});

abstract final class Provenance {
  /// The defs [zoneId]'s gather nodes yield, in node order, each once.
  ///
  /// Empty for a town, and for a zone with no nodes (The Eclipsed Citadel).
  static List<ItemDef> gatherablesIn(String zoneId) =>
      _index.gather[zoneId] ?? const [];

  /// Every def a creature of [zoneId] can drop, at any rate, each once —
  /// ⚠️ **excluding [MoteDef] and [KeyDef]**: motes fall from nearly
  /// everything and would bury the line, and a gate key is a quest, not a
  /// reason to go somewhere.
  ///
  /// ⭐ Ordered for reading: [MaterialDef]s first (what the ruling was looking
  /// for), then what you drink ([ConsumableDef] and [BeltableDef] alike), then
  /// any other kind, then [EquipmentDef]s by [Rarity] ascending. Each group
  /// keeps first-seen order — creature by creature in roster order, and within
  /// one table `always`, `main`, `bonus` ([DropTable.possibleDrops]).
  static List<ItemDef> dropsIn(String zoneId) =>
      _index.drops[zoneId] ?? const [];

  /// Every place [defId] can be found — gathered from a node, dropped by a
  /// creature, or both — in [World.locations] order.
  ///
  /// ⚠️ Unlike [dropsIn], **nothing is filtered**: motes, keys and common
  /// equipment all answer here, because the question is about one item the
  /// player is already holding. Empty for an item that is only ever crafted.
  static List<ItemSource> sourcesOf(String defId) =>
      _index.sources[defId] ?? const [];

  /// The Map's gather line for [location] — `Gather: Rowan Log · Iron Ore` —
  /// or null where there is nothing to gather (every town, and a zone without
  /// nodes).
  static String? gatherLine(GameLocation location) {
    if (location.isTown) return null;
    final names = [
      for (final d in gatherablesIn(location.id)) ItemCatalogue.displayName(d),
    ];
    return names.isEmpty ? null : 'Gather: ${names.join(_sep)}';
  }

  /// The Map's drops line for [location] — `Drops: Hardtack · Countstone
  /// Pendant` — or null where nothing qualifies (every town).
  ///
  /// ⭐ **Equipment only at [Rarity.rare] or better.** A common piece in a
  /// drop table is one of the zone's own crafted set (the Woods' Oak Circlet
  /// off the Rootknuckle), which the player can make at the bench; the rare
  /// and epic pieces are the ones worth travelling for, and listing every
  /// common would push them off the end of a phone-width line.
  ///
  /// ⭐ **What the gather line already says is not said again.** Most of a
  /// zone's gatherables also fall from its creatures; repeating them here
  /// doubled the line and hid the kill-only things (hides, essences,
  /// rations) that only this line can tell you about. The item dialog's
  /// "Found in" line still names both ways for each item.
  static String? dropsLine(GameLocation location) {
    if (location.isTown) return null;
    final gathered = gatherablesIn(location.id).toSet();
    final names = [
      for (final d in dropsIn(location.id))
        if (!gathered.contains(d) &&
            (d is! EquipmentDef || d.rarity.index >= Rarity.rare.index))
          ItemCatalogue.displayName(d),
    ];
    return names.isEmpty ? null : 'Drops: ${names.join(_sep)}';
  }

  /// The item dialog's line for [def] — `Found in: Thunderspire Peaks
  /// (gathered, dropped) · Windward Steppe (dropped)` — or null for an item
  /// with no source (crafted only, or bought).
  static String? foundInLine(ItemDef def) {
    final sources = sourcesOf(def.id);
    if (sources.isEmpty) return null;
    final parts = [
      for (final s in sources)
        '${s.location.name} (${[if (s.gathered) 'gathered', if (s.dropped) 'dropped'].join(', ')})',
    ];
    return 'Found in: ${parts.join(_sep)}';
  }

  static const String _sep = ' · ';

  // ⭐ A `static final` is initialised on first read — this is the lazy,
  // build-once cache.
  static final _ProvenanceIndex _index = _ProvenanceIndex.build();
}

class _ProvenanceIndex {
  final Map<String, List<ItemDef>> gather;
  final Map<String, List<ItemDef>> drops;
  final Map<String, List<ItemSource>> sources;

  const _ProvenanceIndex(this.gather, this.drops, this.sources);

  factory _ProvenanceIndex.build() {
    // Insertion-ordered sets (Dart's default), so "each once" keeps
    // first-seen order for free.
    final gatherIds = <String, Set<String>>{};
    for (final n in GatherNodes.all) {
      (gatherIds[n.zoneId] ??= {}).add(n.yieldsDefId);
    }
    final dropIds = <String, Set<String>>{};
    for (final e in Bestiary.all) {
      (dropIds[e.zoneId] ??= {}).addAll(e.drops.possibleDrops);
    }

    // ⚠️ `tryById`, not `byId`: an id that fails to resolve is a content bug
    // the catalogue law catches (test/provenance_test.dart), not a reason to
    // crash the Map tab.
    List<ItemDef> resolve(Iterable<String> ids) =>
        [for (final id in ids) ItemCatalogue.tryById(id)].nonNulls.toList();

    final gather = {
      for (final MapEntry(:key, :value) in gatherIds.entries)
        key: List<ItemDef>.unmodifiable(resolve(value)),
    };

    final drops = <String, List<ItemDef>>{};
    for (final MapEntry(:key, :value) in dropIds.entries) {
      final defs = resolve(
        value,
      ).where((d) => d is! MoteDef && d is! KeyDef).toList();
      // ⚠️ `List.sort` is not stable, so first-seen order is the explicit
      // tie-break rather than an accident of the algorithm.
      final seen = {for (final (i, d) in defs.indexed) d: i};
      defs.sort((a, b) {
        final byRank = _rank(a).compareTo(_rank(b));
        return byRank != 0 ? byRank : seen[a]!.compareTo(seen[b]!);
      });
      drops[key] = List.unmodifiable(defs);
    }

    final sources = <String, List<ItemSource>>{};
    for (final loc in World.locations) {
      final g = gatherIds[loc.id] ?? const <String>{};
      final d = dropIds[loc.id] ?? const <String>{};
      for (final id in {...g, ...d}) {
        (sources[id] ??= []).add((
          location: loc,
          gathered: g.contains(id),
          dropped: d.contains(id),
        ));
      }
    }

    return _ProvenanceIndex(gather, drops, {
      for (final MapEntry(:key, :value) in sources.entries)
        key: List.unmodifiable(value),
    });
  }

  /// Materials, then drinkables, then any other kind, then equipment by
  /// rarity — see [Provenance.dropsIn].
  static int _rank(ItemDef d) => switch (d) {
    MaterialDef() => 0,
    ConsumableDef() || BeltableDef() => 1,
    EquipmentDef(:final rarity) => 3 + rarity.index,
    _ => 2,
  };
}
