/// [ShopCatalogue]'s E-category derivation and the shelves it computes off the
/// travel graph — ECONOMY_CONTRACT §5.1 as re-cut by §14d rulings 2 and 3
/// (Christian, 2026-08-26).
///
/// ⭐ **Mutation-verified**: every assertion carries a `reason:` naming the
/// wrong implementation it kills — a hand-written ingredient list, a
/// precedence that lets "native" beat "consumable ingredient", a stale E, and
/// a future edge edit that strands a zone.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/economy_config.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

GameState _game() => GameState(_MemStorage(), PlayerProfile.newPlayer());

void main() {
  group('§14d.2 — consumable ingredients are DERIVED, never listed', () {
    test('the shipped set is exactly the three brewing herbs', () {
      // The verbatim derived list, pinned so a silent content change (a new
      // potion, or a herb quietly dropped from a recipe) shows up as a diff
      // here rather than as a shelf that behaves oddly in play.
      expect(
        ShopCatalogue.consumableIngredientIds.toList()..sort(),
        ['brookmint', 'saltwort', 'sapwort'],
        reason: 'sapwort→sapwort_draught, brookmint→brookmint_tonic, '
            'saltwort→saltwort_draught are the only three consumable recipes '
            'the game ships',
      );
    });

    test('every derived id really is an input to a consumable recipe', () {
      // Kills a derivation that collected recipe OUTPUTS, or that forgot the
      // consumable filter and swept in every material in the book.
      for (final id in ShopCatalogue.consumableIngredientIds) {
        final feedsAConsumable = RecipeBook.all.any((r) {
          final out = ItemCatalogue.tryById(r.outputId);
          return (out is ConsumableDef || out is BeltableDef) &&
              r.inputs.any((i) => i.defId == id);
        });
        expect(
          feedsAConsumable,
          isTrue,
          reason: '"$id" is classified as a consumable ingredient but feeds no '
              'consumable recipe — the derivation is collecting the wrong side',
        );
        expect(
          ItemCatalogue.tryById(id),
          isA<MaterialDef>(),
          reason: '"$id" must be a MaterialDef — the ruling names materials',
        );
      }
    });

    test('no GEAR-only material was swept into the ingredient set', () {
      // `oak_log` and `bindweed_fibre` feed wands and robes and nothing
      // drinkable. Kills "every recipe input is an ingredient".
      for (final gearOnly in ['oak_log', 'bindweed_fibre', 'iron_ore']) {
        expect(
          ShopCatalogue.consumableIngredientIds,
          isNot(contains(gearOnly)),
          reason: '$gearOnly feeds only gear recipes; classifying it as a '
              'brewing herb would drop its E from 60 to 10 and starve the '
              'crafting shelf the whole town is built around',
        );
      }
    });

    test(
      '⭐ THE MUTANT-KILLER: one new consumable recipe reclassifies its '
      'inputs, with no edit to shop_catalogue.dart',
      () {
        // ⚠️ **This is the assertion a hand-written list cannot pass.** It
        // appends a recipe the game does not ship — a potion brewed from
        // `oak_log`, today a pure GEAR material — and asks the derivation
        // whether `oak_log` is now an ingredient. A literal
        // `{'sapwort', 'brookmint', 'saltwort'}` answers "no" no matter what
        // ids it contains, so this test fails the instant anyone "simplifies"
        // the RecipeBook walk into a constant.
        const oakTonic = RecipeDef(
          id: 'zz_test_oak_tonic',
          outputId: 'sapwort_draught', // a real consumable output
          skill: CraftSkill.potionsAndAlchemy,
          skillLevel: 1,
          inputs: [RecipeInput('oak_log', 1)],
        );

        expect(
          ShopCatalogue.consumableIngredientsIn(RecipeBook.all),
          isNot(contains('oak_log')),
          reason: 'baseline: oak_log is NOT an ingredient in the shipped book '
              '— without this the assertion below proves nothing',
        );
        expect(
          ShopCatalogue.consumableIngredientsIn([...RecipeBook.all, oakTonic]),
          contains('oak_log'),
          reason: 'adding one consumable recipe MUST reclassify its inputs '
              'mechanically — this is the hand-list mutant',
        );

        // ⭐ And the same case settles the tie-break the ruling had to decide:
        // `oak_log` would still be a Hearthwood-native gear material (E=60),
        // yet it comes back an ingredient (E=10). SCARCER WINS.
        expect(
          ShopCatalogue.consumableIngredientsIn([...RecipeBook.all, oakTonic]),
          contains('oak_log'),
          reason: 'a material feeding BOTH gear and consumables takes the '
              'LOWER E — the tighter shelf, because double demand is more '
              'pressure, and because that rule is monotone: a new recipe can '
              'only ever tighten a shelf, never loosen one',
        );
      },
    );
  });

  group('§14d.2 — categoryFor precedence is ascending E (scarcer wins)', () {
    test('an ingredient outranks NATIVE at the town whose zone grows it', () {
      // `sapwort` lives in a Hearthwood-adjacent zone, so the pre-ruling
      // answer here was nativeMaterial (E=60). Kills a `categoryFor` that
      // asks the native/imported question before the ingredient question.
      expect(
        ShopCatalogue.nativeZonesOf('hearthwood'),
        contains(ItemCatalogue.zoneOf('sapwort')),
        reason: 'fixture check — sapwort must be native to Hearthwood, or this '
            'test is not exercising the precedence it claims to',
      );
      expect(
        ShopCatalogue.categoryFor('hearthwood', 'sapwort'),
        ShopItemCategory.consumableIngredient,
        reason: 'consumableIngredient (10) must beat nativeMaterial (60)',
      );
    });

    test('an ingredient outranks IMPORTED at a town that ships it in', () {
      // ⚠️ `brookmint`, not `sapwort`: sapwort grows in Glimmerbrook, which
      // borders BOTH Hearthwood and Pennycross, so it is native at both and
      // could never exercise the imported branch. Brookmint is an Ashfall Vale
      // herb, native to no open town's neighbourhood but Hearthwood's region.
      expect(
        ShopCatalogue.nativeZonesOf('pennycross'),
        isNot(contains(ItemCatalogue.zoneOf('brookmint'))),
        reason: 'fixture check — brookmint must NOT be native to Pennycross, '
            'or this test is not exercising the imported branch at all',
      );
      expect(
        ShopCatalogue.categoryFor('pennycross', 'brookmint'),
        ShopItemCategory.consumableIngredient,
        reason: 'consumableIngredient (10) must beat importedMaterial (20)',
      );
    });

    test('a consumable outranks everything, including its own ingredients', () {
      // `sapwort_draught` is a BeltableDef; `foragers_ration` a ConsumableDef.
      // Both are the scarcest bucket at every town.
      for (final town in ['hearthwood', 'pennycross', 'galehaven']) {
        for (final id in ['sapwort_draught', 'foragers_ration', 'hardtack']) {
          expect(
            ShopCatalogue.categoryFor(town, id),
            ShopItemCategory.consumable,
            reason: '$id at $town — a ConsumableDef/BeltableDef is the scarcest E '
                'regardless of which zone it is native to',
          );
        }
      }
    });

    test('a plain gear material is still native/imported as before', () {
      // ⚠️ The half of the economy §14d.2 deliberately did NOT touch. Kills a
      // change that collapsed every material into one bucket.
      expect(
        ShopCatalogue.categoryFor('hearthwood', 'oak_log'),
        ShopItemCategory.nativeMaterial,
      );
      expect(
        ShopCatalogue.categoryFor('pennycross', 'oak_log'),
        ShopItemCategory.importedMaterial,
        reason: 'oak_log is shipped into Pennycross, not grown there',
      );
    });
  });

  group('§14d.2 — E per category, through GameState.shopEquilibriumFor', () {
    test('each bucket maps to its own compiled constant', () {
      // The real seam every price reads, not the constants in isolation —
      // kills a switch arm wired to the wrong constant (the copy-paste bug
      // that adding a fourth arm invites).
      final game = _game();
      expect(
        game.shopEquilibriumFor('hearthwood', 'oak_log'),
        EconomyConfig.equilibriumNative,
        reason: 'native gear material → 60',
      );
      expect(
        game.shopEquilibriumFor('pennycross', 'oak_log'),
        EconomyConfig.equilibriumImported,
        reason: 'imported gear material → 20',
      );
      expect(
        game.shopEquilibriumFor('hearthwood', 'sapwort'),
        EconomyConfig.equilibriumConsumableIngredient,
        reason: 'brewing herb → 10',
      );
      expect(
        game.shopEquilibriumFor('hearthwood', 'sapwort_draught'),
        EconomyConfig.equilibriumConsumable,
        reason: 'the potion itself → 6',
      );
    });

    test('the four buckets resolve to four DISTINCT numbers', () {
      // Kills a wiring where two arms happen to return the same constant, which
      // would make three of the four assertions above pass by coincidence.
      final game = _game();
      final es = [
        game.shopEquilibriumFor('hearthwood', 'oak_log'),
        game.shopEquilibriumFor('pennycross', 'oak_log'),
        game.shopEquilibriumFor('hearthwood', 'sapwort'),
        game.shopEquilibriumFor('hearthwood', 'sapwort_draught'),
      ];
      expect(es, [60, 20, 10, 9]);
      expect(
        es.toSet().length,
        4,
        reason: 'four buckets, four distinct equilibria',
      );
    });

    test('a per-item override still wins over the category default (§7)', () {
      // ⚠️ Unchanged by §14d.2 and worth re-pinning: the new bucket must not
      // have been wired ahead of the override lookup.
      final previous = EconomyConfig.current;
      addTearDown(() => EconomyConfig.current = previous);
      EconomyConfig.current = const EconomyConfig(
        equilibriumOverrides: {'sapwort': 999},
      );
      expect(
        _game().shopEquilibriumFor('hearthwood', 'sapwort'),
        999,
        reason: 'config/economy overrides outrank every category default, '
            'including the new consumable-ingredient one',
      );
    });
  });

  group('§14d.3 — Whispering Woods no longer touches Ashfall Vale', () {
    test('the edge is gone from BOTH sides', () {
      // ⚠️ Removing one direction and leaving the other is the classic
      // half-edit; `world_test.dart`'s bidirectionality guard would catch it,
      // but this names the specific pair the ruling removed.
      expect(
        ShopCatalogue.nativeZonesOf('hearthwood'),
        isNotEmpty,
        reason: 'sanity — the graph still resolves',
      );
      expect(
        _connections('whispering_woods'),
        isNot(contains('ashfall_vale')),
        reason: 'the woods must not list the vale (§14d.3)',
      );
      expect(
        _connections('ashfall_vale'),
        isNot(contains('whispering_woods')),
        reason: 'the vale must not list the woods back — the reverse edge is '
            'stored separately and is the half people forget',
      );
    });

    test('⭐ Ashfall Vale is still REACHABLE, via the Foothills', () {
      // The ruling's own condition. `world_test.dart` proves *every* location
      // is reachable; this pins the specific route, so a future edit that
      // rewires the vale onto some other parent has to say so out loud here.
      expect(
        _connections('ashfall_vale'),
        ['cinderpeak_foothills'],
        reason: 'the vale is now a leaf hanging off Cinderpeak Foothills — '
            'drop this last edge and the zone is stranded',
      );
      expect(
        _connections('cinderpeak_foothills'),
        contains('hearthwood'),
        reason: 'and the Foothills reach the start town in one more hop, so '
            'the full route is hearthwood → cinderpeak_foothills → '
            'ashfall_vale',
      );
    });

    test('no shelf moved: every open town stocks exactly what it did', () {
      // ⭐ The surprising, load-bearing finding of §14d.3: Hearthwood borders
      // the FOOTHILLS, not the vale, so removing the woods↔vale road changed
      // no town's native-zone set and therefore no shelf. Pinned verbatim so
      // that if a later edge edit *does* move a shelf, this is the test that
      // says which one.
      expect(ShopCatalogue.stockFor('hearthwood').toList()..sort(), [
        'amber',
        'bindweed_fibre',
        'birch_log',
        'bogflax_fibre',
        'brookmint',
        'copper_ore',
        'fawnhide',
        'fenroot',
        'foragers_ration',
        'oak_log',
        'sapwort',
        'sapwort_draught',
        'tuskhide',
      ], reason: 'Hearthwood was the shelf most likely to move, and did not');
      expect(
        ShopCatalogue.nativeZonesOf('hearthwood').toList()..sort(),
        ['cinderpeak_foothills', 'glimmerbrook', 'thornmire', 'whispering_woods'],
        reason: 'the vale was never native to Hearthwood — it reaches town '
            'through the Foothills, which is exactly why the shelf held',
      );
    });

    test('no location modifier moved either: the vale stays REGIONAL', () {
      // The vale used to reach Hearthwood two ways (via the woods and via the
      // Foothills); it now reaches it one way. Either way it is a 2-hop
      // zone→zone walk, so §4.1 row 2 still applies. Kills the assumption
      // that deleting an edge must have re-tiered something.
      expect(
        ItemCatalogue.zoneOf('birch_log'),
        'ashfall_vale',
        reason: 'fixture check — pick a genuine Ashfall Vale material, or this '
            'test measures nothing about the removed edge',
      );
      expect(
        ShopCatalogue.locationModFor('hearthwood', 'birch_log'),
        ShopCatalogue.regionalMod,
        reason: 'birch_log is an Ashfall Vale material, and Hearthwood still '
            'reaches the vale in two zone-hops through Cinderpeak Foothills — '
            'a drop to baseline/import here would mean the graph walk lost '
            'the surviving route',
      );
    });
  });
}

List<String> _connections(String id) =>
    World.byId(id).connections.toList()..sort();
