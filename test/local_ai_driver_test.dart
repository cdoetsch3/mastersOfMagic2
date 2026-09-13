/// `LocalAiDriver`'s two LADDER seams (LADDER §4): a bot's wardrobe
/// (`gear`) and its per-move delay (`thinkTime`).
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — gear that never reaches the wire, gear that leaks onto a bestiary
/// enemy, a delay that never fires, and a delay that fires when it shouldn't.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/ladder/think_time.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:mom_engine/mom_engine.dart';

const _gear = ItemModifiers(accuracyBonus: 7, maxHpBonus: 25);

void main() {
  group('opponentGear', () {
    test('returns the passed gear when no bestiary enemy is set', () {
      final driver = LocalAiDriver(
        persona: AiRoster.all.first,
        gear: _gear,
        rng: Random(1),
      );
      expect(
        driver.opponentGear,
        _gear,
        reason:
            'a LADDER bot wears a real wardrobe derived from catalogue '
            'items exactly like a player (LADDER §4) — a driver that ignores '
            'the constructor param and keeps returning ItemModifiers.none '
            'would silently undress every bot',
      );
    });

    test(
      'returns ItemModifiers.none for a bestiary enemy even with gear set',
      () {
        final driver = LocalAiDriver(
          persona: AiRoster.all.first,
          enemy: WhisperingWoodsBestiary.listeningFawn,
          gear: _gear,
          rng: Random(1),
        );
        expect(
          driver.opponentGear,
          ItemModifiers.none,
          reason:
              'an archetype and a wardrobe must never stack on one body — '
              'a driver that returns the passed gear whenever enemy is set '
              'would double-dress every bestiary creature',
        );
      },
    );
  });

  group('thinkTime', () {
    test(
      'a non-null thinkTime delays exchangeTurn by at least its minimum',
      () async {
        final driver = LocalAiDriver(
          persona: AiRoster.all.first,
          thinkTime: const ThinkTime(
            meanSeconds: 0.05,
            sigmaSeconds: 0.0,
            minSeconds: 0.05,
            maxSeconds: 0.05,
          ),
          rng: Random(1),
        );
        driver.bind(MageState(name: 'You'), MageState(name: 'Foe'));

        final stopwatch = Stopwatch()..start();
        await driver.exchangeTurn(1, const ForfeitAction());
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          greaterThanOrEqualTo(50),
          reason:
              'a driver that ignores thinkTime (or awaits it AFTER '
              'returning, e.g. fire-and-forget) would answer before the 50ms '
              'floor this ThinkTime enforces',
        );
      },
    );

    test(
      'a null thinkTime (every campaign/practice caller) adds no delay',
      () async {
        final driver = LocalAiDriver(
          persona: AiRoster.all.first,
          rng: Random(1),
        );
        driver.bind(MageState(name: 'You'), MageState(name: 'Foe'));

        final stopwatch = Stopwatch()..start();
        await driver.exchangeTurn(1, const ForfeitAction());
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(20),
          reason:
              'campaign and practice duels never set thinkTime — a driver '
              'that draws a delay unconditionally would slow down every '
              'existing duel, not just the ladder',
        );
      },
    );
  });
}
