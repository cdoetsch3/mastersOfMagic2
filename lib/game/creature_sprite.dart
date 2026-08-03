/// A creature drawn from an **indexed pixel grid**.
///
/// ⭐ **Text, not geometry.** A creature is a list of strings, one per row,
/// each character naming a palette slot. That is diffable, reviewable, and
/// authorable — which hand-written bezier paths are not, and which is why
/// hand-coded `CustomPainter` creatures normally die on the vine.
///
/// ⭐ Same approach the mage sprite already uses, generalised. The three things
/// it hardcoded and this does not: the grid, the palette, and **the
/// dimensions** — 32×44 is the right box for a wizard and the wrong one for a
/// boar, a swarm, or a dome wider than it is tall.
///
/// ⚠️ **Silhouette is what reads.** At a display height of ~160px a 40-row
/// grid gives each pixel about 4 screen pixels; fine detail disappears. Author
/// for a strong outline and three or four tonal values, not for texture.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import 'element_style.dart';

/// The palette slots a creature grid may reference.
///
/// ⭐ Named by **role**, never by clothing — a Rootknuckle has no hat trim.
/// Filled from the element so one grid recoloured gives a whole family.
///
/// | Char | Slot |
/// |---|---|
/// | `b` | body — the main mass |
/// | `d` | body shade |
/// | `l` | body highlight |
/// | `a` | accent — horns, thorns, fungus, metal |
/// | `A` | accent shade |
/// | `o` | outline — near-black, and what makes a shape read at all |
/// | `e` | eye / void — the darkest value |
/// | `g` | glow — element-coloured, brightens with charge |
/// | `G` | glow highlight |
/// | `.` | empty |
@immutable
class SpritePalette {
  final Color body;
  final Color accent;
  final Color glow;

  const SpritePalette({
    required this.body,
    required this.accent,
    required this.glow,
  });

  /// ⭐ A palette derived from an element, so a creature's colours and its
  /// mechanics cannot disagree.
  factory SpritePalette.forElement(
    MagicElement element, {
    Color? body,
    Color? accent,
  }) {
    final c = elementStyles[element]!.color;
    return SpritePalette(
      // ⚠️ Contrast, not tint. A first pass lerped body toward the panel
      // colour and every creature came out the same mid-green lump — with
      // body and shade near-identical there was no internal form at all.
      body: body ?? Color.lerp(c, const Color(0xFF1A1428), 0.30)!,
      accent: accent ?? Color.lerp(c, const Color(0xFFFFFFFF), 0.45)!,
      glow: c,
    );
  }

  static Color _shade(Color c) => Color.lerp(c, const Color(0xFF000000), 0.48)!;
  static Color _light(Color c) => Color.lerp(c, const Color(0xFFFFFFFF), 0.38)!;

  Color? resolve(String ch) => switch (ch) {
    'b' => body,
    'd' => _shade(body),
    'l' => _light(body),
    'a' => accent,
    'A' => _shade(accent),
    'o' => const Color(0xFF120E1A),
    'e' => const Color(0xFF14101C),
    'g' => glow,
    'G' => _light(glow),
    _ => null,
  };
}

/// One creature's pixel art.
///
/// ⚠️ Rows must all be the same length — `creature_sprite_test.dart` asserts
/// it, because a ragged grid draws a torn silhouette rather than throwing.
@immutable
class CreatureArt {
  final List<String> grid;

  /// ⭐ Some creatures are wider than tall. Derived from [grid] rather than
  /// stored, so the two cannot disagree.
  int get rows => grid.length;
  int get cols => grid.isEmpty ? 0 : grid.first.length;

  const CreatureArt(this.grid);

  /// Aspect ratio, for laying the sprite out at a given height.
  double get aspect => rows == 0 ? 1 : cols / rows;
}

/// Draws a [CreatureArt] with a bob, a charge aura, and a defeat topple —
/// matching how the mage sprite behaves so the two read as one game.
class CreatureSprite extends StatefulWidget {
  final CreatureArt art;
  final SpritePalette palette;
  final int charge;
  final bool facingRight;
  final bool defeated;
  final double height;

  const CreatureSprite({
    super.key,
    required this.art,
    required this.palette,
    this.charge = 0,
    this.facingRight = true,
    this.defeated = false,
    this.height = 160,
  });

  @override
  State<CreatureSprite> createState() => _CreatureSpriteState();
}

class _CreatureSpriteState extends State<CreatureSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * widget.art.aspect;
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
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByDouble(widget.facingRight ? 1.0 : -1.0, 1.0, 1.0, 1.0),
        child: SizedBox(
          width: width,
          height: widget.height,
          child: CustomPaint(
            painter: CreaturePainter(
              art: widget.art,
              palette: widget.palette,
              charge: widget.charge,
            ),
          ),
        ),
      ),
    );
  }
}

class CreaturePainter extends CustomPainter {
  final CreatureArt art;
  final SpritePalette palette;
  final int charge;

  const CreaturePainter({
    required this.art,
    required this.palette,
    this.charge = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (art.rows == 0 || art.cols == 0) return;
    final cell = size.width / art.cols;
    final rowH = size.height / art.rows;
    final paint = Paint();

    // Charge aura behind the creature, as on the mage sprite.
    if (charge > 0) {
      paint.color = palette.glow.withValues(alpha: 0.06 * charge);
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.55),
        size.height * (0.26 + 0.04 * charge),
        paint,
      );
    }

    for (var y = 0; y < art.rows; y++) {
      final row = art.grid[y];
      for (var x = 0; x < art.cols && x < row.length; x++) {
        final ch = row[x];
        // ⭐ 'g' brightens with charge, so a charged creature visibly is one.
        final color = ch == 'g' && charge > 0
            ? Color.lerp(
                palette.glow,
                const Color(0xFFFFFFFF),
                (charge * 0.12).clamp(0.0, 0.6),
              )
            : palette.resolve(ch);
        if (color == null) continue;
        paint.color = color;
        // +0.5 closes the hairline seams between cells.
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * rowH, cell + 0.5, rowH + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CreaturePainter old) =>
      old.art != art || old.palette != palette || old.charge != charge;
}
