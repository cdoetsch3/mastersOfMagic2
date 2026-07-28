import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_state.dart';
import '../game/world.dart';
import '../game/world_map_geometry.dart';
import 'app_theme.dart';
import 'map_camera.dart';
import 'world_map_painter.dart';

/// The world map, pannable and zoomable and tappable — wherever it appears.
///
/// ⭐ There is **one** interactive map, not a live one and a preview. The card
/// at the top of the Map tab and the full-screen view are the same widget with
/// different framing: expanding gets you room and the geography labels, not
/// abilities you did not have before. A preview you must leave in order to use
/// is a worse version of the thing it previews.
///
/// ⚠️ Reachability is the graph's business, not the map's — this only ever asks
/// [GameLocation.connections]. The drawing can be rearranged freely without
/// changing where anyone can actually go.
class InteractiveWorldMap extends StatefulWidget {
  final GameState game;

  /// Names of the geography (ranges, rivers, seas). Off in the tab card, where
  /// there is room for terrain but not for thirty-two more words.
  final bool showFeatureLabels;

  /// Smaller controls, for the tab card.
  final bool compact;

  /// Shows the expand button when given.
  final VoidCallback? onExpand;

  /// Opening zoom, as a multiple of the scale that **fills** the box.
  ///
  /// ⚠️ Not a multiple of the whole-world scale. Opening on the whole world
  /// leaves nothing to pan — the viewer refuses every drag, correctly — and on
  /// a wide window shrinks the map to a strip in a sea of empty ocean. Filling
  /// the box is the useful default; the whole world is one button away.
  final double initialZoom;

  /// Open framed on the player rather than on the middle of the world.
  final bool focusOnPlayer;

  const InteractiveWorldMap({
    super.key,
    required this.game,
    this.showFeatureLabels = true,
    this.compact = false,
    this.onExpand,
    this.initialZoom = 1,
    this.focusOnPlayer = false,
  });

  @override
  State<InteractiveWorldMap> createState() => _InteractiveWorldMapState();
}

class _InteractiveWorldMapState extends State<InteractiveWorldMap> {
  final _controller = TransformationController();
  String? _selected;

  /// ⭐ All transform maths lives in [MapCamera]. This state only remembers
  /// which viewport it was last laid out for; every conversion, movement and
  /// clamp is the camera's job — see the class doc for why that separation
  /// exists.
  MapCamera _camera = const MapCamera(viewport: Size.zero);

  /// The opening framing is applied once, on the first real layout. After that
  /// the view is the player's, and a rebuild must not yank it back.
  bool _framed = false;

  GameLocation get _here => widget.game.profile.location;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply(MapCamera next) {
    setState(() {
      _camera = next;
      _controller.value = next.matrix;
    });
  }

  /// Pull the user's own pan/zoom back out of the viewer before moving, so a
  /// button press composes with wherever they dragged to.
  MapCamera get _live =>
      MapCamera.fromMatrix(_controller.value, _camera.viewport);

  void _fitWorld() => _apply(_camera.fitted());

  void _centreOnPlayer() {
    final at = WorldMapGeometry.positions[_here.id];
    if (at == null) return;
    final cam = _live;
    // Zoom in only if the view is wider than the map's own filling scale —
    // otherwise keep the player's zoom and just travel there.
    final k = max(cam.scale, cam.coverScale * 1.4);
    _apply(cam.centredOn(at, scale: k));
  }

  void _zoomBy(double factor) => _apply(_live.zoomedBy(factor));

  void _tap(Offset childPosition) {
    // ⚠️ childPosition, NOT a screen position: this detector sits *inside* the
    // InteractiveViewer, so hit-testing has already undone the transform.
    // Applying the inverse again here was the original tap defect.
    final cam = _live;
    final p = cam.childToMap(childPosition);

    // ⭐ A tap target is a constant number of SCREEN pixels. As a fixed radius
    // in map units it was ~10 px on a desktop at fit scale and ~270 px at 8x.
    final radius = cam.screenToMapDistance(_tapRadiusPx);

    String? hit;
    var best = double.infinity;
    WorldMapGeometry.positions.forEach((id, at) {
      final d = (at - p).distance;
      if (d < radius && d < best) {
        best = d;
        hit = id;
      }
    });
    final id = hit;
    if (id == null) return;
    setState(() => _selected = id);
    _showDetails(World.byId(id));
  }

  /// A wheel scroll **pans**; hold ⌘/Ctrl to zoom.
  ///
  /// ⚠️ `InteractiveViewer` treats a mouse-wheel scroll as zoom. On a laptop
  /// that made the map unusable: scrolling down — the obvious way to move
  /// south — zoomed out instead, reached the whole-world limit in three
  /// notches, and then did nothing at all. It reads exactly like "I can't pan
  /// past here", because the content stops responding.
  ///
  /// ⚠️ The viewer mutates its controller **directly** here, without the
  /// [PointerSignalResolver] — so this cannot preempt it, only outlive it.
  /// `GestureBinding` resolves signals after every listener has been
  /// dispatched, so the registered callback runs last and has the final say;
  /// the pre-zoom camera is captured on the way in, because by then the viewer
  /// has already changed the scale.
  ///
  /// A trackpad scroll is left alone — the viewer already pans for those
  /// (`trackpadScrollCausesScale` is false), and handling it here too would
  /// pan twice.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (event.kind == PointerDeviceKind.trackpad) return;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) return;

    final before = _live;
    final delta = event.scrollDelta;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _apply(
        MapCamera(
          viewport: before.viewport,
          scale: before.scale,
          offset: before.offset - delta,
        ).clamped(),
      );
    });
  }

  /// Comfortable thumb target, in screen pixels.
  static const double _tapRadiusPx = 26;

  Future<void> _showDetails(GameLocation loc) async {
    final connected = _here.connections.contains(loc.id);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => PlaceSheet(
        location: loc,
        isHere: loc.id == _here.id,
        canTravel: connected,
        onTravel: () {
          Navigator.of(ctx).pop();
          _travel(loc);
        },
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  Future<void> _travel(GameLocation loc) async {
    setState(() => _selected = null);
    try {
      // ⚠️ Awaited. Dropping this future swallowed persistence failures — an
      // offline save would fail silently and the player would find themselves
      // back where they started on next launch.
      await widget.game.travelTo(loc.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panelHi,
          content: Text(
            'Could not save your travel to ${loc.name}. Check your connection.',
            style: const TextStyle(color: AppColors.text),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ The map OBSERVES game state rather than reading it once. Before this
    // it happened to render correctly only because GameState._mutate applies
    // its change synchronously before the first await — an accident that would
    // break the moment travel became timed or a sync arrived.
    return ListenableBuilder(
      listenable: widget.game,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          if (viewport != _camera.viewport) {
            var next = _camera.resized(viewport);
            if (!_framed && !viewport.isEmpty) {
              _framed = true;
              next = next.covering(
                focus: widget.focusOnPlayer
                    ? WorldMapGeometry.positions[_here.id]
                    : null,
                zoom: widget.initialZoom,
              );
            }
            _camera = next;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _controller.value = next.matrix;
            });
          }
          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _controller,
                  // ⭐ Never zoom out past the whole world — that is what let a
                  // fling leave the map a dot in a corner with no way back.
                  // With the child sized to the viewport, this is also the
                  // scale at which the viewer's own boundary keeps the map
                  // exactly centred, instead of fighting a centring translate.
                  minScale: _camera.fitScale,
                  maxScale: MapCamera.maxScale,
                  // ⚠️ Keep the user's pan in [_camera] too. It used to live
                  // only in the controller, so the next viewport change
                  // rebuilt from a stale camera and threw the view away.
                  onInteractionEnd: (_) => _camera = _live,
                  child: Listener(
                    onPointerSignal: _onPointerSignal,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _tap(d.localPosition),
                      child: CustomPaint(
                        isComplex: true,
                        painter: WorldMapPainter(
                          currentId: _here.id,
                          reachable: _here.connections.toSet(),
                          // The painter snapshots this itself; see its doc for
                          // why handing over the profile's live Set defeated
                          // every dirty check.
                          seen: widget.game.profile.discoveredLocationIds,
                          selectedId: _selected,
                          showFeatureLabels: widget.showFeatureLabels,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pinch works, but a mouse has nothing to pinch with.
              Positioned(
                right: widget.compact ? 8 : 12,
                bottom: widget.compact ? 8 : 12,
                child: Column(
                  children: [
                    if (widget.onExpand != null) ...[
                      MapButton(
                        icon: Icons.open_in_full,
                        tooltip: 'Open the full map',
                        compact: widget.compact,
                        onTap: widget.onExpand!,
                      ),
                      SizedBox(height: widget.compact ? 6 : 8),
                    ],
                    MapButton(
                      icon: Icons.my_location,
                      tooltip: 'Centre on me',
                      compact: widget.compact,
                      onTap: _centreOnPlayer,
                    ),
                    SizedBox(height: widget.compact ? 6 : 8),
                    MapButton(
                      icon: Icons.add,
                      tooltip: 'Zoom in',
                      compact: widget.compact,
                      onTap: () => _zoomBy(1.4),
                    ),
                    SizedBox(height: widget.compact ? 6 : 8),
                    MapButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom out',
                      compact: widget.compact,
                      onTap: () => _zoomBy(1 / 1.4),
                    ),
                    SizedBox(height: widget.compact ? 6 : 8),
                    MapButton(
                      icon: Icons.fit_screen,
                      tooltip: 'Whole world',
                      compact: widget.compact,
                      onTap: _fitWorld,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool compact;
  const MapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final side = compact ? 32.0 : 40.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: side,
            height: side,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: compact ? 16 : 19, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}

/// What a place is, and whether you can get there from here.
class PlaceSheet extends StatelessWidget {
  final GameLocation location;
  final bool isHere;
  final bool canTravel;
  final VoidCallback onTravel;

  const PlaceSheet({
    super.key,
    required this.location,
    required this.isHere,
    required this.canTravel,
    required this.onTravel,
  });

  @override
  Widget build(BuildContext context) {
    final elements = location.elements
        .map((e) => e.name[0].toUpperCase() + e.name.substring(1))
        .join(' + ');
    return SafeArea(
      // ⚠️ Scrollable, not a bare Column. Content-heavy places (a long arrival
      // passage plus a gate requirement) overflow the modal's height budget on
      // small screens — found because the tap-regression tests opened the
      // sheet for real and the overflow threw.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isHere)
                  const _Chip(text: 'You are here', color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.blurb,
              style: const TextStyle(color: AppColors.textDim, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (elements.isNotEmpty) _Chip(text: elements),
                if (location.hasAdventure)
                  // ⚠️ The ENEMY level, not a requirement. Said in full, because
                  // "Lv 58-60" alone reads as "come back at 58" and players
                  // never return.
                  _Chip(
                    text:
                        'Enemies Lv ${location.minLevel}'
                        '–${location.maxLevel}',
                    color: AppColors.ember,
                  ),
                if (location.station != null)
                  _Chip(text: location.station!, color: AppColors.teal),
                if (location.plane == WorldPlane.empyrean)
                  const _Chip(text: 'Beyond the Veil', color: AppColors.gem),
              ],
            ),
            if (location.arrival.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                location.arrival,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
            ],
            if (location.gate != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.gate!,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canTravel && !isHere ? onTravel : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.bg,
                  disabledBackgroundColor: AppColors.borderDim,
                ),
                child: Text(
                  isHere
                      ? 'You are already here'
                      : canTravel
                      ? 'Travel to ${location.name}'
                      : 'No road from here',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, this.color = AppColors.textDim});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
