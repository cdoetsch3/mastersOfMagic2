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
import 'item_catalogue.dart';
import 'item_def.dart';
import 'item_instance.dart';

/// The carried backpack — a fixed number of slots, one item each, ⭐ **except
/// Dust (25 a slot) and Shards (5 a slot)** — ruling, Christian 2026-09-25.
///
/// ⭐ **Not a count map.** Twenty Oak Logs fill it, which is what makes a
/// gathering run end when you are full rather than when you are bored, and
/// what makes mount cargo worth buying for the road. ⚠️ [free], [used] and
/// [isFull] are about SLOTS; "how many of X" is [countOf], and "would X fit"
/// is [roomFor] — with stacks, a full pack can still take more Dust.
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

  /// One entry per occupied SLOT — ⚠️ a stack of 12 Dust is one entry with
  /// `count` 12, not twelve. Sum `count` when the question is "how many".
  Iterable<InventorySlot> get contents => slots.whereType<InventorySlot>();

  /// How many of [defId] are carried — ⭐ **summed across stacks**, so 25 + 5
  /// Pyro Dust is 30. Every "have N" in the game reads this.
  int countOf(String defId) => contents
      .where((s) => s.defId == defId)
      .fold(0, (sum, s) => sum + s.count);

  /// How many slots [defId] occupies — the UI's "in 2 stacks", never a count
  /// of items (that is [countOf]).
  int stacksOf(String defId) => contents.where((s) => s.defId == defId).length;

  /// How many more of [defId] would fit: every free slot at a full stack, plus
  /// the headroom on the stacks already carried.
  ///
  /// ⭐ **The one room question for a stacking pack.** "Is there a free slot"
  /// was the right question when every item cost one; a full pack with a
  /// 20-stack of Pyro Dust still has room for five more, and a picker that
  /// said 'no room' to them would be lying.
  int roomFor(String defId) {
    final size = _stackSizeOf(defId);
    var room = free * size;
    for (final s in contents) {
      if (s.defId == defId && s.instanceId == null && s.count < size) {
        room += size - s.count;
      }
    }
    return room;
  }

  /// Puts [item] in the pack: ⭐ **topping up stacks of the same def first**
  /// (lowest count first, ruled 2026-09-25), then opening new slots, never
  /// letting a stack pass its def's `stackSize`. A `count: 30` Dust slot
  /// lands as 25 + 5.
  ///
  /// Returns null when the pack cannot take ALL of it — ⚠️ **the caller must
  /// handle that**, because silently dropping loot is the worst possible
  /// failure here. ⚠️ **All-or-nothing**: a partial add would leave the caller
  /// holding a remainder it never asked about, so on null nothing moved.
  Backpack? withAdded(InventorySlot item) {
    final next = [...slots];
    // ⚠️ A rolled item is one physical thing: never merged, never split.
    if (item.instanceId != null) {
      final i = next.indexOf(null);
      if (i < 0) return null;
      next[i] = item;
      return Backpack._(next);
    }
    final size = _stackSizeOf(item.defId);
    var remaining = item.count;
    // ⭐ Lowest count first, ties by position — the ruling's order, and the
    // mirror of [withRemovedFirst] taking from the smallest stack.
    final topUps =
        [
          for (var i = 0; i < next.length; i++)
            if (next[i] case final s?
                when s.defId == item.defId &&
                    s.instanceId == null &&
                    s.count >= 1 &&
                    s.count < size)
              i,
        ]..sort(
          (a, b) => next[a]!.count != next[b]!.count
              ? next[a]!.count - next[b]!.count
              : a - b,
        );
    for (final i in topUps) {
      if (remaining <= 0) break;
      final have = next[i]!.count;
      final take = size - have < remaining ? size - have : remaining;
      next[i] = next[i]!.withCount(have + take);
      remaining -= take;
    }
    while (remaining > 0) {
      final i = next.indexOf(null);
      if (i < 0) return null;
      final put = remaining < size ? remaining : size;
      next[i] = item.withCount(put);
      remaining -= put;
    }
    return Backpack._(next);
  }

  /// ⚠️ An id the catalogue no longer knows stacks to 1 — the cautious answer
  /// for a save a content patch moved out from under the player.
  static int _stackSizeOf(String defId) =>
      ItemCatalogue.tryById(defId)?.stackSize ?? 1;

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

  /// Empties the slot at [index] — ⚠️ **the whole stack**. This is Drop and
  /// Stow: the player pointed at a slot, and the slot is what goes.
  Backpack withRemovedAt(int index) {
    final next = [...slots];
    next[index] = null;
    return Backpack._(next);
  }

  /// Removes [n] of [defId], ⭐ **from the smallest stack first** (ruled
  /// 2026-09-25), emptying a slot when it reaches 0 — so taking 3 from
  /// [25, 5] leaves [25, 2], and the full stack is the last one broken.
  ///
  /// ⚠️ Removes what there is when there are fewer than [n]; the callers gate
  /// on [countOf] first, exactly as they did when this removed one slot.
  Backpack withRemovedFirst(String defId, {int n = 1}) {
    final next = [...slots];
    var left = n;
    while (left > 0) {
      var at = -1;
      for (var i = 0; i < next.length; i++) {
        final s = next[i];
        if (s == null || s.defId != defId) continue;
        if (at < 0 || s.count < next[at]!.count) at = i;
      }
      if (at < 0) break;
      final have = next[at]!.count;
      if (have <= left) {
        next[at] = null;
        // ⚠️ A corrupt 0-count slot is cleared without paying for anything.
        left -= have > 0 ? have : 0;
      } else {
        next[at] = next[at]!.withCount(have - left);
        left = 0;
      }
    }
    return Backpack._(next);
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

  /// Stores [item] — ⭐ **the whole slot**, so stowing a 12-stack of Dust adds
  /// 12 to the count, not 1.
  Storeroom withDeposited(InventorySlot item) {
    if (item.instanceId != null) {
      return Storeroom(
        stacks: stacks,
        instanceIds: [...instanceIds, item.instanceId!],
      );
    }
    return Storeroom(
      stacks: {...stacks, item.defId: (stacks[item.defId] ?? 0) + item.count},
      instanceIds: instanceIds,
    );
  }

  /// Takes [want] back out — `want.count` of it — symmetric with
  /// [withDeposited]. The pack forms the stacks on the way in
  /// (`Backpack.withAdded`).
  ///
  /// Returns `taken: null` when the Storeroom does not hold that many — ⚠️
  /// never fabricates the item, because a withdraw that always succeeds is a
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
    if (have == 0 || want.count < 1 || have < want.count) {
      return (room: this, taken: null);
    }
    final next = {...stacks};
    if (have == want.count) {
      next.remove(want.defId);
    } else {
      next[want.defId] = have - want.count;
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
