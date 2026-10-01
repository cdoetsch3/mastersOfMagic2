/// `GameState.craft` on a transmute recipe (ENCHANTING §3.2): an `anyElement`
/// line draws its count — the curve at the crafter's Enchanting level — from
/// any other element's mote of the tier, largest stacks first, and the plan
/// the refusal counted is exactly what the write spends.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/items/recipes/enchanting_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';

class _Mem implements ProfileStorage {
  int saves = 0;
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    stored = profile;
  }

  @override
  Future<void> clear() async => stored = null;
}

int _xpAt(int level) {
  var total = 0;
  for (var l = 1; l < level; l++) {
    total += Skills.xpToNext(l);
  }
  return total;
}

/// A character in the Whispering Woods (no town, no Storeroom) at Enchanting
/// [level] holding [pack] fungibles.
({GameState game, _Mem disk}) _game({
  int level = 1,
  Map<String, int> pack = const {},
}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = 50000
    ..locationId = 'whispering_woods';
  profile.achievements = {for (final a in Achievements.all) a.id};
  profile.skillXp['enchanting'] = _xpAt(level);
  var bp = Backpack.empty();
  pack.forEach((defId, n) {
    for (var i = 0; i < n; i++) {
      bp = bp.withAdded(InventorySlot(defId: defId))!;
    }
  });
  profile.backpack = bp;
  final disk = _Mem();
  return (game: GameState(disk, profile), disk: disk);
}

final RecipeDef _pyroShard = RecipeBook.tryById(
  EnchantingRecipes.transmuteId(MagicElement.pyro, MoteTier.shard),
)!;

void main() {
  test(
    '⭐ a transmute draws the curve from other elements, largest first',
    () async {
      final (:game, :disk) = _game(
        level: 1,
        pack: {'aqua_shard': 3, 'flora_shard': 2, 'pyro_shard': 5},
      );
      final out = await game.craft(_pyroShard);
      expect(
        out.refusal,
        isNull,
        reason: 'kills a gate that reads the exemplar literally',
      );
      expect(
        (
          game.materialCount('aqua_shard'),
          game.materialCount('flora_shard'),
          game.materialCount('pyro_shard'),
        ),
        (0, 1, 6),
        reason:
            'L1 is 4:1 — three Aqua then one Flora (largest stack first), the '
            'Pyro stack untouched except for the one made; kills spending the '
            'literal 4 of the exemplar, and kills drawing the output element',
      );
      expect(disk.saves, 1, reason: 'one write for the craft');
    },
  );

  test('the curve is read at the crafter\'s level', () async {
    final (:game, disk: _) = _game(level: 45, pack: {'aqua_shard': 2});
    final out = await game.craft(_pyroShard);
    expect(
      out.refusal,
      isNull,
      reason: 'kills ignoring the level (4 needed at L1)',
    );
    expect(
      (game.materialCount('aqua_shard'), game.materialCount('pyro_shard')),
      (0, 1),
      reason: 'L45 is 2:1 — kills a draw that still takes the stored 4',
    );
  });

  test(
    '⚠️ short motes refuse with the tier word, not one element\'s name',
    () async {
      final (:game, disk: _) = _game(
        level: 1,
        pack: {'aqua_shard': 1, 'pyro_shard': 9},
      );
      final out = await game.craft(_pyroShard);
      expect(
        out.refusal,
        'Needs 4 Shards of other elements — you have 1.',
        reason:
            'kills counting the output element toward "have" (it would say 10) '
            'and kills naming the exemplar element',
      );
    },
  );

  test('the Workbench helpers agree with the gate', () {
    final (:game, disk: _) = _game(
      level: 30,
      pack: {'aqua_shard': 2, 'pyro_shard': 9},
    );
    final line = _pyroShard.inputs.firstWhere((i) => i.anyElement);
    expect(game.inputHave(_pyroShard, line), 2, reason: 'other elements only');
    expect(
      game.inputNeed(_pyroShard, line),
      3,
      reason: 'L30 is 5:2, rounded up',
    );
    expect(GameState.transmuteTierLabel(line), 'Shard');
  });

  test('a salvage marker is never a bench recipe', () async {
    final (:game, disk: _) = _game(pack: {'aqua_shard': 9});
    final out = await game.craft(EnchantingRecipes.salvage.first);
    expect(
      out.refusal,
      'That cannot be made here.',
      reason: 'kills a crafter that treats the equipment sentinel as an item',
    );
  });
}
