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
  /// genuinely a mage — see [isMage].
  final List<Spell> moves;

  /// ⭐ **A mage brings a Spellbook loadout, not a creature kit.**
  ///
  /// ENEMIES §3.4: *"beasts and constructs get creature moves; humanoid
  /// casters get `Spellbook`."* The archetype's `moveCount` / cost band
  /// describes a **creature kit**, so it does not apply here: an archmage
  /// fields the same five-element, ten-spell loadout a player would, and the
  /// last fight in the game is therefore the player's own toolbox pointed
  /// back at them.
  ///
  /// ⚠️ **Zone suites must exempt a mage from the move-count law**
  /// (`moves.length == archetype.moveCount`), and assert the loadout instead.
  /// Only two creatures in the game set this: The Archmage (The Collapsed
  /// Academy) and Procarius, the Eclipsed (The Eclipsed Citadel).
  final bool isMage;

  /// ⚠️ **The one documented exception to "intelligence comes from the
  /// archetype"** (ENEMIES §2e, the Procarius table).
  ///
  /// A creature's `LadderAi` rung is normally [EnemyArchetype.intelligence],
  /// and that is still the default — this is null on every other creature in
  /// the game. Procarius is a **shipped `AiPersona`** (`ai_personas.dart`)
  /// that has run at **10** since long before the Tyrant archetype's 9
  /// existed, and ⭐ *"a finale antagonist demoted by a table is a bug, not a
  /// balance decision."* Read through [intelligence], never off the archetype
  /// directly.
  final int? intelligenceOverride;

  final DropTable drops;

  /// Crit / dodge / deflection, KINETIC_CONTRACT §2.2/§2.3. ⚠️ Optional and
  /// inert by default (`EnemyCombatStats.none`) — every Q1 `EnemyDef` omits
  /// it and stays stat-free by construction. Reaches the duel through
  /// `OpponentDriver.opponentCombatStats`, never through `opponentGear`.
  final EnemyCombatStats combatStats;

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
    this.intelligenceOverride,
  });

  /// The `LadderAi` rung this creature actually fights at — the archetype's,
  /// unless [intelligenceOverride] says otherwise. ⭐ **The one door**, so a
  /// call site cannot read the archetype and miss the exception.
  int get intelligence => intelligenceOverride ?? archetype.intelligence;

  /// Max HP for this creature at [level], off the shared level baseline.
  int maxHpAt(int level) =>
      (MageState.scaledMaxHp(level) * archetype.hpScale).round();
}
