import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
import 'package:masters_of_magic_2/ui/world_map_painter.dart';

/// Regenerates `docs/plates/world-map.html`.
///
/// ⚠️ **Terrain comes from the real painter; text does NOT.** `flutter test`
/// substitutes a placeholder font that draws every glyph as a filled box, and
/// no amount of font loading reaches it — so the PNG is rendered with pins and
/// labels OFF, and the names are overlaid as SVG from the same data. One
/// source of truth, and text a human can actually read.
// ignore_for_file: avoid_print

void main() {
  testWidgets('regenerate the world map plate', (tester) async {
    final b = WorldMapGeometry.bounds;
    const scale = 1.4;
    final size = Size(b.width * scale, b.height * scale);

    final recorder = ui.PictureRecorder();
    WorldMapPainter(
      showPins: false,
      showFeatureLabels: false,
    ).paint(Canvas(recorder, Offset.zero & size), size);

    final png = await tester.runAsync(() async {
      final img = await recorder.endRecording().toImage(
        size.width.round(),
        size.height.round(),
      );
      return img.toByteData(format: ui.ImageByteFormat.png);
    });
    File('docs/plates/world-map.png')
        .writeAsBytesSync(png!.buffer.asUint8List());

    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final data = {
      'scale': scale,
      'bounds': {'l': b.left, 't': b.top, 'w': b.width, 'h': b.height},
      'veilY': WorldMapGeometry.veilY,
      'features': [
        for (final l in WorldMapGeometry.featureLabels)
          {
            'text': l.text,
            'x': l.at.dx,
            'y': l.at.dy,
            'size': l.size,
            'tracking': l.tracking,
            'rot': l.rotation,
            'tone': l.tone.name,
          },
      ],
      'places': [
        for (final l in World.locations)
          if (WorldMapGeometry.positions[l.id] != null)
            {
              'id': l.id,
              'name': l.name,
              'kind': l.kind.name,
              'x': WorldMapGeometry.positions[l.id]!.dx,
              'y': WorldMapGeometry.positions[l.id]!.dy,
              'band': l.isTown ? '' : 'Lv ${l.minLevel}-${l.maxLevel}',
              'tier': l.tier?.name ?? '',
              'colors': [
                for (final e in l.elements) hex(elementStyles[e]!.color),
              ],
              'elements': [for (final e in l.elements) elementStyles[e]!.label],
            },
      ],
    };
    File('docs/plates/world-map.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    print('terrain ${size.width.round()}x${size.height.round()}, '
        '${(data['places']! as List).length} places');
  });
}
