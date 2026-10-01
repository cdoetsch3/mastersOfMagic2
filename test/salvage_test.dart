/// Salvage as an item-dialog action (ENCHANTING_DESIGN §6, §7): the pure
/// refusal and its order, the yield landing and the piece leaving BOTH the
/// pack and the instance pool, gems coming back whole, room counted with the
/// piece's own slot free, the XP, the one write; the dialog's Salvage… entry
/// and the sheet's copy and press-stability.
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills. The table itself (`SalvageTable`) is lane 2's
/// (`test/enchanting_recipes_test.dart`); this file owns the act.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/catalogue/gems.dart';
import 'package:masters_of_magic_2/game/items/enchants.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/recipes/enchanting_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/screens/gear_work_actions.dart';
import 'package:masters_of_magic_2/screens/salvage_sheet.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';
import 'package:mom_engine/mom_engine.dart';

/// Common, Whispering Woods → Flora.
const _common = 'oak_wand';

/// Rare, Cinderpeak Foothills → Pyro.
const _rare = 'cinder_loop';

/// Epic, Ashfall Vale → Pyro.
const _epic = 'the_charlock';

/// Common, Hallowmarch → Sanctus, two sockets.
const _socketed = 'spiritwood_wand';

const _id = 'p1';

final _pyroGem = Gems.idFor(MagicElement.pyro, EnchantTier.lesser);
final _aquaGem = Gems.idFor(MagicElement.aqua, EnchantTier.lesser);

class _Mem implements ProfileStorage {
  int saves = 0;
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    stored = profile;
  }

  @override
  Future<void> clear() async => stored = null;
}

/// A character standing [at] (a ZONE by default — salvage needs no station)
/// with [filler] Oak Logs and [pack] fungibles in the pack FIRST, then the
/// piece [_id] — so a pack of 19 filler holds the piece as its twentieth,
/// last item. [where] puts the piece on the body or in [at]'s Storeroom
/// instead.
({GameState game, _Mem disk}) _game({
  String at = 'whispering_woods',
  String defId = _common,
  ItemInstance? piece,
  String where = 'pack',
  Map<String, int> pack = const {},
  int filler = 0,
}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = 50000
    ..locationId = at;
  // ⚠️ Every achievement pre-granted, so `_earnLive` can never add a write
  // of its own — the write counts below are the salvage's alone.
  profile.achievements = {for (final a in Achievements.all) a.id};
  final instance = piece ?? ItemInstance(instanceId: _id, defId: defId);
  profile.itemInstances[instance.instanceId] = instance;
  var bp = Backpack.empty();
  for (var i = 0; i < filler; i++) {
    bp = bp.withAdded(const InventorySlot(defId: 'oak_log'))!;
  }
  pack.forEach((defId, n) {
    bp = bp.withAdded(InventorySlot(defId: defId, count: n))!;
  });
  final slot = InventorySlot(
    defId: instance.defId,
    instanceId: instance.instanceId,
  );
  switch (where) {
    case 'worn':
      profile.equipped[(ItemCatalogue.byId(instance.defId) as EquipmentDef)
              .slot] =
          instance.instanceId;
    case 'stored':
      profile.storerooms[at] = const Storeroom().withDeposited(slot);
    default:
      bp = bp.withAdded(slot)!;
  }
  profile.backpack = bp;
  final disk = _Mem();
  return (game: GameState(disk, profile), disk: disk);
}

int _xp(GameState g) => g.profile.skillXp['enchanting'] ?? 0;

bool _inPack(GameState g, String id) =>
    g.profile.backpack.contents.any((s) => s.instanceId == id);

void main() {
  group('the refusal', () {
    test('⭐ worn: take it off first — and nothing is written', () async {
      final made = _game(where: 'worn');
      final g = made.game;
      expect(
        g.salvageRefusal(_id),
        'Take it off first.',
        reason: 'a check that only looks for the instance salvages worn gear',
      );
      expect(
        await g.salvageItem(_id),
        'Take it off first.',
        reason: 'salvageItem refuses with the same pure function',
      );
      expect(
        g.profile.itemInstances.containsKey(_id),
        isTrue,
        reason: 'a refusal that still destroyed the piece',
      );
      expect(made.disk.saves, 0, reason: 'a refusal that wrote');
    });

    test('⭐ stored: bring it from the storeroom first', () {
      final g = _game(at: 'meridian', where: 'stored').game;
      expect(
        g.salvageRefusal(_id),
        'Bring it from the storeroom first.',
        reason:
            'a check that reads only the pack calls a stored piece "gone"; '
            'one that reads none salvages out of the Storeroom',
      );
    });

    test('⭐ only gear', () async {
      final made = _game(
        piece: const ItemInstance(instanceId: _id, defId: 'oak_log'),
      );
      expect(
        made.game.salvageRefusal(_id),
        'Only gear can be salvaged.',
        reason:
            'no gear check: a log instance "salvages" to an empty yield, '
            'destroying it for nothing',
      );
      expect(
        await made.game.salvageItem(_id),
        'Only gear can be salvaged.',
        reason: 'salvageItem refuses with the same words',
      );
      expect(made.disk.saves, 0, reason: 'a refusal that wrote');
    });

    test('a vanished id is gone', () {
      final g = _game().game;
      expect(
        g.salvageRefusal('nope'),
        'That item is gone.',
        reason: 'a null instance must refuse, never throw',
      );
    });

    test('⭐ no station: allowed in the field', () {
      final g = _game(at: 'whispering_woods').game;
      expect(
        g.salvageRefusal(_id),
        isNull,
        reason:
            'a salvage gated on the Meridian station like Enchant — §6 '
            'makes it field-craftable',
      );
    });

    test('⭐ room: refused when the yield would not all fit', () async {
      // Rare: a Shard and ten Dust — two slots; the piece frees one.
      final made = _game(defId: _rare, filler: 19);
      final g = made.game;
      expect(
        g.profile.backpack.isFull,
        isTrue,
        reason: 'guard: 19 logs and the ring fill the pack',
      );
      expect(
        g.salvageRefusal(_id),
        'No room in your pack for what comes out.',
        reason:
            'a room check on the first line only (the Shard) passes and the '
            'Dust is dropped',
      );
      expect(
        await g.salvageItem(_id),
        'No room in your pack for what comes out.',
        reason: 'salvageItem refuses with the same words',
      );
      expect(
        g.profile.itemInstances.containsKey(_id),
        isTrue,
        reason: 'all-or-nothing: the piece survives a refused salvage',
      );
      expect(made.disk.saves, 0, reason: 'a refusal that wrote');
    });

    test('⭐ room: the piece\'s own slot counts as free', () {
      // Common: three Dust, one slot — and the ring is the 20th, last item.
      final g = _game(filler: 19).game;
      expect(
        g.profile.backpack.isFull,
        isTrue,
        reason: 'guard: the pack is full with the piece as its last item',
      );
      expect(
        g.profile.backpack.slots.last?.instanceId,
        _id,
        reason: 'guard: the piece is the last slot',
      );
      expect(
        g.salvageRefusal(_id),
        isNull,
        reason:
            'a room check made BEFORE freeing the piece\'s slot refuses a '
            'full pack whose last item is the piece',
      );
    });

    test('⭐ room: Dust tops up a stack already carried', () {
      // Full; 15 Pyro Dust has 10 headroom, the freed slot takes the Shard.
      final g = _game(defId: _rare, filler: 18, pack: {'pyro_dust': 15}).game;
      expect(g.profile.backpack.isFull, isTrue, reason: 'guard: full');
      expect(
        g.salvageRefusal(_id),
        isNull,
        reason:
            'a room check that counts free SLOTS per line refuses what '
            'Backpack.withAdded would stack',
      );
    });

    test('⭐ room: the gems need slots too', () {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _socketed,
      ).withSocket(0, _pyroGem).withSocket(1, _aquaGem);
      // Three Sanctus Dust + two gems = three slots.
      final tight = _game(piece: piece, filler: 18).game;
      expect(
        tight.salvageRefusal(_id),
        'No room in your pack for what comes out.',
        reason:
            'a room check on the motes alone passes with two slots, and '
            'one gem is lost',
      );
      final roomy = _game(piece: piece, filler: 17).game;
      expect(
        roomy.salvageRefusal(_id),
        isNull,
        reason: 'three slots free once the piece is gone — it fits',
      );
    });
  });

  group('the act', () {
    test(
      '⭐ common: three Dust of the zone\'s lead element; piece gone',
      () async {
        final made = _game();
        final g = made.game;
        expect(await g.salvageItem(_id), isNull, reason: 'guard: allowed');
        expect(
          g.profile.backpack.countOf('flora_dust'),
          3,
          reason: 'the §6 common row, in Whispering Woods\' lead element',
        );
        expect(
          _inPack(g, _id),
          isFalse,
          reason: 'the slot must leave the pack',
        );
        expect(
          g.profile.itemInstances.containsKey(_id),
          isFalse,
          reason:
              'mutant: the slot removed and the instance left dangling in '
              'itemInstances (the one-pool rule)',
        );
        expect(made.disk.saves, 1, reason: 'one _mutate, one write');
      },
    );

    test('⭐ rare: a Shard and ten Dust', () async {
      final g = _game(defId: _rare).game;
      expect(await g.salvageItem(_id), isNull, reason: 'guard: allowed');
      expect(
        g.profile.backpack.countOf('pyro_shard'),
        1,
        reason: 'the §6 rare row\'s Shard',
      );
      expect(
        g.profile.backpack.countOf('pyro_dust'),
        10,
        reason: 'and its ten Dust — a yield that kept only the first line',
      );
      expect(
        g.profile.itemInstances.containsKey(_id),
        isFalse,
        reason: 'instance left dangling',
      );
    });

    test('⭐ epic: one Crystal', () async {
      final g = _game(defId: _epic).game;
      expect(await g.salvageItem(_id), isNull, reason: 'guard: allowed');
      expect(
        g.profile.backpack.countOf('pyro_crystal'),
        1,
        reason: 'the §6 epic row',
      );
      expect(
        g.profile.backpack.used,
        1,
        reason: 'the Crystal and nothing else: the piece\'s slot is gone',
      );
    });

    test(
      '⭐ the gems come back whole; an empty socket returns nothing',
      () async {
        final piece = const ItemInstance(
          instanceId: _id,
          defId: _socketed,
        ).withSocket(1, _aquaGem);
        final g = _game(piece: piece).game;
        expect(await g.salvageItem(_id), isNull, reason: 'guard: allowed');
        expect(
          g.profile.backpack.countOf(_aquaGem),
          1,
          reason: 'a salvage that ate the gem is the trap §6 rules out',
        );
        expect(
          g.profile.backpack.countOf('sanctus_dust'),
          3,
          reason: 'and the motes still come',
        );
        expect(
          g.profile.backpack.contents.any(
            (s) => s.defId == ItemInstance.emptySocket,
          ),
          isFalse,
          reason: 'an empty socket (socket 0) returned as an id',
        );
        expect(
          g.profile.backpack.used,
          2,
          reason: 'Dust and one gem — nothing for the empty socket',
        );
      },
    );

    test('⭐ Enchanting XP once, by the rarity table', () async {
      final made = _game(defId: _rare);
      final g = made.game;
      final before = _xp(g);
      await g.salvageItem(_id);
      expect(
        _xp(g) - before,
        25,
        reason:
            'a rare pays 25 (§8.3 table) — no XP, XP paid twice (once per '
            'yield line), or the marker formula\'s 6',
      );
      expect(made.disk.saves, 1, reason: 'the XP rides the same write');
    });

    test('📝 the formula pays 6 at every rarity', () {
      for (final rarity in Rarity.values) {
        final marker = EnchantingRecipes.salvage.firstWhere(
          (r) => r.id == EnchantingRecipes.salvageId(rarity),
        );
        expect(
          Skills.xpForRecipe(marker),
          6,
          reason:
              '$rarity: a marker given a level or a count changes what '
              'salvageXpFor reports in §8.3',
        );
      }
      expect(
        GameState.salvageXpFor(ItemCatalogue.byId(_epic) as EquipmentDef),
        50,
        reason:
            'the per-rarity table (§8.3): an epic pays 50, not the marker '
            'formula\'s 6 — kills reverting to Skills.xpForRecipe',
      );
    });
  });

  group('the item dialog', () {
    Future<GameState> pumpTab(
      WidgetTester tester, {
      required String where,
    }) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = _game(at: 'whispering_woods', where: where).game;
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: g,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return g;
    }

    VoidCallback? pressOf(WidgetTester tester, String label) => tester
        .widget<TextButton>(find.widgetWithText(TextButton, label))
        .onPressed;

    testWidgets('⭐ worn: Salvage… greyed with its reason', (tester) async {
      await pumpTab(tester, where: 'worn');
      await tester.tap(find.text('Oak Wand').first);
      await tester.pumpAndSettle();
      expect(
        find.text('$salvageActionLabel: Take it off first.'),
        findsOneWidget,
        reason: 'greyed WITH the reason, never hidden (2026-08-17)',
      );
      expect(
        pressOf(tester, salvageActionLabel),
        isNull,
        reason: 'a live Salvage… on a worn piece',
      );
    });

    testWidgets('⭐ in the pack, in the field: live, opens the sheet', (
      tester,
    ) async {
      await pumpTab(tester, where: 'pack');
      final tile = find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message ?? '').startsWith('Oak Wand'),
      );
      await tester.longPress(
        find.descendant(of: tile.first, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
      expect(
        pressOf(tester, salvageActionLabel),
        isNotNull,
        reason: 'a station gate on Salvage… — §6 is field-craftable',
      );
      await tester.tap(find.widgetWithText(TextButton, salvageActionLabel));
      await tester.pumpAndSettle();
      expect(
        find.byType(SalvageSheet),
        findsOneWidget,
        reason: 'the action opens the confirm sheet, never salvages directly',
      );
    });
  });

  group('the sheet', () {
    Future<GameState> pumpSheet(
      WidgetTester tester, {
      String at = 'whispering_woods',
      String defId = _common,
      ItemInstance? piece,
      int filler = 0,
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = _game(at: at, defId: defId, piece: piece, filler: filler).game;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SalvageSheet(game: g, instanceId: _id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lays out on a phone');
      return g;
    }

    Finder button() => find.widgetWithText(FilledButton, salvageButtonLabel);

    testWidgets('⭐ common: the yield, the plain warning, the XP', (
      tester,
    ) async {
      await pumpSheet(tester);
      expect(
        find.text('Oak Wand'),
        findsOneWidget,
        reason: 'the piece\'s name heads the sheet',
      );
      expect(
        find.text('3 Flora Dust'),
        findsOneWidget,
        reason: 'the yield as count and name, from SalvageTable',
      );
      expect(
        find.text('The piece is destroyed.'),
        findsOneWidget,
        reason:
            'an unenchanted piece is warned without an enchant it does not '
            'have',
      );
      expect(
        find.text('+6 Enchanting XP.'),
        findsOneWidget,
        reason: 'the allowed button says what the press pays',
      );
    });

    testWidgets('⭐ rare: Shard then Dust, one line', (tester) async {
      await pumpSheet(tester, defId: _rare);
      expect(
        find.text('1 Pyro Shard · 10 Pyro Dust'),
        findsOneWidget,
        reason: 'both lines of the rare row, in the table\'s order',
      );
    });

    testWidgets('⭐ gems by name; a repeat once with its count', (tester) async {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _socketed,
      ).withSocket(0, _pyroGem).withSocket(1, _pyroGem);
      await pumpSheet(tester, piece: piece);
      expect(
        find.text('3 Sanctus Dust · Lesser Pyro Gem ×2'),
        findsOneWidget,
        reason: 'a gem left off the yield, or its name printed twice',
      );
    });

    testWidgets('⭐ enchanted: the warning names the enchant', (tester) async {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _common,
      ).withEnchant('pyro_lesser');
      await pumpSheet(tester, piece: piece);
      expect(
        find.text('The piece is destroyed. Its Charred enchant goes with it.'),
        findsOneWidget,
        reason: 'an enchanted piece must say what else is lost',
      );
    });

    testWidgets('an aspect alone is not an enchant', (tester) async {
      const piece = ItemInstance(
        instanceId: _id,
        defId: _common,
        aspect: MagicElement.pyro,
      );
      await pumpSheet(tester, piece: piece);
      expect(
        find.text('The piece is destroyed.'),
        findsOneWidget,
        reason: 'a warning that reads the aspect as an enchant',
      );
    });

    testWidgets('⭐ refused: greyed, with the reason beside it', (tester) async {
      await pumpSheet(tester, defId: _rare, filler: 19);
      expect(
        tester.widget<FilledButton>(button()).onPressed,
        isNull,
        reason: 'a live button on a salvage that cannot fit',
      );
      expect(
        find.text('No room in your pack for what comes out.'),
        findsOneWidget,
        reason: 'a greyed button always carries its reason',
      );
    });

    testWidgets('⭐ press-stable: refused → allowed → pressed', (tester) async {
      final g = await pumpSheet(
        tester,
        at: 'meridian',
        defId: _rare,
        filler: 19,
      );
      expect(
        tester.widget<FilledButton>(button()).onPressed,
        isNull,
        reason: 'guard: refused for room',
      );
      final refused = tester.getRect(button());

      // Stow one log: a slot frees, and the Shard and the Dust now fit.
      await g.deposit('meridian', 0);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(button()).onPressed,
        isNotNull,
        reason: 'guard: the sheet is live — room arriving allows it',
      );
      expect(
        tester.getRect(button()),
        refused,
        reason: 'the reason clearing must not move the button',
      );
      expect(
        find.text('+25 Enchanting XP.'),
        findsOneWidget,
        reason: 'the note swaps from the refusal to the XP',
      );

      await tester.tap(button());
      await tester.pumpAndSettle();
      expect(
        g.profile.itemInstances.containsKey(_id),
        isFalse,
        reason: 'the press salvages',
      );
      expect(
        g.profile.backpack.countOf('pyro_shard'),
        1,
        reason: 'and the yield lands',
      );
      expect(
        Carrying.backpackSlots,
        20,
        reason: 'guard: the filler arithmetic above assumes twenty slots',
      );
    });
  });
}
