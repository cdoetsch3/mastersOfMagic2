/// The pure LADDER_DESIGN §3 search schedule pulled out of
/// `Matchmaking.quickMatch`: [LadderSearch.bandAt]'s widening boundaries and
/// [LadderSearch.pickBot]'s weighted phase-4 pick.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_search.dart';

void main() {
  group('LadderSearch.ratingOf', () {
    final bot = LadderRoster.all.first;
    test('a live standing wins over the seed', () {
      expect(
        LadderSearch.ratingOf(bot, liveRatings: {bot.id: 1333}, academy: false),
        1333,
        reason:
            'a mutant that always answers the seed ignores bots/* — the '
            'pick, the header and the settlement would all drift from reality',
      );
    });
    test('no standing falls back to the ladder\'s seed', () {
      expect(
        LadderSearch.ratingOf(bot, liveRatings: const {}, academy: false),
        bot.seedGeared,
        reason: 'geared falls back to seedGeared',
      );
      expect(
        LadderSearch.ratingOf(bot, liveRatings: const {}, academy: true),
        bot.seedAcademy,
        reason:
            'academy falls back to seedAcademy — a mutant that ignores '
            'the ladder flag hands the geared seed to the Academy',
      );
    });
  });

  group('LadderSearch.bandAt — the widening schedule (LADDER §3)', () {
    test('2999 ms is still phase 1 — band 100', () {
      expect(
        LadderSearch.bandAt(const Duration(milliseconds: 2999)),
        100,
        reason:
            'a mutant that widens one instant early would open band 200 '
            'before the 3 s mark',
      );
    });

    test('3000 ms is already phase 2 — band 200', () {
      expect(
        LadderSearch.bandAt(const Duration(milliseconds: 3000)),
        200,
        reason:
            'the boundary is inclusive on the early side: exactly 3000 ms '
            'has already widened',
      );
    });

    test('5999 ms is still phase 2 — band 200', () {
      expect(
        LadderSearch.bandAt(const Duration(milliseconds: 5999)),
        200,
        reason:
            'a mutant that widens one instant early would open band 400 '
            'before the 6 s mark',
      );
    });

    test('6000 ms is already phase 3 — band 400', () {
      expect(
        LadderSearch.bandAt(const Duration(milliseconds: 6000)),
        400,
        reason: 'exactly 6000 ms has already widened to band 400',
      );
    });

    test('9999 ms is still band 400 (phase 3, one ms from the bot phase)', () {
      expect(
        LadderSearch.bandAt(const Duration(milliseconds: 9999)),
        400,
        reason:
            'band 400 holds through the rest of the human search — phase 4 '
            'stops consulting bandAt entirely rather than widening further',
      );
    });

    test('0 ms — the very start of the search — is band 100', () {
      expect(
        LadderSearch.bandAt(Duration.zero),
        100,
        reason: 'the narrowest band applies from the first instant',
      );
    });
  });

  group('LadderSearch.pickBot — never the excluded id', () {
    test('an exact-match rating never returns the excluded bot', () {
      // Tansy's geared seed is exactly 1200 — the nearest possible pick —
      // yet excluding her must never surface her anyway.
      for (var seed = 0; seed < 200; seed++) {
        final bot = LadderSearch.pickBot(
          1200,
          academy: false,
          excludeBotId: 'tansy',
          rng: Random(seed),
        );
        expect(
          bot.id,
          isNot('tansy'),
          reason:
              'a mutant that filters excludeBotId AFTER weighting (or not '
              'at all) could still draw the excluded bot',
        );
      }
    });

    test('excluding the only bot in the starting band forces widening', () {
      // Academy seed 960 belongs to Wick alone — band 100 at rating 960
      // contains only him. Excluding him must widen the band rather than
      // returning him anyway or throwing.
      for (var seed = 0; seed < 50; seed++) {
        final bot = LadderSearch.pickBot(
          960,
          academy: true,
          excludeBotId: 'wick',
          rng: Random(seed),
        );
        expect(
          bot.id,
          isNot('wick'),
          reason:
              'excluding the sole band-100 candidate must widen the band, '
              'not fall back to the excluded bot',
        );
      }
    });
  });

  group('LadderSearch.pickBot — always returns something', () {
    for (final academy in [false, true]) {
      test(
        'every rating 800..2200 (step 50) on ${academy ? "Academy" : "Geared"} '
        'yields a bot',
        () {
          for (var rating = 800; rating <= 2200; rating += 50) {
            final bot = LadderSearch.pickBot(
              rating,
              academy: academy,
              rng: Random(rating),
            );
            expect(
              bot,
              isA<LadderBot>(),
              reason:
                  'band doubling must always terminate somewhere in the '
                  '27-bot roster, however far $rating sits from every seed',
            );
          }
        },
      );
    }
  });

  group('LadderSearch.pickBot — weighting favours the nearest candidate', () {
    test('over 2000 seeded draws, the nearest candidate wins more often', () {
      // Geared rating 1200: band 100 already holds wick(1107, dist 93),
      // pim(1161, dist 39), tansy(1200, dist 0), orrin(1239, dist 39),
      // marlow(1263, dist 63) — five candidates, so the band never widens.
      // Tansy (dist 0, weight 1.0) is the nearest; Wick (dist 93,
      // weight ≈0.0106) is the farthest.
      final counts = <String, int>{};
      final rng = Random(20260913);
      for (var i = 0; i < 2000; i++) {
        final bot = LadderSearch.pickBot(1200, academy: false, rng: rng);
        counts[bot.id] = (counts[bot.id] ?? 0) + 1;
      }
      expect(
        (counts['tansy'] ?? 0) > (counts['wick'] ?? 0),
        isTrue,
        reason:
            'weight = 1 / (1 + distance): a mutant that weights uniformly '
            '(or inverts the distance) would not favour the exact match '
            'over the farthest candidate in the band',
      );
    });
  });

  group(
    'LadderSearch.pickBot — doubling stops at the first non-empty band',
    () {
      test('rating 1000 (geared) never surfaces a band-400-only bot', () {
        // Band 100 at 1000 is [900, 1100]: empty (Wick, the nearest seed at
        // 1107, sits 107 away). Band 200 is [800, 1200]: Wick(107), Pim(161,
        // seed 1161) and Tansy(200, seed 1200) all qualify — doubling must
        // stop there. Orrin (seed 1239, distance 239) only enters at band
        // 400 and must never appear if doubling correctly stopped at 200.
        for (var seed = 0; seed < 100; seed++) {
          final bot = LadderSearch.pickBot(
            1000,
            academy: false,
            rng: Random(seed),
          );
          expect(
            ['wick', 'pim', 'tansy'].contains(bot.id),
            isTrue,
            reason:
                'a mutant that keeps doubling past the first non-empty band '
                'would eventually let orrin (band-400-only here) through',
          );
        }
      });
    },
  );
}
