import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

/// How a place is presented on the map.
///
/// Deliberately only three values — [WorldPlane] carries the genuinely new
/// distinction (world vs Empyrean), and the UI switches exhaustively on this
/// enum, so widening it is a breaking change rather than an additive one.
enum LocationKind {
  town,

  /// Open-air ground you traverse: woods, coasts, passes, deserts.
  route,

  /// Enclosed: caves, vaults, ruins, the Citadel. These want interior art.
  dungeon,
}

/// Which side of the Veil a place is on (WORLD_DESIGN §1.2, §2.4).
enum WorldPlane {
  /// Physical ground. Has an elevation, weather, and a moon.
  world,

  /// Above the Veil. No altitude, no weather, and **no moon** — Lunar's Full
  /// Moon bonus cannot fire here (WORLD_DESIGN §4.2).
  empyrean,
}

/// A place on the world map. The graph of [connections] is what travel walks;
/// there is no simulated terrain (design decision — menu-based travel only).
///
/// Source of truth: **[WORLD_DESIGN.md](../../docs/WORLD_DESIGN.md) and Plate I-b**
/// (`docs/plates/plate-1b-one-crossing.html`). Coordinates are not stored —
/// the plate holds the geometry, this holds the graph and the text.
/// How a road is travelled, which is not the same as how long it takes.
///
/// ⚠️ Kind exists before duration deliberately. Every edge draws as the same
/// dashed line today, so the **Galehaven–Tidewrack sea passage is
/// indistinguishable from a road** even though WORLD_DESIGN §2.5 makes it
/// design-significant. Kind is also what decides whether a leg can be walked
/// at all, once mounts and boats arrive (§4b.3–4b.4).
enum TravelEdgeKind {
  /// Overland. The default.
  road,

  /// Open water — the Galehaven–Tidewrack crossing.
  sea,

  /// Across the Veil, between the world and the Empyrean.
  veil,
}

/// One leg of the road network: where it goes, and what it costs.
///
/// ⭐ **Duration is the resource the whole trade economy is built on.** If
/// travel is free, nothing in WORLD_DESIGN §4b has any tension in it — no
/// reason to buy a mount, no profit in hauling goods, no cost to a bad route.
///
/// ✅ The baseline is **5 minutes** per leg (§4b.1): long enough that a mount
/// is worth buying, short enough that waiting it out stays a real choice.
/// Legs in the starting valley are shorter, the high country longer, and the
/// two crossings longer still.
@immutable
class TravelEdge {
  /// The location id this road leads to.
  final String to;

  /// The **authored** duration for this road, in minutes on foot.
  ///
  /// ⚠️ **Not what travel currently costs.** [TravelTimes] is the active
  /// policy and presently ignores this, charging a flat 1 minute a leg (3
  /// between towns). These numbers are kept because they carry design work a
  /// rule cannot: the starting valley has shorter legs, the high country
  /// longer ones, and the sea and Veil crossings cost more than any road.
  /// ⭐ Deleting them would lose that and it could not be recovered.
  final int minutes;

  final TravelEdgeKind kind;

  const TravelEdge(this.to, this.minutes, {this.kind = TravelEdgeKind.road});

  @override
  bool operator ==(Object other) =>
      other is TravelEdge &&
      other.to == to &&
      other.minutes == minutes &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(to, minutes, kind);

  @override
  String toString() => 'TravelEdge($to, ${minutes}m, ${kind.name})';
}

/// What a leg of travel actually costs — the **active policy**.
///
/// 📝 **Flat 3 minutes a leg, for now** (Christian, 2026-08-02). An earlier
/// pass tried 1 minute a leg with 3 between towns; ⚠️ **it did not survive
/// contact with the graph** — two ordinary legs undercut one town leg, so
/// cutting through a zone beat the direct road and the town cost almost never
/// applied. Parked rather than patched.
///
/// ⚠️ **[TravelEdge.minutes] is deliberately NOT consulted here.** It holds the
/// hand-authored per-road durations — the starting valley shorter, the high
/// country longer, the sea and Veil crossings longer still — which are kept
/// for when tuning resumes. ⭐ Two durations exist on purpose; this one wins,
/// and `travel_test.dart` asserts which.
abstract final class TravelTimes {
  /// ⭐ **The one knob.** Every leg of every journey costs this.
  ///
  /// 📝 **10 seconds while testing** — a real playthrough wants minutes, but
  /// waiting three of them to check a change is not a workflow. ⚠️ Put this
  /// back to `3 * 60` before anyone plays for real.
  static const int perLegSeconds = 10;

  /// The cost of the leg joining [fromId] and [toId], in seconds.
  ///
  /// Takes both endpoints even though it currently ignores them — ⭐ every
  /// rule worth trying next (by destination kind, by tier, by edge kind) needs
  /// them, and threading them later would touch the solver again.
  static int secondsBetween(String fromId, String toId) => perLegSeconds;

  /// Whole minutes, rounded up, for anything that still counts in minutes.
  ///
  /// ⚠️ Never 0 — a leg that reads as free is worse than one that reads as
  /// slow.
  static int between(String fromId, String toId) {
    final secs = secondsBetween(fromId, toId);
    return secs == 0 ? 0 : ((secs / 60).ceil()).clamp(1, 1 << 30);
  }

  /// A human label for [seconds] — "10s", "3 min", "1h 05m".
  ///
  /// ⭐ One formatter, so a 10-second test build does not display "0 min"
  /// everywhere and look broken.
  static String label(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()} min';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class GameLocation {
  final String id;
  final String name;
  final LocationKind kind;
  final WorldPlane plane;

  /// One line, for the map and travel screens.
  final String blurb;

  /// Shown on first arrival. Second person, present tense, no exposition about
  /// game systems. First-draft copy — see WORLD_DESIGN §6.
  final String arrival;

  /// Shown when the zone's boss falls.
  ///
  /// ⭐ **Arrival poses the question; the epilogue answers it** (GAME_DESIGN
  /// §5). [arrival] deliberately resolves nothing; this delivers the thing the
  /// zone was there to teach. Same voice — second person, present tense, no
  /// exposition about game systems.
  ///
  /// ⚠️ **Must not close the zone off.** Zones are re-run for materials and
  /// for Purge, so an epilogue that kills the place for good contradicts the
  /// next visit.
  final String? epilogue;

  /// One line per section of a run, shown as the player crosses into it.
  ///
  /// ⭐ **This is how a zone tells a story at the pace it is played.** A run is
  /// three sections (GAME_DESIGN §3d), so a realisation can *dawn* — pleasant,
  /// then off, then undeniable — instead of arriving all at once in the
  /// epilogue. Whispering Woods is the case that demanded it: the beat is
  /// slowly noticing something is wrong, and that cannot be one paragraph.
  ///
  /// ⚠️ Up to three, matching the section count. Shorter than [arrival] —
  /// these interrupt a run, so they are a sentence, not a passage.
  final List<String> beats;

  /// Elemental flavour of the monsters found here (empty for towns). One
  /// element for a pure zone, two for a hybrid, all twelve for the Citadel.
  final List<MagicElement> elements;

  /// Which tier's band this belongs to. Towns carry their tier too.
  final MagicTier? tier;

  /// ⚠️ **Enemy** level, not a requirement (GAME_DESIGN §5). The UI must make
  /// that unmistakable or players read "58-60" as "come back at 58".
  final int minLevel;
  final int maxLevel;

  /// The one crafting skill practised here, if any. Decentralised on purpose:
  /// each town is the *only* place its skill can be learned, until Zenith.
  final String? station;

  /// What must be assembled to pass, if this place is a tier gate.
  final String? gate;

  /// The level this place tends to open up at. Towns only; `null` elsewhere.
  final int? opensAtLevel;

  /// Roads out of here, with what each one costs to walk.
  ///
  /// ⚠️ **Bidirectional, and symmetric in duration** — guarded by
  /// `test/world_test.dart`. A road that is quicker one way than the other is
  /// a design decision nobody has made.
  final List<TravelEdge> edges;

  /// Ids of directly reachable locations.
  ///
  /// Derived from [edges] rather than stored, so adjacency and duration
  /// cannot disagree. Everything that only cares *where* you can go reads
  /// this; everything that cares *what it costs* reads [edges].
  List<String> get connections => [for (final e in edges) e.to];

  /// The road to [id], or null if there is none.
  TravelEdge? edgeTo(String id) {
    for (final e in edges) {
      if (e.to == id) return e;
    }
    return null;
  }

  /// One-way teleport destinations. Zenith alone has these; the return trip
  /// is not modelled yet because it needs the Crown check.
  final List<String> teleportsTo;

  const GameLocation({
    required this.id,
    required this.name,
    required this.kind,
    required this.blurb,
    required this.arrival,
    this.epilogue,
    this.beats = const [],
    required this.edges,
    this.plane = WorldPlane.world,
    this.elements = const [],
    this.tier,
    this.minLevel = 0,
    this.maxLevel = 0,
    this.station,
    this.gate,
    this.opensAtLevel,
    this.teleportsTo = const [],
  });

  bool get isTown => kind == LocationKind.town;

  /// Non-town locations host adventures (a duel encounter in Phase 1).
  bool get hasAdventure => kind != LocationKind.town;

  /// The enemy level band, phrased so it cannot be misread.
  ///
  /// ⚠️ One owner for this string. "Lv 58-60" on its own reads as a
  /// *requirement* — players see "come back at 58" and never return
  /// (GAME_DESIGN §5). Every surface that shows a level band reads this, and
  /// `test/world_map_test.dart` fails the build if one builds its own.
  String get enemyBandLabel => 'Enemies Lv $minLevel–$maxLevel';

  /// A hybrid zone teaches the matchup of the two elements that meet there.
  bool get isHybrid => elements.length == 2;

  /// Thin Air applies across the Celestial shelf (WORLD_DESIGN §4.1).
  bool get hasThinAir =>
      tier == MagicTier.celestial && plane == WorldPlane.world;

  /// No moon above the Veil, so Lunar's Full Moon bonus never fires.
  bool get hasMoon => plane == WorldPlane.world;
}

/// The world, rebuilt from Plate I-b.
///
/// Shape: a southern basin rising through the Ironspine to the Celestial
/// shelf, then the climb up **The Vault**. The route leaves the world at
/// Vespergate, crosses the **Empyrean**, and re-enters at the summit through
/// the Eclipsed Citadel — ⭐ **the summit is never climbed.**
abstract final class World {
  static const String startLocationId = 'hearthwood';

  /// Every town, in the order the campaign meets them. Zenith's teleport net
  /// is built from this.
  static const List<String> townIds = [
    'hearthwood',
    'pennycross',
    'forgeholm',
    'galehaven',
    'concordance',
    'meridian',
    'rimeholt',
    'vespergate',
    'zenith',
  ];

  static const List<GameLocation> locations = [
    // ---------------------------------------------------------------
    // Primal — the basin · Lv 1-14 · 0-1 000 m
    // ---------------------------------------------------------------
    GameLocation(
      id: 'hearthwood',
      name: 'Hearthwood',
      kind: LocationKind.town,
      tier: MagicTier.primal,
      opensAtLevel: 1,
      station: 'Woodcarving',
      gate: 'Three ordinary proofs, shown to the guard on the north road',
      blurb: 'A wooded river valley where every mage begins.',
      arrival:
          'Alders lean over the water, and the whole valley smells of wet '
          'bark and woodsmoke. Someone is sharpening something. Nobody looks '
          'up when you pass, which is its own kind of welcome.',
      edges: [
        TravelEdge('whispering_woods', 3),
        TravelEdge('glimmerbrook', 3),
        TravelEdge('thornmire', 3),
        TravelEdge('cinderpeak_foothills', 3),
        TravelEdge('pennycross', 3),
      ],
    ),
    GameLocation(
      id: 'whispering_woods',
      name: 'Whispering Woods',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      elements: [MagicElement.flora],
      minLevel: 1,
      maxLevel: 5,
      blurb: 'Sun-dappled woods that murmur when nothing is moving them.',
      // ⚠️ **Opens pleasant on purpose.** The zone's beat is slowly realising
      // something is wrong, so the first impression must be a nice wood with
      // exactly one thing off — not a warning.
      arrival:
          'Sun comes down through the leaves in pieces and moves when they '
          'move. It is a good path, well walked, and the air smells of warm '
          'bark. Somewhere under it all, something is murmuring.',
      // ⭐ Paced across the run's three sections: pleasant, off, undeniable.
      beats: [
        'The murmur stops the moment you stand still to listen. When you '
            'walk on, it starts again.',
        'You have passed this bend before. The path has not looped — you '
            'have been watching for that. The trees have moved.',
        'It is not coming from the trees. It is coming from underneath '
            'them, from the roots crossing beneath the path, and it is all one '
            'sound. You have been walking on it this whole time.',
      ],
      // ⭐ The quarter's first lesson, paid off: an element can be AWARE.
      // ⚠️ Nothing dies here — the network moves. The wood is still the wood
      // when you come back for oak.
      epilogue:
          'The murmur does not stop when the heartwood comes down. It moves '
          '— under the path, out toward the edges, somewhere you cannot walk '
          'to — and settles there. You did not kill anything. You '
          'interrupted something, and it noticed you doing it.',
      edges: [
        TravelEdge('hearthwood', 3),
        TravelEdge('thornmire', 3),
        TravelEdge('ashfall_vale', 3),
      ],
    ),
    GameLocation(
      id: 'glimmerbrook',
      name: 'Glimmerbrook',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      elements: [MagicElement.aqua],
      minLevel: 3,
      maxLevel: 8,
      blurb: 'Springs and shallows east of Hearthwood, bright enough to hurt.',
      arrival:
          'The brook runs over pale stones and throws the light back at '
          'you in pieces. Fish hang in the current without swimming. The water '
          'is colder than the season should allow.',
      edges: [
        TravelEdge('hearthwood', 3),
        TravelEdge('thornmire', 3),
        TravelEdge('pennycross', 3),
      ],
    ),
    GameLocation(
      id: 'cinderpeak_foothills',
      name: 'Cinderpeak Foothills',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      elements: [MagicElement.pyro],
      minLevel: 6,
      maxLevel: 11,
      blurb:
          'The first rise north, where the ground is warm through your boots.',
      arrival:
          'The grass gives out and the slope turns to grey grit that '
          'shifts under you. Somewhere above, the mountain is breathing. The '
          'air tastes of struck flint.',
      // ⚠️ **No shortcut to Forgeholm from here.** This edge used to exist
      // and it let a level-11 player skip the climb; the way into the range
      // is the Old Quarry, and there is no second way.
      edges: [
        TravelEdge('hearthwood', 3),
        TravelEdge('ashfall_vale', 3),
        TravelEdge('the_molten_deep', 5),
      ],
    ),
    GameLocation(
      id: 'thornmire',
      name: 'Thornmire',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      // Flora ▸ Aqua — the delta where the woods drown in the brook's outflow.
      elements: [MagicElement.flora, MagicElement.aqua],
      minLevel: 8,
      maxLevel: 13,
      blurb: "Where the woods drown in the brook's outflow.",
      arrival:
          'The path becomes a suggestion, then a rumour, then water. '
          'Trees stand in it up to their knees and have made peace with that. '
          'Everything green here is winning.',
      edges: [
        TravelEdge('hearthwood', 3),
        TravelEdge('whispering_woods', 3),
        TravelEdge('glimmerbrook', 3),
      ],
    ),
    GameLocation(
      id: 'ashfall_vale',
      name: 'Ashfall Vale',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      // Pyro ▸ Flora — downwind of the cone, where ash falls on forest.
      elements: [MagicElement.pyro, MagicElement.flora],
      minLevel: 10,
      maxLevel: 14,
      blurb: 'Downwind of the cone: the burn scar where ash falls on forest.',
      arrival:
          'Grey settles on every leaf until the whole valley looks like a '
          'charcoal drawing of itself. New shoots are already pushing up '
          'through it. Fire came through here, and something is arguing about '
          'whether it won.',
      edges: [
        TravelEdge('whispering_woods', 3),
        TravelEdge('cinderpeak_foothills', 3),
      ],
    ),
    GameLocation(
      id: 'pennycross',
      name: 'Pennycross',
      kind: LocationKind.town,
      tier: MagicTier.primal,
      opensAtLevel: 8,
      station: 'Tailoring',
      blurb:
          'The first market, where the river road crosses the mountain road.',
      arrival:
          'Two roads meet and a town happened. Stalls have grown into '
          'buildings, and the buildings still look like stalls. Everyone is '
          'halfway through a transaction.',
      edges: [
        TravelEdge('hearthwood', 3),
        TravelEdge('glimmerbrook', 3),
        TravelEdge('old_quarry', 4),
      ],
    ),

    // ---------------------------------------------------------------
    // Kinetic — the range · Lv 15-29 · -400-2 500 m
    // ---------------------------------------------------------------
    GameLocation(
      id: 'forgeholm',
      name: 'Forgeholm',
      kind: LocationKind.town,
      tier: MagicTier.kinetic,
      opensAtLevel: 15,
      station: 'Metalworking',
      blurb: 'A city with a mountain for a roof, cut into the Ironspine.',
      arrival:
          'You arrive at a door. The road ends at a gate in the rock and '
          'everything past it was cut rather than built — halls stacked over '
          'halls, stairs where a street would be, and a red glow a long way '
          'down that never goes out. Ore does not leave here until it has a '
          'name. It is never quiet and never cold.',
      // ⭐ **One road in from the south, through the quarry.** Everything
      // deeper in the range hangs off the city, so Forgeholm is passed
      // THROUGH rather than visited — which is what makes it a gate.
      edges: [
        TravelEdge('old_quarry', 5),
        TravelEdge('thunderspire_peaks', 5),
      ],
    ),
    GameLocation(
      id: 'old_quarry',
      name: 'Old Quarry',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.geo],
      minLevel: 15,
      maxLevel: 19,
      blurb: "Cut into the range's southern flank, and cut too deep.",
      arrival:
          'The road stops being a road and becomes the floor of something '
          'somebody dug. Terraces step down into shadow, each one squarer '
          'than anything nature makes, and the tool marks are old. Whatever '
          'was quarried out of here left a shape, and the shape has started '
          'to move.',
      // ⭐ **The way into the mountains, and the only one.** The road north
      // from Pennycross runs through the quarry, and Forgeholm is on the far
      // side of it — so the first Kinetic zone is the door to the quarter.
      edges: [
        TravelEdge('pennycross', 4),
        TravelEdge('forgeholm', 5),
        TravelEdge('the_molten_deep', 5),
      ],
    ),
    GameLocation(
      id: 'stormcliff_coast',
      name: 'Stormcliff Coast',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.electro],
      minLevel: 17,
      maxLevel: 22,
      blurb:
          "Where the western ocean's weather hits a wall and has nowhere "
          'to go.',
      arrival:
          'The cliffs take the whole weight of it. Spray comes up further '
          'than it should and your hair lifts before you hear the crack. The '
          'rock is scorched in long vertical lines.',
      edges: [TravelEdge('thunderspire_peaks', 5), TravelEdge('galehaven', 5)],
    ),
    GameLocation(
      id: 'galehaven',
      name: 'Galehaven',
      kind: LocationKind.town,
      tier: MagicTier.kinetic,
      opensAtLevel: 22,
      station: 'Potions and Alchemy',
      blurb: 'The one notch in a hundred miles of cliff.',
      arrival:
          'The harbour is impossibly calm for what is happening outside '
          'it. Cloth and dye come off the boats in bales; nothing here is made '
          'locally except the ships.',
      // ⭐ The sea passage to Tidewrack Shoals is the port's endgame purpose.
      edges: [
        TravelEdge('stormcliff_coast', 5),
        TravelEdge('frostfell_pass', 5),
        TravelEdge('tidewrack_shoals', 12, kind: TravelEdgeKind.sea),
      ],
    ),
    GameLocation(
      id: 'windward_steppe',
      name: 'Windward Steppe',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.aero],
      minLevel: 19,
      maxLevel: 24,
      blurb: 'A high tableland east of the crest, scoured flat.',
      arrival:
          'Nothing here is taller than your knee, and everything leans '
          'the same way. The wind does not gust; it simply blows, and has been '
          'blowing since before there was anyone to notice.',
      edges: [
        TravelEdge('thunderspire_peaks', 5),
        TravelEdge('frostfell_pass', 5),
        TravelEdge('concordance', 5),
      ],
    ),
    GameLocation(
      id: 'frostfell_pass',
      name: 'Frostfell Pass',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      // Ice: sea moisture lifted over the crest by steppe wind, and frozen.
      elements: [MagicElement.aqua, MagicElement.aero],
      minLevel: 21,
      maxLevel: 26,
      blurb: 'The way through. Sea air lifted over the crest and frozen there.',
      arrival:
          'The pass is a white corridor between two black walls. Your '
          'breath goes up and does not come down. The road is under here '
          'somewhere, and other people have been sure of that too.',
      edges: [
        TravelEdge('thunderspire_peaks', 5),
        TravelEdge('windward_steppe', 5),
        TravelEdge('galehaven', 5),
        TravelEdge('concordance', 5),
      ],
    ),
    GameLocation(
      id: 'thunderspire_peaks',
      name: 'Thunderspire Peaks',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      // Electro ▸ Aero — where coastal storm meets steppe wind.
      elements: [MagicElement.electro, MagicElement.aero],
      minLevel: 23,
      maxLevel: 28,
      blurb: 'The summit line where coastal storm meets steppe wind.',
      arrival:
          'You are inside the weather rather than under it. The cloud is '
          'lit from within at intervals, and the intervals are getting '
          'shorter. Metal hums.',
      edges: [
        TravelEdge('forgeholm', 5),
        TravelEdge('stormcliff_coast', 5),
        TravelEdge('windward_steppe', 5),
        TravelEdge('frostfell_pass', 5),
      ],
    ),
    GameLocation(
      id: 'the_molten_deep',
      name: 'The Molten Deep',
      kind: LocationKind.dungeon,
      tier: MagicTier.kinetic,
      elements: [MagicElement.pyro, MagicElement.geo],
      minLevel: 25,
      maxLevel: 29,
      blurb: "Under the quarry, under the mountain, under the sea's level.",
      arrival:
          "The quarry's deepest gallery keeps going after the tool marks "
          'stop. The rock gets warm, then hot, then lit from below. There is a '
          'floor down here that moves like water because it is not water.',
      edges: [
        TravelEdge('old_quarry', 5),
        TravelEdge('cinderpeak_foothills', 5),
      ],
    ),

    // ---------------------------------------------------------------
    // Celestial — the high shelf · Lv 30-44 · 1 700-2 700 m
    // ⚠️ Thin Air applies across this band (WORLD_DESIGN §4.1).
    // ---------------------------------------------------------------
    GameLocation(
      id: 'concordance',
      name: 'Concordance',
      kind: LocationKind.town,
      tier: MagicTier.celestial,
      opensAtLevel: 30,
      gate: 'The Kinetic Sigil, in three parts, shown at the gate',
      // ⭐ No crafting station on purpose — value MOVES here, it is not made.
      blurb:
          'The trade capital, at the head of navigation on the River Concord.',
      arrival:
          'Everything that moves by water or road in this world passes '
          'through here, and the city has arranged itself around that fact. '
          'You show your Sigil at the gate. Nobody fights you; someone writes '
          'your name down.',
      edges: [
        TravelEdge('frostfell_pass', 5),
        TravelEdge('windward_steppe', 5),
        TravelEdge('the_kiln_desert', 5),
        TravelEdge('the_mirrormere', 6),
        TravelEdge('meridian', 5),
      ],
    ),
    GameLocation(
      id: 'the_kiln_desert',
      name: 'The Kiln Desert',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      elements: [MagicElement.solar],
      minLevel: 30,
      maxLevel: 34,
      blurb:
          "A cold high desert in the range's rain shadow, and the sunniest "
          'ground in the world.',
      arrival:
          'The air is too thin to hold heat, so the sun burns while the '
          'wind bites. There is no shade anywhere and no water for a day\'s '
          'walk. Your shadow is the hardest-edged thing you have ever seen.',
      edges: [
        TravelEdge('concordance', 5),
        TravelEdge('meridian', 5),
        TravelEdge('the_sunless_reach', 6),
      ],
    ),
    GameLocation(
      id: 'the_mirrormere',
      name: 'The Mirrormere',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      elements: [MagicElement.lunar],
      minLevel: 32,
      maxLevel: 37,
      blurb: 'A high still lake that holds the moon better than the sky does.',
      arrival:
          'Not a ripple. The surface gives you back the mountains, the '
          'stars, and the moon at a size the moon has no right to be. Walking '
          'the shore, you are careful not to look down for too long.',
      edges: [
        TravelEdge('concordance', 6),
        TravelEdge('meridian', 6),
        TravelEdge('tidewrack_shoals', 6),
        TravelEdge('the_sunless_reach', 6),
        TravelEdge('rimeholt', 6),
      ],
    ),
    GameLocation(
      id: 'starfall_basin',
      name: 'Starfall Basin',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      elements: [MagicElement.astral],
      minLevel: 34,
      maxLevel: 39,
      blurb: 'A crater field, preserved because nothing grows to cover it.',
      arrival:
          'Bowl after bowl in the pale ground, each with something at the '
          'bottom that is not from here. Nothing has grown over them because '
          'nothing grows. At night the sky is so clear it looks like a threat.',
      edges: [TravelEdge('meridian', 6), TravelEdge('the_shattered_orrery', 6)],
    ),
    GameLocation(
      id: 'meridian',
      name: 'Meridian',
      kind: LocationKind.town,
      tier: MagicTier.celestial,
      opensAtLevel: 36,
      station: 'Enchanting',
      blurb:
          'An observatory on the crest of the Scarp: the highest dark-sky '
          'ground there is.',
      arrival:
          'A town of long roofs that open. Everyone keeps different hours '
          'and nobody explains. From the crest you can see the desert on one '
          'side and, on the other, a valley with no light in it at all.',
      edges: [
        TravelEdge('concordance', 5),
        TravelEdge('the_kiln_desert', 5),
        TravelEdge('the_mirrormere', 6),
        TravelEdge('starfall_basin', 6),
        TravelEdge('the_sunless_reach', 6),
        TravelEdge('rimeholt', 6),
      ],
    ),
    GameLocation(
      id: 'tidewrack_shoals',
      name: 'Tidewrack Shoals',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      elements: [MagicElement.lunar, MagicElement.aqua],
      minLevel: 36,
      maxLevel: 40,
      blurb: 'Tides that obey the moon exactly, on the northern shore.',
      arrival:
          'The water goes out further than seems survivable and comes '
          'back faster. What it uncovers has been down there a long time. '
          'Everything is timed to something overhead.',
      edges: [
        TravelEdge('galehaven', 12, kind: TravelEdgeKind.sea),
        TravelEdge('the_mirrormere', 6),
      ],
    ),
    GameLocation(
      id: 'the_sunless_reach',
      name: 'The Sunless Reach',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      // Solar ▸ Lunar — the Scarp's shadowed north face.
      elements: [MagicElement.solar, MagicElement.lunar],
      minLevel: 38,
      maxLevel: 42,
      blurb: "The Scarp's north face. Direct sun never reaches the floor.",
      arrival:
          'You come over the crest out of glare into a valley that has '
          'never been lit. The rock is the same rock. The desert is a thousand '
          'feet away and on the other side of the world.',
      edges: [
        TravelEdge('meridian', 6),
        TravelEdge('the_kiln_desert', 6),
        TravelEdge('the_mirrormere', 6),
      ],
    ),
    GameLocation(
      id: 'the_shattered_orrery',
      name: 'The Shattered Orrery',
      kind: LocationKind.dungeon,
      tier: MagicTier.celestial,
      // ⚠️ Its lightning is mechanical, not meteorological.
      elements: [MagicElement.astral, MagicElement.electro],
      minLevel: 40,
      maxLevel: 44,
      blurb: 'A broken model of the heavens, still trying to run.',
      arrival:
          'Rings the size of bridges, half of them fallen, and the fallen '
          'half still turning. The arcing is not weather; it is the mechanism. '
          'Something is being calculated and has been for a very long time.',
      edges: [
        TravelEdge('starfall_basin', 6),
        TravelEdge('the_glass_archive', 7),
      ],
    ),

    // ---------------------------------------------------------------
    // Ethereal — the climb up The Vault · Lv 45-60 · 2 900-5 200 m
    // ⚠️ Enemies out-level you by up to ten; gear closes the gap, not XP.
    // Everything in this band is above the tree line.
    // ---------------------------------------------------------------
    GameLocation(
      id: 'rimeholt',
      name: 'Rimeholt',
      kind: LocationKind.town,
      tier: MagicTier.ethereal,
      opensAtLevel: 45,
      station: 'Jewelry',
      gate:
          'A Celestial Totem charged with the Solar, Lunar and Astral '
          'essences, to pass the barrier above the town',
      blurb: 'Basecamp. The last mortal outpost, above the tree line.',
      arrival:
          'There is no wood here, so nothing is built of it. The town is '
          'stone and rope and hide, dug in against a slope that goes up out of '
          'sight. Everyone you meet is either arriving or leaving; nobody is '
          'from here.',
      edges: [
        TravelEdge('meridian', 6),
        TravelEdge('the_mirrormere', 6),
        TravelEdge('hallowmarch', 6),
      ],
    ),
    GameLocation(
      id: 'hallowmarch',
      name: 'Hallowmarch',
      kind: LocationKind.route,
      tier: MagicTier.ethereal,
      elements: [MagicElement.sanctus],
      minLevel: 45,
      maxLevel: 49,
      // 📝 Not a marsh — *march* in the older borderland sense.
      blurb:
          "The Vault's south flank: a consecrated causeway up the only side "
          'that thaws.',
      arrival:
          'A raised road, and someone built it. The sun reaches this face '
          'for a few hours and the meltwater runs beside you the whole way. '
          'Every mile or so there is a marker, and every marker has been '
          'maintained.',
      edges: [
        TravelEdge('rimeholt', 6),
        TravelEdge('the_reliquary_deep', 8),
        TravelEdge('vespergate', 6),
        TravelEdge('the_sealed_garden', 6),
      ],
    ),
    GameLocation(
      id: 'the_umbral_wastes',
      name: 'The Umbral Wastes',
      kind: LocationKind.route,
      tier: MagicTier.ethereal,
      elements: [MagicElement.umbra],
      minLevel: 47,
      maxLevel: 51,
      blurb: "The Vault's north face. No direct sun at any hour of any day.",
      arrival:
          'You round the shoulder and the light stops. Not dusk — an '
          'absence with an edge to it. The ice here has never melted and holds '
          'its shape like something that has been thought about.',
      // Reached through the Reliquary, or over the upper icefall to Vespergate.
      edges: [TravelEdge('the_reliquary_deep', 8), TravelEdge('vespergate', 8)],
    ),
    GameLocation(
      id: 'the_reliquary_deep',
      name: 'The Reliquary Deep',
      kind: LocationKind.dungeon,
      tier: MagicTier.ethereal,
      // Sanctus ▸ Umbra — bored through the rock from the lit face to the dark.
      elements: [MagicElement.sanctus, MagicElement.umbra],
      minLevel: 52,
      maxLevel: 56,
      blurb:
          'A vault bored through the mountain from the lit side to the dark.',
      arrival:
          'The door is on the warm flank and the far end opens onto the '
          'ice. In between, a corridor that someone consecrated and someone '
          'else did not leave alone. It is warmer in the middle than at either '
          'end.',
      edges: [TravelEdge('hallowmarch', 8), TravelEdge('the_umbral_wastes', 8)],
    ),
    GameLocation(
      id: 'vespergate',
      name: 'Vespergate',
      kind: LocationKind.town,
      tier: MagicTier.ethereal,
      opensAtLevel: 50,
      blurb: 'Where the ground runs out. The last place with a supply line.',
      arrival:
          'A fortress at the top of the world, facing the wrong way — not '
          'outward at an enemy but upward, at nothing. Above it the rock goes '
          'vertical and stops being a route. They have been brewing their own '
          'everything for a long time.',
      // ⭐ The only door out of the world. The last pitch cannot be climbed,
      // so there is no connection from here to zenith.
      edges: [
        TravelEdge('hallowmarch', 6),
        TravelEdge('the_umbral_wastes', 8),
        TravelEdge('the_buried_sky', 8),
        TravelEdge('the_collapsed_academy', 12, kind: TravelEdgeKind.veil),
      ],
    ),

    // ⭐ Two late hybrids that reach BACK for under-used elements
    // (WORLD_DESIGN §4c). Both pair an Ethereal-band level range with
    // elements from earlier tiers — deliberate, and the reason they exist:
    // without them Flora ends at 14 and Geo at 29.
    GameLocation(
      id: 'the_sealed_garden',
      name: 'The Sealed Garden',
      kind: LocationKind.route,
      tier: MagicTier.ethereal,
      // ⭐ The game's FIRST element guarded by its LAST. Flora is where the
      // player started; Sanctus is where they are now.
      elements: [MagicElement.flora, MagicElement.sanctus],
      minLevel: 49,
      maxLevel: 53,
      blurb: 'A garden nobody has been let into for a very long time.',
      arrival:
          'The wall is low enough to see over and that is the whole '
          'cruelty of it. Inside, everything is in leaf and in season at '
          'once. The gate is shut, the guard is still at the gate, and the '
          'faith that posted him has been gone for centuries.',
      // ⭐ Hallowmarch's causeway was built to reach HERE — which is why its
      // markers are still maintained by an order that no longer exists.
      edges: [TravelEdge('hallowmarch', 6)],
    ),
    GameLocation(
      id: 'the_glass_archive',
      name: 'The Glass Archive',
      kind: LocationKind.dungeon,
      tier: MagicTier.celestial,
      // ⭐ Solar's side-effect is Blind and Arcane's is Arcane Knowledge, so
      // the theme falls out of the pairing rather than being imposed on it:
      // too bright to read, too much to know.
      elements: [MagicElement.solar, MagicElement.arcane],
      minLevel: 43,
      maxLevel: 47,
      blurb: 'They wrote it in light, and light does not keep.',
      arrival:
          'Lenses on every roof, and all of them still aimed. Around '
          'midday the hillside fills with writing you can almost read, and by '
          'the time your eyes adjust it has moved on. Whatever they recorded '
          'here, they recorded onto the one thing that will not hold still.',
      // ⭐ Below the Rimeholt barrier on purpose — this is where a player
      // grinds out the Celestial Totem that gets them past it.
      edges: [TravelEdge('the_shattered_orrery', 7)],
    ),
    GameLocation(
      id: 'the_buried_sky',
      name: 'The Buried Sky',
      kind: LocationKind.dungeon,
      tier: MagicTier.ethereal,
      elements: [MagicElement.geo, MagicElement.astral],
      minLevel: 46,
      maxLevel: 50,
      blurb: 'The oldest rock in the world, and it is full of stars.',
      arrival:
          'You climb to the top of everything in order to go down. The '
          'shaft cuts through band after band of stone, and every band holds '
          'a scatter of light in it. None of the patterns match the sky you '
          'walked in under.',
      edges: [TravelEdge('vespergate', 8)],
    ),

    // ---------------------------------------------------------------
    // The Empyrean — above the Veil · no elevation, no weather, no moon
    // ---------------------------------------------------------------
    GameLocation(
      id: 'the_collapsed_academy',
      name: 'The Collapsed Academy',
      kind: LocationKind.dungeon,
      plane: WorldPlane.empyrean,
      tier: MagicTier.ethereal,
      elements: [MagicElement.arcane],
      minLevel: 50,
      maxLevel: 54,
      blurb: 'A school that read too far, and left.',
      arrival:
          'It is not ruined so much as unfinished in the wrong direction. '
          'Staircases arrive at rooms that were never built. The syllabus is '
          'still on the wall and the last three items on it are not in any '
          'language you have.',
      edges: [
        TravelEdge('vespergate', 12, kind: TravelEdgeKind.veil),
        TravelEdge('the_unwritten_library', 8),
      ],
    ),
    GameLocation(
      id: 'the_unwritten_library',
      name: 'The Unwritten Library',
      kind: LocationKind.dungeon,
      plane: WorldPlane.empyrean,
      tier: MagicTier.ethereal,
      // Umbra ▸ Arcane.
      elements: [MagicElement.umbra, MagicElement.arcane],
      minLevel: 54,
      maxLevel: 58,
      blurb: 'Knowledge that eats its keeper. The shelves are still filling.',
      arrival:
          'Every book here is being written right now, by nobody. The '
          'shelves go up past where a ceiling would be. Something is taking '
          'dictation and it would like your name for the record.',
      edges: [
        TravelEdge('the_collapsed_academy', 8),
        TravelEdge('the_eclipsed_citadel', 8),
      ],
    ),
    GameLocation(
      id: 'the_eclipsed_citadel',
      name: 'The Eclipsed Citadel',
      kind: LocationKind.dungeon,
      plane: WorldPlane.empyrean,
      tier: MagicTier.ethereal,
      // ⭐ All twelve at once — no five-slot loadout counters everything, so it
      // tests whether you can adapt rather than specialise.
      elements: MagicElement.values,
      minLevel: 58,
      maxLevel: 60,
      gate: 'Three Ethereal key fragments',
      blurb: 'The door back into the world, and the thing standing in it.',
      arrival:
          'Below it, through a gap in nothing, is the summit of the '
          'mountain you could not climb. The Citadel is between you and it. '
          'That is what the name has always meant.',
      // ⭐ The way back IN. Beyond it: the summit, and Zenith.
      edges: [
        TravelEdge('the_unwritten_library', 8),
        TravelEdge('zenith', 12, kind: TravelEdgeKind.veil),
      ],
    ),

    // ---------------------------------------------------------------
    // The summit — back in the world, entered from above
    // ---------------------------------------------------------------
    GameLocation(
      id: 'zenith',
      name: 'Zenith',
      kind: LocationKind.town,
      tier: MagicTier.ethereal,
      opensAtLevel: 60,
      station: 'Every station — the only town with all six',
      gate:
          'The Concordant Crown: twelve elemental gems and twelve Cores, '
          'bound with a purchased binding spell',
      blurb: 'The summit. Visible from everywhere below, and shut.',
      arrival:
          'The doors were never locked from the inside. From up here the '
          'whole world is one thing, and every city you have ever walked into '
          'is a mark on it you could put a finger over.',
      // Reached only through the Citadel — the last pitch cannot be climbed.
      edges: [
        TravelEdge('the_eclipsed_citadel', 12, kind: TravelEdgeKind.veil),
      ],
      // ⭐ Line of sight to everywhere is why the teleport net exists at all.
      // One-way for now: the return trip needs a Crown check that is unbuilt.
      teleportsTo: [
        'hearthwood',
        'pennycross',
        'forgeholm',
        'galehaven',
        'concordance',
        'meridian',
        'rimeholt',
        'vespergate',
      ],
    ),
  ];

  static final Map<String, GameLocation> _byId = {
    for (final l in locations) l.id: l,
  };

  /// ⚠️ Falls back to the start location for an unknown id rather than
  /// throwing — a bad id must never crash the app on load.
  static GameLocation byId(String id) => _byId[id] ?? locations.first;

  /// Whether an id names a real place. [byId] falls back to the first
  /// location, so callers that must distinguish "missing" ask this.
  static bool exists(String id) => _byId.containsKey(id);

  static Iterable<GameLocation> get towns => locations.where((l) => l.isTown);

  static Iterable<GameLocation> inTier(MagicTier tier) =>
      locations.where((l) => l.tier == tier);

  /// Zones whose bestiary features [element]. A pure zone is the best source of
  /// its element's motes; a hybrid drops both of its parents'.
  static Iterable<GameLocation> withElement(MagicElement element) =>
      locations.where((l) => l.elements.contains(element));

  /// A themed opponent name for an adventure at [location].
  static String opponentNameFor(GameLocation location) {
    const byId = <String, String>{
      // Primal
      'whispering_woods': 'Thornback Sprite',
      'glimmerbrook': 'Brook Naiad',
      'cinderpeak_foothills': 'Ashjaw Brute',
      'thornmire': 'Mirewalker',
      'ashfall_vale': 'Cinderbloom Husk',
      // Kinetic
      'old_quarry': 'Quarry Golem',
      'stormcliff_coast': 'Stormcliff Tidecaller',
      'windward_steppe': 'Steppe Harrier',
      'frostfell_pass': 'Rime Stalker',
      'thunderspire_peaks': 'Stormcrest Roc',
      'the_molten_deep': 'Molten Warden',
      // Celestial
      'the_kiln_desert': 'Sunstruck Pilgrim',
      'the_mirrormere': 'Mirror Wraith',
      'starfall_basin': 'Crater Revenant',
      'tidewrack_shoals': 'Tidewrack Drowned',
      'the_sunless_reach': 'Eclipse Herald',
      'the_shattered_orrery': 'Orrery Automaton',
      // Ethereal — the climb
      'hallowmarch': 'Causeway Warden',
      'the_umbral_wastes': 'Umbral Devourer',
      'the_reliquary_deep': 'Reliquary Keeper',
      'the_sealed_garden': 'Orchard Warden',
      'the_buried_sky': 'Stratum Warden',
      'the_glass_archive': 'Glasswright',
      // The Empyrean
      'the_collapsed_academy': 'Unfinished Scholar',
      'the_unwritten_library': 'The Dictating Hand',
      'the_eclipsed_citadel': 'Procarius, the Eclipsed',
    };
    return byId[location.id] ?? 'Wandering Mage';
  }
}
