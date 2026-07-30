import 'package:flutter/material.dart';

import '../screens/duel_screen.dart';
import '../ui/app_theme.dart';
import 'ai_personas.dart';
import 'game_state.dart';
import 'loadout.dart';
import 'opponent_driver.dart';

/// Pushes a duel against any [OpponentDriver] (AI persona or remote human)
/// and feeds its result into [GameState] (XP/gold), surfacing any level-up
/// once the player returns to the menus. The duel itself is identical
/// regardless of where the opponent came from.
Future<void> launchDuel(
  BuildContext context, {
  required Loadout loadout,
  required OpponentDriver driver,
  required bool campaign,
}) async {
  final game = GameStateScope.read(context);
  final messenger = ScaffoldMessenger.of(context);

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DuelScreen(
        loadout: loadout,
        driver: driver,
        campaign: campaign,
        // Scales the player's health and damage (4%/level, compounding).
        // Without this the duel screen defaults to level 1 and everyone
        // fights at 100 HP regardless of their real level.
        playerLevel: game.profile.level,
        // ⚠️ Both levels cross this seam. The player's scales their health
        // and damage; the opponent's scales the XP the win is worth. This is
        // the only path a real player takes, so a level dropped here is
        // invisible to every test that builds DuelScreen directly.
        onResult: (won) => game.recordDuelResult(
          won: won,
          opponentLevel: driver.opponentLevel,
        ),
      ),
    ),
  );

  final level = game.pendingLevelUp;
  if (level != null) {
    game.acknowledgeLevelUp();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.panel,
        content: Text(
          'Level up! You are now level $level.',
          style: const TextStyle(color: AppColors.gold),
        ),
      ),
    );
  }
}

/// Convenience: a duel against a named AI persona.
Future<void> launchAiDuel(
  BuildContext context, {
  required Loadout loadout,
  required AiPersona persona,
  required bool campaign,
}) => launchDuel(
  context,
  loadout: loadout,
  driver: LocalAiDriver(persona: persona),
  campaign: campaign,
);
