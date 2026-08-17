import 'package:flutter/material.dart';

import '../../game/game_state.dart';
import '../../game/items/carrying.dart';
import '../../game/items/equipping.dart';
import '../../game/items/inventory.dart';
import '../../game/items/item_catalogue.dart';
import '../../game/items/item_def.dart';
import '../../game/items/item_instance.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
import '../../ui/item_display.dart';
import '../craft_screen.dart';
import '../home_shell.dart';

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
                      onPressed: () async {
                        final moved = await game.depositAll(here.id);
                        if (context.mounted && moved > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stowed $moved item'
                                  '${moved == 1 ? '' : 's'} in '
                                  '${here.name}.'),
                            ),
                          );
                        }
                      },
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
                SectionLabel('${here.name} Storeroom — ${room.itemCount}'),
                _StoreroomList(game: game, town: here.id, room: room),
                const SizedBox(height: 8),
                const Text(
                  // ⚠️ The rule players would otherwise learn the hard way.
                  'Storerooms are per city. What you leave here stays here.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
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
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final slot in EquipSlot.values)
                // ⭐ Every slot but the belt. The belt is drawn below, welded
                // to the slots it grants — see [_BeltBay].
                if (slot != EquipSlot.belt)
                  _EquipSlotChip(
                    label: _labels[slot] ?? slot.name,
                    instanceId: game.profile.equipped[slot],
                    game: game,
                    // ⭐ The five armour slots are the set slots (ITEMS §3.2);
                    // marking them is what makes "3+2" legible later.
                    carriesSet: slot.carriesSet,
                  ),
            ],
          ),
          const Divider(color: AppColors.borderDim, height: 22),
          _BeltBay(game: game, label: _labels[EquipSlot.belt]!),
        ],
      ),
    );
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
class _BeltBay extends StatelessWidget {
  final GameState game;
  final String label;

  const _BeltBay({required this.game, required this.label});

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
        _EquipSlotChip(
          label: label,
          instanceId: game.profile.equipped[EquipSlot.belt],
          game: game,
          carriesSet: EquipSlot.belt.carriesSet,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.science, color: AppColors.teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // ⚠️ "Belt — 0/0" beside a "No belt" hint says the same
                      // thing twice in two grammars; the bare word is enough.
                      capacity == 0 && loaded.isEmpty
                          ? 'Belt'
                          : 'Belt — ${loaded.length}/$capacity',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (boxes == 0)
                const Text(
                  'No belt — wear one to carry potions into a duel.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                )
              else
                Wrap(
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
              const SizedBox(height: 6),
              const Text(
                // ⚠️ The rule that makes the belt a decision rather than a tax.
                'What you can reach mid-duel. Using one spends your turn.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
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
  final String? instanceId;
  final GameState game;
  final bool carriesSet;

  const _EquipSlotChip({
    required this.label,
    required this.instanceId,
    required this.game,
    required this.carriesSet,
  });

  @override
  Widget build(BuildContext context) {
    final inst = instanceId == null
        ? null
        : game.profile.itemInstances[instanceId];
    final def = inst == null ? null : ItemCatalogue.tryById(inst.defId);
    final filled = def != null;
    final colour = filled ? rarityColour(def.rarity) : AppColors.borderDim;
    final chip = Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colour, width: filled ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (carriesSet)
                const Icon(Icons.link, size: 10, color: AppColors.textFaint),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            filled ? ItemCatalogue.displayName(def, inst) : 'Empty',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: filled ? colour : AppColors.textFaint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
    if (def is! EquipmentDef) return chip;
    final slot = def.slot;
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
    final lines = Equipping.describeTotals(
      game.equipmentTotals,
      level: game.profile.level,
    );
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FROM EQUIPMENT',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          if (lines.isEmpty)
            const Text(
              'Nothing you are wearing changes your stats yet.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            )
          else
            for (final line in lines)
              Text(
                line,
                style: const TextStyle(color: AppColors.teal, fontSize: 12.5),
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
              child: Text(
                ItemCatalogue.displayName(def, null).substring(0, 1),
                style: TextStyle(color: colour, fontSize: 13),
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
              child: Text(
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(no)));
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          all
              ? 'Took all $moved ${e.label}.'
              : 'Took $moved of ${e.count} ${e.label} — your pack is full.',
        ),
      ),
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
  final String label;
  final int count;
  final Color colour;
  final VoidCallback? onTake;

  /// ⭐ Null unless this is a stack of more than one — a "Take all" beside a
  /// single item is a second button that does the same thing as the first.
  final VoidCallback? onTakeAll;
  final VoidCallback? onWear;

  const _StoredRow({
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
