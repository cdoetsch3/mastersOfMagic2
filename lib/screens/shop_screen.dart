import 'package:flutter/material.dart';

import '../game/economy/shop_catalogue.dart';
import '../game/economy/shop_pricing.dart';
import '../game/economy/shop_state.dart';
import '../game/game_state.dart';
import '../game/items/inventory.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/world.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import '../ui/item_icon.dart';

/// The town general shop (`ECONOMY_CONTRACT.md` §2/§3/§6/§14b) — reached
/// from the Inventory tab beside its town's Storeroom, the same door.
///
/// ⭐ **In-town trades are shop⇄Storeroom, never the backpack** (§14b's
/// build-wave addition) — buying puts goods straight in the local Storeroom,
/// selling draws from it first. The backpack only matters for HAULING goods
/// between towns, which this screen has no part in.
///
/// ⭐ **A basket, settled once — the designer's ruled transaction model.**
/// Every −/+ stepper on either tab only edits an in-memory basket
/// ([_buy]/[_sellStacks]/[_sellInstances]); nothing debits gold, moves
/// stock, or touches the Storeroom until [_settle] fires [GameState
/// .settleShopBasket] as one atomic mutation. Popping the route with a
/// non-empty basket discards it silently — there is nothing to undo because
/// nothing was ever written.
///
/// ⚠️ **`today` is computed once, at open, and threaded through** — the one
/// clock read on this whole path (`ShopState.epochDayOf(GameState.now())` in
/// [initState], via the same injectable clock every other GameState-driven
/// screen uses). Every price on this screen is quoted against that `int`
/// rather than the wall clock, so a test can pin "today" by injecting
/// `GameState`'s own `now`.
class ShopScreen extends StatefulWidget {
  final String townId;
  const ShopScreen({super.key, required this.townId});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

enum _ShopTab { buy, sell }

class _ShopScreenState extends State<ShopScreen> {
  late final int _today;
  var _tab = _ShopTab.buy;

  /// Pending buy quantities, keyed by item id. Zero-valued entries are
  /// pruned immediately (see [_setBuy]) so `.isEmpty` is a reliable "basket
  /// has no buys" check.
  final Map<String, int> _buy = {};

  /// Pending sell quantities for fungible stacks, keyed by item id.
  final Map<String, int> _sellStacks = {};

  /// Gear instances staged for sale — a toggle, not a stepper, since one
  /// instance is one unit by construction.
  final Set<String> _sellInstances = {};

  bool get _basketEmpty =>
      _buy.isEmpty && _sellStacks.isEmpty && _sellInstances.isEmpty;

  @override
  void initState() {
    super.initState();
    // ⭐ Reads [GameState.now] — the same injectable clock every other
    // GameState-driven screen already uses — rather than `DateTime.now()`
    // directly, so a test can pin "today" by constructing `GameState(...,
    // now: () => fixedDate)` instead of faking the wall clock. Safe to call
    // synchronously here: `GameStateScope` sits above the `Navigator`
    // (`main.dart`), so the ancestor is already mounted by the time this
    // pushed route's `initState` runs.
    final game = GameStateScope.read(context);
    _today = ShopState.epochDayOf(game.now());
    // Resolves the nightly catch-up (§6.1) and persists it before any price
    // on this screen is trusted — scheduled for the frame after this one, the
    // same way `MatchmakingScreen` defers its own opening intent, so the
    // first build never races the mutate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameStateScope.read(context).resolveShop(widget.townId, _today);
    });
  }

  void _setBuy(String itemId, int v) => setState(() {
    if (v <= 0) {
      _buy.remove(itemId);
    } else {
      _buy[itemId] = v;
    }
  });

  void _setSellStack(String itemId, int v) => setState(() {
    if (v <= 0) {
      _sellStacks.remove(itemId);
    } else {
      _sellStacks[itemId] = v;
    }
  });

  void _toggleSellInstance(String instanceId) => setState(() {
    if (!_sellInstances.remove(instanceId)) _sellInstances.add(instanceId);
  });

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final town = World.byId(widget.townId);

    // ⚠️ Defensive, not the primary gate — the Inventory tab only offers the
    // door to an open town (§14b.2), but a stale route or a deep link should
    // read the same closed door rather than a broken shop.
    if (!ShopCatalogue.isOpen(widget.townId)) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.panel, title: Text(town.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              ShopCatalogue.closedFlavor,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final quote = game.priceShopBasket(
      townId: widget.townId,
      today: _today,
      buy: _buy,
      sellStacks: _sellStacks,
      sellInstances: _sellInstances,
    );
    final blockReason = game.shopBasketBlockReason(
      townId: widget.townId,
      today: _today,
      buy: _buy,
      sellStacks: _sellStacks,
      sellInstances: _sellInstances,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${town.name} Shop'),
            const Text(
              'stock resupplies nightly',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: _GoldPill(gold: game.profile.gold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Buy',
                    on: _tab == _ShopTab.buy,
                    onTap: () => setState(() => _tab = _ShopTab.buy),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Sell',
                    on: _tab == _ShopTab.sell,
                    onTap: () => setState(() => _tab = _ShopTab.sell),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == _ShopTab.buy
                  ? _BuyList(
                      game: game,
                      townId: widget.townId,
                      today: _today,
                      qty: _buy,
                      quote: quote,
                      onQtyChanged: _setBuy,
                    )
                  : _SellList(
                      game: game,
                      townId: widget.townId,
                      today: _today,
                      stackQty: _sellStacks,
                      quote: quote,
                      onStackQtyChanged: _setSellStack,
                      selectedInstances: _sellInstances,
                      onInstanceToggled: _toggleSellInstance,
                    ),
            ),
            if (!_basketEmpty)
              _SettleBar(
                quote: quote,
                summary: _summary(quote),
                blockReason: blockReason,
                onSettle: blockReason == null ? _settle : null,
              ),
          ],
        ),
      ),
    );
  }

  /// 'buy 5 oak (57g) · sell 10 bindweed (76g)' — named when a direction is
  /// exactly one kind, otherwise a plain count so the line never overflows.
  String _summary(ShopBasketQuote quote) {
    final parts = <String>[];
    final buyIds = _buy.keys.where((id) => (_buy[id] ?? 0) > 0).toList();
    if (buyIds.isNotEmpty) {
      final n = buyIds.fold<int>(0, (a, id) => a + _buy[id]!);
      final label = buyIds.length == 1
          ? _lower(buyIds.first)
          : '${buyIds.length} kinds';
      parts.add('buy $n $label (${quote.buyGold}g)');
    }
    final sellKinds =
        _sellStacks.keys.where((id) => (_sellStacks[id] ?? 0) > 0).length +
        _sellInstances.length;
    if (sellKinds > 0) {
      final n =
          _sellStacks.values.fold<int>(0, (a, v) => a + v) +
          _sellInstances.length;
      final onlyStack =
          _sellInstances.isEmpty &&
          _sellStacks.keys.where((id) => (_sellStacks[id] ?? 0) > 0).length ==
              1;
      final label = onlyStack
          ? _lower(
              _sellStacks.keys.firstWhere((id) => (_sellStacks[id] ?? 0) > 0),
            )
          : '$sellKinds kinds';
      parts.add('sell $n $label (${quote.sellGold}g)');
    }
    return parts.join(' · ');
  }

  String _lower(String itemId) {
    final def = ItemCatalogue.tryById(itemId);
    return def == null ? itemId : ItemCatalogue.displayName(def).toLowerCase();
  }

  Future<void> _settle() async {
    final messenger = ScaffoldMessenger.of(context);
    final game = GameStateScope.read(context);
    final outcome = await game.settleShopBasket(
      townId: widget.townId,
      today: _today,
      buy: _buy,
      sellStacks: _sellStacks,
      sellInstances: _sellInstances,
    );
    if (!outcome.succeeded) {
      messenger.showSnackBar(SnackBar(content: Text(outcome.refusal!)));
      return;
    }
    setState(() {
      _buy.clear();
      _sellStacks.clear();
      _sellInstances.clear();
    });
    final net = outcome.net;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          net >= 0
              ? 'Settled — netted ${net}g.'
              : 'Settled — spent ${-net}g.',
        ),
      ),
    );
  }
}

// ---- shared chrome ---------------------------------------------------------

class _GoldPill extends StatelessWidget {
  final int gold;
  const _GoldPill({required this.gold});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.panelHi,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderDim),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CoinIcon(size: 15),
        const SizedBox(width: 5),
        Text(
          '$gold',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// ⚠️ Hand-rolled rather than a stock chip — matches `CraftScreen._Chip`'s
/// bordered teal-on-panel shape exactly, so a Buy/Sell toggle reads as the
/// same control family as every other filter pill in the app.
class _TabChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.bg : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.teal : Colors.transparent,
          border: Border.all(color: on ? AppColors.teal : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Spike/sale chip — shown only when `eventMod != 1.0` (§6.2).
class _EventChip extends StatelessWidget {
  final double eventMod;
  const _EventChip({required this.eventMod});

  @override
  Widget build(BuildContext context) {
    final spike = eventMod > 1.0;
    final pct = ((eventMod - 1.0).abs() * 100).round();
    final colour = spike ? AppColors.ember : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        border: Border.all(color: colour),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        spike ? 'Price spike +$pct%' : 'Price drop −$pct%',
        style: TextStyle(color: colour, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The location-modifier note shown as a row's muted subline — §4.1's
/// five-row rule, read back in words rather than a bare multiplier.
String locationModLabel(double mod) {
  if (mod == ShopCatalogue.nativeMod) return 'native (−25%)';
  if (mod == ShopCatalogue.regionalMod) return 'regional (−10%)';
  if (mod == ShopCatalogue.baselineMod) return 'standard';
  if (mod == ShopCatalogue.oneTierMod) return 'imported (+10%)';
  return 'exotic (+25%)';
}

/// A `-`/count/`+` quantity control, bounded to `[min, max]`.
class _QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;

  /// Null disables the whole control — e.g. an out-of-stock item.
  final ValueChanged<int>? onChanged;

  const _QtyStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _StepButton(
        icon: Icons.remove,
        onTap: onChanged == null || value <= min
            ? null
            : () => onChanged!(value - 1),
      ),
      SizedBox(
        width: 26,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
        ),
      ),
      _StepButton(
        icon: Icons.add,
        onTap: onChanged == null || value >= max
            ? null
            : () => onChanged!(value + 1),
      ),
    ],
  );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color: onTap == null ? AppColors.borderDim : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 14,
        color: onTap == null ? AppColors.textFaint : AppColors.text,
      ),
    ),
  );
}

/// A gold-chip total — shown on a row only once its basket quantity is > 0.
class _GoldChip extends StatelessWidget {
  final int gold;
  const _GoldChip({required this.gold});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.15),
      border: Border.all(color: AppColors.gold),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${gold}g',
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ---- Buy tab ----------------------------------------------------------

class _BuyList extends StatelessWidget {
  final GameState game;
  final String townId;
  final int today;
  final Map<String, int> qty;
  final ShopBasketQuote quote;
  final void Function(String itemId, int value) onQtyChanged;

  const _BuyList({
    required this.game,
    required this.townId,
    required this.today,
    required this.qty,
    required this.quote,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = ShopCatalogue.stockFor(townId);
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Nothing on the shelf.',
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        for (final id in items)
          _BuyRow(
            game: game,
            townId: townId,
            itemId: id,
            today: today,
            qty: qty[id] ?? 0,
            total: quote.buyGoldOf[id],
            onQtyChanged: (v) => onQtyChanged(id, v),
          ),
      ],
    );
  }
}

class _BuyRow extends StatelessWidget {
  final GameState game;
  final String townId;
  final String itemId;
  final int today;
  final int qty;

  /// This row's running total from the screen's one [ShopBasketQuote] — null
  /// when the item has no pending buy. ⭐ Read, never recomputed here: the row
  /// and the settle bar must always agree on the same number.
  final int? total;
  final ValueChanged<int> onQtyChanged;

  const _BuyRow({
    required this.game,
    required this.townId,
    required this.itemId,
    required this.today,
    required this.qty,
    required this.total,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(itemId);
    if (def == null) return const SizedBox.shrink();
    final name = ItemCatalogue.displayName(def);
    final state = game.profile.shopStock[townId];
    final equilibrium = game.shopEquilibriumFor(townId, itemId);
    final stock = state?.stockOf(itemId) ?? equilibrium;
    final locationMod = game.shopLocationModFor(townId, itemId);
    final eventMod = game.shopEventsFor(townId, today)[itemId] ?? 1.0;
    final unit = ShopPricing.roundGold(
      ShopPricing.buyPrice(
        base: def.value,
        equilibrium: equilibrium,
        stock: stock,
        locationMod: locationMod,
        eventMod: eventMod,
      ),
    );
    // ⚠️ Bounded to persisted stock — the basket-pricing walk always prices
    // a buy line against `profile.shopStock` as it stands right now (see
    // `GameState.priceShopBasket`'s doc), so the stepper's ceiling must
    // agree with what settling would actually accept.
    final max = stock < 0 ? 0 : stock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ItemIcon(
                  defId: itemId,
                  size: 18,
                  gap: 8,
                  fallback: const SizedBox.shrink(),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: rarityColour(def.rarity),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Stock $stock',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  locationModLabel(locationMod),
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  '${unit}g each',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
                if (eventMod != 1.0) ...[
                  const SizedBox(width: 6),
                  _EventChip(eventMod: eventMod),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QtyStepper(
                  value: qty,
                  min: 0,
                  max: max,
                  onChanged: max <= 0 ? null : onQtyChanged,
                ),
                const Spacer(),
                if (qty > 0 && total != null) _GoldChip(gold: total!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Sell tab ---------------------------------------------------------

class _SellList extends StatelessWidget {
  final GameState game;
  final String townId;
  final int today;
  final Map<String, int> stackQty;
  final ShopBasketQuote quote;
  final void Function(String itemId, int value) onStackQtyChanged;
  final Set<String> selectedInstances;
  final ValueChanged<String> onInstanceToggled;

  const _SellList({
    required this.game,
    required this.townId,
    required this.today,
    required this.stackQty,
    required this.quote,
    required this.onStackQtyChanged,
    required this.selectedInstances,
    required this.onInstanceToggled,
  });

  @override
  Widget build(BuildContext context) {
    final room = game.profile.storerooms[townId] ?? const Storeroom();
    final pack = game.profile.backpack;

    // ⭐ Sellable = the union of the local Storeroom and the backpack — a
    // fungible stack merges counts from both; a gear instance is wherever it
    // physically sits, one row each.
    final fungibleIds = <String>{...room.stacks.keys};
    for (final slot in pack.contents) {
      if (slot.instanceId == null) fungibleIds.add(slot.defId);
    }
    final stackIds =
        fungibleIds.where((id) {
          final def = ItemCatalogue.tryById(id);
          return def != null && (room.stacks[id] ?? 0) + pack.countOf(id) > 0;
        }).toList()
          ..sort((a, b) {
            final da = ItemCatalogue.displayName(ItemCatalogue.byId(a));
            final db = ItemCatalogue.displayName(ItemCatalogue.byId(b));
            return da.compareTo(db);
          });

    final instances = <(String instanceId, String defId)>[
      for (final id in room.instanceIds)
        (id, game.profile.itemInstances[id]?.defId ?? id),
      for (final slot in pack.contents)
        if (slot.instanceId != null) (slot.instanceId!, slot.defId),
    ];

    if (stackIds.isEmpty && instances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Nothing to sell — your Storeroom and pack are empty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        if (stackIds.isNotEmpty) ...[
          const SectionLabel('Materials & consumables'),
          for (final id in stackIds)
            _SellStackRow(
              game: game,
              townId: townId,
              itemId: id,
              today: today,
              available: (room.stacks[id] ?? 0) + pack.countOf(id),
              qty: stackQty[id] ?? 0,
              total: quote.sellGoldOf[id],
              onQtyChanged: (v) => onStackQtyChanged(id, v),
            ),
          const SizedBox(height: 8),
        ],
        if (instances.isNotEmpty) ...[
          const SectionLabel('Gear'),
          for (final e in instances)
            _SellInstanceRow(
              game: game,
              instanceId: e.$1,
              defId: e.$2,
              selected: selectedInstances.contains(e.$1),
              total: quote.instanceGoldOf[e.$1],
              onToggled: () => onInstanceToggled(e.$1),
            ),
        ],
      ],
    );
  }
}

class _SellStackRow extends StatelessWidget {
  final GameState game;
  final String townId;
  final String itemId;
  final int today;
  final int available;
  final int qty;

  /// This row's running total from the screen's one [ShopBasketQuote] —
  /// ⭐ already priced *after* any pending buy of the same item (the
  /// build brief's "per item: buys then sells" fixed order), so a basket
  /// that both buys and sells the same item never shows two numbers that
  /// disagree with what Settle will actually charge.
  final int? total;
  final ValueChanged<int> onQtyChanged;

  const _SellStackRow({
    required this.game,
    required this.townId,
    required this.itemId,
    required this.today,
    required this.available,
    required this.qty,
    required this.total,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(itemId);
    if (def == null) return const SizedBox.shrink();
    final name = ItemCatalogue.displayName(def);
    final bound = def.tradability == Tradability.bound;
    final stocked = ShopCatalogue.stockFor(townId).contains(itemId);
    final max = available < 0 ? 0 : available;

    int unit;
    if (stocked) {
      final state = game.profile.shopStock[townId];
      final equilibrium = game.shopEquilibriumFor(townId, itemId);
      final stock = state?.stockOf(itemId) ?? equilibrium;
      final locationMod = game.shopLocationModFor(townId, itemId);
      final eventMod = game.shopEventsFor(townId, today)[itemId] ?? 1.0;
      unit = ShopPricing.roundGold(
        ShopPricing.sellPrice(
          base: def.value,
          equilibrium: equilibrium,
          stock: stock,
          locationMod: locationMod,
          eventMod: eventMod,
        ),
      );
    } else {
      unit = ShopPricing.vendorPrice(def.value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ItemIcon(
                  defId: itemId,
                  size: 18,
                  gap: 8,
                  fallback: const SizedBox.shrink(),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: rarityColour(def.rarity),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Have $available',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              bound
                  ? 'Bound — cannot be sold.'
                  : stocked
                  ? '${unit}g each'
                  : '${unit}g each · vendor (flat)',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QtyStepper(
                  value: qty,
                  min: 0,
                  max: max,
                  onChanged: bound || max <= 0 ? null : onQtyChanged,
                ),
                const Spacer(),
                if (qty > 0 && total != null) _GoldChip(gold: total!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SellInstanceRow extends StatelessWidget {
  final GameState game;
  final String instanceId;
  final String defId;
  final bool selected;

  /// This row's total from the screen's one [ShopBasketQuote] — non-null
  /// exactly when [selected] (§ single-source-of-truth, same as the stack
  /// rows above).
  final int? total;
  final VoidCallback onToggled;

  const _SellInstanceRow({
    required this.game,
    required this.instanceId,
    required this.defId,
    required this.selected,
    required this.total,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(defId);
    final instance = game.profile.itemInstances[instanceId];
    final name = def == null ? defId : ItemCatalogue.displayName(def, instance);
    final bound = def?.tradability == Tradability.bound;
    final unit = def == null ? 0 : ShopPricing.vendorPrice(def.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        child: Row(
          children: [
            ItemIcon(
              defId: defId,
              size: 18,
              gap: 8,
              fallback: const SizedBox.shrink(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: def == null ? AppColors.text : rarityColour(def.rarity),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    bound ? 'Bound — cannot be sold.' : '${unit}g · vendor (flat)',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected && !bound && total != null) ...[
              _GoldChip(gold: total!),
              const SizedBox(width: 8),
            ],
            OutlinedButton(
              onPressed: bound ? null : onToggled,
              style: OutlinedButton.styleFrom(
                foregroundColor: selected ? AppColors.gold : AppColors.text,
                side: BorderSide(
                  color: selected ? AppColors.gold : AppColors.border,
                ),
              ),
              child: Text(selected ? 'In basket' : 'Sell'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Settle bar -------------------------------------------------------

/// The persistent bottom bar (build brief's "TRANSACTION MODEL"): visible
/// whenever the basket is non-empty, summarising both directions and
/// charging exactly [ShopBasketQuote.net] when [onSettle] fires.
class _SettleBar extends StatelessWidget {
  final ShopBasketQuote quote;
  final String summary;
  final String? blockReason;
  final VoidCallback? onSettle;

  const _SettleBar({
    required this.quote,
    required this.summary,
    required this.blockReason,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final net = quote.net;
    final netColour = net < 0 ? AppColors.ember : AppColors.gold;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (blockReason != null)
                Expanded(
                  child: Text(
                    blockReason!,
                    style: const TextStyle(color: AppColors.ember, fontSize: 11.5),
                  ),
                )
              else
                const Spacer(),
              FilledButton(
                onPressed: onSettle,
                style: FilledButton.styleFrom(
                  backgroundColor: netColour,
                  foregroundColor: AppColors.bg,
                ),
                child: Text('Settle ${net >= 0 ? '+' : ''}${net}g'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
