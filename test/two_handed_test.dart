/// Two-handed weapons: a staff and an offhand cannot be worn together
/// (ruling, Christian 2026-09-21).
///
/// ⭐ **The rule has three faces and they must agree**: the catalogue fact
/// (`EquipmentDef.twoHanded`), the pure helper the UI greys a button with
/// (`Equipping.handsRefusal`), and the two `GameState` equip paths that
/// actually move the gear. Every test below pins one of the three against the
/// others, because a rule enforced in two places out of three is a rule the
/// player meets as a bug.
///
/// ⚠️ Mutation-verified: each `reason:` names the wrong implementation it
/// kills.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';

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

/// The exact words the ruling wrote down. ⚠️ **Spelled out here rather than
/// read off [Equipping]** — a test that quotes the constant it is checking
/// passes against any mutant that renames the string in one place.
const _bothHands = 'Both hands are on your staff.';
const _noRoom = 'Your pack is full — take off your offhand first.';

const _staff = 'oak_quarterstaff';
const _knot = 'oak_knot';
const _wand = 'oak_wand';

/// A level-10 mage holding [packed] in the backpack, wearing [worn].
///
/// ⭐ Copied from `equipping_test.dart`'s shape on purpose: one profile, one
/// instance pool, containers holding ids (ITEMS §10.3a).
GameState _game({
  List<String> packed = const [],
  Map<EquipSlot, String> worn = const {},
  List<String> filler = const [],
}) {
  final profile = PlayerProfile.newPlayer()..xp = 5000; // comfortably past 10
  final slots = <InventorySlot>[];
  for (var i = 0; i < packed.length; i++) {
    final id = 'p$i';
    profile.itemInstances[id] = _inst(id, packed[i]);
    slots.add(InventorySlot(defId: packed[i], instanceId: id));
  }
  for (final defId in filler) {
    slots.add(InventorySlot(defId: defId));
  }
  worn.forEach((slot, defId) {
    final id = 'w_${slot.name}';
    profile.itemInstances[id] = _inst(id, defId);
    profile.equipped[slot] = id;
  });
  profile.backpack = Backpack.of(slots);
  return GameState(_MemStorage(), profile);
}

void main() {
  group('legacy saves: a staff already worn over a knot (settleTwoHanded)', () {
    test('⭐ the knot moves to the pack when there is room', () {
      final game = _game(
        worn: {EquipSlot.mainHand: _staff, EquipSlot.offHand: _knot},
      );
      game.settleTwoHanded();
      expect(
        game.profile.equipped[EquipSlot.offHand],
        isNull,
        reason:
            'a mutant that never runs the settle leaves the illegal '
            'wardrobe every equip path now refuses to build',
      );
      expect(
        game.profile.backpack.countOf(_knot),
        1,
        reason:
            'the knot is moved, not destroyed — a boot must never eat an '
            'item',
      );
      expect(
        game.profile.equipped[EquipSlot.mainHand],
        isNotNull,
        reason: 'the staff stays on; only the offhand is illegal',
      );
    });

    test('⚠️ a full pack leaves both on rather than destroying the knot', () {
      final game = _game(
        worn: {EquipSlot.mainHand: _staff, EquipSlot.offHand: _knot},
        filler: List.filled(Carrying.backpackSlots, _knot),
      );
      game.settleTwoHanded();
      expect(
        game.profile.equipped[EquipSlot.offHand],
        isNotNull,
        reason:
            'a mutant that removes the offhand without a pack slot to '
            'put it in destroys the item',
      );
    });

    test('idempotent, and a no-op for a wand', () {
      final game = _game(
        worn: {EquipSlot.mainHand: _wand, EquipSlot.offHand: _knot},
      );
      game.settleTwoHanded();
      game.settleTwoHanded();
      expect(
        game.profile.equipped[EquipSlot.offHand],
        isNotNull,
        reason:
            'a mutant that treats every main hand as two-handed strips a '
            'legal wand-and-knot wardrobe',
      );
    });
  });

  group('the catalogue knows which weapons take both hands', () {
    test('⭐ every Quarterstaff is two-handed, and no Wand is', () {
      final equipment = ItemCatalogue.all.whereType<EquipmentDef>().toList();
      final staves = equipment.where((d) => d.form == 'Quarterstaff').toList();
      final wands = equipment.where((d) => d.form == 'Wand').toList();

      expect(
        staves.length,
        greaterThanOrEqualTo(5),
        reason:
            'guard: four crafted quarterstaffs plus the Heartwood Staff — '
            'an empty list would make every assertion below vacuous',
      );
      expect(
        staves.where((d) => !d.twoHanded).map((d) => d.id),
        isEmpty,
        reason:
            'a Quarterstaff left one-handed can still be worn with a '
            'knot, which is exactly the pairing the ruling deleted',
      );
      expect(
        wands.where((d) => d.twoHanded).map((d) => d.id),
        isEmpty,
        reason:
            'wands stay one-handed — a blanket "every main hand is a '
            'two-hander" mutant kills the wand+knot lane outright',
      );
      expect(
        wands,
        isNotEmpty,
        reason: 'guard: the wand half of the lane choice must exist',
      );
    });

    test('the Heartwood Staff is in, by form and not by name', () {
      final staff = ItemCatalogue.byId('heartwood_stave') as EquipmentDef;
      expect(staff.form, 'Quarterstaff');
      expect(
        staff.twoHanded,
        isTrue,
        reason:
            'the boss unique is a Quarterstaff too — flagging only the '
            'crafted four would let the best staff in the game dodge the rule',
      );
    });

    test('⚠️ only a main hand may be two-handed — the constructor says so', () {
      expect(
        () => EquipmentDef(
          id: 'two_handed_hat',
          rarity: Rarity.common,
          lore: '',
          slot: EquipSlot.offHand,
          form: 'Knot',
          material: 'Oak',
          twoHanded: true,
        ),
        throwsA(isA<AssertionError>()),
        reason:
            'a two-handed offhand would disable the offhand slot by '
            'wearing it — dropping the assert lets that ship silently',
      );
      expect(
        () => EquipmentDef(
          id: 'ordinary_staff',
          rarity: Rarity.common,
          lore: '',
          slot: EquipSlot.mainHand,
          form: 'Quarterstaff',
          material: 'Oak',
          twoHanded: true,
        ),
        returnsNormally,
        reason:
            '⚠️ the control: an assert inverted to reject the main hand '
            'would pass the test above and ban every staff in the game',
      );
      expect(
        () => EquipmentDef(
          id: 'ordinary_knot',
          rarity: Rarity.common,
          lore: '',
          slot: EquipSlot.offHand,
          form: 'Knot',
          material: 'Oak',
        ),
        returnsNormally,
        reason: 'and a plain offhand is untouched — the default is false',
      );
    });
  });

  group('equipping a staff takes the offhand off', () {
    test('⭐ the knot and the displaced wand both land in the pack', () async {
      final game = _game(
        packed: [_staff],
        worn: {EquipSlot.mainHand: _wand, EquipSlot.offHand: _knot},
      );

      expect(await game.equipFromBackpack(0), isNull);

      expect(
        game.profile.equipped[EquipSlot.mainHand],
        'p0',
        reason: 'the staff must actually be worn',
      );
      expect(
        game.profile.equipped[EquipSlot.offHand],
        isNull,
        reason:
            'the whole ruling: a staff cannot be held over a knot. An '
            'offhand left equipped would still reach the duel through '
            'Equipping.totals',
      );
      expect(
        game.profile.backpack.countOf(_knot),
        1,
        reason:
            'the knot is taken OFF, not destroyed — silently eating gear '
            'is the worst failure this file can have',
      );
      expect(
        game.profile.backpack.countOf(_wand),
        1,
        reason:
            'the displaced main hand still lands in the slot the staff '
            'vacated (the pre-ruling behaviour, unchanged)',
      );
      expect(
        game.profile.backpack.countOf(_staff),
        0,
        reason: 'equipping must not duplicate the staff',
      );
      expect(
        game.equipmentTotals.accuracyBonus,
        5,
        reason:
            'the staff alone: +5. Reading 8 means the knot\'s +3 is still '
            'in the wardrobe the duel sums',
      );
    });

    test('a staff over an EMPTY offhand is an ordinary swap', () async {
      final game = _game(packed: [_staff], worn: {EquipSlot.mainHand: _wand});
      expect(await game.equipFromBackpack(0), isNull);
      expect(game.profile.equipped[EquipSlot.mainHand], 'p0');
      expect(
        game.profile.backpack.countOf(_wand),
        1,
        reason:
            'a two-hander with nothing to displace must not start '
            'refusing or dropping the main hand it replaces',
      );
    });

    test('⚠️ a full pack refuses, and changes NOTHING', () async {
      // 20 slots: the staff, plus 19 logs. Removing the staff frees one slot,
      // the displaced wand takes it back, and the knot has nowhere to go.
      final game = _game(
        packed: [_staff],
        worn: {EquipSlot.mainHand: _wand, EquipSlot.offHand: _knot},
        filler: [for (var i = 0; i < 19; i++) 'oak_log'],
      );
      expect(
        game.profile.backpack.free,
        0,
        reason:
            'guard: the pack must really be full for this to be the '
            'no-room case',
      );

      expect(
        await game.equipFromBackpack(0),
        _noRoom,
        reason:
            'a bare "Your pack is full." sends the player to the wrong '
            'screen — the fix is taking the OFFHAND off',
      );
      expect(
        _noRoom,
        Equipping.noRoomForOffhandMessage,
        reason: 'the refusal and the shared constant must be one string',
      );

      expect(
        game.profile.equipped[EquipSlot.mainHand],
        'w_mainHand',
        reason:
            'a refusal computed halfway through the swap would leave the '
            'staff worn and the wand nowhere',
      );
      expect(
        game.profile.equipped[EquipSlot.offHand],
        'w_offHand',
        reason:
            'the knot must still be worn — the whole point of refusing '
            'BEFORE mutating',
      );
      expect(
        game.profile.backpack.countOf(_staff),
        1,
        reason: 'a refusal must not eat the staff',
      );
      expect(
        game.profile.backpack.countOf('oak_log'),
        19,
        reason: 'and must not quietly drop a log to make room either',
      );
    });

    test(
      'the offhand goes to the STOREROOM when dressing from storage',
      () async {
        final game = _game(
          worn: {EquipSlot.mainHand: _wand, EquipSlot.offHand: _knot},
        );
        game.profile.itemInstances['s1'] = _inst('s1', _staff);
        game.profile.storerooms['hearthwood'] = const Storeroom(
          instanceIds: ['s1'],
        );

        expect(await game.equipFromStoreroom('s1'), isNull);

        final room = game.profile.storerooms['hearthwood']!;
        expect(game.profile.equipped[EquipSlot.mainHand], 's1');
        expect(
          game.profile.equipped[EquipSlot.offHand],
          isNull,
          reason:
              'the Storeroom path must enforce the same rule as the pack '
              'path — a rule in one of two equip methods is half a rule',
        );
        expect(
          room.instanceIds,
          containsAll(<String>['w_offHand', 'w_mainHand']),
          reason:
              'BOTH displaced pieces are stowed; a Storeroom is unbounded '
              '(ITEMS §10.3c), so this direction can never refuse for space',
        );
        expect(
          room.instanceIds,
          isNot(contains('s1')),
          reason: 'the staff left storage — it is being worn',
        );
      },
    );
  });

  group('an offhand cannot go on over a staff', () {
    test('⭐ refused, in the same words the pure helper uses', () async {
      final game = _game(packed: [_knot], worn: {EquipSlot.mainHand: _staff});

      final fromState = await game.equipFromBackpack(0);
      final fromHelper = Equipping.handsRefusal(
        def: ItemCatalogue.byId(_knot) as EquipmentDef,
        wornMainHand: ItemCatalogue.byId(_staff) as EquipmentDef,
      );

      expect(fromState, _bothHands);
      expect(
        fromState,
        fromHelper,
        reason:
            'the greyed-out Equip button quotes handsRefusal while the '
            'tap quotes GameState — a helper returning ANY other string is '
            'two screens disagreeing about one rule',
      );
      expect(
        _bothHands,
        Equipping.bothHandsMessage,
        reason: 'and both must be the constant the ruling wrote down',
      );
      expect(
        game.profile.equipped[EquipSlot.offHand],
        isNull,
        reason: 'a refusal that still equips is the bug, not the message',
      );
      expect(
        game.profile.backpack.countOf(_knot),
        1,
        reason: 'a refusal must not eat the knot',
      );
    });

    test('⚠️ a WAND is one-handed: the knot goes on', () async {
      final game = _game(packed: [_knot], worn: {EquipSlot.mainHand: _wand});

      expect(
        await game.equipFromBackpack(0),
        isNull,
        reason:
            'the mutant this kills: refusing on "a main hand is worn" '
            'rather than on "a TWO-HANDED main hand is worn", which deletes '
            'the wand+knot lane (§9b.8)',
      );
      expect(game.profile.equipped[EquipSlot.offHand], 'p0');
      expect(
        game.equipmentTotals.accuracyBonus,
        3,
        reason: 'the knot really is worn, not merely un-refused',
      );
    });

    test('the Storeroom path refuses too', () async {
      final game = _game(worn: {EquipSlot.mainHand: _staff});
      game.profile.itemInstances['s1'] = _inst('s1', _knot);
      game.profile.storerooms['hearthwood'] = const Storeroom(
        instanceIds: ['s1'],
      );

      expect(await game.equipFromStoreroom('s1'), _bothHands);
      expect(
        game.profile.storerooms['hearthwood']!.instanceIds,
        contains('s1'),
        reason: 'a refused withdraw must leave the knot in storage',
      );
    });

    test('handsRefusal judges only the offhand, and only against a staff', () {
      final knot = ItemCatalogue.byId(_knot) as EquipmentDef;
      final staff = ItemCatalogue.byId(_staff) as EquipmentDef;
      final wand = ItemCatalogue.byId(_wand) as EquipmentDef;
      final hood = ItemCatalogue.byId('bindweed_hood') as EquipmentDef;

      expect(
        Equipping.handsRefusal(def: knot, wornMainHand: staff),
        _bothHands,
      );
      expect(
        Equipping.handsRefusal(def: knot, wornMainHand: wand),
        isNull,
        reason: 'a wand leaves the hand free',
      );
      expect(
        Equipping.handsRefusal(def: knot, wornMainHand: null),
        isNull,
        reason:
            'an empty main hand refuses nothing — a null read as "two '
            'handed" would lock the offhand slot on a naked mage',
      );
      expect(
        Equipping.handsRefusal(def: staff, wornMainHand: staff),
        isNull,
        reason:
            '⚠️ the other direction is a DISPLACEMENT, not a refusal: a '
            'staff you cannot swap for another staff is unplayable',
      );
      expect(
        Equipping.handsRefusal(def: hood, wornMainHand: staff),
        isNull,
        reason: 'a hat has nothing to do with your hands',
      );
    });
  });

  group('the player can see why', () {
    test('slotLabel says two-handed, and only for a two-hander', () {
      expect(
        Equipping.slotLabel(ItemCatalogue.byId(_staff) as EquipmentDef),
        'Main hand · two-handed',
      );
      expect(
        Equipping.slotLabel(ItemCatalogue.byId(_wand) as EquipmentDef),
        'Main hand',
        reason:
            'a wand tagged two-handed would teach the player a rule the '
            'game does not enforce',
      );
      expect(
        Equipping.slotLabel(ItemCatalogue.byId(_knot) as EquipmentDef),
        'Off hand',
      );
    });

    testWidgets('the paper doll marks the worn staff', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final game = _game(packed: [_knot], worn: {EquipSlot.mainHand: _staff});
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('MAIN HAND · TWO-HANDED'),
        findsOneWidget,
        reason:
            'the doll is where the dead off-hand chip is noticed, so it '
            'is where the reason belongs',
      );
      expect(
        find.text('MAIN HAND'),
        findsNothing,
        reason:
            'guard: the plain label must have been REPLACED, not joined '
            'by a second chip',
      );
    });

    testWidgets('⭐ the backpack Equip button is dead, and says why', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final game = _game(packed: [_knot], worn: {EquipSlot.mainHand: _staff});
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester
          .pumpAndSettle(); // ⚠️ was a bare pump: under full-suite load the tile was not built yet (flake seen by four lanes)

      await tester.longPress(find.text('Oak Knot').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Equip: $_bothHands'),
        findsOneWidget,
        reason:
            'greyed WITH the reason, never hidden (2026-08-17) — a '
            'vanished Equip button reads as "this is not equipment"',
      );
      final equip = find.widgetWithText(TextButton, 'Equip');
      expect(equip, findsOneWidget);
      expect(
        tester.widget<TextButton>(equip).onPressed,
        isNull,
        reason:
            'a live button that refuses on tap is the round trip this '
            'wiring exists to delete',
      );
    });
  });
}
