/// The '×12' on a stacked backpack slot (stacking ruling, Christian
/// 2026-09-25, mockup option A).
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A stack's count, drawn as a small dark pill at the bottom-right of an
/// item's icon.
///
/// ⭐ **Gold at a full stack** (×25 Dust, ×5 Shards) — the one glance that says
/// "the next one opens a new slot". Below the cap it is plain [AppColors.text].
///
/// ⚠️ **Nothing at all for a count of 1** — every log, potion and staff is
/// one per slot, and a '×1' on each would be twenty labels saying nothing.
///
/// ⚠️ **A fixed-size cell**, [width] × [height], whatever the number. The
/// badge is overlaid on the icon, so its own size never moves the tile — and
/// fixing it means ×5 and ×25 sit in the same place too, and a count ticking
/// from 9 to 10 does not grow the pill under the player's eye.
class StackCountBadge extends StatelessWidget {
  final int count;

  /// The def's `stackSize` — the count at which the badge turns gold.
  final int cap;

  static const double width = 24;
  static const double height = 13;

  const StackCountBadge({super.key, required this.count, required this.cap});

  /// Whether this count is a full stack — the gold state.
  bool get isFull => count >= cap;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Center(
          // ⚠️ Scale-down only: a three-digit count on a corrupt save must
          // still fit the fixed cell rather than overflow it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '×$count',
              style: TextStyle(
                color: isFull ? AppColors.gold : AppColors.text,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
