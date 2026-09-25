/// Three campaign rulings of one day (Christian, 2026-09-25), pinned together
/// because they meet at the same moment — the boss falling.
///
/// 1. ✅ **Every run is nine fights in one shape** — 2 commons, mini, 2
///    commons, mini, 2 commons, boss — with a gathering spot after each mini
///    and after the boss. The Citadel's two-boss sequence fills the one boss
///    slot (ten fights).
/// 2. ✅ **A boss kill guarantees a rare-or-better piece of the zone's own
///    gear**, keyed on the rank in the loot roller (`rollKill`), never
///    authored into 26 tables.
/// 3. ✅ **Drop from the pack during the loot picker** — *"if I have a dust
///    and am about to loot something but am out of room, I can drop the dust
///    and loot the other item."*
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/loot.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/screens/tabs/map_tab.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';
import 'package:mom_engine/mom_engine.dart';

const _citadel = 'the_eclipsed_citadel';
const _frostfell = 'frostfell_pass';
final _woods = World.byId('whispering_woods');

/// Every zone a run can be rolled in.
final _zones = [
  for (final l in World.locations)
    if (l.hasAdventure && Bestiary.forZone(l.id).isNotEmpty) l,
];

const _c = EnemyRank.common;
const _m = EnemyRank.mini;
const _b = EnemyRank.boss;

AdventureRun _roll(GameLocation zone, int seed) => AdventureRun.roll(
  zone: zone,
  roster: Bestiary.forZone(zone.id),
  playerHp: 100,
  rng: Random(seed),
);

void main() {
  group('the map and the home card know the ruled shape (merge additions)', () {
    test('the run subtitle counts 9 everywhere and 10 at the Citadel', () {
      // The map's subtitle used to compute perSection × 3 + 3 and was off by
      // one for the Citadel's two-boss slot; it now reads the sequence.
      expect(
        mapRunSubtitleForTest(World.byId('old_quarry')),
        startsWith('9 encounters'),
        reason:
            'a mutant back on the old arithmetic still says 9 here — the '
            'Citadel case below is what tells them apart',
      );
      expect(
        mapRunSubtitleForTest(World.byId('the_eclipsed_citadel')),
        startsWith('10 encounters'),
        reason:
            'the Citadel fights Totality then Procarius — a subtitle '
            'promising nine would be a lie at the last door',
      );
    });
  });

  group('ruling 1 — nine fights, one shape, three spots', () {
    test('the tier scaling is gone: two commons per section, every tier', () {
      for (final tier in [null, ...MagicTier.values]) {
        expect(
          commonsPerSectionFor(tier),
          2,
          reason:
              '$tier: a run no longer grows with the game (ruling '
              '2026-09-25) — a surviving 3/4/5 lengthens late runs again',
        );
      }
      expect(
        commonsPerSection,
        2,
        reason: 'the constant is the ruling; the tier function only defers',
      );
    });

    test('every zone rolls 9 fights in the exact pattern (Citadel 10)', () {
      expect(
        _zones,
        hasLength(26),
        reason: 'the world is 26 rostered zones; a missing one skips the shape',
      );
      for (final zone in _zones) {
        final want = zone.id == _citadel
            ? [_c, _c, _m, _c, _c, _m, _c, _c, _b, _b]
            : [_c, _c, _m, _c, _c, _m, _c, _c, _b];
        for (var seed = 0; seed < 12; seed++) {
          final run = _roll(zone, seed);
          expect(
            run.encounters.map((e) => e.def.rank).toList(),
            want,
            reason:
                '${zone.id} seed $seed: 2 commons, mini, 2 commons, mini, 2 '
                'commons, boss — the Citadel\'s sequence filling the boss slot',
          );
        }
      }
    });

    test('three spots, at exactly 2, 5 and 8, in every zone that has any', () {
      final noNodes = <String>[];
      for (final zone in _zones) {
        if (GatherNodes.forZone(zone.id).isEmpty) {
          noNodes.add(zone.id);
          continue;
        }
        for (var seed = 0; seed < 12; seed++) {
          final run = _roll(zone, seed);
          expect(
            run.nodes.map((n) => n.afterIndex).toList(),
            [2, 5, 8],
            reason:
                '${zone.id} seed $seed: one spot immediately after mini 1, '
                'mini 2 and the boss — never drawn inside a section',
          );
          expect(
            run.nodes.last.afterIndex,
            run.encounterCount - 1,
            reason: '${zone.id}: the boss spot is the run\'s last stop',
          );
        }
      }
      expect(
        noNodes,
        [_citadel],
        reason:
            'only the Citadel authors no nodes (ETHEREAL §6); any other zone '
            'here has lost its spots',
      );
    });

    test('⭐ the boss spot is reachable after the clear, and pays', () async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(11));
      final run = game.run!;
      while (!run.isOver) {
        // Walk past every earlier spot; nothing kept from any picker.
        await game.winEncounter(remainingHp: 90, rng: Random(run.index));
        await game.claimVictoryLoot(const <int>{});
      }
      expect(
        run.outcome,
        RunOutcome.cleared,
        reason: 'the boss fell, so the run is over and the zone cleared',
      );
      final node = run.currentNode;
      expect(
        node?.afterIndex,
        8,
        reason:
            'a cleared run must still offer the spot after the boss — '
            '`!isOver` here rolls a node no player can ever reach',
      );
      final before = game.profile.backpack.used;
      final out = await game.gatherNode(rng: Random(1));
      expect(
        out.succeeded,
        isTrue,
        reason: 'the boss spot harvests like any other: ${out.refusal}',
      );
      expect(
        game.profile.backpack.used,
        before + out.amount,
        reason: 'the harvest lands in the pack, all of it',
      );
      expect(
        run.currentNode,
        isNull,
        reason: 'one harvest, then the spot is spent',
      );
    });

    test('⚠️ walking out or dying still closes the road', () async {
      final left = _roll(_woods, 4);
      for (var i = 0; i < 3; i++) {
        left.recordVictory(loot: const [], instances: const {}, remainingHp: 9);
      }
      expect(
        left.currentNode,
        isNotNull,
        reason: 'standing at the spot after mini 1',
      );
      left.returnToTown();
      expect(
        left.currentNode,
        isNull,
        reason: 'a spot behind a player who walked out is not in front of them',
      );

      final dead = _roll(_woods, 4)
        ..recordVictory(loot: const [], instances: const {}, remainingHp: 9)
        ..recordVictory(loot: const [], instances: const {}, remainingHp: 9)
        ..recordVictory(loot: const [], instances: const {}, remainingHp: 9)
        ..recordDefeat();
      expect(
        dead.currentNode,
        isNull,
        reason: 'the cleared-run exception must not leak to a dead run',
      );
      expect(
        dead.onTheRoad,
        isFalse,
        reason: 'a dead run is not on the road: nothing to drop things for',
      );
    });

    testWidgets('the ending screen offers the boss spot above its way out', (
      tester,
    ) async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(11));
      final run = game.run!;
      while (!run.isOver) {
        await game.winEncounter(remainingHp: 90, rng: Random(run.index));
        await game.claimVictoryLoot(const <int>{});
      }
      await _pump(tester, game);

      final gather = find.textContaining('Gather ·');
      final leave = find.text('Back to the map');
      expect(
        gather,
        findsOneWidget,
        reason: 'the boss spot has to be on the ending screen to be reached',
      );
      expect(
        leave,
        findsOneWidget,
        reason: 'the way out is still there — the spot is an offer',
      );
      expect(
        tester.getTopLeft(gather).dy,
        lessThan(tester.getTopLeft(leave).dy),
        reason: 'offered BEFORE the way out, so it is read before leaving',
      );
    });
  });

  group('ruling 2 — a boss kill guarantees rare-or-better zone gear', () {
    final frostBosses = Bestiary.forZone(
      _frostfell,
    ).where((e) => e.rank == EnemyRank.boss).toList();

    bool isRarePlusFrostGear(String defId) {
      final def = ItemCatalogue.tryById(defId);
      return def is EquipmentDef &&
          def.rarity.index >= Rarity.rare.index &&
          ItemCatalogue.zoneOf(defId) == _frostfell;
    }

    test('every Frostfell boss kill carries one, on top of its table', () {
      expect(
        frostBosses,
        isNotEmpty,
        reason: 'Frostfell has bosses to test against',
      );
      for (final boss in frostBosses) {
        for (var seed = 0; seed < 400; seed++) {
          final table = rollDrops(boss.drops, Random(seed));
          final kill = rollKill(
            boss.drops,
            rank: EnemyRank.boss,
            zoneId: _frostfell,
            rng: Random(seed),
          );
          expect(
            kill.slots.length,
            table.slots.length + 1,
            reason:
                '${boss.id} seed $seed: exactly one extra piece — none is the '
                'ruling missed, two is a second roll nobody asked for',
          );
          expect(
            kill.slots.take(table.slots.length).map((s) => s.defId),
            table.slots.map((s) => s.defId),
            reason:
                'the table rolls first and exactly as before — the published '
                'rates must not move for the guarantee',
          );
          final extra = kill.slots.last;
          expect(
            isRarePlusFrostGear(extra.defId),
            isTrue,
            reason:
                '${boss.id} seed $seed paid ${extra.defId}: must be Frostfell '
                'EquipmentDef at rare or above',
          );
          expect(
            kill.instances[extra.instanceId]?.defId,
            extra.defId,
            reason: 'gear is non-fungible; the guaranteed piece needs its roll',
          );
        }
      }
    });

    test('a common or a mini never triggers it', () {
      final others = Bestiary.forZone(
        _frostfell,
      ).where((e) => e.rank != EnemyRank.boss);
      for (final enemy in others) {
        for (var seed = 0; seed < 60; seed++) {
          final table = rollDrops(enemy.drops, Random(seed));
          final kill = rollKill(
            enemy.drops,
            rank: enemy.rank,
            zoneId: _frostfell,
            rng: Random(seed),
          );
          expect(
            kill.slots.map((s) => s.defId),
            table.slots.map((s) => s.defId),
            reason:
                '${enemy.id} (${enemy.rank.name}) seed $seed: only the boss '
                'rank earns the guarantee',
          );
        }
      }
    });

    test('the epic roll lands 25% of the time (4000 seeded kills, ±3%)', () {
      final rng = Random(2026);
      var epics = 0;
      const kills = 4000;
      for (var i = 0; i < kills; i++) {
        final id = rollBossGuarantee(_frostfell, rng)!;
        if (ItemCatalogue.byId(id).rarity == Rarity.epic) epics++;
      }
      expect(
        epics / kills,
        closeTo(bossEpicChance, 0.03),
        reason:
            '$epics of $kills were epic — the ruling is epic on a 25% roll, '
            'rare otherwise',
      );
      expect(bossEpicChance, 0.25, reason: 'the ruling\'s number');
    });

    test('every zone has a rare-or-better candidate of its own', () {
      final noEpic = <String>[];
      for (final zone in _zones) {
        final candidates = bossGuaranteeCandidates(zone.id);
        expect(
          candidates,
          isNotEmpty,
          reason: '${zone.id}: a boss guarantee with nothing to pay',
        );
        for (final d in candidates) {
          expect(
            d.rarity.index,
            greaterThanOrEqualTo(Rarity.rare.index),
            reason:
                '${zone.id}: ${d.id} is ${d.rarity.name} — the best-rarity '
                'fallback woke, so this zone lost its rare+ gear',
          );
          expect(
            ItemCatalogue.zoneOf(d.id),
            zone.id,
            reason: '${d.id}: the zone\'s OWN gear, not a neighbour\'s',
          );
        }
        if (!candidates.any((d) => d.rarity == Rarity.epic)) {
          noEpic.add(zone.id);
        }
      }
      expect(
        noEpic,
        ['glimmerbrook', 'cinderpeak_foothills', 'thornmire'],
        reason:
            'the zones whose boss can only pay rare; a change here is a '
            'catalogue change the ruling should hear about',
      );
    });

    test('⚠️ a zone with only an epic pays the epic, never nothing', () {
      // Ashfall Vale authors an epic and no rare (2026-09-25): a "rare" roll
      // must yield to the tier the zone has.
      final rng = Random(5);
      for (var i = 0; i < 200; i++) {
        final id = rollBossGuarantee('ashfall_vale', rng);
        expect(
          ItemCatalogue.tryById(id ?? '')?.rarity,
          Rarity.epic,
          reason: 'kill $i paid $id: the only rare+ piece Ashfall has',
        );
      }
    });

    test(
      'the boss kill through GameState hands the piece to the picker',
      () async {
        final game = GameState(_Mem(), PlayerProfile.newPlayer());
        await game.beginAdventure(World.byId(_frostfell), rng: Random(2));
        final run = game.run!;
        while (!run.atBoss) {
          await game.winEncounter(remainingHp: 90, rng: Random(run.index));
          await game.claimVictoryLoot(const <int>{});
        }
        final dropped = await game.winEncounter(
          remainingHp: 90,
          rng: Random(99),
        );
        expect(
          dropped.where(isRarePlusFrostGear),
          isNotEmpty,
          reason: 'winEncounter must roll through rollKill, not bare rollDrops',
        );
      },
    );
  });

  group('ruling 3 — drop from the pack during the loot picker', () {
    const mantle = InventorySlot(
      defId: 'sporecap_mantle',
      instanceId: 'inst-mantle',
    );
    const rolls = {
      'inst-mantle': ItemInstance(
        instanceId: 'inst-mantle',
        defId: 'sporecap_mantle',
      ),
    };

    /// A run standing on an unanswered picker offering [mantle], with the
    /// pack full of dust (and, when [crystal], one green crystal first).
    Future<GameState> fullPackAtPicker({bool crystal = false}) async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));
      var pack = game.profile.backpack;
      if (crystal) {
        pack = pack.withAdded(const InventorySlot(defId: 'flora_crystal'))!;
      }
      while (pack.free > 0) {
        pack = pack.withAdded(const InventorySlot(defId: 'flora_dust'))!;
      }
      game.profile.backpack = pack;
      game.run!.recordVictory(
        loot: const [mantle],
        instances: rolls,
        remainingHp: 90,
      );
      return game;
    }

    testWidgets('⭐ Drop on a dust frees a slot, and the row becomes takeable', (
      tester,
    ) async {
      final game = await fullPackAtPicker();
      await _pump(tester, game);

      expect(
        find.text('no room'),
        findsOneWidget,
        reason: 'the setup: a full pack, one drop offered, nothing takeable',
      );
      expect(
        find.textContaining('YOUR PACK'),
        findsOneWidget,
        reason: 'the picker has to show what could be dropped to make room',
      );
      expect(
        find.widgetWithText(TextButton, 'Drop'),
        findsNWidgets(Carrying.backpackSlots),
        reason: 'one Drop per carried slot, in the picker itself',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Drop').first);
      await tester.pumpAndSettle();

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'dust is common: the drop is immediate (ruling 2026-09-21)',
      );
      expect(
        game.profile.backpack.free,
        1,
        reason: 'the strip must reach GameState.discardFromBackpack',
      );
      expect(
        find.text('no room'),
        findsNothing,
        reason: 'the picker\'s room is live — a stale `free` keeps it locked',
      );
      expect(
        find.text('Take 1'),
        findsOneWidget,
        reason:
            'the room made is spent the way the opening ticks were — '
            '"Leave it all behind" one tap after making room is a trap',
      );

      await tester.tap(find.text('Take 1'));
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf('sporecap_mantle'),
        1,
        reason: 'the looted item landed in the slot the dust vacated',
      );
      expect(
        game.profile.backpack.countOf('flora_dust'),
        Carrying.backpackSlots - 1,
        reason: 'exactly one dust went, and nothing else',
      );
    });

    testWidgets('⚠️ an uncommon in the strip still asks first', (tester) async {
      final game = await fullPackAtPicker(crystal: true);
      await _pump(tester, game);

      // The crystal is the pack's first slot, so its Drop is the first.
      await tester.tap(find.widgetWithText(TextButton, 'Drop').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Drop Flora Crystal?'),
        findsOneWidget,
        reason: 'the same confirm rule as the Pack: green and up asks',
      );
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(
        game.profile.backpack.countOf('flora_crystal'),
        1,
        reason: 'Keep keeps',
      );
      expect(
        find.text('no room'),
        findsOneWidget,
        reason: 'nothing dropped, so still no room',
      );
    });

    test('⭐ the BOSS picker can drop too, though the run is over', () async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      await game.beginAdventure(_woods, rng: Random(3));
      final run = game.run!;
      while (!run.atBoss) {
        await game.winEncounter(remainingHp: 90, rng: Random(run.index));
        await game.claimVictoryLoot(const <int>{});
      }
      game.profile.backpack = game.profile.backpack.withAdded(
        const InventorySlot(defId: 'flora_dust'),
      )!;
      await game.winEncounter(remainingHp: 90, rng: Random(1));
      expect(
        run.isOver,
        isTrue,
        reason: 'the setup: the clear ends the run as the boss falls',
      );
      final at = game.profile.backpack.slots.indexWhere(
        (s) => s?.defId == 'flora_dust',
      );
      expect(
        await game.discardFromBackpack(at),
        isNull,
        reason:
            'the boss picker is where a full pack bites hardest; gating Drop '
            'on isOver refuses it exactly there',
      );

      await game.claimVictoryLoot(const <int>{});
      await game.gatherNode(rng: Random(1));
      expect(
        await game.discardFromBackpack(0),
        'Sell it in town.',
        reason:
            'picker answered, spot spent: the road is closed and the shop is '
            'the answer again',
      );
    });
  });
}

/// ⚠️ A ListView only builds what fits — a full pack strip is 20 rows.
Future<void> _pump(WidgetTester tester, GameState game) async {
  await tester.binding.setSurfaceSize(const Size(900, 3600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameStateScope(
        state: game,
        child: AdventureScreen(zone: World.byId(game.run!.zoneId)),
      ),
    ),
  );
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
