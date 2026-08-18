/// Equipping: the rules, the swaps, and the totals the duel reads.
///
/// ⭐ Mutation-verified where it matters: each assertion names the specific
/// wrong implementation it kills.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/catalogue/ashfall_vale_items.dart';
import 'package:masters_of_magic_2/game/items/catalogue/cinderpeak_items.dart';
import 'package:masters_of_magic_2/game/items/catalogue/whispering_woods_items.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
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

ItemInstance _inst(String id, String defId, {Quality? quality}) =>
    ItemInstance(instanceId: id, defId: defId, quality: quality);

/// Total XP that lands exactly on [level] (xpToNext is 100 + 50·(n−1)).
int _xpFor(int level) {
  var xp = 0;
  for (var n = 1; n < level; n++) {
    xp += 100 + (n - 1) * 50;
  }
  return xp;
}

/// A profile carrying [defId] in backpack slot 0, at [level].
GameState _gameCarrying(String defId, {int level = 10, Quality? quality}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = _xpFor(level)
    ..itemInstances['i1'] = _inst('i1', defId, quality: quality)
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

  group('describeTotals — the PANEL shows totals, the ITEM shows deltas', () {
    test('a stat with a base prints the resulting number', () {
      // ⭐ Level 1 is 100 HP flat (scaledMaxHp's baseline), so the arithmetic
      // in the assertion is the arithmetic a player would do.
      final lines = Equipping.describeTotals(
        const ItemModifiers(maxHpBonus: 11, accuracyBonus: 5),
        level: 1,
      );
      expect(
        lines,
        contains('Max health 111 (+11)'),
        reason: 'a bare "+11 max health" never answers "how much have I got"',
      );
      expect(
        lines,
        contains('Accuracy 85% (+5)'),
        reason: 'base hit is 100 − ElementTuning.baseMissPercent, not 100',
      );
    });

    test('max health follows the level curve, not a hardcoded 100', () {
      final lines = Equipping.describeTotals(
        const ItemModifiers(maxHpBonus: 11),
        level: 12,
      );
      expect(
        lines.single,
        'Max health ${MageState.scaledMaxHp(12) + 11} (+11)',
        reason: 'the panel must agree with GameState.maxHp at every level',
      );
      expect(lines.single, isNot(contains('111')));
    });

    test('the Cinder Loop reads as 5% of 155%, exactly as §9b.8 says', () {
      final lines = Equipping.describeTotals(
        CinderpeakItems.cinderLoop.modifiers,
        level: 1,
      );
      expect(lines, contains('Crit chance 5% (+5)'));
      expect(
        lines,
        contains('Crit damage 155% (+5)'),
        reason: 'a crit is 150% before gear — MageState.critDamage starts at 50',
      );
    });

    test('⚠️ a stat with no base keeps the delta form', () {
      final lines = Equipping.describeTotals(
        const ItemModifiers(
          damagePerCast: 2,
          shieldStrengthPercent: 10,
          healingReceivedPercent: 15,
          regrowPercent: 1,
          beltSlots: 2,
        ),
        level: 1,
      );
      // Nothing else grants these, so a "total" would be the bonus in disguise.
      expect(lines, contains('+2 damage per cast'));
      expect(lines, contains('+10% shield strength'));
      expect(lines, contains('+15% healing received'));
      expect(lines, contains('+2 belt slots'));
      expect(lines.where((l) => l.contains('(+')), isEmpty);
    });

    test('nothing worn prints nothing at all', () {
      expect(Equipping.describeTotals(ItemModifiers.none, level: 30), isEmpty);
    });

    test('⚠️ drift guard: both writers cover the same stats', () {
      // Every field non-zero, so a stat added to one writer and forgotten in
      // the other changes exactly one of these counts.
      const everything = ItemModifiers(
        accuracyBonus: 1,
        dodge: 1,
        critChance: 1,
        critDamage: 1,
        deflectChance: 1,
        deflectAmount: 1,
        maxHpBonus: 1,
        damagePerCast: 1,
        damagePerCharge: 1,
        shieldStrengthPercent: 1,
        healingReceivedPercent: 1,
        regrowPercent: 1,
        beltSlots: 1,
      );
      expect(
        Equipping.describeTotals(everything, level: 1),
        hasLength(Equipping.describe(everything).length),
        reason: 'a stat the item dialog shows and the panel does not is a '
            'stat the player is told about once and then never again',
      );
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

  group('take all from the Storeroom', () {
    GameState gameWithStored(int count, {int packUsed = 0}) {
      final profile = PlayerProfile.newPlayer()
        ..storerooms['hearthwood'] = Storeroom(stacks: {'oak_log': count})
        ..backpack = Backpack.of([
          for (var i = 0; i < packUsed; i++)
            const InventorySlot(defId: 'bindweed_fibre'),
        ]);
      return GameState(_MemStorage(), profile);
    }

    test('takes the whole stack when it fits, and says how many', () async {
      final game = gameWithStored(7);
      expect(await game.takeAllFromStoreroom('hearthwood', 'oak_log'), 7);
      expect(game.profile.backpack.countOf('oak_log'), 7);
      expect(
        game.profile.storerooms['hearthwood']!.stacks['oak_log'],
        isNull,
        reason: 'an emptied stack must leave, not linger as a zero',
      );
    });

    test('⭐ bounded by space, and that is a SUCCESS not an error', () async {
      // 18 slots taken, 40 stored: seven come home and the rest waits.
      final game = gameWithStored(40, packUsed: 18);
      expect(await game.takeAllFromStoreroom('hearthwood', 'oak_log'), 2);
      expect(game.profile.backpack.isFull, isTrue);
      expect(
        game.profile.storerooms['hearthwood']!.stacks['oak_log'],
        38,
        reason: 'the remainder must still be in the Storeroom, not vanished',
      );
    });

    test('a full pack or a missing stack moves nothing', () async {
      final full = gameWithStored(5, packUsed: 20);
      expect(await full.takeAllFromStoreroom('hearthwood', 'oak_log'), 0);
      expect(full.profile.storerooms['hearthwood']!.stacks['oak_log'], 5);

      final game = gameWithStored(5);
      expect(await game.takeAllFromStoreroom('hearthwood', 'bindweed_fibre'), 0);
      expect(await game.takeAllFromStoreroom('pennycross', 'oak_log'), 0,
          reason: 'another town\'s Storeroom is not reachable from here');
      expect(game.profile.backpack.used, 0);
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

    test('⚠️ and a Master one adds exactly the same two', () {
      final totals = Equipping.totals(
        equipped: {EquipSlot.belt: 'b'},
        instances: {'b': _inst('b', 'tuskhide_belt', quality: Quality.master)},
      );
      expect(totals.beltSlots, 2,
          reason: 'beltSlots is the non-combat axis (§6b.2): 2 × 1.4 = 2.8 → '
              '3 would be a crafting roll deciding carrying capacity');
    });
  });

  group('quality scales what an owned item grants (ruling 2026-08-18)', () {
    test('modifiersOf is the seam: definition × the instance\'s roll', () {
      // Sporecap Mantle is +12 HP / +2 accuracy.
      final def = ItemCatalogue.byId('sporecap_mantle');
      expect(
        Equipping.modifiersOf(def, _inst('m', 'sporecap_mantle',
            quality: Quality.master)).maxHpBonus,
        17,
        reason: '12 × 1.40 → 17; reading def.modifiers straight says 12');
      expect(
        Equipping.modifiersOf(def, _inst('m', 'sporecap_mantle',
            quality: Quality.rough)).accuracyBonus,
        2,
        reason: '2 × 0.80 = 1.6 → 2');
      expect(Equipping.modifiersOf(def).maxHpBonus, 12,
          reason: 'no instance — the Workbench preview of a thing not yet '
              'made shows the honest base');
      expect(Equipping.modifiersOf(WhisperingWoodsItems.oakLog).isEmpty, isTrue,
          reason: 'a log grants nothing, quality or not');
    });

    test('each worn piece scales on its OWN roll before they are summed', () {
      final totals = Equipping.totals(
        equipped: {
          EquipSlot.robeTop: 'a', // Sporecap Mantle: +12 HP, +2 acc
          EquipSlot.mainHand: 'b', // Oak Quarterstaff: +1/charge, +5 acc
        },
        instances: {
          'a': _inst('a', 'sporecap_mantle', quality: Quality.master),
          'b': _inst('b', 'oak_quarterstaff', quality: Quality.rough),
        },
      );
      expect(totals.maxHpBonus, 17, reason: '12 × 1.40 → 17');
      expect(totals.accuracyBonus, 7,
          reason: '⚠️ 3 (2 × 1.40) + 4 (5 × 0.80) — scaling the SUM by either '
              'roll gives 9 or 5, and one Master ring must never lift a whole '
              'wardrobe');
      expect(totals.damagePerCharge, 1, reason: '1 × 0.80 = 0.8 → 1');
    });

    test('an unrolled instance is worth exactly what it always was', () {
      final totals = Equipping.totals(
        equipped: {EquipSlot.robeTop: 'a'},
        instances: {'a': _inst('a', 'sporecap_mantle')},
      );
      expect(totals.maxHpBonus, 12,
          reason: 'a drop rolls an aspect, not a quality — treating null as '
              'anything but Standard rebalances every dropped item');
    });

    test('the stat lines quote the scaled numbers', () {
      final lines = Equipping.describe(
        Equipping.modifiersOf(
          ItemCatalogue.byId('sporecap_mantle'),
          _inst('m', 'sporecap_mantle', quality: Quality.master),
        ),
      );
      expect(lines, contains('+17 max health'),
          reason: 'a tooltip quoting the base while the duel uses the roll is '
              'the disagreement the one-writer rule exists to prevent');
    });

    test('the duel-facing totals scale too, through the same seam', () async {
      // ⭐ equipmentTotals is what reaches DuelController.playerGear.
      final game = _gameCarrying('oak_wand', quality: Quality.master);
      expect(await game.equipFromBackpack(0), isNull);
      expect(game.equipmentTotals.damagePerCast, 3,
          reason: '2 × 1.40 = 2.8 → 3; an unscaled duel is quality that '
              'changes the tooltip and nothing else');
    });
  });
}
