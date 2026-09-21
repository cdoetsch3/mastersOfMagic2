/// The Primal tier gate — **Pennycross**, not Hearthwood (playtest ruling,
/// Christian 2026-09-21).
///
/// > *"Currently it says the gate to Hearthwood is gated, but that's confusing
/// > since it's not gated, you can leave easily. The gate to Pennycross should
/// > be gated and require the 3 proofs be carried in the inventory once to
/// > unlock it. Once unlocked, the user no longer needs the proofs."*
///
/// Three rules come out of that, and each has a mutant waiting for it:
///  * **carried**, in the backpack, not banked in a storeroom,
///  * **once** — the opening is recorded on the character and never re-checked,
///  * **shown, not spent** — the proofs are still in the pack afterwards.
///
/// `world_test.dart` holds the two facts this file leans on: the gate line is
/// on Pennycross, and all three proof zones are reachable without walking
/// through it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

const _woods = 'proof_of_the_woods';
const _brook = 'proof_of_the_brook';
const _foothills = 'proof_of_the_foothills';
const _allThree = [_woods, _brook, _foothills];

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// A fresh mage in Hearthwood, carrying [carrying].
GameState _atHearthwood({List<String> carrying = const []}) {
  final g = GameState(_Mem(), PlayerProfile.newPlayer());
  for (final id in carrying) {
    g.profile.backpack = g.profile.backpack.withAdded(
      InventorySlot(defId: id),
    )!;
  }
  return g;
}

void main() {
  group('the guard on the north road', () {
    test('⚠️ refuses by name when one proof is missing', () async {
      // ⭐ TWO of three carried, so a mutant that checks `any` instead of
      // `every` — or that names the whole list rather than what is short —
      // fails here rather than in the happy path.
      final g = _atHearthwood(carrying: [_woods, _foothills]);

      expect(
        g.gateRefusal('pennycross'),
        'The guard wants three proofs — you are missing Proof of the Brook.',
        reason:
            'kills a mutant that refuses with a generic line, names the '
            'proofs you DO have, or prints the raw item id',
      );
      expect(
        await g.travelTo('pennycross'),
        'The guard wants three proofs — you are missing Proof of the Brook.',
        reason: 'kills a mutant that checks the gate but refuses silently',
      );
      expect(
        g.profile.trip,
        isNull,
        reason: 'kills a mutant that reports the refusal and travels anyway',
      );
      expect(
        g.profile.openedGates,
        isEmpty,
        reason: 'kills a mutant that banks the opening on a refused attempt',
      );
    });

    test('⚠️ a proof in the storeroom is not a proof in your hands', () async {
      final g = _atHearthwood(carrying: [_woods, _foothills]);
      g.profile.storerooms['hearthwood'] = const Storeroom(stacks: {_brook: 1});

      expect(
        g.gateRefusal('pennycross'),
        contains('Proof of the Brook'),
        reason:
            'kills a mutant that counts the storeroom — the ruling says '
            'CARRIED in the inventory, and the guard is looking at your hands',
      );
    });

    test('names both when two are missing, as a sentence', () async {
      final g = _atHearthwood(carrying: [_brook]);

      expect(
        g.gateRefusal('pennycross'),
        'The guard wants three proofs — you are missing Proof of the Woods '
        'and Proof of the Foothills.',
        reason:
            'kills a mutant that names only the first missing proof, and one '
            'that comma-splices the list instead of joining it with "and"',
      );
    });

    test('lets you through with all three, and records the opening', () async {
      final g = _atHearthwood(carrying: _allThree);

      expect(
        g.gateRefusal('pennycross'),
        isNull,
        reason: 'kills a mutant that refuses even a complete set',
      );
      expect(
        await g.travelTo('pennycross'),
        isNull,
        reason: 'kills a mutant that returns a refusal on a legal trip',
      );
      expect(
        g.profile.trip?.toId,
        'pennycross',
        reason: 'kills a mutant that opens the gate without starting the trip',
      );
      expect(
        g.profile.openedGates,
        contains('pennycross'),
        reason:
            'kills a mutant that lets you through without recording it — the '
            'gate would ask again on the next trip',
      );
    });

    test('⭐ the proofs stay in the pack — shown, not spent', () async {
      final g = _atHearthwood(carrying: _allThree);
      await g.travelTo('pennycross');

      for (final id in _allThree) {
        expect(
          g.profile.backpack.countOf(id),
          1,
          reason:
              'kills a mutant that consumes $id at the gate — the guard looks '
              'at the proofs, he does not keep them (ruling 2026-09-21)',
        );
      }
    });

    test('⭐ once opened, never asked again — even with an empty pack', () async {
      // The real opening, through the real call, and then the proofs are gone:
      // sold, banked, dropped on the road. The road stays open.
      final g = _atHearthwood(carrying: _allThree);
      await g.travelTo('pennycross');
      await g.cancelTravel();
      g.profile.backpack = g.profile.backpack
          .withRemovedFirst(_woods)
          .withRemovedFirst(_brook)
          .withRemovedFirst(_foothills);
      expect(g.profile.backpack.used, 0, reason: 'the pack really is empty');

      expect(
        g.gateRefusal('pennycross'),
        isNull,
        reason:
            'kills a mutant that re-checks the pack on an already-open gate — '
            '"once unlocked, the user no longer needs the proofs"',
      );
      expect(
        await g.travelTo('pennycross'),
        isNull,
        reason: 'kills a mutant that re-checks inside travelTo only',
      );
      expect(
        g.profile.trip?.toId,
        'pennycross',
        reason: 'kills a mutant that allows the trip but never starts it',
      );
    });

    test('⚠️ beginTravel is gated too, not just travelTo', () async {
      // The world map calls `travelTo`, but point-to-point travel goes
      // straight to `beginTravel`. A check that lives only in the tab is a
      // gate with a door beside it.
      final g = _atHearthwood();

      expect(
        await g.beginTravel('pennycross'),
        isFalse,
        reason: 'kills a mutant that gates only travelTo',
      );
      expect(
        g.profile.trip,
        isNull,
        reason: 'kills a mutant that returns false but departs anyway',
      );
    });
  });

  group('everything that is not this gate', () {
    test('Hearthwood has no gate at all', () {
      expect(
        World.byId('hearthwood').gate,
        isNull,
        reason:
            'kills a mutant that leaves the proofs line on the starting town, '
            'which is the confusion the ruling fixes',
      );
      expect(
        World.byId('hearthwood').gateItemIds,
        isEmpty,
        reason: 'kills a mutant that enforces a gate Hearthwood does not have',
      );
      expect(
        _atHearthwood().gateRefusal('hearthwood'),
        isNull,
        reason: 'kills a mutant that refuses travel back to Hearthwood',
      );
    });

    test('⭐ a descriptive-only gate never refuses', () {
      // Concordance's Kinetic Sigil is prose with no items behind it yet, and
      // that is deliberate. It must keep behaving exactly as it did today.
      final concordance = World.byId('concordance');
      expect(
        concordance.gate,
        isNotNull,
        reason: 'kills a mutant that deletes the Sigil copy along with the fix',
      );
      expect(
        concordance.gateItemIds,
        isEmpty,
        reason: 'kills a mutant that invents items for an unbuilt gate',
      );
      expect(
        _atHearthwood().gateRefusal('concordance'),
        isNull,
        reason:
            'kills a mutant that refuses every location carrying gate PROSE — '
            'the string describes, the item list enforces',
      );
    });

    test('an ordinary neighbour is never refused', () {
      expect(
        _atHearthwood().gateRefusal('whispering_woods'),
        isNull,
        reason: 'kills a mutant that gates every destination',
      );
    });
  });

  group('the opening survives a save', () {
    test('⭐ openedGates round-trips through JSON', () {
      final before = PlayerProfile.newPlayer()
        ..openedGates.addAll({'pennycross', 'concordance'});

      final after = PlayerProfile.fromJson(before.toJson());

      expect(
        after.openedGates,
        {'pennycross', 'concordance'},
        reason:
            'kills a mutant that never writes the key, never reads it back, '
            'or writes it under a different name — the player would be asked '
            'for three proofs again on their next launch',
      );
    });

    test('⚠️ a save from before the gate existed has opened nothing', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('openedGates');

      expect(
        PlayerProfile.fromJson(json).openedGates,
        isEmpty,
        reason:
            'kills a mutant that throws on the absent key, and one that '
            'defaults an old save to "every gate open"',
      );
    });
  });

  group('the Map tab says which it is', () {
    Future<void> pumpTab(WidgetTester tester, GameState game) async {
      // ⚠️ Tall on purpose: the Pennycross card is the LAST of Hearthwood's
      // five neighbours, and a phone-height viewport never lays it out.
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

    testWidgets('a fresh profile sees Pennycross Gated', (tester) async {
      await pumpTab(tester, _atHearthwood());

      expect(
        find.text('Gated'),
        findsOneWidget,
        reason:
            'kills a mutant that drops the chip, and one that shows it on '
            'every neighbour rather than the one gated town',
      );
      expect(
        find.text('Gate open'),
        findsNothing,
        reason: 'kills a mutant that reads the refusal backwards',
      );
      expect(
        tester.widget<Text>(find.text('Gated')).style?.color,
        AppColors.gold,
        reason: 'kills a mutant that tints a shut gate like an open one',
      );
    });

    testWidgets('after the guard is satisfied it reads Gate open', (
      tester,
    ) async {
      final g = _atHearthwood(carrying: _allThree);
      await g.travelTo('pennycross');
      await g.cancelTravel();

      await pumpTab(tester, g);

      expect(
        find.text('Gate open'),
        findsOneWidget,
        reason:
            'kills a mutant that leaves the chip saying Gated forever — the '
            'player has no way to see the road opened',
      );
      expect(
        find.text('Gated'),
        findsNothing,
        reason: 'kills a mutant that shows both states at once',
      );
      expect(
        tester.widget<Text>(find.text('Gate open')).style?.color,
        AppColors.teal,
        reason:
            'kills a mutant that keeps the gold lock colour on an open gate',
      );
    });

    testWidgets('⭐ the chip cell does not move when the gate opens', (
      tester,
    ) async {
      // Press-stability: "Gate open" is the wider word, so a self-sizing tag
      // would shove the row it sits in sideways under a finger already coming
      // down. Both states occupy one fixed cell.
      await pumpTab(tester, _atHearthwood());
      final shut = _tagCell(tester, 'Gated');

      final g = _atHearthwood(carrying: _allThree);
      await g.travelTo('pennycross');
      await g.cancelTravel();
      await pumpTab(tester, g);
      final open = _tagCell(tester, 'Gate open');

      expect(
        open.width,
        shut.width,
        reason:
            'kills a mutant that lets the tag size itself — the station and '
            'element chips beside it would shift the moment the gate opened',
      );
    });

    testWidgets('⚠️ a refused tap says why', (tester) async {
      final game = _atHearthwood(carrying: [_woods, _brook]);
      await pumpTab(tester, game);

      await tester.tap(find.text('Pennycross'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The guard wants three proofs — you are missing Proof of the '
          'Foothills.',
        ),
        findsOneWidget,
        reason:
            'kills a mutant that swallows the refusal — a live-looking tile '
            'that does nothing reads as a broken tile, not a shut gate',
      );
      expect(
        game.profile.trip,
        isNull,
        reason: 'kills a mutant that banners the refusal and travels anyway',
      );
    });
  });
}

/// The box the gate tag occupies — the innermost `SizedBox` above [label],
/// which is the fixed cell `_GateTag` reserves.
Rect _tagCell(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(SizedBox)).first,
);
