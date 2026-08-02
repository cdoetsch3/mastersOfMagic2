/// One creature in the bestiary.
///
/// ⚠️ **A creature is not a mage** (ENEMIES_DESIGN §3). Its moves are its own
/// — a boar does not cast Bolt, it gores. Mechanically a move IS a [Spell];
/// what differs is the catalogue it comes from.
library;

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';

/// Where in a zone's structure this creature sits.
enum EnemyRank {
  /// One of the five wandering types.
  common,

  /// One of four; ⭐ **two are drawn per run**, so the pool is a different pair
  /// of tactical roles each visit (GAME_DESIGN §3d).
  mini,

  /// One of two; one is drawn per run.
  boss;

  /// Player-facing wording.
  String get label => switch (this) {
    EnemyRank.common => 'Wild',
    EnemyRank.mini => 'Mini-boss',
    EnemyRank.boss => 'Boss',
  };
}

@immutable
class EnemyDef {
  final String id;
  final String name;
  final String zoneId;
  final EnemyRank rank;
  final EnemyArchetype archetype;

  /// Which element(s) this creature actually uses (ENEMIES §2h). A pure zone's
  /// creatures all share the zone's element; a hybrid's may take one or both.
  final List<MagicElement> elements;

  /// ⭐ The "players who care can learn more" channel. Field-note voice —
  /// an observation about the creature, never a stat line in prose.
  final String lore;

  /// Its own moves. ⚠️ Never a `Spellbook` entry unless the creature is
  /// genuinely a mage.
  final List<Spell> moves;

  final DropTable drops;

  const EnemyDef({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.rank,
    required this.archetype,
    required this.elements,
    required this.lore,
    required this.moves,
    this.drops = DropTable.empty,
  });

  /// Max HP for this creature at [level], off the shared level baseline.
  int maxHpAt(int level) =>
      (MageState.scaledMaxHp(level) * archetype.hpScale).round();
}
