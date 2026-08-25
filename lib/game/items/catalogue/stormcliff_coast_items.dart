/// Everything the Stormcliff Coast can yield (Lv 17–22, Electro).
///
/// ⭐ Pure zone: two materials (KINETIC_CONTRACT §3.1, §9b.8 ruling 7).
/// Seawrack Fibre feeds Tailoring; Saltwort feeds Potions & Alchemy. Neither
/// banks — both are spendable in-band, unlike Old Quarry's Tin.
///
/// ⭐ **The quarter's crit/dodge/deflect debut, from the gear side** (§2.5).
/// The Seawrack set carries the game's first crafted dodge (boots) and first
/// crafted deflect (gloves) — small enough to be a lesson rather than a
/// build. Crit stays off this tier entirely and off Fulgurite too (§2.5's
/// "crit stays off the crafted tier-3 entirely" — Fulgurite is drop-only, not
/// crafted, so the Fulgurite Pendant and Uplight are where the player first
/// *meets* crit, not where they buy it).
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class StormcliffCoastItems {
  // ---- materials ------------------------------------------------------

  /// `value: 30` — ECONOMY_CONTRACT §8.2.
  static const seawrackFibre = MaterialDef(
    id: 'seawrack_fibre',
    properName: 'Seawrack Fibre',
    rarity: Rarity.common,
    lore:
        'The tideline\'s own rope, laid out in long dark ropes and salt-cured '
        'by the weather before anyone gets to it. Stiff until it is worked.',
    skill: CraftSkill.tailoring,
    tier: 3,
    value: 30,
  );

  /// `value: 16` — ECONOMY_CONTRACT §8.2.
  static const saltwort = MaterialDef(
    id: 'saltwort',
    properName: 'Saltwort',
    rarity: Rarity.common,
    lore:
        'A low, fleshy herb that grows only where the spray reaches and '
        'nowhere the spray does not. Bites back the way the ocean does.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 3,
    value: 16,
  );

  // ---- motes ----------------------------------------------------------
  //
  // ⭐ The Electro ladder — the mote lives with the zone that first yields it
  // (§3.2). Stormcliff Coast is a pure zone, so it owns all three tiers.

  static const electroDust = MoteDef(
    id: 'electro_dust',
    // ⭐ Ruled 2026-08-25: one vendor value per TIER, uniform across all
    // elements, LOSSY against the refinement ladder (a Shard vendors for
    // less than its 50 Dust cost) so refine-and-vendor can never profit.
    value: 2,
    properName: 'Electro Dust',
    rarity: Rarity.common,
    lore: 'What a struck thing leaves after the light is already gone.',
    tier: MoteTier.dust,
    element: MagicElement.electro,
  );

  static const electroShard = MoteDef(
    id: 'electro_shard',
    // ⭐ Ruled 2026-08-25: one vendor value per TIER, uniform across all
    // elements, LOSSY against the refinement ladder (a Shard vendors for
    // less than its 50 Dust cost) so refine-and-vendor can never profit.
    value: 25,
    properName: 'Electro Shard',
    rarity: Rarity.common,
    lore: 'Dust that held its charge a moment longer than the rest.',
    tier: MoteTier.shard,
    element: MagicElement.electro,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only. ⭐ Closes the Kinetic triplet
  /// begun by Geo Crystal and finished by Aero Crystal: one sentence of the
  /// same shape, so the ladder reads as one object in nine elements.
  static const electroCrystal = MoteDef(
    id: 'electro_crystal',
    // ⭐ Ruled 2026-08-25: one vendor value per TIER, uniform across all
    // elements, LOSSY against the refinement ladder (a Shard vendors for
    // less than its 50 Dust cost) so refine-and-vendor can never profit.
    value: 150,
    properName: 'Electro Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is live, and it does not discharge.',
    tier: MoteTier.crystal,
    element: MagicElement.electro,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ The Draught form, same shape as Q1's tonics and draughts — a turn
  /// spent drinking is a turn not casting, so a heal can be baited.
  static const saltwortDraught = BeltableDef(
    id: 'saltwort_draught',
    properName: 'Saltwort Draught',
    rarity: Rarity.common,
    lore:
        'Bitter, briny, and it clears the head fast. Galehaven sailors carry '
        'two and swear by both.',
    effect: ItemEffect(healPercent: 30),
    value: 30,
  );

  // ---- equipment: the Seawrack set (Tailoring) -------------------------

  /// ⚠️ **Boundary, not broken**: `craft_seawrack_hood` (seawrack_fibre×2 =
  /// 60) prices Σ(inputs) exactly equal to this Standard value —
  /// ECONOMY_CONTRACT §8.6's own audit blesses it ("seawrack_hood
  /// (60=Standard)"), so the conservation test's `<` bound is a documented
  /// exemption here, not a gap.
  static const seawrackHood = EquipmentDef(
    id: 'seawrack_hood',
    rarity: Rarity.common,
    lore: 'Salt-stiff and close-fitting. It keeps the spray out of the eyes.',
    slot: EquipSlot.hat,
    form: 'Hood',
    material: 'Seawrack',
    modifiers: ItemModifiers(accuracyBonus: 3),
    salvage: [SalvageYield('seawrack_fibre', 1, 1)],
    equipLevel: 16,
    value: 60,
  );

  /// ⭐ `value: 135` — ECONOMY_CONTRACT §8.6/§14b.1's correction (was 95): the
  /// shipped value made this a 🔴 major conservation violation (Σ(inputs)=150
  /// against Ornate=114); the corrected value fits Standard 135 < Σ < Ornate
  /// 162.
  static const seawrackRobe = EquipmentDef(
    id: 'seawrack_robe',
    rarity: Rarity.common,
    lore: 'Woven tight against the wind off the water. Never quite dries.',
    slot: EquipSlot.robeTop,
    form: 'Robe',
    material: 'Seawrack',
    modifiers: ItemModifiers(maxHpBonus: 15),
    salvage: [SalvageYield('seawrack_fibre', 2, 4)],
    equipLevel: 16,
    value: 135,
  );

  /// ⭐ `value: 105` — ECONOMY_CONTRACT §8.6/§14b.1's correction (was 78):
  /// same 🔴 major-violation family as the robe (Σ(inputs)=120 against
  /// Ornate=93.6 at the old value); corrected value fits Standard 105 < Σ <
  /// Ornate 126.
  static const seawrackLeggings = EquipmentDef(
    id: 'seawrack_leggings',
    rarity: Rarity.common,
    lore: 'Salt crusts white along every seam by the second wearing.',
    slot: EquipSlot.robeBottom,
    form: 'Leggings',
    material: 'Seawrack',
    modifiers: ItemModifiers(maxHpBonus: 10),
    salvage: [SalvageYield('seawrack_fibre', 1, 3)],
    equipLevel: 16,
    value: 105,
  );

  /// ⭐ **The game's first crafted dodge** (§2.5) — two points, small enough
  /// to be noticed rather than built around.
  static const seawrackBoots = EquipmentDef(
    id: 'seawrack_boots',
    rarity: Rarity.common,
    lore: 'Soled for wet rock. You stop thinking about your footing in them.',
    slot: EquipSlot.boots,
    form: 'Boots',
    material: 'Seawrack',
    modifiers: ItemModifiers(maxHpBonus: 3, dodge: 2),
    salvage: [SalvageYield('seawrack_fibre', 1, 1)],
    equipLevel: 16,
    value: 55,
  );

  /// ⭐ **The game's first crafted deflect** (§2.5, EV 0.9%) — a glove is the
  /// piece you put in the way.
  static const seawrackGloves = EquipmentDef(
    id: 'seawrack_gloves',
    rarity: Rarity.common,
    lore: 'Thick enough to close a fist around bare wire without noticing.',
    slot: EquipSlot.gloves,
    form: 'Gloves',
    material: 'Seawrack',
    modifiers: ItemModifiers(maxHpBonus: 3, deflectChance: 6, deflectAmount: 15),
    salvage: [SalvageYield('seawrack_fibre', 1, 1)],
    equipLevel: 16,
    value: 55,
  );

  // ---- equipment: the chase ---------------------------------------------

  /// ⭐ Drop-only jewelry — the player's first *meeting* with crit, ahead of
  /// where crafting can buy it (Rowan, equip 25, §2.5).
  static const fulguritePendant = EquipmentDef(
    id: 'fulgurite_pendant',
    properName: 'Fulgurite Pendant',
    rarity: Rarity.rare,
    lore:
        'A shard of fused glass on a plaited cord, dark and faintly '
        'branching, still warm at the core the way a struck thing stays warm '
        'long after the strike.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Fulgurite',
    modifiers: ItemModifiers(critChance: 8, critDamage: 10),
    tradability: Tradability.untradeable,
    equipLevel: 20,
    value: 280,
  );

  /// ⭐ **The quarter's wand epic, and its name is the mechanic** — the
  /// return stroke travels upward. The wand lane's answer to Q1's Heartwood
  /// Staff, and the first weapon to carry both halves of a crit pair.
  static const uplight = EquipmentDef(
    id: 'uplight',
    properName: 'Uplight',
    rarity: Rarity.epic,
    lore:
        'A wand of fused glass, branching like a root at the tip, that never '
        'stops feeling faintly live in the hand. It does not glow so much as '
        'it is always about to.',
    slot: EquipSlot.mainHand,
    form: 'Wand',
    material: 'Fulgurite',
    modifiers: ItemModifiers(
      damagePerCast: 6,
      accuracyBonus: 4,
      critChance: 12,
      critDamage: 15,
    ),
    socketCount: 1,
    tradability: Tradability.untradeable,
    equipLevel: 22,
    value: 760,
  );

  static const all = <ItemDef>[
    seawrackFibre,
    saltwort,
    electroDust,
    electroShard,
    electroCrystal,
    saltwortDraught,
    seawrackHood,
    seawrackRobe,
    seawrackLeggings,
    seawrackBoots,
    seawrackGloves,
    fulguritePendant,
    uplight,
  ];
}
