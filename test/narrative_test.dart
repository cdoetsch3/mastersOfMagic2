import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/world.dart';

void main() {
  group('a zone tells its story at the pace it is played', () {
    test('a beat fires at the start of each section, and only there', () {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: Bestiary.forZone('whispering_woods'),
        playerHp: 100,
        rng: Random(1),
      );
      final starts = <int>[];
      for (var i = 0; i < run.encounters.length; i++) {
        run.index = i;
        if (run.atSectionStart) starts.add(i);
      }
      expect(
        starts,
        hasLength(3),
        reason: 'three sections, three beats (GAME_DESIGN §3d)',
      );
      expect(starts.first, 0);
    });

    test('a section ends on something elevated, never on a common', () {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: Bestiary.forZone('whispering_woods'),
        playerHp: 100,
        rng: Random(4),
      );
      for (final i in [
        for (var i = 0; i < run.encounters.length; i++)
          if (run.sectionAt(i) != run.sectionAt(i + 1)) i,
      ]) {
        expect(run.encounters[i].def.rank, isNot(EnemyRank.common));
      }
    });

    test('⚠️ Whispering Woods opens PLEASANT', () {
      // The zone's beat is slowly realising something is wrong, so the first
      // impression must not be a warning. Nothing alarming in the arrival.
      final woods = World.byId('whispering_woods');
      for (final word in ['wrong', 'stops', 'not wind']) {
        expect(
          woods.arrival.toLowerCase(),
          isNot(contains(word)),
          reason: 'the arrival gives the game away with "$word"',
        );
      }
      expect(woods.arrival.toLowerCase(), contains('sun'));
    });

    test('the beats escalate, and the last one lands the realisation', () {
      final beats = World.byId('whispering_woods').beats;
      expect(beats, hasLength(3));
      // ⭐ The payoff: it is one thing, and it is underneath you.
      expect(beats.last.toLowerCase(), contains('roots'));
      expect(beats.last.toLowerCase(), contains('one sound'));
    });

    test('an epilogue must not close the zone off', () {
      // ⚠️ Zones are re-run for materials and for Purge; an epilogue that
      // kills the place contradicts the next visit.
      final woods = World.byId('whispering_woods');
      expect(woods.epilogue, isNotNull);
      expect(woods.epilogue!.toLowerCase(), contains('did not kill'));
    });

    test('every zone with beats has at most one per section', () {
      for (final l in World.locations) {
        expect(
          l.beats.length,
          lessThanOrEqualTo(3),
          reason: '${l.id} has more beats than a run has sections',
        );
      }
    });
  });
}
