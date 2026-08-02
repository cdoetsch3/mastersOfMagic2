/// Every creature in the game, by zone.
///
/// ⭐ **In code, not the database** — the same determinism argument as items
/// (ENEMIES §1.2). A duel resolves against these move sets and coefficients,
/// and lockstep means both clients must agree exactly.
library;

import 'enemy_def.dart';
import 'whispering_woods.dart';

abstract final class Bestiary {
  /// ⚠️ Only Whispering Woods is built. The other 24 zones have full rosters
  /// designed (ENEMIES §2d–2g) but no definitions yet.
  static const List<EnemyDef> all = [...WhisperingWoodsBestiary.all];

  static List<EnemyDef> forZone(String zoneId) =>
      all.where((e) => e.zoneId == zoneId).toList();

  static EnemyDef? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
