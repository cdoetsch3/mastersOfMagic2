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
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
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
    final missing = <String>[];
    void check(String? id, String where) {
      if (id != null && ItemCatalogue.tryById(id) == null) {
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
        (s) => (s as Map)['type'] == 'drop' &&
            s['zoneId'] == 'whispering_woods',
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
