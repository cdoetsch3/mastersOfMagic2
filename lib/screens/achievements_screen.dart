import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/achievement_families.dart';
import '../game/achievements.dart';
import '../game/game_state.dart';
import '../game/player_profile.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import 'level_up_screen.dart';

/// Every achievement in the catalogue, earned or not — the "Ledger"
/// (ACHIEVEMENTS §7.2, mockup A, with Christian's filters and the 2026-10-01
/// Claim ruling): the points in the app bar, a summary panel, a filter row,
/// then the entries grouped by category.
///
/// ⭐ **A tiered family is one row** ([rowsFor]): its highest earned tier,
/// with progress toward the next. Every count on the screen is of entries
/// (tiers), never of rows — a family of five is five in `n / N`.
///
/// ⭐ **Unearned entries are listed, dimmed** — not hidden by default. The
/// point of the list is to say what there is to do; hiding what is earned is
/// the player's choice ([_hideEarned]), never the screen's.
///
/// ⭐ **Press-stable throughout.** The filter row is one fixed height
/// ([AchievementsScreen.filterRowHeight]); its two toggles are pinned and
/// carry their icon lit or not; every row reserves its claim cell
/// ([AchievementRow.claimCellWidth]); Claim all is always drawn, dim when
/// nothing waits; and the To claim view keeps the rows it opened with, so
/// pressing Claim there never pulls the next row up under the thumb.
///
/// 📝 **No dates.** The profile stores the ids earned and nothing else — no
/// timestamp — so "earned on…" would be a new field on every save first.
class AchievementsScreen extends StatefulWidget {
  /// ⭐ The entries to list — [Achievements.all] in the game. A parameter so
  /// the tests can hand it synthetic families; ⚠️ claiming still goes through
  /// [GameState], which pays from [Achievements.all].
  final List<AchievementDef> catalogue;

  const AchievementsScreen({super.key, this.catalogue = Achievements.all});

  /// The summary's Claim all button, for the tests.
  static const claimAllKey = ValueKey('achievements-claim-all');

  /// ⭐ The summary's claim row's one height.
  static const double claimRowHeight = 32;

  /// The filter row, for the press-stability test.
  static const filterRowKey = ValueKey('achievements-filter-row');

  /// ⭐ The filter row's one height, whatever is selected.
  static const double filterRowHeight = 40;

  /// What an empty view says — everything filtered or hidden away.
  static const emptyLine = 'Nothing left in this view.';

  /// A row's claim button.
  static const claimLabel = 'Claim';

  /// What a row's claim cell says once its reward is paid.
  static const claimedLabel = 'Claimed';

  /// The summary's claim-everything button.
  static const claimAllLabel = 'Claim all';

  /// The All chip.
  static const allLabel = 'All';

  /// The pinned toggle that drops finished rows.
  static const hideEarnedLabel = 'Hide earned';

  /// The pinned toggle that shows only rows with a reward waiting.
  static const toClaimLabel = 'To claim';

  /// The summary's heading.
  static const earnedLabel = 'Earned';

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  /// The category chip lit, or null for All.
  AchievementCategory? _category;
  bool _hideEarned = false;

  /// The To claim view's rows ([FamilyRow.key]s), or null while it is off.
  ///
  /// ⭐ **A snapshot, taken when the toggle is pressed** — not re-asked every
  /// build. A row paid in this view stays, reading Claimed, until the view
  /// is changed: otherwise each Claim would drop its row and pull the next
  /// one's button up under the thumb.
  Set<String>? _toClaim;

  /// Claims what [row] has waiting — ⭐ its lowest unclaimed tier — then,
  /// like every other XP gain, shows a level crossed.
  Future<void> _claim(GameState game, FamilyRow row) async {
    final tier = row.claimable;
    if (tier == null) return;
    await game.claimAchievement(tier.id);
    await _showLevelUpIfAny(game);
  }

  /// Claims everything claimable in one write, and says what it paid.
  Future<void> _claimAll(GameState game) async {
    // ⚠️ Captured before the await (the app_banner idiom): a level-up route
    // may be on top by the time the banner would be looked up.
    final banner = appBannerOf(context);
    final paid = await game.claimAllAchievements();
    if (paid != Reward.none) {
      banner.show(claimedBannerText(paid), color: AppColors.gold);
    }
    await _showLevelUpIfAny(game);
  }

  /// ⚠️ A claim's XP can cross a level, and nothing else on this screen
  /// would ever say so — the duel flows that normally surface
  /// `pendingLevelUp` are not on the stack. Same shape as the adventure's.
  Future<void> _showLevelUpIfAny(GameState game) async {
    final level = game.pendingLevelUp;
    final from = game.pendingLevelUpFrom;
    if (level == null || !mounted) return;
    game.acknowledgeLevelUp();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelUpScreen(from: from ?? level - 1, to: level),
      ),
    );
  }

  void _toggleToClaim(List<FamilyRow> rows) => setState(() {
    _toClaim = _toClaim != null
        ? null
        : {
            for (final r in rows)
              if (r.claimable != null) r.key,
          };
  });

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final profile = game.profile;
    final catalogue = widget.catalogue;
    final rows = rowsFor(catalogue, profile);
    final waiting = [
      for (final a in catalogue)
        if (profile.achievements.contains(a.id) &&
            !profile.claimedAchievements.contains(a.id))
          a,
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Achievements'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _CountPill(
                pointsLabel(_pointsOf(catalogue, profile.achievements)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: _Summary(
                earned: _earnedOf(catalogue, profile.achievements),
                total: catalogue.length,
                waiting: Reward.sum([for (final a in waiting) a.reward]),
                onClaimAll: waiting.isEmpty ? null : () => _claimAll(game),
              ),
            ),
            _filterRow(rows),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                children: _entries(game, rows),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ The category chips scroll; **Hide earned and To claim are pinned** at
  /// the right end. At phone width the chips and the toggles do not fit in
  /// one line, and a toggle scrolled out of sight is a toggle nobody finds.
  Widget _filterRow(List<FamilyRow> rows) => SizedBox(
    key: AchievementsScreen.filterRowKey,
    height: AchievementsScreen.filterRowHeight,
    child: Row(
      children: [
        Expanded(
          // 📝 Not a lazy ListView: eight chips gain nothing from laziness,
          // and an unbuilt chip past the fold is one a test cannot reach.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 14, right: 4),
            child: Row(
              children: [
                _FilterChip(
                  label: AchievementsScreen.allLabel,
                  on: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                // 📝 No chip for a category with nothing in it — a chip that
                // can only ever show the empty line is a promise the screen
                // cannot keep.
                for (final c in AchievementCategory.values)
                  if (widget.catalogue.any((a) => a.category == c))
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterChip(
                label: AchievementsScreen.hideEarnedLabel,
                icon: Icons.visibility_off_outlined,
                on: _hideEarned,
                onTap: () => setState(() => _hideEarned = !_hideEarned),
              ),
              _FilterChip(
                label: AchievementsScreen.toClaimLabel,
                icon: Icons.redeem_outlined,
                on: _toClaim != null,
                onTap: () => _toggleToClaim(rows),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Whether [row] survives the filters.
  ///
  /// ⭐ Hide earned drops a row with **nothing left to earn** — a family
  /// part-way up its tiers stays, because it is still something to do.
  bool _passes(FamilyRow row) {
    if (_category != null && row.category != _category) return false;
    if (_hideEarned && row.complete) return false;
    final toClaim = _toClaim;
    if (toClaim != null && !toClaim.contains(row.key)) return false;
    return true;
  }

  /// The sections and rows the filters leave, or the one empty line.
  ///
  /// ⭐ A section with nothing left in it is dropped whole, heading too; and
  /// with a category chip lit there are no headings at all — the chip
  /// already says which category this is.
  List<Widget> _entries(GameState game, List<FamilyRow> rows) {
    final earned = game.profile.achievements;
    final out = <Widget>[];
    for (final c in AchievementCategory.values) {
      final shown = [
        for (final r in rows)
          if (r.category == c && _passes(r))
            AchievementRow(
              key: ValueKey('row-${r.key}'),
              row: r,
              onClaim: r.claimable == null ? null : () => _claim(game, r),
            ),
      ];
      if (shown.isEmpty) continue;
      if (_category == null) {
        // ⚠️ Counted over the whole category, filters or not, and in
        // entries — a family of five is five here.
        final inCat = [
          for (final a in widget.catalogue)
            if (a.category == c) a,
        ];
        out.add(
          _SectionLabel(
            sectionLabel(c.label, _earnedOf(inCat, earned), inCat.length),
          ),
        );
      }
      out.addAll(shown);
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

/// How many of [catalogue] [earned] holds. ⚠️ A retired or future id is not
/// counted, so the count can never pass the catalogue's length.
int _earnedOf(List<AchievementDef> catalogue, Set<String> earned) =>
    catalogue.where((a) => earned.contains(a.id)).length;

/// The points of every entry of [catalogue] in [earned] — claimed or not:
/// points are for earning, rewards for claiming.
int _pointsOf(List<AchievementDef> catalogue, Set<String> earned) =>
    catalogue.fold(0, (sum, a) => earned.contains(a.id) ? sum + a.points : sum);

/// The app bar's points.
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

/// `Earned` and `n / N` over a bar; under them what is waiting and Claim
/// all.
///
/// ⚠️ **One number, said once**: the points live in the app bar's pill
/// (where §7.2's mockup puts them), the count here beside its bar.
///
/// ⭐ Claim all is **always drawn** — dim and inert when nothing waits — so
/// claiming everything changes a colour and moves nothing.
class _Summary extends StatelessWidget {
  final int earned;
  final int total;

  /// What Claim all would pay — [Reward.none] when nothing waits.
  final AchievementReward waiting;

  /// Null when nothing is claimable — then Claim all is drawn dim.
  final VoidCallback? onClaimAll;

  const _Summary({
    required this.earned,
    required this.total,
    required this.waiting,
    required this.onClaimAll,
  });

  @override
  Widget build(BuildContext context) => GamePanel(
    color: AppColors.panel,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AchievementsScreen.earnedLabel,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              countLabel(earned, total),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Bar(value: total == 0 ? 0 : earned / total, height: 6),
        const SizedBox(height: 8),
        SizedBox(
          height: AchievementsScreen.claimRowHeight,
          child: Row(
            children: [
              Expanded(
                child: onClaimAll == null
                    ? const SizedBox.shrink()
                    : Text(
                        rewardLabel(waiting),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              _ClaimButton(
                key: AchievementsScreen.claimAllKey,
                label: AchievementsScreen.claimAllLabel,
                onTap: onClaimAll,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The gold Claim pill — a row's, and the summary's Claim all. Dim and inert
/// when [onTap] is null, at the same size.
///
/// ⚠️ Hand-rolled like [_FilterChip], for the same reason: the themed
/// buttons bring their own surface and padding.
class _ClaimButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ClaimButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final live = onTap != null;
    return Material(
      color: live ? AppColors.gold : AppColors.borderDim,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: live ? AppColors.bg : AppColors.textFaint,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

/// A category's heading and its count: `Campaign · 19 / 81`.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 0, 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// The three faces of a row's medal.
enum MedalState {
  /// A dim dashed ring: not earned yet.
  unearned,

  /// A gold ✓ in a gold ring: earned, a reward waiting.
  waiting,

  /// A ✓ on solid gold: earned and paid.
  claimed,
}

/// One row of the list: a stand-alone entry, or a tiered family at its
/// current tier ([FamilyRow]). A medal cell; the name, blurb and reward line;
/// a bar with its count while there is something left to count toward; and
/// the claim cell.
///
/// ⚠️ **A hidden entry, unearned, is `???`** — no blurb and no bar, either of
/// which would say what it is for. Its reward line stays: what it pays is
/// not a spoiler.
class AchievementRow extends StatelessWidget {
  final FamilyRow row;

  /// Pays [FamilyRow.claimable] — non-null only while a tier waits, and then
  /// the row draws Claim.
  final VoidCallback? onClaim;

  /// ⭐ The medal cell's one width, whatever its face, so the name sits at
  /// one x the day it is earned.
  static const double medalSize = 34;

  /// ⭐ The claim cell's one width, on **every** row, Claim drawn or not — so
  /// the text column is one width down the whole list, and pressing Claim
  /// moves nothing.
  static const double claimCellWidth = 70;

  /// ⭐ …and its one height: a row whose text ran shorter than the button
  /// would otherwise shrink when Claim leaves.
  static const double claimCellHeight = 30;

  /// What a hidden, unearned entry is called.
  static const hiddenName = '???';

  /// The medal cell of row [key] ([FamilyRow.key]), for the layout tests.
  static ValueKey<String> medalKey(String key) => ValueKey('medal-$key');

  /// The claim cell of row [key] ([FamilyRow.key]), for the layout tests.
  static ValueKey<String> claimCellKey(String key) => ValueKey('claim-$key');

  const AchievementRow({super.key, required this.row, this.onClaim});

  /// Which face the medal shows.
  MedalState get medal => !row.earned
      ? MedalState.unearned
      : row.claimable != null
      ? MedalState.waiting
      : MedalState.claimed;

  @override
  Widget build(BuildContext context) {
    final earned = row.earned;
    final veiled = row.veiled;
    final counted = veiled ? null : row.progress;
    // ⭐ The line says what Claim would pay while a tier waits — for a
    // family that may be a lower tier than the one named, paid in order.
    final paying = row.claimable ?? row.shown;
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
            _Medal(key: medalKey(row.key), state: medal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    veiled ? hiddenName : row.shown.name,
                    style: TextStyle(
                      color: earned ? AppColors.text : AppColors.textFaint,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!veiled) ...[
                    const SizedBox(height: 2),
                    Text(
                      row.shown.blurb,
                      style: TextStyle(
                        color: earned ? AppColors.textDim : AppColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    rewardLabel(paying.reward),
                    style: TextStyle(
                      color: onClaim != null
                          ? AppColors.gold
                          : AppColors.textFaint,
                      fontSize: 11,
                    ),
                  ),
                  if (counted != null) ...[
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
            const SizedBox(width: 8),
            SizedBox(
              key: claimCellKey(row.key),
              width: claimCellWidth,
              height: claimCellHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: onClaim != null
                    ? _ClaimButton(
                        label: AchievementsScreen.claimLabel,
                        onTap: onClaim,
                      )
                    : row.claimed
                    ? const Padding(
                        // The button's own padding, so the word sits where
                        // the button's did.
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          AchievementsScreen.claimedLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `'4,800 / 5,000'` — the count beside a row's bar.
String progressLabel(AchievementProgress p) => countLabel(p.done, p.total);

/// `'n / N'`, thousands grouped — the summary's count and a bar's.
String countLabel(int n, int total) =>
    '${groupedNumber(n)} / ${groupedNumber(total)}';

/// A section heading: `'Campaign · 19 / 81'`, in entries (tiers).
String sectionLabel(String label, int earned, int total) =>
    '$label · ${countLabel(earned, total)}';

/// The face of the medal: a dashed ring, a gold ring with a ✓, or a ✓ on
/// solid gold.
///
/// ⚠️ **No count in the ring** (coordinator, 2026-09-30): the count lives
/// once, beside the row's bar — a second copy in the ring was the same
/// number said twice.
class _Medal extends StatelessWidget {
  final MedalState state;
  const _Medal({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const size = AchievementRow.medalSize;
    switch (state) {
      case MedalState.unearned:
        return const SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _DashedRing(color: AppColors.textFaint)),
        );
      case MedalState.waiting:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 1.5),
          ),
          child: const Icon(Icons.check, size: 20, color: AppColors.gold),
        );
      case MedalState.claimed:
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

/// The banner after Claim all: `'Claimed +1,250 XP · +800 gold · +6 RP'`.
String claimedBannerText(AchievementReward paid) =>
    'Claimed ${rewardLabel(paid)}';

/// The Profile row's trailing count, `'n / N'`. ⚠️ Counts only ids the
/// [catalogue] still knows, so a retired entry cannot push n past N; and ⭐
/// counts entries (tiers), not the screen's collapsed rows.
String achievementCountLabel(
  Set<String> earned, {
  List<AchievementDef> catalogue = Achievements.all,
}) => countLabel(_earnedOf(catalogue, earned), catalogue.length);

/// The Profile row's trailing: ⭐ `'n to claim'` while any reward waits —
/// the one thing worth a glance from the Profile — else [achievementCountLabel].
/// ⚠️ n is tiers waiting, not families: three tiers of one family are three.
String achievementProfileTrailing(
  PlayerProfile p, {
  List<AchievementDef> catalogue = Achievements.all,
}) {
  final waiting = catalogue
      .where(
        (a) =>
            p.achievements.contains(a.id) &&
            !p.claimedAchievements.contains(a.id),
      )
      .length;
  return waiting > 0
      ? '$waiting to claim'
      : achievementCountLabel(p.achievements, catalogue: catalogue);
}

/// A row's reward line: `'+250 XP · +150 gold'`, and `' · +1 RP'` when the
/// entry pays any.
String rewardLabel(AchievementReward r) =>
    '+${groupedNumber(r.xp)} XP · +${groupedNumber(r.gold)} gold'
    '${r.rp > 0 ? ' · +${groupedNumber(r.rp)} RP' : ''}';

/// The app bar's total: `'45 points'`.
String pointsLabel(int points) => '${groupedNumber(points)} points';

/// [n] with thousands commas — `5000` reads `'5,000'`, as §6 writes it.
String groupedNumber(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
