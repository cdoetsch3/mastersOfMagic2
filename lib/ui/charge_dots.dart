import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The charge cost of a spell, said in pips instead of words.
///
/// ⭐ **Pips, because the duel already speaks pips.** The status panels draw
/// the mage's live charge as five circles (`_chargeRow` in `duel_screen.dart`)
/// — filled for charge held, hollow for charge missing. A spell tab that says
/// its price in the same shape lets the eye do the arithmetic that the word
/// "cost 3" makes you read: three dots up top, three pips lit below, go.
///
/// ⭐ **The space is reserved whether or not anything is drawn.** House rule:
/// appearing elements never resize their host, and a button never moves under
/// the finger that pressed it. So the widget is always exactly [reservedWidth]
/// by [dotSize] — Flick (cost 0) draws nothing and still occupies the same
/// corner as Cataclysm (cost 5). Every spell tab is therefore laid out
/// identically, and a loadout swap cannot make the row breathe.
///
/// ⭐ **Right-aligned inside that reserved box**, so the dots grow leftward
/// from the corner they are pinned to. Left-aligning them would leave a
/// ragged gap between a cheap spell's dot and the button edge, and the corner
/// would stop reading as a corner.
class ChargeDots extends StatelessWidget {
  /// The spell's `chargeCost`. The engine ships 0–5; anything larger simply
  /// draws [maxDots] and still measures the same.
  final int cost;

  /// X-cost spells (Barrage) consume ALL held charge and [cost] is only the
  /// minimum. ⭐ Those draw hollow rings rather than filled dots: a solid "1"
  /// on Barrage would be a flat lie about what pressing it spends, and hollow
  /// borrows the meaning the charge meter already gives it — a pip that is not
  /// yet settled.
  final bool variable;

  final double dotSize;
  final double gap;

  /// How many dots the reserved box is sized for — the engine's charge cap.
  final int maxDots;

  final Color? color;

  const ChargeDots({
    super.key,
    required this.cost,
    this.variable = false,
    this.dotSize = 4.5,
    this.gap = 2.5,
    this.maxDots = 5,
    this.color,
  });

  /// The width the widget occupies for every possible [cost].
  double get reservedWidth => maxDots * dotSize + (maxDots - 1) * gap;

  /// What a screen reader hears. Singular/plural is left alone deliberately —
  /// "charge" is a mass noun in this game ("+1 charge, max 5"), never
  /// "charges".
  String get semanticsLabel =>
      variable ? 'costs $cost or more charge' : 'costs $cost charge';

  @override
  Widget build(BuildContext context) {
    final drawn = cost.clamp(0, maxDots);
    final tint = color ?? AppColors.textDim;
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: reservedWidth,
        height: dotSize,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < drawn; i++) ...[
                if (i > 0) SizedBox(width: gap),
                ChargeDot(size: dotSize, color: tint, filled: !variable),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One pip. Public so tests can count them without matching on paint.
class ChargeDot extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const ChargeDot({
    super.key,
    required this.size,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        // ⚠️ The ring is drawn INSIDE the box (`Border.all` on a circle does
        // not grow it), so a hollow dot measures exactly like a filled one.
        border: filled ? null : Border.all(color: color, width: 1),
      ),
    );
  }
}
