/// The gesture schema, the quality pipeline, and Zone 1's gathering nodes.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/crafting/craft_quality.dart';
import 'package:masters_of_magic_2/game/crafting/gesture.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

class _JsonMem implements ProfileStorage {
  String? saved;
  @override
  Future<PlayerProfile?> load() async => saved == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
  @override
  Future<void> save(PlayerProfile profile) async =>
      saved = jsonEncode(profile.toJson());
  @override
  Future<void> clear() async => saved = null;
}

void main() {
  group('the authored scripts hold the rulings', () {
    test('tier-1 recipes have 2-3 steps; nothing exceeds 4', () {
      for (final r in RecipeBook.all) {
        expect(r.steps, isNotEmpty, reason: '${r.id} has no act authored');
        if (r.skillLevel <= 5) {
          expect(r.steps.length, inInclusiveRange(2, 3),
              reason: '${r.id}: tier 1 is 2-3 forgiving steps, ruled §9b.9c');
        }
        expect(r.steps.length, lessThanOrEqualTo(4));
      }
    });

    test('the Woodcarving pilot crosses all three categories', () {
      final staff = RecipeBook.tryById('craft_oak_quarterstaff')!;
      final cats = staff.steps.map((s) => s.engine.category).toSet();
      expect(cats, GestureCategory.values.toSet(),
          reason: 'chop/carve/sand teaches one engine per category — the '
              'tutorial-by-fiction the whole exposure schedule leans on');
    });

    test('tier-2 never uses an engine count jump beyond +1 vs its tier-1 kin',
        () {
      // The exposure lever: birch introduces no NEW engine over oak.
      final oakEngines = {
        for (final id in ['craft_oak_quarterstaff', 'craft_oak_wand'])
          ...RecipeBook.tryById(id)!.steps.map((s) => s.engine),
      };
      final birchEngines = {
        for (final id in ['craft_birch_quarterstaff', 'craft_birch_wand'])
          ...RecipeBook.tryById(id)!.steps.map((s) => s.engine),
      };
      expect(birchEngines.difference(oakEngines), isEmpty,
          reason: 'same vocabulary, more reps — tier 2 raises difficulty, '
              'not exposure');
    });
  });

  group('quality resolution (§9b.9d)', () {
    test('the grade is a ceiling: the roll never exceeds it', () {
      final rng = Random(1);
      for (var i = 0; i < 200; i++) {
        final q = CraftQuality.roll(grade: 0.7, margin: 30, rng: rng);
        expect(q.index, lessThanOrEqualTo(Quality.ornate.index),
            reason: 'grade 0.7 caps at Ornate no matter the margin');
      }
    });

    test('⭐ a perfect at-level craft can still roll Rough', () {
      final rng = Random(2);
      var roughs = 0;
      for (var i = 0; i < 500; i++) {
        if (CraftQuality.roll(grade: 1, margin: 0, rng: rng) ==
            Quality.rough) {
          roughs++;
        }
      }
      expect(roughs, greaterThan(0),
          reason: 'at the edge of your ability the material fights back — '
              'the explicit ruling');
    });

    test('⭐ from margin 5, a perfect craft escapes Rough entirely', () {
      final rng = Random(3);
      for (var i = 0; i < 500; i++) {
        expect(CraftQuality.roll(grade: 1, margin: 5, rng: rng),
            isNot(Quality.rough),
            reason: 'the floor rides the margin');
      }
    });

    test('the skill ceiling clamps below the execution ceiling', () {
      final rng = Random(4);
      for (var i = 0; i < 100; i++) {
        final q = CraftQuality.roll(
          grade: 1,
          margin: 20,
          rng: rng,
          skillCeiling: Quality.standard,
        );
        expect(q.index, lessThanOrEqualTo(Quality.standard.index),
            reason: 'the true cap is the LOWER of hands and level');
      }
    });

    test('margin improves the odds at the top of the band', () {
      Quality atMargin(int m, int seed) =>
          CraftQuality.roll(grade: 1, margin: m, rng: Random(seed));
      var lowTop = 0, highTop = 0;
      for (var i = 0; i < 400; i++) {
        if (atMargin(0, i) == Quality.master) lowTop++;
        if (atMargin(20, i) == Quality.master) highTop++;
      }
      expect(highTop, greaterThan(lowTop),
          reason: "§9b.4's 'better odds at higher skill' lives in the "
              'weights — flat weights kill this');
    });
  });

  group('Zone 1 gathering nodes', () {
    final woods = World.byId('whispering_woods');

    AdventureRun roll(int seed) => AdventureRun.roll(
      zone: woods,
      roster: Bestiary.forZone(woods.id),
      playerHp: 100,
      rng: Random(seed),
    );

    test('a run rolls one node per section, never after the boss', () {
      final run = roll(5);
      expect(run.nodes.length, 3, reason: 'three sections, three spots');
      for (final n in run.nodes) {
        expect(n.afterIndex, lessThan(run.encounters.length - 1),
            reason: 'a node after the boss could never be reached');
        expect(GatherNodes.byId(n.defId), isNotNull);
      }
    });

    test('nodes survive the JSON round trip; an unknown def drops alone', () {
      final run = roll(6);
      final back = AdventureRun.fromJson(run.toJson())!;
      expect(back.nodes.length, run.nodes.length);
      expect(back.nodes.first.defId, run.nodes.first.defId);

      final json = run.toJson();
      (json['nodes'] as List)[0] = {'defId': 'gone_node', 'afterIndex': 0};
      final degraded = AdventureRun.fromJson(json);
      expect(degraded, isNotNull,
          reason: 'losing a spot is nothing; losing the run would be theft');
      expect(degraded!.nodes.length, run.nodes.length - 1);
    });

    /// A run standing at its first gathering spot, with the picker of every
    /// fight on the way already answered (nothing taken — the pack state is
    /// the thing under test here).
    Future<GameState> atFirstNode() async {
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(woods, rng: Random(7));
      final run = game.run!;
      final node = run.nodes.reduce(
          (a, b) => a.afterIndex < b.afterIndex ? a : b);
      while (run.index <= node.afterIndex) {
        await game.winEncounter(remainingHp: 90, rng: Random(run.index));
        await game.claimVictoryLoot(const <int>{});
      }
      expect(run.currentNode, isNotNull, reason: 'the spot should be reached');
      return game;
    }

    test('⭐ gathering goes straight into the backpack, XP with it', () async {
      // Ruling 2026-08-17: materials are fungible and there is nothing to
      // choose between, so the yield skips the picker entirely.
      final game = await atFirstNode();
      final before = game.profile.backpack.used;
      final out = await game.gatherNode(rng: Random(8));

      expect(out.succeeded, isTrue);
      expect(game.profile.backpack.used, before + out.amount,
          reason: 'a yield parked anywhere but the pack is the deleted loot '
              'tracker growing back');
      expect(game.profile.backpack.countOf(out.defId!), out.amount);
      expect(game.run!.unclaimed, isEmpty,
          reason: 'materials are fungible — a picker for eight logs is a '
              'chore, not a decision');
      expect(game.profile.itemInstances, isEmpty,
          reason: 'registering an instance for a log is a save that grows '
              'forever');
      expect(game.profile.skillXp[out.skillKey], out.xp,
          reason: 'the harvest happened, so the effort is paid');

      // Spent is spent.
      final again = await game.gatherNode(rng: Random(9));
      expect(again.succeeded, isFalse,
          reason: 'one simultaneous harvest per node, ruled §9b.7');
    });

    test('⚠️ a pack with no room refuses, and the spot stands', () async {
      final game = await atFirstNode();
      var pack = game.profile.backpack;
      while (!pack.isFull) {
        pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
      }
      game.profile.backpack = pack;
      final node = game.run!.currentNode!;

      final out = await game.gatherNode(rng: Random(8));

      expect(out.succeeded, isFalse,
          reason: 'harvesting into a full pack can only drop the yield — the '
              'exact silent loss the ruling ends');
      expect(out.refusal, contains('room'),
          reason: 'a refusal the player cannot read is a dead button');
      expect(node.spent, isFalse,
          reason: 'spending the node on a refused harvest destroys the spot '
              'and the yield together');
      expect(game.run!.currentNode, same(node),
          reason: 'the spot persists with the run, so it can be harvested '
              'once there is room');
      expect(game.profile.skillXp, isEmpty,
          reason: 'a refusal is not effort');
      expect(game.profile.backpack.countOf('oak_log'),
          Carrying.backpackSlots,
          reason: 'a full pack must not be rewritten by a refused harvest');
    });

    test('⚠️ a PARTIAL fit is refused too, never split', () async {
      final game = await atFirstNode();
      final node = game.run!.currentNode!;
      // One slot free, and every node in the zone yields more than one.
      var pack = game.profile.backpack;
      while (pack.free > 1) {
        pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
      }
      game.profile.backpack = pack;
      expect(node.def.min, greaterThan(1), reason: 'the fixture needs a >1 min');

      final out = await game.gatherNode(rng: Random(8));
      expect(out.succeeded, isFalse,
          reason: 'taking what fits and dropping the rest is the silent '
              'overflow wearing a hat');
      expect(game.profile.backpack.free, 1, reason: 'nothing was taken');
    });
  });
}
