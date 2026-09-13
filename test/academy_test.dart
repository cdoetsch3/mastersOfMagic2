import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/academy.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/matchmaking.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';

/// The Academy (academy.dart, ruled 2026-09-10): level 50, no gear, no belt,
/// no reward, every spell open, its own queue, open to guests. Every
/// assertion names the mutant it kills.
void main() {
  group('duelInputsFor — the one seam every launch passes through', () {
    final profile = PlayerProfile.newPlayer()..xp = 999999;
    const worn = ItemModifiers(maxHpBonus: 40, critChance: 15);

    test('⭐ the Academy overrides level, gear AND belt together', () {
      final r = duelInputsFor(academy: true, profile: profile, equipment: worn);
      expect(r.level, Academy.level, reason: 'everyone is level 50');
      expect(
        r.gear,
        ItemModifiers.none,
        reason:
            '⚠️ the mutant this kills: a launch that took the Academy '
            'level but let the wardrobe through',
      );
      expect(
        r.belt,
        isEmpty,
        reason:
            'and no potions — the belt is the third thing a level '
            'playing field has to strip',
      );
    });

    test('geared play is untouched', () {
      final r = duelInputsFor(
        academy: false,
        profile: profile,
        equipment: worn,
      );
      expect(r.level, profile.level);
      expect(r.gear, worn);
      expect(r.belt, profile.belt.loaded);
    });
  });

  group('the Academy loadout', () {
    test('⭐ the default hand resolves in full — every id is real', () {
      final preset = LoadoutPreset.academy();
      expect(
        preset.unknownSpellIds,
        isEmpty,
        reason:
            'a default that silently dropped a spell would hand a '
            'guest a nine-spell loadout with no way to know why',
      );
      expect(preset.unknownElementIds, isEmpty);
      expect(
        preset.spellIds,
        hasLength(Academy.spellSlots),
        reason: 'a full hand at the ruled cap of 10',
      );
      expect(preset.elementIds, hasLength(Academy.elementSlots));
      expect(preset.toLoadout().spells, hasLength(10));
    });

    test('it round-trips through the profile save', () {
      final p = PlayerProfile.newPlayer();
      p.academyPreset = LoadoutPreset(
        name: 'Academy',
        elementIds: ['solar'],
        spellIds: ['torment', 'execute'],
      );
      final back = PlayerProfile.fromJson(p.toJson());
      expect(
        back.academyPreset.spellIds,
        ['torment', 'execute'],
        reason:
            '⚠️ the mutant this kills: a preset that is never written, '
            'so every reload hands back the default',
      );
      expect(back.academyPreset.elementIds, ['solar']);
    });

    test('a save from before the Academy gets the default hand', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('academyPreset');
      final back = PlayerProfile.fromJson(json);
      expect(back.academyPreset.spellIds, LoadoutPreset.academy().spellIds);
    });
  });

  group('the Academy queue', () {
    test('⭐ tickets only match their own mode', () {
      expect(
        Matchmaking.ticketInMode({'mode': 'academy'}, Academy.mode),
        isTrue,
      );
      expect(
        Matchmaking.ticketInMode({'mode': 'academy'}, Academy.gearedMode),
        isFalse,
        reason:
            '⚠️ the mutant this kills: one queue — a level-50 gearless '
            'mage matched against a geared level-12 one',
      );
      expect(
        Matchmaking.ticketInMode({'mode': 'geared'}, Academy.mode),
        isFalse,
      );
    });

    test('a ticket with no mode is a geared ticket from an older client', () {
      expect(
        Matchmaking.ticketInMode({}, Academy.gearedMode),
        isTrue,
        reason: 'that client is fighting geared whatever we call it',
      );
      expect(
        Matchmaking.ticketInMode({}, Academy.mode),
        isFalse,
        reason: 'and must never be pulled into the Academy',
      );
    });
  });

  group('the drivers build a level-50, naked rival', () {
    test('⭐ RemoteDuelDriver coerces whatever the wire said', () {
      final d = RemoteDuelDriver(
        roomId: 'ROOM',
        isHost: true,
        masterSeed: 1,
        opponentName: 'Rival',
        opponentLevel: 12,
        opponentGear: const ItemModifiers(maxHpBonus: 40),
        opponentRating: 1200,
        academy: true,
      );
      expect(
        d.opponentLevel,
        Academy.level,
        reason:
            '⚠️ the mutant this kills: reading the wire level — both '
            'clients would then build different mages from the same seed',
      );
      expect(d.opponentGear, ItemModifiers.none);
    });

    test('a geared driver keeps the wire values', () {
      final d = RemoteDuelDriver(
        roomId: 'ROOM',
        isHost: true,
        masterSeed: 1,
        opponentName: 'Rival',
        opponentLevel: 12,
        opponentGear: const ItemModifiers(maxHpBonus: 40),
        opponentRating: 1200,
      );
      expect(d.opponentLevel, 12);
      expect(d.opponentGear.maxHpBonus, 40);
    });

    test('an AI stand-in fights at the Academy level', () {
      final persona = AiRoster.nearestToLevel(3);
      expect(
        persona.level,
        lessThan(Academy.level),
        reason: 'this fixture only means something with a low persona',
      );
      final d = LocalAiDriver(persona: persona, levelOverride: Academy.level);
      expect(d.opponentLevel, Academy.level);
      expect(
        LocalAiDriver(persona: persona).opponentLevel,
        persona.level,
        reason: 'and without the override the persona is itself',
      );
    });
  });
}
