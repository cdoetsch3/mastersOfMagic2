import 'dart:async';
import 'dart:math';

import 'package:mom_engine/mom_engine.dart';

import 'academy.dart';
import 'ai_personas.dart';
import 'enemies/enemy_combat_stats.dart';
import 'enemies/enemy_def.dart';
import 'firestore_rest.dart';
import 'items/belt_potions.dart';
import 'items/item_def.dart';
import 'ladder/think_time.dart';
import 'mage_apparel.dart';

/// What one turn's exchange produced: the opponent's action, plus (for
/// networked duels) the seed both clients must use to resolve the turn.
class TurnExchange {
  final MageAction opponentAction;
  final int? turnSeed;

  const TurnExchange(this.opponentAction, [this.turnSeed]);
}

/// The seam that makes every duel identical once it starts: the duel screen
/// talks to a driver, and the driver is a local AI persona, a matchmade
/// human, or a friend — the combat logic never knows the difference.
abstract interface class OpponentDriver {
  String get opponentName;

  /// The opponent's character level, which scales their health and damage
  /// (ElementTuning.percentPerLevel). A practice foe fights at the level its
  /// persona is written for, so beating Procarius means beating a level-60
  /// mage rather than a level-1 one with a good brain.
  int get opponentLevel;

  /// The opponent's Elo on whichever ladder this duel is (LADDER_DESIGN §2),
  /// shown next to their name/level in the arena (LADDER §7 build shape,
  /// item 5). Defaults to the Academy/Geared seed floor of 1200 so every
  /// existing caller (campaign, practice) that never sets one still renders
  /// something sane rather than an empty pill.
  int get opponentRating => 1200;

  /// What the opponent's equipment adds up to (ITEMS §7.4 — current PvP is
  /// the GEARED ladder, so their wardrobe is part of the fight).
  ///
  /// ⚠️ **[ItemModifiers.none] for anything that is not another player.**
  /// Enemies get their numbers from their archetype, never from items
  /// (ENEMIES §2.1) — a foe reporting gear here would be an archetype and a
  /// wardrobe stacked on the same body.
  ///
  /// ⭐ This is the *opponent's own* totals, carried across the wire by
  /// matchmaking. Each client applies its own gear from local state and the
  /// other side's from here, which is the only way both machines build the
  /// same two mages (the lockstep rule).
  ItemModifiers get opponentGear => ItemModifiers.none;

  /// The opponent's crit / dodge / deflection block (KINETIC_CONTRACT §2.2).
  ///
  /// ⚠️ **The new seam, deliberately separate from [opponentGear].** A
  /// bestiary entry's combat stats are its archetype's lean, not a wardrobe —
  /// routing them through `opponentGear` would stack an archetype and a
  /// wardrobe on the same body, exactly what that field's own doc forbids.
  /// [EnemyCombatStats.none] for anything that is not a campaign encounter —
  /// same rule as [opponentHpScale]: archetype-flavoured stats must never
  /// touch PvP.
  EnemyCombatStats get opponentCombatStats => EnemyCombatStats.none;

  MageApparel get opponentApparel;

  /// Multiplier on the opponent's max HP, off the level baseline.
  ///
  /// ⭐ **Where an enemy archetype's `hpScale` enters the duel** (ENEMIES
  /// §2.1). 1.0 for a mage or another player; 2.20 for a Redoubt.
  double get opponentHpScale => 1.0;

  /// Multiplier on the opponent's outgoing damage.
  ///
  /// ⚠️ Damage only — never shields. A Sentinel is low damage *and* a wall,
  /// and scaling both would erase the archetype.
  double get opponentPowerScale => 1.0;

  /// Whether the local player is "host" (engine mage1). Remote duels assign
  /// sides; local duels always make the player the host.
  bool get playerIsHost;

  /// Whether "Duel again" makes sense (true for AI; false for remote rooms).
  bool get supportsRematch;

  /// Exchanges this turn's moves: sends [playerAction], returns the
  /// opponent's. For AI this is instant; for remote play it performs the
  /// commit-reveal round trip (and may report the opponent as forfeiting if
  /// they time out or disconnect).
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction);

  /// Tells the remote peer this player surrendered, so their duel ends
  /// immediately instead of waiting out move timeouts. No-op for local AI.
  Future<void> reportSurrender();

  /// Invokes [onSurrendered] (at most once) if the opponent surrenders,
  /// even while this player is idle at the move picker. No-op for local AI.
  void watchOpponentSurrender(void Function() onSurrendered);

  /// Tear down listeners/rooms.
  Future<void> dispose();
}

/// An AI persona behind the same interface. The controller [bind]s the live
/// mage states after constructing the engine.
class LocalAiDriver implements OpponentDriver {
  final AiPersona persona;

  /// The bestiary entry behind this fight, when there is one.
  ///
  /// ⭐ Present for a campaign encounter, null for a practice persona — which
  /// is why the scales default to 1.0 rather than being required.
  final EnemyDef? enemy;
  final Random rng;
  late final DuelAi _brain = persona.buildBrain();

  MageState? _player;
  MageState? _enemy;

  /// The level the persona is built at when it stands in for a human in
  /// an Academy bout (academy.dart) — null plays the persona at its own.
  final int? levelOverride;

  /// ⭐ A LADDER bot's wardrobe (LADDER §4): item ids + Quality, derived to
  /// `ItemModifiers` exactly as a player's own gear is. Defaults to
  /// [ItemModifiers.none] so every existing caller (campaign, practice) is
  /// unaffected — only ladder construction ever passes a real one.
  final ItemModifiers gear;

  /// ⭐ LADDER §4.2 — when set, [exchangeTurn] waits this long before
  /// returning the brain's action, so a bot never answers instantly. Null
  /// (every non-ladder caller: campaign, practice) means no delay at all.
  final ThinkTime? thinkTime;

  /// ⭐ LADDER §2 — this bot's Elo on whichever ladder it was drawn from.
  /// Defaults to 1200 (the Academy seed / the [OpponentDriver] floor) so
  /// campaign and practice callers, which never pass one, render the same
  /// number the abstract getter already promises.
  final int rating;

  @override
  int get opponentRating => rating;

  LocalAiDriver({
    required this.persona,
    this.enemy,
    this.levelOverride,
    this.gear = ItemModifiers.none,
    this.thinkTime,
    this.rating = 1200,
    Random? rng,
  }) : rng = rng ?? Random();

  @override
  double get opponentHpScale => enemy?.archetype.hpScale ?? 1.0;

  @override
  double get opponentPowerScale => enemy?.archetype.damageScale ?? 1.0;

  /// ⭐ Where an `EnemyDef`'s crit/dodge/deflection reaches the duel
  /// (KINETIC_CONTRACT §2.2). `EnemyCombatStats.none` for a practice persona
  /// with no bestiary entry behind it, exactly like [opponentHpScale].
  @override
  EnemyCombatStats get opponentCombatStats =>
      enemy?.combatStats ?? EnemyCombatStats.none;

  void bind(MageState player, MageState enemy) {
    _player = player;
    _enemy = enemy;
  }

  @override
  String get opponentName => persona.name;

  @override
  int get opponentLevel => levelOverride ?? persona.level;

  /// ⚠️ **A persona or bestiary enemy wears none — archetype stats are their
  /// lane** (LADDER §5). A LADDER bot is different: it wears a real
  /// wardrobe derived from catalogue items exactly like a player's does
  /// (LADDER §4), and that wardrobe arrives through [gear]. But [enemy]
  /// still wins outright: whenever a bestiary entry is set, this returns
  /// [ItemModifiers.none] regardless of [gear], because an archetype and a
  /// wardrobe must never stack on one body (see the file header comments).
  @override
  ItemModifiers get opponentGear => enemy != null ? ItemModifiers.none : gear;

  @override
  MageApparel get opponentApparel => persona.apparel;

  @override
  bool get playerIsHost => true;

  @override
  bool get supportsRematch => true;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async {
    final action = _brain.chooseAction(_enemy!, _player!, rng);
    // ⚠️ **Enemies never use items** (ruling 2026-08-18). Belts, potions and
    // the pack are the player's lane alone — the same rule that keeps gear off
    // an archetype (ENEMIES §2.1). The brains cannot emit one today; this is
    // the guard that makes that a *rule* rather than an accident of what has
    // been written so far, and it fails loudly here rather than quietly
    // healing a monster in front of the player.
    if (action is UseItemAction) {
      throw StateError(
        '${persona.name} tried to use ${action.itemId}: '
        'enemies do not carry items.',
      );
    }
    // ⭐ LADDER §4.2 — a bot "thinks" before committing, redrawn every turn.
    // Null for every non-ladder caller (campaign, practice), so nothing
    // about those duels changes.
    final delay = thinkTime?.next(rng);
    if (delay != null) await Future<void>.delayed(delay);
    return TurnExchange(action);
  }

  @override
  Future<void> reportSurrender() async {}

  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}

  @override
  Future<void> dispose() async {}
}

/// Commit-reveal duel over a Firestore room. Both clients:
///  1. write `sha256(move|nonce)` to the turn doc,
///  2. once both commitments exist, write the (move, nonce) reveal,
///  3. verify the opponent's reveal against their commitment,
///  4. resolve the turn locally with a seed derived from both moves.
/// An opponent that hasn't committed within [opponentTimeout] forfeits the
/// move (also how disconnects are handled — they forfeit until they lose).
class RemoteDuelDriver implements OpponentDriver {
  /// ⚠️ A human opponent is always the baseline — archetype scales are an
  /// enemy-design tool and must never touch PvP.
  @override
  double get opponentHpScale => 1.0;

  @override
  double get opponentPowerScale => 1.0;

  /// ⚠️ Pinned to [EnemyCombatStats.none], same rule as [opponentHpScale] and
  /// [opponentPowerScale] — a human rival's crit/dodge/deflection comes from
  /// their gear wire (`opponentGear`), never from this seam.
  @override
  EnemyCombatStats get opponentCombatStats => EnemyCombatStats.none;

  final String roomId;
  final bool isHost;
  final int masterSeed;
  @override
  final String opponentName;

  /// An Academy bout (academy.dart): the rival is built at [Academy.level]
  /// wearing nothing, WHATEVER the wire said their level and gear were.
  /// ⭐ Coerced here, in the one object both clients build their enemy from,
  /// so a mode mismatch can never desync a duel — both sides read the same
  /// flag off the same room doc.
  final bool academy;

  final int _opponentLevel;
  final ItemModifiers _opponentGear;

  @override
  int get opponentLevel => academy ? Academy.level : _opponentLevel;

  @override
  ItemModifiers get opponentGear =>
      academy ? ItemModifiers.none : _opponentGear;

  /// The opponent's rating on this duel's ladder (LADDER_DESIGN §2), as
  /// read off the ticket/room at match time. ⭐ Required, not defaulted —
  /// same reasoning as [opponentLevel]/[opponentGear]: a silent default
  /// would let a stale client desync the rated math instead of failing
  /// loudly. Callers reading an OLD ticket/room doc (no `rating` field: a
  /// pre-LADDER client) default the parsed value to 1200 themselves before
  /// it ever reaches here.
  @override
  final int opponentRating;

  /// Whether this duel counts for rating (LADDER §3): true only for a
  /// `Matchmaking.quickMatch` human match. ⚠️ **False for every room-code
  /// duel** — friends inviting friends by code (or QR) must never be a
  /// rating farm, so [createRoom]/[waitForGuest]/[joinRoom] never set this.
  final bool rated;

  static const opponentTimeout = Duration(seconds: 25);

  final _rng = Random.secure();

  Timer? _surrenderWatch;
  bool _theySurrendered = false;

  RemoteDuelDriver({
    required this.roomId,
    required this.isHost,
    required this.masterSeed,
    required this.opponentName,
    // ⚠️ Required, not defaulted. A defaulted 1 is how every PvP duel
    // silently simulated the opponent at level 1 — two clients running two
    // different fights (HP pools AND damage scaling), which is a lockstep
    // desync, not a display bug.
    required int opponentLevel,
    // ⚠️ Required for exactly the same reason, and it is the same bug: gear
    // that defaults to none makes each client simulate itself geared against
    // a naked rival (ITEMS §7.4 says PvP counts gear). A silent default is
    // how the level desync survived as long as it did — so there isn't one.
    required ItemModifiers opponentGear,
    required this.opponentRating,
    this.academy = false,
    this.rated = false,
  }) : _opponentLevel = opponentLevel,
       _opponentGear = opponentGear;

  // ignore_for_file: prefer_initializing_formals
  // (the wire values are stored privately so the [academy] getters can
  // coerce them — an initializing formal would expose the raw fields)

  String get _roomPath => 'duels/$roomId';
  String _turnPath(int turn) => '$_roomPath/turns/$turn';

  String get _me => isHost ? 'host' : 'guest';
  String get _them => isHost ? 'guest' : 'host';

  @override
  MageApparel get opponentApparel =>
      isHost ? MageApparel.duskWitch : MageApparel.apprenticeBlue;

  @override
  bool get playerIsHost => isHost;

  @override
  bool get supportsRematch => false;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async {
    final path = _turnPath(turn);
    final myWire = encodeAction(playerAction);
    final myNonce = List.generate(
      4,
      (_) => _rng.nextInt(0x40000000).toRadixString(16),
    ).join();

    // 1. Commit.
    await FirestoreRest.set(path, {
      '${_me}Commit': commitmentOf(myWire, myNonce),
    });

    // 2. Wait for their commitment (or declare a forfeit on timeout).
    var data = await _pollTurn(
      path,
      (d) => d['${_them}Commit'] != null,
      opponentTimeout,
    );
    if (data == null) {
      await FirestoreRest.set(path, {'${_them}Forfeit': true});
      data = await FirestoreRest.get(path) ?? {};
    }
    final theirForfeit =
        data['${_them}Forfeit'] == true && data['${_them}Commit'] == null;

    // 3. Reveal (safe now: both commitments are locked, or they forfeited).
    await FirestoreRest.set(path, {
      '${_me}Move': myWire,
      '${_me}Nonce': myNonce,
    });

    String theirWire;
    if (theirForfeit) {
      theirWire = encodeAction(const ForfeitAction());
    } else {
      final revealed = await _pollTurn(
        path,
        (d) => d['${_them}Move'] != null && d['${_them}Nonce'] != null,
        opponentTimeout,
      );
      if (revealed == null) {
        theirWire = encodeAction(const ForfeitAction());
      } else {
        theirWire = revealed['${_them}Move'] as String;
        final nonce = revealed['${_them}Nonce'] as String;
        final commit = revealed['${_them}Commit'] as String? ?? '';
        if (!verifyCommitment(commit, theirWire, nonce)) {
          theirWire = encodeAction(const ForfeitAction());
        }
      }
    }

    final seed = deriveTurnSeed(masterSeed, turn, myWire, theirWire);
    // ⭐ The catalogue crosses the wire as an id and is resolved HERE, from
    // this client's own item definitions (ITEMS §10.3b) — the opponent sends
    // "U|sapwort_draught", never the numbers, so a doctored client cannot
    // drink a potion this build has never heard of.
    return TurnExchange(
      decodeAction(theirWire, consumables: consumableEffectFor),
      seed,
    );
  }

  /// Polls the turn doc until [ready] passes, or returns null on timeout
  /// (or as soon as the opponent is known to have surrendered — no point
  /// waiting out the clock for a move that will never come).
  Future<Map<String, dynamic>?> _pollTurn(
    String path,
    bool Function(Map<String, dynamic>) ready,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_theySurrendered) return null;
      try {
        final d = await FirestoreRest.get(path);
        if (d != null && ready(d)) return d;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return null;
  }

  @override
  Future<void> reportSurrender() async {
    try {
      await FirestoreRest.set(_roomPath, {
        '${_me}Surrendered': true,
        'status': 'ended',
      });
    } catch (_) {
      // Best effort — the opponent's move timeouts still end the duel.
    }
  }

  @override
  void watchOpponentSurrender(void Function() onSurrendered) {
    _surrenderWatch?.cancel();
    _surrenderWatch = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final room = await FirestoreRest.get(_roomPath);
        if (room?['${_them}Surrendered'] == true) {
          _theySurrendered = true;
          timer.cancel();
          onSurrendered();
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> dispose() async {
    _surrenderWatch?.cancel();
  }
}
