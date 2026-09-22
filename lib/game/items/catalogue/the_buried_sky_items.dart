/// Everything The Buried Sky can yield (Lv 46–50, Geo + Astral).
///
/// ⭐⭐ **Jewelry's debut zone, and the arithmetic is deliberate**
/// (ETHEREAL_CONTRACT §4.2). The Buried Sky opens at 46, one level after
/// Rimeholt's station, and it is where `craft_everice_band` and
/// `craft_nacre_pendant` live — the two recipes that spend the gems banked in
/// Q2 and Q3. ⚠️ **A player's first Jewelry craft is made of things they
/// picked up thirty levels ago.**
///
/// ⭐ **`everice_band` is the most load-bearing item in either contract, and
/// it is a Common ring worth 260 gold.** Its equip level is **45**, one below
/// this zone's band floor of 46, deliberately: a player learns Jewelry at
/// Rimeholt and should be able to wear the first thing they make before they
/// walk anywhere. ⚠️ The zone test exempts it by name.
///
/// ⚠️ **`stonefall_signet` carries `deflectChance` with NO `deflectAmount`** —
/// normally KINETIC §2.1's inert-stat trap. ⭐ It is not, and this is the one
/// place the rule is deliberately bent: §2.1b's cap makes *amount* the scarce
/// resource, so a chance-only piece is real value to a player who already has
/// gloves and dead weight to one who does not. 📝 If it reads as a bug rather
/// than a build, give it `deflectAmount: 6` and drop `the_corona` to 8.
///
/// ⚠️ **No motes defined here.** A hybrid never defines a mote family (§3.2)
/// and both parents already have theirs — `geo_*` lives with the Old Quarry
/// (**Q2**), `astral_*` with Starfall Basin (**Q3**). This zone drops both and
/// defines neither.
///
/// ⚠️ **No key.** §4.2's catalogue table strikes `the_dark_third` out and
/// §3.4's reconciliation moves it to The Umbral Wastes, one of the quarter's
/// three **pure** zones. 📝 The contract's §7.1 count of "Buried Sky 10" was
/// written before that move and is one high; nine is the reconciled figure.
///
/// ⭐ **`corebiter_hide` is kill-only and has no node** (§3.1) — it comes off
/// the thing that eats downward, and a node for it would be a second source
/// contradicting its own fiction. `deepsteel_ingot` has no node either, for
/// the opposite reason: it is smelted, not dug.
///
/// 📝 **Phase 8 hook.** The **Geo or Astral enchant**, and — ⭐ the strongest
/// socket argument in the game — the Buried Sky is full of set stones nobody
/// has cut. When ITEMS §6d ships, this zone's mini pool is the natural
/// **Lesser gem** drop in the Ethereal band. ⚠️ No `socketCount` is authored
/// here; the hook is a note, not a definition (§3.6).
library;

import '../item_def.dart';

abstract final class BuriedSkyItems {
  // ---- materials ------------------------------------------------------

  /// ⭐ The zone's headline material and the input to `deepsteel_ingot`. Mined
  /// at `bs_stratum_seam` — and, uniquely in the game, at a node in **another
  /// zone**: Hallowmarch's `hm_causeway_quarry`, because the causeway's stone
  /// came from down here (§6).
  static const deepstratumOre = MaterialDef(
    id: 'deepstratum_ore',
    properName: 'Deepstratum Ore',
    rarity: Rarity.common,
    lore:
        'Out of the lowest band the shaft reaches. It is older than iron has '
        'any business being.',
    skill: CraftSkill.metalworking,
    tier: 8,
    value: 120,
  );

  /// ⭐ **Spendable the day it is found — the station is open.** The garnet is
  /// the first Jewelry material a player meets after Rimeholt teaches the
  /// skill, and `craft_everice_band` eats one.
  static const nadirGarnet = MaterialDef(
    id: 'nadir_garnet',
    properName: 'Nadir Garnet',
    rarity: Rarity.uncommon,
    lore:
        'Cut out of the bottom band. Held up, the flecks in it are a '
        'constellation and it is not one of ours.',
    skill: CraftSkill.jewelry,
    tier: 8,
    value: 180,
  );

  /// ⚠️ **Kill-only, no node** (§3.1) — one of only five true hides in the
  /// two late quarters. It is what the `hide` drop role resolves to here.
  static const corebiterHide = MaterialDef(
    id: 'corebiter_hide',
    properName: 'Corebiter Hide',
    rarity: Rarity.common,
    lore:
        'Off the thing that eats downward. It has never seen light and it '
        'does not reflect any.',
    skill: CraftSkill.tailoring,
    tier: 8,
    value: 700,
  );

  /// ⭐ The zone's intermediate good, and it feeds four recipes — both
  /// Spiritwood weapons, the Nacre Pendant and its own smelt. ⚠️ Its recipe
  /// belongs to the quarter's recipe lane, not to this file.
  static const deepsteelIngot = MaterialDef(
    id: 'deepsteel_ingot',
    properName: 'Deepsteel Ingot',
    rarity: Rarity.common,
    lore: 'Smelted at Vespergate, because nowhere higher has fuel.',
    skill: CraftSkill.metalworking,
    tier: 8,
    value: 360,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The belt-capacity ladder's Ethereal rung: … Palimpsest 6 → Corebiter
  /// **7**. ⚠️ Belts carry `beltSlots` and nothing else — capacity is the one
  /// axis that is deliberately *not* combat power (ITEMS §6b.2).
  /// ⚠️ **`properName` stays null**: this is crafted (§5.1 #14), so its name
  /// composes from material + form by the §9b.5a grammar.
  static const corebiterBelt = EquipmentDef(
    id: 'corebiter_belt',
    rarity: Rarity.common,
    lore: 'Seven loops of a hide that takes no dye and needs none.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Corebiter',
    modifiers: ItemModifiers(beltSlots: 7),
    salvage: [SalvageYield('corebiter_hide', 1, 2)],
    equipLevel: 48,
    value: 1690,
  );

  /// ⭐⭐ **The first Jewelry recipe in the game** (§5.1 #26, gate 1), and the
  /// reason KINETIC §8.1 told a level-15 player to keep the jasper. ⚠️ Equip
  /// level **45**, one under the band floor, on purpose — see the library
  /// note.
  static const evericeBand = EquipmentDef(
    id: 'everice_band',
    rarity: Rarity.common,
    lore:
        'Ice that never warmed, set in a band by somebody who finally had '
        'the tools. It has been in a pack since Frostfell.',
    slot: EquipSlot.ring,
    form: 'Band',
    material: 'Everice',
    modifiers: ItemModifiers(
      shieldStrengthPercent: 12,
      maxHpBonus: 15,
      dodge: 3,
    ),
    salvage: [SalvageYield('nadir_garnet', 1, 1)],
    equipLevel: 45,
    value: 260,
  );

  /// ⭐ The second half of the banking payoff (§5.1 #27): shell off the
  /// Tidewrack flats (**Q3**) backed in Molten Deep obsidian (**Q2**), set
  /// with this zone's own ingot.
  static const nacrePendant = EquipmentDef(
    id: 'nacre_pendant',
    rarity: Rarity.common,
    lore:
        'Shell off the Tidewrack flats, backed in black glass. Nobody at '
        'Concordance knew what it was for. Rimeholt did.',
    slot: EquipSlot.neck,
    form: 'Pendant',
    material: 'Nacre',
    modifiers: ItemModifiers(
      maxHpBonus: 25,
      dodge: 6,
      shieldStrengthPercent: 8,
    ),
    salvage: [SalvageYield('deepsteel_ingot', 1, 1)],
    equipLevel: 46,
    value: 680,
  );

  /// ⭐ The mini pool's Rare chase. ⚠️ `properName` is set — drop-only jewelry
  /// keeps its own name (§3.5). See the library note for why the bare
  /// `deflectChance` is a build rather than a bug.
  static const stonefallSignet = EquipmentDef(
    id: 'stonefall_signet',
    properName: 'Stonefall Signet',
    rarity: Rarity.rare,
    lore: 'The face is blank. Whatever it sealed, the seal is what mattered.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Nadir Garnet',
    modifiers: ItemModifiers(deflectChance: 18, maxHpBonus: 22, critChance: 6),
    tradability: Tradability.untradeable,
    equipLevel: 48,
    value: 2700,
  );

  /// ⭐ The zone's epic, boss-pool only — the stuff that was under everything,
  /// worn. Its deflect pair is 10/10, an EV of 1.0%: honest, small, and
  /// stacking with the signet's chance rather than duplicating it.
  static const bedrockGreaves = EquipmentDef(
    id: 'bedrock_greaves',
    properName: 'Bedrock Greaves',
    rarity: Rarity.epic,
    lore:
        'Plated in the stuff that was under everything. They are not '
        'comfortable and they have never once given.',
    slot: EquipSlot.robeBottom,
    form: 'Greaves',
    material: 'Deepsteel',
    modifiers: ItemModifiers(
      maxHpBonus: 45,
      deflectChance: 10,
      deflectAmount: 10,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 50,
    value: 7600,
  );

  static const all = <ItemDef>[
    deepstratumOre,
    nadirGarnet,
    corebiterHide,
    deepsteelIngot,
    corebiterBelt,
    evericeBand,
    nacrePendant,
    stonefallSignet,
    bedrockGreaves,
  ];
}
