/// Where a player's things can be, and how much fits.
///
/// ⭐ **Four containers with four jobs** (ITEMS_DESIGN §10.3b). The split is
/// what keeps each one meaningful: the backpack bounds a gathering run, the
/// belt is the only thing combat can reach, the mount is a road stat, and
/// the Storeroom is where everything else waits — ⚠️ **in the city you left it
/// in**.
library;

import 'item_def.dart';

/// The four places an item can be.
///
/// ⚠️ **Named `ItemContainer`, not `Container`.** Flutter's `Container` widget
/// is one of the most-used names in the framework, and a bare `Container` here
/// silently shadows it in every UI file that imports this library.
enum ItemContainer {
  /// Unlimited, and ⚠️ **one per city, not a shared pool** (ITEMS §10.3c).
  /// What you leave in Hearthwood is in Hearthwood; moving it means carrying it.
  ///
  /// ⭐ This is what makes mount cargo, Journey's cargo risk and the
  /// decentralised crafting stations structural rather than flavour.
  ///
  /// ✅ Named the **Storeroom**.
  storeroom,

  /// Carried everywhere. ⭐ The hard limit on an adventure, because the mount
  /// does not come along.
  backpack,

  /// ⭐ The only container reachable **during** combat.
  belt,

  /// ⚠️ **Travel only.** Companions do not enter zones (WORLD_DESIGN §4b.3).
  mount,
}

/// Capacities, in one place.
///
/// ⚠️ **Every capacity in the game is defined here and nowhere else.** These
/// are balance dials — the backpack in particular is expected to move (20 → 25
/// is a live possibility) — and a second copy anywhere would make the change a
/// hunt rather than an edit.
abstract final class Carrying {
  /// ✅ One item per slot, so twenty Oak Logs fill it (ITEMS §10.3a).
  static const int backpackSlots = 20;

  /// What a character can bring into a duel with **no belt worn**: nothing.
  ///
  /// ⚠️ **Zero, ruled 2026-08-17.** This was 2, and two slots that appeared out
  /// of nowhere read as a hardcoded bug rather than a rule — the paper doll
  /// offered belt space while the Belt slot sat empty, so the belt item that
  /// grants slots looked like it did nothing. Belt capacity now comes ONLY from
  /// a worn belt's `beltSlots` modifier (📝 plus progression, when that lands),
  /// which is what makes the Tuskhide Belt a real unlock instead of a +2 on top
  /// of a freebie.
  static const int baseBeltSlots = 0;

  /// ⚠️ The ceiling on belt growth. Past this, "which do I bring?" stops being
  /// a decision — which is the whole reason the belt is bounded.
  static const int maxBeltSlots = 10;

  /// ⭐ Deliberately unbounded. The Storeroom is where the pressure is
  /// *released*; bounding it too would make the game about inventory
  /// management. ⚠️ The scarcity is **which city it is in**, not how much fits.
  static const int? storeroomSlots = null;

  /// The belt a character actually has, clamped to the ceiling.
  static int beltSlotsFor({int fromProgression = 0, int fromGear = 0}) {
    final total = baseBeltSlots + fromProgression + fromGear;
    return total > maxBeltSlots ? maxBeltSlots : total;
  }

  /// Whether [def] is allowed in [where].
  ///
  /// ⭐ The one rule worth stating in code: **only Beltable things reach
  /// combat.** Everything else is a matter of space, not legality.
  static bool accepts(ItemContainer where, ItemDef def) =>
      where != ItemContainer.belt || def is Beltable;

  /// Why [def] cannot go on a belt of [capacity] already holding [used] —
  /// null means it can.
  ///
  /// ⭐ **One writer, two readers** (the shape `Equipping.refusal` already
  /// uses): `GameState.loadOntoBelt` refuses with these words, and the item
  /// dialog greys its button with the same ones. A screen that invented its own
  /// wording would eventually contradict what the action actually does.
  ///
  /// 📝 Space and legality only — whether the item is actually *in the pack* is
  /// the caller's business, because this function never sees a pack.
  static String? beltRefusal(
    ItemDef? def, {
    required int used,
    required int capacity,
  }) {
    if (def == null || !accepts(ItemContainer.belt, def)) {
      return 'Only belt items can be reached mid-duel.';
    }
    // ⚠️ Two refusals, not one. Zero capacity is a wardrobe problem (the
    // 2026-08-17 ruling: no belt, no slots); calling that "full" would send the
    // player looking for something to unload that does not exist.
    if (capacity == 0) return 'You are not wearing a belt.';
    if (used >= capacity) return 'Your belt is full.';
    return null;
  }
}
