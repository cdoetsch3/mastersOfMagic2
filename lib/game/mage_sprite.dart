import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import 'element_style.dart';
import 'mage_apparel.dart';

/// Fine-pixel (32x44) mage sprite, statically drawn. Apparel colors
/// palette-swap the sprite (equipment made visible); shade pixels are derived
/// from the apparel colors so swaps stay consistent. The staff orb takes the
/// charged element's color and glows brighter with more charge.
class MageSprite extends StatefulWidget {
  final MageApparel apparel;
  final MagicElement? element;
  final int charge;
  final bool facingRight;
  final bool defeated;
  final double height;

  const MageSprite({
    super.key,
    required this.apparel,
    this.element,
    this.charge = 0,
    this.facingRight = true,
    this.defeated = false,
    this.height = 160,
  });

  @override
  State<MageSprite> createState() => _MageSpriteState();
}

class _MageSpriteState extends State<MageSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * _MagePainter.cols / _MagePainter.rows;
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final dy = widget.defeated ? 0.0 : sin(_bob.value * 2 * pi) * 3;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: widget.defeated ? (widget.facingRight ? -1 : 1) * pi / 2 : 0,
            child: child,
          ),
        );
      },
      child: Transform.flip(
        flipX: !widget.facingRight,
        child: Opacity(
          opacity: widget.defeated ? 0.55 : 1,
          child: CustomPaint(
            size: Size(width, widget.height),
            painter: _MagePainter(
              apparel: widget.apparel,
              orbColor: widget.element?.style.color ?? const Color(0xFF6E6A7A),
              charge: widget.charge,
            ),
          ),
        ),
      ),
    );
  }
}

class _MagePainter extends CustomPainter {
  static const cols = 32;
  static const rows = 44;

  static const _skin = Color(0xFFE8B98A);
  static const _eye = Color(0xFF2B1D14);
  static const _wood = Color(0xFF7A5230);

  // Pixel grid. h hat, j hat shade, H hat trim, s skin, S skin shade, e eye,
  // r robe, d robe shade, R robe trim, g glove, b boot, B boot shade,
  // w staff wood, W wood shade, o orb, O orb highlight, . empty.
  static const List<String> grid = [
    '............hh..................',
    '...........hhhj.................',
    '...........hhhj.................',
    '..........hhhhhj................',
    '.........hhhhhhhj...............',
    '.........hhhhhhhj...............',
    '........hhhhhhhhjj..............',
    '.......hhhhhhhhhhjj.............',
    '......hhhhhhhhhhhhjj......oo....',
    '.....hhhhhhhhhhhhhhjj....Oooo...',
    '....hhhhhhhhhhhhhhhhjj..Oooooo..',
    '...hhhhhhhhhhhhhhhhhhjj.oooooo..',
    '...HHHHHHHHHHHHHHHHHHHH..oooo...',
    '...HHHHHHHHHHHHHHHHHHHH...oo....',
    '..hhhhhhhhhhhhhhhhhhhhjj..wW....',
    '.jjjjjjjjjjjjjjjjjjjjjjjj.wW....',
    '........sssssssssS........wW....',
    '........sssssssssS........wW....',
    '........ssseesseeS........wW....',
    '........ssseesseeS........wW....',
    '........sssssssssS........wW....',
    '........ssssSSsssS........wW....',
    '.........sssssssS.........wW....',
    '...........ssss...........wW....',
    '......RRRRRRRRRRRRRR......wW....',
    '.....rrrrrrrrrrrrrrdd.....wW....',
    '.....rrrrrrrrrrrrrrddrrrr.wW....',
    '.....rrrrrrrrrrrrrrddrrrr.wW....',
    '.....rrrrrrrrrrrrrrddrrrggwW....',
    '.....rrrrrrrrrrrrrrdd...ggwW....',
    '.....RRRRRRRRRRRRRRRR.....wW....',
    '.....RRRRRRRRRRRRRRRR.....wW....',
    '.....rrrrrrrrrrrrrrdd.....wW....',
    '.....rrrrrrrrrrrrrrdd.....wW....',
    '....rrrrrrrrrrrrrrrrdd....wW....',
    '....rrrrrrrrrrrrrrrrdd....wW....',
    '....rrrrrrrrrrrrrrrrdd....wW....',
    '....rrrrrrrrrrrrrrrrdd....wW....',
    '....RRRRRRRRRRRRRRRRRR....wW....',
    '....RRRRRRRRRRRRRRRRRR....wW....',
    '.......bbbb...bbbb........wW....',
    '.......bbbb...bbbb........wW....',
    '.......BBBB...BBBB........wW....',
    '................................',
  ];

  final MageApparel apparel;
  final Color orbColor;
  final int charge;

  _MagePainter({
    required this.apparel,
    required this.orbColor,
    required this.charge,
  });

  static Color _shade(Color c) => Color.lerp(c, const Color(0xFF000000), 0.28)!;
  static Color _light(Color c) => Color.lerp(c, const Color(0xFFFFFFFF), 0.5)!;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
    final rowH = size.height / rows;
    final paint = Paint();

    // Charge aura behind the mage: grows and brightens with charge.
    if (charge > 0) {
      paint.color = orbColor.withValues(alpha: 0.06 * charge);
      canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.62),
          size.height * (0.26 + 0.04 * charge), paint);
    }

    for (var y = 0; y < rows; y++) {
      final row = grid[y];
      for (var x = 0; x < cols; x++) {
        final color = switch (row[x]) {
          'h' => apparel.hat,
          'j' => _shade(apparel.hat),
          'H' => apparel.hatTrim,
          's' => _skin,
          'S' => _shade(_skin),
          'e' => _eye,
          'r' => apparel.robe,
          'd' => _shade(apparel.robe),
          'R' => apparel.robeTrim,
          'g' => apparel.gloves,
          'b' => apparel.boots,
          'B' => _shade(apparel.boots),
          'w' => _wood,
          'W' => _shade(_wood),
          'o' => orbColor,
          'O' => _light(orbColor),
          _ => null,
        };
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * rowH, cell + 0.5, rowH + 0.5),
          paint,
        );
      }
    }

    // Orb glow on top, scaled by charge.
    if (charge > 0) {
      final orbCenter = Offset(27 * cell, 11 * rowH);
      paint.color = orbColor.withValues(alpha: 0.30);
      canvas.drawCircle(orbCenter, cell * (3.0 + 1.0 * charge), paint);
      paint.color = orbColor.withValues(alpha: 0.55);
      canvas.drawCircle(orbCenter, cell * 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(_MagePainter old) =>
      old.apparel != apparel || old.orbColor != orbColor || old.charge != charge;
}
