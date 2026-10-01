/// The stage-2 achievement catalogue (ACHIEVEMENTS §5, 2026-10-01): the
/// generated Campaign and Mastery entries, Wealth, Dueling and World, the
/// capstones and hidden entries — and Giant Slayer's one new counter.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — a renamed id, a zone missing its three, a key counted toward
/// Collector, a Purge that counts another zone's kills, a threshold out of
/// order, a gap measured after the win's XP.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/achievements/campaign.dart';
import 'package:masters_of_magic_2/game/achievements/duelling.dart';
import 'package:masters_of_magic_2/game/achievements/mastery.dart';
import 'package:masters_of_magic_2/game/achievements/wealth.dart';
import 'package:masters_of_magic_2/game/achievements/world.dart';
import 'package:masters_of_magic_2/game/bestiary_record.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

PlayerProfile _p() => PlayerProfile.newPlayer();

AchievementDef _def(String id) => Achievements.byId(id)!;

AchievementProgress _progress(String id, PlayerProfile p) =>
    _def(id).progress!(p)!;

/// Total XP at the start of [level].
int _xpAt(int level) {
  var xp = 0;
  for (var l = 1; l < level; l++) {
    xp += Progression.xpToNext(l);
  }
  return xp;
}

/// Every creature of [zoneId] slain once.
void _slayAll(PlayerProfile p, String zoneId) {
  for (final e in Bestiary.forZone(zoneId)) {
    p.noteSlain(e.id);
  }
}

/// [zoneId]'s drop tables, worked out here rather than read from the
/// catalogue: every possible drop, keys left out.
Set<String> _dropsWithoutKeys(String zoneId) => {
  for (final e in Bestiary.forZone(zoneId))
    for (final id in e.drops.possibleDrops)
      if (ItemCatalogue.tryById(id) is! KeyDef) id,
};

const _woods = 'whispering_woods';
const _brook = 'glimmerbrook';

void main() {
  group('the catalogue', () {
    test('⭐ the full id list, sorted — ids are forever', () {
      expect(
        [for (final a in Achievements.all) a.id]..sort(),
        [
          'artisan',
          'beyond_the_veil',
          'big_money',
          'cartographer',
          'centurion',
          'champion',
          'clear_ashfall_vale',
          'clear_cinderpeak_foothills',
          'clear_frostfell_pass',
          'clear_glimmerbrook',
          'clear_hallowmarch',
          'clear_old_quarry',
          'clear_starfall_basin',
          'clear_stormcliff_coast',
          'clear_the_buried_sky',
          'clear_the_collapsed_academy',
          'clear_the_eclipsed_citadel',
          'clear_the_glass_archive',
          'clear_the_kiln_desert',
          'clear_the_mirrormere',
          'clear_the_molten_deep',
          'clear_the_reliquary_deep',
          'clear_the_sealed_garden',
          'clear_the_shattered_orrery',
          'clear_the_sunless_reach',
          'clear_the_umbral_wastes',
          'clear_the_unwritten_library',
          'clear_thornmire',
          'clear_thunderspire_peaks',
          'clear_tidewrack_shoals',
          'clear_whispering_woods',
          'clear_windward_steppe',
          'collect_ashfall_vale',
          'collect_cinderpeak_foothills',
          'collect_frostfell_pass',
          'collect_glimmerbrook',
          'collect_hallowmarch',
          'collect_old_quarry',
          'collect_starfall_basin',
          'collect_stormcliff_coast',
          'collect_the_buried_sky',
          'collect_the_collapsed_academy',
          'collect_the_eclipsed_citadel',
          'collect_the_glass_archive',
          'collect_the_kiln_desert',
          'collect_the_mirrormere',
          'collect_the_molten_deep',
          'collect_the_reliquary_deep',
          'collect_the_sealed_garden',
          'collect_the_shattered_orrery',
          'collect_the_sunless_reach',
          'collect_the_umbral_wastes',
          'collect_the_unwritten_library',
          'collect_thornmire',
          'collect_thunderspire_peaks',
          'collect_tidewrack_shoals',
          'collect_whispering_woods',
          'collect_windward_steppe',
          'elementalist',
          'extinction',
          'fat_stacks',
          'first_blood',
          'first_clearing',
          'five_banners',
          'giant_slayer',
          'journeyman',
          'ladder_regular',
          'mastery_aero_1',
          'mastery_aero_2',
          'mastery_aero_3',
          'mastery_aero_4',
          'mastery_aero_5',
          'mastery_aqua_1',
          'mastery_aqua_2',
          'mastery_aqua_3',
          'mastery_aqua_4',
          'mastery_aqua_5',
          'mastery_arcane_1',
          'mastery_arcane_2',
          'mastery_arcane_3',
          'mastery_arcane_4',
          'mastery_arcane_5',
          'mastery_astral_1',
          'mastery_astral_2',
          'mastery_astral_3',
          'mastery_astral_4',
          'mastery_astral_5',
          'mastery_electro_1',
          'mastery_electro_2',
          'mastery_electro_3',
          'mastery_electro_4',
          'mastery_electro_5',
          'mastery_flora_1',
          'mastery_flora_2',
          'mastery_flora_3',
          'mastery_flora_4',
          'mastery_flora_5',
          'mastery_geo_1',
          'mastery_geo_2',
          'mastery_geo_3',
          'mastery_geo_4',
          'mastery_geo_5',
          'mastery_lunar_1',
          'mastery_lunar_2',
          'mastery_lunar_3',
          'mastery_lunar_4',
          'mastery_lunar_5',
          'mastery_pyro_1',
          'mastery_pyro_2',
          'mastery_pyro_3',
          'mastery_pyro_4',
          'mastery_pyro_5',
          'mastery_sanctus_1',
          'mastery_sanctus_2',
          'mastery_sanctus_3',
          'mastery_sanctus_4',
          'mastery_sanctus_5',
          'mastery_solar_1',
          'mastery_solar_2',
          'mastery_solar_3',
          'mastery_solar_4',
          'mastery_solar_5',
          'mastery_umbra_1',
          'mastery_umbra_2',
          'mastery_umbra_3',
          'mastery_umbra_4',
          'mastery_umbra_5',
          'nothing_left_to_find',
          'papers_in_order',
          'procarius_falls',
          'purge_ashfall_vale',
          'purge_cinderpeak_foothills',
          'purge_frostfell_pass',
          'purge_glimmerbrook',
          'purge_hallowmarch',
          'purge_old_quarry',
          'purge_starfall_basin',
          'purge_stormcliff_coast',
          'purge_the_buried_sky',
          'purge_the_collapsed_academy',
          'purge_the_eclipsed_citadel',
          'purge_the_glass_archive',
          'purge_the_kiln_desert',
          'purge_the_mirrormere',
          'purge_the_molten_deep',
          'purge_the_reliquary_deep',
          'purge_the_sealed_garden',
          'purge_the_shattered_orrery',
          'purge_the_sunless_reach',
          'purge_the_umbral_wastes',
          'purge_the_unwritten_library',
          'purge_thornmire',
          'purge_thunderspire_peaks',
          'purge_tidewrack_shoals',
          'purge_whispering_woods',
          'purge_windward_steppe',
          'rated',
          'ten_hours_on_the_road',
          'tenfold',
          'the_empyrean',
          'the_known_world',
          'the_long_road',
          'tres_commas',
          'twelvefold',
          'vanquisher_1',
          'vanquisher_2',
          'vanquisher_3',
          'vanquisher_4',
          'vanquisher_5',
          'wayfarer',
          'young_money',
        ],
        reason:
            'kills a renamed id (every save that earned it would lose it), a '
            'dropped entry and an added one nobody pinned',
      );
    });

    test('⭐ 171 entries — the arithmetic', () {
      expect(
        Achievements.all.length,
        171,
        reason:
            'Campaign 5 shipped + 26 zones × 3 + 3 capstones = 86; Mastery '
            '12 × 5 + Twelvefold + Elementalist = 62; Wealth 4; Dueling 3 '
            'shipped + Champion, Giant Slayer, Procarius Falls + Vanquisher '
            '× 5 = 11; World 4; Craft 2; Ladder 2 — 171. Kills a zone, an '
            'element or a tier lost from (or doubled in) the generation',
      );
      expect(
        {
          for (final c in AchievementCategory.values)
            c.name: Achievements.inCategory(c).length,
        },
        {
          'campaign': 86,
          'mastery': 62,
          'wealth': 4,
          'duelling': 11,
          'world': 4,
          'craft': 2,
          'ladder': 2,
        },
        reason: 'kills an entry filed under the wrong category',
      );
    });

    test('ids are unique, and byId finds each one', () {
      final ids = [for (final a in Achievements.all) a.id];
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

    test('grouped by category, in enum order', () {
      final order = [for (final a in Achievements.all) a.category.index];
      expect(
        order,
        [...order]..sort(),
        reason:
            'kills a section split in two on the screen — all is §5 order, '
            'category by category',
      );
    });

    test('every weight is allowed', () {
      for (final a in Achievements.all) {
        expect(
          AchievementDef.allowedPoints,
          contains(a.points),
          reason: 'kills an off-scale weight on ${a.id}',
        );
      }
    });

    test('⭐ the copy: a full stop, no shouting, no name twice', () {
      for (final a in Achievements.all) {
        expect(
          a.blurb.endsWith('.'),
          isTrue,
          reason: 'house voice: a blurb is a sentence (${a.id})',
        );
        expect(
          '${a.name}${a.blurb}'.contains('!'),
          isFalse,
          reason: 'house voice: no exclamation marks (${a.id})',
        );
      }
      final names = [for (final a in Achievements.all) a.name];
      expect(
        names.toSet().length,
        names.length,
        reason: 'kills a repeated name — two rows the player cannot tell apart',
      );
    });

    test('⭐ the hidden set is exactly the four spoilers', () {
      expect(
        {
          for (final a in Achievements.all)
            if (a.hidden) a.id,
        },
        {
          'extinction',
          'nothing_left_to_find',
          'tres_commas',
          'procarius_falls',
        },
        reason:
            'kills a spoiler shown (Procarius is the ending) and a goal '
            'hidden that the player should see coming',
      );
    });

    test('⭐ a fresh character has earned nothing', () {
      expect(
        Achievements.newlyEarned(_p()),
        isEmpty,
        reason:
            'kills an entry met at level 1 — Elementalist reading the '
            'unenforced slot count, Wayfarer counting Hearthwood as ten',
      );
    });

    test('⭐ every family is tiers 1..n, in catalogue order', () {
      final tiers = <String, List<int>>{};
      for (final a in Achievements.all) {
        if (a.family != null) (tiers[a.family!] ??= []).add(a.tier!);
      }
      for (final MapEntry(key: family, value: list) in tiers.entries) {
        expect(list, [
          for (var t = 1; t <= list.length; t++) t,
        ], reason: 'kills a gap, a repeat or a reordered tier in $family');
      }
      expect(tiers.keys.toSet(), {
        for (final e in MagicElement.values) 'mastery_${e.name}',
        'wealth',
        'vanquisher',
      }, reason: 'kills a family renamed, or a tiered set left without one');
    });
  });

  group('Campaign — three per zone', () {
    test('⭐ 26 combat zones, each with a clear, a purge and a collector', () {
      final zones = CampaignAchievements.combatZones;
      expect(zones.map((z) => z.id), [
        for (final l in World.locations)
          if (!l.isTown) l.id,
      ], reason: 'kills a combat zone left out of the generation');
      expect(zones.length, 26, reason: 'kills a town counted as a zone');
      for (final z in zones) {
        expect(
          [
            for (final a in Achievements.inCategory(
              AchievementCategory.campaign,
            ))
              if (a.id.endsWith('_${z.id}')) a.id,
          ],
          ['clear_${z.id}', 'purge_${z.id}', 'collect_${z.id}'],
          reason: 'kills a zone with a missing or doubled entry (${z.id})',
        );
      }
      expect(
        CampaignAchievements.names.keys.toSet(),
        zones.map((z) => z.id).toSet(),
        reason: 'kills a names row for a zone that does not exist',
      );
    });

    test('points: clear 10, purge 25, collector 50', () {
      for (final z in CampaignAchievements.combatZones) {
        expect(
          [
            _def('clear_${z.id}').points,
            _def('purge_${z.id}').points,
            _def('collect_${z.id}').points,
          ],
          [10, 25, 50],
          reason: 'kills a re-weighted campaign entry (${z.id})',
        );
      }
    });

    test('⭐ every Collector total is the zone\'s drop set, keys left out', () {
      for (final z in CampaignAchievements.combatZones) {
        expect(
          _progress('collect_${z.id}', _p()).total,
          _dropsWithoutKeys(z.id).length,
          reason: 'kills a Collector total that is not the drop set (${z.id})',
        );
        expect(
          _progress('purge_${z.id}', _p()).total,
          Bestiary.forZone(z.id).length,
          reason: 'kills a Purge total that is not the roster (${z.id})',
        );
      }
      final raw = {
        for (final e in Bestiary.forZone(_woods)) ...e.drops.possibleDrops,
      };
      expect(
        raw,
        contains('proof_of_the_woods'),
        reason: 'premise: the Woods drop a key',
      );
      expect(
        _progress('collect_$_woods', _p()).total,
        raw.length - 1,
        reason:
            'kills keys counted — a proof is a quest item, and a character '
            'who carried it before itemsSeen could never see it again',
      );
    });

    test('Clear reads zoneClears for THAT zone, not discovery', () {
      expect(
        _def('clear_$_woods').isMet(_p()..discoveredLocationIds.add(_woods)),
        isFalse,
        reason: 'kills a Clear that reads discovery — walking is not clearing',
      );
      final cleared = _p()..zoneClears[_woods] = 1;
      expect(
        _def('clear_$_woods').isMet(cleared),
        isTrue,
        reason: 'kills a Clear that never fires',
      );
      expect(
        _def('clear_$_brook').isMet(cleared),
        isFalse,
        reason: 'kills a Clear that reads any zone',
      );
    });

    test('⭐ Purge counts distinct slain creatures of THAT zone only', () {
      final roster = Bestiary.forZone(_woods);
      final p = _p();
      for (final e in roster.skip(1)) {
        p.noteSlain(e.id);
        p.noteSlain(e.id);
      }
      _slayAll(p, _brook);
      expect(
        _progress('purge_$_woods', p),
        (done: roster.length - 1, total: roster.length),
        reason:
            'kills a Purge counting kills not creatures (each slain twice), '
            'or counting another zone\'s creatures (the brook, all slain)',
      );
      expect(
        _def('purge_$_woods').isMet(p),
        isFalse,
        reason: 'kills a Purge one short of the roster',
      );
      p.noteSlain(roster.first.id);
      expect(
        _def('purge_$_woods').isMet(p),
        isTrue,
        reason: 'kills a Purge that never completes',
      );
      expect(
        _def(
          'purge_$_woods',
        ).isMet(_p()..bestiary[roster.first.id] = const BestiaryEntry(seen: 9)),
        isFalse,
        reason: 'kills a Purge reading seen instead of slain',
      );
    });

    test('⭐ Collector counts only that zone\'s drops', () {
      final mine = _dropsWithoutKeys(_woods);
      final theirs = _dropsWithoutKeys(_brook).difference(mine);
      final p = _p()
        ..itemsSeen.addAll(theirs)
        ..itemsSeen.add('proof_of_the_woods');
      expect(
        _progress('collect_$_woods', p).done,
        0,
        reason:
            'kills a Collector counting another zone\'s drops, or the key '
            'it leaves out',
      );
      p.itemsSeen.addAll(mine.skip(1));
      expect(_progress('collect_$_woods', p), (
        done: mine.length - 1,
        total: mine.length,
      ), reason: 'kills a Collector count off by one');
      p.itemsSeen.add(mine.first);
      expect(
        _def('collect_$_woods').isMet(p),
        isTrue,
        reason: 'kills a Collector that asks for the key too',
      );
    });

    test('the capstones: all 26, and 25 is not enough', () {
      final ids = [for (final z in CampaignAchievements.combatZones) z.id];
      final most = _p()
        ..zoneClears.addAll({for (final id in ids.skip(1)) id: 1});
      most.zoneClears['not_a_zone'] = 1;
      expect(
        _progress('the_known_world', most),
        (done: 25, total: 26),
        reason:
            'kills a Known World reading zonesCleared — a stray id on the '
            'save is not a zone',
      );
      most.zoneClears[ids.first] = 1;
      expect(
        _def('the_known_world').isMet(most),
        isTrue,
        reason: 'kills a Known World that never completes',
      );

      final slain = _p();
      for (final id in ids) {
        _slayAll(slain, id);
      }
      expect(
        _def('extinction').isMet(slain),
        isTrue,
        reason: 'kills an Extinction that never completes',
      );
      slain.bestiary.remove(Bestiary.forZone(ids.last).last.id);
      expect(_progress('extinction', slain), (
        done: 25,
        total: 26,
      ), reason: 'kills an Extinction counting a zone one creature short');

      final seen = _p()
        ..itemsSeen.addAll({for (final id in ids) ..._dropsWithoutKeys(id)});
      expect(
        _def('nothing_left_to_find').isMet(seen),
        isTrue,
        reason: 'kills a Nothing Left to Find that asks for keys',
      );
      expect(
        _def('extinction').isMet(seen) || _def('the_known_world').isMet(seen),
        isFalse,
        reason: 'kills capstones reading each other\'s counters',
      );
    });
  });

  group('Mastery', () {
    test('⭐ 60 tiers: 5 per element, thresholds ascending', () {
      expect(MasteryAchievements.tiers.length, 60, reason: 'kills 12 × 5 lost');
      for (final e in MagicElement.values) {
        final family = [
          for (final a in Achievements.all)
            if (a.family == 'mastery_${e.name}') a,
        ];
        expect(
          [for (final a in family) a.id],
          [for (var t = 1; t <= 5; t++) 'mastery_${e.name}_$t'],
          reason: 'kills a renamed or missing tier (${e.name})',
        );
        expect(
          [for (final a in family) a.progress!(_p())!.total],
          Achievements.masteryThresholds,
          reason: 'kills a tier on the wrong threshold (${e.name})',
        );
        expect(
          [for (final a in family) a.points],
          [5, 10, 25, 25, 50],
          reason: 'kills a re-weighted tier (${e.name})',
        );
        expect(
          family.first.name,
          '${e.displayName} Mastery I',
          reason: 'kills a tier named for the wrong element',
        );
      }
      final t = Achievements.masteryThresholds;
      for (var i = 1; i < t.length; i++) {
        expect(
          t[i] > t[i - 1],
          isTrue,
          reason: 'kills a threshold out of order',
        );
      }
    });

    test(
      'a tier reads its own element\'s charges, at exactly the threshold',
      () {
        final p = _p()..charges.addAll({'pyro': 249, 'aqua': 25000});
        expect(
          _def('mastery_pyro_1').isMet(p),
          isFalse,
          reason: 'kills a tier met one charge short, or reading aqua',
        );
        p.charges['pyro'] = 250;
        expect(
          _def('mastery_pyro_1').isMet(p),
          isTrue,
          reason: 'kills a strict > at the threshold',
        );
        expect(_progress('mastery_pyro_2', p), (
          done: 250,
          total: 1000,
        ), reason: 'kills a progress bar reading the wrong count');
      },
    );

    test('Twelvefold: tier I in all twelve', () {
      final p = _p()
        ..charges.addAll({
          for (final e in MagicElement.values.skip(1)) e.name: 250,
          MagicElement.values.first.name: 249,
        });
      expect(_progress('twelvefold', p), (
        done: 11,
        total: 12,
      ), reason: 'kills a Twelvefold counting an element one charge short');
      p.charges[MagicElement.values.first.name] = 250;
      expect(
        _def('twelvefold').isMet(p),
        isTrue,
        reason: 'kills a Twelvefold that never completes',
      );
    });

    test('Elementalist: the fifth element slot, by the schedule', () {
      expect(
        _def('elementalist').isMet(_p()..xp = _xpAt(39)),
        isFalse,
        reason:
            'kills an Elementalist reading the unenforced usable count (5 at '
            'level 1)',
      );
      expect(
        _def('elementalist').isMet(_p()..xp = _xpAt(40)),
        isTrue,
        reason: 'kills an Elementalist that never fires at level 40',
      );
    });
  });

  group('Wealth', () {
    test('⭐ gold EARNED, at each threshold', () {
      expect(
        [for (final a in WealthAchievements.all) a.progress!(_p())!.total],
        [10000, 100000, 1000000, 1000000000],
        reason: 'kills a tier on the wrong threshold (ruling 6)',
      );
      expect(
        [for (final a in WealthAchievements.all) a.points],
        [5, 10, 25, 100],
        reason: 'kills a re-weighted wealth tier (ruling 6)',
      );
      expect(
        _def('young_money').isMet(_p()..goldEarned = 9999),
        isFalse,
        reason: 'kills a Young Money one gold short',
      );
      expect(
        _def('young_money').isMet(_p()..goldEarned = 10000),
        isTrue,
        reason: 'kills a strict > at the threshold',
      );
      expect(
        _def('young_money').isMet(_p()..gold = 1000000000),
        isFalse,
        reason: 'kills Wealth reading gold held — spending would un-earn it',
      );
    });
  });

  group('Dueling', () {
    test('Champion: five hundred wins', () {
      expect(_progress('champion', _p()..duelsWon = 499), (
        done: 499,
        total: 500,
      ), reason: 'kills a Champion on the wrong count');
      expect(
        _def('champion').isMet(_p()..academyWins = 500),
        isFalse,
        reason: 'kills a Champion reading Academy wins',
      );
    });

    test('⭐ Giant Slayer at exactly ten levels', () {
      expect(
        _def('giant_slayer').isMet(_p()..biggestWinLevelGap = 9),
        isFalse,
        reason: 'kills a gap of 9 counted',
      );
      expect(
        _def('giant_slayer').isMet(_p()..biggestWinLevelGap = 10),
        isTrue,
        reason: 'kills a strict > — ten levels above is the ruling',
      );
    });

    test('Procarius Falls reads the Citadel\'s last boss, slain', () {
      expect(
        _def('procarius_falls').isMet(
          _p()
            ..bestiary['procarius_the_eclipsed'] = const BestiaryEntry(seen: 3),
        ),
        isFalse,
        reason: 'kills a Procarius Falls on meeting him',
      );
      expect(
        _def('procarius_falls').isMet(_p()..noteSlain('totality')),
        isFalse,
        reason: 'kills a Procarius Falls on the first boss of the sequence',
      );
      expect(
        _def(
          'procarius_falls',
        ).isMet(_p()..noteSlain('procarius_the_eclipsed')),
        isTrue,
        reason:
            'kills a Procarius Falls keyed on the persona id — the bestiary '
            'never holds "procarius"',
      );
    });

    test('Vanquisher: every kill, repeats included', () {
      expect(
        [
          for (final a in DuellingAchievements.vanquisher)
            a.progress!(_p())!.total,
        ],
        [50, 250, 1000, 2500, 5000],
        reason: 'kills a tier on the wrong threshold',
      );
      expect(
        [for (final a in DuellingAchievements.vanquisher) a.points],
        [5, 10, 25, 25, 50],
        reason: 'kills a re-weighted tier',
      );
      final p = _p()
        ..bestiary['thornback_sprite'] = const BestiaryEntry(
          seen: 60,
          slain: 30,
        )
        ..bestiary['brook_naiad'] = const BestiaryEntry(seen: 60, slain: 19);
      expect(
        _progress('vanquisher_1', p),
        (done: 49, total: 50),
        reason:
            'kills a Vanquisher counting distinct creatures, or fights seen',
      );
      p.noteSlain('brook_naiad');
      expect(
        _def('vanquisher_1').isMet(p),
        isTrue,
        reason: 'kills a strict > at the threshold',
      );
    });
  });

  group('World', () {
    test('Wayfarer: ten real places', () {
      final p = _p()
        ..discoveredLocationIds.addAll([
          for (final l in World.locations.take(9)) l.id,
          'retired_place',
        ]);
      expect(_progress('wayfarer', p), (
        done: 9,
        total: 10,
      ), reason: 'kills a stray id on the save counted as a place');
      p.discoveredLocationIds.add(World.locations[9].id);
      expect(
        _def('wayfarer').isMet(p),
        isTrue,
        reason: 'kills a Wayfarer that never fires',
      );
    });

    test('Cartographer: every location', () {
      final p = _p()
        ..discoveredLocationIds.addAll([
          for (final l in World.locations.skip(1)) l.id,
        ])
        ..discoveredLocationIds.remove(World.locations.first.id);
      expect(_progress('cartographer', p), (
        done: World.locations.length - 1,
        total: World.locations.length,
      ), reason: 'kills a Cartographer short of, or past, the whole world');
    });

    test('The Empyrean is Zenith discovered — not the Rimeholt gate', () {
      expect(
        _def('the_empyrean').isMet(_p()..openedGates.add('rimeholt')),
        isFalse,
        reason: 'kills The Empyrean reading the shipped Beyond the Veil',
      );
      expect(
        _def('the_empyrean').isMet(_p()..discoveredLocationIds.add('zenith')),
        isTrue,
        reason: 'kills The Empyrean that never fires',
      );
    });

    test('Ten Hours on the Road at exactly 36,000 seconds', () {
      expect(
        _def('ten_hours_on_the_road').isMet(_p()..travelSeconds = 36000 - 1),
        isFalse,
        reason: 'kills a road one second short counted',
      );
      expect(
        _def('ten_hours_on_the_road').isMet(_p()..travelSeconds = 36000),
        isTrue,
        reason: 'kills a road of eleven hours, or a strict >',
      );
      expect(
        WorldAchievements.all.map((a) => a.id),
        isNot(contains('the_long_road')),
        reason: 'kills the shipped fifteen-clears id reused for travel',
      );
    });
  });

  group('biggestWinLevelGap — Giant Slayer\'s counter', () {
    test('round-trips, is always written, and reads 0 when absent', () {
      final back = PlayerProfile.fromJson(
        jsonDecode(jsonEncode((_p()..biggestWinLevelGap = 12).toJson())),
      );
      expect(
        back.biggestWinLevelGap,
        12,
        reason: 'kills the field missing from toJson or fromJson',
      );
      expect(
        ProfileDocuments.split(
          _p(),
        ).character.containsKey('biggestWinLevelGap'),
        isTrue,
        reason:
            'kills a sparse write — the update mask is built from the '
            'written keys',
      );
      expect(
        PlayerProfile.fromJson(
          _p().toJson()..remove('biggestWinLevelGap'),
        ).biggestWinLevelGap,
        0,
        reason: 'kills a fromJson that throws on, or invents, an absent key',
      );
    });

    test('⭐ recordDuelResult keeps the best gap, wins only', () async {
      final game = GameState(_Mem(), _p()..xp = _xpAt(5));
      await game.recordDuelResult(won: false, opponentLevel: 30);
      expect(
        game.profile.biggestWinLevelGap,
        0,
        reason: 'kills a loss counted — Giant SLAYER',
      );
      await game.recordDuelResult(won: true, opponentLevel: 12);
      expect(
        game.profile.biggestWinLevelGap,
        7,
        reason: 'kills a hook that records nothing, or the opponent\'s level',
      );
      await game.recordDuelResult(won: true, opponentLevel: 3);
      expect(
        game.profile.biggestWinLevelGap,
        7,
        reason: 'kills a gap that goes down after an easier win',
      );
    });

    test(
      '⭐ measured against the level GOING IN, before the win\'s XP',
      () async {
        // One XP short of level 6: the win itself crosses the level.
        final game = GameState(_Mem(), _p()..xp = _xpAt(6) - 1);
        expect(game.profile.level, 5, reason: 'premise: level 5 going in');
        await game.recordDuelResult(won: true, opponentLevel: 15);
        expect(game.profile.level, 6, reason: 'premise: the win levels up');
        expect(
          game.profile.biggestWinLevelGap,
          10,
          reason: 'kills a gap measured after the XP — 9, and no Giant Slayer',
        );
        expect(
          game.profile.achievements,
          contains('giant_slayer'),
          reason: 'kills a Giant Slayer not granted live by the win',
        );
      },
    );
  });
}
