/// The sixteen enemy archetypes (ENEMIES_DESIGN §2).
///
/// ⭐ **An archetype is a multiplier on the level baseline, not a second
/// curve.** `MageState(level: n)` already gives `100 × 1.04^(n-1)` max HP and
/// the same multiplier on outgoing damage, so a 1.0×/1.0× enemy is an exactly
/// even fight and there is no parallel progression to drift.
///
/// ⚠️ **Archetype does not name moves** (§3.2). It supplies stats,
/// intelligence and the *shape* of a move set — how many, roughly what cost.
/// The creature supplies the moves themselves.
library;

import 'package:flutter/foundation.dart';

/// Which tier of encounter an archetype belongs to.
enum EnemyTier { common, mini, boss }

@immutable
class EnemyArchetype {
  final String id;
  final String name;
  final EnemyTier tier;

  /// Multiplier on the level-baseline max HP.
  final double hpScale;

  /// Multiplier on outgoing damage.
  final double damageScale;

  /// The `LadderAi` rung, 1–10. ⭐ Skill is a separate entity from the body:
  /// the same move set at 3 and at 9 is two different opponents.
  final int intelligence;

  /// How many moves this shape wants, and the cost band they sit in.
  ///
  /// ⭐ **Tempo lean is the cost band, not a new field** (§2.5): "slow" means
  /// expensive moves, so it must charge and therefore telegraphs.
  final int moveCount;
  final int minMoveCost;
  final int maxMoveCost;

  /// One line on what this archetype teaches the player (§2.7).
  final String teaches;

  const EnemyArchetype({
    required this.id,
    required this.name,
    required this.tier,
    required this.hpScale,
    required this.damageScale,
    required this.intelligence,
    required this.moveCount,
    required this.minMoveCost,
    required this.maxMoveCost,
    required this.teaches,
  });

  /// ⭐ The fight's total weight. Within a tier these cluster, so archetypes
  /// trade HP against damage rather than being strictly better or worse.
  double get product => hpScale * damageScale;
}

/// ⚠️ **Coefficients are starting values**, to be moved by the balance sim.
abstract final class Archetypes {
  // ---- common: the eight you meet constantly --------------------------
  static const drudge = EnemyArchetype(
    id: 'drudge',
    name: 'Drudge',
    tier: EnemyTier.common,
    hpScale: 0.80,
    damageScale: 0.70,
    intelligence: 1,
    moveCount: 1,
    minMoveCost: 1,
    maxMoveCost: 1,
    teaches: 'the charge/cast loop, while losing nothing',
  );
  static const skirmisher = EnemyArchetype(
    id: 'skirmisher',
    name: 'Skirmisher',
    tier: EnemyTier.common,
    hpScale: 0.70,
    damageScale: 1.15,
    intelligence: 3,
    moveCount: 2,
    minMoveCost: 1,
    maxMoveCost: 2,
    teaches: 'priority — it acts before you and you must plan around that',
  );
  static const lasher = EnemyArchetype(
    id: 'lasher',
    name: 'Lasher',
    tier: EnemyTier.common,
    hpScale: 0.85,
    damageScale: 1.00,
    intelligence: 3,
    moveCount: 2,
    minMoveCost: 1,
    maxMoveCost: 3,
    teaches: 'why a big shield is not always the answer',
  );
  static const glasswing = EnemyArchetype(
    id: 'glasswing',
    name: 'Glasswing',
    tier: EnemyTier.common,
    hpScale: 0.50,
    damageScale: 1.70,
    intelligence: 4,
    moveCount: 2,
    minMoveCost: 1,
    maxMoveCost: 3,
    teaches: 'killing fast beats playing safe',
  );
  static const adept = EnemyArchetype(
    id: 'adept',
    name: 'Adept',
    tier: EnemyTier.common,
    hpScale: 1.00,
    damageScale: 0.90,
    intelligence: 5,
    moveCount: 3,
    minMoveCost: 1,
    maxMoveCost: 3,
    teaches: 'the yardstick every other archetype is felt against',
  );
  static const sentinel = EnemyArchetype(
    id: 'sentinel',
    name: 'Sentinel',
    tier: EnemyTier.common,
    hpScale: 1.25,
    damageScale: 0.70,
    intelligence: 4,
    moveCount: 2,
    minMoveCost: 2,
    maxMoveCost: 4,
    teaches: 'shield-breaking, and it makes Barrage feel good',
  );
  static const bruiser = EnemyArchetype(
    id: 'bruiser',
    name: 'Bruiser',
    tier: EnemyTier.common,
    hpScale: 1.15,
    damageScale: 1.10,
    intelligence: 3,
    moveCount: 2,
    minMoveCost: 2,
    maxMoveCost: 5,
    teaches: 'reading the charge bar — it is completely telegraphed',
  );
  static const blighter = EnemyArchetype(
    id: 'blighter',
    name: 'Blighter',
    tier: EnemyTier.common,
    hpScale: 1.00,
    damageScale: 0.60,
    intelligence: 5,
    moveCount: 2,
    minMoveCost: 1,
    maxMoveCost: 2,
    teaches: 'what statuses actually do',
  );
  static const siphon = EnemyArchetype(
    id: 'siphon',
    name: 'Siphon',
    tier: EnemyTier.common,
    hpScale: 0.95,
    damageScale: 0.85,
    intelligence: 5,
    moveCount: 2,
    minMoveCost: 1,
    maxMoveCost: 3,
    teaches: 'chip damage never accumulates — commit to burst',
  );

  // ---- mini-boss: the four that gate a section ------------------------
  static const champion = EnemyArchetype(
    id: 'champion',
    name: 'Champion',
    tier: EnemyTier.mini,
    hpScale: 1.70,
    damageScale: 1.20,
    intelligence: 7,
    moveCount: 3,
    minMoveCost: 1,
    maxMoveCost: 4,
    teaches: 'a clean skill check',
  );
  static const redoubt = EnemyArchetype(
    id: 'redoubt',
    name: 'Redoubt',
    tier: EnemyTier.mini,
    hpScale: 2.20,
    damageScale: 0.85,
    intelligence: 6,
    moveCount: 3,
    minMoveCost: 2,
    maxMoveCost: 4,
    teaches: 'attrition — and needs the fatigue clock to stay honest',
  );
  static const executioner = EnemyArchetype(
    id: 'executioner',
    name: 'Executioner',
    tier: EnemyTier.mini,
    hpScale: 1.20,
    damageScale: 1.90,
    intelligence: 7,
    moveCount: 2,
    minMoveCost: 3,
    maxMoveCost: 5,
    teaches: 'bring a shield — one misplay ends you',
  );
  static const hexer = EnemyArchetype(
    id: 'hexer',
    name: 'Hexer',
    tier: EnemyTier.mini,
    hpScale: 1.60,
    damageScale: 0.75,
    intelligence: 8,
    moveCount: 3,
    minMoveCost: 1,
    maxMoveCost: 3,
    teaches: 'it punishes a bad loadout, not bad reflexes',
  );

  // ---- boss: the three that end a zone --------------------------------
  static const juggernaut = EnemyArchetype(
    id: 'juggernaut',
    name: 'Juggernaut',
    tier: EnemyTier.boss,
    hpScale: 3.60,
    damageScale: 1.40,
    intelligence: 7,
    moveCount: 3,
    minMoveCost: 3,
    maxMoveCost: 5,
    teaches: 'endurance — it pays for its size by being predictable',
  );
  static const tyrant = EnemyArchetype(
    id: 'tyrant',
    name: 'Tyrant',
    tier: EnemyTier.boss,
    hpScale: 2.60,
    damageScale: 1.70,
    intelligence: 9,
    moveCount: 3,
    minMoveCost: 1,
    maxMoveCost: 5,
    teaches: 'the intelligence is the threat',
  );
  static const aspect = EnemyArchetype(
    id: 'aspect',
    name: 'Aspect',
    tier: EnemyTier.boss,
    hpScale: 2.60,
    damageScale: 1.50,
    intelligence: 8,
    moveCount: 3,
    minMoveCost: 1,
    maxMoveCost: 4,
    teaches: 'one element, taken to an extreme the player has never seen',
  );

  static const all = <EnemyArchetype>[
    drudge,
    skirmisher,
    lasher,
    glasswing,
    adept,
    sentinel,
    bruiser,
    blighter,
    siphon,
    champion,
    redoubt,
    executioner,
    hexer,
    juggernaut,
    tyrant,
    aspect,
  ];

  static EnemyArchetype byId(String id) => all.firstWhere((a) => a.id == id);
}
