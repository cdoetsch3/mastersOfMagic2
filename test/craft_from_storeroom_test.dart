/// Crafting draws on THIS town's Storeroom as well as the backpack
/// (ruling 2026-09-21).
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills. The three things that can go wrong here are a gate that ignores
/// storage, a consumption order that drains the wrong container, and an output
/// added to a pack that had no room for it — one test per failure.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/craft_screen.dart';

class _JsonMem implements ProfileStorage {
  String? saved;
  @override
  Future<PlayerProfile?> load() async => saved == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
  @override
  Future<void> save(PlayerProfile profile) async =>
      saved = jsonEncode(profile.toJson());
  @override
  Future<void> clear() async => saved = null;
}

/// Hearthwood is a town; the Whispering Woods is a route. ⚠️ Asserted below
/// rather than assumed — if the world file ever reclassified either, every
/// test in this file would pass for the wrong reason.
const _town = 'hearthwood';
const _road = 'whispering_woods';

/// The Quarterstaff wants 3 Oak Logs at Woodcarving 1, which a fresh player
/// already has — so every case here turns on materials alone, never the gate.
final _recipe = PrimalRecipes.oakQuarterstaff;

GameState _game({
  String at = _town,
  Map<String, int> pack = const {},
  Map<String, int> stored = const {},
  String storedAt = _town,
}) {
  final profile = PlayerProfile.newPlayer()
    ..locationId = at
    ..backpack = Backpack.of([
      for (final e in pack.entries)
        for (var n = 0; n < e.value; n++) InventorySlot(defId: e.key),
    ]);
  if (stored.isNotEmpty) {
    profile.storerooms[storedAt] = Storeroom(stacks: {...stored});
  }
  return GameState(_JsonMem(), profile);
}

int _stored(GameState game, String defId, [String town = _town]) =>
    game.profile.storerooms[town]?.stacks[defId] ?? 0;

void main() {
  group('crafting from the local Storeroom', () {
    test('the fixture locations are still a town and a route', () {
      expect(
        World.byId(_town).isTown,
        isTrue,
        reason: 'every in-town case here is vacuous if Hearthwood is not one',
      );
      expect(
        World.byId(_road).isTown,
        isFalse,
        reason: 'the road case is vacuous if the Whispering Woods is a town',
      );
    });

    test('in town, the Storeroom tops up a short pack', () async {
      final game = _game(pack: {'oak_log': 2}, stored: {'oak_log': 1});
      final out = await game.craft(_recipe);

      expect(
        out.succeeded,
        isTrue,
        reason:
            'a gate that counts only the backpack refuses a craft the '
            'town can afford — the whole ruling',
      );
      expect(
        game.profile.backpack.countOf('oak_log'),
        0,
        reason: 'the pack is spent first, so both its logs must be gone',
      );
      expect(
        _stored(game, 'oak_log'),
        0,
        reason:
            'a craft that consumes only the pack half duplicates the '
            'stored log',
      );
      expect(
        game.profile.backpack.countOf('oak_quarterstaff'),
        1,
        reason: 'the output belongs in the pack whenever it fits',
      );
    });

    test(
      'in town with a full pack, the output is stowed, not dropped',
      () async {
        // ⚠️ The case the old "space is safe by arithmetic" theorem missed: no
        // input came out of the pack, so the craft nets a slot the pack lacks.
        final game = _game(
          pack: {'bindweed_fibre': Carrying.backpackSlots},
          stored: {'oak_log': 3},
        );
        expect(
          game.profile.backpack.isFull,
          isTrue,
          reason:
              'the premise: a mutant that adds to a full pack must have a '
              'full pack to add to',
        );

        final out = await game.craft(_recipe);

        expect(
          out.succeeded,
          isTrue,
          reason:
              'a full pack is not a refusal — '
              'the town holds both the inputs and the room for the output',
        );
        expect(
          game.profile.backpack.countOf('oak_quarterstaff'),
          0,
          reason:
              'nothing can enter a full pack; a mutant that tries and '
              'swallows the null loses the item silently',
        );
        expect(
          game.profile.backpack.countOf('bindweed_fibre'),
          Carrying.backpackSlots,
          reason:
              'the pack is untouched — the craft must not evict a carried '
              'item to make room',
        );
        expect(
          out.instance,
          isNotNull,
          reason: 'a Quarterstaff is equipment: the mint still happens',
        );
        expect(
          game.profile.storerooms[_town]!.instanceIds,
          contains(out.instance!.instanceId),
          reason:
              'stowed means IN the Storeroom — an outcome that says so '
              'while the item exists nowhere is the worst failure here',
        );
        expect(
          _stored(game, 'oak_log'),
          0,
          reason: 'all three logs came out of storage',
        );
        // ⭐ Named from the INSTANCE, like every other craft message — the
        // rolled name is what the player will look for in the Storeroom.
        final def = ItemCatalogue.tryById('oak_quarterstaff')!;
        expect(
          out.note,
          'Made ${ItemCatalogue.displayName(def, out.instance)} — stowed in '
          'your storeroom (pack full).',
          reason:
              'the player must be told where the item went, and by which '
              'name; a null note leaves them hunting a pack that never got it',
        );
      },
    );

    test('short by one even counting the Storeroom, nothing moves', () async {
      final game = _game(pack: {'oak_log': 1}, stored: {'oak_log': 1});
      final out = await game.craft(_recipe);

      expect(
        out.refusal,
        'Needs 1 more Oak Log.',
        reason:
            'the shortfall is counted against pack + storeroom; a gate '
            'that forgot storage would say "2 more"',
      );
      expect(
        game.profile.backpack.countOf('oak_log'),
        1,
        reason: 'a refusal must not eat materials',
      );
      expect(
        _stored(game, 'oak_log'),
        1,
        reason: 'a refusal must not eat STORED materials either',
      );
    });

    test('on the road, the last town\'s Storeroom is out of reach', () async {
      final game = _game(at: _road, stored: {'oak_log': 3}, storedAt: _town);

      expect(
        game.materialCount('oak_log'),
        0,
        reason:
            'a Storeroom is per city — counting one from the road would '
            'make the pack meaningless (ITEMS §10.3c)',
      );

      final out = await game.craft(_recipe);
      expect(
        out.refusal,
        'Needs 3 more Oak Log.',
        reason:
            'behaviour off the road is exactly what it was before the '
            'ruling: pack only',
      );
      // ⚠️ **The gate is `isTown`, not "is there a map entry here".** A save
      // can carry a Storeroom keyed at any id; without the town check this
      // one would be spent from the middle of the woods.
      final onASpuriousRoom = _game(
        at: _road,
        stored: {'oak_log': 3},
        storedAt: _road,
      );
      expect(
        onASpuriousRoom.materialCount('oak_log'),
        0,
        reason:
            'a Storeroom entry under a route id is still not a town — an '
            'implementation that only looked the id up would count it',
      );
      expect(
        (await onASpuriousRoom.craft(_recipe)).refusal,
        'Needs 3 more Oak Log.',
        reason: 'and the craft gate must agree with materialCount, always',
      );
      expect(
        _stored(game, 'oak_log'),
        3,
        reason:
            'a craft that reached across the map would drain a town the '
            'character is not standing in',
      );
    });

    test('materialSplit names both sources, and only in town', () async {
      final inTown = _game(pack: {'oak_log': 2}, stored: {'oak_log': 5});
      expect(
        inTown.materialSplit('oak_log'),
        (pack: 2, stored: 5),
        reason:
            'the UI prints these two numbers separately; a split that '
            'returns the total in either field prints "7 (7 stored)"',
      );
      expect(
        inTown.materialCount('oak_log'),
        7,
        reason:
            'the count is the sum of the split — one reader, or the row '
            'and the gate disagree',
      );

      final onRoad = _game(
        at: _road,
        pack: {'oak_log': 2},
        stored: {'oak_log': 5},
        storedAt: _town,
      );
      expect(
        onRoad.materialSplit('oak_log'),
        (pack: 2, stored: 0),
        reason: 'off the road the stored half is zero, not the last town\'s 5',
      );
    });

    test('consumption is pack first, then the Storeroom', () async {
      final game = _game(pack: {'oak_log': 1}, stored: {'oak_log': 5});
      final out = await game.craft(_recipe);

      expect(out.succeeded, isTrue, reason: '1 + 5 covers the 3 needed');
      expect(
        game.profile.backpack.countOf('oak_log'),
        0,
        reason:
            'a mutant that drains the Storeroom first leaves the carried '
            'log in the pack, costing the output its slot',
      );
      expect(
        _stored(game, 'oak_log'),
        3,
        reason:
            'exactly the 2 the pack could not cover come out of storage; '
            'storeroom-first would leave 2',
      );
      expect(
        game.profile.backpack.countOf('oak_quarterstaff'),
        1,
        reason: 'the slot the pack freed is the one the output takes',
      );
      expect(
        out.note,
        isNull,
        reason:
            'the item landed in the pack — a stow note here would send '
            'the player to the wrong container',
      );
    });

    test('a pure-pack craft in town never touches the Storeroom', () async {
      final game = _game(pack: {'oak_log': 3});
      final out = await game.craft(_recipe);

      expect(out.succeeded, isTrue, reason: 'three logs are three logs');
      expect(
        game.profile.storerooms.containsKey(_town),
        isFalse,
        reason:
            'a craft that writes the Storeroom unconditionally grows an '
            'empty entry for every town the player ever crafted in',
      );
    });
  });

  group('the Workbench says where the materials are', () {
    testWidgets('the need row names the stored share', (tester) async {
      final game = _game(pack: {'oak_log': 2}, stored: {'oak_log': 1});
      await _pumpWorkbench(tester, game);

      expect(
        find.text('3 / 3 ✓ (1 stored)'),
        findsOneWidget,
        reason:
            'a row that counted the pack alone reads "2 / 3" beside a live '
            'Craft button — the disagreement materialCount exists to prevent',
      );
    });

    testWidgets('a pack-only row says nothing about storage', (tester) async {
      final game = _game(pack: {'oak_log': 3});
      await _pumpWorkbench(tester, game);

      expect(
        find.text('3 / 3 ✓'),
        findsOneWidget,
        reason: 'the ordinary row is untouched by this ruling',
      );
      expect(
        find.textContaining('stored'),
        findsNothing,
        reason:
            'an always-on "(0 stored)" is noise on every row of a shelf the '
            'player reads a dozen times a session',
      );
    });

    testWidgets('the count cell keeps its box when the share appears', (
      tester,
    ) async {
      // ⭐ Both fixtures hold 3 logs, so every row on the shelf is equally
      // craftable and sorts identically — the ONLY difference anywhere on
      // this screen is the '(1 stored)' suffix in one trailing cell.
      final label = 'Craft · +${Skills.xpForRecipe(_recipe)} XP';

      await _pumpWorkbench(tester, _game(pack: {'oak_log': 3}));
      final plainCell = tester.getRect(find.text('3 / 3 ✓'));
      final plainButton = tester.getRect(
        find.widgetWithText(FilledButton, label),
      );

      await _pumpWorkbench(
        tester,
        _game(pack: {'oak_log': 2}, stored: {'oak_log': 1}),
      );

      expect(
        tester.getRect(find.text('3 / 3 ✓ (1 stored)')),
        plainCell,
        reason:
            'a content-sized cell grows by " (1 stored)" and drags the whole '
            'row with it — the fixed trailing cell is what pins it',
      );
      expect(
        tester.getRect(find.widgetWithText(FilledButton, label)),
        plainButton,
        reason:
            'and the press-stability rule proper: a suffix that wrapped to a '
            'second line would grow the card and move the button under the '
            'player\'s finger',
      );
    });
  });
}

/// ⚠️ A tall surface, because a ListView only builds the rows that fit and
/// these tests are about a row's own layout.
Future<void> _pumpWorkbench(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 6000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(state: game, child: const CraftScreen()),
    ),
  );
  await tester.pump();
}
