/// Quality's effect on an item's **gold value** (ECONOMY_CONTRACT §14d,
/// ruling 1, Christian 2026-08-26).
///
/// ⭐ **One seam, deliberately tiny.** The contract had already ruled that a
/// crafted item's vendor value rides the same ×0.8 / ×1.0 / ×1.2 / ×1.4 ladder
/// as its stats; this file is that ruling made executable. Everything that
/// prices a non-fungible item reads [qualityValue] (or [instanceVendorPrice],
/// which composes it with the sink rate) — never `def.value` directly.
///
/// ⚠️ **Why the seam and not two call sites doing the same multiply.** The
/// Shop screen renders a gear row's price, and `GameState.priceShopBasket`
/// computes what Settle actually pays. Before this file those were two
/// independent `ShopPricing.vendorPrice(def.value)` expressions, and the
/// moment one of them learned about quality and the other did not, a player
/// would be shown one number and paid another. [instanceVendorPrice] is the
/// single expression both of them now call, so that drift is not merely
/// unlikely — it is unrepresentable.
///
/// 📝 **The player market will price from here too.** On the future
/// player-to-player market, quality makes an item a DISTINCT listing (a Master
/// Oak Wand and a Rough Oak Wand are not the same row, and must not stack into
/// one order book). [qualityValue] is the function that market will read to
/// anchor each of those listings — which is why it returns a *value*, not a
/// finished vendor price: the sink rate is one consumer of it, not its
/// definition.
library;

import '../items/item_def.dart';
import '../items/item_instance.dart';
import 'shop_pricing.dart';

/// [def]'s gold value **as this particular instance's quality roll made it**.
///
/// ⭐ **The same ladder as stats, by construction.** The multiplier is
/// [Quality.statPercent] — the exact getter `ItemModifiers.scaledBy` uses —
/// not a second copy of `80/100/120/140` living in the economy layer. Retuning
/// the ladder is one edit, and stats and prices cannot end up on different
/// rungs.
///
/// ⭐ **Null quality is Standard, ×1.00** — same reading as
/// [ItemModifiers.scaledBy]. A dropped item rolls an aspect rather than a
/// quality, and every instance minted before the 2026-08-18 ruling has no
/// field at all; both must keep exactly the gold they have always been worth,
/// so old instances do not move by a single coin.
///
/// ⚠️ **Integer arithmetic, round-half-away-from-zero** — `(v * pct + 50) ~/
/// 100`, matching both [ShopPricing.roundGold]'s rule and `scaledBy`'s
/// implementation. Not `(v * 1.4).round()`: binary floating point makes
/// `12 * 1.4` come out `16.799999999999997`, and a price that rounds down on
/// some values and not others is the kind of off-by-one nobody can reproduce.
/// The negative branch is carried for symmetry with `scaledBy` even though no
/// [ItemDef.value] is negative today — a guard costs nothing and a silent
/// asymmetry costs an afternoon.
int qualityValue(ItemDef def, ItemInstance? instance) {
  final quality = instance?.quality;
  if (quality == null || quality == Quality.standard) return def.value;
  final pct = quality.statPercent;
  final v = def.value;
  return (v * pct + (v < 0 ? -50 : 50)) ~/ 100;
}

/// The flat vendor-sink price for one non-fungible item (§2.4 ruling 3's
/// `base × 0.6`), with §14d ruling 1's quality ladder folded into the base
/// first.
///
/// ⭐ **This is the one seam both the Shop screen's gear row and
/// `GameState.priceShopBasket`'s instance walk call.** See the library doc: a
/// row that displayed a different number from what Settle paid is the exact
/// mutant this function's existence kills.
///
/// ⚠️ **Two roundings, on purpose, in this order**: [qualityValue] rounds the
/// quality-scaled value to whole gold, then [ShopPricing.vendorPrice] rounds
/// the sink. The intermediate is what the item is *worth* — a real quantity
/// the player market will also quote — so it is a whole number before anything
/// takes a fraction of it, rather than a float threaded through two multiplies.
int instanceVendorPrice(ItemDef def, ItemInstance? instance) =>
    ShopPricing.vendorPrice(qualityValue(def, instance));
