/// The enchanting build's recipes (ENCHANTING_DESIGN §3, §5, §6, §8.2):
/// Refine ×48, Transmute ×36, Cut ×36, the Jewelry ladder ×12, the six
/// Salvage markers, the pure input matcher and [SalvageTable].
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills, per `testing-conventions.md`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/catalogue/gems.dart';
import 'package:masters_of_magic_2/game/items/enchants.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/recipes/enchanting_recipes.dart';
import 'package:masters_of_magic_2/game/items/recipes/jewelry_recipes.dart';
import 'package:masters_of_magic_2/game/items/recipes/salvage_table.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Typed out, not read off the enum — the ids are save-forever strings, so
/// the pin must not move when the enum does.
const _elements = [
  'aqua',
  'pyro',
  'flora',
  'electro',
  'aero',
  'geo',
  'solar',
  'lunar',
  'astral',
  'sanctus',
  'umbra',
  'arcane',
];

List<String> _sorted(Iterable<String> ids) => ids.toList()..sort();

String _moteId(MagicElement e, MoteTier t) => EnchantingRecipes.moteOf(e, t).id;

void main() {
  group('counts and registration', () {
    test('48 refine / 36 transmute / 36 cut / 12 ladder / 6 salvage', () {
      expect(
        [
          EnchantingRecipes.refine.length,
          EnchantingRecipes.transmute.length,
          JewelryRecipes.cut.length,
          JewelryRecipes.ladder.length,
          EnchantingRecipes.salvage.length,
        ],
        [48, 36, 36, 12, 6],
        reason:
            '12 elements × 4 rungs, 12 targets × 3 tiers, 12 elements × 3 gem '
            'tiers, 6 rungs × ring+pendant, one marker per Rarity — a loop '
            'bound or a missing element/tier is the mutant',
      );
    });

    test('⭐ everything but the salvage markers is in RecipeBook.all', () {
      final book = RecipeBook.all.map((r) => r.id).toSet();
      for (final r in [...EnchantingRecipes.all, ...JewelryRecipes.all]) {
        expect(
          book,
          contains(r.id),
          reason:
              '${r.id} is defined but unregistered — the Workbench never '
              'lists it and no audit ever sees it',
        );
      }
      for (final r in EnchantingRecipes.salvage) {
        expect(
          book,
          isNot(contains(r.id)),
          reason:
              '${r.id} is a marker whose input is an instance and whose '
              'output is input-dependent; in the book, every literal reader '
              '(conservation, probe, export, Workbench) would misread it',
        );
      }
    });

    test('recipe ids are unique across the whole book', () {
      final ids = RecipeBook.all.map((r) => r.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason:
            'a duplicate id makes RecipeBook.tryById return whichever was '
            'registered first — the other recipe silently vanishes',
      );
    });
  });

  group('⭐ ids are pinned (save-forever strings)', () {
    test('refine: refine_<element>_<tier made>', () {
      expect(
        _sorted(EnchantingRecipes.refine.map((r) => r.id)),
        _sorted([
          for (final e in _elements)
            for (final t in ['shard', 'crystal', 'core', 'heart'])
              'refine_${e}_$t',
        ]),
        reason:
            'a rename here orphans every wiki link and any saved Workbench '
            'state that names the recipe — the scheme is the contract',
      );
    });

    test('transmute: transmute_<target element>_<tier>', () {
      expect(
        _sorted(EnchantingRecipes.transmute.map((r) => r.id)),
        _sorted([
          for (final e in _elements)
            for (final t in ['dust', 'shard', 'crystal']) 'transmute_${e}_$t',
        ]),
        reason:
            'named for the TARGET — a scheme named for the source would need '
            '12 × 11 recipes, not 36',
      );
    });

    test('cut: cut_<element>_<gem tier>', () {
      expect(
        _sorted(JewelryRecipes.cut.map((r) => r.id)),
        _sorted([
          for (final e in _elements)
            for (final t in ['lesser', 'standard', 'greater']) 'cut_${e}_$t',
        ]),
        reason: 'the gem tier word is EnchantTier.name, one vocabulary',
      );
    });

    test('ladder and salvage, verbatim', () {
      expect(
        JewelryRecipes.ladder.map((r) => r.id).toList(),
        [
          'craft_amber_band',
          'craft_amber_drop',
          'craft_amber_ring',
          'craft_amber_pendant',
          'craft_jasper_ring',
          'craft_jasper_pendant',
          'craft_obsidian_ring',
          'craft_obsidian_pendant',
          'craft_opal_ring',
          'craft_opal_pendant',
          'craft_sidereal_ring',
          'craft_sidereal_pendant',
        ],
        reason:
            'rung order, ring before pendant — amber_ring, jasper_pendant and '
            'obsidian_ring are the ids KINETIC §8.1 cut, returned unchanged',
      );
      expect(
        EnchantingRecipes.salvage.map((r) => r.id).toList(),
        [
          'salvage_common',
          'salvage_uncommon',
          'salvage_rare',
          'salvage_epic',
          'salvage_mythic',
          'salvage_legendary',
        ],
        reason: 'one marker per Rarity, enum order — the crafter keys on these',
      );
    });
  });

  group('every id resolves', () {
    test('every input and output of every registered recipe resolves', () {
      for (final r in [...EnchantingRecipes.all, ...JewelryRecipes.all]) {
        expect(
          ItemCatalogue.tryById(r.outputId),
          isNotNull,
          reason: '${r.id} mints ${r.outputId}, which no catalogue owns',
        );
        for (final i in r.inputs) {
          expect(
            ItemCatalogue.tryById(i.defId),
            isNotNull,
            reason: '${r.id} eats ${i.defId}, which no catalogue owns',
          );
          expect(
            ItemCatalogue.byId(i.defId).isFungible,
            isTrue,
            reason:
                '${r.id} eats a non-fungible by id — only the salvage '
                'markers may eat an instance, and they are not registered',
          );
        }
      }
    });

    test('⚠️ the salvage markers\' sentinels resolve to NOTHING', () {
      for (final r in EnchantingRecipes.salvage) {
        expect(
          (
            ItemCatalogue.tryById(r.outputId),
            ItemCatalogue.tryById(r.inputs.single.defId),
          ),
          (null, null),
          reason:
              '${r.id}: a sentinel that resolved would let an unwired reader '
              'consume or mint a real item instead of failing loudly',
        );
      }
    });

    test('every gem has exactly one cut, and every cut makes its gem', () {
      expect(
        _sorted(JewelryRecipes.cut.map((r) => r.outputId)),
        _sorted(Gems.all.map((g) => g.id)),
        reason:
            'a gem with no cut can never exist; two cuts for one gem means '
            'an element or tier was produced twice by the loop',
      );
    });
  });

  group('Refine — the §6.0 ladder, exactly', () {
    test('50 / 20 / 12 / 4 of the tier below, at 1 / 10 / 25 / 40', () {
      const expected = {
        MoteTier.shard: (MoteTier.dust, 50, 1),
        MoteTier.crystal: (MoteTier.shard, 20, 10),
        MoteTier.core: (MoteTier.crystal, 12, 25),
        MoteTier.heart: (MoteTier.core, 4, 40),
      };
      for (final e in MagicElement.values) {
        for (final entry in expected.entries) {
          final (from, ratio, level) = entry.value;
          final r = RecipeBook.tryById(
            EnchantingRecipes.refineId(e, entry.key),
          )!;
          expect(
            (
              r.outputId,
              r.outputCount,
              r.inputs.single.defId,
              r.inputs.single.count,
              r.skillLevel,
            ),
            (_moteId(e, entry.key), 1, _moteId(e, from), ratio, level),
            reason:
                '${r.id}: the mutants are a ratio typo (50 → 5), a crossed '
                'element (pyro dust → aqua shard), a skipped tier (dust → '
                'crystal) or a shuffled gate',
          );
        }
      }
    });

    test('Enchanting, field-craftable, exact inputs', () {
      for (final r in EnchantingRecipes.refine) {
        expect(
          (r.skill, r.stationRequired, r.inputs.single.isExact),
          (CraftSkill.enchanting, false, true),
          reason:
              '${r.id}: refining is the ingot of the mote economy (§2) — a '
              'station gate or a flagged input would strand it',
        );
      }
    });

    test('XP follows §9b.9 — refining alone climbs the skill (§3.3)', () {
      final shard = RecipeBook.tryById('refine_pyro_shard')!;
      final heart = RecipeBook.tryById('refine_pyro_heart')!;
      expect(
        (Skills.xpForRecipe(shard), Skills.xpForRecipe(heart)),
        (50 * 6, 4 * 84),
        reason:
            'inputs × (4 + 2 × gate): a flat-XP refine would make the '
            'skill unclimbable by refining, which §3.3 promises',
      );
    });
  });

  group('Transmute — the ruled curve', () {
    test('⭐ the pinned table: L1 4 · L15 3 · L30 3 · L45 2', () {
      expect(
        [
          for (final l in [1, 14, 15, 29, 30, 44, 45, 60])
            Skills.transmuteInputsAt(l),
        ],
        [4, 4, 3, 3, 3, 3, 2, 2],
        reason:
            'ruling 4: 4:1 → 3:1 → 5:2 → 2:1 at 1/15/30/45, rounded UP so '
            'the 5:2 rung is never better than the curve. Mutants: an '
            'off-by-one rung boundary, rounding down (L30 → 2), a 1:1 top',
      );
      expect(
        [
          for (final l in [1, 15, 30, 45]) Skills.transmuteRatioAt(l),
        ],
        [4.0, 3.0, 2.5, 2.0],
        reason: 'the ratio itself is the design\'s, unrounded',
      );
    });

    test('one per (target, tier), gate 1, anyElement, worst-case count', () {
      for (final target in MagicElement.values) {
        for (final tier in EnchantingRecipes.transmuteTiers) {
          final r = RecipeBook.tryById(
            EnchantingRecipes.transmuteId(target, tier),
          )!;
          final input = r.inputs.single;
          final exemplar = ItemCatalogue.byId(input.defId) as MoteDef;
          expect(
            (
              r.outputId,
              r.skillLevel,
              r.stationRequired,
              input.anyElement,
              input.count,
              exemplar.tier,
            ),
            (_moteId(target, tier), 1, false, true, 4, tier),
            reason:
                '${r.id}: the count field must hold the L1 rung so a reader '
                'that ignores the flag sees the worst case, and the exemplar '
                'must be the SAME tier — a cross-tier exemplar is a refine '
                'in disguise',
          );
          expect(
            exemplar.element,
            isNot(target),
            reason:
                '${r.id}: an exemplar of the target element would make an '
                'unwired literal crafter do a 4:1 self-loss',
          );
        }
      }
    });

    test('never Core or Heart', () {
      expect(
        EnchantingRecipes.transmuteTiers,
        [MoteTier.dust, MoteTier.shard, MoteTier.crystal],
        reason:
            '§3.2 names three tiers; a Heart that changed element would be a '
            'second door around the Bound 48-Crystal climb',
      );
    });
  });

  group('⭐ the pure matcher — what GameState.craft must call', () {
    final toPyroDust = RecipeBook.tryById('transmute_pyro_dust')!;

    test('the target element never counts', () {
      expect(
        toPyroDust.drawFrom({'pyro_dust': 99}),
        isNull,
        reason:
            'pyro → pyro is a pure loss no player means; the mutant is a '
            'candidate list that forgot to exclude the output element',
      );
    });

    test('any other element counts, and elements mix in one craft', () {
      expect(
        toPyroDust.drawFrom({'aqua_dust': 2, 'flora_dust': 2}),
        {'aqua_dust': 2, 'flora_dust': 2},
        reason:
            'mixing is allowed — a matcher that demanded one source element '
            'would refuse a pack that plainly holds four non-pyro Dust',
      );
    });

    test('draws the largest stack first, ties in enum order', () {
      expect(
        toPyroDust.drawFrom({
          'aqua_dust': 3,
          'flora_dust': 3,
          'arcane_dust': 10,
        }),
        {'arcane_dust': 4},
        reason:
            'spend the surplus first — enum order alone would eat the aqua '
            'and flora the player may be saving',
      );
      expect(
        toPyroDust.drawFrom({'flora_dust': 3, 'aqua_dust': 3}),
        {'aqua_dust': 3, 'flora_dust': 1},
        reason:
            'a tie breaks in MagicElement order, so the same pack always '
            'draws the same way — the mutant is map-iteration order',
      );
    });

    test('the count follows the curve at the crafter\'s level', () {
      final pack = {'aqua_dust': 3};
      // ⚠️ A list, not a record: records compare maps by identity.
      expect(
        [
          toPyroDust.drawFrom(pack, skillLevel: 1),
          toPyroDust.drawFrom(pack, skillLevel: 15),
          toPyroDust.drawFrom({'aqua_dust': 2}, skillLevel: 45),
        ],
        [
          null,
          {'aqua_dust': 3},
          {'aqua_dust': 2},
        ],
        reason:
            'L1 wants 4, L15 wants 3, L45 wants 2 — a matcher that read '
            'RecipeInput.count would charge a master the novice\'s price',
      );
    });

    test('only the same tier counts', () {
      expect(
        toPyroDust.drawFrom({'aqua_shard': 50, 'aqua_crystal': 5}),
        isNull,
        reason:
            'a Shard is not a Dust — the mutant ignores the exemplar tier '
            'and lets higher motes leak down',
      );
    });

    test('exact lines are exact, and short is null', () {
      final shard = RecipeBook.tryById('refine_geo_shard')!;
      expect(
        [
          shard.drawFrom({'geo_dust': 50, 'aqua_dust': 50}),
          shard.drawFrom({'geo_dust': 49, 'aqua_dust': 50}),
        ],
        [
          {'geo_dust': 50},
          null,
        ],
        reason:
            'an exact line takes only its id — 49 Geo Dust plus any amount '
            'of another element is still short',
      );
      expect(
        shard.satisfiedBy({'geo_dust': 50}),
        isTrue,
        reason: 'satisfiedBy is drawFrom != null for a stacks-only recipe',
      );
    });

    test('the salvage line wants a piece of EXACTLY its rarity', () {
      final rare = EnchantingRecipes.salvage.firstWhere(
        (r) => r.inputs.single.anyEquipmentOfRarity == Rarity.rare,
      );
      final cinderLoop = ItemCatalogue.byId('cinder_loop') as EquipmentDef;
      final theGivenWeight =
          ItemCatalogue.byId('the_given_weight') as EquipmentDef;
      expect(
        (
          rare.satisfiedBy(const {}, piece: cinderLoop),
          rare.satisfiedBy(const {}, piece: theGivenWeight),
          rare.satisfiedBy(const {}),
        ),
        (true, false, false),
        reason:
            'rare accepts the rare Cinder Loop, refuses the epic Given '
            'Weight (an "at least" matcher would pay it the rare yield) and '
            'refuses no piece at all',
      );
      expect(
        [rare.inputs.single.isExact, rare.drawFrom(const {})],
        [false, <String, int>{}],
        reason:
            'an equipment line draws no stack — a matcher that looked its '
            'sentinel id up in the counts would always be short',
      );
    });

    test('salvage pays 6 XP — Enchanting as a 1-input recipe (§6)', () {
      for (final r in EnchantingRecipes.salvage) {
        expect(
          (r.skillLevel, Skills.xpForRecipe(r)),
          (1, 6),
          reason: '${r.id}: 1 × (4 + 2 × 1); a gate above 1 strands salvage',
        );
      }
    });
  });

  group('Salvage — §6\'s table', () {
    List<(String, int)> yieldOf(
      String id, {
      List<String> socketed = const [],
    }) => [
      for (final s in SalvageTable.yieldOf(
        ItemCatalogue.byId(id) as EquipmentDef,
        socketed: socketed,
      ))
        (s.defId, s.count),
    ];

    test('per rarity, in the zone\'s lead element', () {
      expect(
        [
          yieldOf('oak_wand'),
          yieldOf('cinder_loop'),
          yieldOf('the_given_weight'),
        ],
        [
          [('flora_dust', 3)],
          [('pyro_shard', 1), ('pyro_dust', 10)],
          [('geo_crystal', 1)],
        ],
        reason:
            'common 3 Dust · rare 1 Shard + 10 Dust · epic 1 Crystal, of the '
            'defining zone\'s element (Whispering Woods, Cinderpeak, Old '
            'Quarry). Mutants: a crossed rarity row, a fixed element, the '
            'wrong tier',
      );
    });

    test('📝 the uncommon row — no uncommon equipment ships yet', () {
      expect(
        [
          for (final d in ItemCatalogue.ofKind<EquipmentDef>())
            if (d.rarity == Rarity.uncommon) d.id,
        ],
        isEmpty,
        reason:
            'pinned so the first uncommon piece is noticed and given a '
            'catalogue-backed salvage check like the rows above',
      );
      expect(SalvageTable.byRarity[Rarity.uncommon], [
        (MoteTier.dust, 8),
      ], reason: '§6: uncommon → 8 Dust; the table row is all there is to pin');
    });

    test('a hybrid zone salvages to its FIRST element', () {
      expect(
        (
          SalvageTable.elementOf(
            ItemCatalogue.byId('rimebound_ring') as EquipmentDef,
          ),
          SalvageTable.elementOf(
            ItemCatalogue.byId('firstmelt_loop') as EquipmentDef,
          ),
        ),
        (MagicElement.aqua, MagicElement.pyro),
        reason:
            'Frostfell is Aqua + Aero and the Molten Deep Pyro + Geo — the '
            'lead is elements.first; a .last mutant flips both',
      );
    });

    test('📝 mythic and legendary share §6\'s row', () {
      expect(
        [
          SalvageTable.byRarity[Rarity.mythic],
          SalvageTable.byRarity[Rarity.legendary],
        ],
        [
          [(MoteTier.crystal, 1), (MoteTier.shard, 1)],
          [(MoteTier.crystal, 1), (MoteTier.shard, 1)],
        ],
        reason: '§6: "mythic / legendary — 1 Crystal + 1 Shard"',
      );
    });

    test('⭐ socketed gems come out whole; empty sockets do not', () {
      final gem = Gems.idFor(MagicElement.pyro, EnchantTier.lesser);
      expect(
        yieldOf('cinder_loop', socketed: [ItemInstance.emptySocket, gem]),
        [('pyro_shard', 1), ('pyro_dust', 10), (gem, 1)],
        reason:
            'salvaging a socketed piece must not eat its gems (§6), and an '
            'empty-socket placeholder must never come back as an item id',
      );
      final instance = ItemInstance(
        instanceId: 'i1',
        defId: 'cinder_loop',
        socketed: [gem],
      );
      expect(
        SalvageTable.yieldOfInstance(instance).map((s) => s.defId).toList(),
        ['pyro_shard', 'pyro_dust', gem],
        reason: 'the instance entry point reads the instance\'s own sockets',
      );
    });

    test('every shipped piece yields motes — none is zone-less today', () {
      final silent = [
        for (final d in ItemCatalogue.ofKind<EquipmentDef>())
          if (SalvageTable.salvageYield(d).isEmpty) d.id,
      ];
      expect(
        silent,
        isEmpty,
        reason:
            'every EquipmentDef lives in a zone file with elements; a '
            'piece that yields nothing is a salvage the player loses',
      );
    });

    test('⚠️ a zone-less def yields nothing, by rule', () {
      const stray = EquipmentDef(
        id: 'not_in_any_catalogue',
        rarity: Rarity.rare,
        lore: '',
        slot: EquipSlot.ring,
        form: 'Ring',
        material: 'Nothing',
      );
      expect(
        [SalvageTable.elementOf(stray), SalvageTable.salvageYield(stray)],
        [null, <InventorySlot>[]],
        reason:
            'World.byId falls back to the first location for an unknown id; '
            'a salvage that used it would hand a stray piece a guessed '
            'element instead of nothing',
      );
    });

    test('⚠️ §6\'s guard: motes back are worth less than the piece', () {
      final over = [
        for (final d in ItemCatalogue.ofKind<EquipmentDef>())
          if (SalvageTable.moteValueOf(d) >= d.value)
            '${d.id} (${SalvageTable.moteValueOf(d)} ≥ ${d.value})',
      ];
      expect(
        over,
        isEmpty,
        reason:
            'a salvage worth more than the vendor price makes the vendor '
            'pointless and salvage a mint (§6) — the mutant is a table row '
            'inflated (rare → 1 Crystal)',
      );
    });

    test('📝 the Eclipsed Citadel salvages to Aqua (flagged for a ruling)', () {
      final citadel = World.locations.firstWhere(
        (l) => l.id == 'the_eclipsed_citadel',
      );
      expect(
        citadel.elements.first,
        MagicElement.aqua,
        reason:
            'the Citadel lists all twelve in enum order, so "lead element" '
            'is Aqua — pinned so a reorder is noticed, not silent',
      );
    });
  });

  group('Cut — one stone per element', () {
    test('⭐ the stone table, verbatim', () {
      expect(
        {for (final e in JewelryRecipes.stoneFor.entries) e.key.name: e.value},
        {
          'aqua': 'nacre',
          'pyro': 'obsidian',
          'flora': 'amber',
          'electro': 'hum_quartz',
          'aero': 'everice',
          'geo': 'quarry_jasper',
          'solar': 'aetherglass',
          'lunar': 'eclipse_opal',
          'astral': 'sidereal_glass',
          'sanctus': 'reliquary_gold',
          'umbra': 'thoughtglass',
          'arcane': 'colophon_stone',
        },
        reason: 'ENCHANTING §8.2\'s table; a swap is a design change',
      );
    });

    test('twelve distinct stones, each from a zone carrying its element', () {
      expect(
        JewelryRecipes.stoneFor.values.toSet().length,
        12,
        reason: 'a stone reused across elements makes two gems one farm',
      );
      for (final e in JewelryRecipes.stoneFor.entries) {
        final stone = ItemCatalogue.byId(e.value);
        final zone = World.locations.firstWhere(
          (l) => l.id == ItemCatalogue.zoneOf(e.value),
        );
        expect(
          (stone is MaterialDef, zone.elements.contains(e.key)),
          (true, true),
          reason:
              '${e.value} is the ${e.key.name} stone but comes from '
              '${zone.id} (${zone.elements.map((x) => x.name)}) — "matched '
              'by element" is the rule',
        );
      }
    });

    test('stone + one refined mote of the element, at 10 / 25 / 40', () {
      for (final e in MagicElement.values) {
        for (final tier in EnchantTier.values) {
          final r = RecipeBook.tryById(JewelryRecipes.cutId(e, tier))!;
          final (mote, level) = switch (tier) {
            EnchantTier.lesser => (MoteTier.crystal, 10),
            EnchantTier.standard => (MoteTier.core, 25),
            EnchantTier.greater => (MoteTier.heart, 40),
          };
          expect(
            [
              r.outputId,
              r.skill,
              r.skillLevel,
              r.stationRequired,
              [for (final i in r.inputs) (i.defId, i.count)],
            ],
            [
              Gems.idFor(e, tier),
              CraftSkill.jewelry,
              level,
              true,
              [(JewelryRecipes.stoneFor[e]!, 1), (_moteId(e, mote), 1)],
            ],
            reason:
                '${r.id}: §5.1 — Lesser/Crystal/10, Standard/Core/25, '
                'Greater/Heart/40, at Rimeholt. Mutants: a crossed mote tier, '
                'the wrong element\'s mote, a dropped station flag',
          );
        }
      }
    });
  });

  group('the Jewelry ladder below Rimeholt (§5.3)', () {
    test('⭐ levels 1 / 5 / 12 / 18 / 24 / 30, ring then pendant', () {
      expect(
        [
          for (final r in JewelryRecipes.ladder)
            (
              r.skillLevel,
              (ItemCatalogue.byId(r.outputId) as EquipmentDef).slot,
            ),
        ],
        [
          for (final l in [1, 5, 12, 18, 24, 30]) ...[
            (l, EquipSlot.ring),
            (l, EquipSlot.neck),
          ],
        ],
        reason:
            'the ladder climbs in six rungs a ring and a pendant apiece — a '
            'gate out of order makes a later rung unlock first',
      );
    });

    test('every output is a common crafted piece in ItemCatalogue', () {
      for (final r in JewelryRecipes.ladder) {
        final def = ItemCatalogue.tryById(r.outputId);
        expect(
          def,
          isA<EquipmentDef>(),
          reason: '${r.id} makes ${r.outputId}, which is not equipment',
        );
        final piece = def! as EquipmentDef;
        expect(
          (piece.rarity, piece.properName, r.skill, r.stationRequired),
          (Rarity.common, null, CraftSkill.jewelry, false),
          reason:
              '${r.id}: crafted commons take their composed name (§9b.5a) '
              'and stations are convenience, not gates (§9b.2)',
        );
      }
    });

    test('⭐ bronze → iron → skyiron, one stone of the quarter each', () {
      expect(
        [
          for (final r in JewelryRecipes.ladder)
            [for (final i in r.inputs) i.defId],
        ],
        [
          ['bronze_ingot', 'amber'],
          ['bronze_ingot', 'amber'],
          ['bronze_ingot', 'amber'],
          ['bronze_ingot', 'amber'],
          ['iron_ingot', 'quarry_jasper'],
          ['iron_ingot', 'quarry_jasper'],
          ['iron_ingot', 'obsidian'],
          ['iron_ingot', 'obsidian'],
          ['skysteel_ingot', 'eclipse_opal'],
          ['skysteel_ingot', 'eclipse_opal'],
          ['skysteel_ingot', 'sidereal_glass'],
          ['skysteel_ingot', 'sidereal_glass'],
        ],
        reason:
            '§5.3\'s metals verbatim. ⚠️ Never copper_ore — Cinderpeak copper '
            'is banked for exactly one maker (ITEMS §9b.8)',
      );
    });

    test('filed under the zone of its stone, equipping inside its band', () {
      const homes = {
        'amber': 'thornmire',
        'quarry_jasper': 'old_quarry',
        'obsidian': 'the_molten_deep',
        'eclipse_opal': 'the_sunless_reach',
        'sidereal_glass': 'the_shattered_orrery',
      };
      for (final r in JewelryRecipes.ladder) {
        final home = homes[r.inputs.last.defId]!;
        final zone = World.locations.firstWhere((l) => l.id == home);
        final piece = ItemCatalogue.byId(r.outputId) as EquipmentDef;
        expect(
          (
            ItemCatalogue.zoneOf(r.outputId),
            zone.minLevel <= piece.equipLevel,
            piece.equipLevel <= zone.maxLevel,
          ),
          (home, true, true),
          reason:
              '${r.outputId}: defined by its stone\'s zone file and wearable '
              'inside that zone\'s band (${zone.minLevel}–${zone.maxLevel})',
        );
      }
    });

    test('⚠️ no ladder piece carries deflection', () {
      for (final r in JewelryRecipes.ladder) {
        final m = (ItemCatalogue.byId(r.outputId) as EquipmentDef).modifiers;
        expect(
          (m.deflectChance, m.deflectAmount),
          (0, 0),
          reason:
              '${r.outputId}: CELESTIAL §2.1b fences deflection to crafted '
              'gloves + one drop per quarter (Σ amount ≤ 50) — the Geo '
              'pendant takes accuracy instead',
        );
      }
    });
  });
}
