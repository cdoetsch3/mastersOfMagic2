import 'element.dart';
import 'mage.dart';
import 'element_tuning.dart';
import 'status.dart';

/// Tier 1 — Primal element statuses. See TYPE_EFFECTS_DESIGN.md §2. Built on
/// the [TurnStatus] framework; the [DuelEngine] applies/refreshes them from
/// element triggers.

/// **Ignite** (Pyro). A burn that ticks 10% of the triggering attack's raw
/// damage at the end of the turn it lands and the next two — 3 ticks, in the
/// end-phase damage band (E8). Regular damage: hits the shield first, with
/// Pyro counter math. Re-proccing refreshes the window (new value, new clock);
/// it never stacks.
///
/// ⭐ Ignite is a [DamageOverTime] like every other burn (2026-08-28): Fester
/// extends it and Scour collects it, and it says so through the interface
/// rather than by name — which is what lets the spell lane's DoTs and this one
/// feed the same machinery without either knowing the other exists. It is
/// also [TurnTimed] — on a clock, though not the holder's to Meditate.
class IgniteStatus extends TurnStatus implements DamageOverTime, TurnTimed {
  int perTick;
  @override
  int turnsLeft;

  IgniteStatus(this.perTick) : turnsLeft = 3;

  @override
  StatusPolarity get polarity => StatusPolarity.debuff;

  @override
  int get ticksLeft => turnsLeft;

  @override
  int get damagePerTick => perTick;

  @override
  void addTicks(int count) => turnsLeft += count;

  /// ⚠️ [TurnTimed] + debuff is exactly the pair Fester feeds and Meditate must
  /// not: a burn is on a clock, but it is not the holder's to extend.
  @override
  void extendTurns(int turns) => turnsLeft += turns;

  /// Re-proc: a fresh 3-tick clock at the new attack's value.
  void refresh(int newPerTick) {
    perTick = newPerTick;
    turnsLeft = 3;
  }

  @override
  String get id => 'ignite';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.end
      ? [
          StatusDamage(
            perTick,
            lane: Lane.damage,
            source: 'Ignite',
            element: MagicElement.pyro,
          ),
        ]
      : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

/// **Photosynthesis** (Flora). ⭐ **Streak-gated, like Aero's Tailwind**: from
/// the **5th consecutive Flora cast** onward the holder heals **1% of max HP**
/// at the end of each turn, in the heal band (E2), and cannot be Waterlogged.
/// The first four casts do nothing at all.
///
/// ⚠️ **Rewritten 2026-07-26 because the old design made Flora the only
/// element outside the 40–60% balance band at every skill level** (82.9% at
/// intelligence 4, still 70.1% at 10 — see TYPE_EFFECTS §2.3a). The cause was
/// the *trigger*, not the ceiling: every Flora cast added a stack
/// unconditionally, with no hit required, no proc roll and nothing for the
/// opponent to play around. Trimming stacks 5→3 had already failed to fix it,
/// because it treated the symptom.
///
/// A streak gate fixes the trigger instead. It costs five turns of commitment
/// before paying anything, it is visible to the opponent the whole time, and
/// breaking the streak — including with Ignite — switches it straight off.
///
/// Superseded design, for the record: a stacking self-buff (max 3) healing 1%
/// per stack, which **decayed**: each turn without Flora activity (a cast or
/// charge) shed one stack,
/// so the buff is an ongoing commitment, not a fire-and-forget.
class PhotosynthesisStatus extends TurnStatus {
  /// Consecutive Flora casts required before the effect does anything.
  static const int streakThreshold = ElementTuning.photosynthesisStreak;

  /// Percent of max HP healed per turn while active.
  static const int healPercent = ElementTuning.photosynthesisHealPercent;

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  String get id => 'photosynthesis';

  /// Whether [holder]'s Flora streak currently sustains the effect.
  static bool activeFor(MageState holder) =>
      holder.streakElement == MagicElement.flora &&
      holder.streakCount >= streakThreshold;

  /// ⭐ **The gear proc's unit** (ENCHANTING_DESIGN §4.1a "+1 Photosynthesis
  /// stack on you"): one turn's [healPercent] heal granted by a Greater Flora
  /// enchant, owed at THIS turn's end and cleared by its bookkeeping.
  ///
  /// ⚠️ Photosynthesis has had no stacks since the 2026-07-26 streak rework,
  /// so "a stack" maps to its base unit — one turn of the heal — and ⚠️ it
  /// ADDS to a streak-sustained heal rather than replacing it, which is what
  /// "+1" meant against the old stacking design. Set, never incremented: one
  /// proc per hit and one hit a turn makes 1 the most a turn can owe.
  ///
  /// 📝 While it is owed the holder holds Photosynthesis — so it blocks
  /// Waterlogged and Ignite strips it, the §5.2 web unchanged.
  int gearUnits = 0;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    final units = (activeFor(holder) ? 1 : 0) + gearUnits;
    if (phase != TurnPhase.end || units == 0) return const [];
    final heal = units * (holder.maxHp * healPercent / 100).round();
    return heal > 0
        ? [StatusHeal(heal, lane: Lane.heal, source: 'Photosynthesis')]
        : const [];
  }

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    gearUnits = 0;
    return !activeFor(holder);
  }
}

/// **Blind** (Solar in the V2 roster). The holder's harmful spells have a 50%
/// chance to miss for their next 3 turns (not the turn it lands — [missChance]
/// reports 0 until the application turn's bookkeeping runs). Re-proccing
/// refreshes the window. Astral spells are exempt (checked at the miss gate,
/// §4b table). While present it also **eclipses** the holder's moon to New
/// (the engine reads its presence — TYPE_EFFECTS §4b.3).
class BlindStatus extends TurnStatus implements Blinding, TurnTimed {
  @override
  int turnsLeft;
  bool _justApplied = true;

  /// A Blind of [turns] miss-turns. ⭐ The default is the spell path's
  /// [ElementTuning.blindTurns]; a Greater Solar or Lunar enchant's gear proc
  /// passes 1 (ENCHANTING_DESIGN §4.1a "Blind, 1 turn").
  BlindStatus({int turns = ElementTuning.blindTurns}) : turnsLeft = turns;

  @override
  StatusPolarity get polarity => StatusPolarity.debuff;

  @override
  void extendTurns(int turns) => turnsLeft += turns;

  /// Re-proc: a fresh 3-turn window starting next turn.
  void refresh() {
    turnsLeft = 3;
    _justApplied = true;
  }

  @override
  double get missChance => _justApplied ? 0.0 : 0.5;

  @override
  String get id => 'blind';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    if (_justApplied) {
      _justApplied = false; // active from next turn; window uncounted so far
      return false;
    }
    return --turnsLeft <= 0;
  }
}

/// **Creeping Dark** (Umbra). Information warfare: stacks grow by the charge
/// spent on each Umbra cast, decay by 1 on turns without Umbra activity
/// (charging pauses decay but grants nothing), cap 15. Thresholds hide ever
/// more of the game from the OPPONENT's view (display-layer; the engine just
/// tracks state and maintains [MageState.concealed] for Shadow):
///   5+  Shadow — enemy can't see what element the caster is charging
///   10+ Dusk — enemy can't see the caster's charge or health bar
///   15  Midnight — enemy can't see their OWN charge or health bar
/// Cleared entirely when the holder is Blinded (Sanctus banishes Umbra).
class CreepingDarkStatus extends TurnStatus {
  static const int maxStacks = ElementTuning.creepingDarkMaxStacks;
  static const int shadowThreshold = ElementTuning.shadowThreshold;
  static const int duskThreshold = ElementTuning.duskThreshold;
  static const int midnightThreshold = ElementTuning.midnightThreshold;

  int stacks;

  CreepingDarkStatus([this.stacks = 0]);

  void addStacks(int chargeSpent) {
    stacks = (stacks + chargeSpent).clamp(0, maxStacks);
  }

  bool get shadow => stacks >= shadowThreshold;
  bool get dusk => stacks >= duskThreshold;
  bool get midnight => stacks >= midnightThreshold;

  /// ⚠️ Genuinely ambiguous, ruled **buff**: it does nothing *to* its holder at
  /// all — the entire effect is hiding the board from the OPPONENT — so the
  /// only honest reading of "good for whoever holds it" is yes. (Absolution
  /// already treats it that way: it strips the opponent's stacks as a separate,
  /// explicit step rather than through the debuff purge.)
  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  String get id => 'creepingDark';

  /// ⭐ Set by a Greater Umbra enchant's gear proc (ENCHANTING_DESIGN §4.1a):
  /// skip THIS turn's decay once. ⚠️ Without it a stack granted on a
  /// non-Umbra turn decays at that same turn's end and the proc would add
  /// nothing anyone could ever see. Cleared by the bookkeeping that honours
  /// it; the spell path never sets it.
  bool holdDecay = false;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    if (holdDecay) {
      holdDecay = false;
    } else if (holder.activeElementThisTurn != MagicElement.umbra) {
      stacks--;
    }
    return stacks <= 0;
  }
}

/// **Arcane Knowledge** (Arcane). +1 stack per Arcane cast that spends 4+
/// charge (max 5); each stack is +5% damage on every spell, permanent for the
/// duel — never decays, never cleared, never consumed. Gaining is blocked
/// while under the opponent's Dusk or Midnight (Umbra corrupts Arcane). The
/// engine mirrors stacks into [MageState.bonusDamagePercent].
class ArcaneKnowledgeStatus extends TurnStatus {
  /// ⚠️ **Never stripped.** "Permanent for the duel — it never decays, is
  /// never cleared and is never consumed" (§4.3) predates Dispel and outranks
  /// it: what you have learned is not a stance you are holding. (The engine
  /// also mirrors the stacks into [MageState.bonusDamagePercent], so stripping
  /// the status would not even remove the bonus — it would just desync it.)
  @override
  bool get strippable => false;

  static const int maxStacks = ElementTuning.arcaneKnowledgeMaxStacks;
  static const int percentPerStack =
      ElementTuning.arcaneKnowledgePercentPerStack;

  int stacks;

  ArcaneKnowledgeStatus([this.stacks = 1]);

  void addStack() {
    if (stacks < maxStacks) stacks++;
  }

  int get bonusPercent => stacks * percentPerStack;

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  String get id => 'arcaneKnowledge';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => false; // permanent
}

/// **Astral Alignment** (Astral — TYPE_EFFECTS §4b.4). A stacking self-buff
/// that grows with **charge spent**, not cast count: **+1 per charge** on an
/// Astral cast (so a 5-charge spell grants 5), capped at **20**, and −1 on
/// turns without Astral activity — a commit-or-lose rule. (Photosynthesis used
/// to share it; it is streak-gated now and no longer decays.) Each stack
/// routes **1%** of every attack's damage straight
/// to health, bypassing the shield (applied in the engine's `_attack`, not as
/// a StatusOp), so a maxed Alignment pierces **20%**. Polarity is
/// [StatusPolarity.buff] — it's the caster's own, so Absolution never touches
/// it.
class AstralAlignmentStatus extends TurnStatus {
  static const int maxStacks = ElementTuning.alignmentMaxStacks;

  /// Pierce per stack. 1% × 20 stacks = 20% max — deliberately *not* the old
  /// 5%/stack, which at a 20 cap would have pierced 100% and deleted shields.
  static const int percentPerStack = ElementTuning.alignmentPercentPerStack;
  int stacks;

  AstralAlignmentStatus([this.stacks = 1]);

  /// Grants [amount] stacks (the charge spent on the cast), clamped to the cap.
  void addStacks(int amount) {
    stacks = (stacks + amount).clamp(0, maxStacks);
  }

  /// The percent of an attack that bypasses the shield to health (0–20).
  int get piercePercent => stacks * percentPerStack;

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  String get id => 'astralAlignment';

  /// ⭐ Set by a Greater Astral enchant's gear proc — ENCHANTING_DESIGN §4.1a
  /// promises the Alignment "on your NEXT cast", so the granted stack must
  /// survive this turn's decay once. ⚠️ Without it a non-Astral wearer's
  /// stack is gone at the end of the turn it landed, before any cast could
  /// pierce with it. Cleared by the bookkeeping that honours it.
  bool holdDecay = false;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    if (holdDecay) {
      holdDecay = false;
    } else if (holder.activeElementThisTurn != MagicElement.astral) {
      stacks--;
    }
    return stacks <= 0;
  }
}

/// A one-shot marker that schedules **Absolution** to resolve in this turn's
/// end heal band (E1–E3). Added when the 3rd consecutive Sanctus cast lands;
/// emits a single [StatusPurge] in the end phase, then expires in the same
/// turn's bookkeeping. The purge itself (random debuff → else Grace) plus the
/// opponent's Creeping-Dark strip are handled by the engine. TYPE_EFFECTS §4c.
class PendingAbsolutionStatus extends TurnStatus {
  /// ⚠️ Genuinely ambiguous, ruled **neutral**: the Absolution it schedules is
  /// certainly good for the holder, but this is a one-turn scheduler, not a
  /// condition. Calling it a buff would put it in Dispel's pool, letting a 4c
  /// spell cancel a three-cast Sanctus ritual as an invisible side effect
  /// nobody priced — and it self-expires the same turn regardless.
  @override
  StatusPolarity get polarity => StatusPolarity.neutral;

  @override
  String get id => 'pendingAbsolution';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.end ? const [StatusPurge()] : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => true; // fires once, then gone
}
