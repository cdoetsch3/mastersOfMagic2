import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/active_trip.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/travel.dart';

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

void main() {
  final noon = DateTime.utc(2026, 1, 1, 12);
  late DateTime clock;
  DateTime now() => clock;

  setUp(() => clock = noon);

  GameState fresh() =>
      GameState(_MemStorage(), PlayerProfile.newPlayer(), now: now);

  group('a trip is a function of the clock', () {
    ActiveTrip tripTo(String to) =>
        ActiveTrip.fromRoute(Travel.route('aldermere', to)!, noon);

    test('cumulative times line up with the route', () {
      final trip = tripTo('rimeholt');
      expect(trip.stops.length, trip.secondsAtStop.length);
      expect(trip.secondsAtStop.first, 0);
      expect(trip.totalMinutes, Travel.minutesBetween('aldermere', 'rimeholt'));
      expect(
        trip.totalSeconds,
        Travel.minutesBetween('aldermere', 'rimeholt')! * 60,
      );
      for (var i = 1; i < trip.secondsAtStop.length; i++) {
        expect(trip.secondsAtStop[i], greaterThan(trip.secondsAtStop[i - 1]));
      }
    });

    test('you are where the elapsed time says you are', () {
      final trip = tripTo('rimeholt');
      expect(trip.stopReachedAt(noon), 'aldermere');
      expect(
        trip.stopReachedAt(noon.add(const Duration(minutes: 1))),
        'aldermere',
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
      final route = Travel.route('aldermere', 'rimeholt')!;
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
      // ⭐ The design's collapse (§4b.1): the ~39-minute climb to Rimeholt is
      // minutes, not seconds shaved. A whole-minute model could not express
      // this — every leg would round up to a minute of its own.
      expect(onFoot.totalMinutes, 39);
      expect(mounted.totalMinutes, 4);
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
      expect(game.profile.locationId, 'aldermere');
      expect(game.currentLocationId, 'aldermere');
    });

    test('you arrive when the clock says so, not before', () async {
      final game = fresh();
      await game.beginTravel('whispering_woods');
      final total = game.profile.trip!.totalSeconds;

      clock = noon.add(Duration(seconds: total - 1));
      expect(game.isTravelling, isTrue);
      expect(game.profile.locationId, 'aldermere');

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
      expect(await game.beginTravel('aldermere'), isFalse);
      expect(await game.beginTravel('atlantis'), isFalse);
      expect(game.isTravelling, isFalse);
    });

    test('long trips are point to point, not neighbour by neighbour', () async {
      final game = fresh();
      expect(await game.beginTravel('rimeholt'), isTrue);
      final trip = game.profile.trip!;
      expect(trip.stops.length, greaterThan(2));
      expect(trip.toId, 'rimeholt');
      expect(trip.totalMinutes, Travel.minutesBetween('aldermere', 'rimeholt'));
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
        clock = noon.add(const Duration(seconds: 30));
        await game.cancelTravel();
        expect(game.profile.locationId, 'aldermere');
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
      expect(game.profile.locationId, 'aldermere');
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
}
