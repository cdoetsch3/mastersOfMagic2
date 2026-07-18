import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';

/// A scriptable stand-in for a remote opponent: records surrender reports,
/// exposes the surrender callback, and can hold an exchange in flight.
class FakeRemoteDriver implements OpponentDriver {
  bool surrenderReported = false;
  void Function()? onOpponentSurrendered;
  Completer<TurnExchange>? pendingExchange;

  /// When set, exchanges resolve instantly with this opponent action
  /// (instead of waiting on [pendingExchange]).
  MageAction? autoRespond;

  @override
  String get opponentName => 'Rival';

  @override
  MageApparel get opponentApparel => MageApparel.duskWitch;

  @override
  bool get playerIsHost => true;

  @override
  bool get supportsRematch => false;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) {
    final scripted = autoRespond;
    if (scripted != null) return Future.value(TurnExchange(scripted, turn));
    pendingExchange = Completer<TurnExchange>();
    return pendingExchange!.future;
  }

  @override
  Future<void> reportSurrender() async {
    surrenderReported = true;
  }

  @override
  void watchOpponentSurrender(void Function() onSurrendered) {
    onOpponentSurrendered = onSurrendered;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late FakeRemoteDriver driver;
  late DuelController controller;

  setUp(() {
    driver = FakeRemoteDriver();
    controller =
        DuelController(loadout: Loadout.starter, driver: driver);
  });

  test('surrendering tells the driver so the remote peer finds out', () {
    controller.surrender();
    expect(driver.surrenderReported, isTrue);
    expect(controller.gameOver, isTrue);
    expect(controller.playerWon, isFalse);
  });

  test('opponent surrender while idle ends the duel as a win', () {
    expect(driver.onOpponentSurrendered, isNotNull,
        reason: 'controller must start the surrender watch');
    driver.onOpponentSurrendered!();
    expect(controller.gameOver, isTrue);
    expect(controller.playerWon, isTrue);
    expect(controller.enemyDefeated, isTrue);
    expect(controller.battleLog.last, contains('surrenders'));
  });

  test('opponent surrender lands mid-exchange without resolving the turn',
      () async {
    final events =
        controller.submitTurn(const ChargeAction(MagicElement.fire));
    driver.onOpponentSurrendered!(); // surrender arrives while we wait
    // The (now moot) exchange completes afterwards.
    driver.pendingExchange!
        .complete(const TurnExchange(ForfeitAction(), 42));
    expect(await events, isEmpty,
        reason: 'no turn events after the duel already ended');
    expect(controller.gameOver, isTrue);
    expect(controller.playerWon, isTrue);
    expect(controller.turnNumber, 0, reason: 'the turn never resolved');
  });

  test('opponent surrender after the duel is over is ignored', () {
    controller.surrender();
    driver.onOpponentSurrendered!(); // late arrival — must not throw
    expect(controller.playerWon, isFalse,
        reason: 'our surrender stands; the duel outcome does not flip');
  });

  group('forfeit streaks (closed tab / AFK)', () {
    test('forfeiting 3 turns in a row surrenders the duel', () async {
      driver.autoRespond = const ChargeAction(MagicElement.water);
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        expect(controller.gameOver, isFalse);
        await controller.submitTurn(const ForfeitAction());
        controller.finishTurn();
      }
      expect(controller.gameOver, isTrue);
      expect(controller.playerWon, isFalse);
      expect(driver.surrenderReported, isTrue,
          reason: 'the remote peer must be told, so their duel ends too');
    });

    test('an opponent forfeiting 3 turns in a row hands us the win',
        () async {
      driver.autoRespond = const ForfeitAction();
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        expect(controller.gameOver, isFalse);
        await controller.submitTurn(const ChargeAction(MagicElement.fire));
        controller.finishTurn();
      }
      expect(controller.gameOver, isTrue);
      expect(controller.playerWon, isTrue);
      expect(controller.battleLog.last, contains('left the duel'));
    });

    test('a real move resets the forfeit streak', () async {
      driver.autoRespond = const ChargeAction(MagicElement.water);
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ChargeAction(MagicElement.fire));
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      expect(controller.gameOver, isFalse,
          reason: 'streak broke at 2 — never reached the limit');
      expect(driver.surrenderReported, isFalse);
    });
  });
}
