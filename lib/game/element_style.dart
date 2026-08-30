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

  // ---- The banked generation (TYPE_EFFECTS §7a) ------------------------
  // Stat stances
  'lightfoot': Icons.directions_run,
  'twinkleToes': Icons.directions_walk,
  'glance': Icons.redo,
  'divert': Icons.alt_route,
  'truesight': Icons.visibility,
  'hawkeye': Icons.remove_red_eye,
  'keen': Icons.center_focus_strong,
  'ardent': Icons.flash_on,
  'heavyhand': Icons.fitness_center,
  'overkill': Icons.sports_mma,
  // Special stances & sustain
  'steadfast': Icons.security,
  'composure': Icons.self_improvement,
  'bloodlust': Icons.bloodtype,
  'deathWish': Icons.heart_broken,
  'reflect': Icons.flip,
  'mend': Icons.healing,
  'renewal': Icons.spa,
  // DoTs & debuffs
  'agony': Icons.content_cut,
  'torment': Icons.hourglass_top,
  'fester': Icons.bug_report,
  'scour': Icons.waves,
  'murk': Icons.blur_circular,
  'miasma': Icons.cloud,
  'wither': Icons.trending_down,
  'atrophy': Icons.hourglass_bottom,
  'blight': Icons.dangerous,
  'dispel': Icons.block,
  'shatter': Icons.broken_image,
  // Riders, finisher, cleansers
  'pierce': Icons.double_arrow,
  'unerring': Icons.gps_fixed,
  'execute': Icons.gavel,
  'cleanse': Icons.cleaning_services,
  'purify': Icons.auto_fix_high,
  'meditate': Icons.psychology,
};

/// Multi-line tooltip text for a spell: cost, priority, effect, flavor.
String spellTooltip(Spell spell) {
  final cost = spell.xCost ? 'X (all charge)' : '${spell.chargeCost}';
  final detail = switch (spell.effect) {
    // ⚠️ Subtype arms FIRST — a sealed switch matches in order, and the bank's
    // effects extend shipped ones (DotAttackEffect is a DamageEffect, the
    // aux-offense family are DischargeEffects). Parent-first would read Agony
    // as a plain hit and Fester as a charge wipe.
    DotAttackEffect(
      :final minAmount,
      :final maxAmount,
      :final damagePerTick,
      :final ticks,
      :final dotName,
    ) =>
      '$minAmount-$maxAmount damage, then $dotName bleeds $damagePerTick/turn '
          'for $ticks turns',
    DebuffGrantEffect(:final debuff, :final magnitude, :final turns) =>
      switch (debuff) {
        BankDebuff.murk => '$magnitude enemy accuracy for $turns turns',
        BankDebuff.wither =>
          'Healing they receive $magnitude% for $turns turns',
        BankDebuff.blight =>
          'Their heals deal damage instead, for $turns turns',
      },
    FesterEffect(:final damage, :final bonusTicks) =>
      '$damage damage; every burn on them gains $bonusTicks more ticks',
    ScourEffect() =>
      'Every burn on them pays out all remaining ticks NOW, as one hit',
    DispelEffect() => "Strips the enemy's buffs",
    ShatterEffect() =>
      'No damage. Destroys their shield, Barriers and Divert stance',
    DamageEffect(
      :final minAmount,
      :final maxAmount,
      :final hits,
      :final lifesteal,
      :final executeBelowPercent,
    ) =>
      '${hits > 1 ? '$hits hits of ' : ''}$minAmount-$maxAmount damage'
          // 📝 "health lost", not "health damage": overkill and shielded
          // damage both heal nothing (playtest ruling).
          '${lifesteal > 0 ? ', heals for ${(lifesteal * 100).round()}% of the health lost' : ''}'
          '${executeBelowPercent > 0 ? ', always crits below $executeBelowPercent% health' : ''}',
    BarrageEffect(:final minPerCharge, :final maxPerCharge) =>
      'One hit per charge spent, each $minPerCharge-$maxPerCharge damage',
    ShieldEffect(:final minStrength, :final maxStrength) =>
      '$minStrength-$maxStrength shield in your element',
    BarrierEffect() => 'Adds a Barrier point (max 3). Each blocks one hit',
    EmpowerEffect(:final multiplier) => 'Next offensive spell x$multiplier',
    QuickenEffect(:final priorityOverride) =>
      'Next offensive spell at priority $priorityOverride',
    // The next-attack riders (TYPE_EFFECTS §7a) — one bypass each, so the line
    // has to name WHICH, or Pierce and Unerring both read as Phase.
    PhaseEffect(:final bypass) => switch (bypass) {
      AttackBypass.shields =>
        'Next offensive spell ignores shields and Barriers',
      AttackBypass.deflection => 'Next offensive spell cannot be deflected',
      AttackBypass.evasion => 'Next offensive spell cannot miss',
    },
    HasteEffect() => 'Seizes Haste (wins same-priority ties)',
    DischargeEffect() => "Removes ALL of the enemy's charge",
    OverloadEffect(:final minPerCharge, :final maxPerCharge) =>
      "$minPerCharge-$maxPerCharge damage per point of the enemy's charge",
    HallowEffect() => 'Grants Grace — blocks the next debuff on you',
    // The banked self-instants (§7a). ⚠️ [SpellEffect] is sealed, so these arms
    // are not optional — they are what a new effect type costs.
    CleanseEffect(:final all) => all
        ? 'Removes every debuff on you'
        : 'Removes one debuff of your choice',
    MeditateEffect(:final bonusTurns) =>
      'Every turn-timed buff you hold gains $bonusTurns turns',
    // The banked stances (TYPE_EFFECTS §7a) — stat and special alike, one arm
    // since the two lanes' effects were unified. ⚠️ [SpellEffect] is sealed,
    // so this arm is not optional — it is what a new effect type costs.
    StanceEffect(:final grants, :final cleanses) => _stanceDetail(
      grants,
      cleanses,
    ),
  };
  final haste = spell.grantsHaste && spell.effect is! HasteEffect
      ? '\nAlso seizes Haste'
      : '';
  return '${spell.name}\n'
      'Cost $cost · Priority ${spell.priority} (${priorityLabel(spell.priority)})\n'
      '$detail$haste\n'
      '${spellDescriptions[spell.id] ?? ''}';
}

/// The tooltip line for a banked stance: each granted status's numbers and its
/// clock, read off the statuses the cast would actually land, plus any cleanse
/// rider.
///
/// ⭐ Built from the granted statuses rather than retyped, so a retuned stance
/// cannot leave the tooltip quoting last week's numbers — the drift this file's
/// tests exist to catch.
///
/// ⚠️ Plural because Bloodlust grants two (§7a's licensed exception); every
/// other spell in the bank grants one and reads exactly as it did.
String _stanceDetail(
  List<StanceGrant> grants,
  ({String statusId, String momentId})? cleanses,
) {
  final numbers = grants.map((g) {
    final granted = g.build();
    return granted is StanceDescribing
        ? '${(granted as StanceDescribing).grantLine} for '
              '${(granted as StanceDescribing).turnsLeft} turns'
        : 'Grants ${StatusCatalog.byId(granted.id)?.name ?? granted.id}';
  }).join(', and ');
  final cleanse = cleanses == null
      ? ''
      : ', and clears '
            '${StatusCatalog.byId(cleanses.statusId)?.name ?? cleanses.statusId}';
  return '$numbers$cleanse';
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

  // ---- The banked generation (TYPE_EFFECTS §7a) ------------------------
  'lightfoot': 'Move like a rumor. The cheap way to start dodging.',
  'twinkleToes': 'Commit to the dance — a whole duel of not being there.',
  'glance': 'A sliver of deflection. Sometimes the hit just... slides.',
  'divert': 'The proper deflect stance: more often, and more of it.',
  'truesight': 'See them clearly — and burn any Blind off your eyes.',
  'hawkeye': 'Nothing escapes you for a long, long while.',
  'keen': 'An edge on every strike. Crits come looking for you.',
  'ardent': 'The long burn of focus — a duel-length appetite for crits.',
  'heavyhand': 'When they land, they LAND.',
  'overkill': 'Why win by a little? The heaviest crits, for ages.',
  'steadfast': 'Every wall you raise is a quarter stronger while this holds.',
  'composure': 'Their lucky hits are just... hits. Crits mean nothing to you.',
  'bloodlust': 'The all-in window: crit often AND crit hard, briefly.',
  'deathWish': 'Below 15% health, every blow you land is a crit. Live there.',
  'reflect': 'What you deflect comes back to them — every point of it.',
  'mend': 'A short, steady knitting of wounds.',
  'renewal': 'The long healing — half your health back, given time.',
  'agony': 'A quick bleed: pays out fast, hurts the whole way.',
  'torment': 'The slow knife. Nine turns of it — unless they Cleanse.',
  'fester': 'Feed whatever burns on them. Every wound runs longer.',
  'scour': 'Collect early: every bleed pays out at once, as one blow.',
  'murk': 'A thin haze over their aim.',
  'miasma': 'A rolling fog they cannot see through, for twenty turns.',
  'wither': 'Half of every heal they drink, gone.',
  'atrophy': 'The same rot, three times the patience.',
  'blight': 'Their medicine is poison now. Every heal wounds them instead.',
  'dispel': 'Strip their stances bare. The answer to a stacked mage.',
  'shatter': 'Turtle-breaker: shield, Barriers and Divert, all gone at once.',
  'pierce': 'Your next attack cannot be turned aside.',
  'unerring': 'Your next attack cannot miss. Not against anything.',
  'execute': 'The finisher — guaranteed crit against a wounded mage.',
  'cleanse': 'Wash one affliction away — you pick the one.',
  'purify': 'The full rite: every debuff on you, gone.',
  'meditate': 'Breathe. Every stance you hold deepens by five turns.',
};
