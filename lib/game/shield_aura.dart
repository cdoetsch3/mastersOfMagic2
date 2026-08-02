import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How many shield points one ring can represent before a second ring starts.
const int shieldPointsPerRing = 100;

/// Stroke width, in logical pixels, per point of shield — at [auraReferenceHeight].
/// A Ward (~15) is a 3px hairline; a Sanctuary (~75) is a 15px wall.
const double shieldPxPerPoint = 0.2;

/// The sprite height these pixel figures were tuned against. Strokes scale with
/// the actual sprite so a Sanctuary reads the same weight on every screen size,
/// rather than looking chunky on a phone and thin on a desktop.
const double auraReferenceHeight = 150;

/// Splits a shield total into concentric rings of at most [shieldPointsPerRing].
///
/// Returned innermost-first, so the **last** entry is the partial ring — and it
/// is drawn outermost, because damage eats the outside first. 120 → `[100, 20]`;
/// a 40-point hit on that leaves 80 → `[80]`, the small ring having vanished.
///
/// Nothing in the game rolls above 100 today (Sanctuary tops out at 85), so this
/// only starts producing multiple rings once shield-boosting equipment lands.
List<int> shieldRings(int remaining) {
  if (remaining <= 0) return const [];
  final rings = <int>[];
  var left = remaining;
  while (left > 0) {
    rings.add(math.min(left, shieldPointsPerRing));
    left -= shieldPointsPerRing;
  }
  return rings;
}

/// Draws a mage's defences: the elemental shield as one or more rings whose
/// stroke thickness tracks the points **remaining** (so a failing shield visibly
/// thins), and outside them one thin beaded white ring per Barrier point.
///
/// Barriers are deliberately colourless — anything pops a point, so there is no
/// counter maths to communicate — while a shield always wears its element.
class ShieldAuraPainter extends CustomPainter {
  /// The shield's element colour, or null when no shield stands.
  final Color? shieldColor;

  /// Shield points left. Drives both the ring count and their thickness.
  final int shieldRemaining;

  /// Barrier points (0–3), each drawn as its own beaded ring.
  final int barrierPoints;

  /// The mage sprite's height, used to scale the aura with the sprite.
  final double spriteHeight;

  const ShieldAuraPainter({
    required this.shieldColor,
    required this.shieldRemaining,
    required this.barrierPoints,
    required this.spriteHeight,
  });

  static const Color _barrier = Color(0xFFEAF2FF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = spriteHeight / auraReferenceHeight;

    // The innermost shield ring hugs the sprite; everything else stacks outward.
    var rx = spriteHeight * 0.49;
    var ry = spriteHeight * 0.56;

    final rings = shieldColor == null
        ? const <int>[]
        : shieldRings(shieldRemaining);
    for (var i = 0; i < rings.length; i++) {
      final stroke = rings[i] * shieldPxPerPoint * scale;

      // Only the innermost ring carries the faint elemental wash, so a stack
      // doesn't wind up several washes deep.
      if (i == 0) {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
          Paint()..color = shieldColor!.withValues(alpha: 0.09),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = shieldColor!.withValues(alpha: 0.82),
      );

      // Step past this ring's stroke, leave a gap, then make room for the next
      // ring's stroke — measuring from centre-line to centre-line.
      rx += stroke / 2 + 7 * scale;
      ry += stroke / 2 + 8 * scale;
      if (i < rings.length - 1) {
        final next = rings[i + 1] * shieldPxPerPoint * scale;
        rx += next / 2;
        ry += next / 2;
      }
    }

    for (var i = 0; i < barrierPoints; i++) {
      _beadedRing(
        canvas,
        center,
        rx + (8 + i * 12) * scale,
        ry + (9 + i * 13) * scale,
        // Outer rings fade slightly so the count reads as depth, not noise.
        1.0 - i * 0.2,
        scale,
      );
    }
  }

  /// A thin white ring with beads set on it — chosen over dashes or hatching
  /// because a bead stays legible when the aura shrinks, where a gap does not.
  void _beadedRing(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    double opacity,
    double scale,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * scale
        ..color = _barrier.withValues(alpha: 0.85 * opacity),
    );
    const beads = 12;
    final dot = Paint()..color = _barrier.withValues(alpha: opacity);
    for (var b = 0; b < beads; b++) {
      final t = (b / beads) * 2 * math.pi - math.pi / 2;
      canvas.drawCircle(
        Offset(c.dx + math.cos(t) * rx, c.dy + math.sin(t) * ry),
        2.3 * scale,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(ShieldAuraPainter old) =>
      old.shieldColor != shieldColor ||
      old.shieldRemaining != shieldRemaining ||
      old.barrierPoints != barrierPoints ||
      old.spriteHeight != spriteHeight;
}
