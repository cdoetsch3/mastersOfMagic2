import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../ui/app_theme.dart';
import '../ui/rating_text.dart';
import 'account_screen.dart';
import 'coming_soon_screen.dart';
import 'gameplay_guide_screen.dart';
import 'skills_screen.dart';

/// The Profile — everything about *you* rather than about the world: who you
/// are (the hero), how you are doing (three chips), and one panel of rows for
/// the screens that belong to a character rather than to a tab.
///
/// ⭐ Reached from the name pill in `PlayerHeader` (ruling 2026-09-21, mockup
/// option A), which every tab already draws — so there is exactly one door
/// in, and no tab has to spend a card on Skills or the rules again.
///
/// ⭐ **Structure now, screens later** (same ruling). Achievements, the
/// Bestiary and the Item library are rows with nothing behind them yet; they
/// exist so the shape of the profile is settled, and each pushes
/// [ComingSoonScreen]. ⚠️ Do **not** grow their content here — a trailing
/// count that counts something real is the first step to a screen this file
/// was told not to build.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final p = GameStateScope.of(context).profile;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _Hero(
              name: p.name,
              level: p.level,
              xpInto: p.xpIntoLevel,
              xpFor: p.xpForThisLevel,
            ),
            const SizedBox(height: 16),
            _StatChips(
              ratingGeared: p.ratingGeared,
              ratingAcademy: p.ratingAcademy,
              duelsWon: p.duelsWon,
              duelsLost: p.duelsLost,
            ),
            const SizedBox(height: 16),
            // ⭐ **One panel, not one per row.** Six separate cards read as six
            // decisions; one panel reads as a menu, which is what it is.
            GamePanel(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: Icons.handyman,
                      label: 'Skills',
                      onTap: () => _push(context, const SkillsScreen()),
                    ),
                    const _RowDivider(),
                    _MenuRow(
                      icon: Icons.emoji_events,
                      label: 'Achievements',
                      onTap: () => _push(
                        context,
                        const ComingSoonScreen('Achievements'),
                      ),
                    ),
                    const _RowDivider(),
                    _MenuRow(
                      icon: Icons.pets,
                      label: 'Bestiary',
                      // ⚠️ '0 seen' is a **placeholder**, not a count — there
                      // is no bestiary to have seen anything in yet.
                      trailing: '0 seen',
                      onTap: () =>
                          _push(context, const ComingSoonScreen('Bestiary')),
                    ),
                    const _RowDivider(),
                    _MenuRow(
                      icon: Icons.inventory_2,
                      label: 'Item library',
                      trailing: '0 seen',
                      onTap: () => _push(
                        context,
                        const ComingSoonScreen('Item library'),
                      ),
                    ),
                    const _RowDivider(),
                    _MenuRow(
                      icon: Icons.help_outline,
                      label: 'How dueling works',
                      onTap: () => _push(context, const GameplayGuideScreen()),
                    ),
                    const _RowDivider(),
                    _MenuRow(
                      icon: Icons.person,
                      label: 'Account',
                      onTap: () => _push(context, const AccountScreen()),
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
}

/// Who you are: the badge, the name, the level line, and the same gold XP bar
/// the home tab draws — deliberately the same bar, so the two places never
/// disagree about how far along a level is.
class _Hero extends StatelessWidget {
  final String name;
  final int level;
  final int xpInto;
  final int xpFor;

  const _Hero({
    required this.name,
    required this.level,
    required this.xpInto,
    required this.xpFor,
  });

  @override
  Widget build(BuildContext context) {
    // ⚠️ Guard the divide: a level whose cost is 0 would otherwise paint NaN.
    final frac = xpFor == 0 ? 0.0 : (xpInto / xpFor).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PlayerAvatar(name: name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level $level · $xpInto / $xpFor XP',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 8, color: AppColors.borderDim),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(height: 8, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How you are doing: the two ladders and the duel record.
///
/// ⚠️ **Equal thirds, always all three.** A rating gaining a digit (or
/// arriving at all after a first rated match) must not re-lay the row, and a
/// character with no rating yet still gets the chip with an em dash in it —
/// the same reasoning as the home tab's ratings line.
class _StatChips extends StatelessWidget {
  final int? ratingGeared;
  final int? ratingAcademy;
  final int duelsWon;
  final int duelsLost;

  const _StatChips({
    required this.ratingGeared,
    required this.ratingAcademy,
    required this.duelsWon,
    required this.duelsLost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip.rating('Ladder', ratingGeared)),
        const SizedBox(width: 8),
        Expanded(child: _StatChip.rating('Academy', ratingAcademy)),
        const SizedBox(width: 8),
        Expanded(child: _StatChip('Record $duelsWon–$duelsLost')),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  /// Whether this chip carries a rating after its [label]. ⚠️ Separate from
  /// [rating] itself, because a NULL rating ('Academy —') is still a rating
  /// chip — it just has no number yet.
  final bool isRating;
  final int? rating;

  const _StatChip(this.label) : isRating = false, rating = null;

  /// A ladder chip: '[label] N', the number in the one rating style
  /// ([RatingText], 2026-09-25) — '—' until a first rated match.
  const _StatChip.rating(this.label, this.rating) : isRating = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDim),
      ),
      // ⭐ One Text either way — 'Ladder 1420' stays a single run that
      // ellipsizes as a unit (and that a finder can read whole).
      child: Text.rich(
        TextSpan(
          text: isRating ? '$label ' : label,
          children: [if (isRating) RatingText.span(rating, size: 12)],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// One row of the profile menu: icon, label, an optional dim count, chevron.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// A dim glance on the right, or nothing. ⚠️ Optional on purpose — the rows
  /// that have no honest number to show leave the right edge blank rather
  /// than inventing one.
  final String? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final count = trailing;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
            if (count != null) ...[
              Text(
                count,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.textFaint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 14,
    endIndent: 14,
    color: AppColors.borderDim,
  );
}
