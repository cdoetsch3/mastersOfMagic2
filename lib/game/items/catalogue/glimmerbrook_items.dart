/// Everything Glimmerbrook can yield (Lv 3–8, Aqua).
///
/// ⭐ Pure zone, so exactly TWO materials (ITEMS §9b.8): the quarter's hide
/// and its Draught herb both start here. ✅ The roster is built
/// (`lib/game/enemies/glimmerbrook.dart`), so every id below is dropped or
/// crafted — `test/glimmerbrook_test.dart` proves it.
library;

import 'package:mom_engine/mom_engine.dart';

import '../item_def.dart';

abstract final class GlimmerbrookItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ Leather. Belts are a Tailoring product (ITEMS §10.3d), and this is
  /// where the line starts.
  static const fawnhide = MaterialDef(
    id: 'fawnhide',
    properName: 'Fawnhide',
    rarity: Rarity.common,
    lore:
        'Thin, and it takes a dye better than anything else this close to '
        'the water. Nobody in Hearthwood will say where they get it.',
    skill: CraftSkill.tailoring,
    tier: 1,
  );

  /// The Draught herb (§9b.8's potion grammar: ingredient = magnitude).
  static const sapwort = MaterialDef(
    id: 'sapwort',
    properName: 'Sapwort',
    rarity: Rarity.common,
    lore:
        'Grows with its feet in the brook and its head in the sun, and tastes '
        'of neither.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 1,
  );

  // ---- motes ----------------------------------------------------------
  //
  // ⭐ The Aqua ladder, same three rungs and the same rate shape as Flora's
  // (ITEMS §8): dust off everything, shard off the tougher commons upward,
  // crystal from mini-bosses only. ⚠️ The ladder is a **catalogue-wide**
  // resource, not a zone-local one — Thornmire drops these too, because a
  // hybrid drops both its parents' motes. Defining them here rather than in
  // a shared file follows the WW precedent: the mote lives with the zone
  // that first yields it.

  static const aquaDust = MoteDef(
    id: 'aqua_dust',
    properName: 'Aqua Dust',
    rarity: Rarity.common,
    lore: 'What water leaves when it is broken faster than it can close.',
    tier: MoteTier.dust,
    element: MagicElement.aqua,
  );

  static const aquaShard = MoteDef(
    id: 'aqua_shard',
    properName: 'Aqua Shard',
    rarity: Rarity.common,
    lore: 'Dust that stood in one place long enough to set.',
    tier: MoteTier.shard,
    element: MagicElement.aqua,
  );

  /// ⚠️ Uncommon — mini-bosses and bosses only, exactly as Flora Crystal is.
  /// ⭐ The lore deliberately echoes it: the crystals are the same object in
  /// different elements, and the pair reads as a set.
  static const aquaCrystal = MoteDef(
    id: 'aqua_crystal',
    properName: 'Aqua Crystal',
    rarity: Rarity.uncommon,
    lore: 'It is cold, and it does not stop being cold.',
    tier: MoteTier.crystal,
    element: MagicElement.aqua,
  );

  // ---- consumables ----------------------------------------------------

  /// ⭐ Beltable, so it can be drunk mid-duel — at the cost of the turn.
  /// The Draught form: a flat heal, always (§9b.8).
  static const sapwortDraught = BeltableDef(
    id: 'sapwort_draught',
    properName: 'Sapwort Draught',
    rarity: Rarity.common,
    lore:
        'Tastes like the underside of a leaf. Apprentices carry two and use '
        'neither, which is its own kind of lesson.',
    // ⚠️ Weaker than a ration on purpose: this one costs a TURN, and the
    // opponent committed blind, so its value is the timing, not the number.
    effect: ItemEffect(healPercent: 20),
    value: 12,
  );

  // ---- equipment ------------------------------------------------------

  /// ⭐ The first belt in the game (ITEMS §10.3d) — capacity, nothing else.
  static const fawnhideBelt = EquipmentDef(
    id: 'fawnhide_belt',
    rarity: Rarity.common,
    lore: 'Soft enough to sleep in. It will hold a bottle where you can '
        'reach it, which is worth more than it sounds.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Fawnhide',
    modifiers: ItemModifiers(beltSlots: 1),
    salvage: [SalvageYield('fawnhide', 1, 2)],
    equipLevel: 4,
    value: 40,
  );

  /// ⭐ **Drop-only jewelry** (§9b.8): no maker until Rimeholt, so the mini
  /// pool is the only source. ✅ Dropper: the mini table, authored for the
  /// **Frostgleam Naiad** — the pool shares one table per the Whispering Woods
  /// shape, so all four minis carry it at the chase weight.
  static const brookstonePendant = EquipmentDef(
    id: 'brookstone_pendant',
    properName: 'Brookstone Pendant',
    rarity: Rarity.rare,
    lore:
        'A river pebble with a hole worn through it, strung on gut. Looking '
        'through the hole shows the same world, calmer.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Brookstone',
    modifiers: ItemModifiers(shieldStrengthPercent: 10),
    tradability: Tradability.untradeable,
    equipLevel: 6,
    value: 200,
  );

  // ---- the gate ------------------------------------------------------

  /// ⭐ **The second of Hearthwood's *"three ordinary proofs"*** (`world.dart`)
  /// — one from each Primal pure zone. ⚠️ Both bosses guarantee it on their
  /// `always` list; on a main table it would be luck, and progression behind a
  /// dice roll is the failure the Woods' proof was written to avoid.
  static const proofOfTheBrook = KeyDef(
    id: 'proof_of_the_brook',
    properName: 'Proof of the Brook',
    rarity: Rarity.rare,
    lore:
        'A pale river stone that has not warmed since it left the water. The '
        'guard on the north road weighs it in his palm and takes his time.',
    gates: 'hearthwood',
  );

  static const all = <ItemDef>[
    fawnhide,
    sapwort,
    aquaDust,
    aquaShard,
    aquaCrystal,
    sapwortDraught,
    fawnhideBelt,
    brookstonePendant,
    proofOfTheBrook,
  ];
}
