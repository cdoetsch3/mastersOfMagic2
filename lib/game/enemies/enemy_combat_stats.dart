/// The enemy half of crit / dodge / deflection (KINETIC_CONTRACT §2).
///
/// ⚠️ **Lives on [EnemyDef], never on `EnemyArchetype`.** The sixteen
/// archetype constants are shared with every Q1 creature; a field added there
/// would retroactively give Rootknuckle a crit chance in the tutorial zone
/// (KINETIC_CONTRACT §2.2, ITEMS §9b.8 ruling 5). A per-def field defaulting
/// to [none] leaves Q1 untouched by construction — every existing `EnemyDef`
/// compiles unchanged and stays stat-free.
library;

import 'package:flutter/foundation.dart';

@immutable
class EnemyCombatStats {
  /// Added to the 80% base hit chance, same lane as gear's `accuracyBonus`.
  final int accuracyBonus;

  /// Subtracted from the attacker's hit chance. ⚠️ Contract caps enemy dodge
  /// at 10 — enforced by the authoring table, not by this type.
  final int dodge;

  /// Chance (%) this creature's own attacks crit.
  final int critChance;

  /// Extra crit damage, in percent, ADDED to the engine's base 50 — inert
  /// without [critChance] > 0 (the engine's own guard, MageState/DuelEngine).
  final int critDamage;

  /// Chance (%) this creature deflects an incoming hit.
  final int deflectChance;

  /// Percent of a deflected hit removed — inert without [deflectChance] > 0.
  final int deflectAmount;

  const EnemyCombatStats({
    this.accuracyBonus = 0,
    this.dodge = 0,
    this.critChance = 0,
    this.critDamage = 0,
    this.deflectChance = 0,
    this.deflectAmount = 0,
  });

  /// The inert default — every Q1 `EnemyDef` and any Kinetic def that doesn't
  /// name one. Applying it to a `MageState` changes nothing (KINETIC_CONTRACT
  /// §2.2's invariance requirement).
  static const none = EnemyCombatStats();

  @override
  bool operator ==(Object other) =>
      other is EnemyCombatStats &&
      accuracyBonus == other.accuracyBonus &&
      dodge == other.dodge &&
      critChance == other.critChance &&
      critDamage == other.critDamage &&
      deflectChance == other.deflectChance &&
      deflectAmount == other.deflectAmount;

  @override
  int get hashCode => Object.hash(
    accuracyBonus,
    dodge,
    critChance,
    critDamage,
    deflectChance,
    deflectAmount,
  );

  @override
  String toString() =>
      'EnemyCombatStats(acc: $accuracyBonus, dodge: $dodge, '
      'crit: $critChance/+$critDamage, deflect: $deflectChance/$deflectAmount)';
}
