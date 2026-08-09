/// Everything the Cinderpeak Foothills can yield (Lv 6–11, Pyro).
///
/// ⭐ Pure zone: two materials. Copper is the first ⏳ **banking material**
/// (§9b.8) — gatherable from level 6, spendable when Forgeholm's
/// Metalworking opens at 15. The signposting matters: "you will want this
/// later" is a promise, not a tax.
library;

import '../item_def.dart';

abstract final class CinderpeakItems {
  // ---- materials ------------------------------------------------------

  /// ⏳ Banks for Q2. ⚠️ No Q1 recipe consumes it — by ruling, not omission.
  static const copperOre = MaterialDef(
    id: 'copper_ore',
    properName: 'Copper Ore',
    rarity: Rarity.common,
    lore:
        'The hills here rust green. Forgeholm pays for it by the sack and '
        'does not say what the hurry is.',
    skill: CraftSkill.metalworking,
    tier: 2,
  );

  /// The tier-2 hide.
  static const tuskhide = MaterialDef(
    id: 'tuskhide',
    properName: 'Tuskhide',
    rarity: Rarity.common,
    lore:
        'Scarred, singed, and thicker than a door. Whatever wears it walks '
        'through embers on purpose.',
    skill: CraftSkill.tailoring,
    tier: 2,
  );

  // ---- equipment ------------------------------------------------------

  static const tuskhideBelt = EquipmentDef(
    id: 'tuskhide_belt',
    rarity: Rarity.common,
    lore: 'Two bottles and room for a third. The buckle outweighs the knife.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Tuskhide',
    modifiers: ItemModifiers(beltSlots: 2),
    salvage: [SalvageYield('tuskhide', 1, 2)],
    equipLevel: 11,
    value: 110,
  );

  /// ⭐ **The game's only crafted-adjacent crit source in Q1** (§9b.8): base
  /// crit is +50% damage, each crit-damage point adds one — this ring alone
  /// is a 5% chance of 155%. A preview of a Q2 mechanic, sold early by a
  /// mini-boss. 📝 Dropper: The Emberqueen, when the roster is built.
  static const cinderLoop = EquipmentDef(
    id: 'cinder_loop',
    properName: 'Cinder Loop',
    rarity: Rarity.rare,
    lore:
        'A ring of char that never quite goes out. Wearing it feels like the '
        'moment before a pot boils over.',
    slot: EquipSlot.ring,
    form: 'Ring',
    material: 'Cinder',
    modifiers: ItemModifiers(critChance: 5, critDamage: 5),
    tradability: Tradability.untradeable,
    equipLevel: 9,
    value: 220,
  );

  static const all = <ItemDef>[copperOre, tuskhide, tuskhideBelt, cinderLoop];
}
