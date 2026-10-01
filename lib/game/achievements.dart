/// The achievement catalogue: what can be earned, named and described.
///
/// ⭐ **Ids on the profile, everything else here** (ruling, Christian
/// 2026-09-25). A character holds only the **ids** it has earned
/// (`PlayerProfile.achievements`), so a renamed achievement or a rewritten
/// blurb never touches a save.
///
/// ⭐ **Every condition reads a counter the profile already keeps** (ruling,
/// Christian 2026-09-30, note 7). No achievement adds a field: wins are
/// `duelsWon`, clears are `zoneClears`, gates are `openedGates`, crafts are
/// `skillXp`, the ladder is its rated-game counts. So an entry
/// added later is earned retroactively by the load-time sweep
/// (`GameState`), never lost to "you did it before it existed".
///
/// ⚠️ **An id is forever.** Once shipped, an id is on disk in every profile
/// that earned it. Rename the [AchievementDef.name] freely; never the id.
library;

import 'items/item_def.dart';
import 'player_profile.dart';

/// The Achievements screen's groups, **in screen order** — the enum order is
/// the order the sections appear and the filter chips run.
enum AchievementCategory {
  journey('Journey'),
  combat('Combat'),
  craft('Craft'),
  ladder('Ladder');

  /// What the player sees: the section heading and the filter chip.
  final String label;

  const AchievementCategory(this.label);
}

/// How far a countable goal has come: [done] of [total].
typedef AchievementProgress = ({int done, int total});

/// One thing a character can earn.
class AchievementDef {
  /// Stable key, persisted on the profile. ⚠️ See the library note.
  final String id;

  /// What the player sees: the Achievements screen and the toast.
  final String name;

  /// One line on what it is for — shown under the [name].
  final String blurb;

  /// Which section of the screen it sits in.
  final AchievementCategory category;

  /// For an entry with a countable goal, how far [PlayerProfile] has come —
  /// earned once `done >= total`. Null for a one-shot.
  ///
  /// ⭐ **Pure, and [AchievementProgress.done] is capped at the total**, so
  /// the screen can print it as-is: a hundred and twelve wins read
  /// `100/100`, never `112/100`.
  final AchievementProgress? Function(PlayerProfile)? progress;

  /// For a one-shot, whether [PlayerProfile] has done it. Ignored when
  /// [progress] is set.
  ///
  /// ⚠️ Null on both means **never earned by a condition** — only something
  /// granting the id directly could earn it.
  final bool Function(PlayerProfile)? earnedWhen;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.category,
    this.progress,
    this.earnedWhen,
  });

  /// Whether [p] has met this entry's condition — whether or not the id is
  /// on the profile yet.
  bool isMet(PlayerProfile p) {
    final counted = progress?.call(p);
    if (counted != null) return counted.done >= counted.total;
    return earnedWhen?.call(p) ?? false;
  }
}

/// [done] of [total], with [done] capped at [total] (see
/// [AchievementDef.progress]).
AchievementProgress _of(int done, int total) =>
    (done: done < total ? done : total, total: total);

/// The highest level any **craft** skill has reached. ⚠️ Gathering skills
/// (Felling, Foraging, Mining) are not crafts and do not count.
int _bestCraftLevel(PlayerProfile p) {
  var best = 0;
  for (final s in CraftSkill.values) {
    final level = p.skillLevel(s.name);
    if (level > best) best = level;
  }
  return best;
}

abstract final class Achievements {
  // ---- Journey -----------------------------------------------------------

  /// ⭐ The game's first achievement: opening the Pennycross gate, which
  /// costs the three proofs (ruling 2026-09-25). `GameState.openGateAt`
  /// grants it in the same write as the opening; the condition here only
  /// matters to the load-time sweep.
  static const papersInOrder = AchievementDef(
    id: 'papers_in_order',
    name: 'Papers in Order',
    blurb: 'Pennycross unlocked. The proofs stay with the guard.',
    category: AchievementCategory.journey,
    earnedWhen: _pennycrossOpen,
  );

  static const firstClearing = AchievementDef(
    id: 'first_clearing',
    name: 'First Clearing',
    blurb: 'One zone cleared to its boss.',
    category: AchievementCategory.journey,
    earnedWhen: _anyZoneCleared,
  );

  static const fiveBanners = AchievementDef(
    id: 'five_banners',
    name: 'Five Banners',
    blurb: 'Five zones cleared to their bosses.',
    category: AchievementCategory.journey,
    progress: _zonesOf5,
  );

  static const theLongRoad = AchievementDef(
    id: 'the_long_road',
    name: 'The Long Road',
    blurb: 'Fifteen zones cleared to their bosses.',
    category: AchievementCategory.journey,
    progress: _zonesOf15,
  );

  /// ⚠️ Rimeholt's gate only LOOKS at the Celestial Totem (it is kept), so
  /// the blurb says so rather than borrowing Pennycross's sentence.
  static const beyondTheVeil = AchievementDef(
    id: 'beyond_the_veil',
    name: 'Beyond the Veil',
    blurb: 'Rimeholt unlocked. The Totem stays with you.',
    category: AchievementCategory.journey,
    earnedWhen: _rimeholtOpen,
  );

  // ---- Combat ------------------------------------------------------------

  /// ⚠️ Combat counts [PlayerProfile.duelsWon] — the geared and campaign
  /// record. Academy ladder wins are a separate record and do not count.
  static const firstBlood = AchievementDef(
    id: 'first_blood',
    name: 'First Blood',
    blurb: 'One duel won.',
    category: AchievementCategory.combat,
    earnedWhen: _anyWin,
  );

  static const tenfold = AchievementDef(
    id: 'tenfold',
    name: 'Tenfold',
    blurb: 'Ten duels won.',
    category: AchievementCategory.combat,
    progress: _winsOf10,
  );

  static const centurion = AchievementDef(
    id: 'centurion',
    name: 'Centurion',
    blurb: 'A hundred duels won.',
    category: AchievementCategory.combat,
    progress: _winsOf100,
  );

  // ---- Craft -------------------------------------------------------------

  static const journeyman = AchievementDef(
    id: 'journeyman',
    name: 'Journeyman',
    blurb: 'One craft taken to level 5.',
    category: AchievementCategory.craft,
    progress: _craftOf5,
  );

  /// 📝 Level 10 is where the second tier of recipes opens (`Skills`).
  static const artisan = AchievementDef(
    id: 'artisan',
    name: 'Artisan',
    blurb: 'One craft taken to level 10.',
    category: AchievementCategory.craft,
    progress: _craftOf10,
  );

  // ---- Ladder ------------------------------------------------------------

  static const rated = AchievementDef(
    id: 'rated',
    name: 'On the Ladder',
    blurb: 'One rated duel played, on either ladder.',
    category: AchievementCategory.ladder,
    earnedWhen: _anyRatedGame,
  );

  /// Rated duels on both ladders together.
  ///
  /// 📝 **Replaced a rating goal before it shipped** (coordinator,
  /// 2026-09-30). "A rating of 1200" was nearly free: the Academy ladder
  /// seeds every character at 1200, so the first rated win earned it.
  /// Games played cannot be had for nothing.
  static const ladderRegular = AchievementDef(
    id: 'ladder_regular',
    name: 'Regular',
    blurb: 'Ten rated duels played, on either ladder.',
    category: AchievementCategory.ladder,
    progress: _ratedOf10,
  );

  /// Every achievement: ⭐ grouped by [AchievementCategory] in enum order,
  /// and within a category in the order the screen lists them.
  static const all = <AchievementDef>[
    papersInOrder,
    firstClearing,
    fiveBanners,
    theLongRoad,
    beyondTheVeil,
    firstBlood,
    tenfold,
    centurion,
    journeyman,
    artisan,
    rated,
    ladderRegular,
  ];

  /// The entries in [category], in catalogue order.
  static List<AchievementDef> inCategory(AchievementCategory category) => [
    for (final a in all)
      if (a.category == category) a,
  ];

  /// The def for [id], or null for an id no catalogue entry claims — a save
  /// from a future build, or a retired entry.
  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// How many of [earned] the catalogue still knows. ⚠️ A retired or
  /// future id is not counted, so the count can never pass [all]'s length.
  static int earnedCount(Set<String> earned) =>
      all.where((a) => earned.contains(a.id)).length;

  /// ⭐ Every entry [p] has met but does not hold yet, in catalogue order —
  /// the one question both the live grant and the load-time sweep ask.
  static List<AchievementDef> newlyEarned(PlayerProfile p) => [
    for (final a in all)
      if (!p.achievements.contains(a.id) && a.isMet(p)) a,
  ];

  // ---- conditions (static, so the defs above stay const) ------------------

  static bool _pennycrossOpen(PlayerProfile p) =>
      p.openedGates.contains('pennycross');

  /// ⚠️ `'rimeholt'` is the location the Celestial Totem gate guards.
  static bool _rimeholtOpen(PlayerProfile p) =>
      p.openedGates.contains('rimeholt');

  static bool _anyZoneCleared(PlayerProfile p) => p.zonesCleared >= 1;
  static AchievementProgress _zonesOf5(PlayerProfile p) =>
      _of(p.zonesCleared, 5);
  static AchievementProgress _zonesOf15(PlayerProfile p) =>
      _of(p.zonesCleared, 15);

  static bool _anyWin(PlayerProfile p) => p.duelsWon >= 1;
  static AchievementProgress _winsOf10(PlayerProfile p) => _of(p.duelsWon, 10);
  static AchievementProgress _winsOf100(PlayerProfile p) =>
      _of(p.duelsWon, 100);

  static AchievementProgress _craftOf5(PlayerProfile p) =>
      _of(_bestCraftLevel(p), 5);
  static AchievementProgress _craftOf10(PlayerProfile p) =>
      _of(_bestCraftLevel(p), 10);

  static bool _anyRatedGame(PlayerProfile p) =>
      p.ratedGamesGeared + p.ratedGamesAcademy >= 1;
  static AchievementProgress _ratedOf10(PlayerProfile p) =>
      _of(p.ratedGamesGeared + p.ratedGamesAcademy, 10);
}
