/// How a flat achievement catalogue becomes the Achievements screen's rows.
///
/// ⭐ **A tiered family is ONE row** (ACHIEVEMENTS §3.1, §7.2). Twelve
/// elements × five Mastery tiers would be sixty rows otherwise; the list
/// shows each family at its current tier, with progress toward the next.
///
/// ⭐ **Pure.** Defs and a profile in, rows out — no widgets, no
/// [AchievementDef] lookups by id — so the laws are tested without a screen
/// and the screen can be handed a synthetic catalogue.
///
/// ⚠️ **Counts are of tiers, never of rows.** A family is five entries on
/// disk and five in every `n / N`; collapsing is only how they are drawn.
library;

import 'achievements.dart';
import 'player_profile.dart';

/// One row of the Achievements screen: a stand-alone entry, or a whole
/// tiered family collapsed to its current tier.
class FamilyRow {
  /// The family's tiers, lowest first — or the one stand-alone entry.
  final List<AchievementDef> tiers;

  /// The entry the row is named after: ⭐ the **highest earned** tier, or
  /// tier I while nothing is earned. Its name, blurb and `hidden` flag are
  /// what the row prints.
  final AchievementDef shown;

  /// Whether any tier is earned (for a stand-alone entry: whether it is).
  final bool earned;

  /// The tier Claim pays, or null when nothing waits.
  ///
  /// ⭐ The **lowest** earned-but-unclaimed tier — so a player who earned
  /// I, II and III while away is paid I, then II, then III, in order.
  final AchievementDef? claimable;

  /// The tier being worked toward: the one after the highest earned (tier I
  /// while nothing is earned). Null once every tier is earned.
  final AchievementDef? next;

  /// How far [next] has come, or null — when [next] is, or is a one-shot.
  final AchievementProgress? progress;

  const FamilyRow({
    required this.tiers,
    required this.shown,
    required this.earned,
    required this.claimable,
    required this.next,
    required this.progress,
  });

  /// The row's stable key: the family, or the stand-alone entry's id.
  String get key => shown.family ?? shown.id;

  /// The section the row sits in — its tiers' category.
  AchievementCategory get category => shown.category;

  /// Whether this row stands for a tiered family.
  bool get isFamily => shown.family != null;

  /// Nothing left to earn: a stand-alone entry earned, or every tier.
  bool get complete => next == null;

  /// Earned, and nothing waiting to be claimed.
  bool get claimed => earned && claimable == null;

  /// ⚠️ A spoiler: the shown entry is hidden and not earned yet — the row
  /// prints `???`, no blurb and no progress (§7.1).
  bool get veiled => shown.hidden && !earned;
}

/// The rows for [catalogue] as [profile] stands, in catalogue order.
///
/// ⭐ A stand-alone entry is one row; a family is one row, at the position of
/// its first member in [catalogue], whatever order its tiers are listed in.
List<FamilyRow> rowsFor(List<AchievementDef> catalogue, PlayerProfile profile) {
  // Keyed by family (or id), in first-seen order — a LinkedHashMap.
  final groups = <String, List<AchievementDef>>{};
  for (final def in catalogue) {
    groups.putIfAbsent(def.family ?? def.id, () => []).add(def);
  }
  return [for (final g in groups.values) _rowOf(g, profile)];
}

FamilyRow _rowOf(List<AchievementDef> group, PlayerProfile profile) {
  final tiers = [...group]
    ..sort((a, b) => (a.tier ?? 0).compareTo(b.tier ?? 0));
  final earned = profile.achievements;
  final claimed = profile.claimedAchievements;

  AchievementDef? highest;
  AchievementDef? claimable;
  for (final t in tiers) {
    if (!earned.contains(t.id)) continue;
    highest = t;
    if (claimable == null && !claimed.contains(t.id)) claimable = t;
  }

  // ⚠️ The tier after the HIGHEST earned, not the first unearned: a save
  // holding tier II without tier I is still working toward III.
  final next = highest == null
      ? tiers.first
      : tiers.skip(tiers.indexOf(highest) + 1).firstOrNull;

  return FamilyRow(
    tiers: tiers,
    shown: highest ?? tiers.first,
    earned: highest != null,
    claimable: claimable,
    next: next,
    progress: next?.progress?.call(profile),
  );
}
