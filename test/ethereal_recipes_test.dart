/// The Ethereal recipe ladder (ETHEREAL_CONTRACT §5), modelled on
/// `test/celestial_recipes_test.dart` — the same laws, for the quarter that
/// debuts Jewelry, spends seven gems banked since level 15, and makes
/// §6a.1's "every slot has a maker" true for the first time.
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
import 'package:masters_of_magic_2/game/items/recipe_def.dart';
import 'package:masters_of_magic_2/game/items/recipes/ethereal_recipes.dart';
import 'package:masters_of_magic_2/game/items/recipes/jewelry_recipes.dart';
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

/// Total banked XP that puts a skill at exactly [level].
///
/// ⚠️ Summed from `Skills.xpToNext` rather than from a closed form, so a
/// change to the curve moves the fixtures with it instead of making them
/// quietly test the wrong level.
int _xpToReach(int level) {
  var total = 0;
  for (var l = 1; l < level; l++) {
    total += Skills.xpToNext(l);
  }
  return total;
}

/// ⚠️ Written out rather than read from [ItemCatalogue.byZone]. Every one of
/// this quarter's 32 outputs is owned by an Ethereal catalogue — the ladder
/// mints nothing into an earlier quarter's file — and taking the catalogue's
/// own key set would make that law unfalsifiable.
const _etherealZones = <String>{
  'hallowmarch',
  'the_buried_sky',
  'the_umbral_wastes',
  'the_sealed_garden',
  'the_collapsed_academy',
  'the_reliquary_deep',
  'the_unwritten_library',
  'the_eclipsed_citadel',
};

/// ⭐ §5.1's banking table, transcribed: the seven gems banked across three
/// quarters, each with the one Jewelry recipe that spends it. ⚠️ §0.2 rules
/// that nothing may be left unspent, so this map is the ruling made
/// checkable — a gem losing its consumer is a promise the game stops paying.
const _bankedGems = <String, String>{
  'quarry_jasper': 'craft_everice_band', // Old Quarry, Q2, L15–19
  'everice': 'craft_everice_band', // Frostfell Pass, Q2, L21–26
  'obsidian': 'craft_nacre_pendant', // The Molten Deep, Q2, L25–29
  'nacre': 'craft_nacre_pendant', // Tidewrack Shoals, Q3, L36–40
  'eclipse_opal': 'craft_eclipse_signet', // The Sunless Reach, Q3, L38–42
  'sidereal_glass': 'craft_eclipse_signet', // The Shattered Orrery, Q3
  'aetherglass': 'craft_aetherglass_locket', // The Glass Archive, Q3
};

/// §5.1's table, transcribed as `id -> expected XP`. ⭐ The second source the
/// formula is checked against: `Skills.xpForRecipe` recomputes it from the
/// inputs and the gate, so a wrong count or a wrong gate shows up here even
/// when both halves are self-consistent.
const _tableXp = <String, int>{
  'craft_deepsteel_ingot': 480,
  'craft_aethersteel_ingot': 520,
  'craft_spiritwood_quarterstaff': 384,
  'craft_spiritwood_wand': 288,
  'craft_spiritwood_knot': 192,
  'craft_aetherwood_quarterstaff': 416,
  'craft_aetherwood_wand': 312,
  'craft_aetherwood_knot': 208,
  'craft_umbralweave_hood': 276,
  'craft_umbralweave_robe': 552,
  'craft_umbralweave_leggings': 460,
  'craft_umbralweave_boots': 276,
  'craft_umbralweave_gloves': 276,
  'craft_corebiter_belt': 288,
  'craft_unleft_hood': 300,
  'craft_unleft_robe': 600,
  'craft_unleft_leggings': 500,
  'craft_unleft_boots': 300,
  'craft_unleft_gloves': 300,
  'craft_penitent_belt': 300,
  'craft_blankspine_belt': 312,
  'craft_goldenrood_draught': 288,
  'craft_worldroot_tonic': 300,
  'craft_censer_draught': 400,
  'craft_nightink_draught': 416,
  'craft_everice_band': 30,
  'craft_nacre_pendant': 144,
  'craft_eclipse_signet': 308,
  'craft_aetherglass_locket': 320,
  'craft_orchard_loop': 370,
  'craft_corona_torc': 460,
  'craft_eclipse_ring': 520,
};

void main() {
  group('the 32 are registered', () {
    test('EtherealRecipes.all is exactly 32, ids unique', () {
      expect(
        EtherealRecipes.all,
        hasLength(32),
        reason:
            '§7.1\'s table is 32 rows — above the ~20–26 guide because '
            'Jewelry debuts with seven (§5). A stray entry or a dropped one '
            'both break this count',
      );
      final ids = EtherealRecipes.all.map((r) => r.id).toSet();
      expect(
        ids,
        hasLength(32),
        reason:
            'a duplicated id shadows another in RecipeBook._byId — the '
            'shadowed recipe silently disappears from the craft screen',
      );
    });

    test('every Ethereal recipe is reachable through RecipeBook.all', () {
      for (final r in EtherealRecipes.all) {
        expect(
          RecipeBook.tryById(r.id),
          same(r),
          reason:
              '${r.id} is authored but not registered in RecipeBook — '
              'the silent failure `recipe_book.dart`\'s own doc warns '
              'about: it compiles fine and never resolves',
        );
      }
    });

    test('⚠️ no duplicate recipe id anywhere in the game', () {
      // Game-wide, not just this quarter: RecipeBook._byId is last-wins, so
      // a collision with ANY earlier quarter silently deletes a recipe.
      final ids = RecipeBook.all.map((r) => r.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason:
            'two recipes share an id somewhere in RecipeBook.all — '
            'whichever spreads last wins and the other becomes '
            'unreachable, with nothing failing to say so',
      );
      final earlier = {for (final r in RecipeBook.all) r.id}
        ..removeAll(EtherealRecipes.all.map((r) => r.id));
      for (final r in EtherealRecipes.all) {
        expect(
          earlier,
          isNot(contains(r.id)),
          reason:
              '${r.id} is already owned by a Primal, Kinetic or Celestial '
              'recipe',
        );
      }
    });

    test('every recipe id is `craft_<outputId>` (§3.5)', () {
      for (final r in EtherealRecipes.all) {
        expect(
          r.id,
          'craft_${r.outputId}',
          reason:
              '§3.5 pins the recipe id convention; ${r.id} makes '
              '${r.outputId} and the wiki export keys off the pair matching',
        );
      }
    });

    test('the skill split matches §7.1: Tailoring 13, Woodcarving 6, '
        'Jewelry 7, Potions 4, Metalworking 2, Enchanting 0', () {
      int countOf(CraftSkill s) =>
          EtherealRecipes.all.where((r) => r.skill == s).length;
      expect(
        countOf(CraftSkill.tailoring),
        13,
        reason:
            '⭐ two sets + THREE belts — the one quarter that breaks the '
            '5+5+2 pattern, because §5.3 gives the belt ladder its last '
            'three rungs here',
      );
      expect(
        countOf(CraftSkill.woodcarving),
        6,
        reason:
            'two wood tiers × (quarterstaff, wand, knot) — Celestial had '
            'three tiers and nine',
      );
      expect(
        countOf(CraftSkill.jewelry),
        7,
        reason:
            '⭐⭐ the debut, and the number is not free: seven recipes for '
            'seven banked gems (§5.3). Trimming one strands a material '
            '§0.2 rules must be spent',
      );
      expect(
        countOf(CraftSkill.potionsAndAlchemy),
        4,
        reason: '§3.3 runs the Draught/Tonic alternation to the end',
      );
      expect(
        countOf(CraftSkill.metalworking),
        2,
        reason: 'the feeder lane stays two ingots, a fourth quarter running',
      );
      expect(
        countOf(CraftSkill.enchanting),
        0,
        reason:
            '⚠️ §5.2 — Enchanting gets nothing this quarter. CELESTIAL '
            '§8.2\'s ❓ (does Transmute pay XP?) is still open, and a '
            'recipe added here to "fix" it is a builder overruling a '
            'designer',
      );
      expect(
        EtherealRecipes.all.length,
        13 + 6 + 7 + 4 + 2 + 0,
        reason:
            'the six per-skill counts must add to the whole ladder, or one '
            'recipe carries a skill §7.1 never assigned',
      );
    });
  });

  group('every input and output resolves, and is in-band', () {
    test('every output id resolves through ItemCatalogue', () {
      for (final r in EtherealRecipes.all) {
        expect(
          ItemCatalogue.tryById(r.outputId),
          isNotNull,
          reason:
              '${r.id} mints ${r.outputId}, which no catalogue owns — '
              'craft() refuses with "That cannot be made" and the recipe '
              'is dead content',
        );
      }
    });

    test('every input id resolves through ItemCatalogue', () {
      for (final r in EtherealRecipes.all) {
        for (final i in r.inputs) {
          expect(
            ItemCatalogue.tryById(i.defId),
            isNotNull,
            reason: '${r.id} eats ${i.defId}, which no catalogue owns',
          );
        }
      }
    });

    test('⚠️ every output is defined by one of this quarter\'s eight zones '
        '(§3.5)', () {
      for (final r in EtherealRecipes.all) {
        final zone = ItemCatalogue.zoneOf(r.outputId);
        expect(
          zone,
          isNotNull,
          reason:
              '${r.outputId} resolves by id but no zone owns it — an icon '
              'path that can never load, with nothing failing to say so',
        );
        expect(
          _etherealZones,
          contains(zone),
          reason:
              '${r.id} mints ${r.outputId}, which $zone defines — not an '
              'Ethereal zone. §3.5\'s "no builder edits an earlier '
              'quarter\'s catalogue" has its other half here: this '
              'quarter\'s ladder mints only into this quarter\'s files',
        );
      }
    });

    test('⭐ every input is obtainable in-band: a drop, a node, or a prior '
        'craft (§7.4)', () {
      final drops = _allDropIds();
      final nodes = _allNodeIds();
      final craftedOutputs = RecipeBook.all.map((r) => r.outputId).toSet();

      for (final r in EtherealRecipes.all) {
        for (final i in r.inputs) {
          final obtainable =
              drops.contains(i.defId) ||
              nodes.contains(i.defId) ||
              craftedOutputs.contains(i.defId);
          expect(
            obtainable,
            isTrue,
            reason:
                '${r.id} needs ${i.defId}, which drops from nothing, has '
                'no gather node, and is no recipe\'s output — a material '
                'the player can never actually acquire',
          );
        }
      }
    });

    test('⚠️ every input is fungible (RecipeInput\'s own law)', () {
      for (final r in EtherealRecipes.all) {
        for (final i in r.inputs) {
          expect(
            ItemCatalogue.byId(i.defId).isFungible,
            isTrue,
            reason:
                '${r.id} eats ${i.defId}, a non-fungible — crafting eats '
                'stacks, salvage eats instances. A non-fungible input '
                'would need instance-selection UI and provenance tracking '
                'nothing in crafting has',
          );
        }
      }
    });

    test('⭐ every non-fungible output is built from fungibles only', () {
      final nonFungibleMakers = [
        for (final r in EtherealRecipes.all)
          if (!ItemCatalogue.byId(r.outputId).isFungible) r,
      ];
      expect(
        nonFungibleMakers,
        hasLength(26),
        reason:
            'the 26 equipment recipes — 6 Woodcarving + 13 Tailoring + 7 '
            'Jewelry. The two ingots and the four potions are fungible '
            'outputs and roll no quality',
      );
      for (final r in nonFungibleMakers) {
        expect(
          r.inputs.every((i) => ItemCatalogue.byId(i.defId).isFungible),
          isTrue,
          reason:
              '${r.id} rolls a quality on its output, so every input must '
              'be a stack — otherwise one instance\'s roll would silently '
              'feed another\'s',
        );
      }
    });

    test('⭐ charcoal is spent a FOURTH quarter running, and still gathers', () {
      expect(
        ItemCatalogue.tryById('charcoal'),
        isNotNull,
        reason:
            'Ashfall Vale\'s L10 material is this quarter\'s one '
            'cross-quarter ore-lane input; renaming it silently empties '
            'both ingots',
      );
      expect(
        _allNodeIds(),
        contains('charcoal'),
        reason:
            'a banked material with no node left is a promise the player '
            'cannot go and collect on — §9b.6\'s "a concrete reason to '
            'revisit old zones"',
      );
      final charcoalEaters = EtherealRecipes.all
          .where((r) => r.inputs.any((i) => i.defId == 'charcoal'))
          .map((r) => r.id)
          .toSet();
      expect(
        charcoalEaters,
        {'craft_deepsteel_ingot', 'craft_aethersteel_ingot'},
        reason:
            '§5.1: exactly the two ingots. A third consumer would change '
            'the revisit economics the contract worked out',
      );
    });

    test('⚠️ the three kill-only hides get no gather node (§6)', () {
      // §6: "Five materials get none" — three kill-only hides plus the
      // Citadel's two. A node for any hide would make its belt gatherable
      // and quietly delete the reason it earns its own gate.
      for (final hide in [
        'corebiter_hide',
        'thornpenitent_hide',
        'blankspine_vellum',
      ]) {
        expect(
          _allNodeIds(),
          isNot(contains(hide)),
          reason:
              '$hide is a hide; §9b.7b makes hides kill-only and §6 counts '
              'exactly three of them this quarter',
        );
        expect(
          _allDropIds(),
          contains(hide),
          reason: '$hide is kill-only, so a kill had better yield it',
        );
      }
    });

    test(
      '⚠️ the Citadel\'s two Jewelry materials are kill-only too (§3.1)',
      () {
        // Distinguishing regression: a helpful builder giving the Citadel a
        // gather node. §3.1 rules it has none at all.
        for (final id in ['eclipse_iron', 'corona_pearl']) {
          expect(
            _allNodeIds(),
            isNot(contains(id)),
            reason:
                '$id must stay kill-only — §3.1 gives the Eclipsed Citadel '
                'zero gather nodes, so the last two Jewelry recipes are '
                'earned in the fight and nowhere else',
          );
          expect(
            _allDropIds(),
            contains(id),
            reason:
                '$id has no node by ruling, so a kill is the ONLY source — '
                'if it does not drop either, the game\'s last ring cannot be '
                'made at all',
          );
        }
      },
    );

    test('⚠️ no mote is consumed by any Ethereal recipe (§7.5)', () {
      final motes = {
        for (final d in ItemCatalogue.all)
          if (d is MoteDef) d.id,
      };
      expect(
        motes,
        isNotEmpty,
        reason:
            'if MoteDef ever stops being the mote kind this guard silently '
            'checks nothing',
      );
      final consumed = {
        for (final r in EtherealRecipes.all)
          for (final i in r.inputs) i.defId,
      };
      expect(
        consumed.intersection(motes),
        isEmpty,
        reason:
            'ECONOMY §14c makes motes sell-only and lossy against the '
            'refinement ladder — a mote in a gear recipe makes '
            'refine-and-craft a second, unaudited arbitrage',
      );
    });
  });

  group('the ladder actually climbs', () {
    test('gates are non-decreasing per skill, in table order (§5.2)', () {
      for (final skill in CraftSkill.values) {
        final ladder = [
          for (final r in EtherealRecipes.all)
            if (r.skill == skill) r,
        ];
        for (var i = 1; i < ladder.length; i++) {
          expect(
            ladder[i].skillLevel,
            greaterThanOrEqualTo(ladder[i - 1].skillLevel),
            reason:
                '$skill regresses at ${ladder[i].id} (gate '
                '${ladder[i].skillLevel}) after ${ladder[i - 1].id} (gate '
                '${ladder[i - 1].skillLevel}) — `Skills.allRecipesFor` '
                'reads `all` in order and would show the ladder going '
                'backwards',
          );
        }
      }
    });

    test('⭐ each skill\'s distinct gates are exactly §5.2\'s rows', () {
      List<int> gatesFor(CraftSkill s) => <int>{
        for (final r in EtherealRecipes.all)
          if (r.skill == s) r.skillLevel,
      }.toList()..sort();

      expect(gatesFor(CraftSkill.metalworking), [
        46,
        50,
      ], reason: '§5.2: Metalworking 46 then 50, and nothing between');
      expect(gatesFor(CraftSkill.woodcarving), [
        46,
        50,
      ], reason: '§5.2: Spiritwood 46, Aetherwood 50 — one per tier');
      expect(
        gatesFor(CraftSkill.tailoring),
        [44, 46, 48, 50],
        reason:
            '§5.2: Umbralweave 44, Corebiter belt 46, Unleft + Penitent '
            'belt 48, Blankspine belt 50 — ⚠️ the Penitent belt shares 48 '
            'with the Unleft set rather than sitting between the sets, '
            'which is what §5.1\'s table says',
      );
      expect(
        gatesFor(CraftSkill.potionsAndAlchemy),
        [46, 48, 50],
        reason:
            '§5.2: four potions across three gates — Censer and Worldroot '
            'share 48',
      );
      expect(
        gatesFor(CraftSkill.jewelry),
        [1, 10, 20, 30, 35, 44, 50],
        reason:
            '⭐⭐ §5.2: "a complete seven-rung ladder from 1 to 50 inside '
            'one quarter, which no other skill has ever been given." Seven '
            'recipes at seven DISTINCT gates — two sharing a gate would '
            'leave a rung with nothing to climb on, which is exactly '
            'Metalworking\'s inherited grind repeating',
      );
    });

    test('⚠️ every non-Jewelry gate sits in the band §5.1 authors (44–50)', () {
      for (final r in EtherealRecipes.all) {
        if (r.skill == CraftSkill.jewelry) continue;
        expect(
          r.skillLevel,
          inInclusiveRange(44, 50),
          reason:
              '${r.id} gates at ${r.skillLevel}, outside 44–50 — a gate '
              'below 44 makes the quarter craftable from the previous '
              'band, and one above 50 makes it uncraftable inside its own',
        );
      }
    });

    test('⭐ Jewelry is the only skill reaching under 44 — the debut', () {
      final underBand = <CraftSkill>{
        for (final r in EtherealRecipes.all)
          if (r.skillLevel < 44) r.skill,
      };
      expect(
        underBand,
        {CraftSkill.jewelry},
        reason:
            'a sub-44 gate on any other skill would mean a SECOND skill '
            'debuted this quarter, which §5.3 says only Jewelry does',
      );
      expect(
        [for (final r in EtherealRecipes.all) r.skillLevel].reduce(min),
        1,
        reason:
            '⭐ §5.2: the Everice Band gates at 1. A player learns Jewelry '
            'at Rimeholt with zero XP and is therefore level 1 — any '
            'higher floor is a tier gate nobody can pass on the day the '
            'skill opens',
      );
    });

    test('⭐ Jewelry\'s ladder is climbable: each rung is reachable from the '
        'XP the rungs below it pay', () {
      // Distinguishing regression: §5.2's whole claim is that this ladder
      // does NOT repeat Metalworking's 28-craft grind. That is only true if
      // the recipes below each gate actually pay enough XP to reach it —
      // a gate raised without a rung beneath it passes every other test
      // in this file.
      final jewelry = [
        for (final r in EtherealRecipes.all)
          if (r.skill == CraftSkill.jewelry) r,
      ];
      // §5.2's own "Crafts after the previous gate" column, recomputed:
      // the XP still owed on reaching a gate, over the best-paying rung
      // already open. ⚠️ Measured from the PREVIOUS gate, not from zero —
      // XP earned on the way to rung N is not spent again on rung N+1.
      final craftsPerRung = [
        for (var i = 1; i < jewelry.length; i++)
          ((_xpToReach(jewelry[i].skillLevel) -
                      _xpToReach(jewelry[i - 1].skillLevel)) /
                  jewelry.take(i).map(Skills.xpForRecipe).reduce(max))
              .ceil(),
      ];
      expect(
        craftsPerRung,
        [12, 7, 5, 3, 6, 4],
        reason:
            '§5.2\'s table, transcribed: 12 Everice Bands open gate 10, then '
            '7 Pendants, 5 Signets, 3 Lockets, 6 Loops, 4 Torcs. ⚠️ A gate '
            'raised without a rung beneath it, or a rung whose XP quietly '
            'drops, shows up here as a longer grind while passing every '
            'other test in this file',
      );
      expect(
        craftsPerRung.reduce(max),
        12,
        reason:
            '⭐ §5.2: the debut rung is the longest stretch in the ladder and '
            'it is twelve crafts — CELESTIAL §5.2 flagged Metalworking\'s '
            'inherited ~28-craft grind as the Celestial quarter\'s one '
            'problem, and "Jewelry does not repeat it" is this number',
      );
    });
  });

  group('XP is the formula, on every row of §5.1', () {
    test('Skills.xpForRecipe reproduces all 32 table values', () {
      for (final r in EtherealRecipes.all) {
        expect(
          Skills.xpForRecipe(r),
          _tableXp[r.id]!,
          reason:
              '${r.id}: §5.1 says ${_tableXp[r.id]} XP. The formula is '
              'Σ counts × (4 + 2 × gate), so a mismatch means an input '
              'count or a gate level was transcribed wrong — the table '
              'and the code disagree and the table is canon',
        );
      }
    });

    test('the transcribed table covers exactly the authored ids', () {
      // Without this, a recipe dropped from `all` would make the loop above
      // pass vacuously for that row.
      expect(
        EtherealRecipes.all.map((r) => r.id).toSet(),
        _tableXp.keys.toSet(),
        reason:
            'the §5.1 transcription and the authored ladder must name the '
            'same 32 recipes, or one of them is checking nothing',
      );
    });

    test('⭐ hand-worked spot checks, independent of the map', () {
      expect(
        Skills.xpForRecipe(EtherealRecipes.unleftRobe),
        6 * (4 + 2 * 48),
        reason: 'Unleft Robe: 6 inputs × 100 = 600, the ladder\'s best XP',
      );
      expect(
        Skills.xpForRecipe(EtherealRecipes.evericeBand),
        5 * (4 + 2 * 1),
        reason:
            '⚠️ the Everice Band: 5 inputs × 6 = 30. Gate 1 makes it the '
            'quarter\'s cheapest XP despite closing a promise made two '
            'quarters ago — deliberate, since it is the rung everything '
            'else in Jewelry is climbed from',
      );
      expect(
        Skills.xpForRecipe(EtherealRecipes.eclipseRing),
        5 * (4 + 2 * 50),
        reason: 'the game\'s last recipe: (3+2) × 104 = 520',
      );
    });
  });

  group('⭐⭐ §5.3 slot coverage — the promise closes', () {
    test('every equip slot in the game has a maker, for the first time', () {
      // ⭐⭐ §6a.1's claim, asserted GAME-WIDE rather than per quarter —
      // the whole point of this quarter is that the claim stops being
      // aspirational. A slot dropping out is a regression in a promise
      // sixty levels in the making.
      final made = <EquipSlot>{
        for (final r in RecipeBook.all)
          if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d) d.slot,
      };
      expect(
        made,
        EquipSlot.values.toSet(),
        reason:
            '⭐⭐ §5.3: "every slot has a maker becomes true here, for the '
            'first time, sixty levels in." Missing: '
            '${EquipSlot.values.toSet().difference(made)} — a slot with no '
            'recipe is a slot the player can only ever fill from a drop',
      );
    });

    test(
      '⭐ Neck and Ring are newly filled, and Jewelry is what fills them',
      () {
        // Distinguishing regression: the two slots that were drop-only from
        // the Whispering Woods to The Glass Archive. Before this quarter NO
        // recipe made either; the assertion is not "some recipe does" but
        // "exactly these seven, all Jewelry, all Ethereal".
        //
        // 📝 2026-10-01 — ENCHANTING §5.3 (scope ruling 2) added a Jewelry
        // ladder below Rimeholt in its own file, `JewelryRecipes.ladder`. So
        // the seven are now "the Ethereal quarter's", and every OTHER maker
        // in the book must be one of the ladder's twelve — ⚠️ still never a
        // recipe in an earlier quarter's own file, which is the mutant.
        List<String> makersOf(EquipSlot slot, Iterable<RecipeDef> book) => [
          for (final r in book)
            if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
              if (d.slot == slot) r.id,
        ];
        expect(
          makersOf(EquipSlot.neck, EtherealRecipes.all),
          [
            'craft_nacre_pendant',
            'craft_aetherglass_locket',
            'craft_corona_torc',
          ],
          reason:
              '§5.3: the three Ethereal Neck makers, in gate order. An extra '
              'one means the quarter grew a necklace recipe it was not given',
        );
        expect(makersOf(EquipSlot.ring, EtherealRecipes.all), [
          'craft_everice_band',
          'craft_eclipse_signet',
          'craft_orchard_loop',
          'craft_eclipse_ring',
        ], reason: '§5.3: the four Ethereal Ring makers, in gate order');
        final ladder = JewelryRecipes.ladder.map((r) => r.id).toSet();
        for (final slot in [EquipSlot.neck, EquipSlot.ring]) {
          final elsewhere = makersOf(
            slot,
            RecipeBook.all,
          ).toSet().difference(makersOf(slot, EtherealRecipes.all).toSet());
          expect(
            elsewhere.difference(ladder),
            isEmpty,
            reason:
                '${slot.name}: an earlier quarter grew a ${slot.name} recipe '
                'it was ruled not to have — the only makers outside this '
                'quarter are ENCHANTING §5.3\'s ladder',
          );
        }
        for (final id in [
          ...makersOf(EquipSlot.neck, RecipeBook.all),
          ...makersOf(EquipSlot.ring, RecipeBook.all),
        ]) {
          expect(
            RecipeBook.tryById(id)!.skill,
            CraftSkill.jewelry,
            reason:
                '$id fills Neck or Ring but is not Jewelry — §5.3 says '
                'Jewelry is what closes these two, and a Tailoring necklace '
                'would close them by accident instead',
          );
        }
      },
    );

    test('⭐ Jewelry makes Neck and Ring and NOTHING else', () {
      final jewelrySlots = <EquipSlot>{
        for (final r in EtherealRecipes.all)
          if (r.skill == CraftSkill.jewelry)
            if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
              d.slot,
      };
      expect(
        jewelrySlots,
        {EquipSlot.neck, EquipSlot.ring},
        reason:
            '§5.3: Jewelry\'s remit is the two slots nothing else covers. '
            'A Jewelry belt or hat would overlap Tailoring and make the '
            'debut a second maker for a solved slot',
      );
    });

    test('Woodcarving and Tailoring keep their remits unchanged', () {
      Set<EquipSlot> slotsFor(CraftSkill skill) => {
        for (final r in EtherealRecipes.all)
          if (r.skill == skill)
            if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
              d.slot,
      };
      expect(
        slotsFor(CraftSkill.woodcarving),
        {EquipSlot.mainHand, EquipSlot.offHand},
        reason:
            '§5.3: Woodcarving is the Main Hand and Off Hand maker, two '
            'tiers of each this quarter',
      );
      expect(
        slotsFor(CraftSkill.tailoring),
        {
          EquipSlot.hat,
          EquipSlot.robeTop,
          EquipSlot.robeBottom,
          EquipSlot.boots,
          EquipSlot.gloves,
          EquipSlot.belt,
        },
        reason:
            '§5.3: Tailoring still covers every armour slot plus the belt '
            '— a missing one is a slot with no maker this quarter',
      );
      final belts = [
        for (final r in EtherealRecipes.all)
          if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
            if (d.slot == EquipSlot.belt) r.outputId,
      ];
      expect(
        belts,
        ['corebiter_belt', 'penitent_belt', 'blankspine_belt'],
        reason:
            '⭐ §5.3: "Tailoring (3)" — the belt ladder\'s last three rungs, '
            'in gate order. Celestial and Kinetic gave two each',
      );
    });

    test('⭐ Metalworking feeds four recipes, and two of them are Jewelry', () {
      final ingotConsumers = EtherealRecipes.all
          .where(
            (r) => r.inputs.any(
              (i) =>
                  i.defId == 'deepsteel_ingot' ||
                  i.defId == 'aethersteel_ingot',
            ),
          )
          .map((r) => r.id)
          .toSet();
      expect(
        ingotConsumers,
        {
          'craft_spiritwood_quarterstaff',
          'craft_spiritwood_wand',
          'craft_aetherwood_quarterstaff',
          'craft_aetherwood_wand',
          'craft_nacre_pendant',
          'craft_orchard_loop',
          'craft_corona_torc',
        },
        reason:
            '⭐ §5.3\'s "Metalworking feeds 4" counts Woodcarving weapons; '
            'this quarter Jewelry becomes a THIRD consumer of the feeder '
            'lane (Pendant, Loop, Torc). A missing one means an ingot '
            'quietly dropped out of a mount',
      );
      expect(
        ingotConsumers.map((id) => RecipeBook.tryById(id)!.skill).toSet(),
        {CraftSkill.woodcarving, CraftSkill.jewelry},
        reason:
            'Metalworking must stay a pure FEEDER — nothing is crafted '
            'from an ingot by Metalworking itself, a fourth quarter running',
      );
    });

    test('⚠️ no knot eats an ingot, and no set piece eats anything but its '
        'own bolt', () {
      // Distinguishing regression: copying a quarterstaff's input list onto
      // the knot is the easy transcription slip, and it passes every count
      // and resolution check above.
      for (final id in ['spiritwood_knot', 'aetherwood_knot']) {
        expect(
          RecipeBook.tryById('craft_$id')!.inputs,
          hasLength(1),
          reason:
              'craft_$id takes logs and nothing else — §5.1 gives the '
              'off-hand no ferrule at any tier',
        );
      }
      for (final r in EtherealRecipes.all) {
        if (r.skill != CraftSkill.tailoring) continue;
        if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d) {
          if (d.slot == EquipSlot.belt) continue;
          expect(
            r.inputs,
            hasLength(1),
            reason:
                '${r.id} is a set piece: §5.1 gives every Umbralweave and '
                'Unleft garment exactly one material line. Only the three '
                'belts take a second (the thread)',
          );
        }
      }
    });
  });

  group('⭐⭐ the seven banked gems — §0.2\'s ruling, made checkable', () {
    test('each banked gem is consumed by exactly one Ethereal Jewelry '
        'recipe', () {
      // 📝 2026-10-01 — ENCHANTING §5.1/§5.3 gave these stones more Jewelry
      // consumers (the gem cuts and the ladder below Rimeholt), priced in
      // ECONOMY §8.8. The §5.1 payoff this test pins is THIS quarter's one
      // recipe per stone; the new eaters must all be Jewelry and all live in
      // `JewelryRecipes`, never in a quarter's own file.
      final enchantingJewelry = JewelryRecipes.all.map((r) => r.id).toSet();
      for (final entry in _bankedGems.entries) {
        final eaters = [
          for (final r in EtherealRecipes.all)
            if (r.inputs.any((i) => i.defId == entry.key)) r.id,
        ];
        final others = {
          for (final r in RecipeBook.all)
            if (r.inputs.any((i) => i.defId == entry.key)) r.id,
        }.difference(eaters.toSet());
        expect(
          others.difference(enchantingJewelry),
          isEmpty,
          reason:
              '${entry.key} gained a consumer outside the Ethereal payoff and '
              'outside ENCHANTING §5\'s Jewelry recipes — an uninvited eater',
        );
        expect(
          eaters,
          [entry.value],
          reason:
              '⚠️ ${entry.key} was banked under ITEMS §9b.8 ruling 7\'s '
              'promise "gatherable now, spendable next quarter". §5.1 '
              'spends it in ${entry.value} and nowhere else — two '
              'consumers make the gem a bottleneck the contract never '
              'priced, and zero leaves a promise unpaid',
        );
        expect(
          RecipeBook.tryById(entry.value)!.skill,
          CraftSkill.jewelry,
          reason:
              '${entry.key} must be spent by JEWELRY — §8.1 banked it '
              'against the skill\'s debut, not against whatever recipe '
              'happens to want a shiny stone',
        );
      }
    });

    test('⚠️ all seven are still gatherable — a walk back, not a lockout', () {
      // §5.1: "A player who ignored every jewel material from level 15
      // onward arrives at Rimeholt with an empty bag and a maker they
      // cannot feed. That is the intended lesson and it is a harsh one —
      // all seven are still gatherable." Removing a node turns the lesson
      // into an unrecoverable dead end.
      expect(
        _allNodeIds(),
        containsAll(_bankedGems.keys),
        reason:
            'a banked gem whose node was removed makes its Jewelry recipe '
            'permanently uncraftable for any player who did not hoard — '
            'the lockout §5.1 explicitly rules out',
      );
    });

    test('⭐ the seven are spread over exactly four Jewelry recipes, and the '
        'other three are made of this quarter\'s own stones', () {
      final bankFed = <String>{..._bankedGems.values};
      expect(
        bankFed,
        {
          'craft_everice_band',
          'craft_nacre_pendant',
          'craft_eclipse_signet',
          'craft_aetherglass_locket',
        },
        reason:
            '§5.1: "#26 through #29 are the payoff of every banking clause '
            'in the design docs." The Loop, the Torc and the Ring are '
            'this quarter\'s own — if a banked gem migrates into one of '
            'them the four-recipe payoff story stops being true',
      );
      final selfFed = EtherealRecipes.all
          .where((r) => r.skill == CraftSkill.jewelry)
          .where((r) => !bankFed.contains(r.id))
          .map((r) => r.id)
          .toList();
      expect(selfFed, [
        'craft_orchard_loop',
        'craft_corona_torc',
        'craft_eclipse_ring',
      ], reason: '§5.1 #30–#32, the ladder\'s top three rungs');
      for (final id in selfFed) {
        for (final i in RecipeBook.tryById(id)!.inputs) {
          expect(
            _bankedGems.keys,
            isNot(contains(i.defId)),
            reason:
                '$id eats ${i.defId}, a banked gem — that both double-books '
                'a material §0.2 allots to one recipe and makes the top of '
                'the ladder depend on hoarding since level 15',
          );
        }
      }
    });

    test('⚠️ Rimeholt is where Jewelry is learned, and it opens at 45', () {
      final rimeholt = World.locations.firstWhere((l) => l.id == 'rimeholt');
      expect(
        rimeholt.station,
        'Jewelry',
        reason:
            '§0.1 canon (ITEMS §9b.8 ruling 9, KINETIC §8.1): the station '
            'and the learning are Rimeholt\'s. If the station moves, every '
            'banking clause in three contracts points at the wrong town',
      );
      expect(
        rimeholt.opensAtLevel,
        45,
        reason:
            'the seven gems were banked against L45 specifically — a '
            'different door level re-times three quarters of promises',
      );
      expect(
        ItemCatalogue.byId('everice_band'),
        isA<EquipmentDef>().having((d) => d.equipLevel, 'equipLevel', 45),
        reason:
            '⭐ §4.2: the Band\'s equip level is 45, one BELOW the Buried '
            'Sky\'s band floor of 46, deliberately — "a player learns '
            'Jewelry at Rimeholt and should be able to wear the first '
            'thing they make before they walk anywhere"',
      );
    });
  });

  group('⭐ every recipe has an authored gesture script', () {
    test('no recipe falls back to the plain button', () {
      for (final r in EtherealRecipes.all) {
        expect(
          r.steps,
          isNotEmpty,
          reason:
              '${r.id} has no steps, so the Workbench silently drops to '
              'the plain button — the craft act disappears with nothing '
              'failing',
        );
        expect(
          r.steps.length,
          inInclusiveRange(2, 3),
          reason:
              '${r.id} has ${r.steps.length} steps; the shipped ladder is '
              '2–3 throughout and a fourth is a new act shape, not a '
              'transcription',
        );
      }
    });

    test('⚠️ nothing in this quarter requires a station (§9b.2)', () {
      final gated = [
        for (final r in EtherealRecipes.all)
          if (r.stationRequired) r.id,
      ];
      expect(
        gated,
        isEmpty,
        reason:
            '§9b.2: stations are convenience, not gates. The Celestial '
            'Totem is the only `true` in the game and it is one because a '
            'TIER GATE must not be craftable in the field — Rimeholt '
            'teaches Jewelry, it does not own every subsequent craft',
      );
    });

    test('⭐ Jewelry\'s script climbs with its gate', () {
      // The debut rung is forgiving for the same reason `craft_bronze_ingot`
      // is; the last is the hardest act in the game. A flat script across
      // seven gates would make the ladder read as seven copies.
      final jewelry = [
        for (final r in EtherealRecipes.all)
          if (r.skill == CraftSkill.jewelry) r,
      ];
      int effort(RecipeDef r) =>
          r.steps.fold(0, (sum, s) => sum + s.reps * s.complexity);
      for (var i = 1; i < jewelry.length; i++) {
        expect(
          effort(jewelry[i]),
          greaterThan(effort(jewelry[i - 1])),
          reason:
              '${jewelry[i].id} (gate ${jewelry[i].skillLevel}) is no '
              'harder to perform than ${jewelry[i - 1].id} (gate '
              '${jewelry[i - 1].skillLevel}) — the seven-rung ladder §5.2 '
              'celebrates would be seven copies of one act',
        );
      }
      expect(
        jewelry.first.steps,
        hasLength(2),
        reason:
            '⭐ the Everice Band is the debut recipe and its act is the '
            'short one — the role `craft_bronze_ingot` played for '
            'Metalworking',
      );
    });
  });

  group('⭐ Jewelry\'s debut, end to end', () {
    test('everice_band: a level-1 enchanter\'s counterpart — a brand-new '
        'jeweller can make the first thing in the book', () async {
      final game = _carrying({
        'everice': 2,
        'quarry_jasper': 2,
        'nadir_garnet': 1,
      });
      expect(
        game.profile.skillLevel('jewelry'),
        1,
        reason:
            'a fresh profile has zero Jewelry XP — this is the fixture the '
            'whole gate-1 design is for',
      );

      final out = await game.craft(EtherealRecipes.evericeBand, rng: Random(7));
      expect(
        out.succeeded,
        isTrue,
        reason:
            '⚠️ the distinguishing case for "gate 1 is a floor, not a '
            'wall": a player arriving at Rimeholt has never made a ring '
            'and must be able to make this one the day the skill opens',
      );
      for (final id in ['everice', 'quarry_jasper', 'nadir_garnet']) {
        expect(
          game.profile.backpack.countOf(id),
          0,
          reason: '$id is spent by the craft — all five pieces',
        );
      }
      expect(
        game.profile.backpack.countOf('everice_band'),
        1,
        reason:
            'the mint must actually happen, or the seven banked gems buy '
            'nothing',
      );
      expect(
        game.profile.skillXp['jewelry'],
        30,
        reason:
            'Skills.xpForRecipe(evericeBand) = 5 × 6 = 30 — the first '
            'Jewelry XP anyone has ever earned',
      );
      expect(
        out.quality,
        isNotNull,
        reason:
            '⭐ a ring is EquipmentDef and therefore non-fungible, so it '
            'rolls a quality (§9b.4); a null here means it minted as a '
            'stack and lost its instance',
      );
    });

    test(
      'refuses when a banked gem is missing, and names the shortfall',
      () async {
        // Distinguishing regression: the harsh lesson of §5.1 must arrive as
        // a legible refusal, not as a silent no-op.
        final game = _carrying({'everice': 2, 'nadir_garnet': 1});
        final out = await game.craft(EtherealRecipes.evericeBand);
        expect(
          out.succeeded,
          isFalse,
          reason:
              'two Quarry Jasper short — the player walked past the Old '
              'Quarry at level 15 and this is the bill',
        );
        expect(
          out.refusal,
          contains('2 more'),
          reason:
              'the refusal must count the shortfall, or the player cannot '
              'tell how far back they have to walk',
        );
        expect(
          game.profile.backpack.countOf('everice'),
          2,
          reason:
              '⚠️ a refusal must not eat materials — eating a gem banked '
              'since level 21 on a failed craft is close to unrecoverable',
        );
      },
    );

    test('⭐ the last recipe in the game: eclipse_ring at Jewelry 50', () async {
      final game = _carrying(
        {'eclipse_iron': 3, 'colophon_stone': 2},
        skillXp: {'jewelry': _xpToReach(50)},
      );
      expect(
        game.profile.skillLevel('jewelry'),
        50,
        reason:
            'the fixture must sit exactly at the gate, or this stops '
            'testing the gate',
      );
      final out = await game.craft(EtherealRecipes.eclipseRing, rng: Random(3));
      expect(out.succeeded, isTrue, reason: 'at gate, with every input');
      expect(
        game.profile.backpack.countOf('eclipse_ring'),
        1,
        reason:
            'the game\'s only crafted level-60 item must actually mint, or '
            'the ladder ends one rung short of its own top',
      );
      final slot = game.profile.backpack.slots.firstWhere(
        (s) => s?.defId == 'eclipse_ring',
      );
      expect(
        slot!.instanceId,
        isNotNull,
        reason:
            'a non-fungible carries a per-instance roll and therefore needs '
            'its own UUID',
      );
    });

    test('⚠️ one level under the gate is refused', () async {
      final game = _carrying(
        {'eclipse_iron': 3, 'colophon_stone': 2},
        skillXp: {'jewelry': _xpToReach(49)},
      );
      final out = await game.craft(EtherealRecipes.eclipseRing);
      expect(
        out.succeeded,
        isFalse,
        reason:
            'gate 50 must exclude level 49 — an off-by-one in the gate '
            'check passes every other test in this file',
      );
      expect(
        game.profile.backpack.countOf('eclipse_iron'),
        3,
        reason: 'a refusal must not eat materials',
      );
    });

    test('a crafted ring survives a JSON reload', () async {
      final storage = _JsonMem();
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'everice'),
          InventorySlot(defId: 'everice'),
          InventorySlot(defId: 'quarry_jasper'),
          InventorySlot(defId: 'quarry_jasper'),
          InventorySlot(defId: 'nadir_garnet'),
        ]);
      final game = GameState(storage, profile);
      await game.craft(EtherealRecipes.evericeBand, rng: Random(11));

      final back = GameState(storage, (await storage.load())!);
      expect(
        back.profile.backpack.countOf('everice_band'),
        1,
        reason:
            'a ring that does not survive the save spends three quarters '
            'of banked gems on nothing',
      );
      expect(
        back.profile.skillXp['jewelry'],
        30,
        reason: 'XP that does not survive the save never existed',
      );
    });
  });
}
