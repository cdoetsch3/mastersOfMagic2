/// GameState.craft — the gate, the consumption, the mint, the XP.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills. Storage goes through real JSON (the object-identity fake would
/// pass while the save format was broken).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

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

void main() {
  group('crafting', () {
    test('consumes the inputs, mints the output, pays the XP', () async {
      final game = _carrying({'oak_log': 5});
      final out = await game.craft(PrimalRecipes.oakWand);

      expect(out.succeeded, isTrue);
      expect(game.profile.backpack.countOf('oak_log'), 3,
          reason: 'a craft that does not consume is a duplication engine');
      expect(game.profile.backpack.countOf('oak_wand'), 1);
      expect(game.profile.skillXp['woodcarving'], 15,
          reason: 'xpForRecipe(level 1) = 15, banked on the ledger');
      // Equipment is non-fungible: the mint must register an instance.
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'oak_wand');
      expect(slot!.instanceId, isNotNull);
      expect(game.profile.itemInstances[slot.instanceId], isNotNull,
          reason: 'an unregistered instance id dangles forever');
    });

    test('a potion is fungible and mints no instance', () async {
      final game = _carrying({'sapwort': 2});
      final out = await game.craft(PrimalRecipes.sapwortDraught);
      expect(out.succeeded, isTrue);
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'sapwort_draught');
      expect(slot!.instanceId, isNull,
          reason: 'two draughts are interchangeable — an id would be '
              'meaningless state (ITEMS §10.3a)');
    });

    test('refuses below the skill gate, naming the gap', () async {
      final game = _carrying({'birch_log': 5});
      final out = await game.craft(PrimalRecipes.birchWand);
      expect(out.refusal, contains('Woodcarving 10'));
      expect(game.profile.backpack.countOf('birch_log'), 5,
          reason: 'a refusal must not eat materials');
    });

    test('passes the gate once the ledger says 10', () async {
      // 585 XP walks the ladder past level 10.
      final game =
          _carrying({'birch_log': 5}, skillXp: {'woodcarving': 600});
      final out = await game.craft(PrimalRecipes.birchWand);
      expect(out.succeeded, isTrue);
    });

    test('refuses missing materials, counting the shortfall', () async {
      final game = _carrying({'oak_log': 1});
      final out = await game.craft(PrimalRecipes.oakQuarterstaff);
      expect(out.refusal, contains('2 more'),
          reason: 'the message must say how far short, not merely "no"');
    });

    test('reports the level-up on the craft that crosses it', () async {
      // 19 XP in: one more level-1 craft (+15) crosses 20.
      final game = _carrying({'sapwort': 2}, skillXp: {'potionsAndAlchemy': 19});
      final out = await game.craft(PrimalRecipes.sapwortDraught);
      expect(out.leveledTo, 2,
          reason: 'the UI celebrates off this field; null means silence');
    });

    test('a two-input recipe consumes both lines', () async {
      final game = _carrying(
        {'fawnhide': 2, 'bindweed_fibre': 3},
        skillXp: {'tailoring': 100},
      );
      final out = await game.craft(PrimalRecipes.fawnhideBelt);
      expect(out.succeeded, isTrue);
      expect(game.profile.backpack.countOf('fawnhide'), 0);
      expect(game.profile.backpack.countOf('bindweed_fibre'), 2,
          reason: 'only the recipe line is consumed, never the whole stack');
    });

    test('the whole craft survives a JSON reload', () async {
      final storage = _JsonMem();
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'oak_log'),
        ]);
      final game = GameState(storage, profile);
      await game.craft(PrimalRecipes.oakKnot);

      final back = GameState(storage, (await storage.load())!);
      expect(back.profile.backpack.countOf('oak_knot'), 1);
      expect(back.profile.skillLevel('woodcarving'), 1);
      expect(back.profile.skillXp['woodcarving'], 15,
          reason: 'XP that does not survive the save never existed');
    });
  });
}
