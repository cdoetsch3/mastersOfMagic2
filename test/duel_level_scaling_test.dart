import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_launcher.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// The player's level has to survive the whole way from the save file to the
/// mage that walks into the arena.
///
/// ⚠️ This exists because it once did not. Every other test builds a
/// [DuelScreen] directly and hands it a level, so all of them passed while the
/// launcher — the only path a real player takes — quietly never passed one at
/// all. A level-3 player fought at 100 HP. Nothing in the suite could see it,
/// because nothing exercised the seam between GameState and the duel.
void main() {
  test('the engine scales health geometrically with level', () {
    expect(MageState(name: 'x').maxHp, 100);
    expect(MageState(name: 'x', level: 3).maxHp, 108, reason: '1.04^2');
    expect(MageState(name: 'x', level: 50).maxHp, greaterThan(600));
  });

  testWidgets('a levelled player brings their real health into a duel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A level-3 profile: enough XP to have levelled twice.
    final profile = PlayerProfile.newPlayer();
    while (profile.level < 3) {
      profile.xp += 50;
    }
    expect(profile.level, 3);

    final game = GameState(_MemStorage(), profile);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: GameStateScope(
          state: game,
          child: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // Launch the way the game does, not by constructing DuelScreen by hand —
    // hand-construction is exactly what hid the missing wiring.
    unawaited(
      launchDuel(
        ctx,
        loadout: Loadout.starter,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
        campaign: true,
      ),
    );
    // Bounded pumps, not pumpAndSettle: the arena animates continuously (the
    // move timer), so it never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final screen = tester.widget<DuelScreen>(find.byType(DuelScreen));
    expect(
      screen.playerLevel,
      3,
      reason: 'the launcher must pass the profile level through',
    );
    expect(
      find.textContaining('108'),
      findsWidgets,
      reason: 'a level-3 mage fights at 108 HP, not 100',
    );
  });

  group('XP tracks who you beat', () {
    test('a win pays a base plus 5 per opponent level', () {
      // The literals are the 2026-08-10 halved rates (base 30, +5/level);
      // pinning them here is what makes a silent re-tune show up as a failure.
      expect(
        Progression.xpForDuel(won: true, opponentLevel: 1),
        35,
        reason: '⚠️ kills the pre-halving 60 + 10/level rates',
      );
      expect(
        Progression.xpForDuel(won: true, opponentLevel: 60),
        330,
      );
      expect(Progression.winXp, 30);
      expect(Progression.xpPerOpponentLevel, 5);
    });

    test('beating something tougher always pays more', () {
      var previous = 0;
      for (var level = 1; level <= 60; level++) {
        final xp = Progression.xpForDuel(won: true, opponentLevel: level);
        expect(
          xp,
          greaterThan(previous),
          reason: 'level $level must beat level ${level - 1}',
        );
        previous = xp;
      }
    });

    test('a PvP loss pays the flat floor, however big the enemy', () {
      // ⚠️ Deliberately unscaled: losing to a level-60 must be consolation,
      // not a payday you could farm by throwing fights.
      expect(
        Progression.xpForDuel(won: false, opponentLevel: 60, pvp: true),
        Progression.lossXp,
      );
      expect(
        Progression.xpForDuel(won: false, opponentLevel: 1, pvp: true),
        Progression.lossXp,
      );
      expect(Progression.lossXp, 8,
          reason: '⚠️ kills the pre-halving 15 consolation');
    });

    test('⭐ a single-player loss pays NOTHING (ruling 2026-08-17)', () {
      expect(
        Progression.xpForDuel(won: false, opponentLevel: 60),
        0,
        reason: 'an AI you can lose to on purpose is a farm — the floor only '
            'exists for opponents you cannot conjure on demand',
      );
      expect(
        Progression.xpForDuel(won: false, opponentLevel: 1, pvp: false),
        0,
      );
      expect(
        Progression.xpForDuel(won: true, opponentLevel: 4),
        Progression.xpForDuel(won: true, opponentLevel: 4, pvp: true),
        reason: 'the ruling touches losses only — a win pays the same wherever '
            'it was won',
      );
    });

    testWidgets('the launcher reports the opponent level it fought', (
      tester,
    ) async {
      // ⚠️ Same seam that swallowed the player's level once already: only the
      // launcher crosses it, so only a test that goes through the launcher
      // can see a level dropped here.
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      final xpBefore = game.profile.xp;
      final foe = AiRoster.all.last; // the highest-level persona
      expect(foe.level, greaterThan(1));

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      unawaited(
        launchDuel(
          ctx,
          loadout: Loadout.starter,
          driver: LocalAiDriver(persona: foe, rng: Random(1)),
          campaign: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final screen = tester.widget<DuelScreen>(find.byType(DuelScreen));
      screen.onResult!(true);
      await tester.pump();

      expect(
        game.profile.xp - xpBefore,
        Progression.xpForDuel(won: true, opponentLevel: foe.level),
        reason: 'beating a level-${foe.level} foe must pay for that level',
      );
    });
  });
}

void unawaited(Future<void> f) {}
