import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:masters_of_magic_2/ui/element_glyphs.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  group('every element has a mark that renders', () {
    for (final element in MagicElement.values) {
      testWidgets('${element.name} draws at icon sizes', (tester) async {
        for (final size in [14.0, 18.0, 40.0]) {
          await tester.pumpWidget(
            Center(
              child: MediaQuery(
                data: const MediaQueryData(),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: elementGlyph(element, size: size),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${element.name} @$size',
          );
        }
      });
    }
  });

  group('the drawn glyphs', () {
    test('Sanctus and Umbra are drawn, not Material icons', () {
      // Material has no halo and no demon; if these ever fall back to an icon
      // they will silently look like a second Solar and a second Lunar again.
      expect(MagicElement.sanctus.style.glyph, isNotNull);
      expect(MagicElement.umbra.style.glyph, isNotNull);
    });

    test('no other element claims a drawn glyph', () {
      for (final e in MagicElement.values) {
        if (e == MagicElement.sanctus || e == MagicElement.umbra) continue;
        expect(e.style.glyph, isNull, reason: '${e.name} should use its icon');
      }
    });

    testWidgets('both painters repaint when their colour changes', (
      tester,
    ) async {
      expect(
        const HaloGlyphPainter(
          Colors.red,
        ).shouldRepaint(const HaloGlyphPainter(Colors.blue)),
        isTrue,
      );
      expect(
        const HaloGlyphPainter(
          Colors.red,
        ).shouldRepaint(const HaloGlyphPainter(Colors.red)),
        isFalse,
      );
      expect(
        const DemonGlyphPainter(
          Colors.red,
        ).shouldRepaint(const DemonGlyphPainter(Colors.blue)),
        isTrue,
      );
    });
  });
}
