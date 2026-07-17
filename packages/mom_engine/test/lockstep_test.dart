import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The multiplayer contract: two engines fed the same actions and per-turn
/// seeds must reach identical state (this is what lets both clients resolve
/// duels locally in a commit-reveal exchange).
void main() {
  test('two engines in lockstep stay byte-identical for a whole duel', () {
    const masterSeed = 987654;
    final rngA = ReseedableRandom();
    final rngB = ReseedableRandom();
    final a1 = MageState(name: 'Host');
    final a2 = MageState(name: 'Guest');
    final b1 = MageState(name: 'Host');
    final b2 = MageState(name: 'Guest');
    final engineA = DuelEngine(a1, a2, rng: rngA);
    final engineB = DuelEngine(b1, b2, rng: rngB);

    // Scripted decision-making driven by a third RNG (simulating players).
    final script = Random(42);
    final ai = TunableAi(mistakeChance: 0.4);
    var turn = 0;
    while (!engineA.isOver && turn < 100) {
      turn++;
      final move1 = ai.chooseAction(a1, a2, script);
      final move2 = ai.chooseAction(a2, a1, script);
      final seed = deriveTurnSeed(
          masterSeed, turn, encodeAction(move1), encodeAction(move2));
      rngA.reseed(seed);
      rngB.reseed(seed);
      engineA.resolveTurn(move1, move2);
      // Engine B receives the moves over "the wire".
      engineB.resolveTurn(
        decodeAction(encodeAction(move1)),
        decodeAction(encodeAction(move2)),
      );

      expect(b1.hp, a1.hp, reason: 'host hp diverged on turn $turn');
      expect(b2.hp, a2.hp, reason: 'guest hp diverged on turn $turn');
      expect(b1.charge, a1.charge);
      expect(b2.charge, a2.charge);
      expect(b1.shield?.remaining, a1.shield?.remaining);
      expect(b2.shield?.remaining, a2.shield?.remaining);
      expect(b1.hasHaste, a1.hasHaste);
      expect(b2.hasHaste, a2.hasHaste);
    }
    expect(engineA.isOver, isTrue, reason: 'the duel should finish');
    expect(engineB.isOver, isTrue);
    expect(engineB.winner?.name, engineA.winner?.name);
  });

  test('ReseedableRandom replays identically after reseed', () {
    final r = ReseedableRandom();
    r.reseed(123);
    final first = List.generate(10, (_) => r.nextInt(1000));
    r.reseed(123);
    final second = List.generate(10, (_) => r.nextInt(1000));
    expect(second, first);
  });

  group('TunableAi', () {
    test('always produces legal moves across whole duels', () {
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        final m1 = MageState(name: 'A');
        final m2 = MageState(name: 'B');
        final duel = DuelEngine(m1, m2, rng: rng);
        final novice = TunableAi(mistakeChance: 0.6, aggression: 0.5);
        final vet = TunableAi(mistakeChance: 0.0);
        while (!duel.isOver && duel.turnNumber < 200) {
          duel.resolveTurn(
            novice.chooseAction(m1, m2, rng),
            vet.chooseAction(m2, m1, rng),
          );
        }
      }
    });

    test('lower mistakeChance beats higher mistakeChance', () {
      final rng = Random(11);
      var sharpWins = 0, sloppyWins = 0;
      for (var i = 0; i < 300; i++) {
        final sharp = MageState(name: 'Sharp');
        final sloppy = MageState(name: 'Sloppy');
        final duel = DuelEngine(sharp, sloppy, rng: rng);
        final sharpAi = TunableAi(mistakeChance: 0.02);
        final sloppyAi = TunableAi(mistakeChance: 0.6);
        while (!duel.isOver && duel.turnNumber < 200) {
          duel.resolveTurn(
            sharpAi.chooseAction(sharp, sloppy, rng),
            sloppyAi.chooseAction(sloppy, sharp, rng),
          );
        }
        if (duel.winner == sharp) sharpWins++;
        if (duel.winner == sloppy) sloppyWins++;
      }
      expect(sharpWins, greaterThan(sloppyWins * 2),
          reason: 'skill dial should matter ($sharpWins vs $sloppyWins)');
    });
  });
}
