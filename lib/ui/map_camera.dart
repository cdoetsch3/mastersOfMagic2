import 'dart:math';

import 'package:flutter/widgets.dart';

import '../game/world_map_geometry.dart';

/// The one owner of map view transforms.
///
/// ⚠️ **This exists because the transform maths had no owner.** Six call sites
/// each re-derived the unit conversion and hand-rolled their own matrix
/// composition, and one of them applied an inverse transform to a position
/// Flutter had already un-transformed — a double inversion that made
/// tap-to-travel land ~43 px off at fit scale and off-screen entirely when
/// zoomed. A value type that can be unit-tested without a widget tree would
/// have caught that before any pixels existed.
///
/// ## Three coordinate spaces, named
///
/// The distinction below is the whole point of this class:
///
/// | Space | What it is |
/// |---|---|
/// | **map** | The drawing's own units — [WorldMapGeometry.bounds] |
/// | **child** | The painted canvas, before the interactive transform |
/// | **screen** | The viewport, after pan and zoom |
///
/// ⚠️ A [GestureDetector] *inside* an `InteractiveViewer` receives **child**
/// coordinates, because hit-testing already undid the transform. One outside
/// receives **screen** coordinates. Using the wrong conversion is exactly the
/// bug this class was extracted to prevent, so both are spelled out:
/// [childToMap] and [screenToMap].
///
/// ## The child is exactly the viewport
///
/// ⭐ The map is *contained* inside the canvas — scaled to fit both axes and
/// centred, letterboxed where the aspect ratios differ — so **child space and
/// the viewport are the same size**, and scale 1 means "the whole world".
///
/// This is a deliberate correction. The child used to be a tall canvas
/// (1150:1890) scaled to width, centred by *translation*. `InteractiveViewer`
/// clamps translation against its own boundary on every gesture, so it fought
/// that centring the entire time: panning stuttered and the map snapped to the
/// left edge whenever the scaled child was narrower than the window. Centring
/// is a layout concern; making it one leaves the viewer nothing to argue with,
/// and lets the same widget work in a square tab card and a wide window.
@immutable
class MapCamera {
  /// The visible area, in logical pixels.
  final Size viewport;

  /// Zoom, where **1 shows the whole world** — see [fitScale].
  final double scale;

  /// Pan, in screen pixels — the child's origin relative to the viewport.
  final Offset offset;

  const MapCamera({
    required this.viewport,
    this.scale = 1,
    this.offset = Offset.zero,
  });

  static Rect get _bounds => WorldMapGeometry.bounds;

  /// Child pixels per map unit — the *contained* fit, so the short axis wins.
  double get unit => viewport.isEmpty
      ? 1
      : min(viewport.width / _bounds.width, viewport.height / _bounds.height);

  /// The painted canvas at scale 1 — the viewport itself.
  Size get childSize => viewport;

  /// The empty band the contained map leaves on the long axis. The painter
  /// fills it by continuing the sea and the void off the edge of the drawing.
  Offset get letterbox => Offset(
    (viewport.width - _bounds.width * unit) / 2,
    (viewport.height - _bounds.height * unit) / 2,
  );

  /// The scale at which the whole world is visible.
  ///
  /// Always 1, by construction — kept as a named concept because "never zoom
  /// out past the world" is the rule callers actually mean, and spelling it
  /// `1.0` at each call site is how that rule gets lost.
  double get fitScale => 1;

  /// The scale at which the map **fills** the viewport, overflowing the long
  /// axis. Always ≥ [fitScale]; equal only when the box matches the map's own
  /// proportions.
  ///
  /// ⚠️ This is the scale a map view should normally *open* at, and leaving it
  /// out was a real regression. Opening at [fitScale] looks reasonable and is
  /// quietly unusable: the whole world is on screen, so there is nothing to
  /// pan — `InteractiveViewer` correctly refuses every drag — while on a wide
  /// window the world shrinks to a narrow strip with two thirds of the space
  /// left as empty ocean. Players read "drawn, but I cannot get to it".
  double get coverScale {
    if (viewport.isEmpty) return 1;
    final drawn = Size(_bounds.width * unit, _bounds.height * unit);
    return max(viewport.width / drawn.width, viewport.height / drawn.height);
  }

  /// The transform to hand an `InteractiveViewer`.
  Matrix4 get matrix => Matrix4.identity()
    ..translateByDouble(offset.dx, offset.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);

  // ---- conversions -----------------------------------------------------

  Offset mapToChild(Offset map) =>
      Offset((map.dx - _bounds.left) * unit, (map.dy - _bounds.top) * unit) +
      letterbox;

  Offset childToMap(Offset child) {
    final c = child - letterbox;
    return Offset(c.dx / unit + _bounds.left, c.dy / unit + _bounds.top);
  }

  Offset mapToScreen(Offset map) => mapToChild(map) * scale + offset;

  Offset screenToMap(Offset screen) => childToMap((screen - offset) / scale);

  /// A distance in screen pixels, expressed in map units at the current zoom.
  ///
  /// ⭐ Tap targets belong in screen space: a fixed radius in *map* units is a
  /// 10 px target on a desktop at fit scale and a 270 px one at 8×.
  double screenToMapDistance(double screenPixels) =>
      screenPixels / (unit * scale);

  // ---- movements (all return a new camera) ------------------------------

  /// Frame the entire world — every place on screen at once, nothing to pan.
  MapCamera fitted() => MapCamera(viewport: viewport);

  /// Fill the viewport with the map, optionally framed on [focus].
  ///
  /// The opening view: the map uses the whole window and the long axis
  /// overflows, so panning does something from the first drag.
  MapCamera covering({Offset? focus, double zoom = 1}) {
    if (viewport.isEmpty) return this;
    final k = coverScale * zoom;
    return centredOn(focus ?? _bounds.center, scale: k);
  }

  /// Put [map] in the middle of the viewport.
  MapCamera centredOn(Offset map, {double? scale}) {
    if (viewport.isEmpty) return this;
    final k = (scale ?? this.scale).clamp(fitScale, maxScale);
    final child = mapToChild(map) * k;
    return MapCamera(
      viewport: viewport,
      scale: k,
      offset: Offset(
        viewport.width / 2 - child.dx,
        viewport.height / 2 - child.dy,
      ),
    ).clamped();
  }

  /// Zoom about a fixed point — the viewport centre unless [focus] is given.
  ///
  /// The focal point keeps its screen position, which is what makes pinch and
  /// button zoom feel like the same gesture.
  MapCamera zoomedBy(double factor, {Offset? focus}) {
    if (viewport.isEmpty) return this;
    final next = (scale * factor).clamp(fitScale, maxScale);
    if (next == scale) return this;
    final f = focus ?? Offset(viewport.width / 2, viewport.height / 2);
    final k = next / scale;
    return MapCamera(
      viewport: viewport,
      scale: next,
      offset: Offset(
        f.dx - (f.dx - offset.dx) * k,
        f.dy - (f.dy - offset.dy) * k,
      ),
    ).clamped();
  }

  /// Keep the world on screen.
  ///
  /// ⚠️ Without this a fling could leave the map a dot in a corner with no way
  /// back. Since the child is the viewport, at scale 1 this pins the offset to
  /// zero — the map is simply centred, with nothing for a gesture to drift.
  MapCamera clamped() {
    if (viewport.isEmpty) return this;
    double axis(double off, double child, double view) => child <= view
        ? off.clamp(0.0, view - child)
        : off.clamp(view - child, 0.0);
    return MapCamera(
      viewport: viewport,
      scale: scale,
      offset: Offset(
        axis(offset.dx, childSize.width * scale, viewport.width),
        axis(offset.dy, childSize.height * scale, viewport.height),
      ),
    );
  }

  /// Rebuild for a resized window, holding the map point at the centre.
  MapCamera resized(Size next) {
    if (next == viewport) return this;
    if (viewport.isEmpty || next.isEmpty) {
      return MapCamera(viewport: next);
    }
    final centre = screenToMap(Offset(viewport.width / 2, viewport.height / 2));
    return MapCamera(viewport: next, scale: scale).centredOn(centre);
  }

  /// Read a camera back out of an `InteractiveViewer`'s controller.
  factory MapCamera.fromMatrix(Matrix4 m, Size viewport) => MapCamera(
    viewport: viewport,
    scale: m.storage[0],
    offset: Offset(m.storage[12], m.storage[13]),
  );

  static const double maxScale = 8;

  @override
  bool operator ==(Object other) =>
      other is MapCamera &&
      other.viewport == viewport &&
      other.scale == scale &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(viewport, scale, offset);

  @override
  String toString() =>
      'MapCamera(viewport: $viewport, scale: ${scale.toStringAsFixed(3)}, '
      'offset: $offset)';
}
