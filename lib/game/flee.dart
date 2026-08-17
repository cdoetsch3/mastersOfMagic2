import 'enemies/enemy_def.dart';

/// Whether a campaign duel can be walked out of, and how likely that is.
///
/// ⭐ **Fleeing is a ROLL, not a button** (designer ruling, 2026-08-17). The
/// old campaign "Flee" was a surrender: it ended the fight as a loss and paid
/// the full defeat penalty, so the only two options a losing run ever had were
/// "die" and "die on purpose". The middle ground is an escape *attempt* — a
/// clean getaway costs nothing but the run, a failed one costs a turn.
///
/// ⚠️ **Pure arithmetic, plain inputs.** No engine state, no widgets, no
/// controller — it takes levels, health, and a rank, which is what makes the
/// ruled anchors testable as arithmetic rather than as a duel that has to be
/// played out to see the number.
abstract final class Flee {
  /// The even-fight baseline: two duellists of a level, both at full health,
  /// no rank penalty. ⭐ Deliberately generous — the ruling wants running away
  /// from a common to be a real option, not a gamble.
  static const double baseChance = 0.80;

  /// Per level of advantage over the enemy.
  static const double perLevelEdge = 0.05;

  /// ⚠️ Level edge is capped **before** it is weighted, at ±[levelEdgeCap]. A
  /// twenty-level gap is not four times more escapable than a five-level one;
  /// without the cap the ceiling/floor would be the only thing left doing any
  /// work at the extremes and the rank penalty would stop mattering entirely.
  static const int levelEdgeCap = 5;

  /// How hard the health difference pulls. ⭐ The dominant term by design: it
  /// is worth up to ±0.75, where the whole level range is worth ±0.25 — what
  /// decides an escape is how the fight is *going*, not the character sheet.
  static const double healthEdgeWeight = 0.75;

  /// ⚠️ Applied **before** the clamp, never after, so a boss's penalty cannot
  /// push anyone below [floor]: cornered by a boss at death's door is still a
  /// 20% escape, exactly like being cornered by anything else. Ordering it the
  /// other way would make bosses inescapable, which is a death sentence rather
  /// than a difficulty.
  static const double floor = 0.20;

  /// ⭐ Never a certainty. Even at maximum advantage the enemy gets one chance
  /// in twenty to cut the escape off — a flee button that always works is a
  /// free reset on every fight the player does not like the look of.
  static const double ceiling = 0.95;

  /// What the creature's standing costs the attempt. Commons let you go;
  /// bosses very much do not.
  static double rankPenalty(EnemyRank rank) => switch (rank) {
    EnemyRank.common => 0.0,
    EnemyRank.mini => 0.10,
    EnemyRank.boss => 0.20,
  };

  /// The chance (0–1) that an escape attempt gets clean away.
  ///
  /// The ruled formula, in one line:
  /// `clamp(0.80 + 0.05·levelEdge + 0.75·healthEdge − rankPenalty, 0.20, 0.95)`
  static double chance({
    required int playerLevel,
    required int enemyLevel,
    required int playerHp,
    required int playerMaxHp,
    required int enemyHp,
    required int enemyMaxHp,
    EnemyRank rank = EnemyRank.common,
  }) {
    final levelEdge = (playerLevel - enemyLevel).clamp(
      -levelEdgeCap,
      levelEdgeCap,
    );
    final healthEdge =
        _healthFraction(playerHp, playerMaxHp) -
        _healthFraction(enemyHp, enemyMaxHp);
    final raw =
        baseChance +
        perLevelEdge * levelEdge +
        healthEdgeWeight * healthEdge -
        rankPenalty(rank);
    return raw.clamp(floor, ceiling);
  }

  /// The same number as the button shows it: whole percent, rounded.
  ///
  /// ⭐ One function, so "Flee (73%)" and the roll can never disagree — the
  /// display rounds the number the roll actually uses rather than deriving its
  /// own.
  static int percent({
    required int playerLevel,
    required int enemyLevel,
    required int playerHp,
    required int playerMaxHp,
    required int enemyHp,
    required int enemyMaxHp,
    EnemyRank rank = EnemyRank.common,
  }) =>
      (chance(
                playerLevel: playerLevel,
                enemyLevel: enemyLevel,
                playerHp: playerHp,
                playerMaxHp: playerMaxHp,
                enemyHp: enemyHp,
                enemyMaxHp: enemyMaxHp,
                rank: rank,
              ) *
              100)
          .round();

  /// ⚠️ Guarded rather than trusted: a zero or negative pool would divide by
  /// zero and hand the clamp a NaN, which clamps to *neither* bound and would
  /// silently ship a broken percentage. Clamped to 0–1 for the same reason —
  /// overheal must not read as more than full health.
  static double _healthFraction(int hp, int maxHp) =>
      maxHp <= 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
}
