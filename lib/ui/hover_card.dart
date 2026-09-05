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
      final origin = box.localToGlobal(Offset.zero);
      _anchor = origin & box.size;
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
        final screen = MediaQuery.sizeOf(ctx);
        const gap = 6.0;
        // Below the tile when there is room, otherwise above it; and never
        // past the right edge.
        final left = (_anchor.left).clamp(8.0, screen.width - widget.cardWidth - 8);
        final spaceBelow = screen.height - _anchor.bottom - gap;
        final placeBelow = spaceBelow >= screen.height * 0.45;
        return Positioned(
          left: left,
          top: placeBelow ? _anchor.bottom + gap : null,
          bottom: placeBelow ? null : screen.height - _anchor.top + gap,
          width: widget.cardWidth,
          child: IgnorePointer(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screen.height * 0.6),
              child: widget.card(ctx),
            ),
          ),
        );
      },
      child: MouseRegion(onEnter: _enter, onExit: _exit, child: widget.child),
    );
  }
}
