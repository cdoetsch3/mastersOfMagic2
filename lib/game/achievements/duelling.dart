/// ACHIEVEMENTS §5.4 — the stage-2 Dueling entries. First Blood, Tenfold and
/// Centurion shipped in stage 1 and stay in `achievements.dart`.
library;

import '../achievements.dart';
import '../enemies/the_eclipsed_citadel.dart';
import '../player_profile.dart';
import 'shared.dart';

abstract final class DuellingAchievements {
  /// ⚠️ Counts [PlayerProfile.duelsWon], like Centurion: Academy wins are a
  /// separate record and do not count.
  static final champion = AchievementDef(
    id: 'champion',
    name: 'Champion',
    blurb: 'Five hundred duels won.',
    category: AchievementCategory.duelling,
    points: 50,
    progress: (p) => cappedProgress(p.duelsWon, 500),
  );

  /// How far above you an opponent must be — inclusive: exactly ten counts.
  static const giantSlayerGap = 10;

  /// Reads [PlayerProfile.biggestWinLevelGap], written by
  /// `GameState.recordDuelResult` on every win.
  static final giantSlayer = AchievementDef(
    id: 'giant_slayer',
    name: 'Giant Slayer',
    blurb: 'A duel won against a foe ten levels above you.',
    category: AchievementCategory.duelling,
    points: 25,
    earnedWhen: (p) => p.biggestWinLevelGap >= giantSlayerGap,
  );

  /// ⭐ The bestiary's record of the Citadel's last boss —
  /// `procarius_the_eclipsed`, not the duelling persona `procarius`: a
  /// practice bout against the persona is not the finale.
  static final procariusFalls = AchievementDef(
    id: 'procarius_falls',
    name: 'Procarius Falls',
    blurb: 'Procarius defeated at the top of the Eclipsed Citadel.',
    category: AchievementCategory.duelling,
    points: 50,
    hidden: true,
    earnedWhen: (p) =>
        p
            .bestiaryEntryFor(EclipsedCitadelBestiary.procariusTheEclipsed.id)
            .slain >=
        1,
  );

  /// The family Vanquisher I–V share.
  static const vanquisherFamily = 'vanquisher';

  /// Creatures slain, all told, for Vanquisher I–V.
  static const vanquisherThresholds = <int>[50, 250, 1000, 2500, 5000];

  static const _vanquisherPoints = <int>[5, 10, 25, 25, 50];

  /// Every creature slain, across the whole bestiary — repeats included.
  static int totalSlain(PlayerProfile p) =>
      p.bestiary.values.fold(0, (sum, e) => sum + e.slain);

  static final List<AchievementDef> vanquisher = List.unmodifiable([
    for (var t = 1; t <= vanquisherThresholds.length; t++)
      AchievementDef(
        id: '${vanquisherFamily}_$t',
        name: 'Vanquisher ${tierNumeral(t)}',
        blurb: '${groupedDigits(vanquisherThresholds[t - 1])} creatures slain.',
        category: AchievementCategory.duelling,
        points: _vanquisherPoints[t - 1],
        family: vanquisherFamily,
        tier: t,
        progress: (p) =>
            cappedProgress(totalSlain(p), vanquisherThresholds[t - 1]),
      ),
  ]);

  /// The stage-2 Dueling entries, after Centurion.
  static final List<AchievementDef> all = List.unmodifiable([
    champion,
    giantSlayer,
    procariusFalls,
    ...vanquisher,
  ]);
}
