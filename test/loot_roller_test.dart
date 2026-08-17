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
import 'package:masters_of_magic_2/game/enemies/drop_table.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
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

void _expectRate(int observed, double expected, String what) {
  expect(
    observed / _n,
    closeTo(expected, _tolerance),
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
