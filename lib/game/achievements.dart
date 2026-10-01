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
/// 📝 Stage 2 added exactly one counter for one entry:
/// `PlayerProfile.biggestWinLevelGap`, for Giant Slayer — a win before it
/// existed left no record of the gap, so that one entry is not retroactive.
///
/// ⚠️ **An id is forever.** Once shipped, an id is on disk in every profile
/// that earned it. Rename the [AchievementDef.name] freely; never the id.
///
/// ⭐ **Earning and being paid are two moments** (ruling, Christian
/// 2026-10-01). An entry met is earned (`PlayerProfile.achievements`, the
/// toast); its [Reward] waits on the Achievements screen until the player
/// presses Claim (`PlayerProfile.claimedAchievements`). See
/// ACHIEVEMENTS_DESIGN's 2026-10-01 rulings.
///
/// 📝 The counters the stage-2 catalogue reads (charges, gold earned, items
/// seen, travel) exist on the profile since 2026-10-01; the twelve entries
/// here predate them and still read only the older counters.
///
/// ⭐ **Stage 2 (2026-10-01): the full catalogue lives in
/// `achievements/`** — one file per §5 section, the per-zone and
/// per-element entries generated from the world and the element list. This
/// file keeps the model and the twelve shipped entries; [Achievements.all]
/// stitches them together in §5 order.
library;

import 'achievements/campaign.dart';
import 'achievements/duelling.dart';
import 'achievements/mastery.dart';
import 'achievements/wealth.dart';
import 'achievements/world.dart';
import 'items/item_def.dart';
import 'player_profile.dart';

/// The Achievements screen's groups, **in screen order** — the enum order is
/// the order the sections appear and the filter chips run.
///
/// ⭐ ACHIEVEMENTS §5's sections (2026-10-01). The 2026-09-30 `journey` and
/// `combat` became [campaign] and [duelling]. ⚠️ A category is never on
/// disk — only ids are — so renaming one costs no save anything.
///
/// 📝 [mastery], [wealth] and [world] hold nothing until the stage-2
/// catalogue lands; the screen offers no chip for an empty category.
enum AchievementCategory {
  campaign('Campaign'),
  mastery('Mastery'),
  wealth('Wealth'),
  duelling('Dueling'),
  world('World'),
  craft('Craft'),
  ladder('Ladder');

  /// What the player sees: the section heading and the filter chip.
  final String label;

  const AchievementCategory(this.label);
}

/// How far a countable goal has come: [done] of [total].
typedef AchievementProgress = ({int done, int total});

/// What claiming an achievement pays: XP, gold and Resonance Prisms.
typedef AchievementReward = ({int xp, int gold, int rp});

/// The ACHIEVEMENTS §6 reward table, keyed on points (ruling, Christian
/// 2026-10-01: §6 as written; no titles or cosmetics this pass).
///
/// | Points | XP | Gold | RP |
/// |---|---|---|---|
/// | 5 | 100 | 50 | — |
/// | 10 | 250 | 150 | — |
/// | 25 | 750 | 500 | 1 |
/// | 50 | 2,000 | 1,500 | 5 |
/// | 100+ | 5,000 | 5,000 | 25 |
///
/// ⭐ **Rewards are never power** (§6): XP, gold and RP only — no equipment,
/// materials, elements, spells or slots, ever.
abstract final class Reward {
  /// Nothing — what `GameState.claimAllAchievements` pays with nothing due.
  static const AchievementReward none = (xp: 0, gold: 0, rp: 0);

  /// The row for [points]. ⚠️ A threshold walk, not an exact-key lookup: a
  /// 150-point entry pays the **100+** row (§6), and anything between rows
  /// pays the row below it.
  static AchievementReward forPoints(int points) {
    if (points >= 100) return (xp: 5000, gold: 5000, rp: 25);
    if (points >= 50) return (xp: 2000, gold: 1500, rp: 5);
    if (points >= 25) return (xp: 750, gold: 500, rp: 1);
    if (points >= 10) return (xp: 250, gold: 150, rp: 0);
    return (xp: 100, gold: 50, rp: 0);
  }

  /// [rewards] added together — what Claim all pays.
  static AchievementReward sum(Iterable<AchievementReward> rewards) {
    var xp = 0, gold = 0, rp = 0;
    for (final r in rewards) {
      xp += r.xp;
      gold += r.gold;
      rp += r.rp;
    }
    return (xp: xp, gold: gold, rp: rp);
  }
}

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

  /// The arcade-style weight: one of [allowedPoints]. ⭐ Decides the
  /// [reward] (§6) and sums into the screen's total.
  final int points;

  /// The tiered set this entry belongs to (§3.1) — e.g. `'pyro_mastery'` —
  /// or null for a stand-alone entry. ⭐ Tiers are N separate entries sharing
  /// a family, never one entry with a level; the stage-2 screen collapses a
  /// family to its current tier.
  final String? family;

  /// This entry's tier within its [family], 1 upward; null when [family] is.
  final int? tier;

  /// A spoiler: the screen shows `???` and no blurb until it is earned (§7.1).
  final bool hidden;

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

  /// The weights an entry may carry (§3, §5).
  static const allowedPoints = [5, 10, 25, 50, 100, 150];

  const AchievementDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.category,
    required this.points,
    this.family,
    this.tier,
    this.hidden = false,
    this.progress,
    this.earnedWhen,
  }) : assert(
         (family == null) == (tier == null),
         'a tier needs a family, and a family member needs a tier',
       );

  /// What claiming this entry pays — [Reward.forPoints] of [points].
  AchievementReward get reward => Reward.forPoints(points);

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
  /// Lifetime charges of one element for Mastery tiers I–V (ruling,
  /// Christian 2026-10-01; a duel is 30–40 charges, so tier I is roughly
  /// seven duels in one element and tier V several hundred). ⭐ Consts to
  /// tune, read by the stage-2 Mastery family (`achievements/mastery.dart`).
  static const masteryThresholds = <int>[250, 1000, 5000, 10000, 25000];

  // ---- Campaign ----------------------------------------------------------
  //
  // 📝 Points (2026-10-01): a one-shot 5–10, a counted goal 10–25, and the
  // two far milestones (Beyond the Veil, The Long Road) 25.

  /// ⭐ The game's first achievement: opening the Pennycross gate, which
  /// costs the three proofs (ruling 2026-09-25). `GameState.openGateAt`
  /// grants it in the same write as the opening; the condition here only
  /// matters to the load-time sweep.
  static const papersInOrder = AchievementDef(
    id: 'papers_in_order',
    name: 'Papers in Order',
    blurb: 'Pennycross unlocked. The proofs stay with the guard.',
    category: AchievementCategory.campaign,
    points: 10,
    earnedWhen: _pennycrossOpen,
  );

  static const firstClearing = AchievementDef(
    id: 'first_clearing',
    name: 'First Clearing',
    blurb: 'One zone cleared to its boss.',
    category: AchievementCategory.campaign,
    points: 10,
    earnedWhen: _anyZoneCleared,
  );

  static const fiveBanners = AchievementDef(
    id: 'five_banners',
    name: 'Five Banners',
    blurb: 'Five zones cleared to their bosses.',
    category: AchievementCategory.campaign,
    points: 10,
    progress: _zonesOf5,
  );

  static const theLongRoad = AchievementDef(
    id: 'the_long_road',
    name: 'The Long Road',
    blurb: 'Fifteen zones cleared to their bosses.',
    category: AchievementCategory.campaign,
    points: 25,
    progress: _zonesOf15,
  );

  /// ⚠️ Rimeholt's gate only LOOKS at the Celestial Totem (it is kept), so
  /// the blurb says so rather than borrowing Pennycross's sentence.
  static const beyondTheVeil = AchievementDef(
    id: 'beyond_the_veil',
    name: 'Beyond the Veil',
    blurb: 'Rimeholt unlocked. The Totem stays with you.',
    category: AchievementCategory.campaign,
    points: 25,
    earnedWhen: _rimeholtOpen,
  );

  // ---- Duelling ----------------------------------------------------------

  /// ⚠️ Duelling counts [PlayerProfile.duelsWon] — the geared and campaign
  /// record. Academy ladder wins are a separate record and do not count.
  static const firstBlood = AchievementDef(
    id: 'first_blood',
    name: 'First Blood',
    blurb: 'One duel won.',
    category: AchievementCategory.duelling,
    points: 5,
    earnedWhen: _anyWin,
  );

  static const tenfold = AchievementDef(
    id: 'tenfold',
    name: 'Tenfold',
    blurb: 'Ten duels won.',
    category: AchievementCategory.duelling,
    points: 10,
    progress: _winsOf10,
  );

  static const centurion = AchievementDef(
    id: 'centurion',
    name: 'Centurion',
    blurb: 'A hundred duels won.',
    category: AchievementCategory.duelling,
    points: 25,
    progress: _winsOf100,
  );

  // ---- Craft -------------------------------------------------------------

  static const journeyman = AchievementDef(
    id: 'journeyman',
    name: 'Journeyman',
    blurb: 'One craft taken to level 5.',
    category: AchievementCategory.craft,
    points: 10,
    progress: _craftOf5,
  );

  /// 📝 Level 10 is where the second tier of recipes opens (`Skills`).
  static const artisan = AchievementDef(
    id: 'artisan',
    name: 'Artisan',
    blurb: 'One craft taken to level 10.',
    category: AchievementCategory.craft,
    points: 25,
    progress: _craftOf10,
  );

  // ---- Ladder ------------------------------------------------------------

  static const rated = AchievementDef(
    id: 'rated',
    name: 'On the Ladder',
    blurb: 'One rated duel played, on either ladder.',
    category: AchievementCategory.ladder,
    points: 5,
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
    points: 10,
    progress: _ratedOf10,
  );

  /// Every achievement: ⭐ grouped by [AchievementCategory] in enum order,
  /// and within a category in the order the screen lists them.
  ///
  /// ⭐ Stage 2: the shipped twelve where they fit, the generated sections
  /// around them (§5). ⚠️ `final`, not `const` — the generated entries close
  /// over a zone or an element.
  static final List<AchievementDef> all = List.unmodifiable([
    // Campaign: the shipped five, every zone's three, the capstones.
    papersInOrder,
    firstClearing,
    fiveBanners,
    theLongRoad,
    beyondTheVeil,
    ...CampaignAchievements.zones,
    ...CampaignAchievements.capstones,
    ...MasteryAchievements.all,
    ...WealthAchievements.all,
    firstBlood,
    tenfold,
    centurion,
    ...DuellingAchievements.all,
    ...WorldAchievements.all,
    journeyman,
    artisan,
    rated,
    ladderRegular,
  ]);

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

  /// ⭐ Every entry [p] has earned but not claimed, in catalogue order — what
  /// Claim and Claim all may pay. ⚠️ An id the catalogue no longer knows is
  /// never listed, so a retired entry can never be paid.
  static List<AchievementDef> claimable(PlayerProfile p) => [
    for (final a in all)
      if (p.achievements.contains(a.id) &&
          !p.claimedAchievements.contains(a.id))
        a,
  ];

  /// The [AchievementDef.points] of every entry [p] has earned — claimed or
  /// not: points are for earning, rewards for claiming (§7.1: this is the
  /// number other players may one day see).
  static int totalPoints(PlayerProfile p) => [
    for (final a in all)
      if (p.achievements.contains(a.id)) a.points,
  ].fold(0, (a, b) => a + b);

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
