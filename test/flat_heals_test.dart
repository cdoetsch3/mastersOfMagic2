/// Consumables restore a FLAT amount (Christian, 2026-09-21).
///
/// ⭐ The ruling: a potion is a fixed object. It holds what it holds, and it
/// restores the same health in a level-1 hand and a level-40 one. Zone
/// progression does the scaling the old percentage was there to do — a
/// higher-zone potion is simply a bigger potion.
///
/// ⭐ Mutation-verified, and the mutant this file exists to kill is a single
/// one: an implementation that kept `maxHp × N / 100` anywhere. It is
/// invisible at 100 max health, so **every character here is level 10**
/// (142 max) — where 30 flat and "30%" differ by 13, loudly.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/duel_status_badges.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/belt_potions.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// Every shipped heal and what each one restores in total, as ruled.
///
/// ⚠️ The Tonic's 30 is its whole three-tick course, which is what using it
/// out of combat applies — `ItemEffect.healFor` sums the ticks.
///
/// 📝 `arcsalt_draught` is the first Celestial rung (CELESTIAL_CONTRACT
/// §3.3/§4.6, The Shattered Orrery): **185**, flat like every rung below it.
/// ⚠️ It is drop-only at band 40 as well as craftable, so it reaches a pack
/// without a recipe — which is exactly the path the fixture below walks.
const _ruled = <String, int>{
  'foragers_ration': 25,
  'sapwort_draught': 30,
  'hardtack': 60,
  'saltwort_draught': 75,
  'brookmint_tonic': 30,
  'arcsalt_draught': 185,
};

/// Total XP landing exactly on [level] (xpToNext is 100 + 50·(n−1)).
int _xpFor(int level) {
  var xp = 0;
  for (var n = 1; n < level; n++) {
    xp += 100 + (n - 1) * 50;
  }
  return xp;
}

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

/// A level-10 character on the road, carrying one [defId] in the pack.
Future<GameState> _onTheRoad(String defId) async {
  final game = GameState(
    _MemStorage(),
    PlayerProfile.newPlayer()..xp = _xpFor(10),
  );
  await game.beginAdventure(World.byId('whispering_woods'), rng: Random(1));
  game.profile.backpack = game.profile.backpack.withAdded(
    InventorySlot(defId: defId),
  )!;
  return game;
}

void main() {
  group('every shipped heal restores exactly its number', () {
    test(
      '⭐ a level-10 mage has 142 max health, so a percent would show',
      () async {
        final game = await _onTheRoad('foragers_ration');
        expect(
          game.profile.level,
          10,
          reason:
              'the fixture must actually be level 10 or nothing below bites',
        );
        expect(
          game.maxHp,
          142,
          reason:
              '⚠️ THE premise of this file: 100 × 1.04⁹. At 100 max every '
              'assertion here passes against the percentage implementation '
              'too, and the suite would be decorative',
        );
      },
    );

    for (final MapEntry(key: defId, value: amount) in _ruled.entries) {
      // ⚠️ **The level-10 fixture only bites while the heal fits under the
      // bar.** A band-40 draught restores more than 142, so `1 + amount`
      // would be capped at max HP and the assertion would compare a clamp
      // against a ruling — passing for a percentage implementation too,
      // which is the one thing this file exists to catch. Those rungs are
      // pinned by `healFor()` below instead, and by the completeness check.
      if (1 + amount <= 142) {
        test('$defId restores $amount from 1 health', () async {
          final game = await _onTheRoad(defId);
          game.run!.playerHp = 1;
          final outcome = await game.useItem(defId);

          expect(outcome.consumed, isTrue, reason: 'a wounded mage can drink');
          expect(
            game.run!.playerHp,
            1 + amount,
            reason:
                '⚠️ the ruled flat $amount. A surviving percentage restores '
                '${(142 * amount / 100).round()} here (142 × $amount%), which '
                'is the whole reason this runs at level 10',
          );
        });
      }

      test('$defId says "$amount health" and never a percentage', () {
        final def = ItemCatalogue.byId(defId) as Usable;
        expect(
          def.effect.describe,
          isNot(contains('%')),
          reason:
              'the tooltip is built from the effect, so a % surviving here '
              'means a % survived in the number too',
        );
        expect(
          def.effect.healFor(),
          amount,
          reason: 'and the text and the total come from the same field',
        );
      });
    }

    test('the catalogue ships no OTHER heal that anyone forgot', () {
      // ⚠️ Kills the quiet drift: a sixth consumable added later without a
      // ruled number would heal whatever its author guessed, and no test
      // above would notice.
      final healers = ItemCatalogue.all
          .whereType<Usable>()
          .where((d) => !d.effect.isNothing)
          .map((d) => (d as ItemDef).id)
          .toSet();
      expect(
        healers,
        _ruled.keys.toSet(),
        reason:
            'every healing item in the game is pinned here, or the ruling '
            'covers only the five that happened to be written down',
      );
    });
  });

  group('the flat amount still meets the rest of the rules', () {
    test('⭐ healing-received gear multiplies it', () {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: const [],
        playerHp: 1,
        rng: Random(1),
      );
      final outcome = run.use(
        'hardtack',
        maxHp: 1000,
        carried: true,
        healingReceivedPercent: 50,
      );
      expect(outcome.consumed, isTrue);
      expect(
        run.playerHp,
        91,
        reason:
            '60 × 1.5 = 90, onto 1. ⚠️ Flat does NOT mean unmodified — a '
            'Wickerbound Ring that stopped working on potions is the '
            'regression this ruling could easily have caused',
      );
    });

    test('⚠️ and is still clamped to max health', () {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: const [],
        playerHp: 100,
        rng: Random(1),
      );
      final outcome = run.use('saltwort_draught', maxHp: 120, carried: true);
      expect(outcome.consumed, isTrue);
      expect(
        run.playerHp,
        120,
        reason:
            'a 75 into a 20-point gap fills the gap and stops — overflow '
            'health is the bug flat heals make easiest to ship',
      );
    });

    test('a potion that can do nothing is refused, not eaten', () {
      final run = AdventureRun.roll(
        zone: World.byId('whispering_woods'),
        roster: const [],
        playerHp: 142,
        rng: Random(1),
      );
      final outcome = run.use('hardtack', maxHp: 142, carried: true);
      expect(
        outcome.consumed,
        isFalse,
        reason:
            'the refusal reads the POOL, not the bottle — spending a 60 at '
            'full health is the game stealing an item',
      );
    });
  });

  group('the belt path in a duel', () {
    test('⭐ the seam hands the engine the flat number, not a percent', () {
      expect(
        consumableEffectFor('saltwort_draught')!.healNow,
        75,
        reason:
            'the app resolves the catalogue locally for both lockstep '
            'clients; a seam still dividing by 100 sends 0 across',
      );
    });

    test('⭐ drinking off the belt mid-duel heals the flat amount', () async {
      // The drink path the arena actually uses: spendBeltItem builds the
      // action, submitTurn resolves it in the engine.
      final controller = DuelController(
        loadout: Loadout.starter,
        driver: _ForfeitingDriver(),
        belt: const ['sapwort_draught'],
        playerLevel: 10,
      );
      addTearDown(controller.dispose);
      controller.player.hp = 1;

      final drink = await controller.spendBeltItem('sapwort_draught');
      await controller.submitTurn(drink!);

      expect(
        controller.player.maxHp,
        142,
        reason: 'the duel builds the same level-10 pool the road does',
      );
      expect(
        controller.player.hp,
        31,
        reason:
            '⚠️ THE pin for the duel half of the ruling: the Draught\'s '
            'flat 30. A percentage restores 43 off the 142 max, and the '
            'two readings are indistinguishable at level 1',
      );
    });

    test('⭐ the Tonic ticks a flat 10, three times', () async {
      final controller = DuelController(
        loadout: Loadout.starter,
        driver: _ForfeitingDriver(),
        belt: const ['brookmint_tonic'],
        playerLevel: 10,
      );
      addTearDown(controller.dispose);
      controller.player.hp = 1;

      final drink = await controller.spendBeltItem('brookmint_tonic');
      await controller.submitTurn(drink!);
      controller.finishTurn();
      expect(
        controller.player.hp,
        11,
        reason:
            'the first tick lands on the turn it is drunk — a flat 10, '
            'where a 10% tick off 142 would read 15',
      );

      // Two more turns of channelling — a charge spends nothing and takes
      // nothing, so the only thing moving this health bar is the Tonic.
      for (var turn = 0; turn < 2; turn++) {
        await controller.submitTurn(const ChargeAction(MagicElement.flora));
        controller.finishTurn();
      }
      expect(
        controller.player.hp,
        31,
        reason:
            '⚠️ THE pin: three ticks of exactly 10 onto 1. A surviving '
            'percentage ticks 14 off the 142 max and lands on 43',
      );
      expect(
        controller.player.statuses.whereType<HealOverTimeStatus>(),
        isEmpty,
        reason:
            'and the course is over — a fourth tick would carry it past '
            'the 3 turns the bottle sells',
      );
    });

    test('⭐ the Tonic pip counts health, not percent', () {
      final mage = MageState(name: 'Morwen', level: 10)
        ..statuses.add(HealOverTimeStatus(healPerTurn: 10, turnsLeft: 3));
      final pip = statusBadgesFor(mage).singleWhere((b) => b.label == 'Tonic');
      expect(
        pip.sub,
        '10/t · 3t',
        reason:
            '⚠️ "10%/t" is the pre-ruling text, and on a 142-health mage it '
            'promises 14 a turn while 10 lands — the Mending and Regrow '
            'pips beside it are still percentages, so the % cannot simply '
            'be stripped everywhere',
      );
    });
  });
}

/// The minimum driver: an opponent that always forfeits, so nothing the
/// enemy does can move the health this file is measuring.
class _ForfeitingDriver implements OpponentDriver {
  @override
  String get opponentName => 'Rival';
  @override
  int get opponentLevel => 1;
  @override
  int get opponentRating => 1200;
  @override
  ItemModifiers get opponentGear => ItemModifiers.none;
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
