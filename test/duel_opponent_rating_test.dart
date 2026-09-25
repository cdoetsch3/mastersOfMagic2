/// Ratings on the arena's nameplates (LADDER_DESIGN §7 item 5: "opponent
/// card shows rating + record for everyone"; Christian, 2026-09-25: the
/// player's own rating beside their name, on the same ladder, and nothing on
/// either side of an unrated duel).
///
/// ⭐ Mutation-verified: names the wrong implementation it kills — a rating
/// that never reaches the widget tree, a player rating resolved differently
/// from the settler's, a campaign/practice foe wearing its driver's
/// placeholder 1200, and a driver default that silently drops to 0.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:masters_of_magic_2/ui/rating_text.dart';
import 'package:mom_engine/mom_engine.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

void main() {
  /// Builds the arena under a real [GameStateScope] holding [profile] — the
  /// way `launchDuel` reaches it — and stops at the first frame.
  Future<void> arena(
    WidgetTester tester, {
    required PlayerProfile profile,
    required OpponentDriver driver,
    bool campaign = false,
    bool academy = false,
  }) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GameStateScope(
        state: GameState(_Mem(), profile),
        child: MaterialApp(
          home: DuelScreen(
            loadout: Loadout.starter,
            driver: driver,
            campaign: campaign,
            academy: academy,
            playerLevel: 5,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// A nameplate's rating, exactly as `_StatusPanel` prints it: one rich
  /// Text reading '· N'.
  Finder plate(int rating) => find.text('· $rating');

  LocalAiDriver ladderDriver(LadderBot bot, int rating) => LocalAiDriver(
    persona: bot.toPersona(),
    gear: bot.gearModifiers,
    ladderBot: true,
    rating: rating,
    rng: Random(1),
  );

  testWidgets('a rated bot duel shows BOTH ratings, one per nameplate', (
    tester,
  ) async {
    final profile = PlayerProfile.newPlayer()..ratingGeared = 1432;
    await arena(
      tester,
      profile: profile,
      driver: ladderDriver(LadderRoster.byId('hesper'), 1569),
    );

    expect(
      plate(1569),
      findsOneWidget,
      reason:
          'opponentRating is plumbed from LocalAiDriver.rating through to '
          "the enemy nameplate — a widget that never reads driver."
          'opponentRating would never show this number',
    );
    expect(
      plate(1432),
      findsOneWidget,
      reason:
          'the player\'s own geared rating sits beside their name — a '
          'mutant that leaves the player panel\'s rating null (the '
          'pre-2026-09-25 arena) shows only the opponent\'s',
    );
  });

  testWidgets('the player plate reads the ladder the duel is ON', (
    tester,
  ) async {
    final profile = PlayerProfile.newPlayer()
      ..ratingGeared = 1432
      ..ratingAcademy = 1255;
    await arena(
      tester,
      profile: profile,
      academy: true,
      driver: ladderDriver(LadderRoster.byId('hesper'), 1200),
    );

    expect(
      plate(1255),
      findsOneWidget,
      reason: 'an Academy bout shows the Academy rating',
    );
    expect(
      plate(1432),
      findsNothing,
      reason:
          'a mutant that always reads ratingGeared would print the geared '
          '1432 in an Academy bout',
    );
  });

  testWidgets('a first rated match shows the SEED the settler will rate from', (
    tester,
  ) async {
    // Never rated on the geared ladder: ratingGeared is null.
    final profile = PlayerProfile.newPlayer();
    await arena(
      tester,
      profile: profile,
      driver: ladderDriver(LadderRoster.byId('wick'), 1107),
    );

    final seed = LadderSeeds.gearedPlayer(level: profile.level);
    expect(
      plate(seed),
      findsOneWidget,
      reason:
          'a first-timer is rated from the level seed (settleRatedDuel via '
          'playerRatingOn) — a mutant that falls back to 1200, or shows '
          'nothing until a rating is banked, would disagree with the '
          'number the result is then measured from',
    );
  });

  testWidgets('a campaign fight shows NEITHER rating', (tester) async {
    final profile = PlayerProfile.newPlayer()..ratingGeared = 1432;
    await arena(
      tester,
      profile: profile,
      campaign: true,
      driver: LocalAiDriver(
        persona: const EnemyEncounter(
          def: WhisperingWoodsBestiary.sporecapShambler,
          level: 3,
        ).toPersona(),
        enemy: WhisperingWoodsBestiary.sporecapShambler,
        rng: Random(1),
      ),
    );

    expect(
      plate(1432),
      findsNothing,
      reason:
          'a campaign fight rates nothing — a mutant that shows the '
          'player\'s rating whenever a profile is in scope fails here',
    );
    expect(
      plate(1200),
      findsNothing,
      reason:
          'the driver\'s default 1200 is a placeholder, not a rating — a '
          'mutant that still prints opponentRating on every duel shows it '
          'on a mushroom',
    );
  });

  testWidgets('campaign stays unrated even behind a ladder-flagged driver', (
    tester,
  ) async {
    final profile = PlayerProfile.newPlayer()..ratingGeared = 1432;
    await arena(
      tester,
      profile: profile,
      campaign: true,
      driver: ladderDriver(LadderRoster.byId('hesper'), 1569),
    );

    expect(
      plate(1569),
      findsNothing,
      reason:
          'campaign is checked on its own, not only through the driver — a '
          'mutant that trusts isRatedDuel alone rates a campaign bout here',
    );
    expect(
      plate(1432),
      findsNothing,
      reason: 'and the player\'s side follows the same rule',
    );
  });

  testWidgets('a practice persona (not a ladder bot) shows neither rating', (
    tester,
  ) async {
    final profile = PlayerProfile.newPlayer()..ratingGeared = 1432;
    await arena(
      tester,
      profile: profile,
      driver: LocalAiDriver(
        persona: AiRoster.all.first,
        rating: 1569,
        rng: Random(1),
      ),
    );

    expect(
      plate(1569),
      findsNothing,
      reason:
          'practice never rates (ladderBot: false) — a mutant keyed on '
          '!campaign alone would print a rating on a sparring dummy',
    );
    expect(
      plate(1432),
      findsNothing,
      reason: 'nor the player\'s, on a duel that will not move it',
    );
  });

  testWidgets('both plates print in the one rating style', (tester) async {
    final profile = PlayerProfile.newPlayer()..ratingGeared = 1432;
    await arena(
      tester,
      profile: profile,
      driver: ladderDriver(LadderRoster.byId('hesper'), 1569),
    );

    for (final r in [1432, 1569]) {
      final text = tester.widget<Text>(plate(r));
      final numberSpan =
          (text.textSpan! as TextSpan).children!.single as TextSpan;
      expect(
        numberSpan.style?.color,
        RatingText.colour,
        reason:
            'the $r on the nameplate is a RatingText span — a mutant that '
            'kept the old dim grey number would fail this',
      );
    }
  });

  test('OpponentDriver.opponentRating defaults to 1200', () {
    final driver = LocalAiDriver(persona: AiRoster.all.first, rng: Random(1));
    expect(
      driver.opponentRating,
      1200,
      reason:
          'campaign and practice callers never pass a rating — a driver '
          'that defaults to 0 (or omits the override entirely) would '
          'break the documented Academy-seed floor',
    );
  });
}
