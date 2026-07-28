import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/element_style.dart';
import '../game/world.dart';
import '../game/world_map_geometry.dart';
import 'app_theme.dart';

/// Palette for the drawn world. Separate from [AppColors] because this is
/// *terrain*, not chrome — the map is a place, and it keeps its own light.
abstract final class MapColors {
  static const sea = Color(0xFF3E7C94);
  static const seaLine = Color(0xFF8FC0D2);
  static const land = Color(0xFF93B26E);
  static const coast = Color(0xFF28402F);
  static const shelf = Color(0xFFD3C296);
  static const basin = Color(0xFF71A057);
  static const marsh = Color(0xFF5C8C5D);
  static const desert = Color(0xFFE6CD8E);
  static const desertHi = Color(0xFFDFC48B);
  static const dune = Color(0xFFB08843);
  static const shadow = Color(0xFF47536E);
  static const volcanic = Color(0xFF8E6353);
  static const caldera = Color(0xFF6E4438);
  static const ice = Color(0xFFDFE9F0);
  static const iceDeep = Color(0xFFA2B3C8);
  static const iceShelf = Color(0xFFBFD3DF);
  static const crack = Color(0xFF8CA4BB);
  static const water = Color(0xFF3F86AC);
  static const waterHi = Color(0xFF5AA3C6);
  static const treeDark = Color(0xFF2F5E3A);
  static const treeLight = Color(0xFF4C8848);
  static const ashDark = Color(0xFF463C34);
  static const ashLight = Color(0xFF665545);
  static const rock = Color(0xFF7E7166);
  static const rockEdge = Color(0xFF3F362F);
  static const scarpRock = Color(0xFF8C7C67);
  static const snowRock = Color(0xFFC6D4E2);
  static const snowRockHi = Color(0xFFD3DFEA);
  static const snowEdge = Color(0xFF5A6C7E);
  static const snow = Color(0xFFF6FAFF);
  static const road = Color(0xFFF4E9C8);

  // The void above the Veil — its own world, deliberately unlike the sea.
  static const void_ = Color(0xFF140C28);
  static const voidBand = Color(0xFF2A1440);
  static const star = Color(0xFFCBB8F0);
  static const isle = Color(0xFF2E2050);
  static const isleEdge = Color(0xFF6B4C9E);
  static const veil = Color(0xFFD65AB8);
}

/// The single capitalisation rule for anything written on the map.
///
/// ⚠️ Place pins and named geography are drawn by different code paths, and
/// applying this to only one of them left the map in two voices for four
/// rounds of review. One function, used by both, guarded by a test.
String mapLabelFor(String name) =>
    name.replaceFirst(RegExp(r'^The '), '').toUpperCase();

/// The world, drawn.
///
/// ⭐ **No image assets.** Coastline is one path, biomes are noise-shaped
/// curves, and forests, ranges and dunes are scattered from a fixed seed — so
/// the same world is drawn every launch, and the whole map is `Path` and
/// `drawPath`, consistent with the rest of the game's art.
///
/// The scatter is computed once and cached: it is deterministic, so there is no
/// reason to pay for it on every frame.
class WorldMapPainter extends CustomPainter {
  /// Where the player is now — gold ring.
  final String? currentId;

  /// Places reachable from [currentId] — teal ring.
  final Set<String> reachable;

  /// Places the player has been. Everything else is dimmed.
  final Set<String> seen;

  /// Highlighted by a tap, if any.
  final String? selectedId;

  /// Below this the pins and labels are dropped — a thumbnail wants terrain,
  /// not thirty-two names it has no room for.
  final bool showPins;

  /// Labels for the named geography (ranges, rivers, seas).
  final bool showFeatureLabels;

  const WorldMapPainter({
    this.currentId,
    this.reachable = const {},
    this.seen = const {},
    this.selectedId,
    this.showPins = true,
    this.showFeatureLabels = true,
  });

  // ---- cached procedural scatter --------------------------------------
  static final List<Offset> _forest = WorldMapGeometry.scatter(
    Random(11),
    360,
    1218,
    206,
    172,
    124,
  );
  static final List<Offset> _ashwood = WorldMapGeometry.scatter(
    Random(12),
    298,
    1110,
    72,
    46,
    18,
  );
  static final List<Offset> _dunes = WorldMapGeometry.scatter(
    Random(13),
    802,
    678,
    154,
    136,
    32,
  );
  static final List<Offset> _dunes2 = WorldMapGeometry.scatter(
    Random(14),
    842,
    514,
    96,
    84,
    14,
  );
  static final List<Offset> _cracks = WorldMapGeometry.scatter(
    Random(15),
    474,
    208,
    248,
    208,
    34,
  );
  static final List<Offset> _stars = WorldMapGeometry.scatter(
    Random(16),
    500,
    -195,
    620,
    130,
    90,
  );
  static final _spine = WorldMapGeometry.rangeField(
    WorldMapGeometry.ironspine,
    112,
    48,
    11,
    31,
    seed: 21,
  );
  static final _scarp = WorldMapGeometry.rangeField(
    WorldMapGeometry.scarp,
    48,
    27,
    10,
    25,
    seed: 22,
  );
  static final _vaultA = WorldMapGeometry.rangeField(
    WorldMapGeometry.vaultOuter,
    78,
    42,
    12,
    35,
    seed: 23,
  );
  static final _vaultB = WorldMapGeometry.rangeField(
    WorldMapGeometry.vaultInner,
    46,
    27,
    16,
    43,
    seed: 24,
  );
  static final Path _coast = WorldMapGeometry.coastline();

  @override
  void paint(Canvas canvas, Size size) {
    final b = WorldMapGeometry.bounds;
    canvas.save();
    canvas.scale(size.width / b.width);
    canvas.translate(-b.left, -b.top);

    _paintVoid(canvas);
    _paintSea(canvas);
    canvas.drawPath(_coast, Paint()..color = MapColors.land);
    canvas.save();
    canvas.clipPath(_coast);
    _paintBiomes(canvas);
    _paintScatter(canvas);
    // ⚠️ Ranges first, then water. Painting peaks last put mountains *inside*
    // Lake Mirrormere — the spine's scatter band reaches that far east.
    _paintRanges(canvas);
    _paintWater(canvas);
    canvas.restore();
    canvas.drawPath(
      _coast,
      Paint()
        ..color = MapColors.coast
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    _paintVeil(canvas);
    if (showFeatureLabels) _paintFeatureLabels(canvas);
    _paintRoads(canvas);
    if (showPins) _paintPins(canvas);
    canvas.restore();
  }

  // ---- layers ---------------------------------------------------------

  void _paintVoid(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(-70, -330, 1150, 270),
      Paint()..color = MapColors.void_,
    );
    final star = Paint()..color = MapColors.star.withValues(alpha: 0.75);
    for (final s in _stars) {
      if (s.dy > WorldMapGeometry.veilY - 12) continue;
      canvas.drawCircle(s, 1.4, star);
    }
    canvas.drawRect(
      const Rect.fromLTWH(-70, -64, 1150, 18),
      Paint()..color = MapColors.voidBand.withValues(alpha: 0.9),
    );
    // The three Arcane places hang here, off the world entirely.
    for (final isle in const [
      (474.0, -132.0, 150.0, 30.0),
      (606.0, -186.0, 132.0, 26.0),
      (726.0, -148.0, 140.0, 28.0),
    ]) {
      final (cx, cy, rx, ry) = isle;
      final p = Path()
        ..moveTo(cx - rx, cy)
        ..cubicTo(
          cx - rx * .6,
          cy - ry * 1.5,
          cx + rx * .4,
          cy - ry * 1.8,
          cx + rx,
          cy,
        )
        ..cubicTo(
          cx + rx * .5,
          cy + ry * 2.4,
          cx - rx * .4,
          cy + ry * 2.8,
          cx - rx,
          cy,
        )
        ..close();
      canvas.drawPath(p, Paint()..color = MapColors.isle);
      canvas.drawPath(
        p,
        Paint()
          ..color = MapColors.isleEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _paintSea(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(-70, -52, 1150, 1610),
      Paint()..color = MapColors.sea,
    );
    final line = Paint()
      ..color = MapColors.seaLine.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var y = -40.0; y < 1560; y += 20) {
      for (var x = -70.0; x < 1080; x += 30) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y + 13)
            ..quadraticBezierTo(x + 7.5, y + 7.5, x + 15, y + 13)
            ..quadraticBezierTo(x + 22.5, y + 18.5, x + 30, y + 13),
          line,
        );
      }
    }
  }

  void _paintBiomes(Canvas canvas) {
    void blob(
      double cx,
      double cy,
      double rx,
      double ry,
      Color c, {
      double rough = .2,
      int seed = 1,
      double alpha = 1,
    }) {
      canvas.drawPath(
        WorldMapGeometry.region(cx, cy, rx, ry, rough: rough, seed: seed),
        Paint()..color = c.withValues(alpha: alpha),
      );
    }

    blob(712, 608, 338, 296, MapColors.shelf, rough: .17, seed: 31);
    blob(380, 1216, 256, 220, MapColors.basin, rough: .19, seed: 32);
    blob(332, 1384, 126, 76, MapColors.marsh, rough: .26, seed: 33);
    blob(802, 678, 172, 156, MapColors.desert, rough: .21, seed: 34);
    blob(842, 514, 110, 100, MapColors.desertHi, rough: .24, seed: 35);
    blob(704, 480, 134, 80, MapColors.shadow, rough: .22, seed: 36, alpha: .6);
    blob(372, 1080, 102, 76, MapColors.volcanic, rough: .24, seed: 37);
    blob(358, 1092, 56, 38, MapColors.caldera, rough: .3, seed: 38);
    blob(474, 208, 278, 238, MapColors.ice, rough: .15, seed: 39);
    blob(
      430,
      154,
      146,
      102,
      MapColors.iceDeep,
      rough: .22,
      seed: 40,
      alpha: .68,
    );
    blob(248, 442, 92, 64, MapColors.iceShelf, rough: .25, seed: 41, alpha: .8);
  }

  void _paintScatter(Canvas canvas) {
    void tree(Offset o, double s, Color dark, Color light) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - s * 1.8)
          ..lineTo(o.dx + s, o.dy)
          ..lineTo(o.dx - s, o.dy)
          ..close(),
        Paint()..color = dark,
      );
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - s * 1.2)
          ..lineTo(o.dx + s * .6, o.dy + s * .28)
          ..lineTo(o.dx - s * .6, o.dy + s * .28)
          ..close(),
        Paint()..color = light.withValues(alpha: 0.8),
      );
    }

    final forest = [..._forest]..sort((a, b) => a.dy.compareTo(b.dy));
    for (final o in forest) {
      tree(o, 5 + (o.dx % 7) * 0.5, MapColors.treeDark, MapColors.treeLight);
    }
    for (final o in _ashwood) {
      tree(o, 5 + (o.dy % 5) * 0.6, MapColors.ashDark, MapColors.ashLight);
    }
    final dune = Paint()
      ..color = MapColors.dune.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final o in [..._dunes, ..._dunes2]) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..quadraticBezierTo(o.dx + 17, o.dy - 8, o.dx + 34, o.dy),
        dune,
      );
    }
    final crack = Paint()
      ..color = MapColors.crack.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _cracks.length; i++) {
      final o = _cracks[i];
      final a = (i * 2.399) % (pi * 2);
      canvas.drawLine(o, o + Offset(cos(a) * 22, sin(a) * 22), crack);
    }
  }

  void _paintWater(Canvas canvas) {
    Paint w(double width) => Paint()
      ..color = MapColors.water
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final s in WorldMapGeometry.streams()) {
      canvas.drawPath(s, w(3.4)..color = const Color(0xFF4A90B4));
    }
    canvas.drawPath(WorldMapGeometry.ironrun(), w(6));
    canvas.drawPath(WorldMapGeometry.mirrorfall(), w(5.5));
    canvas.drawPath(WorldMapGeometry.concord(), w(9));
    canvas.drawPath(WorldMapGeometry.glimmerbrook(), w(7));
    canvas.drawCircle(
      WorldMapGeometry.confluence,
      7,
      Paint()..color = MapColors.water,
    );
    canvas.drawPath(
      WorldMapGeometry.region(520, 500, 58, 36, rough: .3, seed: 51, n: 30),
      Paint()..color = MapColors.water,
    );
    canvas.drawPath(
      WorldMapGeometry.region(519, 497, 45, 25, rough: .3, seed: 52, n: 30),
      Paint()..color = MapColors.waterHi.withValues(alpha: 0.7),
    );
  }

  void _paintRanges(Canvas canvas) {
    void peaks(
      List<({Offset at, double size})> field,
      Color fill,
      Color edge, {
      bool snowy = false,
    }) {
      for (final m in field) {
        final x = m.at.dx, y = m.at.dy, s = m.size, h = s * 1.35;
        final tri = Path()
          ..moveTo(x - s, y)
          ..lineTo(x, y - h)
          ..lineTo(x + s, y)
          ..close();
        canvas.drawPath(tri, Paint()..color = fill);
        canvas.drawPath(
          tri,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.2, s * .09)
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          Path()
            ..moveTo(x, y - h)
            ..lineTo(x + s * .5, y)
            ..lineTo(x, y)
            ..close(),
          Paint()..color = Colors.black.withValues(alpha: 0.17),
        );
        if (snowy && s > 13) {
          final c = h * .34;
          canvas.drawPath(
            Path()
              ..moveTo(x - c * .72, y - h + c)
              ..lineTo(x, y - h)
              ..lineTo(x + c * .72, y - h + c)
              ..lineTo(x + c * .3, y - h + c * .72)
              ..lineTo(x, y - h + c * 1.05)
              ..lineTo(x - c * .34, y - h + c * .66)
              ..close(),
            Paint()..color = MapColors.snow.withValues(alpha: 0.93),
          );
        }
      }
    }

    peaks(_spine, MapColors.rock, MapColors.rockEdge);
    peaks(_scarp, MapColors.scarpRock, MapColors.rockEdge);
    peaks(_vaultA, MapColors.snowRock, MapColors.snowEdge, snowy: true);
    peaks(_vaultB, MapColors.snowRockHi, MapColors.snowEdge, snowy: true);
  }

  void _paintVeil(Canvas canvas) {
    final p = Path()
      ..moveTo(-70, -60)
      ..cubicTo(120, -74, 300, -46, 480, -60)
      ..cubicTo(660, -74, 840, -46, 1080, -58);
    canvas.drawPath(
      _dash(p, 14, 10),
      Paint()
        ..color = MapColors.veil
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _paintRoads(Canvas canvas) {
    final drawn = <String>{};
    for (final loc in World.locations) {
      final a = WorldMapGeometry.positions[loc.id];
      if (a == null) continue;
      for (final id in loc.connections) {
        final key = ([loc.id, id]..sort()).join('|');
        if (!drawn.add(key)) continue;
        final b = WorldMapGeometry.positions[id];
        if (b == null) continue;
        final open = loc.id == currentId || id == currentId;
        if (open) {
          canvas.drawLine(
            a,
            b,
            Paint()
              ..color = AppColors.teal
              ..strokeWidth = 6.5
              ..strokeCap = StrokeCap.round,
          );
        } else {
          canvas.drawPath(
            _dash(
              Path()
                ..moveTo(a.dx, a.dy)
                ..lineTo(b.dx, b.dy),
              13,
              9,
            ),
            Paint()
              ..color = MapColors.road.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  void _paintPins(Canvas canvas) {
    for (final loc in World.locations) {
      final at = WorldMapGeometry.positions[loc.id];
      if (at == null) continue;
      final isHere = loc.id == currentId;
      final open = reachable.contains(loc.id);
      final dim = !isHere && !open && !seen.contains(loc.id);
      final r = loc.isTown ? 13.0 : 12.0;

      if (isHere || open || loc.id == selectedId) {
        canvas.drawCircle(
          at,
          21,
          Paint()
            ..color = isHere ? AppColors.gold : AppColors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHere ? 5 : 4,
        );
      }
      final alpha = dim ? 0.5 : 1.0;
      final edge = Paint()
        ..color = AppColors.bg.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      if (loc.isTown) {
        final rect = Rect.fromCircle(center: at, radius: r);
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.rotate(pi / 4);
        canvas.translate(-at.dx, -at.dy);
        canvas.drawRect(
          rect,
          Paint()..color = const Color(0xFFF4EFE2).withValues(alpha: alpha),
        );
        canvas.drawRect(rect, edge);
        canvas.restore();
      } else if (loc.id == 'the_eclipsed_citadel') {
        canvas.drawCircle(
          at,
          r + 3,
          Paint()..color = AppColors.gem.withValues(alpha: alpha),
        );
        canvas.drawCircle(at, r + 3, edge);
      } else if (loc.elements.length == 2) {
        for (final (i, e) in loc.elements.indexed) {
          canvas.drawPath(
            Path()
              ..moveTo(at.dx, at.dy - r)
              ..arcToPoint(
                Offset(at.dx, at.dy + r),
                radius: Radius.circular(r),
                clockwise: i == 0,
              )
              ..close(),
            Paint()..color = elementStyles[e]!.color.withValues(alpha: alpha),
          );
        }
        canvas.drawCircle(at, r, edge);
      } else {
        final c = loc.elements.isEmpty
            ? const Color(0xFFB9A9D6)
            : elementStyles[loc.elements.first]!.color;
        canvas.drawCircle(at, r, Paint()..color = c.withValues(alpha: alpha));
        canvas.drawCircle(at, r, edge);
      }
      if (isHere) {
        canvas.drawCircle(at, 4.5, Paint()..color = AppColors.gold);
      }
      // Only label what matters now — 32 names at once is unreadable.
      if (loc.isTown || open || isHere) {
        _label(
          canvas,
          mapLabelFor(loc.name),
          Offset(at.dx, at.dy - 21),
          size: loc.isTown ? 21 : 18,
          color: const Color(0xFF141021),
          halo: const Color(0xFFFBF6E9),
          bold: true,
        );
      }
    }
  }

  /// Ink and halo for each tone, so a label always reads against its ground.
  static const _tones = <MapLabelTone, (Color, Color)>{
    MapLabelTone.land: (Color(0xFF25412E), Color(0xFFF2EBD8)),
    MapLabelTone.cold: (Color(0xFF3B4E63), Color(0xFFEDF3F8)),
    MapLabelTone.dry: (Color(0xFF7A5A1E), Color(0xFFF6EBCE)),
    MapLabelTone.warm: (Color(0xFF6E3524), Color(0xFFF4E3D6)),
    MapLabelTone.sea: (Color(0xFFEAF4F8), Color(0xFF2C6076)),
    MapLabelTone.river: (Color(0xFFDCF0FA), Color(0xFF255A75)),
    MapLabelTone.beyond: (Color(0xFFEBD9FF), MapColors.void_),
    MapLabelTone.veil: (Color(0xFFF0BCE6), Color(0xFF3A1030)),
  };

  void _paintFeatureLabels(Canvas canvas) {
    for (final l in WorldMapGeometry.featureLabels) {
      final (ink, halo) = _tones[l.tone]!;
      if (l.rotation != 0) {
        canvas.save();
        canvas.translate(l.at.dx, l.at.dy);
        canvas.rotate(l.rotation);
        _label(
          canvas,
          l.text,
          Offset.zero,
          size: l.size,
          color: ink,
          halo: halo,
          bold: true,
          tracking: l.tracking,
        );
        canvas.restore();
      } else {
        _label(
          canvas,
          l.text,
          l.at,
          size: l.size,
          color: ink,
          halo: halo,
          bold: true,
          tracking: l.tracking,
        );
      }
    }
  }

  // ---- helpers --------------------------------------------------------

  /// Text with a halo, so a label stays readable wherever it crosses a border.
  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required double size,
    required Color color,
    required Color halo,
    bool bold = false,
    double tracking = 0,
  }) {
    for (final pass in [halo, color]) {
      final isHalo = pass == halo;
      final b =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.center,
                fontSize: size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: isHalo ? null : pass,
                letterSpacing: tracking,
                foreground: isHalo
                    ? (Paint()
                        ..color = pass
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = size * 0.24
                        ..strokeJoin = StrokeJoin.round)
                    : null,
              ),
            )
            ..addText(text);
      final p = b.build()..layout(const ui.ParagraphConstraints(width: 600));
      canvas.drawParagraph(p, Offset(at.dx - 300, at.dy - size * 0.9));
    }
  }

  /// Flutter has no dash support on Path — walk the metric and emit segments.
  Path _dash(Path src, double on, double off) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, min(d + on, m.length)), Offset.zero);
        d += on + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(WorldMapPainter old) =>
      old.currentId != currentId ||
      old.selectedId != selectedId ||
      old.showPins != showPins ||
      old.showFeatureLabels != showFeatureLabels ||
      old.reachable.length != reachable.length ||
      old.seen.length != seen.length;
}
