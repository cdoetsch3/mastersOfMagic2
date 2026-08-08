import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/travel.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
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
    final game = GameState(_MemStorage(), PlayerProfile.newPlayer(), now: now);
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
