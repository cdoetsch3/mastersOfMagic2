import 'element.dart';
import 'mage.dart';
import 'status.dart';

/// Tier 1 — Primal element statuses. See TYPE_EFFECTS_DESIGN.md §2. Built on
/// the [TurnStatus] framework; the [DuelEngine] applies/refreshes them from
/// element triggers.

/// **Ignite** (Pyro). A burn that ticks 10% of the triggering attack's raw
/// damage at the end of the turn it lands and the next two — 3 ticks, in the
/// end-phase damage band (E8). Regular damage: hits the shield first, with
/// Pyro counter math. Re-proccing refreshes the window (new value, new clock);
/// it never stacks.
class IgniteStatus extends TurnStatus {
  int perTick;
  int turnsLeft;

  IgniteStatus(this.perTick) : turnsLeft = 3;

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
              StatusDamage(perTick,
                  lane: Lane.damage,
                  source: 'Ignite',
                  element: MagicElement.pyro)
            ]
          : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

/// **Photosynthesis** (Flora). A stacking self-buff (max 3) that heals 1% of
/// max HP per stack at the end of each turn, in the heal band (E2) — so it
/// out-survives same-turn DoTs. While the holder has ≥1 stack they cannot be
/// Waterlogged. Cleared instantly by Ignite landing; otherwise it **decays**:
/// each turn without Flora activity (a Flora cast or charge) sheds one stack,
/// so the buff is an ongoing commitment, not a fire-and-forget.
class PhotosynthesisStatus extends TurnStatus {
  static const int maxStacks = 3;
  int stacks;

  PhotosynthesisStatus([this.stacks = 1]);

  void addStack() {
    if (stacks < maxStacks) stacks++;
  }

  @override
  String get id => 'photosynthesis';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) {
    if (phase != TurnPhase.end) return const [];
    final heal = (holder.maxHp * stacks / 100).round();
    return heal > 0
        ? [StatusHeal(heal, lane: Lane.heal, source: 'Photosynthesis')]
        : const [];
  }

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    // The turn's heal (if any) has already landed — decay applies after, in
    // the bookkeeping band, mirroring Creeping Dark's activity rule.
    if (holder.activeElementThisTurn != MagicElement.flora) {
      stacks--;
    }
    return stacks <= 0;
  }
}

/// **Blind** (Sanctus; moves to Solar in Phase 3). The holder's harmful spells have a 50% chance to miss
/// for their next 3 turns (not the turn it lands — [missChance] reports 0
/// until the application turn's bookkeeping runs). Re-proccing refreshes the
/// window. Arcane spells are exempt (checked at the miss gate, §4 table).
class BlindStatus extends TurnStatus implements Blinding {
  int turnsLeft = 3;
  bool _justApplied = true;

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
  static const int maxStacks = 15;
  static const int shadowThreshold = 5;
  static const int duskThreshold = 10;
  static const int midnightThreshold = 15;

  int stacks;

  CreepingDarkStatus([this.stacks = 0]);

  void addStacks(int chargeSpent) {
    stacks = (stacks + chargeSpent).clamp(0, maxStacks);
  }

  bool get shadow => stacks >= shadowThreshold;
  bool get dusk => stacks >= duskThreshold;
  bool get midnight => stacks >= midnightThreshold;

  @override
  String get id => 'creepingDark';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    if (holder.activeElementThisTurn != MagicElement.umbra) {
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
  static const int maxStacks = 5;
  static const int percentPerStack = 5;

  int stacks;

  ArcaneKnowledgeStatus([this.stacks = 1]);

  void addStack() {
    if (stacks < maxStacks) stacks++;
  }

  int get bonusPercent => stacks * percentPerStack;

  @override
  String get id => 'arcaneKnowledge';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => false; // permanent
}
