/// What a player **owns**, as opposed to what an item **is**.
///
/// ⚠️ **These live in the database, not in code.** A character who starts on
/// one machine and continues on another must find the same loot; definitions
/// go the other way, into code, because the duel resolves against them
/// (ITEMS_DESIGN §10.1).
library;

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'enchants.dart';
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

  /// The element prefix a piece carries (ITEMS §9b.5b), independent of
  /// [quality].
  ///
  /// ⭐ Two ways in: a rare-or-better **drop** rolls one at mint
  /// (`aspectedDropPercent` in `loot.dart`, ENCHANTING §4.4), and an
  /// **enchant** sets it to its own element ([withEnchant]). With no
  /// [enchantId] an aspect grants its element's **Lesser** affinity — the
  /// "pre-enchanted sidegrade, weaker" (§4.4), resolved in
  /// `Equipping.modifiersOf`.
  final MagicElement? aspect;

  /// Gem def ids, positionally — index `i` is socket `i`. Length must not
  /// exceed the def's socketCount.
  ///
  /// ⚠️ **An empty socket BEFORE a filled one is [emptySocket] (`''`)**, so a
  /// gem keeps its index when the one beside it comes out ([withoutSocket]).
  /// Trailing empties are trimmed, so an all-empty piece is `[]` and writes no
  /// key at all — exactly the shape every save before sockets already has.
  final List<String> socketed;

  /// The enchant applied, if any — an `Enchants` id (`pyro_standard`).
  /// ⭐ Includes the unbinding enchant, which is how an Untradeable item
  /// becomes Tradeable (ITEMS §6c; reserved as `unbind`, ENCHANTING §4.5).
  final String? enchantId;

  /// What [socketed] holds for an empty socket that has a filled one after
  /// it. ⚠️ Never a def id, so it can never resolve to a gem.
  static const String emptySocket = '';

  const ItemInstance({
    required this.instanceId,
    required this.defId,
    this.quality,
    this.aspect,
    this.socketed = const [],
    this.enchantId,
  });

  /// This piece with [enchantId] applied (ENCHANTING §4.1): ⭐ sets the
  /// enchant AND the [aspect] to the enchant's element, so the piece is named
  /// by its prefix (*Charred Oak Staff*) from the shipped grammar.
  ///
  /// ⭐ **Replaces** whatever was there — an older enchant, or a drop's own
  /// aspect (§4.3, §4.4: "the enchant replaces the aspect"). Cost and level
  /// gates are the caller's (lane 3's item-dialog action); this is the fact,
  /// not the transaction.
  ///
  /// ⚠️ Throws on an id the enchant table does not hold: an enchant whose
  /// element is unknown has no aspect to set, and minting a piece that
  /// half-applies one is a save nobody can explain later.
  ItemInstance withEnchant(String enchantId) {
    final enchant = Enchants.tryById(enchantId);
    if (enchant == null) {
      throw ArgumentError.value(enchantId, 'enchantId', 'no such enchant');
    }
    return ItemInstance(
      instanceId: instanceId,
      defId: defId,
      quality: quality,
      aspect: enchant.element,
      socketed: socketed,
      enchantId: enchant.id,
    );
  }

  /// This piece with [gemId] seated in socket [index] (ENCHANTING §5.2),
  /// replacing whatever was there. Sockets before [index] that do not exist
  /// yet are padded with [emptySocket].
  ///
  /// ⚠️ **Does not check the def's socketCount or that [gemId] is a gem** —
  /// an instance does not know its catalogue. The Socket… action (lane 3)
  /// validates; `Equipping.modifiersOf` ignores anything past socketCount
  /// and anything that does not resolve to a `GemDef`, so a bad write can
  /// never grant a stat.
  ItemInstance withSocket(int index, String gemId) {
    RangeError.checkNotNegative(index, 'index');
    final next = [...socketed];
    while (next.length <= index) {
      next.add(emptySocket);
    }
    next[index] = gemId;
    return _withSockets(next);
  }

  /// This piece with socket [index] emptied (ENCHANTING §5.2 — the gem
  /// survives; giving it back is the caller's job). Other gems keep their
  /// indices. An index that is already empty, or past the end, is a no-op.
  ItemInstance withoutSocket(int index) {
    RangeError.checkNotNegative(index, 'index');
    if (index >= socketed.length) return this;
    final next = [...socketed];
    next[index] = emptySocket;
    return _withSockets(next);
  }

  /// ⚠️ Trims trailing empties — see [socketed].
  ItemInstance _withSockets(List<String> sockets) {
    while (sockets.isNotEmpty && sockets.last == emptySocket) {
      sockets.removeLast();
    }
    return ItemInstance(
      instanceId: instanceId,
      defId: defId,
      quality: quality,
      aspect: aspect,
      socketed: List.unmodifiable(sockets),
      enchantId: enchantId,
    );
  }

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
