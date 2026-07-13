import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import 'element_style.dart';
import 'mage_apparel.dart';

/// Low-rez, statically drawn pixel mage. Apparel colors palette-swap the
/// sprite (equipment made visible); the staff orb takes the charged
/// element's color and glows brighter with more charge.
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
  static const cols = 16;
  static const rows = 22;

  // Pixel grid. h hat, H hat trim, s skin, e eye, r robe, R robe trim,
  // g glove, b boot, w staff wood, o staff orb, . empty.
  static const List<String> grid = [
    '......hh........',
    '.....hhhh.......',
    '....hhhhhh......',
    '...hhhhhhhh.....',
    '..hhhhhhhhhh....',
    '.HHHHHHHHHHHH...',
    '....ssssss......',
    '....sseses......',
    '....ssssss......',
    '.....ssss....oo.',
    '..RRRRRRRRR..oo.',
    '..rrrrrrrrr...w.',
    '..rrrrrrrrr...w.',
    '..rrrrrrrrrgg.w.',
    '..rrrrrrrrr.ggw.',
    '..rrrrrrrrr...w.',
    '..rrrrrrrrr...w.',
    '..rrrrrrrrr...w.',
    '..RRRRRRRRR...w.',
    '..rrrrrrrrr...w.',
    '..bbb...bbb.....',
    '..bbb...bbb.....',
  ];

  final MageApparel apparel;
  final Color orbColor;
  final int charge;

  _MagePainter({
    required this.apparel,
    required this.orbColor,
    required this.charge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
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
          'H' => apparel.hatTrim,
          's' => const Color(0xFFE8B98A),
          'e' => const Color(0xFF2B1D14),
          'r' => apparel.robe,
          'R' => apparel.robeTrim,
          'g' => apparel.gloves,
          'b' => apparel.boots,
          'w' => const Color(0xFF7A5230),
          'o' => orbColor,
          _ => null,
        };
        if (color == null) continue;
        paint.color = color;
        final rowH = size.height / rows;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * rowH, cell + 0.5, rowH + 0.5),
          paint,
        );
      }
    }

    // Orb glow ring on top, scaled by charge.
    if (charge > 0) {
      final orbCenter = Offset(13.9 * cell, size.height * (9.9 / rows));
      paint.color = orbColor.withValues(alpha: 0.30);
      canvas.drawCircle(orbCenter, cell * (1.4 + 0.5 * charge), paint);
      paint.color = orbColor.withValues(alpha: 0.85);
      canvas.drawCircle(orbCenter, cell * 1.15, paint);
    }
  }

  @override
  bool shouldRepaint(_MagePainter old) =>
      old.apparel != apparel || old.orbColor != orbColor || old.charge != charge;
}
