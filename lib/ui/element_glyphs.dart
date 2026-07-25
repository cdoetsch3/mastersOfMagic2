import 'package:flutter/material.dart';

/// Hand-drawn element glyphs for the two elements Material has no icon for.
///
/// Sanctus needs a halo and Umbra a demon; the icon set offers neither, and
/// the nearest stand-ins (`light_mode`, `dark_mode`) read as a second Solar and
/// a second Lunar. Everything else in this game is already drawn rather than
/// asset-loaded — the mage, the shields, the combat FX — so these are painted
/// the same way and scale cleanly to any size.

/// A halo: a ring seen in perspective, glowing, with nothing at its centre.
///
/// The hollow centre and the *elliptical* foreshortening are what keep it from
/// reading as a sun — Solar's glyph is a filled disc with radial rays, so a
/// hollow ring viewed at an angle can't be mistaken for it.
class HaloGlyphPainter extends CustomPainter {
  final Color color;

  const HaloGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Sits high in the box, the way a halo floats above a head.
    final center = Offset(w * 0.5, h * 0.46);
    final rx = w * 0.40, ry = h * 0.22;
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    // Soft bloom, so it glows rather than merely outlines.
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.19
        ..color = color.withValues(alpha: 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.07),
    );

    // The ring itself.
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..color = color,
    );

    // A brighter crown along the top arc — light catching the near edge.
    canvas.drawArc(
      rect.deflate(w * 0.004),
      3.34, // just past due-left, sweeping over the top
      2.24,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.05
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Three motes of light falling below it — enough to say "descending
    // blessing" without crowding the glyph at 16px.
    final mote = Paint()..color = color.withValues(alpha: 0.75);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.30 + i * 0.20), h * (0.80 + (i == 1 ? 0.06 : 0))),
        w * 0.045,
        mote,
      );
    }
  }

  @override
  bool shouldRepaint(HaloGlyphPainter old) => old.color != color;
}

/// A horned demon's head: the malevolent reading of shadow, not the physical
/// one. Curved horns, a heavy brow, and hollow eyes cut clean through.
///
/// Drawn as a single even-odd path so the eyes are true holes — they show the
/// background rather than a guessed fill colour, which keeps the glyph honest
/// on the dark arena, the light dialogs and the coloured chips alike.
class DemonGlyphPainter extends CustomPainter {
  final Color color;

  const DemonGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()..fillType = PathFillType.evenOdd;

    // Skull: a rounded cranium tapering to a narrow jaw.
    path.moveTo(w * 0.50, h * 0.22);
    path.cubicTo(w * 0.78, h * 0.22, w * 0.84, h * 0.44, w * 0.80, h * 0.60);
    path.cubicTo(w * 0.77, h * 0.74, w * 0.64, h * 0.86, w * 0.50, h * 0.92);
    path.cubicTo(w * 0.36, h * 0.86, w * 0.23, h * 0.74, w * 0.20, h * 0.60);
    path.cubicTo(w * 0.16, h * 0.44, w * 0.22, h * 0.22, w * 0.50, h * 0.22);
    path.close();

    // Horns sweeping up and outward, tapering to points.
    void horn(double dir) {
      final x = w * 0.5;
      path.moveTo(x + dir * w * 0.26, h * 0.30);
      path.quadraticBezierTo(
          x + dir * w * 0.50, h * 0.16, x + dir * w * 0.44, h * 0.02);
      path.quadraticBezierTo(
          x + dir * w * 0.30, h * 0.14, x + dir * w * 0.13, h * 0.22);
      path.close();
    }

    horn(-1);
    horn(1);

    // Eyes: angled slits, inner corners low, for a scowl.
    void eye(double dir) {
      final x = w * 0.5 + dir * w * 0.155;
      path.moveTo(x - dir * w * 0.10, h * 0.49);
      path.lineTo(x + dir * w * 0.09, h * 0.55);
      path.lineTo(x + dir * w * 0.05, h * 0.64);
      path.lineTo(x - dir * w * 0.08, h * 0.57);
      path.close();
    }

    eye(-1);
    eye(1);

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(DemonGlyphPainter old) => old.color != color;
}

/// Draws a painted glyph at [size] — the drop-in replacement for an [Icon].
class PaintedGlyph extends StatelessWidget {
  final CustomPainter Function(Color) painter;
  final double size;
  final Color color;

  const PaintedGlyph({
    super.key,
    required this.painter,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: painter(color)),
      );
}
