import 'element.dart';
import 'status.dart';

/// A raised shield occupying the mage's (single, in v1) shield slot.
class ActiveShield {
  /// Null for barriers, which are element-less.
  final MagicElement? element;

  int remaining;

  final bool isBarrier;

  ActiveShield.elemental(MagicElement this.element, this.remaining)
      : isBarrier = false;

  ActiveShield.barrier()
      : element = null,
        remaining = 0,
        isBarrier = true;

  @override
  String toString() =>
      isBarrier ? 'Barrier' : '${element!.name} shield ($remaining)';
}

/// Mutable per-duel state of one combatant (player or monster — same rules).
class MageState {
  final String name;
  final int maxHp;
  int hp;

  /// 0–5. At 0 the mage must choose an element before (or while) acting.
  int charge = 0;

  /// The element of the current charging cycle. Null whenever charge is 0
  /// and no cast is in flight.
  MagicElement? element;

  ActiveShield? shield;

  // Pending aux buffs, consumed by the next offensive spell cast.
  int? empowerMultiplier;
  int? quickenPriority;
  bool phaseNext = false;

  /// The **Haste** initiative token. At most one mage holds it; it breaks
  /// same-priority ties (the holder's spell resolves first). Managed by the
  /// engine — see DuelEngine.
  bool hasHaste = false;

  /// When true, this mage's charging element is hidden from the opponent
  /// (reserved for a future Shadow "Concealed" effect). Default false: the
  /// opponent can see what you're charging.
  bool concealed = false;

  /// **Grace** (Sanctus §4c.1 / the Hallow spell): the next debuff applied to
  /// this mage is blocked outright. Max 1, no stacking, persists until
  /// consumed. Does not block Fatigue.
  bool hasGrace = false;

  /// Active persistent statuses (DoTs, HoTs, stacking buffs). Resolved each
  /// turn's start/end phases by the engine — see [TurnStatus] and
  /// TYPE_EFFECTS_DESIGN.md §5.1. Empty until element effects apply them.
  final List<TurnStatus> statuses = [];

  // ---- Consecutive-cast streak (TYPE_EFFECTS_DESIGN.md §5.4) -------------
  // The element of the current cast streak and how many consecutive casts of
  // it have landed. Charging, forfeiting, fizzling, and missing leave these
  // untouched; casting a spell of a different element resets to (that, 1).
  MagicElement? streakElement;
  int streakCount = 0;

  /// The element this mage engaged this turn — set for a channel or a
  /// committed cast (fizzled/missed casts included: they "behave like a
  /// charge" of the cycling element), null on a forfeited turn. Drives
  /// activity-based stack decay (Photosynthesis; later, Creeping Dark).
  MagicElement? activeElementThisTurn;

  // ---- Precedence-pipeline modifiers (§5.2) -----------------------------
  // Set by procs; read at main-phase resolution in the documented order
  // (fizzle → priority → miss → damage mods).

  /// Added to this mage's next committed action priority (Waterlogged +10 —
  /// slower). Consumed when the action's priority is computed.
  int priorityPenalty = 0;

  /// Multiplier on this mage's next offensive spell's damage (Stagger = 0.5).
  /// Consumed by the next offensive spell that resolves.
  double nextOffensiveDamageScale = 1.0;

  /// Flat additive damage bonus, in percent, applied to every offensive spell
  /// (Arcane Knowledge = 5% per stack). Read at resolution, never consumed.
  int bonusDamagePercent = 0;

  // ---- Combat stats (GAME_DESIGN §1 "Combat stats") — Phase 3b ----------
  // All default to no-ops, and every roll that reads them is guarded on the
  // relevant chance being > 0, so a mage with default stats consumes no extra
  // RNG — the whole point is that turning these on is what changes a duel,
  // never leaving them off.

  /// Flat accuracy bonus (from gear), added to a spell's own accuracy. Percent.
  int accuracyBonus = 0;

  /// Reduces an attacker's hit chance against this mage. Percent points.
  int dodge = 0;

  /// Chance this mage's attacks land a crit (percent, 0–100).
  int critChance = 0;

  /// Extra damage a crit deals, in percent (default +50). Inert without
  /// [critChance], which is the natural brake on the pair.
  int critDamage = 50;

  /// Chance this mage deflects an incoming hit (percent, 0–100).
  int deflectChance = 0;

  /// Percent of a deflected hit that is removed (pure reduction, not
  /// reflection). The 50% player cap is a gear-budget rule (ITEMS §4.1a),
  /// enforced where stats are granted — the engine only clamps to [0,100] so
  /// damage can't go negative.
  int deflectAmount = 0;

  MageState({required this.name, this.maxHp = 100}) : hp = maxHp;

  /// Records a resolved cast for streak tracking. Not called for charges,
  /// forfeits, fizzles, or misses (those behave like a charge — no change).
  void recordCastForStreak(MagicElement element) {
    if (streakElement == element) {
      streakCount++;
    } else {
      streakElement = element;
      streakCount = 1;
    }
  }

  /// Highest miss chance among any [Blinding] status on this mage (0 if none).
  double get missChance => statuses
      .whereType<Blinding>()
      .fold(0.0, (m, b) => b.missChance > m ? b.missChance : m);

  bool get alive => hp > 0;

  static const int maxCharge = 5;

  void takeHpDamage(int amount) {
    hp = (hp - amount).clamp(0, maxHp);
  }

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  /// Consumes and returns the pending offensive buffs.
  ({int multiplier, bool phase}) consumeOffensiveBuffs() {
    final result = (multiplier: empowerMultiplier ?? 1, phase: phaseNext);
    empowerMultiplier = null;
    phaseNext = false;
    return result;
  }
}
