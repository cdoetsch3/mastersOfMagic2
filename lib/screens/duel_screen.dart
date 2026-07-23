import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/duel_controller.dart';
import '../game/duel_status_badges.dart';
import '../game/element_style.dart';
import '../game/loadout.dart';
import '../game/mage_apparel.dart';
import '../game/mage_sprite.dart';
import '../game/opponent_driver.dart';
import '../game/progression.dart';
import '../ui/app_theme.dart';
import 'home_shell.dart';

/// The landscape duel arena. Keyboard: 1-8 = element slots, QWERT/ASDFG =
/// spell slots, C = channel. Turn resolution plays the engine's event list
/// as a sequenced animation whose intensity scales with charge spent.
class DuelScreen extends StatefulWidget {
  final Loadout loadout;

  /// Provides the opponent (AI persona or remote human). The duel logic is
  /// identical regardless of which it is.
  final OpponentDriver driver;

  /// Campaign battles say "Flee"; PvP-style duels say "Surrender".
  final bool campaign;

  /// Called once when a duel ends (win, loss, draw, or forfeit) with whether
  /// the player won. Lets the caller grant XP/gold. Draws report `false`.
  final void Function(bool playerWon)? onResult;

  const DuelScreen({
    super.key,
    required this.loadout,
    required this.driver,
    this.campaign = false,
    this.onResult,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

enum _FxKind { none, projectile, impact, shieldUp, charge, heal, flash }

class _DuelScreenState extends State<DuelScreen>
    with SingleTickerProviderStateMixin {
  late final DuelController c =
      DuelController(loadout: widget.loadout, driver: widget.driver);
  bool _resultReported = false;
  late final AnimationController _fx = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  _FxKind _fxKind = _FxKind.none;
  Color _fxColor = Colors.white;
  bool _fxAtEnemy = true;
  String? _fxText;
  double _fxIntensity = 1;
  int _fxProjectiles = 1;
  double _shake = 0;
  String? _banner;
  Color _bannerColor = Colors.white;
  MagicElement? _castElement;
  Spell? _castSpell;
  int _castCharge = 0;

  // Every combat message stays up long enough to actually read. Animations
  // that play while it is showing count toward this, so a message is only
  // held back if the turn would otherwise blow past it.
  static const Duration _minMessageVisible = Duration(seconds: 2);
  DateTime? _messageShownAt;

  static const _spellKeyLabels = 'QWERTASDFG';

  // Per-move countdown. Not committing in time forfeits the move (also how a
  // disconnected PvP opponent is handled — they forfeit until they lose).
  static const double _moveSeconds = 10;
  Timer? _moveTimer;
  double _secondsLeft = _moveSeconds;
  double _clockTotal = _moveSeconds;
  // Wall-clock deadline, not tick-counting: browsers throttle timers in
  // hidden tabs, and a tick-counted clock would run far slower than real
  // time there — never forfeiting, stalling a networked opponent.
  DateTime _moveDeadline = DateTime.now();

  /// Runs the countdown ring. With [forfeitOnExpiry] this is the player's
  /// move clock; without it, a display-only clock showing how long until
  /// the waiting-on opponent is declared forfeit (so a quiet wait doesn't
  /// look like a freeze).
  void _startClock(double seconds, {required bool forfeitOnExpiry}) {
    _moveTimer?.cancel();
    _clockTotal = seconds;
    _moveDeadline =
        DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
    setState(() => _secondsLeft = seconds);
    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      // Pause the clock while the arena is hidden behind the rotate prompt
      // (extend the deadline by the elapsed tick so time stands still).
      final size = MediaQuery.of(context).size;
      if (size.height > size.width) {
        _moveDeadline = _moveDeadline.add(const Duration(milliseconds: 100));
        return;
      }
      final left =
          _moveDeadline.difference(DateTime.now()).inMilliseconds / 1000.0;
      setState(() => _secondsLeft = left.clamp(0.0, seconds));
      if (left <= 0) {
        if (!forfeitOnExpiry) {
          t.cancel(); // the driver's own timeout resolves the turn from here
          return;
        }
        // Keep ticking while an animation is mid-flight; the forfeit must
        // eventually fire or a networked opponent would wait forever.
        if (c.animating) return;
        t.cancel();
        if (!c.gameOver) _submit(const ForfeitAction());
      }
    });
  }

  void _startMoveTimer() => _startClock(_moveSeconds, forfeitOnExpiry: true);

  void _stopMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  @override
  void initState() {
    super.initState();
    c.addListener(_checkResult);
    _startMoveTimer();
    // The arena is a landscape experience. Locks orientation on devices
    // (no-op on web, where the portrait guard below shows a rotate prompt).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Reports the outcome exactly once per duel (win/loss/draw/forfeit).
  void _checkResult() {
    if (!_resultReported && c.gameOver) {
      _resultReported = true;
      widget.onResult?.call(c.playerWon);
    }
  }

  @override
  void dispose() {
    _stopMoveTimer();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    c.removeListener(_checkResult);
    _fx.dispose();
    c.dispose();
    super.dispose();
  }

  /// Blocks until the message on screen has had its full reading time.
  Future<void> _awaitMessageRead() async {
    final shownAt = _messageShownAt;
    if (shownAt == null) return;
    final remaining = _minMessageVisible - DateTime.now().difference(shownAt);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  /// Shows a combat message, first letting the previous one finish being read
  /// so messages can never flash past faster than [_minMessageVisible].
  Future<void> _showMessage(String text, Color color) async {
    await _awaitMessageRead();
    if (!mounted) return;
    setState(() {
      _banner = text;
      _bannerColor = color;
    });
    _messageShownAt = DateTime.now();
  }

  Future<void> _runFx(_FxKind kind,
      {required bool atEnemy,
      Color color = Colors.white,
      String? text,
      double intensity = 1,
      int projectiles = 1,
      double shake = 0,
      int ms = 400}) async {
    setState(() {
      _fxKind = kind;
      _fxAtEnemy = atEnemy;
      _fxColor = color;
      _fxText = text;
      _fxIntensity = intensity;
      _fxProjectiles = projectiles;
      _shake = shake;
    });
    _fx.duration = Duration(milliseconds: ms);
    try {
      // .orCancel converts an interrupted ticker into an exception instead of
      // a future that never completes (which would freeze the turn loop). The
      // timeout guards against muted tickers: browsers throttle hidden tabs,
      // and a never-advancing animation would otherwise stall a PvP duel.
      await _fx
          .forward(from: 0)
          .orCancel
          .timeout(Duration(milliseconds: ms * 3 + 1000));
    } on TickerCanceled {
      // Animation was interrupted — skip ahead.
    } on TimeoutException {
      _fx.stop();
    }
    if (mounted) setState(() => _fxKind = _FxKind.none);
  }

  Future<void> _submit(MageAction action) async {
    // Move locked in. For remote duels, keep a visible countdown running so
    // the wait reads as "opponent has N seconds left", not a frozen app.
    if (widget.driver is RemoteDuelDriver) {
      _startClock(RemoteDuelDriver.opponentTimeout.inSeconds.toDouble(),
          forfeitOnExpiry: false);
    } else {
      _stopMoveTimer();
    }
    try {
      final events = await c.submitTurn(action);
      _stopMoveTimer(); // exchange done — the clock is moot while animating
      for (final event in events) {
        await _animate(event);
        if (!mounted) return;
        c.applyEvent(event);
      }
    } catch (error, stack) {
      debugPrint('Turn resolution error: $error\n$stack');
    }
    // Let the turn's last message finish being read before clearing it —
    // otherwise the final beat of a turn flashes past.
    await _awaitMessageRead();
    if (mounted) {
      setState(() => _banner = null);
      _messageShownAt = null;
      c.finishTurn();
      if (!c.gameOver) _startMoveTimer(); // next move's clock
    }
  }

  Future<void> _animate(DuelEvent event) async {
    switch (event) {
      case ChargedEvent(:final mage, :final element, :final newCharge):
        final isEnemy = mage == c.enemy;
        final color =
            isEnemy ? const Color(0xFF8E8E9E) : element.style.color;
        await _runFx(_FxKind.charge,
            atEnemy: isEnemy,
            color: color,
            intensity: 1 + newCharge * 0.35,
            ms: 550);
      case SpellCastEvent(:final caster, :final spell, :final element):
        _castElement = element;
        _castSpell = spell;
        _castCharge =
            caster == c.player ? c.shownPlayerCharge : c.shownEnemyCharge;
        final isEnemy = caster == c.enemy;
        await _showMessage(
            isEnemy
                ? '${c.enemy.name} casts ${element.style.label} ${spell.name}'
                : 'You cast ${element.style.label} ${spell.name}',
            element.style.color);
        await _runFx(_FxKind.flash,
            atEnemy: isEnemy,
            color: element.style.color,
            intensity: 1 + _castCharge * 0.3,
            ms: 300 + _castCharge * 40);
      case DamageEvent(
          :final target,
          :final toShield,
          :final toHp,
          :final shieldMultiplierPercent,
          :final shieldBroken
        ):
        final isEnemy = target == c.enemy;
        final color = _castElement?.style.color ?? Colors.white;
        final charge = _castCharge;
        final isMultiHit = switch (_castSpell?.effect) {
          DamageEffect(:final hits) => hits > 1,
          _ => false,
        };
        final projectiles =
            _castSpell?.effect is BarrageEffect ? max(1, charge) : 1;
        await _runFx(_FxKind.projectile,
            atEnemy: isEnemy,
            color: color,
            intensity: 1 + charge * 0.35,
            projectiles: projectiles,
            ms: isMultiHit ? 240 : max(280, 420 - charge * 20));
        final text = [
          if (toHp > 0) '-$toHp',
          if (toHp == 0 && toShield > 0) 'blocked',
          if (shieldMultiplierTag(shieldMultiplierPercent) case final t?)
            '$t vs shield',
          if (shieldBroken) 'shield shattered',
        ].join('  ');
        await _runFx(_FxKind.impact,
            atEnemy: isEnemy,
            color: color,
            text: text,
            intensity: 1 + charge * 0.45,
            shake: charge >= 3 ? (charge - 2) * 3.5 : 0,
            ms: isMultiHit ? 320 : 440 + charge * 50);
      case ShieldRaisedEvent(
          :final mage,
          :final element,
          :final isBarrier,
          :final strength
        ):
        final isEnemy = mage == c.enemy;
        final color = isBarrier ? Colors.white : element!.style.color;
        await _runFx(_FxKind.shieldUp,
            atEnemy: isEnemy,
            color: color,
            intensity: isBarrier ? 1.6 : 0.8 + strength / 40,
            ms: 480);
      case HealedEvent(:final mage, :final amount):
        await _runFx(_FxKind.heal,
            atEnemy: mage == c.enemy,
            color: const Color(0xFF58B368),
            text: '+$amount',
            intensity: 1 + amount / 30,
            ms: 500);
      case EffectDamageEvent(
          :final target,
          :final toHp,
          :final toShield,
          :final source
        ):
        // A status tick (DoT). Small impact pulse; no projectile.
        await _runFx(_FxKind.impact,
            atEnemy: target == c.enemy,
            color: const Color(0xFFE2732C),
            text: toHp > 0
                ? '-$toHp $source'
                : (toShield > 0 ? '$source blocked' : source),
            intensity: 1.1,
            ms: 460);
      case EffectHealEvent(:final mage, :final amount, :final source):
        if (amount > 0) {
          await _runFx(_FxKind.heal,
              atEnemy: mage == c.enemy,
              color: const Color(0xFF58B368),
              text: '+$amount $source',
              intensity: 1 + amount / 30,
              ms: 460);
        }
      case BuffAppliedEvent(:final mage, :final description):
        await _showMessage(
            '${mage == c.enemy ? c.enemy.name : 'You'}: $description',
            const Color(0xFFE8C547));
        await _runFx(_FxKind.flash,
            atEnemy: mage == c.enemy,
            color: const Color(0xFFE8C547),
            ms: 550);
      case ChargeDrainedEvent(:final mage, :final amount):
        if (amount > 0) {
          await _runFx(_FxKind.impact,
              atEnemy: mage == c.enemy,
              color: const Color(0xFF8B5CD6),
              text: 'charge drained',
              ms: 500);
        }
      case HasteChangedEvent(:final holder):
        await _showMessage(
            holder == null
                ? 'Haste is contested'
                : '${holder == c.enemy ? c.enemy.name : 'You'} '
                    'seize${holder == c.enemy ? 's' : ''} the initiative',
            const Color(0xFF7FD4E8));
        await _runFx(_FxKind.flash,
            atEnemy: holder == c.enemy,
            color: const Color(0xFF7FD4E8),
            ms: 450);
      case ForfeitedEvent(:final mage):
        await _showMessage(
            mage == c.enemy
                ? '${c.enemy.name} forfeits the turn'
                : 'You ran out of time — turn forfeited',
            const Color(0xFFD85A30));
        await Future<void>.delayed(const Duration(milliseconds: 650));
      case SpellFizzledEvent(:final caster, :final spell):
        await _showMessage(
            '${caster == c.enemy ? c.enemy.name : 'You'}: '
            '${spell.name} fizzled — charge disrupted',
            const Color(0xFFE8C547));
        await _runFx(_FxKind.flash,
            atEnemy: caster == c.enemy,
            color: const Color(0xFFE8C547),
            ms: 450);
      case SpellMissedEvent(:final caster, :final spell):
        await _showMessage(
            '${caster == c.enemy ? c.enemy.name : 'You'}: '
            '${spell.name} missed — blinded',
            const Color(0xFFF2E7C9));
        await _runFx(_FxKind.flash,
            atEnemy: caster == c.enemy,
            color: const Color(0xFFF2E7C9),
            ms: 450);
      case DefeatedEvent():
        await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  // Keyboard: 1-8 element slots, QWERT/ASDFG spell slots, C = channel.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyC) {
      if (c.canCharge) _submit(c.chargeAction());
      return KeyEventResult.handled;
    }
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
    ];
    final digitSlot = digits.indexOf(key);
    if (digitSlot >= 0) {
      if (digitSlot < c.loadout.elements.length) {
        c.selectElement(c.loadout.elements[digitSlot]);
      }
      return KeyEventResult.handled;
    }
    const spellKeys = [
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyG,
    ];
    final spellSlot = spellKeys.indexOf(key);
    if (spellSlot >= 0) {
      if (spellSlot < c.loadout.spells.length) {
        final spell = c.loadout.spells[spellSlot];
        if (c.canAct(spell)) _submit(c.castAction(spell));
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.height > size.width) {
      // Portrait: the arena needs landscape. Devices auto-rotate via the
      // orientation lock; web/desktop users see this prompt instead.
      return Scaffold(
        backgroundColor: const Color(0xFF141021),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.screen_rotation,
                  size: 56, color: Color(0xFFE8C547)),
              const SizedBox(height: 18),
              const Text('Rotate your device',
                  style: TextStyle(
                      color: Color(0xFFECE7F8),
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Duels are fought in landscape.',
                  style:
                      TextStyle(color: Color(0xFF9C93C4), fontSize: 13)),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF141021),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final playerPos = Offset(w * 0.24, h * 0.42);
              final enemyPos = Offset(w * 0.76, h * 0.42);
              final spriteH = min(h * 0.42, 190.0);
              return AnimatedBuilder(
                animation: _fx,
                builder: (context, child) {
                  final shakeAmount = _fxKind == _FxKind.impact && _shake > 0
                      ? _shake * (1 - _fx.value)
                      : 0.0;
                  final dx = sin(_fx.value * pi * 10) * shakeAmount;
                  final dy = cos(_fx.value * pi * 8) * shakeAmount * 0.6;
                  return Transform.translate(
                      offset: Offset(dx, dy), child: child);
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h * 0.52,
                      height: h * 0.12,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: w * 0.08),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1531),
                          borderRadius:
                              BorderRadius.all(Radius.elliptical(w * 0.4, 26)),
                        ),
                      ),
                    ),
                    _mage(playerPos, spriteH, isEnemy: false),
                    _mage(enemyPos, spriteH, isEnemy: true),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _fx,
                          builder: (context, _) => CustomPaint(
                            painter: _FxPainter(
                              kind: _fxKind,
                              t: _fx.value,
                              color: _fxColor,
                              text: _fxText,
                              intensity: _fxIntensity,
                              projectiles: _fxProjectiles,
                              from: _fxAtEnemy ? playerPos : enemyPos,
                              to: _fxAtEnemy ? enemyPos : playerPos,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        left: 10,
                        top: 8,
                        width: w * 0.30,
                        child: _playerPanel()),
                    Positioned(
                        right: 10,
                        top: 8,
                        width: w * 0.30,
                        child: _enemyPanel()),
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(child: _turnChip()),
                    ),
                    if (_banner != null)
                      Positioned(
                        top: h * 0.20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xCC1B1531),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _bannerColor, width: 1),
                            ),
                            child: Text(_banner!,
                                style: TextStyle(
                                    color: _bannerColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _actionBar(context)),
                    if (c.gameOver) _gameOverOverlay(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _mage(Offset pos, double height, {required bool isEnemy}) {
    final shield = isEnemy ? c.shownEnemyShield : c.shownPlayerShield;
    return Positioned(
      left: pos.dx - height * 0.45,
      top: pos.dy - height * 0.55,
      child: SizedBox(
        width: height * 0.9,
        height: height * 1.15,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MageSprite(
              apparel: isEnemy
                  ? widget.driver.opponentApparel
                  : MageApparel.apprenticeBlue,
              element: isEnemy
                  ? c.revealedEnemyElement
                  : (c.shownPlayerElement ?? c.pendingElement),
              charge: isEnemy ? c.shownEnemyCharge : c.shownPlayerCharge,
              facingRight: !isEnemy,
              defeated: isEnemy ? c.enemyDefeated : c.playerDefeated,
              height: height,
            ),
            if (shield != null)
              IgnorePointer(
                child: Container(
                  width: height * 0.98,
                  height: height * 1.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (shield.isBarrier
                              ? Colors.white
                              : shield.element!.style.color)
                          .withValues(alpha: 0.75),
                      width: 3,
                    ),
                    color: (shield.isBarrier
                            ? Colors.white
                            : shield.element!.style.color)
                        .withValues(alpha: 0.08),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _turnChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!c.gameOver) _countdown(),
        if (!c.gameOver) const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1531),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('Turn ${c.turnNumber + 1}',
              style: const TextStyle(color: Color(0xFF9C93C4), fontSize: 12)),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _showLog(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
                color: Color(0xFF1B1531), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long,
                size: 14, color: Color(0xFF9C93C4)),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: c.animating || c.gameOver ? null : _confirmForfeit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1531),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5A2430)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag, size: 12, color: Color(0xFFD85A30)),
                const SizedBox(width: 4),
                Text(widget.campaign ? 'Flee' : 'Surrender',
                    style: const TextStyle(
                        color: Color(0xFFD85A30), fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // A per-move countdown. When it empties (or the player is idle/disconnected)
  // the move is forfeited. While waiting on a remote opponent it keeps
  // counting (in gold) toward the moment they are declared forfeit, so the
  // wait is visibly alive rather than looking frozen.
  Widget _countdown() {
    final waiting = c.waitingForOpponent;
    final showClock = waiting || !c.animating;
    final frac = (_secondsLeft / _clockTotal).clamp(0.0, 1.0);
    final secs = _secondsLeft.ceil().clamp(0, _clockTotal.toInt());
    final urgent = !waiting && _secondsLeft <= 3;
    final color = !showClock
        ? const Color(0xFF6E6A7A)
        : waiting
            ? AppColors.gold
            : (urgent ? const Color(0xFFD85A30) : const Color(0xFF7FD4E8));
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: showClock ? frac : null,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF2A2342),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          if (showClock)
            Text('$secs',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _confirmForfeit() async {
    final verb = widget.campaign ? 'flee' : 'surrender';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1531),
        title: Text(widget.campaign ? 'Flee the battle?' : 'Surrender the duel?',
            style: const TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text('This counts as a loss.',
            style: TextStyle(color: Color(0xFF9C93C4))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep fighting'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.campaign ? 'Flee' : 'Surrender',
                style: const TextStyle(color: Color(0xFFD85A30))),
          ),
        ],
      ),
    );
    if (confirmed == true) c.surrender(verb: verb);
  }

  /// The opponent's Creeping Dark is what blinds *my* view. Dusk hides the
  /// enemy's charge/health; Midnight also hides my own (§4.2).
  CreepingDarkStatus? get _enemyDark =>
      c.enemy.statuses.whereType<CreepingDarkStatus>().firstOrNull;

  Widget _playerPanel() {
    final midnight = _enemyDark?.midnight ?? false;
    return _StatusPanel(
      name: 'You',
      hp: c.shownPlayerHp,
      maxHp: c.player.maxHp,
      charge: c.shownPlayerCharge,
      element: c.shownPlayerElement ?? c.pendingElement,
      elementHidden: false,
      shield: c.shownPlayerShield,
      alignEnd: false,
      badges: statusBadgesFor(c.player),
      barsVeiled: midnight,
      veilLabel: 'Midnight',
    );
  }

  Widget _enemyPanel() {
    final dark = _enemyDark;
    return _StatusPanel(
      name: c.enemy.name,
      hp: c.shownEnemyHp,
      maxHp: c.enemy.maxHp,
      charge: c.shownEnemyCharge,
      element: c.revealedEnemyElement,
      elementHidden: c.enemyIsCharging && c.revealedEnemyElement == null,
      shield: c.shownEnemyShield,
      alignEnd: true,
      badges: statusBadgesFor(c.enemy),
      barsVeiled: dark?.dusk ?? false,
      veilLabel: (dark?.midnight ?? false) ? 'Midnight' : 'Dusk',
    );
  }

  Widget _actionBar(BuildContext context) {
    final spells = c.loadout.spells;
    Widget spellRow(int offset) => Row(
          children: [
            for (var i = offset; i < offset + 5; i++)
              Expanded(
                child: i < spells.length
                    ? _spellButton(spells[i], i)
                    : _emptySlot(i),
              ),
          ],
        );
    return Container(
      color: const Color(0xE6100C1B),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < c.loadout.elements.length; i++)
                _elementButton(c.loadout.elements[i], i),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    spellRow(0),
                    const SizedBox(height: 4),
                    spellRow(5),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _channelButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _elementButton(MagicElement element, int slot) {
    final style = element.style;
    final locked = c.player.charge > 0;
    final active = locked
        ? c.shownPlayerElement == element
        : c.pendingElement == element;
    final selectable = !locked && !c.animating && !c.gameOver;
    final strong = element.strongAgainst.map((e) => e.style.label).join(', ');
    final weak = element.weakAgainst.map((e) => e.style.label).join(', ');
    return Tooltip(
      message: element.volatility == 0
          ? '${style.label} — counters nothing, countered by nothing'
          : '${style.label} — strong vs $strong · weak vs $weak',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Opacity(
          opacity: locked && !active ? 0.25 : 1,
          child: InkWell(
            onTap: selectable ? () => c.selectElement(element) : null,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? style.color
                    : style.color.withValues(alpha: 0.16),
                border: Border.all(
                    color: active ? Colors.white : style.color, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(style.icon,
                      size: 16,
                      color: active ? const Color(0xFF141021) : style.color),
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: Text('${slot + 1}',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: active
                                ? const Color(0xFF141021)
                                : style.color.withValues(alpha: 0.9))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptySlot(int slot) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF241D3D)),
      ),
      child: Center(
        child: Text(_spellKeyLabels[slot],
            style:
                const TextStyle(color: Color(0xFF352C55), fontSize: 10)),
      ),
    );
  }

  Widget _spellButton(Spell spell, int slot) {
    final usable = c.canAct(spell);
    final elementColor =
        (c.shownPlayerElement ?? c.pendingElement)?.style.color ??
            const Color(0xFF6E6A7A);
    return Tooltip(
      message: spellTooltip(spell),
      waitDuration: const Duration(milliseconds: 350),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Opacity(
          opacity: usable ? 1 : 0.32,
          child: InkWell(
            onTap: usable ? () => _submit(c.castAction(spell)) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1836),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF373060)),
              ),
              child: Row(
                children: [
                  Icon(spellIcons[spell.id] ?? Icons.auto_fix_high,
                      size: 19, color: elementColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spell.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFECE7F8), fontSize: 11.5)),
                        Text(
                            spell.xCost
                                ? 'cost X'
                                : 'cost ${spell.chargeCost}',
                            style: const TextStyle(
                                color: Color(0xFF9C93C4), fontSize: 9)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141021),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF443A6A)),
                    ),
                    child: Text(_spellKeyLabels[slot],
                        style: const TextStyle(
                            color: Color(0xFF9C93C4),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _channelButton() {
    final element = c.shownPlayerElement ?? c.pendingElement;
    final color = element?.style.color ?? const Color(0xFF373060);
    return Tooltip(
      message:
          'Channel (C): +1 charge, max 5.\nNo attack or defense this turn.',
      child: SizedBox(
        height: 96,
        width: 108,
        child: ElevatedButton(
          onPressed: c.canCharge ? () => _submit(c.chargeAction()) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: const Color(0xFF141021),
            disabledBackgroundColor: const Color(0xFF2A2342),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload, size: 22),
              const SizedBox(height: 2),
              const Text('Channel',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('C',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay() {
    final won = c.playerWon;
    final title = c.isDraw ? 'Draw' : (won ? 'Victory!' : 'Defeat');
    final accent = won ? const Color(0xFFE8C547) : const Color(0xFFD85A30);
    final goldEarned = won ? Progression.winGold : Progression.lossGold;
    final xpEarned = won ? Progression.winXp : Progression.lossXp;

    return Positioned.fill(
      child: Container(
        color: const Color(0xCC0A0812),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            width: 340,
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1531),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    won
                        ? Icons.emoji_events
                        : (c.isDraw ? Icons.handshake : Icons.sentiment_dissatisfied),
                    color: accent,
                    size: 40),
                const SizedBox(height: 6),
                Text(title,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: accent)),
                Text('vs ${c.enemy.name}',
                    style: const TextStyle(
                        color: Color(0xFF9C93C4), fontSize: 13)),
                const SizedBox(height: 16),
                _rewardRow(
                  leading: const CoinIcon(size: 20),
                  label: 'Gold',
                  value: goldEarned > 0 ? '+$goldEarned' : '—',
                ),
                const SizedBox(height: 8),
                _rewardRow(
                  leading: const Icon(Icons.star_rounded,
                      color: Color(0xFF7FD4E8), size: 22),
                  label: 'Experience',
                  value: xpEarned > 0 ? '+$xpEarned XP' : '—',
                ),
                const SizedBox(height: 8),
                _rewardRow(
                  leading: const Icon(Icons.military_tech,
                      color: Color(0xFF6E6A7A), size: 22),
                  label: 'Ranking',
                  value: 'coming soon',
                  muted: true,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _showLog(context),
                  icon: const Icon(Icons.receipt_long,
                      size: 17, color: Color(0xFF9C93C4)),
                  label: const Text('Review battle log',
                      style:
                          TextStyle(color: Color(0xFF9C93C4), fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.campaign) {
                            Navigator.of(context).pop();
                          } else {
                            HomeShell.goHome();
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                        icon: Icon(widget.campaign ? Icons.map : Icons.home,
                            size: 18),
                        label: Text(widget.campaign ? 'Leave' : 'Home'),
                      ),
                    ),
                    if (widget.driver.supportsRematch) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE25822),
                            foregroundColor: const Color(0xFF141021),
                          ),
                          onPressed: () {
                            _resultReported = false;
                            c.newDuel();
                            _startMoveTimer();
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Again'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardRow({
    required Widget leading,
    required String label,
    required String value,
    bool muted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141021),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFECE7F8), fontSize: 14)),
          ),
          Text(value,
              style: TextStyle(
                  color: muted
                      ? const Color(0xFF6E6A7A)
                      : const Color(0xFFE8C547),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1531),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 18, color: Color(0xFFE8C547)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Battle log',
                        style: TextStyle(
                            color: Color(0xFFECE7F8),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Text('newest first',
                      style:
                          TextStyle(color: Color(0xFF6E6A7A), fontSize: 11)),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 20, color: Color(0xFF9C93C4)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2342)),
            Expanded(
              child: c.battleLog.isEmpty
                  ? const Center(
                      child: Text('No turns fought yet.',
                          style: TextStyle(
                              color: Color(0xFF6E6A7A), fontSize: 13)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        for (final line in c.battleLog.reversed)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Text(line,
                                style: TextStyle(
                                    color: line.startsWith('—')
                                        ? const Color(0xFFE8C547)
                                        : const Color(0xFFB9B2D6),
                                    fontWeight: line.startsWith('—')
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12.5)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final String name;
  final int hp;
  final int maxHp;
  final int charge;
  final MagicElement? element;
  final bool elementHidden;
  final ShownShield? shield;
  final bool alignEnd;
  final List<StatusBadge> badges;

  /// When true, this mage's charge and health are hidden behind an enemy
  /// Creeping Dark (Dusk / Midnight). [veilLabel] names the curse so the
  /// blackout reads as intentional, not a rendering bug.
  final bool barsVeiled;
  final String? veilLabel;

  static const _umbra = Color(0xFF8B5CD6);

  const _StatusPanel({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.charge,
    required this.element,
    required this.elementHidden,
    required this.shield,
    required this.alignEnd,
    required this.badges,
    this.barsVeiled = false,
    this.veilLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pipColor = elementHidden
        ? const Color(0xFF8E8E9E)
        : element?.style.color ?? const Color(0xFF443A6A);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCC1B1531),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (barsVeiled)
                _veilPill()
              else
                Text('$hp/$maxHp',
                    style: const TextStyle(
                        color: Color(0xFF9C93C4), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          if (barsVeiled)
            _veiledBar()
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: hp / maxHp),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                builder: (context, value, _) => Stack(
                  children: [
                    Container(height: 8, color: const Color(0xFF2A2342)),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0, 1),
                      child: Container(
                          height: 8,
                          color: value > 0.35
                              ? const Color(0xFF58B368)
                              : const Color(0xFFD85A30)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 5),
          if (barsVeiled)
            Row(
              mainAxisAlignment:
                  alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: const [
                Icon(Icons.nightlight_round, size: 12, color: _umbra),
                SizedBox(width: 5),
                Text('charge veiled',
                    style: TextStyle(
                        color: _umbra,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ],
            )
          else
            Row(
              mainAxisAlignment:
                  alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!alignEnd) ..._chargeRow(pipColor),
                if (elementHidden)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('?',
                        style: TextStyle(
                            color: Color(0xFF8E8E9E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
                else if (element != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(element!.style.icon,
                        size: 14, color: element!.style.color),
                  ),
                if (alignEnd) ..._chargeRow(pipColor),
              ],
            ),
          if (shield != null || badges.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: [
              if (shield != null) _shieldBadge(),
              for (final b in badges) _statusChip(b),
            ],
          ),
        ],
      ),
    );
  }

  /// The "hidden by DUSK / MIDNIGHT" pill that replaces the HP readout.
  Widget _veilPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _umbra.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _umbra.withValues(alpha: 0.8), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round, size: 10, color: _umbra),
          const SizedBox(width: 3),
          Text((veilLabel ?? 'Veiled').toUpperCase(),
              style: const TextStyle(
                  color: _umbra,
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// A redacted health bar: diagonal umbra hatching, unmistakably not a health
  /// color and not an empty (dead) bar.
  Widget _veiledBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: CustomPaint(painter: _VeilHatchPainter()),
      ),
    );
  }

  /// A2 chip: buffs/streaks keep a colored border on a dark fill; debuffs
  /// invert to a solid ember fill so they can't be mistaken for a buff.
  Widget _statusChip(StatusBadge b) {
    final debuff = b.kind == BadgeKind.debuff;
    final fg = debuff ? const Color(0xFF141021) : b.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: debuff ? b.color : b.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: b.color, width: debuff ? 0 : 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.label,
              style: TextStyle(
                  color: fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
          if (b.sub != null) ...[
            const SizedBox(width: 4),
            Text(b.sub!,
                style: TextStyle(
                    color: debuff
                        ? const Color(0xFF141021)
                        : AppColors.textFaint,
                    fontSize: 9.5)),
          ],
        ],
      ),
    );
  }

  List<Widget> _chargeRow(Color color) => [
        for (var i = 0; i < 5; i++)
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < charge ? color : Colors.transparent,
              border: Border.all(
                  color: i < charge ? color : const Color(0xFF443A6A)),
            ),
          ),
      ];

  Widget _shieldBadge() {
    final color =
        shield!.isBarrier ? Colors.white : shield!.element!.style.color;
    final label = shield!.isBarrier
        ? 'Barrier'
        : '${shield!.element!.style.label} ${shield!.remaining}';
    return _badge(label, color, icon: Icons.shield);
  }

  Widget _badge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 10.5)),
        ],
      ),
    );
  }
}

/// Diagonal umbra hatching for a Dusk/Midnight-veiled health bar.
class _VeilHatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF221A38));
    final stripe = Paint()
      ..color = const Color(0x558B5CD6)
      ..strokeWidth = 3;
    const gap = 7.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
  }

  @override
  bool shouldRepaint(_VeilHatchPainter oldDelegate) => false;
}

class _FxPainter extends CustomPainter {
  final _FxKind kind;
  final double t;
  final Color color;
  final String? text;
  final double intensity;
  final int projectiles;
  final Offset from;
  final Offset to;

  _FxPainter({
    required this.kind,
    required this.t,
    required this.color,
    required this.text,
    required this.intensity,
    required this.projectiles,
    required this.from,
    required this.to,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == _FxKind.none) return;
    final paint = Paint()..color = color;
    switch (kind) {
      case _FxKind.projectile:
        for (var p = 0; p < projectiles; p++) {
          // Stagger multiple projectiles in time and fan them in an arc.
          final stagger = projectiles > 1 ? p * 0.55 / projectiles : 0.0;
          final pt = ((t - stagger) / (1 - stagger)).clamp(0.0, 1.0);
          if (pt <= 0) continue;
          final arc = projectiles > 1 ? (p - (projectiles - 1) / 2) * 26.0 : 0.0;
          final base = Offset.lerp(from, to, Curves.easeIn.transform(pt))!;
          final lift = sin(pt * pi) * arc;
          final pos = base + Offset(0, -lift.abs() - sin(pt * pi) * 14);
          for (var i = 0; i < 3 + intensity.round(); i++) {
            final trailT = (pt - i * 0.06).clamp(0.0, 1.0);
            final trailBase =
                Offset.lerp(from, to, Curves.easeIn.transform(trailT))!;
            final trailPos = trailBase +
                Offset(0, -(sin(trailT * pi) * arc).abs() - sin(trailT * pi) * 14);
            paint.color = color.withValues(
                alpha: ((1 - i * 0.2) * 0.9).clamp(0.0, 1.0));
            canvas.drawCircle(
                trailPos, (5.5 + intensity * 2.5) - i * 1.3, paint);
          }
          paint.color = Colors.white.withValues(alpha: 0.85);
          canvas.drawCircle(pos, 2.5 + intensity, paint);
        }
      case _FxKind.impact:
        final rings = 1 + (intensity / 0.9).floor();
        for (var r = 0; r < rings; r++) {
          final rt = ((t - r * 0.12).clamp(0.0, 1.0));
          paint.color = color.withValues(alpha: (1 - rt) * 0.55);
          canvas.drawCircle(to, (10 + 30 * rt) * (0.8 + intensity * 0.35), paint);
        }
        paint.color = Colors.white.withValues(alpha: (1 - t) * 0.9);
        canvas.drawCircle(to, (5 + 10 * t) * (0.8 + intensity * 0.2), paint);
        if (intensity >= 2.4) {
          // Cataclysm-tier: whole-screen flash.
          paint.color = Colors.white.withValues(alpha: (1 - t) * 0.22);
          canvas.drawRect(Offset.zero & size, paint);
        }
        _drawText(canvas, to + Offset(0, -40 - 28 * t), 1 - t * 0.7,
            fontSize: 15 + intensity * 3);
      case _FxKind.shieldUp:
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + intensity
          ..color = color.withValues(alpha: 1 - t * 0.4);
        canvas.drawCircle(
            to, (26 + 42 * Curves.easeOut.transform(t)) * (0.7 + intensity * 0.25),
            ringPaint);
      case _FxKind.charge:
        final particles = 3 + (intensity * 2.2).round();
        for (var i = 0; i < particles; i++) {
          final angle = t * (4 + intensity) + i * 2 * pi / particles;
          final radius = (48 + intensity * 12) * (1 - t * 0.7);
          paint.color = color.withValues(alpha: 0.35 + 0.5 * t);
          canvas.drawCircle(
              to + Offset(cos(angle) * radius, sin(angle) * radius * 0.6),
              3 + intensity + 2 * t,
              paint);
        }
      case _FxKind.heal:
        paint.color = color.withValues(alpha: (1 - t) * 0.8);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
              to + Offset((i - 1) * 22.0, 10 - 55 * t + i * 8), 5, paint);
        }
        _drawText(canvas, to + Offset(0, -30 - 25 * t), 1 - t * 0.6);
      case _FxKind.flash:
        paint.color = color.withValues(alpha: (1 - t) * 0.5);
        canvas.drawCircle(to, (36 + 18 * t) * (0.8 + intensity * 0.3), paint);
      case _FxKind.none:
        break;
    }
  }

  void _drawText(Canvas canvas, Offset pos, double opacity,
      {double fontSize = 17}) {
    if (text == null || text!.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity.clamp(0, 1)),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: color, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, pos - Offset(painter.width / 2, 0));
  }

  @override
  bool shouldRepaint(_FxPainter old) =>
      old.t != t || old.kind != kind || old.color != color;
}
