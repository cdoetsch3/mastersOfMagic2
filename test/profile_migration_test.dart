/// Renaming a zone must never strand an existing save (World.renamedIds).
///
/// ⭐ The bug this guards: Aldermere became Hearthwood, `World.byId` fell back
/// to the start location so the *place* looked right, but the stored id
/// stayed dead — and `Travel.route` keyed on it and returned null, silently
/// breaking travel for every character created before the rename.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/game/world.dart';

void main() {
  test('the rename map points the old id at a real place', () {
    expect(World.canonicalId('aldermere'), 'hearthwood');
    expect(World.exists(World.canonicalId('aldermere')), isTrue);
    // ⚠️ An id that was never renamed passes straight through.
    expect(World.canonicalId('pennycross'), 'pennycross');
  });

  test('a save on the old id loads onto the new one, everywhere it appears',
      () {
    final legacy = <String, dynamic>{
      'name': 'Old Timer',
      'locationId': 'aldermere',
      'discoveredLocationIds': ['aldermere', 'whispering_woods'],
      'zoneClears': {'aldermere': 2},
      'storerooms': {
        'aldermere': {
          'stacks': {'oak_log': 5},
        },
      },
    };

    final p = PlayerProfile.fromJson(legacy);

    expect(p.locationId, 'hearthwood', reason: 'the live location id');
    expect(p.discoveredLocationIds, contains('hearthwood'));
    expect(p.discoveredLocationIds, isNot(contains('aldermere')));
    expect(p.zoneClears['hearthwood'], 2, reason: 'clears follow the rename');
    expect(p.storerooms['hearthwood']?.stacks['oak_log'], 5,
        reason: 'a Storeroom must not be orphaned on a dead id');
  });

  test('the migrated location can actually be travelled from', () {
    final p = PlayerProfile.fromJson({'locationId': 'aldermere'});
    // ⭐ The regression itself: routing from the canonical id resolves.
    final route = Travel.route(p.locationId, 'whispering_woods');
    expect(route, isNotNull,
        reason: 'travel was broken because the dead id had no route');
  });

  test('a trip in flight when the rename landed keeps working', () {
    final p = PlayerProfile.fromJson({
      'locationId': 'aldermere',
      'trip': {
        'stops': ['aldermere', 'whispering_woods'],
        'secondsAtStop': [0, 180],
        'departedAt': '2026-01-01T00:00:00Z',
      },
    });
    expect(p.trip?.fromId, 'hearthwood');
    expect(p.trip?.toId, 'whispering_woods');
  });
}
