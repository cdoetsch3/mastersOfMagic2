/// What a tier gate SAYS — the words at the gate screen and on the travel
/// card — kept apart from what it CHECKS (`GameLocation.gateItemIds`).
///
/// ⭐ **RULING (Christian, 2026-09-25): the gate is a stop on the road**
/// (mockup option B). Travel to a shut gate is never refused at departure;
/// the trip arrives, and the player lands at the gate rather than in the
/// town, until they unlock it there (`GateScreen`). Unlocking Pennycross
/// consumes the proofs — *"the proofs stay with the guard"*.
///
/// ⚠️ **Spending is per gate, and only Pennycross spends.** Every other
/// enforced gate keeps the 2026-09-21 contract, *shown, not spent*: the
/// Celestial Totem is ruled keepable (GAME_DESIGN §3, CELESTIAL_CONTRACT
/// §3.4 — "a charged artifact is a better souvenir than a spent one"), and
/// the arrival ruling did not reopen that.
///
/// ⚠️ **Only Pennycross has ruled copy.** Every other enforced gate (today,
/// Rimeholt's Celestial Totem) falls back to its `GameLocation.gate` prose
/// and a bare 'Gated' tag, which is honest rather than borrowed: "three
/// proofs" is the Primal guard's sentence, not a general one.
library;

import 'enemies/bestiary.dart';
import 'enemies/enemy_def.dart';
import 'achievements.dart';
import 'world.dart';

/// The words one gate uses.
class GateCopy {
  final String locationId;

  /// What the guard says, shown as a quote on the gate screen.
  final String guardLine;

  /// The travel card's tag while the gate is shut.
  final String shutTag;

  /// Granted the first time this gate is unlocked, if anything is.
  final String? achievementId;

  /// Whether Unlock SPENDS the items (true) or only shows them (false).
  final bool guardKeepsItems;

  const GateCopy({
    required this.locationId,
    required this.guardLine,
    required this.shutTag,
    this.achievementId,
    this.guardKeepsItems = false,
  });
}

abstract final class Gates {
  /// The bare tag for a gate with no ruled copy — and for every gate whose
  /// items are not built yet (prose only, `gateItemIds` empty).
  static const String plainShutTag = 'Gated';

  static const pennycross = GateCopy(
    locationId: 'pennycross',
    guardLine:
        'Three proofs. One from each of the old roads. Then the gate is '
        'yours, and I keep the papers.',
    shutTag: 'Gated · show three proofs at the gate',
    achievementId: 'papers_in_order',
    guardKeepsItems: true,
  );

  static const _ruled = <GateCopy>[pennycross];

  /// The ruled copy for [locationId], or null when it has none.
  static GateCopy? forLocation(String locationId) {
    for (final g in _ruled) {
      if (g.locationId == locationId) return g;
    }
    return null;
  }

  /// The gate screen's title.
  static String titleFor(GameLocation location) =>
      'The gate to ${location.name}';

  /// The travel card's tag while [location]'s gate is shut.
  static String shutTagFor(GameLocation location) =>
      forLocation(location.id)?.shutTag ?? plainShutTag;

  /// Whether unlocking [locationId] spends its items. ⚠️ False for a gate
  /// with no ruled copy — see the library note on the Totem.
  static bool guardKeepsItems(String locationId) =>
      forLocation(locationId)?.guardKeepsItems ?? false;

  /// The achievement unlocking [locationId] grants, if any.
  static AchievementDef? achievementFor(String locationId) {
    final id = forLocation(locationId)?.achievementId;
    return id == null ? null : Achievements.byId(id);
  }

  /// Where a gate item comes from, as the gate screen's dim line —
  /// `'from Whispering Woods · boss'` — or null when no boss drops it (the
  /// Celestial Totem is crafted).
  ///
  /// ⭐ **Read off the bestiary, not written down twice.** The proof is a
  /// guaranteed boss drop (`DropTable.always`); a hand-kept map from item to
  /// zone would be a second record of the same fact, free to drift.
  static String? sourceLineFor(String itemId) {
    for (final e in Bestiary.all) {
      if (e.rank != EnemyRank.boss) continue;
      if (e.drops.always.any((d) => d.defId == itemId)) {
        return 'from ${World.byId(e.zoneId).name} · boss';
      }
    }
    return null;
  }
}
