/// Every item definition in the game, addressable by id.
///
/// ⭐ **The lookup that makes string-keyed drop tables safe.** Dart forbids
/// field access inside a const expression, so drop tables and recipes must
/// name items by string; this registry is what lets a test prove every one of
/// those strings resolves.
library;

import 'catalogue/ashfall_vale_items.dart';
import 'catalogue/cinderpeak_items.dart';
import 'catalogue/glimmerbrook_items.dart';
import 'catalogue/thornmire_items.dart';
import 'catalogue/whispering_woods_items.dart';
import 'item_def.dart';
import 'item_instance.dart';
import 'item_naming.dart';

abstract final class ItemCatalogue {
  /// ⚠️ **Every zone catalogue must be listed here.** An unlisted one compiles
  /// fine and simply never resolves, which is exactly the silent failure the
  /// id test exists to catch.
  ///
  /// ⭐ **Keyed by zone id, and that key is load-bearing** — it is the only
  /// place in the game that records *which zone defines an item*, which is
  /// what [zoneOf] and therefore `assets/items/<zone>/<id>.png` are built on.
  /// ⚠️ The key must be a real `World.locations` id, not a display name or a
  /// class name; a test asserts it.
  ///
  /// ⭐ **A cross-zone recipe output belongs to the file that DEFINES it**, not
  /// to the zone whose materials it eats — the Tuskhide Belt is Cinderpeak's
  /// even though Thornmire supplies its thread. That is the same rule the
  /// catalogue files already follow for motes ("the mote lives with the zone
  /// that first yields it"), so nothing falls between two zones.
  static const Map<String, List<ItemDef>> byZone = <String, List<ItemDef>>{
    'whispering_woods': WhisperingWoodsItems.all,
    'glimmerbrook': GlimmerbrookItems.all,
    'cinderpeak_foothills': CinderpeakItems.all,
    'thornmire': ThornmireItems.all,
    'ashfall_vale': AshfallValeItems.all,
  };

  /// ⚠️ **Derived from [byZone], not written out again.** Two hand-kept lists
  /// of the same five catalogues is exactly how an item ends up resolvable by
  /// id but owned by no zone — an icon that can never load, with nothing
  /// failing to say so.
  static final List<ItemDef> all = <ItemDef>[
    for (final defs in byZone.values) ...defs,
  ];

  static final Map<String, ItemDef> _byId = {for (final d in all) d.id: d};

  static final Map<String, String> _zoneById = {
    for (final e in byZone.entries)
      for (final d in e.value) d.id: e.key,
  };

  /// Which zone's catalogue file defines [defId].
  ///
  /// ⭐ **A lookup rather than a field on [ItemDef].** A `zoneId` on every def
  /// would be a fact stated twice — once by which file the `static const`
  /// lives in and once by the string beside it — and the two can disagree.
  /// Here the file placement *is* the answer, so it cannot.
  ///
  /// ⚠️ Null means no catalogue claims the id, which callers must treat the
  /// way `tryById` does: a save written before a content patch, not a crash.
  static String? zoneOf(String defId) => _zoneById[defId];

  /// Null when nothing owns [id] — callers should treat that as a bug, not a
  /// missing item.
  static ItemDef? tryById(String id) => _byId[id];

  /// The player-facing name, ⭐ **composed from the facts** rather than stored
  /// (ITEMS §9b.5a): aspect prefix + quality + material + form.
  ///
  /// ⚠️ Only equipment has a grammar. Everything else uses its own written
  /// name, which is why [ItemDef] carries no `name` field for them to drift
  /// against.
  static String displayName(ItemDef def, [ItemInstance? instance]) {
    if (def is! EquipmentDef) return def.properName ?? def.id;
    // ⭐ Named equipment — boss uniques and the drop-only jewelry — keeps its
    // bespoke name (§9b.5): "Heartwood Staff", never "Heartwood Quarterstaff".
    if (def.properName != null) return def.properName!;
    return composeItemName(
      aspectPrefix: instance?.aspect == null
          ? null
          : aspectPrefixes[instance!.aspect!.name],
      quality: instance?.quality,
      material: def.material,
      form: def.form,
    );
  }

  static ItemDef byId(String id) {
    final d = _byId[id];
    if (d == null) throw ArgumentError('no item definition for "$id"');
    return d;
  }

  static bool contains(String id) => _byId.containsKey(id);

  static Iterable<T> ofKind<T extends ItemDef>() => all.whereType<T>();
}
