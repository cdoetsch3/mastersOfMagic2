/// The gesture schema, the quality pipeline, and the Primal quarter's
/// gathering nodes.
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
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
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

  group('the rest of the Primal quarter gathers too (§9b.7)', () {
    /// ⭐ The literal registry. Written out rather than derived so that
    /// deleting an entry from [GatherNodes.all] — the file's own named silent
    /// failure, since an unlisted node compiles and simply never spawns —
    /// fails here instead of quietly emptying a zone.
    const authored = <String, ({String zone, GatherSkill skill, String yield})>{
      'ww_oak_stand': (
        zone: 'whispering_woods',
        skill: GatherSkill.felling,
        yield: 'oak_log',
      ),
      'ww_bindweed_tangle': (
        zone: 'whispering_woods',
        skill: GatherSkill.foraging,
        yield: 'bindweed_fibre',
      ),
      'gb_sapwort_shallows': (
        zone: 'glimmerbrook',
        skill: GatherSkill.foraging,
        yield: 'sapwort',
      ),
      'cp_copper_seam': (
        zone: 'cinderpeak_foothills',
        skill: GatherSkill.mining,
        yield: 'copper_ore',
      ),
      'tm_bogflax_retting': (
        zone: 'thornmire',
        skill: GatherSkill.foraging,
        yield: 'bogflax_fibre',
      ),
      'tm_fenroot_hummock': (
        zone: 'thornmire',
        skill: GatherSkill.foraging,
        yield: 'fenroot',
      ),
      'tm_amber_bog_oak': (
        zone: 'thornmire',
        skill: GatherSkill.mining,
        yield: 'amber',
      ),
      'av_birch_stand': (
        zone: 'ashfall_vale',
        skill: GatherSkill.felling,
        yield: 'birch_log',
      ),
      'av_brookmint_rill': (
        zone: 'ashfall_vale',
        skill: GatherSkill.foraging,
        yield: 'brookmint',
      ),
      'av_charcoal_burn': (
        zone: 'ashfall_vale',
        skill: GatherSkill.felling,
        yield: 'charcoal',
      ),
    };

    const primalZones = [
      'whispering_woods',
      'glimmerbrook',
      'cinderpeak_foothills',
      'thornmire',
      'ashfall_vale',
    ];

    test('⚠️ every authored node is REGISTERED, and nothing extra is', () {
      expect(
        GatherNodes.all.map((n) => n.id).toSet(),
        authored.keys.toSet(),
        reason: 'a node left out of GatherNodes.all compiles fine and simply '
            'never spawns — the file warns about exactly this, so the '
            'registry is what the test pins',
      );
      expect(GatherNodes.all.map((n) => n.id).toSet(),
          hasLength(GatherNodes.all.length),
          reason: 'a duplicated id would make byId resolve one node and the '
              'other unreachable');
      for (final e in authored.entries) {
        final n = GatherNodes.byId(e.key);
        expect(n, isNotNull, reason: '${e.key} does not resolve by id');
        expect(n!.zoneId, e.value.zone);
        expect(n.skill, e.value.skill);
        expect(n.yieldsDefId, e.value.yield);
      }
    });

    test('⚠️ forZone reaches every node — the spawn path is the only door', () {
      // AdventureRun.roll draws from forZone and nothing else, so a node that
      // is in `all` but whose zoneId is a typo is invisible in exactly the
      // same way an unlisted one is.
      final reached = <String>{};
      for (final zoneId in primalZones) {
        final here = GatherNodes.forZone(zoneId);
        expect(here, isNotEmpty,
            reason: '$zoneId has no node: its materials would be drop-only '
                'and no GatherSkill could level there');
        for (final n in here) {
          expect(n.zoneId, zoneId);
          reached.add(n.id);
        }
      }
      expect(reached, authored.keys.toSet(),
          reason: 'a node no zone claims is dead content');
      expect(GatherNodes.forZone('hearthwood'), isEmpty,
          reason: 'a town is not a gathering zone; forZone matching loosely '
              'would spawn nodes on the map screen');
    });

    test('every node yields a real, fungible, stackable material', () {
      for (final n in GatherNodes.all) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull,
            reason: '${n.id} yields ${n.yieldsDefId}, which no catalogue '
                'owns — gatherNode would name the raw id at the player');
        expect(def, isA<MaterialDef>(),
            reason: '${n.id} yields something that is not a material; '
                'equipment would need a quality roll and an instance, which '
                'is the picker §9b.7 rules the yield out of');
        expect(def!.isFungible, isTrue,
            reason: '${n.id}: gatherNode adds `InventorySlot(defId:)` N times '
                'and registers no instance, so a non-fungible yield loses its '
                'rolls in silence');
      }
    });

    test('⚠️ nothing that comes off a corpse has a node', () {
      // Hides drop from the creature wearing them and motes from the thing
      // unmade; a node for either is a second source that contradicts its own
      // fiction (and would make the kill-only jewelry pools skippable).
      final yielded = GatherNodes.all.map((n) => n.yieldsDefId).toSet();
      for (final id in ['fawnhide', 'tuskhide']) {
        expect(yielded, isNot(contains(id)),
            reason: '$id comes off a creature — foraging it out of the ground '
                'is the no-second-source ruling broken');
      }
      for (final d in ItemCatalogue.all.whereType<MoteDef>()) {
        expect(yielded, isNot(contains(d.id)),
            reason: '${d.id}: motes are combat drops (§6.1); a mote node '
                'would uncouple Enchanting from fighting entirely');
      }
    });

    test("⭐ every Q1 material EXCEPT the kill-only ones has a node", () {
      // The other half of the ruling: §9b.8 calls Copper, Charcoal, Fenroot
      // and Amber alike "gatherable now", so a banking material without a
      // node is a promise the world cannot keep.
      const killOnly = {'fawnhide', 'tuskhide'};
      final yielded = GatherNodes.all.map((n) => n.yieldsDefId).toSet();
      for (final d in ItemCatalogue.all.whereType<MaterialDef>()) {
        if (killOnly.contains(d.id)) continue;
        expect(yielded, contains(d.id),
            reason: '${d.id} is a world material with nowhere to gather it — '
                'drop-only is what this whole pass exists to end');
      }
    });

    test('⭐ node XP is 9 + 2×(band floor − 1), and climbs with the band', () {
      // The Woods' authored 9 at floor 1, extended by the only zone number
      // the design publishes. Flat XP would make the Woods the fastest place
      // to level Foraging forever.
      for (final n in GatherNodes.all) {
        final zone = World.byId(n.zoneId);
        expect(n.xp, 9 + 2 * (zone.minLevel - 1),
            reason: '${n.id} (${n.zoneId}, floor ${zone.minLevel}) breaks the '
                'documented scaling');
        expect(n.xp, greaterThan(0),
            reason: 'a node that pays nothing is a button with no reason');
      }

      final byBand = [...GatherNodes.all]
        ..sort((a, b) =>
            World.byId(a.zoneId).minLevel.compareTo(World.byId(b.zoneId).minLevel));
      for (var i = 1; i < byBand.length; i++) {
        expect(byBand[i].xp, greaterThanOrEqualTo(byBand[i - 1].xp),
            reason: '${byBand[i].id} pays less than a node in an EASIER band — '
                'that makes the low zone the efficient grind');
      }
      expect(byBand.last.xp, greaterThan(byBand.first.xp),
          reason: 'if every band paid the same, the formula is not a formula');
    });

    test('every node is harvestable and worth the trip', () {
      for (final n in GatherNodes.all) {
        expect(n.min, greaterThan(1),
            reason: '${n.id}: the yield is all-or-nothing, so a 1-min node '
                'reads as a bug the first time a nearly-full pack refuses it');
        expect(n.max, greaterThanOrEqualTo(n.min),
            reason: '${n.id}: gatherNode calls nextInt(max - min + 1), which '
                'throws outright on an inverted range');
        expect(n.flavor, isNotEmpty, reason: '${n.id} has no flavor');
        expect(n.flavor.length, greaterThan(40),
            reason: '${n.id}: the node IS how the world teaches, so a stub '
                'line is a missing feature');
      }
    });

    test('⚠️ the skill key every node pays actually resolves', () {
      // gatherNode writes `profile.skillXp[def.skill.name]`, and the Skills
      // ledger reads it back by string. Mining is the live risk: this is the
      // first content that ever exercises it.
      for (final n in GatherNodes.all) {
        final key = n.skill.name;
        expect(Skills.allKeys, contains(key),
            reason: '${n.id} pays "$key", a key the ledger never lists — the '
                'XP would land in a row nothing renders');
        expect(Skills.isGathering(key), isTrue);
        expect(Skills.displayName(key), isNot(key),
            reason: '$key falls through the displayName switch and would show '
                'the raw enum name to the player');
        expect(Skills.blurb(key), isNotEmpty);
      }
      expect(GatherNodes.all.map((n) => n.skill).toSet(),
          GatherSkill.values.toSet(),
          reason: 'all three gathering skills must have somewhere to level; '
              'mining had nowhere at all before this content');
    });

    test('the gathering act reuses engines and never invents a step', () {
      for (final n in GatherNodes.all) {
        expect(GestureEngine.values, contains(n.step.engine));
        expect(n.step.skin, isNotEmpty,
            reason: '${n.id}: the skin is the copy and art key');
      }
      // ⭐ Birch is Oak's engine and skin with one more rep — the wood
      // ladder's tier 2 raises difficulty, not exposure (§9b.9c, lever 3).
      final oak = GatherNodes.byId('ww_oak_stand')!.step;
      final birch = GatherNodes.byId('av_birch_stand')!.step;
      expect(birch.engine, oak.engine);
      expect(birch.skin, oak.skin);
      expect(birch.reps, greaterThan(oak.reps),
          reason: 'a tier-2 stand that plays identically to tier 1 wastes the '
              'only difficulty lever the schema stores');
    });

    // ---- the round trip, in a zone that had nothing before ---------------

    /// A run in [zoneId] standing at its first gathering spot, every picker
    /// on the way declined.
    Future<GameState> atFirstNodeIn(String zoneId, {int seed = 11}) async {
      final zone = World.byId(zoneId);
      final game = GameState(_JsonMem(), PlayerProfile.newPlayer());
      await game.beginAdventure(zone, rng: Random(seed));
      final run = game.run!;
      expect(run.nodes, isNotEmpty,
          reason: '$zoneId rolled a run with no spots — forZone found nothing');
      final node =
          run.nodes.reduce((a, b) => a.afterIndex < b.afterIndex ? a : b);
      while (run.index <= node.afterIndex) {
        await game.winEncounter(remainingHp: 90, rng: Random(run.index));
        await game.claimVictoryLoot(const <int>{});
      }
      expect(run.currentNode, isNotNull);
      return game;
    }

    test('⭐ Cinderpeak: the first Mining harvest in the game round-trips',
        () async {
      final game = await atFirstNodeIn('cinderpeak_foothills');
      final before = game.profile.backpack.used;
      final out = await game.gatherNode(rng: Random(12));

      expect(out.succeeded, isTrue);
      expect(out.skillKey, 'mining',
          reason: 'the whole point of this zone: Mining had no node anywhere, '
              'so the skill could not leave level 1');
      expect(out.defId, 'copper_ore');
      expect(game.profile.backpack.used, before + out.amount,
          reason: 'a yield parked anywhere but the pack is the deleted loot '
              'tracker growing back');
      expect(game.profile.backpack.countOf('copper_ore'), out.amount);
      expect(game.run!.unclaimed, isEmpty,
          reason: 'materials are fungible — ore goes straight to the pack');
      expect(game.profile.itemInstances, isEmpty,
          reason: 'registering an instance per ore is a save that grows '
              'forever');
      expect(game.profile.skillXp['mining'], 19,
          reason: "Cinderpeak's band floor is 6, so 9 + 2×5");

      final again = await game.gatherNode(rng: Random(13));
      expect(again.succeeded, isFalse,
          reason: 'one simultaneous harvest per node, ruled §9b.7');
    });

    test('⚠️ Ashfall: a full pack refuses, and the spot stands', () async {
      final game = await atFirstNodeIn('ashfall_vale');
      var pack = game.profile.backpack;
      while (!pack.isFull) {
        pack = pack.withAdded(const InventorySlot(defId: 'oak_log'))!;
      }
      game.profile.backpack = pack;
      final node = game.run!.currentNode!;

      final out = await game.gatherNode(rng: Random(14));

      expect(out.succeeded, isFalse,
          reason: 'the all-or-nothing rule is not zone 1 special-casing');
      expect(out.refusal, contains('room'));
      expect(node.spent, isFalse,
          reason: 'spending the node on a refused harvest destroys the spot '
              'and the yield together');
      expect(game.profile.skillXp, isEmpty, reason: 'a refusal is not effort');
      expect(game.profile.backpack.countOf('oak_log'), Carrying.backpackSlots,
          reason: 'a full pack must not be rewritten by a refused harvest');
    });

    test('every Primal zone can actually surface its nodes on a run', () {
      // The spawn path takes zone + roster and nothing else; this is the
      // end-to-end proof that no zone needed extra wiring.
      for (final zoneId in primalZones) {
        final zone = World.byId(zoneId);
        final authoredHere =
            GatherNodes.forZone(zoneId).map((n) => n.id).toSet();
        final seen = <String>{};
        for (var seed = 0; seed < 40; seed++) {
          final run = AdventureRun.roll(
            zone: zone,
            roster: Bestiary.forZone(zoneId),
            playerHp: 100,
            rng: Random(seed),
          );
          expect(run.nodes, hasLength(3),
              reason: '$zoneId: three sections, three spots');
          for (final n in run.nodes) {
            expect(GatherNodes.byId(n.defId), isNotNull);
            expect(n.afterIndex, lessThan(run.encounters.length - 1),
                reason: 'a node after the boss could never be reached');
            seen.add(n.defId);
          }
        }
        expect(seen, authoredHere,
            reason: '$zoneId authors ${authoredHere.length} node(s) but only '
                '${seen.length} ever spawned — a def the draw cannot reach is '
                'the unlisted-node failure wearing a hat');
      }
    });
  });
}
