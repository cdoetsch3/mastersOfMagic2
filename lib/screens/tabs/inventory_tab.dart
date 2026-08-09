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
    final beltCapacity =
        Carrying.beltSlotsFor(fromGear: game.equipmentTotals.beltSlots);
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final slot in EquipSlot.values)
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
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belt — ${game.profile.belt.used}/$beltCapacity',
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            // ⚠️ The rule that makes the belt a decision rather than a tax.
            'What you can reach mid-duel. Using one spends your turn.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < beltCapacity; i++) ...[
                _BeltSlot(
                  defId: i < game.profile.belt.loaded.length
                      ? game.profile.belt.loaded[i]
                      : null,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
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
      onTap: () => showItemActions(
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

/// The gear sum, printed by the same writer every stats panel uses
/// (Equipping.describe) — ⭐ so this panel cannot disagree with the duel.
class _GearTotals extends StatelessWidget {
  final GameState game;

  const _GearTotals({required this.game});

  @override
  Widget build(BuildContext context) {
    final lines = Equipping.describe(game.equipmentTotals);
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

/// One dialog for every item interaction — what it is, what it does, and
/// what you can do with it here. [actions] whose `run` returns a refusal
/// string surface it; null means done.
Future<void> showItemActions(
  BuildContext context, {
  required ItemDef def,
  ItemInstance? instance,
  List<({String label, Future<String?> Function() run})> actions = const [],
}) async {
  final lines = def is EquipmentDef
      ? Equipping.describe(def.modifiers)
      : (def is Usable ? [(def as Usable).effect.describe] : const <String>[]);
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(
        ItemCatalogue.displayName(def, instance),
        style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (def is EquipmentDef)
            Text(
              'Level ${def.equipLevel}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          for (final line in lines)
            Text(
              line,
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            ),
          const SizedBox(height: 8),
          Text(
            def.lore,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        for (final a in actions)
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final no = await a.run();
              // ⚠️ A refusal the player never sees is a button that looks
              // broken. Every rule speaks here.
              if (no != null) {
                messenger.showSnackBar(SnackBar(content: Text(no)));
              }
            },
            child: Text(a.label),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _BeltSlot extends StatelessWidget {
  final String? defId;

  const _BeltSlot({required this.defId});

  @override
  Widget build(BuildContext context) {
    final def = defId == null ? null : ItemCatalogue.tryById(defId!);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: def == null ? AppColors.borderDim : rarityColour(def.rarity),
        ),
      ),
      child: def == null
          ? null
          : Center(
              child: Text(
                ItemCatalogue.displayName(def, null).substring(0, 1),
                style: TextStyle(color: rarityColour(def.rarity), fontSize: 13),
              ),
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
          return _ItemSlot(
            slot: slot,
            instance: instance,
            onTap: def == null
                ? null
                : () => showItemActions(
                    context,
                    def: def,
                    instance: instance,
                    actions: [
                      // ⭐ Wearing beats stowing in the ordering — it is the
                      // rarer, more deliberate act.
                      if (def is EquipmentDef)
                        (
                          label: 'Equip',
                          run: () => game.equipFromBackpack(i),
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
                  ),
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
              // ⭐ The Storeroom-as-wardrobe move: dress straight from
              // storage, displaced gear stows itself in exchange.
              onWear:
                  ItemCatalogue.tryById(
                        game.profile.itemInstances[id]?.defId ?? '',
                      )
                      is EquipmentDef
                  ? () async {
                      final no = await game.equipFromStoreroom(id);
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
  final VoidCallback? onWear;

  const _StoredRow({
    required this.label,
    required this.count,
    required this.colour,
    this.onTake,
    this.onWear,
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
        if (onWear != null)
          TextButton(onPressed: onWear, child: const Text('Wear')),
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
