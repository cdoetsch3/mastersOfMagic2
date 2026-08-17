/// The roller, held to the numbers the content declares.
///
/// ⭐ **Why frequency tests and not just unit tests.** A weighted draw is the
/// kind of code that is *plausible* while wrong — an off-by-one in the
/// cumulative sum, an `<=` where a `<` belongs, a `nextInt(total + 1)` — and
/// every one of those still returns a legal entry every time. Nothing short of
/// counting catches it. So the suite counts.
///
/// ⚠️ **Deterministic seeds, loose bounds.** These are pinned with fixed seeds
/// and generous tolerances so they can never go flaky, but the tolerances are
/// still far tighter than any real bias: an off-by-one on the boss table moves
/// a slot by ~10 percentage points, and these bounds are 1.
///
/// ⭐ The bounds are checked against `DropTable.mainChanceOf` — the same
/// accountant `content_export.dart` publishes to the wiki — rather than
/// against numbers retyped here. That is what makes the wiki's percentages
/// *true* rather than merely *consistent with themselves*.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/drop_table.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

/// Enough rolls that a 5% slot lands inside 1 point, cheap enough to run on
/// every commit.
const _n = 20000;

/// ~3 sigma at the widest slot in these tables (p≈0.45 → σ≈0.0035), and 20×
/// smaller than the smallest bias any plausible bug would produce.
const _tolerance = 0.01;

/// Rolls only [table]'s main bucket [_n] times and counts which entry won.
///
/// ⚠️ Isolating `main` matters: with `always` attached, an id that appears in
/// both buckets would be uncountable. Rebuilding the table from the *real*
/// entries keeps this a test of shipped content, not of a fixture.
Map<String, int> _mainHistogram(DropTable table, int seed) {
  final probe = DropTable(main: table.main);
  final rng = Random(seed);
  final counts = <String, int>{};
  for (var i = 0; i < _n; i++) {
    final loot = rollDrops(probe, rng);
    // Exactly one entry is drawn, so every slot carries the same id — or the
    // list is empty, which is the "nothing" outcome.
    final key = loot.slots.isEmpty ? '(nothing)' : loot.slots.first.defId;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Fraction of [_n] kills in which [defId] appeared at all.
Map<String, int> _appearanceHistogram(DropTable table, int seed) {
  final rng = Random(seed);
  final counts = <String, int>{};
  for (var i = 0; i < _n; i++) {
    for (final id in rollDrops(table, rng).slots.map((s) => s.defId).toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

void _expectRate(
  int observed,
  double expected,
  String what, [
  double tolerance = _tolerance,
]) {
  expect(
    observed / _n,
    closeTo(expected, tolerance),
    reason:
        '$what came out ${(observed / _n * 100).toStringAsFixed(2)}% over $_n '
        'rolls; the table declares ${(expected * 100).toStringAsFixed(2)}%',
  );
}

void main() {
  group('the boss main table pays at its declared rates', () {
    final drops = WhisperingWoodsBestiary.heartwood.drops;
    final counts = _mainHistogram(drops, 20250816);

    test('every slot lands on its weight fraction', () {
      // 🚫 Kills: off-by-one in the cumulative subtraction, `nextInt(total+1)`,
      // `roll <= 0` instead of `roll < 0`, and any drift between the roller
      // and the `mainChanceOf` number the wiki prints.
      for (final e in drops.main) {
        _expectRate(
          counts[e.defId] ?? 0,
          drops.mainChanceOf(e.defId!),
          '${e.defId} from the boss table',
        );
      }
    });

    test('the Epic is a 1-in-10 chase, and the roller agrees', () {
      // ⭐ The reported "epic twice in a row". At 10% a boss kill, two
      // consecutive runs' bosses both paying is 1%. Unlucky-lucky, not broken.
      expect(drops.mainChanceOf('heartwood_stave'), 0.10);
      _expectRate(counts['heartwood_stave'] ?? 0, 0.10, 'heartwood_stave');
    });

    test('a boss main table never comes up empty', () {
      // ⚠️ There is no `nothing` entry, so a `(nothing)` bucket here would mean
      // `_drawOne` fell off the end of the loop — the classic off-by-one tell.
      expect(
        counts['(nothing)'] ?? 0,
        0,
        reason: 'the weighted draw fell through and paid nothing',
      );
      expect(counts.values.fold(0, (a, b) => a + b), _n);
    });
  });

  group('the mini-boss main table pays at its declared rates', () {
    final drops = WhisperingWoodsBestiary.elderroot.drops;
    final counts = _mainHistogram(drops, 761101);

    test('every slot lands on its weight fraction', () {
      for (final e in drops.main) {
        _expectRate(
          counts[e.defId] ?? 0,
          drops.mainChanceOf(e.defId!),
          '${e.defId} from the mini table',
        );
      }
    });

    test('the Rare chase is 1-in-20 per mini', () {
      // Two minis per run (§2g), so a run shows one 9.75% of the time and
      // both 0.25% of the time.
      expect(drops.mainChanceOf('sporecap_mantle'), 0.05);
      _expectRate(counts['sporecap_mantle'] ?? 0, 0.05, 'sporecap_mantle');
    });

    test('all four minis share one table, so one audit covers all four', () {
      for (final m in WhisperingWoodsBestiary.minis) {
        expect(
          m.drops.main,
          same(drops.main),
          reason: '${m.id} has drifted off the shared _miniDrops table',
        );
      }
      for (final b in WhisperingWoodsBestiary.bosses) {
        expect(
          b.drops.main,
          same(WhisperingWoodsBestiary.heartwood.drops.main),
          reason: '${b.id} has drifted off the shared _bossDrops table',
        );
      }
    });
  });

  group('the "nothing" slot is a real outcome', () {
    test('a common comes up empty at exactly its declared weight', () {
      // 🚫 Kills a `_drawOne` that skips null entries instead of counting their
      // weight — which would silently inflate every real slot on every common.
      final drops = WhisperingWoodsBestiary.listeningFawn.drops;
      final counts = _mainHistogram(drops, 4242);
      _expectRate(counts['(nothing)'] ?? 0, 0.40, 'the fawn paying nothing');
      _expectRate(counts['bindweed_fibre'] ?? 0, 0.45, 'bindweed_fibre');
      _expectRate(counts['foragers_ration'] ?? 0, 0.15, 'foragers_ration');
    });
  });

  group('the weighted draw has no edge bias', () {
    test('a flat table is flat — first and last entries included', () {
      // ⭐ An off-by-one shows up at the ENDS. Six equal entries make the first
      // and last as likely as the middle, so either kind of drift is visible.
      const flat = DropTable(
        main: [
          DropEntry('oak_log'),
          DropEntry('bindweed_fibre'),
          DropEntry('flora_shard'),
          DropEntry('flora_dust'),
          DropEntry('foragers_ration'),
          DropEntry('flora_crystal'),
        ],
      );
      final counts = _mainHistogram(flat, 99);
      for (final e in flat.main) {
        _expectRate(counts[e.defId] ?? 0, 1 / 6, '${e.defId} in a flat table');
      }
    });

    test('a 1-in-100 slot really is 1-in-100', () {
      // The smallest weight the format can express, at the END of the list —
      // the position an off-by-one starves or doubles.
      const skewed = DropTable(
        main: [DropEntry('oak_log', weight: 99), DropEntry('flora_crystal')],
      );
      final counts = _mainHistogram(skewed, 31337);
      _expectRate(counts['flora_crystal'] ?? 0, 0.01, 'the 1% tail slot');
    });

    test('a zero-weight entry can never be drawn', () {
      const dead = DropTable(
        main: [
          DropEntry('oak_log', weight: 0),
          DropEntry('flora_shard', weight: 1),
        ],
      );
      final counts = _mainHistogram(dead, 7);
      expect(
        counts['oak_log'] ?? 0,
        0,
        reason: 'weight 0 must mean never, not "whenever the roll lands on 0"',
      );
    });
  });

  group('the always bucket honours its own chances', () {
    test('a mini hands over a Crystal one kill in four, not every kill', () {
      // 🚫 Kills the bug this audit found: `rollDrops` expanded every `always`
      // entry unconditionally, so `chance: 0.25` meant 100%. A Crystal is 20
      // Shards (ITEMS §8), so a guaranteed one made the guaranteed 1–3 Shards
      // beside it statistical noise — and the wiki was publishing 25%.
      final counts = _appearanceHistogram(
        WhisperingWoodsBestiary.elderroot.drops,
        5150,
      );
      _expectRate(counts['flora_crystal'] ?? 0, 0.25, 'flora_crystal');
      _expectRate(counts['flora_shard'] ?? 0, 1.0, 'flora_shard (chance 1)');
    });

    test('a common sheds dust three kills in four', () {
      final counts = _appearanceHistogram(
        WhisperingWoodsBestiary.listeningFawn.drops,
        8080,
      );
      _expectRate(counts['flora_dust'] ?? 0, 0.75, 'flora_dust');
    });

    test('a boss always bucket is genuinely guaranteed', () {
      // ⚠️ The gate item. Every kill, no exceptions — progression must not sit
      // behind a dice roll.
      final counts = _appearanceHistogram(
        WhisperingWoodsBestiary.heartwood.drops,
        606,
      );
      expect(
        counts['proof_of_the_woods'],
        _n,
        reason: 'the Hearthwood gate item missed a boss kill',
      );
      expect(counts['flora_crystal'], _n);
      expect(counts['flora_shard'], _n);
    });
  });

  group('each roll draws fresh randomness', () {
    test('bonus entries are independent, not one shared coin flip', () {
      // 🚫 Kills a `rollDrops` that hoists `rng.nextDouble()` out of the bonus
      // loop. Three 50% entries sharing one flip would only ever yield 0 or 3.
      const table = DropTable(
        bonus: [
          DropEntry('oak_log', chance: 0.5),
          DropEntry('flora_shard', chance: 0.5),
          DropEntry('flora_dust', chance: 0.5),
        ],
      );
      final rng = Random(2468);
      final byCount = <int, int>{};
      for (var i = 0; i < 4000; i++) {
        final n = rollDrops(table, rng).slots.length;
        byCount[n] = (byCount[n] ?? 0) + 1;
      }
      for (final n in [0, 1, 2, 3]) {
        expect(
          byCount[n] ?? 0,
          greaterThan(0),
          reason: '$n-of-3 never happened — the bonus rolls are correlated',
        );
      }
      // Binomial(3, 0.5): the middles must dominate the extremes.
      expect((byCount[1] ?? 0) + (byCount[2] ?? 0), greaterThan(4000 * 0.6));
    });

    test('quantity spans its whole min..max band, uniformly', () {
      // `min + nextInt(max - min + 1)` — an off-by-one here would clip `max`.
      const table = DropTable(main: [DropEntry('oak_log', min: 4, max: 8)]);
      final rng = Random(1234);
      final byQty = <int, int>{};
      for (var i = 0; i < 10000; i++) {
        final n = rollDrops(table, rng).slots.length;
        byQty[n] = (byQty[n] ?? 0) + 1;
      }
      expect(byQty.keys.toList()..sort(), [4, 5, 6, 7, 8]);
      for (final q in [4, 5, 6, 7, 8]) {
        expect(
          byQty[q]! / 10000,
          closeTo(0.2, 0.02),
          reason: 'quantity $q is not uniform across 4..8',
        );
      }
    });
  });

  group('production loot is not replaying one seed', () {
    test('winEncounter without an rng varies fight to fight', () async {
      // ⚠️ THE reported symptom's most dangerous explanation: a fixed or
      // hoisted seed in `GameState.winEncounter` would make every kill in
      // every run drop the identical bundle. The real caller
      // (`adventure_screen.dart`) passes no rng, so this is that exact path.
      // 🚫 Kills `rng ?? Random(<literal>)` and any cached `Random` field.
      final woods = World.byId('whispering_woods');
      final hauls = <String>{};
      for (var i = 0; i < 40; i++) {
        final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
        // ⚠️ The RUN seed is held FIXED on purpose. Varying it would draw a
        // different enemy each time and the hauls would differ for that
        // reason alone — the test would pass with a hard-coded loot seed,
        // which is precisely the bug it exists to catch. Same enemy, same
        // table, forty kills: only the loot rng can make them differ.
        game.beginAdventure(woods, rng: Random(1));
        hauls.add((await game.winEncounter(remainingHp: 90)).join(','));
      }
      expect(
        hauls.length,
        greaterThan(1),
        reason: 'forty kills produced one identical haul — the seed is fixed',
      );
    });

    test('rollDrops with no rng draws from the shared lootRng, and it moves',
        () {
      // ⭐ The production call shape after the audit: no rng at all, so
      // `lootRng` supplies it. 🚫 Kills a default that hands back a *fresh*
      // `Random()` each call on a backend where that could correlate, and
      // kills a `lootRng` accidentally declared `Random(<literal>)`.
      final drops = WhisperingWoodsBestiary.heartwood.drops;
      final hauls = <String>{};
      for (var i = 0; i < 200; i++) {
        hauls.add(rollDrops(drops).slots.map((s) => s.defId).join(','));
      }
      expect(hauls.length, greaterThan(1),
          reason: 'the default rng is stuck — 200 kills, one haul');
    });

    test('one Random instance carries an encounter, and keeps advancing', () {
      // ⭐ Sharing an rng across a kill's rolls is correct and cheap. What is
      // NOT correct is re-seeding per roll, which this catches: the same seed
      // handed to two calls must not be re-created between them.
      final rng = Random(555);
      final drops = WhisperingWoodsBestiary.heartwood.drops;
      final first = rollDrops(drops, rng).slots.map((s) => s.defId).join(',');
      var differed = false;
      for (var i = 0; i < 20 && !differed; i++) {
        differed =
            rollDrops(drops, rng).slots.map((s) => s.defId).join(',') != first;
      }
      expect(
        differed,
        isTrue,
        reason: 'a shared Random produced 21 identical hauls — it is stuck',
      );
    });
  });

  // ------------------------------------------------------------------------
  // The deep audit (2026-08-17): "the Epic three runs running".
  // ------------------------------------------------------------------------
  //
  // ⭐ **Why this exists when `_mainHistogram` already says 10%.** That test
  // rolls the boss table in isolation, from ONE seeded `Random`. The player's
  // Epic does not come out of a table in isolation — it comes out of a rolled
  // run, walked to its last encounter, drawn with whatever rng production
  // hands over. Every step between those two is a place a bias could hide:
  // a run that picks the boss non-uniformly, a `current` that points at the
  // wrong encounter, an rng that is re-created per kill.
  //
  // ⚠️ **Unseeded on purpose.** A seeded version of this test would answer a
  // different question. The tolerance below is set so wide that an unseeded
  // run cannot flake, and still far narrower than any bias worth reporting.
  group('the FULL production chain pays the Epic at its declared 10%', () {
    /// ~5.7σ at p=0.10 over [_n] draws (σ≈0.21 points), so a false failure is
    /// about 1 in 10^8 — while still catching anything at 11.2% or above. The
    /// streak that prompted this audit would need ~25%.
    const liveTolerance = 0.012;

    /// Walks a freshly rolled Whispering Woods run to its boss and rolls that
    /// kill's drops through [roll], returning what came out.
    ///
    /// ⚠️ The chain is the real one end to end: `AdventureRun.roll` with the
    /// real roster (as `GameState.beginAdventure` does), `recordVictory` per
    /// win (as `GameState.winEncounter` does), and `run.current!.def.drops`
    /// as the table (the exact expression `winEncounter` passes).
    Loot bossKill(Loot Function(DropTable) roll) {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: Bestiary.forZone('whispering_woods'),
        playerHp: 100,
        // ⚠️ Unseeded, exactly as `beginAdventure` builds it.
        rng: Random(),
      );
      while (!run.atBoss && !run.isFinished && !run.isOver) {
        run.recordVictory(
          loot: const <InventorySlot>[],
          instances: const {},
          remainingHp: 100,
        );
      }
      final loot = roll(run.current!.def.drops);
      run.recordVictory(
        loot: loot.slots,
        instances: loot.instances,
        remainingHp: 100,
      );
      return loot;
    }

    void auditEpicRate(String shape, Loot Function(DropTable) roll) {
      var epics = 0;
      var kills = 0;
      for (var i = 0; i < _n; i++) {
        final loot = bossKill(roll);
        kills++;
        // ⚠️ `any`, not a count: the stave sits only in `main`, so a kill that
        // produced two would itself be the bug (a table rolled twice).
        expect(
          loot.slots.where((s) => s.defId == 'heartwood_stave').length,
          lessThan(2),
          reason: 'one kill produced two staves — the main table rolled twice',
        );
        if (loot.slots.any((s) => s.defId == 'heartwood_stave')) epics++;
      }
      expect(kills, _n, reason: 'a run failed to reach its boss');
      _expectRate(epics, 0.10, 'heartwood_stave over $shape', liveTolerance);
    }

    test('a fresh unseeded Random per kill — the shape production ships today',
        () {
      // 🚫 Kills the whole reported hypothesis: if per-kill `Random()`
      // construction correlated on any backend we build for, 20k of them in a
      // tight loop is the very worst case for it, and this is where it shows.
      auditEpicRate('20k live boss kills, fresh Random() each',
          (table) => rollDrops(table, Random()));
    });

    test('the shared lootRng — the shape production ships after the audit', () {
      auditEpicRate(
          '20k live boss kills, one shared lootRng', (table) => rollDrops(table));
    });

    test('every rolled run ends on a boss, and both bosses share one table',
        () {
      // ⚠️ The audit above is only about `heartwood_stave` if the walk really
      // lands on a boss table. Whispering Woods has two bosses and the roll
      // shuffles them, so BOTH must carry the stave at 10% or the rate the
      // player experiences is a blend of two different numbers.
      final bosses = Bestiary.forZone('whispering_woods')
          .where((e) => e.rank == EnemyRank.boss);
      expect(bosses.length, 2);
      for (final b in bosses) {
        expect(b.drops.mainChanceOf('heartwood_stave'), 0.10,
            reason: '${b.id} pays the Epic at a different rate');
      }
    });
  });

  // ------------------------------------------------------------------------
  // The mote economy (ruling, 2026-08-17): Dust routine, Shards uncommon.
  // ------------------------------------------------------------------------
  //
  // ⭐ **Why a whole-run simulation and not weight assertions.** The player's
  // complaint — "Shards are everywhere, Dust is useless" — is about what a
  // *visit to a zone* hands over, and no single table answers that. A Primal
  // run is 6 commons, 2 minis and a boss (`commonsPerSectionFor`), and the
  // Shards were coming almost entirely from the two elevated ranks' `always`
  // buckets, which carry no weights at all. Counting weights would have
  // declared victory while the glut sat untouched.
  group('the mote economy pays Dust routinely and Shards rarely', () {
    /// Walks one whole seeded run of [zoneId] and tallies every mote it paid.
    Map<String, int> runHaul(String zoneId, Random rng) {
      final run = AdventureRun.roll(
        zone: World.byId(zoneId),
        roster: Bestiary.forZone(zoneId),
        playerHp: 100,
        rng: rng,
      );
      final tally = <String, int>{};
      while (!run.isOver && !run.isFinished) {
        final loot = rollDrops(run.current!.def.drops, rng);
        for (final s in loot.slots) {
          tally[s.defId] = (tally[s.defId] ?? 0) + 1;
        }
        run.recordVictory(
          loot: loot.slots,
          instances: loot.instances,
          remainingHp: 100,
        );
      }
      return tally;
    }

    /// Motes per run of [zoneId], averaged over 4000 seeded runs.
    Map<String, double> perRun(String zoneId, int seed) {
      const runs = 4000;
      final rng = Random(seed);
      final total = <String, int>{};
      for (var i = 0; i < runs; i++) {
        runHaul(zoneId, rng).forEach((k, v) {
          total[k] = (total[k] ?? 0) + v;
        });
      }
      return {for (final e in total.entries) e.key: e.value / runs};
    }

    /// ⚠️ Sums both ladders on a hybrid — the ruling is about the mote TIER,
    /// and a hybrid splitting its income two ways must not read as "fixed".
    double sumOf(Map<String, double> haul, String tier) => haul.entries
        .where((e) => e.key.endsWith('_$tier'))
        .fold(0.0, (a, e) => a + e.value);

    const zones = {
      'whispering_woods': 11,
      'glimmerbrook': 22,
      'cinderpeak_foothills': 33,
      'thornmire': 44,
      'ashfall_vale': 55,
    };

    for (final entry in zones.entries) {
      test('${entry.key}: a run brings home ≥4 Dust for every Shard', () {
        // 🚫 Kills a partial revert — restoring any one of the mini `1–3`,
        // the boss `3–6`, or the commons' old weights drags this back under 4.
        // ⭐ Before the ruling this ratio was **0.7 Dust per Shard**; the
        // ladder read backwards, which is exactly what the player felt.
        final haul = perRun(entry.key, entry.value);
        final dust = sumOf(haul, 'dust');
        final shards = sumOf(haul, 'shard');
        expect(shards, greaterThan(0),
            reason: '${entry.key} stopped paying Shards entirely — the ruling '
                'made them uncommon, not extinct');
        expect(
          dust / shards,
          greaterThan(4),
          reason: '${entry.key} pays ${dust.toStringAsFixed(2)} Dust to '
              '${shards.toStringAsFixed(2)} Shards per run — Dust is supposed '
              'to be the routine mote',
        );
      });
    }

    test('an elevated rank still owes a Shard, and only it pays Crystal', () {
      // ⚠️ Cutting the bands must not have cut what the ladder *promises*.
      // ⭐ The promise is "one Shard per elevated kill", and a hybrid keeps it
      // by splitting the chance across its two ladders rather than paying two
      // Shards — the same trade its Crystals already make (0.15 + 0.15 against
      // a pure zone's 0.25). Summing `chance` is therefore the invariant, not
      // "every entry is guaranteed": a hybrid mini would fail that and be
      // right to. A boss owes one of EACH ladder outright, again matching how
      // it guarantees every Crystal it carries.
      for (final zoneId in zones.keys) {
        for (final e in Bestiary.forZone(zoneId)) {
          final shards =
              e.drops.always.where((d) => d.defId?.endsWith('_shard') == true);
          final owed = shards.fold(0.0, (a, d) => a + d.chance);
          final crystals =
              e.drops.possibleDrops.where((id) => id.endsWith('_crystal'));
          switch (e.rank) {
            case EnemyRank.common:
              expect(crystals, isEmpty, reason: '${e.id} hands out Crystal');
            case EnemyRank.mini:
              expect(owed, closeTo(1, 1e-9),
                  reason: '${e.id} owes $owed Shards a kill, not one');
              expect(crystals, isNotEmpty, reason: '${e.id} lost its Crystal');
            case EnemyRank.boss:
              expect(shards.every((d) => d.chance >= 1), isTrue,
                  reason: '${e.id} put a Shard behind a dice roll');
              expect(crystals, isNotEmpty, reason: '${e.id} lost its Crystal');
          }
        }
      }
    });

    test('every main table still sums to 100 after the reweighting', () {
      // 🚫 Kills the arithmetic slip this rebalance invites: moving weight off
      // a Shard and onto a Dust is two edits, and dropping one of them changes
      // every *other* slot's percentage on that table silently.
      for (final zoneId in zones.keys) {
        for (final e in Bestiary.forZone(zoneId)) {
          expect(e.drops.totalWeight, 100,
              reason: '${e.id} main table sums to ${e.drops.totalWeight}');
        }
      }
    });

    test('no main table sells a Shard more often than the Dust beside it', () {
      // ⭐ The ruling, stated as an invariant a future author trips over
      // rather than a set of numbers they have to look up.
      for (final zoneId in zones.keys) {
        for (final e in Bestiary.forZone(zoneId)) {
          for (final shard in e.drops.main.where(
            (d) => d.defId?.endsWith('_shard') == true,
          )) {
            final element = shard.defId!.split('_').first;
            final dust = e.drops.main
                .where((d) => d.defId == '${element}_dust')
                .fold(0, (a, d) => a + d.weight);
            expect(dust, greaterThan(shard.weight),
                reason: '${e.id} sells $element Shards at weight '
                    '${shard.weight} against $dust of Dust');
          }
        }
      }
    });
  });

  group('a kill rolls its drops exactly once', () {
    test('what winEncounter reports is what the run banked — no second roll',
        () async {
      // 🚫 Kills an end screen (or anything downstream) that rolls its own
      // copy of the haul to display: the reported list and the banked list
      // would then be two independent draws and diverge within a few kills.
      // That divergence is also the only way a "10%" table could feel like
      // 20% — two rolls per kill doubles every chase slot.
      final game = GameState(_MemStorage(), PlayerProfile.newPlayer());
      await game.beginAdventure(World.byId('whispering_woods'), rng: Random(9));
      final reported = <String>[];
      while (game.run != null && !game.run!.isOver && !game.run!.isFinished) {
        reported.addAll(await game.winEncounter(remainingHp: 90));
      }
      // (2026-08-17 model: unanswered victory drops accumulate on
      // run.unclaimed until the picker claims them — this walk never claims,
      // so the whole haul is still there to compare.)
      final banked = [for (final s in game.run!.unclaimed) s.defId];
      expect(
        (reported..sort()).join(','),
        (banked..sort()).join(','),
        reason: 'the run banked a different haul than the screen was shown',
      );
      expect(reported, isNotEmpty, reason: 'the walk rolled nothing at all');
    });
  });
}

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;

  @override
  Future<PlayerProfile?> load() async => stored;

  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;

  @override
  Future<void> clear() async => stored = null;
}
