/// The Celestial recipe ladder (CELESTIAL_CONTRACT §5), modelled on
/// `test/kinetic_recipes_test.dart` — the same laws, for the quarter that
/// debuts Enchanting and ships the Rimeholt gate as a craft.
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
import 'package:masters_of_magic_2/game/items/recipes/celestial_recipes.dart';
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
/// ⚠️ Summed from `Skills.xpToNext` rather than from §5.2's closed form
/// `20(g−1) + 5(g−1)(g−2)/2`, so a change to the curve moves the fixtures
/// with it instead of making them quietly test the wrong level.
int _xpToReach(int level) {
  var total = 0;
  for (var l = 1; l < level; l++) {
    total += Skills.xpToNext(l);
  }
  return total;
}

/// ⚠️ Written out rather than read from [ItemCatalogue.byZone], deliberately.
/// Taking the catalogue's own key set would make the ownership law vacuous
/// today and silently admit an Ethereal item the moment Rimeholt's zones land
/// — which is the exact regression §3.5's "no builder edits an earlier
/// quarter's catalogue" rule is the other half of.
const _celestialOrEarlierZones = <String>{
  // Primal (Q1)
  'whispering_woods',
  'glimmerbrook',
  'cinderpeak_foothills',
  'thornmire',
  'ashfall_vale',
  'old_quarry',
  // Kinetic (Q2)
  'windward_steppe',
  'stormcliff_coast',
  'frostfell_pass',
  'thunderspire_peaks',
  'the_molten_deep',
  // Celestial (Q3)
  'the_kiln_desert',
  'the_mirrormere',
  'starfall_basin',
  'tidewrack_shoals',
  'the_sunless_reach',
  'the_shattered_orrery',
  'the_glass_archive',
};

/// §5.1's table, transcribed as `id -> expected XP`. ⭐ The second source the
/// formula is checked against: `Skills.xpForRecipe` recomputes it from the
/// inputs and the gate, so a wrong count or a wrong gate shows up here even
/// when both halves are self-consistent.
const _tableXp = <String, int>{
  'craft_skysteel_ingot': 380,
  'craft_starbrass_ingot': 460,
  'craft_ironwood_quarterstaff': 304,
  'craft_ironwood_wand': 228,
  'craft_ironwood_knot': 152,
  'craft_bloodwood_quarterstaff': 336,
  'craft_bloodwood_wand': 252,
  'craft_bloodwood_knot': 168,
  'craft_ebony_quarterstaff': 368,
  'craft_ebony_wand': 276,
  'craft_ebony_knot': 184,
  'craft_mirrorflax_hood': 228,
  'craft_mirrorflax_robe': 456,
  'craft_mirrorflax_leggings': 380,
  'craft_mirrorflax_boots': 228,
  'craft_mirrorflax_gloves': 228,
  'craft_drownling_belt': 240,
  'craft_wrackcotton_hood': 252,
  'craft_wrackcotton_robe': 504,
  'craft_wrackcotton_leggings': 420,
  'craft_wrackcotton_boots': 252,
  'craft_wrackcotton_gloves': 252,
  'craft_palimpsest_belt': 276,
  'craft_glasswort_draught': 144,
  'craft_duskcap_tonic': 160,
  'craft_arcsalt_draught': 264,
  'craft_sunbleach_tonic': 276,
  'craft_celestial_totem': 48,
};

void main() {
  group('the 28 are registered', () {
    test('CelestialRecipes.all is exactly 28, ids unique', () {
      expect(
        CelestialRecipes.all,
        hasLength(28),
        reason:
            '§5\'s table is 28 rows — three wood tiers where Kinetic had '
            'two (ITEMS §9b.6). A stray entry or a dropped one both break '
            'this count',
      );
      final ids = CelestialRecipes.all.map((r) => r.id).toSet();
      expect(
        ids,
        hasLength(28),
        reason:
            'a duplicated id shadows another in RecipeBook._byId — the '
            'shadowed recipe silently disappears from the craft screen',
      );
    });

    test('every Celestial recipe is reachable through RecipeBook.all', () {
      for (final r in CelestialRecipes.all) {
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

    test('⚠️ Celestial ids collide with no earlier quarter', () {
      final earlier = {for (final r in RecipeBook.all) r.id}
        ..removeAll(CelestialRecipes.all.map((r) => r.id));
      for (final r in CelestialRecipes.all) {
        expect(
          earlier,
          isNot(contains(r.id)),
          reason:
              '${r.id} is already owned by a Primal or Kinetic recipe — '
              'whichever spreads last into RecipeBook.all wins and the '
              'other becomes unreachable',
        );
      }
    });

    test('every recipe id is `craft_<outputId>` (§3.5)', () {
      for (final r in CelestialRecipes.all) {
        expect(
          r.id,
          'craft_${r.outputId}',
          reason:
              '§3.5 pins the recipe id convention; ${r.id} makes '
              '${r.outputId} and the wiki export keys off the pair '
              'matching',
        );
      }
    });

    test('the skill split matches §5: Metalworking 2, Woodcarving 9, '
        'Tailoring 12, Potions 4, Enchanting 1', () {
      int countOf(CraftSkill s) =>
          CelestialRecipes.all.where((r) => r.skill == s).length;
      expect(
        countOf(CraftSkill.metalworking),
        2,
        reason: 'the feeder lane stays two ingots (§5.3)',
      );
      expect(
        countOf(CraftSkill.woodcarving),
        9,
        reason:
            'three wood tiers × (quarterstaff, wand, knot) — the ⭐ change '
            '§5.3 records, and the whole reason 28 is above the guide',
      );
      expect(countOf(CraftSkill.tailoring), 12, reason: 'two sets + two belts');
      expect(
        countOf(CraftSkill.potionsAndAlchemy),
        4,
        reason: '§3.3 settles the KINETIC §9 debt with four rungs, not one',
      );
      expect(
        countOf(CraftSkill.enchanting),
        1,
        reason:
            '⭐ Enchanting debuts with exactly one recipe, the Totem — '
            'a second would contradict §5.2\'s "does not climb at all '
            'this quarter"',
      );
      expect(
        countOf(CraftSkill.jewelry),
        0,
        reason:
            '⚠️ §5.3 — Jewelry is still empty; its debut and its seven '
            'banked gems are ETHEREAL §5.3\'s, at Rimeholt L45',
      );
    });
  });

  group('every input and output resolves, and is in-band', () {
    test('every output id resolves through ItemCatalogue', () {
      for (final r in CelestialRecipes.all) {
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
      for (final r in CelestialRecipes.all) {
        for (final i in r.inputs) {
          expect(
            ItemCatalogue.tryById(i.defId),
            isNotNull,
            reason: '${r.id} eats ${i.defId}, which no catalogue owns',
          );
        }
      }
    });

    test(
      '⚠️ every output is defined by a Celestial-or-earlier zone (§3.5)',
      () {
        for (final r in CelestialRecipes.all) {
          final zone = ItemCatalogue.zoneOf(r.outputId);
          expect(
            zone,
            isNotNull,
            reason:
                '${r.outputId} resolves by id but no zone owns it — an icon '
                'path that can never load, with nothing failing to say so',
          );
          expect(
            _celestialOrEarlierZones,
            contains(zone),
            reason:
                '${r.id} mints ${r.outputId}, which $zone defines — a zone '
                'later than this quarter. A Celestial recipe must never '
                'reach forward into the Ethereal catalogue',
          );
        }
      },
    );

    test('⚠️ every input is obtainable in-band: a drop, a node, or a prior '
        'craft (§7.4)', () {
      final drops = _allDropIds();
      final nodes = _allNodeIds();
      final craftedOutputs = RecipeBook.all.map((r) => r.outputId).toSet();

      for (final r in CelestialRecipes.all) {
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
      for (final r in CelestialRecipes.all) {
        for (final i in r.inputs) {
          expect(
            ItemCatalogue.byId(i.defId).isFungible,
            isTrue,
            reason:
                '${r.id} eats ${i.defId}, a non-fungible — crafting eats '
                'stacks, salvage eats instances. A non-fungible input '
                'would need instance-selection UI and provenance '
                'tracking nothing in crafting has',
          );
        }
      }
    });

    test('⭐ every non-fungible output is built from fungibles only', () {
      final nonFungibleMakers = [
        for (final r in CelestialRecipes.all)
          if (!ItemCatalogue.byId(r.outputId).isFungible) r,
      ];
      expect(
        nonFungibleMakers,
        hasLength(21),
        reason:
            'the 21 equipment recipes — 9 Woodcarving + 12 Tailoring. The '
            'ingots, the four potions and the Totem are all fungible '
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

    test('⭐ the two cross-quarter inputs this ladder spends still resolve '
        'and still gather (§5)', () {
      // `charcoal` banks in Ashfall Vale at L10 and this is the THIRD quarter
      // to spend it; `hum_quartz` banked in Kinetic with no named consumer
      // until the Totem. Both are §9b.6's "a concrete reason to revisit old
      // zones", and both break if an earlier catalogue is ever renamed.
      expect(ItemCatalogue.tryById('charcoal'), isNotNull);
      expect(ItemCatalogue.tryById('hum_quartz'), isNotNull);
      expect(
        _allNodeIds(),
        containsAll(['charcoal', 'hum_quartz']),
        reason:
            'a banked material with no node left is a promise the player '
            'cannot go and collect on',
      );

      final consumed = {
        for (final r in CelestialRecipes.all)
          for (final i in r.inputs) i.defId,
      };
      expect(
        consumed,
        containsAll(['charcoal', 'iron_ingot', 'hum_quartz']),
        reason:
            '§5\'s three named cross-quarter spends — drop any one and the '
            'quarter stops paying a banking promise it was written to pay',
      );
    });

    test('⚠️ the two kill-only hides get no gather node (§6)', () {
      // §6: "Two materials get none, because hides are kill-only (§9b.7b)."
      // A node for either would make both belts gatherable and quietly
      // delete the reason they earn their own gates.
      for (final hide in ['drownling_hide', 'palimpsest_vellum']) {
        expect(
          _allNodeIds(),
          isNot(contains(hide)),
          reason:
              '$hide is a hide; §9b.7b makes hides kill-only and §6 counts '
              'exactly two materials with no node',
        );
        expect(
          _allDropIds(),
          contains(hide),
          reason: '$hide is kill-only, so a kill had better yield it',
        );
      }
    });

    test('⚠️ no mote is consumed by any Celestial recipe (§5.5)', () {
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
        for (final r in CelestialRecipes.all)
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
          for (final r in CelestialRecipes.all)
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
        for (final r in CelestialRecipes.all)
          if (r.skill == s) r.skillLevel,
      }.toList()..sort();

      expect(gatesFor(CraftSkill.metalworking), [
        36,
        44,
      ], reason: '§5.2: Metalworking 36 then 44, and nothing between');
      expect(gatesFor(CraftSkill.woodcarving), [
        36,
        40,
        44,
      ], reason: '§5.2: Ironwood 36, Bloodwood 40, Ebony 44 — one per tier');
      expect(
        gatesFor(CraftSkill.tailoring),
        [36, 38, 40, 44],
        reason:
            '§5.2: Mirrorflax 36, Drownling belt 38, Wrackcotton 40, '
            'Palimpsest belt 44 — the belts sit between the sets, not on '
            'them',
      );
      expect(
        gatesFor(CraftSkill.potionsAndAlchemy),
        [34, 38, 42, 44],
        reason:
            '§5.2: the potion ladder opens EARLIEST of the five, at 34 — '
            'the one skill a player arrives already able to use',
      );
      expect(
        gatesFor(CraftSkill.enchanting),
        [1],
        reason:
            '⭐ §5.2: "the debut: nothing to climb". Enchanting has one '
            'gate and it is 1',
      );
    });

    test(
      '⚠️ every non-Enchanting gate sits in the band §5.1 authors (34–44)',
      () {
        for (final r in CelestialRecipes.all) {
          if (r.skill == CraftSkill.enchanting) continue;
          expect(
            r.skillLevel,
            inInclusiveRange(34, 44),
            reason:
                '${r.id} gates at ${r.skillLevel}, outside 34–44 — a gate '
                'below 34 makes the quarter craftable from the previous '
                'band, and one above 44 makes it uncraftable inside its own',
          );
        }
      },
    );

    test('⭐ Potions opens the quarter and Enchanting is the only gate under '
        '34', () {
      final underBand = [
        for (final r in CelestialRecipes.all)
          if (r.skillLevel < 34) r.id,
      ];
      expect(
        underBand,
        ['craft_celestial_totem'],
        reason:
            'a second sub-34 recipe would mean some other skill also '
            'debuted this quarter, which §5.3 says only Enchanting does',
      );
      final lowestBandGate = [
        for (final r in CelestialRecipes.all)
          if (r.skill != CraftSkill.enchanting) r.skillLevel,
      ].reduce(min);
      expect(
        lowestBandGate,
        34,
        reason:
            '§5.2 has Potions 34 as the quarter\'s cheapest in-band door, '
            'reached from Q2\'s Saltwort Draught',
      );
    });
  });

  group('XP is the formula, on every row of §5.1', () {
    test('Skills.xpForRecipe reproduces all 28 table values', () {
      for (final r in CelestialRecipes.all) {
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
        CelestialRecipes.all.map((r) => r.id).toSet(),
        _tableXp.keys.toSet(),
        reason:
            'the §5.1 transcription and the authored ladder must name the '
            'same 28 recipes, or one of them is checking nothing',
      );
    });

    test('⭐ hand-worked spot checks, independent of the map', () {
      expect(
        Skills.xpForRecipe(CelestialRecipes.wrackcottonRobe),
        6 * (4 + 2 * 40),
        reason: 'Wrackcotton Robe: 6 inputs × 84 = 504, the ladder\'s best XP',
      );
      expect(
        Skills.xpForRecipe(CelestialRecipes.starbrassIngot),
        5 * (4 + 2 * 44),
        reason: 'Starbrass Ingot: (3+2) × 92 = 460',
      );
      expect(
        Skills.xpForRecipe(CelestialRecipes.celestialTotem),
        8 * (4 + 2 * 1),
        reason:
            'the Totem: 8 inputs × 6 = 48. ⚠️ Gate 1 makes it the '
            'quarter\'s cheapest XP despite being its most expensive '
            'craft — deliberate, since nothing levels off it',
      );
    });
  });

  group('§5.3 slot coverage is pinned', () {
    test('Woodcarving covers Main Hand and Off Hand, and nothing else', () {
      Set<EquipSlot> slotsFor(CraftSkill skill) => {
        for (final r in CelestialRecipes.all)
          if (r.skill == skill)
            if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
              d.slot,
      };
      expect(
        slotsFor(CraftSkill.woodcarving),
        {EquipSlot.mainHand, EquipSlot.offHand},
        reason:
            '§5.3: Woodcarving is the Main Hand and Off Hand maker, three '
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
    });

    test('⭐ three main-hand tiers and three off-hand tiers — the quarter\'s '
        'one change to coverage', () {
      final mainHands = [
        for (final r in CelestialRecipes.all)
          if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
            if (d.slot == EquipSlot.mainHand) r.outputId,
      ];
      expect(
        mainHands,
        hasLength(6),
        reason:
            '§5.3: three wood tiers × (quarterstaff, wand). Kinetic had '
            'two tiers and four',
      );
      final offHands = [
        for (final r in CelestialRecipes.all)
          if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d)
            if (d.slot == EquipSlot.offHand) r.outputId,
      ];
      expect(offHands, [
        'ironwood_knot',
        'bloodwood_knot',
        'ebony_knot',
      ], reason: '§5.3: "Knot ×3", in tier order');
    });

    test('⚠️ Neck and Ring stay drop-only — no Celestial recipe outputs '
        'either', () {
      for (final r in CelestialRecipes.all) {
        final def = ItemCatalogue.byId(r.outputId);
        if (def is EquipmentDef) {
          expect(
            def.slot,
            isNot(EquipSlot.neck),
            reason:
                '${r.id}: §5.3 — Neck stays drop-only, because Jewelry\'s '
                'station and all four of this quarter\'s jewel materials '
                'wait for Rimeholt',
          );
          expect(
            def.slot,
            isNot(EquipSlot.ring),
            reason: '${r.id}: §5.3 — Ring stays drop-only for the same reason',
          );
        }
      }
    });

    test('⭐ Metalworking feeds exactly four Woodcarving recipes (§5.3)', () {
      final ingotConsumers = CelestialRecipes.all
          .where(
            (r) => r.inputs.any(
              (i) =>
                  i.defId == 'skysteel_ingot' || i.defId == 'starbrass_ingot',
            ),
          )
          .map((r) => r.id)
          .toSet();
      expect(
        ingotConsumers,
        {
          'craft_bloodwood_quarterstaff',
          'craft_bloodwood_wand',
          'craft_ebony_quarterstaff',
          'craft_ebony_wand',
        },
        reason:
            '§5.3: "2 ingots → 4 weapons". A fifth consumer or a missing '
            'one both break the feeder-lane claim — and note the Ironwood '
            'pair is NOT here: it eats Kinetic\'s iron_ingot',
      );
      for (final id in ingotConsumers) {
        expect(
          RecipeBook.tryById(id)!.skill,
          CraftSkill.woodcarving,
          reason:
              '$id consumes an ingot but is not Woodcarving — '
              'Metalworking would no longer be a pure feeder lane',
        );
      }
      expect(
        CelestialRecipes.all
            .where((r) => r.inputs.any((i) => i.defId == 'iron_ingot'))
            .map((r) => r.id)
            .toSet(),
        {'craft_ironwood_quarterstaff', 'craft_ironwood_wand'},
        reason:
            '⭐ §5.1: the Kinetic intermediate keeps feeding one quarter '
            'later — exactly two recipes, the Ironwood weapon pair',
      );
    });

    test('⚠️ no knot eats an ingot, and no set piece eats anything but its '
        'own bolt', () {
      // Distinguishing regression: copying a quarterstaff's input list onto
      // the knot is the easy transcription slip, and it passes every count
      // and resolution check above.
      for (final id in ['ironwood_knot', 'bloodwood_knot', 'ebony_knot']) {
        final r = RecipeBook.tryById('craft_$id')!;
        expect(
          r.inputs,
          hasLength(1),
          reason:
              'craft_$id takes logs and nothing else — §5.1 gives the '
              'off-hand no ferrule at any tier',
        );
      }
      for (final r in CelestialRecipes.all) {
        if (r.skill != CraftSkill.tailoring) continue;
        if (ItemCatalogue.byId(r.outputId) case final EquipmentDef d) {
          if (d.slot == EquipSlot.belt) continue;
          expect(
            r.inputs,
            hasLength(1),
            reason:
                '${r.id} is a set piece: §5.1 gives every Mirrorflax and '
                'Wrackcotton garment exactly one material line. Only the '
                'two belts take a second (the thread)',
          );
        }
      }
    });
  });

  group('⭐ every recipe has an authored gesture script', () {
    test('no recipe falls back to the plain button', () {
      for (final r in CelestialRecipes.all) {
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

    test('⚠️ only the Totem requires a station (§3.4)', () {
      final gated = [
        for (final r in CelestialRecipes.all)
          if (r.stationRequired) r.id,
      ];
      expect(
        gated,
        ['craft_celestial_totem'],
        reason:
            '§9b.2: stations are convenience, not gates. §5.1 says the '
            'Totem "is the only recipe in this contract that does" — a '
            'second `true` makes a station a gate somewhere it was never '
            'ruled to be',
      );
    });
  });

  group(
    '⭐ the Rimeholt gate — Enchanting\'s debut and the quarter\'s point',
    () {
      test('the Totem gates at 1, at Enchanting, and is the whole skill', () {
        final totem = CelestialRecipes.celestialTotem;
        expect(
          totem.skill,
          CraftSkill.enchanting,
          reason: '§3.4: the Totem is charged by Enchanting, at Meridian',
        );
        expect(
          totem.skillLevel,
          1,
          reason:
              '⚠️ §3.4/§5.2: gate 1. Enchanting opens at Meridian with an '
              'empty book and no second recipe to earn XP on, so any gate '
              'above 1 is a tier gate nobody could ever pass — the Rimeholt '
              'barrier would be permanently shut',
        );
        expect(
          RecipeBook.forSkill(CraftSkill.enchanting),
          [totem],
          reason:
              'the Totem is the only Enchanting recipe in the entire game '
              'so far; a second would contradict §5.2\'s "does not climb at '
              'all this quarter"',
        );
      });

      test('⭐ the Totem is craftable at the band it is needed: Meridian opens '
          'at 36, Rimeholt at 45', () {
        final meridian = World.locations.firstWhere((l) => l.id == 'meridian');
        expect(
          meridian.station,
          'Enchanting',
          reason:
              '§3.4 puts the charging at Meridian — if the station moves, '
              'the only place the Totem can be made moves with it',
        );
        final rimeholt = World.locations.firstWhere((l) => l.id == 'rimeholt');
        expect(
          meridian.opensAtLevel,
          36,
          reason:
              '§3.4 puts the charging at Meridian, which opens at L36 — '
              'the band the Totem is needed in',
        );
        expect(
          rimeholt.opensAtLevel,
          45,
          reason: 'the gate the Totem opens sits nine levels further up',
        );
        expect(
          meridian.opensAtLevel!,
          lessThan(rimeholt.opensAtLevel!),
          reason:
              'the station that makes the gate item must open BEFORE the '
              'gate it opens, or the barrier is unpassable by construction',
        );
        expect(
          CelestialRecipes.celestialTotem.skillLevel,
          lessThanOrEqualTo(1),
          reason:
              '⭐ a player reaching Meridian at 36 has zero Enchanting XP '
              'and is therefore level 1; the gate must be at or under that '
              'or the quarter dead-ends',
        );
      });

      test('⚠️ rimeholt.gateItemIds is the single crafted Totem — shown, not '
          'spent (§3.4)', () {
        final rimeholt = World.locations.firstWhere((l) => l.id == 'rimeholt');
        expect(
          rimeholt.gateItemIds,
          ['celestial_totem'],
          reason:
              '⭐ KINETIC §8.6 rejected collect-three-keys. One id, not '
              'three: the essences are the RECIPE\'s inputs, not the '
              'gate\'s. An empty list makes the whole of §3.4 a lore line',
        );
        final def = ItemCatalogue.byId('celestial_totem');
        expect(
          def,
          isA<KeyDef>().having((d) => d.gates, 'gates', 'rimeholt'),
          reason:
              'the Totem must be a KeyDef pointing back at rimeholt, or the '
              'gate and the item disagree about what opens what',
        );
        expect(
          def.value,
          0,
          reason:
              'KeyDef forces value 0 and Bound — that is what exempts the '
              'Totem from §5.5\'s value-conservation window instead of '
              'failing it',
        );
      });

      test('the Totem eats the three essences, the banked quartz and the '
          'fallstone — all five lines', () {
        final byId = {
          for (final i in CelestialRecipes.celestialTotem.inputs)
            i.defId: i.count,
        };
        expect(
          byId,
          {
            'solar_essence': 1,
            'lunar_essence': 1,
            'astral_essence': 1,
            'hum_quartz': 3,
            'fallstone': 2,
          },
          reason:
              '§3.4\'s input table exactly. Dropping an essence would let a '
              'player skip one of the three zones the gate is meant to '
              'require; dropping the quartz unpays the Kinetic banking '
              'promise',
        );
      });

      test('⚠️ each essence is boss-only: a drop, never a node (§3.4)', () {
        final nodes = _allNodeIds();
        final drops = _allDropIds();
        for (final e in ['solar_essence', 'lunar_essence', 'astral_essence']) {
          expect(
            drops,
            contains(e),
            reason:
                '$e is guaranteed on its zone\'s boss `always` line — no '
                'drop means the gate cannot be assembled at all',
          );
          expect(
            nodes,
            isNot(contains(e)),
            reason:
                '⚠️ $e must stay kill-only. A gather node would let a player '
                'walk past the boss the essence exists to make them fight',
          );
        }
      });

      test('⭐ the first Enchanting craft in the game\'s history: consumes, '
          'mints, banks', () async {
        final game = _carrying({
          'solar_essence': 1,
          'lunar_essence': 1,
          'astral_essence': 1,
          'hum_quartz': 3,
          'fallstone': 2,
        });
        final out = await game.craft(
          CelestialRecipes.celestialTotem,
          rng: Random(7),
        );

        expect(
          out.succeeded,
          isTrue,
          reason:
              '⚠️ a brand-new profile has zero Enchanting XP and is '
              'therefore level 1, and the Totem gates at exactly 1 — this '
              'is the distinguishing case for "gate 1 is a floor, not a '
              'wall"',
        );
        for (final id in [
          'solar_essence',
          'lunar_essence',
          'astral_essence',
          'hum_quartz',
          'fallstone',
        ]) {
          expect(
            game.profile.backpack.countOf(id),
            0,
            reason:
                '$id is spent by the craft — ⚠️ the GATE is shown not spent, '
                'but the RECIPE is an ordinary craft and eats its inputs',
          );
        }
        expect(
          game.profile.backpack.countOf('celestial_totem'),
          1,
          reason: 'the mint must actually happen or Rimeholt never opens',
        );
        expect(
          game.profile.skillXp['enchanting'],
          48,
          reason:
              'Skills.xpForRecipe(celestialTotem) = 8 × 6 = 48 — the first '
              'Enchanting XP anyone has ever earned',
        );
        expect(
          out.quality,
          isNull,
          reason:
              'a KeyDef is fungible, so no quality is rolled — an Ornate '
              'gate key would be meaningless state',
        );
      });

      test(
        'refuses when an essence is missing, and names the shortfall',
        () async {
          // Distinguishing regression: a missing essence must REFUSE, not
          // silently craft a Totem that then fails the gate check.
          final game = _carrying({
            'solar_essence': 1,
            'lunar_essence': 1,
            'hum_quartz': 3,
            'fallstone': 2,
          });
          final out = await game.craft(CelestialRecipes.celestialTotem);
          expect(
            out.succeeded,
            isFalse,
            reason:
                'one Astral Essence short — Starfall Basin\'s boss unbeaten',
          );
          expect(
            out.refusal,
            contains('1 more'),
            reason:
                'the refusal must count the shortfall, or the player cannot '
                'tell which zone they still owe',
          );
          expect(
            game.profile.backpack.countOf('solar_essence'),
            1,
            reason:
                '⚠️ a refusal must not eat materials — eating a boss-only '
                'essence on a failed craft is unrecoverable',
          );
        },
      );

      test('the Totem survives a JSON reload', () async {
        final storage = _JsonMem();
        final profile = PlayerProfile.newPlayer()
          ..backpack = Backpack.of(const [
            InventorySlot(defId: 'solar_essence'),
            InventorySlot(defId: 'lunar_essence'),
            InventorySlot(defId: 'astral_essence'),
            InventorySlot(defId: 'hum_quartz'),
            InventorySlot(defId: 'hum_quartz'),
            InventorySlot(defId: 'hum_quartz'),
            InventorySlot(defId: 'fallstone'),
            InventorySlot(defId: 'fallstone'),
          ]);
        final game = GameState(storage, profile);
        await game.craft(CelestialRecipes.celestialTotem);

        final back = GameState(storage, (await storage.load())!);
        expect(
          back.profile.backpack.countOf('celestial_totem'),
          1,
          reason:
              'a gate key that does not survive the save is a gate that '
              'closes again on relaunch',
        );
        expect(
          back.profile.skillXp['enchanting'],
          48,
          reason: 'XP that does not survive the save never existed',
        );
      });
    },
  );

  group('⭐ a full in-band craft, end to end', () {
    test('wrackcotton_robe: six bolts in, one rolled instance out', () async {
      final game = _carrying(
        {'wrackcotton': 6},
        // Tailoring 40 exactly — at the gate, not above it.
        skillXp: {'tailoring': _xpToReach(40)},
      );
      expect(
        game.profile.skillLevel('tailoring'),
        40,
        reason:
            'the fixture must sit exactly at the gate, or this stops '
            'testing the gate',
      );

      final out = await game.craft(
        CelestialRecipes.wrackcottonRobe,
        rng: Random(3),
      );
      expect(out.succeeded, isTrue, reason: 'at gate, with every input');
      expect(
        game.profile.backpack.countOf('wrackcotton'),
        0,
        reason: 'all six bolts eaten',
      );
      expect(
        game.profile.backpack.countOf('wrackcotton_robe'),
        1,
        reason: 'the mint must happen',
      );
      expect(
        out.quality,
        isNotNull,
        reason:
            '⭐ every equipment recipe rolls a quality (§9b.4); a null here '
            'means the robe minted as a fungible and lost its instance',
      );
      final slot = game.profile.backpack.slots.firstWhere(
        (s) => s?.defId == 'wrackcotton_robe',
      );
      expect(
        slot!.instanceId,
        isNotNull,
        reason:
            'a non-fungible carries a per-instance roll and therefore '
            'needs its own UUID',
      );
    });

    test('⚠️ one level under the gate is refused', () async {
      final game = _carrying(
        {'wrackcotton': 6},
        skillXp: {'tailoring': _xpToReach(39)},
      );
      final out = await game.craft(CelestialRecipes.wrackcottonRobe);
      expect(
        out.succeeded,
        isFalse,
        reason:
            'gate 40 must exclude level 39 — an off-by-one in the gate '
            'check passes every other test in this file',
      );
      expect(
        game.profile.backpack.countOf('wrackcotton'),
        6,
        reason: 'a refusal must not eat materials',
      );
    });
  });
}
