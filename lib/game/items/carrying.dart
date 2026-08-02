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
enum Container {
  /// Unlimited, and ⚠️ **one per city, not a shared pool** (ITEMS §10.3c).
  /// What you leave in Aldermere is in Aldermere; moving it means carrying it.
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

  /// What a new character can bring into a duel, before progression and gear.
  static const int baseBeltSlots = 2;

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
  static bool accepts(Container where, ItemDef def) =>
      where != Container.belt || def is Beltable;
}
