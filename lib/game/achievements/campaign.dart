/// ACHIEVEMENTS §5.1 — three entries per combat zone, and the capstones.
///
/// ⭐ **Generated, not written out.** Every combat zone (`World.locations`
/// with an adventure) gets a **Clear**, a **Purge** and a **Collector** of
/// the same shape, so the shape is code and only the NAMES are hand-written
/// ([names]). A zone added to the world without a row there fails at load —
/// and `test/achievement_catalogue_test.dart` names it.
///
/// ⚠️ **Ids are built from the zone id** — `clear_<zone>`, `purge_<zone>`,
/// `collect_<zone>` — so a zone id, once shipped, is an achievement id too.
/// `World.renamedIds` covers a save's stored location; it does NOT rename
/// an earned achievement. Never rename a combat zone's id.
library;

import '../achievements.dart';
import '../enemies/bestiary.dart';
import '../items/item_catalogue.dart';
import '../items/item_def.dart';
import '../player_profile.dart';
import '../world.dart';
import 'shared.dart';

/// The three hand-written names of one zone's entries.
typedef ZoneAchievementNames = ({String clear, String purge, String collect});

abstract final class CampaignAchievements {
  /// ⭐ The 78 names, by zone id, in world order (§5.1a). **Clear** is the
  /// walker who crossed it, **Purge** a "Nothing Left Standing", **Collector**
  /// an "Everything the Woods Gave". Rename freely — names are not on disk.
  static const Map<String, ZoneAchievementNames> names = {
    // Primal
    'whispering_woods': (
      clear: 'Woods Walker',
      purge: 'Nothing Left Standing',
      collect: 'Everything the Woods Gave',
    ),
    'glimmerbrook': (
      clear: 'Brook Wader',
      purge: 'The Brook Runs Quiet',
      collect: 'All That Glimmers',
    ),
    'cinderpeak_foothills': (
      clear: 'Foothill Climber',
      purge: 'Cold Ashes',
      collect: 'Picked from the Cinders',
    ),
    'thornmire': (
      clear: 'Mire Strider',
      purge: 'The Mire Lies Still',
      collect: 'Dredged from the Mire',
    ),
    'ashfall_vale': (
      clear: 'Vale Wanderer',
      purge: 'The Vale Swept Clean',
      collect: 'Sifted from the Ash',
    ),
    // Kinetic
    'old_quarry': (
      clear: 'Quarry Scrambler',
      purge: 'Not a Stone Stirring',
      collect: 'Quarried Clean',
    ),
    'stormcliff_coast': (
      clear: 'Coast Runner',
      purge: 'The Storm Breaks',
      collect: 'Storm Salvage',
    ),
    'windward_steppe': (
      clear: 'Steppe Rider',
      purge: 'Nothing on the Wind',
      collect: 'Gathered on the Wind',
    ),
    'frostfell_pass': (
      clear: 'Frost Treader',
      purge: 'Nothing Left but Snow',
      collect: 'Dug from the Snow',
    ),
    'thunderspire_peaks': (
      clear: 'Spire Scaler',
      purge: 'The Thunder Stops',
      collect: 'Struck Lucky',
    ),
    'the_molten_deep': (
      clear: 'Deep Delver',
      purge: 'Nothing Left but Slag',
      collect: 'Pulled from the Fire',
    ),
    // Celestial
    'the_kiln_desert': (
      clear: 'Dune Crosser',
      purge: 'Only Sand Remains',
      collect: 'Fired in the Kiln',
    ),
    'the_mirrormere': (
      clear: 'Mere Skimmer',
      purge: 'Nothing in the Mirror',
      collect: 'Everything the Mere Reflected',
    ),
    'starfall_basin': (
      clear: 'Basin Roamer',
      purge: 'The Stars Go Out',
      collect: 'Every Fallen Star',
    ),
    'tidewrack_shoals': (
      clear: 'Shoal Sailor',
      purge: 'The Tide Goes Out',
      collect: 'Flotsam and Jetsam',
    ),
    'the_sunless_reach': (
      clear: 'Sunless Rambler',
      purge: 'Nothing in the Dark',
      collect: 'Found in the Dark',
    ),
    'the_shattered_orrery': (
      clear: 'Orrery Drifter',
      purge: 'The Gears Stop Turning',
      collect: 'Every Last Cog',
    ),
    // Ethereal
    'hallowmarch': (
      clear: 'March Pilgrim',
      purge: 'The March Ends',
      collect: 'Every Offering',
    ),
    'the_umbral_wastes': (
      clear: 'Shadow Trekker',
      purge: 'Not a Shadow Moves',
      collect: 'Everything the Shadows Held',
    ),
    'the_reliquary_deep': (
      clear: 'Vault Descender',
      purge: 'Nothing Left to Guard',
      collect: 'Every Relic',
    ),
    'the_sealed_garden': (
      clear: 'Garden Trespasser',
      purge: 'The Garden Weeded',
      collect: 'The Full Harvest',
    ),
    'the_glass_archive': (
      clear: 'Glass Stepper',
      purge: 'Nothing Behind the Glass',
      collect: 'The Archive Catalogued',
    ),
    'the_buried_sky': (
      clear: 'Sky Burrower',
      purge: 'The Sky Stays Buried',
      collect: 'Everything the Sky Buried',
    ),
    'the_collapsed_academy': (
      clear: 'Rubble Crawler',
      purge: 'Class Dismissed',
      collect: 'Full Marks',
    ),
    'the_unwritten_library': (
      clear: 'Stack Rover',
      purge: 'Not a Page Turns',
      collect: 'Every Unwritten Page',
    ),
    'the_eclipsed_citadel': (
      clear: 'Eclipse Chaser',
      purge: 'The Citadel Empty',
      collect: 'Everything the Eclipse Hid',
    ),
  };

  /// Every zone that hosts an adventure, in world order — the 26 the
  /// campaign entries are generated for.
  static final List<GameLocation> combatZones = List.unmodifiable([
    for (final l in World.locations)
      if (l.hasAdventure) l,
  ]);

  /// The creature ids of [zoneId]'s roster — what Purge asks to see slain.
  static Set<String> rosterOf(String zoneId) => _rosters[zoneId] ?? const {};

  /// ⭐ What Collector asks to see: every def id any creature of [zoneId]
  /// can drop (`DropTable.possibleDrops`), motes included.
  ///
  /// ⚠️ **Keys excluded.** A [KeyDef] (the proofs, the Ethereal thirds) is
  /// a quest item: it drops until it is carried, and a character who opened
  /// the gate before `itemsSeen` existed could never see it again.
  ///
  /// 📝 Only the zone's drop TABLES. The boss's guaranteed zone gear and the
  /// empty-roll consolation (`rollKill`) are not in any table, so they are
  /// not asked for.
  static Set<String> collectorDropsOf(String zoneId) =>
      _drops[zoneId] ?? const {};

  /// How many distinct creatures of [zoneId] [p] has slain — ⚠️ that zone's
  /// roster only; a kill anywhere else never counts here.
  static int slainIn(PlayerProfile p, String zoneId) =>
      rosterOf(zoneId).where((id) => p.bestiaryEntryFor(id).slain > 0).length;

  /// How many of [zoneId]'s Collector drops [p] has seen.
  static int seenIn(PlayerProfile p, String zoneId) =>
      collectorDropsOf(zoneId).where(p.itemsSeen.contains).length;

  static bool _purged(PlayerProfile p, String zoneId) =>
      slainIn(p, zoneId) >= rosterOf(zoneId).length;

  static bool _collected(PlayerProfile p, String zoneId) =>
      seenIn(p, zoneId) >= collectorDropsOf(zoneId).length;

  static final Map<String, Set<String>> _rosters = {
    for (final z in combatZones)
      z.id: {for (final e in Bestiary.forZone(z.id)) e.id},
  };

  static final Map<String, Set<String>> _drops = {
    for (final z in combatZones)
      z.id: {
        for (final e in Bestiary.forZone(z.id))
          for (final id in e.drops.possibleDrops)
            if (ItemCatalogue.tryById(id) is! KeyDef) id,
      },
  };

  /// [name] mid-sentence: `'The Molten Deep'` reads `'the Molten Deep'`.
  static String _inSentence(String name) =>
      name.startsWith('The ') ? 'the ${name.substring(4)}' : name;

  static ZoneAchievementNames _namesFor(GameLocation z) =>
      names[z.id] ??
      (throw StateError(
        'No achievement names for combat zone ${z.id} — add a row to '
        'CampaignAchievements.names',
      ));

  /// ⭐ Clear, Purge and Collector for every combat zone, zone by zone in
  /// world order.
  static final List<AchievementDef> zones = List.unmodifiable([
    for (final z in combatZones) ..._entriesFor(z),
  ]);

  static List<AchievementDef> _entriesFor(GameLocation z) {
    final n = _namesFor(z);
    final at = _inSentence(z.name);
    return [
      AchievementDef(
        id: 'clear_${z.id}',
        name: n.clear,
        blurb: '${z.name} cleared to its boss.',
        category: AchievementCategory.campaign,
        points: 10,
        earnedWhen: (p) => p.hasCleared(z.id),
      ),
      AchievementDef(
        id: 'purge_${z.id}',
        name: n.purge,
        blurb: 'Every creature of $at slain at least once.',
        category: AchievementCategory.campaign,
        points: 25,
        progress: (p) =>
            cappedProgress(slainIn(p, z.id), rosterOf(z.id).length),
      ),
      AchievementDef(
        id: 'collect_${z.id}',
        name: n.collect,
        blurb: 'Everything $at can drop, seen at least once.',
        category: AchievementCategory.campaign,
        points: 50,
        progress: (p) =>
            cappedProgress(seenIn(p, z.id), collectorDropsOf(z.id).length),
      ),
    ];
  }

  // ---- Capstones ---------------------------------------------------------

  static final theKnownWorld = AchievementDef(
    id: 'the_known_world',
    name: 'The Known World',
    blurb: 'Every zone cleared to its boss.',
    category: AchievementCategory.campaign,
    points: 100,
    progress: (p) => _zonesWhere((id) => p.hasCleared(id)),
  );

  static final extinction = AchievementDef(
    id: 'extinction',
    name: 'Extinction',
    blurb: 'Every creature in every zone slain at least once.',
    category: AchievementCategory.campaign,
    points: 100,
    hidden: true,
    progress: (p) => _zonesWhere((id) => _purged(p, id)),
  );

  static final nothingLeftToFind = AchievementDef(
    id: 'nothing_left_to_find',
    name: 'Nothing Left to Find',
    blurb: 'Everything every zone can drop, seen at least once.',
    category: AchievementCategory.campaign,
    points: 150,
    hidden: true,
    progress: (p) => _zonesWhere((id) => _collected(p, id)),
  );

  /// The capstones, after every zone's three.
  static final List<AchievementDef> capstones = List.unmodifiable([
    theKnownWorld,
    extinction,
    nothingLeftToFind,
  ]);

  /// How many of the [combatZones] pass [test], of all of them.
  static AchievementProgress _zonesWhere(bool Function(String id) test) =>
      cappedProgress(
        combatZones.where((z) => test(z.id)).length,
        combatZones.length,
      );
}
