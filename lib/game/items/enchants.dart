/// Enchants — the element axis laid onto one piece of gear (ENCHANTING_DESIGN
/// §4, ITEMS §6.3).
///
/// ⭐ **An enchant is data the instance points at**, never a field copied onto
/// it: [ItemInstance.enchantId] holds one of the ids below and
/// `Equipping.modifiersOf` resolves it here. Retuning a number in this file
/// retunes every piece already wearing it — the same rule `ItemDef` follows.
///
/// ✅ **Both, by tier** (Christian, 2026-10-01): every tier grants the
/// element's affinity stat (CELESTIAL §2.5a); **Greater** also grants the
/// element's status as a gear proc (§4.1a) — see [EnchantDef.procElement].
///
/// ⚠️ **Ids are forever once a save holds one** (`<element>_<tier>`). A rename
/// here is a save migration, exactly as it is for an item def id.
library;

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'item_def.dart';
import 'item_naming.dart';

/// The three enchant tiers (ENCHANTING_DESIGN §4.2): Lesser (5 Shards,
/// Enchanting 1), Standard (3 Crystals, 15), Greater (1 Core, 30).
enum EnchantTier {
  lesser,
  standard,
  greater;

  /// ⭐ Only Greater carries the gear proc (§4.1a). One getter, so "which
  /// tiers proc" is a fact stated once rather than a `== greater` scattered
  /// through every reader.
  bool get grantsProc => this == EnchantTier.greater;

  /// 'Lesser', 'Standard', 'Greater' — the word the stat line prints.
  String get label => switch (this) {
    EnchantTier.lesser => 'Lesser',
    EnchantTier.standard => 'Standard',
    EnchantTier.greater => 'Greater',
  };
}

/// One enchant: an element at a tier, and what it grants.
@immutable
class EnchantDef {
  /// `<element>_<tier>`, e.g. `pyro_standard`. ⚠️ Forever — see the library
  /// doc.
  final String id;
  final MagicElement element;
  final EnchantTier tier;

  /// The affinity stat(s), from [Affinity.enchantAmount]. ⭐ **Never scaled by
  /// quality** — an enchant is the enchanter's work, not the smith's, so a
  /// Rough staff and a Master staff carry the same Charred (Standard).
  final ItemModifiers modifiers;

  const EnchantDef({
    required this.id,
    required this.element,
    required this.tier,
    required this.modifiers,
  });

  /// The element this enchant procs on hit, or null below Greater (§4.1a).
  MagicElement? get procElement => tier.grantsProc ? element : null;

  /// What wearing it adds: [modifiers], plus the proc as
  /// [ItemModifiers.gearProcs] when there is one.
  ///
  /// ⭐ **The proc rides the modifiers**, so it crosses the PvP handshake,
  /// sums across a wardrobe (a set union — two Greater Pyro pieces are still
  /// one roll) and reaches `DuelController._buildMage` through the exact
  /// seam every other gear stat already uses.
  ItemModifiers get grants {
    final proc = procElement;
    return proc == null
        ? modifiers
        : modifiers + ItemModifiers(gearProcs: {proc});
  }

  /// The aspect prefix this enchant names the piece with — 'Charred'.
  String get prefix => aspectPrefixes[element.name]!;

  /// 'Charred (Standard)' — how the stat line names the enchant.
  String get label => '$prefix (${tier.label})';
}

/// The affinity table (CELESTIAL §2.5a) as numbers — shared by enchants and
/// gems, so the two can never disagree about which stat an element leans on.
abstract final class Affinity {
  /// The element's affinity stat(s) at [amount] points.
  ///
  /// ⭐ **Sanctus is the one element that gains two** (§2.5a: Aqua's and
  /// Flora's leans at once) — both at [amount], which is how the enchant
  /// table's `+2 / +2` row reads.
  static ItemModifiers of(MagicElement element, int amount) =>
      switch (element) {
        MagicElement.pyro ||
        MagicElement.umbra => ItemModifiers(critDamage: amount),
        MagicElement.electro ||
        MagicElement.astral => ItemModifiers(critChance: amount),
        MagicElement.aero || MagicElement.lunar => ItemModifiers(dodge: amount),
        MagicElement.geo ||
        MagicElement.arcane => ItemModifiers(deflectChance: amount),
        MagicElement.solar => ItemModifiers(accuracyBonus: amount),
        MagicElement.aqua => ItemModifiers(shieldStrengthPercent: amount),
        MagicElement.flora => ItemModifiers(healingReceivedPercent: amount),
        MagicElement.sanctus => ItemModifiers(
          shieldStrengthPercent: amount,
          healingReceivedPercent: amount,
        ),
      };

  /// ENCHANTING_DESIGN §4.1's table, per element and tier.
  ///
  /// 📝 A first draft sized against the shipped rare jewelry; ⚠️ the §8.4
  /// re-sim gate runs before Greater is final ("Greater lands around two
  /// thirds of the draft").
  static int enchantAmount(MagicElement element, EnchantTier tier) {
    final row = switch (element) {
      MagicElement.pyro ||
      MagicElement.umbra ||
      MagicElement.aqua ||
      MagicElement.flora => const [4, 8, 14],
      MagicElement.electro ||
      MagicElement.astral ||
      MagicElement.aero ||
      MagicElement.lunar ||
      MagicElement.sanctus => const [2, 4, 7],
      MagicElement.geo ||
      MagicElement.arcane ||
      MagicElement.solar => const [3, 6, 10],
    };
    return row[tier.index];
  }
}

abstract final class Enchants {
  /// The gear-proc effect each element applies (ENCHANTING_DESIGN §4.1a), as
  /// the player reads it.
  ///
  /// ⚠️ **Solar and Lunar both Blind** — Lunar's lock is Blind (§4.1a), and
  /// the design gives the two the same proc on purpose.
  static String procEffectName(MagicElement element) => switch (element) {
    MagicElement.pyro => 'Ignite',
    MagicElement.aqua => 'Waterlogged',
    MagicElement.flora => 'Photosynthesis',
    MagicElement.electro => 'Static Feedback',
    MagicElement.aero => 'Tailwind',
    MagicElement.geo => 'Stagger',
    MagicElement.solar || MagicElement.lunar => 'Blind',
    MagicElement.astral => 'Astral Alignment',
    MagicElement.sanctus => 'Grace',
    MagicElement.umbra => 'Creeping Dark',
    MagicElement.arcane => 'Arcane Knowledge',
  };

  /// Every enchant, element-enum order then tier order — 36.
  ///
  /// ⭐ **Generated from the two tables above**, never written out: 36 hand-
  /// typed rows is 36 chances for one to name the wrong stat.
  static final List<EnchantDef> all = List.unmodifiable([
    for (final element in MagicElement.values)
      for (final tier in EnchantTier.values)
        EnchantDef(
          id: idFor(element, tier),
          element: element,
          tier: tier,
          modifiers: Affinity.of(
            element,
            Affinity.enchantAmount(element, tier),
          ),
        ),
  ]);

  static final Map<String, EnchantDef> byId = Map.unmodifiable({
    for (final e in all) e.id: e,
  });

  /// `<element>_<tier>`. ⚠️ The id scheme is part of the save format.
  static String idFor(MagicElement element, EnchantTier tier) =>
      '${element.name}_${tier.name}';

  /// The enchant for [element] at [tier].
  static EnchantDef of(MagicElement element, EnchantTier tier) =>
      byId[idFor(element, tier)]!;

  /// Null for null, and for any id this table does not hold — ⚠️ including
  /// the reserved `unbind` (§4.5), which is an enchant with no stats, and a
  /// save written by a newer build. Callers treat null as "grants nothing".
  static EnchantDef? tryById(String? id) => id == null ? null : byId[id];
}
