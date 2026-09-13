import 'package:flutter/material.dart';

import '../screens/duel_screen.dart';
import '../screens/level_up_screen.dart';
import 'academy.dart';
import 'ai_personas.dart';
import 'duel_controller.dart';
import 'game_state.dart';
import 'items/item_def.dart';
import 'ladder/ladder_bots.dart';
import 'ladder/ladder_result.dart';
import 'ladder/think_time.dart';
import 'loadout.dart';
import 'opponent_driver.dart';

/// Finds the [LadderBot] behind [driver], or null when it isn't one —
/// [LocalAiDriver.thinkTime] is set ONLY by the ladder path ([launchAiDuel]'s
/// [LadderBot] branch below), so a practice-roster fight against a persona
/// that happens to share an id with a borrowed bot (Wick, Brightgale,
/// Thornwall, Morwen, Al'Dorian) is correctly NOT treated as rated.
LadderBot? _ladderBotBehind(OpponentDriver driver) {
  if (driver is! LocalAiDriver || driver.thinkTime == null) return null;
  for (final bot in LadderRoster.all) {
    if (bot.id == driver.persona.id) return bot;
  }
  return null;
}

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
          // records neither a win nor a loss (2026-08-17 ruling), and it is
          // never rated either — nobody actually finished the fight.
          if (outcome == DuelOutcome.fled) return;
          final won = outcome == DuelOutcome.won;
          // ⭐ Academy banks no XP/gold/win-count (ruled 2026-09-10) — the
          // character is untouched — but it DOES rate (LADDER §1 law 4).
          // Geared banks XP/gold AND rates.
          if (!academy) {
            game.recordDuelResult(
              won: won,
              opponentLevel: driver.opponentLevel,
              // ⭐ **The one place that can tell a human from a persona**
              // (ruling 2026-08-17: only a PvP loss pays XP). `campaign`
              // cannot answer it — a practice bout is campaign:false and
              // still single player — but the driver can: a room is remote,
              // everything else is a brain on this device.
              pvp: driver is RemoteDuelDriver,
            );
          }
          // ⭐ LADDER §2: a quickMatch human (RemoteDuelDriver.rated) or a
          // ladder bot rates; a room-code duel or a practice-roster persona
          // does not. `settleRatedDuel` itself also refuses an unrated
          // RemoteDuelDriver, so this check is belt-and-braces, not the only
          // guard.
          final bot = _ladderBotBehind(driver);
          final rated = driver is RemoteDuelDriver ? driver.rated : bot != null;
          if (rated) {
            settleRatedDuel(
              game,
              driver: driver,
              academy: academy,
              won: won,
              // ⭐ Whatever the driver was built with: the wire's number for
              // a human, the search's live-or-seed number for a bot. The
              // header showed this same figure, so what the player saw is
              // what the result is measured against.
              opponentRating: driver.opponentRating,
            );
          }
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

/// Convenience: a duel against a named AI persona, OR a LADDER bot.
///
/// ⚠️ **Exactly one of [persona]/[bot] is expected.** The practice roster
/// (AiRoster) passes [persona] alone — no gear, no think-time, unrated. LADDER
/// matchmaking passes [bot] alone: its wardrobe ([LadderBot.gearModifiers])
/// and [ThinkTime.standard] both ride along, and [bot]'s presence is exactly
/// what [_ladderBotBehind] reads back out to decide the duel is rated.
Future<void> launchAiDuel(
  BuildContext context, {
  required Loadout loadout,
  AiPersona? persona,
  LadderBot? bot,
  // The rating the search held [bot] at (`MatchResult.botRating`); null
  // falls back to the bot's seed on this ladder. Ignored for a persona.
  int? rating,
  required bool campaign,
  bool academy = false,
}) {
  assert(
    (persona == null) != (bot == null),
    'launchAiDuel needs exactly one of persona or bot',
  );
  return launchDuel(
    context,
    loadout: loadout,
    // An Academy stand-in fights at the Academy's level like everyone there.
    driver: LocalAiDriver(
      persona: bot?.toPersona() ?? persona!,
      levelOverride: academy ? Academy.level : null,
      // ⚠️ A bot's gear is stripped in the Academy exactly like a player's —
      // duelInputsFor already strips OURS, but that seam never touches the
      // opponent, so the bot's own wardrobe has to be zeroed here.
      gear: bot == null
          ? ItemModifiers.none
          : (academy ? ItemModifiers.none : bot.gearModifiers),
      thinkTime: bot == null ? null : ThinkTime.standard,
      rating: bot == null
          ? 1200
          : rating ?? (academy ? bot.seedAcademy : bot.seedGeared),
    ),
    campaign: campaign,
    academy: academy,
  );
}
