import 'element.dart';

/// Every tunable number behind the twelve element side-effects, in one place.
///
/// ⚠️ **These exist so the engine and the tooltips cannot disagree.** The
/// numbers used to be inline literals in `duel.dart` while the player-facing
/// text repeated them from memory in `element_lore.dart` and
/// `status_catalog.dart` — three copies, no link. When Photosynthesis was
/// reworked, every copy went stale and the consistency test could not tell,
/// because it only compared effect *names*.
///
/// `test/tooltip_consistency_test.dart` now asserts each element's lore quotes
/// the values below, so changing a number here fails the build until the text
/// is updated with it.
///
/// Specification: TYPE_EFFECTS_DESIGN.md §2 and §4.

abstract final class ElementTuning {
  /// ⭐ **The base miss chance every harmful cast carries** (ITEMS §9b.8,
  /// ruled 2026-08-09): base hit chance is 80%, and accuracy gear closes the
  /// gap. Symmetric — enemies whiff at the same rate. 📝 Flagged for one
  /// playtest before it is final; set to 0 to restore the old always-hit
  /// baseline.
  static const int baseMissPercent = 20;

  // ---- Tier 1 — Primal ------------------------------------------------

  /// Ignite (Pyro): chance to proc on a damaging hit, even a fully shielded
  /// one.
  static const int ignitePercent = 25;

  /// Ignite: burn per tick, as a percent of the attack's raw damage.
  static const int igniteBurnPercentOfDamage = 10;

  /// Ignite: number of end-of-turn ticks, the application turn included.
  static const int igniteTicks = 3;

  /// Waterlogged (Aqua): every Nth consecutive Aqua cast applies it.
  static const int waterloggedEveryNthCast = 3;

  /// Waterlogged: priority added to the victim's next action, sending it last.
  static const int waterloggedPriorityPenalty = 10;

  /// Photosynthesis (Flora): consecutive Flora casts before it activates.
  static const int photosynthesisStreak = 5;

  /// Photosynthesis: percent of max HP healed per turn while active.
  static const int photosynthesisHealPercent = 1;

  // ---- Tier 2 — Kinetic -----------------------------------------------

  /// Static Feedback (Electro): chance to strip a charge on a damaging hit.
  static const int staticFeedbackPercent = 20;

  /// Static Feedback: charges stripped per proc.
  static const int staticFeedbackChargeDrain = 1;

  /// Tailwind (Aero): consecutive Aero casts before it seizes Haste.
  /// How much a single level is worth, as a percent, applied to **both**
  /// max health and outgoing damage.
  ///
  /// ⭐ Both sides scale together, so a duel between equal levels plays
  /// exactly as it did before — which is what keeps the intelligence ladder
  /// and every balance figure measured against it still valid. Levels buy an
  /// advantage over *lower* levels, and nothing else.
  static const int percentPerLevel = 4;

  static const int tailwindStreak = 3;

  /// The point past which counting a streak stops meaning anything.
  ///
  /// ⭐ A streak that is *gated* — Flora's Photosynthesis at 5, Aero's
  /// Tailwind at 3 —
  /// gains nothing from climbing further, and a pip reading "Flora 9" invites
  /// the player to expect a payoff that does not exist. Those counters stop at
  /// the gate.
  ///
  /// ⚠️ Returns null for the **cadence** elements, which fire every Nth cast
  /// (Aqua's Waterlogged, Geo's Stagger, Sanctus's Absolution). Capping those
  /// would not tidy a display — it would silently switch the effect off
  /// forever once the cap was reached.
  static int? streakCap(MagicElement element) => switch (element) {
    MagicElement.flora => photosynthesisStreak,
    MagicElement.aero => tailwindStreak,
    _ => null,
  };

  /// Stagger (Geo): every Nth consecutive Geo cast applies it.
  static const int staggerEveryNthCast = 4;

  /// Stagger: percent damage the victim's next offensive spell deals.
  static const int staggerDamagePercent = 50;

  // ---- Tier 3 — Celestial ---------------------------------------------

  /// Blind (Solar): chance per charge spent on the attack.
  static const int blindPercentPerCharge = 10;

  /// Blind: the victim's offensive spells miss this often.
  static const int blindMissPercent = 50;

  /// Blind: how many of the victim's turns it lasts.
  static const int blindTurns = 3;

  /// The moon advances one step per turn through this many phases.
  static const int moonCycleTurns = 4;

  /// Lunar attacks hit this much harder on a Full Moon.
  static const int lunarFullMoonBonusPercent = 20;

  /// Astral Alignment: stacks gained per charge spent on an Astral cast.
  static const int alignmentPerCharge = 1;

  /// Astral Alignment: stack ceiling.
  static const int alignmentMaxStacks = 20;

  /// Astral Alignment: percent of each attack routed past shields, per stack.
  static const int alignmentPercentPerStack = 1;

  // ---- Tier 4 — Ethereal ----------------------------------------------

  /// Absolution (Sanctus): every Nth consecutive Sanctus cast fires the rite.
  static const int absolutionEveryNthCast = 3;

  /// Absolution: Creeping Dark seared off the opponent per firing.
  static const int absolutionSearsDark = 5;

  /// Grace: how many banked blocks can be held at once.
  static const int graceMaxStacks = 1;

  /// Creeping Dark (Umbra): stacks gained per charge spent on an Umbra cast.
  static const int creepingDarkPerCharge = 1;

  /// Creeping Dark: stack ceiling, which is also the Midnight threshold.
  static const int creepingDarkMaxStacks = 15;

  /// Creeping Dark: hides the holder's charging element from the opponent.
  static const int shadowThreshold = 5;

  /// Creeping Dark: hides the holder's charge and health from the opponent.
  static const int duskThreshold = 10;

  /// Creeping Dark: hides the holder's own charge and health from themselves.
  static const int midnightThreshold = 15;

  /// Arcane Knowledge: minimum charge spent on an Arcane cast to gain a stack.
  static const int arcaneKnowledgeMinCharge = 4;

  /// Arcane Knowledge: stack ceiling.
  static const int arcaneKnowledgeMaxStacks = 5;

  /// Arcane Knowledge: damage bonus per stack, on every spell.
  static const int arcaneKnowledgePercentPerStack = 5;
}
