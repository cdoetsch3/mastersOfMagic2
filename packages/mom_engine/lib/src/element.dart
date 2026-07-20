/// The nine elements, in three tiers of three. See TYPE_EFFECTS_DESIGN.md.
///
/// Each tier is a **closed counter-triangle**: every element counters exactly
/// one other element and is countered by exactly one, all within its own tier.
/// There are no cross-tier counter relationships. Countering matters for two
/// layers — shield math (an attack deals double to a countered shield) and the
/// per-tier effect interactions (the cleanse/immunity web) — both following
/// the same triangles.
///
/// Triangles (A → B means "A counters B"):
///   Tier 1 (Primal):   Pyro → Flora → Aqua → Pyro
///   Tier 2 (Kinetic):  Electro → Aero → Geo → Electro
///   Tier 3 (Ethereal): Radiant → Umbra → Arcane → Radiant
enum MagicTier { primal, kinetic, ethereal }

enum MagicElement {
  // Tier 1 — Primal
  aqua,
  pyro,
  flora,
  // Tier 2 — Kinetic
  electro,
  aero,
  geo,
  // Tier 3 — Ethereal
  radiant,
  umbra,
  arcane;

  MagicTier get tier => switch (this) {
        aqua || pyro || flora => MagicTier.primal,
        electro || aero || geo => MagicTier.kinetic,
        radiant || umbra || arcane => MagicTier.ethereal,
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
  // Tier 3: Radiant → Umbra → Arcane → Radiant
  MagicElement.radiant: MagicElement.umbra,
  MagicElement.umbra: MagicElement.arcane,
  MagicElement.arcane: MagicElement.radiant,
};
