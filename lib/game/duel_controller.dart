import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';

/// UI-facing snapshot of a shield (engine shields mutate in place, so the
/// controller keeps its own copies for lagged display during animations).
class ShownShield {
  final MagicElement? element;
  final bool isBarrier;
  int remaining;

  ShownShield({this.element, this.isBarrier = false, this.remaining = 0});
}

/// Holds the engine, drives turns, and exposes a *display* state that lags
/// the engine while turn animations play (the engine resolves a whole turn
/// instantly; the UI reveals it event by event).
class DuelController extends ChangeNotifier {
  final Random rng;
  late DuelEngine engine;
  late MageState player;
  late MageState enemy;
  final DuelAi enemyAi = GreedyAi();

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
  final List<String> battleLog = [];

  final Loadout loadout;
  final String enemyName;

  DuelController({
    required this.loadout,
    this.enemyName = 'Procarius',
    int? seed,
  }) : rng = Random(seed) {
    newDuel();
  }

  void newDuel() {
    player = MageState(name: 'You');
    enemy = MageState(name: enemyName);
    engine = DuelEngine(player, enemy, rng: rng);
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

  /// Resolves a turn and returns the events for the screen to animate.
  /// The screen must call [applyEvent] after animating each one.
  List<DuelEvent> submitTurn(MageAction action) {
    final enemyAction = enemyAi.chooseAction(enemy, player, rng);
    animating = true;
    final result = engine.resolveTurn(action, enemyAction);
    battleLog.add('— Turn ${result.turn}');
    battleLog.addAll(result.events.map(_describe));
    notifyListeners();
    return result.events;
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
    notifyListeners();
  }

  /// Called by the screen once every event animation has played.
  void finishTurn() {
    animating = false;
    if (player.charge == 0) pendingElement = null;
    // After the turn, the enemy's element is only knowable via their shield.
    revealedEnemyElement = null;
    notifyListeners();
  }

  String _describe(DuelEvent event) {
    // Mask the enemy's charged element in the player-facing log.
    if (event is ChargedEvent && event.mage == enemy) {
      return '${enemy.name} channels an unknown element '
          '(charge ${event.newCharge})';
    }
    return event.toString();
  }
}
