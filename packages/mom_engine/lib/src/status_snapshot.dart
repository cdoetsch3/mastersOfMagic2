import 'element.dart';
import 'element_status.dart';
import 'mage.dart';

/// One status/buff on a mage, frozen at a moment in time.
///
/// The engine mutates [MageState] in place, so the UI — which replays a turn's
/// events one animation at a time — cannot read live state without jumping
/// straight to the end-of-turn result. These snapshots let the pips advance in
/// step with the animation instead of all appearing at once.
class StatusView {
  /// Stable identifier, matching the [TurnStatus] id where one exists
  /// (`ignite`, `blind`, `photosynthesis`, `creepingDark`, `arcaneKnowledge`,
  /// `astralAlignment`) or a synthetic one for field-backed statuses
  /// (`haste`, `grace`, `empower`, `quicken`, `phase`, `waterlogged`,
  /// `stagger`, `streak`).
  final String id;

  /// Stack count where the status has one (0 when it doesn't).
  final int stacks;

  /// Turns remaining where the status is timed (0 when it isn't).
  final int turnsLeft;

  /// The status's headline number — Ignite's per-tick damage, Arcane
  /// Knowledge's bonus percent, Astral Alignment's pierce percent, Empower's
  /// multiplier. 0 when the status has no such figure.
  final int magnitude;

  /// The element a streak is building in (only set on the `streak` entry).
  final MagicElement? element;

  const StatusView({
    required this.id,
    this.stacks = 0,
    this.turnsLeft = 0,
    this.magnitude = 0,
    this.element,
  });
}

/// Everything the HUD needs to draw one mage's pips, frozen at a point in the
/// turn. Built by [StatusSnapshot.of] after each event the engine emits.
class StatusSnapshot {
  final List<StatusView> statuses;

  const StatusSnapshot(this.statuses);

  static const StatusSnapshot empty = StatusSnapshot([]);

  /// Freezes [m]'s display-relevant status state. Cheap: a dozen small
  /// objects, built a few dozen times per turn.
  factory StatusSnapshot.of(MageState m) {
    final out = <StatusView>[];

    // Consecutive-cast streak (only the elements that build toward something
    // are worth a pip; the HUD decides which those are).
    if (m.streakElement != null && m.streakCount > 0) {
      out.add(StatusView(
          id: 'streak', stacks: m.streakCount, element: m.streakElement));
    }

    // Statuses proper.
    for (final s in m.statuses) {
      switch (s) {
        case PhotosynthesisStatus(:final stacks):
          out.add(StatusView(id: 'photosynthesis', stacks: stacks));
        case ArcaneKnowledgeStatus(:final stacks, :final bonusPercent):
          out.add(StatusView(
              id: 'arcaneKnowledge', stacks: stacks, magnitude: bonusPercent));
        case CreepingDarkStatus(:final stacks):
          out.add(StatusView(id: 'creepingDark', stacks: stacks));
        case AstralAlignmentStatus(:final stacks, :final piercePercent):
          out.add(StatusView(
              id: 'astralAlignment',
              stacks: stacks,
              magnitude: piercePercent));
        case IgniteStatus(:final perTick, :final turnsLeft):
          out.add(StatusView(
              id: 'ignite', turnsLeft: turnsLeft, magnitude: perTick));
        case BlindStatus(:final turnsLeft):
          out.add(StatusView(id: 'blind', turnsLeft: turnsLeft));
      }
    }

    // Field-backed buffs and debuffs — not [TurnStatus]es, but pips all the
    // same, so they must ride along or they'd still jump to end-of-turn state.
    if (m.hasHaste) out.add(const StatusView(id: 'haste'));
    if (m.hasGrace) out.add(const StatusView(id: 'grace'));
    if (m.empowerMultiplier != null) {
      out.add(StatusView(id: 'empower', magnitude: m.empowerMultiplier!));
    }
    if (m.quickenPriority != null) out.add(const StatusView(id: 'quicken'));
    if (m.phaseNext) out.add(const StatusView(id: 'phase'));
    if (m.priorityPenalty > 0) out.add(const StatusView(id: 'waterlogged'));
    if (m.nextOffensiveDamageScale < 1.0) {
      out.add(const StatusView(id: 'stagger'));
    }

    return StatusSnapshot(out);
  }

  StatusView? operator [](String id) {
    for (final s in statuses) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Both mages' snapshots taken immediately after one event was emitted.
typedef StatusFrame = ({StatusSnapshot mage1, StatusSnapshot mage2});
