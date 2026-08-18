/// Showing a creature: generated art if it exists, pixel grid if it does not.
///
/// ⚠️ **This is the first image asset in the project.** Everything else is a
/// `CustomPainter` (README §4) and that stays true for the map, the mage, and
/// every combat effect — it is why the world is seeded and deterministic. What
/// changed is that a bestiary of 275 creatures is not something hand-placed
/// pixels can carry; see IMPLEMENTATION_PLAN.
library;

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/creature_sprite.dart';
import '../game/enemies/enemy_def.dart';
import '../game/enemies/whispering_woods_art.dart';

/// Where a creature's generated sprite lives, if one has been made.
String creatureAssetFor(EnemyDef def) =>
    'assets/creatures/${def.zoneId}/${def.id}.png';

/// Where a zone's arena backdrop lives, if one has been made.
///
/// ⭐ **Flat, and deliberately without a `manifest.json`** — unlike
/// `assets/creatures/<zone>/`, which has one. The creature manifest earns its
/// keep because a zone is a *directory* of eleven files named for hand-written
/// creature ids, so "the roster and the art agree" is a real claim that can be
/// checked. A zone has exactly **one** backdrop and its name is the zone id, so
/// a manifest here could only restate this expression. What is checked instead
/// is the reverse — that nothing in `assets/backgrounds/` is named for a place
/// that does not exist — in `test/arena_backdrop_test.dart`, because that is
/// the only mistake a flat convention still allows.
///
/// ⚠️ The generator writes these — `tool/pixelate.py --mode background`, 384×216
/// out of `art/source/backgrounds/`, one source file per zone id.
String backdropFor(String zoneId) => 'assets/backgrounds/$zoneId.png';

/// A creature, drawn the best way currently available.
///
/// ⭐ **Falls back rather than failing.** Art arrives one zone at a time, so a
/// creature with no PNG yet gets its pixel grid, and one with neither gets an
/// elemental silhouette. Nothing renders as a wizard.
class CreatureView extends StatelessWidget {
  final EnemyDef def;
  final double height;
  final int charge;
  final bool facingRight;
  final bool defeated;

  const CreatureView({
    super.key,
    required this.def,
    required this.height,
    this.charge = 0,
    this.facingRight = true,
    this.defeated = false,
  });

  @override
  Widget build(BuildContext context) {
    final element = def.elements.isEmpty
        ? MagicElement.flora
        : def.elements.first;

    final fallback = _PixelFallback(
      def: def,
      element: element,
      height: height,
      charge: charge,
      facingRight: facingRight,
      defeated: defeated,
    );

    return _Posed(
      facingRight: facingRight,
      defeated: defeated,
      child: Image.asset(
        creatureAssetFor(def),
        height: height,
        // ⭐ **Nearest-neighbour, always.** The sprites are 64px and displayed
        // at ~160; the default smooth filter turns deliberate pixel art into
        // a blur, which is the single easiest way to waste the whole pipeline.
        filterQuality: FilterQuality.none,
        // ⚠️ Not an error — most creatures have no art yet.
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Bob and topple, so generated art behaves like the pixel sprites beside it.
class _Posed extends StatefulWidget {
  final Widget child;
  final bool facingRight;
  final bool defeated;

  const _Posed({
    required this.child,
    required this.facingRight,
    required this.defeated,
  });

  @override
  State<_Posed> createState() => _PosedState();
}

class _PosedState extends State<_Posed> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _bob,
    builder: (context, child) {
      final t = _bob.value * 2 * 3.14159;
      return Transform.translate(
        offset: Offset(
          0,
          widget.defeated ? 0 : 3 * (t.remainder(6.28) - 3.14) / 3.14,
        ),
        child: Transform.rotate(
          angle: widget.defeated ? (widget.facingRight ? -1.57 : 1.57) : 0,
          child: child,
        ),
      );
    },
    child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(widget.facingRight ? 1.0 : -1.0, 1.0, 1.0, 1.0),
      child: widget.child,
    ),
  );
}

/// The pixel grid, or an elemental silhouette if the creature has no grid.
class _PixelFallback extends StatelessWidget {
  final EnemyDef def;
  final MagicElement element;
  final double height;
  final int charge;
  final bool facingRight;
  final bool defeated;

  const _PixelFallback({
    required this.def,
    required this.element,
    required this.height,
    required this.charge,
    required this.facingRight,
    required this.defeated,
  });

  @override
  Widget build(BuildContext context) {
    final art = WhisperingWoodsArt.byEnemyId[def.id];
    final palette = SpritePalette.forElement(element);
    if (art == null) {
      // ⚠️ Deliberately plain. A creature with no art at all should look
      // unfinished rather than borrow someone else's body — which is what the
      // mage sprite was doing to every animal in the game.
      return SizedBox(
        height: height,
        width: height * 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.body,
            borderRadius: BorderRadius.circular(height * 0.12),
            border: Border.all(color: palette.glow, width: 2),
          ),
        ),
      );
    }
    return CreatureSprite(
      art: art,
      palette: palette,
      charge: charge,
      facingRight: facingRight,
      defeated: defeated,
      height: height,
    );
  }
}

/// A zone's arena backdrop, if one exists.
///
/// ⚠️ Sits **behind** everything and must lose to it. The pipeline already
/// darkens and desaturates; this adds a scrim on top, because a backdrop that
/// competes with the creature standing on it defeats the point.
class ArenaBackdrop extends StatelessWidget {
  final String zoneId;

  const ArenaBackdrop({super.key, required this.zoneId});

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Image.asset(
      backdropFor(zoneId),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      color: const Color(0xB3141021),
      colorBlendMode: BlendMode.srcOver,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}
