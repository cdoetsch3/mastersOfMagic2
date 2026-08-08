import 'dart:math';
import 'dart:ui';

/// Where the world is *drawn*.
///
/// Kept apart from [World] on purpose: that file owns the graph — what connects
/// to what — and this one owns the picture. A place can move on the map without
/// its roads changing, and vice versa.
///
/// ⭐ **Everything here is procedural and seeded**, so there are no image
/// assets: the coastline is one path, biome boundaries are noise-shaped closed
/// curves, and the forests, ranges and dunes are scattered from a fixed seed.
/// The same seed draws the same world every launch.
///
/// Source drawing: `docs/plates/plate-1b-one-crossing.html` and the region-map
/// design pass. Coordinates share Plate I-b's space, so the two never disagree.
/// How a named feature is inked — each biome gets its own tint so a label
/// never fights the ground it sits on.
enum MapLabelTone { land, cold, dry, warm, sea, river, beyond, veil }

/// A named piece of geography.
///
/// ⭐ **Data, not code.** These used to be a run of `feat(...)` calls buried in
/// the painter, where a formatter reflow could silently defeat an edit — twice.
/// As a list they can be checked by tests: capitalisation, overlap, and staying
/// on the canvas are all now assertions rather than eyeballing.
class MapLabel {
  final String text;
  final Offset at;
  final MapLabelTone tone;
  final double size;
  final double tracking;

  /// Radians. Only the Western Ocean uses this — the strip it names is far too
  /// narrow to take the words across.
  final double rotation;

  const MapLabel(
    this.text,
    this.at,
    this.tone, {
    this.size = 27,
    this.tracking = 7,
    this.rotation = 0,
  });

  /// Rough drawn width, for collision checks.
  double get width => text.length * (size * 0.58 + tracking);
}

abstract final class WorldMapGeometry {
  /// ⚠️ **Every label is ALL CAPS**, enforced by `world_map_test.dart`. Mixed
  /// case and a lower-case "the" made the map read as three different maps.
  /// ⚠️ **Every label is ALL CAPS**, and no label names something a *pin*
  /// already names. Both are enforced by `world_map_test.dart`, which also
  /// checks that none of them overlap each other, sit on a pin, or run off the
  /// canvas — every one of those faults shipped at least once by eye.
  static const List<MapLabel> featureLabels = [
    MapLabel('THE EMPYREAN', Offset(300, -250), MapLabelTone.beyond),
    MapLabel(
      'THE VEIL',
      Offset(860, -78),
      MapLabelTone.veil,
      size: 17,
      tracking: 5,
    ),
    MapLabel('THE VAULT', Offset(644, 206), MapLabelTone.cold),
    MapLabel(
      'THE MERIDIAN SCARP',
      Offset(880, 598),
      MapLabelTone.dry,
      size: 21,
      tracking: 5,
    ),
    MapLabel('THE KILN DESERT', Offset(792, 792), MapLabelTone.dry),
    // ⚠️ Moved south when the Kinetic block moved up — at y 700 it sat on
    // Forgeholm, Galehaven and Windward Steppe at once.
    MapLabel('THE IRONSPINE', Offset(292, 1096), MapLabelTone.land, size: 24),
    MapLabel('THE VERDANT BASIN', Offset(352, 1306), MapLabelTone.land),
    MapLabel('CINDERLANDS', Offset(760, 940), MapLabelTone.warm),
    MapLabel(
      'RIVER CONCORD',
      Offset(646, 1178),
      MapLabelTone.river,
      size: 19,
      tracking: 4,
    ),
    // ⚠️ No label for LAKE MIRRORMERE, THE SUNLESS REACH or THE RIME SHELF.
    // The first two are *places* whose pins already name them — stacking a
    // second name on one spot is what made this quarter unreadable — and the
    // third had nowhere to sit without crossing the coast or a pin. Fewer,
    // well-placed names beat more crowded ones.
    MapLabel(
      'THE IRONRUN',
      Offset(500, 560),
      MapLabelTone.river,
      size: 16,
      tracking: 3,
    ),
    MapLabel(
      'THE MIRRORFALL',
      Offset(620, 620),
      MapLabelTone.river,
      size: 16,
      tracking: 3,
    ),
    MapLabel('THE SOUTHERN SHALLOWS', Offset(560, 1470), MapLabelTone.sea),
    MapLabel(
      'WESTERN OCEAN',
      Offset(30, 700),
      MapLabelTone.sea,
      tracking: 8,
      rotation: -pi / 2,
    ),
  ];

  /// The drawn area, including the void band above the world.
  static const Rect bounds = Rect.fromLTWH(-70, -330, 1150, 1890);

  /// Where the Veil sits — the border between the world and the Empyrean.
  static const double veilY = -60;

  /// Map position of every place, campaign order.
  static const Map<String, Offset> positions = {
    'hearthwood': Offset(424, 1274),
    'whispering_woods': Offset(296, 1212),
    'glimmerbrook': Offset(556, 1256),
    'thornmire': Offset(326, 1376),
    'cinderpeak_foothills': Offset(690, 1104),
    'ashfall_vale': Offset(762, 1014),
    'pennycross': Offset(598, 1096),
    // ⭐ **The north road climbs the range's southern toe and goes IN.**
    // Pennycross used to be one hop from the Kinetic quarter.
    'the_bellows_gap': Offset(470, 1004),
    'the_charring_yards': Offset(392, 876),
    // ⚠️ **Forgeholm sits ON `ironspine`, at roughly its middle** — the town
    // is cut into the mountain, not parked at its foot, and `world_map_test`
    // asserts the first half of that. The whole Kinetic block was moved up
    // around it; it used to sit at the range's southern tip.
    'forgeholm': Offset(346, 748),
    'old_quarry': Offset(462, 846),
    'stormcliff_coast': Offset(206, 810),
    'galehaven': Offset(186, 700),
    'windward_steppe': Offset(470, 700),
    'frostfell_pass': Offset(330, 570),
    'thunderspire_peaks': Offset(300, 650),
    'the_molten_deep': Offset(826, 912),
    'concordance': Offset(556, 712),
    'the_kiln_desert': Offset(766, 672),
    'the_mirrormere': Offset(520, 508),
    'starfall_basin': Offset(838, 540),
    'meridian': Offset(652, 574),
    'tidewrack_shoals': Offset(238, 468),
    'the_sunless_reach': Offset(760, 466),
    'the_shattered_orrery': Offset(826, 430),
    'rimeholt': Offset(472, 398),
    'hallowmarch': Offset(444, 330),
    'the_umbral_wastes': Offset(388, 124),
    'the_reliquary_deep': Offset(416, 238),
    'vespergate': Offset(556, 286),
    // ⭐ The three late zones are pushed into the empty north rather than
    // packed around the Vault — the centre of this map is crowded enough.
    'the_sealed_garden': Offset(230, 270),
    'the_buried_sky': Offset(710, 150),
    'the_glass_archive': Offset(850, 260),
    'the_collapsed_academy': Offset(726, -148),
    'the_unwritten_library': Offset(606, -186),
    'the_eclipsed_citadel': Offset(474, -132),
    'zenith': Offset(474, 152),
  };

  // ---- terrain -------------------------------------------------------

  /// The continent. One path, hand-drawn once.
  static Path coastline() => Path()
    ..moveTo(214, 118)
    ..cubicTo(250, 90, 300, 70, 360, 58)
    ..cubicTo(420, 46, 470, 38, 520, 34)
    ..cubicTo(580, 30, 640, 42, 700, 64)
    ..cubicTo(760, 86, 810, 112, 856, 150)
    ..cubicTo(900, 190, 924, 250, 932, 316)
    ..cubicTo(940, 390, 918, 470, 906, 540)
    ..cubicTo(894, 610, 926, 690, 938, 762)
    ..cubicTo(950, 834, 918, 918, 884, 996)
    ..cubicTo(850, 1074, 812, 1140, 762, 1206)
    ..cubicTo(712, 1272, 660, 1320, 596, 1358)
    ..cubicTo(532, 1396, 470, 1418, 412, 1424)
    ..cubicTo(354, 1430, 300, 1414, 262, 1382)
    ..cubicTo(224, 1350, 204, 1300, 192, 1246)
    ..cubicTo(180, 1192, 178, 1140, 170, 1088)
    ..cubicTo(162, 1036, 140, 986, 146, 932)
    ..cubicTo(152, 878, 178, 846, 190, 806)
    ..cubicTo(196, 786, 188, 772, 196, 752)
    ..cubicTo(206, 726, 168, 690, 160, 646)
    ..cubicTo(152, 602, 172, 556, 186, 510)
    ..cubicTo(200, 470, 176, 456, 210, 436)
    ..cubicTo(244, 416, 196, 344, 194, 268)
    ..cubicTo(192, 196, 196, 140, 214, 118)
    ..close();

  /// ⚠️ **Not an ellipse.** A biome edge modulated by five octaves of sine
  /// noise and smoothed through Catmull-Rom — real boundaries follow ridges and
  /// water, and a circle reads as a colour blob rather than a region.
  static Path region(
    double cx,
    double cy,
    double rx,
    double ry, {
    double rough = 0.20,
    int seed = 1,
    int n = 54,
  }) {
    final rnd = Random(seed);
    const freqs = [2, 3, 5, 9, 17];
    const weights = [1.0, 0.7, 0.45, 0.26, 0.13];
    final phase = [
      for (var i = 0; i < freqs.length; i++) rnd.nextDouble() * pi * 2,
    ];
    final total = weights.reduce((a, b) => a + b);
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = i / n * pi * 2;
      var sum = 0.0;
      for (var f = 0; f < freqs.length; f++) {
        sum += weights[f] * sin(freqs[f] * a + phase[f]);
      }
      final m = 1 + rough * sum / total;
      pts.add(Offset(cx + cos(a) * rx * m, cy + sin(a) * ry * m));
    }
    return _smoothClosed(pts);
  }

  static Path _smoothClosed(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < p.length; i++) {
      final p0 = p[(i - 1 + p.length) % p.length];
      final p1 = p[i];
      final p2 = p[(i + 1) % p.length];
      final p3 = p[(i + 2) % p.length];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path..close();
  }

  /// Points inside an ellipse, thinned toward the rim so edges feel soft.
  static List<Offset> scatter(
    Random rnd,
    double cx,
    double cy,
    double rx,
    double ry,
    int n,
  ) {
    return [
      for (var i = 0; i < n; i++)
        () {
          final a = rnd.nextDouble() * pi * 2;
          final d = sqrt(rnd.nextDouble()) * 0.94;
          return Offset(cx + cos(a) * rx * d, cy + sin(a) * ry * d);
        }(),
    ];
  }

  /// A **band** of peaks around a spine, sized largest mid-chain and along the
  /// centre line, sorted so far ridges draw first.
  ///
  /// ⚠️ A single row of same-size chevrons reads as a path of arrows, not a
  /// mountain range — the size variation and the overlap are what sell it.
  static List<({Offset at, double size})> rangeField(
    List<Offset> spine,
    int n,
    double half,
    double minS,
    double maxS, {
    int seed = 7,
  }) {
    final rnd = Random(seed);
    final out = <({Offset at, double size})>[];
    for (var i = 0; i < n; i++) {
      final t = ((i + rnd.nextDouble() * 0.7) / n).clamp(0.0, 0.999);
      final (p, ang) = _along(spine, t);
      final off = rnd.nextDouble() * 2 - 1;
      final at = Offset(
        p.dx - sin(ang) * off * half,
        p.dy + cos(ang) * off * half,
      );
      var s =
          minS + (maxS - minS) * (sin(pi * t) * 0.7 + (1 - off.abs()) * 0.3);
      s *= 0.85 + rnd.nextDouble() * 0.32;
      out.add((at: at, size: s));
    }
    out.sort((a, b) => a.at.dy.compareTo(b.at.dy));
    return out;
  }

  static (Offset, double) _along(List<Offset> poly, double t) {
    var total = 0.0;
    final segs = <double>[];
    for (var i = 0; i < poly.length - 1; i++) {
      final d = (poly[i + 1] - poly[i]).distance;
      segs.add(d);
      total += d;
    }
    var want = t * total, acc = 0.0;
    for (var i = 0; i < segs.length; i++) {
      if (acc + segs[i] >= want) {
        final u = segs[i] == 0 ? 0.0 : (want - acc) / segs[i];
        final d = poly[i + 1] - poly[i];
        return (poly[i] + d * u, atan2(d.dy, d.dx));
      }
      acc += segs[i];
    }
    return (poly.last, 0);
  }

  // ---- the named features --------------------------------------------

  static const ironspine = [
    Offset(398, 1044),
    Offset(388, 984),
    Offset(398, 928),
    Offset(384, 876),
    Offset(366, 824),
    Offset(350, 776),
    Offset(342, 726),
    Offset(352, 676),
    Offset(374, 628),
    Offset(398, 582),
    Offset(422, 536),
    Offset(446, 492),
    Offset(466, 448),
  ];
  static const scarp = [
    Offset(606, 556),
    Offset(660, 548),
    Offset(714, 540),
    Offset(768, 534),
    Offset(822, 528),
    Offset(882, 524),
  ];
  static const vaultOuter = [
    Offset(300, 300),
    Offset(360, 240),
    Offset(420, 196),
    Offset(474, 168),
    Offset(528, 196),
    Offset(590, 244),
    Offset(650, 306),
  ];
  static const vaultInner = [
    Offset(360, 330),
    Offset(430, 268),
    Offset(474, 238),
    Offset(520, 268),
    Offset(590, 332),
  ];

  /// The Ironrun falls out of the range, gathering streams.
  static Path ironrun() => Path()
    ..moveTo(418, 494)
    ..cubicTo(442, 540, 458, 578, 482, 616)
    ..cubicTo(506, 652, 532, 684, 556, 712);

  /// ⚠️ Every stream **joins** the Ironrun. The endpoints are sampled off the
  /// Ironrun's own curve, so they land *on* it — a tributary that stops in open
  /// ground reads as a mistake, because it is one.
  static List<Path> streams() => [
    // off the high ridge
    Path()
      ..moveTo(392, 498)
      ..cubicTo(408, 510, 424, 524, 439, 536),
    // from the snowline
    Path()
      ..moveTo(368, 540)
      ..cubicTo(396, 550, 428, 560, 455, 568),
    // the long western feeder
    Path()
      ..moveTo(344, 572)
      ..cubicTo(386, 582, 432, 592, 472, 600),
    // the low spur
    Path()
      ..moveTo(360, 610)
      ..cubicTo(402, 620, 456, 628, 495, 635),
  ];

  /// The Mirrorfall drains Lake Mirrormere due south.
  static Path mirrorfall() => Path()
    ..moveTo(523, 534)
    ..cubicTo(533, 580, 541, 632, 550, 676)
    ..cubicTo(553, 692, 555, 702, 556, 712);

  /// Below the confluence it is the River Concord — and wider for it.
  static Path concord() => Path()
    ..moveTo(556, 712)
    ..cubicTo(580, 756, 594, 812, 600, 880)
    ..cubicTo(608, 960, 602, 1030, 598, 1096)
    ..cubicTo(594, 1170, 610, 1250, 646, 1338);

  static Path glimmerbrook() => Path()
    ..moveTo(424, 1122)
    ..cubicTo(470, 1166, 512, 1210, 556, 1254)
    ..cubicTo(512, 1300, 400, 1338, 326, 1374);

  /// ⭐ Concordance stands where the Ironrun and the Mirrorfall meet — the
  /// concord of two waters, which is where the capital's name comes from.
  static const confluence = Offset(556, 712);
}
