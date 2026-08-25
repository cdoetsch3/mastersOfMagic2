import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';

/// `ECONOMY_CONTRACT.md` §6 (nightly reset, daily events) and §11 (schema).
void main() {
  group('TownShopState — JSON round trip', () {
    test('stock and lastResetDay survive toJson/fromJson', () {
      const state = TownShopState(
        stock: {'oak_log': 42, 'sapwort': 7},
        lastResetDay: 12345,
      );
      final restored = TownShopState.fromJson(state.toJson());
      expect(restored.stock, state.stock);
      expect(restored.lastResetDay, state.lastResetDay);
    });

    test('an empty stock map is sparse — omitted from JSON entirely', () {
      const state = TownShopState(lastResetDay: 5);
      final json = state.toJson();
      expect(
        json.containsKey('stock'),
        isFalse,
        reason: 'mirrors Storeroom\'s own sparse-write pattern',
      );
      expect(json['lastResetDay'], 5);
    });

    test('fromJson(null) — old-save tolerance for a missing entry', () {
      final state = TownShopState.fromJson(null);
      expect(state.stock, isEmpty);
      expect(state.lastResetDay, 0);
      expect(state.isEmpty, isTrue);
    });

    test('stockOf reads a present item and defaults absent ones to 0', () {
      const state = TownShopState(stock: {'oak_log': 5}, lastResetDay: 1);
      expect(state.stockOf('oak_log'), 5);
      expect(state.stockOf('never_seen'), 0);
    });
  });

  group('ShopState.epochDayOf', () {
    test('the same UTC calendar day always gives the same number', () {
      final a = ShopState.epochDayOf(DateTime.utc(2026, 8, 25, 3));
      final b = ShopState.epochDayOf(DateTime.utc(2026, 8, 25, 23, 59));
      expect(a, b);
    });

    test('crossing UTC midnight advances by exactly one', () {
      final day1 = ShopState.epochDayOf(DateTime.utc(2026, 8, 25, 23, 59));
      final day2 = ShopState.epochDayOf(DateTime.utc(2026, 8, 26, 0, 1));
      expect(day2, day1 + 1);
    });

    test('a local-time DateTime is normalised through UTC first', () {
      // ⚠️ The mutant this kills: reading year/month/day off the local
      // clock instead of calling .toUtc() first, which would put players in
      // different time zones on different reset days for the same instant.
      final utcNoon = DateTime.utc(2026, 8, 25, 12);
      final asLocal = utcNoon.toLocal();
      expect(ShopState.epochDayOf(asLocal), ShopState.epochDayOf(utcNoon));
    });
  });

  group('§6.1 the nightly resupply catch-up', () {
    int flatEquilibrium(String id) => 60;

    test('zero elapsed days resolves to the same stock, not a fresh reset',
        () {
      const prior = TownShopState(stock: {'oak_log': 10}, lastResetDay: 100);
      final resolved = ShopState.resolve(
        state: prior,
        today: 100,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
      );
      expect(resolved.stock['oak_log'], 10);
      expect(resolved.lastResetDay, 100);
    });

    test(
      '⭐ the contract\'s own worked example: stock=0, E=60, rate=0.5, 5 days',
      () {
        const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
        final days = <int, int>{};
        for (var n = 1; n <= 5; n++) {
          final resolved = ShopState.resolve(
            state: prior,
            today: n,
            itemIds: ['oak_log'],
            equilibriumOf: flatEquilibrium,
          );
          days[n] = resolved.stock['oak_log']!;
        }
        // §6.1's table: 30.00, 45.00, 52.50, 56.25, 58.13 — rounded to gold.
        expect(days[1], 30, reason: 'day 1: E − (E)(0.5)^1 = 30');
        expect(days[2], 45);
        expect(days[3], 53, reason: '52.50 rounds up (half away from zero)');
        expect(days[4], 56);
        expect(days[5], 58, reason: '58.125 → 58');
      },
    );

    test('RESUPPLY_RATE 1.0 fully resupplies after a single elapsed day', () {
      const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
      final resolved = ShopState.resolve(
        state: prior,
        today: 1,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
        resupplyRate: 1.0,
      );
      expect(resolved.stock['oak_log'], 60);
    });

    test('RESUPPLY_RATE 1.0 holds at full equilibrium for any further days',
        () {
      const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
      final resolved = ShopState.resolve(
        state: prior,
        today: 40,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
        resupplyRate: 1.0,
      );
      expect(resolved.stock['oak_log'], 60);
    });

    test('a glutted shop (stock above E) decays back DOWN toward E too', () {
      const prior = TownShopState(stock: {'oak_log': 200}, lastResetDay: 0);
      final resolved = ShopState.resolve(
        state: prior,
        today: 1,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
      );
      // E − (E − stock0) × 0.5 = 60 − (60 − 200) × 0.5 = 60 + 70 = 130.
      expect(resolved.stock['oak_log'], 130);
    });

    test('40 days away resolves in one closed-form step, not a 40-loop', () {
      const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
      final resolved = ShopState.resolve(
        state: prior,
        today: 40,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
      );
      // (1-0.5)^40 is astronomically small — this must read as fully
      // resupplied, not diverge or hang.
      expect(resolved.stock['oak_log'], 60);
      expect(resolved.lastResetDay, 40);
    });

    test('a never-visited town (null state) resolves fresh at equilibrium',
        () {
      final resolved = ShopState.resolve(
        state: null,
        today: 500,
        itemIds: ['oak_log', 'sapwort'],
        equilibriumOf: (id) => id == 'oak_log' ? 60 : 30,
      );
      expect(resolved.stock, {'oak_log': 60, 'sapwort': 30});
      expect(resolved.lastResetDay, 500);
    });

    test(
      'an item newer than the character\'s last visit resolves fresh at '
      'equilibrium too, independent of how stale the town\'s OTHER items are',
      () {
        const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
        final resolved = ShopState.resolve(
          state: prior,
          today: 40, // long enough that oak_log fully recovers regardless
          itemIds: ['oak_log', 'brand_new_item'],
          equilibriumOf: (id) => id == 'oak_log' ? 60 : 20,
        );
        expect(resolved.stock['brand_new_item'], 20);
      },
    );

    test(
      'a genuinely stale item (present, but never touched by resupply) '
      'still uses its OWN saved stock as the recurrence\'s starting point',
      () {
        const prior = TownShopState(
          stock: {'oak_log': 0, 'sapwort': 0},
          lastResetDay: 0,
        );
        final resolved = ShopState.resolve(
          state: prior,
          today: 1,
          itemIds: ['oak_log', 'sapwort'],
          equilibriumOf: (id) => id == 'oak_log' ? 60 : 30,
        );
        expect(resolved.stock['oak_log'], 30, reason: '60 × 0.5');
        expect(resolved.stock['sapwort'], 15, reason: '30 × 0.5');
      },
    );

    test('elapsed days never goes negative even with a clock that looks stale', () {
      // A defensive guard: `today` earlier than `lastResetDay` (a bad clock,
      // a save imported across devices) must not produce a negative
      // exponent or corrupt stock.
      const prior = TownShopState(stock: {'oak_log': 10}, lastResetDay: 100);
      final resolved = ShopState.resolve(
        state: prior,
        today: 50,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
      );
      expect(resolved.stock['oak_log'], 10, reason: 'zero elapsed, no-op');
    });

    test('stock never resolves negative', () {
      const prior = TownShopState(stock: {'oak_log': 0}, lastResetDay: 0);
      final resolved = ShopState.resolve(
        state: prior,
        today: 1,
        itemIds: ['oak_log'],
        equilibriumOf: flatEquilibrium,
      );
      expect(resolved.stock['oak_log'], greaterThanOrEqualTo(0));
    });
  });

  group('PlayerProfile.shopStock — §11.2, mirroring storerooms', () {
    test('survives save and load', () {
      final p = PlayerProfile.newPlayer()
        ..shopStock['hearthwood'] = const TownShopState(
          stock: {'oak_log': 42},
          lastResetDay: 100,
        );
      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.shopStock['hearthwood']!.stock['oak_log'], 42);
      expect(back.shopStock['hearthwood']!.lastResetDay, 100);
    });

    test('a fresh character has visited no town\'s shop', () {
      final back = PlayerProfile.fromJson(PlayerProfile.newPlayer().toJson());
      expect(back.shopStock, isEmpty);
    });

    test(
      '⚠️ old-save tolerance: a save with no "shopStock" key at all reads as '
      'fresh state, not a crash',
      () {
        final p = PlayerProfile.newPlayer()..gold = 250;
        final json = p.toJson();
        json.remove('shopStock');
        final back = PlayerProfile.fromJson(json);
        expect(back.shopStock, isEmpty);
        expect(back.gold, 250, reason: 'the rest of the save is untouched');
      },
    );

    test('a town with no recorded stock is sparse, not written as {}', () {
      final p = PlayerProfile.newPlayer()
        ..shopStock['hearthwood'] = const TownShopState(lastResetDay: 1);
      final json = p.toJson();
      expect(
        (json['shopStock'] as Map).containsKey('hearthwood'),
        isFalse,
        reason: 'mirrors storerooms\' `if (!e.value.isEmpty)` write guard',
      );
    });
  });

  group('§6.2 deterministic daily events', () {
    final catalogue = [
      'oak_log',
      'sapwort',
      'fawnhide',
      'bindweed_fibre',
      'hardtack',
      'sapwort_draught',
    ];

    test('two independent computations of the same inputs agree exactly',
        () {
      final a = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      final b = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      expect(a, b);
    });

    test('input order does not change the result', () {
      final forward = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      final reversed = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue.reversed,
      );
      expect(forward, reversed);
    });

    test('a different shop, same day, picks a different set or directions',
        () {
      final hearthwood = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      final pennycross = ShopState.eventsFor(
        shopId: 'pennycross',
        today: 20330,
        candidateItemIds: catalogue,
      );
      expect(
        hearthwood,
        isNot(equals(pennycross)),
        reason: 'seeded from shopId too, not just the date',
      );
    });

    test('the same shop, a different day, picks a different set or directions',
        () {
      final day1 = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      final day2 = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20331,
        candidateItemIds: catalogue,
      );
      expect(day1, isNot(equals(day2)));
    });

    test('defaults to ~2 items per shop per day, each at ±20%', () {
      final events = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      expect(events.length, 2);
      for (final mod in events.values) {
        expect(mod == 1.2 || mod == 0.8, isTrue, reason: 'mod was $mod');
      }
      for (final id in events.keys) {
        expect(catalogue, contains(id));
      }
    });

    test('itemsPerDay and magnitudePercent are honoured when overridden', () {
      final events = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
        itemsPerDay: 3,
        magnitudePercent: 10,
      );
      expect(events.length, 3);
      for (final mod in events.values) {
        expect(mod == 1.1 || mod == 0.9, isTrue);
      }
    });

    test('itemsPerDay never exceeds the candidate pool size', () {
      final events = ShopState.eventsFor(
        shopId: 'meridian',
        today: 20330,
        candidateItemIds: ['hum_quartz'],
        itemsPerDay: 5,
      );
      expect(events.length, 1);
    });

    test('an empty candidate list produces no events, not an error', () {
      final events = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: const <String>[],
      );
      expect(events, isEmpty);
    });

    test('duplicate ids in the candidate list are deduped before picking',
        () {
      final withDupes = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: [...catalogue, ...catalogue, ...catalogue],
      );
      final clean = ShopState.eventsFor(
        shopId: 'hearthwood',
        today: 20330,
        candidateItemIds: catalogue,
      );
      expect(withDupes, clean);
    });
  });
}
