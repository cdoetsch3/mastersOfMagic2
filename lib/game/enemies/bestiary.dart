/// Every creature in the game, by zone.
///
/// ⭐ **In code, not the database** — the same determinism argument as items
/// (ENEMIES §1.2). A duel resolves against these move sets and coefficients,
/// and lockstep means both clients must agree exactly.
library;

import 'ashfall_vale.dart';
import 'cinderpeak_foothills.dart';
import 'enemy_def.dart';
import 'frostfell_pass.dart';
import 'glimmerbrook.dart';
import 'old_quarry.dart';
import 'starfall_basin.dart';
import 'stormcliff_coast.dart';
import 'the_mirrormere.dart';
import 'the_kiln_desert.dart';
import 'the_buried_sky.dart';
import 'the_collapsed_academy.dart';
import 'the_glass_archive.dart';
import 'the_reliquary_deep.dart';
import 'the_molten_deep.dart';
import 'the_shattered_orrery.dart';
import 'the_sunless_reach.dart';
import 'the_umbral_wastes.dart';
import 'the_unwritten_library.dart';
import 'thornmire.dart';
import 'thunderspire_peaks.dart';
import 'tidewrack_shoals.dart';
import 'whispering_woods.dart';
import 'windward_steppe.dart';

abstract final class Bestiary {
  /// ⚠️ **Every zone bestiary must be listed here.** An unlisted one compiles
  /// fine and simply never appears in an encounter — the same silent failure
  /// [ItemCatalogue] guards against for items.
  ///
  /// ✅ The whole **Primal quarter** is built: 5 zones × 11 creatures = 55.
  /// The Kinetic quarter (KINETIC_CONTRACT) is landing zone by zone on top.
  /// Remaining zones have full rosters designed (ENEMIES §2d–2g) but no
  /// definitions yet.
  static const List<EnemyDef> all = [
    ...WhisperingWoodsBestiary.all,
    ...GlimmerbrookBestiary.all,
    ...CinderpeakBestiary.all,
    ...ThornmireBestiary.all,
    ...AshfallValeBestiary.all,
    ...OldQuarryBestiary.all,
    ...WindwardSteppeBestiary.all,
    ...StormcliffCoastBestiary.all,
    ...FrostfellPassBestiary.all,
    ...ThunderspirePeaksBestiary.all,
    ...TheMoltenDeepBestiary.all,
    ...MirrormereBestiary.all,
    ...ShatteredOrreryBestiary.all,
    ...KilnDesertBestiary.all,
    ...TidewrackShoalsBestiary.all,
    ...StarfallBasinBestiary.all,
    ...SunlessReachBestiary.all,
    ...GlassArchiveBestiary.all,
    ...BuriedSkyBestiary.all,
    ...CollapsedAcademyBestiary.all,
    ...ReliquaryDeepBestiary.all,
    ...UmbralWastesBestiary.all,
    ...UnwrittenLibraryBestiary.all,
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
