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
import 'hallowmarch.dart';
import 'old_quarry.dart';
import 'starfall_basin.dart';
import 'stormcliff_coast.dart';
import 'the_mirrormere.dart';
import 'the_kiln_desert.dart';
import 'the_buried_sky.dart';
import 'the_collapsed_academy.dart';
import 'the_glass_archive.dart';
import 'the_reliquary_deep.dart';
import 'the_sealed_garden.dart';
import 'the_eclipsed_citadel.dart';
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
    ...HallowmarchBestiary.all,
    ...SealedGardenBestiary.all,
    ...EclipsedCitadelBestiary.all,
  ];

  static List<EnemyDef> forZone(String zoneId) =>
      all.where((e) => e.zoneId == zoneId).toList();

  static EnemyDef? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// ⭐⭐ **The boss ORDER for a zone that fights all of its bosses, in
  /// sequence, every clear — and the empty list for every other zone.**
  ///
  /// ⚠️ **Empty is the rule; a sequence is the exception.** Every zone in the
  /// game draws ONE boss out of a pool of two (`AdventureRun.roll`, GAME_DESIGN
  /// §3d) so that a clear is a coin flip and a zone is not memorised after one
  /// run. Only The Eclipsed Citadel overrides that, because ⭐ *"a finale that
  /// ends on a coin flip has no ending"* — half the players would never meet
  /// Procarius, who is the game's named antagonist and its only level-60
  /// persona (ENEMIES §2e, §4.1).
  ///
  /// ⭐ **Read by `adventure.dart`, which is the only caller.** When this is
  /// non-empty the run's boss stage becomes the whole list, in order, one fight
  /// each; `AdventureRun.atFinalBoss` then makes the zone count as cleared only
  /// once the LAST of them falls. When it is empty — everywhere else — nothing
  /// about the single-boss draw changes.
  ///
  /// ⚠️ **Ids, not defs.** A `List<EnemyDef>` here would make the bestiary and
  /// the sequence two records of the same roster, free to drift; the ids are
  /// resolved against the roster the run was actually given, and a name that no
  /// longer resolves falls back to the ordinary draw rather than dropping a
  /// boss.
  static List<String> bossSequenceFor(String zoneId) =>
      _bossSequences[zoneId] ?? const <String>[];

  /// ⚠️ **One entry, and it should stay that way.** See [bossSequenceFor].
  static const Map<String, List<String>> _bossSequences = {
    'the_eclipsed_citadel': EclipsedCitadelBestiary.bossSequence,
  };
}
