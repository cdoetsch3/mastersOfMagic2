/// Rewards are CLAIMED, not auto-granted (ruling, Christian 2026-10-01): the
/// §6 reward table, the catalogue's points and shape, and
/// `GameState.claimAchievement` / `claimAllAchievements`.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — a reward paid twice, a reward paid unearned, a table off by a
/// row, a claim that skips the lifetime gold count, a level-up nobody hears
/// about, a Claim all that writes once per entry.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

/// Round-trips through JSON and counts writes.
class _JsonMem implements ProfileStorage {
  String? saved;
  int saves = 0;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    saved = jsonEncode(profile.toJson());
  }

  @override
  Future<void> clear() async => saved = null;

  PlayerProfile? get stored => saved == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
}

PlayerProfile _p() => PlayerProfile.newPlayer();

void main() {
  group('the §6 reward table', () {
    test('⭐ each row, as written', () {
      expect(
        {
          for (final pts in [5, 10, 25, 50, 100]) pts: Reward.forPoints(pts),
        },
        {
          5: (xp: 100, gold: 50, rp: 0),
          10: (xp: 250, gold: 150, rp: 0),
          25: (xp: 750, gold: 500, rp: 1),
          50: (xp: 2000, gold: 1500, rp: 5),
          100: (xp: 5000, gold: 5000, rp: 25),
        },
        reason: 'kills a row off by a number, or rows shifted by one',
      );
    });

    test('150 pays the 100+ row; between rows pays the row below', () {
      expect(
        Reward.forPoints(150),
        Reward.forPoints(100),
        reason: 'kills an exact-key table with no row for 150 (§6: "100 pt+")',
      );
      expect(
        Reward.forPoints(49),
        Reward.forPoints(25),
        reason: 'kills a threshold rounded up to the next row',
      );
    });

    test('sum adds each column', () {
      expect(Reward.sum([Reward.forPoints(5), Reward.forPoints(25)]), (
        xp: 850,
        gold: 550,
        rp: 1,
      ), reason: 'kills a sum that drops a column, or keeps only the last');
      expect(
        Reward.sum(const []),
        Reward.none,
        reason: 'kills a sum of nothing that pays something',
      );
    });
  });

  group('the catalogue shape', () {
    // 📝 The twelve shipped before stage 2. The stage-2 catalogue's shape is
    // pinned in `achievement_catalogue_test`.
    const shipped = {
      'papers_in_order',
      'first_clearing',
      'five_banners',
      'the_long_road',
      'beyond_the_veil',
      'first_blood',
      'tenfold',
      'centurion',
      'journeyman',
      'artisan',
      'rated',
      'ladder_regular',
    };

    test('⭐ the twelve, re-pointed (2026-10-01)', () {
      expect(
        {
          for (final a in Achievements.all)
            if (shipped.contains(a.id)) a.id: a.points,
        },
        {
          'papers_in_order': 10,
          'first_clearing': 10,
          'five_banners': 10,
          'the_long_road': 25,
          'beyond_the_veil': 25,
          'first_blood': 5,
          'tenfold': 10,
          'centurion': 25,
          'journeyman': 10,
          'artisan': 25,
          'rated': 5,
          'ladder_regular': 10,
        },
        reason:
            'kills a re-pointed entry — one-shots 5–10, counted 10–25, the '
            'two far milestones 25',
      );
    });

    test('every entry carries an allowed weight, and a reward to match', () {
      for (final a in Achievements.all) {
        expect(
          AchievementDef.allowedPoints,
          contains(a.points),
          reason: 'kills an off-scale weight on ${a.id}',
        );
        expect(
          a.reward,
          Reward.forPoints(a.points),
          reason: 'kills a reward that ignores the points (${a.id})',
        );
      }
    });

    test('the Mastery thresholds, as ruled', () {
      expect(
        Achievements.masteryThresholds,
        [250, 1000, 5000, 10000, 25000],
        reason:
            'kills a retuned threshold that did not come from a ruling '
            '(2026-10-01)',
      );
    });

    test('none of the twelve is hidden or tiered yet', () {
      expect(
        [
          for (final a in Achievements.all)
            if (shipped.contains(a.id) &&
                (a.hidden || a.family != null || a.tier != null))
              a.id,
        ],
        isEmpty,
        reason:
            'kills a migrated entry that hides itself or joins a family — '
            'both are stage-2 content',
      );
    });
  });

  group('claimable and totalPoints', () {
    test('⭐ claimable is earned and not claimed, in catalogue order', () {
      final p = _p()
        ..achievements.addAll({'tenfold', 'first_blood', 'artisan', 'gone'})
        ..claimedAchievements.addAll({'tenfold', 'rated'});
      expect(
        [for (final a in Achievements.claimable(p)) a.id],
        ['first_blood', 'artisan'],
        reason:
            'kills a claimable that lists the claimed (tenfold), the '
            'unearned (rated), a retired id (gone), or loses catalogue order',
      );
    });

    test('totalPoints sums what is earned, claimed or not', () {
      final p = _p()
        ..achievements.addAll({'first_blood', 'centurion', 'gone'})
        ..claimedAchievements.add('first_blood');
      expect(
        Achievements.totalPoints(p),
        5 + 25,
        reason:
            'kills a total over claimed only (5), one that counts a retired '
            'id, or one that counts entries rather than points (2)',
      );
    });
  });

  group('⭐ claimAchievement', () {
    test('pays the table in one write, and records the claim', () async {
      final storage = _JsonMem();
      final game = GameState(
        storage,
        _p()
          ..achievements.add('centurion') // 25 points
          ..xp = 0
          ..gold = 7
          ..resonancePrisms = 2,
      );
      expect(
        await game.claimAchievement('centurion'),
        isTrue,
        reason: 'kills a claim that refuses an earned, unclaimed entry',
      );
      final saved = storage.stored!;
      expect(
        [saved.xp, saved.gold, saved.resonancePrisms],
        [750, 507, 3],
        reason: 'kills a claim that pays the wrong row, or drops a column',
      );
      expect(saved.claimedAchievements, {
        'centurion',
      }, reason: 'kills a claim that pays without recording it');
      expect(storage.saves, 1, reason: 'kills a claim split across writes');
    });

    test(
      '⭐ a double claim is refused — nothing paid, nothing written',
      () async {
        final storage = _JsonMem();
        final game = GameState(storage, _p()..achievements.add('tenfold'));
        await game.claimAchievement('tenfold');
        final xp = game.profile.xp;
        final saves = storage.saves;
        expect(
          await game.claimAchievement('tenfold'),
          isFalse,
          reason: 'kills a claim with its idempotence dropped',
        );
        expect(game.profile.xp, xp, reason: 'kills a second payout');
        expect(
          storage.saves,
          saves,
          reason: 'kills a refusal that still saves',
        );
      },
    );

    test('an unearned or unknown id is refused', () async {
      final storage = _JsonMem();
      final game = GameState(storage, _p());
      expect(
        await game.claimAchievement('tenfold'),
        isFalse,
        reason: 'kills a claim that pays what was never earned',
      );
      game.profile.achievements.add('retired_id');
      expect(
        await game.claimAchievement('retired_id'),
        isFalse,
        reason: 'kills a claim that pays an id the catalogue no longer knows',
      );
      expect(storage.saves, 0, reason: 'kills a refusal that writes');
      expect(game.profile.claimedAchievements, isEmpty, reason: 'nothing kept');
    });

    test('⭐ the claimed gold counts as gold earned', () async {
      final game = GameState(_JsonMem(), _p()..achievements.add('tenfold'));
      await game.claimAchievement('tenfold');
      expect(
        game.profile.goldEarned,
        150,
        reason: 'kills a claim that pays gold with a raw `gold +=`',
      );
    });

    test('⭐ a claim that crosses a level flags the level-up', () async {
      // 250 XP from level 1: 100 to level 2, 150 more to level 3.
      final game = GameState(_JsonMem(), _p()..achievements.add('tenfold'));
      await game.claimAchievement('tenfold');
      expect(
        [game.pendingLevelUpFrom, game.pendingLevelUp],
        [1, 3],
        reason:
            'kills a claim that adds XP behind the level-up check — the '
            'player would level in silence',
      );
    });

    test('a claim that crosses nothing flags nothing', () async {
      final game = GameState(_JsonMem(), _p()..achievements.add('rated'));
      await game.claimAchievement('rated'); // 100 XP: exactly level 2
      game.acknowledgeLevelUp();
      game.profile.achievements.add('first_blood');
      game.profile.xp = 110;
      await game.claimAchievement('first_blood'); // 210: still level 2
      expect(
        game.pendingLevelUp,
        isNull,
        reason: 'kills a level-up flagged on every claim',
      );
    });
  });

  group('⭐ claimAllAchievements', () {
    test('one write for the lot, and the summed reward back', () async {
      final storage = _JsonMem();
      final game = GameState(
        storage,
        _p()
          ..achievements.addAll({'first_blood', 'tenfold', 'centurion'})
          ..claimedAchievements.add('tenfold'),
      );
      final paid = await game.claimAllAchievements();
      expect(
        paid,
        Reward.sum([Reward.forPoints(5), Reward.forPoints(25)]),
        reason:
            'kills a Claim all that re-pays the claimed (tenfold), or '
            'returns something other than what it paid',
      );
      expect(storage.stored!.claimedAchievements, {
        'tenfold',
        'first_blood',
        'centurion',
      }, reason: 'kills a Claim all that pays without recording');
      expect(
        [storage.stored!.xp, storage.stored!.goldEarned],
        [paid.xp, paid.gold],
        reason: 'kills a Claim all that reports more than it banked',
      );
      expect(storage.saves, 1, reason: 'kills a write per entry');
    });

    test('nothing due: pays nothing, writes nothing', () async {
      final storage = _JsonMem();
      final game = GameState(storage, _p());
      expect(
        await game.claimAllAchievements(),
        Reward.none,
        reason: 'kills a Claim all that pays from an empty list',
      );
      expect(storage.saves, 0, reason: 'kills an empty Claim all that saves');
    });
  });

  group('earning still never pays', () {
    test(
      '⭐ a live grant and the load sweep leave the reward to claim',
      () async {
        final storage = _JsonMem();
        await storage.save(_p()..duelsWon = 12);
        final booted = await GameState.boot(storage);
        expect(
          booted.profile.achievements,
          containsAll(['first_blood', 'tenfold']),
          reason: 'premise: the sweep earns',
        );
        expect(
          [booted.profile.xp, booted.profile.claimedAchievements],
          [0, isEmpty],
          reason:
              'kills a sweep that auto-pays — a returning player is owed a '
              'pile to claim',
        );
        expect(Achievements.claimable(booted.profile).map((a) => a.id), [
          'first_blood',
          'tenfold',
        ], reason: 'the swept entries wait on the screen');
      },
    );
  });
}
