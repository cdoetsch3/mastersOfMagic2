import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/duel_controller.dart';
import '../game/element_style.dart';
import '../game/loadout.dart';
import '../game/mage_apparel.dart';
import '../game/mage_sprite.dart';

/// The landscape duel arena. Keyboard: 1-8 = element slots, QWERT/ASDFG =
/// spell slots, C = channel. Turn resolution plays the engine's event list
/// as a sequenced animation whose intensity scales with charge spent.
class DuelScreen extends StatefulWidget {
  final Loadout loadout;

  /// Campaign battles say "Flee"; PvP-style duels say "Surrender".
  final bool campaign;

  const DuelScreen({super.key, required this.loadout, this.campaign = false});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

enum _FxKind { none, projectile, impact, shieldUp, charge, heal, flash }

class _DuelScreenState extends State<DuelScreen>
    with SingleTickerProviderStateMixin {
  late final DuelController c = DuelController(loadout: widget.loadout);
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

  static const _spellKeyLabels = 'QWERTASDFG';

  @override
  void dispose() {
    _fx.dispose();
    c.dispose();
    super.dispose();
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
      // a future that never completes (which would freeze the turn loop).
      await _fx.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Animation was interrupted — skip ahead.
    }
    if (mounted) setState(() => _fxKind = _FxKind.none);
  }

  Future<void> _submit(MageAction action) async {
    try {
      final events = c.submitTurn(action);
      for (final event in events) {
        await _animate(event);
        if (!mounted) return;
        c.applyEvent(event);
      }
    } catch (error, stack) {
      debugPrint('Turn resolution error: $error\n$stack');
    } finally {
      if (mounted) {
        setState(() => _banner = null);
        c.finishTurn();
      }
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
        setState(() {
          _banner = isEnemy
              ? '${c.enemy.name} casts ${element.style.label} ${spell.name}'
              : 'You cast ${element.style.label} ${spell.name}';
          _bannerColor = element.style.color;
        });
        await _runFx(_FxKind.flash,
            atEnemy: isEnemy,
            color: element.style.color,
            intensity: 1 + _castCharge * 0.3,
            ms: 300 + _castCharge * 40);
      case DamageEvent(
          :final target,
          :final toShield,
          :final toHp,
          :final countered,
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
          if (countered) '2x vs shield',
          if (shieldBroken) 'shield shattered',
        ].join('  ');
        await _runFx(_FxKind.impact,
            atEnemy: isEnemy,
            color: color,
            text: text,
            intensity: 1 + charge * 0.45,
            shake: charge >= 3 ? (charge - 2) * 3.5 : 0,
            ms: isMultiHit ? 320 : 440 + charge * 50);
      case ShieldRaisedEvent(:final mage, :final shield):
        final isEnemy = mage == c.enemy;
        final color =
            shield.isBarrier ? Colors.white : shield.element!.style.color;
        await _runFx(_FxKind.shieldUp,
            atEnemy: isEnemy,
            color: color,
            intensity: shield.isBarrier ? 1.6 : 0.8 + shield.remaining / 40,
            ms: 480);
      case HealedEvent(:final mage, :final amount):
        await _runFx(_FxKind.heal,
            atEnemy: mage == c.enemy,
            color: const Color(0xFF58B368),
            text: '+$amount',
            intensity: 1 + amount / 30,
            ms: 500);
      case BuffAppliedEvent(:final mage, :final description):
        setState(() {
          _banner =
              '${mage == c.enemy ? c.enemy.name : 'You'}: $description';
          _bannerColor = const Color(0xFFE8C547);
        });
        await _runFx(_FxKind.flash,
            atEnemy: mage == c.enemy,
            color: const Color(0xFFE8C547),
            ms: 550);
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
              apparel:
                  isEnemy ? MageApparel.duskWitch : MageApparel.apprenticeBlue,
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

  Widget _playerPanel() {
    return _StatusPanel(
      name: 'You',
      hp: c.shownPlayerHp,
      maxHp: c.player.maxHp,
      charge: c.shownPlayerCharge,
      element: c.shownPlayerElement ?? c.pendingElement,
      elementHidden: false,
      shield: c.shownPlayerShield,
      alignEnd: false,
      buffs: [
        if (c.player.empowerMultiplier != null) 'Empowered',
        if (c.player.quickenPriority != null) 'Quickened',
        if (c.player.phaseNext) 'Phasing',
      ],
    );
  }

  Widget _enemyPanel() {
    return _StatusPanel(
      name: c.enemy.name,
      hp: c.shownEnemyHp,
      maxHp: c.enemy.maxHp,
      charge: c.shownEnemyCharge,
      element: c.revealedEnemyElement,
      elementHidden: c.enemyIsCharging && c.revealedEnemyElement == null,
      shield: c.shownEnemyShield,
      alignEnd: true,
      buffs: [
        if (c.enemy.empowerMultiplier != null) 'Empowered',
        if (c.enemy.quickenPriority != null) 'Quickened',
        if (c.enemy.phaseNext) 'Phasing',
      ],
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
    final title = c.isDraw
        ? 'Draw'
        : c.playerWon
            ? 'Victory!'
            : 'Defeat';
    return Positioned.fill(
      child: Container(
        color: const Color(0xB3000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: c.playerWon
                          ? const Color(0xFFE8C547)
                          : Colors.white)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.tune),
                    label: const Text('Change loadout'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: c.newDuel,
                    icon: const Icon(Icons.replay),
                    label: const Text('Duel again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1531),
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final line in c.battleLog.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line,
                  style: TextStyle(
                      color: line.startsWith('—')
                          ? const Color(0xFFE8C547)
                          : const Color(0xFFB9B2D6),
                      fontSize: 12.5)),
            ),
        ],
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
  final List<String> buffs;

  const _StatusPanel({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.charge,
    required this.element,
    required this.elementHidden,
    required this.shield,
    required this.alignEnd,
    required this.buffs,
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
              Text('$hp/$maxHp',
                  style:
                      const TextStyle(color: Color(0xFF9C93C4), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
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
          if (shield != null || buffs.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if (shield != null) _shieldBadge(),
              for (final buff in buffs) _badge(buff, const Color(0xFFE8C547)),
            ],
          ),
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
