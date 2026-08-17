/// The regulation engines (ITEMS §9b.9a): rateDrag and bandKeeper.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../game/crafting/gesture.dart';
import '../app_theme.dart';
import 'scoring.dart';

/// Keep scrubbing at a steady rate — too slow does nothing, too fast bites.
/// Progress accrues only while the speed sits in the band; the step ends
/// when the work meter fills. Skins: sand, grind, swirl, saw, wire.
class RateDragStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const RateDragStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<RateDragStep> createState() => _RateDragStepState();
}

class _RateDragStepState extends State<RateDragStep>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Work needed, seconds-in-band. Reps are literally more rubbing.
  late final double _workNeeded = 2.2 * widget.step.reps;

  double _progress = 0; // seconds in band
  double _dragTime = 0; // seconds dragging at all
  double _speed = 0; //    px/s, smoothed
  Offset? _last;
  var _done = false;

  // Band in px/s; wider with margin. Values chosen for thumb and mouse alike.
  double get _lo => 140 / widget.tuning.window;
  double get _hi => 700 * widget.tuning.window;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_done) return;
      setState(() {
        // Exponential decay so lifting the finger reads as stopping.
        _speed *= 0.86;
        if (_speed > 1) {
          _dragTime += 1 / 60;
          if (_speed >= _lo && _speed <= _hi) _progress += 1 / 60;
        }
      });
      if (_progress >= _workNeeded) {
        _done = true;
        widget.onDone(bandFraction(_progress, max(_dragTime, 0.001)));
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onMove(Offset p) {
    if (_last != null) {
      // Instantaneous speed, blended for stability at 60fps.
      final v = (p - _last!).distance * 60;
      _speed = _speed * 0.7 + v * 0.3;
    }
    _last = p;
  }

  @override
  Widget build(BuildContext context) {
    final inBand = _speed >= _lo && _speed <= _hi && _speed > 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          switch (widget.step.skin) {
            'grind' => 'Grind — steady circles',
            'swirl' => 'Swirl — steady circles',
            _ => 'Scrub — small steady strokes',
          },
          style: const TextStyle(color: AppColors.text, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onPanUpdate: (d) => _onMove(d.localPosition),
          onPanEnd: (_) => _last = null,
          child: Container(
            width: 280,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: inBand ? AppColors.teal : AppColors.border,
                width: inBand ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _speed <= 1
                    ? 'rub here'
                    : inBand
                    ? 'good…'
                    : _speed < _lo
                    ? 'faster'
                    : 'gentler!',
                style: TextStyle(
                  color: inBand ? AppColors.teal : AppColors.textDim,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_progress / _workNeeded).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.bg,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hold to heat, release to cool — keep the line inside the drifting band
/// until the timer runs out. Skins: simmer, bellows, glass-blow.
class BandKeeperStep extends StatefulWidget {
  final GestureStep step;
  final StepTuning tuning;
  final ValueChanged<double> onDone;

  const BandKeeperStep({
    super.key,
    required this.step,
    required this.tuning,
    required this.onDone,
  });

  @override
  State<BandKeeperStep> createState() => _BandKeeperStepState();
}

class _BandKeeperStepState extends State<BandKeeperStep>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final double _duration = 4.0 * widget.step.reps;

  double _t = 0;
  double _value = 0.5;
  double _inBand = 0;
  bool _holding = false;
  var _done = false;

  double get _bandHalf => 0.09 * widget.tuning.window;

  double _bandCenter(double t) =>
      0.5 + 0.24 * sin(t * 0.9 / widget.tuning.tempo);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_done) return;
      setState(() {
        _t += 1 / 60;
        // Heat rises while held, falls while not; both gentle.
        _value += (_holding ? 0.55 : -0.45) / 60;
        _value = _value.clamp(0.0, 1.0);
        final c = _bandCenter(_t);
        if ((_value - c).abs() <= _bandHalf) _inBand += 1 / 60;
      });
      if (_t >= _duration) {
        _done = true;
        widget.onDone(bandFraction(_inBand, _duration));
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _bandCenter(_t);
    final inBand = (_value - c).abs() <= _bandHalf;
    return GestureDetector(
      onTapDown: (_) => setState(() => _holding = true),
      onTapUp: (_) => setState(() => _holding = false),
      onTapCancel: () => setState(() => _holding = false),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hold to heat — stay in the band '
            '(${max(0, _duration - _t).ceil()}s)',
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            height: 170,
            child: CustomPaint(
              painter: _BandPainter(
                value: _value,
                center: c,
                half: _bandHalf,
                inBand: inBand,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            inBand ? 'simmering…' : (_holding ? 'too hot!' : 'too cool'),
            style: TextStyle(
              color: inBand ? AppColors.teal : AppColors.textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  final double value, center, half;
  final bool inBand;

  _BandPainter({
    required this.value,
    required this.center,
    required this.half,
    required this.inBand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = AppColors.bg,
    );
    double y(double v) => size.height * (1 - v);
    canvas.drawRect(
      Rect.fromLTRB(0, y(center + half), size.width, y(center - half)),
      Paint()..color = AppColors.gold.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      Offset(0, y(value)),
      Offset(size.width, y(value)),
      Paint()
        ..color = inBand ? AppColors.teal : AppColors.ember
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.value != value || old.center != center || old.inBand != inBand;
}
