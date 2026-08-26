/// `config/economy` — the game's first server-tunable gameplay data
/// (ECONOMY_CONTRACT §7). Every failure path — missing doc, missing field,
/// wrong-typed field, network error, timeout — must fall back to the
/// compiled default for *that field only*; a malformed doc must never poison
/// the fields that did parse. The fetch is also non-blocking: shop code
/// reads `EconomyConfig.current`, which starts at the compiled defaults and
/// is swapped in place once the fetch resolves — nothing waits on it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/content_version.dart';
import 'package:masters_of_magic_2/game/economy/economy_config.dart';

void main() {
  /// A fake REST layer. Never touches the network; records what was asked
  /// for.
  ContentDocReader reader(
    Map<String, dynamic>? fields, {
    Object? throws,
    Duration delay = Duration.zero,
    List<String>? asked,
  }) {
    return (path) async {
      asked?.add(path);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (throws != null) throw throws;
      return fields;
    };
  }

  setUp(() {
    // Every test starts from a clean cache — [EconomyConfig.current] is
    // process-global static state, and `fetchAndCache` mutates it.
    EconomyConfig.current = EconomyConfig.defaults;
  });

  group('compiled defaults', () {
    test('match the contract exactly (§6, §7)', () {
      const cfg = EconomyConfig.defaults;
      expect(
        cfg.resupplyRate,
        0.5,
        reason: '§6.1 rules RESUPPLY_RATE default 0.5',
      );
      expect(
        cfg.eventMagnitudePercent,
        20,
        reason: '§6.2 rules eventMod ±20%',
      );
      expect(
        cfg.eventItemsPerShopPerDay,
        2,
        reason: '§6.2 rules ~2 affected items per shop per day',
      );
      expect(
        cfg.locationModOverrides,
        isEmpty,
        reason: 'no overrides by default — §4.1\'s travel-graph rule alone '
            'decides every (town, item) location modifier',
      );
      expect(
        cfg.equilibriumOverrides,
        isEmpty,
        reason: 'no overrides by default — §5.1\'s category defaults alone '
            'decide every item\'s equilibrium stock',
      );
    });

    test(
      'E category defaults are native 60 / imported 20 / '
      'consumable-ingredient 10 / consumables 9 (provisional, §14d.3)',
      () {
        // ✅ §5.1 as re-cut by §14d ruling 2 (Christian, 2026-08-26): the two
        // GEAR-material buckets are untouched at 60/20; the consumable lane is
        // the whole edit — a new ingredient bucket at 10, and consumables
        // themselves dropped 30 → 6.
        // These are compiled constants, not part of config/economy's schema
        // (only per-item overrides are server-tunable per §7) — this pins the
        // values a shop builder reads directly.
        expect(
          EconomyConfig.equilibriumNative,
          60,
          reason: 'gear materials were explicitly NOT re-tuned by §14d.2',
        );
        expect(
          EconomyConfig.equilibriumImported,
          20,
          reason: 'gear materials were explicitly NOT re-tuned by §14d.2',
        );
        expect(
          EconomyConfig.equilibriumConsumableIngredient,
          10,
          reason: 'the herb shelf is scarcer than an imported gear material — '
              'herbs are picked, not shipped',
        );
        expect(
          EconomyConfig.equilibriumConsumable,
          9,
          reason: 'a potion shelf is the scarcest thing a town sells — 9 is '
              'the §14d.3 provisional (the ruled ~6 opens the round-trip '
              'faucet; E ≤ 8 exploitable, and 10 would collide with the '
              'ingredient bucket)',
        );
      },
    );

    test('the four E buckets are strictly ordered, scarcest last', () {
      // ⭐ Not decoration: `ShopCatalogue.categoryFor` resolves an item that
      // fits two buckets by returning the SCARCER one, and it does that by
      // ordering its `if`s rather than by comparing numbers. That trick is
      // only correct while the constants stay in this order, so the ordering
      // is pinned here, next to the numbers, where a future re-tune will see
      // it. Re-tuning consumables above imports without touching
      // `categoryFor` would silently invert the ruling.
      expect(
        [
          EconomyConfig.equilibriumNative,
          EconomyConfig.equilibriumImported,
          EconomyConfig.equilibriumConsumableIngredient,
          EconomyConfig.equilibriumConsumable,
        ],
        [60, 20, 10, 9],
        reason: 'native > imported > consumable-ingredient > consumable, '
            'strictly decreasing — the precedence `categoryFor` encodes',
      );
    });
  });

  group('EconomyConfig.fetch — full doc parses', () {
    test('every field reads from a complete doc', () async {
      final asked = <String>[];
      final cfg = await EconomyConfig.fetch(
        read: reader({
          'resupplyRate': 1.0,
          'eventMagnitudePercent': 35,
          'eventItemsPerShopPerDay': 4,
          'locationModOverrides': {'forgeholm.copper_ore': 10},
          'equilibriumOverrides': {'oak_log': 80},
        }, asked: asked),
      );
      expect(
        asked,
        ['config/economy'],
        reason: 'a wrong path would 404 forever and silently disable tuning',
      );
      expect(cfg.resupplyRate, 1.0);
      expect(cfg.eventMagnitudePercent, 35);
      expect(cfg.eventItemsPerShopPerDay, 4);
      expect(cfg.locationModOverrides, {'forgeholm.copper_ore': 10});
      expect(cfg.equilibriumOverrides, {'oak_log': 80});
    });

    test('integer-valued numeric fields parse too (Firestore integerValue)', () async {
      // The REST layer decodes a Firestore integerValue as a Dart int, not a
      // double — a `is double` check on the field would wrongly reject it.
      final cfg = await EconomyConfig.fetch(
        read: reader({'resupplyRate': 1, 'eventItemsPerShopPerDay': 3}),
      );
      expect(
        cfg.resupplyRate,
        1.0,
        reason: 'an `is double`-only parse would drop a console-entered '
            'integer on the floor and silently fall back to the default',
      );
      expect(cfg.eventItemsPerShopPerDay, 3.0);
    });
  });

  group('EconomyConfig.fetch — partial doc keeps defaults for missing fields', () {
    test('only resupplyRate set — every other field stays at its default', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({'resupplyRate': 0.75}),
      );
      expect(cfg.resupplyRate, 0.75);
      expect(
        cfg.eventMagnitudePercent,
        EconomyConfig.defaultEventMagnitudePercent,
        reason: '⚠️ kills all-or-nothing parsing: a partial doc must not '
            'blank out fields it never mentioned',
      );
      expect(
        cfg.eventItemsPerShopPerDay,
        EconomyConfig.defaultEventItemsPerShopPerDay,
      );
      expect(cfg.locationModOverrides, isEmpty);
      expect(cfg.equilibriumOverrides, isEmpty);
    });

    test('empty doc ({}) is the same as a missing field for every field', () async {
      final cfg = await EconomyConfig.fetch(read: reader({}));
      expect(cfg.resupplyRate, EconomyConfig.defaultResupplyRate);
      expect(
        cfg.eventMagnitudePercent,
        EconomyConfig.defaultEventMagnitudePercent,
      );
      expect(
        cfg.eventItemsPerShopPerDay,
        EconomyConfig.defaultEventItemsPerShopPerDay,
      );
      expect(cfg.locationModOverrides, isEmpty);
      expect(cfg.equilibriumOverrides, isEmpty);
    });
  });

  group('EconomyConfig.fetch — a wrong-typed field falls back ALONE', () {
    test('a string resupplyRate falls back, but a correct sibling field still parses', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({
          'resupplyRate': 'fast', // wrong type
          'eventMagnitudePercent': 40, // correctly typed
        }),
      );
      expect(
        cfg.resupplyRate,
        EconomyConfig.defaultResupplyRate,
        reason: 'a hand-typed string in the console must not throw or wedge '
            'the whole parse',
      );
      expect(
        cfg.eventMagnitudePercent,
        40,
        reason: '⚠️ the poison mutant this kills: a single try/catch wrapped '
            'around the WHOLE doc parse would fall back to compiled defaults '
            'for every field the moment any one field is malformed — this '
            'field parsed fine and must keep its own value',
      );
    });

    test('locationModOverrides as the wrong type (a string) falls back to empty, alone', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({
          'locationModOverrides': 'not a map',
          'equilibriumOverrides': {'oak_log': 13},
        }),
      );
      expect(cfg.locationModOverrides, isEmpty);
      expect(
        cfg.equilibriumOverrides,
        {'oak_log': 13},
        reason: 'the sibling override map must survive a malformed neighbor',
      );
    });

    test('a malformed entry inside an otherwise-good map is skipped, not fatal to the map', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({
          'equilibriumOverrides': {
            'oak_log': 80, // good
            'rimepelt': 'lots', // wrong type — must not poison the map
            5: 40, // non-string key — must not poison the map
          },
        }),
      );
      expect(
        cfg.equilibriumOverrides,
        {'oak_log': 80},
        reason: 'a single bad entry must not blank the whole override map '
            'nor throw and fall back to compiled equilibrium everywhere',
      );
    });

    test('a double-instead-of-int equilibriumOverrides entry still parses (truncated to int)', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({
          'equilibriumOverrides': {'oak_log': 80.0},
        }),
      );
      expect(cfg.equilibriumOverrides, {'oak_log': 80});
    });
  });

  group('EconomyConfig.fetch — fetch failure falls back to ALL defaults', () {
    test('a thrown fetch (offline, rules, 500) returns defaults', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader(null, throws: Exception('offline')),
      );
      expect(
        cfg,
        isA<EconomyConfig>()
            .having((c) => c.resupplyRate, 'resupplyRate', 0.5)
            .having(
              (c) => c.eventMagnitudePercent,
              'eventMagnitudePercent',
              20,
            ),
        reason: 'an uncaught throw here would crash the fetch instead of '
            'falling open to the compiled defaults',
      );
    });

    test('a fetch that never returns falls back once the timeout elapses', () async {
      final cfg = await EconomyConfig.fetch(
        read: reader({'resupplyRate': 0.9}, delay: const Duration(seconds: 30)),
        timeout: const Duration(milliseconds: 20),
      );
      expect(
        cfg.resupplyRate,
        EconomyConfig.defaultResupplyRate,
        reason: 'without the timeout this fetch would hang indefinitely; '
            'with one, it must resolve to defaults rather than propagate',
      );
    });

    test('a missing document (null fields) returns defaults', () async {
      final cfg = await EconomyConfig.fetch(read: reader(null));
      expect(cfg.resupplyRate, EconomyConfig.defaultResupplyRate);
      expect(
        cfg.eventMagnitudePercent,
        EconomyConfig.defaultEventMagnitudePercent,
        reason: 'config/economy is documented as OPTIONAL — an absent doc '
            'must play identically to a doc full of defaults',
      );
    });
  });

  group('EconomyConfig.fetchAndCache — the boot seam', () {
    test('caches the resolved config into EconomyConfig.current', () async {
      expect(EconomyConfig.current, EconomyConfig.defaults);
      await EconomyConfig.fetchAndCache(
        read: reader({'resupplyRate': 0.9}),
      );
      expect(
        EconomyConfig.current.resupplyRate,
        0.9,
        reason: 'shop code reads EconomyConfig.current directly; the fetch '
            'must land there for a resolved doc to ever take effect',
      );
    });

    test('a failed fetch caches the all-defaults config, not a stale half-state', () async {
      await EconomyConfig.fetchAndCache(
        read: reader({'resupplyRate': 0.9}),
      );
      expect(EconomyConfig.current.resupplyRate, 0.9);

      await EconomyConfig.fetchAndCache(
        read: reader(null, throws: Exception('offline')),
      );
      expect(
        EconomyConfig.current.resupplyRate,
        EconomyConfig.defaultResupplyRate,
        reason: 'a later failed re-fetch must not leave the previous '
            'successful value stuck in the cache silently — it should '
            'resolve to a clean defaults config',
      );
    });

    testWidgets(
      'never blocks: a widget renders before the config future resolves',
      (tester) async {
        // Mirrors main.dart's actual boot seam shape: kick off the fetch in
        // initState without awaiting it, and build content immediately. If
        // a future implementation mistakenly gated a FutureBuilder on this
        // fetch (the way the content-version gate legitimately does on
        // checkContentVersion), this test would hang or show nothing
        // instead of the ready text on the very first pump.
        final completer = Completer<Map<String, dynamic>?>();
        await tester.pumpWidget(
          MaterialApp(
            home: _BootSeamHarness(read: (path) => completer.future),
          ),
        );

        // The very first pump already shows the widget's content — nothing
        // awaited the fetch to get here — and the fetch is still in flight,
        // so the cache is untouched.
        expect(find.text('ready'), findsOneWidget);
        expect(
          EconomyConfig.current,
          EconomyConfig.defaults,
          reason: 'the fetch has not resolved yet; current must still read '
              'the compiled defaults, not block waiting for the real value',
        );

        completer.complete({'resupplyRate': 0.42});
        await tester.pumpAndSettle();
        expect(
          EconomyConfig.current.resupplyRate,
          0.42,
          reason: 'once the future resolves, the seam must still land the '
              'result in the cache exactly as the non-widget fetchAndCache '
              'tests already prove',
        );
      },
    );
  });
}

class _BootSeamHarness extends StatefulWidget {
  final ContentDocReader read;
  const _BootSeamHarness({required this.read});

  @override
  State<_BootSeamHarness> createState() => _BootSeamHarnessState();
}

class _BootSeamHarnessState extends State<_BootSeamHarness> {
  @override
  void initState() {
    super.initState();
    // Deliberately not awaited — this is the exact pattern under test.
    EconomyConfig.fetchAndCache(read: widget.read);
  }

  @override
  Widget build(BuildContext context) => const Text('ready');
}
