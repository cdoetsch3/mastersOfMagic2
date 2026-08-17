/// What comes home is the player's choice, made the moment the fight ends.
///
/// ⭐ **RULING (2026-08-17): the run-long loot tracker is gone.** Drops used to
/// ride the run to its ending and be claimed in one lump, which meant a haul
/// could be stranded by a force-quit, destroyed by entering another zone, or
/// silently trimmed to fit. Now every victory offers its own drops immediately
/// and what is kept is in the backpack before the next fight starts.
///
/// ⚠️ The invariant every test here circles: the chosen loot and the abandoned
/// loot leave the run in the **same write**. A run saved still holding loot
/// that is already in the backpack hands it over again on the next launch.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
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

/// A run standing on a fresh victory whose drops are [loot], unanswered.
///
/// [packUsed] pre-fills the backpack, because the whole picker exists for the
/// case where the drops do not fit.
Future<GameState> _wonWith(List<InventorySlot> loot, {int packUsed = 0}) async {
  final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
  await game.beginAdventure(_woods, rng: Random(3));
  var pack = game.profile.backpack;
  for (var i = 0; i < packUsed; i++) {
    pack = pack.withAdded(_log)!;
  }
  game.profile.backpack = pack;
  game.run!.recordVictory(loot: loot, instances: _rolls, remainingHp: 90);
  return game;
}

void main() {
  group('a win hands nothing over by itself', () {
    test('the drops wait on the run until the picker is answered', () async {
      final game = await _wonWith([_log, _staff]);
      expect(
        game.profile.backpack.used,
        0,
        reason:
            'winEncounter that banks on its own makes the picker decorative — '
            'the items would already be in the pack when it opened',
      );
      expect(
        game.run!.unclaimed.map((s) => s.defId),
        ['oak_log', 'heartwood_stave'],
        reason: 'the screen has nothing to draw if the roll is not parked',
      );
    });

    test('⭐ the drops survive a force-quit taken mid-choice', () async {
      final game = await _wonWith([_log, _staff]);
      await game.touchPresence(); // any write; the run rides the profile
      final reloaded = (await game.storage.load())!;
      expect(
        reloaded.run!.unclaimed.map((s) => s.defId),
        ['oak_log', 'heartwood_stave'],
        reason:
            'an in-memory-only picker loses the whole batch to a phone call — '
            'the same abandoned-not-approximated contract as the rest of the '
            'run',
      );
      expect(
        reloaded.run!.unclaimedInstances['inst-staff']?.defId,
        'heartwood_stave',
        reason: 'a slot whose instance did not survive points at nothing',
      );
    });

    test('⭐ the boss fight goes through the same step', () async {
      // One ritual at every victory, not a special case for the fight where
      // loot is most likely to matter.
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(7));
      while (!game.run!.isFinished) {
        final before = game.profile.backpack.used;
        await game.winEncounter(remainingHp: 70, rng: Random(7));
        expect(
          game.profile.backpack.used,
          before,
          reason:
              'winEncounter banking behind the picker gives some fight its '
              'own rules',
        );
        await game.claimVictoryLoot(game.defaultVictoryChoice);
      }
      expect(game.run!.outcome, RunOutcome.cleared);
      expect(
        game.profile.backpack.used,
        greaterThan(0),
        reason: 'the fixture needs at least one drop to have been claimed',
      );
    });

    test('⚠️ a death leaves no picker to answer', () async {
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(5));
      await game.loseEncounter();
      expect(game.run!.unclaimed, isEmpty);
      final result = await game.claimVictoryLoot(const [0, 1, 2]);
      expect(
        result.taken,
        isEmpty,
        reason: 'a claim against an empty batch must not fabricate loot',
      );
      expect(game.profile.backpack.used, 0);
    });
  });

  group('the chosen subset, and only it', () {
    test('what is picked lands; what is not is gone for good', () async {
      final game = await _wonWith([_log, _log, _crystal]);
      final result = await game.claimVictoryLoot({2});

      expect(
        game.profile.backpack.contents.map((s) => s.defId),
        ['flora_crystal'],
        reason:
            'banking the whole batch and ignoring the selection is the old '
            'behaviour wearing a new signature',
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
        reloaded.run!.unclaimed,
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
      final game = await _wonWith([_log, _crystal]);
      final result = await game.claimVictoryLoot(const <int>{});
      expect(game.profile.backpack.used, 0);
      expect(result.left, hasLength(2));
      final reloaded = (await game.storage.load())!;
      expect(
        reloaded.run!.unclaimed,
        isEmpty,
        reason:
            'an empty selection that leaves the run untouched would let the '
            'player reopen the picker and change their mind forever',
      );
    });

    test('⭐ a claimed instance is registered; an abandoned one is not',
        () async {
      final game = await _wonWith([_staff, _mantle]);
      await game.claimVictoryLoot({0});

      expect(
        game.profile.itemInstances.keys,
        ['inst-staff'],
        reason:
            'a claim that registers nothing leaves the staff in the pack with '
            'no rolls behind it; keeping every instance leaks the rolls of an '
            'item nobody owns',
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
    test('⚠️ a selection too big is clamped, not refused — best first',
        () async {
      // One slot free, three things wanted. Clamping is what stops a confirm
      // button from doing nothing at all; rarity-first is what decides the
      // casualty.
      final game = await _wonWith([
        _log,
        _staff,
        _crystal,
      ], packUsed: Carrying.backpackSlots - 1);
      final result = await game.claimVictoryLoot({0, 1, 2});

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
        game.run!.unclaimed,
        isEmpty,
        reason:
            'a clamp that refuses instead of proceeding strands the run '
            'holding a picker it can never close',
      );
    });

    test('a full pack takes nothing and says so', () async {
      final game = await _wonWith([_staff], packUsed: Carrying.backpackSlots);
      final result = await game.claimVictoryLoot({0});
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
      final game = await _wonWith([
        _log,
        _staff,
        _crystal,
      ], packUsed: Carrying.backpackSlots - 2);

      expect(
        game.defaultVictoryChoice,
        [1, 2],
        reason:
            'first-N-that-fit in drop order defaults to the log and the '
            'crystal, and a player who just taps confirm loses the epic',
      );

      await game.claimVictoryLoot(game.defaultVictoryChoice);
      expect(
        game.profile.backpack.countOf('heartwood_stave'),
        1,
        reason: 'the default the picker shows is not the one it banks',
      );
    });

    test('everything is chosen when everything fits', () async {
      final game = await _wonWith([_log, _crystal, _staff]);
      expect(
        game.defaultVictoryChoice.toSet(),
        {0, 1, 2},
        reason:
            'a default that drops anything while slots are free makes the '
            'common case a loss',
      );
    });

    test('no run means no choice, rather than a crash', () async {
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      expect(game.defaultVictoryChoice, isEmpty);
      expect((await game.claimVictoryLoot(const [0])).taken, isEmpty);
    });
  });

  group('the picker\'s order: rarity down, then alphabetical', () {
    test('⭐ the rarest thing sits on top', () {
      final loot = [_log, _crystal, _staff, _mantle];
      expect(
        lootDisplayOrder(loot, _rolls).map((i) => loot[i].defId),
        ['heartwood_stave', 'sporecap_mantle', 'flora_crystal', 'oak_log'],
        reason:
            'drop order puts the log first — the row the player must not miss '
            'has to be the one their eye lands on',
      );
    });

    test('⚠️ equal rarity sorts by NAME, not by when it dropped', () {
      // Three genuine commons — Oak Log, Flora Shard, Bindweed Fibre —
      // dropped in reverse alphabetical order.
      const loot = [
        InventorySlot(defId: 'oak_log'),
        InventorySlot(defId: 'flora_shard'),
        InventorySlot(defId: 'bindweed_fibre'),
      ];
      final names = lootDisplayOrder(loot, const {})
          .map((i) => loot[i].defId)
          .toList();
      expect(
        names,
        ['bindweed_fibre', 'flora_shard', 'oak_log'],
        reason:
            'falling back to drop order scatters identical-rarity rows and '
            'makes a long list unreadable',
      );
    });

    test('⚠️ identical items keep drop order, so rows never shuffle', () {
      const loot = [_log, _log, _log];
      expect(
        lootDisplayOrder(loot, const {}),
        [0, 1, 2],
        reason:
            "Dart's sort is not stable — without the explicit index tie-break "
            'the picker can reorder identical items between builds',
      );
    });

    test('⚠️ an item the catalogue forgot sorts last instead of throwing', () {
      const loot = [InventorySlot(defId: 'patched_out_thing'), _log];
      expect(
        lootDisplayOrder(loot, const {}).map((i) => loot[i].defId),
        ['oak_log', 'patched_out_thing'],
        reason:
            'a content patch that removes an item must not make the picker '
            'crash on a save that still holds one',
      );
    });
  });

  group('⚠️ the migration of 2026-08-17', () {
    /// A save written by the pre-ruling build: a finished run still holding a
    /// whole adventure's `pendingLoot`, which nothing in this build would ever
    /// offer again.
    Map<String, dynamic> legacySave({
      required List<Map<String, dynamic>> pending,
      int packUsed = 0,
    }) {
      final profile = PlayerProfile.newPlayer();
      var pack = profile.backpack;
      for (var i = 0; i < packUsed; i++) {
        pack = pack.withAdded(_log)!;
      }
      profile
        ..backpack = pack
        // A real rolled run: `AdventureRun.fromJson` refuses a line it cannot
        // rebuild, so a hand-written stub would never reach the migration.
        ..run = AdventureRun.roll(
          zone: _woods,
          roster: Bestiary.forZone('whispering_woods'),
          playerHp: 100,
          rng: Random(3),
        )
        ..run!.returnToTown();
      final json =
          jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>;
      // The two keys this build no longer writes, put back the way a
      // pre-ruling save holds them.
      (json['run'] as Map<String, dynamic>)
        ..['pendingLoot'] = pending
        ..['pendingInstances'] = {
          for (final e in _rolls.entries) e.key: e.value.toJson(),
        };
      return json;
    }

    test('a stranded haul is handed over, best first', () {
      final profile = PlayerProfile.fromJson(
        legacySave(pending: [_log.toJson(), _staff.toJson()]),
      );
      expect(
        profile.backpack.contents.map((s) => s.defId),
        containsAll(['oak_log', 'heartwood_stave']),
        reason:
            'deleting the loot tracker must not delete the loot a playtester '
            'was standing on when they closed the app',
      );
      expect(
        profile.itemInstances['inst-staff']?.defId,
        'heartwood_stave',
        reason: 'a migrated non-fungible with no instance is a nameless husk',
      );
      expect(
        profile.run!.unclaimed,
        isEmpty,
        reason:
            'a migrated haul that also lands in `unclaimed` gets handed over '
            'twice — once here and once through the picker',
      );
    });

    test('⭐ what does not fit is dropped by rarity, never by luck', () {
      final profile = PlayerProfile.fromJson(
        legacySave(
          pending: [_log.toJson(), _staff.toJson(), _crystal.toJson()],
          packUsed: Carrying.backpackSlots - 1,
        ),
      );
      expect(
        profile.backpack.countOf('heartwood_stave'),
        1,
        reason:
            'migrating in stored order spends the last slot on a log and '
            'quietly destroys the epic — the exact bug the ruling ends',
      );
      expect(profile.backpack.isFull, isTrue);
      expect(
        profile.itemInstances.containsKey('inst-mantle'),
        isFalse,
        reason: 'only instances whose slot landed may enter the pool',
      );
    });

    test('⚠️ the legacy keys never reach the next save', () {
      final profile = PlayerProfile.fromJson(
        legacySave(pending: [_log.toJson()]),
      );
      final written = jsonDecode(jsonEncode(profile.toJson()))
          as Map<String, dynamic>;
      expect(
        (written['run'] as Map).containsKey('pendingLoot'),
        isFalse,
        reason:
            'a migration that rewrites the old key runs again on every load, '
            'duplicating the haul each time',
      );
      // And a second trip through load must not conjure another log.
      final again = PlayerProfile.fromJson(written);
      expect(again.backpack.countOf('oak_log'), 1);
    });

    test('a legacy save with an empty haul is left completely alone', () {
      final profile = PlayerProfile.fromJson(legacySave(pending: const []));
      expect(profile.backpack.used, 0);
      expect(profile.run, isNotNull, reason: 'the run itself still loads');
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
