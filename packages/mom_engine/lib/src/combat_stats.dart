/// The six combat stats, the seam statuses use to move them, and the global
/// output clamps — TYPE_EFFECTS_DESIGN.md §7a ("Priority lanes & global
/// clamps", ruled 2026-08-26).
///
/// ⭐ **The rule this file exists to enforce: DERIVATION, never
/// mutate-and-revert.** A status that grants +15 dodge does *not* write 15 into
/// [MageState.dodge] on application and subtract it again on expiry. It
/// declares a contribution, and every roll recomputes
/// `effective = base + gear + Σ(active statuses)` from scratch. Mutate-and-
/// revert loses the base the moment two sources overlap, a duel ends mid-buff,
/// or a status is stripped by something that didn't apply it — and the bug it
/// leaves behind (a mage permanently +15 dodge) is invisible until someone
/// audits a save.
library;

/// The six stats a status may move. Names match [MageState]'s stored fields so
/// the mapping is one-to-one and greppable.
///
/// ⚠️ Deliberately NOT a bag of every number a status can touch. Shield
/// strength, healing received and flat damage are their own levers with their
/// own rules (percent multipliers, once-per-cast application); folding them in
/// here would promise a summation semantic that isn't theirs.
enum CombatStat {
  /// Added to the spell's own accuracy in the hit roll (Truesight lane).
  accuracy,

  /// Subtracted from the attacker's hit roll (Lightfoot lane).
  dodge,

  /// Percent chance an incoming hit is deflected at all (Divert, part 1).
  deflectActivation,

  /// Percent of a deflected hit that is removed (Divert, part 2).
  deflectAmount,

  /// Percent chance an outgoing hit crits (Keen lane).
  critChance,

  /// Extra percent damage a crit deals (Heavyhand lane).
  critDamage,
}

/// A [TurnStatus] that moves one or more [CombatStat]s.
///
/// Implemented by the banked stat-granting statuses (Lightfoot, Divert,
/// Truesight, Murk, Keen, Heavyhand…). Nothing shipped implements it yet, so
/// every sum below is currently 0 — which is exactly right: the seam must be
/// provably inert before the spells that use it land.
///
/// Contributions are **signed**: Murk returns a negative [CombatStat.accuracy]
/// on the mage it afflicts. They are **summed across lanes** (spell + item +
/// element + gear underneath) per law 4 — same-lane collisions are prevented by
/// the replace-on-recast rule (law 5), not by anything here.
abstract interface class StatModifier {
  /// This status's signed contribution to [stat], or 0 if it doesn't touch it.
  int contributionTo(CombatStat stat);
}

/// The global output clamps (ruled 2026-08-26).
///
/// ⭐ **Clamp the OUTPUT, not the components.** The alternative — capping dodge
/// at 60 or accuracy at 150 — was rejected because it makes every individual
/// grant conditionally worthless (your +20 dodge does nothing because gear
/// already capped you) and forces every future stat source to know the cap.
/// One clamp at the point of resolution keeps every grant honest and keeps the
/// guarantee legible: *there is always a sliver that lands, and only Unerring
/// literally cannot miss.*
abstract final class CombatClamps {
  /// No attack is ever less than this likely to land, however evasive the
  /// target (§7a "Hit-chance floor").
  static const int hitChanceFloorPercent = 10;

  /// …and no roll is needed above this, which is what "cannot miss" means.
  static const int hitChanceCapPercent = 100;

  /// Deflection may never become a certainty (§7a "Deflect clamps").
  static const int deflectActivationCapPercent = 90;

  /// …nor may a deflected hit be erased entirely.
  static const int deflectFractionCapPercent = 90;

  /// Clamps a fully-assembled hit chance into [hitChanceFloorPercent] …
  /// [hitChanceCapPercent].
  static int hitChance(int raw) =>
      raw.clamp(hitChanceFloorPercent, hitChanceCapPercent);

  /// Clamps a fully-assembled deflect activation chance. Floors at 0 (a
  /// negative chance is "never", not "always").
  static int deflectActivation(int raw) =>
      raw.clamp(0, deflectActivationCapPercent);

  /// Clamps a fully-assembled deflected fraction.
  static int deflectFraction(int raw) =>
      raw.clamp(0, deflectFractionCapPercent);
}
