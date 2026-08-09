import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';

/// ⚠️ A ListView only builds what fits. The default 800x600 test viewport
/// leaves the Storeroom below the fold, so it never renders and assertions
/// about it fail for a reason that has nothing to do with the UI.
Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(game));
}

Widget _wrap(GameState game) => MaterialApp(
  home: GameStateScope(
    state: game,
    child: const Scaffold(body: InventoryTab()),
  ),
);

void main() {
  testWidgets('the pack shows every slot, full or empty', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    await _pump(tester, game);
    expect(find.textContaining('BACKPACK — 0/20'), findsOneWidget);
  });

  testWidgets('a carried item is named, not shown as its id', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.backpack = game.profile.backpack.withAdded(
      const InventorySlot(defId: 'oak_log'),
    )!;
    await _pump(tester, game);
    expect(find.text('Oak Log'), findsOneWidget);
    expect(find.text('oak_log'), findsNothing);
  });

  testWidgets('in town, the Storeroom is shown and named for that town', (
    tester,
  ) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.storerooms['hearthwood'] = const Storeroom(
      stacks: {'oak_log': 4},
    );
    await _pump(tester, game);
    expect(find.textContaining('HEARTHWOOD STOREROOM'), findsOneWidget);
    expect(find.text('×4'), findsOneWidget);
    // ⚠️ The per-city rule, stated where a player will actually read it.
    expect(find.textContaining('per city'), findsOneWidget);
  });

  testWidgets('outside a town there is no Storeroom to use', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.locationId = 'whispering_woods';
    await _pump(tester, game);
    expect(find.textContaining('Storeroom is in town'), findsOneWidget);
  });

  testWidgets('all ten equipment slots are shown, empty included', (
    tester,
  ) async {
    // ⭐ A paper doll that only lists worn items looks like a bug when you own
    // nothing, which is exactly the state a new character is in.
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    await _pump(tester, game);
    expect(find.text('Empty'), findsNWidgets(EquipSlot.values.length));
    expect(find.text('HAT'), findsOneWidget);
    expect(find.text('BELT'), findsOneWidget);
  });

  testWidgets('the belt shows its capacity and what it costs', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    await _pump(tester, game);
    expect(
      find.textContaining('Belt — 0/${Carrying.baseBeltSlots}'),
      findsOneWidget,
    );
    // ⚠️ The rule that makes the belt a decision rather than a tax.
    expect(find.textContaining('spends your turn'), findsOneWidget);
  });

  test('every item in the catalogue renders a name that is not its id', () {
    // ⭐ Drift guard: an item added without a properName would show its raw id
    // to players, which is the kind of thing that ships.
    for (final def in ItemCatalogue.all) {
      final name = ItemCatalogue.displayName(def, null);
      expect(name, isNot(def.id), reason: '${def.id} has no display name');
      expect(name.trim(), isNotEmpty);
    }
  });

  test('⚠️ crafted equipment must never carry a written name', () {
    // Its name is composed from aspect + quality + material + form so it
    // cannot drift from the facts (ITEMS §9b.5a). ⭐ The exception is NAMED
    // drops — boss uniques and the drop-only jewelry — whose bespoke name is
    // the point (§9b.5). Commons are always crafted-grammar items.
    for (final def in ItemCatalogue.all) {
      if (def is EquipmentDef) {
        if (def.rarity == Rarity.common) {
          expect(
            def.properName,
            isNull,
            reason: '${def.id} would let its name drift from its facts',
          );
        }
      } else {
        expect(def.properName, isNotNull, reason: '${def.id} needs a name');
      }
    }
  });
}

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}
