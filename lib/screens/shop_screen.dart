import 'dart:async';

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
                onReviewBasket: _openBasketReview,
              ),
          ],
        ),
      ),
    );
  }

  /// 'Buying 6 items −24g · Selling 7 items +105g' — the designer's ruled
  /// wording (2026-08-25 UI pass, point 5): counts and signed gold, never
  /// the old 'buy 6 2 kinds' shorthand that read like a typo.
  String _summary(ShopBasketQuote quote) {
    final parts = <String>[];
    final buyN = _buy.values.fold<int>(0, (a, v) => a + v);
    if (buyN > 0) {
      parts.add('Buying $buyN item${buyN == 1 ? '' : 's'} −${quote.buyGold}g');
    }
    final sellN =
        _sellStacks.values.fold<int>(0, (a, v) => a + v) +
        _sellInstances.length;
    if (sellN > 0) {
      parts.add(
        'Selling $sellN item${sellN == 1 ? '' : 's'} +${quote.sellGold}g',
      );
    }
    return parts.join(' · ');
  }

  /// The basket review sheet (UI pass, point 5): every pending line with a
  /// remove control, so the basket can be pruned without hunting both tabs.
  /// Reads the live maps through a [StatefulBuilder] so removals repaint the
  /// sheet AND the screen; pops itself when the last line goes.
  void _openBasketReview() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void both(VoidCallback edit) {
            setState(edit);
            setSheetState(() {});
            if (_basketEmpty) Navigator.of(sheetContext).pop();
          }

          final game = GameStateScope.read(context);
          final lines = <Widget>[
            for (final e in _buy.entries)
              _BasketLine(
                label: 'Buy ${e.value} × ${_name(e.key)}',
                onRemove: () => both(() => _buy.remove(e.key)),
              ),
            for (final e in _sellStacks.entries)
              _BasketLine(
                label: 'Sell ${e.value} × ${_name(e.key)}',
                onRemove: () => both(() => _sellStacks.remove(e.key)),
              ),
            for (final id in _sellInstances)
              _BasketLine(
                label:
                    'Sell ${_name(game.profile.itemInstances[id]?.defId ?? id)}',
                onRemove: () => both(() => _sellInstances.remove(id)),
              ),
          ];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basket',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lines,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _name(String itemId) {
    final def = ItemCatalogue.tryById(itemId);
    return def == null ? itemId : ItemCatalogue.displayName(def);
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

/// ⚠️ Gold when lit, not teal (UI pass, point 8): on a screen whose every
/// accent is gold, the old teal pill was the one off-palette element.
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
          color: on ? AppColors.gold : Colors.transparent,
          border: Border.all(color: on ? AppColors.gold : AppColors.border),
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

/// The five location tiers as a colour-coded chip (UI pass, point 3):
/// bright green → red is the ruled colour code, and the WORD rides along for
/// colour-blind players. One of exactly five per §4.1, so the mapping is a
/// closed switch, not a formula.
class _TierChip extends StatelessWidget {
  final double mod;
  const _TierChip({required this.mod});

  @override
  Widget build(BuildContext context) {
    final (label, colour) = tierOf(mod);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        border: Border.all(color: colour),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(color: colour, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// (label, colour) for a location-mod multiplier — the ruled five-step code.
(String, Color) tierOf(double mod) {
  if (mod == ShopCatalogue.nativeMod) {
    return ('Native −25%', const Color(0xFF45D06E));
  }
  if (mod == ShopCatalogue.regionalMod) {
    return ('Regional −10%', const Color(0xFFA3CF45));
  }
  if (mod == ShopCatalogue.baselineMod) {
    return ('Standard', const Color(0xFFD0BD45));
  }
  if (mod == ShopCatalogue.oneTierMod) {
    return ('Imported +10%', const Color(0xFFD08C45));
  }
  return ('Exotic +25%', const Color(0xFFD05252));
}

/// The reserved icon slot (UI pass, point 7): a dim square with the item's
/// initial, replaced by the real PNG when the art lands — names align either
/// way, and an icon-less shelf stops looking ragged.
class _ItemGlyph extends StatelessWidget {
  final String defId;
  final String name;
  const _ItemGlyph({required this.defId, required this.name});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 26,
    child: ItemIcon(
      defId: defId,
      size: 26,
      gap: 0,
      fallback: Container(
        decoration: BoxDecoration(
          color: AppColors.panelHi,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            name.isEmpty ? '?' : name[0],
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

/// `-`/count/`+`, with the UI-pass point-8 ergonomics: hold either button to
/// auto-repeat (accelerating), tap the number to edit it in place.
class _QtyControl extends StatefulWidget {
  final int value;
  final int min;
  final int max;

  /// Null disables the whole control — e.g. an out-of-stock item.
  final ValueChanged<int>? onChanged;

  const _QtyControl({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_QtyControl> createState() => _QtyControlState();
}

class _QtyControlState extends State<_QtyControl> {
  Timer? _repeat;
  var _held = 0;
  var _editing = false;
  late final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _repeat?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _bump(int dir) {
    final v = (widget.value + dir).clamp(widget.min, widget.max);
    if (v != widget.value) widget.onChanged?.call(v);
  }

  /// ⭐ Accelerating hold-to-repeat: ~7 steps/s for the first second, then
  /// ~18/s — fast enough to reach any stock ceiling in a couple of seconds
  /// without a separate 'max' control.
  void _startRepeat(int dir) {
    _held = 0;
    _repeat = Timer.periodic(const Duration(milliseconds: 140), (t) {
      _held++;
      _bump(dir);
      if (_held == 7) {
        t.cancel();
        _repeat = Timer.periodic(
          const Duration(milliseconds: 55),
          (_) => _bump(dir),
        );
      }
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _commitEdit() {
    final parsed = int.tryParse(_text.text.trim());
    setState(() => _editing = false);
    if (parsed == null) return;
    final v = parsed.clamp(widget.min, widget.max);
    if (v != widget.value) widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: !enabled || widget.value <= widget.min ? null : () => _bump(-1),
          onHoldStart: !enabled ? null : () => _startRepeat(-1),
          onHoldEnd: _stopRepeat,
        ),
        SizedBox(
          width: 34,
          child: _editing
              ? TextField(
                  controller: _text,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onSubmitted: (_) => _commitEdit(),
                  onTapOutside: (_) => _commitEdit(),
                )
              : InkWell(
                  onTap: !enabled
                      ? null
                      : () => setState(() {
                          _text.text = '${widget.value}';
                          _editing = true;
                        }),
                  child: Text(
                    '${widget.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                  ),
                ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: !enabled || widget.value >= widget.max ? null : () => _bump(1),
          onHoldStart: !enabled ? null : () => _startRepeat(1),
          onHoldEnd: _stopRepeat,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  const _StepButton({
    required this.icon,
    required this.onTap,
    this.onHoldStart,
    this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: onTap == null ? null : (_) => onHoldStart?.call(),
    onLongPressEnd: (_) => onHoldEnd?.call(),
    onLongPressCancel: onHoldEnd,
    child: InkWell(
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
    ),
  );
}

/// A gold-chip total — 'N for Xg' once a row's quantity is > 0, so the
/// marginal walk explains itself instead of contradicting the unit price
/// (UI pass, point 2 — the '3g each but 5 for 16g' trap).
class _GoldChip extends StatelessWidget {
  final int gold;
  final int qty;
  const _GoldChip({required this.gold, required this.qty});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.15),
      border: Border.all(color: AppColors.gold),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      qty > 1 ? '$qty for ${gold}g' : '${gold}g',
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// The price fragment of a row subline: strikethrough base → event price
/// when an event is live (UI pass, point 6), '· next Ng' once the marginal
/// walk has moved past the sticker price (point 2).
class _PriceLine extends StatelessWidget {
  final int unit;
  final int? preEventUnit;
  final int? nextUnit;
  final bool spike;
  final String suffix;
  const _PriceLine({
    required this.unit,
    required this.preEventUnit,
    required this.nextUnit,
    required this.spike,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final eventColour = spike ? AppColors.ember : AppColors.teal;
    return Text.rich(
      TextSpan(
        children: [
          if (preEventUnit != null && preEventUnit != unit) ...[
            TextSpan(
              text: '${preEventUnit}g ',
              style: const TextStyle(
                color: AppColors.textFaint,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            TextSpan(
              text: '${unit}g each',
              style: TextStyle(color: eventColour),
            ),
          ] else
            TextSpan(text: '${unit}g each'),
          if (nextUnit != null && nextUnit != unit)
            TextSpan(
              text: ' · next ${nextUnit}g',
              style: const TextStyle(color: AppColors.textFaint),
            ),
          if (suffix.isNotEmpty) TextSpan(text: suffix),
        ],
      ),
      style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
    );
  }
}

class _BasketLine extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _BasketLine({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, size: 16, color: AppColors.textDim),
        onPressed: onRemove,
        tooltip: 'Remove from basket',
      ),
    ],
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

/// One SINGLE-LINE shelf row (UI pass, point 1 — the old card spent ~220px
/// on ~40px of information): glyph · name+chips over a price subline ·
/// stepper · total, everything on one visual line.
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
    int unitAt(int atStock, {double event = 1.0}) => ShopPricing.roundGold(
      ShopPricing.buyPrice(
        base: def.value,
        equilibrium: equilibrium,
        stock: atStock,
        locationMod: locationMod,
        eventMod: event,
      ),
    );
    final unit = unitAt(stock, event: eventMod);
    // ⭐ Point 2: the NEXT unit's marginal price — the walk's convention
    // prices unit i at the stock left after i−1 units, so with [qty] pending
    // the next one costs the price at `stock − qty`.
    final nextUnit = qty > 0 && qty < stock
        ? unitAt(stock - qty, event: eventMod)
        : null;
    final preEvent = eventMod != 1.0 ? unitAt(stock) : null;
    // ⚠️ Bounded to persisted stock — the basket-pricing walk always prices
    // a buy line against `profile.shopStock` as it stands right now (see
    // `GameState.priceShopBasket`'s doc), so the stepper's ceiling must
    // agree with what settling would actually accept.
    final max = stock < 0 ? 0 : stock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GamePanel(
        child: Row(
          children: [
            _ItemGlyph(defId: itemId, name: name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: rarityColour(def.rarity),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TierChip(mod: locationMod),
                      if (eventMod != 1.0) ...[
                        const SizedBox(width: 4),
                        _EventChip(eventMod: eventMod),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  _PriceLine(
                    unit: unit,
                    preEventUnit: preEvent,
                    nextUnit: nextUnit,
                    spike: eventMod > 1.0,
                    suffix: ' · stock $stock',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QtyControl(
              value: qty,
              min: 0,
              max: max,
              onChanged: max <= 0 ? null : onQtyChanged,
            ),
            if (qty > 0 && total != null) ...[
              const SizedBox(width: 8),
              _GoldChip(gold: total!, qty: qty),
            ],
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
    int? nextUnit;
    int? preEvent;
    var spike = false;
    double locationMod = 1.0;
    double eventMod = 1.0;
    if (stocked) {
      final state = game.profile.shopStock[townId];
      final equilibrium = game.shopEquilibriumFor(townId, itemId);
      final stock = state?.stockOf(itemId) ?? equilibrium;
      locationMod = game.shopLocationModFor(townId, itemId);
      eventMod = game.shopEventsFor(townId, today)[itemId] ?? 1.0;
      spike = eventMod > 1.0;
      int unitAt(int atStock, {double event = 1.0}) => ShopPricing.roundGold(
        ShopPricing.sellPrice(
          base: def.value,
          equilibrium: equilibrium,
          stock: atStock,
          locationMod: locationMod,
          eventMod: event,
        ),
      );
      unit = unitAt(stock, event: eventMod);
      // Selling FLOODS stock, so the next unit prices at `stock + qty` —
      // the mirror of the buy row's `stock − qty`.
      nextUnit = qty > 0 ? unitAt(stock + qty, event: eventMod) : null;
      preEvent = eventMod != 1.0 ? unitAt(stock) : null;
    } else {
      unit = ShopPricing.vendorPrice(def.value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GamePanel(
        child: Row(
          children: [
            _ItemGlyph(defId: itemId, name: name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: rarityColour(def.rarity),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (stocked) ...[
                        const SizedBox(width: 6),
                        _TierChip(mod: locationMod),
                      ],
                      if (eventMod != 1.0) ...[
                        const SizedBox(width: 4),
                        _EventChip(eventMod: eventMod),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (bound)
                    const Text(
                      'Bound — cannot be sold.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11.5),
                    )
                  else if (stocked)
                    _PriceLine(
                      unit: unit,
                      preEventUnit: preEvent,
                      nextUnit: nextUnit,
                      spike: spike,
                      suffix: ' · have $available',
                    )
                  else
                    Text(
                      '${unit}g each · vendor (flat) · have $available',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QtyControl(
              value: qty,
              min: 0,
              max: max,
              onChanged: bound || max <= 0 ? null : onQtyChanged,
            ),
            if (qty > 0 && total != null) ...[
              const SizedBox(width: 8),
              _GoldChip(gold: total!, qty: qty),
            ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: GamePanel(
        child: Row(
          children: [
            _ItemGlyph(defId: defId, name: name),
            const SizedBox(width: 10),
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
                    style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected && !bound && total != null) ...[
              _GoldChip(gold: total!, qty: 1),
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
/// charging exactly [ShopBasketQuote.net] when [onSettle] fires. ⭐ The
/// summary line is TAPPABLE (UI pass, point 5) — it opens the basket review
/// sheet, the only place the whole basket is visible at once.
class _SettleBar extends StatelessWidget {
  final ShopBasketQuote quote;
  final String summary;
  final String? blockReason;
  final VoidCallback? onSettle;
  final VoidCallback onReviewBasket;

  const _SettleBar({
    required this.quote,
    required this.summary,
    required this.blockReason,
    required this.onSettle,
    required this.onReviewBasket,
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
          InkWell(
            onTap: onReviewBasket,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: summary),
                  const TextSpan(
                    text: '  ·  tap to review',
                    style: TextStyle(color: AppColors.textFaint),
                  ),
                ],
              ),
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
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
