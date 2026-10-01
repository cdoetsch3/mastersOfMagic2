/// The achievement catalogue and how it is granted (ruling, Christian
/// playtest 2026-09-30, note 7): categories, countable goals read off
/// counters the profile already keeps, [Achievements.newlyEarned], the live
/// grant that toasts, and the load-time sweep that does not.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — a renamed id, an off-by-one goal, a goal reading the wrong
/// counter, a grant that repeats, a sweep that toasts, a hook removed.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/achievements_screen.dart';
import 'package:masters_of_magic_2/screens/home_shell.dart';
import 'package:masters_of_magic_2/ui/app_banner.dart';

/// Round-trips through JSON, so what is asserted on disk is what a reload
/// would see.
class _JsonMem implements ProfileStorage {
  String? saved;
  int saves = 0;
  @override
  Future<PlayerProfile?> load() async => saved == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
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

/// Refuses its first save as a conflict, then accepts; its cloud copy is
/// [cloud].
class _ConflictOnce implements ProfileStorage {
  final PlayerProfile cloud;
  int saves = 0;
  PlayerProfile? last;
  _ConflictOnce(this.cloud);

  @override
  Future<PlayerProfile?> load() async =>
      PlayerProfile.fromJson(jsonDecode(jsonEncode(cloud.toJson())));

  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    if (saves == 1) throw const SaveConflictException('users/u/characters/c');
    last = profile;
  }

  @override
  Future<void> clear() async {}
}

/// Total skill XP for exactly [level].
int _xpFor(int level) {
  var xp = 0;
  for (var l = 1; l < level; l++) {
    xp += Skills.xpToNext(l);
  }
  return xp;
}

/// [n] distinct cleared zones, each cleared once.
Map<String, int> _zones(int n) => {for (var i = 0; i < n; i++) 'zone_$i': 1};

PlayerProfile _p() => PlayerProfile.newPlayer();

Iterable<String> _ids(Iterable<AchievementDef> defs) => defs.map((d) => d.id);

void main() {
  group('the catalogue', () {
    test('⭐ the full id list, in order, with categories — ids are forever', () {
      expect(
        [for (final a in Achievements.all) '${a.category.name}:${a.id}'],
        [
          'journey:papers_in_order',
          'journey:first_clearing',
          'journey:five_banners',
          'journey:the_long_road',
          'journey:beyond_the_veil',
          'combat:first_blood',
          'combat:tenfold',
          'combat:centurion',
          'craft:journeyman',
          'craft:artisan',
          'ladder:rated',
          'ladder:ladder_regular',
        ],
        reason:
            'kills a renamed id (every save that earned it would lose it), '
            'an entry moved between categories, and a reordered list',
      );
    });

    test('ids are unique, and byId finds each one', () {
      final ids = _ids(Achievements.all).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'kills a duplicated id — two entries, one earning',
      );
      for (final a in Achievements.all) {
        expect(
          Achievements.byId(a.id),
          same(a),
          reason: 'kills a byId that misses ${a.id}',
        );
      }
    });

    test('categories run in enum order, with their labels', () {
      expect(
        [for (final c in AchievementCategory.values) c.label],
        ['Journey', 'Combat', 'Craft', 'Ladder'],
        reason: 'kills a relabelled or reordered category',
      );
      expect(_ids(Achievements.inCategory(AchievementCategory.combat)), [
        'first_blood',
        'tenfold',
        'centurion',
      ], reason: 'kills an inCategory that leaks or reorders entries');
    });

    test('the copy, as written', () {
      expect(
        {for (final a in Achievements.all) a.name: a.blurb},
        {
          'Papers in Order':
              'Pennycross unlocked. The proofs stay with the guard.',
          'First Clearing': 'One zone cleared to its boss.',
          'Five Banners': 'Five zones cleared to their bosses.',
          'The Long Road': 'Fifteen zones cleared to their bosses.',
          'Beyond the Veil': 'Rimeholt unlocked. The Totem stays with you.',
          'First Blood': 'One duel won.',
          'Tenfold': 'Ten duels won.',
          'Centurion': 'A hundred duels won.',
          'Journeyman': 'One craft taken to level 5.',
          'Artisan': 'One craft taken to level 10.',
          'On the Ladder': 'One rated duel played, on either ladder.',
          'Regular': 'Ten rated duels played, on either ladder.',
        },
        reason: 'kills a reworded entry; and no blurb shouts',
      );
      for (final a in Achievements.all) {
        expect(
          a.blurb.contains('!'),
          isFalse,
          reason: 'house voice: no exclamation marks (${a.id})',
        );
      }
    });

    test("Rimeholt is the Celestial Totem's gate", () {
      expect(
        World.byId('rimeholt').gateItemIds,
        contains('celestial_totem'),
        reason:
            'Beyond the Veil reads openedGates for "rimeholt"; if the totem '
            'gate moved, the entry would be unearnable',
      );
    });
  });

  group('conditions, each against its own counter', () {
    AchievementProgress? progress(AchievementDef d, PlayerProfile p) =>
        d.progress!(p);

    test('one-shots have no count; counted entries do', () {
      expect(
        [
          for (final a in Achievements.all)
            if (a.progress != null) a.id,
        ],
        [
          'five_banners',
          'the_long_road',
          'tenfold',
          'centurion',
          'journeyman',
          'artisan',
          'ladder_regular',
        ],
        reason: 'kills a count dropped from, or added to, an entry',
      );
    });

    test('Papers in Order and Beyond the Veil read openedGates', () {
      final seen = _p()
        ..discoveredLocationIds.addAll({'pennycross', 'rimeholt'});
      expect(
        Achievements.papersInOrder.isMet(seen) ||
            Achievements.beyondTheVeil.isMet(seen),
        isFalse,
        reason: 'kills a condition reading discovery — seeing is not opening',
      );
      expect(
        Achievements.papersInOrder.isMet(_p()..openedGates.add('pennycross')),
        isTrue,
        reason: 'kills a Papers in Order that ignores the gate',
      );
      expect(
        Achievements.beyondTheVeil.isMet(_p()..openedGates.add('pennycross')),
        isFalse,
        reason: 'kills a Beyond the Veil that opens on any gate',
      );
      expect(
        Achievements.beyondTheVeil.isMet(_p()..openedGates.add('rimeholt')),
        isTrue,
        reason: 'kills a Beyond the Veil that never opens',
      );
    });

    test('First Clearing: one boss, not a discovered zone', () {
      final walked = _p()..discoveredLocationIds.add('whispering_woods');
      expect(
        Achievements.firstClearing.isMet(walked),
        isFalse,
        reason: 'kills a condition reading discovery instead of clears',
      );
      expect(
        Achievements.firstClearing.isMet(_p()..zoneClears.addAll(_zones(1))),
        isTrue,
        reason: 'kills an off-by-one (> 1)',
      );
    });

    test('Five Banners and The Long Road count distinct zones', () {
      final twice = _p()..zoneClears['zone_0'] = 6;
      expect(
        progress(Achievements.fiveBanners, twice),
        (done: 1, total: 5),
        reason:
            'kills a count of clears rather than zones — six clears of one '
            'zone is one banner',
      );
      expect(
        progress(Achievements.fiveBanners, _p()..zoneClears.addAll(_zones(4))),
        (done: 4, total: 5),
        reason: 'kills a count off by one',
      );
      expect(
        Achievements.fiveBanners.isMet(_p()..zoneClears.addAll(_zones(4))),
        isFalse,
        reason: 'kills a goal of 4',
      );
      expect(
        Achievements.fiveBanners.isMet(_p()..zoneClears.addAll(_zones(5))),
        isTrue,
        reason: 'kills a goal of 6, or a strict >',
      );
      expect(
        progress(Achievements.theLongRoad, _p()..zoneClears.addAll(_zones(14))),
        (done: 14, total: 15),
        reason: 'kills a Long Road of the wrong length',
      );
      expect(
        Achievements.theLongRoad.isMet(_p()..zoneClears.addAll(_zones(15))),
        isTrue,
        reason: 'kills a goal of 16',
      );
    });

    test('Combat counts duelsWon — not losses, not Academy wins', () {
      final noise = _p()
        ..duelsLost = 500
        ..academyWins = 500;
      expect(
        Achievements.firstBlood.isMet(noise),
        isFalse,
        reason: 'kills a First Blood reading losses or Academy wins',
      );
      expect(progress(Achievements.tenfold, noise..duelsWon = 9), (
        done: 9,
        total: 10,
      ), reason: 'kills a Tenfold reading the wrong counter');
      expect(
        Achievements.tenfold.isMet(noise),
        isFalse,
        reason: 'kills a goal of 9',
      );
      expect(
        Achievements.firstBlood.isMet(_p()..duelsWon = 1),
        isTrue,
        reason: 'kills a First Blood that needs two',
      );
      expect(
        Achievements.tenfold.isMet(_p()..duelsWon = 10),
        isTrue,
        reason: 'kills a goal of 11, or a strict >',
      );
      expect(progress(Achievements.centurion, _p()..duelsWon = 99), (
        done: 99,
        total: 100,
      ), reason: 'kills a Centurion of the wrong size');
      expect(progress(Achievements.centurion, _p()..duelsWon = 112), (
        done: 100,
        total: 100,
      ), reason: 'kills an uncapped count — the screen would print 112/100');
    });

    test('Craft reads the best CRAFT skill, never a gathering one', () {
      final felled = _p()..skillXp['felling'] = _xpFor(12);
      expect(
        progress(Achievements.journeyman, felled),
        (done: 1, total: 5),
        reason:
            'kills a count over every skill — Felling is gathering, not a '
            'craft',
      );
      final four = _p()
        ..skillXp['woodcarving'] = _xpFor(5) - 1
        ..skillXp['tailoring'] = _xpFor(3);
      expect(
        progress(Achievements.journeyman, four),
        (done: 4, total: 5),
        reason:
            'kills a count off by one at the level boundary, or one that '
            'sums levels across crafts',
      );
      expect(
        Achievements.journeyman.isMet(four),
        isFalse,
        reason: 'kills a goal of 4',
      );
      expect(
        Achievements.journeyman.isMet(_p()..skillXp['jewelry'] = _xpFor(5)),
        isTrue,
        reason: 'kills a Journeyman that reads only one craft',
      );
      expect(
        progress(Achievements.artisan, _p()..skillXp['tailoring'] = _xpFor(9)),
        (done: 9, total: 10),
        reason: 'kills an Artisan of the wrong level',
      );
      expect(
        Achievements.artisan.isMet(_p()..skillXp['tailoring'] = _xpFor(10)),
        isTrue,
        reason: 'kills a goal of 11',
      );
    });

    test('On the Ladder: either ladder, one rated game', () {
      expect(
        Achievements.rated.isMet(_p()..duelsWon = 5),
        isFalse,
        reason: 'kills a condition reading unrated duels',
      );
      expect(
        Achievements.rated.isMet(_p()..ratedGamesGeared = 1),
        isTrue,
        reason: 'kills a condition that reads only the Academy',
      );
      expect(
        Achievements.rated.isMet(_p()..ratedGamesAcademy = 1),
        isTrue,
        reason: 'kills a condition that reads only the Geared ladder',
      );
    });

    test('Regular sums rated duels across both ladders, out of 10', () {
      AchievementProgress? regular(PlayerProfile p) =>
          Achievements.ladderRegular.progress!(p);
      final seeded = _p()
        ..duelsWon = 40
        ..academyWins = 40
        ..ratingAcademy = 1600
        ..peakAcademy = 1600;
      expect(
        regular(seeded),
        (done: 0, total: 10),
        reason:
            'kills a Regular reading wins or a rating — a high rating with '
            'no rated duels is not a regular',
      );
      final split = _p()
        ..ratedGamesGeared = 4
        ..ratedGamesAcademy = 5;
      expect(
        regular(split),
        (done: 9, total: 10),
        reason:
            'kills a Regular that reads one ladder only (4 or 5), or counts '
            'off by one',
      );
      expect(
        Achievements.ladderRegular.isMet(split),
        isFalse,
        reason: 'kills a goal of 9',
      );
      expect(
        Achievements.ladderRegular.isMet(split..ratedGamesAcademy = 6),
        isTrue,
        reason: 'kills a goal of 11, or a strict >',
      );
      expect(regular(_p()..ratedGamesGeared = 30), (
        done: 10,
        total: 10,
      ), reason: 'kills an uncapped count');
    });
  });

  group('newlyEarned', () {
    test('⭐ the satisfied and unheld, nothing else, in catalogue order', () {
      final p = _p()
        ..duelsWon = 12
        ..zoneClears.addAll(_zones(1))
        ..achievements.add('first_blood');
      expect(
        _ids(Achievements.newlyEarned(p)),
        ['first_clearing', 'tenfold'],
        reason:
            'kills a newlyEarned that repeats what is held (first_blood), '
            'skips what is satisfied, or includes what is not (centurion)',
      );
      expect(
        Achievements.newlyEarned(_p()),
        isEmpty,
        reason: 'kills a condition that a fresh character already meets',
      );
    });
  });

  group('granting live — with the toast', () {
    test('⭐ a duel win earns, saves and queues the toast', () async {
      final storage = _JsonMem();
      final game = GameState(storage, _p()..duelsWon = 9);
      game.profile.achievements.add('first_blood');

      await game.recordDuelResult(won: true);

      expect(
        game.profile.achievements,
        contains('tenfold'),
        reason: 'kills a recordDuelResult with no achievement hook',
      );
      expect(
        storage.stored!.achievements,
        contains('tenfold'),
        reason: 'kills a grant made in memory and never saved',
      );
      expect(
        _ids(game.achievementNews.value),
        ['tenfold'],
        reason:
            'kills a live grant that earns silently, and one that re-toasts '
            'first_blood',
      );
    });

    test('a boss win earns two, queued together in catalogue order', () async {
      final game = GameState(_JsonMem(), _p());
      await game.recordDuelResult(
        won: true,
        bossDefeated: true,
        locationId: 'whispering_woods',
      );
      expect(_ids(game.achievementNews.value), [
        'first_clearing',
        'first_blood',
      ], reason: 'kills a hook that grants only the first it finds');
      expect(
        achievementsToastText(game.achievementNews.value),
        'Achievements · First Clearing, First Blood',
        reason:
            'one toast names both — a second banner would replace the first',
      );
      expect(
        achievementsToastText([Achievements.tenfold]),
        'Achievement · Tenfold',
        reason: 'one alone reads as the gate toast always has',
      );
    });

    test('a loss earns nothing and writes nothing extra', () async {
      final storage = _JsonMem();
      final game = GameState(storage, _p());
      await game.recordDuelResult(won: false);
      expect(
        game.achievementNews.value,
        isEmpty,
        reason: 'kills a grant on a loss',
      );
      expect(
        storage.saves,
        1,
        reason: 'kills a hook that writes when nothing was earned',
      );
    });

    test('a rated result earns the Ladder entries', () async {
      final game = GameState(_JsonMem(), _p());
      await game.applyRatedResult(academy: true, newRating: 1220, won: true);
      expect(
        _ids(game.achievementNews.value),
        ['rated'],
        reason:
            'kills an applyRatedResult with no achievement hook — and a '
            'first rated win is no longer a second achievement',
      );

      game.achievementNews.value = const [];
      game.profile.ratedGamesGeared = 8;
      await game.applyRatedResult(academy: false, newRating: 1300, won: true);
      expect(_ids(game.achievementNews.value), [
        'ladder_regular',
      ], reason: 'kills a Regular never granted live at the tenth rated duel');
    });

    test('a craft that reaches level 5 earns Journeyman', () async {
      final p = _p()
        ..locationId = 'hearthwood'
        ..skillXp['woodcarving'] = _xpFor(5) - 1
        ..backpack = Backpack.of([
          for (var i = 0; i < 3; i++) const InventorySlot(defId: 'oak_log'),
        ]);
      final game = GameState(_JsonMem(), p);
      final out = await game.craft(PrimalRecipes.oakQuarterstaff);
      expect(out.succeeded, isTrue, reason: 'premise: the craft is made');
      expect(_ids(game.achievementNews.value), [
        'journeyman',
      ], reason: 'kills a craft with no achievement hook');
    });

    test(
      'Pennycross queues nothing — the gate screen toasts its own',
      () async {
        final p = _p()
          ..locationId = 'pennycross'
          ..arrivedFromId = 'hearthwood';
        for (final id in World.byId('pennycross').gateItemIds) {
          p.backpack = p.backpack.withAdded(InventorySlot(defId: id))!;
        }
        final game = GameState(_JsonMem(), p);
        expect(await game.openGateAt('pennycross'), isTrue, reason: 'premise');
        expect(game.profile.achievements, {
          'papers_in_order',
        }, reason: 'the gate still grants its own, in its own write');
        expect(
          game.achievementNews.value,
          isEmpty,
          reason: 'kills a double toast for Papers in Order',
        );
      },
    );
  });

  group('the sweep on load — silent', () {
    test('⭐ boot grants what was already met, with no toast', () async {
      final storage = _JsonMem();
      await storage.save(_p()..duelsWon = 12);

      final game = await GameState.boot(storage);

      expect(game.profile.achievements, {
        'first_blood',
        'tenfold',
      }, reason: 'kills a boot with no sweep — twelve wins and no Tenfold');
      expect(storage.stored!.achievements, {
        'first_blood',
        'tenfold',
      }, reason: 'kills a sweep that never reaches disk');
      expect(
        game.achievementNews.value,
        isEmpty,
        reason:
            'kills a sweep that toasts — a launch would open on a stack of '
            'banners for things done weeks ago',
      );
    });

    test('a conflict reload sweeps the cloud copy, and saves it', () async {
      final storage = _ConflictOnce(_p()..duelsWon = 1);
      final game = GameState(storage, _p());

      await game.touchPresence();

      expect(game.profile.achievements, {
        'first_blood',
      }, reason: 'kills a reload that skips the sweep');
      expect(storage.last?.achievements, {
        'first_blood',
      }, reason: 'kills a sweep after a reload that is never written back');
      expect(
        game.achievementNews.value,
        isEmpty,
        reason: 'kills a reload sweep that toasts',
      );
    });
  });

  group('the shell shows live news', () {
    testWidgets('one gold toast, then the news is cleared', (tester) async {
      final game = GameState(_JsonMem(), _p());
      await tester.pumpWidget(
        GameStateScope(
          state: game,
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      await tester.pump();

      game.achievementNews.value = [Achievements.tenfold];
      await tester.pump();

      expect(
        find.text('Achievement · Tenfold'),
        findsOneWidget,
        reason: 'kills a shell that never listens to the news',
      );
      expect(
        game.achievementNews.value,
        isEmpty,
        reason: 'kills a shell that leaves the news to toast again',
      );
      await tester.pump(kAppBannerHold + kAppBannerFade * 2);
    });
  });
}
