/// The export is the wiki's food supply, so what these tests really guard is
/// every future wiki page.
///
/// ⭐ **Referential integrity is the framework** (docs/CONTENT_EXPORT.md): a
/// zone catalogue that names an unlisted item id compiles clean and fails
/// only here, which is what lets 25 more zones be added without re-auditing
/// by hand.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_export.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/world.dart';

void main() {
  final export = ContentExport.build();

  test('the export is deterministic — two builds encode identically', () {
    // ⚠️ Compared as JSON strings, not deep-equal maps: encoding is what the
    // wiki consumes, and it is where map-ordering nondeterminism shows up.
    expect(jsonEncode(ContentExport.build()), jsonEncode(export));
  });

  test('every id any table references resolves in a catalogue', () {
    // 📝 **The next parallel wave arrived** (Celestial/Ethereal, 2026-09-22)
    // and the machinery is doing the job it was kept for. Each id below is
    // referenced by a zone that has landed and defined by a zone that has
    // not — the merge window, exactly as `hardtack` was at C2a.
    //
    // ⚠️ **Empty this set once the wave is merged.** An exemption that
    // outlives its merge window is a permanently unresolvable drop that the
    // test now blesses.
    //
    //  - `astral_*` — the Starfall Basin lane (CELESTIAL_CONTRACT §3.2);
    //    referenced by The Shattered Orrery, which pays both mote ladders.
    //  - `pilgrims_ration` — The Kiln Desert lane (§3.3); the quarter's
    //    shared drop-only ration, referenced by every Celestial zone.
    // ✅ Emptied 2026-09-22: the Celestial wave's seven zones are all on
    // main, so every id resolves for real again. The Ethereal wave will
    // need this window once more (sanctus_* / umbra_* land with Hallowmarch
    // and the Umbral Wastes); empty it again the moment that wave lands.
    // ✅ Emptied 2026-09-22: both late quarters are on main; every id
    // resolves for real. Reopen only for the next parallel wave.
    const crossBuilderIds = <String>{};
    final missing = <String>[];
    void check(String? id, String where) {
      if (id != null &&
          !crossBuilderIds.contains(id) &&
          ItemCatalogue.tryById(id) == null) {
        missing.add('$where -> $id');
      }
    }

    for (final e in Bestiary.all) {
      for (final d in [...e.drops.always, ...e.drops.main, ...e.drops.bonus]) {
        check(d.defId, 'drop ${e.id}');
      }
    }
    for (final r in RecipeBook.all) {
      check(r.outputId, 'recipe ${r.id} output');
      for (final i in r.inputs) {
        check(i.defId, 'recipe ${r.id} input');
      }
    }
    for (final n in GatherNodes.all) {
      check(n.yieldsDefId, 'gather node ${n.id}');
      expect(
        World.exists(n.zoneId),
        isTrue,
        reason: '${n.id} spawns in a zone that does not exist',
      );
    }
    // Salvage is already covered by the items' own tests, but the export
    // walks it too — keep the net over the same water.
    expect(missing, isEmpty, reason: 'ids referenced but owned by nothing');
  });

  test('every creature belongs to a real zone', () {
    final zoneIds = World.locations.map((l) => l.id).toSet();
    for (final e in Bestiary.all) {
      expect(zoneIds, contains(e.zoneId), reason: e.id);
    }
  });

  test('each creature publishes its kill rules (rulings 2026-09-30)', () {
    // ⭐ The consolation and rank gear live in the roller, not the tables; a
    // wiki that read `drops` alone would show kills that pay nothing.
    final creatures = (export['creatures']! as List).cast<Map>();
    Map kill(String id) =>
        creatures.firstWhere((c) => c['id'] == id)['kill'] as Map;
    expect(
      kill('ionwake')['consolationItemId'],
      'iron_ore',
      reason: 'kills an export that drops or restates the consolation',
    );
    expect(
      kill('mirage')['consolationItemId'],
      'solar_dust',
      reason: 'the no-craftable fallback is published too',
    );
    final byRank = {
      for (final c in creatures)
        c['rank'] as String: (c['kill'] as Map)['rankGearChance'],
    };
    expect(byRank, {
      'common': 0.0,
      'mini': miniGearChance,
      'boss': 1.0,
    }, reason: 'kills a rank-gear chance published for the wrong rank');
    expect(
      kill('ionwake')['rankGearEpicShare'],
      bossEpicChance,
      reason: 'the epic share is the roller\'s knob, not a copy',
    );
  });

  test('recipe ids are unique, and no recipe is a faucet', () {
    final ids = RecipeBook.all.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
    // ⚠️ This check lives here rather than in a RecipeDef assert because
    // list length is not const-evaluable in Dart.
    for (final r in RecipeBook.all) {
      expect(r.inputs, isNotEmpty, reason: '${r.id} consumes nothing');
    }
  });

  test('the derived index answers "where does oak_log come from"', () {
    final index = export['index']! as Map<String, Object?>;
    final sources = index['itemSources']! as Map<String, Object?>;
    // ⭐ Mutation check with teeth: oak_log drops in the Whispering Woods, so
    // an index that loses drop-walking loses this key.
    final oak = sources['oak_log']! as List;
    expect(oak, isNotEmpty);
    expect(
      oak.any(
        (s) =>
            (s as Map)['type'] == 'drop' && s['zoneId'] == 'whispering_woods',
      ),
      isTrue,
    );
  });

  test('the gate item is sourced from both bosses', () {
    final index = export['index']! as Map<String, Object?>;
    final sources = index['itemSources']! as Map<String, Object?>;
    final proof = (sources['proof_of_the_woods']! as List).cast<Map>();
    final droppers = proof.map((s) => s['from']).toSet();
    expect(droppers.length, greaterThanOrEqualTo(2));
  });
}
