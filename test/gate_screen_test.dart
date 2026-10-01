/// The gate as a place you arrive at (ruling, Christian 2026-09-25, mockup
/// B): the trip to a shut gate lands at the [GateScreen], not in the town;
/// Unlock spends the three proofs, opens the gate for good and earns the
/// game's first achievement; Turn back is the way you came, and the passage
/// rule may not refuse it.
///
/// ⭐ Driven through the real seam — a trip, a clock moved forward, `tick` —
/// and the real [GateCheckpoint], so nothing here is a gate screen pumped
/// on its own and believed to be reachable.
///
/// `gate_test.dart` owns the departure half (never refused any more) and the
/// Map tab's tag.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/gates.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/gate_screen.dart';
import 'package:masters_of_magic_2/screens/home_shell.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';

const _woods = 'proof_of_the_woods';
const _brook = 'proof_of_the_brook';
const _foothills = 'proof_of_the_foothills';
const _allThree = [_woods, _brook, _foothills];

/// What the checkpoint shows when the player is NOT at the gate.
const _town = 'In town';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

DateTime _clock = DateTime.utc(2026, 1, 1, 12);

/// A fresh mage in Hearthwood carrying [carrying], on a clock the test owns.
GameState _mage({List<String> carrying = const []}) {
  _clock = DateTime.utc(2026, 1, 1, 12);
  final g = GameState(_Mem(), PlayerProfile.newPlayer(), now: () => _clock);
  for (final id in carrying) {
    g.profile.backpack = g.profile.backpack.withAdded(
      InventorySlot(defId: id),
    )!;
  }
  return g;
}

/// Walk to [toId] and arrive — the real departure, the real settle.
Future<void> _walkTo(GameState g, String toId) async {
  expect(
    await g.beginTravel(toId),
    isTrue,
    reason: 'the road to $toId must be walkable for this test to mean much',
  );
  _clock = _clock.add(const Duration(days: 1));
  await g.tick();
}

/// The checkpoint over a stand-in town, the way `HomeShell` wraps its tabs.
Future<void> _pumpCheckpoint(
  WidgetTester tester,
  GameState game, {
  Widget town = const Scaffold(body: Center(child: Text(_town))),
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GameStateScope(
      state: game,
      child: MaterialApp(home: GateCheckpoint(child: town)),
    ),
  );
  await tester.pumpAndSettle();
}

FilledButton _unlockButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(of: find.text('Unlock'), matching: find.byType(FilledButton)),
);

void main() {
  group('arriving at a shut gate', () {
    testWidgets('⭐ two of three: the gate screen, Unlock off, the missing '
        'proof named with its zone', (tester) async {
      final game = _mage(carrying: [_woods, _brook]);
      await _pumpCheckpoint(tester, game);
      expect(find.text(_town), findsOneWidget, reason: 'starts in Hearthwood');

      await _walkTo(game, 'pennycross');
      await tester.pumpAndSettle();

      expect(
        find.byType(GateScreen),
        findsOneWidget,
        reason:
            'kills a mutant that lets the trip arrive IN the town — the '
            'ruling is that the player lands at the gate',
      );
      expect(
        find.text(_town),
        findsNothing,
        reason: 'kills a mutant that draws the gate over a live town',
      );
      expect(
        find.text('The gate to Pennycross'),
        findsOneWidget,
        reason: 'the title names the town behind the gate',
      );
      expect(
        find.text(
          '"Three proofs. One from each of the old roads. Then the gate is '
          'yours, and I keep the papers."',
        ),
        findsOneWidget,
        reason:
            "kills a mutant that drops the guard's line, or shows the gate "
            'prose unquoted in its place',
      );
      expect(
        _unlockButton(tester).onPressed,
        isNull,
        reason: 'kills a mutant whose Unlock is live short of three proofs',
      );
      expect(
        find.text('Proof of the Foothills'),
        findsOneWidget,
        reason: 'the missing proof is named, not just counted',
      );
      expect(
        find.text('from Cinderpeak Foothills · boss'),
        findsOneWidget,
        reason:
            'kills a mutant that hides where the missing proof comes from, '
            'or names the wrong zone',
      );
      expect(
        find.text('from Whispering Woods · boss'),
        findsNothing,
        reason:
            'kills a mutant that prints the source line under proofs the '
            'player already carries',
      );
      expect(
        find.byIcon(Icons.check_circle),
        findsNWidgets(2),
        reason: 'kills a mutant that ticks every proof, or none — two carried',
      );
    });

    testWidgets('⭐ a gate already open lands in town, never at the screen', (
      tester,
    ) async {
      // The player who opened Pennycross under the 2026-09-21 rule: gate in
      // openedGates, proofs still in the pack. 📝 They keep the proofs.
      final game = _mage(carrying: _allThree)
        ..profile.openedGates.add('pennycross');
      await _pumpCheckpoint(tester, game);

      await _walkTo(game, 'pennycross');
      await tester.pumpAndSettle();

      expect(
        find.byType(GateScreen),
        findsNothing,
        reason:
            'kills a mutant that keys the screen off "has gateItemIds" '
            'rather than "is still shut"',
      );
      expect(find.text(_town), findsOneWidget, reason: 'in the town proper');
      expect(
        game.profile.backpack.countOf(_woods),
        1,
        reason:
            'kills a mutant that silently collects a legacy player\'s proofs '
            '— the ruling leaves them (they may sell them)',
      );
    });

    testWidgets('the home shell is wrapped in the checkpoint', (tester) async {
      // Standing at the shut gate from the first frame — a launch after the
      // trip finished while the app was closed.
      final profile = PlayerProfile.newPlayer()
        ..locationId = 'pennycross'
        ..arrivedFromId = 'hearthwood';
      final game = GameState(_Mem(), profile, now: () => _clock);
      await tester.pumpWidget(
        GameStateScope(
          state: game,
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      await tester.pump();

      expect(
        find.byType(GateScreen),
        findsOneWidget,
        reason:
            'kills a mutant that builds the checkpoint but never wraps the '
            'real shell in it — the tabs would open onto the town',
      );
    });
  });

  group('Unlock', () {
    testWidgets('⭐ spends exactly the three proofs, opens the gate, earns '
        'Papers in Order, and toasts it', (tester) async {
      // A spare proof and a log besides — "exactly the three" means one
      // of each, and nothing else in the pack.
      final game = _mage(carrying: [..._allThree, _woods, 'oak_log']);
      final before = game.profile.backpack.used;
      await _pumpCheckpoint(tester, game);
      await _walkTo(game, 'pennycross');
      await tester.pumpAndSettle();

      expect(
        _unlockButton(tester).onPressed,
        isNotNull,
        reason: 'kills a mutant whose Unlock stays off with all three carried',
      );
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(
        game.profile.backpack.used,
        before - 3,
        reason: 'kills a mutant that spends more, or fewer, than three slots',
      );
      expect(
        game.profile.backpack.countOf(_woods),
        1,
        reason:
            'kills a mutant that takes every Proof of the Woods — the guard '
            'keeps one of each; the spare stays',
      );
      for (final id in [_brook, _foothills]) {
        expect(
          game.profile.backpack.countOf(id),
          0,
          reason:
              'kills a mutant that leaves $id in the pack (shown, not kept)',
        );
      }
      expect(
        game.profile.backpack.countOf('oak_log'),
        1,
        reason: 'kills a mutant that clears the pack rather than the proofs',
      );
      expect(
        game.profile.openedGates,
        contains('pennycross'),
        reason: 'kills a mutant that spends the proofs without opening',
      );
      expect(
        game.profile.achievements,
        contains('papers_in_order'),
        reason: 'kills a mutant that opens the gate without the achievement',
      );
      expect(
        await game.grantAchievement('papers_in_order'),
        isFalse,
        reason: 'kills a non-idempotent grant — the second one is not new',
      );
      expect(
        find.text('Achievement · Papers in Order'),
        findsOneWidget,
        reason: 'kills a mutant that earns it silently — the toast says so',
      );
      expect(
        find.text(_town),
        findsOneWidget,
        reason: 'kills a mutant that leaves the player at an open gate',
      );
      expect(
        find.byType(GateScreen),
        findsNothing,
        reason: 'the gate screen is gone once the gate is open',
      );
    });

    testWidgets('⭐ once open, the travel card and the town card carry no '
        'gate line', (tester) async {
      final game = _mage(carrying: _allThree);
      await _walkTo(game, 'pennycross');
      expect(
        await game.openGateAt('pennycross'),
        isTrue,
        reason: 'the real unlock, through the real call',
      );

      // Standing in Pennycross: the town card used to print the proofs line.
      await _pumpCheckpoint(
        tester,
        game,
        town: Scaffold(body: MapTab(onSelectTab: (_) {})),
      );
      expect(
        find.textContaining('Three ordinary proofs'),
        findsNothing,
        reason:
            'kills a mutant that keeps the lock line on the town card once '
            'the player is through the gate',
      );

      // Back in Hearthwood, the Pennycross travel card.
      await game.beginTravel('hearthwood');
      _clock = _clock.add(const Duration(days: 1));
      await game.tick();
      tester.view.physicalSize = const Size(420, 2400);
      await tester.pumpAndSettle();
      expect(
        find.text('Pennycross'),
        findsOneWidget,
        reason: 'the Pennycross card is on screen',
      );
      expect(
        find.text(Gates.pennycross.shutTag),
        findsNothing,
        reason: 'kills a mutant that leaves the shut tag on an open gate',
      );
      expect(
        find.byIcon(Icons.lock_outline),
        findsNothing,
        reason: 'kills a mutant that keeps the lock glyph with no words',
      );
    });
  });

  group('⚠️ only Pennycross spends', () {
    test('Rimeholt opens on the totem and keeps it, earning its own', () async {
      // The Celestial Totem is ruled keepable (CELESTIAL_CONTRACT §3.4);
      // the arrival ruling made Rimeholt a stop too, but did not make its
      // guard keep anything.
      final profile = PlayerProfile.newPlayer()
        ..locationId = 'rimeholt'
        ..arrivedFromId = 'meridian';
      profile.backpack = profile.backpack.withAdded(
        const InventorySlot(defId: 'celestial_totem', instanceId: 'totem-1'),
      )!;
      final game = GameState(_Mem(), profile, now: () => _clock);
      expect(
        profile.shutGateHere,
        'rimeholt',
        reason: 'premise: Rimeholt is a shut gate too',
      );

      expect(
        await game.openGateAt('rimeholt'),
        isTrue,
        reason: 'the totem is carried, so the gate opens',
      );
      expect(
        game.profile.backpack.countOf('celestial_totem'),
        1,
        reason:
            "kills a mutant that spends every gate's items — the proofs stay "
            'with the Pennycross guard; the totem stays with the player',
      );
      expect(
        game.profile.achievements,
        {'beyond_the_veil'},
        reason:
            'kills a mutant that hands Papers in Order out at any gate, and '
            'one that opens Rimeholt without Beyond the Veil (ruling '
            '2026-09-30, note 7)',
      );
      expect(
        game.achievementNews.value.map((a) => a.id),
        ['beyond_the_veil'],
        reason:
            'kills a mutant that earns it silently — Rimeholt has no gate '
            'toast of its own, so the shell must hear of it',
      );
    });
  });

  group('Turn back', () {
    testWidgets('⭐ goes back the way you came, and the town is not entered', (
      tester,
    ) async {
      final game = _mage(carrying: [_woods]);
      await _pumpCheckpoint(tester, game);
      await _walkTo(game, 'pennycross');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Turn back'));
      await tester.pumpAndSettle();

      expect(
        game.profile.trip?.toId,
        'hearthwood',
        reason: 'kills a mutant that turns back to anywhere but the origin',
      );
      _clock = _clock.add(const Duration(days: 1));
      await game.tick();
      await tester.pumpAndSettle();
      expect(
        game.profile.locationId,
        'hearthwood',
        reason: 'the trip back arrives where it set out from',
      );
      expect(
        game.profile.openedGates,
        isEmpty,
        reason: 'kills a mutant that opens the gate on the way out',
      );
    });

    testWidgets('⚠️ the passage rule may not refuse the way you came', (
      tester,
    ) async {
      // ⭐ Contrived on purpose: an origin whose road from Pennycross runs
      // through the uncleared Old Quarry, so the passage rule WOULD refuse it
      // from anywhere but a shut gate. (A legitimate arrival never looks like
      // this, which is exactly why a mutant that forgot the exemption would
      // survive every realistic test.)
      final open = PlayerProfile.newPlayer()
        ..locationId = 'pennycross'
        ..arrivedFromId = 'forgeholm'
        ..openedGates.add('pennycross');
      expect(
        GameState(_Mem(), open).passageRefusal('forgeholm'),
        isNotNull,
        reason: 'premise: through an open gate the rule does refuse this road',
      );

      final profile = PlayerProfile.newPlayer()
        ..locationId = 'pennycross'
        ..arrivedFromId = 'forgeholm';
      final game = GameState(_Mem(), profile, now: () => _clock);
      await _pumpCheckpoint(tester, game);
      expect(find.byType(GateScreen), findsOneWidget, reason: 'at the gate');

      await tester.tap(find.text('Turn back'));
      await tester.pumpAndSettle();

      expect(
        game.profile.trip?.toId,
        'forgeholm',
        reason:
            'kills a mutant that sends Turn back through the passage rule — '
            'the way you came is always open (ruling 2026-09-25)',
      );
    });

    test('📝 a legacy save with no arrivedFromId turns back to a town', () {
      final legacy = PlayerProfile.newPlayer()..locationId = 'pennycross';

      expect(
        legacy.gateTurnBackId,
        'hearthwood',
        reason:
            'kills a mutant that strands a legacy player at the gate, or '
            'sends them on into Old Quarry',
      );
    });
  });

  group('achievements on the profile', () {
    test('⭐ round-trip through JSON under "achievements"', () {
      final before = PlayerProfile.newPlayer()
        ..achievements.add('papers_in_order');
      final json = before.toJson();

      expect(json['achievements'], [
        'papers_in_order',
      ], reason: 'kills a mutant that writes the key under another name');
      expect(PlayerProfile.fromJson(json).achievements, {
        'papers_in_order',
      }, reason: 'kills a mutant that never reads the key back');
    });

    test('⚠️ absent reads as earned nothing', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('achievements');

      expect(
        PlayerProfile.fromJson(json).achievements,
        isEmpty,
        reason: 'kills a mutant that throws on a save from before 2026-09-25',
      );
    });

    test('grantAchievement: new once, then not; unknown ids refused', () async {
      final g = _mage();

      expect(
        await g.grantAchievement(Achievements.papersInOrder.id),
        isTrue,
        reason: 'kills a grant that never reports a first earn',
      );
      expect(
        (g.storage as _Mem).stored?.achievements,
        contains('papers_in_order'),
        reason: 'kills a grant that changes memory but never persists',
      );
      expect(
        await g.grantAchievement('papers_in_order'),
        isFalse,
        reason: 'kills a grant that toasts every time',
      );
      expect(
        await g.grantAchievement('not_a_real_one'),
        isFalse,
        reason: 'kills a grant that banks a typo forever',
      );
      expect(g.profile.achievements, {
        'papers_in_order',
      }, reason: 'the typo was not stored');
    });
  });
}
