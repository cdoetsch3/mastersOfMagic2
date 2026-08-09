import 'package:flutter/material.dart';

import '../screens/duel_screen.dart';
import '../screens/level_up_screen.dart';
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
        // ⭐ Gear reaches every duel the player actually fights. Tests that
        // build DuelScreen directly stay at the unequipped baseline.
        playerGear: game.equipmentTotals,
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
  final from = game.pendingLevelUpFrom;
  if (level != null && context.mounted) {
    // ⭐ A screen, not a snackbar. A level-up that flashes past in three
    // seconds is the same as no level-up, and this is one of the few moments
    // the game has to say "you are now better at this".
    game.acknowledgeLevelUp();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelUpScreen(from: from ?? level - 1, to: level),
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
