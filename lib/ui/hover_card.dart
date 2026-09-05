import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Shows [card] floating beside [child] while a MOUSE hovers it — the rich
/// panel a desktop player would otherwise have to click ⓘ for. Touch never
/// hovers, so on a phone this widget is inert and the ⓘ dialog stays the way
/// in; the two are the same card, not two descriptions of one spell.
///
/// ⚠️ The floating card ignores pointer events: if it could be hovered
/// itself, leaving the tile INTO the card would keep it open, and a card that
/// only closes when you find its edge is a modal in disguise.
class HoverCard extends StatefulWidget {
  final Widget child;
  final WidgetBuilder card;
  final Duration delay;
  final double cardWidth;

  const HoverCard({
    super.key,
    required this.child,
    required this.card,
    this.delay = const Duration(milliseconds: 350),
    this.cardWidth = 380,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  final _portal = OverlayPortalController();
  Timer? _pending;
  Rect _anchor = Rect.zero;
  Size _overlaySize = Size.zero;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  void _enter(PointerEnterEvent _) {
    _pending?.cancel();
    _pending = Timer(widget.delay, () {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      // ⚠️ Measured in the OVERLAY's coordinate space, not the window's.
      // The app centres itself as a column on wide screens, and the nearest
      // Overlay is the column's, not the window's — a global offset fed to a
      // Positioned inside it lands the card a full column-margin to the
      // right of the tile (the first hover bug this widget shipped with).
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final origin = overlay.globalToLocal(box.localToGlobal(Offset.zero));
      _anchor = origin & box.size;
      _overlaySize = overlay.size;
      _portal.show();
      setState(() {});
    });
  }

  void _exit(PointerExitEvent _) {
    _pending?.cancel();
    if (_portal.isShowing) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (ctx) {
        final area = _overlaySize;
        const gap = 6.0;
        // The card is capped at 60% of the area's height; it goes BELOW the
        // tile whenever that much fits, and only otherwise above — flipping
        // on a looser rule put it over the element grid for tiles halfway
        // down the screen.
        final maxHeight = area.height * 0.6;
        final spaceBelow = area.height - _anchor.bottom - gap;
        final placeBelow = spaceBelow >= maxHeight ||
            spaceBelow >= _anchor.top - gap;
        final maxLeft = (area.width - widget.cardWidth - 8).clamp(8.0, double.infinity);
        final left = _anchor.left.clamp(8.0, maxLeft);
        return Positioned(
          left: left,
          top: placeBelow ? _anchor.bottom + gap : null,
          bottom: placeBelow ? null : area.height - _anchor.top + gap,
          width: widget.cardWidth,
          child: IgnorePointer(
            // ⭐ The card floats over panels painted in its own colours, so
            // it needs an edge the page does not have: a gold border, a deep
            // drop shadow and a faint gold glow lift it off the ground it
            // would otherwise blend into (designer, 2026-08-29). A page-wide
            // scrim was the alternative and was rejected — a hover that dims
            // the whole screen flickers like a modal as the mouse travels.
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE8C547), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(color: Color(0x40E8C547), blurRadius: 14),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: widget.card(ctx),
              ),
            ),
          ),
        );
      },
      child: MouseRegion(onEnter: _enter, onExit: _exit, child: widget.child),
    );
  }
}
