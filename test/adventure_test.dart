import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
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

void main() {
  group('a run is rolled up front', () {
    test('three sections: commons, mini, commons, mini, commons, boss', () {
      final run = _run();
      final ranks = run.encounters.map((e) => e.def.rank).toList();
      expect(ranks.where((r) => r == EnemyRank.mini), hasLength(2));
      expect(ranks.where((r) => r == EnemyRank.boss), hasLength(1));
      expect(ranks.last, EnemyRank.boss, reason: 'the boss ends the run');
      // Primal runs lean: 2 commons per section (§3d).
      expect(run.encounterCount, 2 + 1 + 2 + 1 + 2 + 1);
    });

    test('the count is known before the first fight', () {
      // ⭐ "encounter 3 of 9" must not be a lie (GAME_DESIGN world structure).
      final run = _run();
      expect(run.encounterNumber, 1);
      expect(run.encounterCount, greaterThan(0));
    });

    test('the pool draws 2 of 4 minis and 1 of 2 bosses', () {
      final seenMinis = <String>{};
      final seenBosses = <String>{};
      for (var seed = 0; seed < 60; seed++) {
        final run = _run(seed);
        final minis = run.encounters
            .where((e) => e.def.rank == EnemyRank.mini)
            .map((e) => e.def.id);
        expect(minis.toSet(), hasLength(2), reason: 'two distinct minis');
        seenMinis.addAll(minis);
        seenBosses.addAll(
          run.encounters
              .where((e) => e.def.rank == EnemyRank.boss)
              .map((e) => e.def.id),
        );
      }
      // ⭐ Over many runs every pool member should show up — that is what makes
      // Purge take ~4 clears rather than 1.
      expect(seenMinis, hasLength(4));
      expect(seenBosses, hasLength(2));
    });

    test('elevated ranks fight at the top of the band', () {
      final run = _run();
      for (final e in run.encounters) {
        if (e.def.rank != EnemyRank.common) {
          expect(
            e.level,
            _woods.maxLevel,
            reason: 'a boss must not be a common with more health',
          );
        }
      }
    });
  });

  group('the band is a ramp, not a midpoint', () {
    test('the first fight of the game is at the bottom of the band', () {
      // ⚠️ The playtest bug: Whispering Woods advertises 1-5 and opened on a
      // level-3 creature, because commons all fought at ((min+max)/2).
      for (var seed = 0; seed < 20; seed++) {
        final run = _run(seed);
        expect(
          run.encounters.first.level,
          _woods.minLevel,
          reason: 'seed $seed opened above minLevel — the midpoint is back',
        );
      }
    });

    test('the last encounter is at the top of the band', () {
      final run = _run();
      expect(
        run.encounters.last.level,
        _woods.maxLevel,
        reason: 'the boss ends the climb, so the band must be fully walked',
      );
    });

    test('commons only ever climb, never fall back', () {
      // ⭐ Measured over the commons alone: minis and the boss sit at maxLevel
      // by design, so the full line dips back down after every milestone.
      for (var seed = 0; seed < 20; seed++) {
        final levels = _run(seed).encounters
            .where((e) => e.def.rank == EnemyRank.common)
            .map((e) => e.level)
            .toList();
        for (var i = 1; i < levels.length; i++) {
          expect(
            levels[i],
            greaterThanOrEqualTo(levels[i - 1]),
            reason:
                'seed $seed went $levels — a ramp indexed per section, or off '
                'the commons rather than the whole line, does this',
          );
        }
        expect(
          levels.last,
          greaterThan(levels.first),
          reason: 'seed $seed never climbed at all — that is a flat band',
        );
        for (final level in levels) {
          expect(level, inInclusiveRange(_woods.minLevel, _woods.maxLevel));
        }
      }
    });
  });

  group('no creature twice in a row', () {
    test('consecutive encounters never share a defId', () {
      // ⚠️ The playtest bug: uniform draws gave 3 of the first 5 fights to the
      // same creature. Legal, and it read as the generator being broken.
      for (var seed = 0; seed < 200; seed++) {
        final ids = _run(seed).encounters.map((e) => e.def.id).toList();
        for (var i = 1; i < ids.length; i++) {
          expect(
            ids[i],
            isNot(ids[i - 1]),
            reason: 'seed $seed drew ${ids[i]} back to back at $i: $ids',
          );
        }
      }
    });

    test('the bag deals every common before any of them repeats', () {
      final pool = Bestiary.forZone(
        'whispering_woods',
      ).where((e) => e.rank == EnemyRank.common).length;
      // 3 sections × the tier's commons per section (§3d).
      final slots = commonsPerSectionFor(_woods.tier) * 3;
      final cap = (slots / pool).ceil() + 1;
      for (var seed = 0; seed < 200; seed++) {
        final counts = <String, int>{};
        for (final e in _run(seed).encounters) {
          if (e.def.rank != EnemyRank.common) continue;
          counts[e.def.id] = (counts[e.def.id] ?? 0) + 1;
        }
        for (final entry in counts.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(cap),
            reason:
                'seed $seed used ${entry.key} ${entry.value}x — a bag that is '
                'refilled early, or a die dressed up as one, clusters like '
                'this',
          );
        }
      }
    });

    test('the same seed rolls the same line, every time', () {
      // ⭐ The bag must not reach for a global Random — lockstep and every
      // seeded test above depend on the injected one being the only source.
      final a = _run(42).encounters.map((e) => '${e.def.id}@${e.level}');
      final b = _run(42).encounters.map((e) => '${e.def.id}@${e.level}');
      expect(a, orderedEquals(b.toList()));
    });
  });

  group('push your luck', () {
    test('HP persists between encounters', () {
      final run = _run();
      run.recordVictory(loot: [], instances: {}, remainingHp: 61);
      expect(run.playerHp, 61);
      expect(run.encounterNumber, 2);
    });

    test('walking out banks the loot', () {
      final run = _run()
        ..recordVictory(
          loot: [const InventorySlot(defId: 'oak_log')],
          instances: {},
          remainingHp: 90,
        )
        ..returnToTown();
      expect(run.lootIsBanked, isTrue);
      expect(run.pendingLoot, hasLength(1));
    });

    test('⚠️ dying costs the whole run', () {
      final run = _run()
        ..recordVictory(
          loot: [const InventorySlot(defId: 'oak_log')],
          instances: {},
          remainingHp: 12,
        )
        ..recordDefeat();
      expect(run.outcome, RunOutcome.died);
      expect(run.lootIsBanked, isFalse);
      expect(
        run.pendingLoot,
        isEmpty,
        reason: 'cleared at the source so nothing downstream can bank it',
      );
    });

    test('beating the boss clears the zone', () {
      final run = _run();
      while (!run.isFinished) {
        run.recordVictory(loot: [], instances: {}, remainingHp: 50);
      }
      expect(run.outcome, RunOutcome.cleared);
      expect(run.lootIsBanked, isTrue);
    });
  });

  group('loot rolls into real items', () {
    test('every id a drop table names exists', () {
      for (final id in WhisperingWoodsBestiary.allDrops) {
        expect(
          ItemCatalogue.tryById(id),
          isNotNull,
          reason: '"$id" is dropped but not defined',
        );
      }
    });

    test('a kill produces one slot per item, not a stack', () {
      var slots = 0;
      for (var seed = 0; seed < 200; seed++) {
        slots += rollDrops(
          WhisperingWoodsBestiary.listeningFawn.drops,
          Random(seed),
        ).count;
      }
      expect(slots, greaterThan(0));
    });

    test('exactly one MAIN entry is drawn per kill', () {
      // ⭐ This is what bounds a kill's value and makes rates readable as
      // percentages. ⚠️ One *entry*, not one item — an entry may yield 4-8
      // logs, which is a quantity roll and not a second draw.
      final table = WhisperingWoodsBestiary.heartwood.drops;
      final mainIds = table.main
          .map((e) => e.defId)
          .whereType<String>()
          .toSet();
      // Ids that appear ONLY in main, so an `always` entry cannot confuse it.
      final alwaysIds = table.always.map((e) => e.defId).whereType<String>();
      final mainOnly = mainIds.difference(alwaysIds.toSet());
      for (var seed = 0; seed < 200; seed++) {
        final drawn = rollDrops(
          table,
          Random(seed),
        ).slots.map((s) => s.defId).where(mainOnly.contains).toSet();
        expect(
          drawn.length,
          lessThanOrEqualTo(1),
          reason: 'seed $seed drew $drawn — two entries from one main table',
        );
      }
    });

    test('non-fungible loot gets a unique instance', () {
      final minted = <String>{};
      for (var seed = 0; seed < 300; seed++) {
        final loot = rollDrops(
          WhisperingWoodsBestiary.heartwood.drops,
          Random(seed),
        );
        for (final s in loot.slots) {
          final def = ItemCatalogue.byId(s.defId);
          expect(s.instanceId != null, !def.isFungible, reason: s.defId);
          if (s.instanceId != null) minted.add(s.instanceId!);
        }
      }
      expect(minted.length, greaterThan(1), reason: 'ids must not repeat');
    });
  });

  group('the whole loop, end to end', () {
    test('fight, loot, walk out, stow it in Hearthwood', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));

      // Clear the first two fights.
      await game.winEncounter(remainingHp: 80, rng: Random(3));
      await game.winEncounter(remainingHp: 65, rng: Random(4));
      expect(game.run!.pendingLoot, isNotEmpty);

      // Walk out — the loot becomes yours.
      await game.leaveAdventure();
      expect(game.profile.backpack.used, greaterThan(0));

      // Stow the first slot in Hearthwood's Storeroom.
      final carried = game.profile.backpack.used;
      await game.deposit('hearthwood', 0);
      expect(game.profile.backpack.used, carried - 1);
      expect(game.profile.storerooms['hearthwood']!.itemCount, 1);
      expect(
        game.profile.storerooms['forgeholm'],
        isNull,
        reason: 'ITEMS §10.3c — Storerooms are per city',
      );

      // And take it back out.
      final want = game.profile.storerooms['hearthwood']!.stacks.keys.first;
      final ok = await game.withdraw('hearthwood', InventorySlot(defId: want));
      expect(ok, isTrue);
      expect(game.profile.backpack.used, carried);
    });

    test('dying banks nothing', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(5));
      await game.winEncounter(remainingHp: 40, rng: Random(5));
      await game.loseEncounter();
      expect(game.profile.backpack.used, 0);
      expect(game.run!.outcome, RunOutcome.died);
    });

    test('clearing the zone marks it cleared', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(7));
      while (!game.run!.isFinished) {
        await game.winEncounter(remainingHp: 70, rng: Random(7));
      }
      expect(game.profile.hasCleared('whispering_woods'), isTrue);
      expect(game.profile.clearCountFor('whispering_woods'), 1);
    });

    test(
      '⚠️ a full backpack reports overflow rather than eating loot',
      () async {
        final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
        // Fill the pack first.
        var pack = game.profile.backpack;
        for (var i = 0; i < Carrying.backpackSlots; i++) {
          pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
        }
        game.profile.backpack = pack;

        await game.beginAdventure(_woods, rng: Random(11));
        await game.winEncounter(remainingHp: 90, rng: Random(11));
        await game.leaveAdventure();
        expect(game.profile.backpack.isFull, isTrue);
        expect(
          game.profile.backpack.countOf('oak_log'),
          Carrying.backpackSlots,
        );
      },
    );
  });
}

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;

  @override
  Future<PlayerProfile?> load() async => stored;

  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;

  @override
  Future<void> clear() async => stored = null;
}
