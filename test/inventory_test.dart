import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';

const _log = InventorySlot(defId: 'oak_log');

void main() {
  group('the backpack is slots, not stacks', () {
    test('twenty logs fill it and the twenty-first does not fit', () {
      var pack = Backpack.empty();
      for (var i = 0; i < Carrying.backpackSlots; i++) {
        final next = pack.withAdded(_log);
        expect(next, isNotNull, reason: 'slot ${i + 1} should fit');
        pack = next!;
      }
      expect(pack.isFull, isTrue);
      expect(pack.countOf('oak_log'), Carrying.backpackSlots);
      expect(
        pack.withAdded(_log),
        isNull,
        reason: 'a full pack must refuse, never silently drop loot',
      );
    });

    test('withAll reports overflow instead of discarding it', () {
      final r = Backpack.empty().withAll([
        for (var i = 0; i < Carrying.backpackSlots + 3; i++) _log,
      ]);
      expect(r.pack.isFull, isTrue);
      expect(r.overflow, hasLength(3));
    });

    test('removing frees a slot', () {
      final pack = Backpack.empty()
          .withAdded(_log)!
          .withRemovedFirst('oak_log');
      expect(pack.used, 0);
    });

    test('survives a round trip, holes included', () {
      final pack = Backpack.of([_log, null, _log]);
      final back = Backpack.fromJson(pack.toJson());
      expect(back.used, 2);
      expect(back.slots[1], isNull);
      expect(back.slots.length, Carrying.backpackSlots);
    });
  });

  group('a Storeroom belongs to one city', () {
    test('depositing in Hearthwood does not put it in Forgeholm', () {
      final p = PlayerProfile.newPlayer();
      p.storerooms['hearthwood'] = const Storeroom().withDeposited(_log);
      expect(p.storerooms['hearthwood']!.itemCount, 1);
      expect(
        p.storerooms['forgeholm'],
        isNull,
        reason: 'ITEMS §10.3c — moving it means carrying it',
      );
    });

    test('fungibles collapse to counts; non-fungibles stay distinct', () {
      var room = const Storeroom();
      for (var i = 0; i < 50; i++) {
        room = room.withDeposited(_log);
      }
      room = room.withDeposited(
        const InventorySlot(defId: 'oak_quarterstaff', instanceId: 'uuid-1'),
      );
      room = room.withDeposited(
        const InventorySlot(defId: 'oak_quarterstaff', instanceId: 'uuid-2'),
      );
      expect(room.stacks['oak_log'], 50);
      expect(room.instanceIds, hasLength(2));
      expect(room.itemCount, 52);
    });

    test('withdrawing what is not there returns nothing, never a copy', () {
      final r = const Storeroom().withWithdrawn(_log);
      expect(r.taken, isNull, reason: 'a withdraw that always succeeds dupes');
      expect(r.room.isEmpty, isTrue);
    });

    test('deposit then withdraw is a round trip', () {
      final room = const Storeroom().withDeposited(_log);
      final r = room.withWithdrawn(_log);
      expect(r.taken, isNotNull);
      expect(r.room.isEmpty, isTrue);
    });
  });

  group('the profile round trips its containers', () {
    test('backpack and storerooms survive save and load', () {
      final p = PlayerProfile.newPlayer()
        ..backpack = Backpack.empty().withAdded(_log)!
        ..storerooms['hearthwood'] = const Storeroom(stacks: {'oak_log': 9});
      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.backpack.countOf('oak_log'), 1);
      expect(back.storerooms['hearthwood']!.stacks['oak_log'], 9);
    });

    test('a fresh character carries and stores nothing', () {
      final back = PlayerProfile.fromJson(PlayerProfile.newPlayer().toJson());
      expect(back.backpack.used, 0);
      expect(back.storerooms, isEmpty);
    });
  });

  group('instances are one pool that containers point into', () {
    test('an instance survives moving between containers', () {
      final p = PlayerProfile.newPlayer();
      const inst = ItemInstance(
        instanceId: 'uuid-1',
        defId: 'oak_quarterstaff',
        quality: Quality.ornate,
      );
      p.itemInstances['uuid-1'] = inst;
      const slot = InventorySlot(
        defId: 'oak_quarterstaff',
        instanceId: 'uuid-1',
      );
      p.backpack = p.backpack.withAdded(slot)!;

      // ... carry it to town and stow it
      p.backpack = p.backpack.withRemovedFirst('oak_quarterstaff');
      p.storerooms['hearthwood'] = const Storeroom().withDeposited(slot);

      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.storerooms['hearthwood']!.instanceIds, ['uuid-1']);
      expect(
        back.itemInstances['uuid-1']!.quality,
        Quality.ornate,
        reason: 'the same staff, not a fresh one',
      );
    });

    test('every referenced instance id resolves', () {
      // ⚠️ The cost of a shared pool is dangling ids. This is the guard.
      final p = PlayerProfile.newPlayer();
      p.itemInstances['uuid-1'] = const ItemInstance(
        instanceId: 'uuid-1',
        defId: 'oak_quarterstaff',
      );
      p.backpack = p.backpack.withAdded(
        const InventorySlot(defId: 'oak_quarterstaff', instanceId: 'uuid-1'),
      )!;
      p.storerooms['hearthwood'] = const Storeroom(instanceIds: ['uuid-1']);

      final referenced = <String>{
        for (final s in p.backpack.contents)
          if (s.instanceId != null) s.instanceId!,
        for (final r in p.storerooms.values) ...r.instanceIds,
      };
      for (final id in referenced) {
        expect(p.itemInstances, contains(id), reason: '$id is dangling');
      }
    });
  });

  group('the belt only takes what combat can reach', () {
    test('it round trips and unloads', () {
      final belt = const Belt().withLoaded('lesser_tonic');
      expect(belt.used, 1);
      expect(Belt.fromJson(belt.toJson()).loaded, ['lesser_tonic']);
      expect(belt.withUnloaded('lesser_tonic').used, 0);
    });
  });
}
