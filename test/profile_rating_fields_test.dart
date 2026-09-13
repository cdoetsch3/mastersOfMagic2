/// The ladder rating fields on [PlayerProfile] (LADDER_DESIGN §2) and
/// [applyRatedResult]'s pure mutation of them.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_record.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';

void main() {
  group('PlayerProfile rating fields — round-trip', () {
    test('all eight fields survive a toJson/fromJson round-trip', () {
      final p = PlayerProfile.newPlayer()
        ..ratingGeared = 1234
        ..ratingAcademy = 1355
        ..ratedGamesGeared = 12
        ..ratedGamesAcademy = 7
        ..peakGeared = 1400
        ..peakAcademy = 1360
        ..academyWins = 4
        ..academyLosses = 3;

      final reloaded = PlayerProfile.fromJson(p.toJson());

      expect(
        reloaded.ratingGeared,
        1234,
        reason:
            'a mutant dropping ratingGeared from toJson/fromJson '
            'would read this back as null',
      );
      expect(
        reloaded.ratingAcademy,
        1355,
        reason: 'ratingAcademy must not be conflated with ratingGeared',
      );
      expect(
        reloaded.ratedGamesGeared,
        12,
        reason:
            'ratedGamesGeared must round-trip independently of '
            'ratedGamesAcademy',
      );
      expect(
        reloaded.ratedGamesAcademy,
        7,
        reason:
            'ratedGamesAcademy must round-trip independently of '
            'ratedGamesGeared',
      );
      expect(
        reloaded.peakGeared,
        1400,
        reason: 'peakGeared must round-trip independently of peakAcademy',
      );
      expect(
        reloaded.peakAcademy,
        1360,
        reason: 'peakAcademy must round-trip independently of peakGeared',
      );
      expect(
        reloaded.academyWins,
        4,
        reason:
            'academyWins must round-trip independently of '
            'academyLosses and of duelsWon',
      );
      expect(
        reloaded.academyLosses,
        3,
        reason:
            'academyLosses must round-trip independently of '
            'academyWins and of duelsLost',
      );
    });

    test('a pre-ladder save (no keys) reads as nulls/zeros', () {
      final p = PlayerProfile.fromJson({'name': 'Old Timer'});

      expect(
        p.ratingGeared,
        isNull,
        reason:
            'never played a rated Geared match — must not default to '
            'a seed value the loader invented',
      );
      expect(
        p.ratingAcademy,
        isNull,
        reason:
            'never played a rated Academy match — same reasoning as '
            'ratingGeared',
      );
      expect(
        p.ratedGamesGeared,
        0,
        reason: 'a counter absent from the save reads as zero, not null',
      );
      expect(p.ratedGamesAcademy, 0);
      expect(p.peakGeared, 0);
      expect(p.peakAcademy, 0);
      expect(p.academyWins, 0);
      expect(p.academyLosses, 0);
      expect(
        p.lastOpponentBotId,
        isNull,
        reason: 'no bot fought yet — absent, same as a fresh character',
      );
    });

    test('lastOpponentBotId (LADDER §3) round-trips, and is null by default', () {
      final fresh = PlayerProfile.newPlayer();
      expect(
        fresh.lastOpponentBotId,
        isNull,
        reason: 'a brand-new character has fought nobody yet',
      );

      final p = PlayerProfile.newPlayer()..lastOpponentBotId = 'garrick';
      final reloaded = PlayerProfile.fromJson(p.toJson());
      expect(
        reloaded.lastOpponentBotId,
        'garrick',
        reason:
            'a mutant dropping lastOpponentBotId from toJson/fromJson '
            'would read this back as null, letting the search repeat the '
            'same bot',
      );

      final backToHuman = PlayerProfile.fromJson(
        (p..lastOpponentBotId = null).toJson(),
      );
      expect(
        backToHuman.lastOpponentBotId,
        isNull,
        reason:
            'set back to null after a human match — the null itself must '
            'also round-trip, not linger as the last non-null value',
      );
    });

    test('ratingGeared: 0 round-trips as 0, not null', () {
      // ⭐ The trap the null-default idiom sets: `?? 0` would turn an
      // explicit 0 rating into 0 too (indistinguishable), but a naive
      // `json['ratingGeared'] == null ? seed : ...` written the wrong way
      // round could mistake 0 for "absent". Pin the exact value survives.
      final p = PlayerProfile.fromJson({'ratingGeared': 0});
      expect(
        p.ratingGeared,
        0,
        reason:
            'an explicit 0 is a real (if extreme) rating, not '
            'shorthand for "never played" — only a truly absent key means '
            'that',
      );

      final reloaded = PlayerProfile.fromJson(p.toJson());
      expect(
        reloaded.ratingGeared,
        0,
        reason:
            'toJson must write the 0 rather than omitting a falsy '
            'field, or the second fromJson would read it back as null',
      );
    });
  });

  group('applyRatedResult', () {
    test(
      'Geared win: sets rating, bumps ratedGamesGeared, leaves the record',
      () {
        final p = PlayerProfile.newPlayer()..ratingGeared = 1200;

        applyRatedResult(p, academy: false, newRating: 1216, won: true);

        expect(
          p.ratingGeared,
          1216,
          reason: 'the new rating the caller computed must be written',
        );
        expect(
          p.ratedGamesGeared,
          1,
          reason: 'one rated Geared game was just played',
        );
        expect(
          p.ratedGamesAcademy,
          0,
          reason: 'a Geared result must not touch the Academy counter',
        );
        expect(
          p.duelsWon,
          0,
          reason:
              'the geared record is GameState.recordDuelResult\'s — a '
              'mutant that bumps duelsWon here double-counts every geared win',
        );
        expect(p.duelsLost, 0);
        expect(
          p.academyWins,
          0,
          reason: 'a Geared result must not touch the Academy record',
        );
      },
    );

    test('Geared loss: sets rating, leaves the record alone', () {
      final p = PlayerProfile.newPlayer()..ratingGeared = 1200;

      applyRatedResult(p, academy: false, newRating: 1184, won: false);

      expect(
        p.ratingGeared,
        1184,
        reason: 'a loss writes the lower rating the caller computed',
      );
      expect(
        p.duelsLost,
        0,
        reason:
            'recordDuelResult owns duelsLost — a mutant bumping it here '
            'double-counts every geared loss',
      );
      expect(p.duelsWon, 0);
    });

    test(
      'Academy win: sets rating, bumps ratedGamesAcademy and academyWins',
      () {
        final p = PlayerProfile.newPlayer()..ratingAcademy = 1200;

        applyRatedResult(p, academy: true, newRating: 1216, won: true);

        expect(p.ratingAcademy, 1216);
        expect(p.ratedGamesAcademy, 1);
        expect(
          p.ratedGamesGeared,
          0,
          reason: 'an Academy result must not touch the Geared counter',
        );
        expect(
          p.academyWins,
          1,
          reason:
              'the Academy keeps its own win/loss record, per '
              'LADDER_DESIGN §2 — must not fall through to duelsWon',
        );
        expect(p.academyLosses, 0);
        expect(
          p.duelsWon,
          0,
          reason: 'an Academy result must not touch the campaign record',
        );
      },
    );

    test('Academy loss: bumps academyLosses, not academyWins', () {
      final p = PlayerProfile.newPlayer()..ratingAcademy = 1200;

      applyRatedResult(p, academy: true, newRating: 1184, won: false);

      expect(p.ratingAcademy, 1184);
      expect(p.academyLosses, 1);
      expect(p.academyWins, 0);
    });

    test('peak rises on a new high', () {
      final p = PlayerProfile.newPlayer()
        ..ratingGeared = 1200
        ..peakGeared = 1200;

      applyRatedResult(p, academy: false, newRating: 1230, won: true);

      expect(
        p.peakGeared,
        1230,
        reason: 'a new high must raise the stored peak',
      );
    });

    test('peak does not fall on a loss below the peak', () {
      final p = PlayerProfile.newPlayer()
        ..ratingGeared = 1250
        ..peakGeared = 1250;

      applyRatedResult(p, academy: false, newRating: 1220, won: false);

      expect(
        p.ratingGeared,
        1220,
        reason: 'the current rating does drop with the loss',
      );
      expect(
        p.peakGeared,
        1250,
        reason:
            'the peak must survive a later drop — a mutant that '
            'always sets peak = newRating would fail this',
      );
    });

    test('peak does not fall for the Academy ladder either', () {
      final p = PlayerProfile.newPlayer()
        ..ratingAcademy = 1250
        ..peakAcademy = 1250;

      applyRatedResult(p, academy: true, newRating: 1220, won: false);

      expect(
        p.peakAcademy,
        1250,
        reason: 'symmetric with the Geared peak-only-rises rule',
      );
    });

    test('a tie with the current peak does not "rise" past itself', () {
      final p = PlayerProfile.newPlayer()
        ..ratingGeared = 1200
        ..peakGeared = 1250;

      applyRatedResult(p, academy: false, newRating: 1250, won: true);

      expect(
        p.peakGeared,
        1250,
        reason:
            'reaching exactly the peak again must not error or '
            'double-count; a mutant using >= vs > only shows up if the '
            'peak also gets asserted after an actual rise, which the '
            'earlier tests cover — this pins the boundary itself',
      );
    });
  });
}
