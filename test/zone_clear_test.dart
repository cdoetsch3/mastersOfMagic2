import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

void main() {
  group('a character remembers which zones it has cleared', () {
    test('a new character has cleared nothing, but has discovered its start', () {
      final p = PlayerProfile.newPlayer();
      expect(p.zoneClears, isEmpty);
      expect(p.zonesCleared, 0);
      expect(p.hasCleared(World.startLocationId), isFalse);
      // ⚠️ Discovery is not clearing. Conflating them is the likely bug.
      expect(p.discoveredLocationIds, contains(World.startLocationId));
    });

    test('clears survive a save/load round trip', () {
      final p = PlayerProfile.newPlayer()
        ..zoneClears.addAll({'whispering_woods': 4, 'glimmerbrook': 1});
      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.zoneClears, {'whispering_woods': 4, 'glimmerbrook': 1});
      expect(back.hasCleared('whispering_woods'), isTrue);
      expect(back.clearCountFor('whispering_woods'), 4);
      expect(back.hasCleared('thornmire'), isFalse);
      expect(back.clearCountFor('thornmire'), 0);
    });

    test('a save from before clears existed reads as cleared nothing', () {
      // ⭐ The safe direction: an old character can only be withheld
      // repeat-clear content, never granted it early.
      final json = PlayerProfile.newPlayer().toJson()..remove('zoneClears');
      expect(PlayerProfile.fromJson(json).zoneClears, isEmpty);
    });

    test('walking somewhere never marks it cleared', () {
      final p = PlayerProfile.newPlayer()
        ..discoveredLocationIds.addAll({'thornmire', 'ashfall_vale'});
      for (final id in p.discoveredLocationIds) {
        expect(p.hasCleared(id), isFalse);
      }
    });

    test('every cleared id must be a real combat zone, never a town', () {
      // Guards the shape of the data rather than any one write.
      for (final l in World.locations) {
        final p = PlayerProfile.newPlayer()..zoneClears[l.id] = 1;
        if (l.isTown) {
          expect(
            l.hasAdventure,
            isFalse,
            reason: 'towns have no boss, so ${l.id} can never be cleared',
          );
        } else {
          expect(p.hasCleared(l.id), isTrue);
        }
      }
    });
  });

  group('recordDuelResult only clears a zone when a BOSS falls', () {
    test('an ordinary win does not clear the zone', () async {
      final g = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await g.recordDuelResult(won: true, locationId: 'whispering_woods');
      expect(g.profile.duelsWon, 1);
      expect(
        g.profile.hasCleared('whispering_woods'),
        isFalse,
        reason: 'a Phase-1 adventure is one ordinary duel, not a boss',
      );
    });

    test('a boss win clears it', () async {
      final g = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await g.recordDuelResult(
        won: true,
        bossDefeated: true,
        locationId: 'whispering_woods',
      );
      expect(g.profile.hasCleared('whispering_woods'), isTrue);
      expect(g.profile.clearCountFor('whispering_woods'), 1);
    });

    test('repeat clears accumulate — the Purge tier needs about 4', () async {
      final g = GameState(_MemStorage(), PlayerProfile.newPlayer());
      for (var i = 0; i < 5; i++) {
        await g.recordDuelResult(
          won: true,
          bossDefeated: true,
          locationId: 'thornmire',
        );
      }
      expect(g.profile.clearCountFor('thornmire'), 5);
      expect(g.profile.zonesCleared, 1);
    });

    test('losing to a boss clears nothing', () async {
      final g = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await g.recordDuelResult(
        won: false,
        bossDefeated: true,
        locationId: 'whispering_woods',
      );
      expect(g.profile.zoneClears, isEmpty);
    });
  });
}

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;

  @override
  Future<PlayerProfile?> load() async => stored;

  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;

  @override
  Future<void> clear() async => stored = null;
}
