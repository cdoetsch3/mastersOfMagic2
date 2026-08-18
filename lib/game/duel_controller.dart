import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

import 'enemies/enemy_def.dart';
import 'flee.dart';
import 'items/belt_potions.dart';
import 'items/item_def.dart';
import 'loadout.dart';
import 'opponent_driver.dart';

/// How a duel ended, for everyone downstream of the arena.
///
/// ⭐ **Three outcomes, not a bool.** A campaign escape is neither a win nor a
/// loss (2026-08-17 ruling): it pays no XP, records no defeat, and must never
/// reach `GameState.loseEncounter`. Encoding it as `won: false` is exactly the
/// bug this enum exists to make impossible — every seam that used to carry
/// `won` now carries the outcome, so the fled case has to be *handled* rather
/// than silently defaulting to the punishing branch.
enum DuelOutcome {
  won,

  /// Defeated, conceded, or drawn — the paths that pay a loss.
  lost,

  /// Ran away clean. Nobody won.
  fled,
}

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

  /// The duel's ONE random stream — the engine resolves turns from it, the
  /// driver reseeds it per turn in remote duels, and [attemptFlee] rolls from
  /// it too.
  ///
  /// ⭐ The flee roll deliberately shares the stream rather than opening a
  /// private `Random()`: a duel's luck is one seeded sequence, so a scripted
  /// stream can pin "this escape failed" in a test instead of replaying the
  /// fight until the dice cooperate.
  final ReseedableRandom _rng;

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

  /// ⭐ The player got clean away (campaign only, 2026-08-17 ruling). Both
  /// mages are still standing and the engine still thinks the fight is live —
  /// this flag is the ending. ⚠️ Distinct from [playerDefeated] on purpose:
  /// downstream, defeat wipes a run and this does not.
  bool _fled = false;
  bool get fled => _fled;

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

  /// What the player's gear adds up to (Equipping.totals).
  ///
  /// ⭐ **Always the LOCAL player's own equipment**, read from local state.
  /// The opposite number is [OpponentDriver.opponentGear], which arrives over
  /// the wire — a local AI reports none, so campaign enemies stay pure
  /// archetype (ENEMIES §2.1) while a human rival brings their wardrobe
  /// (ITEMS §7.4).
  final ItemModifiers playerGear;

  /// The consumables the player carried in, by def id, in slot order.
  ///
  /// ⚠️ **Mutable, and deliberately not reset by [newDuel].** A drunk potion
  /// is gone; a rematch does not refill the belt any more than it refills the
  /// pack. Everything else in [newDuel] is duel state, which is exactly why
  /// this lives outside it.
  final List<String> _belt;

  /// What is still on the belt right now — what the arena draws.
  List<String> get beltItems => List.unmodifiable(_belt);

  /// Persists the loss of one belt item, immediately — the seam
  /// `GameState.consumeBeltItem` fills.
  ///
  /// ⭐ A callback rather than a `GameState`: the controller is built by tests
  /// and by two different screens, and none of them should have to construct a
  /// profile to fight. Null simply means nothing to save — a practice duel.
  final Future<void> Function(String defId)? onItemConsumed;

  DuelController({
    required this.loadout,
    required this.driver,
    this.playerLevel = 1,
    this.playerStartingHp,
    this.playerGear = ItemModifiers.none,
    List<String> belt = const [],
    this.onItemConsumed,
    ReseedableRandom? rng,
  }) : _belt = [...belt],
       _rng = rng ?? ReseedableRandom() {
    newDuel();
    driver.watchOpponentSurrender(_onOpponentSurrendered);
  }

  bool get playerIsHost => driver.playerIsHost;

  /// Builds one duellist: the level baseline, times its archetype, plus what
  /// it is wearing.
  ///
  /// ⚠️ **Both mages are built here, and nowhere else.** In a remote duel the
  /// enemy this client builds must be bit-for-bit the player the OTHER client
  /// builds for itself — same level, same totals, same fields — or the two
  /// machines resolve different fights from the same seed. Two copies of this
  /// arithmetic, one per side, is precisely how they would drift apart; one
  /// function called twice cannot.
  ///
  /// Gear reaches the duel HERE, and only here (ITEMS §9b.8): flat HP into the
  /// constructor (so `hp` starts full at the boosted maximum, not below it),
  /// everything else onto the MageState fields the engine already rolls.
  static MageState _buildMage({
    required String name,
    required int level,
    required ItemModifiers gear,
    double hpScale = 1.0,
  }) {
    final mage = MageState(
      name: name,
      level: level,
      // ⚠️ Archetype scales the BASELINE; gear is flat on top. Scaling the
      // gear too would make a Redoubt's hat worth more than a mage's.
      maxHp: (MageState.scaledMaxHp(level) * hpScale).round() + gear.maxHpBonus,
    )
      ..accuracyBonus = gear.accuracyBonus
      ..dodge = gear.dodge
      ..critChance = gear.critChance
      // ⭐ critDamage ADDS to the engine's 50 base, so Cinder Loop's 5 points
      // read 155%, exactly as ruled.
      ..critDamage = 50 + gear.critDamage
      ..deflectChance = gear.deflectChance
      ..deflectAmount = gear.deflectAmount
      ..damagePerCast = gear.damagePerCast
      ..damagePerCharge = gear.damagePerCharge
      ..shieldStrengthPercent = gear.shieldStrengthPercent
      ..healingReceivedPercent = gear.healingReceivedPercent;
    // ⭐ Regrow rides the status machinery (item_status.dart), so the lane
    // sort and the HUD pip come for free. Permanent: gear is not taken off
    // mid-duel.
    if (gear.regrowPercent > 0) {
      mage.statuses.add(RegrowStatus(gear.regrowPercent));
    }
    return mage;
  }

  void newDuel() {
    // ⭐ Level scales health and damage on both sides (4%/level). An
    // even-level duel plays exactly as it always did; a level gap is now
    // worth something.
    player = _buildMage(name: 'You', level: playerLevel, gear: playerGear);
    final carried = playerStartingHp;
    if (carried != null) player.hp = carried.clamp(1, player.maxHp);
    // ⭐ An enemy is the level baseline TIMES its archetype (ENEMIES §1.1), so
    // a Glasswing and a Redoubt of the same level are genuinely different
    // fights rather than the same fight with different names — plus, for a
    // human rival, whatever they are wearing. ⚠️ The two are exclusive in
    // practice: archetypes only come from LocalAiDriver, which reports no
    // gear, and RemoteDuelDriver pins both scales to 1.0.
    enemy = _buildMage(
      name: driver.opponentName,
      level: driver.opponentLevel,
      gear: driver.opponentGear,
      hpScale: driver.opponentHpScale,
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
    _fled = false;
    pendingElement = null;
    animating = false;
    waitingForOpponent = false;
    _myForfeitStreak = 0;
    _theirForfeitStreak = 0;
    battleLog.clear();
    notifyListeners();
  }

  /// ⚠️ **The one place "the duel has ended" is decided.** A clean escape ends
  /// it with both mages standing, which the engine has no way to represent —
  /// its `isOver` means somebody is at 0 hp, and the two states it can express
  /// (a concession, a draw) are both *results*, which fleeing is not. So the
  /// fled ending lives here, beside the engine rather than inside it, and
  /// every gate that used to ask `engine.isOver` asks this instead.
  bool get _duelEnded => engine.isOver || _fled;

  bool get gameOver => _duelEnded && !animating;

  /// ⚠️ Explicitly false when [fled]: nobody won a fight nobody finished, and
  /// `engine.winner` would happily name the enemy the moment anything else set
  /// this duel over.
  bool get playerWon => !_fled && engine.winner == player;
  bool get isDraw => !_fled && engine.isDraw;

  /// How this duel ended, for the screen and the adventure flow.
  DuelOutcome get outcome => _fled
      ? DuelOutcome.fled
      : (playerWon ? DuelOutcome.won : DuelOutcome.lost);

  bool get needsElement => player.charge == 0 && pendingElement == null;
  int get turnNumber => engine.turnNumber;

  bool canAfford(Spell spell) =>
      spell.xCost ? player.charge >= 1 : spell.chargeCost <= player.charge;

  bool canAct(Spell spell) =>
      !animating &&
      !_duelEnded &&
      canAfford(spell) &&
      (player.charge > 0 || pendingElement != null);

  bool get canCharge =>
      !animating &&
      !_duelEnded &&
      player.charge < MageState.maxCharge &&
      (player.charge > 0 || pendingElement != null);

  /// Whether the player can drink [defId] right now.
  ///
  /// ⭐ Deliberately shaped like [canAct]: same animation and duel-over gates,
  /// because using an item IS a move. The extra clauses are the belt's own —
  /// it must be loaded, and it must resolve to something the engine can do.
  ///
  /// 📝 **The Academy guard point.** The ruled Academy format bans consumables
  /// outright; when it exists it belongs here (`&& !academy`), as one clause
  /// on the one predicate the arena asks — not as a check sprinkled through
  /// the UI, which is how a banned item ends up drinkable by keyboard.
  bool canUseItem(String defId) =>
      !animating &&
      !_duelEnded &&
      _belt.contains(defId) &&
      consumableEffectFor(defId) != null;

  /// Spends [defId] off the belt and returns the move to submit, or null if it
  /// cannot be used.
  ///
  /// ⚠️ **Consumption happens HERE, before the turn is submitted, and the
  /// profile is saved before this future completes** (ruling 2026-08-18). Win,
  /// lose, flee or close the tab: the potion is spent. Doing it after the turn
  /// resolved would hand the item back to anyone who quit mid-animation, and
  /// doing it in the engine is impossible — the engine has no profile.
  ///
  /// It returns the action rather than submitting it so the screen keeps its
  /// one submission path (clock, animation, forfeit tracking) instead of
  /// growing a second one. That is also what makes the forfeit-streak reset
  /// free: a [UseItemAction] flows through [submitTurn] like any played turn,
  /// and [_trackForfeits] resets on anything that is not a [ForfeitAction].
  Future<UseItemAction?> spendBeltItem(String defId) async {
    if (!canUseItem(defId)) return null;
    final effect = consumableEffectFor(defId)!;
    // Removes the FIRST match: two Draughts on the belt are two Draughts, and
    // drinking one must leave the other.
    _belt.remove(defId);
    notifyListeners();
    await onItemConsumed?.call(defId);
    return UseItemAction(defId, effect);
  }

  void selectElement(MagicElement element) {
    if (animating || player.charge > 0) return;
    pendingElement = element;
    notifyListeners();
  }

  /// Exchanges moves through the driver, resolves the turn, and returns the
  /// events for the screen to animate ([applyEvent] after each).
  ///
  /// [fleeAttempt] marks this forfeit as the cost of a *failed escape* rather
  /// than an absent player — see [_trackForfeits] for why that distinction is
  /// load-bearing.
  Future<List<DuelEvent>> submitTurn(
    MageAction action, {
    bool fleeAttempt = false,
  }) async {
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

    // The duel may have ended while the exchange was in flight (the opponent
    // surrendered and the watcher already ended it) — nothing left to resolve.
    // Asks [_duelEnded] rather than the engine so that an ending the engine
    // cannot see, like an escape, cannot be resolved straight through either.
    if (_duelEnded) {
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
    _trackForfeits(action, theirs, fleeAttempt: fleeAttempt);
    notifyListeners();
    return result.events;
  }

  /// Applies the [forfeitLimit] rule after a turn resolves: whichever side
  /// has forfeited that many turns in a row surrenders the duel.
  ///
  /// ⚠️ **A failed flee never counts toward the streak** (2026-08-17 ruling).
  /// The limit exists to hand a loss to a player who has *stopped playing* —
  /// a closed tab forfeiting every turn on the move timer. A player rolling
  /// escapes is the opposite of absent, and three unlucky rolls would
  /// otherwise auto-surrender them straight into the defeat penalty the flee
  /// ruling exists to spare them: a 20%-chance flee attempted three times
  /// would go from "three free hits" to "the run is dead" for nothing but bad
  /// luck. The streak is RESET rather than merely not incremented — deciding
  /// to run is proof of a live player, so it also clears whatever timeouts
  /// came before it.
  void _trackForfeits(
    MageAction mine,
    MageAction theirs, {
    bool fleeAttempt = false,
  }) {
    _myForfeitStreak = (mine is ForfeitAction && !fleeAttempt)
        ? _myForfeitStreak + 1
        : 0;
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
      case ItemUsedEvent(:final mage, :final healed):
        // ⚠️ Charge and element are untouched on purpose — a potion is not a
        // cast and spends nothing but the turn, so the bar the player was
        // building is still there when they come back to it.
        if (mage == player) {
          shownPlayerHp = (shownPlayerHp + healed).clamp(0, player.maxHp);
        } else {
          shownEnemyHp = (shownEnemyHp + healed).clamp(0, enemy.maxHp);
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

  /// What the creature behind this fight is worth to the escape roll.
  ///
  /// ⚠️ A practice persona and a human rival read as [EnemyRank.common] — they
  /// have no bestiary entry and no rank. Harmless, because the flee button is
  /// campaign-only; if it ever is not, "no rank" must mean "no penalty" rather
  /// than a crash.
  EnemyRank get enemyRank {
    final d = driver;
    return d is LocalAiDriver
        ? (d.enemy?.rank ?? EnemyRank.common)
        : EnemyRank.common;
  }

  /// The live escape chance (0–1) — see [Flee.chance] for the ruled formula.
  ///
  /// ⭐ Read off the ENGINE's health, not the lagging `shown*` display values:
  /// the button is disabled while a turn animates, so the only moment this is
  /// read is a moment the two agree — and if they ever drift, the number the
  /// player is shown must be the number they are about to roll against.
  double get fleeChance => Flee.chance(
    playerLevel: player.level,
    enemyLevel: enemy.level,
    playerHp: player.hp,
    playerMaxHp: player.maxHp,
    enemyHp: enemy.hp,
    enemyMaxHp: enemy.maxHp,
    rank: enemyRank,
  );

  /// The same number the button prints: whole percent.
  int get fleePercent => (fleeChance * 100).round();

  /// Rolls an escape attempt (campaign only).
  ///
  /// Returns **true** on a clean getaway: the duel is over as [fled] right
  /// now, before the enemy's action for this turn is ever chosen — the ruled
  /// semantics are that a successful escape resolves *first*, so the free hit
  /// a failure hands over is the entire cost of trying.
  ///
  /// Returns **false** when the attempt fails, and then the caller owes the
  /// duel a turn: submit `ForfeitAction` through
  /// [submitTurn] with `fleeAttempt: true`, so the enemy's move resolves
  /// against a player who did nothing. ⚠️ If that kills them it is an ordinary
  /// death down the ordinary path — they died fighting after a failed escape,
  /// not fleeing — which is precisely why the failure branch does no ending
  /// bookkeeping of its own.
  ///
  /// ⭐ **Flat odds on repeats** (ruled): no decay, no escalation. The free
  /// enemy turn per failure is already a compounding price, and stacking a
  /// shrinking chance on top would make the second attempt a trap.
  bool attemptFlee() {
    if (_duelEnded || animating) return false;
    final chance = fleeChance;
    // `< chance`, so a 0.95 ceiling really does leave a sliver: a roll of
    // exactly 0.95 fails.
    final escaped = _rng.nextDouble() < chance;
    final shown = (chance * 100).round();
    if (!escaped) {
      battleLog.add('You break for the exit ($shown%) and fail to get clear.');
      notifyListeners();
      return false;
    }
    _fled = true;
    battleLog.add('You break for the exit ($shown%) and get clean away.');
    // ⚠️ No `driver.reportSurrender()`: this is not a concession, and there is
    // no remote peer to tell — flee exists only in campaign duels, whose
    // opponent is a local brain.
    notifyListeners();
    return true;
  }

  /// Forfeit the duel ("surrender" in PvP, "flee" in the campaign).
  void surrender({String verb = 'surrender'}) {
    if (_duelEnded || animating) return;
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
    if (_duelEnded) return;
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
      'drinks': 'drink',
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
