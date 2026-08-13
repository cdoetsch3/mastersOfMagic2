/// What comes home is the player's choice, and what is left is gone.
///
/// ⭐ The bug this guards: ending a run banked everything automatically and
/// silently dropped whatever did not fit. A playtester lost a rare that way and
/// never saw it happen. The take-home step replaces that with a decision —
/// shown at **every** ending that kept its loot, so it is a ritual rather than
/// a surprise sprung on a full backpack.
///
/// ⚠️ The invariant every test here circles: the chosen loot and the abandoned
/// loot leave the run in the **same write**. A run saved still holding loot
/// that is already in the backpack hands it over again on the next launch.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

final _woods = World.byId('whispering_woods');

// The rarity ladder, in items that actually exist (ITEMS §8).
const _log = InventorySlot(defId: 'oak_log'); // common
const _crystal = InventorySlot(defId: 'flora_crystal'); // uncommon
const _mantle = InventorySlot(
  defId: 'sporecap_mantle', // rare, non-fungible
  instanceId: 'inst-mantle',
);
const _staff = InventorySlot(
  defId: 'heartwood_stave', // epic, non-fungible
  instanceId: 'inst-staff',
);
const _rolls = {
  'inst-mantle': ItemInstance(
    instanceId: 'inst-mantle',
    defId: 'sporecap_mantle',
  ),
  'inst-staff': ItemInstance(
    instanceId: 'inst-staff',
    defId: 'heartwood_stave',
  ),
};

/// A run that has just been walked out of, holding [loot] and nothing banked.
///
/// [packUsed] pre-fills the backpack, because the whole picker exists for the
/// case where the haul does not fit.
Future<GameState> _walkedOutWith(
  List<InventorySlot> loot, {
  int packUsed = 0,
}) async {
  final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
  await game.beginAdventure(_woods, rng: Random(3));
  var pack = game.profile.backpack;
  for (var i = 0; i < packUsed; i++) {
    pack = pack.withAdded(_log)!;
  }
  game.profile.backpack = pack;
  game.run!
    ..pendingLoot.addAll(loot)
    ..pendingInstances.addAll(_rolls);
  await game.leaveAdventure();
  return game;
}

void main() {
  group('ending a run hands nothing over by itself', () {
    test('walking out leaves the haul pending, waiting to be chosen', () async {
      final game = await _walkedOutWith([_log, _staff]);
      expect(
        game.profile.backpack.used,
        0,
        reason:
            'leaveAdventure that still banks makes the picker decorative — '
            'the items would already be in the pack when it opened',
      );
      expect(
        game.run!.awaitingLootChoice,
        isTrue,
        reason: 'the end screen has no way to know the picker is owed',
      );
    });

    test('⭐ clearing the boss goes through the same step', () async {
      // The designer's ruling: one ritual at every ending, not a special case
      // for the ending where loot is most likely to matter.
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(7));
      while (!game.run!.isFinished) {
        await game.winEncounter(remainingHp: 70, rng: Random(7));
      }
      expect(game.run!.outcome, RunOutcome.cleared);
      expect(game.run!.pendingLoot, isNotEmpty, reason: 'fixture needs a drop');
      expect(
        game.profile.backpack.used,
        0,
        reason:
            'winEncounter banking the cleared run behind the picker gives the '
            'boss path different rules from the walk-out path',
      );
      expect(game.run!.awaitingLootChoice, isTrue);
    });

    test('⚠️ death still forfeits everything, and opens no picker', () async {
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(5));
      await game.winEncounter(remainingHp: 40, rng: Random(5));
      await game.loseEncounter();
      expect(game.run!.pendingLoot, isEmpty);
      expect(
        game.run!.awaitingLootChoice,
        isFalse,
        reason: 'a picker after a death would hand back the defeat penalty',
      );
      final result = await game.takeRunLoot(const [0, 1, 2]);
      expect(
        result.taken,
        isEmpty,
        reason: 'takeRunLoot that skips the lootIsBanked gate revives a corpse',
      );
      expect(game.profile.backpack.used, 0);
    });
  });

  group('the chosen subset, and only it', () {
    test('what is picked lands; what is not is gone for good', () async {
      final game = await _walkedOutWith([_log, _log, _crystal]);
      final result = await game.takeRunLoot({2});

      expect(
        game.profile.backpack.contents.map((s) => s.defId),
        ['flora_crystal'],
        reason:
            'banking the whole pendingLoot list and ignoring the selection is '
            'the old behaviour wearing a new signature',
      );
      expect(result.taken.map((s) => s.defId), ['flora_crystal']);
      expect(
        result.left.map((s) => s.defId),
        ['oak_log', 'oak_log'],
        reason:
            'the screen cannot say what was abandoned if the call does not '
            'report it — and an unreported loss is the bug being fixed',
      );

      final reloaded = (await game.storage.load())!;
      expect(
        reloaded.run!.pendingLoot,
        isEmpty,
        reason:
            'loot left behind but still saved on the run comes back on the '
            'next launch — abandonment has to be permanent to be a decision',
      );
      expect(
        reloaded.backpack.contents.map((s) => s.defId),
        ['flora_crystal'],
        reason: 'the choice never reached disk',
      );
    });

    test('taking nothing is allowed, and abandons the lot', () async {
      final game = await _walkedOutWith([_log, _crystal]);
      final result = await game.takeRunLoot(const <int>{});
      expect(game.profile.backpack.used, 0);
      expect(result.left, hasLength(2));
      final reloaded = (await game.storage.load())!;
      expect(
        reloaded.run!.pendingLoot,
        isEmpty,
        reason:
            'an empty selection that leaves the run untouched would let the '
            'player reopen the picker and change their mind forever',
      );
    });

    test('⚠️ an abandoned instance never reaches the pool', () async {
      final game = await _walkedOutWith([_staff, _mantle]);
      await game.takeRunLoot({0});

      expect(
        game.profile.itemInstances.keys,
        ['inst-staff'],
        reason:
            'keeping every pending instance leaks the rolls of an item nobody '
            'owns — a save that grows forever and a name for a missing staff',
      );
      final reloaded = (await game.storage.load())!;
      expect(
        reloaded.itemInstances.containsKey('inst-mantle'),
        isFalse,
        reason: 'the dangling instance survived the write',
      );
      expect(
        reloaded.backpack.contents.single.instanceId,
        'inst-staff',
        reason: 'a slot whose instance went missing points at nothing',
      );
    });
  });

  group('bounded by the free slots', () {
    test(
      '⚠️ a selection too big is clamped, not refused — best first',
      () async {
        // One slot free, three things wanted. Clamping is what stops a confirm
        // button from doing nothing at all; rarity-first is what decides the
        // casualty.
        final game = await _walkedOutWith([
          _log,
          _staff,
          _crystal,
        ], packUsed: Carrying.backpackSlots - 1);
        final result = await game.takeRunLoot({0, 1, 2});

        expect(
          result.taken.map((s) => s.defId),
          ['heartwood_stave'],
          reason:
              'clamping by list order abandons the epic and keeps a log — '
              'exactly the loss this whole step was built to prevent',
        );
        expect(
          result.left.map((s) => s.defId),
          containsAll(['oak_log', 'flora_crystal']),
          reason: 'the overflow has to be reported, not silently dropped',
        );
        expect(game.profile.backpack.isFull, isTrue);
        expect(
          game.run!.pendingLoot,
          isEmpty,
          reason:
              'a clamp that refuses instead of proceeding strands the run in '
              'its unclaimed state forever',
        );
      },
    );

    test('a full pack takes nothing and says so', () async {
      final game = await _walkedOutWith([
        _staff,
      ], packUsed: Carrying.backpackSlots);
      final result = await game.takeRunLoot({0});
      expect(result.taken, isEmpty);
      expect(
        result.left,
        hasLength(1),
        reason: 'loot that fits nowhere must still be reported as lost',
      );
      expect(
        game.profile.itemInstances,
        isEmpty,
        reason: 'an instance whose slot never landed must not be kept',
      );
    });
  });

  group('the default selection is rarity-first', () {
    test('⭐ the valuable thing is never the default casualty', () async {
      final game = await _walkedOutWith([
        _log,
        _staff,
        _crystal,
      ], packUsed: Carrying.backpackSlots - 2);

      expect(
        game.defaultLootChoice,
        [1, 2],
        reason:
            'first-N-that-fit in drop order defaults to the log and the '
            'crystal, and a player who just taps confirm loses the epic',
      );

      await game.takeRunLoot(game.defaultLootChoice);
      expect(
        game.profile.backpack.countOf('heartwood_stave'),
        1,
        reason: 'the default the picker shows is not the one it banks',
      );
    });

    test('everything is chosen when everything fits', () async {
      final game = await _walkedOutWith([_log, _crystal, _staff]);
      expect(
        game.defaultLootChoice.toSet(),
        {0, 1, 2},
        reason:
            'a default that drops anything while slots are free makes the '
            'common case a loss',
      );
    });

    test('⚠️ ties break on drop order, so the default is stable', () async {
      final game = await _walkedOutWith([_log, _log, _log]);
      expect(
        game.defaultLootChoice,
        [0, 1, 2],
        reason:
            'Dart\'s sort is not stable — without the explicit index '
            'tie-break the picker can reorder identical items between builds',
      );
    });

    test('no run means no choice, rather than a crash', () async {
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      expect(game.defaultLootChoice, isEmpty);
      expect((await game.takeRunLoot(const [0])).taken, isEmpty);
    });
  });

  group('the overwrite guard', () {
    test('starting a new adventure auto-claims an unclaimed haul, best first',
        () async {
      final game = await _walkedOutWith([_log, _staff]);
      expect(game.run!.awaitingLootChoice, isTrue);

      // ⚠️ Kills the silent-overwrite implementation: entering another zone
      // without answering the picker must bank the rarity-first default, not
      // destroy the haul.
      await game.beginAdventure(_woods, rng: Random(12));
      expect(game.run!.pendingLoot, isEmpty,
          reason: 'the new run must start clean');
      expect(game.profile.backpack.countOf(_staff.defId), 1,
          reason: 'the best item must come home even when the picker was '
              'dodged');
    });
  });
}

/// Storage that goes through real JSON, the way both the local store and
/// Firestore do — an in-memory store that hands the same object back would
/// pass every "it reached disk" test here while the save format was broken.
class _JsonMem implements ProfileStorage {
  String? _raw;

  @override
  Future<PlayerProfile?> load() async => _raw == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(_raw!) as Map<String, dynamic>);

  @override
  Future<void> save(PlayerProfile profile) async =>
      _raw = jsonEncode(profile.toJson());

  @override
  Future<void> clear() async => _raw = null;

}
