import 'package:mom_engine/mom_engine.dart';

enum LocationKind { town, route, dungeon }

/// A place on the world map. The graph of [connections] is what travel walks;
/// there is no simulated terrain (design decision — menu-based travel only).
class GameLocation {
  final String id;
  final String name;
  final LocationKind kind;
  final String blurb;

  /// Elemental flavor of the monsters found here (empty for towns).
  final List<MagicElement> elements;
  final int minLevel;
  final int maxLevel;

  /// Ids of directly reachable locations.
  final List<String> connections;

  const GameLocation({
    required this.id,
    required this.name,
    required this.kind,
    required this.blurb,
    this.elements = const [],
    this.minLevel = 0,
    this.maxLevel = 0,
    required this.connections,
  });

  bool get isTown => kind == LocationKind.town;

  /// Non-town locations host adventures (a duel encounter in Phase 1).
  bool get hasAdventure => kind != LocationKind.town;
}

/// The Phase-1 world. Names/levels track GAME_DESIGN.md's draft region table.
abstract final class World {
  static const String startLocationId = 'aldermere';

  static const List<GameLocation> locations = [
    GameLocation(
      id: 'aldermere',
      name: 'Aldermere',
      kind: LocationKind.town,
      blurb: 'The home town where every mage begins.',
      connections: [
        'whispering_woods',
        'glimmerbrook',
        'cinderpeak_foothills',
        'stormcliff_coast',
      ],
    ),
    GameLocation(
      id: 'whispering_woods',
      name: 'Whispering Woods',
      kind: LocationKind.route,
      blurb: 'Sun-dappled woods that murmur with earth and air.',
      elements: [MagicElement.geo, MagicElement.aero],
      minLevel: 1,
      maxLevel: 5,
      connections: ['aldermere', 'old_quarry'],
    ),
    GameLocation(
      id: 'old_quarry',
      name: 'Old Quarry',
      kind: LocationKind.dungeon,
      blurb: 'An abandoned dig where stone-things still stir.',
      elements: [MagicElement.geo],
      minLevel: 4,
      maxLevel: 8,
      connections: ['whispering_woods'],
    ),
    GameLocation(
      id: 'glimmerbrook',
      name: 'Glimmerbrook',
      kind: LocationKind.route,
      blurb: 'A bright creek where water and light dance.',
      elements: [MagicElement.aqua, MagicElement.sanctus],
      minLevel: 2,
      maxLevel: 6,
      connections: ['aldermere'],
    ),
    GameLocation(
      id: 'cinderpeak_foothills',
      name: 'Cinderpeak Foothills',
      kind: LocationKind.route,
      blurb: 'Ashen slopes on the road to Forgeholm.',
      elements: [MagicElement.pyro, MagicElement.geo],
      minLevel: 8,
      maxLevel: 14,
      connections: ['aldermere', 'forgeholm'],
    ),
    GameLocation(
      id: 'forgeholm',
      name: 'Forgeholm',
      kind: LocationKind.town,
      blurb: 'A mining town carved into the mountainside.',
      connections: [
        'cinderpeak_foothills',
        'the_caldera',
        'crystal_caverns',
        'frostfell_pass',
      ],
    ),
    GameLocation(
      id: 'the_caldera',
      name: 'The Caldera',
      kind: LocationKind.dungeon,
      blurb: 'A dormant crater brimming with fire.',
      elements: [MagicElement.pyro],
      minLevel: 15,
      maxLevel: 22,
      connections: ['forgeholm'],
    ),
    GameLocation(
      id: 'crystal_caverns',
      name: 'Crystal Caverns',
      kind: LocationKind.dungeon,
      blurb: 'Glittering tunnels of earth and light.',
      elements: [MagicElement.geo, MagicElement.sanctus],
      minLevel: 16,
      maxLevel: 24,
      connections: ['forgeholm'],
    ),
    GameLocation(
      id: 'stormcliff_coast',
      name: 'Stormcliff Coast',
      kind: LocationKind.route,
      blurb: 'Wind-lashed cliffs on the road to Galehaven.',
      elements: [MagicElement.aqua, MagicElement.electro],
      minLevel: 8,
      maxLevel: 14,
      connections: ['aldermere', 'galehaven'],
    ),
    GameLocation(
      id: 'galehaven',
      name: 'Galehaven',
      kind: LocationKind.town,
      blurb: 'A salt-worn port town open to the sea.',
      connections: ['stormcliff_coast', 'thunderspire_peaks'],
    ),
    GameLocation(
      id: 'frostfell_pass',
      name: 'Frostfell Pass',
      kind: LocationKind.route,
      blurb: 'A frozen mountain pass toward Rimeholt.',
      elements: [MagicElement.flora, MagicElement.aero],
      minLevel: 18,
      maxLevel: 26,
      connections: ['forgeholm', 'rimeholt'],
    ),
    GameLocation(
      id: 'thunderspire_peaks',
      name: 'Thunderspire Peaks',
      kind: LocationKind.route,
      blurb: 'Storm-wracked summits crackling with power.',
      elements: [MagicElement.electro, MagicElement.aero],
      minLevel: 26,
      maxLevel: 34,
      connections: ['galehaven', 'rimeholt'],
    ),
    GameLocation(
      id: 'rimeholt',
      name: 'Rimeholt',
      kind: LocationKind.town,
      blurb: 'A hardy village high in the frozen peaks.',
      connections: [
        'frostfell_pass',
        'thunderspire_peaks',
        'the_mirrormere',
        'radiant_sanctum',
        'nightfen_marsh',
      ],
    ),
    GameLocation(
      id: 'the_mirrormere',
      name: 'The Mirrormere',
      kind: LocationKind.dungeon,
      blurb: 'A frozen lake of water and ice.',
      elements: [MagicElement.aqua, MagicElement.flora],
      minLevel: 26,
      maxLevel: 34,
      connections: ['rimeholt'],
    ),
    GameLocation(
      id: 'radiant_sanctum',
      name: 'Radiant Sanctum',
      kind: LocationKind.dungeon,
      blurb: 'A ruined temple that still blazes with light.',
      elements: [MagicElement.sanctus],
      minLevel: 30,
      maxLevel: 38,
      connections: ['rimeholt'],
    ),
    GameLocation(
      id: 'nightfen_marsh',
      name: 'Nightfen Marsh',
      kind: LocationKind.route,
      blurb: 'A drowned bog where shadows gather.',
      elements: [MagicElement.aqua, MagicElement.umbra],
      minLevel: 38,
      maxLevel: 46,
      connections: ['rimeholt', 'the_umbral_wastes'],
    ),
    GameLocation(
      id: 'the_umbral_wastes',
      name: 'The Umbral Wastes',
      kind: LocationKind.dungeon,
      blurb: 'The dark edge of the known world.',
      elements: [MagicElement.umbra],
      minLevel: 45,
      maxLevel: 55,
      connections: ['nightfen_marsh', 'the_eclipsed_citadel'],
    ),
    GameLocation(
      id: 'the_eclipsed_citadel',
      name: 'The Eclipsed Citadel',
      kind: LocationKind.dungeon,
      blurb: 'Where light and shadow wage their final war.',
      elements: [MagicElement.umbra, MagicElement.sanctus],
      minLevel: 55,
      maxLevel: 60,
      connections: ['the_umbral_wastes'],
    ),
  ];

  static final Map<String, GameLocation> _byId = {
    for (final l in locations) l.id: l,
  };

  static GameLocation byId(String id) => _byId[id] ?? locations.first;

  /// A themed opponent name for an adventure at [location].
  static String opponentNameFor(GameLocation location) {
    final byId = <String, String>{
      'whispering_woods': 'Thornback Sprite',
      'old_quarry': 'Quarry Golem',
      'glimmerbrook': 'Brook Naiad',
      'cinderpeak_foothills': 'Ashjaw Brute',
      'the_caldera': 'Molten Warden',
      'crystal_caverns': 'Prism Revenant',
      'stormcliff_coast': 'Tidecaller',
      'frostfell_pass': 'Rime Stalker',
      'thunderspire_peaks': 'Stormcrest Roc',
      'the_mirrormere': 'Mirror Wraith',
      'radiant_sanctum': 'Seraph of Ash',
      'nightfen_marsh': 'Fen Lurker',
      'the_umbral_wastes': 'Umbral Devourer',
      'the_eclipsed_citadel': 'Procarius, the Eclipsed',
    };
    return byId[location.id] ?? 'Wandering Mage';
  }
}
