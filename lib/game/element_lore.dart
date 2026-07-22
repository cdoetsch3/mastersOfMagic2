import 'package:mom_engine/mom_engine.dart';

/// Player-facing lore for an element's side-effect and its two counter layers
/// (shield ×2 + effect interaction). Text matches TYPE_EFFECTS_DESIGN.md.
class ElementLore {
  /// The named effect (e.g. "Ignite").
  final String effectName;

  /// One-line trigger summary (e.g. "25% on hit").
  final String trigger;

  /// The full effect rules, one bullet each.
  final String description;

  /// Effect-layer line for the element this one beats (paired with the ×2
  /// shield advantage).
  final String beatsEffect;

  /// Effect-layer line for the element this one is weak to.
  final String weakEffect;

  const ElementLore({
    required this.effectName,
    required this.trigger,
    required this.description,
    required this.beatsEffect,
    required this.weakEffect,
  });
}

const Map<MagicElement, ElementLore> elementLore = {
  // ---- Tier 1 — Primal ------------------------------------------------
  MagicElement.pyro: ElementLore(
    effectName: 'Ignite',
    trigger: '25% on hit · even through a shield',
    description: 'Burns 10% of the attack\'s total damage at end of turn for '
        '3 turns (this one included). Burn is regular damage — it hits the '
        'shield first. Re-igniting refreshes; it never stacks.',
    beatsEffect: 'Ignite clears their Photosynthesis stacks',
    weakEffect: 'Their Aqua shield douses your Ignite',
  ),
  MagicElement.aqua: ElementLore(
    effectName: 'Waterlogged',
    trigger: 'every 3rd consecutive Aqua cast',
    description: 'The opponent\'s next action (including a charge) is dragged '
        '+10 priority — it resolves dead last. Does not stack; refreshes. '
        'Casting any Aqua shield also douses Ignite on you.',
    beatsEffect: 'Your shield douses their Ignite',
    weakEffect: 'Their Photosynthesis blocks your Waterlogged',
  ),
  MagicElement.flora: ElementLore(
    effectName: 'Photosynthesis',
    trigger: 'every Flora cast (max 3 stacks)',
    description: 'Heals 1% of max HP per stack at end of turn — before any '
        'burn lands. Sheds a stack each turn you don\'t cast or charge Flora. '
        'While you hold a stack you can\'t be Waterlogged.',
    beatsEffect: 'A stack blocks their Waterlogged',
    weakEffect: 'Their Ignite clears all your stacks',
  ),

  // ---- Tier 2 — Kinetic -----------------------------------------------
  MagicElement.electro: ElementLore(
    effectName: 'Static Feedback',
    trigger: '20% on hit',
    description: 'Strips one charge from the target. If they locked in a spell '
        'they can no longer afford, it fizzles — they keep the rest of their '
        'charge but waste the turn. Every Electro attack also scatters their '
        'Tailwind streak (their held Haste survives).',
    beatsEffect: 'Your attacks scatter their Tailwind streak',
    weakEffect: 'Their Geo shield grounds your Static Feedback',
  ),
  MagicElement.aero: ElementLore(
    effectName: 'Tailwind',
    trigger: '3rd consecutive Aero cast onward',
    description: 'Seizes the Haste token — while the streak lives you re-grab '
        'it every cast, winning every same-speed tie. At a streak of 3+ you '
        'also shrug off Stagger.',
    beatsEffect: 'A 3+ streak shrugs off their Stagger',
    weakEffect: 'Their Electro attacks scatter your Tailwind',
  ),
  MagicElement.geo: ElementLore(
    effectName: 'Stagger',
    trigger: 'every 4th consecutive Geo cast',
    description: 'The opponent\'s next offensive spell deals 50% damage — it '
        'lingers until they cast one. Whiffs against a Tailwind streak of 3+. '
        'A standing Geo shield also grounds enemy Static Feedback.',
    beatsEffect: 'Your shield grounds their Static Feedback',
    weakEffect: 'Their Tailwind 3+ shrugs off your Stagger',
  ),

  // ---- Tier 3 — Celestial ----------------------------------------------
  // Effects arrive in Phase 3 (TYPE_EFFECTS_DESIGN §4b). Until then these
  // read honestly as "not yet active" rather than describing behaviour the
  // engine doesn't have — a player must never be told about a mechanic that
  // won't fire.
  MagicElement.solar: ElementLore(
    effectName: 'Blind',
    trigger: 'not yet active',
    description: 'The Celestial tier is still being woven. Solar will inherit '
        'Blind: a chance per charge spent to leave the opponent missing their '
        'attacks. Not yet implemented.',
    beatsEffect: 'Solar eclipses Lunar',
    weakEffect: 'Astral slips through Solar',
  ),
  MagicElement.lunar: ElementLore(
    effectName: 'Phases of the Moon',
    trigger: 'not yet active',
    description: 'The Celestial tier is still being woven. Lunar will follow a '
        'public four-turn moon cycle — new, waxing, full, waning — that '
        'strengthens and weakens its spells in turn. Not yet implemented.',
    beatsEffect: 'Lunar anchors Astral',
    weakEffect: 'Solar eclipses Lunar',
  ),
  MagicElement.astral: ElementLore(
    effectName: 'Astral Alignment',
    trigger: 'not yet active',
    description: 'The Celestial tier is still being woven. Astral will stack '
        'Alignment, sending part of every attack straight through shields to '
        'health. Not yet implemented.',
    beatsEffect: 'Astral slips through Solar',
    weakEffect: 'Lunar anchors Astral',
  ),

  // ---- Tier 4 — Ethereal ----------------------------------------------
  MagicElement.sanctus: ElementLore(
    effectName: 'Blind',
    trigger: '10% per charge spent, on attack',
    description: 'For the opponent\'s next 3 turns, each offensive spell has a '
        '50% chance to miss — no effect, but the charge is spent. A proc also '
        'burns away all their Creeping Dark. Arcane spells never miss.',
    beatsEffect: 'Blind burns away their Creeping Dark',
    weakEffect: 'Their Arcane spells are immune to Blind',
  ),
  MagicElement.umbra: ElementLore(
    effectName: 'Creeping Dark',
    trigger: '+1 stack per charge spent (max 15)',
    description: 'Sheds a stack each turn without Umbra activity. Thresholds '
        'blind the enemy: 5 Shadow (hides your element), 10 Dusk (hides your '
        'charge & health), 15 Midnight (hides their own). Dusk+ also stops '
        'them gaining Arcane Knowledge.',
    beatsEffect: 'Dusk blocks their Arcane Knowledge',
    weakEffect: 'Their Blind burns away your Creeping Dark',
  ),
  MagicElement.arcane: ElementLore(
    effectName: 'Arcane Knowledge',
    trigger: '4+ charge Arcane cast (max 5 stacks)',
    description: '+5% damage per stack on every spell, permanent for the duel '
        '— never decays or is consumed. Blocked while the opponent\'s darkness '
        'has you at Dusk or worse. Arcane spells can never miss.',
    beatsEffect: 'Your spells are immune to their Blind',
    weakEffect: 'Their Dusk blocks your Arcane Knowledge',
  ),
};
