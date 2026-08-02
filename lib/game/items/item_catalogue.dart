/// Every item definition in the game, addressable by id.
///
/// ⭐ **The lookup that makes string-keyed drop tables safe.** Dart forbids
/// field access inside a const expression, so drop tables and recipes must
/// name items by string; this registry is what lets a test prove every one of
/// those strings resolves.
library;

import 'catalogue/whispering_woods_items.dart';
import 'item_def.dart';
import 'item_instance.dart';
import 'item_naming.dart';

abstract final class ItemCatalogue {
  /// ⚠️ **Every zone catalogue must be listed here.** An unlisted one compiles
  /// fine and simply never resolves, which is exactly the silent failure the
  /// id test exists to catch.
  static const List<ItemDef> all = <ItemDef>[...WhisperingWoodsItems.all];

  static final Map<String, ItemDef> _byId = {for (final d in all) d.id: d};

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
