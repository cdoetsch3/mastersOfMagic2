import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/shield_aura.dart';

void main() {
  group('shieldRings splits a total into 100-point rings', () {
    test('nothing to draw at or below zero', () {
      expect(shieldRings(0), isEmpty);
      expect(shieldRings(-5), isEmpty);
    });

    test('anything at or under 100 is a single ring', () {
      expect(shieldRings(1), [1]);
      expect(shieldRings(45), [45]);
      expect(shieldRings(100), [100]);
    });

    test("the worked example: 120 is a full 100 plus a 20", () {
      expect(shieldRings(120), [100, 20]);
    });

    test('the partial ring is last, so it can be drawn outermost', () {
      expect(shieldRings(175), [100, 75]);
      expect(shieldRings(260), [100, 100, 60]);
    });

    test('exact multiples produce no empty partial ring', () {
      expect(shieldRings(200), [100, 100]);
      expect(shieldRings(300), [100, 100, 100]);
    });

    test('the rings always sum back to the total', () {
      for (var total = 1; total <= 400; total++) {
        expect(
          shieldRings(total).fold(0, (a, b) => a + b),
          total,
          reason: 'total $total',
        );
      }
    });

    test(
      '120 taking a 40-point hit drops the small ring and thins the big one',
      () {
        expect(shieldRings(120), [100, 20], reason: 'before');
        // 20 absorbed by the outer ring, 20 more off the inner one.
        expect(shieldRings(80), [80], reason: 'after — one thinner ring');
      },
    );
  });

  group('the aura paints without error across the whole range', () {
    // Guards the geometry maths: a stack deep enough to matter, no shield,
    // no barrier, and the maxed-out combination all have to paint cleanly.
    for (final (label, colour, remaining, barrier)
        in <(String, Color?, int, int)>[
          ('nothing at all', null, 0, 0),
          ('barrier only', null, 0, 3),
          ('a Ward', Colors.blue, 15, 0),
          ('a Sanctuary', Colors.blue, 75, 0),
          ('a stacked 260', Colors.blue, 260, 0),
          ('everything at once', Colors.blue, 260, 3),
        ]) {
      testWidgets('paints $label', (tester) async {
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: CustomPaint(
                painter: ShieldAuraPainter(
                  shieldColor: colour,
                  shieldRemaining: remaining,
                  barrierPoints: barrier,
                  spriteHeight: 150,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  test('stroke scales with the sprite so it reads the same on any screen', () {
    // Not a paint assertion — just pinning the documented constants, since the
    // whole "same weight on every screen" claim rests on them.
    expect(shieldPxPerPoint * 15, closeTo(3.0, 0.01), reason: 'Ward ~3px');
    expect(
      shieldPxPerPoint * 75,
      closeTo(15.0, 0.01),
      reason: 'Sanctuary ~15px',
    );
    expect(
      shieldPxPerPoint * shieldPointsPerRing,
      20.0,
      reason: 'a full ring caps at 20px, under the barrier gap',
    );
  });
}
