import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/world.dart';
import '../game/world_map_geometry.dart';
import '../ui/app_theme.dart';
import '../ui/world_map_painter.dart';

/// The full-screen world map: pan, zoom, tap a place for its details, travel
/// from there if a road connects it.
///
/// ⚠️ Reachability is the graph's business, not the map's — this only ever asks
/// [GameLocation.connections]. The drawing can be rearranged freely without
/// changing where anyone can actually go.
class WorldMapScreen extends StatefulWidget {
  final GameState game;
  const WorldMapScreen({super.key, required this.game});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final _controller = TransformationController();
  String? _selected;
  Size _viewport = Size.zero;

  /// Scale at which the whole world fits the viewport. On a desktop window the
  /// map is far taller than the screen, so this is well below 1.
  double get _fitScale {
    if (_viewport.isEmpty) return 1;
    final b = WorldMapGeometry.bounds;
    final paintedHeight = _viewport.width * b.height / b.width;
    return min(1.0, _viewport.height / paintedHeight);
  }

  GameLocation get _here => widget.game.profile.location;

  @override
  void initState() {
    super.initState();
    // ⚠️ Open on the WHOLE WORLD, not on the player. Opening zoomed in filled
    // a desktop window with three trees and no way to tell where they were —
    // the map's first job is orientation, and "centre on me" is one tap away.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitWorld());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Frame the entire world.
  void _fitWorld() {
    if (_viewport.isEmpty) return;
    final b = WorldMapGeometry.bounds;
    final k = _fitScale;
    final paintedHeight = _viewport.width * b.height / b.width;
    setState(() {
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          (_viewport.width - _viewport.width * k) / 2,
          (_viewport.height - paintedHeight * k) / 2,
          0,
          1,
        )
        ..scaleByDouble(k, k, 1, 1);
    });
  }

  void _centreOnPlayer() => _centreOn(_here.id, max(1.6, _fitScale * 3));

  void _centreOn(String id, double scale) {
    if (_viewport.isEmpty) return;
    final at = WorldMapGeometry.positions[id];
    if (at == null) return;
    final b = WorldMapGeometry.bounds;
    // Map units -> the painter's own coordinate space at scale 1.
    final unit = _viewport.width / b.width;
    final px = (at.dx - b.left) * unit, py = (at.dy - b.top) * unit;
    setState(() {
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          _viewport.width / 2 - px * scale,
          _viewport.height / 2 - py * scale,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1);
    });
  }

  /// Zoom about the centre of the view, so the thing you were looking at stays
  /// roughly where it was.
  void _zoomBy(double factor) {
    final m = _controller.value.clone();
    final current = m.storage[0];
    final next = (current * factor).clamp(_fitScale * 0.85, 8.0);
    final k = next / current;
    final cx = _viewport.width / 2, cy = _viewport.height / 2;
    setState(() {
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          cx - (cx - m.storage[12]) * k,
          cy - (cy - m.storage[13]) * k,
          0,
          1,
        )
        ..scaleByDouble(next, next, 1, 1);
    });
  }

  /// Child-space tap position -> map coordinates.
  ///
  /// ⚠️ No matrix work here, deliberately. The [GestureDetector] sits *inside*
  /// the [InteractiveViewer]'s transformed subtree, so Flutter's hit-testing
  /// has already un-transformed the position — `localPosition` arrives in
  /// child space. An earlier version applied the inverse view transform on top
  /// of that (a double inversion): taps were ~43 px off at fit scale and the
  /// responsive spot left the screen entirely at 3× zoom. Guarded by
  /// `world_map_screen_test.dart`, which taps real pin positions at both fit
  /// and zoomed scales.
  Offset _toMap(Offset local, Size size) {
    final b = WorldMapGeometry.bounds;
    final unit = size.width / b.width;
    return Offset(local.dx / unit + b.left, local.dy / unit + b.top);
  }

  void _tap(Offset local, Size size) {
    final p = _toMap(local, size);
    String? hit;
    var best = double.infinity;
    WorldMapGeometry.positions.forEach((id, at) {
      final d = (at - p).distance;
      if (d < 34 && d < best) {
        best = d;
        hit = id;
      }
    });
    if (hit == null) return;
    setState(() => _selected = hit);
    _showDetails(World.byId(hit!));
  }

  Future<void> _showDetails(GameLocation loc) async {
    final connected = _here.connections.contains(loc.id);
    final isHere = loc.id == _here.id;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _PlaceSheet(
        location: loc,
        isHere: isHere,
        canTravel: connected,
        onTravel: () {
          Navigator.of(ctx).pop();
          widget.game.travelTo(loc.id);
          setState(() => _selected = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.text,
        title: Text(_here.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centre on me',
            onPressed: _centreOnPlayer,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size != _viewport) {
            _viewport = size;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.value == Matrix4.identity()) {
                _fitWorld();
              }
            });
          }
          final b = WorldMapGeometry.bounds;
          final height = size.width * b.height / b.width;
          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _controller,
                // ⚠️ The map is taller than most viewports. Constrained (the
                // default) would clamp the child to the viewport height: the
                // canvas still paints (CustomPaint does not clip) but the hit
                // area shrinks, so the bottom of the map draws yet cannot be
                // tapped on short-wide windows.
                constrained: false,
                // ⚠️ Must go below the fit scale, or a tall map can never be
                // seen whole on a wide window.
                minScale: 0.05,
                maxScale: 8,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tap(d.localPosition, size),
                  child: SizedBox(
                    width: size.width,
                    height: height,
                    child: CustomPaint(
                      painter: WorldMapPainter(
                        currentId: _here.id,
                        reachable: _here.connections.toSet(),
                        seen: widget.game.profile.discoveredLocationIds,
                        selectedId: _selected,
                      ),
                    ),
                  ),
                ),
              ),
              // Pinch works, but a mouse has nothing to pinch with.
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.add,
                      tooltip: 'Zoom in',
                      onTap: () => _zoomBy(1.4),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom out',
                      onTap: () => _zoomBy(1 / 1.4),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.fit_screen,
                      tooltip: 'Whole world',
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

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.panel.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 19, color: AppColors.text),
        ),
      ),
    ),
  );
}

/// What a place is, and whether you can get there from here.
class _PlaceSheet extends StatelessWidget {
  final GameLocation location;
  final bool isHere;
  final bool canTravel;
  final VoidCallback onTravel;

  const _PlaceSheet({
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
                      : 'No road from ${'here'}',
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

/// The map as it appears at the top of the Map tab: terrain and roads, no pins,
/// tap to open the real thing.
class WorldMapThumbnail extends StatelessWidget {
  final GameState game;
  final VoidCallback onTap;
  const WorldMapThumbnail({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final here = game.profile.location;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: _focus(here.id),
                child: SizedBox(
                  width: WorldMapGeometry.bounds.width,
                  height: WorldMapGeometry.bounds.height,
                  child: CustomPaint(
                    painter: WorldMapPainter(
                      currentId: here.id,
                      reachable: here.connections.toSet(),
                      seen: game.profile.discoveredLocationIds,
                      // A thumbnail has room for terrain, not thirty-two names.
                      showFeatureLabels: false,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_full, size: 13, color: AppColors.gold),
                    SizedBox(width: 6),
                    Text(
                      'Open map',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Frame the thumbnail on the player, clamped so it never shows empty void.
  Alignment _focus(String id) {
    final at = WorldMapGeometry.positions[id];
    if (at == null) return Alignment.center;
    final b = WorldMapGeometry.bounds;
    final x = ((at.dx - b.left) / b.width * 2 - 1).clamp(-1.0, 1.0);
    final y = ((at.dy - b.top) / b.height * 2 - 1).clamp(-1.0, 1.0);
    return Alignment(x, max(-0.75, y));
  }
}
