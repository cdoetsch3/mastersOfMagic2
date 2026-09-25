/// What a player **owns**, as opposed to what an item **is**.
///
/// ⚠️ **These live in the database, not in code.** A character who starts on
/// one machine and continues on another must find the same loot; definitions
/// go the other way, into code, because the duel resolves against them
/// (ITEMS_DESIGN §10.1).
library;

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'item_def.dart';

/// A non-fungible item — one that carries rolls of its own.
///
/// ⭐ Only ever created for a def where `isFungible` is false. A fungible item
/// needs no instance at all: its `defId` says everything about it.
@immutable
class ItemInstance {
  /// Unique per physical item. ⚠️ Generated at craft or drop time and never
  /// reused — trade history and the bank both key on it.
  final String instanceId;

  final String defId;

  /// The quality tier that scales this piece's stats (ITEMS §9b.9f).
  ///
  /// ⭐ Crafted gear rolls it through the §9b.9d pipeline; dropped gear rolls
  /// it at mint (90/8/2 Standard/Ornate/Master, never Rough — a drop was not
  /// your hands, so there is nothing to fumble). Null — any pre-ruling
  /// instance — reads as Standard.
  final Quality? quality;

  /// The element prefix a drop carries (ITEMS §9b.5b). 📝 Not rolled by
  /// anything yet; independent of [quality].
  final MagicElement? aspect;

  /// Gem def ids, positionally. Length must not exceed the def's socketCount.
  final List<String> socketed;

  /// The enchant applied, if any. ⭐ Includes the unbinding enchant, which is
  /// how an Untradeable item becomes Tradeable (ITEMS §6c).
  final String? enchantId;

  const ItemInstance({
    required this.instanceId,
    required this.defId,
    this.quality,
    this.aspect,
    this.socketed = const [],
    this.enchantId,
  });

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'defId': defId,
    if (quality != null) 'quality': quality!.name,
    if (aspect != null) 'aspect': aspect!.name,
    if (socketed.isNotEmpty) 'socketed': socketed,
    if (enchantId != null) 'enchantId': enchantId,
  };

  factory ItemInstance.fromJson(Map<String, dynamic> json) => ItemInstance(
    instanceId: json['instanceId'] as String,
    defId: json['defId'] as String,
    quality: _byName(Quality.values, json['quality'] as String?),
    aspect: _byName(MagicElement.values, json['aspect'] as String?),
    socketed: (json['socketed'] as List?)?.cast<String>() ?? const [],
    enchantId: json['enchantId'] as String?,
  );
}

T? _byName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// One slot of the carried backpack.
///
/// ⭐ **One item per slot** (ITEMS §10.3a) — twenty Oak Logs occupy twenty
/// slots. That is what makes carrying capacity a real resource, and why a
/// gathering trip ends when you are full rather than when you are bored.
/// ⭐ **Except motes** (ruling, Christian 2026-09-25): Dust stacks to 25 in a
/// slot and Shards to 5 — see [count] and `ItemDef.stackSize`.
/// ⚠️ Storage (the bank) is the other shape entirely and collapses fungibles
/// to counts.
@immutable
class InventorySlot {
  final String defId;

  /// Set **iff** the definition is non-fungible. ⚠️ Guarded by
  /// [InventorySlot.forDef]; constructing one by hand can break the invariant.
  final String? instanceId;

  /// How many of [defId] this one slot holds.
  ///
  /// ⭐ **Only ever > 1 for a def that stacks** (`ItemDef.stackSize` > 1 — Dust
  /// and Shards, ruled 2026-09-25), and in the backpack never above that
  /// def's cap: `Backpack.withAdded` splits anything bigger across slots.
  /// ⚠️ A loot row on the victory picker (`AdventureRun.unclaimed`) is the one
  /// place a count may exceed the cap — it is a drop waiting to be split, not
  /// a slot.
  final int count;

  const InventorySlot({required this.defId, this.instanceId, this.count = 1});

  /// This slot holding [n] instead. ⚠️ The def and instance ride along
  /// unchanged — a stack is the same thing, only more or fewer of it.
  InventorySlot withCount(int n) =>
      InventorySlot(defId: defId, instanceId: instanceId, count: n);

  /// Builds a slot, enforcing the fungibility invariant.
  factory InventorySlot.forDef(
    ItemDef def, {
    String? instanceId,
    int count = 1,
  }) {
    if (count != 1 && def.stackSize <= 1) {
      throw ArgumentError(
        '${def.id} does not stack, so a slot of it holds exactly one — a '
        'count of $count would be items the backpack never paid a slot for.',
      );
    }
    if (def.isFungible && instanceId != null) {
      throw ArgumentError(
        '${def.id} is fungible and must not carry an instance id — two of '
        'them are interchangeable, so the id would be meaningless state.',
      );
    }
    if (!def.isFungible && instanceId == null) {
      throw ArgumentError(
        '${def.id} is not fungible and needs its own instance id — its '
        'quality, aspect, sockets and enchant have nowhere else to live.',
      );
    }
    return InventorySlot(defId: def.id, instanceId: instanceId, count: count);
  }

  /// ⚠️ `count` is written only when it is above 1, so every save written
  /// before stacking — and every single-item slot after it — keeps exactly
  /// the shape it always had.
  Map<String, dynamic> toJson() => {
    'defId': defId,
    if (instanceId != null) 'instanceId': instanceId,
    if (count > 1) 'count': count,
  };

  /// ⭐ An absent `count` reads as 1, so every save from before stacking loads
  /// unchanged. ⚠️ An out-of-range count is read as written, never clamped
  /// here — `PlayerProfile.repairContainers` is the one place that fixes it,
  /// and it counts the fix.
  factory InventorySlot.fromJson(Map<String, dynamic> json) => InventorySlot(
    defId: json['defId'] as String,
    instanceId: json['instanceId'] as String?,
    count: (json['count'] as num?)?.toInt() ?? 1,
  );
}
