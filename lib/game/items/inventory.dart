/// The containers a character actually owns things in.
///
/// ⭐ **Instances live in one pool, and containers hold ids** (ITEMS §10.3a).
/// A staff moved from the backpack to a Storeroom must be the *same* staff —
/// same quality, same sockets — so the instance cannot live inside whichever
/// container currently names it. ⚠️ The cost is that a dangling id is possible;
/// `PlayerProfile` guards against it and a test asserts it.
library;

import 'package:flutter/foundation.dart';

import 'carrying.dart';
import 'item_def.dart';
import 'item_instance.dart';

/// The carried backpack — a fixed number of slots, one item each.
///
/// ⭐ **Not a count map.** Twenty Oak Logs fill it, which is what makes a
/// gathering run end when you are full rather than when you are bored, and
/// what makes mount cargo worth buying for the road.
@immutable
class Backpack {
  /// Always [Carrying.backpackSlots] long. `null` is an empty slot.
  final List<InventorySlot?> slots;

  const Backpack._(this.slots);

  factory Backpack.empty() =>
      Backpack._(List.filled(Carrying.backpackSlots, null));

  factory Backpack.of(List<InventorySlot?> items) {
    final padded = List<InventorySlot?>.filled(Carrying.backpackSlots, null);
    for (var i = 0; i < items.length && i < padded.length; i++) {
      padded[i] = items[i];
    }
    return Backpack._(padded);
  }

  int get used => slots.where((s) => s != null).length;
  int get free => slots.length - used;
  bool get isFull => free == 0;

  Iterable<InventorySlot> get contents => slots.whereType<InventorySlot>();

  /// How many of [defId] are carried. ⚠️ Counts *slots*, not a stack.
  int countOf(String defId) => contents.where((s) => s.defId == defId).length;

  /// Puts [item] in the first free slot.
  ///
  /// Returns null when the pack is full — ⚠️ **the caller must handle that**,
  /// because silently dropping loot is the worst possible failure here.
  Backpack? withAdded(InventorySlot item) {
    final i = slots.indexOf(null);
    if (i < 0) return null;
    final next = [...slots];
    next[i] = item;
    return Backpack._(next);
  }

  /// Adds as many of [items] as fit, and reports what did not.
  ({Backpack pack, List<InventorySlot> overflow}) withAll(
    List<InventorySlot> items,
  ) {
    var pack = this;
    final overflow = <InventorySlot>[];
    for (final item in items) {
      final next = pack.withAdded(item);
      if (next == null) {
        overflow.add(item);
      } else {
        pack = next;
      }
    }
    return (pack: pack, overflow: overflow);
  }

  Backpack withRemovedAt(int index) {
    final next = [...slots];
    next[index] = null;
    return Backpack._(next);
  }

  /// Removes the first slot holding [defId], if any.
  Backpack withRemovedFirst(String defId) {
    final i = slots.indexWhere((s) => s?.defId == defId);
    return i < 0 ? this : withRemovedAt(i);
  }

  List<Map<String, dynamic>?> toJson() => [for (final s in slots) s?.toJson()];

  factory Backpack.fromJson(List<dynamic>? json) {
    if (json == null) return Backpack.empty();
    return Backpack.of([
      for (final e in json)
        e == null ? null : InventorySlot.fromJson(e as Map<String, dynamic>),
    ]);
  }
}

/// One city's Storeroom (ITEMS §10.3c).
///
/// ⚠️ **Per city, never a shared pool.** What you leave in Hearthwood is in
/// Hearthwood; moving it means carrying it. ⭐ That is what makes mount cargo,
/// Journey's cargo risk and the decentralised crafting stations structural
/// rather than flavour.
@immutable
class Storeroom {
  /// Fungible goods collapse to counts — the Storeroom is where slot pressure
  /// is released, so there is no reason to spend a slot per log here.
  final Map<String, int> stacks;

  /// Non-fungibles, by instance id. Each is a distinct physical thing.
  final List<String> instanceIds;

  const Storeroom({this.stacks = const {}, this.instanceIds = const []});

  bool get isEmpty => stacks.isEmpty && instanceIds.isEmpty;

  /// Total distinct things held, for a UI summary.
  int get itemCount =>
      stacks.values.fold(0, (a, b) => a + b) + instanceIds.length;

  Storeroom withDeposited(InventorySlot item) {
    if (item.instanceId != null) {
      return Storeroom(
        stacks: stacks,
        instanceIds: [...instanceIds, item.instanceId!],
      );
    }
    return Storeroom(
      stacks: {...stacks, item.defId: (stacks[item.defId] ?? 0) + 1},
      instanceIds: instanceIds,
    );
  }

  /// Takes [want] back out, symmetric with [withDeposited].
  ///
  /// Returns `taken: null` when the Storeroom does not hold it — ⚠️ never
  /// fabricates the item, because a withdraw that always succeeds is a
  /// duplication bug waiting to be found by a player rather than a test.
  ({Storeroom room, InventorySlot? taken}) withWithdrawn(InventorySlot want) {
    if (want.instanceId != null) {
      if (!instanceIds.contains(want.instanceId)) {
        return (room: this, taken: null);
      }
      final rest = [...instanceIds]..remove(want.instanceId);
      return (room: Storeroom(stacks: stacks, instanceIds: rest), taken: want);
    }
    final have = stacks[want.defId] ?? 0;
    if (have == 0) return (room: this, taken: null);
    final next = {...stacks};
    if (have == 1) {
      next.remove(want.defId);
    } else {
      next[want.defId] = have - 1;
    }
    return (
      room: Storeroom(stacks: next, instanceIds: instanceIds),
      taken: want,
    );
  }

  Map<String, dynamic> toJson() => {
    if (stacks.isNotEmpty) 'stacks': stacks,
    if (instanceIds.isNotEmpty) 'instanceIds': instanceIds,
  };

  factory Storeroom.fromJson(Map<String, dynamic>? json) => Storeroom(
    stacks:
        (json?['stacks'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ) ??
        const {},
    instanceIds: (json?['instanceIds'] as List?)?.cast<String>() ?? const [],
  );
}

/// What a character can reach during a duel.
///
/// ⭐ Loaded from the backpack before or at the start of combat, and ⚠️ **using
/// one spends the turn** (ITEMS §10.3b) — which is what makes a potion a
/// decision rather than a tax.
@immutable
class Belt {
  /// Def ids, one per slot. Beltable items only.
  final List<String> loaded;

  const Belt({this.loaded = const []});

  int get used => loaded.length;

  /// Whether [def] may be loaded, given a belt of [capacity].
  bool canLoad(ItemDef def, int capacity) =>
      def is Beltable && loaded.length < capacity;

  Belt withLoaded(String defId) => Belt(loaded: [...loaded, defId]);

  Belt withUnloaded(String defId) {
    final next = [...loaded]..remove(defId);
    return Belt(loaded: next);
  }

  List<String> toJson() => loaded;

  factory Belt.fromJson(List<dynamic>? json) =>
      Belt(loaded: json?.cast<String>() ?? const []);
}
