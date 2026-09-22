import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/active_trip.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/game/world.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  int writes = 0;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async {
    writes++;
    stored = profile;
  }

  @override
  Future<void> clear() async => stored = null;
}

/// A mage who has beaten every zone's boss.
///
/// ⚠️ **Needed since the passage ruling (Christian, 2026-09-21): you cannot
/// travel THROUGH a node you have not cleared.** The trips below are chosen
/// for their *shape* — several legs, a stop to cancel at — and a character who
/// had cleared nothing could not legally start one, so every timing assertion
/// here would quietly become an assertion about the refusal. The rule itself
/// is owned by `passage_test.dart`.
PlayerProfile _veteran() {
  final profile = PlayerProfile.newPlayer();
  for (final l in World.locations) {
    if (!l.isTown) profile.zoneClears[l.id] = 1;
    // ⚠️ …and every guarded gate stands open (Pennycross's proofs, Rimeholt's
    // totem) — a veteran has shown them all once.
    if (l.gateItemIds.isNotEmpty) profile.openedGates.add(l.id);
  }
  return profile;
}

void main() {
  final noon = DateTime.utc(2026, 1, 1, 12);
  late DateTime clock;
  DateTime now() => clock;

  setUp(() => clock = noon);

  GameState fresh() => GameState(_MemStorage(), _veteran(), now: now);

  group('a trip is a function of the clock', () {
    ActiveTrip tripTo(String to) =>
        ActiveTrip.fromRoute(Travel.route('hearthwood', to)!, noon);

    test('cumulative times line up with the route', () {
      final trip = tripTo('rimeholt');
      expect(trip.stops.length, trip.secondsAtStop.length);
      expect(trip.secondsAtStop.first, 0);
      // ⭐ Seconds are the source of truth; minutes are a rounded-up view of
      // them. Asserting minutes*60 would break the moment a leg is shorter
      // than a minute, which it is while testing.
      expect(
        trip.totalSeconds,
        Travel.secondsBetween('hearthwood', 'rimeholt'),
      );
      expect(
        trip.totalMinutes,
        Travel.minutesBetween('hearthwood', 'rimeholt'),
      );
      for (var i = 1; i < trip.secondsAtStop.length; i++) {
        expect(trip.secondsAtStop[i], greaterThan(trip.secondsAtStop[i - 1]));
      }
    });

    test('you are where the elapsed time says you are', () {
      final trip = tripTo('rimeholt');
      expect(trip.stopReachedAt(noon), 'hearthwood');
      // ⚠️ Just short of the first leg, not a fixed minute — a leg can be
      // seconds long while testing.
      expect(
        trip.stopReachedAt(
          noon.add(Duration(seconds: trip.secondsAtStop[1] - 1)),
        ),
        'hearthwood',
      );

      // Exactly at the second stop's time, you have reached it.
      final second = trip.secondsAtStop[1];
      expect(
        trip.stopReachedAt(noon.add(Duration(seconds: second))),
        trip.stops[1],
      );
      expect(trip.stopReachedAt(trip.arrivesAt), 'rimeholt');
    });

    test('a clock that runs backwards cannot lengthen a trip', () {
      // ⚠️ Without clamping, a device clock jumping back makes the journey get
      // *longer* the longer you wait, which reads as the game being broken.
      final trip = tripTo('pennycross');
      final before = noon.subtract(const Duration(days: 1));
      expect(trip.elapsedAt(before), Duration.zero);
      expect(trip.remainingAt(before), Duration(seconds: trip.totalSeconds));
      expect(trip.isCompleteAt(before), isFalse);
    });

    test('waiting past arrival does not overshoot', () {
      final trip = tripTo('pennycross');
      final late = trip.arrivesAt.add(const Duration(days: 3));
      expect(trip.elapsedAt(late), Duration(seconds: trip.totalSeconds));
      expect(trip.remainingAt(late), Duration.zero);
      expect(trip.progressAt(late), 1);
      expect(trip.legAt(late), isNull);
    });

    test('a mount shortens every leg, and never to nothing', () {
      final route = Travel.route('hearthwood', 'rimeholt')!;
      final onFoot = ActiveTrip.fromRoute(route, noon);
      final mounted = ActiveTrip.fromRoute(
        route,
        noon,
        speedMultiplier: 10,
        mountId: 'eagle',
      );
      expect(mounted.totalSeconds, lessThan(onFoot.totalSeconds));
      expect(mounted.mountId, 'eagle');
      for (var i = 1; i < mounted.secondsAtStop.length; i++) {
        expect(
          mounted.secondsAtStop[i],
          greaterThan(mounted.secondsAtStop[i - 1]),
          reason: 'a leg must never become free, however fast the mount',
        );
      }
      // ⭐ The design's collapse (§4b.1): the climb to Rimeholt is minutes
      // saved, not seconds. A whole-minute model could not express this —
      // every leg would round up to a minute of its own.
      expect(
        onFoot.totalSeconds,
        route.legs.length * TravelTimes.perLegSeconds,
      );
      expect(
        mounted.totalSeconds,
        lessThan(onFoot.totalSeconds),
        reason: 'a mount must actually help',
      );
    });

    test('a trip survives a save and reload', () {
      final trip = tripTo('rimeholt');
      final back = ActiveTrip.fromJson(trip.toJson())!;
      expect(back.stops, trip.stops);
      expect(back.secondsAtStop, trip.secondsAtStop);
      expect(back.departedAt, trip.departedAt);
      expect(back.arrivesAt, trip.arrivesAt);
    });

    test('a save that makes no sense strands nobody', () {
      expect(ActiveTrip.fromJson(null), isNull);
      expect(ActiveTrip.fromJson({'stops': [], 'secondsAtStop': []}), isNull);
      expect(
        ActiveTrip.fromJson({
          'stops': ['a', 'b'],
          'secondsAtStop': [0],
          'departedAt': noon.toIso8601String(),
        }),
        isNull,
        reason: 'stops and times must agree',
      );
    });
  });

  group('travelling', () {
    test('departing does not move you', () async {
      final game = fresh();
      expect(await game.beginTravel('whispering_woods'), isTrue);
      expect(game.isTravelling, isTrue);
      expect(game.profile.locationId, 'hearthwood');
      expect(game.currentLocationId, 'hearthwood');
    });

    test('you arrive when the clock says so, not before', () async {
      final game = fresh();
      await game.beginTravel('whispering_woods');
      final total = game.profile.trip!.totalSeconds;

      clock = noon.add(Duration(seconds: total - 1));
      expect(game.isTravelling, isTrue);
      expect(game.profile.locationId, 'hearthwood');

      clock = noon.add(Duration(seconds: total));
      expect(game.isTravelling, isFalse);
      expect(game.profile.locationId, 'whispering_woods');
    });

    test('you arrive even if the app was closed the whole time', () async {
      // ⭐ The reason arrival is derived rather than scheduled: nothing had to
      // be running for this to happen.
      final storage = _MemStorage();
      final first = GameState(storage, PlayerProfile.newPlayer(), now: now);
      await first.beginTravel('whispering_woods');
      expect(storage.stored!.trip, isNotNull);

      clock = noon.add(const Duration(days: 1));
      final reopened = GameState(storage, storage.stored!, now: now);
      expect(reopened.profile.locationId, 'whispering_woods');
      expect(reopened.isTravelling, isFalse);
    });

    test('one trip at a time', () async {
      final game = fresh();
      expect(await game.beginTravel('whispering_woods'), isTrue);
      expect(await game.beginTravel('glimmerbrook'), isFalse);
      expect(game.profile.trip!.toId, 'whispering_woods');
    });

    test('you cannot travel to where you already are', () async {
      final game = fresh();
      expect(await game.beginTravel('hearthwood'), isFalse);
      expect(await game.beginTravel('atlantis'), isFalse);
      expect(game.isTravelling, isFalse);
    });

    test('long trips are point to point, not neighbour by neighbour', () async {
      final game = fresh();
      expect(await game.beginTravel('rimeholt'), isTrue);
      final trip = game.profile.trip!;
      expect(trip.stops.length, greaterThan(2));
      expect(trip.toId, 'rimeholt');
      expect(
        trip.totalMinutes,
        Travel.minutesBetween('hearthwood', 'rimeholt'),
      );
    });
  });

  group('cancelling', () {
    test('drops you at the LAST STOP REACHED, not back at the start', () async {
      // ⭐ The ruling: A -> B -> C -> D cancelled between B and C leaves you at
      // B, instantly. Turning back the whole way would make any long trip a
      // gamble nobody would take.
      final game = fresh();
      await game.beginTravel('rimeholt');
      final trip = game.profile.trip!;
      expect(trip.stops.length, greaterThan(3));

      // Somewhere between the second and third stop.
      final between = (trip.secondsAtStop[1] + trip.secondsAtStop[2]) ~/ 2;
      clock = noon.add(Duration(seconds: between));
      await game.cancelTravel();

      expect(game.isTravelling, isFalse);
      expect(game.profile.locationId, trip.stops[1]);
    });

    test(
      'cancelling before the first stop leaves you where you set out',
      () async {
        final game = fresh();
        await game.beginTravel('rimeholt');
        // ⚠️ Just short of the first stop, expressed against the trip rather
        // than a fixed 30 seconds — a leg can be shorter than that.
        clock = noon.add(
          Duration(seconds: game.profile.trip!.secondsAtStop[1] - 1),
        );
        await game.cancelTravel();
        expect(game.profile.locationId, 'hearthwood');
      },
    );

    test('everywhere passed is on your map afterwards', () async {
      final game = fresh();
      await game.beginTravel('rimeholt');
      final trip = game.profile.trip!;
      clock = noon.add(Duration(seconds: trip.secondsAtStop[2]));
      await game.cancelTravel();

      for (final id in trip.stops.take(3)) {
        expect(
          game.profile.discoveredLocationIds,
          contains(id),
          reason: 'cancelling must not strand you somewhere unseen',
        );
      }
    });

    test('cancelling when not travelling does nothing', () async {
      final game = fresh();
      await game.cancelTravel();
      expect(game.profile.locationId, 'hearthwood');
    });
  });

  test('settling costs no write when there is nothing to settle', () async {
    final storage = _MemStorage();
    final game = GameState(storage, PlayerProfile.newPlayer(), now: now);
    await game.beginTravel('whispering_woods');
    final writes = storage.writes;

    // ⚠️ The UI ticks this every second. It must not save every second.
    for (var i = 0; i < 5; i++) {
      await game.tick();
    }
    expect(storage.writes, writes);

    clock = noon.add(const Duration(hours: 1));
    await game.tick();
    expect(storage.writes, writes + 1);
  });

  /// ⭐ Ruling 2026-09-21: the countdown must reach 0:00 exactly when the bar
  /// reaches the end, so it CEILS the seconds. The trip itself is unchanged —
  /// these assertions are about the string, not about `arrivesAt`.
  group('formatRemaining rounds up so the clock lands with the bar', () {
    test('a fraction of a second still reads as a second', () {
      expect(
        formatRemaining(const Duration(milliseconds: 400)),
        '0:01',
        reason:
            'the bug itself: a floor prints 0:00 here while the bar still '
            'has 0.4 s of walking left',
      );
    });

    test('0:00 is reserved for actually having arrived', () {
      expect(
        formatRemaining(Duration.zero),
        '0:00',
        reason:
            'a naive ceil-then-add-one (or a +1 s applied to the duration) '
            'would print 0:01 at the very instant of arrival, so the clock '
            'would never show 0:00 at all',
      );
    });

    test('a whole number of seconds is not pushed up a step', () {
      expect(
        formatRemaining(const Duration(seconds: 61)),
        '1:01',
        reason:
            'ceil must be a no-op on an exact second — a +1 s implementation '
            'reads 1:02 here',
      );
    });

    test('the carry into the minute is computed after rounding', () {
      expect(
        formatRemaining(const Duration(milliseconds: 60500)),
        '1:01',
        reason:
            'a floor mutant says 1:00; a mutant that ceils the SECONDS field '
            'alone (60.5 s → 1 min + ceil(0.5 s)) happens to agree here but '
            'not at the 119.5 s case below',
      );
      expect(
        formatRemaining(const Duration(milliseconds: 119500)),
        '2:00',
        reason:
            'rounding up must carry into the minutes — 119.5 s is 120 s, and '
            'a per-field ceil prints 1:60',
      );
    });

    test('a clock nudged past arrival never prints a negative countdown', () {
      expect(
        formatRemaining(const Duration(seconds: -5)),
        '0:00',
        reason:
            'without the isNegative guard, ceil(-5) prints "0:-5"; '
            'remainingAt clamps, but this formatter is public and must not '
            'depend on its caller for that',
      );
    });

    test('an hour or more switches to Nh MMm, still rounded up', () {
      expect(
        formatRemaining(const Duration(minutes: 90)),
        '1h 30m',
        reason:
            'the long-haul shape survives the rewrite — a mm:ss-only '
            'formatter prints 90:00 for a mounted cross-map journey',
      );
      expect(
        formatRemaining(const Duration(milliseconds: 3599500)),
        '1h 00m',
        reason:
            'rounding up crosses the hour line: 3599.5 s is 3600 s, and a '
            'mutant testing the RAW duration against an hour prints 59:60',
      );
    });
  });
}
