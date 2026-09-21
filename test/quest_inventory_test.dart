/// Managing what you carry **while the quest is still running** (playtest
/// ruling, 2026-09-21).
///
/// > *"Need inventory management during the quest — can't drop anything and
/// > accidentally filled up on dust. Need a way to consume consumables in
/// > between battles on a quest."*
///
/// Two doors come out of that: [GameState.discardFromBackpack], which destroys
/// a slot because the road has no shop, and [GameState.useBeltItem], which
/// drinks off the belt for free between fights. This file pins the rules they
/// answer to; `adventure_pack_panel_test.dart` pins that the screen reaches
/// them.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

final _woods = World.byId('whispering_woods');

/// A character standing in the woods with a run under way.
Future<GameState> _onAdventure() async {
  final g = GameState(_Mem(), PlayerProfile.newPlayer());
  await g.beginAdventure(_woods, rng: Random(3));
  return g;
}

/// The same character before they left — in town, where the shop is the
/// answer.
GameState _inTown() => GameState(_Mem(), PlayerProfile.newPlayer());

/// Puts [slot] in the pack and hands back the index it landed in.
int _carry(GameState g, InventorySlot slot) {
  g.profile.backpack = g.profile.backpack.withAdded(slot)!;
  return g.profile.backpack.slots.indexWhere((s) => s == slot);
}

void main() {
  group('dropping on the road', () {
    test('⚠️ a rolled item takes its own instance with it', () async {
      final g = await _onAdventure();
      // ⭐ TWO staves, so the slot under test is not the first match for its
      // def id: a mutant reaching for `withRemovedFirst(defId)` destroys the
      // wrong staff, and with rolled gear that is a different item.
      for (final id in ['inst-1', 'inst-2']) {
        g.profile.itemInstances[id] = ItemInstance(
          instanceId: id,
          defId: 'heartwood_stave',
        );
        _carry(g, InventorySlot(defId: 'heartwood_stave', instanceId: id));
      }
      final second = g.profile.backpack.slots.indexWhere(
        (s) => s?.instanceId == 'inst-2',
      );

      expect(await g.discardFromBackpack(second), isNull);

      expect(
        g.profile.backpack.countOf('heartwood_stave'),
        1,
        reason: 'a drop that leaves the slot filled did nothing at all',
      );
      expect(
        g.profile.backpack.contents.single.instanceId,
        'inst-1',
        reason:
            'the INDEX is the item, not the def id — a mutant dropping the '
            'first match burns the staff the player meant to keep',
      );
      expect(
        g.profile.itemInstances.containsKey('inst-2'),
        isFalse,
        reason:
            'the one-pool rule (ITEMS §10.3a): an instance whose slot is gone '
            'is a leak that grows the save forever — a mutant that only '
            'clears the slot fails here',
      );
      expect(
        g.profile.itemInstances.containsKey('inst-1'),
        isTrue,
        reason:
            'a mutant clearing every instance of that def id un-names the '
            'staff still in the pack',
      );
    });

    test('a fungible stack slot loses exactly one slot', () async {
      final g = await _onAdventure();
      for (var n = 0; n < 3; n++) {
        _carry(g, const InventorySlot(defId: 'oak_log'));
      }
      final i = g.profile.backpack.slots.indexWhere(
        (s) => s?.defId == 'oak_log',
      );

      expect(await g.discardFromBackpack(i), isNull);

      expect(
        g.profile.backpack.countOf('oak_log'),
        2,
        reason:
            'one tap destroys one log — a mutant that clears every matching '
            'slot empties the pack the player was trying to trim',
      );
    });

    test('⚠️ in town the shop is the answer, in those words', () async {
      final g = _inTown();
      final i = _carry(g, const InventorySlot(defId: 'oak_log'));

      expect(
        await g.discardFromBackpack(i),
        'Sell it in town.',
        reason:
            'burning an item in front of a buyer is the UI failing the '
            'player — a mutant that drops it anywhere fails here',
      );
      expect(
        g.profile.backpack.countOf('oak_log'),
        1,
        reason: 'a refusal that still destroyed the log is the worse bug',
      );
    });

    test('⚠️ a finished run is town again', () async {
      final g = await _onAdventure();
      final i = _carry(g, const InventorySlot(defId: 'oak_log'));
      await g.leaveAdventure();

      expect(
        await g.discardFromBackpack(i),
        'Sell it in town.',
        reason:
            'the gate is the run, not the map pin — a mutant checking only '
            '`run != null` lets a walked-out player burn their haul',
      );
      expect(g.profile.backpack.countOf('oak_log'), 1);
    });

    test('an empty slot is refused, not silently accepted', () async {
      final g = await _onAdventure();
      final before = g.profile.backpack.used;

      expect(
        await g.discardFromBackpack(0),
        isNotNull,
        reason:
            'a drop on nothing that reports success reads as the item having '
            'been destroyed',
      );
      expect(g.profile.backpack.used, before);
    });
  });

  group('drinking off the belt between fights', () {
    test('⭐ it heals and unloads exactly one copy', () async {
      final g = await _onAdventure();
      g.profile.belt = const Belt(
        loaded: ['sapwort_draught', 'sapwort_draught'],
      );
      g.run!.playerHp = 40;

      final outcome = await g.useBeltItem('sapwort_draught');

      expect(outcome.consumed, isTrue);
      expect(
        g.run!.playerHp,
        greaterThan(40),
        reason:
            'a belt potion that heals nothing between fights is the whole '
            'complaint the ruling answers',
      );
      expect(
        g.profile.belt.loaded,
        ['sapwort_draught'],
        reason:
            'one drink spends one draught — a mutant assigning an empty belt, '
            'or one filtering every copy out, drinks both at once',
      );
      expect(
        g.profile.backpack.countOf('sapwort_draught'),
        0,
        reason:
            'the belt is not the pack: a drink that also empties a pack slot '
            'is spending an item the player never touched',
      );
    });

    test('⚠️ what is not on the belt cannot be drunk off it', () async {
      final g = await _onAdventure();
      // In the pack, deliberately — the pack has its own door (`useItem`).
      _carry(g, const InventorySlot(defId: 'sapwort_draught'));
      g.run!.playerHp = 40;

      final outcome = await g.useBeltItem('sapwort_draught');

      expect(
        outcome.consumed,
        isFalse,
        reason:
            'a mutant reading the pack for `carried` drinks a potion off a '
            'belt that never held it — and then unloads nothing, so the pack '
            'copy is free healing forever',
      );
      expect(g.run!.playerHp, 40);
      expect(g.profile.belt.loaded, isEmpty);
      expect(
        g.profile.backpack.countOf('sapwort_draught'),
        1,
        reason: 'the pack copy is untouched by the belt door',
      );
    });

    test('⚠️ a refusal at full health leaves the belt loaded', () async {
      final g = await _onAdventure();
      g.profile.belt = const Belt(loaded: ['sapwort_draught']);
      // Full health by construction — `beginAdventure` starts there.
      final outcome = await g.useBeltItem('sapwort_draught');

      expect(outcome.consumed, isFalse);
      expect(
        outcome.message,
        contains('full health'),
        reason: 'a silent no-op reads as the button being broken',
      );
      expect(
        g.profile.belt.loaded,
        ['sapwort_draught'],
        reason:
            'a mutant unloading before checking `consumed` drinks the potion '
            'for no benefit — the game stealing an item',
      );
    });

    test('off an adventure there is no belt to drink from', () async {
      final g = _inTown();
      g.profile.belt = const Belt(loaded: ['sapwort_draught']);

      final outcome = await g.useBeltItem('sapwort_draught');

      expect(outcome.consumed, isFalse);
      expect(
        g.profile.belt.loaded,
        ['sapwort_draught'],
        reason:
            'healing out of a run heals a pool nothing is tracking, and '
            'would spend the potion to do it',
      );
    });
  });
}

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}
