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

  /// ⭐ Leather. Belts are a Tailoring product (ITEMS §10.3d), and this is
  /// where the line starts.
  static const fawnhide = MaterialDef(
    id: 'fawnhide',
    properName: 'Fawnhide',
    rarity: Rarity.common,
    lore:
        'Thin, and it takes a dye better than anything else at this depth of '
        'the wood. Nobody in Hearthwood will say where they get it.',
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

  /// ⭐ Beltable, so it can be drunk mid-duel — at the cost of the turn.
  static const sapwortDraught = BeltableDef(
    id: 'sapwort_draught',
    properName: 'Sapwort Draught',
    rarity: Rarity.common,
    lore:
        'Tastes like the underside of a leaf. Apprentices carry two and use '
        'neither, which is its own kind of lesson.',
    // ⚠️ Weaker than a ration on purpose: this one costs a TURN, and the
    // opponent committed blind, so its value is the timing, not the number.
    effect: ItemEffect(healPercent: 15),
    value: 12,
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

  /// ⭐ The first belt in the game (ITEMS §10.3d) — capacity, nothing else.
  static const bindweedBelt = EquipmentDef(
    id: 'bindweed_belt',
    rarity: Rarity.common,
    lore:
        'Woven wet and left to shrink. It will hold a bottle and not much '
        'dignity.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Bindweed',
    modifiers: ItemModifiers(beltSlots: 1),
    salvage: [SalvageYield('bindweed_fibre', 1, 2)],
    value: 30,
  );

  /// ⭐ **Rare — the mini-boss chase.** Rarity buys *capability*: this carries
  /// a modifier that no crafted Common can have at any quality (§9b.6a).
  static const sporecapMantle = EquipmentDef(
    id: 'sporecap_mantle',
    rarity: Rarity.rare,
    lore:
        'Still shedding. Field note: the spores settle on whatever is nearest '
        'and the wearer is rarely nearest.',
    slot: EquipSlot.robeTop,
    form: 'Mantle',
    material: 'Sporecap',
    modifiers: ItemModifiers(dodge: 3, deflectChance: 4),
    socketCount: 1,
    salvage: [SalvageYield('bindweed_fibre', 2, 4)],
    tradability: Tradability.untradeable,
    equipLevel: 4,
    value: 180,
  );

  /// ⭐ **Epic — the boss chase.** Strong modifier, enchantable, socketed.
  static const heartwoodStave = EquipmentDef(
    id: 'heartwood_stave',
    rarity: Rarity.epic,
    lore:
        'Cut from the centre, which is why it is warm. It is still growing, '
        'very slowly, in whichever direction it is pointed.',
    slot: EquipSlot.mainHand,
    form: 'Quarterstaff',
    material: 'Heartwood',
    modifiers: ItemModifiers(critChance: 5, critDamage: 10, accuracyBonus: 2),
    socketCount: 2,
    salvage: [SalvageYield('oak_log', 3, 5)],
    tradability: Tradability.untradeable,
    equipLevel: 5,
    value: 600,
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
    fawnhide,
    floraDust,
    floraShard,
    floraCrystal,
    foragersRation,
    sapwortDraught,
    oakCirclet,
    bindweedBelt,
    sporecapMantle,
    heartwoodStave,
    proofOfTheWoods,
  ];
}
