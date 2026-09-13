import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Mutation-verified: every `expect` names the mutant it kills
/// (LADDER_DESIGN §2 is the spec).
void main() {
  group('Elo.expected', () {
    test('equal ratings are a coinflip', () {
      expect(
        Elo.expected(1200, 1200),
        0.5,
        reason:
            'equal ratings must give exactly 0.5 — '
            'a mutant that drops the +1 in the denominator fails here',
      );
    });

    test('200-point gap is ~0.24 win probability', () {
      expect(
        double.parse(Elo.expected(1200, 1400).toStringAsFixed(2)),
        0.24,
        reason:
            'a mutant that flips the sign of (b-a) would give 0.76 '
            'instead of 0.24',
      );
    });

    test('symmetry: expected(a,b) + expected(b,a) == 1', () {
      for (final pair in [
        [1200, 1200],
        [1200, 1400],
        [1000, 1900],
        [2400, 800],
      ]) {
        final sum =
            Elo.expected(pair[0], pair[1]) + Elo.expected(pair[1], pair[0]);
        expect(
          sum,
          closeTo(1.0, 1e-9),
          reason:
              'expected(a,b)+expected(b,a) must sum to 1 for $pair — '
              'a mutant that uses (a-b) instead of (b-a) on one side breaks '
              'this symmetry',
        );
      }
    });
  });

  group('Elo.delta', () {
    test('equal ratings, win, K40 -> +20', () {
      expect(
        Elo.delta(rating: 1200, opponentRating: 1200, score: 1.0, k: 40),
        20,
        reason:
            'K * (1 - 0.5) = 20 — a mutant that hardcodes score as 0.5 '
            'or drops the K multiply fails here',
      );
    });

    test('equal ratings, loss, K40 -> -20', () {
      expect(
        Elo.delta(rating: 1200, opponentRating: 1200, score: 0.0, k: 40),
        -20,
        reason:
            'K * (0 - 0.5) = -20 — a mutant that uses score.abs() or '
            'forgets the loss case entirely fails here',
      );
    });

    test('1200 vs 1400, win, K40 -> +30 (nearest-int rounding)', () {
      // exact: 40 * (1 - 0.240253...) = 30.3899 -> rounds to 30
      expect(
        Elo.delta(rating: 1200, opponentRating: 1400, score: 1.0, k: 40),
        30,
        reason:
            'a mutant that truncates instead of rounds would give 30 '
            'too by luck here, but one that floors 30.39 down after adding '
            '0.5 wrongly (banker\'s-style) or ceils would give 31 — this '
            'pins the exact rounded value the spec calls out',
      );
    });

    test('rounding is nearest-int both directions', () {
      // 1200 vs 1207: expected(1200,1207) = 1/(1+10^(7/400)) ~ 0.48993
      // K=20: 20*(1-0.48993)=10.2014 -> rounds to 10
      expect(
        Elo.delta(rating: 1200, opponentRating: 1207, score: 1.0, k: 20),
        10,
        reason: 'a mutant that always rounds up (ceil) would give 11 here',
      );
      // 1207 vs 1200 losing: expected(1207,1200) ~0.51007
      // K=20: 20*(0-0.51007) = -10.2014 -> rounds to -10
      expect(
        Elo.delta(rating: 1207, opponentRating: 1200, score: 0.0, k: 20),
        -10,
        reason:
            'a mutant that always rounds toward zero after truncating '
            'the wrong way, or floors negative numbers (giving -11), '
            'fails this negative-side rounding check',
      );
    });

    test('zero-sum-ish: winner delta == -loser delta at equal K', () {
      for (final pair in [
        [1200, 1200],
        [1200, 1400],
        [1000, 1600],
        [1500, 1450],
        [900, 2100],
      ]) {
        final a = pair[0], b = pair[1];
        const k = 32;
        final winnerDelta = Elo.delta(
          rating: a,
          opponentRating: b,
          score: 1.0,
          k: k,
        );
        final loserDelta = Elo.delta(
          rating: b,
          opponentRating: a,
          score: 0.0,
          k: k,
        );
        expect(
          winnerDelta,
          -loserDelta,
          reason:
              'at equal K, what the winner gains the loser must lose '
              'for $pair — a mutant that computes expected() from the '
              'wrong side for one of the two calls breaks this',
        );
      }
    });
  });

  group('Elo.kFor', () {
    test('29 rated games, low peak -> K40', () {
      expect(
        Elo.kFor(ratedGames: 29, peakRating: 1500),
        40,
        reason:
            'still under the 30-game threshold — a mutant using '
            '<= instead of < would wrongly drop to 20 here',
      );
    });

    test('30 rated games, low peak -> K20', () {
      expect(
        Elo.kFor(ratedGames: 30, peakRating: 1500),
        20,
        reason:
            'exactly the 30-game boundary — a mutant using < instead '
            'of <= (i.e. checking ratedGames < 30 wrong-way) would keep '
            'this at 40',
      );
    });

    test('peak 2400, zero rated games -> K10 always wins', () {
      expect(
        Elo.kFor(ratedGames: 0, peakRating: 2400),
        10,
        reason:
            'the 2400-peak rule overrides the games count entirely — '
            'a mutant that checks games first and returns early would '
            'give 40 here',
      );
    });

    test('peak 2399 with 100 games -> K20, not K10', () {
      expect(
        Elo.kFor(ratedGames: 100, peakRating: 2399),
        20,
        reason:
            'peak must clear 2400, not just get close — a mutant using '
            '>= 2399 or > 2399 would wrongly give 10 here',
      );
    });
  });

  group('Elo.clampToSeed', () {
    test('below floor gets raised to seed - band', () {
      expect(
        Elo.clampToSeed(1000, seed: 1400, band: 300),
        1100,
        reason:
            'floor is seed - band = 1100 — a mutant that adds instead '
            'of subtracts the band would give 1700',
      );
    });

    test('above ceiling gets lowered to seed + band', () {
      expect(
        Elo.clampToSeed(1800, seed: 1400, band: 300),
        1700,
        reason:
            'ceiling is seed + band = 1700 — a mutant that clamps to '
            'the floor on the high side too would wrongly give 1100',
      );
    });

    test('inside the band is left unchanged', () {
      expect(
        Elo.clampToSeed(1350, seed: 1400, band: 300),
        1350,
        reason:
            'a mutant that always snaps to the seed would give 1400 '
            'here instead of leaving 1350 alone',
      );
    });

    test('band parameter is honoured, not hardcoded to 300', () {
      expect(
        Elo.clampToSeed(1000, seed: 1400, band: 100),
        1300,
        reason:
            'floor with band=100 is 1300 — a mutant that ignores the '
            'band parameter and always uses 300 would give 1100 instead',
      );
    });

    test('default band is 300 when omitted', () {
      expect(
        Elo.clampToSeed(1000, seed: 1400),
        1100,
        reason:
            'the default band must be 300 — a mutant that changes the '
            'default would move this floor',
      );
    });
  });

  group('LadderSeeds.gearedBot', () {
    test('Wick: L1, int1, Bare(0) -> 1107', () {
      expect(
        LadderSeeds.gearedBot(level: 1, intelligence: 1, gearTerm: 0),
        1107,
        reason:
            'LADDER_DESIGN §5 roster table pins Wick at 1107 — a '
            'mutant that drops the +15*intelligence term would give 1092',
      );
    });

    test("Al'Dorian: L50, int9, Peak(60) -> 1875", () {
      expect(
        LadderSeeds.gearedBot(level: 50, intelligence: 9, gearTerm: 60),
        1875,
        reason:
            "LADDER_DESIGN §5 roster table pins Al'Dorian at 1875 — a "
            'mutant that uses 10*level instead of 12*level would give 1795',
      );
    });

    test('Ysolde: L50, int8, Peak(60) -> 1860 (second data point)', () {
      expect(
        LadderSeeds.gearedBot(level: 50, intelligence: 8, gearTerm: 60),
        1860,
        reason:
            'LADDER_DESIGN §5 roster table pins Ysolde at 1860 — a '
            'mutant that drops the base 1080 constant would give 780',
      );
    });

    test('Garrick: L25, int3, Prized(45) -> 1470 (third data point)', () {
      expect(
        LadderSeeds.gearedBot(level: 25, intelligence: 3, gearTerm: 45),
        1470,
        reason:
            'LADDER_DESIGN §5 roster table pins Garrick at 1470 — a '
            'mutant that ignores gearTerm entirely would give 1425',
      );
    });
  });

  group('LadderSeeds.gearedPlayer', () {
    test('level 30 -> 1515', () {
      expect(
        LadderSeeds.gearedPlayer(level: 30),
        1515,
        reason:
            'the bot formula at intelligence 5, no gear: '
            '1080 + 360 + 75 = 1515 — a mutant that drops the +75 constant '
            'would give 1440',
      );
    });

    test('level 1 -> 1167 (second data point)', () {
      expect(
        LadderSeeds.gearedPlayer(level: 1),
        1167,
        reason:
            '1080 + 12 + 75 = 1167 — a mutant that uses 15*level '
            'instead of 12*level would give 1170',
      );
    });
  });

  group('LadderSeeds.academyBot', () {
    test('intelligence 9 -> 1440', () {
      expect(
        LadderSeeds.academyBot(intelligence: 9),
        1440,
        reason:
            "LADDER_DESIGN §5 pins Al'Dorian/Nyx-tier Academy seed at "
            '1440 — a mutant that uses (intelligence - 1) instead of '
            '(intelligence - 5) would give 1680',
      );
    });

    test('intelligence 1 -> 960', () {
      expect(
        LadderSeeds.academyBot(intelligence: 1),
        960,
        reason:
            'LADDER_DESIGN §5 pins Wick\'s Academy seed at 960 — a '
            'mutant that clamps negative offsets to 0 would give 1200 '
            'instead of allowing the seed to go below starting rating',
      );
    });

    test('intelligence 8 -> 1380 (third data point)', () {
      expect(
        LadderSeeds.academyBot(intelligence: 8),
        1380,
        reason:
            "LADDER_DESIGN §5 pins Lisbet/Ysolde's Academy seed at "
            '1380 — a mutant that multiplies by 50 instead of 60 would '
            'give 1350',
      );
    });

    test('intelligence 5 -> starting rating (no offset)', () {
      expect(
        LadderSeeds.academyBot(intelligence: 5),
        Elo.startingRating,
        reason:
            'intelligence 5 is the baseline with zero offset, so a bot '
            'there must equal Elo.startingRating (1200) — a mutant that '
            'adds a stray constant would break this identity',
      );
    });
  });
}
