/// Helpers the stage-2 catalogue files share (ACHIEVEMENTS §5).
///
/// 📝 Kept out of `achievements.dart` so the catalogue files depend on the
/// model, never on each other.
library;

import '../achievements.dart';

/// [done] of [total], with [done] capped at [total] — ⭐ the same contract
/// as [AchievementDef.progress]: the screen prints it as-is, so a hundred and
/// twelve of a hundred reads `100/100`.
AchievementProgress cappedProgress(int done, int total) =>
    (done: done < total ? done : total, total: total);

/// [n] with thousands commas — `25000` reads `'25,000'`, the way the blurbs
/// and §5 write numbers.
String groupedDigits(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// The roman numeral for a tier, 1–5 — `'<Element> Mastery III'`.
String tierNumeral(int tier) => const ['I', 'II', 'III', 'IV', 'V'][tier - 1];
