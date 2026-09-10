import 'package:flutter/material.dart';

import '../screens/duel_screen.dart';
import '../screens/level_up_screen.dart';
import 'academy.dart';
import 'ai_personas.dart';
import 'duel_controller.dart';
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
  // An Academy bout (academy.dart): level 50, no gear, no belt, no reward.
  bool academy = false,
}) async {
  final game = GameStateScope.read(context);
  // ⭐ One seam resolves level, wardrobe and belt for the mode (pinned by
  // academy_test) — a launch cannot take the Academy level and keep the belt.
  final inputs = duelInputsFor(
    academy: academy,
    profile: game.profile,
    equipment: game.equipmentTotals,
  );

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DuelScreen(
        loadout: loadout,
        driver: driver,
        campaign: campaign,
        academy: academy,
        // Scales the player's health and damage (4%/level, compounding).
        // Without this the duel screen defaults to level 1 and everyone
        // fights at 100 HP regardless of their real level.
        playerLevel: inputs.level,
        // ⭐ Gear reaches every duel the player actually fights. Tests that
        // build DuelScreen directly stay at the unequipped baseline.
        playerGear: inputs.gear,
        // ⭐ And so does the belt (ITEMS §10.3b) — including PvP, which is
        // ruled to allow consumables. The save happens the moment one is
        // drunk, not when the duel ends.
        belt: inputs.belt,
        onItemConsumed: game.consumeBeltItem,
        // ⚠️ Both levels cross this seam. The player's scales their health
        // and damage; the opponent's scales the XP the win is worth. This is
        // the only path a real player takes, so a level dropped here is
        // invisible to every test that builds DuelScreen directly.
        onResult: (outcome) {
          // ⚠️ A fled duel is banked by nobody. It pays no XP, no gold, and
          // records neither a win nor a loss (2026-08-17 ruling).
          if (outcome == DuelOutcome.fled) return;
          // ⭐ And an Academy bout banks NOTHING at all (ruled 2026-09-10):
          // no XP, no gold, no win count — the character is untouched.
          if (academy) return;
          game.recordDuelResult(
            won: outcome == DuelOutcome.won,
            opponentLevel: driver.opponentLevel,
            // ⭐ **The one place that can tell a human from a persona**
            // (ruling 2026-08-17: only a PvP loss pays XP). `campaign`
            // cannot answer it — a practice bout is campaign:false and still
            // single player — but the driver can: a room is remote,
            // everything else is a brain on this device.
            pvp: driver is RemoteDuelDriver,
          );
        },
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
  bool academy = false,
}) => launchDuel(
  context,
  loadout: loadout,
  // An Academy stand-in fights at the Academy's level like everyone there.
  driver: LocalAiDriver(
    persona: persona,
    levelOverride: academy ? Academy.level : null,
  ),
  campaign: campaign,
  academy: academy,
);
