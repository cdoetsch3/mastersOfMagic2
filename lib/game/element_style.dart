import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../ui/element_glyphs.dart';

/// Visual identity of each element: color + glyph + display name.
class ElementStyle {
  final Color color;

  /// The Material icon, used for every element Material can actually express.
  final IconData icon;

  /// A hand-drawn glyph, for the elements Material cannot: Sanctus's halo and
  /// Umbra's demon. Takes precedence over [icon] when present.
  final CustomPainter Function(Color)? glyph;

  final String label;

  const ElementStyle(this.color, this.icon, this.label, {this.glyph});
}

const Map<MagicElement, ElementStyle> elementStyles = {
  // Tier 1 — Primal
  MagicElement.aqua: ElementStyle(Color(0xFF3D8BD9), Icons.water_drop, 'Aqua'),
  MagicElement.pyro: ElementStyle(
    Color(0xFFE25822),
    Icons.local_fire_department,
    'Pyro',
  ),
  MagicElement.flora: ElementStyle(Color(0xFF5FB35B), Icons.eco, 'Flora'),
  // Tier 2 — Kinetic
  MagicElement.electro: ElementStyle(Color(0xFFE8C547), Icons.bolt, 'Electro'),
  MagicElement.aero: ElementStyle(Color(0xFF9BB8C4), Icons.air, 'Aero'),
  MagicElement.geo: ElementStyle(Color(0xFF9C7A4B), Icons.landscape, 'Geo'),
  // Tier 3 — Celestial
  MagicElement.solar: ElementStyle(Color(0xFFF5B23E), Icons.wb_sunny, 'Solar'),
  MagicElement.lunar: ElementStyle(
    Color(0xFFAFC3E8),
    Icons.nightlight_round,
    'Lunar',
  ),
  MagicElement.astral: ElementStyle(
    Color(0xFF6E7BD6),
    Icons.star_outline,
    'Astral',
  ),
  // Tier 4 — Ethereal
  // Sanctus and Umbra deliberately avoid sun/moon glyphs — those belong to
  // Solar and Lunar, and the old light_mode/dark_mode pair read as a second
  // sun and a second moon. Sanctus takes a haloed seal, Umbra the blinded eye
  // (its Creeping Dark is literally what hides the board from you).
  // Material has no halo and no demon, so these two are drawn (see
  // ui/element_glyphs.dart). The icons named here are fallbacks only.
  MagicElement.sanctus: ElementStyle(
    Color(0xFFF2E7C9),
    Icons.workspace_premium,
    'Sanctus',
    glyph: HaloGlyphPainter.new,
  ),
  MagicElement.umbra: ElementStyle(
    Color(0xFF8B5CD6),
    Icons.dark_mode,
    'Umbra',
    glyph: DemonGlyphPainter.new,
  ),
  MagicElement.arcane: ElementStyle(
    Color(0xFFD65AB8),
    Icons.auto_awesome,
    'Arcane',
  ),
};

/// Display label for a tier (Spellbook grouping, tooltips).
const Map<MagicTier, String> tierLabels = {
  MagicTier.primal: 'Primal',
  MagicTier.kinetic: 'Kinetic',
  MagicTier.celestial: 'Celestial',
  MagicTier.ethereal: 'Ethereal',
};

extension ElementStyleX on MagicElement {
  ElementStyle get style => elementStyles[this]!;
}

/// The element's mark at [size] — its drawn glyph where it has one, otherwise
/// its Material icon. Use this rather than `Icon(element.style.icon)` so the
/// hand-drawn elements render everywhere they appear.
Widget elementGlyph(
  MagicElement element, {
  required double size,
  Color? color,
}) {
  final style = element.style;
  final tint = color ?? style.color;
  final glyph = style.glyph;
  return glyph == null
      ? Icon(style.icon, size: size, color: tint)
      : PaintedGlyph(painter: glyph, size: size, color: tint);
}

String priorityLabel(int priority) => switch (priority) {
  <= 2 => 'instant',
  3 => 'shield',
  4 => 'channel',
  <= 6 => 'quick',
  <= 8 => 'aux',
  _ => 'regular',
};

const Map<String, IconData> spellIcons = {
  'flick': Icons.auto_awesome,
  'bolt': Icons.whatshot,
  'blast': Icons.whatshot,
  'surge': Icons.whatshot,
  'ruin': Icons.whatshot,
  'cataclysm': Icons.flare,
  'jolt': Icons.speed,
  'flurry': Icons.scatter_plot,
  'volley': Icons.scatter_plot,
  'barrage': Icons.grain,
  'sap': Icons.favorite,
  'leech': Icons.favorite,
  'drain': Icons.favorite,
  'ward': Icons.shield_outlined,
  'aegis': Icons.shield_outlined,
  'bulwark': Icons.shield,
  'rampart': Icons.shield,
  'sanctuary': Icons.shield,
  'barrier': Icons.shield_moon,
  'empower': Icons.upgrade,
  'quicken': Icons.fast_forward,
  'phase': Icons.blur_on,
  'hasty': Icons.bolt,
  'discharge': Icons.power_off,
  'overload': Icons.electric_bolt,
  'hallow': Icons.verified_user,
};

/// Multi-line tooltip text for a spell: cost, priority, effect, flavor.
String spellTooltip(Spell spell) {
  final cost = spell.xCost ? 'X (all charge)' : '${spell.chargeCost}';
  final detail = switch (spell.effect) {
    DamageEffect(
      :final minAmount,
      :final maxAmount,
      :final hits,
      :final lifesteal,
    ) =>
      '${hits > 1 ? '$hits hits of ' : ''}$minAmount-$maxAmount damage'
          // 📝 "health lost", not "health damage": overkill and shielded
          // damage both heal nothing (playtest ruling).
          '${lifesteal > 0 ? ', heals for ${(lifesteal * 100).round()}% of the health lost' : ''}',
    BarrageEffect(:final minPerCharge, :final maxPerCharge) =>
      'One hit per charge spent, each $minPerCharge-$maxPerCharge damage',
    ShieldEffect(:final minStrength, :final maxStrength) =>
      '$minStrength-$maxStrength shield in your element',
    BarrierEffect() => 'Adds a Barrier point (max 3). Each blocks one hit',
    EmpowerEffect(:final multiplier) => 'Next offensive spell x$multiplier',
    QuickenEffect(:final priorityOverride) =>
      'Next offensive spell at priority $priorityOverride',
    PhaseEffect() => 'Next offensive spell ignores shields and Barriers',
    HasteEffect() => 'Seizes Haste (wins same-priority ties)',
    DischargeEffect() => "Removes ALL of the enemy's charge",
    OverloadEffect(:final minPerCharge, :final maxPerCharge) =>
      "$minPerCharge-$maxPerCharge damage per point of the enemy's charge",
    HallowEffect() => 'Grants Grace — blocks the next debuff on you',
  };
  final haste = spell.grantsHaste && spell.effect is! HasteEffect
      ? '\nAlso seizes Haste'
      : '';
  return '${spell.name}\n'
      'Cost $cost · Priority ${spell.priority} (${priorityLabel(spell.priority)})\n'
      '$detail$haste\n'
      '${spellDescriptions[spell.id] ?? ''}';
}

/// One-line flavor/description per spell id, for tooltips.
const Map<String, String> spellDescriptions = {
  'flick': 'A free spark of raw magic. Never leaves you empty-handed.',
  'bolt': 'The dependable workhorse of dueling.',
  'blast': 'A solid mid-weight strike.',
  'surge': 'A heavy wave of force.',
  'ruin': 'Devastation for the patient.',
  'cataclysm': 'Five charges of pure annihilation.',
  'jolt': 'Strikes early and seizes Haste, winning future same-speed ties.',
  'flurry': 'Three rapid strikes; each rolls its own damage.',
  'volley': 'Four bolts in succession — steady chip through a shield.',
  'barrage':
      'Spends ALL your charge as separate bolts — one per point. '
      'Each meets the shield on its own, so it chews through Barriers.',
  'sap': 'Heals you for half the health they lose.',
  'leech': 'A stronger draught — still half the health they lose.',
  'drain': 'The heaviest steal; heals half the health it takes off them.',
  'ward': 'A light shield in your element.',
  'aegis': 'A sturdy shield in your element.',
  'bulwark': 'A heavy shield in your element.',
  'rampart': 'A towering shield in your element.',
  'sanctuary': 'The greatest shield a mage can weave.',
  'barrier':
      'Stacks up to 3 points; each blocks one hit whole. '
      'Element-less — a multi-hit spell burns one point per hit.',
  'empower': 'Your next offensive spell deals double damage.',
  'quicken': 'Your next offensive spell strikes before enemy shields.',
  'phase': 'Your next offensive spell ignores shields AND Barriers.',
  'hasty': 'Free initiative — seize Haste to win same-speed ties.',
  'discharge': "Strip the enemy's stored charge. Fizzles a same-turn Barrage.",
  'overload': "Detonate the enemy's own charge — brutal against a full mage.",
  'hallow': 'Ward yourself: the next debuff that lands on you is blocked.',
};
