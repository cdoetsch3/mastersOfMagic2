// ignore_for_file: avoid_print
/// Renders every Whispering Woods creature to a PNG contact sheet, so the
/// sprites can be looked at rather than imagined.
///
/// `flutter test tool/render_creatures_test.dart`
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/creature_sprite.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods_art.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  testWidgets('contact sheet', (tester) async {
    final entries = WhisperingWoodsArt.byEnemyId.entries.toList();
    const cellW = 260.0;
    const cellH = 240.0;
    const perRow = 4;
    final rows = (entries.length / perRow).ceil();
    final size = Size(cellW * perRow, cellH * rows);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF141021),
    );

    final palette = SpritePalette.forElement(MagicElement.flora);
    for (var i = 0; i < entries.length; i++) {
      final art = entries[i].value;
      final col = i % perRow;
      final row = i ~/ perRow;
      // Fit each sprite inside its cell, preserving aspect.
      const box = 190.0;
      final h = art.aspect > 1 ? box / art.aspect : box;
      final w = h * art.aspect;
      canvas.save();
      canvas.translate(
        col * cellW + (cellW - w) / 2,
        row * cellH + (cellH - h) / 2 - 10,
      );
      CreaturePainter(art: art, palette: palette).paint(canvas, Size(w, h));
      canvas.restore();
    }

    final png = await tester.runAsync(() async {
      final img = await recorder.endRecording().toImage(
        size.width.round(),
        size.height.round(),
      );
      return img.toByteData(format: ui.ImageByteFormat.png);
    });
    File('docs/plates/creatures-whispering-woods.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
    print('wrote ${entries.length} creatures, '
        '${size.width.round()}x${size.height.round()}');
  });
}
