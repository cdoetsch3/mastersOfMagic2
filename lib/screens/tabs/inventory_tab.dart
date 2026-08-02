import 'package:flutter/material.dart';

import '../../game/game_state.dart';
import '../../game/items/carrying.dart';
import '../../game/items/inventory.dart';
import '../../game/items/item_catalogue.dart';
import '../../game/items/item_def.dart';
import '../../game/items/item_instance.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
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
              SectionLabel(
                'Backpack — ${game.profile.backpack.used}'
                '/${Carrying.backpackSlots}',
              ),
              _BackpackGrid(game: game, town: inTown ? here.id : null),
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
          return _ItemSlot(
            slot: slot,
            instance: slot.instanceId == null
                ? null
                : game.profile.itemInstances[slot.instanceId],
            onTap: town == null ? null : () => game.deposit(town!, i),
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

  const _ItemSlot({required this.slot, this.instance, this.onTap});

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

class _StoreroomList extends StatelessWidget {
  final GameState game;
  final String town;
  final Storeroom room;

  const _StoreroomList({
    required this.game,
    required this.town,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
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
    return GamePanel(
      child: Column(
        children: [
          for (final e in room.stacks.entries)
            _StoredRow(
              label: _nameOf(e.key),
              count: e.value,
              colour: _colourOf(e.key),
              onTake: full
                  ? null
                  : () => game.withdraw(town, InventorySlot(defId: e.key)),
            ),
          for (final id in room.instanceIds)
            _StoredRow(
              label: _instanceName(id),
              count: 1,
              colour: _colourOf(game.profile.itemInstances[id]?.defId ?? ''),
              onTake: full
                  ? null
                  : () => game.withdraw(
                      town,
                      InventorySlot(
                        defId: game.profile.itemInstances[id]!.defId,
                        instanceId: id,
                      ),
                    ),
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

  String _nameOf(String defId) {
    final def = ItemCatalogue.tryById(defId);
    return def == null ? defId : ItemCatalogue.displayName(def, null);
  }

  String _instanceName(String id) {
    final inst = game.profile.itemInstances[id];
    if (inst == null) return id;
    final def = ItemCatalogue.tryById(inst.defId);
    return def == null ? inst.defId : ItemCatalogue.displayName(def, inst);
  }

  Color _colourOf(String defId) {
    final def = ItemCatalogue.tryById(defId);
    return def == null ? AppColors.textFaint : rarityColour(def.rarity);
  }
}

class _StoredRow extends StatelessWidget {
  final String label;
  final int count;
  final Color colour;
  final VoidCallback? onTake;

  const _StoredRow({
    required this.label,
    required this.count,
    required this.colour,
    this.onTake,
  });

  @override
  Widget build(BuildContext context) => Padding(
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
        TextButton(onPressed: onTake, child: const Text('Take')),
      ],
    ),
  );
}

/// ⭐ The standard ARPG ladder (ITEMS §8), so players read rank on sight.
/// ⚠️ Legendary wants a gradient treatment, not a flat colour — it degrades to
/// gold here until that widget exists.
Color rarityColour(Rarity r) => switch (r) {
  Rarity.common => const Color(0xFFCFD8DC),
  Rarity.uncommon => const Color(0xFF6BBF59),
  Rarity.rare => const Color(0xFF4A90D9),
  Rarity.epic => const Color(0xFFA96BD8),
  Rarity.mythic => const Color(0xFFE08A3C),
  Rarity.legendary => const Color(0xFFE8C547),
};
