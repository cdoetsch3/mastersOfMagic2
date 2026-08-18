/// Showing an item: its generated icon if one exists, and otherwise **exactly
/// what the screen already showed**.
///
/// ⭐ **The pipeline ships before the paint**, the same way `ArenaBackdrop`
/// did. `assets/items/` is empty today, so every call site below is a no-op on
/// screen — which is the whole design goal. The day the maintainer runs
/// `tool/pixelate.py --mode icon`, icons appear in the backpack, the belt, the
/// Storeroom, the paper doll, the loot picker and the item dialog without one
/// more line of UI code.
///
/// ⚠️ **The fallback is passed IN, never invented here.** Six call sites show
/// an item six different ways — a 9px wrapped name in a grid tile, a single
/// initial in a 34px belt box, a drink glyph on the duel rail, an 8px rarity
/// swatch in a row. A widget that guessed at one of them would silently
/// redesign five screens the moment an icon failed to decode. See
/// `lib/ui/creature_art.dart`, which builds its fallback the same way.
library;

import 'package:flutter/material.dart';

import '../game/items/item_catalogue.dart';

/// Where an item's generated icon lives, if one has been made.
///
/// ⭐ **Zone-foldered, like `assets/creatures/<zone>/`, not flat like
/// `assets/backgrounds/`.** Fifty-two ids in one directory is a folder nobody
/// can review; per zone it is 18/9/8/9/8 and the quarter's shape is visible in
/// a directory listing. ⚠️ **No `manifest.json`.** The creature manifest earns
/// its keep because art arrives per zone and "the roster and the art agree" is
/// a claim worth checking; here `ItemCatalogue` already *is* that roster and
/// [ItemCatalogue.zoneOf] already *is* the index — a manifest could only
/// restate this expression. What is checked instead is the reverse, in
/// `test/item_icon_test.dart`: nothing in `assets/items/` is named for an item
/// or a zone that does not exist.
///
/// ⚠️ Returns null for an id no catalogue claims — a save written before a
/// content patch, exactly as `ItemCatalogue.tryById` treats it.
String? itemIconFor(String defId) {
  final zone = ItemCatalogue.zoneOf(defId);
  return zone == null ? null : 'assets/items/$zone/$defId.png';
}

/// An item's icon, or [fallback] when there is no PNG for it.
///
/// ⭐ **Falls back rather than failing**, and the fallback is what the screen
/// drew before this widget existed — so wiring `ItemIcon` in changes nothing
/// visible until art lands.
class ItemIcon extends StatelessWidget {
  final String defId;

  /// The icon's box, in logical pixels.
  ///
  /// ⚠️ **Null means "as large as the parent allows"** — used by the backpack
  /// tile, whose size is the grid's to decide and changes with the window. A
  /// hard number there would overflow the tile on a narrow phone; a hard
  /// number everywhere else is what keeps the swap layout-neutral.
  final double? size;

  /// Space to the right of the icon that **disappears with it**.
  ///
  /// ⭐ The trick that lets an icon be added to a row that has none today
  /// without reserving a gap forever. It is drawn as extra width on the image
  /// box with `Alignment.centerLeft`, so it is part of the image widget and
  /// the `errorBuilder` takes it away too. ⚠️ A `SizedBox` sibling would not:
  /// it survives the failed decode and every row on the screen shifts right by
  /// [gap] for art that is not there.
  final double gap;

  final Widget fallback;

  const ItemIcon({
    super.key,
    required this.defId,
    required this.fallback,
    this.size,
    this.gap = 0,
  }) : assert(
         gap == 0 || size != null,
         // ⚠️ The gap is drawn as extra width on a sized box. With no size
         // there is no box to widen, so it would vanish silently and the row
         // would render with the icon jammed against its label.
         'gap needs a size to hang off',
       );

  @override
  Widget build(BuildContext context) {
    final path = itemIconFor(defId);
    // ⚠️ Not an error, and not worth an Image that can only fail: an unknown
    // id has no zone, so there is no path to even ask for.
    if (path == null) return fallback;
    return Image.asset(
      path,
      width: size == null ? null : size! + gap,
      height: size,
      // ⭐ Contain, never cover: an icon cropped to fill its box loses the
      // silhouette the descriptions in docs/ITEM_ART.md are written around.
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      // ⭐ **Nearest-neighbour, always** — same reason as `CreatureView`. The
      // icons are 64px and shown between 8 and 40; a smooth filter turns
      // deliberate pixel art into a smudge.
      filterQuality: FilterQuality.none,
      // ⚠️ **The fallback also covers the LOADING frames, not just failure.**
      // An asset load is asynchronous even when it is going to fail, so an
      // `errorBuilder` alone leaves a frame (or several) of empty box before
      // the error arrives — and with `assets/items/` empty that is every item
      // on every inventory screen flashing blank on open. `frame == null` is
      // "nothing decoded yet", which is exactly when the screen should still
      // look like it did before this widget existed.
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
          wasSynchronouslyLoaded || frame != null ? child : fallback,
      // ⚠️ Not an error — assets/items/ is empty today, which is the state the
      // game actually ships in.
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
