/// ACHIEVEMENTS §5.3 — four entries, ruling 6 (Christian 2026-10-01).
///
/// ⭐ **Gold earned, never gold held** ([PlayerProfile.goldEarned]): a player
/// who spends on gear must not watch the bar walk backwards.
library;

import '../achievements.dart';
import '../player_profile.dart';
import 'shared.dart';

abstract final class WealthAchievements {
  /// The family all four share — tiers 1–4.
  static const family = 'wealth';

  static final youngMoney = _tier(
    tier: 1,
    id: 'young_money',
    name: 'Young Money',
    threshold: 10000,
    blurb: '10,000 gold earned.',
    points: 5,
  );

  static final fatStacks = _tier(
    tier: 2,
    id: 'fat_stacks',
    name: 'Fat Stacks',
    threshold: 100000,
    blurb: '100,000 gold earned.',
    points: 10,
  );

  static final bigMoney = _tier(
    tier: 3,
    id: 'big_money',
    name: 'Big Money',
    threshold: 1000000,
    blurb: 'A million gold earned.',
    points: 25,
  );

  /// ❓ §10: whether a billion is reachable waits on the end-game economy.
  /// Hidden until then — the number is a joke the player finds, not a goal.
  static final tresCommas = _tier(
    tier: 4,
    id: 'tres_commas',
    name: 'Tres Commas',
    threshold: 1000000000,
    blurb: 'A billion gold earned.',
    points: 100,
    hidden: true,
  );

  static final List<AchievementDef> all = List.unmodifiable([
    youngMoney,
    fatStacks,
    bigMoney,
    tresCommas,
  ]);

  static AchievementDef _tier({
    required int tier,
    required String id,
    required String name,
    required int threshold,
    required String blurb,
    required int points,
    bool hidden = false,
  }) => AchievementDef(
    id: id,
    name: name,
    blurb: blurb,
    category: AchievementCategory.wealth,
    points: points,
    family: family,
    tier: tier,
    hidden: hidden,
    progress: (PlayerProfile p) => cappedProgress(p.goldEarned, threshold),
  );
}
