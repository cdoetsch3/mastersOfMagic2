import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
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

  /// ⭐ Settable, because in a remote duel these two ARE the wire: whatever
  /// the other client claimed about itself is all this side ever knows.
  @override
  int opponentLevel = 1;

  @override
  ItemModifiers opponentGear = ItemModifiers.none;

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
          reason: 'a driver reporting no gear must leave the enemy bare');
      expect(geared.enemy.statuses.whereType<RegrowStatus>(), isEmpty);
    });

    test('a remote rival\'s gear lands on the ENEMY, and only the enemy', () {
      // ⭐ ITEMS §7.4: PvP is the GEARED ladder, so what they are wearing is
      // part of the fight — and it arrives over the wire, from the driver.
      final duel = DuelController(
        loadout: Loadout.starter,
        driver: FakeRemoteDriver()
          ..opponentGear = const ItemModifiers(
            maxHpBonus: 20,
            accuracyBonus: 3,
            dodge: 4,
            critChance: 7,
            critDamage: 5,
            deflectChance: 2,
            deflectAmount: 6,
            damagePerCast: 2,
            damagePerCharge: 1,
            shieldStrengthPercent: 15,
            healingReceivedPercent: 8,
            regrowPercent: 3,
          ),
      );
      expect(duel.enemy.maxHp, 120);
      expect(duel.enemy.hp, 120, reason: 'they start full at the bigger pool');
      expect(duel.enemy.accuracyBonus, 3);
      expect(duel.enemy.dodge, 4);
      expect(duel.enemy.critChance, 7);
      // ⭐ The same 50-base ruling applies to THEIR crits, or the two clients
      // roll different crit damage from the same seed.
      expect(duel.enemy.critDamage, 55);
      expect(duel.enemy.deflectChance, 2);
      expect(duel.enemy.deflectAmount, 6);
      expect(duel.enemy.damagePerCast, 2);
      expect(duel.enemy.damagePerCharge, 1);
      expect(duel.enemy.shieldStrengthPercent, 15);
      expect(duel.enemy.healingReceivedPercent, 8);
      expect(
        duel.enemy.statuses.whereType<RegrowStatus>().single.percentPerTurn,
        3,
        reason: 'their Regrow must tick on our machine too',
      );
      // ⚠️ Their wardrobe is theirs — none of it may leak onto us.
      expect(duel.player.maxHp, 100);
      expect(duel.player.accuracyBonus, 0);
      expect(duel.player.critDamage, 50);
      expect(duel.player.statuses.whereType<RegrowStatus>(), isEmpty);
    });

    test('⭐ both clients build the same two mages (the lockstep rule)', () {
      // The whole point of the fix: A applies its OWN gear locally and B's
      // from the wire, B does the mirror image — so A's enemy must come out
      // byte-identical to the player B built for itself, and vice versa.
      // Deliberately asymmetric levels AND kit: equal ones would pass even
      // if one side's numbers were being used for both mages.
      const mine = ItemModifiers(
        maxHpBonus: 30,
        accuracyBonus: 5,
        critChance: 5,
        critDamage: 5,
        damagePerCast: 3,
        regrowPercent: 2,
      );
      const theirs = ItemModifiers(
        maxHpBonus: 11,
        dodge: 9,
        deflectChance: 4,
        deflectAmount: 7,
        damagePerCharge: 2,
        shieldStrengthPercent: 20,
        healingReceivedPercent: 12,
      );
      final myClient = DuelController(
        loadout: Loadout.starter,
        driver: FakeRemoteDriver()
          ..opponentLevel = 9
          ..opponentGear = theirs,
        playerLevel: 4,
        playerGear: mine,
      );
      final theirClient = DuelController(
        loadout: Loadout.starter,
        driver: FakeRemoteDriver()
          ..opponentLevel = 4
          ..opponentGear = mine,
        playerLevel: 9,
        playerGear: theirs,
      );

      void sameMage(MageState a, MageState b, String who) {
        expect(a.level, b.level, reason: '$who level');
        expect(a.maxHp, b.maxHp, reason: '$who maxHp');
        expect(a.hp, b.hp, reason: '$who starting hp');
        expect(a.accuracyBonus, b.accuracyBonus, reason: '$who accuracy');
        expect(a.dodge, b.dodge, reason: '$who dodge');
        expect(a.critChance, b.critChance, reason: '$who crit chance');
        expect(a.critDamage, b.critDamage, reason: '$who crit damage');
        expect(a.deflectChance, b.deflectChance, reason: '$who deflect chance');
        expect(a.deflectAmount, b.deflectAmount, reason: '$who deflect amount');
        expect(a.damagePerCast, b.damagePerCast, reason: '$who per cast');
        expect(a.damagePerCharge, b.damagePerCharge, reason: '$who per charge');
        expect(a.powerScale, b.powerScale, reason: '$who power scale');
        expect(
          a.shieldStrengthPercent,
          b.shieldStrengthPercent,
          reason: '$who shield strength',
        );
        expect(
          a.healingReceivedPercent,
          b.healingReceivedPercent,
          reason: '$who healing received',
        );
        expect(
          a.statuses.whereType<RegrowStatus>().map((s) => s.percentPerTurn),
          b.statuses.whereType<RegrowStatus>().map((s) => s.percentPerTurn),
          reason: '$who regrow',
        );
      }

      sameMage(myClient.enemy, theirClient.player, 'the rival');
      sameMage(theirClient.enemy, myClient.player, 'us');
      // ⚠️ And the two are genuinely different mages — otherwise the checks
      // above are satisfied by everyone being identical.
      expect(myClient.player.maxHp, isNot(myClient.enemy.maxHp));
    });

    test('a local AI opponent brings no wardrobe at all', () {
      // ⚠️ Campaign foes get archetypes, never items (ENEMIES §2.1) — the
      // gear seam must not have quietly opened a second power source.
      final persona = AiRoster.all.first;
      final duel = DuelController(
        loadout: Loadout.starter,
        driver: LocalAiDriver(persona: persona),
        playerGear: const ItemModifiers(maxHpBonus: 50, critDamage: 20),
      );
      expect(duel.enemy.maxHp, MageState.scaledMaxHp(persona.level));
      expect(duel.enemy.critDamage, 50);
      expect(duel.enemy.statuses.whereType<RegrowStatus>(), isEmpty);
      expect(duel.player.maxHp, 150, reason: 'ours still counts');
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
