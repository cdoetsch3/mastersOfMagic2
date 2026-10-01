import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/achievements.dart';
import '../game/game_state.dart';
import '../game/player_profile.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';

/// Every achievement in the catalogue, earned or not — the "Ledger" (ruling,
/// Christian playtest 2026-09-30 note 7, mockup A): a count in the app bar,
/// a summary panel, a filter row, then the entries grouped by category.
///
/// ⭐ **Unearned entries are listed, dimmed** — not hidden by default. The
/// point of the list is to say what there is to do; hiding what is earned is
/// the player's choice ([_hideEarned]), never the screen's.
///
/// ⭐ **The filter row is press-stable**: a fixed-height horizontal scroller
/// ([AchievementsScreen.filterRowHeight]), so a long label scrolls rather
/// than wrapping the row taller, and picking a chip never moves the list.
///
/// 📝 **No dates.** The profile stores the ids earned and nothing else — no
/// timestamp — so "earned on…" would be a new field on every save first.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  /// The filter row, for the press-stability test.
  static const filterRowKey = ValueKey('achievements-filter-row');

  /// ⭐ The filter row's one height, whatever is selected.
  static const double filterRowHeight = 40;

  /// What an empty view says — everything filtered or hidden away.
  static const emptyLine = 'Nothing left in this view.';

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  /// The category chip lit, or null for All.
  AchievementCategory? _category;
  bool _hideEarned = false;

  @override
  Widget build(BuildContext context) {
    final profile = GameStateScope.of(context).profile;
    final earned = profile.achievements;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Achievements'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: _CountPill(achievementCountLabel(earned))),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: _Summary(earned: Achievements.earnedCount(earned)),
            ),
            _filterRow(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                children: _entries(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ The category chips scroll; **Hide earned is pinned** at the right
  /// end. At phone width the five chips and the toggle do not fit in one
  /// line, and a toggle scrolled out of sight is a toggle nobody finds.
  Widget _filterRow() => SizedBox(
    key: AchievementsScreen.filterRowKey,
    height: AchievementsScreen.filterRowHeight,
    child: Row(
      children: [
        Expanded(
          // 📝 Not a lazy ListView: five chips gain nothing from laziness,
          // and an unbuilt chip past the fold is one a test cannot reach.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 14, right: 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  on: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in AchievementCategory.values)
                  _FilterChip(
                    label: c.label,
                    on: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: _FilterChip(
            label: 'Hide earned',
            icon: Icons.visibility_off_outlined,
            on: _hideEarned,
            onTap: () => setState(() => _hideEarned = !_hideEarned),
          ),
        ),
      ],
    ),
  );

  /// The sections and rows the filters leave, or the one empty line.
  ///
  /// ⭐ A section with nothing left in it is dropped whole, heading too; and
  /// with a category chip lit there are no headings at all — the chip
  /// already says which category this is.
  List<Widget> _entries(PlayerProfile profile) {
    final earned = profile.achievements;
    final out = <Widget>[];
    final categories = _category == null
        ? AchievementCategory.values
        : [_category!];
    for (final c in categories) {
      final rows = [
        for (final def in Achievements.inCategory(c))
          if (!(_hideEarned && earned.contains(def.id)))
            AchievementRow(
              def: def,
              earned: earned.contains(def.id),
              progress: def.progress?.call(profile),
            ),
      ];
      if (rows.isEmpty) continue;
      if (_category == null) out.add(_SectionLabel(c.label));
      out.addAll(rows);
    }
    if (out.isEmpty) {
      out.add(
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text(
            AchievementsScreen.emptyLine,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFaint, fontSize: 13),
          ),
        ),
      );
    }
    return out;
  }
}

/// The app bar's `n / N`.
class _CountPill extends StatelessWidget {
  final String text;
  const _CountPill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.panelHi,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderDim),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// `Earned`, the percent, and a bar.
///
/// ⚠️ **No `n of N` here** (coordinator, 2026-09-30): the app bar's pill
/// already says it, and one number is said once.
class _Summary extends StatelessWidget {
  final int earned;
  const _Summary({required this.earned});

  @override
  Widget build(BuildContext context) {
    final total = Achievements.all.length;
    // ⚠️ Floored, so 100% means every last one — never 11 of 12 rounded up.
    final percent = total == 0 ? 0 : earned * 100 ~/ total;
    return GamePanel(
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Earned',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(color: AppColors.gold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Bar(value: total == 0 ? 0 : earned / total, height: 6),
        ],
      ),
    );
  }
}

/// A rounded progress bar in gold on the dim border colour.
class _Bar extends StatelessWidget {
  final double value;
  final double height;
  const _Bar({required this.value, required this.height});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value,
      minHeight: height,
      backgroundColor: AppColors.borderDim,
      color: AppColors.gold,
    ),
  );
}

/// ⚠️ Hand-rolled rather than Material's FilterChip, for the same reason as
/// the shop's tab chips: the themed chip brings its own surface and ripple.
///
/// ⭐ An [icon] is always drawn when given, lit or not, so toggling a chip
/// never changes its width.
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool on;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.bg : AppColors.textDim;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: on ? AppColors.gold : Colors.transparent,
              border: Border.all(color: on ? AppColors.gold : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A category's heading, in the small-caps style of the Skills ledger.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 6, 0, 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 9.5,
        letterSpacing: 1.2,
      ),
    ),
  );
}

/// One catalogue entry: a medal cell, the name and blurb, and — while a
/// countable entry is unearned — a thin bar with its count.
class AchievementRow extends StatelessWidget {
  final AchievementDef def;
  final bool earned;

  /// How far a countable entry has come; null for a one-shot.
  final AchievementProgress? progress;

  /// ⭐ The medal cell's one width, earned or not, so the name sits at one x
  /// the day it is earned.
  static const double medalSize = 34;

  /// The medal cell of entry [id], for the layout tests.
  static ValueKey<String> medalKey(String id) => ValueKey('medal-$id');

  const AchievementRow({
    super.key,
    required this.def,
    required this.earned,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = earned ? AppColors.text : AppColors.textFaint;
    final counted = progress;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        color: AppColors.panel,
        padding: const EdgeInsets.all(12),
        borderColor: earned ? AppColors.gold : AppColors.borderDim,
        child: Row(
          // ⭐ Top-aligned: the bar leaving on earning shortens the text,
          // and a centred medal would hop up beside it.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Medal(key: medalKey(def.id), earned: earned),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.name,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.blurb,
                    style: TextStyle(
                      color: earned ? AppColors.textDim : AppColors.textFaint,
                      fontSize: 12,
                    ),
                  ),
                  if (!earned && counted != null) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _Bar(
                            value: counted.total == 0
                                ? 0
                                : counted.done / counted.total,
                            height: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          progressLabel(counted),
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `'n/N'` — the count beside a row's bar.
String progressLabel(AchievementProgress p) => '${p.done}/${p.total}';

/// ✓ on gold when earned; a plain dim dashed ring when not.
///
/// ⚠️ **No count in the ring** (coordinator, 2026-09-30): the count lives
/// once, beside the row's bar — a second copy in the ring was the same
/// number said twice.
class _Medal extends StatelessWidget {
  final bool earned;
  const _Medal({super.key, required this.earned});

  @override
  Widget build(BuildContext context) {
    const size = AchievementRow.medalSize;
    if (earned) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold,
        ),
        child: const Icon(Icons.check, size: 20, color: AppColors.bg),
      );
    }
    return const SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DashedRing(color: AppColors.textFaint)),
    );
  }
}

/// A circle of short arcs — the not-yet medal.
class _DashedRing extends CustomPainter {
  final Color color;
  const _DashedRing({required this.color});

  static const int _dashes = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    const step = 2 * math.pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, i * step, step * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}

/// The toast for a newly earned achievement: `'Achievement · <name>'` on the
/// gold edge. ⭐ Takes a captured [AppBannerMessenger] (the
/// `appBannerOf`-before-the-await idiom), because the caller usually earns
/// it by an action that tears its own screen down.
void announceAchievement(AppBannerMessenger banner, AchievementDef def) =>
    banner.show(achievementToastText(def), color: AppColors.gold);

/// [announceAchievement] for one or more at once — ⭐ one toast, because a
/// second banner replaces the first rather than queueing behind it.
void announceAchievements(
  AppBannerMessenger banner,
  List<AchievementDef> defs,
) => banner.show(achievementsToastText(defs), color: AppColors.gold);

/// The toast's words, one owner for the screen and its tests.
String achievementToastText(AchievementDef def) => 'Achievement · ${def.name}';

/// The toast's words for [defs]: the single form for one, and
/// `'Achievements · A, B'` for several.
String achievementsToastText(List<AchievementDef> defs) => defs.length == 1
    ? achievementToastText(defs.single)
    : 'Achievements · ${defs.map((d) => d.name).join(', ')}';

/// The Profile row's trailing count, `'n / N'`. ⚠️ Counts only ids the
/// catalogue still knows, so a retired entry cannot push n past N.
String achievementCountLabel(Set<String> earned) =>
    '${Achievements.earnedCount(earned)} / ${Achievements.all.length}';
