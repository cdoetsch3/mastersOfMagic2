/// `rowsFor` — how a flat catalogue becomes the Achievements screen's rows
/// (ACHIEVEMENTS §3.1, §7.2): a tiered family collapses to one row at its
/// highest earned tier, with progress toward the next, and Claim pays the
/// lowest unclaimed tier first.
///
/// ⭐ Mutation-verified: each `reason:` names the wrong implementation it
/// kills. The family is synthetic (three tiers on `duelsWon`) so these laws
/// hold whatever the real catalogue holds.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievement_families.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';

AchievementProgress _wins(PlayerProfile p, int total) =>
    (done: p.duelsWon < total ? p.duelsWon : total, total: total);

final _t1 = AchievementDef(
  id: 'wins_1',
  name: 'Wins I',
  blurb: 'Ten duels won.',
  category: AchievementCategory.duelling,
  points: 5,
  family: 'wins',
  tier: 1,
  progress: (p) => _wins(p, 10),
);
final _t2 = AchievementDef(
  id: 'wins_2',
  name: 'Wins II',
  blurb: 'Twenty duels won.',
  category: AchievementCategory.duelling,
  points: 10,
  family: 'wins',
  tier: 2,
  progress: (p) => _wins(p, 20),
);
final _t3 = AchievementDef(
  id: 'wins_3',
  name: 'Wins III',
  blurb: 'Thirty duels won.',
  category: AchievementCategory.duelling,
  points: 25,
  family: 'wins',
  tier: 3,
  progress: (p) => _wins(p, 30),
);
const _solo = AchievementDef(
  id: 'solo',
  name: 'Solo',
  blurb: 'A one-shot.',
  category: AchievementCategory.campaign,
  points: 5,
);

PlayerProfile _profile({
  int wins = 0,
  Set<String> earned = const {},
  Set<String> claimed = const {},
}) => PlayerProfile.newPlayer()
  ..duelsWon = wins
  ..achievements.addAll(earned)
  ..claimedAchievements.addAll(claimed);

/// The one row for the `wins` family.
FamilyRow _family(PlayerProfile p) =>
    rowsFor([_t1, _t2, _t3], p).singleWhere((r) => r.key == 'wins');

void main() {
  group('⭐ a family is one row', () {
    test('three tiers and a stand-alone make two rows, in catalogue order', () {
      final rows = rowsFor([_solo, _t1, _t2, _t3], _profile());
      expect(
        rows.map((r) => r.key).toList(),
        ['solo', 'wins'],
        reason:
            'kills a mutant that lists every tier (four rows), and one that '
            'drops the stand-alone entry',
      );
      expect(rows.last.tiers.map((t) => t.id).toList(), [
        'wins_1',
        'wins_2',
        'wins_3',
      ], reason: 'kills a family row that loses a tier');
    });

    test('a family sits where its first member does, tiers sorted', () {
      final rows = rowsFor([_t3, _solo, _t1, _t2], _profile());
      expect(rows.map((r) => r.key).toList(), [
        'wins',
        'solo',
      ], reason: 'kills a family placed at its last member, or at the end');
      expect(
        rows.first.tiers.map((t) => t.tier).toList(),
        [1, 2, 3],
        reason:
            'kills tiers taken in catalogue order — tier III would be '
            '"tier I" and nothing earned would show Wins III',
      );
      expect(
        rows.first.shown,
        _t1,
        reason: 'the same mutant: nothing earned must show tier I',
      );
    });
  });

  group('⭐ the laws of the collapsed row', () {
    test('nothing earned: tier I, its progress, nothing to claim', () {
      final row = _family(_profile(wins: 4));
      expect(
        [row.shown.id, row.earned, row.claimable, row.next?.id],
        ['wins_1', false, null, 'wins_1'],
        reason: 'kills a row that names a higher tier before any is earned',
      );
      expect(row.progress, (
        done: 4,
        total: 10,
      ), reason: 'kills a row without its progress toward tier I');
      expect(row.complete, isFalse, reason: 'kills "complete" at nothing');
    });

    test('tier I earned, unclaimed: tier I, claimable, progress to II', () {
      final row = _family(_profile(wins: 14, earned: {'wins_1'}));
      expect(
        [row.shown.id, row.earned, row.claimable?.id, row.next?.id],
        ['wins_1', true, 'wins_1', 'wins_2'],
        reason:
            'kills a row that forgets the waiting reward, or still counts '
            'toward tier I',
      );
      expect(row.progress, (
        done: 14,
        total: 20,
      ), reason: "kills progress read off the shown tier's goal (10/10)");
      expect(row.claimed, isFalse, reason: 'kills "claimed" with one waiting');
    });

    test('tiers I–II claimed: tier II, progress to III', () {
      final row = _family(
        _profile(
          wins: 24,
          earned: {'wins_1', 'wins_2'},
          claimed: {'wins_1', 'wins_2'},
        ),
      );
      expect(
        [row.shown.id, row.claimable, row.next?.id, row.claimed],
        ['wins_2', null, 'wins_3', true],
        reason:
            'kills a row named after the LOWEST earned tier, and a Claim '
            'offered on tiers already paid',
      );
      expect(row.progress, (
        done: 24,
        total: 30,
      ), reason: 'kills a row without progress toward tier III');
    });

    test('every tier earned: tier III, no progress, complete', () {
      final row = _family(
        _profile(
          wins: 31,
          earned: {'wins_1', 'wins_2', 'wins_3'},
          claimed: {'wins_1', 'wins_2', 'wins_3'},
        ),
      );
      expect(
        [row.shown.id, row.next, row.progress, row.complete],
        ['wins_3', null, null, true],
        reason:
            'kills a finished family still showing a bar, or one that '
            'wraps back to tier I',
      );
    });

    test('⭐ Claim pays the LOWEST unclaimed tier first', () {
      final row = _family(
        _profile(wins: 30, earned: {'wins_1', 'wins_2', 'wins_3'}),
      );
      expect(
        row.claimable?.id,
        'wins_1',
        reason:
            'kills a Claim that pays the highest tier first — tiers I and '
            'II would be left owed behind a "claimed" top tier',
      );
      expect(
        row.shown.id,
        'wins_3',
        reason: 'the row is still named after the highest earned tier',
      );

      final after = _family(
        _profile(
          wins: 30,
          earned: {'wins_1', 'wins_2', 'wins_3'},
          claimed: {'wins_1'},
        ),
      );
      expect(
        after.claimable?.id,
        'wins_2',
        reason: 'kills a claimable stuck on a tier already paid',
      );
    });

    test('a gap in the earned tiers still counts toward the one above', () {
      // A save holding tier II without tier I (granted directly, or a tier
      // re-cut): the row is at II and works toward III.
      final row = _family(_profile(wins: 22, earned: {'wins_2'}));
      expect(
        [row.shown.id, row.next?.id, row.claimable?.id],
        ['wins_2', 'wins_3', 'wins_2'],
        reason:
            'kills "next" taken as the first unearned tier — the row would '
            'count toward tier I it has already passed',
      );
    });
  });

  group('a stand-alone entry', () {
    test('unearned: itself, as the next; earned: complete, claimable', () {
      final before = rowsFor([_solo], _profile()).single;
      expect(
        [before.shown, before.earned, before.next, before.isFamily],
        [_solo, false, _solo, false],
        reason: 'kills a stand-alone row that is not its own goal',
      );

      final earned = rowsFor([_solo], _profile(earned: {'solo'})).single;
      expect(
        [earned.complete, earned.claimable, earned.key],
        [true, _solo, 'solo'],
        reason: 'kills an earned one-shot left "in progress", or unclaimable',
      );

      final paid = rowsFor([
        _solo,
      ], _profile(earned: {'solo'}, claimed: {'solo'})).single;
      expect(
        [paid.claimable, paid.claimed],
        [null, true],
        reason: 'kills a paid entry still offering Claim',
      );
    });

    test('a hidden entry is veiled until earned', () {
      const secret = AchievementDef(
        id: 'secret',
        name: 'Secret',
        blurb: 'Shh.',
        category: AchievementCategory.world,
        points: 5,
        hidden: true,
      );
      expect(
        [
          rowsFor([secret], _profile()).single.veiled,
          rowsFor([secret], _profile(earned: {'secret'})).single.veiled,
        ],
        [true, false],
        reason: 'kills a spoiler shown unearned, or one veiled forever',
      );
    });
  });
}
