import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/ui/travel_progress_card.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
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

  Future<GameState> pumpTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final game = GameState(_MemStorage(), _veteran(), now: now);
    await tester.pumpWidget(
      MaterialApp(
        home: GameStateScope(
          state: game,
          child: Scaffold(body: MapTab(onSelectTab: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return game;
  }

  testWidgets('the cost of a trip is visible before committing to it', (
    tester,
  ) async {
    await pumpTab(tester);
    // Hearthwood's neighbours are 3-minute walks.
    // ⭐ Whatever a leg currently costs, the trip must state it — the point is
    // that the price is visible, not that it is any particular number.
    expect(
      find.textContaining(
        TravelTimes.label(Travel.secondsBetween('hearthwood', 'pennycross')!),
      ),
      findsWidgets,
    );
  });

  testWidgets('a journey in progress is shown, and can be stopped', (
    tester,
  ) async {
    final game = await pumpTab(tester);
    await game.beginTravel('whispering_woods');
    await tester.pump();

    expect(
      find.textContaining('Travelling to Whispering Woods'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // ⭐ The button names where you end up, because cancelling drops you at
    // the last place reached rather than back at the start.
    expect(find.textContaining('Stop at Hearthwood'), findsOneWidget);

    await tester.tap(find.textContaining('Stop at Hearthwood'));
    await tester.pumpAndSettle();
    expect(game.isTravelling, isFalse);
    expect(game.profile.locationId, 'hearthwood');
    expect(find.textContaining('Travelling to'), findsNothing);
  });

  testWidgets('the countdown counts down', (tester) async {
    final game = await pumpTab(tester);
    await game.beginTravel('whispering_woods');
    await tester.pump();

    // ⭐ Expressed against the trip, not a fixed 3:00 — the per-leg duration
    // is a knob (TravelTimes.perLegSeconds) and a pinned clock face would
    // fail every time it is tuned.
    final total = game.profile.trip!.totalSeconds;
    String face(int secs) =>
        '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    expect(find.text(face(total)), findsOneWidget);

    clock = noon.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(face(total - 1)), findsOneWidget);

    // Let the ticker settle the arrival on its own.
    clock = noon.add(Duration(seconds: total + 60));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(game.profile.locationId, 'whispering_woods');
  });

  testWidgets('you cannot start a second journey while walking the first', (
    tester,
  ) async {
    final game = await pumpTab(tester);
    await game.beginTravel('whispering_woods');
    await tester.pump();

    // The travel cards are still listed — the map should not empty out —
    // but they no longer do anything.
    // ⚠️ Dragged from BELOW the map. A drag starting on the map pans the map
    // and deliberately does not scroll the page — see _MapTabState.
    await tester.dragFrom(const Offset(210, 820), const Offset(0, -400));
    await tester.pumpAndSettle();
    final card = find.textContaining('Glimmerbrook');
    expect(card, findsWidgets);
    await tester.tap(card.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(game.profile.trip!.toId, 'whispering_woods');
  });

  testWidgets('the card shows which leg you are on', (tester) async {
    final game = await pumpTab(tester);
    // A multi-leg trip so there is a leg to name.
    await game.beginTravel('forgeholm');
    await tester.pump();
    final trip = game.profile.trip!;
    expect(trip.stops.length, greaterThan(2));

    expect(find.textContaining('On the road from Hearthwood'), findsOneWidget);

    clock = noon.add(Duration(seconds: trip.secondsAtStop[1] + 5));
    await tester.pump(const Duration(seconds: 1));
    final second = World.byId(trip.stops[1]).name;
    expect(find.textContaining('On the road from $second'), findsOneWidget);
  });

  // ⭐ Ruling 2026-09-30 (note 12): a chained trip says what is still ahead.
  testWidgets('⭐ a chained trip names its next stop, then the rest', (
    tester,
  ) async {
    final game = await pumpTab(tester);
    await game.beginTravel('forgeholm');
    await tester.pump();
    final trip = game.profile.trip!;
    expect(trip.stops, [
      'hearthwood',
      'pennycross',
      'old_quarry',
      'forgeholm',
    ], reason: 'the premise: the four-stop chain');

    expect(
      find.text('Next: Pennycross · then Old Quarry, Forgeholm'),
      findsOneWidget,
      reason: 'kills a mutant that names only the destination',
    );
    expect(
      find.text('On the road from Hearthwood'),
      findsOneWidget,
      reason:
          'kills a mutant that names the next stop twice — the line below '
          'already says it',
    );

    clock = noon.add(Duration(seconds: trip.secondsAtStop[1] + 1));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Next: Old Quarry · then Forgeholm'),
      findsOneWidget,
      reason: 'kills a mutant that never moves on from the first leg',
    );

    clock = noon.add(Duration(seconds: trip.secondsAtStop[2] + 1));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Next: Forgeholm'),
      findsOneWidget,
      reason:
          'kills a mutant that drops the line on the last leg — the Stop '
          'button would jump up a line mid-journey',
    );
  });

  testWidgets('a single-leg trip is unchanged', (tester) async {
    final game = await pumpTab(tester);
    await game.beginTravel('whispering_woods');
    await tester.pump();
    expect(
      find.textContaining('Next:'),
      findsNothing,
      reason: 'kills a mutant that adds the line to every trip',
    );
    expect(
      find.text('On the road from Hearthwood to Whispering Woods'),
      findsOneWidget,
      reason: 'kills a mutant that shortens the single-leg line too',
    );
  });

  // ⭐ Ruling 2026-09-21: "it ends at 0:00 instead of the 0:00 hitting before
  // the bar reaches the end". Pumped against the CARD rather than the tab, so
  // the clock can sit a fraction of a second short of arrival — the tab's
  // ticker settles the trip on the next tick and takes the card with it.
  testWidgets('the clock reaches 0:00 only when the bar is full', (
    tester,
  ) async {
    final game = GameState(_MemStorage(), _veteran(), now: now);
    await game.beginTravel('whispering_woods');
    final arrivesAt = game.profile.trip!.arrivesAt;

    // A fresh widget instance each time: the card reads the clock in build,
    // and nothing else would ask it to rebuild at a chosen instant.
    Future<void> pumpAt(DateTime at) async {
      clock = at;
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: Scaffold(body: TravelProgressCard(game: game)),
          ),
        ),
      );
      await tester.pump();
    }

    double barValue() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await pumpAt(arrivesAt.subtract(const Duration(milliseconds: 300)));
    expect(
      find.text('0:01'),
      findsOneWidget,
      reason:
          'the floor mutant (the shipped behaviour before this ruling) reads '
          '0:00 here, 300 ms before arrival',
    );
    expect(
      barValue(),
      lessThan(1.0),
      reason:
          'and it reads it while the bar is still short of the end — the '
          'disagreement the ruling is about',
    );

    await pumpAt(arrivesAt);
    expect(
      find.text('0:00'),
      findsOneWidget,
      reason:
          'a fix that lengthened the TRIP by a second (rather than ceiling '
          'the display) would still read 0:01 at arrivesAt',
    );
    expect(
      barValue(),
      1.0,
      reason:
          'the bar and the clock must land on the same instant; this also '
          'pins that the fix did not move arrivesAt itself',
    );
    expect(
      game.profile.trip!.isCompleteAt(arrivesAt),
      isTrue,
      reason:
          'the trip is unchanged by a display rule — a +1 s added to the '
          'journey would leave it incomplete at its own arrivesAt',
    );
  });

  testWidgets('a drag below the map scrolls the page', (tester) async {
    // ⭐ The map sits inside the list and pans under your finger — verified on
    // device. That half is deliberately NOT asserted here: the gesture arena's
    // outcome depends on real pointer timing, and a synthetic drag either
    // dispatches every event before a frame renders (which no finger can do)
    // or resolves the arena differently than a real one. A test that fakes it
    // would be asserting the harness, not the app.
    //
    // What is worth pinning is the other half: away from the map, the page
    // still scrolls normally.
    await pumpTab(tester);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    await tester.dragFrom(const Offset(210, 820), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
