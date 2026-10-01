/// The Gather / Drops / Found-in lines on screen (ruling, Christian, playtest
/// 2026-09-30, note 3): the Map tab's current-location card and travel cards,
/// the world map's place sheet, and the item dialog.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — lines missing from a card, lines printed on a town, a travel card
/// that only reserves the cell when it has something to put in it (so the
/// cards below jump between a town neighbour and a zone neighbour), a line
/// left free to wrap on a travel card, and a found-in line printed for an
/// item nobody can find.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/provenance.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:masters_of_magic_2/ui/interactive_world_map.dart';
import 'package:masters_of_magic_2/ui/item_display.dart';

class _MemStorage implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// A player standing in Cinderpeak Foothills, whose roads lead to Hearthwood
/// (a town) and Ashfall Vale (a zone) — one card of each kind, side by side.
///
/// 📝 Was Whispering Woods → Thornmire until the 2026-09-30 map
/// simplification cut that road (WORLD_DESIGN §4b.7); the Woods now has a
/// town neighbour only. The Foothills have the same shape.
Future<void> _pumpMapTabInFoothills(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final profile = PlayerProfile.newPlayer()
    ..locationId = 'cinderpeak_foothills';
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: GameState(_MemStorage(), profile),
        child: Scaffold(body: MapTab(onSelectTab: (_) {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The travel card whose title is [name].
Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(GamePanel)).first;

Finder _inCard(String name, Finder f) =>
    find.descendant(of: _card(name), matching: f);

void main() {
  final foothills = World.byId('cinderpeak_foothills');
  final hearthwood = World.byId('hearthwood');
  final ashfall = World.byId('ashfall_vale');

  setUpAll(() {
    expect(
      foothills.connections,
      containsAll([hearthwood.id, ashfall.id]),
      reason: 'precondition: the test needs a town card and a zone card',
    );
    expect(
      (hearthwood.isTown, ashfall.isTown),
      (true, false),
      reason: 'precondition: one of each kind',
    );
  });

  group('the Map tab', () {
    testWidgets("the current location's card carries both lines", (
      tester,
    ) async {
      await _pumpMapTabInFoothills(tester);
      expect(
        find.text(Provenance.gatherLine(foothills)!),
        findsOneWidget,
        reason:
            'the Foothills\' gather line under its blurb — a current card '
            'without the lines fails here (the Foothills are nobody\'s '
            'neighbour here, so only that card can print it)',
      );
      expect(
        find.text(Provenance.dropsLine(foothills)!),
        findsOneWidget,
        reason: 'and its drops line',
      );
    });

    testWidgets('a zone travel card carries both lines; a town card neither', (
      tester,
    ) async {
      await _pumpMapTabInFoothills(tester);
      expect(
        _inCard(
          ashfall.name,
          find.text('Gather: Birch Log · Brookmint · Charcoal'),
        ),
        findsOneWidget,
        reason:
            'Ashfall Vale\'s three nodes — a travel card without the lines, '
            'or one reading the CURRENT location, fails here',
      );
      expect(
        _inCard(ashfall.name, find.textContaining('Drops: ')),
        findsOneWidget,
        reason: 'and its drops line',
      );
      expect(
        _inCard(hearthwood.name, find.textContaining('Gather: ')),
        findsNothing,
        reason: 'a town prints no gather line',
      );
      expect(
        _inCard(hearthwood.name, find.textContaining('Drops: ')),
        findsNothing,
        reason: 'a town prints no drops line',
      );
    });

    testWidgets(
      '⭐ the cell is the same height on a town card and a zone card',
      (tester) async {
        // ⭐ Press-stability: a town neighbour and a zone neighbour stand the
        // same height in this cell, so the cards below never shift by which
        // kind of place sits above them.
        await _pumpMapTabInFoothills(tester);
        final town = tester.getSize(find.byKey(mapYieldCellKey(hearthwood.id)));
        final zone = tester.getSize(find.byKey(mapYieldCellKey(ashfall.id)));
        expect(
          zone.height,
          greaterThan(0),
          reason: 'precondition: the zone\'s lines take room',
        );
        expect(
          town.height,
          zone.height,
          reason:
              'a cell that is only built when there is something to put in it '
              'is 0 tall on the town card and 2 lines tall on the zone card',
        );
      },
    );

    testWidgets('a travel card line never wraps', (tester) async {
      await _pumpMapTabInFoothills(tester);
      final line = tester.widget<Text>(
        _inCard(ashfall.name, find.textContaining('Drops: ')),
      );
      expect(
        (line.maxLines, line.overflow),
        (1, TextOverflow.ellipsis),
        reason:
            'a long drops line left free to wrap grows the card on a phone '
            'and moves every card below it — the reserved cell is one line '
            'per line',
      );
    });
  });

  group("the world map's place sheet", () {
    Future<void> pumpSheet(WidgetTester tester, GameLocation loc) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSheet(location: loc, isHere: false, onTravel: () {}),
          ),
        ),
      );
    }

    testWidgets('a zone shows both lines', (tester) async {
      final peaks = World.byId('thunderspire_peaks');
      await pumpSheet(tester, peaks);
      expect(
        find.text('Gather: Rowan Log · Iron Ore · Hum Quartz'),
        findsOneWidget,
        reason: 'the ruling\'s own search — a sheet without the lines fails',
      );
      expect(
        find.text(Provenance.dropsLine(peaks)!),
        findsOneWidget,
        reason: 'and the drops line, the same copy as the Map tab',
      );
    });

    testWidgets('a town shows neither', (tester) async {
      await pumpSheet(tester, hearthwood);
      expect(
        find.textContaining('Gather: '),
        findsNothing,
        reason: 'a town has nothing to gather',
      );
      expect(
        find.textContaining('Drops: '),
        findsNothing,
        reason: 'and nothing to drop',
      );
    });
  });

  group('the item dialog', () {
    Future<void> open(WidgetTester tester, String defId, double width) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showItemDialog(context, def: ItemCatalogue.byId(defId)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lays out at $width');
    }

    testWidgets('a found item names where', (tester) async {
      await open(tester, 'rowan_log', 400);
      expect(
        find.text('Found in: Thunderspire Peaks (gathered, dropped)'),
        findsOneWidget,
        reason: 'the line under the value — a dialog without it fails here',
      );
    });

    testWidgets('a crafted-only item prints no line', (tester) async {
      await open(tester, 'oak_wand', 400);
      expect(
        find.textContaining('Found in'),
        findsNothing,
        reason:
            'the Oak Wand comes from the bench — "Found in: " with nothing '
            'after it fails here',
      );
    });

    testWidgets('⚠️ eight places wrap inside a narrow dialog', (tester) async {
      final line = Provenance.foundInLine(
        ItemCatalogue.byId('climbers_ration'),
      )!;
      expect(
        Provenance.sourcesOf('climbers_ration').length,
        8,
        reason: 'precondition: the longest line in the game',
      );
      await open(tester, 'climbers_ration', 320);
      final found = find.text(line);
      expect(found, findsOneWidget, reason: 'printed whole, not clipped');
      final text = tester.widget<Text>(found);
      expect(
        tester.getSize(found).height,
        greaterThan(3 * text.style!.fontSize!),
        reason:
            'it wraps onto several lines — a single-line or no-softWrap '
            'Text runs off the side of a 320px dialog instead',
      );
    });
  });
}
