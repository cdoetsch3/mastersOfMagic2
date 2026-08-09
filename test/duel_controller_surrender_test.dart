import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';

/// A scriptable stand-in for a remote opponent: records surrender reports,
/// exposes the surrender callback, and can hold an exchange in flight.
class FakeRemoteDriver implements OpponentDriver {
  @override
  double get opponentHpScale => 1.0;

  @override
  double get opponentPowerScale => 1.0;

  @override
  int get opponentLevel => 1;

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
    controller = DuelController(loadout: Loadout.starter, driver: driver);
  });

  group('gear reaches the duel (ITEMS §9b.8)', () {
    test('the totals land on the player MageState, and only the player', () {
      final geared = DuelController(
        loadout: Loadout.starter,
        driver: FakeRemoteDriver(),
        playerLevel: 1,
        playerGear: const ItemModifiers(
          maxHpBonus: 12,
          accuracyBonus: 5,
          critChance: 5,
          critDamage: 5,
          damagePerCharge: 1,
          shieldStrengthPercent: 10,
          healingReceivedPercent: 10,
          regrowPercent: 2,
        ),
      );
      expect(geared.player.maxHp, 112,
          reason: 'flat HP must reach the constructor, not be added after');
      expect(geared.player.accuracyBonus, 5);
      expect(geared.player.damagePerCharge, 1);
      // ⭐ The ruling: crit = 150% base + points. Engine base is 50, so the
      // Cinder Loop's 5 points must read 55, never 5.
      expect(geared.player.critDamage, 55);
      expect(geared.player.shieldStrengthPercent, 10);
      expect(geared.player.healingReceivedPercent, 10);
      // ⭐ Regrow arrives as a status, so the HUD pip and the heal-lane
      // ordering come for free.
      expect(geared.player.statuses.whereType<RegrowStatus>(), isNotEmpty);
      expect(geared.enemy.accuracyBonus, 0,
          reason: 'enemies get archetypes, never the player\'s wardrobe');
      expect(geared.enemy.statuses.whereType<RegrowStatus>(), isEmpty);
    });

    test('an unequipped player is byte-identical to the old baseline', () {
      final bare = DuelController(
        loadout: Loadout.starter,
        driver: FakeRemoteDriver(),
      );
      expect(bare.player.maxHp, 100);
      expect(bare.player.critChance, 0);
      expect(bare.player.critDamage, 50,
          reason: 'the engine default, untouched by empty gear');
    });
  });

  test('surrendering tells the driver so the remote peer finds out', () {
    controller.surrender();
    expect(driver.surrenderReported, isTrue);
    expect(controller.gameOver, isTrue);
    expect(controller.playerWon, isFalse);
  });

  test('opponent surrender while idle ends the duel as a win', () {
    expect(
      driver.onOpponentSurrendered,
      isNotNull,
      reason: 'controller must start the surrender watch',
    );
    driver.onOpponentSurrendered!();
    expect(controller.gameOver, isTrue);
    expect(controller.playerWon, isTrue);
    expect(controller.enemyDefeated, isTrue);
    expect(controller.battleLog.last, contains('surrenders'));
  });

  test(
    'opponent surrender lands mid-exchange without resolving the turn',
    () async {
      final events = controller.submitTurn(
        const ChargeAction(MagicElement.pyro),
      );
      driver.onOpponentSurrendered!(); // surrender arrives while we wait
      // The (now moot) exchange completes afterwards.
      driver.pendingExchange!.complete(const TurnExchange(ForfeitAction(), 42));
      expect(
        await events,
        isEmpty,
        reason: 'no turn events after the duel already ended',
      );
      expect(controller.gameOver, isTrue);
      expect(controller.playerWon, isTrue);
      expect(controller.turnNumber, 0, reason: 'the turn never resolved');
    },
  );

  test('opponent surrender after the duel is over is ignored', () {
    controller.surrender();
    driver.onOpponentSurrendered!(); // late arrival — must not throw
    expect(
      controller.playerWon,
      isFalse,
      reason: 'our surrender stands; the duel outcome does not flip',
    );
  });

  group('forfeit streaks (closed tab / AFK)', () {
    test('forfeiting 3 turns in a row surrenders the duel', () async {
      driver.autoRespond = const ChargeAction(MagicElement.aqua);
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        expect(controller.gameOver, isFalse);
        await controller.submitTurn(const ForfeitAction());
        controller.finishTurn();
      }
      expect(controller.gameOver, isTrue);
      expect(controller.playerWon, isFalse);
      expect(
        driver.surrenderReported,
        isTrue,
        reason: 'the remote peer must be told, so their duel ends too',
      );
    });

    test('an opponent forfeiting 3 turns in a row hands us the win', () async {
      driver.autoRespond = const ForfeitAction();
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        expect(controller.gameOver, isFalse);
        await controller.submitTurn(const ChargeAction(MagicElement.pyro));
        controller.finishTurn();
      }
      expect(controller.gameOver, isTrue);
      expect(controller.playerWon, isTrue);
      expect(controller.battleLog.last, contains('left the duel'));
    });

    test('a real move resets the forfeit streak', () async {
      driver.autoRespond = const ChargeAction(MagicElement.aqua);
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ChargeAction(MagicElement.pyro));
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      expect(
        controller.gameOver,
        isFalse,
        reason: 'streak broke at 2 — never reached the limit',
      );
      expect(driver.surrenderReported, isFalse);
    });
  });
}
