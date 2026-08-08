import 'dart:math';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
import 'package:masters_of_magic_2/ui/map_camera.dart';
import 'package:masters_of_magic_2/ui/world_map_painter.dart';

/// Guards the seam between the world graph and the drawing of it.
///
/// ⚠️ The likeliest failure here is silent: a place is added to [World] and the
/// map simply never draws it, or a position is left behind after a rename. Both
/// look fine in code review and wrong on screen.
void main() {
  group('the map covers the world', () {
    test('every place has a position, and every position is a place', () {
      final placed = WorldMapGeometry.positions.keys.toSet();
      final real = World.locations.map((l) => l.id).toSet();

      expect(
        placed.difference(real),
        isEmpty,
        reason: 'the map draws places that no longer exist',
      );
      expect(
        real.difference(placed),
        isEmpty,
        reason: 'these places would never appear on the map',
      );
    });

    test('no two places sit on top of each other', () {
      // Pins are ~13 units and the tap radius is 34, so anything closer than
      // that is unselectable in practice.
      final entries = WorldMapGeometry.positions.entries.toList();
      final tooClose = <String>[];
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          final d = (entries[i].value - entries[j].value).distance;
          if (d < 34) {
            tooClose.add(
              '${entries[i].key} / ${entries[j].key} '
              '(${d.toStringAsFixed(0)} apart)',
            );
          }
        }
      }
      expect(
        tooClose,
        isEmpty,
        reason: 'these pins overlap and cannot both be tapped: $tooClose',
      );
    });

    test('every position is inside the drawn canvas', () {
      for (final e in WorldMapGeometry.positions.entries) {
        expect(
          WorldMapGeometry.bounds.inflate(-10).contains(e.value),
          isTrue,
          reason: '${e.key} at ${e.value} falls outside the canvas',
        );
      }
    });

    test('⭐ Forgeholm is IN the Ironspine, not beside it', () {
      // The town is cut into the mountain — "halls stacked over halls, stairs
      // where a street would be". ⚠️ Its pin drifted 110 units off the range
      // once while making room for the north road, which quietly turned a
      // mountain hall into a foothill village.
      final spine = WorldMapGeometry.ironspine;
      var nearest = double.infinity;
      final at = WorldMapGeometry.positions['forgeholm']!;
      for (var i = 0; i < spine.length - 1; i++) {
        final a = spine[i];
        final seg = spine[i + 1] - a;
        final t = (((at - a).dx * seg.dx + (at - a).dy * seg.dy) /
                seg.distanceSquared)
            .clamp(0.0, 1.0);
        final d = (at - (a + seg * t)).distance;
        if (d < nearest) nearest = d;
      }
      expect(
        nearest,
        lessThan(15),
        reason:
            'Forgeholm is ${nearest.toStringAsFixed(0)} from the Ironspine. '
            'It is supposed to be inside it.',
      );
    });
  });

  group('the two planes are drawn apart', () {
    test('the Empyrean sits above the Veil; the world sits below it', () {
      for (final l in World.locations) {
        final at = WorldMapGeometry.positions[l.id]!;
        if (l.plane == WorldPlane.empyrean) {
          expect(
            at.dy,
            lessThan(WorldMapGeometry.veilY),
            reason: '${l.id} is beyond the Veil and must be drawn above it',
          );
        } else {
          expect(
            at.dy,
            greaterThan(WorldMapGeometry.veilY),
            reason: '${l.id} is in the world and must be drawn below it',
          );
        }
      }
    });

    test('exactly one road crosses the Veil — the crossing itself', () {
      final crossings = <String>{};
      for (final l in World.locations) {
        final a = WorldMapGeometry.positions[l.id]!;
        for (final id in l.connections) {
          final b = WorldMapGeometry.positions[id]!;
          final crosses =
              (a.dy < WorldMapGeometry.veilY) !=
              (b.dy < WorldMapGeometry.veilY);
          if (crosses) crossings.add(([l.id, id]..sort()).join(' <-> '));
        }
      }
      // Out at Vespergate; back in at the summit through the Citadel.
      expect(crossings, {
        'the_collapsed_academy <-> vespergate',
        'the_eclipsed_citadel <-> zenith',
      });
    });
  });

  group('the terrain is deterministic', () {
    test('the same seed draws the same world', () {
      // ⭐ The map has no image assets — it is scattered procedurally — so the
      // one thing that must hold is that it does not reshuffle between runs.
      List<Offset> draw() =>
          WorldMapGeometry.scatter(Random(11), 360, 1218, 206, 172, 20);
      expect(draw(), draw());

      List<({Offset at, double size})> range() => WorldMapGeometry.rangeField(
        WorldMapGeometry.ironspine,
        20,
        48,
        11,
        31,
        seed: 21,
      );
      final a = range(), b = range();
      for (var i = 0; i < a.length; i++) {
        expect(a[i].at, b[i].at);
        expect(a[i].size, b[i].size);
      }
    });

    test('a mountain range varies in size — it is not a row of arrows', () {
      final field = WorldMapGeometry.rangeField(
        WorldMapGeometry.ironspine,
        112,
        48,
        11,
        31,
        seed: 21,
      );
      final sizes = field.map((m) => m.size).toList()..sort();
      expect(
        sizes.last / sizes.first,
        greaterThan(2.0),
        reason: 'peaks must differ enough to read as a range',
      );
      // Painter's order: far ridges first, so nearer ones overlap them.
      for (var i = 1; i < field.length; i++) {
        expect(field[i].at.dy, greaterThanOrEqualTo(field[i - 1].at.dy));
      }
    });

    test('a region boundary is not a circle', () {
      final path = WorldMapGeometry.region(0, 0, 100, 100, rough: .2, seed: 3);
      final m = path.computeMetrics().first;
      final radii = <double>[];
      for (var t = 0.0; t < 1; t += 0.02) {
        radii.add(m.getTangentForOffset(m.length * t)!.position.distance);
      }
      radii.sort();
      expect(
        radii.last - radii.first,
        greaterThan(15),
        reason: 'the boundary should wander, not trace a circle',
      );
    });
  });

  group('the labels are legible', () {
    // ⚠️ These exist because the same three faults kept coming back: mixed
    // capitalisation, names stacked on one spot, and text off the canvas.
    // Eyeballing a screenshot missed them every time.

    /// Rough drawn box for a label.
    Rect boxOf(MapLabel l) =>
        Rect.fromCenter(center: l.at, width: l.width, height: l.size * 1.35);

    test('every PLACE name is ALL CAPS on the map', () {
      // ⚠️ The miss that survived four rounds of review. Place pins and named
      // geography are drawn by different code paths, and only the geography
      // was being capitalised — so towns still read "Hearthwood" next to
      // "THE VERDANT BASIN". Both paths now go through [mapLabelFor].
      for (final loc in World.locations) {
        final drawn = mapLabelFor(loc.name);
        expect(
          drawn,
          drawn.toUpperCase(),
          reason: '"${loc.name}" would draw as "$drawn"',
        );
        expect(
          drawn.startsWith('THE '),
          isFalse,
          reason: 'the leading article is dropped for space: "$drawn"',
        );
      }
      expect(mapLabelFor('The Eclipsed Citadel'), 'ECLIPSED CITADEL');
      expect(mapLabelFor('Hearthwood'), 'HEARTHWOOD');
    });

    test('every feature label is ALL CAPS', () {
      for (final l in WorldMapGeometry.featureLabels) {
        expect(
          l.text,
          l.text.toUpperCase(),
          reason: '"${l.text}" breaks the map\'s single voice',
        );
      }
    });

    test('no feature label overlaps another', () {
      final all = WorldMapGeometry.featureLabels
          .where((l) => l.rotation == 0)
          .toList();
      final hits = <String>[];
      for (var i = 0; i < all.length; i++) {
        for (var j = i + 1; j < all.length; j++) {
          if (boxOf(all[i]).overlaps(boxOf(all[j]))) {
            hits.add('${all[i].text} / ${all[j].text}');
          }
        }
      }
      expect(hits, isEmpty, reason: 'these labels collide: $hits');
    });

    test('no feature label lands on a place pin', () {
      // A pin draws its own name just above itself; a feature name in the same
      // space is what made the Meridian corner unreadable.
      final hits = <String>[];
      for (final l in WorldMapGeometry.featureLabels) {
        if (l.rotation != 0) continue;
        for (final e in WorldMapGeometry.positions.entries) {
          final pin = Rect.fromCenter(
            center: e.value.translate(0, -21),
            width: 150,
            height: 40,
          );
          if (boxOf(l).overlaps(pin)) hits.add('${l.text} on ${e.key}');
        }
      }
      expect(hits, isEmpty, reason: 'labels sitting on pins: $hits');
    });

    test('every feature label stays on the canvas', () {
      for (final l in WorldMapGeometry.featureLabels) {
        if (l.rotation != 0) continue;
        expect(
          WorldMapGeometry.bounds.contains(boxOf(l).topLeft),
          isTrue,
          reason: '"${l.text}" runs off the left/top edge',
        );
        expect(
          WorldMapGeometry.bounds.contains(boxOf(l).bottomRight),
          isTrue,
          reason: '"${l.text}" runs off the right/bottom edge',
        );
      }
    });

    test('no feature label repeats a TOWN name', () {
      // ⚠️ Deliberately towns only. A town pin *always* draws its name, so a
      // matching feature label is a guaranteed double. Zone pins only label
      // themselves when you are there or can reach them, so a region like THE
      // KILN DESERT still needs its own name for the other 95% of the time —
      // an earlier version of this test banned those and was simply wrong.
      final townNames = {
        for (final t in World.towns)
          t.name.toUpperCase().replaceFirst('THE ', ''),
      };
      for (final l in WorldMapGeometry.featureLabels) {
        final bare = l.text.replaceFirst('THE ', '').replaceFirst('LAKE ', '');
        expect(
          townNames.contains(bare),
          isFalse,
          reason: '"${l.text}" repeats a town that always shows its name',
        );
      }
    });
  });

  group('the waters make sense', () {
    test('every stream joins the Ironrun', () {
      // ⚠️ A tributary that stops in open ground reads as a bug, because it is
      // one. This caught one stream ending 19 units short of the river.
      final m = WorldMapGeometry.ironrun().computeMetrics().first;
      final river = [
        for (var t = 0.0; t <= 1.0; t += 0.005)
          m.getTangentForOffset(m.length * t)!.position,
      ];
      for (final (i, s) in WorldMapGeometry.streams().indexed) {
        final sm = s.computeMetrics().first;
        final end = sm.getTangentForOffset(sm.length)!.position;
        final gap = river.map((p) => (p - end).distance).reduce(min);
        expect(
          gap,
          lessThan(4.0),
          reason: 'stream $i ends ${gap.toStringAsFixed(1)} from the river',
        );
      }
    });

    test('water runs downhill', () {
      for (final (i, s) in WorldMapGeometry.streams().indexed) {
        final m = s.computeMetrics().first;
        final a = m.getTangentForOffset(0)!.position;
        final b = m.getTangentForOffset(m.length)!.position;
        expect(b.dy, greaterThan(a.dy), reason: 'stream $i runs uphill');
      }
    });

    test('the two rivers meet at Concordance', () {
      final at = WorldMapGeometry.positions['concordance']!;
      expect(
        (at - WorldMapGeometry.confluence).distance,
        lessThan(2),
        reason: 'the capital stands at the concord of two waters',
      );
      for (final r in [
        WorldMapGeometry.ironrun(),
        WorldMapGeometry.mirrorfall(),
      ]) {
        final m = r.computeMetrics().first;
        final end = m.getTangentForOffset(m.length)!.position;
        expect((end - WorldMapGeometry.confluence).distance, lessThan(2));
      }
    });
  });

  group('the painter repaints when it must', () {
    test('moving, selecting or hiding pins all trigger a repaint', () {
      final base = WorldMapPainter(currentId: 'hearthwood');
      expect(
        base.shouldRepaint(WorldMapPainter(currentId: 'pennycross')),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          WorldMapPainter(currentId: 'hearthwood', selectedId: 'x'),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          WorldMapPainter(currentId: 'hearthwood', showPins: false),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(WorldMapPainter(currentId: 'hearthwood')),
        isFalse,
      );
    });

    test('discovering a place repaints, even at the same count', () {
      // ⚠️ The old check compared `.length`. Swapping one known place for
      // another — a quest reveal, a scrying spell, a multiplayer sighting —
      // left the count identical, so the map silently kept the stale dimming.
      final before = WorldMapPainter(seen: {'hearthwood', 'thornmire'});
      final after = WorldMapPainter(seen: {'hearthwood', 'pennycross'});
      expect(before.shouldRepaint(after), isTrue);
      expect(
        before.shouldRepaint(WorldMapPainter(seen: {'thornmire', 'hearthwood'})),
        isFalse,
        reason: 'set equality, not order',
      );
    });

    test('a caller\'s live set cannot defeat the dirty check', () {
      // ⚠️ The real shape of the bug: the screen handed over
      // profile.discoveredLocationIds itself, so old and new painters held one
      // instance and every comparison was an object against itself.
      final live = <String>{'hearthwood'};
      final before = WorldMapPainter(seen: live);
      live.add('thornmire');
      final after = WorldMapPainter(seen: live);
      expect(
        before.shouldRepaint(after),
        isTrue,
        reason: 'the painter must have snapshotted, not aliased',
      );
      expect(before.seen, {'hearthwood'});
      expect(() => before.seen.add('x'), throwsUnsupportedError);
    });
  });

  testWidgets('the map paints without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: CustomPaint(
            painter: WorldMapPainter(
              currentId: 'hearthwood',
              reachable: World.byId('hearthwood').connections.toSet(),
              seen: const {'hearthwood'},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('the DRAWING lands where the camera says it does', () {
    // ⚠️ The gap that let a real defect ship. A stray duplicated
    // `canvas.translate(-b.left, -b.top)` shifted the whole map down 130 px
    // and right 28 px, pushing the southern fifth of the world outside the
    // canvas — unreachable at any zoom, because the canvas *is* the child.
    // Every existing test passed: the hit-test and the test helpers both used
    // MapCamera and agreed with each other, while the drawing agreed with
    // neither. Nothing compared rendered pixels to the camera until this.
    Future<void> checkFit(WidgetTester tester, Size size) async {
      final recorder = ui.PictureRecorder();
      WorldMapPainter(currentId: 'hearthwood').paint(Canvas(recorder), size);
      final picture = recorder.endRecording();

      await tester.runAsync(() async {
        final image = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        int pixel(int x, int y) {
          final i = (y * size.width.toInt() + x) * 4;
          return (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
        }

        // Land is the only strongly green thing; sea and void are not.
        bool isLand(int c) {
          final r = (c >> 16) & 0xff, g = (c >> 8) & 0xff, b = c & 0xff;
          return g > r && g > b + 20;
        }

        var top = -1, bottom = -1;
        for (var y = 0; y < size.height.toInt(); y++) {
          for (var x = 0; x < size.width.toInt(); x += 2) {
            if (isLand(pixel(x, y))) {
              if (top < 0) top = y;
              bottom = y;
              break;
            }
          }
        }
        expect(top, greaterThan(0), reason: 'no land drawn at all in $size');

        final cam = MapCamera(viewport: size);
        final coast = WorldMapGeometry.coastline().getBounds();
        final wantTop = cam.mapToChild(Offset(0, coast.top)).dy;
        final wantBottom = cam.mapToChild(Offset(0, coast.bottom)).dy;

        // Generous tolerance: the coast's extreme points are narrow, so a
        // sampled scan finds them a few rows in. A transform error is tens of
        // pixels, which this still catches.
        expect(
          top.toDouble(),
          closeTo(wantTop, 12),
          reason: 'north edge, $size',
        );
        expect(
          bottom.toDouble(),
          closeTo(wantBottom, 12),
          reason: 'south edge, $size — the coast must not run off the canvas',
        );
        expect(
          bottom,
          lessThan(size.height.toInt() - 1),
          reason: 'the south of the world must be inside the box, $size',
        );
      });
    }

    testWidgets('on a wide window', (tester) async {
      await checkFit(tester, const Size(1400, 744));
    });

    testWidgets('in a square card', (tester) async {
      await checkFit(tester, const Size(380, 380));
    });

    testWidgets('on a tall phone', (tester) async {
      await checkFit(tester, const Size(390, 780));
    });
  });
}
