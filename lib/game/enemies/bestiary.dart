/// Every creature in the game, by zone.
///
/// ⭐ **In code, not the database** — the same determinism argument as items
/// (ENEMIES §1.2). A duel resolves against these move sets and coefficients,
/// and lockstep means both clients must agree exactly.
library;

import 'ashfall_vale.dart';
import 'cinderpeak_foothills.dart';
import 'enemy_def.dart';
import 'glimmerbrook.dart';
import 'thornmire.dart';
import 'whispering_woods.dart';

abstract final class Bestiary {
  /// ⚠️ **Every zone bestiary must be listed here.** An unlisted one compiles
  /// fine and simply never appears in an encounter — the same silent failure
  /// [ItemCatalogue] guards against for items.
  ///
  /// ✅ The whole **Primal quarter** is built: 5 zones × 11 creatures = 55.
  /// The other 21 zones have full rosters designed (ENEMIES §2d–2g) but no
  /// definitions yet.
  static const List<EnemyDef> all = [
    ...WhisperingWoodsBestiary.all,
    ...GlimmerbrookBestiary.all,
    ...CinderpeakBestiary.all,
    ...ThornmireBestiary.all,
    ...AshfallValeBestiary.all,
  ];

  static List<EnemyDef> forZone(String zoneId) =>
      all.where((e) => e.zoneId == zoneId).toList();

  static EnemyDef? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
