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
/// Source of truth: **[WORLD_DESIGN.md](../../WORLD_DESIGN.md) and Plate I-b**
/// (`docs/plates/plate-1b-one-crossing.html`). Coordinates are not stored —
/// the plate holds the geometry, this holds the graph and the text.
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

  /// Elemental flavour of the monsters found here (empty for towns). One
  /// element for a pure zone, two for a hybrid, all twelve for the Citadel.
  final List<MagicElement> elements;

  /// Which tier's band this belongs to. Towns carry their tier too.
  final MagicTier? tier;

  /// ⚠️ **Enemy** level, not a requirement (GAME_DESIGN §5). The UI must make
  /// that unmistakable or players read "58-60" as "come back at 58".
  final int minLevel;
  final int maxLevel;

  /// Metres above sea level. `null` above the Veil, where altitude stops
  /// meaning anything. ⚠️ Elevation is **not** difficulty (WORLD_DESIGN §3.2)
  /// — Tidewrack Shoals is a Lv 36-40 zone at 20 m.
  final int? elevationMetres;

  /// The one crafting skill practised here, if any. Decentralised on purpose:
  /// each town is the *only* place its skill can be learned, until Zenith.
  final String? station;

  /// What must be assembled to pass, if this place is a tier gate.
  final String? gate;

  /// The level this place tends to open up at. Towns only; `null` elsewhere.
  final int? opensAtLevel;

  /// Ids of directly reachable locations. Walkable and **bidirectional** —
  /// guarded by `test/world_test.dart`.
  final List<String> connections;

  /// One-way teleport destinations. Zenith alone has these; the return trip
  /// is not modelled yet because it needs the Crown check.
  final List<String> teleportsTo;

  const GameLocation({
    required this.id,
    required this.name,
    required this.kind,
    required this.blurb,
    required this.arrival,
    required this.connections,
    this.plane = WorldPlane.world,
    this.elements = const [],
    this.tier,
    this.minLevel = 0,
    this.maxLevel = 0,
    this.elevationMetres,
    this.station,
    this.gate,
    this.opensAtLevel,
    this.teleportsTo = const [],
  });

  bool get isTown => kind == LocationKind.town;

  /// Non-town locations host adventures (a duel encounter in Phase 1).
  bool get hasAdventure => kind != LocationKind.town;

  /// A hybrid zone teaches the matchup of the two elements that meet there.
  bool get isHybrid => elements.length == 2;

  /// Above the tree line (2 800 m), nothing grows and only Rimeholt holds.
  bool get isAboveTreeLine =>
      elevationMetres != null && elevationMetres! >= World.treeLineMetres;

  /// Thin Air applies across the Celestial shelf (WORLD_DESIGN §4.1).
  bool get hasThinAir => tier == MagicTier.celestial && plane == WorldPlane.world;

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
  static const String startLocationId = 'aldermere';

  /// Above this, nothing grows (WORLD_DESIGN §3.1). The only hard altitude the
  /// design ever implied: Rimeholt is "the last mortal outpost, above the tree
  /// line."
  static const int treeLineMetres = 2800;

  /// Every town, in the order the campaign meets them. Zenith's teleport net
  /// is built from this.
  static const List<String> townIds = [
    'aldermere',
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
      id: 'aldermere',
      name: 'Aldermere',
      kind: LocationKind.town,
      tier: MagicTier.primal,
      elevationMetres: 240,
      opensAtLevel: 1,
      station: 'Woodcarving',
      gate: 'Three ordinary proofs, shown to the guard on the north road',
      blurb: 'A wooded river valley where every mage begins.',
      arrival: 'Alders lean over the water, and the whole valley smells of wet '
          'bark and woodsmoke. Someone is sharpening something. Nobody looks '
          'up when you pass, which is its own kind of welcome.',
      connections: [
        'whispering_woods',
        'glimmerbrook',
        'thornmire',
        'cinderpeak_foothills',
        'pennycross',
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
      elevationMetres: 300,
      blurb: 'Sun-dappled woods that murmur when nothing is moving them.',
      arrival: 'The murmur is not wind. It comes from the ground, from the '
          'roots crossing under the path, and it stops the moment you stand '
          'still to listen.',
      connections: ['aldermere', 'thornmire', 'ashfall_vale'],
    ),
    GameLocation(
      id: 'glimmerbrook',
      name: 'Glimmerbrook',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      elements: [MagicElement.aqua],
      minLevel: 3,
      maxLevel: 8,
      elevationMetres: 180,
      blurb: 'Springs and shallows east of Aldermere, bright enough to hurt.',
      arrival: 'The brook runs over pale stones and throws the light back at '
          'you in pieces. Fish hang in the current without swimming. The water '
          'is colder than the season should allow.',
      connections: ['aldermere', 'thornmire', 'pennycross'],
    ),
    GameLocation(
      id: 'cinderpeak_foothills',
      name: 'Cinderpeak Foothills',
      kind: LocationKind.route,
      tier: MagicTier.primal,
      elements: [MagicElement.pyro],
      minLevel: 6,
      maxLevel: 11,
      elevationMetres: 950,
      blurb: 'The first rise north, where the ground is warm through your boots.',
      arrival: 'The grass gives out and the slope turns to grey grit that '
          'shifts under you. Somewhere above, the mountain is breathing. The '
          'air tastes of struck flint.',
      connections: [
        'aldermere',
        'ashfall_vale',
        'forgeholm',
        'the_molten_deep',
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
      elevationMetres: 0,
      blurb: "Where the woods drown in the brook's outflow.",
      arrival: 'The path becomes a suggestion, then a rumour, then water. '
          'Trees stand in it up to their knees and have made peace with that. '
          'Everything green here is winning.',
      connections: ['aldermere', 'whispering_woods', 'glimmerbrook'],
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
      elevationMetres: 700,
      blurb: 'Downwind of the cone: the burn scar where ash falls on forest.',
      arrival: 'Grey settles on every leaf until the whole valley looks like a '
          'charcoal drawing of itself. New shoots are already pushing up '
          'through it. Fire came through here, and something is arguing about '
          'whether it won.',
      connections: ['whispering_woods', 'cinderpeak_foothills'],
    ),
    GameLocation(
      id: 'pennycross',
      name: 'Pennycross',
      kind: LocationKind.town,
      tier: MagicTier.primal,
      elevationMetres: 360,
      opensAtLevel: 8,
      blurb: 'The first market, where the river road crosses the mountain road.',
      arrival: 'Two roads meet and a town happened. Stalls have grown into '
          'buildings, and the buildings still look like stalls. Everyone is '
          'halfway through a transaction.',
      connections: ['aldermere', 'glimmerbrook', 'forgeholm'],
    ),

    // ---------------------------------------------------------------
    // Kinetic — the range · Lv 15-29 · -400-2 500 m
    // ---------------------------------------------------------------
    GameLocation(
      id: 'forgeholm',
      name: 'Forgeholm',
      kind: LocationKind.town,
      tier: MagicTier.kinetic,
      elevationMetres: 1080,
      opensAtLevel: 15,
      station: 'Metalworking',
      blurb: 'The last flat ground before the Ironspine.',
      arrival: 'The town is built into the hill rather than on it. Ore goes in '
          'one end and comes out the other as something with a name. It is '
          'never quiet and never cold.',
      connections: ['cinderpeak_foothills', 'pennycross', 'old_quarry'],
    ),
    GameLocation(
      id: 'old_quarry',
      name: 'Old Quarry',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.geo],
      minLevel: 15,
      maxLevel: 19,
      elevationMetres: 1400,
      blurb: "Cut into the range's southern flank, and cut too deep.",
      arrival: 'Terraces step down into shadow, each one squarer than anything '
          'nature makes. The tool marks are old. Whatever was quarried out of '
          'here left a shape, and the shape has started to move.',
      connections: ['forgeholm', 'the_molten_deep', 'thunderspire_peaks'],
    ),
    GameLocation(
      id: 'stormcliff_coast',
      name: 'Stormcliff Coast',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.electro],
      minLevel: 17,
      maxLevel: 22,
      elevationMetres: 430,
      blurb: "Where the western ocean's weather hits a wall and has nowhere "
          'to go.',
      arrival: 'The cliffs take the whole weight of it. Spray comes up further '
          'than it should and your hair lifts before you hear the crack. The '
          'rock is scorched in long vertical lines.',
      connections: ['thunderspire_peaks', 'galehaven'],
    ),
    GameLocation(
      id: 'galehaven',
      name: 'Galehaven',
      kind: LocationKind.town,
      tier: MagicTier.kinetic,
      elevationMetres: 5,
      opensAtLevel: 22,
      station: 'Tailoring',
      blurb: 'The one notch in a hundred miles of cliff.',
      arrival: 'The harbour is impossibly calm for what is happening outside '
          'it. Cloth and dye come off the boats in bales; nothing here is made '
          'locally except the ships.',
      // ⭐ The sea passage to Tidewrack Shoals is the port's endgame purpose.
      connections: ['stormcliff_coast', 'frostfell_pass', 'tidewrack_shoals'],
    ),
    GameLocation(
      id: 'windward_steppe',
      name: 'Windward Steppe',
      kind: LocationKind.route,
      tier: MagicTier.kinetic,
      elements: [MagicElement.aero],
      minLevel: 19,
      maxLevel: 24,
      elevationMetres: 1900,
      blurb: 'A high tableland east of the crest, scoured flat.',
      arrival: 'Nothing here is taller than your knee, and everything leans '
          'the same way. The wind does not gust; it simply blows, and has been '
          'blowing since before there was anyone to notice.',
      connections: ['thunderspire_peaks', 'frostfell_pass', 'concordance'],
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
      elevationMetres: 2500,
      blurb: 'The way through. Sea air lifted over the crest and frozen there.',
      arrival: 'The pass is a white corridor between two black walls. Your '
          'breath goes up and does not come down. The road is under here '
          'somewhere, and other people have been sure of that too.',
      connections: [
        'thunderspire_peaks',
        'windward_steppe',
        'galehaven',
        'concordance',
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
      elevationMetres: 2400,
      blurb: 'The summit line where coastal storm meets steppe wind.',
      arrival: 'You are inside the weather rather than under it. The cloud is '
          'lit from within at intervals, and the intervals are getting '
          'shorter. Metal hums.',
      connections: [
        'old_quarry',
        'stormcliff_coast',
        'windward_steppe',
        'frostfell_pass',
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
      // ⚠️ The only place in the world below sea level.
      elevationMetres: -400,
      blurb: "Under the quarry, under the mountain, under the sea's level.",
      arrival: "The quarry's deepest gallery keeps going after the tool marks "
          'stop. The rock gets warm, then hot, then lit from below. There is a '
          'floor down here that moves like water because it is not water.',
      connections: ['old_quarry', 'cinderpeak_foothills'],
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
      elevationMetres: 1700,
      opensAtLevel: 30,
      gate: 'The Kinetic Sigil, in three parts, shown at the gate',
      // ⭐ No crafting station on purpose — value MOVES here, it is not made.
      blurb: 'The trade capital, at the head of navigation on the River Concord.',
      arrival: 'Everything that moves by water or road in this world passes '
          'through here, and the city has arranged itself around that fact. '
          'You show your Sigil at the gate. Nobody fights you; someone writes '
          'your name down.',
      connections: [
        'frostfell_pass',
        'windward_steppe',
        'the_kiln_desert',
        'the_mirrormere',
        'meridian',
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
      elevationMetres: 2100,
      blurb: "A cold high desert in the range's rain shadow, and the sunniest "
          'ground in the world.',
      arrival: 'The air is too thin to hold heat, so the sun burns while the '
          'wind bites. There is no shade anywhere and no water for a day\'s '
          'walk. Your shadow is the hardest-edged thing you have ever seen.',
      connections: ['concordance', 'meridian', 'the_sunless_reach'],
    ),
    GameLocation(
      id: 'the_mirrormere',
      name: 'The Mirrormere',
      kind: LocationKind.route,
      tier: MagicTier.celestial,
      elements: [MagicElement.lunar],
      minLevel: 32,
      maxLevel: 37,
      elevationMetres: 2400,
      blurb: 'A high still lake that holds the moon better than the sky does.',
      arrival: 'Not a ripple. The surface gives you back the mountains, the '
          'stars, and the moon at a size the moon has no right to be. Walking '
          'the shore, you are careful not to look down for too long.',
      connections: [
        'concordance',
        'meridian',
        'tidewrack_shoals',
        'the_sunless_reach',
        'rimeholt',
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
      elevationMetres: 2300,
      blurb: 'A crater field, preserved because nothing grows to cover it.',
      arrival: 'Bowl after bowl in the pale ground, each with something at the '
          'bottom that is not from here. Nothing has grown over them because '
          'nothing grows. At night the sky is so clear it looks like a threat.',
      connections: ['meridian', 'the_shattered_orrery'],
    ),
    GameLocation(
      id: 'meridian',
      name: 'Meridian',
      kind: LocationKind.town,
      tier: MagicTier.celestial,
      elevationMetres: 2600,
      opensAtLevel: 36,
      station: 'Enchanting',
      blurb: 'An observatory on the crest of the Scarp: the highest dark-sky '
          'ground there is.',
      arrival: 'A town of long roofs that open. Everyone keeps different hours '
          'and nobody explains. From the crest you can see the desert on one '
          'side and, on the other, a valley with no light in it at all.',
      connections: [
        'concordance',
        'the_kiln_desert',
        'the_mirrormere',
        'starfall_basin',
        'the_sunless_reach',
        'rimeholt',
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
      // ⭐ A Lv 36-40 zone at 20 m: elevation is not difficulty.
      elevationMetres: 20,
      blurb: 'Tides that obey the moon exactly, on the northern shore.',
      arrival: 'The water goes out further than seems survivable and comes '
          'back faster. What it uncovers has been down there a long time. '
          'Everything is timed to something overhead.',
      connections: ['galehaven', 'the_mirrormere'],
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
      elevationMetres: 2650,
      blurb: "The Scarp's north face. Direct sun never reaches the floor.",
      arrival: 'You come over the crest out of glare into a valley that has '
          'never been lit. The rock is the same rock. The desert is a thousand '
          'feet away and on the other side of the world.',
      connections: ['meridian', 'the_kiln_desert', 'the_mirrormere'],
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
      elevationMetres: 2500,
      blurb: 'A broken model of the heavens, still trying to run.',
      arrival: 'Rings the size of bridges, half of them fallen, and the fallen '
          'half still turning. The arcing is not weather; it is the mechanism. '
          'Something is being calculated and has been for a very long time.',
      connections: ['starfall_basin'],
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
      elevationMetres: 2900,
      opensAtLevel: 45,
      station: 'Jewelry',
      gate: 'A Celestial Totem charged with the Solar, Lunar and Astral '
          'essences, to pass the barrier above the town',
      blurb: 'Basecamp. The last mortal outpost, above the tree line.',
      arrival: 'There is no wood here, so nothing is built of it. The town is '
          'stone and rope and hide, dug in against a slope that goes up out of '
          'sight. Everyone you meet is either arriving or leaving; nobody is '
          'from here.',
      connections: ['meridian', 'the_mirrormere', 'hallowmarch'],
    ),
    GameLocation(
      id: 'hallowmarch',
      name: 'Hallowmarch',
      kind: LocationKind.route,
      tier: MagicTier.ethereal,
      elements: [MagicElement.sanctus],
      minLevel: 45,
      maxLevel: 49,
      elevationMetres: 3150,
      // 📝 Not a marsh — *march* in the older borderland sense.
      blurb: "The Vault's south flank: a consecrated causeway up the only side "
          'that thaws.',
      arrival: 'A raised road, and someone built it. The sun reaches this face '
          'for a few hours and the meltwater runs beside you the whole way. '
          'Every mile or so there is a marker, and every marker has been '
          'maintained.',
      connections: ['rimeholt', 'the_reliquary_deep', 'vespergate'],
    ),
    GameLocation(
      id: 'the_umbral_wastes',
      name: 'The Umbral Wastes',
      kind: LocationKind.route,
      tier: MagicTier.ethereal,
      elements: [MagicElement.umbra],
      minLevel: 47,
      maxLevel: 51,
      elevationMetres: 3600,
      blurb: "The Vault's north face. No direct sun at any hour of any day.",
      arrival: 'You round the shoulder and the light stops. Not dusk — an '
          'absence with an edge to it. The ice here has never melted and holds '
          'its shape like something that has been thought about.',
      // Reached through the Reliquary, or over the upper icefall to Vespergate.
      connections: ['the_reliquary_deep', 'vespergate'],
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
      elevationMetres: 3300,
      blurb: 'A vault bored through the mountain from the lit side to the dark.',
      arrival: 'The door is on the warm flank and the far end opens onto the '
          'ice. In between, a corridor that someone consecrated and someone '
          'else did not leave alone. It is warmer in the middle than at either '
          'end.',
      connections: ['hallowmarch', 'the_umbral_wastes'],
    ),
    GameLocation(
      id: 'vespergate',
      name: 'Vespergate',
      kind: LocationKind.town,
      tier: MagicTier.ethereal,
      elevationMetres: 4500,
      opensAtLevel: 50,
      station: 'Potions and Alchemy',
      blurb: 'Where the ground runs out. The last place with a supply line.',
      arrival: 'A fortress at the top of the world, facing the wrong way — not '
          'outward at an enemy but upward, at nothing. Above it the rock goes '
          'vertical and stops being a route. They have been brewing their own '
          'everything for a long time.',
      // ⭐ The only door out of the world. The last pitch cannot be climbed,
      // so there is no connection from here to zenith.
      connections: [
        'hallowmarch',
        'the_umbral_wastes',
        'the_collapsed_academy',
      ],
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
      arrival: 'It is not ruined so much as unfinished in the wrong direction. '
          'Staircases arrive at rooms that were never built. The syllabus is '
          'still on the wall and the last three items on it are not in any '
          'language you have.',
      connections: ['vespergate', 'the_unwritten_library'],
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
      arrival: 'Every book here is being written right now, by nobody. The '
          'shelves go up past where a ceiling would be. Something is taking '
          'dictation and it would like your name for the record.',
      connections: ['the_collapsed_academy', 'the_eclipsed_citadel'],
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
      arrival: 'Below it, through a gap in nothing, is the summit of the '
          'mountain you could not climb. The Citadel is between you and it. '
          'That is what the name has always meant.',
      // ⭐ The way back IN. Beyond it: the summit, and Zenith.
      connections: ['the_unwritten_library', 'zenith'],
    ),

    // ---------------------------------------------------------------
    // The summit — back in the world, entered from above
    // ---------------------------------------------------------------
    GameLocation(
      id: 'zenith',
      name: 'Zenith',
      kind: LocationKind.town,
      tier: MagicTier.ethereal,
      elevationMetres: 5200,
      opensAtLevel: 60,
      station: 'Every station — the only town with all six',
      gate: 'The Concordant Crown: twelve elemental gems and twelve Cores, '
          'bound with a purchased binding spell',
      blurb: 'The summit. Visible from everywhere below, and shut.',
      arrival: 'The doors were never locked from the inside. From up here the '
          'whole world is one thing, and every city you have ever walked into '
          'is a mark on it you could put a finger over.',
      // Reached only through the Citadel — the last pitch cannot be climbed.
      connections: ['the_eclipsed_citadel'],
      // ⭐ Line of sight to everywhere is why the teleport net exists at all.
      // One-way for now: the return trip needs a Crown check that is unbuilt.
      teleportsTo: [
        'aldermere',
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
  /// throwing — a stale save must never crash the app on load. Use [exists] to
  /// detect that case; [PlayerProfile.migrateWorld] repairs it.
  static GameLocation byId(String id) => _byId[id] ?? locations.first;

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
      // The Empyrean
      'the_collapsed_academy': 'Unfinished Scholar',
      'the_unwritten_library': 'The Dictating Hand',
      'the_eclipsed_citadel': 'Procarius, the Eclipsed',
    };
    return byId[location.id] ?? 'Wandering Mage';
  }
}
