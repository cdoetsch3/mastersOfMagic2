import 'dart:math';
import 'combat_stats.dart';
import 'element.dart';
import 'element_tuning.dart';
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

  /// The elemental shield slot. Barriers live in [barrier], a separate slot —
  /// the two stack, and a Barrier never displaces a shield you paid for.
  ActiveShield? shield;

  /// **Barrier points**, independent of [shield]. Each point blocks one
  /// incoming hit entirely, then is spent — so a 3-hit spell burns three
  /// points. Element-less by design: anything pops a point, so no counter
  /// math applies. Casting Barrier adds a point, up to [maxBarrierPoints].
  /// Checked before [shield] on every hit.
  int barrierPoints = 0;

  static const int maxBarrierPoints = 3;

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
  /// activity-based stack decay — Creeping Dark and Astral Alignment.
  /// (Photosynthesis no longer uses it: it is streak-gated, and streaks are
  /// built by casts alone.)
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
  //
  // ⚠️ **These fields are the BASE + GEAR figure and nothing else.** They are
  // written once, when the mage is built (a player from their equipment, an
  // enemy from its archetype's EnemyCombatStats), and never again. Statuses do
  // NOT write here — they contribute through [StatModifier], and the engine
  // reads the `effective*` getters below, which recompute the sum at every
  // roll. See combat_stats.dart for why mutate-and-revert was rejected.

  /// Flat accuracy bonus (from gear), added to a spell's own accuracy. Percent.
  int accuracyBonus = 0;

  /// Flat damage added ONCE per offensive cast (the wand lane, ITEMS §9b.8).
  /// Applied to the first hit, so multi-hit spells gain it once, not per hit.
  int damagePerCast = 0;

  /// Flat damage per charge the spell COST (the quarterstaff lane, §9b.8).
  /// "Charge spent" is §5b.3a's definition: the spell's cost, or what an
  /// X-cost spell actually paid. Also applied once, on the first hit.
  int damagePerCharge = 0;

  /// Shields this mage casts are this % stronger (ITEMS §9b.8). Elemental
  /// shields only — Barrier is point-based and has no strength to scale.
  int shieldStrengthPercent = 0;

  /// Healing this mage receives is this % larger (ITEMS §9b.8). Applied
  /// inside [heal], so potions, lifesteal, Photosynthesis and Regrow all
  /// route through it without knowing it exists.
  int healingReceivedPercent = 0;

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

  // ---- The derivation seam (TYPE_EFFECTS §7a law 3) ---------------------

  /// The signed sum of every active status's contribution to [stat].
  ///
  /// 0 today: no shipped status implements [StatModifier]. That is the correct
  /// state for this landing — the seam is provably inert until the banked
  /// stat-granting spells (Lightfoot, Divert, Truesight, Murk, Keen,
  /// Heavyhand…) arrive and start returning numbers from it.
  int statusContributionTo(CombatStat stat) {
    var sum = 0;
    for (final s in statuses) {
      if (s is StatModifier) sum += (s as StatModifier).contributionTo(stat);
    }
    return sum;
  }

  /// `base + gear + Σ(active statuses)`, recomputed on the spot. The engine
  /// reads these — never the stored fields — for every roll that matters.
  ///
  /// ⚠️ Unclamped by design: [CombatClamps] applies to the *assembled output*
  /// of a roll (hit chance, deflect activation, deflected fraction), not to a
  /// component. A stat clamped here would silently make a grant worthless and
  /// no test would ever see the difference.
  int get effectiveAccuracyBonus =>
      accuracyBonus + statusContributionTo(CombatStat.accuracy);

  int get effectiveDodge => dodge + statusContributionTo(CombatStat.dodge);

  int get effectiveCritChance =>
      critChance + statusContributionTo(CombatStat.critChance);

  int get effectiveCritDamage =>
      critDamage + statusContributionTo(CombatStat.critDamage);

  int get effectiveDeflectChance =>
      deflectChance + statusContributionTo(CombatStat.deflectActivation);

  int get effectiveDeflectAmount =>
      deflectAmount + statusContributionTo(CombatStat.deflectAmount);

  /// `gear + Σ(active statuses)` shield strength percent — the figure a shield
  /// is rolled against at the moment it is RAISED (Steadfast, §7a).
  ///
  /// ⚠️ Read once per shield, not per hit, and that is deliberate: a shield's
  /// strength is a pool the engine banks and then spends down, so the bonus
  /// belongs to the roll that fills it. See [SteadfastStatus] for the argument
  /// — the short version is that re-deriving a *running balance* every hit
  /// would shrink a half-spent shield when the buff falls off.
  int get effectiveShieldStrengthPercent {
    var sum = shieldStrengthPercent;
    for (final s in statuses) {
      if (s is ShieldStrengthModifier) {
        sum += (s as ShieldStrengthModifier).shieldStrengthContribution;
      }
    }
    return sum;
  }

  /// Active statuses of one polarity, in application order (fixed, so a
  /// lockstep random pick from it is identical on both clients). The hook
  /// Dispel (buffs), Cleanse/Purify (debuffs) and Absolution (a random debuff)
  /// query — none of them names a status.
  ///
  /// ⚠️ [TurnStatus]es only. The field-backed statuses (Waterlogged, Stagger,
  /// Grace, Haste, Empower, Quicken, Phase) are not in this list; a spell that
  /// must cover them adds them explicitly, as `_resolveAbsolution` does.
  Iterable<TurnStatus> statusesWithPolarity(StatusPolarity p) =>
      statuses.where((s) => s.polarity == p);

  /// The mage's character level. Drives [levelScale]; 1 is the baseline every
  /// balance figure in the design docs was measured at.
  final int level;

  /// An extra multiplier on **outgoing damage only**, on top of [levelScale].
  ///
  /// ⭐ **This is where an enemy archetype's `damageScale` lands** (ENEMIES
  /// §2.1). A player is always 1.0; a Glasswing is 1.70 and a Sentinel 0.70,
  /// which is what makes two enemies of the same level feel different rather
  /// than merely have different health.
  ///
  /// ⚠️ **Deliberately NOT applied to shields.** A Sentinel is 0.70 damage
  /// *and* a wall — scaling its shields down too would erase the archetype it
  /// exists to be. Damage and defence are separate dials on purpose.
  ///
  /// ⚠️ Lockstep: both clients derive this from the same `EnemyDef`, so it
  /// must never be rolled or read from anywhere but the shared definition.
  double powerScale = 1.0;

  /// Multiplier on max health and outgoing damage, from [level].
  ///
  /// ⭐ **Geometric, not linear** (ruling, 2026-07-28). At 4%/level compounding
  /// a level-50 mage is ~6.8x a level-1, where linear would be ~3x. That is
  /// deliberate: a fifty-level gap *should* be no contest, and it is what
  /// makes fighting monsters a few levels above you a real decision rather
  /// than a rounding error. Linear does not bite hard enough late.
  ///
  /// ⚠️ Both sides scale identically, so an even-level duel plays exactly as
  /// it always did — which is what keeps the intelligence ladder and every
  /// balance figure measured against it valid.
  double get levelScale => levelScaleFor(level);

  static double levelScaleFor(int level) =>
      pow(1 + ElementTuning.percentPerLevel / 100, level - 1).toDouble();

  /// Max health for a mage of [level], from the [base] at level 1.
  static int scaledMaxHp(int level, {int base = 100}) =>
      (base * levelScaleFor(level)).round();

  MageState({required this.name, this.level = 1, int? maxHp})
      : maxHp = maxHp ?? scaledMaxHp(level),
        hp = maxHp ?? scaledMaxHp(level);

  /// Records a resolved cast for streak tracking. Not called for charges,
  /// forfeits, fizzles, or misses (those behave like a charge — no change).
  void recordCastForStreak(MagicElement element) {
    if (streakElement == element) {
      // ⚠️ Gated streaks stop at their gate. Flora activates at 5 and gains
      // nothing from a 9th cast, and a pip counting past the payoff promises
      // one that is not coming. Cadence elements (Aqua, Geo, Sanctus) fire
      // every Nth cast and are deliberately left uncapped — see
      // [ElementTuning.streakCap].
      final cap = ElementTuning.streakCap(element);
      if (cap == null || streakCount < cap) streakCount++;
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

  /// Heals [amount], and returns the **signed** change in health: positive for
  /// health restored, NEGATIVE when Blight turned the heal into damage.
  ///
  /// ⭐ The one door all healing walks through (ITEMS §9b.8), which is exactly
  /// why the anti-heal debuffs live here: Wither taxes and Blight inverts
  /// potions, HoTs, Regrow, Photosynthesis and lifesteal alike, without any of
  /// them knowing either exists. Callers read the return value (or measure hp
  /// before and after) so their events stay truthful.
  int heal(int amount) {
    final before = hp;
    if (amount > 0 && isHealInverted) {
      // ⭐ **Blight supersedes Wither entirely** (ruled 2026-08-26): the FULL
      // heal is inverted, not the Wither-reduced one — a player's second
      // debuff must never weaken their first. At face value, too: healing
      // received modifiers of either sign are simply not consulted, because
      // this is no longer healing. It lands on health directly, as the heal it
      // replaces would have.
      takeHpDamage(amount);
      return hp - before;
    }
    final percent = healingReceivedPercent + statusHealingPercent;
    if (amount > 0 && percent != 0) {
      amount = (amount * (100 + percent) / 100).round();
      if (amount < 0) amount = 0; // a −150% tax heals nothing; it never bites
    }
    hp = (hp + amount).clamp(0, maxHp);
    return hp - before;
  }

  /// The healing-received modifier contributed by statuses (Wither = −50), in
  /// percent points, summed with the gear stat of the same name. Derivation,
  /// like every `effective*` getter above — recomputed at each heal.
  int get statusHealingPercent {
    var sum = 0;
    for (final s in statuses) {
      if (s is HealingModifier) {
        sum += (s as HealingModifier).healingReceivedPercent;
      }
    }
    return sum;
  }

  /// Whether any status inverts this mage's healing into damage (Blight).
  bool get isHealInverted => statuses.any((s) => s is HealInverting);

  /// Consumes and returns the pending offensive buffs.
  ({int multiplier, bool phase}) consumeOffensiveBuffs() {
    final result = (multiplier: empowerMultiplier ?? 1, phase: phaseNext);
    empowerMultiplier = null;
    phaseNext = false;
    return result;
  }
}
