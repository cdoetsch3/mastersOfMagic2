/// An adventure must survive the app closing.
///
/// ⭐ The bug this guards: the in-progress run lived in `GameState` memory
/// only. A playtester at encounter 4 of 9 force-quit, came back, and the run
/// was simply gone — nine fights of pushing your luck thrown away by a phone
/// call.
///
/// ⚠️ The ruling these tests pin down: resuming lands at the **start of the
/// current encounter**. Nothing mid-duel is stored, so quitting a fight costs
/// that fight and nothing else.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

final _woods = World.byId('whispering_woods');

AdventureRun _run([int seed = 1]) => AdventureRun.roll(
  zone: _woods,
  roster: Bestiary.forZone('whispering_woods'),
  playerHp: 100,
  rng: Random(seed),
);

/// Through real JSON, not just through the maps — a value the encoder cannot
/// write (an enum, a DateTime) would pass a map-only round trip and then fail
/// on the actual save.
Map<String, dynamic> _reencode(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('a run round-trips through JSON', () {
    test('index, HP, outcome, loot and the whole line come back', () {
      final run = _run(3)
        ..recordVictory(
          loot: const [
            InventorySlot(defId: 'oak_log'),
            InventorySlot(defId: 'heartwood_stave', instanceId: 'inst-1'),
          ],
          instances: const {
            'inst-1': ItemInstance(
              instanceId: 'inst-1',
              defId: 'heartwood_stave',
            ),
          },
          remainingHp: 61,
        );

      final back = AdventureRun.fromJson(_reencode(run.toJson()))!;

      expect(back.zoneId, run.zoneId, reason: 'the run forgot which zone');
      expect(back.index, 1, reason: 'resuming at 1 of 9 replays a won fight');
      expect(
        back.playerHp,
        61,
        reason:
            'HP is the push-your-luck resource; a default of full HP here '
            'hands the player a free heal for force-quitting',
      );
      expect(back.outcome, RunOutcome.running);
      expect(
        back.pendingLoot.map((s) => s.defId),
        orderedEquals(['oak_log', 'heartwood_stave']),
        reason: 'unbanked loot dropped on load is the whole run lost',
      );
      expect(
        back.pendingLoot[1].instanceId,
        'inst-1',
        reason: 'a slot that loses its instance id points at nothing',
      );
      expect(
        back.pendingInstances['inst-1']?.defId,
        'heartwood_stave',
        reason: 'the rolls of a non-fungible drop live only in the instance',
      );
      expect(
        back.encounters.map((e) => e.def.id),
        orderedEquals(run.encounters.map((e) => e.def.id)),
        reason: 're-rolling the line on load makes "encounter 3 of 9" a lie',
      );
      expect(
        back.encounters.map((e) => e.level),
        orderedEquals(run.encounters.map((e) => e.level)),
        reason: 'levels are rolled per run, not re-derived from the zone band',
      );
    });

    test('a finished run keeps its ending', () {
      final run = _run(4);
      while (!run.isFinished) {
        run.recordVictory(loot: [], instances: {}, remainingHp: 50);
      }
      final back = AdventureRun.fromJson(_reencode(run.toJson()))!;
      expect(back.outcome, RunOutcome.cleared);
      expect(
        back.index,
        run.encounters.length,
        reason: 'index == length is a legal run, not an out-of-range one',
      );
    });
  });

  group('⚠️ a run that cannot be rebuilt exactly is abandoned', () {
    test('a creature a content patch removed loads as null, not a crash', () {
      final json = _reencode(_run().toJson());
      (json['encounters'] as List)[2] = {
        'defId': 'creature_that_was_deleted',
        'level': 3,
      };
      expect(
        AdventureRun.fromJson(json),
        isNull,
        reason:
            'substituting another creature stands the player in front of '
            'a fight they never chose; throwing bricks the app on load',
      );
    });

    test('a zone that no longer exists loads as null', () {
      final json = _reencode(_run().toJson())..['zoneId'] = 'sunken_nowhere';
      expect(
        AdventureRun.fromJson(json),
        isNull,
        reason:
            'World.byId falls back to the start town, so an unchecked id '
            'would resume the run in Hearthwood',
      );
    });

    test('an index past the end loads as null', () {
      final json = _reencode(_run().toJson())..['index'] = 99;
      expect(
        AdventureRun.fromJson(json),
        isNull,
        reason: 'a run whose index outruns its line crashes on `current`',
      );
    });

    test('null in, null out', () {
      expect(AdventureRun.fromJson(null), isNull);
    });
  });

  group('the run rides on the profile', () {
    test('it survives PlayerProfile.fromJson(toJson)', () {
      final profile = PlayerProfile.newPlayer()..run = _run(7);
      final back = PlayerProfile.fromJson(_reencode(profile.toJson()));
      expect(back.run, isNotNull, reason: 'the field never reached the save');
      expect(back.run!.zoneId, 'whispering_woods');
      expect(
        back.run!.encounters.map((e) => e.def.id),
        orderedEquals(profile.run!.encounters.map((e) => e.def.id)),
      );
    });

    test('an old save with no run field loads fine, with no run', () {
      // ⚠️ Every save written before this feature looks exactly like this.
      final legacy = PlayerProfile.fromJson({
        'name': 'Old Timer',
        'locationId': 'hearthwood',
      });
      expect(
        legacy.run,
        isNull,
        reason: 'absent must read as "not adventuring", never as a default run',
      );
      expect(legacy.name, 'Old Timer', reason: 'the rest of the save survived');
    });

    test('a stored run whose zone was renamed follows the rename', () {
      // The Aldermere→Hearthwood class of migration, applied to a live run.
      final run = _run();
      final json = _reencode(run.toJson());
      expect(
        AdventureRun.fromJson(json)?.zoneId,
        World.canonicalId(run.zoneId),
      );
    });
  });

  group('resume semantics', () {
    test(
      'a win lands the reload on the NEXT encounter, at the banked HP',
      () async {
        final storage = _JsonMem();
        final game = GameState(storage, PlayerProfile.newPlayer());
        await game.beginAdventure(_woods, rng: Random(3));

        final line = game.run!.encounters.map((e) => e.def.id).toList();
        await game.winEncounter(remainingHp: 61, rng: Random(3));

        final reloaded = (await storage.load())!;
        expect(
          reloaded.run,
          isNotNull,
          reason: 'closing the app at encounter 4 of 9 came back to nothing',
        );
        expect(
          reloaded.run!.encounterNumber,
          2,
          reason:
              'a reload that replays the fight you just won is not a resume',
        );
        expect(
          reloaded.run!.playerHp,
          61,
          reason: 'HP banked on the win is what the next fight starts from',
        );
        expect(
          reloaded.run!.encounters.map((e) => e.def.id),
          orderedEquals(line),
          reason: 'the remaining fights must be the ones already promised',
        );
      },
    );

    test('⚠️ reloading mid-run does not duplicate pending loot', () async {
      final storage = _JsonMem();
      final game = GameState(storage, PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));

      // Fight until something actually drops, so there is loot to duplicate.
      var seed = 0;
      while (game.run!.pendingLoot.isEmpty && !game.run!.isFinished) {
        await game.winEncounter(remainingHp: 70, rng: Random(seed++));
      }
      final carried = game.run!.pendingLoot.map((s) => s.defId).toList();
      expect(carried, isNotEmpty, reason: 'the fixture needs a drop');

      final reloaded = (await storage.load())!;
      expect(
        reloaded.run!.pendingLoot.map((s) => s.defId),
        orderedEquals(carried),
        reason:
            'loot appended on load rather than replaced would double the '
            'haul on every reopen',
      );
      expect(
        reloaded.profileBackpackIds,
        isEmpty,
        reason: 'pending loot is NOT the player\'s until they walk out',
      );
    });

    test('walking out leaves nothing pending to hand over twice', () async {
      final storage = _JsonMem();
      final game = GameState(storage, PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));
      var seed = 0;
      while (game.run!.pendingLoot.isEmpty && !game.run!.isFinished) {
        await game.winEncounter(remainingHp: 70, rng: Random(seed++));
      }
      final haul = game.run!.pendingLoot.length;
      await game.leaveAdventure();

      final reloaded = (await storage.load())!;
      expect(reloaded.backpack.used, haul, reason: 'the loot became real');
      expect(
        reloaded.run!.pendingLoot,
        isEmpty,
        reason:
            'banking that clears the run AFTER the save writes a run still '
            'holding loot already in the backpack — reopen and get it again',
      );
    });

    test('a death survives the reload rather than being escapable', () async {
      final storage = _JsonMem();
      final game = GameState(storage, PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(5));
      await game.loseEncounter();

      final reloaded = (await storage.load())!;
      expect(
        reloaded.run!.outcome,
        RunOutcome.died,
        reason:
            'a stored run that forgets it died would let a force-quit undo '
            'the defeat penalty',
      );
      expect(reloaded.run!.pendingLoot, isEmpty);
    });
  });
}

extension on PlayerProfile {
  List<String> get profileBackpackIds =>
      backpack.contents.map((s) => s.defId).toList();
}

/// Storage that goes through real JSON, the way both the local store and
/// Firestore do — an in-memory store that hands the same object back would
/// pass every test here while the save format was broken.
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
