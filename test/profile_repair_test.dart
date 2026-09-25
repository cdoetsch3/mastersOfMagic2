/// `PlayerProfile.repairContainers` — the sweep after the sync race of
/// 2026-09-25, which left Christian's storerooms naming ten instances his
/// character document no longer held.
///
/// ⭐ What these defend: a dangling id is dropped from whichever container
/// names it, never the container itself (a storeroom's stacks survive); an
/// instance nobody names is dropped from the pool; a consistent save is left
/// byte-identical; and `GameState.boot` runs it with one banner.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';

/// A consistent character: one staff worn, one in the pack, one stored, and
/// a stack of logs in the same storeroom.
PlayerProfile _consistent() {
  final p = PlayerProfile.newPlayer(name: 'Christian')
    ..locationId = 'hearthwood'
    ..backpack = Backpack.of(const [
      InventorySlot(defId: 'heartwood_stave', instanceId: 'packed'),
      InventorySlot(defId: 'oak_log'),
    ])
    ..storerooms['hearthwood'] = const Storeroom(
      stacks: {'oak_log': 6},
      instanceIds: ['stored'],
    );
  for (final id in ['worn', 'packed', 'stored']) {
    p.itemInstances[id] = ItemInstance(
      instanceId: id,
      defId: 'heartwood_stave',
    );
  }
  p.equipped[EquipSlot.mainHand] = 'worn';
  return p;
}

/// [p] round-tripped through JSON, the way every load sees it.
PlayerProfile _reloaded(PlayerProfile p) =>
    PlayerProfile.fromJson(jsonDecode(jsonEncode(p.toJson())));

void main() {
  test('a storeroom id absent from the pool is dropped, count 1, and the '
      'stacks are untouched', () {
    final json = _consistent().toJson();
    (json['storerooms'] as Map)['hearthwood'] = {
      'stacks': {'oak_log': 6},
      'instanceIds': ['stored', 'chmikx1dnj4a'],
    };
    final p = PlayerProfile.fromJson(jsonDecode(jsonEncode(json)));

    final dropped = p.repairContainers();

    expect(dropped, 1, reason: 'one dangling id, nothing else amiss');
    expect(
      p.storerooms['hearthwood']!.instanceIds,
      ['stored'],
      reason:
          '⚠️ the mutant this kills: a sweep that skips storerooms — the '
          'exact container the race left dangling',
    );
    expect(
      p.storerooms['hearthwood']!.stacks,
      {'oak_log': 6},
      reason:
          '⭐ repair drops the ID, not the container: six logs are not '
          'collateral damage of one missing staff',
    );
    expect(
      p.itemInstances.containsKey('stored'),
      isTrue,
      reason: 'the good id beside the dangling one keeps its instance',
    );
  });

  test('a dangling id in the pack or on the paper doll is dropped too', () {
    final p = _consistent()
      ..backpack = Backpack.of(const [
        InventorySlot(defId: 'heartwood_stave', instanceId: 'packed'),
        InventorySlot(defId: 'heartwood_stave', instanceId: 'ghost_pack'),
        InventorySlot(defId: 'oak_log'),
      ]);
    p.equipped[EquipSlot.offHand] = 'ghost_worn';

    final dropped = p.repairContainers();

    expect(dropped, 2, reason: 'one in the pack, one worn');
    expect(
      p.backpack.contents.map((s) => s.instanceId),
      ['packed', null],
      reason:
          'the ghost slot empties; the good staff and the fungible log '
          '(no instance id at all) stay',
    );
    expect(
      p.equipped,
      {EquipSlot.mainHand: 'worn'},
      reason:
          '⚠️ the mutant this kills: a sweep that skips `equipped` — '
          'a paper doll wearing nothing by name',
    );
  });

  test('an instance referenced by no container is dropped', () {
    final p = _consistent();
    p.itemInstances['orphan'] = const ItemInstance(
      instanceId: 'orphan',
      defId: 'heartwood_stave',
    );

    final dropped = p.repairContainers();

    expect(dropped, 1, reason: 'the orphan is the one repair');
    expect(
      p.itemInstances.keys.toSet(),
      {'worn', 'packed', 'stored'},
      reason:
          '⚠️ the mutant this kills: a one-directional sweep — an orphan is '
          'a staff nobody holds, and a save that grows forever',
    );
  });

  test('a consistent profile: count 0 and byte-identical JSON', () {
    final p = _reloaded(_consistent());
    final before = jsonEncode(p.toJson());

    expect(p.repairContainers(), 0, reason: 'nothing to repair');
    expect(
      jsonEncode(p.toJson()),
      before,
      reason:
          'a repair that rewrites a healthy save would cost every player a '
          'cloud write on every boot',
    );
  });

  test('boot repairs, banners once, and persists the repaired save', () async {
    final json = _consistent().toJson();
    (json['storerooms'] as Map)['hearthwood'] = {
      'stacks': {'oak_log': 6},
      'instanceIds': ['stored', 'a', 'b'],
    };
    final storage = _MemoryStorage(
      PlayerProfile.fromJson(jsonDecode(jsonEncode(json))),
    );

    final game = await GameState.boot(storage);

    expect(
      game.notice.value,
      GameState.repairNotice(2),
      reason: 'the player is told, once, what could not be saved',
    );
    expect(
      GameState.repairNotice(2),
      '2 items could not be recovered from an earlier sync conflict.',
      reason: 'the ruling\'s wording',
    );
    expect(storage.saved!.storerooms['hearthwood']!.instanceIds, [
      'stored',
    ], reason: 'the repaired profile is what reached the disk');
  });

  test('boot of a healthy save raises no notice', () async {
    final game = await GameState.boot(_MemoryStorage(_consistent()));
    expect(
      game.notice.value,
      isNull,
      reason: 'a banner on every boot would teach players to ignore it',
    );
  });

  testWidgets(
    'a dangling storeroom slot renders "Unknown item", never the id',
    (tester) async {
      final p = _consistent()
        ..storerooms['hearthwood'] = const Storeroom(
          instanceIds: ['chmikx1dnj4a'],
        );
      final game = GameState(_MemoryStorage(p), p);
      // Tall enough that the lazy ListView builds the storeroom below the fold.
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('chmikx1dnj4a'),
        findsNothing,
        reason:
            '⚠️ the symptom Christian saw: a Firestore-style id on a tile. '
            'Mutant: the old `return id` fallback',
      );
      expect(
        find.text('Unknown item'),
        findsWidgets,
        reason: 'the defensive label stands in for the missing instance',
      );
    },
  );
}

class _MemoryStorage implements ProfileStorage {
  PlayerProfile? held;
  PlayerProfile? saved;

  _MemoryStorage(this.held);

  @override
  Future<PlayerProfile?> load() async => held;

  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;

  @override
  Future<void> clear() async {}
}
