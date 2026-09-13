import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/game/spell_browser.dart';

/// LADDER_DESIGN.md §5's table, hard-coded. This is the ground truth: a
/// mutant that nudges any level, archetype, gear tier or seed in
/// `ladder_bots.dart` away from the design doc is caught here, not by a
/// formula re-deriving the very numbers it is supposed to check.
const _table = [
  (
    id: 'wick',
    level: 1,
    archetype: 'drudge',
    gearTier: GearTier.bare,
    seedGeared: 1107,
    seedAcademy: 960,
  ),
  (
    id: 'pim',
    level: 3,
    archetype: 'skirmisher',
    gearTier: GearTier.bare,
    seedGeared: 1161,
    seedAcademy: 1080,
  ),
  (
    id: 'tansy',
    level: 5,
    archetype: 'lasher',
    gearTier: GearTier.worn,
    seedGeared: 1200,
    seedAcademy: 1080,
  ),
  (
    id: 'orrin',
    level: 7,
    archetype: 'sentinel',
    gearTier: GearTier.worn,
    seedGeared: 1239,
    seedAcademy: 1140,
  ),
  (
    id: 'marlow',
    level: 9,
    archetype: 'glasswing',
    gearTier: GearTier.worn,
    seedGeared: 1263,
    seedAcademy: 1140,
  ),
  (
    id: 'sable',
    level: 11,
    archetype: 'blighter',
    gearTier: GearTier.worn,
    seedGeared: 1302,
    seedAcademy: 1200,
  ),
  (
    id: 'dunstan',
    level: 13,
    archetype: 'bruiser',
    gearTier: GearTier.kitted,
    seedGeared: 1311,
    seedAcademy: 1080,
  ),
  (
    id: 'brightgale',
    level: 15,
    archetype: 'skirmisher',
    gearTier: GearTier.worn,
    seedGeared: 1320,
    seedAcademy: 1080,
  ),
  (
    id: 'quill',
    level: 17,
    archetype: 'adept',
    gearTier: GearTier.worn,
    seedGeared: 1374,
    seedAcademy: 1200,
  ),
  (
    id: 'hesper',
    level: 19,
    archetype: 'siphon',
    gearTier: GearTier.kitted,
    seedGeared: 1413,
    seedAcademy: 1200,
  ),
  (
    id: 'rook',
    level: 21,
    archetype: 'lasher',
    gearTier: GearTier.kitted,
    seedGeared: 1407,
    seedAcademy: 1080,
  ),
  (
    id: 'isolde',
    level: 23,
    archetype: 'sentinel',
    gearTier: GearTier.kitted,
    seedGeared: 1446,
    seedAcademy: 1140,
  ),
  (
    id: 'garrick',
    level: 25,
    archetype: 'bruiser',
    gearTier: GearTier.prized,
    seedGeared: 1470,
    seedAcademy: 1080,
  ),
  (
    id: 'thornwall',
    level: 28,
    archetype: 'adept',
    gearTier: GearTier.kitted,
    seedGeared: 1521,
    seedAcademy: 1200,
  ),
  (
    id: 'nettle',
    level: 30,
    archetype: 'blighter',
    gearTier: GearTier.kitted,
    seedGeared: 1545,
    seedAcademy: 1200,
  ),
  (
    id: 'corvane',
    level: 32,
    archetype: 'glasswing',
    gearTier: GearTier.prized,
    seedGeared: 1569,
    seedAcademy: 1140,
  ),
  (
    id: 'lisbet',
    level: 34,
    archetype: 'hexer',
    gearTier: GearTier.worn,
    seedGeared: 1623,
    seedAcademy: 1380,
  ),
  (
    id: 'ashbourne',
    level: 36,
    archetype: 'redoubt',
    gearTier: GearTier.prized,
    seedGeared: 1647,
    seedAcademy: 1260,
  ),
  (
    id: 'vale',
    level: 38,
    archetype: 'executioner',
    gearTier: GearTier.kitted,
    seedGeared: 1671,
    seedAcademy: 1320,
  ),
  (
    id: 'morwen',
    level: 40,
    archetype: 'champion',
    gearTier: GearTier.prized,
    seedGeared: 1710,
    seedAcademy: 1320,
  ),
  (
    id: 'tarquin',
    level: 42,
    archetype: 'siphon',
    gearTier: GearTier.prized,
    seedGeared: 1704,
    seedAcademy: 1200,
  ),
  (
    id: 'seraphel',
    level: 44,
    archetype: 'champion',
    gearTier: GearTier.prized,
    seedGeared: 1758,
    seedAcademy: 1320,
  ),
  (
    id: 'halvard',
    level: 46,
    archetype: 'redoubt',
    gearTier: GearTier.peak,
    seedGeared: 1782,
    seedAcademy: 1260,
  ),
  (
    id: 'nyx',
    level: 48,
    archetype: 'aspect',
    gearTier: GearTier.peak,
    seedGeared: 1836,
    seedAcademy: 1380,
  ),
  (
    id: 'aldorian',
    level: 50,
    archetype: 'tyrant',
    gearTier: GearTier.peak,
    seedGeared: 1875,
    seedAcademy: 1440,
  ),
  (
    id: 'ysolde',
    level: 50,
    archetype: 'aspect',
    gearTier: GearTier.peak,
    seedGeared: 1860,
    seedAcademy: 1380,
  ),
  (
    id: 'bramwell',
    level: 50,
    archetype: 'executioner',
    gearTier: GearTier.worn,
    seedGeared: 1800,
    seedAcademy: 1320,
  ),
];

/// LADDER_DESIGN §5 borrows these five personas by id rather than
/// duplicating their kit — see the `AiRoster` doc note and the library doc
/// on `LadderRoster`.
const _reusedPersonaIds = {
  'wick',
  'brightgale',
  'thornwall',
  'morwen',
  'aldorian',
};

/// ⚠️ Two reused personas' loadouts predate `Progression.plannedUnlockLevel`
/// (Brightgale carries Jolt, unlock 35, at L15; Thornwall carries Bulwark,
/// unlock 35, at L28) — `ai_roster_test.dart` already guards them against
/// the OLDER `Progression.unlockLevelOf` schedule, which they satisfy. Every
/// hand-written *new* bot here is held to the newer, planned schedule; these
/// two legacy kits are not re-litigated by this file.
const _plannedUnlockExemptIds = {'brightgale', 'thornwall'};

/// ⚠️ Offensive-core count that deliberately falls short of (or, for
/// Al'Dorian, exceeds) `archetype.moveCount` — see the `LadderRoster` library
/// doc for why each one is unavoidable given `plannedUnlockLevel` and the
/// design doc's fixed level/archetype/kit assignments.
const _offensiveCoreCountOverride = {
  'pim': 1,
  'orrin': 1,
  'dunstan': 1,
  'aldorian': 4,
};

const _tierUnlockLevel = {
  MagicTier.primal: 1,
  MagicTier.kinetic: 15,
  MagicTier.celestial: 30,
  MagicTier.ethereal: 45,
};

/// The 9 combat slots Peak gear fills (LADDER_DESIGN §5): everything but the
/// belt, which grants carrying capacity rather than combat power.
const _combatSlots = {
  EquipSlot.hat,
  EquipSlot.robeTop,
  EquipSlot.robeBottom,
  EquipSlot.boots,
  EquipSlot.gloves,
  EquipSlot.neck,
  EquipSlot.ring,
  EquipSlot.mainHand,
  EquipSlot.offHand,
};

void main() {
  test('the roster has exactly the 27 rows of LADDER_DESIGN §5', () {
    expect(
      LadderRoster.all.length,
      27,
      reason: 'LADDER_DESIGN §5 lists exactly 27 bots',
    );
    expect(
      LadderRoster.all.map((b) => b.id).toList(),
      _table.map((t) => t.id).toList(),
      reason: 'roster order and membership must match §5, top to bottom',
    );
  });

  test('the roster is level-ascending', () {
    final levels = LadderRoster.all.map((b) => b.level).toList();
    expect(
      levels,
      orderedEquals(List.of(levels)..sort()),
      reason: 'LadderRoster.all must stay weakest-to-strongest',
    );
  });

  test('ids and names are unique', () {
    final ids = LadderRoster.all.map((b) => b.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate bot id');
    final names = LadderRoster.all.map((b) => b.name).toList();
    expect(names.toSet().length, names.length, reason: 'duplicate bot name');
    for (final id in ids) {
      expect(LadderRoster.byId(id).id, id, reason: 'byId($id) must resolve');
    }
  });

  test('Procarius is not in the pool', () {
    expect(
      LadderRoster.all.where((b) => b.name == 'Procarius'),
      isEmpty,
      reason: 'Procarius stays a campaign boss (§4, §5)',
    );
    expect(
      LadderRoster.all.where((b) => b.level > 50),
      isEmpty,
      reason: 'no bot in the pool sits above the player cap',
    );
  });

  test('level, archetype and gear tier match §5 for every bot', () {
    for (final row in _table) {
      final bot = LadderRoster.byId(row.id);
      expect(bot.level, row.level, reason: '${row.id} level');
      expect(bot.archetype.id, row.archetype, reason: '${row.id} archetype');
      expect(bot.gearTier, row.gearTier, reason: '${row.id} gear tier');
    }
  });

  test('both seed ratings match §5 for every bot', () {
    for (final row in _table) {
      final bot = LadderRoster.byId(row.id);
      expect(
        bot.seedGeared,
        row.seedGeared,
        reason:
            '${row.id}: 1080 + 12·${bot.level} + 15·${bot.intelligence} '
            '+ ${bot.gearTier.term} (gear ${bot.gearTier.name})',
      );
      expect(
        bot.seedAcademy,
        row.seedAcademy,
        reason: '${row.id}: 1200 + 60·(${bot.intelligence} − 5)',
      );
    }
  });

  test(
    'intelligence is exactly the archetype\'s, nothing borrowed from a rating',
    () {
      for (final bot in LadderRoster.all) {
        expect(
          bot.intelligence,
          bot.archetype.intelligence,
          reason: '${bot.id} intelligence must come from its archetype alone',
        );
      }
    },
  );

  test('every element is legal for its bot\'s level', () {
    for (final bot in LadderRoster.all) {
      for (final element in bot.loadout.elements) {
        final needs = _tierUnlockLevel[element.tier]!;
        expect(
          bot.level,
          greaterThanOrEqualTo(needs),
          reason:
              '${bot.id} (L${bot.level}) carries ${element.name}, but '
              '${element.tier.name} unlocks at L$needs',
        );
      }
      expect(
        bot.loadout.elements.toSet().length,
        bot.loadout.elements.length,
        reason: '${bot.id} lists a duplicate element',
      );
      expect(
        bot.loadout.elements.length,
        inInclusiveRange(1, 5),
        reason: '${bot.id} element pool must fit the 5-slot cap',
      );
    }
  });

  test(
    'every spell is unlocked by its bot\'s level under the planned schedule',
    () {
      for (final bot in LadderRoster.all) {
        if (_plannedUnlockExemptIds.contains(bot.id)) continue;
        for (final spell in bot.loadout.spells) {
          final needs = Progression.plannedUnlockLevelOf(spell);
          expect(
            bot.level,
            greaterThanOrEqualTo(needs),
            reason:
                '${bot.id} (L${bot.level}) carries ${spell.id}, which the '
                'planned schedule unlocks at L$needs',
          );
        }
        expect(
          bot.loadout.spells.map((s) => s.id).toSet().length,
          bot.loadout.spells.length,
          reason: '${bot.id} lists a duplicate spell',
        );
        expect(
          bot.loadout.spells.length,
          inInclusiveRange(1, 10),
          reason: '${bot.id} spell pool must fit the 10-slot cap',
        );
      }
    },
  );

  test('the exempted legacy kits are legal under the OLDER unlock schedule '
      'instead, so nothing here is actually illegal content', () {
    for (final id in _plannedUnlockExemptIds) {
      final bot = LadderRoster.byId(id);
      for (final spell in bot.loadout.spells) {
        expect(
          bot.level,
          greaterThanOrEqualTo(Progression.unlockLevelOf(spell)),
          reason:
              '$id carries ${spell.id}, illegal even under the older '
              'schedule — that would be a real bug, not a grandfathered one',
        );
      }
    }
  });

  test('the offensive core has archetype.moveCount spells, cost in band', () {
    for (final bot in LadderRoster.all) {
      final core = bot.loadout.spells
          .where((s) => spellKindOf(s) == SpellKind.offense)
          .toList();
      final expectedCount =
          _offensiveCoreCountOverride[bot.id] ?? bot.archetype.moveCount;
      expect(
        core.length,
        expectedCount,
        reason:
            '${bot.id}: offensive core should be $expectedCount spell(s) '
            '(archetype ${bot.archetype.id} wants ${bot.archetype.moveCount})',
      );
      for (final spell in core) {
        expect(
          spell.chargeCost,
          inInclusiveRange(
            bot.archetype.minMoveCost,
            bot.archetype.maxMoveCost,
          ),
          reason:
              '${bot.id}: ${spell.id} costs ${spell.chargeCost}, outside '
              '${bot.archetype.id}\'s [${bot.archetype.minMoveCost},'
              '${bot.archetype.maxMoveCost}] band',
        );
      }
    }
  });

  test(
    'the documented offensive-core overrides are exactly these four bots',
    () {
      // A mutation that quietly adds or removes an override should fail loudly
      // rather than silently relax the count test above.
      expect(
        _offensiveCoreCountOverride.keys.toSet(),
        {'pim', 'orrin', 'dunstan', 'aldorian'},
        reason: 'the override map itself is part of the documented content gap',
      );
    },
  );

  group('gear', () {
    test('bare bots carry no gear', () {
      for (final bot in LadderRoster.all.where(
        (b) => b.gearTier == GearTier.bare,
      )) {
        expect(bot.gear, isEmpty, reason: '${bot.id} is Bare');
      }
    });

    test('piece count matches the tier\'s band', () {
      for (final bot in LadderRoster.all) {
        final n = bot.gear.length;
        switch (bot.gearTier) {
          case GearTier.bare:
            expect(n, 0, reason: '${bot.id} Bare');
          case GearTier.worn:
            expect(n, inInclusiveRange(2, 4), reason: '${bot.id} Worn');
          case GearTier.kitted:
            expect(n, inInclusiveRange(5, 7), reason: '${bot.id} Kitted');
          case GearTier.prized:
            expect(n, inInclusiveRange(7, 9), reason: '${bot.id} Prized');
          case GearTier.peak:
            expect(n, 9, reason: '${bot.id} Peak fills every combat slot');
        }
      }
    });

    test('quality matches the tier: standard/standard/ornate/master', () {
      const expected = {
        GearTier.worn: Quality.standard,
        GearTier.kitted: Quality.standard,
        GearTier.prized: Quality.ornate,
        GearTier.peak: Quality.master,
      };
      for (final bot in LadderRoster.all) {
        final want = expected[bot.gearTier];
        if (want == null) continue; // Bare has nothing to check.
        for (final piece in bot.gear) {
          expect(
            piece.quality,
            want,
            reason:
                '${bot.id}/${piece.itemId} should be $want for '
                '${bot.gearTier.name}',
          );
        }
      }
    });

    test(
      'every piece resolves, is equipment, and is legal for the bot\'s level',
      () {
        for (final bot in LadderRoster.all) {
          for (final piece in bot.gear) {
            final def = ItemCatalogue.tryById(piece.itemId);
            expect(
              def,
              isNotNull,
              reason:
                  '${bot.id}: "${piece.itemId}" does not resolve in '
                  'ItemCatalogue',
            );
            expect(
              def,
              isA<EquipmentDef>(),
              reason: '${bot.id}: "${piece.itemId}" is not wearable equipment',
            );
            final eq = def as EquipmentDef;
            expect(
              eq.equipLevel,
              lessThanOrEqualTo(bot.level),
              reason:
                  '${bot.id} (L${bot.level}) cannot legally equip '
                  '${piece.itemId} (requires L${eq.equipLevel})',
            );
          }
        }
      },
    );

    test('no bot repeats a slot', () {
      for (final bot in LadderRoster.all) {
        final slots = <EquipSlot>[];
        for (final piece in bot.gear) {
          final def = ItemCatalogue.byId(piece.itemId) as EquipmentDef;
          slots.add(def.slot);
        }
        expect(
          slots.toSet().length,
          slots.length,
          reason: '${bot.id} equips two pieces in the same slot',
        );
      }
    });

    test('Peak bots fill exactly the 9 combat slots, never the belt', () {
      for (final bot in LadderRoster.all.where(
        (b) => b.gearTier == GearTier.peak,
      )) {
        final slots = {
          for (final piece in bot.gear)
            (ItemCatalogue.byId(piece.itemId) as EquipmentDef).slot,
        };
        expect(slots, _combatSlots, reason: '${bot.id} Peak wardrobe');
      }
    });

    test(
      'gearModifiers is the fold of Equipping.modifiersOf over the pieces',
      () {
        for (final bot in LadderRoster.all) {
          var expected = ItemModifiers.none;
          for (final piece in bot.gear) {
            final def = ItemCatalogue.byId(piece.itemId);
            final instance = ItemInstance(
              instanceId: 'check_${bot.id}_${piece.itemId}',
              defId: piece.itemId,
              quality: piece.quality,
            );
            expected = expected + Equipping.modifiersOf(def, instance);
          }
          expect(
            bot.gearModifiers.toJson(),
            expected.toJson(),
            reason:
                '${bot.id}: gearModifiers must equal the piece-by-piece '
                'Equipping.modifiersOf fold, not a shortcut over raw defs',
          );
        }
      },
    );

    test('a bare bot contributes zero modifiers', () {
      for (final bot in LadderRoster.all.where(
        (b) => b.gearTier == GearTier.bare,
      )) {
        expect(
          bot.gearModifiers.isEmpty,
          isTrue,
          reason: '${bot.id} has no gear to contribute anything',
        );
      }
    });
  });

  group('reused personas', () {
    test(
      'the five borrowed bots share loadout and apparel identity with AiRoster',
      () {
        for (final id in _reusedPersonaIds) {
          final bot = LadderRoster.byId(id);
          final persona = AiRoster.byId(id);
          expect(
            identical(bot.loadout, persona.loadout),
            isTrue,
            reason: '$id must reuse AiRoster\'s Loadout instance, not a copy',
          );
          expect(
            identical(bot.apparel, persona.apparel),
            isTrue,
            reason:
                '$id must reuse AiRoster\'s MageApparel instance, not a copy',
          );
          expect(
            bot.name,
            persona.name,
            reason: '$id name must match AiRoster',
          );
          expect(
            bot.level,
            persona.level,
            reason: '$id level must match AiRoster',
          );
        }
      },
    );

    test('exactly these five are reused, and no more', () {
      expect(_reusedPersonaIds.length, 5, reason: 'Procarius is not reused');
      expect(_reusedPersonaIds, {
        'wick',
        'brightgale',
        'thornwall',
        'morwen',
        'aldorian',
      });
    });
  });

  test(
    'toPersona bridges cleanly to the shape LocalAiDriver already knows',
    () {
      for (final bot in LadderRoster.all) {
        final persona = bot.toPersona();
        expect(persona.id, bot.id, reason: '${bot.id} toPersona id');
        expect(persona.level, bot.level, reason: '${bot.id} toPersona level');
        expect(
          persona.intelligence,
          bot.intelligence,
          reason: '${bot.id} toPersona intelligence',
        );
        expect(
          identical(persona.loadout, bot.loadout),
          isTrue,
          reason: '${bot.id} toPersona must not copy the loadout',
        );
        expect(
          persona.buildBrain(),
          isNotNull,
          reason: '${bot.id} builds a brain',
        );
      }
    },
  );

  group('withinBand', () {
    test(
      'returns bots whose seed sits within the band, on the right ladder',
      () {
        final wick = LadderRoster.byId(
          'wick',
        ); // seedGeared 1107, seedAcademy 960
        final near = LadderRoster.withinBand(1107, band: 0, academy: false);
        expect(
          near.map((b) => b.id),
          contains('wick'),
          reason: 'an exact-match rating must be within a zero band',
        );
        expect(
          near.every((b) => (b.seedGeared - 1107).abs() <= 0),
          isTrue,
          reason: 'every returned bot must actually satisfy the geared band',
        );

        final farAcademy = LadderRoster.withinBand(960, band: 0, academy: true);
        expect(
          farAcademy.map((b) => b.id),
          contains('wick'),
          reason: 'academy: false vs true must read different seeds',
        );
        expect(
          wick.seedGeared,
          isNot(wick.seedAcademy),
          reason: 'sanity: two ladders differ',
        );
      },
    );

    test(
      'a huge band returns everyone; a negative-width band returns no one',
      () {
        expect(
          LadderRoster.withinBand(1500, band: 10000, academy: false).length,
          27,
          reason: 'a band that wide must cover the whole pool',
        );
        expect(
          LadderRoster.withinBand(1, band: -1, academy: false),
          isEmpty,
          reason: 'abs(seed - rating) can never be < 0',
        );
      },
    );
  });
}
