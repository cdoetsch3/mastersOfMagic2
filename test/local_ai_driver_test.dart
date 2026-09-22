/// `LocalAiDriver`'s two LADDER seams (LADDER §4): a bot's wardrobe
/// (`gear`) and the rated-bot marker (`ladderBot`).
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

  group('ladderBot flag (the rated marker; the think-time pause is gone)', () {
    test('defaults to false for every campaign/practice caller', () {
      final driver = LocalAiDriver(persona: AiRoster.all.first);
      expect(
        driver.ladderBot,
        isFalse,
        reason:
            'a mutant defaulting to true would rate every practice bout '
            'against Wick as a ladder match',
      );
    });

    test('exchangeTurn answers without any injected delay', () async {
      final driver = LocalAiDriver(
        persona: AiRoster.all.first,
        ladderBot: true,
        rng: Random(1),
      );
      driver.bind(MageState(name: 'You'), MageState(name: 'Foe'));
      final sw = Stopwatch()..start();
      await driver.exchangeTurn(1, const ForfeitAction());
      sw.stop();
      expect(
        sw.elapsedMilliseconds,
        lessThan(200),
        reason:
            'Christian removed the 1–5 s bot pause (2026-09-21); a mutant '
            'that still sleeps on a ladder bot fails here',
      );
    });
  });
}
