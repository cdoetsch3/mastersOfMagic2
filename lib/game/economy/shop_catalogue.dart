/// The nine towns' general-shop stock tables and the mechanically-derived
/// location-price modifier (ECONOMY_CONTRACT.md §2, §4, §14b).
///
/// ⚠️ **Scope fence, read before touching this file**: this owns VALUES and
/// SHOP TABLES only. It does NOT own the pricing formula (§3: `base ×
/// clamp((E/stock)^0.5, 0.4, 2.5) × locationMod × eventMod`), the nightly
/// resupply loop (§6), the `config/economy` plumbing (§7), or any UI. Those
/// are separate builders' contracts; wiring them against wrong tables here is
/// a worse bug than leaving a seam unbuilt.
///
/// ⭐ **§14b's four rulings this file encodes:**
/// 1. Material values are audit-derived (ECONOMY_CONTRACT §8.2), authored on
///    the `ItemDef`s themselves (`lib/game/items/catalogue/*.dart`) — not
///    duplicated here.
/// 2. The four content-empty towns (Meridian, Rimeholt, Vespergate, Zenith)
///    are **closed** at launch — no import-placeholder shelves.
/// 3. Ingots (`bronze_ingot`, `iron_ingot`) are **never** shop stock —
///    smelting is Metalworking's reason to exist. Vendorable, never on a
///    shelf.
/// 4. Location modifiers are **mechanically derived from the travel graph**
///    (§4.1) — never a hand-filled per-cell table. [locationModFor] reads
///    only [World]'s edges and [ItemCatalogue]'s zone ownership; it does not
///    hard-code a single town/item pair.
library;

import '../items/item_catalogue.dart';
import '../items/item_def.dart';
import '../world.dart';

/// Whether a town's shop is trading.
///
/// ⚠️ §14b.2: **closed, not empty-catalogue.** A closed town has no shelf at
/// all, not an import-only placeholder — the distinction the contract's own
/// Decision 2 debated and Christian resolved against option (c).
enum ShopStatus { open, closedThisSeason }

/// §5.1's three E-category buckets, exposed so the (separately-owned)
/// pricing engine can look up `E` without re-deriving "is this native here."
///
/// ⚠️ **Consumable outranks native/imported.** A `ConsumableDef`/`BeltableDef`
/// is always [consumable] (E=30) regardless of which zone it's native to —
/// §5.1 states the three buckets are exhaustive and consumables are their own
/// bucket, not "a native or imported material that happens to be edible."
enum ShopItemCategory {
  /// A `MaterialDef` native to this town (one of its adjacent, shipped
  /// zones, §2.1/§4.1). E = 60.
  nativeMaterial,

  /// A `MaterialDef` not native to this town. E = 20.
  importedMaterial,

  /// A `ConsumableDef` or `BeltableDef`, any town. E = 30.
  consumable,
}

abstract final class ShopCatalogue {
  // ---- §14b.2: which towns are open --------------------------------------

  /// ✅ Five of nine towns are open at launch — the five whose adjacent
  /// zones (§2.1) have shipped `ItemCatalogue.byZone` content. The other
  /// four (Meridian, Rimeholt, Vespergate, Zenith) border zero shipped
  /// zones and are CLOSED, per §14b.2, not given import-only placeholders.
  static const Map<String, ShopStatus> status = {
    'hearthwood': ShopStatus.open,
    'pennycross': ShopStatus.open,
    'forgeholm': ShopStatus.open,
    'galehaven': ShopStatus.open,
    'concordance': ShopStatus.open,
    'meridian': ShopStatus.closedThisSeason,
    'rimeholt': ShopStatus.closedThisSeason,
    'vespergate': ShopStatus.closedThisSeason,
    'zenith': ShopStatus.closedThisSeason,
  };

  static bool isOpen(String townId) => status[townId] == ShopStatus.open;

  /// ⭐ §14b.2's own phrase, verbatim: the season-flavor hook for a closed
  /// town's shop door. One string, not per-town copy — the four towns are
  /// closed for the identical reason (no content, not a town-specific
  /// story), and a builder wiring the UI reads this rather than inventing
  /// four bespoke lines that could drift out of sync with each other.
  static const String closedFlavor =
      "The caravans haven't come this season.";

  // ---- §14b.3: ingots are never stock -------------------------------------

  /// ⚠️ **The one hand-authored exclusion list in this file**, because it is
  /// a *ruling* (§14b.3), not a fact derivable from the travel graph:
  /// Metalworking's crafted intermediates are vendorable but never shelved,
  /// so a player cannot buy past the ore-and-charcoal haul.
  static const Set<String> _neverStocked = {'bronze_ingot', 'iron_ingot'};

  static bool _isStockableKind(ItemDef def) =>
      def is MaterialDef || def is ConsumableDef || def is BeltableDef;

  // ---- native-zone stock, computed — not hand-typed ----------------------
  //
  // ⭐ §4.1's own warning generalizes past location mods: "306 cells hand-
  // tuned individually is exactly the kind of table that drifts." A town's
  // native item list is exactly as derivable from World+ItemCatalogue as its
  // location mod is, so it is computed here rather than typed out — the same
  // reasoning, applied to stock composition instead of pricing.

  /// The non-town zones directly reachable from [townId] — §2.1's "adjacent
  /// zone" definition, read straight off [GameLocation.edges].
  static Set<String> nativeZonesOf(String townId) {
    final town = World.byId(townId);
    return {for (final id in town.connections) if (!World.byId(id).isTown) id};
  }

  /// Every stockable id whose owning zone ([ItemCatalogue.zoneOf]) is native
  /// to [townId], per §2.3's "native stock" column — computed from the
  /// shipped catalogues, so a new zone or a new item in an existing zone
  /// enters a town's shelf automatically, the same way §4's location mods
  /// never need a hand edit when the graph changes.
  static List<String> nativeStockFor(String townId) {
    final zones = nativeZonesOf(townId);
    return [
      for (final zoneId in zones)
        if (ItemCatalogue.byZone.containsKey(zoneId))
          for (final def in ItemCatalogue.byZone[zoneId]!)
            if (_isStockableKind(def) && !_neverStocked.contains(def.id))
              def.id,
    ];
  }

  // ---- curated imports (§2.3's "small imported selection") ---------------
  //
  // ⚠️ **This part genuinely cannot be computed.** §2.3 is explicit that the
  // native columns are fixed by the graph but "the imports are the red-pen
  // target" — which zone's flavor a town chooses to import is a curatorial,
  // narrative call (Forgeholm imports Bronze's other two-thirds; Concordance
  // imports "a taste of everywhere" because it is the trade capital), not a
  // graph fact. Hand-authored on purpose; sized 2-8 per §2.3.

  static const Map<String, List<String>> _imports = {
    // ⭐ §2.3's worked table names only `birch_log` but sizes Hearthwood's
    // imports at 2 — `brookmint` (Ashfall Vale's other Q1-relevant material)
    // fills the second slot, keeping "a taste of Ashfall" coherent rather
    // than inventing an unrelated import. Flagged as a red-pen resolution,
    // not a contract-mandated id.
    'hearthwood': ['birch_log', 'brookmint'],

    // ✅ §2.3 verbatim: "bridges Hearthwood."
    'pennycross': ['oak_log', 'bindweed_fibre'],

    // ⭐ §2.3's load-bearing worked example (§4.2's own text calls this out
    // by name): Bronze needs copper_ore×2 + tin_ore×1 + charcoal×1; tin_ore
    // is already native here, so importing exactly the other two closes the
    // loop — "the Metalworking hub importing exactly what its own signature
    // recipe needs."
    'forgeholm': ['copper_ore', 'charcoal'],

    // ✅ §2.3 verbatim: "generic travel stock, the port sells what comes off
    // the boats."
    'galehaven': ['hardtack', 'brookmint_tonic'],

    // ✅ §2.3 verbatim: one representative material per built zone not
    // already native here — "value MOVES here, it is not made."
    'concordance': [
      'oak_log',
      'fawnhide',
      'bogflax_fibre',
      'birch_log',
      'tin_ore',
      'seawrack_fibre',
      'rowan_log',
    ],
  };

  /// The full catalogue (native + imports) for [townId] — empty for a closed
  /// town (§14b.2), never an import-only placeholder.
  static List<String> stockFor(String townId) {
    if (!isOpen(townId)) return const [];
    return [...nativeStockFor(townId), ...?_imports[townId]];
  }

  // ---- §5.1 category, for the (separately-owned) pricing engine ----------

  static ShopItemCategory categoryFor(String townId, String itemId) {
    final def = ItemCatalogue.byId(itemId);
    if (def is ConsumableDef || def is BeltableDef) {
      return ShopItemCategory.consumable;
    }
    return nativeZonesOf(townId).contains(ItemCatalogue.zoneOf(itemId))
        ? ShopItemCategory.nativeMaterial
        : ShopItemCategory.importedMaterial;
  }

  // ---- §4.1: the mechanically-derived location modifier -------------------

  static const double nativeMod = 0.75;
  static const double regionalMod = 0.90;
  static const double baselineMod = 1.00;
  static const double oneTierMod = 1.10;
  static const double exoticMod = 1.25;

  /// §4.1's five-row rule, read entirely off [World]'s graph and
  /// [ItemCatalogue.zoneOf] — ⚠️ **no per-(town, item) table**. Christian's
  /// ruling (§14b, "also confirmed") is explicit that a 9×34 hand-filled
  /// grid is the failure mode this function exists to avoid.
  ///
  /// Throws if [itemId] resolves to no zone (a bug — every stockable item is
  /// defined in exactly one zone catalogue, per [ItemCatalogue.zoneOf]).
  static double locationModFor(String townId, String itemId) {
    final zoneId = ItemCatalogue.zoneOf(itemId);
    if (zoneId == null) {
      throw ArgumentError('no zone owns item "$itemId"');
    }

    // Row 1 — native: itemZone is one of townId's own adjacent zones.
    final native = nativeZonesOf(townId);
    if (native.contains(zoneId)) return nativeMod;

    // Row 2 — regional: itemZone is adjacent to one of townId's adjacent
    // zones (a 2-hop, zone-to-zone walk), but not native itself.
    final regional = <String>{
      for (final nz in native)
        for (final id in World.byId(nz).connections)
          if (id != townId && !World.byId(id).isTown) id,
    };
    if (regional.contains(zoneId)) return regionalMod;

    // Rows 3-5 — tier-band distance. Same band: baseline. One band: import
    // surcharge. Two+ bands: the exotic cap.
    final townTier = World.byId(townId).tier;
    final itemTier = World.byId(zoneId).tier;
    if (townTier == null || itemTier == null) return baselineMod;
    if (itemTier == townTier) return baselineMod;
    final distance = (itemTier.index - townTier.index).abs();
    return distance == 1 ? oneTierMod : exoticMod;
  }
}
