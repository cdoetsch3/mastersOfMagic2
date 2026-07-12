/// The eight launch elements and their counter relationships.
///
/// Invariant (enforced by tests): every element has the same number of
/// strengths as weaknesses ("volatility"), and no two elements counter each
/// other mutually. Elements only matter for shield math: an attack whose
/// element counters the target shield's element deals double damage to that
/// shield.
enum MagicElement {
  earth,
  fire,
  water,
  air,
  electric,
  ice,
  light,
  shadow;

  /// Elements whose shields this element deals double damage to.
  Set<MagicElement> get strongAgainst => _counters[this]!;

  /// Elements whose attacks deal double damage to this element's shields.
  Set<MagicElement> get weakAgainst =>
      _counters.entries.where((e) => e.value.contains(this)).map((e) => e.key).toSet();

  /// Strength count == weakness count, by design ("volatility").
  int get volatility => strongAgainst.length;

  bool counters(MagicElement other) => strongAgainst.contains(other);
}

// The counter wheel (GAME_DESIGN.md):
//  - Air is the untouchable wind: counters nothing, countered by nothing.
//  - Light outshines every other light source; swallowed by the dark places.
//  - Shadow claims the dark places; banished by everything that glows.
const Map<MagicElement, Set<MagicElement>> _counters = {
  MagicElement.air: {},
  MagicElement.fire: {MagicElement.ice, MagicElement.shadow},
  MagicElement.water: {MagicElement.fire, MagicElement.light},
  MagicElement.earth: {MagicElement.electric, MagicElement.light},
  MagicElement.electric: {MagicElement.water, MagicElement.shadow},
  MagicElement.ice: {MagicElement.earth, MagicElement.light},
  MagicElement.light: {
    MagicElement.shadow,
    MagicElement.fire,
    MagicElement.electric,
  },
  MagicElement.shadow: {
    MagicElement.water,
    MagicElement.earth,
    MagicElement.ice,
  },
};
