/// The Kinetic recipe ladder (KINETIC_CONTRACT §5), mirroring the coverage
/// `test/craft_test.dart` / `test/skills_test.dart` / `test/craft_screen_filter_test.dart`
/// / `test/gesture_and_nodes_test.dart` gave the Primal ladder, consolidated
/// into one file for the quarter that debuted Metalworking.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipes/kinetic_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';

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

GameState _carrying(Map<String, int> items, {Map<String, int>? skillXp}) {
  final profile = PlayerProfile.newPlayer()
    ..backpack = Backpack.of([
      for (final e in items.entries)
        for (var n = 0; n < e.value; n++) InventorySlot(defId: e.key),
    ]);
  if (skillXp != null) profile.skillXp.addAll(skillXp);
  return GameState(_JsonMem(), profile);
}

/// Every item id any Bestiary entry can drop, at any rate — the "obtainable
/// by kill" half of §7.4's obtainability check.
Set<String> _allDropIds() => {
  for (final e in Bestiary.all) ...e.drops.possibleDrops,
};

/// Every item id a gather node yields — the "obtainable by node" half.
Set<String> _allNodeIds() => {for (final n in GatherNodes.all) n.yieldsDefId};

void main() {
  group('the 21 are registered', () {
    test('KineticRecipes.all is exactly 21, ids unique', () {
      expect(KineticRecipes.all, hasLength(21),
          reason:
              'KINETIC_CONTRACT §5.1\'s table is renumbered 1–21 with no '
              'gaps after the five §8.1/§8.5 cuts — a stray or a dropped '
              'entry both break this count');
      final ids = KineticRecipes.all.map((r) => r.id).toSet();
      expect(ids, hasLength(21), reason: 'a duplicated id shadows another');
    });

    test('every Kinetic recipe is reachable through RecipeBook.all', () {
      for (final r in KineticRecipes.all) {
        expect(RecipeBook.tryById(r.id), same(r),
            reason: '${r.id} is authored but not registered in RecipeBook — '
                'the exact silent failure §7.1 warns about: it compiles fine '
                'and never appears on the craft screen or the wiki');
      }
    });

    test('the skill split matches §5.1: Metalworking 2, Woodcarving 6, '
        'Tailoring 12, Potions 1', () {
      int countOf(CraftSkill s) =>
          KineticRecipes.all.where((r) => r.skill == s).length;
      expect(countOf(CraftSkill.metalworking), 2);
      expect(countOf(CraftSkill.woodcarving), 6);
      expect(countOf(CraftSkill.tailoring), 12);
      expect(countOf(CraftSkill.potionsAndAlchemy), 1);
      expect(countOf(CraftSkill.jewelry), 0,
          reason: 'Jewelry does not debut this quarter (§8.1) — its station '
              'and its learning both stay at Rimeholt, L45');
      expect(countOf(CraftSkill.enchanting), 0,
          reason: 'Enchanting stays at Meridian, L36 — no Kinetic recipe '
              'should claim it early');
    });
  });

  group('every input and output resolves, and every input is in-band', () {
    test('every output id resolves through ItemCatalogue', () {
      for (final r in KineticRecipes.all) {
        expect(ItemCatalogue.tryById(r.outputId), isNotNull,
            reason: '${r.id} mints ${r.outputId}, which no catalogue owns — '
                'the mint would crash on the real item lookup');
      }
    });

    test('every input id resolves through ItemCatalogue', () {
      for (final r in KineticRecipes.all) {
        for (final i in r.inputs) {
          expect(ItemCatalogue.tryById(i.defId), isNotNull,
              reason: '${r.id} eats ${i.defId}, which no catalogue owns');
        }
      }
    });

    test('⚠️ every input is obtainable in-band: a drop, a node, or a prior '
        'craft (KINETIC_CONTRACT §7.4)', () {
      final drops = _allDropIds();
      final nodes = _allNodeIds();
      final craftedOutputs = RecipeBook.all.map((r) => r.outputId).toSet();

      for (final r in KineticRecipes.all) {
        for (final i in r.inputs) {
          final obtainable = drops.contains(i.defId) ||
              nodes.contains(i.defId) ||
              craftedOutputs.contains(i.defId);
          expect(obtainable, isTrue,
              reason: '${r.id} needs ${i.defId}, which drops from nothing, '
                  'has no gather node, and is no recipe\'s output — a '
                  'material the player can never actually acquire');
        }
      }
    });

    test('⭐ the two banked Q1 materials this quarter finally spends '
        '(copper_ore, charcoal) still resolve and still gather', () {
      // §5.1: "Two of Q1's four banked materials are spent this quarter" —
      // Bronze is the payoff §9b.8 promised when Cinderpeak and Ashfall Vale
      // banked them with no consumer.
      expect(ItemCatalogue.tryById('copper_ore'), isNotNull);
      expect(ItemCatalogue.tryById('charcoal'), isNotNull);
      expect(_allNodeIds(), containsAll(['copper_ore', 'charcoal']));
    });

    test('⚠️ the six banking materials remain unconsumed by every Kinetic '
        'recipe (§7.4)', () {
      // quarry_jasper/everice/obsidian bank to Rimeholt (§8.1); hoarlichen/
      // firesalt bank to the deferred potions (§8.5); hum_quartz banks to
      // Meridian on schedule. A Kinetic recipe eating any of them would be a
      // builder inventing a consumer the contract explicitly forbids.
      const stillBanking = {
        'quarry_jasper',
        'everice',
        'obsidian',
        'hoarlichen',
        'firesalt',
        'hum_quartz',
      };
      final consumed = {
        for (final r in KineticRecipes.all)
          for (final i in r.inputs) i.defId,
      };
      expect(consumed.intersection(stillBanking), isEmpty,
          reason: 'a Kinetic recipe must not force the four-for-four promise '
              'before the maker that was supposed to spend it opens');
    });
  });

  group('the ladder actually climbs', () {
    test('gates are non-decreasing per skill, in table order (§5.2)', () {
      for (final skill in CraftSkill.values) {
        final gates = [
          for (final r in KineticRecipes.all)
            if (r.skill == skill) r.skillLevel,
        ];
        for (var i = 1; i < gates.length; i++) {
          expect(gates[i], greaterThanOrEqualTo(gates[i - 1]),
              reason: '$skill\'s ladder regresses at position $i — a later '
                  'recipe must never gate lower than an earlier one in the '
                  'same skill');
        }
      }
    });

    test('gates sit within the Kinetic band: Metalworking opens at 1, '
        'nothing exceeds 34', () {
      final metalworking =
          KineticRecipes.all.where((r) => r.skill == CraftSkill.metalworking);
      expect(metalworking.map((r) => r.skillLevel), contains(1),
          reason: 'Bronze Ingot gates at 1 — "the correct feel for a skill '
              'you just learned" (§5.2)');
      for (final r in KineticRecipes.all) {
        expect(r.skillLevel, inInclusiveRange(1, 34),
            reason: '${r.id} gates at ${r.skillLevel}, outside the ladder '
                '§5.1 actually authors (Metalworking 1–10, everything else '
                '20–34)');
      }
    });
  });

  group('§5.3 slot coverage is pinned', () {
    test('Metalworking feeds exactly the four Woodcarving recipes that '
        'consume an ingot', () {
      final ingotConsumers = KineticRecipes.all
          .where((r) => r.inputs.any(
              (i) => i.defId == 'bronze_ingot' || i.defId == 'iron_ingot'))
          .map((r) => r.id)
          .toSet();
      expect(
        ingotConsumers,
        {
          'craft_yew_quarterstaff',
          'craft_yew_wand',
          'craft_rowan_quarterstaff',
          'craft_rowan_wand',
        },
        reason: '§5.1\'s note: "Metalworking is a pure feeder lane… two '
            'recipes and four downstream consumers, all Woodcarving" — a '
            'fifth consumer or a missing one both break the claim',
      );
      for (final r in ingotConsumers) {
        expect(RecipeBook.tryById(r)!.skill, CraftSkill.woodcarving);
      }
    });

    test('⚠️ Neck and Ring stay drop-only — no Kinetic recipe outputs '
        'either slot', () {
      for (final r in KineticRecipes.all) {
        final def = ItemCatalogue.byId(r.outputId);
        if (def is EquipmentDef) {
          expect(def.slot, isNot(EquipSlot.neck),
              reason: '${r.id}: §5.3 — Neck stays drop-only this quarter, '
                  'Jewelry\'s station still at Rimeholt (§8.1)');
          expect(def.slot, isNot(EquipSlot.ring),
              reason: '${r.id}: §5.3 — Ring stays drop-only for the same '
                  'reason');
        }
      }
    });

    test('Woodcarving still covers Main Hand and Off Hand; Tailoring still '
        'covers every armour slot plus the belt', () {
      Set<EquipSlot> slotsFor(CraftSkill skill) => {
        for (final r in KineticRecipes.all)
          if (r.skill == skill)
            if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
              d.slot,
      };
      expect(slotsFor(CraftSkill.woodcarving),
          {EquipSlot.mainHand, EquipSlot.offHand});
      expect(slotsFor(CraftSkill.tailoring), {
        EquipSlot.hat,
        EquipSlot.robeTop,
        EquipSlot.robeBottom,
        EquipSlot.boots,
        EquipSlot.gloves,
        EquipSlot.belt,
      });
    });
  });

  group('xpForRecipe spot-checks (hand-computed against §5.1)', () {
    test('Bronze Ingot: 4 inputs × (4 + 2×1) = 24', () {
      expect(Skills.xpForRecipe(KineticRecipes.bronzeIngot), 24);
    });

    test('Rowan Quarterstaff: 4 inputs × (4 + 2×30) = 256', () {
      expect(Skills.xpForRecipe(KineticRecipes.rowanQuarterstaff), 256);
    });

    test('Tussock Robe: 6 inputs × (4 + 2×30) = 384', () {
      expect(Skills.xpForRecipe(KineticRecipes.tussockRobe), 384);
    });
  });

  group('⭐ the first Metalworking craft in the game\'s history', () {
    test('bronze_ingot: consumes the inputs, mints the output, banks the '
        'XP', () async {
      final game = _carrying(
        {'copper_ore': 2, 'tin_ore': 1, 'charcoal': 1},
        skillXp: {'metalworking': 0},
      );
      final out = await game.craft(KineticRecipes.bronzeIngot, rng: Random(1));

      expect(out.succeeded, isTrue,
          reason: 'a profile carrying exactly the recipe\'s inputs at gate '
              'level must succeed');
      expect(game.profile.backpack.countOf('copper_ore'), 0,
          reason: 'both copper eaten');
      expect(game.profile.backpack.countOf('tin_ore'), 0,
          reason: 'the missing half Old Quarry supplies, eaten');
      expect(game.profile.backpack.countOf('charcoal'), 0,
          reason: 'the banked Ashfall Vale material, finally spent');
      expect(game.profile.backpack.countOf('bronze_ingot'), 1,
          reason: 'the mint must actually happen');
      expect(game.profile.skillXp['metalworking'], 24,
          reason: 'Skills.xpForRecipe(bronzeIngot) = 4 × 6 = 24, banked on '
              'the ledger — the first Metalworking XP anyone has ever '
              'earned');
      expect(game.profile.skillLevel('metalworking'), 2,
          reason: 'xpToNext(1) = 20 + 5×0 = 20, and 24 XP clears it — the '
              'first Metalworking level-up in the game');
      expect(out.leveledTo, 2,
          reason: 'the craft that crosses the gate must report it, or the '
              'UI never celebrates the very first Metalworking level');

      // bronze_ingot is fungible (a MaterialDef): no instance is minted.
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'bronze_ingot');
      expect(slot!.instanceId, isNull,
          reason: 'two Bronze Ingots are interchangeable — an instance id '
              'would be meaningless state, same ruling as a potion');
      expect(out.quality, isNull,
          reason: 'a fungible material rolls no quality');
    });

    test('⚠️ gate 1 is the floor, not a wall: zero Metalworking XP still '
        'succeeds', () async {
      // Distinguishing regression: gate 1 must not accidentally require
      // *positive* XP — level 1 is the default level with zero XP banked.
      final game = _carrying({'copper_ore': 2, 'tin_ore': 1, 'charcoal': 1});
      final out = await game.craft(KineticRecipes.bronzeIngot);
      expect(out.succeeded, isTrue,
          reason: 'a brand-new profile with zero Metalworking XP is already '
              'level 1, and Bronze gates at exactly 1');
    });

    test('refuses missing materials, counting the shortfall', () async {
      final game = _carrying({'copper_ore': 1, 'tin_ore': 1, 'charcoal': 1});
      final out = await game.craft(KineticRecipes.bronzeIngot);
      expect(out.succeeded, isFalse);
      expect(out.refusal, contains('1 more'),
          reason: 'one copper short of the two the recipe needs');
      expect(game.profile.backpack.countOf('copper_ore'), 1,
          reason: 'a refusal must not eat materials');
    });

    test('the whole craft survives a JSON reload', () async {
      final storage = _JsonMem();
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'copper_ore'),
          InventorySlot(defId: 'copper_ore'),
          InventorySlot(defId: 'tin_ore'),
          InventorySlot(defId: 'charcoal'),
        ]);
      final game = GameState(storage, profile);
      await game.craft(KineticRecipes.bronzeIngot);

      final back = GameState(storage, (await storage.load())!);
      expect(back.profile.backpack.countOf('bronze_ingot'), 1);
      expect(back.profile.skillXp['metalworking'], 24,
          reason: 'XP that does not survive the save never existed');
    });
  });
}
