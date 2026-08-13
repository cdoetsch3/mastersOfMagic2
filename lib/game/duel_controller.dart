import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'items/item_def.dart';
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

  /// Barrier POINTS (0–3), separate from the elemental shield — the two stack
  /// and each point blocks one hit.
  int shownPlayerBarrier = 0;
  int shownEnemyBarrier = 0;

  /// Status pips, advanced one event at a time as the turn animates rather
  /// than read from live engine state (which is already final the moment the
  /// turn resolves, so every pip would appear at once). Fed by the frames the
  /// engine records alongside its events.
  StatusSnapshot shownPlayerStatuses = StatusSnapshot.empty;
  StatusSnapshot shownEnemyStatuses = StatusSnapshot.empty;
  List<StatusFrame> _frames = const [];

  /// True between the turn resolving and its animation finishing. The engine's
  /// turn counter has already advanced by then, so anything the HUD shows for
  /// "this turn" has to read one turn back while this is set.
  bool _replaying = false;

  /// The moon the HUD should show.
  ///
  /// While a turn is being animated this is the moon that actually governed
  /// **that** turn, so it matches the Lunar damage the player is watching land.
  /// Once the turn finishes it advances to the turn they are about to act in.
  MoonPhase get shownMoonPhase =>
      _replaying ? moonPhaseForTurn(engine.turnNumber) : engine.moonPhase;

  /// The phase after [shownMoonPhase] — the "next turn" preview.
  MoonPhase get shownNextMoonPhase => _replaying
      ? moonPhaseForTurn(engine.turnNumber + 1)
      : engine.nextMoonPhase;
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
  ///
  /// ⚠️ **Deliberately NOT exempted for local AI**, even though a local brain
  /// cannot disconnect and so can only forfeit through a bug. A Sporecap
  /// Shambler once charged to full, decided every one of its moves was
  /// worthless against a standing Barrier, and forfeited its way into
  /// conceding the fight (fixed in `LadderAi._score`). Two reasons to leave
  /// the rule alone: the brain now treats [ForfeitAction] as "no legal move
  /// exists" rather than "no move looks good", so the streak is unreachable
  /// for any creature with a move it can afford from zero — which every
  /// creature is required to have; and the rule is the only thing that
  /// guarantees a duel terminates if that invariant is ever broken again. An
  /// AI-only branch here would be dead code that makes the *next* stalemate
  /// hang forever instead of ending loudly.
  static const int forfeitLimit = 3;
  int _myForfeitStreak = 0;
  int _theirForfeitStreak = 0;

  final List<String> battleLog = [];

  /// The player's character level, for health and damage scaling.
  final int playerLevel;

  /// ⭐ Health carried in from an adventure. Null starts at full.
  ///
  /// ⚠️ Applied to the *player only* — an encounter's enemy is always fresh,
  /// because the run's tension is the player's dwindling health, not a chain
  /// of half-dead monsters.
  final int? playerStartingHp;

  /// What the player's gear adds up to (Equipping.totals). ⭐ **Applied to
  /// the player's MageState only** — enemies get their numbers from their
  /// archetype, never from items.
  final ItemModifiers playerGear;

  DuelController({
    required this.loadout,
    required this.driver,
    this.playerLevel = 1,
    this.playerStartingHp,
    this.playerGear = ItemModifiers.none,
  }) {
    newDuel();
    driver.watchOpponentSurrender(_onOpponentSurrendered);
  }

  bool get playerIsHost => driver.playerIsHost;

  void newDuel() {
    // ⭐ Level scales health and damage on both sides (4%/level). An
    // even-level duel plays exactly as it always did; a level gap is now
    // worth something.
    // ⭐ Gear reaches the duel HERE, and only here (ITEMS §9b.8): flat HP on
    // the constructor, everything else onto the MageState fields the engine
    // already rolls. critDamage ADDS to the engine's 50 base, so Cinder
    // Loop's 5 points read 155%, exactly as ruled.
    player = MageState(
      name: 'You',
      level: playerLevel,
      maxHp: MageState.scaledMaxHp(playerLevel) + playerGear.maxHpBonus,
    )
      ..accuracyBonus = playerGear.accuracyBonus
      ..dodge = playerGear.dodge
      ..critChance = playerGear.critChance
      ..critDamage = 50 + playerGear.critDamage
      ..deflectChance = playerGear.deflectChance
      ..deflectAmount = playerGear.deflectAmount
      ..damagePerCast = playerGear.damagePerCast
      ..damagePerCharge = playerGear.damagePerCharge
      ..shieldStrengthPercent = playerGear.shieldStrengthPercent
      ..healingReceivedPercent = playerGear.healingReceivedPercent;
    // ⭐ Regrow rides the status machinery (item_status.dart), so the lane
    // sort and the HUD pip come for free. Permanent: gear is not taken off
    // mid-duel.
    if (playerGear.regrowPercent > 0) {
      player.statuses.add(RegrowStatus(playerGear.regrowPercent));
    }
    final carried = playerStartingHp;
    if (carried != null) player.hp = carried.clamp(1, player.maxHp);
    // ⭐ An enemy is the level baseline TIMES its archetype (ENEMIES §1.1), so
    // a Glasswing and a Redoubt of the same level are genuinely different
    // fights rather than the same fight with different names.
    enemy = MageState(
      name: driver.opponentName,
      level: driver.opponentLevel,
      maxHp:
          (MageState.scaledMaxHp(driver.opponentLevel) * driver.opponentHpScale)
              .round(),
    )..powerScale = driver.opponentPowerScale;
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
    shownPlayerBarrier = 0;
    shownEnemyBarrier = 0;
    shownPlayerStatuses = StatusSnapshot.empty;
    shownEnemyStatuses = StatusSnapshot.empty;
    _frames = const [];
    _replaying = false;
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
      !animating &&
      !engine.isOver &&
      canAfford(spell) &&
      (player.charge > 0 || pendingElement != null);

  bool get canCharge =>
      !animating &&
      !engine.isOver &&
      player.charge < MageState.maxCharge &&
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
    // The counter has advanced; hold the HUD on the turn being replayed.
    _replaying = true;
    _frames = result.frames;
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
        '${enemy.name} wins.',
      );
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
  ///
  /// [index] is the event's position in the turn — pass it so the status pips
  /// step forward with the animation. Omit it and the pips hold still.
  void applyEvent(DuelEvent event, {int? index}) {
    if (index != null && index < _frames.length) {
      final frame = _frames[index];
      final playerIsMage1 = identical(player, engine.mage1);
      shownPlayerStatuses = playerIsMage1 ? frame.mage1 : frame.mage2;
      shownEnemyStatuses = playerIsMage1 ? frame.mage2 : frame.mage1;
    }
    _applyEventInner(event);
  }

  void _applyEventInner(DuelEvent event) {
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
      case ShieldRaisedEvent(
        :final mage,
        :final element,
        :final isBarrier,
        :final strength,
      ):
        final snapshot = ShownShield(
          element: element,
          isBarrier: isBarrier,
          remaining: strength,
        );
        // A Barrier occupies its own slot and never displaces the elemental
        // shield the player paid for.
        if (isBarrier) {
          // `strength` is the resulting point count.
          if (mage == player) {
            shownPlayerBarrier = strength;
          } else {
            shownEnemyBarrier = strength;
          }
        } else if (mage == player) {
          shownPlayerShield = snapshot;
        } else {
          shownEnemyShield = snapshot;
        }
      case DamageEvent(
        :final target,
        :final toShield,
        :final shieldBroken,
        :final barrierPopped,
      ):
        if (barrierPopped) {
          // One point ate the hit; the shield behind it is intact.
          if (target == player) {
            shownPlayerBarrier = (shownPlayerBarrier - 1).clamp(0, 3);
          } else {
            shownEnemyBarrier = (shownEnemyBarrier - 1).clamp(0, 3);
          }
        } else {
          final shield = target == player
              ? shownPlayerShield
              : shownEnemyShield;
          if (shieldBroken) {
            if (target == player) {
              shownPlayerShield = null;
            } else {
              shownEnemyShield = null;
            }
          } else if (shield != null && toShield > 0) {
            shield.remaining -= toShield;
          }
        }
        shownPlayerHp = player == target ? _clampHp(event) : shownPlayerHp;
        shownEnemyHp = enemy == target ? _clampHp(event) : shownEnemyHp;
      case HealedEvent(:final mage, :final amount):
        if (mage == player) {
          shownPlayerHp = (shownPlayerHp + amount).clamp(0, player.maxHp);
        } else {
          shownEnemyHp = (shownEnemyHp + amount).clamp(0, enemy.maxHp);
        }
      case EffectDamageEvent(
        :final target,
        :final toShield,
        :final toHp,
        :final shieldBroken,
        :final barrierPopped,
      ):
        // A status tick (e.g. Ignite) — same display bookkeeping as a hit.
        if (barrierPopped) {
          if (target == player) {
            shownPlayerBarrier = (shownPlayerBarrier - 1).clamp(0, 3);
          } else {
            shownEnemyBarrier = (shownEnemyBarrier - 1).clamp(0, 3);
          }
        } else {
          final shield = target == player
              ? shownPlayerShield
              : shownEnemyShield;
          if (shieldBroken) {
            if (target == player) {
              shownPlayerShield = null;
            } else {
              shownEnemyShield = null;
            }
          } else if (shield != null && toShield > 0) {
            shield.remaining -= toShield;
          }
        }
        if (target == player) {
          shownPlayerHp = (shownPlayerHp - toHp).clamp(0, player.maxHp);
        } else {
          shownEnemyHp = (shownEnemyHp - toHp).clamp(0, enemy.maxHp);
        }
      case EffectHealEvent(:final mage, :final amount):
        if (mage == player) {
          shownPlayerHp = (shownPlayerHp + amount).clamp(0, player.maxHp);
        } else {
          shownEnemyHp = (shownEnemyHp + amount).clamp(0, enemy.maxHp);
        }
      case DefeatedEvent(:final mage):
        if (mage == player) playerDefeated = true;
        if (mage == enemy) enemyDefeated = true;
      case ChargeDrainedEvent(:final mage, :final amount):
        // Two very different drains share this event: Discharge wipes ALL
        // charge, Static Feedback strips exactly 1. Subtract the reported
        // amount — zeroing unconditionally made a 1-charge Static proc look
        // like a full wipe and wrongly forgot the element you were still
        // charging (which is what a fizzle then looked like).
        if (mage == player) {
          shownPlayerCharge = (shownPlayerCharge - amount).clamp(0, 5);
          if (shownPlayerCharge == 0) shownPlayerElement = null;
        } else {
          shownEnemyCharge = (shownEnemyCharge - amount).clamp(0, 5);
          if (shownEnemyCharge == 0) {
            enemyIsCharging = false;
            revealedEnemyElement = null;
          }
        }
      case SpellMissedEvent(:final caster):
        // Blinded miss — charge is still spent, so reset like a normal cast.
        if (caster == player) {
          shownPlayerCharge = 0;
          shownPlayerElement = null;
        } else {
          shownEnemyCharge = 0;
          enemyIsCharging = false;
        }
      case SpellFizzledEvent():
        // Fizzle keeps the charge (nothing was cast) — no display change.
        break;
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
    _replaying = false;
    // Settle the pips on the turn's true final state. Frames only capture the
    // moment each EVENT was emitted, but a turn keeps mutating after its last
    // event — end-phase bookkeeping, the charge sweep, decay. Without this,
    // anything that changes after the final event would not show until some
    // later turn happened to emit an event and snapshot it.
    shownPlayerStatuses = StatusSnapshot.of(player);
    shownEnemyStatuses = StatusSnapshot.of(enemy);
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
    return toSecondPerson(event.toString());
  }

  /// The engine writes log lines in the third person from each mage's name
  /// ("Morwen casts…"). The local player is named **You**, so those same
  /// templates come out as "You forfeits" and "You's charge is drained" —
  /// fix the agreement rather than duplicating every template per person.
  @visibleForTesting
  static String toSecondPerson(String line) {
    if (!line.startsWith('You')) return line;
    // Possessive first: "You's Bolt fizzles" → "Your Bolt fizzles".
    var s = line.replaceFirst("You's", 'Your');
    // Copula: "You is defeated" / "You is blinded" → "You are …".
    s = s.replaceFirst(RegExp(r'^You is\b'), 'You are');
    // Third-person singular verbs sitting directly after the subject.
    const verbs = {
      'channels': 'channel',
      'casts': 'cast',
      'raises': 'raise',
      'takes': 'take',
      'drains': 'drain',
      'seizes': 'seize',
      'forfeits': 'forfeit',
      'suffers': 'suffer',
      'heals': 'heal',
    };
    for (final MapEntry(key: third, value: base) in verbs.entries) {
      if (s.startsWith('You $third ')) {
        return s.replaceFirst('You $third ', 'You $base ');
      }
    }
    return s;
  }

  @override
  void dispose() {
    driver.dispose();
    super.dispose();
  }
}
