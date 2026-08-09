/// Putting things on, taking things off, and what it all adds up to.
///
/// ⭐ **Pure functions over the profile's own state** — the `equipped` map
/// (slot → instance id) and the instance pool. `GameState` owns the mutation
/// and persistence; this file owns the rules, so the rules are testable
/// without a profile, a duel, or a widget.
library;

import 'item_catalogue.dart';
import 'item_def.dart';
import 'item_instance.dart';

abstract final class Equipping {
  /// The sum of every worn item's modifiers.
  ///
  /// ⭐ **This is THE number the whole system feeds** — the duel reads it, the
  /// belt sizes itself off it, and the Inventory screen shows it. A dangling
  /// instance id contributes nothing rather than throwing: the profile guards
  /// against them, and a stats panel is the wrong place to crash.
  static ItemModifiers totals({
    required Map<EquipSlot, String> equipped,
    required Map<String, ItemInstance> instances,
  }) {
    var sum = ItemModifiers.none;
    for (final id in equipped.values) {
      final def = ItemCatalogue.tryById(instances[id]?.defId ?? '');
      if (def is EquipmentDef) sum = sum + def.modifiers;
    }
    return sum;
  }

  /// Why [def] cannot be equipped right now — null means it can.
  ///
  /// ⭐ Player-facing strings, decided here so every code path refuses with
  /// the same words.
  static String? refusal(ItemDef? def, {required int playerLevel}) {
    if (def is! EquipmentDef) return 'That cannot be worn.';
    if (def.equipLevel > playerLevel) {
      return 'Requires level ${def.equipLevel}.';
    }
    return null;
  }

  /// The stat lines a worn item (or a total) shows, in a fixed order.
  ///
  /// ⭐ **One writer for every stats panel** — built from the modifiers so a
  /// renamed or added field shows up everywhere or nowhere, never in one
  /// screen and not another. Only non-zero lines are emitted (the export
  /// makes the same choice, for the same reason).
  static List<String> describe(ItemModifiers m) => [
    if (m.maxHpBonus != 0) '+${m.maxHpBonus} max health',
    if (m.damagePerCast != 0) '+${m.damagePerCast} damage per cast',
    if (m.damagePerCharge != 0) '+${m.damagePerCharge} damage per charge spent',
    if (m.accuracyBonus != 0) '+${m.accuracyBonus}% accuracy',
    if (m.critChance != 0) '+${m.critChance}% crit chance',
    if (m.critDamage != 0) '+${m.critDamage}% crit damage',
    if (m.dodge != 0) '+${m.dodge}% dodge',
    if (m.deflectChance != 0) '+${m.deflectChance}% deflect chance',
    if (m.deflectAmount != 0) '${m.deflectAmount}% deflected',
    if (m.shieldStrengthPercent != 0)
      '+${m.shieldStrengthPercent}% shield strength',
    if (m.healingReceivedPercent != 0)
      '+${m.healingReceivedPercent}% healing received',
    if (m.regrowPercent != 0) 'Regrow ${m.regrowPercent}% health each turn',
    if (m.beltSlots != 0) '+${m.beltSlots} belt slots',
  ];
}
