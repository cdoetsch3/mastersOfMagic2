/// The four lifetime counters the stage-2 achievement catalogue reads
/// (ACHIEVEMENTS §11 prerequisites, ruling Christian 2026-10-01): per-element
/// charges, gold earned, items seen and travel seconds — plus the claimed
/// set. Each is pinned on disk (always written, absent reads empty) and at
/// its one hook.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills — a field never written, a hook dropped, a charge saved per turn, a
/// spend that un-earns, an opponent's charge counted as ours.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/active_trip.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/duel_launcher.dart';
import 'package:masters_of_magic_2/game/economy/shop_catalogue.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

/// Round-trips through JSON and counts writes, so what is asserted on disk
/// is what a reload would see.
class _JsonMem implements ProfileStorage {
  String? saved;
  int saves = 0;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    saved = jsonEncode(profile.toJson());
  }

  @override
  Future<void> clear() async => saved = null;

  PlayerProfile? get stored => saved == null
      ? null
      : PlayerProfile.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
}

/// An opponent that answers every turn with [reply], instantly.
class _Scripted implements OpponentDriver {
  MageAction reply;
  _Scripted(this.reply);

  @override
  double get opponentHpScale => 1.0;
  @override
  double get opponentPowerScale => 1.0;
  @override
  EnemyCombatStats get opponentCombatStats => EnemyCombatStats.none;
  @override
  int get opponentLevel => 1;
  @override
  int get opponentRating => 1200;
  @override
  ItemModifiers get opponentGear => ItemModifiers.none;
  @override
  String get opponentName => 'Rival';
  @override
  MageApparel get opponentApparel => MageApparel.duskWitch;
  @override
  bool get playerIsHost => true;
  @override
  bool get supportsRematch => false;
  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) =>
      Future.value(TurnExchange(reply, turn));
  @override
  Future<void> reportSurrender() async {}
  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}
  @override
  Future<void> dispose() async {}
}

PlayerProfile _p() => PlayerProfile.newPlayer();

PlayerProfile _roundTrip(PlayerProfile p) =>
    PlayerProfile.fromJson(jsonDecode(jsonEncode(p.toJson())));

final _woods = World.byId('whispering_woods');

void main() {
  group('on disk', () {
    test('⭐ every counter round-trips through JSON', () {
      final p = _p()
        ..claimedAchievements.add('first_blood')
        ..charges.addAll({'pyro': 412, 'umbra': 3})
        ..goldEarned = 9001
        ..itemsSeen.addAll({'oak_log', 'pyro_dust'})
        ..travelSeconds = 3600;
      final back = _roundTrip(p);
      expect(back.claimedAchievements, {
        'first_blood',
      }, reason: 'kills claimedAchievements missing from toJson or fromJson');
      expect(back.charges, {
        'pyro': 412,
        'umbra': 3,
      }, reason: 'kills charges missing from toJson or fromJson');
      expect(
        back.goldEarned,
        9001,
        reason: 'kills goldEarned missing from toJson or fromJson',
      );
      expect(back.itemsSeen, {
        'oak_log',
        'pyro_dust',
      }, reason: 'kills itemsSeen missing from toJson or fromJson');
      expect(
        back.travelSeconds,
        3600,
        reason: 'kills travelSeconds missing from toJson or fromJson',
      );
    });

    test('⭐ always written, even empty — so the update mask covers them', () {
      // `FirestoreProfileStorage._maskFor` builds the character document's
      // mask from the written keys: a field omitted when empty would leave a
      // reset character's old value on the server.
      final character = ProfileDocuments.split(_p()).character;
      for (final key in const [
        'claimedAchievements',
        'charges',
        'goldEarned',
        'itemsSeen',
        'travelSeconds',
      ]) {
        expect(
          character.containsKey(key),
          isTrue,
          reason:
              'kills a sparse write of $key, or one cut off the character '
              'document',
        );
      }
    });

    test('a save from before 2026-10-01 reads as nothing yet', () {
      final old = _p().toJson()
        ..remove('claimedAchievements')
        ..remove('charges')
        ..remove('goldEarned')
        ..remove('itemsSeen')
        ..remove('travelSeconds')
        ..['achievements'] = ['first_blood'];
      final p = PlayerProfile.fromJson(old);
      expect(
        p.claimedAchievements,
        isEmpty,
        reason:
            'kills an old save read as having claimed what it earned — the '
            'earned-before-the-ruling reward would never be paid',
      );
      expect(
        [p.charges.isEmpty, p.goldEarned, p.itemsSeen.isEmpty, p.travelSeconds],
        [true, 0, true, 0],
        reason: 'kills a fromJson that throws on, or invents, an absent key',
      );
    });
  });

  group('gold earned', () {
    test('⭐ earnGold adds to gold AND the lifetime count', () {
      final p = _p()..gold = 10;
      p.earnGold(40);
      expect(p.gold, 50, reason: 'kills an earnGold that skips the purse');
      expect(
        p.goldEarned,
        40,
        reason: 'kills an earnGold that skips the lifetime count',
      );
    });

    test('a duel win counts; a loss pays what it pays', () async {
      final game = GameState(_JsonMem(), _p());
      await game.recordDuelResult(won: true);
      expect(
        game.profile.goldEarned,
        Progression.winGold,
        reason: 'kills a win that pays gold with a raw `gold +=`',
      );
      await game.recordDuelResult(won: false);
      expect(
        game.profile.goldEarned,
        Progression.winGold + Progression.lossGold,
        reason: 'kills a loss-gold site left off earnGold',
      );
    });

    test('⭐ a vendor sale earns; a purchase does not un-earn', () async {
      const town = 'hearthwood';
      final game = GameState(_JsonMem(), _p()..gold = 1000)
        ..profile.locationId = town;
      game.profile.backpack = Backpack.of([
        const InventorySlot(defId: 'pyro_dust', count: 5),
      ]);
      final today = ShopState.epochDayOf(game.now());
      // As the shop screen does on entry: the shelves exist before a sale.
      await game.resolveShop(town, today);

      final sold = await game.settleShopBasket(
        townId: town,
        today: today,
        buy: const {},
        sellStacks: const {'pyro_dust': 5},
        sellInstances: const {},
      );
      expect(sold.refusal, isNull, reason: 'premise: the sale settles');
      expect(
        game.profile.goldEarned,
        sold.sellGold,
        reason: 'kills a shop that pays sales with a raw `gold +=`',
      );
      expect(sold.sellGold, greaterThan(0), reason: 'premise: it paid');

      final earned = game.profile.goldEarned;
      final purse = game.profile.gold;
      // The first shelf item actually in stock today.
      final item = ShopCatalogue.stockFor(town).firstWhere(
        (id) =>
            game.shopBasketBlockReason(
              townId: town,
              today: today,
              buy: {id: 1},
              sellStacks: const {},
              sellInstances: const {},
            ) ==
            null,
      );
      final bought = await game.settleShopBasket(
        townId: town,
        today: today,
        buy: {item: 1},
        sellStacks: const {},
        sellInstances: const {},
      );
      expect(bought.refusal, isNull, reason: 'premise: the purchase settles');
      expect(
        game.profile.goldEarned,
        earned,
        reason:
            'kills a goldEarned that tracks gold held — spending must not '
            'walk Wealth backwards (§5.3)',
      );
      expect(
        game.profile.gold,
        purse + bought.net,
        reason: 'kills a settle that no longer charges exactly the quote',
      );
    });
  });

  group('charges', () {
    test('⭐ the controller counts OUR charges, by the element charged', () {
      final element = Loadout.starter.elements.first;
      final c = DuelController(
        loadout: Loadout.starter,
        driver: _Scripted(const ChargeAction(MagicElement.umbra)),
      );
      addTearDown(c.dispose);
      return Future(() async {
        c.selectElement(element);
        await c.submitTurn(c.chargeAction());
        c.finishTurn();
        // ⚠️ The second action names NO element — the bar is started.
        expect(
          (c.chargeAction() as ChargeAction).element,
          isNull,
          reason: 'premise: a continuing charge carries no element',
        );
        await c.submitTurn(c.chargeAction());
        c.finishTurn();
        expect(
          c.chargesThisDuel,
          {element.name: 2},
          reason:
              'kills a tally read off the action (the second charge names no '
              'element), and one that counts the opponent\'s umbra',
        );
        c.newDuel();
        expect(
          c.chargesThisDuel,
          isEmpty,
          reason: 'kills a rematch that inherits the last duel\'s charges',
        );
      });
    });

    test(
      '⭐ banked in the result write — one save, not one per charge',
      () async {
        final storage = _JsonMem();
        // First Blood already held, so the win earns nothing of its own and
        // the result write is the only write.
        final game = GameState(
          storage,
          _p()
            ..charges['pyro'] = 10
            ..achievements.add('first_blood'),
        );
        await game.recordDuelResult(
          won: true,
          charges: const {'pyro': 7, 'aqua': 2},
        );
        expect(
          storage.stored!.charges,
          {'pyro': 17, 'aqua': 2},
          reason:
              'kills recordDuelResult dropping the charges, and one that '
              'replaces the lifetime count instead of adding',
        );
        expect(
          storage.saves,
          1,
          reason:
              'kills a charge flush in a write of its own — it rides the '
              'XP/gold write',
        );
      },
    );

    test('the encounter paths pass the tally through', () async {
      final won = GameState(_JsonMem(), _p());
      await won.beginAdventure(_woods, rng: Random(3));
      await won.winEncounter(
        remainingHp: 80,
        rng: Random(3),
        charges: const {'flora': 4},
      );
      expect(won.profile.charges, {
        'flora': 4,
      }, reason: 'kills winEncounter dropping the charges');

      final lost = GameState(_JsonMem(), _p());
      await lost.beginAdventure(_woods, rng: Random(3));
      await lost.loseEncounter(charges: const {'geo': 3});
      expect(lost.profile.charges, {
        'geo': 3,
      }, reason: 'kills loseEncounter dropping the charges');

      final storage = _JsonMem();
      final fled = GameState(storage, _p());
      await fled.beginAdventure(_woods, rng: Random(3));
      await fled.fleeEncounter(remainingHp: 50, charges: const {'aero': 2});
      expect(storage.stored!.charges, {
        'aero': 2,
      }, reason: 'kills fleeEncounter dropping the charges, or never saving');
    });

    testWidgets('⭐ launchDuel banks them — and the Academy does not', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<DuelScreen> launch(GameState game, {required bool academy}) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            // A fresh navigator each launch — the last arena stays pushed.
            key: UniqueKey(),
            home: GameStateScope(
              state: game,
              child: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        unawaited(
          launchDuel(
            ctx,
            loadout: Loadout.starter,
            driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
            campaign: false,
            academy: academy,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        return tester.widget<DuelScreen>(find.byType(DuelScreen));
      }

      final geared = GameState(_JsonMem(), _p());
      final screen = await launch(geared, academy: false);
      await screen.onResult!(DuelOutcome.won, const {'solar': 5});
      await tester.pump();
      expect(geared.profile.charges, {
        'solar': 5,
      }, reason: 'kills a launcher that drops the tally on the way in');

      final academy = GameState(_JsonMem(), _p());
      final bout = await launch(academy, academy: true);
      await bout.onResult!(DuelOutcome.won, const {'solar': 5});
      await tester.pump();
      expect(
        academy.profile.charges,
        isEmpty,
        reason:
            'kills an Academy bout that touches the character — it banks no '
            'XP, gold or wins, and no charges either',
      );
    });

    testWidgets('⭐ the arena hands the controller\'s tally to its settler', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Map<String, int>? handed;
      await tester.pumpWidget(
        MaterialApp(
          home: DuelScreen(
            loadout: Loadout.starter,
            driver: _Scripted(const ForfeitAction()),
            onResult: (outcome, charges) async {
              handed = charges;
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      final element = Loadout.starter.elements.first;
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      // Let the turn animate out, in bounded steps (the arena never settles).
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      final leave = find.text('Surrender');
      await tester.tap(leave.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(leave.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        handed,
        {element.name: 1},
        reason:
            'kills an arena that reports the outcome without the charges '
            'thrown — the tally would never leave the controller',
      );
    });
  });

  group('items seen', () {
    test('⭐ a win records every def that DROPPED, kept or not', () async {
      final storage = _JsonMem();
      final game = GameState(storage, _p());
      await game.beginAdventure(_woods, rng: Random(3));
      final dropped = await game.winEncounter(remainingHp: 80, rng: Random(3));
      expect(dropped, isNotEmpty, reason: 'premise: something dropped');
      expect(
        storage.stored!.itemsSeen,
        dropped.toSet(),
        reason:
            'kills winEncounter with no itemsSeen hook, and one whose '
            'record never reaches disk',
      );
      expect(
        game.profile.backpack.contents,
        isEmpty,
        reason: 'premise: seen before anything is kept (the picker is after)',
      );
    });
  });

  group('travel', () {
    final departed = DateTime.utc(2026, 1, 1, 12);
    ActiveTrip trip() => ActiveTrip(
      stops: const ['hearthwood', 'whispering_woods', 'pennycross'],
      secondsAtStop: const [0, 100, 300],
      departedAt: departed,
    );

    test('⭐ an arrival adds the whole trip, once', () async {
      var clock = departed.add(const Duration(seconds: 50));
      final game = GameState(_JsonMem(), _p()..trip = trip(), now: () => clock);
      expect(
        game.profile.travelSeconds,
        0,
        reason: 'kills seconds counted before the trip arrives',
      );
      clock = departed.add(const Duration(hours: 2));
      await game.tick();
      expect(
        game.profile.travelSeconds,
        300,
        reason:
            'kills a settleTravel with no travelSeconds hook, and one that '
            'counts wall-clock time since departure rather than the trip',
      );
      await game.tick();
      expect(
        game.profile.travelSeconds,
        300,
        reason: 'kills a trip counted again on the next tick',
      );
    });

    test('a cancel adds the road actually walked', () async {
      final game = GameState(
        _JsonMem(),
        _p()..trip = trip(),
        now: () => departed.add(const Duration(seconds: 120)),
      );
      await game.cancelTravel();
      expect(
        game.profile.travelSeconds,
        120,
        reason:
            'kills a cancel that loses the walk (0), or pays the whole trip '
            '(300)',
      );
    });
  });
}
