/// Consumable potency — the belt's stat (ruling, Christian 2026-09-25:
/// "approved as designed").
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — the belt that ignores its quality roll, the quality roll that
/// leaks into belt slots, the road that skips the belt, the Tonic that rounds
/// once instead of per tick, the duel mage built without it, and the dialog
/// that forgets (or over-remembers) the line.
///
/// ⚠️ **Quality is the SHIPPED ladder, 80/100/120/140** (`Quality.statPercent`),
/// not the 0.8/1.0/1.3/1.6 the ruling's mockup quoted — the ruling said to
/// verify and use what items already use. So a Master Fawnhide reads +14%,
/// not +16%, and a Master Blankspine +42%, not +48%.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/ui/item_display.dart';
import 'package:mom_engine/mom_engine.dart';

/// The ruled table: id → (tier, base potency = 5 × tier + 5).
const _belts = {
  'fawnhide_belt': (1, 10),
  'tuskhide_belt': (2, 15),
  'rimepelt_belt': (3, 20),
  'emberhide_belt': (3, 20),
  'drownling_belt': (4, 25),
  'palimpsest_belt': (4, 25),
  'corebiter_belt': (5, 30),
  'penitent_belt': (5, 30),
  'blankspine_belt': (5, 30),
};

ItemInstance _roll(String defId, Quality? q) =>
    ItemInstance(instanceId: 'i-$defId', defId: defId, quality: q);

ItemModifiers _worn(String defId, Quality? q) =>
    Equipping.modifiersOf(ItemCatalogue.byId(defId), _roll(defId, q));

AdventureRun _run(int hp) => AdventureRun.roll(
  zone: World.byId('whispering_woods'),
  roster: const [],
  playerHp: hp,
  rng: Random(1),
);

void main() {
  group('the catalogue', () {
    test('⭐ every belt carries its tier\'s potency, and no belt is missed', () {
      final shipped = {
        for (final d in ItemCatalogue.all.whereType<EquipmentDef>())
          if (d.slot == EquipSlot.belt)
            d.id: d.modifiers.consumablePotencyPercent,
      };
      expect(
        shipped,
        {for (final e in _belts.entries) e.key: e.value.$2},
        reason:
            '5 × tier + 5 for all nine — a belt added later without a '
            'potency (or one left at 0) fails here',
      );
    });

    test('nothing but a belt carries potency', () {
      final others = [
        for (final d in ItemCatalogue.all.whereType<EquipmentDef>())
          if (d.slot != EquipSlot.belt &&
              d.modifiers.consumablePotencyPercent != 0)
            d.id,
      ];
      expect(
        others,
        isEmpty,
        reason: 'the ruling is the belt\'s stat; a hat with potency is a leak',
      );
    });
  });

  group('quality', () {
    test('⭐ a Master Fawnhide reads +14 — potency scales with the roll', () {
      expect(
        _worn('fawnhide_belt', Quality.master).consumablePotencyPercent,
        14,
        reason:
            '10 × 1.40 — a scaledBy that forgot the field reads the base 10',
      );
    });

    test('a Rough one reads +8, a Standard one the base', () {
      expect(
        _worn('fawnhide_belt', Quality.rough).consumablePotencyPercent,
        8,
        reason: '10 × 0.80',
      );
      expect(
        _worn('fawnhide_belt', null).consumablePotencyPercent,
        10,
        reason: 'null is Standard — a drop keeps the definition\'s number',
      );
    });

    test('a Master Blankspine reads +42', () {
      expect(
        _worn('blankspine_belt', Quality.master).consumablePotencyPercent,
        42,
        reason: '30 × 1.40 — the top of the ladder',
      );
    });

    test('⚠️ belt SLOTS still never scale', () {
      expect(
        _worn('tuskhide_belt', Quality.master).beltSlots,
        2,
        reason:
            'capacity is not a strength — a scaledBy that scaled beltSlots '
            'alongside potency reads 2 × 1.40 → 3',
      );
    });

    test('it crosses the wire, both ways', () {
      const m = ItemModifiers(beltSlots: 1, consumablePotencyPercent: 14);
      expect(
        ItemModifiers.fromJson(m.toJson()).consumablePotencyPercent,
        14,
        reason:
            'PvP builds the opponent from their handshake gear — a field '
            'that fails to cross is a drink the two clients heal differently',
      );
      expect(
        const ItemModifiers(consumablePotencyPercent: 1).isEmpty,
        isFalse,
        reason: 'a potency-only item is not "no modifiers"',
      );
      expect(
        (m + m).consumablePotencyPercent,
        28,
        reason: 'summed like every other line',
      );
    });
  });

  group('applyPotency', () {
    test('⭐ 30 at +16% is 35, rounded', () {
      expect(
        applyPotency(30, 16),
        35,
        reason: '30 × 1.16 = 34.8 — truncation reads 34',
      );
    });
  });

  group('on the road', () {
    test('⭐ a Sapwort Draught heals 34 with a Master Fawnhide, 30 without', () {
      final potency = _worn(
        'fawnhide_belt',
        Quality.master,
      ).consumablePotencyPercent;
      final withBelt = _run(1)
        ..use(
          'sapwort_draught',
          maxHp: 1000,
          carried: true,
          consumablePotencyPercent: potency,
        );
      final without = _run(1)
        ..use('sapwort_draught', maxHp: 1000, carried: true);
      expect(
        withBelt.playerHp - 1,
        34,
        reason: '30 × 1.14 = 34.2 — a road that ignored the belt heals 30',
      );
      expect(without.playerHp - 1, 30, reason: 'no belt, the bottle\'s 30');
    });

    test('a Standard Tuskhide makes it 35', () {
      final run = _run(1)
        ..use(
          'sapwort_draught',
          maxHp: 1000,
          carried: true,
          consumablePotencyPercent: _worn(
            'tuskhide_belt',
            null,
          ).consumablePotencyPercent,
        );
      expect(
        run.playerHp - 1,
        35,
        reason: '30 × 1.15 = 34.5, half away from zero',
      );
    });

    test('⭐ a Tonic scales tick by tick, as it would in a duel', () {
      final run = _run(1)
        ..use(
          'brookmint_tonic',
          maxHp: 1000,
          carried: true,
          consumablePotencyPercent: 14,
        );
      expect(
        run.playerHp - 1,
        33,
        reason:
            '3 ticks of 10 × 1.14 → 11 each = 33. Scaling the 30 lump '
            'reads 34 — one HP the duel would never have paid',
      );
    });

    test('⭐ potency and healing received multiply', () {
      final run = _run(1)
        ..use(
          'sapwort_draught',
          maxHp: 1000,
          carried: true,
          consumablePotencyPercent: 16,
          healingReceivedPercent: 10,
        );
      expect(
        run.playerHp - 1,
        39,
        reason:
            '30 → 35 (potency), then 35 × 1.10 = 38.5 → 39. The additive '
            'mutant (30 × 1.26 = 37.8) reads 38 — which is also what one '
            'rounding at the end would read, so this pins the two stages',
      );
    });

    test('⭐ GameState hands the worn belt\'s potency to the road', () async {
      final g = GameState(_Mem(), PlayerProfile.newPlayer());
      await g.beginAdventure(World.byId('whispering_woods'), rng: Random(1));
      final belt = _roll('fawnhide_belt', Quality.master);
      g.profile.itemInstances = {belt.instanceId: belt};
      g.profile.equipped = {EquipSlot.belt: belt.instanceId};
      g.profile.backpack = g.profile.backpack.withAdded(
        const InventorySlot(defId: 'sapwort_draught'),
      )!;
      g.run!.playerHp = 10;
      await g.useItem('sapwort_draught');
      expect(
        g.run!.playerHp,
        44,
        reason: '10 + 34 — useItem that forgot the belt restores 30 → 40',
      );

      // ⚠️ And the belt's own door, which is a separate call site.
      g.profile.belt = const Belt(loaded: ['sapwort_draught']);
      g.run!.playerHp = 10;
      await g.useBeltItem('sapwort_draught');
      expect(
        g.run!.playerHp,
        44,
        reason:
            'drinking off the hip between fights — useBeltItem that forgot '
            'the belt restores 30 → 40',
      );
    });
  });

  group('in a duel', () {
    test('⭐ each mage is built with its OWN belt\'s potency', () {
      final c = DuelController(
        loadout: Loadout.starter,
        driver: _Driver(const ItemModifiers(consumablePotencyPercent: 30)),
        playerGear: const ItemModifiers(consumablePotencyPercent: 20),
      );
      expect(
        c.player.consumablePotencyPercent,
        20,
        reason: 'the player\'s belt reaches the player\'s mage',
      );
      expect(
        c.enemy.consumablePotencyPercent,
        30,
        reason:
            'the opponent\'s belt arrives in THEIR gear — both lockstep '
            'clients must build the same number for the same drinker',
      );
    });
  });

  group('the item dialog', () {
    Future<void> open(WidgetTester tester, String defId, Quality? q) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showItemDialog(
                    context,
                    def: ItemCatalogue.byId(defId),
                    instance: _roll(defId, q),
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
      expect(tester.takeException(), isNull, reason: 'lays out on a phone');
    }

    testWidgets('⭐ a Master belt shows its potency, base and example', (
      tester,
    ) async {
      await open(tester, 'fawnhide_belt', Quality.master);
      expect(
        find.text('Consumable potency (base 10%) +14%'),
        findsOneWidget,
        reason:
            'the rolled number with the definition beside it — a dialog '
            'quoting only the base would disagree with the drink',
      );
      expect(
        find.text('A Sapwort Draught heals 30 → 34 with this belt.'),
        findsOneWidget,
        reason: 'the worked example, from the shipped Draught and the roll',
      );
    });

    testWidgets('a Standard belt shows no pointless base', (tester) async {
      await open(tester, 'blankspine_belt', Quality.standard);
      expect(
        find.text('Consumable potency +30%'),
        findsOneWidget,
        reason: "'(base 30%) +30%' would restate the same number",
      );
      expect(
        find.text('A Sapwort Draught heals 30 → 39 with this belt.'),
        findsOneWidget,
        reason: '30 × 1.30',
      );
    });

    testWidgets('⭐ a hat shows neither', (tester) async {
      await open(tester, 'mirrorflax_hood', Quality.master);
      expect(
        find.textContaining('Consumable potency'),
        findsNothing,
        reason: 'only non-zero lines are emitted',
      );
      expect(
        find.textContaining('with this belt'),
        findsNothing,
        reason: 'the example belongs to potency, not to every item',
      );
    });
  });

  group('the Inventory stats panel', () {
    test('⭐ the worn total gains a Consumable potency line', () {
      final m = _worn('fawnhide_belt', Quality.master);
      final line = Equipping.statTotals(
        m,
        level: 1,
      ).where((l) => l.label == 'Consumable potency').single;
      expect(line.total, '+14%', reason: 'the rolled total, signed');
      expect(
        line.base,
        isNull,
        reason: 'pure-gear, like healing received — the mage starts at 0',
      );
      expect(
        Equipping.describeTotals(m, level: 1),
        contains('Consumable potency +14%'),
        reason: 'the string form reads the same as the item line',
      );
    });
  });
}

class _Driver implements OpponentDriver {
  _Driver(this.opponentGear);

  @override
  final ItemModifiers opponentGear;
  @override
  String get opponentName => 'Rival';
  @override
  int get opponentLevel => 1;
  @override
  int get opponentRating => 1200;
  @override
  MageApparel get opponentApparel => MageApparel.duskWitch;
  @override
  double get opponentHpScale => 1.0;
  @override
  double get opponentPowerScale => 1.0;
  @override
  EnemyCombatStats get opponentCombatStats => EnemyCombatStats.none;
  @override
  bool get playerIsHost => true;
  @override
  bool get supportsRematch => false;
  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async =>
      const TurnExchange(ForfeitAction());
  @override
  Future<void> reportSurrender() async {}
  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}
  @override
  Future<void> dispose() async {}
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
