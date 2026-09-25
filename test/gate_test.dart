/// The Primal tier gate — **Pennycross**, not Hearthwood (playtest ruling,
/// Christian 2026-09-21).
///
/// > *"Currently it says the gate to Hearthwood is gated, but that's confusing
/// > since it's not gated, you can leave easily. The gate to Pennycross should
/// > be gated and require the 3 proofs be carried in the inventory once to
/// > unlock it. Once unlocked, the user no longer needs the proofs."*
///
/// Three rules came out of that, and each has a mutant waiting for it:
///  * **carried**, in the backpack, not banked in a storeroom,
///  * **once** — the opening is recorded on the character and never re-checked,
///  * ~~shown, not spent~~ — ⭐ **superseded 2026-09-25**: the proofs are
///    consumed at the gate, and the gate is a place you ARRIVE at (mockup B).
///
/// ⭐ **RULING (Christian, 2026-09-25): departure is never refused.** The road
/// to a shut gate is an ordinary road; the trip arrives at the gate screen
/// and the guard asks there. This file owns the departure half and the Map
/// tab's tag; `gate_screen_test.dart` owns the arrival, the Unlock and the
/// achievement.
///
/// `world_test.dart` holds the two facts this file leans on: the gate line is
/// on Pennycross, and all three proof zones are reachable without walking
/// through it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/gates.dart';
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

/// The test clock — moved forward to make a trip arrive.
DateTime _clock = DateTime.utc(2026, 1, 1, 12);

/// A fresh mage in Hearthwood, carrying [carrying].
GameState _atHearthwood({List<String> carrying = const []}) {
  _clock = DateTime.utc(2026, 1, 1, 12);
  final g = GameState(_Mem(), PlayerProfile.newPlayer(), now: () => _clock);
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
  });

  group('⭐ the road to a shut gate is an ordinary road (2026-09-25)', () {
    test('two of three proofs: travelTo departs, and says nothing', () async {
      final g = _atHearthwood(carrying: [_woods, _foothills]);

      expect(
        await g.travelTo('pennycross'),
        isNull,
        reason:
            'kills the 2026-09-21 departure check — the guard asks at the '
            'gate now, not on the road out of Hearthwood',
      );
      expect(
        g.profile.trip?.toId,
        'pennycross',
        reason: 'kills a mutant that returns no refusal but never departs',
      );
      expect(
        g.profile.openedGates,
        isEmpty,
        reason: 'kills a mutant that opens a gate the player cannot unlock',
      );
    });

    test('⚠️ beginTravel departs too, with an empty pack', () async {
      // Every caller goes through beginTravel in the end; a departure check
      // left behind there would be the old rule with a door beside it.
      final g = _atHearthwood();

      expect(
        await g.beginTravel('pennycross'),
        isTrue,
        reason: 'kills a mutant that keeps the gate check in beginTravel',
      );
      expect(
        g.profile.trip?.toId,
        'pennycross',
        reason: 'kills a mutant that returns true but never departs',
      );
    });

    test(
      '⭐ all three carried: nothing opens and nothing is spent on the road',
      () async {
        final g = _atHearthwood(carrying: _allThree);
        await g.travelTo('pennycross');

        expect(
          g.profile.openedGates,
          isEmpty,
          reason:
              'kills the old "opens as the trip STARTS" write — the gate opens '
              'on Unlock, at the gate screen, and nowhere else',
        );
        for (final id in _allThree) {
          expect(
            g.profile.backpack.countOf(id),
            1,
            reason:
                'kills a mutant that spends $id at departure — the guard keeps '
                'the proofs only when the player presses Unlock',
          );
        }
      },
    );

    test('⭐ arriving at a shut gate stands you AT the gate', () async {
      final g = _atHearthwood(carrying: [_woods]);
      await g.travelTo('pennycross');
      _clock = _clock.add(const Duration(days: 1));
      await g.tick();

      expect(
        g.profile.locationId,
        'pennycross',
        reason: 'kills a mutant that bounces the player back on arrival',
      );
      expect(
        g.profile.shutGateHere,
        'pennycross',
        reason:
            'kills a mutant that lets a player with one proof straight into '
            'the town — this is what puts the gate screen up',
      );
      expect(
        g.profile.gateTurnBackId,
        'hearthwood',
        reason: 'kills a mutant that forgets which way the player came',
      );
    });

    test('⭐ once opened, never asked again — even with an empty pack', () async {
      final g = _atHearthwood();
      g.profile.openedGates.add('pennycross');

      await g.travelTo('pennycross');
      _clock = _clock.add(const Duration(days: 1));
      await g.tick();

      expect(
        g.profile.locationId,
        'pennycross',
        reason: 'the trip really arrived',
      );
      expect(
        g.profile.shutGateHere,
        isNull,
        reason:
            'kills a mutant that re-checks the pack on an already-open gate — '
            '"once unlocked, the user no longer needs the proofs"',
      );
      expect(
        g.gateRefusal('pennycross'),
        isNull,
        reason: 'kills a mutant that asks the guard again after opening',
      );
    });

    test(
      '⚠️ openGateAt refuses short of a full set, and spends nothing',
      () async {
        final g = _atHearthwood(carrying: [_woods, _brook]);
        await g.travelTo('pennycross');
        _clock = _clock.add(const Duration(days: 1));
        await g.tick();

        expect(
          await g.openGateAt('pennycross'),
          isFalse,
          reason: "kills a mutant whose Unlock skips the guard's check",
        );
        expect(
          g.profile.backpack.countOf(_woods) +
              g.profile.backpack.countOf(_brook),
          2,
          reason: 'kills a mutant that spends the proofs on a refused unlock',
        );
        expect(
          g.profile.openedGates,
          isEmpty,
          reason: 'kills a mutant that opens the gate on a refused unlock',
        );
      },
    );

    test('⚠️ openGateAt refuses from anywhere but the gate', () async {
      final g = _atHearthwood(carrying: _allThree);

      expect(
        await g.openGateAt('pennycross'),
        isFalse,
        reason:
            'kills a mutant that unlocks Pennycross from Hearthwood — the '
            'guard is at the gate, not in your pocket',
      );
      expect(
        g.profile.backpack.countOf(_woods),
        1,
        reason: 'kills a mutant that spends before checking where you are',
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

    const shutTag = 'Gated · show three proofs at the gate';

    testWidgets('a fresh profile sees Pennycross gated, with what to show', (
      tester,
    ) async {
      await pumpTab(tester, _atHearthwood());

      expect(
        find.text(shutTag),
        findsOneWidget,
        reason:
            'kills a mutant that keeps the bare "Gated" chip, drops the '
            'chip, or shows it on every neighbour rather than the one town',
      );
      expect(
        tester.widget<Text>(find.text(shutTag)).style?.color,
        AppColors.gold,
        reason: 'kills a mutant that tints a shut gate like an open road',
      );
    });

    testWidgets('⭐ once opened, the card carries no gate at all', (
      tester,
    ) async {
      final g = _atHearthwood()..profile.openedGates.add('pennycross');
      await pumpTab(tester, g);

      expect(
        find.text(shutTag),
        findsNothing,
        reason: 'kills a mutant that leaves the shut tag on an open gate',
      );
      expect(
        find.text('Gate open'),
        findsNothing,
        reason:
            'kills a mutant that keeps the old "Gate open" chip — open means '
            'gone (ruling 2026-09-25)',
      );
      expect(
        find.byIcon(Icons.lock_outline),
        findsNothing,
        reason:
            'kills a mutant that drops the words but keeps the lock glyph — '
            'no other neighbour of Hearthwood has a gate',
      );
    });

    testWidgets('⭐ a tap with two proofs travels, no banner', (tester) async {
      final game = _atHearthwood(carrying: [_woods, _brook]);
      await pumpTab(tester, game);

      await tester.tap(find.text('Pennycross'));
      await tester.pumpAndSettle();

      expect(
        game.profile.trip?.toId,
        'pennycross',
        reason:
            'kills a mutant that still refuses the tap — the guard asks at '
            'the gate now',
      );
      expect(
        find.textContaining('The guard wants three proofs'),
        findsNothing,
        reason: 'kills a mutant that banners the old refusal and travels',
      );
    });

    test('a gate with no ruled copy keeps the bare tag', () {
      // Concordance's Sigil is prose with nothing behind it, and Rimeholt's
      // totem has no ruled words yet; "three proofs" is the Primal guard's
      // sentence and must not be borrowed.
      expect(
        Gates.shutTagFor(World.byId('concordance')),
        'Gated',
        reason: "kills a mutant that prints Pennycross's tag on every gate",
      );
      expect(
        Gates.shutTagFor(World.byId('rimeholt')),
        'Gated',
        reason:
            'kills a mutant that keys the long tag off "has gate items" '
            "rather than off Pennycross's own copy",
      );
    });
  });
}
