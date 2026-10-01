/// The enchanting build, lane 3 — the surfaces (ENCHANTING_DESIGN §4.2, §4.3,
/// §5.2, §7): the three instance mutations with their station, level, mote,
/// socket and room gates; the item dialog's Enchant… and Socket…; the two
/// sheets; and the "From equipment" panel's view of the overlay.
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills. The model and overlay arithmetic are lane 1's
/// (`test/enchanting_model_test.dart`); this file owns what the player can DO
/// to a piece and what they are told.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/achievements.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/catalogue/gems.dart';
import 'package:masters_of_magic_2/game/items/enchants.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/screens/enchant_sheet.dart';
import 'package:masters_of_magic_2/screens/socket_sheet.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';
import 'package:masters_of_magic_2/ui/item_display.dart';
import 'package:mom_engine/mom_engine.dart';

/// Two sockets, no properName — so the aspect prefix shows in its name.
const _wand = 'spiritwood_wand';

/// No sockets.
const _belt = 'fawnhide_belt';

const _id = 'w1';

final _pyroLesser = Enchants.of(MagicElement.pyro, EnchantTier.lesser);
final _pyroStandard = Enchants.of(MagicElement.pyro, EnchantTier.standard);
final _pyroGreater = Enchants.of(MagicElement.pyro, EnchantTier.greater);
final _aquaLesser = Enchants.of(MagicElement.aqua, EnchantTier.lesser);
final _pyroGem = Gems.idFor(MagicElement.pyro, EnchantTier.lesser);
final _aquaGem = Gems.idFor(MagicElement.aqua, EnchantTier.lesser);

/// Total XP at the start of [level].
int _xpAt(int level) {
  var total = 0;
  for (var l = 1; l < level; l++) {
    total += Skills.xpToNext(l);
  }
  return total;
}

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

/// A character standing [at], holding the wand [_id] (in the pack, or worn
/// when [worn]), with [pack] and [stored] fungibles.
({GameState game, _Mem disk}) _game({
  String at = 'meridian',
  int level = 1,
  String defId = _wand,
  ItemInstance? piece,
  bool worn = false,
  Map<String, int> pack = const {},
  Map<String, int> stored = const {},
  int filler = 0,
}) {
  final profile = PlayerProfile.newPlayer()
    ..xp = 50000
    ..locationId = at;
  // ⚠️ Every achievement pre-granted, so `_earnLive` after a mutation can
  // never add a write of its own — the write counts below are the
  // mutation's alone.
  profile.achievements = {for (final a in Achievements.all) a.id};
  profile.skillXp['enchanting'] = _xpAt(level);
  final instance = piece ?? ItemInstance(instanceId: _id, defId: defId);
  profile.itemInstances[instance.instanceId] = instance;
  var bp = Backpack.empty();
  if (worn) {
    profile.equipped[(ItemCatalogue.byId(instance.defId) as EquipmentDef)
            .slot] =
        instance.instanceId;
  } else {
    bp = bp.withAdded(
      InventorySlot(defId: instance.defId, instanceId: instance.instanceId),
    )!;
  }
  pack.forEach((defId, n) {
    for (var i = 0; i < n; i++) {
      bp = bp.withAdded(InventorySlot(defId: defId))!;
    }
  });
  for (var i = 0; i < filler; i++) {
    bp = bp.withAdded(const InventorySlot(defId: 'oak_log'))!;
  }
  profile.backpack = bp;
  if (stored.isNotEmpty) profile.storerooms[at] = Storeroom(stacks: stored);
  final disk = _Mem();
  return (game: GameState(disk, profile), disk: disk);
}

ItemInstance _inst(GameState g) => g.profile.itemInstances[_id]!;

void main() {
  group('the station gate', () {
    test('⭐ Enchant refuses away from Meridian, naming it', () {
      final g = _game(at: 'pennycross', pack: {'pyro_shard': 5}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        'Needs the Meridian station.',
        reason:
            'a gate that never reads World.byId(location).station lets the '
            'field enchant — the tier gate §4.2 says must be station-bound',
      );
    });

    test('Rimeholt is not an Enchanting station', () {
      final g = _game(at: 'rimeholt', pack: {'pyro_shard': 5}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        'Needs the Meridian station.',
        reason: 'a gate that accepts ANY station would pass here',
      );
    });

    test('a zone is never a station, even with motes in hand', () {
      final g = _game(at: 'whispering_woods', pack: {'pyro_shard': 5}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        'Needs the Meridian station.',
        reason: 'a gate that only checks "not a different station" passes',
      );
    });

    test('⭐ Zenith has every station', () {
      final g = _game(at: 'zenith', pack: {'pyro_shard': 5, _pyroGem: 1}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        isNull,
        reason:
            'a gate matching the station string exactly refuses Zenith, '
            'whose string is "Every station — …"',
      );
      expect(
        g.socketRefusal(_id, 0, _pyroGem),
        isNull,
        reason: 'and Zenith seats gems too',
      );
    });

    test('⭐ Socket and Take out refuse away from Rimeholt, naming it', () {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withSocket(0, _pyroGem);
      final g = _game(
        at: 'meridian',
        piece: piece,
        pack: {_pyroGem: 1, 'pyro_shard': 1},
      ).game;
      expect(
        g.socketRefusal(_id, 1, _pyroGem),
        'Needs the Rimeholt station.',
        reason: 'Socket shares Enchanting\'s gate by mistake',
      );
      expect(
        g.unsocketRefusal(_id, 0),
        'Needs the Rimeholt station.',
        reason: 'Take out is done at Rimeholt too (§5.2)',
      );
    });
  });

  group('Enchant', () {
    test('⭐ the level gates: 15 for Standard, 30 for Greater', () {
      final g = _game(
        level: 14,
        pack: {'pyro_crystal': 3, 'pyro_core': 1},
      ).game;
      expect(
        g.enchantRefusal(_id, _pyroStandard),
        'Enchanting 15 needed.',
        reason: 'no level gate, or the wrong tier\'s number',
      );
      expect(
        g.enchantRefusal(_id, _pyroGreater),
        'Enchanting 30 needed.',
        reason: 'Greater reads its own gate, not Standard\'s',
      );
      final at15 = _game(level: 15, pack: {'pyro_crystal': 3}).game;
      expect(
        at15.enchantRefusal(_id, _pyroStandard),
        isNull,
        reason: 'exactly 15 passes — a `<=` gate refuses it',
      );
    });

    test('⭐ short motes are counted and named', () {
      final g = _game(pack: {'pyro_shard': 3}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        'Needs 2 more Pyro Shards.',
        reason: 'Lesser costs 5 Shards; a cost of 3 would pass here',
      );
      final one = _game(pack: {'pyro_shard': 4}).game;
      expect(
        one.enchantRefusal(_id, _pyroLesser),
        'Needs 1 more Pyro Shard.',
        reason:
            'one is singular — "1 more Pyro Shards" is the unpluralised '
            'mutant',
      );
      final crystals = _game(level: 15, pack: {'pyro_crystal': 2}).game;
      expect(
        crystals.enchantRefusal(_id, _pyroStandard),
        'Needs 1 more Pyro Crystal.',
        reason: 'Standard spends Crystals, three of them',
      );
    });

    test('⭐ the Storeroom counts, as it does for a craft', () {
      final g = _game(pack: {'pyro_shard': 3}, stored: {'pyro_shard': 2}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        isNull,
        reason: 'a gate reading the pack alone refuses 3 + 2 stored',
      );
    });

    test('⭐ spends exactly five Shards, pack first, and writes once', () async {
      final made = _game(pack: {'pyro_shard': 3}, stored: {'pyro_shard': 4});
      final g = made.game;
      expect(await g.enchantItem(_id, _pyroLesser), isNull);
      expect(
        g.profile.backpack.countOf('pyro_shard'),
        0,
        reason: 'pack first — a Storeroom-first spend leaves the pack\'s 3',
      );
      expect(
        g.profile.storerooms['meridian']!.stacks['pyro_shard'],
        2,
        reason: '5 spent in all: 3 from the pack, 2 from storage',
      );
      expect(
        _inst(g).enchantId,
        'pyro_lesser',
        reason: 'the instance is replaced with withEnchant',
      );
      expect(
        _inst(g).aspect,
        MagicElement.pyro,
        reason: 'and named by its prefix',
      );
      expect(
        made.disk.saves,
        1,
        reason:
            'ONE _mutate — a spend and an enchant written apart can land '
            'half on disk',
      );
    });

    test('⭐ pays 40 / 120 / 400 Enchanting XP by tier', () async {
      for (final (enchant, cost, xp) in [
        (_pyroLesser, {'pyro_shard': 5}, 40),
        (_pyroStandard, {'pyro_crystal': 3}, 120),
        (_pyroGreater, {'pyro_core': 1}, 400),
      ]) {
        final g = _game(level: 30, pack: cost).game;
        final before = g.profile.skillXp['enchanting']!;
        await g.enchantItem(_id, enchant);
        expect(
          g.profile.skillXp['enchanting']! - before,
          xp,
          reason:
              '${enchant.tier.label} pays $xp — a flat or recipe-formula '
              'payout reads differently',
        );
        expect(
          g.profile.backpack.countOf(EnchantingCosts.of(enchant).defId),
          0,
          reason: '${enchant.tier.label} spends its whole cost',
        );
      }
    });

    test('⭐ a refusal spends nothing and writes nothing', () async {
      final made = _game(pack: {'pyro_shard': 4});
      expect(
        await made.game.enchantItem(_id, _pyroLesser),
        'Needs 1 more Pyro Shard.',
        reason: 'the mutation refuses with the pure refusal\'s words',
      );
      expect(
        made.game.profile.backpack.countOf('pyro_shard'),
        4,
        reason: 'a refused enchant that spent anyway',
      );
      expect(
        _inst(made.game).enchantId,
        isNull,
        reason: 'a refused enchant that applied anyway',
      );
      expect(made.disk.saves, 0, reason: 'a refusal that wrote');
    });

    test('⭐ re-enchanting costs the FULL price (§4.3)', () async {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withEnchant('pyro_lesser');
      final short = _game(piece: piece, pack: {'aqua_shard': 4}).game;
      expect(
        short.enchantRefusal(_id, _aquaLesser),
        'Needs 1 more Aqua Shard.',
        reason: 'SYSTEMS §3.6\'s half price (3) would pass with 4 — declined',
      );
      final g = _game(piece: piece, pack: {'aqua_shard': 5}).game;
      expect(await g.enchantItem(_id, _aquaLesser), isNull);
      expect(
        g.profile.backpack.countOf('aqua_shard'),
        0,
        reason: 'all five spent on a piece that already wore an enchant',
      );
      expect(
        _inst(g).enchantId,
        'aqua_lesser',
        reason: 'the new enchant replaces the old',
      );
    });

    test('the same enchant again is refused — it would change nothing', () {
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withEnchant('pyro_lesser');
      final g = _game(piece: piece, pack: {'pyro_shard': 5}).game;
      expect(
        g.enchantRefusal(_id, _pyroLesser),
        'It already carries Charred (Lesser).',
        reason: 'five Shards spent to rewrite the identical enchant',
      );
      expect(
        g.enchantRefusal(_id, _pyroStandard),
        'Enchanting 15 needed.',
        reason: 'a different tier of the same element is a real change',
      );
    });

    test('works on a worn piece', () async {
      final g = _game(worn: true, pack: {'pyro_shard': 5}).game;
      expect(await g.enchantItem(_id, _pyroLesser), isNull);
      expect(
        g.equipmentTotals.critDamage,
        (ItemCatalogue.byId(_wand) as EquipmentDef).modifiers.critDamage + 4,
        reason: 'the totals read the rewritten instance — +4 crit damage',
      );
    });

    test('a missing instance is refused, never thrown', () {
      final g = _game(pack: {'pyro_shard': 5}).game;
      expect(
        g.enchantRefusal('nope', _pyroLesser),
        'That item is gone.',
        reason: 'a dangling id must not throw inside a refusal',
      );
    });
  });

  group('Socket', () {
    test('⭐ the gates, in order', () {
      final full = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withSocket(0, _pyroGem);
      final g = _game(at: 'rimeholt', piece: full, pack: {_aquaGem: 1}).game;
      expect(
        g.socketRefusal(_id, 2, _aquaGem),
        'It has no socket there.',
        reason: 'a two-socket wand has no index 2 — withSocket would pad it',
      );
      expect(
        g.socketRefusal(_id, 0, _aquaGem),
        'That socket is full — take the gem out first.',
        reason: 'socketing over a gem would destroy it',
      );
      expect(
        g.socketRefusal(_id, 1, _pyroGem),
        'Needs 1 more Lesser Pyro Gem.',
        reason: 'no gem to hand — a gate that skips the count mints one',
      );
      expect(
        g.socketRefusal(_id, 1, _aquaGem),
        isNull,
        reason: 'the empty socket takes the held gem',
      );
    });

    test('⭐ spends exactly one gem and seats it, in one write', () async {
      final made = _game(at: 'rimeholt', pack: {_pyroGem: 2});
      final g = made.game;
      expect(await g.socketGem(_id, 1, _pyroGem), isNull);
      expect(
        g.profile.backpack.countOf(_pyroGem),
        1,
        reason: 'one gem spent, not both and not none',
      );
      expect(_inst(g).socketed, [
        ItemInstance.emptySocket,
        _pyroGem,
      ], reason: 'seated at index 1, index 0 left empty');
      expect(made.disk.saves, 1, reason: 'one _mutate');
    });

    test('a gem in the Storeroom is spent from there', () async {
      final g = _game(at: 'rimeholt', stored: {_pyroGem: 1}).game;
      expect(
        await g.socketGem(_id, 0, _pyroGem),
        isNull,
        reason: 'a gate reading the pack alone refuses a stored gem',
      );
      expect(
        g.profile.storerooms['rimeholt']!.stacks[_pyroGem],
        isNull,
        reason: 'the stored gem was the one spent',
      );
    });
  });

  group('Take out', () {
    final socketed = const ItemInstance(
      instanceId: _id,
      defId: _wand,
    ).withSocket(0, _pyroGem);

    test('⭐ costs one Shard of the gem\'s element', () {
      final g = _game(
        at: 'rimeholt',
        piece: socketed,
        pack: {'aqua_shard': 3},
      ).game;
      expect(
        g.unsocketRefusal(_id, 0),
        'Needs 1 more Pyro Shard.',
        reason: 'the GEM\'s element — any-Shard would pass on Aqua',
      );
      expect(
        g.unsocketRefusal(_id, 1),
        'That socket is empty.',
        reason: 'nothing to take out of an empty socket',
      );
    });

    test(
      '⭐ spends one Shard, returns the gem, empties the socket, once',
      () async {
        final made = _game(
          at: 'rimeholt',
          piece: socketed,
          pack: {'pyro_shard': 3},
        );
        final g = made.game;
        expect(await g.unsocketGem(_id, 0), isNull);
        expect(
          g.profile.backpack.countOf('pyro_shard'),
          2,
          reason: 'exactly one Shard',
        );
        expect(
          g.profile.backpack.countOf(_pyroGem),
          1,
          reason: 'the gem survives (§5.2) — a removal that eats it',
        );
        expect(_inst(g).socketed, isEmpty, reason: 'the socket is emptied');
        expect(made.disk.saves, 1, reason: 'one _mutate');
      },
    );

    test('⭐ a full pack refuses — the gem must land somewhere', () {
      final g = _game(
        at: 'rimeholt',
        piece: socketed,
        stored: {'pyro_shard': 1},
        filler: Carrying.backpackSlots - 1,
      ).game;
      expect(
        g.unsocketRefusal(_id, 0),
        'No room in your pack for the gem.',
        reason: 'a take-out that drops the gem on a full pack',
      );
    });

    test('room is asked AFTER the Shard is paid', () {
      // The pack's last slot is the one Shard: spending it frees the slot.
      final g = _game(
        at: 'rimeholt',
        piece: socketed,
        pack: {'pyro_shard': 1},
        filler: Carrying.backpackSlots - 2,
      ).game;
      expect(g.profile.backpack.isFull, isTrue, reason: 'guard: full pack');
      expect(
        g.unsocketRefusal(_id, 0),
        isNull,
        reason: 'a room check before the spend refuses a take-out that fits',
      );
    });
  });

  group('the item dialog', () {
    testWidgets('⭐ an enchanted, socketed piece prints every overlay line', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withEnchant('pyro_standard').withSocket(0, _pyroGem);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showItemDialog(
                    context,
                    def: ItemCatalogue.byId(_wand),
                    instance: piece,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      for (final line in [
        '+14% crit damage',
        'Enchant: Charred (Standard) · +8% crit damage',
        'Socket: Lesser Pyro Gem · +2% crit damage',
        'Socket: empty',
      ]) {
        expect(
          find.text(line),
          findsOneWidget,
          reason:
              '"$line" — a dialog still printing describe(modifiersOf) sums '
              'the overlay into one +24% line and names nothing',
        );
      }
      expect(
        find.text('Charred Spiritwood Wand'),
        findsOneWidget,
        reason: 'the aspect prefix names the piece',
      );
    });
  });

  group('the Inventory tab', () {
    Future<GameState> pumpTab(
      WidgetTester tester, {
      required String at,
      String defId = _wand,
    }) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = _game(at: at, defId: defId).game;
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: g,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = find.byWidgetPredicate(
        (w) =>
            w is Tooltip &&
            (w.message ?? '').startsWith(
              ItemCatalogue.displayName(ItemCatalogue.byId(defId)),
            ),
      );
      await tester.longPress(
        find.descendant(of: tile.first, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
      return g;
    }

    VoidCallback? pressOf(WidgetTester tester, String label) => tester
        .widget<TextButton>(find.widgetWithText(TextButton, label))
        .onPressed;

    testWidgets('⭐ away from both stations: both greyed, each with its town', (
      tester,
    ) async {
      await pumpTab(tester, at: 'pennycross');
      expect(
        find.text('Enchant…: Needs the Meridian station.'),
        findsOneWidget,
        reason: 'greyed WITH the reason, never hidden (2026-08-17)',
      );
      expect(
        find.text('Socket…: Needs the Rimeholt station.'),
        findsOneWidget,
        reason: 'Socket names its own town, not Enchanting\'s',
      );
      expect(
        pressOf(tester, 'Enchant…'),
        isNull,
        reason: 'a live button that refuses on tap',
      );
      expect(
        pressOf(tester, 'Socket…'),
        isNull,
        reason: 'a live button that refuses on tap',
      );
    });

    testWidgets('⭐ at Meridian: Enchant… is live and opens the sheet', (
      tester,
    ) async {
      await pumpTab(tester, at: 'meridian');
      expect(
        pressOf(tester, 'Enchant…'),
        isNotNull,
        reason: 'the station gate passes at Meridian',
      );
      expect(
        pressOf(tester, 'Socket…'),
        isNull,
        reason: 'Meridian is not a Jewelry station',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Enchant…'));
      await tester.pumpAndSettle();
      expect(
        find.byType(EnchantSheet),
        findsOneWidget,
        reason: 'the action opens the picker',
      );
    });

    testWidgets('a piece with no sockets offers no Socket… at all', (
      tester,
    ) async {
      await pumpTab(tester, at: 'pennycross', defId: _belt);
      expect(
        find.textContaining('Socket…'),
        findsNothing,
        reason: 'a greyed Socket… on a belt promises what no trip can give',
      );
      expect(
        find.text('Enchant…: Needs the Meridian station.'),
        findsOneWidget,
        reason: 'every slot takes an enchant (§4.1)',
      );
    });

    testWidgets('⭐ the From-equipment panel sums the overlay and the proc', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final piece = const ItemInstance(
        instanceId: _id,
        defId: _wand,
      ).withEnchant('pyro_greater');
      final g = _game(piece: piece, worn: true).game;
      final lines = Equipping.statTotals(g.equipmentTotals, level: 1);
      expect(
        lines.firstWhere((l) => l.label == 'Crit damage').bonus,
        14 + 14,
        reason:
            'the wand\'s +14 and the Greater enchant\'s +14 — totals that '
            'skip the overlay read 14',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: g,
            child: const Scaffold(body: InventoryTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ignite on hit'),
        findsOneWidget,
        reason: 'the Greater proc reaches the panel',
      );
    });
  });

  group('the Enchant sheet', () {
    Future<GameState> pumpSheet(
      WidgetTester tester, {
      ItemInstance? piece,
      int level = 1,
      Map<String, int> pack = const {},
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = _game(piece: piece, level: level, pack: pack).game;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnchantSheet(game: g, instanceId: _id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lays out on a phone');
      return g;
    }

    Finder button() => find.widgetWithText(FilledButton, enchantButtonLabel);

    testWidgets('⭐ twelve chips: the prefix, the element under it', (
      tester,
    ) async {
      await pumpSheet(tester);
      for (final e in MagicElement.values) {
        expect(
          find.text(Enchants.of(e, EnchantTier.lesser).prefix),
          findsOneWidget,
          reason: '${e.displayName}\'s chip shows its prefix',
        );
        expect(
          find.text(e.displayName),
          findsOneWidget,
          reason: 'and the element it means, once',
        );
      }
    });

    testWidgets('⭐ the rows: cost against what you have, the stat, the proc', (
      tester,
    ) async {
      await pumpSheet(tester, pack: {'pyro_shard': 3});
      await tester.tap(find.text('Charred'));
      await tester.pumpAndSettle();
      for (final text in [
        '3 / 5 Pyro Shards',
        '0 / 3 Pyro Crystals',
        '0 / 1 Pyro Core',
      ]) {
        expect(
          find.text(text, findRichText: true),
          findsOneWidget,
          reason: '"$text" — what you HAVE beside what it costs',
        );
      }
      for (final text in [
        '+4% crit damage',
        '+8% crit damage',
        '+14% crit damage',
        '15% on hit: Ignite',
      ]) {
        expect(
          find.text(text),
          findsOneWidget,
          reason: '"$text" in describe wording, Greater with its proc',
        );
      }
      expect(
        find.text('Needs 2 more Pyro Shards.'),
        findsOneWidget,
        reason: 'the greyed button carries enchantRefusal\'s words',
      );
      expect(
        tester.widget<FilledButton>(button()).onPressed,
        isNull,
        reason: 'greyed while refused',
      );
    });

    testWidgets('the current enchant is marked, and what goes is said', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        level: 15,
        piece: const ItemInstance(
          instanceId: _id,
          defId: _wand,
        ).withEnchant('pyro_lesser'),
        pack: {'pyro_crystal': 3},
      );
      expect(
        find.text(' · current'),
        findsOneWidget,
        reason: 'opens on the piece\'s own element, its tier marked',
      );
      expect(
        find.text('It already carries Charred (Lesser).'),
        findsOneWidget,
        reason: 'opens on the current tier, refused as a no-op',
      );
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();
      expect(
        find.text('Replaces Charred (Lesser).'),
        findsOneWidget,
        reason: 'a full-cost re-enchant says what it overwrites',
      );
    });

    testWidgets('⭐ press-stable: refused → allowed → refused, never moves', (
      tester,
    ) async {
      final g = await pumpSheet(tester, pack: {'pyro_shard': 5});
      await tester.tap(find.text('Charred'));
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enchanting 15 needed.'),
        findsOneWidget,
        reason: 'guard: Standard is refused at level 1',
      );
      final refused = tester.getRect(button());

      await tester.tap(find.text('Lesser'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(button()).onPressed,
        isNotNull,
        reason: 'guard: Lesser is allowed with five Shards',
      );
      expect(
        tester.getRect(button()),
        refused,
        reason: 'the reason clearing must not move the button',
      );

      await tester.tap(button());
      await tester.pumpAndSettle();
      expect(_inst(g).enchantId, 'pyro_lesser', reason: 'the press enchants');
      expect(
        find.text('It already carries Charred (Lesser).'),
        findsOneWidget,
        reason: 'the sheet is live: the new state refuses a repeat',
      );
      expect(
        tester.getRect(button()),
        refused,
        reason:
            'a reason arriving must not move it — nor the piece\'s new '
            'name (Charred …) wrapping the title onto a second line',
      );
    });
  });

  group('the Socket sheet', () {
    Future<GameState> pumpSheet(
      WidgetTester tester, {
      ItemInstance? piece,
      Map<String, int> pack = const {},
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = _game(at: 'rimeholt', piece: piece, pack: pack).game;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocketSheet(game: g, instanceId: _id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lays out on a phone');
      return g;
    }

    Finder button(String label) => find.widgetWithText(FilledButton, label);

    testWidgets('no gems: the reason says so', (tester) async {
      await pumpSheet(tester);
      expect(
        find.text(emptySocketLabel),
        findsNWidgets(2),
        reason: 'one cell per socket, both empty',
      );
      expect(
        find.text(noGemsReason),
        findsOneWidget,
        reason: 'the greyed Put in carries its reason',
      );
    });

    testWidgets('⭐ pick, put in, take out — the button never moves', (
      tester,
    ) async {
      final g = await pumpSheet(tester, pack: {_pyroGem: 1, 'pyro_shard': 1});
      expect(
        find.text(pickAGemReason),
        findsOneWidget,
        reason: 'nothing chosen yet',
      );
      final at = tester.getRect(button(putInLabel));

      await tester.tap(find.text('Lesser Pyro Gem'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(button(putInLabel)).onPressed,
        isNotNull,
        reason: 'a held gem, an empty socket, at Rimeholt',
      );
      expect(
        tester.getRect(button(putInLabel)),
        at,
        reason: 'the reason clearing must not move the button',
      );

      await tester.tap(button(putInLabel));
      await tester.pumpAndSettle();
      expect(_inst(g).socketed, [_pyroGem], reason: 'seated in socket 0');
      expect(
        find.text('+2% crit damage'),
        findsOneWidget,
        reason: 'the filled cell shows what the gem adds here',
      );
      expect(
        find.text('Costs 1 Pyro Shard — you have 1.'),
        findsOneWidget,
        reason: 'the filled socket offers Take out with its Shard cost',
      );
      expect(
        tester.getRect(button(takeOutLabel)),
        at,
        reason: 'Put in becoming Take out moves nothing',
      );

      await tester.tap(button(takeOutLabel));
      await tester.pumpAndSettle();
      expect(_inst(g).socketed, isEmpty, reason: 'taken out');
      expect(
        g.profile.backpack.countOf(_pyroGem),
        1,
        reason: 'the gem is back in the pack',
      );
      expect(
        g.profile.backpack.countOf('pyro_shard'),
        0,
        reason: 'the Shard paid for it',
      );
    });
  });
}
