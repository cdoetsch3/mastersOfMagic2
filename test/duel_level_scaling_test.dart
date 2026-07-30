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
}

void unawaited(Future<void> f) {}
