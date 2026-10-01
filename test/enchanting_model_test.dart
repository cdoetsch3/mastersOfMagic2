/// The enchanting build, lane 1 — the model and the engine seam
/// (ENCHANTING_DESIGN §8.1, ruled 2026-10-01).
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills. The engine half of gear procs lives in
/// `packages/mom_engine/test/gear_proc_test.dart`; this file owns the tables,
/// the overlay arithmetic, the instance mutations and their save shape, the
/// stat lines, the wire, and the aspected-drop roll.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_export.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/drop_table.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/items/catalogue/gems.dart';
import 'package:masters_of_magic_2/game/items/catalogue/refined_motes.dart';
import 'package:masters_of_magic_2/game/items/enchants.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **The ids are forever once a save holds one** — so they are pinned as
/// literals, never rebuilt from the generator they would be checking.
const _moteIds = [
  'aero_core', 'aero_heart', 'aqua_core', 'aqua_heart', 'arcane_core', //
  'arcane_heart', 'astral_core', 'astral_heart', 'electro_core',
  'electro_heart', 'flora_core', 'flora_heart', 'geo_core', 'geo_heart',
  'lunar_core', 'lunar_heart', 'pyro_core', 'pyro_heart', 'sanctus_core',
  'sanctus_heart', 'solar_core', 'solar_heart', 'umbra_core', 'umbra_heart',
];
const _enchantIds = [
  'aero_greater', 'aero_lesser', 'aero_standard', 'aqua_greater', //
  'aqua_lesser', 'aqua_standard', 'arcane_greater', 'arcane_lesser',
  'arcane_standard', 'astral_greater', 'astral_lesser', 'astral_standard',
  'electro_greater', 'electro_lesser', 'electro_standard', 'flora_greater',
  'flora_lesser', 'flora_standard', 'geo_greater', 'geo_lesser',
  'geo_standard', 'lunar_greater', 'lunar_lesser', 'lunar_standard',
  'pyro_greater', 'pyro_lesser', 'pyro_standard', 'sanctus_greater',
  'sanctus_lesser', 'sanctus_standard', 'solar_greater', 'solar_lesser',
  'solar_standard', 'umbra_greater', 'umbra_lesser', 'umbra_standard',
];
const _gemIds = [
  'gem_aero_greater', 'gem_aero_lesser', 'gem_aero_standard', //
  'gem_aqua_greater', 'gem_aqua_lesser', 'gem_aqua_standard',
  'gem_arcane_greater', 'gem_arcane_lesser', 'gem_arcane_standard',
  'gem_astral_greater', 'gem_astral_lesser', 'gem_astral_standard',
  'gem_electro_greater', 'gem_electro_lesser', 'gem_electro_standard',
  'gem_flora_greater', 'gem_flora_lesser', 'gem_flora_standard',
  'gem_geo_greater', 'gem_geo_lesser', 'gem_geo_standard',
  'gem_lunar_greater', 'gem_lunar_lesser', 'gem_lunar_standard',
  'gem_pyro_greater', 'gem_pyro_lesser', 'gem_pyro_standard',
  'gem_sanctus_greater', 'gem_sanctus_lesser', 'gem_sanctus_standard',
  'gem_solar_greater', 'gem_solar_lesser', 'gem_solar_standard',
  'gem_umbra_greater', 'gem_umbra_lesser', 'gem_umbra_standard',
];

/// ENCHANTING_DESIGN §4.1's table, written out as the doc writes it — the
/// wire form of each tier's modifiers, Lesser / Standard / Greater.
const _section41 = <MagicElement, List<Map<String, int>>>{
  // ✅ The §8.4 retune (2026-10-01): dodge 1/1/2, crit chance 1/2/3, every
  // other Greater row two thirds of the draft, Sanctus 2/4/5.
  MagicElement.pyro: [
    {'critDamage': 4},
    {'critDamage': 8},
    {'critDamage': 9},
  ],
  MagicElement.umbra: [
    {'critDamage': 4},
    {'critDamage': 8},
    {'critDamage': 9},
  ],
  MagicElement.electro: [
    {'critChance': 1},
    {'critChance': 2},
    {'critChance': 3},
  ],
  MagicElement.astral: [
    {'critChance': 1},
    {'critChance': 2},
    {'critChance': 3},
  ],
  MagicElement.aero: [
    {'dodge': 1},
    {'dodge': 1},
    {'dodge': 2},
  ],
  MagicElement.lunar: [
    {'dodge': 1},
    {'dodge': 1},
    {'dodge': 2},
  ],
  MagicElement.geo: [
    {'deflectChance': 3},
    {'deflectChance': 6},
    {'deflectChance': 7},
  ],
  MagicElement.arcane: [
    {'deflectChance': 3},
    {'deflectChance': 6},
    {'deflectChance': 7},
  ],
  MagicElement.solar: [
    {'accuracyBonus': 3},
    {'accuracyBonus': 6},
    {'accuracyBonus': 7},
  ],
  MagicElement.aqua: [
    {'shieldStrengthPercent': 4},
    {'shieldStrengthPercent': 8},
    {'shieldStrengthPercent': 9},
  ],
  MagicElement.flora: [
    {'healingReceivedPercent': 4},
    {'healingReceivedPercent': 8},
    {'healingReceivedPercent': 9},
  ],
  MagicElement.sanctus: [
    {'shieldStrengthPercent': 2, 'healingReceivedPercent': 2},
    {'shieldStrengthPercent': 4, 'healingReceivedPercent': 4},
    {'shieldStrengthPercent': 5, 'healingReceivedPercent': 5},
  ],
};

/// A common, three-socket main hand with `critDamage: 18` — the Pyro
/// affinity stat, so every overlay below lands on a number the def already
/// has (Aetherwood Quarterstaff, The Collapsed Academy).
const _staffId = 'aetherwood_quarterstaff';
EquipmentDef get _staff => ItemCatalogue.byId(_staffId) as EquipmentDef;

ItemInstance _piece({
  String defId = _staffId,
  Quality? quality,
  MagicElement? aspect,
  String? enchantId,
  List<String> socketed = const [],
}) => ItemInstance(
  instanceId: 'i',
  defId: defId,
  quality: quality,
  aspect: aspect,
  enchantId: enchantId,
  socketed: socketed,
);

int _critDamageOf(ItemInstance i) =>
    Equipping.modifiersOf(ItemCatalogue.byId(i.defId), i).critDamage;

void main() {
  group('table laws', () {
    test(
      '24 refined motes, ids pinned, Core rare 900 · Heart epic Bound 0',
      () {
        expect(
          [for (final m in RefinedMotes.all) m.id]..sort(),
          _moteIds,
          reason: 'a renamed mote id is a save migration — the ids are forever',
        );
        for (final m in RefinedMotes.all) {
          final core = m.tier == MoteTier.core;
          expect(
            (m.rarity, m.value, m.tradability, m.stackSize),
            core
                ? (Rarity.rare, 900, Tradability.tradeable, 1)
                : (Rarity.epic, 0, Tradability.bound, 1),
            reason:
                '${m.id}: Core rare 900 (ECONOMY §14c), Heart epic with NO '
                'value and Bound (§14c) — and a slot each, like every tier '
                'above Shard (the mutant: a Core stacking like Dust)',
          );
          expect(
            m.properName,
            '${m.element!.displayName} ${core ? 'Core' : 'Heart'}',
            reason: 'motes are named `<Element> <Tier>` (ITEMS §6)',
          );
          expect(
            m.lore.length,
            greaterThan(20),
            reason: '${m.id} lore is thin',
          );
        }
        expect(
          {
            for (final e in MagicElement.values)
              e: [RefinedMotes.coreOf(e).id, RefinedMotes.heartOf(e).id],
          },
          {
            for (final e in MagicElement.values)
              e: ['${e.name}_core', '${e.name}_heart'],
          },
          reason: 'coreOf/heartOf must answer by element, never by position',
        );
      },
    );

    test('36 enchants, ids pinned, numbers exactly §4.1', () {
      expect(
        [for (final e in Enchants.all) e.id]..sort(),
        _enchantIds,
        reason: 'enchant ids are written into saves — forever',
      );
      for (final e in Enchants.all) {
        expect(
          e.modifiers.toJson(),
          _section41[e.element]![e.tier.index],
          reason:
              '${e.id}: §4.1 says this — the mutants this kills are an '
              'element on the wrong affinity stat (CELESTIAL §2.5a) or a tier '
              'reading the wrong column; Sanctus alone grants two stats',
        );
        expect(
          e.procElement,
          e.tier == EnchantTier.greater ? e.element : null,
          reason: '"both, by tier" — ONLY Greater carries the gear proc',
        );
        expect(
          e.grants.gearProcs,
          e.tier == EnchantTier.greater ? {e.element} : <MagicElement>{},
          reason: 'the proc must ride the grants, or it never leaves the table',
        );
        expect(Enchants.byId[e.id], same(e));
        expect(Enchants.of(e.element, e.tier), same(e));
      }
      expect(
        Enchants.of(MagicElement.pyro, EnchantTier.standard).label,
        'Charred (Standard)',
        reason: 'the §9b.5b prefix names the enchant',
      );
      expect(
        Enchants.tryById('unbind'),
        isNull,
        reason: 'unbinding is reserved (§4.5), not a stat enchant',
      );
    });

    test('36 gems, ids pinned, affinity +2 / +4 / +7', () {
      expect([for (final g in Gems.all) g.id]..sort(), _gemIds);
      for (final g in Gems.all) {
        final tier = EnchantTier.values.firstWhere(
          (t) => g.id.endsWith('_${t.name}'),
        );
        final n = Affinity.enchantAmount(g.element!, tier);
        expect(
          g.modifiers.toJson(),
          {for (final k in _section41[g.element]![0].keys) k: n},
          reason:
              '${g.id}: the element\'s affinity stat at +$n (§5.1) — never '
              'the enchant\'s column, never another element\'s stat',
        );
        expect(
          (g.rarity, g.value, g.tradability),
          (
            const [Rarity.uncommon, Rarity.rare, Rarity.epic][tier.index],
            const [300, 1500, 0][tier.index],
            const [
              Tradability.tradeable,
              Tradability.tradeable,
              Tradability.bound,
            ][tier.index],
          ),
          reason:
              '${g.id}: Lesser/Standard/Greater = uncommon/rare/epic — and a '
              'Greater gem is Bound at 0g like the Heart it is cut from '
              '(ECONOMY §14c); kills a vendorable Greater gem',
        );
        expect(
          g.properName,
          '${tier.label} ${g.element!.displayName} Gem',
          reason: 'the Socket: line prints this name',
        );
      }
    });

    test('the content export carries enchants and gems, additively', () {
      final export = ContentExport.build();
      final enchants = (export['enchants']! as List).cast<Map>();
      expect(
        (enchants.length, (export['counts']! as Map)['enchants']),
        (36, 36),
        reason: 'ENCHANTING §8.1: the wiki reads enchants off the table',
      );
      expect(enchants.firstWhere((e) => e['id'] == 'pyro_greater'), {
        'id': 'pyro_greater',
        'element': 'pyro',
        'tier': 'greater',
        'label': 'Charred (Greater)',
        'modifiers': {'critDamage': 9},
        'procElement': 'pyro',
        'procPercent': ElementTuning.gearProcPercent,
      });
      expect(
        enchants.firstWhere((e) => e['id'] == 'pyro_standard')['procElement'],
        isNull,
        reason: 'only Greater exports a proc',
      );
      expect(
        export['schemaVersion'],
        1,
        reason: 'additive keys never bump the schema',
      );
      final gems = [
        for (final i in (export['items']! as List).cast<Map>())
          if (i['kind'] == 'gem') i['id'],
      ];
      expect(gems..sort(), _gemIds, reason: 'gems export as items, kind gem');
    });

    test('made-not-found defs resolve, belong to no zone, and are filed', () {
      for (final id in [..._moteIds, ..._gemIds]) {
        expect(ItemCatalogue.tryById(id), isNotNull, reason: '$id resolves');
        expect(
          ItemCatalogue.zoneOf(id),
          isNull,
          reason: 'no zone yields $id — zoneOf is geography (shops, rank gear)',
        );
      }
      expect(ItemCatalogue.homeOf('pyro_core'), 'refined');
      expect(ItemCatalogue.homeOf('gem_pyro_lesser'), 'gems');
    });
  });

  group('the overlay (Equipping.modifiersOf)', () {
    test('⭐ an enchant is NOT scaled by quality — the def is', () {
      final master = _piece(
        quality: Quality.master,
        enchantId: 'pyro_standard',
      );
      expect(
        _critDamageOf(master),
        (18 * 1.4).round() + 8,
        reason:
            'Master scales the staff\'s 18 to 25; Charred (Standard) adds a '
            'flat 8 — the mutant this kills scales the sum (36)',
      );
    });

    test('⭐ repeats give half, floored; distinct gems give full', () {
      expect(
        _critDamageOf(
          _piece(
            socketed: [
              'gem_pyro_greater',
              'gem_pyro_greater',
              'gem_pyro_greater',
            ],
          ),
        ),
        18 + 9 + 4 + 4,
        reason:
            'first copy 9, later copies 9 >> 1 = 4 — the mutants this kills '
            'are full repeats (45) and rounding up (9 + 5 + 5)',
      );
      expect(
        _critDamageOf(
          _piece(
            socketed: [
              'gem_pyro_lesser',
              'gem_pyro_standard',
              'gem_pyro_greater',
            ],
          ),
        ),
        18 + 4 + 8 + 9,
        reason: 'the rule is per GEM ID — three tiers are three firsts',
      );
      expect(
        _critDamageOf(
          _piece(quality: Quality.rough, socketed: ['gem_pyro_greater']),
        ),
        (18 * 0.8).round() + 9,
        reason: 'a gem is the jeweller\'s work — quality never scales it',
      );
    });

    test('an aspected drop with no enchant grants its Lesser affinity', () {
      expect(
        _critDamageOf(_piece(aspect: MagicElement.pyro)),
        18 + 4,
        reason: '§4.4: "pre-enchanted sidegrade, weaker" — Charred (Lesser)',
      );
      expect(
        _critDamageOf(
          _piece(aspect: MagicElement.pyro, enchantId: 'pyro_greater'),
        ),
        18 + 9,
        reason: 'an enchant REPLACES the aspect — never both (27 + 4)',
      );
      expect(
        _critDamageOf(_piece(aspect: MagicElement.pyro, enchantId: 'unbind')),
        18,
        reason:
            'an enchant this build cannot read grants nothing, and does not '
            'fall back to the aspect it replaced',
      );
    });

    test('bad sockets are harmless: empty, non-gem, and past socketCount', () {
      expect(
        _critDamageOf(
          _piece(
            socketed: [ItemInstance.emptySocket, 'oak_log', 'gem_pyro_lesser'],
          ),
        ),
        18 + 4,
        reason: 'only a GemDef in a real socket grants anything',
      );
      final noSockets = ItemCatalogue.ofKind<EquipmentDef>().firstWhere(
        (d) => d.socketCount == 0 && d.modifiers.critDamage == 0,
      );
      expect(
        Equipping.modifiersOf(
          noSockets,
          _piece(defId: noSockets.id, socketed: ['gem_pyro_greater']),
        ).critDamage,
        0,
        reason:
            'a gem written past socketCount (a bad write — the instance '
            'does not know its catalogue) must not grant a stat',
      );
    });

    test('⭐ procs dedupe across a wardrobe — one roll per element', () {
      ItemModifiers wear(List<String> enchants) => Equipping.totals(
        equipped: {
          for (var i = 0; i < enchants.length; i++) EquipSlot.values[i]: 'p$i',
        },
        instances: {
          for (var i = 0; i < enchants.length; i++)
            'p$i': _piece(enchantId: enchants[i]),
        },
      );
      expect(wear(['pyro_greater', 'pyro_greater']).gearProcs, {
        MagicElement.pyro,
      }, reason: '§4.1a: two Greater Pyro enchants are still ONE Ignite roll');
      expect(
        wear(['pyro_greater', 'electro_greater', 'pyro_standard']).gearProcs,
        {MagicElement.pyro, MagicElement.electro},
        reason: 'a Pyro and an Electro are two rolls; a Standard adds none',
      );
      expect(
        wear(['pyro_greater', 'pyro_greater']).critDamage,
        2 * (18 + 9),
        reason: 'the STATS still sum — only the proc dedupes',
      );
    });

    test('caps: the overlay sums honestly; CombatClamps clamps the output', () {
      // Thirteen Greater Geo enchants (7 each since the §8.4 retune): one
      // past the deflect activation cap of 90. ⚠️ No kit holds thirteen
      // pieces — this is the arithmetic, not a wardrobe.
      var deflect = ItemModifiers.none;
      for (var i = 0; i < 13; i++) {
        deflect =
            deflect +
            Equipping.enchantOverlay(_piece(enchantId: 'geo_greater'));
      }
      expect(
        (
          deflect.deflectChance,
          CombatClamps.deflectActivation(deflect.deflectChance),
        ),
        (91, 90),
        reason:
            'one past the cap: the overlay reports 91 (no clamp in '
            'modifiersOf — the mutant this kills clamps the components) and '
            'the resolution clamps it to 90',
      );
      // Three Greater Solar enchants (7 each) close the 20-point base miss.
      final acc =
          Equipping.enchantOverlay(_piece(enchantId: 'solar_greater')) +
          Equipping.enchantOverlay(_piece(enchantId: 'solar_greater')) +
          Equipping.enchantOverlay(_piece(enchantId: 'solar_greater'));
      int hit(int bonus) =>
          CombatClamps.hitChance(100 - ElementTuning.baseMissPercent + bonus);
      expect(hit(acc.accuracyBonus), CombatClamps.hitChanceCapPercent);
      expect(
        hit(acc.accuracyBonus + 1),
        CombatClamps.hitChanceCapPercent,
        reason: 'one past "cannot miss" is still cannot miss',
      );
    });
  });

  group('ItemModifiers.gearProcs crosses the wire', () {
    test('json is enum-ordered, round-trips, and drops unknown names', () {
      const m = ItemModifiers(
        critDamage: 3,
        gearProcs: {MagicElement.arcane, MagicElement.pyro},
      );
      expect(
        m.toJson(),
        {
          'critDamage': 3,
          'gearProcs': ['pyro', 'arcane'],
        },
        reason:
            'element-enum order, whatever the set\'s insertion order — the '
            'handshake JSON must be deterministic',
      );
      expect(
        ItemModifiers.fromJson(jsonDecode(jsonEncode(m.toJson()))).gearProcs,
        {MagicElement.pyro, MagicElement.arcane},
        reason:
            'a proc lost on the wire is a roll one client makes and the other '
            'does not — a desync',
      );
      expect(
        ItemModifiers.fromJson({
          'gearProcs': ['pyro', 'chronos'],
        }).gearProcs,
        {MagicElement.pyro},
        reason: 'a newer client\'s element is ignored, never thrown on',
      );
      expect(ItemModifiers.fromJson({}).gearProcs, isEmpty);
    });

    test(
      'procs union on +, survive quality and halving, count as non-empty',
      () {
        const a = ItemModifiers(gearProcs: {MagicElement.pyro});
        const b = ItemModifiers(
          gearProcs: {MagicElement.pyro, MagicElement.geo},
        );
        expect((a + b).gearProcs, {MagicElement.pyro, MagicElement.geo});
        expect(a.scaledBy(Quality.master).gearProcs, {
          MagicElement.pyro,
        }, reason: 'a Master staff does not lose (or multiply) its proc');
        expect(a.halved().gearProcs, {MagicElement.pyro});
        expect(
          a.isEmpty,
          isFalse,
          reason: 'a procs-only piece is not "no modifiers"',
        );
      },
    );

    test('⭐ _buildMage gives each mage its OWN gear\'s procs, as a copy', () {
      const mine = ItemModifiers(gearProcs: {MagicElement.pyro});
      final c = DuelController(
        loadout: Loadout.starter,
        driver: _Driver(const ItemModifiers(gearProcs: {MagicElement.electro})),
        playerGear: mine,
      );
      expect(c.player.gearProcs, {MagicElement.pyro});
      expect(
        c.enemy.gearProcs,
        {MagicElement.electro},
        reason:
            'the opponent\'s procs arrive in THEIR gear — both lockstep '
            'clients must build the same set for the same mage',
      );
      expect(
        identical(c.player.gearProcs, mine.gearProcs),
        isFalse,
        reason: 'the engine owns its mage — never alias the const set',
      );
      expect(
        DuelController(
          loadout: Loadout.starter,
          driver: _Driver(ItemModifiers.none),
        ).player.gearProcs,
        isEmpty,
        reason: 'no gear, no procs — and so no draws',
      );
    });
  });

  group('instance mutations and their save shape', () {
    test('withEnchant sets the enchant AND the aspect, replacing both', () {
      final dropped = _piece(
        aspect: MagicElement.aqua,
        quality: Quality.ornate,
      );
      final enchanted = dropped.withEnchant('pyro_standard');
      expect(
        (enchanted.enchantId, enchanted.aspect, enchanted.quality),
        ('pyro_standard', MagicElement.pyro, Quality.ornate),
        reason:
            'the enchant names the piece (Charred …) — an enchant that left '
            'the old aspect would print Tidewashed on a Pyro piece',
      );
      expect(
        enchanted.withEnchant('geo_lesser').aspect,
        MagicElement.geo,
        reason: 're-enchanting replaces (§4.3)',
      );
      expect(
        () => dropped.withEnchant('unbind'),
        throwsArgumentError,
        reason: 'an enchant with no element cannot set an aspect',
      );
    });

    test('sockets are positional: pad, replace, empty, trim', () {
      final a = _piece().withSocket(2, 'gem_pyro_lesser');
      expect(a.socketed, [
        '',
        '',
        'gem_pyro_lesser',
      ], reason: 'socket 2 stays socket 2 — earlier ones pad as empty');
      final b = a
          .withSocket(0, 'gem_geo_lesser')
          .withSocket(0, 'gem_aqua_lesser');
      expect(b.socketed, ['gem_aqua_lesser', '', 'gem_pyro_lesser']);
      expect(
        b.withoutSocket(0).socketed,
        ['', '', 'gem_pyro_lesser'],
        reason:
            'the gem beside it keeps its index — the mutant removeAt shifts it',
      );
      expect(b.withoutSocket(2).socketed, [
        'gem_aqua_lesser',
      ], reason: 'trailing empties trim, so an emptied piece saves as before');
      expect(b.withoutSocket(9).socketed, b.socketed);
      expect(
        _piece().withSocket(0, 'gem_pyro_lesser').withoutSocket(0).toJson(),
        _piece().toJson(),
        reason: 'all-empty writes no `socketed` key — every pre-socket save',
      );
    });

    test('json round-trips all three fields, through the save documents', () {
      final i = ItemInstance(
        instanceId: 'abc',
        defId: _staffId,
        quality: Quality.master,
      ).withEnchant('umbra_greater').withSocket(1, 'gem_umbra_standard');
      final back = ItemInstance.fromJson(jsonDecode(jsonEncode(i.toJson())));
      expect(
        (back.aspect, back.enchantId),
        (MagicElement.umbra, 'umbra_greater'),
        reason: 'fromJson must read both — a dropped key un-enchants a piece',
      );
      expect(back.socketed, [
        '',
        'gem_umbra_standard',
      ], reason: 'positional, the leading empty included');

      final profile = PlayerProfile.newPlayer()..itemInstances['abc'] = i;
      final character = ProfileDocuments.split(profile).character;
      expect(
        (character['itemInstances'] as Map)['abc'],
        i.toJson(),
        reason:
            '⭐ the update mask names `itemInstances` as ONE field, so its '
            'nested aspect / enchantId / socketed ride every write',
      );
      final reloaded = PlayerProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())),
      ).itemInstances['abc']!;
      expect(
        _critDamageOf(reloaded),
        _critDamageOf(i),
        reason: 'a reloaded piece grants exactly what it granted',
      );
    });
  });

  group('stat lines', () {
    test('⭐ describeInstance: def, enchant, then one line per socket', () {
      final i = _piece(
        enchantId: 'pyro_standard',
      ).withSocket(0, 'gem_pyro_lesser').withSocket(1, 'gem_pyro_lesser');
      expect(Equipping.describeInstance(_staff, i), [
        ...Equipping.describe(_staff.modifiers),
        'Enchant: Charred (Standard) · +8% crit damage',
        'Socket: Lesser Pyro Gem · +4% crit damage',
        'Socket: Lesser Pyro Gem · +2% crit damage (repeat, half)',
        'Socket: empty',
      ], reason: 'ENCHANTING §7\'s lines, numbers read through the overlay');
    });

    test('a Greater enchant prints its proc; a bare aspect says Aspect', () {
      expect(
        Equipping.describeInstance(
          _staff,
          _piece(enchantId: 'pyro_greater'),
        ).where((l) => l.startsWith('Enchant')),
        ['Enchant: Charred (Greater) · +9% crit damage, 10% on hit: Ignite'],
      );
      expect(
        Equipping.describeInstance(
          _staff,
          _piece(aspect: MagicElement.lunar),
        ).where((l) => !l.startsWith('Socket')).last,
        'Aspect: Moonlit · +1% dodge',
        reason:
            'a §4.4 drop has no enchant to name — its Lesser affinity still '
            'needs a line, or the dialog and the totals disagree',
      );
    });

    test('totals carry overlays and procs; describe(m) is unchanged', () {
      expect(
        Equipping.describe(
          const ItemModifiers(
            critDamage: 4,
            gearProcs: {MagicElement.solar, MagicElement.lunar},
          ),
        ),
        ['+4% crit damage', '10% on hit: Blind', '10% on hit: Blind'],
        reason: 'Solar and Lunar both Blind (§4.1a) — one line per roll',
      );
      final lines = Equipping.describeTotals(
        Equipping.modifiersOf(_staff, _piece(enchantId: 'aero_greater')),
        level: 50,
      );
      expect(lines, contains('Dodge 2% (+2)'));
      expect(lines, contains('Tailwind on hit 10%'));
    });
  });

  group('aspected drops (ENCHANTING §4.4)', () {
    final rare = ItemCatalogue.byId('wickerbound_ring'); // Thornmire's
    test('10% of rare+ drops, the zone\'s LEAD element', () {
      final rng = Random(41);
      final seen = <MagicElement?, int>{};
      for (var i = 0; i < 10000; i++) {
        final a = rollDropAspect(rare, 'thornmire', rng);
        seen[a] = (seen[a] ?? 0) + 1;
      }
      expect(
        seen.keys.toSet(),
        {null, MagicElement.flora},
        reason:
            'Thornmire is Flora + Aqua — the LEAD element only; the mutant '
            'this kills picks any of the zone\'s elements',
      );
      expect(
        seen[MagicElement.flora],
        inInclusiveRange(900, 1100),
        reason: 'aspectedDropPercent is 10 — 1,000 ± 100 of 10,000',
      );
      expect(aspectedDropPercent, 10);
    });

    test('⭐ twin streams: below rare, and non-equipment, draw nothing', () {
      for (final id in [_staffId, 'oak_log', 'pyro_core']) {
        final a = Random(5);
        final b = Random(5);
        expect(rollDropAspect(ItemCatalogue.byId(id), 'thornmire', a), isNull);
        expect(
          a.nextDouble(),
          b.nextDouble(),
          reason:
              '$id is not rare+ equipment — the mutant this kills draws the '
              'roll for every piece and shifts every seeded loot test',
        );
      }
    });

    test('a place with no element pays nothing', () {
      final always = _AlwaysZero();
      expect(
        rollDropAspect(rare, 'hearthwood', always),
        isNull,
        reason: 'a town has no lead element — the roll hits and pays nothing',
      );
      // 📝 Belt-and-braces today: World.byId falls back to the FIRST
      // location for an unknown id, and that is a town, so the exists()
      // guard is an equivalent mutant until the list's head changes.
      expect(rollDropAspect(rare, 'nowhere_at_all', always), isNull);
    });

    test('⭐ rollKill mints it LAST: same id and quality, one more draw', () {
      const table = DropTable(always: [DropEntry('wickerbound_ring')]);
      // ⚠️ Fifty seeds, not one: quality is Standard 90% of the time, so a
      // single seed rarely notices an aspect drawn BEFORE the quality.
      for (var seed = 0; seed < 50; seed++) {
        final plain = Random(seed);
        final zoned = Random(seed);
        final a = rollDrops(table, plain);
        final b = rollKill(
          table,
          rank: EnemyRank.common,
          zoneId: 'thornmire',
          rng: zoned,
        );
        final ia = a.instances.values.single;
        final ib = b.instances.values.single;
        expect(
          (ib.instanceId, ib.quality),
          (ia.instanceId, ia.quality),
          reason:
              'seed $seed: the aspect roll comes after the id and the '
              'quality — the mutant this kills draws it first and re-rolls '
              'every seeded drop\'s quality',
        );
        plain.nextInt(100); // the one aspect draw rollKill made
        expect(
          zoned.nextDouble(),
          plain.nextDouble(),
          reason: 'seed $seed: exactly one extra draw per rare+ piece',
        );
      }
    });

    test('a table of commons and materials rolls exactly as before', () {
      const table = DropTable(
        always: [DropEntry('oak_log', min: 2, max: 4)],
        main: [
          DropEntry('aetherwood_quarterstaff'),
          DropEntry.nothing(weight: 3),
        ],
      );
      for (var seed = 0; seed < 20; seed++) {
        final plain = Random(seed);
        final zoned = Random(seed);
        rollDrops(table, plain);
        rollKill(
          table,
          rank: EnemyRank.common,
          zoneId: 'thornmire',
          rng: zoned,
        );
        expect(
          zoned.nextDouble(),
          plain.nextDouble(),
          reason: 'seed $seed: no rare, no aspect draw',
        );
      }
    });

    test('boss kills: about one rank-gear piece in ten is aspected', () {
      final rng = Random(3);
      var aspected = 0;
      for (var i = 0; i < 2000; i++) {
        final loot = rollKill(
          DropTable.empty,
          rank: EnemyRank.boss,
          zoneId: 'thornmire',
          rng: rng,
        );
        final piece = loot.instances.values.single;
        if (piece.aspect != null) {
          expect(piece.aspect, MagicElement.flora);
          aspected++;
        }
      }
      expect(
        aspected,
        inInclusiveRange(160, 240),
        reason:
            'rank gear is rare+ by construction, so 10% of it — the '
            'mutant this kills forgets to thread the zone into rank gear',
      );
    });
  });
}

/// Every `nextInt` 0 — so a gate drawn with `nextInt(100) < n` always hits.
class _AlwaysZero implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

class _Driver implements OpponentDriver {
  _Driver(this.opponentGear);

  @override
  final ItemModifiers opponentGear;
  @override
  String get opponentName => 'Rival';
  @override
  int get opponentLevel => 1;
  @override
  int get opponentRating => 1200;
  @override
  MageApparel get opponentApparel => MageApparel.duskWitch;
  @override
  double get opponentHpScale => 1.0;
  @override
  double get opponentPowerScale => 1.0;
  @override
  EnemyCombatStats get opponentCombatStats => EnemyCombatStats.none;
  @override
  bool get playerIsHost => true;
  @override
  bool get supportsRematch => false;
  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async =>
      const TurnExchange(ForfeitAction());
  @override
  Future<void> reportSurrender() async {}
  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}
  @override
  Future<void> dispose() async {}
}
