import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';

/// ⭐ **Difficulty ascends along the forced route** (ruling, Christian
/// 2026-09-21).
///
/// A band that drops as you walk away from town is not a difficulty curve, it
/// is a pothole: the player is made to fight 23-28 content to reach 17-22
/// content, and the zone they arrive at is trivial by the time they get there.
/// Two places in the shipped graph did exactly that — Forgeholm's only way on
/// was Thunderspire Peaks at 23-28 with three *lower* zones behind it, and
/// Hallowmarch (45-49) reached The Umbral Wastes (47-51) through the Reliquary
/// Deep (52-56). Both are re-banded/re-routed; this file is what stops a third.
///
/// ⚠️ **"Outward" has to be defined, or the rule is unusable.** The road
/// network is a web, not a tree: every zone has a way back, and a way back is
/// *supposed* to descend. So the walk below only follows edges that lead
/// strictly further from Hearthwood — one more leg of road than the place it
/// left. Return roads, loops and side doors are all edges that do not increase
/// that distance, and none of them is a promise about difficulty.
///
/// 📝 Hearthwood is the origin because it is where every mage starts and the
/// only place the graph has that is not reached *through* something else.
void main() {
  final byId = {for (final l in World.locations) l.id: l};

  /// Legs of road between Hearthwood and everywhere else, walked over the
  /// whole graph — towns included, because the road runs through them.
  Map<String, int> hopsFromHearthwood() {
    final hops = <String, int>{World.startLocationId: 0};
    final queue = <String>[World.startLocationId];
    for (var head = 0; head < queue.length; head++) {
      final here = queue[head];
      for (final c in byId[here]!.connections) {
        if (hops.containsKey(c)) continue;
        hops[c] = hops[here]! + 1;
        queue.add(c);
      }
    }
    return hops;
  }

  String describe(List<String> path) => [
    for (final id in path)
      byId[id]!.isTown
          ? byId[id]!.name
          : '${byId[id]!.name} (${byId[id]!.minLevel}-${byId[id]!.maxLevel})',
  ].join(' → ');

  group('the bands climb along the forced route', () {
    test('no road out of a town ever drops to an easier band', () {
      final hops = hopsFromHearthwood();
      final failures = <String>[];

      // Walks outward from [path]'s last zone. No visited set is needed: a
      // step is only taken when it increases the distance from Hearthwood, so
      // the walk cannot revisit and every path it builds is simple.
      void walkOn(List<String> path) {
        final here = byId[path.last]!;
        for (final nextId in here.connections) {
          final there = byId[nextId]!;
          if (there.isTown) continue; // a town is the end of a road out.
          if (hops[nextId] != hops[path.last]! + 1) continue; // not outward.
          if (there.minLevel < here.minLevel) {
            failures.add(describe([...path, nextId]));
            continue; // one report per pothole, not one per path beyond it.
          }
          walkOn([...path, nextId]);
        }
      }

      for (final town in World.towns) {
        for (final first in town.connections) {
          if (byId[first]!.isTown) continue;
          walkOn([town.id, first]);
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'these roads lead AWAY from town into an EASIER band — the '
            'player is made to clear the harder zone to reach the softer '
            'one:\n  ${failures.join("\n  ")}',
      );
    });

    test('the walk is not vacuous — it really does cross the whole world', () {
      // ⚠️ Kills the mutant that makes the guard above pass by walking
      // nowhere: tighten "outward" by one step too far and every failure
      // disappears along with every check.
      final hops = hopsFromHearthwood();
      var outwardSteps = 0;
      for (final l in World.locations) {
        if (l.isTown) continue;
        for (final c in l.connections) {
          if (byId[c]!.isTown) continue;
          if (hops[c] == hops[l.id]! + 1) outwardSteps++;
        }
      }
      expect(
        outwardSteps,
        greaterThanOrEqualTo(8),
        reason:
            'only $outwardSteps zone-to-zone step(s) count as outward — the '
            'band guard would be checking almost nothing',
      );
    });
  });

  group('the two places the ruling moved', () {
    test('Thunderspire is the low road out of Forgeholm, Stormcliff the high '
        'one', () {
      final thunderspire = byId['thunderspire_peaks']!;
      final stormcliff = byId['stormcliff_coast']!;

      expect(
        [thunderspire.minLevel, thunderspire.maxLevel],
        [17, 22],
        reason:
            'kills the mutant that puts Thunderspire back at 23-28, above '
            'everything Forgeholm opens onto',
      );
      expect(
        [stormcliff.minLevel, stormcliff.maxLevel],
        [23, 28],
        reason: 'kills the mutant that leaves Stormcliff at 17-22',
      );

      // ⭐ The swap is only a swap if the two bands trade places — a mutant
      // that lowers both, or raises both, breaks the quarter's ceiling.
      expect(
        thunderspire.maxLevel,
        lessThan(stormcliff.minLevel),
        reason: 'the coast is now strictly the harder of the pair',
      );
      expect(
        byId['forgeholm']!.connections,
        contains('thunderspire_peaks'),
        reason: "Forgeholm's way on is what the re-band exists to fix",
      );
    });

    // 📝 2026-09-30 (playtest note 1, "simplify the map"): the Hallowmarch ↔
    // Umbral Wastes road was cut as a duplicate — both already touch
    // Vespergate. The 2026-09-21 point of this test survives intact: the
    // Reliquary is still the TOP of the north road, behind the Wastes, and
    // no level-45 road opens onto it.
    test('the Umbral Wastes sit between Vespergate and the Reliquary', () {
      expect(
        byId['hallowmarch']!.connections,
        ['rimeholt', 'vespergate', 'the_sealed_garden'],
        reason:
            'kills the mutant that puts the Hallowmarch → Reliquary Deep '
            'short cut back (a level-45 road opening on 52-56 content), and '
            'the one that restores the Hallowmarch → Umbral Wastes road the '
            '2026-09-30 ruling cut',
      );
      expect(
        byId['the_umbral_wastes']!.connections,
        ['the_reliquary_deep', 'vespergate'],
        reason:
            'kills the mutant that drops the Vespergate road — since '
            '2026-09-30 it is the only way into the Wastes',
      );
      expect(
        byId['the_reliquary_deep']!.connections,
        ['the_umbral_wastes'],
        reason:
            'the Reliquary is the top of this road and is entered from the '
            'dark face only',
      );

      // ⚠️ Durations were deliberately NOT retuned by either ruling — only
      // the shape of the road changed.
      for (final pair in [
        ['vespergate', 'the_umbral_wastes'],
        ['the_umbral_wastes', 'the_reliquary_deep'],
      ]) {
        expect(
          byId[pair[0]]!.edgeTo(pair[1])?.minutes,
          8,
          reason: '${pair[0]} → ${pair[1]} should still be an 8-minute leg',
        );
      }
    });
  });

  group('the re-route strands nobody', () {
    test('every location is still reachable on foot from Hearthwood', () {
      final reached = hopsFromHearthwood().keys.toSet();
      final stranded = byId.keys.toSet().difference(reached);
      expect(
        stranded,
        isEmpty,
        reason:
            'dropping the Hallowmarch → Reliquary Deep edge must not cut '
            'anything off: ${stranded.join(", ")}',
      );
    });

    test(
      'the three proof zones are still found without passing Pennycross',
      () {
        // ⚠️ The Primal gate's keys must stay in front of the gate. Re-stated
        // here because a band-driven re-route is exactly the kind of edit that
        // would break it by accident; `test/world_test.dart` owns the canonical
        // version.
        final seen = <String>{World.startLocationId};
        final queue = <String>[World.startLocationId];
        while (queue.isNotEmpty) {
          for (final c in byId[queue.removeLast()]!.connections) {
            if (c == 'pennycross') continue;
            if (seen.add(c)) queue.add(c);
          }
        }
        for (final zone in [
          'whispering_woods',
          'glimmerbrook',
          'cinderpeak_foothills',
        ]) {
          expect(
            seen,
            contains(zone),
            reason: '$zone is now behind the gate its own proof opens',
          );
        }
      },
    );
  });

  // ⭐ **The wood ladder follows the bands** (ruling, Christian 2026-09-30,
  // playtest note 9). The 2026-09-21 re-band put Thunderspire Peaks (17-22)
  // below Windward Steppe (19-24), but the logs kept their old ladder:
  // Thunderspire's Rowan was tier 4 and Windward's Yew tier 3. The ruling
  // re-tiers the logs, and the gear's `value`s follow their logs (same-day
  // follow-up); nothing else moved.
  group('the wood ladder follows the bands (2026-09-30)', () {
    /// The zone whose gather node yields [logId]: where the log comes from,
    /// read from the content rather than restated here.
    GameLocation homeOf(String logId) {
      final zones = {
        for (final n in GatherNodes.all)
          if (n.yieldsDefId == logId) n.zoneId,
      };
      expect(
        zones,
        hasLength(1),
        reason: 'precondition: $logId is gathered in exactly one zone',
      );
      return byId[zones.single]!;
    }

    test("yew_log's tier is above rowan_log's, matching the zone bands", () {
      final rowan = ItemCatalogue.byId('rowan_log') as MaterialDef;
      final yew = ItemCatalogue.byId('yew_log') as MaterialDef;
      final rowanZone = homeOf('rowan_log');
      final yewZone = homeOf('yew_log');

      expect(
        (rowanZone.id, yewZone.id),
        ('thunderspire_peaks', 'windward_steppe'),
        reason: 'precondition: the logs are where the ruling says they are',
      );
      expect(
        yewZone.minLevel,
        greaterThan(rowanZone.minLevel),
        reason:
            'precondition: Windward Steppe sits above Thunderspire since '
            'the 2026-09-21 re-band, which is what the ruling follows',
      );
      expect(
        yew.tier,
        greaterThan(rowan.tier),
        reason:
            'kills the mutant that swaps the tiers back (Rowan 4, Yew 3): '
            'the higher-band zone must drop the higher-tier log',
      );
      expect(
        yew.value,
        greaterThan(rowan.value),
        reason:
            'kills the mutant that swaps the tiers but leaves the values '
            'behind: the value moves with the tier',
      );
      expect(
        [(rowan.tier, rowan.value), (yew.tier, yew.value)],
        [(3, 58), (4, 120)],
        reason:
            'the ruling\'s exact figures: the two logs trade tier AND value '
            'wholesale (Rowan 4/120 → 3/58, Yew 3/58 → 4/120), nothing '
            're-derived',
      );
    });
  });
}
