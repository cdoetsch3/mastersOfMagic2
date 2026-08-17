/// The timing engines (ITEMS §9b.9a): releaseTiming and sweetSpot.
///
/// ⭐ **An engine is an input contract, not a picture** — the skin only
/// changes copy and accent colour. Both engines here share the shape: a
/// moving value, a target, and one decisive act whose closeness scores.
///
/// Every engine widget takes its [GestureStep], the computed [StepTuning]
/// (levers 4–6 — wider windows and slower sweeps at higher margin), and an
/// [onDone] fired exactly once with the step's 0–1 accuracy.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../game/crafting/gesture.dart';
import '../app_theme.dart';
import 'scoring.dart';

/// Hold — a power meter climbs and falls while held — release at the peak
/// band. One swing per rep; the step's accuracy is the mean of its swings.
/// Skins: chop, quench, channel.
class ReleaseTimingStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const ReleaseTimingStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<ReleaseTimingStep> createState() => _ReleaseTimingStepState();
}

class _ReleaseTimingStepState extends State<ReleaseTimingStep>
    with SingleTickerProviderStateMixin {
  static const _target = 0.82;

  late final Ticker _ticker;
  double _held = 0; // seconds the current hold has run
  bool _holding = false;
  final List<double> _swings = [];

  /// Slower climb at higher margin — lever 6 as a felt thing.
  double get _period => 1.1 * widget.tuning.tempo;
  double get _window => 0.11 * widget.tuning.window * // lever 4's authored
      (1.0 - 0.1 * (widget.step.complexity - 1)); //    half tightens it

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_holding) {
        setState(() => _held += 1 / 60);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double get _meter => pingPong(_held, _period);

  void _release() {
    if (!_holding) return;
    final swing = closeness(_meter, _target, _window);
    setState(() {
      _holding = false;
      _held = 0;
      _swings.add(swing);
    });
    if (_swings.length >= widget.step.reps) {
      widget.onDone(gradeOf(_swings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meter = _meter;
    return GestureDetector(
      onTapDown: (_) => setState(() => _holding = true),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Swing ${min(_swings.length + 1, widget.step.reps)} '
            'of ${widget.step.reps}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 66,
            height: 220,
            child: CustomPaint(
              painter: _MeterPainter(
                value: _holding ? meter : 0,
                target: _target,
                window: _window,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _holding ? 'Release at the mark!' : 'Press and hold…',
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
          if (_swings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _swings.map((s) => gradeLabel(s)).join(' · '),
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double value, target, window;
  _MeterPainter({
    required this.value,
    required this.target,
    required this.window,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(r, Paint()..color = AppColors.bg);
    canvas.drawRRect(
      r,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke,
    );
    // Target band, top-down coordinates.
    final bandTop = size.height * (1 - (target + window));
    final bandBottom = size.height * (1 - (target - window));
    canvas.drawRect(
      Rect.fromLTRB(2, bandTop, size.width - 2, bandBottom),
      Paint()..color = AppColors.gold.withValues(alpha: 0.35),
    );
    // Fill.
    final fillTop = size.height * (1 - value);
    canvas.drawRect(
      Rect.fromLTRB(4, fillTop, size.width - 4, size.height - 4),
      Paint()..color = AppColors.teal.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.value != value || old.target != target || old.window != window;
}

/// Tap as the marker crosses the mark. The marker ping-pongs along a track;
/// each rep re-seats the mark so rhythm is earned, not memorised.
/// Skins: stitch, hammer, distil.
class SweetSpotStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const SweetSpotStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<SweetSpotStep> createState() => _SweetSpotStepState();
}

class _SweetSpotStepState extends State<SweetSpotStep>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rng = Random();
  double _t = 0;
  late double _target = _nextTarget();
  final List<double> _taps = [];

  double get _period => 0.9 * widget.tuning.tempo;
  double get _window => 0.09 * widget.tuning.window;

  double _nextTarget() => 0.25 + _rng.nextDouble() * 0.5;

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

  void _tap() {
    final marker = pingPong(_t, _period);
    setState(() {
      _taps.add(closeness(marker, _target, _window));
      _target = _nextTarget();
    });
    if (_taps.length >= widget.step.reps) {
      widget.onDone(gradeOf(_taps));
    }
  }

  @override
  Widget build(BuildContext context) {
    final marker = pingPong(_t, _period);
    return GestureDetector(
      onTapDown: (_) => _tap(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${widget.step.skin == 'stitch' ? 'Stitch' : 'Strike'} '
            '${min(_taps.length + 1, widget.step.reps)} of ${widget.step.reps}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 280,
            height: 54,
            child: CustomPaint(
              painter: _TrackPainter(
                marker: marker,
                target: _target,
                window: _window,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap as the needle crosses the mark',
            style: TextStyle(color: AppColors.text, fontSize: 14),
          ),
          if (_taps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _taps.map(gradeLabel).join(' · '),
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final double marker, target, window;
  _TrackPainter({
    required this.marker,
    required this.target,
    required this.window,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, midY - 5, size.width, midY + 5),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.bg,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * (target - window),
        midY - 12,
        size.width * (target + window),
        midY + 12,
      ),
      Paint()..color = AppColors.gold.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      Offset(size.width * marker, midY),
      9,
      Paint()..color = AppColors.teal,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.marker != marker || old.target != target;
}
