import 'element.dart';

/// Whether a status helps its holder, hurts them, or is a moment rather than a
/// lasting condition.
enum StatusKind {
  /// Good for whoever holds it.
  buff,

  /// Bad for whoever holds it.
  debuff,

  /// A thing that *happened* — a cleanse, a strip, a block — rather than a
  /// condition you carry. These flash in the log but never sit as a pip.
  moment,
}

/// One entry in the catalogue of everything that can be applied to a mage.
class StatusInfo {
  /// Matches [BuffAppliedEvent.statusId] and the ids in `StatusSnapshot`.
  final String id;

  /// Player-facing name.
  final String name;

  /// What it does, in the player's terms.
  final String description;

  /// How you come to have it.
  final String trigger;

  final StatusKind kind;

  /// The element responsible, or null when any element can cause it (the aux
  /// spells: Empower, Quicken, Phase, Hallow, Hasty).
  final MagicElement? element;

  /// True when it persists across turns and shows as a HUD pip; false for
  /// one-shot moments.
  final bool lingers;

  const StatusInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.kind,
    required this.element,
    required this.lingers,
  });
}

/// The single source of truth for every status in the game.
///
/// The duel HUD, the battle log, the animation table and (eventually) the
/// player guide all read from here, so a new status is described once and shows
/// up everywhere. `status_catalog_test` asserts that every id the engine
/// actually emits has an entry, which is what stops this drifting.
abstract final class StatusCatalog {
  static const List<StatusInfo> all = [
    // ---- Lasting conditions (these show as HUD pips) --------------------
    StatusInfo(
      id: 'ignite',
      name: 'Ignite',
      description:
          'Burns for a share of the hit that lit it, at the end of each of '
          'your next three turns. Re-igniting refreshes it rather than '
          'stacking. An Aqua shield douses it.',
      trigger: 'A Pyro attack that lands — even one a shield soaks.',
      kind: StatusKind.debuff,
      element: MagicElement.pyro,
      lingers: true,
    ),
    StatusInfo(
      id: 'blind',
      name: 'Blind',
      description:
          'Your offensive spells have a 50% chance to miss for three turns. A '
          'miss still spends the charge. Astral spells are exempt, and a '
          'Lunar mage is also eclipsed — locked out of the Full Moon bonus.',
      trigger: 'A Solar attack — 10% per point of charge spent on it.',
      kind: StatusKind.debuff,
      element: MagicElement.solar,
      lingers: true,
    ),
    StatusInfo(
      id: 'waterlogged',
      name: 'Waterlogged',
      description:
          'Your next action resolves dead last, whatever its normal priority.',
      trigger: 'Every 3rd consecutive Aqua cast. Photosynthesis prevents it.',
      kind: StatusKind.debuff,
      element: MagicElement.aqua,
      lingers: true,
    ),
    StatusInfo(
      id: 'stagger',
      name: 'Stagger',
      description: 'Your next offensive spell deals half damage.',
      trigger:
          'Every 4th consecutive Geo cast. Whiffs against a Tailwind streak.',
      kind: StatusKind.debuff,
      element: MagicElement.geo,
      lingers: true,
    ),
    StatusInfo(
      id: 'photosynthesis',
      name: 'Photosynthesis',
      description:
          'From your 5th Flora cast in a row, heals 1% of your maximum health '
          'at the end of every turn and makes you immune to Waterlogged. Cast '
          'anything else and the bloom ends; Ignite breaks it outright.',
      trigger: 'Any Flora cast.',
      kind: StatusKind.buff,
      element: MagicElement.flora,
      lingers: true,
    ),
    StatusInfo(
      id: 'creepingDark',
      name: 'Creeping Dark',
      description:
          'Hides the board from your opponent as it deepens: 5 stacks hides '
          'the element you are charging, 10 hides your charge and health, 15 '
          'hides their own. Caps at 15 and sheds one per turn without Umbra.',
      trigger: 'Any Umbra cast — one stack per point of charge spent.',
      kind: StatusKind.buff,
      element: MagicElement.umbra,
      lingers: true,
    ),
    StatusInfo(
      id: 'arcaneKnowledge',
      name: 'Arcane Knowledge',
      description:
          '+5% damage on every spell you cast, per stack, up to 5. Permanent '
          'for the duel — it never decays and is never consumed.',
      trigger:
          'An Arcane cast costing 4 or more. Blocked while the enemy\'s '
          'darkness has you at Dusk.',
      kind: StatusKind.buff,
      element: MagicElement.arcane,
      lingers: true,
    ),
    StatusInfo(
      id: 'astralAlignment',
      name: 'Astral Alignment',
      description:
          'Sends 1% of every attack per stack straight past shields to health '
          '— up to 20% at 20 stacks, ignoring counter maths and piercing '
          'Barriers. Sheds a stack on any turn you do not cast Astral.',
      trigger: 'Any Astral cast — one stack per point of charge spent.',
      kind: StatusKind.buff,
      element: MagicElement.astral,
      lingers: true,
    ),
    StatusInfo(
      id: 'grace',
      name: 'Grace',
      description:
          'Blocks the next debuff applied to you outright, then is spent. Only '
          'one at a time, and it never expires on its own.',
      trigger: 'Casting Hallow, or an Absolution that finds nothing to purge.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'haste',
      name: 'Haste',
      description:
          'You hold the initiative: when both mages act at the same priority, '
          'your spell resolves first — so a lethal hit can land before the '
          'reply.',
      trigger: 'Casting Hasty or Jolt, or riding an Aero Tailwind streak.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'empower',
      name: 'Empower',
      description:
          'Your next offensive spell deals double damage. Waits as long as it '
          'needs to — shields and aux spells do not consume it.',
      trigger: 'Casting Empower.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'quicken',
      name: 'Quicken',
      description:
          'Your next offensive spell resolves ahead of enemy shields.',
      trigger: 'Casting Quicken.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'phase',
      name: 'Phase',
      description:
          'Your next offensive spell passes straight through shields and '
          'Barriers to health.',
      trigger: 'Casting Phase.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),

    // ---- Moments: things that happen, rather than conditions ------------
    StatusInfo(
      id: 'absolutionRising',
      name: 'Absolution rising',
      description:
          'Your third consecutive Sanctus cast has called an Absolution — it '
          'resolves at the end of this turn.',
      trigger: 'Every 3rd consecutive Sanctus cast.',
      kind: StatusKind.moment,
      element: MagicElement.sanctus,
      lingers: false,
    ),
    StatusInfo(
      id: 'absolution',
      name: 'Absolution',
      description:
          'Strips one debuff from you at random, before end-of-turn burns can '
          'tick.',
      trigger: 'An Absolution resolving with a debuff to remove.',
      kind: StatusKind.moment,
      element: MagicElement.sanctus,
      lingers: false,
    ),
    StatusInfo(
      id: 'graceConsumed',
      name: 'Grace absorbs',
      description: 'Your Grace swallowed an incoming debuff and was spent.',
      trigger: 'Any debuff landing on you while you hold Grace.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'graceAlready',
      name: 'Already warded',
      description:
          'You already held Grace, so the cast added nothing — Grace does not '
          'stack.',
      trigger: 'Casting Hallow while you already hold Grace.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'igniteDoused',
      name: 'Ignite doused',
      description: 'The water puts your burn out.',
      trigger: 'Raising an Aqua shield while Ignited.',
      kind: StatusKind.moment,
      element: MagicElement.aqua,
      lingers: false,
    ),
    StatusInfo(
      id: 'tailwindScattered',
      name: 'Tailwind scattered',
      description:
          'The lightning breaks the wind: your Aero streak resets to nothing. '
          'Haste you already hold is untouched.',
      trigger: 'Any Electro attack landing on an Aero streak.',
      kind: StatusKind.moment,
      element: MagicElement.electro,
      lingers: false,
    ),
    StatusInfo(
      id: 'alignmentStripped',
      name: 'Alignment stripped',
      description:
          'The moon pulls your Astral Alignment apart — one stack normally, '
          'all of them under a Full Moon.',
      trigger: 'A Lunar attack landing on a mage holding Alignment.',
      kind: StatusKind.moment,
      element: MagicElement.lunar,
      lingers: false,
    ),
    StatusInfo(
      id: 'darkSeared',
      name: 'Dark seared',
      description:
          'Consecration burns five stacks off the enemy\'s Creeping Dark — one '
          'whole threshold of darkness.',
      trigger: 'Any Absolution resolving.',
      kind: StatusKind.moment,
      element: MagicElement.sanctus,
      lingers: false,
    ),
    StatusInfo(
      id: 'sanctusUnravelled',
      name: 'Rite unravelled',
      description:
          'The Arcane hit undoes the ritual: your consecutive Sanctus count '
          'resets, pushing Absolution three casts away again.',
      trigger: 'An Arcane attack that reaches health, on a Sanctus streak.',
      kind: StatusKind.moment,
      element: MagicElement.arcane,
      lingers: false,
    ),
  ];

  static final Map<String, StatusInfo> _byId = {
    for (final s in all) s.id: s,
  };

  static StatusInfo? byId(String id) => _byId[id];

  /// Lasting conditions only — the ones that show as HUD pips.
  static Iterable<StatusInfo> get lasting => all.where((s) => s.lingers);

  /// One-shot moments — cleanses, strips, blocks.
  static Iterable<StatusInfo> get moments => all.where((s) => !s.lingers);
}
