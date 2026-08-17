/// Equipping: the rules, the swaps, and the totals the duel reads.
///
/// ⭐ Mutation-verified where it matters: each assertion names the specific
/// wrong implementation it kills.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/catalogue/ashfall_vale_items.dart';
import 'package:masters_of_magic_2/game/items/catalogue/whispering_woods_items.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

ItemInstance _inst(String id, String defId) =>
    ItemInstance(instanceId: id, defId: defId);

/// Total XP that lands exactly on [level] (xpToNext is 100 + 50·(n−1)).
int _xpFor(int level) {
  var xp = 0;
  for (var n = 1; n < level; n++) {
    xp += 100 + (n - 1) * 50;
  }
  return xp;
}

/// A profile carrying [defId] in backpack slot 0, at [level].
GameState _gameCarrying(String defId, {int level = 10}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = _xpFor(level)
    ..itemInstances['i1'] = _inst('i1', defId)
    ..backpack = Backpack.of([
      InventorySlot(defId: defId, instanceId: 'i1'),
    ]);
  return GameState(_MemStorage(), profile);
}

void main() {
  group('totals', () {
    test('sums across worn items, and skips dangling ids', () {
      final totals = Equipping.totals(
        equipped: {
          EquipSlot.mainHand: 'a',
          EquipSlot.robeTop: 'b',
          // ⚠️ A dangling id must contribute nothing, not throw — the
          // profile guards against them, but a stats panel is the wrong
          // place to find out it failed.
          EquipSlot.ring: 'gone',
        },
        instances: {
          'a': _inst('a', 'oak_quarterstaff'), // +1/charge, +5 acc
          'b': _inst('b', 'bindweed_robe'), // +6 HP
        },
      );
      expect(totals.damagePerCharge, 1);
      expect(totals.accuracyBonus, 5);
      expect(totals.maxHpBonus, 6, reason: 'robe HP lost in the sum');
    });
  });

  group('rules', () {
    test('materials cannot be worn; low levels cannot wear high gear', () {
      expect(Equipping.refusal(WhisperingWoodsItems.oakLog, playerLevel: 60),
          isNotNull);
      // The Charlock is equip 14 — a level-13 is refused, a 14 is not.
      expect(
        Equipping.refusal(AshfallValeItems.theCharlock, playerLevel: 13),
        contains('14'),
      );
      expect(
        Equipping.refusal(AshfallValeItems.theCharlock, playerLevel: 14),
        isNull,
      );
    });
  });

  group('equip from backpack', () {
    test('moves the item onto the doll and out of the pack', () async {
      final game = _gameCarrying('oak_wand');
      expect(await game.equipFromBackpack(0), isNull);
      expect(game.profile.equipped[EquipSlot.mainHand], 'i1');
      expect(game.profile.backpack.countOf('oak_wand'), 0,
          reason: 'equipping must not duplicate the item');
      expect(game.equipmentTotals.damagePerCast, 2);
    });

    test('is a swap: the displaced item lands in the vacated slot', () async {
      final game = _gameCarrying('oak_wand');
      game.profile.itemInstances['i2'] = _inst('i2', 'oak_quarterstaff');
      game.profile.equipped[EquipSlot.mainHand] = 'i2';
      expect(await game.equipFromBackpack(0), isNull);
      expect(game.profile.equipped[EquipSlot.mainHand], 'i1');
      // ⭐ The staff is back in the pack — a swap can never fail for space.
      expect(game.profile.backpack.countOf('oak_quarterstaff'), 1);
    });

    test('refuses under-level gear without touching anything', () async {
      final game = _gameCarrying('birch_wand', level: 5); // equip 10
      expect(await game.equipFromBackpack(0), contains('10'));
      expect(game.profile.equipped, isEmpty);
      expect(game.profile.backpack.countOf('birch_wand'), 1,
          reason: 'a refusal must not eat the item');
    });
  });

  group('unequip', () {
    test('returns the item to the pack — unless the pack is full', () async {
      final game = _gameCarrying('oak_wand');
      await game.equipFromBackpack(0);
      expect(await game.unequip(EquipSlot.mainHand), isNull);
      expect(game.profile.equipped, isEmpty);
      expect(game.profile.backpack.countOf('oak_wand'), 1);

      // Now with a full pack.
      await game.equipFromBackpack(0);
      final filler = [
        for (var i = 0; i < 20; i++) const InventorySlot(defId: 'oak_log'),
      ];
      game.profile.backpack = Backpack.of(filler);
      expect(await game.unequip(EquipSlot.mainHand), contains('full'));
      expect(game.profile.equipped[EquipSlot.mainHand], 'i1',
          reason: 'a refused unequip must leave the item worn');
    });
  });

  group('equip from the Storeroom', () {
    test('wears stored gear and stows the displaced piece in exchange',
        () async {
      final game = _gameCarrying('oak_wand');
      await game.equipFromBackpack(0);
      game.profile.itemInstances['i2'] = _inst('i2', 'oak_quarterstaff');
      game.profile.storerooms['hearthwood'] =
          const Storeroom(instanceIds: ['i2']);

      expect(await game.equipFromStoreroom('i2'), isNull);
      expect(game.profile.equipped[EquipSlot.mainHand], 'i2');
      final room = game.profile.storerooms['hearthwood']!;
      expect(room.instanceIds, ['i1'],
          reason: 'the wand must be stowed, not vanished');
      expect(game.profile.backpack.used, 0,
          reason: 'a wardrobe swap must not touch the pack');
    });

    test('refuses gear stored in another town', () async {
      final game = _gameCarrying('oak_wand');
      game.profile.itemInstances['i2'] = _inst('i2', 'oak_quarterstaff');
      game.profile.storerooms['pennycross'] =
          const Storeroom(instanceIds: ['i2']);
      // The player is in Hearthwood; the staff is in Pennycross.
      expect(await game.equipFromStoreroom('i2'), isNotNull);
      expect(game.profile.equipped, isEmpty);
    });
  });

  group('deposit all (backpack only, never equipped)', () {
    test('empties the whole pack into the Storeroom and reports the count',
        () async {
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'bindweed_fibre'),
        ]);
      final game = GameState(_MemStorage(), profile);

      expect(await game.depositAll('hearthwood'), 3);
      expect(game.profile.backpack.used, 0);
      final room = game.profile.storerooms['hearthwood']!;
      expect(room.stacks['oak_log'], 2, reason: 'fungibles collapse to counts');
      expect(room.stacks['bindweed_fibre'], 1);
    });

    test('⚠️ never touches equipped gear — the whole ruling', () async {
      final game = _gameCarrying('oak_wand');
      await game.equipFromBackpack(0); // the wand is now WORN, not in the pack
      game.profile.backpack = Backpack.of(const [
        InventorySlot(defId: 'oak_log'),
      ]);

      final moved = await game.depositAll('hearthwood');

      expect(moved, 1, reason: 'only the loose log moves');
      expect(game.profile.equipped[EquipSlot.mainHand], 'i1',
          reason: 'the worn wand must still be equipped');
      expect(game.profile.storerooms['hearthwood']?.instanceIds ?? const [],
          isNot(contains('i1')),
          reason: 'equipped gear must never reach the Storeroom');
    });

    test('an empty pack is a no-op that moves nothing', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      expect(await game.depositAll('hearthwood'), 0);
    });
  });

  group('a run begins at the GEARED maximum', () {
    test('the robe\'s health is in the pool the first encounter loads with',
        () async {
      // ⚠️ The bug this kills: beginAdventure seeded the run from
      // MageState.scaledMaxHp(level) alone, while the duel builds the same
      // mage as curve + gear. The player walked into encounter one already
      // missing exactly their gear bonus — reported as "148 / 159 when
      // combat loaded".
      final game = _gameCarrying('bindweed_robe'); // +6 max health
      expect(await game.equipFromBackpack(0), isNull,
          reason: 'guard: the robe must actually be worn');
      final bonus = game.equipmentTotals.maxHpBonus;
      expect(bonus, greaterThan(0),
          reason: 'guard: a zero-bonus item would make every assertion below '
              'pass against the broken implementation too');

      final run = await game.beginAdventure(
        World.byId('whispering_woods'),
        rng: Random(1),
      );

      final curveOnly = MageState.scaledMaxHp(game.profile.level);
      expect(run.playerHp, game.maxHp,
          reason: 'the run must start full against the SAME pool the duel and '
              'the ration both read');
      expect(run.playerHp, curveOnly + bonus);
      expect(run.playerHp, isNot(curveOnly),
          reason: 'seeding from the bare level curve is the whole bug');
    });

    test('an ungeared mage is unaffected — the fix adds nothing from nowhere',
        () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      final run = await game.beginAdventure(
        World.byId('whispering_woods'),
        rng: Random(1),
      );
      expect(run.playerHp, MageState.scaledMaxHp(game.profile.level));
    });
  });

  group('the belt sizes itself off gear', () {
    test('a worn Tuskhide Belt adds its two slots', () {
      final totals = Equipping.totals(
        equipped: {EquipSlot.belt: 'b'},
        instances: {'b': _inst('b', 'tuskhide_belt')},
      );
      expect(totals.beltSlots, 2);
    });
  });
}
