/// Where things come from (ruling, Christian, playtest 2026-09-30, note 3:
/// "…so I can more easily search for a place that has Rowan logs or iron
/// ore"): `Provenance`, read off the gather nodes and the drop tables.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a lookup against the wrong zone, the mote/key filter dropped, the
/// groups sorted the wrong way round, a source index that only reads nodes or
/// only reads drops, and copy that repeats what the gather line said.
///
/// 📝 The per-zone tests (`glimmerbrook_test.dart` and friends) already prove
/// each zone's OWN drops resolve; the catalogue law here is the
/// `Bestiary.all`-wide one, because `Provenance` skips an id that fails to
/// resolve rather than crashing the Map tab, and that skip must stay
/// theoretical.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/provenance.dart';
import 'package:masters_of_magic_2/game/world.dart';

List<String> _ids(List<ItemDef> defs) => [for (final d in defs) d.id];

/// The group a def sorts into on the drops list — written out here rather
/// than borrowed, so the law is checked against the ruling, not against
/// itself.
int _group(ItemDef d) => switch (d) {
  MaterialDef() => 0,
  ConsumableDef() || BeltableDef() => 1,
  EquipmentDef() => 3,
  _ => 2,
};

void main() {
  const peaks = 'thunderspire_peaks';

  group('the catalogue law', () {
    test('every id any creature can drop, and every node yield, resolves', () {
      final missing = [
        for (final e in Bestiary.all)
          for (final id in e.drops.possibleDrops)
            if (!ItemCatalogue.contains(id)) '${e.id} drops $id',
        for (final n in GatherNodes.all)
          if (!ItemCatalogue.contains(n.yieldsDefId))
            '${n.id} yields ${n.yieldsDefId}',
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'Provenance silently skips an unresolved id — a typo in a drop '
            'table would vanish from the Map instead of failing here',
      );
    });
  });

  group('gatherablesIn', () {
    test("Thunderspire Peaks yields Rowan Log and Iron Ore, in node order", () {
      final ids = _ids(Provenance.gatherablesIn(peaks));
      expect(
        ids,
        containsAll(['rowan_log', 'iron_ore']),
        reason:
            'the ruling\'s own example — a lookup keyed on the wrong zone '
            '(or on the node id) comes back without them',
      );
      expect(
        ids,
        ['rowan_log', 'iron_ore', 'hum_quartz'],
        reason:
            'node order (the Rowan stand, the iron seam, the humming face) — '
            'a list read off the drop tables instead comes back Rowan, Hum '
            'Quartz, Iron',
      );
    });

    test('a town gathers nothing', () {
      expect(
        Provenance.gatherablesIn(World.startLocationId),
        isEmpty,
        reason:
            'Hearthwood has no nodes — a fallback to some default zone '
            '(World.byId falls back to the first location) fails here',
      );
    });
  });

  group('dropsIn', () {
    test('excludes motes and keys — though the raw tables hold both', () {
      final raw = {
        for (final e in Bestiary.all)
          for (final id in e.drops.possibleDrops) ItemCatalogue.byId(id),
      };
      // ⚠️ Precondition, so the exclusion below is not vacuous.
      expect(
        raw.whereType<MoteDef>(),
        isNotEmpty,
        reason: 'the test needs motes in the raw tables',
      );
      expect(
        raw.whereType<KeyDef>(),
        isNotEmpty,
        reason: 'the test needs keys in the raw tables',
      );
      for (final loc in World.locations) {
        final drops = Provenance.dropsIn(loc.id);
        expect(
          drops.whereType<MoteDef>(),
          isEmpty,
          reason: '${loc.id}: motes listed — the mote filter was dropped',
        );
        expect(
          drops.whereType<KeyDef>(),
          isEmpty,
          reason: '${loc.id}: a key listed — the key filter was dropped',
        );
      }
    });

    test('materials, then drinkables, then equipment by rarity ascending; '
        'each group in first-seen order', () {
      for (final loc in World.locations) {
        final drops = Provenance.dropsIn(loc.id);
        // First-seen order, rebuilt independently: creature by creature,
        // `always` → `main` → `bonus`.
        final seen = <String>{
          for (final e in Bestiary.forZone(loc.id)) ...e.drops.possibleDrops,
        }.toList();
        for (var i = 1; i < drops.length; i++) {
          final a = drops[i - 1], b = drops[i];
          final ga = _group(a), gb = _group(b);
          expect(
            ga <= gb,
            isTrue,
            reason:
                '${loc.id}: ${a.id} (group $ga) before ${b.id} (group $gb) — '
                'an unsorted list, or materials ranked after rations, fails '
                'here',
          );
          if (ga == 3 && gb == 3) {
            expect(
              a.rarity.index <= b.rarity.index,
              isTrue,
              reason:
                  '${loc.id}: ${a.id} (${a.rarity.name}) before ${b.id} '
                  '(${b.rarity.name}) — equipment sorted by rarity '
                  'DESCENDING fails here',
            );
          }
          if (ga == gb && (ga != 3 || a.rarity == b.rarity)) {
            expect(
              seen.indexOf(a.id) < seen.indexOf(b.id),
              isTrue,
              reason:
                  '${loc.id}: ${a.id} and ${b.id} share a group but are out '
                  'of first-seen order — a group sorted by name fails here',
            );
          }
        }
      }
    });

    test('Thunderspire Peaks: its three materials, Hardtack, then the rare '
        'pendant before the epic grips', () {
      expect(
        _ids(Provenance.dropsIn(peaks)),
        [
          'rowan_log',
          'hum_quartz',
          'iron_ore',
          'hardtack',
          'countstone_pendant',
          'groundfault_grips',
        ],
        reason:
            'the whole list for one zone pinned — a drop table read from the '
            'wrong zone, or equipment ranked ahead of materials, fails here',
      );
    });
  });

  group('sourcesOf', () {
    test("'rowan_log' names Thunderspire Peaks and nothing else", () {
      final sources = Provenance.sourcesOf('rowan_log');
      expect(
        [for (final s in sources) s.location.id],
        [peaks],
        reason:
            'one zone has Rowan — an index keyed on the item\'s catalogue '
            'zone (ItemCatalogue.zoneOf) or on every connected zone fails',
      );
      expect(
        (sources.single.gathered, sources.single.dropped),
        (true, true),
        reason:
            'rowan is both on a node and in a drop table there — an index '
            'that reads only nodes, or only drops, gets one flag wrong',
      );
    });

    test('an item that is only ever crafted has no source', () {
      expect(
        ItemCatalogue.contains('oak_wand'),
        isTrue,
        reason: 'precondition: the Oak Wand is a real item',
      );
      expect(
        Provenance.sourcesOf('oak_wand'),
        isEmpty,
        reason:
            'the Oak Wand is crafted at the bench — a fallback that answers '
            'with the item\'s home zone fails here',
      );
    });

    test('motes answer too — unlike dropsIn, nothing is filtered', () {
      expect(
        Provenance.sourcesOf('flora_dust'),
        isNotEmpty,
        reason:
            'Flora Dust drops in the Woods — sourcesOf built from the '
            'filtered dropsIn lists finds nothing',
      );
    });

    test('in World.locations order, flags per zone', () {
      final sources = Provenance.sourcesOf('deepstratum_ore');
      expect(
        [for (final s in sources) s.location.id],
        ['hallowmarch', 'the_buried_sky'],
        reason: 'map order — a list in bestiary or node order fails here',
      );
      expect(
        [for (final s in sources) (s.gathered, s.dropped)],
        [(true, false), (true, true)],
        reason:
            'Hallowmarch has the node only; the Buried Sky has node and '
            'drop — flags shared across zones fail here',
      );
    });
  });

  group('the copy', () {
    final thunderspire = World.byId(peaks);
    final woods = World.byId('whispering_woods');
    final hearthwood = World.byId(World.startLocationId);

    test('gather line', () {
      expect(
        Provenance.gatherLine(thunderspire),
        'Gather: Rowan Log · Iron Ore · Hum Quartz',
        reason: 'display names, node order, one label, " · " separators',
      );
      expect(
        Provenance.gatherLine(World.byId('the_eclipsed_citadel')),
        isNull,
        reason:
            'the Citadel has no nodes — "Gather: " with nothing after it '
            'fails here',
      );
    });

    test('drops line: no repeats of the gather line, no common equipment', () {
      expect(
        Provenance.dropsLine(thunderspire),
        'Drops: Hardtack · Countstone Pendant · Groundfault Grips',
        reason:
            'Rowan, Iron and Hum Quartz are on the gather line already — a '
            'drops line that repeats them fails here',
      );
      final woodsLine = Provenance.dropsLine(woods)!;
      expect(
        _ids(Provenance.dropsIn(woods.id)),
        contains('oak_circlet'),
        reason: 'precondition: the Rootknuckle drops a common Oak Circlet',
      );
      expect(
        woodsLine,
        isNot(contains('Oak Circlet')),
        reason: 'commons are the crafted set — the rarity floor was dropped',
      );
      expect(
        woodsLine,
        contains('Sporecap Mantle'),
        reason: 'a rare piece stays — a floor set above rare fails here',
      );
    });

    test('towns say nothing', () {
      expect(
        (Provenance.gatherLine(hearthwood), Provenance.dropsLine(hearthwood)),
        (null, null),
        reason: 'a town is not a place you hunt in',
      );
    });

    test('found-in line', () {
      expect(
        Provenance.foundInLine(ItemCatalogue.byId('deepstratum_ore')),
        'Found in: Hallowmarch (gathered) · The Buried Sky (gathered, dropped)',
        reason: 'one label, place names in map order, both ways named',
      );
      expect(
        Provenance.foundInLine(ItemCatalogue.byId('oak_wand')),
        isNull,
        reason: 'a crafted-only item prints no line at all',
      );
    });
  });
}
