/// The belt: loading it, emptying it, and the 2026-08-17 "no belt, no slots"
/// migration.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — the duplicating load, the silently-eaten potion, the crash on an
/// old save.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

const _draught = 'sapwort_draught';
const _log = 'oak_log';

/// Total XP that lands exactly on [level] (xpToNext is 100 + 50·(n−1)).
int _xpFor(int level) {
  var xp = 0;
  for (var n = 1; n < level; n++) {
    xp += 100 + (n - 1) * 50;
  }
  return xp;
}

/// A level-15 character wearing [belt] (a def id, or null for none) and
/// carrying [carrying] in the pack.
GameState _game({String? belt, List<String> carrying = const []}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = _xpFor(15)
    ..backpack = Backpack.of([
      for (final id in carrying) InventorySlot(defId: id),
    ]);
  if (belt != null) {
    profile.itemInstances['b'] = ItemInstance(instanceId: 'b', defId: belt);
    profile.equipped[EquipSlot.belt] = 'b';
  }
  return GameState(_MemStorage(), profile);
}

void main() {
  group('capacity comes from the belt you are wearing', () {
    test('⚠️ none worn is ZERO slots (ruling 2026-08-17)', () {
      expect(
        _game().beltCapacity,
        0,
        reason: 'the two free slots were a hardcoded bug, not a rule',
      );
    });

    test('a Fawnhide is one, a Tuskhide is two', () {
      expect(_game(belt: 'fawnhide_belt').beltCapacity, 1);
      expect(_game(belt: 'tuskhide_belt').beltCapacity, 2);
    });
  });

  group('loading MOVES the item, it does not copy it', () {
    test('⭐ the draught leaves the pack and appears on the belt', () async {
      final game = _game(belt: 'tuskhide_belt', carrying: [_draught]);
      expect(await game.loadOntoBelt(_draught), isNull);
      expect(game.profile.belt.loaded, [_draught]);
      expect(
        game.profile.backpack.countOf(_draught),
        0,
        reason: 'it is carried ON the belt — a copy in the pack is a dupe bug',
      );
      expect(game.profile.backpack.used, 0);
    });

    test('two of the same stack onto two slots, one at a time', () async {
      final game = _game(
        belt: 'tuskhide_belt',
        carrying: [_draught, _draught],
      );
      expect(await game.loadOntoBelt(_draught), isNull);
      expect(await game.loadOntoBelt(_draught), isNull);
      expect(game.profile.belt.loaded, [_draught, _draught]);
      expect(game.profile.backpack.used, 0);
    });

    test('the load survives the round trip to disk', () async {
      final storage = _MemStorage();
      final profile = PlayerProfile.newPlayer()
        ..xp = _xpFor(15)
        ..itemInstances['b'] = const ItemInstance(
          instanceId: 'b',
          defId: 'tuskhide_belt',
        )
        ..equipped[EquipSlot.belt] = 'b'
        ..backpack = Backpack.of([const InventorySlot(defId: _draught)]);
      final game = GameState(storage, profile);
      await game.loadOntoBelt(_draught);
      final reloaded = PlayerProfile.fromJson(storage.saved!.toJson());
      expect(
        reloaded.belt.loaded,
        [_draught],
        reason: 'a belt that empties itself on restart is not a belt',
      );
    });
  });

  group('what the belt refuses, and why', () {
    test('⚠️ no belt worn is its own message, not "full"', () async {
      final game = _game(carrying: [_draught]);
      expect(await game.loadOntoBelt(_draught), contains('not wearing a belt'));
      expect(
        game.profile.backpack.countOf(_draught),
        1,
        reason: 'a refusal must never eat the item',
      );
      expect(game.profile.belt.used, 0);
    });

    test('a full belt refuses the third bottle', () async {
      final game = _game(
        belt: 'tuskhide_belt',
        carrying: [_draught, _draught, _draught],
      );
      await game.loadOntoBelt(_draught);
      await game.loadOntoBelt(_draught);
      expect(await game.loadOntoBelt(_draught), contains('full'));
      expect(game.profile.belt.used, 2);
      expect(game.profile.backpack.countOf(_draught), 1);
    });

    test('only Beltable things reach a duel', () async {
      final game = _game(belt: 'tuskhide_belt', carrying: [_log]);
      expect(await game.loadOntoBelt(_log), isNotNull);
      expect(await game.loadOntoBelt('no_such_item'), isNotNull);
      expect(game.profile.belt.used, 0);
    });

    test('you cannot belt what you are not carrying', () async {
      final game = _game(belt: 'tuskhide_belt');
      expect(await game.loadOntoBelt(_draught), contains('not in your pack'));
      expect(
        game.profile.belt.used,
        0,
        reason: 'loading from thin air would print potions',
      );
    });
  });

  group('unloading is the way back', () {
    test('the draught returns to the pack', () async {
      final game = _game(belt: 'tuskhide_belt', carrying: [_draught]);
      await game.loadOntoBelt(_draught);
      expect(await game.unloadFromBelt(_draught), isNull);
      expect(game.profile.belt.used, 0);
      expect(game.profile.backpack.countOf(_draught), 1);
    });

    test('⚠️ a full pack refuses rather than destroying it', () async {
      final game = _game(belt: 'tuskhide_belt', carrying: [_draught]);
      await game.loadOntoBelt(_draught);
      game.profile.backpack = Backpack.of([
        for (var i = 0; i < Carrying.backpackSlots; i++)
          const InventorySlot(defId: _log),
      ]);
      expect(await game.unloadFromBelt(_draught), contains('full'));
      expect(
        game.profile.belt.loaded,
        [_draught],
        reason: 'a refused unload must leave the item on the belt',
      );
    });

    test('unloading what is not there changes nothing', () async {
      final game = _game(belt: 'tuskhide_belt');
      expect(await game.unloadFromBelt(_draught), isNotNull);
      expect(game.profile.backpack.used, 0);
    });
  });

  group('⚠️ the migration: a save from when beltless meant two slots', () {
    /// A profile that was legal before the ruling: two loaded, no belt worn.
    PlayerProfile legacy({String location = 'hearthwood', int packUsed = 0}) =>
        PlayerProfile.newPlayer()
          ..locationId = location
          ..belt = const Belt(loaded: [_draught, _draught])
          ..backpack = Backpack.of([
            for (var i = 0; i < packUsed; i++) const InventorySlot(defId: _log),
          ]);

    test('overflow comes home to the pack, and nothing is lost', () {
      final game = GameState(_MemStorage(), legacy());
      expect(game.settleBeltOverflow(), 2);
      expect(game.profile.belt.used, 0);
      expect(
        game.profile.backpack.countOf(_draught),
        2,
        reason: 'the pack is the first place the player will look',
      );
    });

    test('a full pack in town falls back to THIS town\'s Storeroom', () {
      final game = GameState(_MemStorage(), legacy(packUsed: 20));
      expect(game.settleBeltOverflow(), 2);
      expect(game.profile.belt.used, 0);
      expect(game.profile.storerooms['hearthwood']!.stacks[_draught], 2);
      expect(
        game.profile.storerooms['pennycross'],
        isNull,
        reason: 'ITEMS §10.3c — only the Storeroom you are standing in',
      );
    });

    test('⭐ a full pack on the road keeps them belted, never deletes', () {
      final game = GameState(
        _MemStorage(),
        legacy(location: 'whispering_woods', packUsed: 20),
      );
      expect(game.settleBeltOverflow(), 0);
      expect(
        game.profile.belt.loaded,
        [_draught, _draught],
        reason: 'an over-capacity belt is legal; an eaten potion is not',
      );
      expect(game.profile.storerooms, isEmpty);
    });

    test('room for one: one comes home, one stays put', () {
      final game = GameState(
        _MemStorage(),
        legacy(location: 'whispering_woods', packUsed: 19),
      );
      expect(game.settleBeltOverflow(), 1);
      expect(game.profile.backpack.countOf(_draught), 1);
      expect(game.profile.belt.loaded, [_draught]);
    });

    test('a belt that fits is left completely alone', () {
      final profile = PlayerProfile.newPlayer()
        ..xp = _xpFor(15)
        ..itemInstances['b'] = const ItemInstance(
          instanceId: 'b',
          defId: 'tuskhide_belt',
        )
        ..equipped[EquipSlot.belt] = 'b'
        ..belt = const Belt(loaded: [_draught, _draught]);
      final game = GameState(_MemStorage(), profile);
      expect(game.settleBeltOverflow(), 0);
      expect(game.profile.belt.loaded, [_draught, _draught]);
      expect(game.profile.backpack.used, 0);
      // ⭐ Idempotent — it runs on every load, including after a sign-in.
      expect(game.settleBeltOverflow(), 0);
    });

    test('booting an old save settles it, and never throws', () async {
      final storage = _MemStorage()..saved = legacy();
      final game = await GameState.boot(storage);
      expect(game.profile.belt.used, 0);
      expect(game.profile.backpack.countOf(_draught), 2);
      expect(
        storage.saved!.belt.loaded,
        isEmpty,
        reason: 'the migration must reach disk, not only memory',
      );
    });
  });
}
