import 'element.dart';
import 'status.dart';

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

  /// Explicit polarity, when the [kind] derivation below is wrong for this
  /// entry. Almost always null — see [polarity].
  final StatusPolarity? polarityOverride;

  /// Good for the holder, bad for them, or neither (TYPE_EFFECTS §7a law 3).
  ///
  /// ⭐ **This is where the field-backed statuses get classified.** Waterlogged,
  /// Stagger, Grace, Haste, Empower, Quicken and Phase are plain fields on
  /// [MageState], not [TurnStatus] objects, so the catalogue is the *only*
  /// place they can carry a polarity — and Dispel, Cleanse and Purify all need
  /// to know that Empower is strippable and Stagger is cleansable.
  ///
  /// Derived from [kind] rather than duplicated, because the two agree by
  /// construction for every shipped entry and a hand-copied second field would
  /// only ever drift. Moments map to [StatusPolarity.neutral]: a moment is a
  /// flash in the log, not a condition — there is nothing there to strip.
  /// [polarityOverride] exists for the case [StatusKind] cannot express, a
  /// *lasting* status that is neither good nor bad.
  StatusPolarity get polarity =>
      polarityOverride ??
      switch (kind) {
        StatusKind.buff => StatusPolarity.buff,
        StatusKind.debuff => StatusPolarity.debuff,
        StatusKind.moment => StatusPolarity.neutral,
      };

  const StatusInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.kind,
    required this.element,
    required this.lingers,
    this.polarityOverride,
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
          'anything else and it ends; Ignite breaks it outright.',
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

    // ---- Banked NEXT-ATTACK RIDERS (TYPE_EFFECTS §7a) -------------------
    // ⭐ Phase's two siblings, described in the same voice: one bypass each,
    // and each waits for an ATTACK rather than a clock — which is also why
    // Meditate cannot deepen them and Dispel's polarity sweep cannot find them.
    StatusInfo(
      id: 'pierce',
      name: 'Pierce',
      description:
          'Your next offensive spell cannot be deflected — the enemy\'s Divert '
          'does not even roll against it. Waits as long as it needs to: '
          'shields and aux spells do not consume it.',
      trigger: 'Casting Pierce.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'unerring',
      name: 'Unerring',
      description:
          'Your next offensive spell cannot miss. Dodge, blindness and the '
          'base miss chance all stop applying — it does not roll to hit at '
          'all, which is the one thing in the game that beats a dodge stance '
          'outright.',
      trigger: 'Casting Unerring.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),

    // ---- Banked STAT STANCES (TYPE_EFFECTS §7a) -------------------------
    // ⭐ One entry per SET, never per spell: Lightfoot and Twinkle Toes are two
    // prices for the status below, so the guide describes the stance once and
    // the numbers belong to whichever cast is running. Each description says
    // that casting the other price point replaces it, because "last cast wins"
    // is the rule players most need told (§7a law 5).
    StatusInfo(
      id: 'lightfoot',
      name: 'Lightfoot',
      description:
          'Attacks against you are less likely to land. How much dodge, and '
          'for how long, is set by the spell that granted it — casting either '
          'Lightfoot spell replaces the other outright. No attack can ever be '
          'driven below a 10% chance to hit you.',
      trigger: 'Casting Lightfoot or Twinkle Toes.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'divert',
      name: 'Divert',
      description:
          'Incoming hits sometimes glance off you. It carries two numbers: how '
          'often a deflection fires, and how much of the hit it removes — each '
          'capped at 90%, so there is always a sliver that lands. Casting '
          'either Divert spell replaces the other outright.',
      trigger: 'Casting Glance or Divert.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'truesight',
      name: 'Truesight',
      description:
          'Your spells are more accurate for as long as it lasts, and the cast '
          'that grants it clears a Blind on the spot. It does not stop the '
          'next one: a fresh Blind lands on you as normal. Casting either '
          'Truesight spell replaces the other outright.',
      trigger: 'Casting Truesight or Hawkeye.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'keen',
      name: 'Keen',
      description:
          'Your attacks crit more often. Worth nothing against an opponent '
          "holding Composure, which resolves your crits as ordinary hits. "
          'Casting either Keen spell replaces the other outright.',
      trigger: 'Casting Keen or Ardent.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'heavyhand',
      name: 'Heavyhand',
      description:
          'Your crits hit harder, on top of the 50% extra a crit already '
          'deals. It does nothing at all until something is critting, so it '
          'wants crit chance beside it. Casting either Heavyhand spell '
          'replaces the other outright.',
      trigger: 'Casting Heavyhand or Overkill.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),

    // ---- The bank: DoTs & debuffs (TYPE_EFFECTS §7a) --------------------
    StatusInfo(
      id: 'agony',
      name: 'Agony',
      description:
          'Bleeds for 7 at the end of each of your next three turns, starting '
          'with the one it lands on. Casting it again refreshes the bleed '
          'rather than stacking it.',
      trigger: 'Being hit by Agony — even a hit a shield soaks.',
      kind: StatusKind.debuff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'torment',
      name: 'Torment',
      description:
          'Bleeds for 5 at the end of each of your next nine turns. The long '
          'burn: more damage in total than the quick one, and far longer for '
          'the duel to end first.',
      trigger: 'Being hit by Torment — even a hit a shield soaks.',
      kind: StatusKind.debuff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'murk',
      name: 'Murk',
      description:
          'Your own accuracy is cut while it lasts — 15 points from Murk, 25 '
          'from Miasma. It stacks with Blind: they come from different '
          'sources, so both apply.',
      trigger: 'The enemy casting Murk or Miasma.',
      kind: StatusKind.debuff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'wither',
      name: 'Wither',
      description:
          'All healing you receive is halved — potions, heals over time, '
          'Photosynthesis and lifesteal alike. Always −50%: Atrophy buys three '
          'times the duration, never a deeper cut.',
      trigger: 'The enemy casting Wither or Atrophy.',
      kind: StatusKind.debuff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'blight',
      name: 'Blight',
      description:
          'Your healing DAMAGES you instead — every potion, tick and lifesteal '
          'heal-back. It overrides Wither entirely: the full heal is inverted, '
          'not the halved one.',
      trigger: 'The enemy casting Blight.',
      kind: StatusKind.debuff,
      element: null,
      lingers: true,
    ),

    // ---- Banked SPECIAL STANCES & SUSTAIN (TYPE_EFFECTS §7a) ------------
    // The half of the bank that changes a rule rather than a number. ⚠️ Keen
    // and Heavyhand are NOT here: Bloodlust grants the stat lane's statuses at
    // its own price point, so they are catalogued once, above.
    StatusInfo(
      id: 'steadfast',
      name: 'Steadfast',
      description:
          'Shields you raise are 25% stronger for 25 turns. The bonus is baked '
          'in when the shield goes up, so a wall already standing keeps its '
          'full strength after this runs out.',
      trigger: 'Casting Steadfast.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'composure',
      name: 'Composure',
      description:
          'Critical hits against you land as ordinary hits for 25 turns — no '
          'bonus damage, however the attacker earned the crit.',
      trigger: 'Casting Composure.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'deathWish',
      name: 'Death Wish',
      description:
          'For 10 turns, every attack you land is a critical hit while your '
          'own health is below 15% of maximum. Their Composure still blanks '
          'them.',
      trigger: 'Casting Death Wish.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'reflect',
      name: 'Reflect',
      description:
          'For 25 turns, damage you deflect is dealt straight back to whoever '
          'sent it — their shields first. Worth nothing without a deflect '
          'chance underneath it, and the return can never bounce again.',
      trigger: 'Casting Reflect.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),
    StatusInfo(
      id: 'mending',
      name: 'Mending',
      description:
          'Heals a share of your maximum health at the end of every turn: 3% '
          'for 6 turns from Mend, 5% for 10 from Renewal. Only one at a time — '
          'the newer cast replaces the older entirely.',
      trigger: 'Casting Mend or Renewal.',
      kind: StatusKind.buff,
      element: null,
      lingers: true,
    ),

    // ---- Moments: things that happen, rather than conditions ------------
    // The bank's self-instants (§7a INSTANTS) report as moments: they change
    // the board and leave nothing behind to carry.
    StatusInfo(
      id: 'cleansed',
      name: 'Cleansed',
      description:
          'One debuff of your choosing has been lifted off you — a burn, a '
          'blindness, whatever you named. Only one: Cleanse is for the big '
          'commitments, not the chip.',
      trigger: 'Casting Cleanse with at least one debuff on you.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'cleanseEmpty',
      name: 'Nothing to cleanse',
      description:
          'The rite found no debuff to lift. The cast still resolved and the '
          'charge is still spent — you simply had nothing wrong with you.',
      trigger: 'Casting Cleanse or Purify while entirely clean.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'purified',
      name: 'Purified',
      description:
          'Every debuff on you is gone at once. Your buffs and stances are '
          'untouched — this undoes what was done TO you, not everything.',
      trigger: 'Casting Purify with at least one debuff on you.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'meditated',
      name: 'Meditated',
      description:
          'Every buff of yours that runs on a turn count gains five more '
          'turns — your stances deepen. Next-attack riders wait for an attack '
          'rather than a clock, so they gain nothing.',
      trigger: 'Casting Meditate.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'fester',
      name: 'Fester',
      description:
          'Every burn on you lasts three ticks longer — whatever lit it. Cast '
          'on the turn of a burn\'s last tick, it still catches it.',
      trigger: 'The enemy casting Fester.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'scour',
      name: 'Scour',
      description:
          'Every burn on you pays out all its remaining ticks at once, as a '
          'single hit, and is consumed — one shield to get through, one chance '
          'to deflect.',
      trigger: 'The enemy casting Scour.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'dispel',
      name: 'Dispel',
      description:
          'Strips your buffs — stances, pending riders and Grace. Arcane '
          'Knowledge is never stripped, and Haste is not a stance.',
      trigger: 'The enemy casting Dispel.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'shatter',
      name: 'Shatter',
      description:
          'Your shield, every Barrier point and your Divert stance are gone at '
          'once. It deals no damage — it just leaves you standing in the open.',
      trigger: 'The enemy casting Shatter.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
    StatusInfo(
      id: 'blindLifted',
      name: 'Blind lifted',
      description:
          'The clarity burns the Blind away — your spells stop missing for it.',
      trigger: 'Casting Truesight or Hawkeye while Blinded.',
      kind: StatusKind.moment,
      element: null,
      lingers: false,
    ),
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

  /// The polarity of [id], or null when nothing by that id is catalogued.
  ///
  /// The lookup Dispel/Cleanse/Purify use for the **field-backed** statuses
  /// (Waterlogged, Stagger, Grace, Haste, Empower, Quicken, Phase). A
  /// [TurnStatus] answers for itself — ask `status.polarity` there instead, so
  /// the runtime object stays the authority on the runtime object.
  static StatusPolarity? polarityOf(String id) => _byId[id]?.polarity;

  /// Lasting conditions of one polarity — Dispel's and Purify's target lists,
  /// in catalogue order (which is fixed, so a lockstep pick is identical on
  /// both clients).
  static Iterable<StatusInfo> lastingWithPolarity(StatusPolarity p) =>
      lasting.where((s) => s.polarity == p);

  /// Lasting conditions only — the ones that show as HUD pips.
  static Iterable<StatusInfo> get lasting => all.where((s) => s.lingers);

  /// One-shot moments — cleanses, strips, blocks.
  static Iterable<StatusInfo> get moments => all.where((s) => !s.lingers);
}
