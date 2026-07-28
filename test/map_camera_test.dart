import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/world_map_geometry.dart';
import 'package:masters_of_magic_2/ui/map_camera.dart';

/// ⭐ The value of extracting [MapCamera] is that all of this can be asserted
/// with no widget tree at all. The defect it was extracted from — a double
/// inversion in the tap path — is a two-line round-trip test here, and would
/// have failed before any pixel was drawn.
void main() {
  const phone = Size(400, 800);
  const desktop = Size(1600, 900);
  final bounds = WorldMapGeometry.bounds;

  group('coordinate round trips', () {
    test('map -> child -> map is the identity, at any zoom', () {
      for (final viewport in [phone, desktop]) {
        for (final scale in [0.3, 1.0, 4.0]) {
          final cam = MapCamera(
            viewport: viewport,
            scale: scale,
            offset: const Offset(37, -211),
          );
          for (final at in WorldMapGeometry.positions.values) {
            final back = cam.childToMap(cam.mapToChild(at));
            expect(back.dx, closeTo(at.dx, 0.001));
            expect(back.dy, closeTo(at.dy, 0.001));
          }
        }
      }
    });

    test('map -> screen -> map is the identity, at any zoom', () {
      for (final scale in [0.3, 1.0, 4.0]) {
        final cam = MapCamera(
          viewport: phone,
          scale: scale,
          offset: const Offset(-90, 44),
        );
        for (final at in WorldMapGeometry.positions.values) {
          final back = cam.screenToMap(cam.mapToScreen(at));
          expect(back.dx, closeTo(at.dx, 0.001));
          expect(back.dy, closeTo(at.dy, 0.001));
        }
      }
    });

    test('child and screen conversions are NOT the same thing', () {
      // ⚠️ The heart of the original defect. Confusing these is silent — both
      // return an Offset that looks plausible — so the difference is asserted
      // explicitly rather than left to a comment.
      final cam = MapCamera(
        viewport: phone,
        scale: 2.5,
        offset: const Offset(60, -400),
      );
      const probe = Offset(180, 300);
      expect(cam.childToMap(probe), isNot(cam.screenToMap(probe)));

      // With no pan and no zoom they coincide — which is precisely why the bug
      // survived casual testing on a phone at fit scale.
      const still = MapCamera(viewport: phone);
      expect(still.childToMap(probe), still.screenToMap(probe));
    });
  });

  group('fitting the world', () {
    test('the map is CONTAINED in the box, on the short axis', () {
      // ⚠️ The child used to be scaled to WIDTH and centred by translation —
      // which InteractiveViewer clamps, so it fought the centring: panning
      // stuttered and the map snapped to the left edge. Containing it makes
      // the child exactly the viewport, and centring a layout fact.
      const cam = MapCamera(viewport: desktop);
      expect(cam.childSize, desktop);
      expect(
        cam.unit,
        closeTo(desktop.height / bounds.height, 0.0001),
        reason: 'the map is far taller than a desktop window, so height wins',
      );
      expect(bounds.width * cam.unit, lessThanOrEqualTo(desktop.width + 0.5));
      expect(bounds.height * cam.unit, closeTo(desktop.height, 0.5));
    });

    test('the whole world is visible at scale 1', () {
      // The old code opened the full-screen map at 2.2 — about 7x too close.
      for (final viewport in [phone, desktop]) {
        expect(MapCamera(viewport: viewport).fitScale, 1);
      }
    });

    test('the letterbox band is split evenly, so the map is centred', () {
      const cam = MapCamera(viewport: desktop);
      final centre = cam.mapToScreen(bounds.center);
      expect(centre.dx, closeTo(desktop.width / 2, 0.5));
      expect(centre.dy, closeTo(desktop.height / 2, 0.5));
      expect(
        cam.letterbox.dy,
        closeTo(0, 0.5),
        reason: 'height is the constrained axis here — no vertical band',
      );
      expect(cam.letterbox.dx, greaterThan(0));
    });

    test('fitting shows the whole world and nothing more', () {
      for (final viewport in [phone, desktop]) {
        final cam = MapCamera(viewport: viewport).fitted();
        final tl = cam.mapToScreen(bounds.topLeft);
        final br = cam.mapToScreen(bounds.bottomRight);
        expect(tl.dx, greaterThanOrEqualTo(-0.5));
        expect(tl.dy, greaterThanOrEqualTo(-0.5));
        expect(br.dx, lessThanOrEqualTo(viewport.width + 0.5));
        expect(br.dy, lessThanOrEqualTo(viewport.height + 0.5));
      }
    });

    test('every place is on screen when fitted', () {
      final cam = MapCamera(viewport: desktop).fitted();
      for (final e in WorldMapGeometry.positions.entries) {
        final s = cam.mapToScreen(e.value);
        expect(s.dx, inInclusiveRange(0, desktop.width), reason: e.key);
        expect(s.dy, inInclusiveRange(0, desktop.height), reason: e.key);
      }
    });
  });

  group('the opening view can actually be panned', () {
    // ⚠️ The regression that made the map "drawn but unreachable": opening at
    // fitScale puts the whole world on screen, so InteractiveViewer refuses
    // every drag — correctly, there is nowhere to go — and on a wide window
    // the world shrinks to a strip with two thirds of the space empty ocean.
    test('cover fills the box on both axes', () {
      for (final viewport in [phone, desktop, const Size(900, 900)]) {
        final cam = MapCamera(viewport: viewport).covering();
        final tl = cam.mapToScreen(bounds.topLeft);
        final br = cam.mapToScreen(bounds.bottomRight);
        expect(tl.dx, lessThanOrEqualTo(0.5), reason: '\$viewport');
        expect(tl.dy, lessThanOrEqualTo(0.5), reason: '\$viewport');
        expect(br.dx, greaterThanOrEqualTo(viewport.width - 0.5));
        expect(br.dy, greaterThanOrEqualTo(viewport.height - 0.5));
      }
    });

    test('there is somewhere to pan on a window shaped unlike the map', () {
      // A wide window is the case that hurt: the map is far taller than it.
      final cam = MapCamera(viewport: desktop).covering();
      expect(
        cam.coverScale,
        greaterThan(2),
        reason: 'the desktop window is much wider than the map',
      );
      final childH = cam.childSize.height * cam.scale;
      expect(
        childH,
        greaterThan(desktop.height + 100),
        reason: 'otherwise every drag is a no-op',
      );
    });

    test('the far south is reachable from the opening view', () {
      final south = WorldMapGeometry.positions.values.reduce(
        (a, b) => a.dy > b.dy ? a : b,
      );
      for (final viewport in [phone, desktop]) {
        final cam = MapCamera(viewport: viewport).covering(focus: south);
        final s = cam.mapToScreen(south);
        // Comfortably on screen — not clipped to an edge, which is how "I
        // cannot get to the bottom of the map" felt.
        expect(
          s.dx,
          inInclusiveRange(20, viewport.width - 20),
          reason: '$viewport',
        );
        expect(
          s.dy,
          inInclusiveRange(20, viewport.height - 20),
          reason: '$viewport',
        );
      }
    });

    test(
      'cover is never below fit, and zooming out still reaches the world',
      () {
        for (final viewport in [phone, desktop, const Size(700, 1150)]) {
          final cam = MapCamera(viewport: viewport);
          expect(cam.coverScale, greaterThanOrEqualTo(cam.fitScale));
        }
        // From the opening view, "Whole world" gets all the way back.
        final back = MapCamera(viewport: desktop).covering().fitted();
        expect(back.scale, 1);
        expect(back.offset, Offset.zero);
      },
    );
  });

  group('movement', () {
    test('centring puts the place in the middle', () {
      final at = WorldMapGeometry.positions['concordance']!;
      final cam = MapCamera(viewport: phone).fitted().centredOn(at, scale: 3);
      final s = cam.mapToScreen(at);
      expect(s.dx, closeTo(phone.width / 2, 1));
      expect(s.dy, closeTo(phone.height / 2, 1));
    });

    test('zooming holds the focal point still', () {
      final cam = MapCamera(viewport: phone).fitted();
      const focus = Offset(120, 500);
      final before = cam.screenToMap(focus);
      final after = cam.zoomedBy(2.5, focus: focus);
      final moved = after.screenToMap(focus);
      expect(moved.dx, closeTo(before.dx, 0.5));
      expect(moved.dy, closeTo(before.dy, 0.5));
    });

    test('zoom cannot go below fit or above the ceiling', () {
      final cam = MapCamera(viewport: desktop).fitted();
      var out = cam;
      for (var i = 0; i < 20; i++) {
        out = out.zoomedBy(0.5);
      }
      expect(
        out.scale,
        closeTo(cam.fitScale, 0.0001),
        reason: 'zooming out past the world is what lost the map before',
      );

      var into = cam;
      for (var i = 0; i < 30; i++) {
        into = into.zoomedBy(2);
      }
      expect(into.scale, MapCamera.maxScale);
    });
  });

  group('the world cannot be lost', () {
    test('panning far away is clamped back to the world', () {
      final cam = MapCamera(
        viewport: phone,
      ).fitted().zoomedBy(4).copyOffset(const Offset(-99999, 99999)).clamped();
      // The child must still cover the viewport.
      final childW = cam.childSize.width * cam.scale;
      final childH = cam.childSize.height * cam.scale;
      expect(cam.offset.dx, inInclusiveRange(phone.width - childW, 0));
      expect(cam.offset.dy, inInclusiveRange(phone.height - childH, 0));
    });

    test('at fit scale a pan cannot move the map AT ALL', () {
      // ⚠️ This is the "sticks to the left edge" bug, stated as a property.
      // When the child is the viewport there is nothing to pan at scale 1, so
      // the map cannot drift off-centre — and the viewer has no clamp to apply
      // that would fight a centring translate.
      for (final viewport in [phone, desktop]) {
        for (final drag in const [Offset(-5000, 0), Offset(900, 400)]) {
          final cam = MapCamera(viewport: viewport).copyOffset(drag).clamped();
          expect(cam.offset, Offset.zero, reason: '\$viewport dragged \$drag');
          final centre = cam.mapToScreen(bounds.center);
          expect(centre.dx, closeTo(viewport.width / 2, 0.5));
          expect(centre.dy, closeTo(viewport.height / 2, 0.5));
        }
      }
    });
  });

  group('tap targets live in screen space', () {
    test('a fixed screen radius shrinks in map units as you zoom in', () {
      final fit = MapCamera(viewport: desktop).fitted();
      final close = fit.zoomedBy(6);
      final atFit = fit.screenToMapDistance(24);
      final atZoom = close.screenToMapDistance(24);
      expect(
        atZoom,
        lessThan(atFit),
        reason: 'otherwise a zoomed tap grabs pins from across the screen',
      );
      // The old fixed 34 map units was ~10 screen px here — nearly untappable.
      expect(
        atFit,
        greaterThan(34),
        reason: 'a fixed map radius is far too small at fit scale',
      );
    });
  });

  group('resizing', () {
    test('a window resize while fitted stays fitted', () {
      final cam = MapCamera(viewport: phone).fitted().resized(desktop);
      expect(cam.scale, closeTo(MapCamera(viewport: desktop).fitScale, 0.001));
    });

    test('a window resize while zoomed keeps the centre', () {
      final at = WorldMapGeometry.positions['forgeholm']!;
      final cam = MapCamera(
        viewport: phone,
      ).fitted().centredOn(at, scale: 3).resized(desktop);
      final s = cam.mapToScreen(at);
      expect(s.dx, closeTo(desktop.width / 2, 2));
      expect(s.dy, closeTo(desktop.height / 2, 2));
    });
  });

  test('a camera survives a matrix round trip', () {
    // The InteractiveViewer owns a Matrix4; the camera must read back cleanly.
    final cam = MapCamera(viewport: phone).fitted().zoomedBy(2.2);
    final back = MapCamera.fromMatrix(cam.matrix, phone);
    expect(back.scale, closeTo(cam.scale, 0.0001));
    expect(back.offset.dx, closeTo(cam.offset.dx, 0.0001));
    expect(back.offset.dy, closeTo(cam.offset.dy, 0.0001));
  });
}

extension on MapCamera {
  MapCamera copyOffset(Offset o) =>
      MapCamera(viewport: viewport, scale: scale, offset: o);
}
