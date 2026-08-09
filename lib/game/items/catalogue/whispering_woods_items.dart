/// Everything the Whispering Woods can yield (Lv 1–5, Flora).
///
/// ⭐ **The first zone's catalogue, and therefore the template.** Per ITEMS §8,
/// rarity decides *which kinds of property can exist at all*: Common is flat
/// stats only, Rare carries a modifier, Epic carries a strong one. That is why
/// a mini-boss drop beats a Master-crafted item **categorically** rather than
/// numerically (§9b.6a) — the market sells the floor, never the ceiling.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class WhisperingWoodsItems {
  // ---- materials ------------------------------------------------------

  /// ✅ The zone's assigned wood (ITEMS §9b.6, wood ladder tier 1).
  static const oakLog = MaterialDef(
    id: 'oak_log',
    properName: 'Oak Log',
    rarity: Rarity.common,
    lore:
        'Cut green, it weeps for a week. Hearthwood seasons it in the open '
        'because the smoke gets into anything dried indoors.',
    skill: CraftSkill.woodcarving,
    tier: 1,
  );

  /// ⭐ Foraged fibre — the Tailoring input, and what a starter belt is woven
  /// from (ITEMS §6a.1).
  static const bindweedFibre = MaterialDef(
    id: 'bindweed_fibre',
    properName: 'Bindweed Fibre',
    rarity: Rarity.common,
    lore:
        'Strong out of all proportion to its thickness. The trick is cutting '
        'it before it notices.',
    skill: CraftSkill.tailoring,
    tier: 1,
  );
  // ---- motes ----------------------------------------------------------

  static const floraDust = MoteDef(
    id: 'flora_dust',
    properName: 'Flora Dust',
    rarity: Rarity.common,
    lore: 'What a growing thing leaves when it is unmade faster than it grew.',
    tier: MoteTier.dust,
    element: MagicElement.flora,
  );

  static const floraShard = MoteDef(
    id: 'flora_shard',
    properName: 'Flora Shard',
    rarity: Rarity.common,
    lore: 'Dust that settled somewhere it was not disturbed.',
    tier: MoteTier.shard,
    element: MagicElement.flora,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. The step from Shard to Crystal
  /// is the first place the mote ladder is felt (ITEMS §8).
  static const floraCrystal = MoteDef(
    id: 'flora_crystal',
    properName: 'Flora Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is warm, and it does not stop being warm.',
    tier: MoteTier.crystal,
    element: MagicElement.flora,
  );

  // ---- consumables ----------------------------------------------------

  /// ⚠️ **Not Beltable** — a between-encounters item. Eating it mid-duel is
  /// not a thing, which is the distinction ITEMS §10.3b draws.
  static const foragersRation = ConsumableDef(
    id: 'foragers_ration',
    properName: "Forager's Ration",
    rarity: Rarity.common,
    lore: 'Filling. That is the whole of its reputation.',
    // ⭐ Between encounters only — eating mid-duel would be a free turn.
    effect: ItemEffect(healPercent: 25),
    value: 4,
  );
  // ---- equipment ------------------------------------------------------

  /// ⚠️ Common, so **flat stats only** — it structurally cannot carry a
  /// modifier (ITEMS §8). That is the whole reason a Rare drop matters.
  static const oakCirclet = EquipmentDef(
    id: 'oak_circlet',
    rarity: Rarity.common,
    lore: 'A band of green wood, bent and pinned. It tightens as it dries.',
    slot: EquipSlot.hat,
    form: 'Circlet',
    material: 'Oak',
    modifiers: ItemModifiers(accuracyBonus: 1),
    salvage: [SalvageYield('oak_log', 1, 1)],
    value: 20,
  );
  /// ⭐ **Rare — the mini-boss chase.** Beats the Standard crafted robe
  /// (+6 HP) outright, which is what rare means before sockets and riders
  /// exist. ⚠️ Dodge/deflection are Q2 mechanics (§9b.8) — nothing in this
  /// zone may carry them.
  static const sporecapMantle = EquipmentDef(
    id: 'sporecap_mantle',
    rarity: Rarity.rare,
    lore:
        'Still shedding. Field note: the spores settle on whatever is nearest '
        'and the wearer is rarely nearest.',
    slot: EquipSlot.robeTop,
    form: 'Mantle',
    material: 'Sporecap',
    modifiers: ItemModifiers(maxHpBonus: 12, accuracyBonus: 2),
    salvage: [SalvageYield('bindweed_fibre', 2, 4)],
    tradability: Tradability.untradeable,
    equipLevel: 4,
    value: 180,
  );

  /// ⭐ **Epic — the boss chase**, and the game's first crit source alongside
  /// the Cinder Loop. A boss unique is the deliberate exception to "crits are
  /// Q2" (§9b.8) — Birch-staff commitment damage five levels early, plus the
  /// preview of a mechanic no crafted item has.
  static const heartwoodStaff = EquipmentDef(
    id: 'heartwood_stave',
    properName: 'Heartwood Staff',
    rarity: Rarity.epic,
    lore:
        'Cut from the centre, which is why it is warm. It is still growing, '
        'very slowly, in whichever direction it is pointed.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Heartwood',
    modifiers: ItemModifiers(
      damagePerCharge: 3,
      accuracyBonus: 7,
      critChance: 5,
      critDamage: 10,
    ),
    socketCount: 2,
    salvage: [SalvageYield('oak_log', 3, 5)],
    tradability: Tradability.untradeable,
    equipLevel: 5,
    value: 600,
  );

  // ---- crafted: Woodcarving (ITEMS §9b.8) ------------------------------
  //
  // ⭐ The lane choice in two stats: the quarterstaff pays PER CHARGE THE
  // SPELL COST (commitment), the wand PER CAST (tempo). Crossover at 2
  // charges. The staff out-accurates wand + knot combined on purpose — part
  // of the two-hander's budget is sureness.

  static const oakQuarterstaff = EquipmentDef(
    id: 'oak_quarterstaff',
    rarity: Rarity.common,
    lore: 'Season it a year and it stops arguing. Nobody seasons it a year.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Oak',
    modifiers: ItemModifiers(damagePerCharge: 1, accuracyBonus: 5),
    salvage: [SalvageYield('oak_log', 1, 2)],
    value: 30,
  );

  static const oakWand = EquipmentDef(
    id: 'oak_wand',
    rarity: Rarity.common,
    lore: 'Light enough to forget, which is the point of it.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Oak',
    modifiers: ItemModifiers(damagePerCast: 2),
    salvage: [SalvageYield('oak_log', 1, 1)],
    value: 25,
  );

  /// ⭐ The Woodcarving off-hand family (§9b.8). 📝 Form under a naming
  /// reservation — "Knot" holds for the first two tiers.
  static const oakKnot = EquipmentDef(
    id: 'oak_knot',
    rarity: Rarity.common,
    lore:
        'A burl worked smooth, kept in the off hand. Carvers say the tangle '
        'remembers which way it grew, and pointing it settles the question.',
    slot: EquipSlot.offHand,
    form: 'Knot',
    material: 'Oak',
    modifiers: ItemModifiers(accuracyBonus: 3),
    salvage: [SalvageYield('oak_log', 1, 1)],
    value: 20,
  );

  // ---- crafted: the Bindweed set (Tailoring, §9b.8) --------------------
  //
  // ⚠️ Flat HP and accuracy ONLY. Dodge, deflection and crit are Q2's
  // mechanics to introduce; the hood carries the accuracy so the set and the
  // weapons teach the same stat.

  static const bindweedHood = EquipmentDef(
    id: 'bindweed_hood',
    rarity: Rarity.common,
    lore: 'It keeps the sun off, and the wood does the rest.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Bindweed',
    modifiers: ItemModifiers(accuracyBonus: 1),
    salvage: [SalvageYield('bindweed_fibre', 1, 1)],
    value: 18,
  );

  static const bindweedRobe = EquipmentDef(
    id: 'bindweed_robe',
    rarity: Rarity.common,
    lore: 'Woven wet and left to shrink. It fits by the third day.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Bindweed',
    modifiers: ItemModifiers(maxHpBonus: 6),
    salvage: [SalvageYield('bindweed_fibre', 2, 3)],
    value: 30,
  );

  static const bindweedLeggings = EquipmentDef(
    id: 'bindweed_leggings',
    rarity: Rarity.common,
    lore: 'They whistle faintly in a wind. No one has explained it.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Bindweed',
    modifiers: ItemModifiers(maxHpBonus: 4),
    salvage: [SalvageYield('bindweed_fibre', 1, 2)],
    value: 24,
  );

  static const bindweedBoots = EquipmentDef(
    id: 'bindweed_boots',
    rarity: Rarity.common,
    lore: 'Quiet on leaf litter, which in this wood cuts both ways.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Bindweed',
    modifiers: ItemModifiers(maxHpBonus: 1),
    salvage: [SalvageYield('bindweed_fibre', 1, 1)],
    value: 15,
  );

  static const bindweedGloves = EquipmentDef(
    id: 'bindweed_gloves',
    rarity: Rarity.common,
    lore: 'The weave tightens when you grip. Let go slowly.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Bindweed',
    modifiers: ItemModifiers(maxHpBonus: 1),
    salvage: [SalvageYield('bindweed_fibre', 1, 1)],
    value: 15,
  );

  // ---- the gate ------------------------------------------------------

  /// ⭐ **The first real gate item.** Hearthwood's north road asks for *"three
  /// ordinary proofs"* (`world.dart`) — one from each Primal pure zone. Until
  /// now every gate in the game was a prose string with nothing behind it.
  static const proofOfTheWoods = KeyDef(
    id: 'proof_of_the_woods',
    properName: 'Proof of the Woods',
    rarity: Rarity.rare,
    lore:
        'A knot of root that kept growing after it was cut. The guard on the '
        'north road has seen a hundred and still turns each one over twice.',
    gates: 'hearthwood',
  );

  static const all = <ItemDef>[
    oakLog,
    bindweedFibre,
    floraDust,
    floraShard,
    floraCrystal,
    foragersRation,
    oakCirclet,
    oakQuarterstaff,
    oakWand,
    oakKnot,
    bindweedHood,
    bindweedRobe,
    bindweedLeggings,
    bindweedBoots,
    bindweedGloves,
    sporecapMantle,
    heartwoodStaff,
    proofOfTheWoods,
  ];
}
