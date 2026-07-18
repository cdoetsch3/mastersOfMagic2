import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';
import 'opponent_driver.dart';

/// UI-facing snapshot of a shield (engine shields mutate in place, so the
/// controller keeps its own copies for lagged display during animations).
class ShownShield {
  final MagicElement? element;
  final bool isBarrier;
  int remaining;

  ShownShield({this.element, this.isBarrier = false, this.remaining = 0});
}

/// Holds the engine, drives turns through an [OpponentDriver], and exposes a
/// *display* state that lags the engine while turn animations play.
///
/// The controller is side-aware: in remote duels the local player may be the
/// host (engine mage1) or the guest (mage2) — both clients run the identical
/// engine in lockstep, seeded per turn by the driver.
class DuelController extends ChangeNotifier {
  final Loadout loadout;
  final OpponentDriver driver;

  late DuelEngine engine;
  late MageState player;
  late MageState enemy;
  final ReseedableRandom _rng = ReseedableRandom();

  // Display state (lags engine during animation).
  late int shownPlayerHp;
  late int shownEnemyHp;
  int shownPlayerCharge = 0;
  int shownEnemyCharge = 0;
  MagicElement? shownPlayerElement;
  bool enemyIsCharging = false;
  MagicElement? revealedEnemyElement;
  ShownShield? shownPlayerShield;
  ShownShield? shownEnemyShield;
  bool playerDefeated = false;
  bool enemyDefeated = false;

  // Selection state.
  MagicElement? pendingElement;
  bool animating = false;

  /// True while the commit-reveal exchange is in flight (remote duels).
  bool waitingForOpponent = false;

  /// Forfeiting this many turns in a row is treated as surrendering — it is
  /// how a player who closed their tab (forfeiting every turn via timeout)
  /// is handed their loss instead of dragging the duel out forever.
  static const int forfeitLimit = 3;
  int _myForfeitStreak = 0;
  int _theirForfeitStreak = 0;

  final List<String> battleLog = [];

  DuelController({required this.loadout, required this.driver}) {
    newDuel();
    driver.watchOpponentSurrender(_onOpponentSurrendered);
  }

  bool get playerIsHost => driver.playerIsHost;

  void newDuel() {
    player = MageState(name: 'You');
    enemy = MageState(name: driver.opponentName);
    final host = playerIsHost ? player : enemy;
    final guest = playerIsHost ? enemy : player;
    engine = DuelEngine(host, guest, rng: _rng);
    final d = driver;
    if (d is LocalAiDriver) d.bind(player, enemy);
    shownPlayerHp = player.hp;
    shownEnemyHp = enemy.hp;
    shownPlayerCharge = 0;
    shownEnemyCharge = 0;
    shownPlayerElement = null;
    enemyIsCharging = false;
    revealedEnemyElement = null;
    shownPlayerShield = null;
    shownEnemyShield = null;
    playerDefeated = false;
    enemyDefeated = false;
    pendingElement = null;
    animating = false;
    waitingForOpponent = false;
    _myForfeitStreak = 0;
    _theirForfeitStreak = 0;
    battleLog.clear();
    notifyListeners();
  }

  bool get gameOver => engine.isOver && !animating;
  bool get playerWon => engine.winner == player;
  bool get isDraw => engine.isDraw;
  bool get needsElement => player.charge == 0 && pendingElement == null;
  int get turnNumber => engine.turnNumber;

  bool canAfford(Spell spell) =>
      spell.xCost ? player.charge >= 1 : spell.chargeCost <= player.charge;

  bool canAct(Spell spell) =>
      !animating && !engine.isOver && canAfford(spell) &&
      (player.charge > 0 || pendingElement != null);

  bool get canCharge =>
      !animating && !engine.isOver && player.charge < MageState.maxCharge &&
      (player.charge > 0 || pendingElement != null);

  void selectElement(MagicElement element) {
    if (animating || player.charge > 0) return;
    pendingElement = element;
    notifyListeners();
  }

  /// Exchanges moves through the driver, resolves the turn, and returns the
  /// events for the screen to animate ([applyEvent] after each).
  Future<List<DuelEvent>> submitTurn(MageAction action) async {
    animating = true;
    waitingForOpponent = true;
    notifyListeners();

    final TurnExchange exchange;
    try {
      exchange = await driver.exchangeTurn(engine.turnNumber + 1, action);
    } finally {
      waitingForOpponent = false;
      notifyListeners();
    }

    // The opponent may have surrendered while the exchange was in flight
    // (the watcher already ended the duel) — nothing left to resolve.
    if (engine.isOver) {
      animating = false;
      notifyListeners();
      return const [];
    }

    if (exchange.turnSeed != null) _rng.reseed(exchange.turnSeed!);
    final theirs = exchange.opponentAction;
    final hostAction = playerIsHost ? action : theirs;
    final guestAction = playerIsHost ? theirs : action;
    final result = engine.resolveTurn(hostAction, guestAction);
    battleLog.add('— Turn ${result.turn}');
    battleLog.addAll(result.events.map(_describe));
    _trackForfeits(action, theirs);
    notifyListeners();
    return result.events;
  }

  /// Applies the [forfeitLimit] rule after a turn resolves: whichever side
  /// has forfeited that many turns in a row surrenders the duel.
  void _trackForfeits(MageAction mine, MageAction theirs) {
    _myForfeitStreak = mine is ForfeitAction ? _myForfeitStreak + 1 : 0;
    _theirForfeitStreak = theirs is ForfeitAction ? _theirForfeitStreak + 1 : 0;
    if (engine.isOver) return;
    if (_myForfeitStreak >= forfeitLimit) {
      engine.concede(player);
      playerDefeated = true;
      shownPlayerHp = 0;
      battleLog.add(
          'You forfeited $forfeitLimit turns in a row and surrender. '
          '${enemy.name} wins.');
      driver.reportSurrender(); // fire-and-forget: tell the remote peer
    } else if (_theirForfeitStreak >= forfeitLimit) {
      engine.concede(enemy);
      enemyDefeated = true;
      shownEnemyHp = 0;
      battleLog.add('${enemy.name} left the duel. You win!');
    }
  }

  MageAction chargeAction() =>
      ChargeAction(player.charge == 0 ? pendingElement : null);

  MageAction castAction(Spell spell) =>
      CastAction(spell, player.charge == 0 ? pendingElement : null);

  /// Advances the display state past [event] (called after its animation).
  void applyEvent(DuelEvent event) {
    switch (event) {
      case ChargedEvent(:final mage, :final element, :final newCharge):
        if (mage == player) {
          shownPlayerCharge = newCharge;
          shownPlayerElement = element;
        } else {
          shownEnemyCharge = newCharge;
          enemyIsCharging = true;
          // You can see what the enemy is charging — unless Concealed (a
          // future Shadow effect), which keeps the mystery "?".
          revealedEnemyElement = enemy.concealed ? null : element;
        }
      case SpellCastEvent(:final caster, :final element):
        if (caster == player) {
          shownPlayerCharge = 0;
          shownPlayerElement = null;
        } else {
          shownEnemyCharge = 0;
          enemyIsCharging = false;
          revealedEnemyElement = element;
        }
      case ShieldRaisedEvent(:final mage, :final shield):
        final snapshot = ShownShield(
          element: shield.element,
          isBarrier: shield.isBarrier,
          remaining: shield.remaining,
        );
        if (mage == player) {
          shownPlayerShield = snapshot;
        } else {
          shownEnemyShield = snapshot;
        }
      case DamageEvent(:final target, :final toShield, :final shieldBroken):
        final shield = target == player ? shownPlayerShield : shownEnemyShield;
        if (shieldBroken) {
          if (target == player) {
            shownPlayerShield = null;
          } else {
            shownEnemyShield = null;
          }
        } else if (shield != null && toShield > 0) {
          shield.remaining -= toShield;
        }
        shownPlayerHp = player == target ? _clampHp(event) : shownPlayerHp;
        shownEnemyHp = enemy == target ? _clampHp(event) : shownEnemyHp;
      case HealedEvent(:final mage, :final amount):
        if (mage == player) {
          shownPlayerHp = (shownPlayerHp + amount).clamp(0, player.maxHp);
        } else {
          shownEnemyHp = (shownEnemyHp + amount).clamp(0, enemy.maxHp);
        }
      case DefeatedEvent(:final mage):
        if (mage == player) playerDefeated = true;
        if (mage == enemy) enemyDefeated = true;
      case ChargeDrainedEvent(:final mage):
        if (mage == player) {
          shownPlayerCharge = 0;
          shownPlayerElement = null;
        } else {
          shownEnemyCharge = 0;
          enemyIsCharging = false;
          revealedEnemyElement = null;
        }
      case HasteChangedEvent():
      case ForfeitedEvent():
      case BuffAppliedEvent():
        break;
    }
    notifyListeners();
  }

  int _clampHp(DamageEvent event) {
    final shown = event.target == player ? shownPlayerHp : shownEnemyHp;
    return (shown - event.toHp).clamp(0, event.target.maxHp);
  }

  /// Forfeit the duel ("surrender" in PvP, "flee" in the campaign).
  void surrender({String verb = 'surrender'}) {
    if (engine.isOver || animating) return;
    engine.concede(player);
    playerDefeated = true;
    shownPlayerHp = 0;
    battleLog.add('You $verb. ${enemy.name} wins.');
    driver.reportSurrender(); // fire-and-forget: tell the remote peer
    notifyListeners();
  }

  /// The remote opponent surrendered: the duel ends right now as a win,
  /// whether this player was mid-exchange or idle at the move picker.
  void _onOpponentSurrendered() {
    if (engine.isOver) return;
    engine.concede(enemy);
    enemyDefeated = true;
    shownEnemyHp = 0;
    battleLog.add('${enemy.name} surrenders. You win!');
    notifyListeners();
  }

  /// Called by the screen once every event animation has played.
  void finishTurn() {
    animating = false;
    if (player.charge == 0) pendingElement = null;
    // Persistently show what the enemy is currently charging, unless they
    // are Concealed (a future Shadow effect) — then it stays a mystery.
    revealedEnemyElement = enemy.concealed ? null : enemy.element;
    enemyIsCharging = enemy.charge > 0 && enemy.element != null;
    notifyListeners();
  }

  String _describe(DuelEvent event) {
    // Only mask the enemy's charged element while they are Concealed.
    if (event is ChargedEvent && event.mage == enemy && enemy.concealed) {
      return '${enemy.name} channels an unknown element '
          '(charge ${event.newCharge})';
    }
    return event.toString();
  }

  @override
  void dispose() {
    driver.dispose();
    super.dispose();
  }
}
