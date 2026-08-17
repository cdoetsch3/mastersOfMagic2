/// The precision engines (ITEMS §9b.9a): trace and alignCommit.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../game/crafting/gesture.dart';
import '../app_theme.dart';
import 'scoring.dart';

/// Drag along the shown line without leaving it. Complexity picks the line:
/// 1 a gentle arc, 2+ an S-curve. Coverage beats wobble (scoring.traceScore).
/// Skins: carve, thread, cut, pull, rune-trace.
class TraceStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const TraceStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<TraceStep> createState() => _TraceStepState();
}

class _TraceStepState extends State<TraceStep> {
  static const _size = Size(300, 220);

  late final List<Offset> _path = _buildPath();
  final List<Offset> _drag = [];

  /// Per path point: has the drag ever come close enough?
  late final List<bool> _covered = List.filled(_path.length, false);
  var _done = false;

  double get _tolerance => 22.0 * widget.tuning.window;

  List<Offset> _buildPath() {
    // ⭐ Deterministic per complexity — the recipe's own contribution
    // (lever 4's authored half); randomness here would make one craft of a
    // recipe harder than the next for no reason the player can see.
    final pts = <Offset>[];
    const n = 40;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final x = 20 + t * (_size.width - 40);
      final y = widget.step.complexity <= 1
          // A single gentle arc.
          ? _size.height / 2 + sin(t * pi) * -55
          // An S-curve that doubles back.
          : _size.height / 2 + sin(t * 2 * pi) * 62;
      pts.add(Offset(x, y));
    }
    return pts;
  }

  void _onDrag(Offset local) {
    if (_done) return;
    setState(() {
      _drag.add(local);
      for (var i = 0; i < _path.length; i++) {
        if (!_covered[i] && (local - _path[i]).distance <= _tolerance) {
          _covered[i] = true;
        }
      }
    });
    // Reaching the end of the line finishes the stroke.
    if ((local - _path.last).distance <= _tolerance) _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    final coverage =
        _covered.where((c) => c).length / _covered.length.toDouble();
    var onPath = 0;
    for (final p in _drag) {
      final d = distanceToPolyline(
        p.dx,
        p.dy,
        [for (final q in _path) q.dx],
        [for (final q in _path) q.dy],
      );
      if (d <= _tolerance) onPath++;
    }
    final fidelity = _drag.isEmpty ? 0.0 : onPath / _drag.length;
    widget.onDone(traceScore(coverage: coverage, fidelity: fidelity));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Follow the line, end to end',
          style: TextStyle(color: AppColors.text, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onPanUpdate: (d) => _onDrag(d.localPosition),
          // Lifting early scores what was covered — abandoning a carve is
          // a worse carve, not a reset (cumulative accuracy, §9b.9b).
          onPanEnd: (_) => _finish(),
          child: Container(
            width: _size.width,
            height: _size.height,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: CustomPaint(
              painter: _TracePainter(
                path: _path,
                drag: _drag,
                covered: _covered,
                tolerance: _tolerance,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<Offset> path;
  final List<Offset> drag;
  final List<bool> covered;
  final double tolerance;

  _TracePainter({
    required this.path,
    required this.drag,
    required this.covered,
    required this.tolerance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..strokeWidth = tolerance
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lit = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < path.length - 1; i++) {
      canvas.drawLine(path[i], path[i + 1], guide..strokeWidth = tolerance);
      if (covered[i]) canvas.drawLine(path[i], path[i + 1], lit);
    }
    // Start and end markers.
    canvas.drawCircle(path.first, 7, Paint()..color = AppColors.teal);
    canvas.drawCircle(path.last, 7, Paint()..color = AppColors.ember);
    final ink = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < drag.length - 1; i++) {
      canvas.drawLine(drag[i], drag[i + 1], ink);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.drag.length != drag.length || old.covered != covered;
}

/// A needle wobbles around centre; commit (tap) when it settles level.
/// Skins: knot, pour, gem-set, tune, stamp.
class AlignCommitStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const AlignCommitStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<AlignCommitStep> createState() => _AlignCommitStepState();
}

class _AlignCommitStepState extends State<AlignCommitStep>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  var _done = false;

  double get _window => 0.12 * widget.tuning.window;

  /// Two incommensurate sines — a wobble with a rhythm you can read but
  /// not simply count. Slower at higher margin.
  double get _needle {
    final tempo = widget.tuning.tempo;
    return 0.6 * sin(_t * 2.1 / tempo) + 0.4 * sin(_t * 3.7 / tempo);
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() => _t += 1 / 60))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _commit() {
    if (_done) return;
    _done = true;
    // Needle spans −1..1; closeness against 0 with the tuned window.
    widget.onDone(closeness(_needle.abs(), 0, _window * 2));
  }

  @override
  Widget build(BuildContext context) {
    final needle = _needle;
    return GestureDetector(
      onTapDown: (_) => _commit(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 90,
            child: CustomPaint(
              painter: _NeedlePainter(needle: needle, window: _window),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.step.skin == 'pour'
                ? 'Tap when the stream runs level'
                : 'Tap when it settles in the centre',
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final double needle; // −1..1
  final double window;

  _NeedlePainter({required this.needle, required this.window});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, baseY - 4, size.width, baseY + 4),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.bg,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        cx - size.width / 2 * window,
        baseY - 10,
        cx + size.width / 2 * window,
        baseY + 10,
      ),
      Paint()..color = AppColors.gold.withValues(alpha: 0.4),
    );
    final tip = Offset(cx + needle * (size.width / 2 - 10), 8);
    canvas.drawLine(
      Offset(cx, baseY),
      tip,
      Paint()
        ..color = AppColors.teal
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 6, Paint()..color = AppColors.teal);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.needle != needle;
}
