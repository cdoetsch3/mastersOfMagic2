/// The thirty-six elemental gems (ENCHANTING_DESIGN §5.1, ITEMS §6d).
///
/// ⭐ **Elemental only** (ruling 5–9 "as recommended", 2026-10-01): universal
/// gems are §6d.3's anti-meta hazard and wait until sockets feel too narrow.
/// Each gem is element-bound by the mote that cut it — Lesser from a Crystal,
/// Standard from a Core, Greater from a Heart — and grants that element's
/// affinity stat (CELESTIAL §2.5a) at **+2 / +4 / +7**.
///
/// ⭐ **Made, never found** — cut by Jewelry at Rimeholt (lane 2's recipes),
/// so they belong to no zone and live under `ItemCatalogue.byWorkshop['gems']`.
///
/// ⚠️ **The second identical gem on one piece gives half** (§6d.3 fix 2) — but
/// that is a rule about a SOCKET LIST, not about a gem, so it lives in
/// `Equipping.modifiersOf`, not here.
library;

import 'package:mom_engine/mom_engine.dart';

import '../enchants.dart';
import '../item_def.dart';

abstract final class Gems {
  /// The affinity points each gem tier grants (§5.1).
  ///
  /// 📝 Flat across elements, as the design writes it — so a Pyro gem's +2 is
  /// +2 crit DAMAGE where an Electro gem's is +2 crit CHANCE. The enchant
  /// table scales by the stat's unit and this one does not; ⚠️ the §8.4
  /// re-sim is where that gets judged.
  /// ✅ **A gem grants its element's enchant amount for the tier** (the §8.4
  /// retune, 2026-10-01) — not the draft's flat +2/+4/+7, which made six
  /// Greater Aero gems alone worth 5.4 levels. One table, two doors.
  static int affinityOf(MagicElement element, EnchantTier tier) =>
      Affinity.enchantAmount(element, tier);

  /// Vendor values, Lesser / Standard / Greater. ❓ Draft numbers (§5.1),
  /// kept as consts so the ruling is one edit.
  static const int lesserValue = 300;
  static const int standardValue = 1500;

  /// ⚠️ **A Greater gem is cut from a Heart, and a Heart is Bound at 0g**
  /// (ECONOMY_CONTRACT §14c, ruled 2026-08-25). A vendorable Greater gem
  /// would be the Heart's missing vendor path by another door, so the gem
  /// is Bound and worth nothing at the till too (manager, 2026-10-01).
  static const int greaterValue = 0;
  static const Tradability greaterTradability = Tradability.bound;

  static const List<Tradability> _tradabilityByTier = [
    Tradability.tradeable,
    Tradability.tradeable,
    greaterTradability,
  ];

  static const List<int> _valueByTier = [
    lesserValue,
    standardValue,
    greaterValue,
  ];

  static const List<Rarity> _rarityByTier = [
    Rarity.uncommon,
    Rarity.rare,
    Rarity.epic,
  ];

  /// What each element's gem looks like in the hand — one clause, framed per
  /// tier by [_lore].
  static const Map<MagicElement, String> _feel = {
    MagicElement.aqua: 'There is a tide in it, turning',
    MagicElement.pyro: 'It is warm on the side that faces you',
    MagicElement.flora: 'Something in it is growing toward the light',
    MagicElement.electro: 'It hums against a fingernail',
    MagicElement.aero: 'It is lighter than the stone it was cut from',
    MagicElement.geo: 'It sits in a setting as if it was always there',
    MagicElement.solar: 'It throws a small noon onto whatever is near it',
    MagicElement.lunar: 'It shows a different phase from every side',
    MagicElement.astral: 'There is a pattern in it you almost recognise',
    MagicElement.sanctus: 'It is calm, and so is the hand that holds it',
    MagicElement.umbra: 'It is darker than it should be in any light',
    MagicElement.arcane: 'It has the look of a thing that is reading you back',
  };

  static String _lore(MagicElement element, EnchantTier tier) {
    final feel = _feel[element]!;
    return switch (tier) {
      EnchantTier.lesser => '$feel, if you look for it.',
      EnchantTier.standard => '$feel.',
      EnchantTier.greater => '$feel, and the room knows it.',
    };
  }

  /// `gem_<element>_<tier>`. ⚠️ Forever once a save holds one — it is a def
  /// id like any other, and it is also what [ItemInstance.socketed] stores.
  static String idFor(MagicElement element, EnchantTier tier) =>
      'gem_${element.name}_${tier.name}';

  /// The gem for [element] at [tier].
  static GemDef of(MagicElement element, EnchantTier tier) =>
      all.firstWhere((g) => g.id == idFor(element, tier));

  /// ⭐ The three gem tiers ARE the three enchant tiers — Lesser, Standard,
  /// Greater — so [EnchantTier] names both rather than a second enum that
  /// could drift from it. Element-enum order, then tier order.
  static final List<GemDef> all = List.unmodifiable([
    for (final element in MagicElement.values)
      for (final tier in EnchantTier.values)
        GemDef(
          id: idFor(element, tier),
          properName: '${tier.label} ${element.displayName} Gem',
          rarity: _rarityByTier[tier.index],
          lore: _lore(element, tier),
          element: element,
          modifiers: Affinity.of(element, affinityOf(element, tier)),
          value: _valueByTier[tier.index],
          tradability: _tradabilityByTier[tier.index],
        ),
  ]);
}
