/// The twelve elements, in four tiers of three. See TYPE_EFFECTS_DESIGN.md.
///
/// Each tier is a **closed counter-triangle**: every element counters exactly
/// one other element and is countered by exactly one, all within its own tier.
/// Countering matters for two layers — shield math (an attack deals double to
/// a countered shield) and the per-tier effect interactions (the
/// cleanse/immunity web) — both following the same triangles.
///
/// Triangles (A → B means "A counters B"):
///   Tier 1 (Primal):    Pyro → Flora → Aqua → Pyro
///   Tier 2 (Kinetic):   Electro → Aero → Geo → Electro
///   Tier 3 (Celestial): Solar → Lunar → Astral → Solar
///   Tier 4 (Ethereal):  Sanctus → Umbra → Arcane → Sanctus
///
/// **Macro-tier loop** (TYPE_EFFECTS_DESIGN §0.3) — a second, coarser layer
/// that applies only *between* tiers. The higher tier beats the one below it,
/// and the starter tier beats the endgame tier:
///
///   Kinetic → Primal → Ethereal → Celestial → Kinetic
///
/// Primal beating Ethereal is the anti-power-creep valve: the starter
/// elements are the designed answer to the endgame tier, so a max-level mage
/// can never simply out-tier everyone. Opposite tiers (Primal↔Celestial,
/// Kinetic↔Ethereal) are neutral in both directions.
enum MagicTier {
  primal,
  kinetic,
  celestial,
  ethereal;

  /// The tier this one counters in the macro-tier loop.
  MagicTier get beatsTier => _tierCounters[this]!;

  /// The tier that counters this one.
  MagicTier get beatenByTier =>
      _tierCounters.entries.firstWhere((e) => e.value == this).key;

  /// True if this tier counters [other] at the macro layer. Always false for
  /// [other] == this — same-tier matchups resolve on the element triangle.
  bool countersTier(MagicTier other) => _tierCounters[this] == other;

  /// True if neither tier counters the other (the "opposite" tier in the
  /// 4-cycle). Same-tier is not neutral — it uses the element triangle.
  bool isNeutralWith(MagicTier other) =>
      this != other && !countersTier(other) && !other.countersTier(this);
}

enum MagicElement {
  // Tier 1 — Primal
  aqua,
  pyro,
  flora,
  // Tier 2 — Kinetic
  electro,
  aero,
  geo,
  // Tier 3 — Celestial
  solar,
  lunar,
  astral,
  // Tier 4 — Ethereal
  sanctus,
  umbra,
  arcane;

  MagicTier get tier => switch (this) {
        aqua || pyro || flora => MagicTier.primal,
        electro || aero || geo => MagicTier.kinetic,
        solar || lunar || astral => MagicTier.celestial,
        sanctus || umbra || arcane => MagicTier.ethereal,
      };

  /// Elements whose shields this element deals double damage to (and, at the
  /// effect layer, the element this one "wins" the tier interaction against).
  Set<MagicElement> get strongAgainst => {_counters[this]!};

  /// Elements whose attacks deal double damage to this element's shields.
  Set<MagicElement> get weakAgainst =>
      _counters.entries.where((e) => e.value == this).map((e) => e.key).toSet();

  /// Strength count == weakness count (== 1 for every element). Kept for
  /// compatibility with the old "volatility" concept; now uniform.
  int get volatility => strongAgainst.length;

  bool counters(MagicElement other) => _counters[this] == other;

  /// The one element this element is countered by (its tier predecessor).
  MagicElement get counteredBy =>
      _counters.entries.firstWhere((e) => e.value == this).key;
}

/// Each element counters exactly the next element in its tier's 3-cycle.
const Map<MagicElement, MagicElement> _counters = {
  // Tier 1: Pyro → Flora → Aqua → Pyro
  MagicElement.pyro: MagicElement.flora,
  MagicElement.flora: MagicElement.aqua,
  MagicElement.aqua: MagicElement.pyro,
  // Tier 2: Electro → Aero → Geo → Electro
  MagicElement.electro: MagicElement.aero,
  MagicElement.aero: MagicElement.geo,
  MagicElement.geo: MagicElement.electro,
  // Tier 3: Solar → Lunar → Astral → Solar
  MagicElement.solar: MagicElement.lunar,
  MagicElement.lunar: MagicElement.astral,
  MagicElement.astral: MagicElement.solar,
  // Tier 4: Sanctus → Umbra → Arcane → Sanctus
  MagicElement.sanctus: MagicElement.umbra,
  MagicElement.umbra: MagicElement.arcane,
  MagicElement.arcane: MagicElement.sanctus,
};

/// The macro-tier 4-cycle. Each tier counters exactly one other tier, and the
/// loop closes back on Primal → Ethereal (the anti-power-creep valve).
const Map<MagicTier, MagicTier> _tierCounters = {
  MagicTier.kinetic: MagicTier.primal,
  MagicTier.celestial: MagicTier.kinetic,
  MagicTier.ethereal: MagicTier.celestial,
  MagicTier.primal: MagicTier.ethereal,
};

/// The shield-damage multiplier for an [attack] element striking a shield of
/// [shieldElement], as an **integer percent**. TYPE_EFFECTS_DESIGN §0.3.
///
/// Two layers, which never stack — same-tier matchups use the element
/// triangle, cross-tier matchups use the macro-tier loop:
///
/// | Relationship                         | Percent |
/// |--------------------------------------|---------|
/// | Within-tier, you counter their shield| 200     |
/// | Within-tier, their shield counters you| 50     |
/// | Within-tier, same element            | 100     |
/// | Macro-tier, your tier counters theirs| 150     |
/// | Macro-tier, their tier counters yours| 75      |
/// | Macro-tier, opposite (neutral) tier  | 100     |
///
/// [attack] null means element-agnostic damage (a raw hit, a DoT that carries
/// no element): it never counters, so the multiplier is always 100.
int shieldMultiplierPercent(MagicElement? attack, MagicElement shieldElement) {
  if (attack == null) return 100;
  if (attack.tier == shieldElement.tier) {
    if (attack.counters(shieldElement)) return 200;
    if (shieldElement.counters(attack)) return 50;
    return 100; // same element (the only within-tier non-counter)
  }
  if (attack.tier.countersTier(shieldElement.tier)) return 150;
  if (shieldElement.tier.countersTier(attack.tier)) return 75;
  return 100; // opposite tier — neutral both ways
}

/// A short label for a non-neutral shield multiplier ("2×", "1.5×", "¾×",
/// "½×"), or null at 100% so callers can omit it. Shared by the battle log
/// and the duel screen so both read identically.
String? shieldMultiplierTag(int percent) => switch (percent) {
      200 => '2×',
      150 => '1.5×',
      75 => '¾×',
      50 => '½×',
      _ => null,
    };

/// The four phases of the moon (Lunar — TYPE_EFFECTS_DESIGN §4b.2). A single
/// **global, public, deterministic** clock derived from the turn counter, not
/// per-mage state — both clients compute it, so it needs no RNG or netcode.
enum MoonPhase { newMoon, waxing, full, waning }

/// The global moon phase on [turnNumber]. Turn 1 is New Moon, then the cycle
/// runs New → Waxing → Full → Waning every four turns (`turnNumber % 4`).
MoonPhase moonPhaseForTurn(int turnNumber) => switch (turnNumber % 4) {
      1 => MoonPhase.newMoon,
      2 => MoonPhase.waxing,
      3 => MoonPhase.full,
      _ => MoonPhase.waning, // 0
    };

/// The **additive** damage percent a Lunar attack gets in [phase] (folded in
/// alongside Arcane Knowledge, before multipliers — §5.2 step 5). New Moon is
/// the trough, Full Moon the peak; Waning is neutral for attacks (its bonus is
/// on shields/heals instead).
int lunarAttackPercent(MoonPhase phase) => switch (phase) {
      MoonPhase.newMoon => -25,
      MoonPhase.waxing => 25,
      MoonPhase.full => 50,
      MoonPhase.waning => 0,
    };
