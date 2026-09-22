/// Everything The Unwritten Library can yield (Lv 54–58, Umbra + Arcane —
/// ETHEREAL_CONTRACT §4.7).
///
/// ⭐ **Theme: it is still writing, and it wants you in it.** The fusion is
/// **authorship with no author** — Arcane supplies the writing, Umbra
/// supplies the nobody.
///
/// ⭐ **Three materials, because a hybrid gets three** (ITEMS §9b.8 ruling 7):
/// Nightink feeds Potions, Colophon Stone feeds Jewelry, Blankspine Vellum
/// feeds Tailoring. ⚠️ **The vellum is a hide** (§3.1: *"A blankspine is a
/// vellum is a hide"*) — kill-only, no gather node, ever. It is deliberately
/// paired with the Glass Archive's `palimpsest_vellum` one quarter earlier:
/// the Archive's page had been written on and scraped; the Library's never
/// has, *yet*.
///
/// ⚠️ **No mote family is defined here.** This zone pays in `umbra_*` +
/// `arcane_*` and owns neither: `umbra_*` belongs to The Umbral Wastes
/// (§3.2, a parallel Ethereal lane) and `arcane_*` to **The Glass Archive**,
/// seven levels downhill in the Celestial quarter (CELESTIAL §3.2 — *the mote
/// lives with the zone that first yields it*). ⚠️ A builder looking for
/// `arcane_dust` in the Ethereal quarter will not find it, and that is
/// correct.
///
/// ⚠️ **`nightink_draught` at 320 is the largest heal in the game** and the
/// top rung of §3.3's ladder. The check §3.3 applies still holds: it is two
/// thirds of one cast and it costs the turn.
///
/// ⭐ **The belt ladder completes here: … Penitent 8 → Blankspine 9.**
/// `Carrying.maxBeltSlots` is 10, so one rung is left — 📝 deliberately, for
/// Zenith or for Phase 8.
///
/// ⭐⭐ **`the_open_colophon` is the game's first and only off-hand that is
/// not a Knot** (§4.7), and ITEMS §9b.6's own 💡 asked for it. A **Codex** is
/// the book family's debut and its identity is the wand lane's — per-cast
/// damage and the accuracy to land it — which is what makes wand + codex a
/// real alternative to `the_unbuilt_stair` at the top of the game. 📝 The two
/// lanes measured (§4.7): the staff gives +40 flat on a 4-charge cast; wand +
/// codex gives +22 flat, +14 accuracy and +17 crit chance.
///
/// ⚠️ **Rarity discipline (§3.6):** every armour piece here is a plain Common
/// so Phase 8 can add set Tiers III/IV *beside* them rather than instead of
/// them. Mythic and Legendary appear nowhere in this quarter.
///
/// 📝 **Four "colophon" strings in one zone** (§7.2) — the creature
/// *Colophon*, `colophon_stone`, `colophon_signet` and `the_open_colophon`.
/// The ids are distinct; the **display** names may read as a set they are
/// not.
library;

import '../item_def.dart';

abstract final class UnwrittenLibraryItems {
  // ---- materials --------------------------------------------------------

  /// Potions, tier 10 — the band's reagent and `nightink_draught`'s only
  /// input (§5.1 #25, `nightink` ×4).
  static const nightink = MaterialDef(
    id: 'nightink',
    properName: 'Nightink',
    rarity: Rarity.common,
    lore:
        'It is being made somewhere and it is arriving here. Nobody has '
        'found the somewhere.',
    skill: CraftSkill.potionsAndAlchemy,
    tier: 10,
    value: 63,
  );

  /// ⚠️ Uncommon, which is the gem grade — `uncommon` survives on gem-grade
  /// materials and Crystal motes and nowhere else in this quarter (§0.2).
  static const colophonStone = MaterialDef(
    id: 'colophon_stone',
    properName: 'Colophon Stone',
    rarity: Rarity.uncommon,
    lore:
        'The stone a book\'s last page is cut from. There are a great many '
        'of them here and every book is still being written.',
    skill: CraftSkill.jewelry,
    tier: 10,
    value: 480,
  );

  /// ⚠️ **A hide, and therefore kill-only** (§3.1; ITEMS §9b.7b). It has no
  /// gather node and must not acquire one — a node for a hide is a second
  /// source that contradicts its own fiction. ⭐ It is this zone's `hide`
  /// drop role, so §3.5.1's second-material fallback does NOT apply here.
  static const blankspineVellum = MaterialDef(
    id: 'blankspine_vellum',
    properName: 'Blankspine Vellum',
    rarity: Rarity.common,
    lore:
        'It has not been written on yet. That is the only difference '
        'between it and everything else here.',
    skill: CraftSkill.tailoring,
    tier: 10,
    value: 1400,
  );

  // ---- consumables ------------------------------------------------------

  /// ⭐ **The largest heal in the game**, and the Draught form's last rung
  /// (§3.3: *Ration = 35% of the band floor's health · Draught = 40% · Tonic
  /// = 24% total*). 320 against a level-54 bar of 798 is 40.1%.
  /// ⚠️ **Value is not priced against the heal number** (the 2026-09-21
  /// ruling): 250 sits just under Σ(inputs) = 4 × 63 = 252 so
  /// buy→craft→vendor cannot profit (§5.4).
  static const nightinkDraught = BeltableDef(
    id: 'nightink_draught',
    properName: 'Nightink Draught',
    rarity: Rarity.common,
    lore:
        'Black, thick, and it tastes of nothing whatsoever. Vespergate '
        'brews it and will not say from what.',
    effect: ItemEffect(heal: 320),
    value: 250,
  );

  // ---- equipment --------------------------------------------------------

  /// ⭐ The belt-capacity ladder's last authored rung: Fawnhide 1 → … →
  /// Palimpsest 6 → … → Penitent 8 → **Blankspine 9**. ⚠️ Belts carry
  /// `beltSlots` and nothing else — capacity is the one axis that is
  /// deliberately *not* combat power (ITEMS §6b.2).
  /// ⚠️ **`properName` stays null**: this is crafted (§5.1 #21), so its name
  /// is composed from material + form by the §9b.5a grammar rather than
  /// written down here where it could drift.
  static const blankspineBelt = EquipmentDef(
    id: 'blankspine_belt',
    rarity: Rarity.common,
    lore:
        'Nine loops of a vellum that has not been written on. You will want '
        'to keep it that way.',
    slot: EquipSlot.belt,
    form: 'Belt',
    material: 'Blankspine',
    modifiers: ItemModifiers(beltSlots: 9),
    salvage: [SalvageYield('blankspine_vellum', 1, 2)],
    equipLevel: 56,
    value: 3320,
  );

  /// ⭐ The mini pool's Rare chase. Umbra's gear affinity is **crit damage**
  /// (§2.5a), and a signet that presses one deep mark is that said as an
  /// object: it does not happen often and when it does it was decided.
  static const colophonSignet = EquipmentDef(
    id: 'colophon_signet',
    properName: 'Colophon Signet',
    rarity: Rarity.rare,
    lore: 'It presses a mark that means \'ends here\'. Nothing here ends.',
    slot: EquipSlot.ring,
    form: 'Signet',
    material: 'Colophon Stone',
    modifiers: ItemModifiers(accuracyBonus: 3, critChance: 12, critDamage: 30),
    tradability: Tradability.untradeable,
    equipLevel: 56,
    value: 6400,
  );

  /// ⭐⭐ **The game's first and only non-Knot off-hand** (§4.7). The Codex
  /// is the book family's debut and it carries the wand lane's identity:
  /// per-cast damage, plus the accuracy to land it.
  /// ⚠️ **Not two-handed and not a main hand** — it is what a wand is held
  /// *with*, which is the whole point of the pairing.
  static const theOpenColophon = EquipmentDef(
    id: 'the_open_colophon',
    properName: 'The Open Colophon',
    rarity: Rarity.epic,
    lore:
        'Held open at the last page. The last page is being written and it '
        'is about you.',
    slot: EquipSlot.offHand,
    form: 'Codex',
    material: 'Blankspine',
    modifiers: ItemModifiers(
      accuracyBonus: 9,
      critChance: 8,
      damagePerCast: 12,
    ),
    tradability: Tradability.untradeable,
    equipLevel: 58,
    value: 17500,
  );

  /// ✅ **7 defs** — §7.1's count for this zone: 3 materials + 1 consumable +
  /// 3 equipment. ⚠️ **No motes and no key**: the mote families are owned
  /// elsewhere (§3.2) and this is not a gate zone (§2e.1 — the three Ethereal
  /// fragments fall in Hallowmarch, The Umbral Wastes and The Collapsed
  /// Academy).
  static const all = <ItemDef>[
    nightink,
    colophonStone,
    blankspineVellum,
    nightinkDraught,
    blankspineBelt,
    colophonSignet,
    theOpenColophon,
  ];
}
