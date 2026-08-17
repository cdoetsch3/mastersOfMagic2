import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
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

  testWidgets('⚠️ with no belt worn there are no slots, and it says so', (
    tester,
  ) async {
    // The 2026-08-17 ruling: Carrying.baseBeltSlots is 0, so a fresh character
    // gets a hint where the empty boxes used to be.
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    await _pump(tester, game);
    expect(find.textContaining('No belt'), findsOneWidget);
    expect(
      find.textContaining('Belt — '),
      findsNothing,
      reason: '"Belt — 0/0" beside "No belt" says it twice',
    );
    // ⚠️ The rule that makes the belt a decision rather than a tax.
    expect(find.textContaining('spends your turn'), findsOneWidget);
  });

  testWidgets('wearing a belt is what grants the slots', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.itemInstances['b'] = const ItemInstance(
      instanceId: 'b',
      defId: 'tuskhide_belt',
    );
    game.profile.equipped[EquipSlot.belt] = 'b';
    await _pump(tester, game);
    expect(
      find.textContaining('Belt — 0/2'),
      findsOneWidget,
      reason: 'the Tuskhide Belt grants two, and nothing else does',
    );
    expect(find.textContaining('No belt'), findsNothing);
  });

  testWidgets('⚠️ the belt bay fits a phone', (tester) async {
    // The belt chip and its slots are one Row now, which is exactly the shape
    // that overflows at 380pt if the slots ever stop wrapping.
    await tester.binding.setSurfaceSize(const Size(380, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile
      ..xp = 100000
      ..itemInstances['b'] = const ItemInstance(
        instanceId: 'b',
        defId: 'tuskhide_belt',
      )
      ..equipped[EquipSlot.belt] = 'b'
      ..belt = const Belt(loaded: ['sapwort_draught'])
      ..storerooms['hearthwood'] = const Storeroom(stacks: {'oak_log': 6});
    await tester.pumpWidget(_wrap(game));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gear panel shows TOTALS, not bare bonuses', (tester) async {
    // ⭐ An ITEM shows its contribution; the PANEL answers "what am I at".
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.itemInstances['r'] = const ItemInstance(
      instanceId: 'r',
      defId: 'bindweed_robe', // +6 max health
    );
    game.profile.equipped[EquipSlot.robeTop] = 'r';
    await _pump(tester, game);
    expect(find.text('Max health 106 (+6)'), findsOneWidget);
    expect(
      find.text('+6 max health'),
      findsNothing,
      reason: 'the delta form belongs in the item dialog, not the panel',
    );
  });

  testWidgets('a Beltable item can be loaded from the pack', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile
      ..xp = 100000 // past the Tuskhide's level 11
      ..itemInstances['b'] = const ItemInstance(
        instanceId: 'b',
        defId: 'tuskhide_belt',
      )
      ..equipped[EquipSlot.belt] = 'b'
      ..backpack = Backpack.of(
        const [InventorySlot(defId: 'sapwort_draught')],
      );
    await _pump(tester, game);

    // Long-press opens the full menu (tap stows, in town).
    await tester.longPress(find.text('Sapwort Draught'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load onto belt'));
    await tester.pumpAndSettle();

    expect(game.profile.belt.loaded, ['sapwort_draught']);
    expect(
      game.profile.backpack.used,
      0,
      reason: 'loading is a MOVE — the draught is on the belt now',
    );
  });

  testWidgets('⚠️ with no belt, the action is greyed WITH its reason', (
    tester,
  ) async {
    // A "Load onto belt" that simply vanishes teaches the player that the
    // draught is not beltable, which is the opposite of true.
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.backpack = Backpack.of(
      const [InventorySlot(defId: 'sapwort_draught')],
    );
    await _pump(tester, game);
    await tester.longPress(find.text('Sapwort Draught'));
    await tester.pumpAndSettle();

    expect(find.text('Load onto belt'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Load onto belt'),
    );
    expect(button.onPressed, isNull, reason: 'it must not be tappable');
    expect(
      find.textContaining('not wearing a belt'),
      findsOneWidget,
      reason: 'the reason has to be readable without a hover',
    );
  });

  testWidgets('a loaded belt slot can be tapped to take it off', (
    tester,
  ) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile
      ..xp = 100000
      ..itemInstances['b'] = const ItemInstance(
        instanceId: 'b',
        defId: 'tuskhide_belt',
      )
      ..equipped[EquipSlot.belt] = 'b'
      ..belt = const Belt(loaded: ['sapwort_draught']);
    await _pump(tester, game);

    // The slot chip shows the item's initial; the dialog does the rest.
    await tester.tap(find.text('S'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take off belt'));
    await tester.pumpAndSettle();

    expect(game.profile.belt.loaded, isEmpty);
    expect(game.profile.backpack.countOf('sapwort_draught'), 1);
  });

  testWidgets('Take all empties a stack into the free slots', (tester) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.storerooms['hearthwood'] = const Storeroom(
      stacks: {'oak_log': 6},
    );
    await _pump(tester, game);
    expect(find.text('Take all'), findsOneWidget);
    await tester.tap(find.text('Take all'));
    await tester.pumpAndSettle();
    expect(game.profile.backpack.countOf('oak_log'), 6);
    expect(find.textContaining('Took all 6'), findsOneWidget);
  });

  testWidgets('⭐ Take all moving only part of a stack still reports it', (
    tester,
  ) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile
      ..storerooms['hearthwood'] = const Storeroom(stacks: {'oak_log': 40})
      ..backpack = Backpack.of([
        for (var i = 0; i < 17; i++)
          const InventorySlot(defId: 'bindweed_fibre'),
      ]);
    await _pump(tester, game);
    await tester.tap(find.text('Take all'));
    await tester.pumpAndSettle();
    expect(game.profile.backpack.countOf('oak_log'), 3);
    expect(find.textContaining('Took 3 of 40'), findsOneWidget);
  });

  testWidgets('a single stored item offers Take, but not Take all', (
    tester,
  ) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.storerooms['hearthwood'] = const Storeroom(
      stacks: {'oak_log': 1},
    );
    await _pump(tester, game);
    expect(find.text('Take'), findsOneWidget);
    expect(
      find.text('Take all'),
      findsNothing,
      reason: 'a second button that does the same thing as the first',
    );
  });

  testWidgets('the Storeroom sorts best-first and filters by kind', (
    tester,
  ) async {
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.storerooms['hearthwood'] = const Storeroom(
      stacks: {
        'oak_log': 3, // common material
        'sapwort_draught': 2, // common consumable
        'cinder_loop': 1, // RARE equipment
      },
    );
    await _pump(tester, game);

    // ⭐ Rarity descending: the rare leads, then the two commons by name.
    final rows = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where(
          (s) => s == 'Cinder Loop' || s == 'Oak Log' || s == 'Sapwort Draught',
        )
        .toList();
    expect(rows, ['Cinder Loop', 'Oak Log', 'Sapwort Draught']);

    await tester.tap(find.text('Consumables'));
    await tester.pumpAndSettle();
    expect(find.text('Sapwort Draught'), findsOneWidget);
    expect(find.text('Oak Log'), findsNothing);
    expect(find.text('Cinder Loop'), findsNothing);

    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Cinder Loop'), findsOneWidget);
    expect(find.text('Sapwort Draught'), findsNothing);

    await tester.tap(find.text('Materials'));
    await tester.pumpAndSettle();
    expect(
      find.text('Oak Log'),
      findsOneWidget,
      reason: 'materials is everything neither worn nor used, so nothing '
          'can hide from every chip',
    );
    expect(find.text('Cinder Loop'), findsNothing);
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
