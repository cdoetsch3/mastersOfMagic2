/// Putting things on, taking things off, and what it all adds up to.
///
/// ⭐ **Pure functions over the profile's own state** — the `equipped` map
/// (slot → instance id) and the instance pool. `GameState` owns the mutation
/// and persistence; this file owns the rules, so the rules are testable
/// without a profile, a duel, or a widget.
library;

import 'package:mom_engine/mom_engine.dart';

import 'item_catalogue.dart';
import 'item_def.dart';
import 'item_instance.dart';

abstract final class Equipping {
  /// What one **owned** item actually grants: the definition's base stats as
  /// its own quality roll made them (`ItemModifiers.scaledBy`).
  ///
  /// ⭐ **THE resolution seam.** An `ItemDef` says what an item is worth in
  /// the abstract; only an [ItemInstance] knows what *this* one is worth. Every
  /// reader — the duel's totals, the equip screen, the item dialog — comes
  /// through here, so a scaling rule changed once is changed everywhere and no
  /// two screens can quote different numbers for the same wand.
  ///
  /// ⚠️ Anything that is not equipment grants nothing: gems carry modifiers
  /// too, but a socketed gem is resolved through the *host* item's sockets,
  /// not by wearing the gem.
  static ItemModifiers modifiersOf(ItemDef? def, [ItemInstance? instance]) {
    if (def is! EquipmentDef) return ItemModifiers.none;
    return def.modifiers.scaledBy(instance?.quality);
  }

  /// The sum of every worn item's modifiers.
  ///
  /// ⭐ **This is THE number the whole system feeds** — the duel reads it, the
  /// belt sizes itself off it, and the Inventory screen shows it. A dangling
  /// instance id contributes nothing rather than throwing: the profile guards
  /// against them, and a stats panel is the wrong place to crash.
  ///
  /// ⚠️ **Resolved, then summed** — quality scales each piece on its own,
  /// because scaling the sum would let one Master ring lift a whole wardrobe.
  static ItemModifiers totals({
    required Map<EquipSlot, String> equipped,
    required Map<String, ItemInstance> instances,
  }) {
    var sum = ItemModifiers.none;
    for (final id in equipped.values) {
      final instance = instances[id];
      final def = ItemCatalogue.tryById(instance?.defId ?? '');
      sum = sum + modifiersOf(def, instance);
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

  /// Base hit chance, before any accuracy gear (ITEMS §9b.8).
  ///
  /// ⭐ **Derived, never typed twice.** The duel rolls against
  /// `ElementTuning.baseMissPercent`; if that dial moves, the number the player
  /// reads moves with it.
  static const int baseHitPercent = 100 - ElementTuning.baseMissPercent;

  /// What a crit deals with no crit-damage gear: 150% of the hit.
  ///
  /// ⚠️ **Mirrors `MageState.critDamage`'s default of +50** on top of the 100%
  /// a normal hit deals. It is a field default rather than a const over in the
  /// engine, so it cannot be imported — this is the one place the app restates
  /// it, and it is stated once.
  static const int baseCritDamagePercent = 150;

  /// The same stats as [describe], but as the numbers the player **ends up
  /// with** — for the "From equipment" panel.
  ///
  /// ⭐ **An ITEM shows its contribution; the PANEL shows your totals**
  /// (designer, 2026-08-17). "+11 max health" answers "what does this hat do";
  /// it does not answer "how much health do I have", which is the question the
  /// panel is on screen to answer. So a stat with a real base prints
  /// `Max health 159 (+11)` — the total, with the gear's share still visible so
  /// the panel keeps saying what the gear is worth.
  ///
  /// ⚠️ **Only stats with a base get the total form.** Damage per cast, shield
  /// strength, healing received, regrow and belt slots have no baseline to add
  /// to (the mage starts at zero of each and nothing else grants them), so a
  /// "total" would be the bonus wearing a disguise. They keep `+N`.
  ///
  /// ⚠️ Still emits only non-zero lines, exactly like [describe]: this panel is
  /// "from equipment", and a full stat sheet listing everything gear does *not*
  /// touch would bury the four lines that matter.
  static List<String> describeTotals(ItemModifiers m, {required int level}) => [
    if (m.maxHpBonus != 0)
      'Max health ${MageState.scaledMaxHp(level) + m.maxHpBonus} '
          '(+${m.maxHpBonus})',
    if (m.damagePerCast != 0) '+${m.damagePerCast} damage per cast',
    if (m.damagePerCharge != 0) '+${m.damagePerCharge} damage per charge spent',
    if (m.accuracyBonus != 0)
      'Accuracy ${baseHitPercent + m.accuracyBonus}% (+${m.accuracyBonus})',
    // ⭐ Base zero, and that is the point of the line: crits exist ONLY through
    // gear (§9b.8), so the total IS the bonus — printed in total form anyway so
    // the panel reads as one sheet rather than two grammars.
    if (m.critChance != 0) 'Crit chance ${m.critChance}% (+${m.critChance})',
    if (m.critDamage != 0)
      'Crit damage ${baseCritDamagePercent + m.critDamage}% '
          '(+${m.critDamage})',
    if (m.dodge != 0) 'Dodge ${m.dodge}% (+${m.dodge})',
    if (m.deflectChance != 0)
      'Deflect chance ${m.deflectChance}% (+${m.deflectChance})',
    if (m.deflectAmount != 0) '${m.deflectAmount}% deflected',
    if (m.shieldStrengthPercent != 0)
      '+${m.shieldStrengthPercent}% shield strength',
    if (m.healingReceivedPercent != 0)
      '+${m.healingReceivedPercent}% healing received',
    if (m.regrowPercent != 0) 'Regrow ${m.regrowPercent}% health each turn',
    if (m.beltSlots != 0) '+${m.beltSlots} belt slots',
  ];
}
