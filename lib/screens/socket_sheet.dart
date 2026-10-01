/// The Socket… sheet (ENCHANTING_DESIGN §5.2, §7): one owned piece's sockets
/// as cells, filled or empty; put a gem from the pack or the Storeroom into
/// an empty one, or take one out for a Shard of its element.
///
/// ⭐ **The refusals are `GameState.socketRefusal` / `unsocketRefusal`** — the
/// same functions `socketGem` / `unsocketGem` refuse with — so the greyed
/// button and a refused press can never disagree.
library;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/items/catalogue/gems.dart';
import '../game/items/equipping.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import '../ui/item_display.dart';
import 'gear_work_actions.dart';

/// Opens the Socket sheet over [context] for the owned piece [instanceId].
Future<void> showSocketSheet(
  BuildContext context, {
  required GameState game,
  required String instanceId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.panel,
  builder: (_) => SocketSheet(game: game, instanceId: instanceId),
);

/// The commit button's label on an empty socket.
const String putInLabel = 'Put in';

/// The commit button's label on a filled socket.
const String takeOutLabel = 'Take out';

/// What an empty socket's cell reads.
const String emptySocketLabel = 'empty';

/// The reason 'Put in' is greyed before a gem is chosen.
const String pickAGemReason = 'Pick a gem below.';

/// The reason 'Put in' is greyed when there is no gem to choose.
const String noGemsReason = 'No gems in your pack or storeroom.';

class SocketSheet extends StatefulWidget {
  final GameState game;
  final String instanceId;

  const SocketSheet({super.key, required this.game, required this.instanceId});

  @override
  State<SocketSheet> createState() => _SocketSheetState();
}

class _SocketSheetState extends State<SocketSheet> {
  late int _index;
  String? _gem;

  @override
  void initState() {
    super.initState();
    // ⭐ Opens on the first EMPTY socket — the one a player came here to fill
    // — or the first socket when all are full.
    final instance = widget.game.profile.itemInstances[widget.instanceId];
    final def = instance == null ? null : ItemCatalogue.tryById(instance.defId);
    final count = def is EquipmentDef ? def.socketCount : 0;
    _index = 0;
    for (var i = 0; i < count; i++) {
      if (_filled(instance!, i) == null) {
        _index = i;
        break;
      }
    }
  }

  static String? _filled(ItemInstance instance, int i) =>
      i < instance.socketed.length &&
          instance.socketed[i] != ItemInstance.emptySocket
      ? instance.socketed[i]
      : null;

  Future<void> _run(Future<String?> Function() act) async {
    final no = await act();
    if (no != null && mounted) {
      showAppBanner(context, no, color: AppColors.ember);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.game,
    builder: (context, _) {
      final game = widget.game;
      final id = widget.instanceId;
      final instance = game.profile.itemInstances[id];
      final def = instance == null
          ? null
          : ItemCatalogue.tryById(instance.defId);
      if (instance == null || def is! EquipmentDef) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'That item is gone.',
              style: TextStyle(color: AppColors.textDim),
            ),
          ),
        );
      }
      final overlays = Equipping.socketOverlays(def, instance);
      final filledId = _filled(instance, _index);
      // ⭐ Gems to hand, by the same count a craft reads (pack + this town's
      // Storeroom), in catalogue order so the list never reshuffles.
      final held = [
        for (final g in Gems.all)
          if (game.materialCount(g.id) > 0) g,
      ];
      // ⚠️ A chosen gem that ran out (the last one just went in) is no
      // longer a choice.
      final gem = held.any((g) => g.id == _gem) ? _gem : null;

      final String label;
      final String? no;
      final String note;
      if (filledId != null) {
        label = takeOutLabel;
        no = game.unsocketRefusal(id, _index);
        final shard = game.unsocketShardFor(id, _index);
        final shardDef = shard == null ? null : ItemCatalogue.tryById(shard);
        note =
            no ??
            (shardDef == null
                ? ''
                : 'Costs 1 ${ItemCatalogue.displayName(shardDef)} — you have '
                      '${game.materialCount(shard!)}.');
      } else {
        label = putInLabel;
        no =
            game.stationRefusal(CraftSkill.jewelry) ??
            (held.isEmpty
                ? noGemsReason
                : gem == null
                ? pickAGemReason
                : game.socketRefusal(id, _index, gem));
        note = no ?? '';
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ One line, as on the Enchant sheet: a long name that wrapped would
              // push the cells and the button below it down.
              Text(
                ItemCatalogue.displayName(def, instance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: rarityColour(def.rarity), fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < def.socketCount; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _SocketCell(
                        gem: switch (_filled(instance, i)) {
                          final g? => ItemCatalogue.tryById(g),
                          null => null,
                        },
                        stat: overlays[i],
                        selected: i == _index,
                        onTap: () => setState(() => _index = i),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // ⭐ ABOVE the gem list, so the list growing or emptying never
              // moves the button.
              ReservedActionRow(
                label: label,
                onPressed: no != null
                    ? null
                    : filledId != null
                    ? () => _run(() => game.unsocketGem(id, _index))
                    : () => _run(() => game.socketGem(id, _index, gem!)),
                note: note,
              ),
              if (filledId == null && held.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final g in held)
                  _GemRow(
                    gem: g,
                    count: game.materialCount(g.id),
                    selected: g.id == gem,
                    onTap: () => setState(() => _gem = g.id),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// One socket: the gem's name and what it adds here, or 'empty'.
class _SocketCell extends StatelessWidget {
  /// Null for an empty socket.
  final ItemDef? gem;

  /// What this socket adds on this piece (`Equipping.socketOverlays` — so a
  /// repeated gem reads its halved number, exactly as the totals do).
  final ItemModifiers? stat;
  final bool selected;
  final VoidCallback onTap;

  /// ⭐ Fixed: a socket filling or emptying rewrites the cell, never resizes it.
  static const double height = 54;

  const _SocketCell({
    required this.gem,
    required this.stat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.panelHi : AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.borderDim,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gem == null ? emptySocketLabel : ItemCatalogue.displayName(gem!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: gem == null
                  ? AppColors.textFaint
                  : rarityColour(gem!.rarity),
              fontSize: 12,
            ),
          ),
          if (stat != null)
            Text(
              Equipping.describe(stat!).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.teal, fontSize: 11),
            ),
        ],
      ),
    ),
  );
}

/// One gem to hand: its name, what it grants, how many you hold.
class _GemRow extends StatelessWidget {
  final GemDef gem;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _GemRow({
    required this.gem,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 16,
            color: selected ? AppColors.teal : AppColors.textFaint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ItemCatalogue.displayName(gem),
                  style: TextStyle(
                    color: rarityColour(gem.rarity),
                    fontSize: 13,
                  ),
                ),
                Text(
                  Equipping.describe(gem.modifiers).join(', '),
                  style: const TextStyle(color: AppColors.teal, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '×$count',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
