import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/creature_sprite.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods_art.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  group('a grid must be a rectangle', () {
    test('every row is the same length', () {
      // ⚠️ A ragged grid does not throw — it draws a torn silhouette, which
      // reads as bad art rather than as a bug.
      WhisperingWoodsArt.byEnemyId.forEach((id, art) {
        final widths = art.grid.map((r) => r.length).toSet();
        expect(widths, hasLength(1), reason: '$id has ragged rows: $widths');
        expect(art.cols, widths.single);
      });
    });

    test('every character is a palette slot', () {
      const legal = {'b', 'd', 'l', 'a', 'A', 'o', 'e', 'g', 'G', '.'};
      WhisperingWoodsArt.byEnemyId.forEach((id, art) {
        for (final row in art.grid) {
          for (final ch in row.split('')) {
            expect(legal, contains(ch), reason: '$id uses "$ch"');
          }
        }
      });
    });

    test('nothing is blank', () {
      WhisperingWoodsArt.byEnemyId.forEach((id, art) {
        final filled = art.grid
            .expand((r) => r.split(''))
            .where((c) => c != '.')
            .length;
        expect(filled, greaterThan(20), reason: '$id is nearly empty');
      });
    });
  });

  group('the roster and the art agree', () {
    test('every Whispering Woods creature has a sprite', () {
      for (final e in Bestiary.forZone('whispering_woods')) {
        expect(
          WhisperingWoodsArt.byEnemyId,
          contains(e.id),
          reason: '${e.name} has no art',
        );
      }
    });

    test('no art belongs to a creature that does not exist', () {
      final ids = Bestiary.all.map((e) => e.id).toSet();
      for (final id in WhisperingWoodsArt.byEnemyId.keys) {
        expect(ids, contains(id), reason: '$id is art for nothing');
      }
    });
  });

  group('the palette', () {
    test('an element palette is built from that element', () {
      final flora = SpritePalette.forElement(MagicElement.flora);
      final pyro = SpritePalette.forElement(MagicElement.pyro);
      expect(flora.glow, isNot(pyro.glow));
      // ⭐ One grid recoloured is a whole family, so body must move too.
      expect(flora.body, isNot(pyro.body));
    });

    test('body, shade and highlight are distinguishable', () {
      // ⚠️ The first pass lerped body toward the panel colour and every
      // creature came out a flat lump with no internal form.
      final p = SpritePalette.forElement(MagicElement.flora);
      final body = p.resolve('b')!;
      final shade = p.resolve('d')!;
      final light = p.resolve('l')!;
      // ⚠️ Color.r/g/b are 0..1 doubles, not 0..255 ints — an integer
      // formula here silently returns 0 for everything and passes nothing.
      double lum(Color c) => c.r * 0.299 + c.g * 0.587 + c.b * 0.114;
      expect((lum(body) - lum(shade)).abs(), greaterThan(0.06));
      expect((lum(light) - lum(body)).abs(), greaterThan(0.06));
    });

    test('an unknown character draws nothing rather than throwing', () {
      expect(SpritePalette.forElement(MagicElement.flora).resolve('?'), isNull);
    });
  });
}
