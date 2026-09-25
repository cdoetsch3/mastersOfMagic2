import 'package:flutter/material.dart';

import '../game/achievements.dart';
import '../game/game_state.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';

/// Every achievement in the catalogue, earned or not (ruling, Christian
/// 2026-09-25) — the Profile's Achievements row, no longer a placeholder.
///
/// ⭐ **Unearned entries are listed, dimmed** — not hidden. A catalogue of
/// one that showed nothing until earned would read as an empty screen, and
/// the point of the list is to say what there is to do.
///
/// 📝 Small on purpose; the catalogue grows later. No categories, no
/// progress bars, no dates — each would be a field on the profile first.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earned = GameStateScope.of(context).profile.achievements;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Achievements'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          children: [
            for (final def in Achievements.all)
              AchievementRow(def: def, earned: earned.contains(def.id)),
          ],
        ),
      ),
    );
  }
}

/// One catalogue entry: ✓ and text colour when earned, dim when not.
class AchievementRow extends StatelessWidget {
  final AchievementDef def;
  final bool earned;

  const AchievementRow({super.key, required this.def, required this.earned});

  @override
  Widget build(BuildContext context) {
    final nameColor = earned ? AppColors.text : AppColors.textFaint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        color: AppColors.panel,
        borderColor: earned ? AppColors.gold : AppColors.borderDim,
        child: Row(
          children: [
            // ⭐ One fixed cell for both states, so the name sits at one x
            // whether or not it has been earned.
            SizedBox(
              width: 28,
              child: Icon(
                earned ? Icons.check_circle : Icons.emoji_events_outlined,
                size: 20,
                color: earned ? AppColors.green : AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The toast for a newly earned achievement: `'Achievement · <name>'` on the
/// gold edge. ⭐ Takes a captured [AppBannerMessenger] (the
/// `appBannerOf`-before-the-await idiom), because the caller usually earns
/// it by an action that tears its own screen down.
void announceAchievement(AppBannerMessenger banner, AchievementDef def) =>
    banner.show(achievementToastText(def), color: AppColors.gold);

/// The toast's words, one owner for the screen and its tests.
String achievementToastText(AchievementDef def) => 'Achievement · ${def.name}';

/// The Profile row's trailing count, `'n / N'`. ⚠️ Counts only ids the
/// catalogue still knows, so a retired entry cannot push n past N.
String achievementCountLabel(Set<String> earned) {
  final n = Achievements.all.where((a) => earned.contains(a.id)).length;
  return '$n / ${Achievements.all.length}';
}
