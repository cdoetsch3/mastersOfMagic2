/// Four loot rulings of one playtest (Christian, 2026-09-30), pinned together
/// because they all land in one kill.
///
/// 1. ✅ **Every monster drops SOMETHING** (note 4: *"Ionwake carried
///    nothing"*) — an empty table roll pays one unit of the table's
///    consolation craftable, keyed in `rollKill`, never authored into tables.
/// 2. ✅ **Mini-bosses pay rare/epic gear more often** (note 5) — a mini kill
///    makes the boss's rare-or-better roll on a `miniGearChance` gate.
/// 3. ✅ **A rare never drops twice in one kill** (note 11: *"double dropped
///    Leanstone Charm from a boss"*) — the rank-gear pool excludes every def
///    the table already paid.
/// 4. ✅ **The tables lean toward craftables** — the per-zone weights are
///    re-pinned in each zone's own test; the game-wide shape is pinned here.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/drop_table.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';

const _thunderspire = 'thunderspire_peaks';
const _windward = 'windward_steppe';

EnemyDef _creature(String id) => Bestiary.byId(id)!;

List<String> _ids(Loot l) => [for (final s in l.slots) s.defId];

void main() {
  group('ruling 1 — every monster drops something', () {
    final ionwake = _creature('ionwake');

    test('Ionwake consoles with its heaviest craftable, iron ore', () {
      expect(
        consolationOf(ionwake.drops),
        'iron_ore',
        reason:
            'iron_ore is the heaviest MaterialDef in its main — kills a '
            'consolation that takes hum_quartz (lighter) or the first '
            'always entry (dust) while a craftable exists',
      );
    });

    test('an empty table roll pays the consolation, and only it', () {
      int? seed;
      for (var s = 0; s < 2000 && seed == null; s++) {
        if (rollDrops(ionwake.drops, Random(s)).isEmpty) seed = s;
      }
      expect(
        seed,
        isNotNull,
        reason: 'the search must find an empty roll, or the test is vacuous',
      );
      final kill = rollKill(
        ionwake.drops,
        rank: EnemyRank.common,
        zoneId: _thunderspire,
        rng: Random(seed!),
      );
      expect(
        _ids(kill),
        ['iron_ore'],
        reason:
            'seed $seed rolled nothing: exactly ONE iron ore — kills no '
            'consolation (empty), a consolation of the wrong item, and a '
            'consolation that pays more than one unit',
      );
      expect(
        kill.instances,
        isEmpty,
        reason: 'a craftable is fungible — nothing to mint',
      );
    });

    test('a roll that paid something gets no consolation', () {
      var checked = 0;
      for (var s = 0; s < 200; s++) {
        final table = rollDrops(ionwake.drops, Random(s));
        if (table.isEmpty) continue;
        checked++;
        final kill = rollKill(
          ionwake.drops,
          rank: EnemyRank.common,
          zoneId: _thunderspire,
          rng: Random(s),
        );
        expect(
          _ids(kill),
          _ids(table),
          reason:
              'seed $s paid ${_ids(table)}: the kill is exactly the table — '
              'kills an unconditional consolation',
        );
      }
      expect(checked, greaterThan(150), reason: 'most rolls pay something');
    });

    test('⭐ the law: no creature in the game ever pays nothing', () {
      var consoled = 0;
      for (final c in Bestiary.all) {
        for (var s = 0; s < 200; s++) {
          if (rollDrops(c.drops, Random(s)).isEmpty) consoled++;
          final kill = rollKill(
            c.drops,
            rank: c.rank,
            zoneId: c.zoneId,
            rng: Random(s),
          );
          expect(
            kill.isEmpty,
            isFalse,
            reason:
                '${c.id} (${c.zoneId}) seed $s paid nothing — kills a '
                'consolation that is skipped for any rank or zone',
          );
        }
      }
      expect(
        consoled,
        greaterThan(0),
        reason:
            'some base rolls were empty, so the law above really exercised '
            'the consolation rather than passing on lucky tables',
      );
    });

    test('a craftable outranks a heavier mote; a tie goes to the first', () {
      const table = DropTable(
        main: [
          DropEntry.nothing(weight: 10),
          DropEntry('aero_dust', weight: 90),
          DropEntry('yew_log', weight: 5),
          DropEntry('tussock_flax', weight: 5),
        ],
      );
      expect(
        consolationOf(table),
        'yew_log',
        reason:
            'kills "heaviest entry of any kind" (aero_dust) and "last of a '
            'tie" (tussock_flax)',
      );
    });

    test('⚠️ Mirage, with no craftable, consoles with its first always', () {
      expect(
        consolationOf(_creature('mirage').drops),
        'solar_dust',
        reason:
            'no MaterialDef in its main: the first always entry — kills a '
            'fallback that returns null and lets the Mirage pay nothing',
      );
    });

    test('DropTable.empty is the only kill that pays nothing', () {
      expect(
        consolationOf(DropTable.empty),
        isNull,
        reason: 'nothing to console with — kills a made-up default item',
      );
      expect(
        rollKill(
          DropTable.empty,
          rank: EnemyRank.common,
          zoneId: _thunderspire,
          rng: Random(1),
        ).isEmpty,
        isTrue,
        reason: 'the documented exception',
      );
    });
  });

  group('ruling 2 — minis pay rare/epic gear on a miniGearChance', () {
    const zone = 'frostfell_pass';

    test('the two knobs are Christian\'s numbers', () {
      expect(
        miniGearChance,
        0.30,
        reason:
            'ruling 2026-09-30 note 5, amended the same day from 0.20 to '
            '0.30 — kills a knob left at the first number',
      );
      expect(
        bossEpicChance,
        0.25,
        reason: 'the epic share, identical for minis (2026-09-30)',
      );
    });

    test('a mini roll hits miniGearChance of the time (5000 rolls, ±3%)', () {
      final rng = Random(930);
      var hits = 0;
      var epics = 0;
      const n = 5000;
      for (var i = 0; i < n; i++) {
        final id = rollRankGear(EnemyRank.mini, zone, rng);
        if (id == null) continue;
        hits++;
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(
          def.rarity.index,
          greaterThanOrEqualTo(Rarity.rare.index),
          reason: '$id: a mini pays the boss roll — rare or better',
        );
        if (def.rarity == Rarity.epic) epics++;
      }
      expect(
        hits / n,
        closeTo(miniGearChance, 0.03),
        reason:
            '$hits of $n hit — kills a mini that never rolls (0%) or always '
            'pays (100%)',
      );
      expect(
        epics / hits,
        closeTo(bossEpicChance, 0.05),
        reason: '$epics of $hits were epic — the same epic share as a boss',
      );
    });

    test('a common never rolls rank gear and draws nothing for it', () {
      for (var s = 0; s < 50; s++) {
        final rng = Random(s);
        expect(
          rollRankGear(EnemyRank.common, zone, rng),
          isNull,
          reason: 'seed $s: kills a common that earns gear',
        );
        expect(
          rng.nextDouble(),
          Random(s).nextDouble(),
          reason:
              'seed $s: the common branch must not touch the stream — kills '
              'a gate roll drawn for commons too',
        );
      }
    });

    test('⚠️ a mini draws the same numbers whether or not the gate hits', () {
      // A mini is "a gate roll, then the boss's whole roll": so after
      // skipping one draw, a boss roll on a twin stream must land on the
      // same piece AND leave the stream in the same place — on a miss too.
      var hits = 0;
      var misses = 0;
      for (var s = 0; s < 300; s++) {
        final mini = Random(s);
        final twin = Random(s)..nextDouble();
        final miniId = rollRankGear(EnemyRank.mini, zone, mini);
        final bossId = rollRankGear(EnemyRank.boss, zone, twin);
        if (miniId == null) {
          misses++;
        } else {
          hits++;
          expect(
            miniId,
            bossId,
            reason: 'seed $s: a hit pays exactly the boss roll',
          );
        }
        expect(
          mini.nextDouble(),
          twin.nextDouble(),
          reason:
              'seed $s (${miniId == null ? 'miss' : 'hit'}): the stream must '
              'end in the same place — kills a mini that skips its roll on '
              'a miss',
        );
      }
      expect(hits, greaterThan(0), reason: 'both outcomes were exercised');
      expect(misses, greaterThan(0), reason: 'both outcomes were exercised');
    });

    test('a real mini kill: table first, then rare+ gear at the knob', () {
      final mini = Bestiary.forZone(
        zone,
      ).firstWhere((e) => e.rank == EnemyRank.mini);
      var extras = 0;
      const n = 2000;
      for (var s = 0; s < n; s++) {
        final table = rollDrops(mini.drops, Random(s));
        final kill = rollKill(
          mini.drops,
          rank: EnemyRank.mini,
          zoneId: zone,
          rng: Random(s),
        );
        expect(
          _ids(kill).take(table.count),
          _ids(table),
          reason: 'seed $s: the table is rolled first and untouched',
        );
        expect(
          kill.count - table.count,
          lessThanOrEqualTo(1),
          reason: 'seed $s: at most one extra piece per mini kill',
        );
        if (kill.count > table.count) extras++;
      }
      expect(
        extras / n,
        closeTo(miniGearChance, 0.03),
        reason:
            '$extras of $n mini kills paid gear — rollKill must route a '
            'mini through rollRankGear',
      );
    });
  });

  group('ruling 3 — a rare never drops twice in one kill', () {
    final windBoss = Bestiary.forZone(
      _windward,
    ).firstWhere((e) => e.rank == EnemyRank.boss);

    test('the playtest double: Leanstone Charm from the Windward boss', () {
      expect(
        windBoss.drops.possibleDrops,
        contains('leanstone_charm'),
        reason: 'the boss\'s own main can pay the charm — the premise',
      );
      expect(
        rankGearCandidates(_windward).map((d) => d.id),
        contains('leanstone_charm'),
        reason: 'and the rank-gear pool can too — the premise',
      );
      // Find a seed where the table pays the charm AND an un-excluded
      // guarantee, drawn from the very same stream, would pay it again.
      int? seed;
      for (var s = 0; s < 5000 && seed == null; s++) {
        final rng = Random(s);
        final table = rollDrops(windBoss.drops, rng);
        if (!_ids(table).contains('leanstone_charm')) continue;
        if (rollRankGear(EnemyRank.boss, _windward, rng) == 'leanstone_charm') {
          seed = s;
        }
      }
      expect(seed, isNotNull, reason: 'the double must be reachable');
      final kill = rollKill(
        windBoss.drops,
        rank: EnemyRank.boss,
        zoneId: _windward,
        rng: Random(seed!),
      );
      expect(
        _ids(kill).where((id) => id == 'leanstone_charm').length,
        1,
        reason:
            'seed $seed: exactly one charm — kills a rank-gear roll with no '
            'exclusion (two charms, the playtest bug)',
      );
      final table = rollDrops(windBoss.drops, Random(seed));
      expect(
        kill.count,
        table.count + 1,
        reason:
            'the guarantee still pays — a different rare+ piece, since the '
            'pool has more than the charm',
      );
    });

    test('a pool emptied by exclusion pays no extra piece', () {
      final all = {for (final d in rankGearCandidates(_windward)) d.id};
      expect(
        rankGearCandidates(_windward, excluding: all),
        isEmpty,
        reason: 'kills an exclusion that is ignored',
      );
      for (var s = 0; s < 20; s++) {
        expect(
          rollRankGear(EnemyRank.boss, _windward, Random(s), excluding: all),
          isNull,
          reason:
              'seed $s: nothing left — kills a fallback to the un-excluded '
              'pool, which would pay a second copy',
        );
      }
    });

    test('⚠️ exclusion never drags the pool below rare', () {
      // Ashfall Vale has an epic and no rare: excluding that epic must leave
      // nothing, not wake the best-rarity fallback onto uncommon gear.
      final only = rankGearCandidates('ashfall_vale');
      expect(only, hasLength(1), reason: 'the premise: one rare+ piece');
      expect(
        rankGearCandidates('ashfall_vale', excluding: {only.single.id}),
        isEmpty,
        reason:
            'kills exclusion applied BEFORE the rarity cut, which pays the '
            'zone\'s best remaining (sub-rare) gear',
      );
    });
  });

  group('ruling 4 — the 2026-09-30 lean, game-wide', () {
    MoteTier? tier(String? id) {
      final d = id == null ? null : ItemCatalogue.tryById(id);
      return d is MoteDef ? d.tier : null;
    }

    test('mini crystals at 15% (10% where shards are halved)', () {
      for (final c in Bestiary.all.where((c) => c.rank == EnemyRank.mini)) {
        for (final e in c.drops.always) {
          if (tier(e.defId) != MoteTier.crystal) continue;
          expect(
            e.chance,
            anyOf(0.15, 0.1),
            reason:
                '${c.id}: ${e.defId} at ${e.chance} — kills a zone the lean '
                'missed (0.25) or double-applied',
          );
        }
      }
    });

    test('mini dust at most 1–3, boss dust at most 3–6', () {
      for (final c in Bestiary.all) {
        if (c.rank == EnemyRank.common) continue;
        for (final e in c.drops.always) {
          if (tier(e.defId) != MoteTier.dust) continue;
          expect(
            e.max,
            lessThanOrEqualTo(c.rank == EnemyRank.mini ? 3 : 6),
            reason:
                '${c.id} (${c.rank.name}): ${e.defId} ${e.min}–${e.max} — '
                'kills a table the lean missed (2–4 / 4–8)',
          );
        }
      }
    });

    test('⚠️ the Mirage, with no craftable, is left at 45/15/40', () {
      // ✅ Christian, 2026-09-30: the lean favours craftables, and a table
      // with none has nothing to lean into.
      expect(
        [for (final e in _creature('mirage').drops.main) e.weight],
        [45, 15, 40],
        reason:
            'kills a lean applied to a table with no MaterialDef (the '
            'literal "first non-mote entry" reading gave 63/10/27)',
      );
    });

    test('every common main still sums to its authored total', () {
      // ⭐ The lean moved weight, never added it — rates stay readable as
      // percentages. Every common table was authored to 100.
      for (final c in Bestiary.all.where((c) => c.rank == EnemyRank.common)) {
        expect(
          c.drops.totalWeight,
          100,
          reason:
              '${c.id}: main sums to ${c.drops.totalWeight} — kills freed '
              'weight that was dropped rather than moved to the craftable',
        );
      }
    });
  });
}
