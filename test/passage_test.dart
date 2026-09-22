/// You cannot travel **through** a node you have not cleared (playtest ruling,
/// Christian 2026-09-21).
///
/// > *"I shouldn't be able to travel through a node on the map if I haven't
/// > cleared it. I can travel to it, and I can travel back where I came from
/// > FROM it, but I shouldn't be able to travel to any other nodes through it
/// > until having beaten its boss at least once. For example, I'm in
/// > Pennycross, I shouldn't be able to get to Forgeholm without clearing Old
/// > Quarry."*
///
/// Three rules come out of that, and each has a mutant waiting for it:
///  * **through** — an uncleared stop in the MIDDLE of a point-to-point route
///    shuts the whole trip, which is the Pennycross → Forgeholm case;
///  * **to, and back** — an uncleared zone is a dead end you may enter, whose
///    one legal exit is the door you came in by;
///  * **cleared means the boss** — `zoneClears` > 0, never mere discovery.
///
/// ⚠️ Towns are never gates. `world_test.dart` holds the map facts this file
/// leans on (Old Quarry is the only road from Pennycross into the range).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/active_trip.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

final _noon = DateTime.utc(2026, 1, 1, 12);

/// A mage standing at [at], having walked in from [cameFrom], with [cleared]
/// zones behind them. ⚠️ `cameFrom: null` is the legacy-save shape on purpose.
///
/// ⚠️ [opened] is the **tier gate**, not this rule. Pennycross is gated, so a
/// character who genuinely walked Pennycross → Old Quarry has it in
/// `openedGates` already; a test that wants to walk back has to say so, or it
/// is testing the guard rather than the road.
GameState _standingIn(
  String at, {
  String? cameFrom,
  List<String> cleared = const [],
  List<String> opened = const [],
}) {
  final profile = PlayerProfile.newPlayer()
    ..locationId = at
    ..arrivedFromId = cameFrom;
  for (final id in cleared) {
    profile.zoneClears[id] = 1;
  }
  profile.openedGates.addAll(opened);
  return GameState(_Mem(), profile, now: () => _noon);
}

const _throughQuarry =
    'The road runs through Old Quarry, and you have not cleared it.';
const _backToPennycross =
    'Clear Old Quarry first, or go back the way you came (Pennycross).';
const _backToATown = 'Clear Old Quarry first, or go back to a town.';

void main() {
  group('the road through the quarry', () {
    test(
      '⭐ Pennycross to Forgeholm is refused, and names the quarry',
      () async {
        final g = _standingIn('pennycross');

        // The premise the ruling rests on: the quarry really is in the middle.
        expect(
          Travel.route('pennycross', 'forgeholm')!.stops,
          ['pennycross', 'old_quarry', 'forgeholm'],
          reason:
              'kills a mutant that reroutes around the quarry — every other '
              'assertion in this file would pass vacuously',
        );
        expect(
          g.passageRefusal('forgeholm'),
          _throughQuarry,
          reason:
              'kills a mutant that ignores intermediate stops, and one that '
              'prints the raw id instead of the place name',
        );
        expect(
          await g.travelTo('forgeholm'),
          _throughQuarry,
          reason: 'kills a mutant that checks passage but refuses silently',
        );
        expect(
          await g.beginTravel('forgeholm'),
          isFalse,
          reason:
              'kills a mutant that gates only travelTo — the world map goes '
              'straight to beginTravel',
        );
        expect(
          g.profile.trip,
          isNull,
          reason: 'kills a mutant that reports the refusal and departs anyway',
        );
      },
    );

    test('⭐ clearing the quarry opens the road behind it', () async {
      final g = _standingIn('pennycross', cleared: ['old_quarry']);

      expect(
        g.passageRefusal('forgeholm'),
        isNull,
        reason:
            'kills a mutant that never re-reads zoneClears — the boss would '
            'be beatable and Forgeholm still unreachable',
      );
      expect(
        await g.beginTravel('forgeholm'),
        isTrue,
        reason: 'kills a mutant that refuses a legal trip anyway',
      );
      expect(
        g.profile.trip?.toId,
        'forgeholm',
        reason: 'kills a mutant that returns true without starting the trip',
      );
    });

    test('⚠️ one clear is enough — the count is not a threshold', () {
      final g = _standingIn('pennycross');
      g.profile.zoneClears['old_quarry'] = 1;

      expect(
        g.passageRefusal('forgeholm'),
        isNull,
        reason:
            'kills a mutant that demands more than one clear, or that reads '
            '"cleared" as > 1 rather than > 0',
      );
    });

    test('⚠️ discovery is not clearing', () {
      final g = _standingIn('pennycross');
      g.profile.discoveredLocationIds.add('old_quarry');

      expect(
        g.passageRefusal('forgeholm'),
        _throughQuarry,
        reason:
            'kills a mutant that reads discoveredLocationIds — walking into '
            'the quarry is exactly what this rule stops being enough',
      );
    });

    test('travelling TO the uncleared quarry is always fine', () async {
      final g = _standingIn('pennycross');

      expect(
        g.passageRefusal('old_quarry'),
        isNull,
        reason:
            'kills a mutant that refuses the DESTINATION as well as the '
            'middle — "I can travel to it" is half the ruling',
      );
      expect(
        await g.beginTravel('old_quarry'),
        isTrue,
        reason: 'kills a mutant that shuts an uncleared zone off entirely',
      );
    });
  });

  group('standing in an uncleared zone', () {
    test('⭐ you may go back the way you came', () async {
      final g = _standingIn(
        'old_quarry',
        cameFrom: 'pennycross',
        opened: ['pennycross'],
      );

      expect(
        g.passageRefusal('pennycross'),
        isNull,
        reason:
            'kills a mutant that strands you — "I can travel back where I '
            'came from FROM it"',
      );
      expect(
        await g.travelTo('pennycross'),
        isNull,
        reason: 'kills a mutant that refuses the one legal exit',
      );
    });

    test('⭐ but not on to Forgeholm, nor down into the Molten Deep', () async {
      final g = _standingIn('old_quarry', cameFrom: 'pennycross');

      expect(
        g.passageRefusal('forgeholm'),
        _backToPennycross,
        reason:
            'kills a mutant that only checks INTERMEDIATE stops — the quarry '
            'is the origin here, so rule (a) can never see it',
      );
      expect(
        g.passageRefusal('the_molten_deep'),
        _backToPennycross,
        reason:
            'kills a mutant that allows any neighbour that is not the origin '
            'of the road you refused, rather than only the door you came in by',
      );
      expect(
        await g.beginTravel('the_molten_deep'),
        isFalse,
        reason: 'kills a mutant that gates only travelTo',
      );
      expect(
        g.profile.trip,
        isNull,
        reason: 'kills a mutant that returns false but departs anyway',
      );
    });

    test('⚠️ the exit is the door you came in by, not any neighbour', () {
      // Arrived from the Molten Deep instead: now THAT is the way back and
      // Pennycross is not. A mutant that reads "any town" passes the test
      // above and dies here.
      final g = _standingIn('old_quarry', cameFrom: 'the_molten_deep');

      expect(
        g.passageRefusal('the_molten_deep'),
        isNull,
        reason: 'kills a mutant that hard-codes Pennycross as the way back',
      );
      expect(
        g.passageRefusal('pennycross'),
        'Clear Old Quarry first, or go back the way you came '
        '(The Molten Deep).',
        reason:
            'kills a mutant that lets any TOWN out of an uncleared zone, and '
            'one that names the destination rather than the door you came in by',
      );
    });

    test('⭐ clearing it opens all three roads at once', () async {
      final g = _standingIn(
        'old_quarry',
        cameFrom: 'pennycross',
        cleared: ['old_quarry'],
      );

      for (final id in ['pennycross', 'forgeholm', 'the_molten_deep']) {
        expect(
          g.passageRefusal(id),
          isNull,
          reason:
              'kills a mutant that keeps the dead-end rule on a CLEARED zone '
              '— $id should be open once the boss has fallen',
        );
      }
      expect(
        await g.beginTravel('forgeholm'),
        isTrue,
        reason:
            'kills a mutant that reports the road open but will not walk it',
      );
    });

    test('⚠️ a town origin never refuses on its own account', () {
      // Pennycross has zero clears and always will — it has no boss. A mutant
      // that forgets `isTown` shuts every crossroads in the game.
      final g = _standingIn('pennycross', cleared: ['old_quarry']);

      for (final id in ['hearthwood', 'glimmerbrook', 'old_quarry']) {
        expect(
          g.passageRefusal(id),
          isNull,
          reason:
              'kills a mutant that treats a town as an uncleared node — a '
              'town has no boss, so $id would be unreachable forever',
        );
      }
    });

    test('⚠️ a town in the MIDDLE of a route is not a wall either', () {
      // Hearthwood → Pennycross → Old Quarry passes through a town with zero
      // clears. Rule (a) must let it by.
      final g = _standingIn('hearthwood', cleared: []);
      final stops = Travel.route('hearthwood', 'old_quarry')!.stops;

      expect(
        stops,
        contains('pennycross'),
        reason: 'the premise: a town really does sit in the middle here',
      );
      expect(
        g.passageRefusal('old_quarry'),
        isNull,
        reason:
            'kills a mutant that drops the isTown test in rule (a) — every '
            'route through a market town would close',
      );
    });
  });

  group('the door you came in by', () {
    test('⭐ settleTravel records the trip ORIGIN, not the last leg', () {
      // Pennycross → Old Quarry → Forgeholm, legal because the quarry is
      // cleared. Arriving in Forgeholm, the way back is PENNYCROSS.
      final profile = PlayerProfile.newPlayer()..locationId = 'pennycross';
      profile.zoneClears['old_quarry'] = 1;
      var clock = _noon;
      final g = GameState(_Mem(), profile, now: () => clock);

      final route = Travel.route('pennycross', 'forgeholm')!;
      expect(route.stops.length, 3, reason: 'the premise: a three-stop route');
      profile.trip = ActiveTrip.fromRoute(route, _noon);
      clock = _noon.add(const Duration(days: 1));

      expect(g.settleTravel(), isTrue, reason: 'the trip really did complete');
      expect(
        profile.arrivedFromId,
        'pennycross',
        reason:
            'kills a mutant that stores the last leg\'s start (old_quarry), '
            'the destination, or nothing at all',
      );
      expect(
        profile.locationId,
        'forgeholm',
        reason: 'kills a mutant that writes arrivedFromId over locationId',
      );
    });

    test('⚠️ an unfinished trip records nothing', () {
      final profile = PlayerProfile.newPlayer()..locationId = 'pennycross';
      var clock = _noon;
      final g = GameState(_Mem(), profile, now: () => clock);
      profile.trip = ActiveTrip.fromRoute(
        Travel.route('pennycross', 'old_quarry')!,
        _noon,
      );
      clock = _noon.add(const Duration(seconds: 1));

      expect(g.settleTravel(), isFalse, reason: 'still walking');
      expect(
        profile.arrivedFromId,
        isNull,
        reason:
            'kills a mutant that writes the field before arrival — you would '
            'be allowed out of a zone you have not reached',
      );
    });

    test('⭐ a real journey writes it end to end', () async {
      var clock = _noon;
      final profile = PlayerProfile.newPlayer()..locationId = 'pennycross';
      final g = GameState(_Mem(), profile, now: () => clock);

      await g.beginTravel('old_quarry');
      clock = _noon.add(const Duration(days: 1));
      await g.tick();

      expect(
        profile.locationId,
        'old_quarry',
        reason: 'the journey really completed',
      );
      expect(
        profile.arrivedFromId,
        'pennycross',
        reason:
            'kills a mutant that only sets the field in a direct settleTravel '
            'call and not on the UI ticker path',
      );
      expect(
        g.passageRefusal('pennycross'),
        isNull,
        reason:
            'kills a mutant whose recorded door does not match the one the '
            'passage rule reads — the player would be sealed in',
      );
    });

    test('⭐ arrivedFromId round-trips through JSON', () {
      final before = PlayerProfile.newPlayer()..arrivedFromId = 'pennycross';

      expect(
        PlayerProfile.fromJson(before.toJson()).arrivedFromId,
        'pennycross',
        reason:
            'kills a mutant that never writes the key, never reads it back, '
            'or writes it under a different name — the player would be sealed '
            'into an uncleared zone on their next launch',
      );
    });

    test('⚠️ a save from before the rule has no door recorded', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('arrivedFromId');

      expect(
        PlayerProfile.fromJson(json).arrivedFromId,
        isNull,
        reason:
            'kills a mutant that throws on the absent key, and one that '
            'defaults it to the start location',
      );
    });

    test('⚠️ a legacy save in an uncleared zone can still reach a town', () {
      final g = _standingIn('old_quarry');

      expect(
        g.profile.arrivedFromId,
        isNull,
        reason: 'the premise: this is the legacy shape',
      );
      expect(
        g.passageRefusal('pennycross'),
        isNull,
        reason:
            'kills a mutant that strands a legacy character in the quarry — '
            'a null door must never mean "no way out"',
      );
      expect(
        g.passageRefusal('the_molten_deep'),
        _backToATown,
        reason:
            'kills a mutant that reads a null door as "go anywhere", which '
            'would hand every legacy save the whole quarter for free',
      );
      expect(
        g.passageRefusal('forgeholm'),
        isNull,
        reason:
            'kills a mutant that refuses every destination on a null door — '
            'Forgeholm is a town, and a town is the fallback exit',
      );
    });
  });

  group('the gate still speaks first', () {
    test('⚠️ a missing proof is reported as a missing proof', () async {
      // Standing in the uncleared Whispering Woods, having come from
      // Hearthwood, with no proofs: BOTH rules refuse Pennycross. The guard's
      // sentence is the more specific one and must win.
      final g = _standingIn('whispering_woods', cameFrom: 'hearthwood');

      expect(
        g.passageRefusal('pennycross'),
        isNotNull,
        reason: 'the premise: the passage rule would refuse this too',
      );
      expect(
        await g.travelTo('pennycross'),
        startsWith('The guard wants three proofs'),
        reason:
            'kills a mutant that checks passage before the gate — the player '
            'would be told to clear a zone when what they need is three items',
      );
    });
  });

  group('the Map tab shows the wall', () {
    Future<void> pumpTab(WidgetTester tester, GameState game) async {
      // ⚠️ Tall on purpose, as in gate_test: the quarry's three travel cards
      // never lay out in a phone-height viewport.
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: Scaffold(body: MapTab(onSelectTab: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The card whose title is [name] — its `GamePanel` is what carries the tap.
    GamePanel cardFor(WidgetTester tester, String name) =>
        tester.widget<GamePanel>(
          find
              .ancestor(of: find.text(name), matching: find.byType(GamePanel))
              .first,
        );

    testWidgets('⭐ Forgeholm is disabled and says why', (tester) async {
      final g = _standingIn('old_quarry', cameFrom: 'pennycross');
      await pumpTab(tester, g);

      // ⭐ Two, not one: Forgeholm and the Molten Deep are both walled off,
      // and each card carries its own copy of the reason. A mutant that
      // prints the line once, above the list, fails here.
      expect(
        find.text(_backToPennycross),
        findsNWidgets(2),
        reason:
            'kills a mutant that disables the cards without printing the '
            'reason — a dead tile with no sentence reads as a bug — and one '
            'that only marks the first refused neighbour',
      );
      expect(
        cardFor(tester, 'Forgeholm').onTap,
        isNull,
        reason:
            'kills a mutant that prints the sentence but leaves the Travel '
            'button live, so the tap silently does nothing',
      );
      expect(
        cardFor(tester, 'The Molten Deep').onTap,
        isNull,
        reason: 'kills a mutant that blocks only the first refused neighbour',
      );
      expect(
        cardFor(tester, 'Pennycross').onTap,
        isNotNull,
        reason:
            'kills a mutant that disables every travel card — the way you '
            'came in must stay pressable',
      );
    });

    testWidgets('⚠️ a cleared quarry leaves no sentence behind', (
      tester,
    ) async {
      final g = _standingIn(
        'old_quarry',
        cameFrom: 'pennycross',
        cleared: ['old_quarry'],
      );
      await pumpTab(tester, g);

      expect(
        find.textContaining('Clear Old Quarry first'),
        findsNothing,
        reason:
            'kills a mutant that prints the refusal unconditionally, which '
            'would leave the wall on screen after the boss had fallen',
      );
      expect(
        cardFor(tester, 'Forgeholm').onTap,
        isNotNull,
        reason: 'kills a mutant that never re-enables the card',
      );
    });
  });
}
