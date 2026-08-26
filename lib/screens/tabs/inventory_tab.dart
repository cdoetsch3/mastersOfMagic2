import 'package:flutter/material.dart';

import '../../game/economy/shop_catalogue.dart';
import '../../game/game_state.dart';
import '../../game/items/carrying.dart';
import '../../game/items/equipping.dart';
import '../../game/items/inventory.dart';
import '../../game/items/item_catalogue.dart';
import '../../game/items/item_def.dart';
import '../../game/items/item_instance.dart';
import '../../game/world.dart';
import '../../ui/app_banner.dart';
import '../../ui/app_theme.dart';
import '../../ui/item_display.dart';
import '../../ui/item_icon.dart';
import '../craft_screen.dart';
import '../home_shell.dart';
import '../shop_screen.dart';

/// The backpack, and — when the player is standing in a town — that town's
/// Storeroom beside it.
///
/// ⭐ **Both are shown together on purpose.** Moving things between them is the
/// whole interaction, and a Storeroom on its own screen would turn a two-sided
/// decision into two one-sided ones.
class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final here = World.byId(game.profile.locationId);
    final inTown = here.isTown;
    final room = game.profile.storerooms[here.id] ?? const Storeroom();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Inventory'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            children: [
              const SectionLabel('Equipped'),
              _PaperDoll(game: game),
              const SizedBox(height: 10),
              _GearTotals(game: game),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      'Backpack — ${game.profile.backpack.used}'
                      '/${Carrying.backpackSlots}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CraftScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.handyman, size: 16),
                    label: const Text('Craft'),
                  ),
                  // ⭐ In town only, and only when there is something to move.
                  // Deposits the whole pack; equipped gear is never touched.
                  if (inTown && game.profile.backpack.used > 0)
                    TextButton.icon(
                      // ⭐ **Says nothing, on purpose** (notice ruling,
                      // 2026-08-26). Deposit-all empties the whole pack: the
                      // grid below clears, the "Backpack — n/24" count above
                      // drops to 0, and the button removes itself because
                      // `used > 0` stopped being true. A notice reporting a
                      // count the screen just finished showing three ways is
                      // the redundant-confirmation case the rule deletes.
                      onPressed: () => game.depositAll(here.id),
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Deposit all'),
                    ),
                ],
              ),
              _BackpackGrid(game: game, town: inTown ? here.id : null),
              if (inTown)
                const Padding(
                  padding: EdgeInsets.only(top: 2, left: 4),
                  child: Text(
                    'Tap to stow · hold for options.',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 16),
              if (inTown) ...[
                Row(
                  children: [
                    Expanded(
                      child: SectionLabel(
                        '${here.name} Storeroom — ${room.itemCount}',
                      ),
                    ),
                    // ⭐ The same door as the Storeroom, per the designer's
                    // ruling — OPEN towns only (§14b.2); a closed town shows
                    // no button at all, just the season line below.
                    if (ShopCatalogue.isOpen(here.id))
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ShopScreen(townId: here.id),
                          ),
                        ),
                        icon: const Icon(Icons.storefront, size: 16),
                        label: const Text('Shop'),
                      ),
                  ],
                ),
                _StoreroomList(game: game, town: here.id, room: room),
                const SizedBox(height: 8),
                const Text(
                  // ⚠️ The rule players would otherwise learn the hard way.
                  'Storerooms are per city. What you leave here stays here.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                ),
                // ⭐ "closed towns surface the season line if anything" —
                // the shop door simply is not offered above, and this is
                // the one line explaining why.
                if (!ShopCatalogue.isOpen(here.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Shop: ${ShopCatalogue.closedFlavor}',
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
              ] else
                const GamePanel(
                  child: Text(
                    'Your Storeroom is in town. Travel to a city to stow what '
                    'you are carrying.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ten equipment slots, plus what the belt can currently hold.
///
/// ⭐ **Empty slots are shown, not hidden.** Most of the value of this panel
/// early on is telling the player what they do not have yet — a paper doll
/// that only lists worn items looks like a bug when you own nothing.
///
/// ⭐ Tap a worn item to see its stats or take it off; tap a backpack item
/// to wear it. Since 2026-08-09 the totals genuinely reach the duel.
class _PaperDoll extends StatelessWidget {
  final GameState game;

  const _PaperDoll({required this.game});

  static const _labels = {
    EquipSlot.hat: 'Hat',
    EquipSlot.robeTop: 'Robe top',
    EquipSlot.robeBottom: 'Robe bottom',
    EquipSlot.gloves: 'Gloves',
    EquipSlot.boots: 'Boots',
    EquipSlot.neck: 'Neck',
    EquipSlot.ring: 'Ring',
    EquipSlot.mainHand: 'Main hand',
    EquipSlot.offHand: 'Off hand',
    EquipSlot.belt: 'Belt',
  };

  @override
  Widget build(BuildContext context) {
    final armour = EquipSlot.values.where((s) => s.carriesSet);
    final rest = EquipSlot.values.where((s) => !s.carriesSet);
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ Option A (ruling 2026-08-25): slots grouped by category with
          // labelled headers — and the old unexplained link icon replaced by
          // something EARNED: a matching-set counter, live before set
          // bonuses exist, as a collection cue (ITEMS §3.2's five set slots).
          Text(
            _armourHeader(game),
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final slot in armour)
                _EquipSlotChip(
                  label: _labels[slot] ?? slot.name,
                  slot: slot,
                  instanceId: game.profile.equipped[slot],
                  game: game,
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'WEAPONS & ACCESSORIES',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // ⭐ The belt is one of these chips now — its LOADED slots keep
              // their own bay below, but the wearable itself lives in the
              // grid like every other slot (the old two-line lecture is gone).
              for (final slot in rest)
                _EquipSlotChip(
                  label: _labels[slot] ?? slot.name,
                  slot: slot,
                  instanceId: game.profile.equipped[slot],
                  game: game,
                ),
            ],
          ),
          if (game.beltCapacity > 0 || game.profile.belt.loaded.isNotEmpty) ...[
            const Divider(color: AppColors.borderDim, height: 22),
            _BeltBay(game: game),
          ],
        ],
      ),
    );
  }

  /// 'ARMOR · BINDWEED 3/5' when worn set pieces share a material, 'ARMOR'
  /// otherwise. Counts by [EquipmentDef.material] — the set field until sets
  /// are real (Phase 8).
  String _armourHeader(GameState game) {
    final materials = <String, int>{};
    for (final slot in EquipSlot.values.where((s) => s.carriesSet)) {
      final inst = game.profile.itemInstances[game.profile.equipped[slot]];
      final def = inst == null ? null : ItemCatalogue.tryById(inst.defId);
      if (def is EquipmentDef) {
        materials[def.material] = (materials[def.material] ?? 0) + 1;
      }
    }
    final best = materials.entries.fold<MapEntry<String, int>?>(
      null,
      (a, e) => a == null || e.value > a.value ? e : a,
    );
    if (best == null || best.value < 2) return 'ARMOR';
    return 'ARMOR · ${best.key.toUpperCase()} ${best.value}/5';
  }
}

/// The belt equipment chip and the belt slots it grants, as one unit.
///
/// ⭐ **Adjacency is the whole point** (designer, 2026-08-17). Since belt
/// capacity now comes only from the worn belt (`Carrying.baseBeltSlots` is 0),
/// cause and effect have to be readable in one glance: an empty Belt chip
/// beside "No belt" explains itself, where an empty chip in a grid of ten and
/// a row of slot boxes twenty pixels lower did not. Wearing a Tuskhide Belt
/// fills the chip and grows the row beside it, in the same movement.
/// The loaded belt slots — shown only while a belt is worn (or an
/// over-capacity leftover exists); the wearable itself is a grid chip now.
/// ⭐ The old two-line lecture is gone (Option A ruling): an empty belt slot
/// grid explains carrying, and the turn cost is taught where it is paid —
/// on the duel's belt rail.
class _BeltBay extends StatelessWidget {
  final GameState game;

  const _BeltBay({required this.game});

  @override
  Widget build(BuildContext context) {
    final capacity = game.beltCapacity;
    final loaded = game.profile.belt.loaded;
    // ⚠️ Draws every loaded item even past capacity. An over-capacity belt is
    // a legal state (see GameState.settleBeltOverflow: a full pack on the road
    // leaves items belted), and an item the UI refuses to draw is an item the
    // player cannot unload — which is how "the game ate my potion" happens.
    final boxes = loaded.length > capacity ? loaded.length : capacity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.science, color: AppColors.teal, size: 16),
        const SizedBox(width: 8),
        Text(
          'Belt — ${loaded.length}/$capacity',
          style: const TextStyle(color: AppColors.text, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < boxes; i++)
                _BeltSlot(
                  defId: i < loaded.length ? loaded[i] : null,
                  game: game,
                  overCapacity: i >= capacity,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquipSlotChip extends StatelessWidget {
  final String label;
  final EquipSlot slot;
  final String? instanceId;
  final GameState game;

  const _EquipSlotChip({
    required this.label,
    required this.slot,
    required this.instanceId,
    required this.game,
  });

  /// Backpack indices whose instance would fill [slot] — what an empty
  /// chip's tap offers.
  List<int> _candidates() => [
    for (var i = 0; i < game.profile.backpack.slots.length; i++)
      if (game.profile.backpack.slots[i]?.instanceId != null &&
          (ItemCatalogue.tryById(game.profile.backpack.slots[i]!.defId)
                  is EquipmentDef) &&
          (ItemCatalogue.tryById(game.profile.backpack.slots[i]!.defId)!
                      as EquipmentDef)
                  .slot ==
              slot)
        i,
  ];

  @override
  Widget build(BuildContext context) {
    final inst = instanceId == null
        ? null
        : game.profile.itemInstances[instanceId];
    final def = inst == null ? null : ItemCatalogue.tryById(inst.defId);
    final filled = def != null;
    final colour = filled ? rarityColour(def.rarity) : AppColors.borderDim;
    final candidates = filled ? const <int>[] : _candidates();
    // ⭐ Ruling 2026-08-25 (Option A): rarity moved OFF the border and onto a
    // left-edge stripe — a coloured border on two cards in a grey grid read
    // as selection state, a stripe reads as a property. Empty slots dim and
    // become ACTIONABLE: '＋ Equip' when the pack holds a candidate.
    // ⚠️ The stripe is an inner clipped element, NOT a fat left BorderSide:
    // Flutter refuses a borderRadius on a non-uniform Border (found by the
    // suite the moment the first belt test wore one).
    final chip = Container(
      width: 104,
      decoration: BoxDecoration(
        color: filled ? AppColors.bg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        // ⚠️ IntrinsicHeight: `stretch` needs a bounded height for the
        // stripe to fill, and a Wrap gives its children none.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (filled) Container(width: 3, color: colour),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: _chipBody(filled, def, inst, candidates, colour),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return _wrapTap(context, chip, def, inst, candidates);
  }

  Widget _chipBody(
    bool filled,
    ItemDef? def,
    ItemInstance? inst,
    List<int> candidates,
    Color colour,
  ) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: filled ? AppColors.textFaint : AppColors.textFaint
                  .withValues(alpha: 0.6),
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ The icon leads the name, and takes its own 6px of breathing
              // room with it when there is no PNG — see [ItemIcon.gap]. An
              // empty slot has no item and therefore never asks for one.
              if (filled)
                ItemIcon(
                  defId: def!.id,
                  size: 18,
                  gap: 6,
                  fallback: const SizedBox.shrink(),
                ),
              Expanded(
                child: Text(
                  filled
                      ? ItemCatalogue.displayName(def!, inst)
                      : candidates.isEmpty
                      ? 'Empty'
                      : slot == EquipSlot.belt && candidates.length == 1
                      ? '＋ ${ItemCatalogue.displayName(ItemCatalogue.byId(game.profile.backpack.slots[candidates.first]!.defId))}'
                      : '＋ Equip',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled
                        ? colour
                        : candidates.isEmpty
                        ? AppColors.textFaint
                        : slot == EquipSlot.belt
                        ? AppColors.gold
                        : AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
  }

  Widget _wrapTap(
    BuildContext context,
    Widget chip,
    ItemDef? def,
    ItemInstance? inst,
    List<int> candidates,
  ) {
    if (def is EquipmentDef) {
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showItemDialog(
          context,
          def: def,
          instance: inst,
          actions: [
            (
              label: 'Unequip',
              run: () => GameStateScope.read(context).unequip(slot),
            ),
          ],
        ),
        child: chip,
      );
    }
    if (candidates.isEmpty) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _pickCandidate(context, candidates),
      child: chip,
    );
  }

  /// One candidate equips immediately; several open a picker sheet.
  Future<void> _pickCandidate(BuildContext context, List<int> indices) async {
    final gs = GameStateScope.read(context);
    if (indices.length == 1) {
      await gs.equipFromBackpack(indices.first);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            for (final i in indices)
              ListTile(
                dense: true,
                title: Text(
                  ItemCatalogue.displayName(
                    ItemCatalogue.byId(gs.profile.backpack.slots[i]!.defId),
                    gs.profile.itemInstances[gs
                        .profile
                        .backpack
                        .slots[i]!
                        .instanceId],
                  ),
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await gs.equipFromBackpack(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// The gear sum as the numbers the player ends up with, printed by
/// `Equipping.describeTotals` — ⭐ so this panel cannot disagree with the duel.
///
/// ⚠️ **Totals here, deltas in the item dialog** (designer, 2026-08-17). An
/// ITEM shows its contribution ("+11 max health"); this PANEL answers "what am
/// I actually at" — "Max health 159 (+11)". Both come from `equipping.dart`,
/// so neither can drift from the stats the duel applies.
class _GearTotals extends StatelessWidget {
  final GameState game;

  const _GearTotals({required this.game});

  @override
  Widget build(BuildContext context) {
    final lines = Equipping.statTotals(
      game.equipmentTotals,
      level: game.profile.level,
    );
    final pieces = game.profile.equipped.values.whereType<String>().length;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FROM EQUIPMENT${pieces > 0 ? ' · $pieces PIECE${pieces == 1 ? '' : 'S'}' : ''}',
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          if (lines.isEmpty)
            const Text(
              'Nothing you are wearing changes your stats yet.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            )
          else
            // ⭐ Two columns (ruling 2026-08-25, round 2): numbers stay close
            // to their labels instead of a screen-wide gap — and every TOTAL
            // right-aligns on its column edge because the parenthesis moved
            // IN FRONT of it ('(167 +12) 179'), the reversal the designer
            // pre-approved for exactly this alignment. One column on narrow
            // screens rather than two cramped ones.
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 430;
                if (!twoCol) {
                  return Column(
                    children: [for (final l in lines) _StatRow(line: l)],
                  );
                }
                final half = (lines.length + 1) ~/ 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (final l in lines.take(half)) _StatRow(line: l),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Column(
                        children: [
                          for (final l in lines.skip(half)) _StatRow(line: l),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final GearStatLine line;
  const _StatRow({required this.line});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            line.label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
        ),
        _StatNumbers(line: line),
      ],
    ),
  );
}

/// The colour a gear bonus wears: green when it gives, red when it takes.
/// ⭐ Public-shaped on purpose (ruling 2026-08-25): stat-LOWERING equipment
/// is planned, and this is the one function that decides how a negative
/// reads everywhere it will ever appear.
Color bonusColour(int bonus) => bonus < 0 ? AppColors.ember : AppColors.green;

/// Format 1 (ruling 2026-08-25): `TOTAL (base +bonus)` — total large, base
/// muted, bonus coloured by sign via [bonusColour]. Base-less stats print
/// the total alone; base-ZERO stats keep the parenthesis but hide the 0.
class _StatNumbers extends StatelessWidget {
  final GearStatLine line;
  const _StatNumbers({required this.line});

  @override
  Widget build(BuildContext context) {
    // ⭐ Parenthesis BEFORE the total — '(167 +12) 179' — so the big number
    // is always the LAST thing on the line and every total in a column
    // right-aligns on the same edge (ruling 2026-08-25, round 2).
    final signed = '${line.bonus >= 0 ? '+' : '−'}${line.bonus.abs()}';
    return Text.rich(
      TextSpan(
        children: [
          if (line.base != null) ...[
            TextSpan(
              text: line.base! > 0 ? '(${line.base} ' : '(',
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 11.5,
              ),
            ),
            TextSpan(
              text: signed,
              style: TextStyle(
                color: bonusColour(line.bonus),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(
              text: ')  ',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
            ),
          ],
          TextSpan(
            text: line.total,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One belt slot — empty, or a loaded item that can be taken off again.
///
/// ⭐ **Tappable to unload**, using the same dialog the pack and the paper doll
/// use: the belt is the only container that had no way back, and a potion you
/// can load but never retrieve is a trap rather than a decision.
class _BeltSlot extends StatelessWidget {
  final String? defId;
  final GameState game;

  /// True for a slot the belt no longer has room for — see [_BeltBay].
  final bool overCapacity;

  const _BeltSlot({
    required this.defId,
    required this.game,
    this.overCapacity = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = defId == null ? null : ItemCatalogue.tryById(defId!);
    final colour = def == null
        ? AppColors.borderDim
        : (overCapacity ? AppColors.ember : rarityColour(def.rarity));
    final box = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colour),
      ),
      child: def == null
          ? null
          : Center(
              // ⭐ The icon REPLACES the initial rather than joining it — a
              // 34px box has room for one thing, and "S" for Sapwort Draught
              // was only ever standing in for a picture.
              child: ItemIcon(
                defId: def.id,
                size: 26,
                fallback: Text(
                  ItemCatalogue.displayName(def, null).substring(0, 1),
                  style: TextStyle(color: colour, fontSize: 13),
                ),
              ),
            ),
    );
    if (def == null) return box;
    return Tooltip(
      message: overCapacity
          // ⚠️ Names the state rather than hiding it: the item is safe, it just
          // does not fit any more.
          ? '${ItemCatalogue.displayName(def, null)} — no slot for this; '
                'take it off or wear a belt'
          : ItemCatalogue.displayName(def, null),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showItemDialog(
          context,
          def: def,
          actions: [
            (
              label: 'Take off belt',
              run: () => game.unloadFromBelt(def.id),
            ),
          ],
        ),
        child: box,
      ),
    );
  }
}

/// Twenty slots, drawn as a grid. ⭐ One item per slot, so the pressure is
/// visible rather than a number the player has to go and look up.
class _BackpackGrid extends StatelessWidget {
  final GameState game;

  /// Non-null when the player is in a town and can therefore deposit.
  final String? town;

  const _BackpackGrid({required this.game, required this.town});

  @override
  Widget build(BuildContext context) {
    final slots = game.profile.backpack.slots;
    return GamePanel(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: slots.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          final slot = slots[i];
          if (slot == null) return const _EmptySlot();
          final instance = slot.instanceId == null
              ? null
              : game.profile.itemInstances[slot.instanceId];
          final def = ItemCatalogue.tryById(slot.defId);
          if (def == null) {
            return _ItemSlot(slot: slot, instance: instance);
          }
          // ⭐ Why this item cannot be belted right now — null when it can, and
          // the same words GameState.loadOntoBelt would refuse with.
          final beltNo = def is Beltable
              ? Carrying.beltRefusal(
                  def,
                  used: game.profile.belt.used,
                  capacity: game.beltCapacity,
                )
              : null;
          // The full menu, reached by long-press (Option A) — or by tap when
          // out of town, where there is nowhere to deposit.
          void openMenu() => showItemDialog(
            context,
            def: def,
            instance: instance,
            actions: [
              // ⭐ Wearing beats stowing in the ordering — the rarer, more
              // deliberate act.
              if (def is EquipmentDef)
                (label: 'Equip', run: () => game.equipFromBackpack(i)),
              if (def is Beltable && beltNo == null)
                (
                  label: 'Load onto belt',
                  run: () => game.loadOntoBelt(def.id),
                ),
              if (town != null)
                (
                  label: 'Stow',
                  run: () async {
                    await game.deposit(town!, i);
                    return null;
                  },
                ),
            ],
            // ⚠️ Greyed with the reason rather than hidden — otherwise a full
            // belt is indistinguishable from an item that was never beltable.
            unavailable: [
              if (beltNo != null) (label: 'Load onto belt', reason: beltNo),
            ],
          );
          return _ItemSlot(
            slot: slot,
            instance: instance,
            // ⭐ Option A: in town a single tap stows instantly; out of town
            // there is nowhere to stow, so tap opens the menu instead. The
            // menu is always one long-press away.
            onTap: town == null ? openMenu : () => game.deposit(town!, i),
            onLongPress: openMenu,
          );
        },
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.borderDim),
    ),
    child: const SizedBox.expand(),
  );
}

class _ItemSlot extends StatelessWidget {
  final InventorySlot slot;
  final ItemInstance? instance;
  final VoidCallback? onTap;

  /// ⭐ Option A: tap moves the item, press-and-hold opens the full menu
  /// (Equip / Use / details). Right-click maps to the same on desktop.
  final VoidCallback? onLongPress;

  const _ItemSlot({
    required this.slot,
    this.instance,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(slot.defId);
    final colour = def == null ? AppColors.textFaint : rarityColour(def.rarity);
    final name = def == null
        ? slot.defId
        : ItemCatalogue.displayName(def, instance);
    return Tooltip(
      message: def == null ? slot.defId : '$name\n${def.lore}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colour, width: 1.5),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(3),
              // ⭐ The icon REPLACES the wrapped 9px name. A tile that showed
              // both would show neither legibly, and the name is already on
              // the tooltip and in the dialog one tap away.
              //
              // ⚠️ **No `size`** — the tile is the grid's to size (five
              // across, whatever the window is), so a hard number would
              // overflow it on a narrow phone. Unsized, the image takes its
              // intrinsic 64px capped by the tile's own constraints.
              child: ItemIcon(
                defId: slot.defId,
                fallback: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colour, fontSize: 9, height: 1.15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a Storeroom row is, once names and rarities have been resolved.
///
/// ⭐ Stacks and instances become the same shape here, so ordering and
/// filtering are written once instead of twice.
class _StoredEntry {
  final String defId;

  /// Non-null for a non-fungible — the specific staff, not "a staff".
  final String? instanceId;
  final String label;
  final int count;
  final ItemDef? def;

  const _StoredEntry({
    required this.defId,
    required this.instanceId,
    required this.label,
    required this.count,
    required this.def,
  });

  /// ⚠️ An id no catalogue entry claims sorts below common rather than
  /// throwing — a save written before a content patch must still open.
  int get rarityRank => def?.rarity.index ?? -1;
}

/// The kinds a Storeroom can be narrowed to.
///
/// ⭐ **Three buckets and All, not nine item classes.** The player is looking
/// for "the thing I craft with" or "the thing I drink", and a chip per sealed
/// subclass would be a taxonomy rather than a filter. ⚠️ Total by construction:
/// materials is everything that is neither worn nor used, so no stored item can
/// hide from every chip.
enum _StoreFilter {
  all('All'),
  equipment('Equipment'),
  consumables('Consumables'),
  materials('Materials');

  final String label;
  const _StoreFilter(this.label);

  bool accepts(ItemDef? def) => switch (this) {
    _StoreFilter.all => true,
    _StoreFilter.equipment => def is EquipmentDef,
    _StoreFilter.consumables => def is Usable,
    _StoreFilter.materials => def is! EquipmentDef && def is! Usable,
  };
}

class _StoreroomList extends StatefulWidget {
  final GameState game;
  final String town;
  final Storeroom room;

  const _StoreroomList({
    required this.game,
    required this.town,
    required this.room,
  });

  @override
  State<_StoreroomList> createState() => _StoreroomListState();
}

class _StoreroomListState extends State<_StoreroomList> {
  _StoreFilter _filter = _StoreFilter.all;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final room = widget.room;
    if (room.isEmpty) {
      return const GamePanel(
        child: Text(
          'Empty. Tap something in your pack to stow it here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      );
    }
    final full = game.profile.backpack.isFull;
    final entries = _sorted(_entries());
    final shown = [
      for (final e in entries)
        if (_filter.accepts(e.def)) e,
    ];
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in _StoreFilter.values)
                _FilterChip(
                  label: f.label,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing stored here is that kind of thing.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ),
          for (final e in shown)
            _StoredRow(
              defId: e.defId,
              label: e.label,
              count: e.count,
              colour: e.def == null
                  ? AppColors.textFaint
                  : rarityColour(e.def!.rarity),
              onTake: full
                  ? null
                  : () => game.withdraw(
                      widget.town,
                      InventorySlot(defId: e.defId, instanceId: e.instanceId),
                    ),
              // ⭐ Only for a real stack: "take all" of one instance is Take.
              onTakeAll: full || e.instanceId != null || e.count < 2
                  ? null
                  : () => _takeAll(e),
              // ⭐ The Storeroom-as-wardrobe move: dress straight from
              // storage, displaced gear stows itself in exchange.
              onWear: e.instanceId != null && e.def is EquipmentDef
                  ? () async {
                      final no = await game.equipFromStoreroom(e.instanceId!);
                      if (no != null && context.mounted) {
                        showAppBanner(context, no, color: AppColors.ember);
                      }
                    }
                  : null,
            ),
          if (full)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Your pack is full.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }

  /// ⭐ **Reports what actually moved.** Taking 7 of 40 because seven slots
  /// were free is a success, and a bulk action that says nothing reads as
  /// having done nothing.
  Future<void> _takeAll(_StoredEntry e) async {
    final moved = await widget.game.takeAllFromStoreroom(
      widget.town,
      e.defId,
    );
    if (!mounted || moved == 0) return;
    final all = moved >= e.count;
    // ⭐ Banner rather than REMOVE: the counts do move on screen, but the
    // REASON a bulk take stopped at 3 of 40 appears nowhere else, and that is
    // the half of the message worth reading.
    showAppBanner(
      context,
      all
          ? 'Took all $moved ${e.label}.'
          : 'Took $moved of ${e.count} ${e.label} — your pack is full.',
    );
  }

  List<_StoredEntry> _entries() {
    final game = widget.game;
    return [
      for (final s in widget.room.stacks.entries)
        _StoredEntry(
          defId: s.key,
          instanceId: null,
          label: _nameOf(s.key),
          count: s.value,
          def: ItemCatalogue.tryById(s.key),
        ),
      for (final id in widget.room.instanceIds)
        _StoredEntry(
          defId: game.profile.itemInstances[id]?.defId ?? id,
          instanceId: id,
          label: _instanceName(id),
          count: 1,
          def: ItemCatalogue.tryById(
            game.profile.itemInstances[id]?.defId ?? '',
          ),
        ),
    ];
  }

  /// ⭐ **Rarity descending, then name** — the same ordering the loot picker
  /// defaults to (`GameState.defaultLootChoice`), so "best first" means one
  /// thing everywhere. ⚠️ Name breaks every tie explicitly: Dart's sort is not
  /// stable, and a Storeroom that reshuffles itself on every rebuild is worse
  /// than an unsorted one.
  List<_StoredEntry> _sorted(List<_StoredEntry> entries) {
    final out = [...entries];
    out.sort((a, b) {
      final byRarity = b.rarityRank - a.rarityRank;
      return byRarity != 0 ? byRarity : a.label.compareTo(b.label);
    });
    return out;
  }

  String _nameOf(String defId) {
    final def = ItemCatalogue.tryById(defId);
    return def == null ? defId : ItemCatalogue.displayName(def, null);
  }

  String _instanceName(String id) {
    final inst = widget.game.profile.itemInstances[id];
    if (inst == null) return id;
    final def = ItemCatalogue.tryById(inst.defId);
    return def == null ? inst.defId : ItemCatalogue.displayName(def, inst);
  }
}

/// A small pill, in the paper doll's idiom — ⚠️ hand-rolled rather than
/// Material's `FilterChip`, which brings its own palette and would be the only
/// stock-looking control on the screen.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.panelHi : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.borderDim,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.teal : AppColors.textDim,
          fontSize: 11.5,
        ),
      ),
    ),
  );
}

class _StoredRow extends StatelessWidget {
  /// ⚠️ The **def** id, not the instance id — an icon is a fact about the
  /// definition, and two rolls of the same staff share one picture.
  final String defId;
  final String label;
  final int count;
  final Color colour;
  final VoidCallback? onTake;

  /// ⭐ Null unless this is a stack of more than one — a "Take all" beside a
  /// single item is a second button that does the same thing as the first.
  final VoidCallback? onTakeAll;
  final VoidCallback? onWear;

  const _StoredRow({
    required this.defId,
    required this.label,
    required this.count,
    required this.colour,
    this.onTake,
    this.onTakeAll,
    this.onWear,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    // ⭐ Option A: tapping the row takes one back — the mirror of tapping a
    // pack tile to stow. The explicit buttons stay for discoverability and
    // because Wear is a second, distinct action.
    onTap: onTake,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(width: 8, height: 8, color: colour),
        const SizedBox(width: 8),
        // ⭐ Beside the rarity swatch, not instead of it: the swatch answers
        // "how good is this" at a glance and an icon does not. ⚠️ 18px sits
        // inside the row's existing 13px-text line box, so the rows do not
        // grow when the art lands — and with no art the gap goes too.
        ItemIcon(
          defId: defId,
          size: 18,
          gap: 8,
          fallback: const SizedBox.shrink(),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
          ),
        ),
        Text(
          '×$count',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(width: 8),
        if (onWear != null)
          TextButton(onPressed: onWear, child: const Text('Wear')),
        TextButton(onPressed: onTake, child: const Text('Take')),
        if (onTakeAll != null)
          TextButton(onPressed: onTakeAll, child: const Text('Take all')),
      ],
    ),
    ),
  );
}
