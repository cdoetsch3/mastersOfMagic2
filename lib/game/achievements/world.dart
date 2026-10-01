/// ACHIEVEMENTS §5.5 — the map and the road.
///
/// ⚠️ **Two of §5.5's names were already taken** by stage-1 Campaign entries
/// with other meanings: `beyond_the_veil` is Rimeholt's gate and
/// `the_long_road` is fifteen clears. Here they are **The Empyrean** and
/// **Ten Hours on the Road**.
library;

import '../achievements.dart';
import '../player_profile.dart';
import '../world.dart';
import 'shared.dart';

abstract final class WorldAchievements {
  static final wayfarer = AchievementDef(
    id: 'wayfarer',
    name: 'Wayfarer',
    blurb: 'Ten places discovered.',
    category: AchievementCategory.world,
    points: 10,
    progress: (p) => cappedProgress(_discovered(p), 10),
  );

  static final cartographer = AchievementDef(
    id: 'cartographer',
    name: 'Cartographer',
    blurb: 'Every place in the world discovered.',
    category: AchievementCategory.world,
    points: 50,
    progress: (p) => cappedProgress(_discovered(p), World.locations.length),
  );

  /// Zenith, the town across the Empyrean.
  static final theEmpyrean = AchievementDef(
    id: 'the_empyrean',
    name: 'The Empyrean',
    blurb: 'Zenith discovered, across the Empyrean.',
    category: AchievementCategory.world,
    points: 25,
    earnedWhen: (p) => p.discoveredLocationIds.contains('zenith'),
  );

  /// Hours on the road for [tenHoursOnTheRoad].
  static const roadHours = 10;

  static final tenHoursOnTheRoad = AchievementDef(
    id: 'ten_hours_on_the_road',
    name: 'Ten Hours on the Road',
    blurb: 'Ten hours spent on the road.',
    category: AchievementCategory.world,
    points: 25,
    // ⭐ Whole hours, so the bar reads `3/10`, not `10800/36000` — and is
    // met at exactly 36,000 seconds all the same.
    progress: (p) => cappedProgress(p.travelSeconds ~/ 3600, roadHours),
  );

  static final List<AchievementDef> all = List.unmodifiable([
    wayfarer,
    cartographer,
    theEmpyrean,
    tenHoursOnTheRoad,
  ]);

  /// ⚠️ Only ids that name a real place — a retired id left on an old save
  /// must not count toward every place in the world.
  static int _discovered(PlayerProfile p) =>
      p.discoveredLocationIds.where(World.exists).length;
}
