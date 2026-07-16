import 'package:flutter/material.dart';

import '../screens/duel_screen.dart';
import '../ui/app_theme.dart';
import 'game_state.dart';
import 'loadout.dart';

/// Pushes a duel and feeds its result back into [GameState] (XP/gold), then
/// surfaces any level-up once the player returns to the menus.
Future<void> launchDuel(
  BuildContext context, {
  required Loadout loadout,
  required bool campaign,
  String enemyName = 'Procarius',
}) async {
  final game = GameStateScope.read(context);
  final messenger = ScaffoldMessenger.of(context);

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DuelScreen(
        loadout: loadout,
        campaign: campaign,
        enemyName: enemyName,
        onResult: (won) => game.recordDuelResult(won: won),
      ),
    ),
  );

  final level = game.pendingLevelUp;
  if (level != null) {
    game.acknowledgeLevelUp();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.panel,
        content: Text('Level up! You are now level $level.',
            style: const TextStyle(color: AppColors.gold)),
      ),
    );
  }
}
