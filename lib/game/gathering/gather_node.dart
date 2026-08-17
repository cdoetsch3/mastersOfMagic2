/// Gathering nodes: where the world hands you materials (ITEMS §9b.7).
///
/// ⭐ **A node is an encounter card, not a map pin** (the Workbench-sheet
/// ruling, 2026-08-10): it appears between fights on an adventure, offers
/// one harvest, and its yield rides the run's pending loot through the same
/// take-home picker as drops. One simultaneous harvest per node (§9b.7's
/// one-harvest ruling); replenishment is simply the next run's roll.
///
/// ⚠️ **The flavor line never says what grows where beyond THIS node** — the
/// node itself is how the world teaches (the no-second-source ruling).
library;

import '../crafting/gesture.dart';
import '../skills.dart';

class GatherNodeDef {
  final String id;
  final String zoneId;
  final GatherSkill skill;

  /// What one harvest yields: [min]–[max] of the fungible [yieldsDefId].
  final String yieldsDefId;
  final int min;
  final int max;

  /// The gathering act — same vocabulary as crafting steps, so the gesture
  /// engines are reused with a field skin (Felling IS the chop meter).
  /// 📝 Unused until the engines exist; the button harvests instantly.
  final GestureStep step;

  /// Skill XP for the harvest.
  final int xp;

  /// One or two sentences, in the zone's voice.
  final String flavor;

  const GatherNodeDef({
    required this.id,
    required this.zoneId,
    required this.skill,
    required this.yieldsDefId,
    required this.min,
    required this.max,
    required this.step,
    required this.xp,
    required this.flavor,
  });
}

abstract final class GatherNodes {
  /// ⭐ Whispering Woods yields exactly its two materials (ITEMS §9b.8's
  /// 2-per-pure-zone rule): the wood and the fibre.
  static const oakStand = GatherNodeDef(
    id: 'ww_oak_stand',
    zoneId: 'whispering_woods',
    skill: GatherSkill.felling,
    yieldsDefId: 'oak_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 2),
    xp: 9,
    flavor:
        'An old stand, wind-felled and seasoning where it lies. Good logs, '
        'if your arms are willing.',
  );

  static const bindweedTangle = GatherNodeDef(
    id: 'ww_bindweed_tangle',
    zoneId: 'whispering_woods',
    skill: GatherSkill.foraging,
    yieldsDefId: 'bindweed_fibre',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pull', complexity: 1),
    xp: 9,
    flavor:
        'A tangle thick enough to trip a horse. The trick is cutting it '
        'before it notices.',
  );

  /// ⚠️ Every zone list must be reachable from here — an unlisted node
  /// compiles fine and simply never spawns, the usual silent failure.
  static const all = <GatherNodeDef>[oakStand, bindweedTangle];

  static final Map<String, GatherNodeDef> _byId = {
    for (final n in all) n.id: n,
  };

  static GatherNodeDef? byId(String id) => _byId[id];

  static List<GatherNodeDef> forZone(String zoneId) =>
      [for (final n in all) if (n.zoneId == zoneId) n];
}
