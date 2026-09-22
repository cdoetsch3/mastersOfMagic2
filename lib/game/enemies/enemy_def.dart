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
import 'enemy_combat_stats.dart';

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

  /// Crit / dodge / deflection, KINETIC_CONTRACT §2.2/§2.3. ⚠️ Optional and
  /// inert by default (`EnemyCombatStats.none`) — every Q1 `EnemyDef` omits
  /// it and stays stat-free by construction. Reaches the duel through
  /// `OpponentDriver.opponentCombatStats`, never through `opponentGear`.
  final EnemyCombatStats combatStats;

  /// ⭐ **A mage brings a Spellbook loadout, not a creature kit**
  /// (ENEMIES_DESIGN §3.4). The Ethereal band is scholars, wardens and
  /// archmages; those fight you with *your own tools*, which is a genuinely
  /// different duel from a creature's two or three verbs. When this is true,
  /// [moves] is a level-legal selection from [Spellbook] rather than moves
  /// authored for this creature.
  ///
  /// ⚠️ **It is a licence, not a decoration.** Three laws every zone test
  /// enforces on creatures are *off* for a mage, and only because the
  /// Spellbook already answers them its own way:
  ///  - the archetype's `moveCount` / cost band (§3.2) — a loadout is ten
  ///    slots, not two or three;
  ///  - the zone move-id prefix — the ids are `bolt`, `ruin`, `aegis`;
  ///  - the contract's raw-damage ceiling (§1.3) — the Spellbook is priced
  ///    for players, and Cataclysm's 59–72 is over the creature ceiling by
  ///    construction.
  ///
  /// ⚠️ In exchange a mage owes the one law a creature does not: every entry
  /// must be in `Spellbook.all` and unlocked at or below the encounter level
  /// (`Progression.plannedUnlockLevelOf`). ⭐ Defaults false, so every
  /// creature already shipped stays a creature without being edited.
  final bool isMage;

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
    this.combatStats = EnemyCombatStats.none,
    this.isMage = false,
  });

  /// Max HP for this creature at [level], off the shared level baseline.
  int maxHpAt(int level) =>
      (MageState.scaledMaxHp(level) * archetype.hpScale).round();
}
