import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/flee.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

/// Fleeing a campaign duel (2026-08-17 ruling): a rolled escape, not a
/// surrender. Success ends the run the way walking out does; failure costs the
/// turn and nothing else.
void main() {
  group('the ruled escape formula', () {
    // ⚠️ Every constant below is the RULING, not a tuning knob. A test that
    // recomputed the formula from `Flee`'s own constants would pass through any
    // re-tune; these are hand-written anchors on purpose.

    test('even level, both at full health: 80%', () {
      expect(
        Flee.percent(
          playerLevel: 5,
          enemyLevel: 5,
          playerHp: 100,
          playerMaxHp: 100,
          enemyHp: 120,
          enemyMaxHp: 120,
        ),
        80,
        reason: 'the even-fight baseline is 0.80 and nothing else applies',
      );
    });

    test('even level, you at 10% and the enemy at 55%: about 46%', () {
      // 0.80 + 0.75 × (0.10 − 0.55) = 0.4625 → 46%.
      expect(
        Flee.percent(
          playerLevel: 3,
          enemyLevel: 3,
          playerHp: 10,
          playerMaxHp: 100,
          enemyHp: 110,
          enemyMaxHp: 200,
        ),
        46,
        reason: 'health is the dominant term: 0.75 × a 45-point deficit',
      );
    });

    test('+4 levels with both at full health hits the 95% ceiling', () {
      // 0.80 + 0.05 × 4 = 1.00, which the ceiling cuts to 0.95.
      expect(
        Flee.percent(
          playerLevel: 9,
          enemyLevel: 5,
          playerHp: 80,
          playerMaxHp: 80,
          enemyHp: 60,
          enemyMaxHp: 60,
        ),
        95,
        reason: '⚠️ escape is never certain — the ceiling must bind here',
      );
    });

    test("death's door against something ten levels up: the 20% floor", () {
      // Level edge clamps to −5 (−0.25); health edge is −0.99 (−0.7425).
      // 0.80 − 0.25 − 0.7425 = −0.19, floored to 0.20.
      expect(
        Flee.percent(
          playerLevel: 2,
          enemyLevel: 12,
          playerHp: 1,
          playerMaxHp: 100,
          enemyHp: 300,
          enemyMaxHp: 300,
        ),
        20,
        reason: 'the floor is what keeps a losing fight from being a cage',
      );
    });

    test('the ceiling holds even at maximum advantage', () {
      // +40 levels, untouched, against a boss on its last hit point: 1.79 raw.
      expect(
        Flee.percent(
          playerLevel: 45,
          enemyLevel: 5,
          playerHp: 400,
          playerMaxHp: 400,
          enemyHp: 1,
          enemyMaxHp: 500,
          rank: EnemyRank.boss,
        ),
        95,
        reason: 'no amount of advantage buys a guaranteed escape',
      );
    });

    group('rank is what a creature is worth to an escape', () {
      test('common, mini-boss, boss: 80%, 70%, 60% at the baseline', () {
        int at(EnemyRank rank) => Flee.percent(
          playerLevel: 4,
          enemyLevel: 4,
          playerHp: 50,
          playerMaxHp: 50,
          enemyHp: 90,
          enemyMaxHp: 90,
          rank: rank,
        );
        expect(at(EnemyRank.common), 80, reason: 'commons cost nothing');
        expect(at(EnemyRank.mini), 70, reason: 'a mini-boss costs 10 points');
        expect(at(EnemyRank.boss), 60, reason: 'a boss costs 20');
      });

      test('a rank-less caller pays no penalty', () {
        expect(
          Flee.percent(
            playerLevel: 1,
            enemyLevel: 1,
            playerHp: 100,
            playerMaxHp: 100,
            enemyHp: 100,
            enemyMaxHp: 100,
          ),
          80,
          reason: 'the default rank must be the free one',
        );
      });
    });

    group('clamp ordering', () {
      test('⭐ the rank penalty applies BEFORE the floor', () {
        // The mutant this kills: clamping first and subtracting the penalty
        // after, which reads 0.20 − 0.20 = 0% — a boss you can never escape.
        expect(
          Flee.percent(
            playerLevel: 1,
            enemyLevel: 20,
            playerHp: 1,
            playerMaxHp: 200,
            enemyHp: 400,
            enemyMaxHp: 400,
            rank: EnemyRank.boss,
          ),
          20,
          reason: 'cornered by a boss is still the 20% floor, never worse',
        );
      });

      test('the ceiling survives the penalty too', () {
        // A boss at max advantage: 0.80 + 0.25 + 0.75 − 0.20 = 1.60 → 0.95.
        expect(
          Flee.percent(
            playerLevel: 30,
            enemyLevel: 10,
            playerHp: 300,
            playerMaxHp: 300,
            enemyHp: 1,
            enemyMaxHp: 1000,
            rank: EnemyRank.boss,
          ),
          95,
        );
      });
    });

    test('the level edge is capped at ±5 before it is weighted', () {
      // Uncapped, +40 levels would be +2.00 and the rank penalty would be
      // invisible under the ceiling; capped, the boss penalty still shows.
      expect(
        Flee.percent(
          playerLevel: 45,
          enemyLevel: 5,
          playerHp: 50,
          playerMaxHp: 100,
          enemyHp: 100,
          enemyMaxHp: 100,
          rank: EnemyRank.boss,
        ),
        // 0.80 + 0.25 + 0.75 × (0.5 − 1.0) − 0.20 = 0.475.
        48,
        reason: '⚠️ an uncapped level edge would read 95% here',
      );
      expect(
        Flee.percent(
          playerLevel: 1,
          enemyLevel: 41,
          playerHp: 100,
          playerMaxHp: 100,
          enemyHp: 50,
          enemyMaxHp: 100,
        ),
        // 0.80 − 0.25 + 0.75 × 0.5 = 0.925 — the cap is why this is not floored.
        93,
        reason: 'a 40-level deficit clamps to −5 like a 5-level one',
      );
    });

    test('a zero-size health pool cannot poison the number', () {
      // ⚠️ NaN clamps to neither bound; a broken percentage would ship.
      final chance = Flee.chance(
        playerLevel: 1,
        enemyLevel: 1,
        playerHp: 0,
        playerMaxHp: 0,
        enemyHp: 0,
        enemyMaxHp: 0,
      );
      expect(chance.isNaN, isFalse);
      expect(chance, inInclusiveRange(Flee.floor, Flee.ceiling));
    });
  });

  group('the controller rolls the escape', () {
    test('a winning roll ends the duel as fled: no winner, no defeat', () {
      final duel = _campaignDuel(rank: EnemyRank.common);
      // Even level, both full: 80%. A roll under it gets away.
      duel.rng.force(0.10);
      expect(duel.controller.attemptFlee(), isTrue);

      final c = duel.controller;
      expect(c.fled, isTrue);
      expect(c.gameOver, isTrue, reason: 'the fight is over the moment we go');
      expect(c.outcome, DuelOutcome.fled);
      expect(c.playerWon, isFalse, reason: 'nobody won a fight nobody finished');
      expect(c.isDraw, isFalse, reason: 'a draw is a result; this is not');
      expect(
        c.playerDefeated,
        isFalse,
        reason: '⚠️ the flag the run wipe hangs off must stay down',
      );
      expect(
        c.player.hp,
        greaterThan(0),
        reason: 'escaping must not route through concede()',
      );
      expect(c.enemy.hp, greaterThan(0));
      expect(c.turnNumber, 0, reason: 'the escape beat the enemy to the punch');
    });

    test('a losing roll leaves the duel running and costs the turn', () async {
      final duel = _campaignDuel(rank: EnemyRank.common);
      final c = duel.controller;
      duel.rng.force(0.99); // above any chance the formula can produce
      expect(c.attemptFlee(), isFalse);
      expect(c.fled, isFalse);
      expect(c.gameOver, isFalse, reason: 'a failed escape ends nothing');

      await c.submitTurn(const ForfeitAction(), fleeAttempt: true);
      c.finishTurn();
      expect(c.turnNumber, 1, reason: 'the turn resolved against us');
      expect(
        c.player.charge,
        0,
        reason: 'we did nothing with our turn — that is the price',
      );
      expect(
        c.enemy.charge > 0 || c.player.hp < c.player.maxHp,
        isTrue,
        reason: '⭐ the enemy got a free action out of it',
      );
      expect(
        c.battleLog.any((l) => l.contains('forfeit')),
        isTrue,
        reason: 'the log has to show the turn was given away',
      );
    });

    test('the roll reads the live chance, not a fixed number', () {
      final duel = _campaignDuel(rank: EnemyRank.common);
      final c = duel.controller;
      expect(c.fleePercent, 80, reason: 'even level, both at full');
      c.player.hp = c.player.maxHp ~/ 2;
      // The ruling restated by hand rather than by calling Flee again: half
      // health against a full-health even-level common.
      final expected =
          ((0.80 + 0.75 * (c.player.hp / c.player.maxHp - 1.0)) * 100).round();
      expect(expected, inInclusiveRange(41, 43), reason: 'sanity: about 42%');
      expect(
        c.fleePercent,
        expected,
        reason: 'bleeding out must move the number the button shows',
      );
      // 0.50 clears 80% but not ~42% — same roll, two answers.
      duel.rng.force(0.50);
      expect(c.attemptFlee(), isFalse);
    });

    test('a boss is harder to run from than a common', () {
      expect(_campaignDuel(rank: EnemyRank.common).controller.fleePercent, 80);
      expect(_campaignDuel(rank: EnemyRank.mini).controller.fleePercent, 70);
      expect(_campaignDuel(rank: EnemyRank.boss).controller.fleePercent, 60);
    });

    test('the ceiling really can fail: a 0.95 roll at 95% does not escape', () {
      final duel = _campaignDuel(rank: EnemyRank.common, playerLevel: 9);
      expect(duel.controller.fleePercent, 95);
      duel.rng.force(0.95);
      expect(
        duel.controller.attemptFlee(),
        isFalse,
        reason: '⚠️ `< chance`, so the top 5% is a real sliver',
      );
    });

    test('fleeing an already-finished duel does nothing', () {
      final duel = _campaignDuel(rank: EnemyRank.common);
      duel.controller.surrender();
      duel.rng.force(0.0);
      expect(duel.controller.attemptFlee(), isFalse);
      expect(
        duel.controller.fled,
        isFalse,
        reason: 'a conceded duel must not be retconned into an escape',
      );
    });

    test('⭐ three failed escapes in a row do NOT auto-surrender', () async {
      // ⚠️ The regression this exists for: the forfeit-streak rule was built
      // for a player who closed their tab, and it would otherwise convert
      // three unlucky rolls into the surrender — and the run wipe — that the
      // whole flee ruling exists to spare them.
      final duel = _campaignDuel(rank: EnemyRank.common);
      final c = duel.controller;
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        duel.rng.force(0.999);
        expect(c.attemptFlee(), isFalse, reason: 'attempt ${i + 1} must fail');
        await c.submitTurn(const ForfeitAction(), fleeAttempt: true);
        c.finishTurn();
      }
      expect(
        c.battleLog.any((l) => l.contains('turns in a row')),
        isFalse,
        reason: 'the streak rule must never have fired',
      );
      expect(
        c.gameOver,
        isFalse,
        reason: '⚠️ three unlucky rolls are not a surrender',
      );
      expect(c.playerDefeated, isFalse);
      expect(c.turnNumber, DuelController.forfeitLimit);
    });

    test('a flee attempt clears a timeout streak already in progress', () async {
      // Deciding to run is proof of a live player, which is the only thing the
      // streak rule is trying to detect.
      final duel = _campaignDuel(rank: EnemyRank.common);
      final c = duel.controller;
      await c.submitTurn(const ForfeitAction()); // timed out
      c.finishTurn();
      await c.submitTurn(const ForfeitAction()); // timed out again
      c.finishTurn();
      duel.rng.force(0.999);
      expect(c.attemptFlee(), isFalse);
      await c.submitTurn(const ForfeitAction(), fleeAttempt: true);
      c.finishTurn();
      expect(
        c.gameOver,
        isFalse,
        reason: 'the third forfeit was a flee, so the streak reset',
      );
    });

    test('an ordinary forfeit streak still surrenders the duel', () async {
      // ⚠️ The exemption must not have disarmed the rule it is exempt from.
      final duel = _campaignDuel(rank: EnemyRank.common);
      final c = duel.controller;
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        await c.submitTurn(const ForfeitAction());
        c.finishTurn();
      }
      expect(c.gameOver, isTrue);
      expect(c.playerDefeated, isTrue);
      expect(c.fled, isFalse, reason: 'that was a surrender, not an escape');
      expect(c.outcome, DuelOutcome.lost);
    });

    test('a fresh duel forgets the escape', () {
      final duel = _campaignDuel(rank: EnemyRank.common);
      duel.rng.force(0.0);
      expect(duel.controller.attemptFlee(), isTrue);
      duel.controller.newDuel();
      expect(duel.controller.fled, isFalse);
      expect(duel.controller.gameOver, isFalse);
      expect(duel.controller.outcome, DuelOutcome.lost, reason: 'nothing yet');
    });
  });

  group('a fled run is a walk-out, never a defeat', () {
    test('the haul and the backpack both survive', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));
      await game.winEncounter(remainingHp: 80, rng: Random(3));
      // (2026-08-17 loot model: a win's drops sit on run.unclaimed until the
      // picker answers for them — fleeing must leave that batch intact.)
      final haul = game.run!.unclaimed.length;
      expect(haul, greaterThan(0), reason: 'the fixture needs a drop');
      final packBefore = game.profile.backpack.used;

      await game.fleeEncounter(remainingHp: 22);

      expect(
        game.run!.outcome,
        RunOutcome.returned,
        reason: '⭐ fleeing ends the run the way walking out does',
      );
      expect(
        game.run!.unclaimed,
        hasLength(haul),
        reason: '⚠️ the mutant this kills: routing flee through loseEncounter',
      );
      expect(
        game.profile.backpack.used,
        packBefore,
        reason: 'nothing touches the pack until the picker is answered',
      );
      expect(game.run!.playerHp, 22, reason: 'the HP escaped with is recorded');
    });

    test('it pays no XP, no gold, and records no loss', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(5));
      final xp = game.profile.xp;
      final gold = game.profile.gold;
      final lost = game.profile.duelsLost;
      final won = game.profile.duelsWon;

      await game.fleeEncounter(remainingHp: 40);

      expect(
        game.profile.xp,
        xp,
        reason: 'a duel nobody won pays nothing — not even the loss floor',
      );
      expect(game.profile.gold, gold);
      expect(
        game.profile.duelsLost,
        lost,
        reason: '⚠️ an escape is not a defeat on the record either',
      );
      expect(game.profile.duelsWon, won);
      expect(
        Progression.lossXp,
        greaterThan(0),
        reason: 'the check above only means something while a loss DOES pay',
      );
    });

    test('and the run is over — no fighting on after running away', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(7));
      await game.fleeEncounter(remainingHp: 50);
      expect(game.run!.isOver, isTrue);
      expect(game.run!.current, isNull);
      // A second call is a no-op rather than a second ending.
      await game.fleeEncounter(remainingHp: 1);
      expect(game.run!.playerHp, 50);
    });

    test('dying is still the punishing path (the contrast)', () async {
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));
      await game.winEncounter(remainingHp: 80, rng: Random(3));
      expect(game.run!.unclaimed, isNotEmpty);
      await game.loseEncounter();
      expect(game.run!.outcome, RunOutcome.died);
      expect(game.run!.unclaimed, isEmpty,
          reason: 'defeat forfeits the unanswered batch (recordDefeat)');
      expect(game.profile.backpack.used, 0,
          reason: 'the 2026-08-17 wipe: death costs the inventory');
      expect(game.profile.duelsLost, 1);
    });
  });

  group('the arena button', () {
    testWidgets('a campaign fight shows the live escape chance', (tester) async {
      await _pumpDuel(tester, campaign: true);
      expect(
        find.text('Flee (80%)'),
        findsOneWidget,
        reason: '⭐ ruled: the number is on the button, not hidden in a dialog',
      );
      expect(find.text('Surrender'), findsNothing);
    });

    testWidgets('a boss fight shows its harder number', (tester) async {
      await _pumpDuel(tester, campaign: true, rank: EnemyRank.boss);
      expect(find.text('Flee (60%)'), findsOneWidget);
    });

    testWidgets('a PvP duel keeps plain Surrender', (tester) async {
      await _pumpDuel(tester, campaign: false);
      expect(
        find.text('Surrender'),
        findsOneWidget,
        reason: '⚠️ the escape roll is campaign-only',
      );
      expect(find.textContaining('Flee'), findsNothing);
    });

    testWidgets('the dialog sells the odds, not a loss', (tester) async {
      final rng = _ScriptedRandom();
      await _pumpDuel(tester, campaign: true, rng: rng);
      await tester.tap(find.text('Flee (80%)'));
      await tester.pump();
      expect(find.text('Run for it?'), findsOneWidget);
      expect(
        find.textContaining('80% chance'),
        findsOneWidget,
        reason: 'the confirm has to restate what is being gambled',
      );
      expect(
        find.textContaining('counts as a loss'),
        findsNothing,
        reason: '⚠️ the old copy was the old ruling — fleeing is not a loss',
      );
    });

    testWidgets('⭐ a successful escape settles the run as fled', (
      tester,
    ) async {
      final rng = _ScriptedRandom();
      DuelOutcome? settled;
      await _pumpDuel(
        tester,
        campaign: true,
        rng: rng,
        onSettle: (outcome, hp) async {
          settled = outcome;
          return const [];
        },
      );
      await tester.tap(find.text('Flee (80%)'));
      await tester.pump();
      rng.force(0.01); // a clean getaway
      await tester.tap(find.text('Flee (80%)').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        settled,
        DuelOutcome.fled,
        reason: '⚠️ the mutant this kills: the campaign branch calling '
            'surrender(), which would settle as lost and wipe the run',
      );
      expect(find.text('Escaped'), findsOneWidget);
      expect(find.text('Defeat'), findsNothing);
    });

    testWidgets('a failed escape keeps fighting and settles nothing', (
      tester,
    ) async {
      final rng = _ScriptedRandom();
      DuelOutcome? settled;
      await _pumpDuel(
        tester,
        campaign: true,
        rng: rng,
        onSettle: (outcome, hp) async {
          settled = outcome;
          return const [];
        },
      );
      await tester.tap(find.text('Flee (80%)'));
      await tester.pump();
      rng.force(0.99); // no escape
      await tester.tap(find.text('Flee (80%)').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(settled, isNull, reason: 'the duel is still going');
      expect(find.text('Escaped'), findsNothing);
      expect(
        find.textContaining('Flee ('),
        findsWidgets,
        reason: 'the button is still there to try again — flat odds, no decay',
      );
    });
  });
}

// ---- fixtures -------------------------------------------------------------

final _woods = World.byId('whispering_woods');

/// A bestiary entry of [rank] from Zone 1 — real content, so the rank penalty
/// is read off the same field the game reads.
EnemyDef _enemyOf(EnemyRank rank) =>
    Bestiary.forZone('whispering_woods').firstWhere((e) => e.rank == rank);

/// ⚠️ Scripts exactly ONE `nextDouble`, then falls back to the real stream.
///
/// The engine draws from this same stream while resolving a turn (miss checks,
/// Ignite, Static), so a queue of scripted values would be eaten by whichever
/// caller happened to be next. Forcing a single value immediately before
/// [DuelController.attemptFlee] pins the flee roll and nothing else.
class _ScriptedRandom extends ReseedableRandom {
  double? _forced;

  _ScriptedRandom() : super(1);

  void force(double value) => _forced = value;

  @override
  double nextDouble() {
    final forced = _forced;
    _forced = null;
    return forced ?? super.nextDouble();
  }
}

typedef _Duel = ({DuelController controller, _ScriptedRandom rng});

/// A campaign duel against a creature of [rank], both sides at full health and
/// (by default) the same level — the 80% baseline.
_Duel _campaignDuel({required EnemyRank rank, int playerLevel = 5}) {
  final def = _enemyOf(rank);
  final rng = _ScriptedRandom();
  final controller = DuelController(
    loadout: Loadout.starter,
    driver: LocalAiDriver(
      persona: EnemyEncounter(def: def, level: 5).toPersona(),
      enemy: def,
      rng: Random(2),
    ),
    playerLevel: playerLevel,
    rng: rng,
  );
  return (controller: controller, rng: rng);
}

Future<void> _pumpDuel(
  WidgetTester tester, {
  required bool campaign,
  EnemyRank rank = EnemyRank.common,
  _ScriptedRandom? rng,
  Future<List<String>> Function(DuelOutcome outcome, int remainingHp)? onSettle,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final def = _enemyOf(rank);
  await tester.pumpWidget(
    MaterialApp(
      home: DuelScreen(
        loadout: Loadout.starter,
        driver: LocalAiDriver(
          persona: EnemyEncounter(def: def, level: 1).toPersona(),
          enemy: def,
          rng: Random(2),
        ),
        campaign: campaign,
        playerLevel: 1,
        rng: rng,
        onSettle: onSettle,
      ),
    ),
  );
  // Bounded pumps: the arena animates continuously, so it never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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
