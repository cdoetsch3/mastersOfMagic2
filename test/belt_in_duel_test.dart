/// The belt as a duel mechanic (ITEMS §10.3b; rulings 2026-08-18): a loaded
/// potion is a move, it is spent the moment it is drunk, and only the player
/// has one.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — the potion that survives the fight it was drunk in, the free turn,
/// the monster that heals itself, the belt row that renders an empty rail.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/belt_potions.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

const _draught = 'sapwort_draught';
const _tonic = 'brookmint_tonic';
const _ration = 'foragers_ration';

void main() {
  group('the catalogue seam (consumableEffectFor)', () {
    test('⭐ reads the numbers off the def, never a second copy of them', () {
      final effect = consumableEffectFor(_draught)!;
      expect(effect.name, 'Sapwort Draught', reason: 'the log says the name');
      expect(
        effect.healNowPercent,
        20,
        reason: 'restating the 20 here is how a tooltip and a heal drift apart',
      );
      expect(effect.hotTurns, 0);
    });

    test('the Tonic arrives as a heal-over-time, not a lump', () {
      final effect = consumableEffectFor(_tonic)!;
      expect(effect.healNowPercent, 0);
      expect(effect.hotPercentPerTurn, 9);
      expect(effect.hotTurns, 3);
    });

    test('⚠️ a ration is Usable but NOT beltable, so it resolves to nothing',
        () {
      expect(
        consumableEffectFor(_ration),
        isNull,
        reason: 'gating on Usable rather than BeltableDef is exactly the '
            'loophole §6b.3 splits the two types to close',
      );
    });

    test('an id nothing owns resolves to nothing rather than crashing', () {
      expect(consumableEffectFor('philosophers_stone'), isNull);
    });

    test('a belt slot cannot hold equipment', () {
      expect(consumableEffectFor('fawnhide_belt'), isNull);
    });
  });

  group('drinking spends the item, immediately and permanently', () {
    test('⭐ the slot empties and the profile SAVES right then', () async {
      final storage = _MemStorage();
      final game = _game(storage, belt: [_draught]);
      final controller = _controller(
        _FakeDriver(),
        belt: game.profile.belt.loaded,
        onItemConsumed: game.consumeBeltItem,
      );

      final action = await controller.spendBeltItem(_draught);

      expect(action, isNotNull);
      expect(action!.itemId, _draught);
      expect(controller.beltItems, isEmpty, reason: 'the belt slot is empty');
      expect(
        game.profile.belt.loaded,
        isEmpty,
        reason: 'and so is the profile the arena was handed',
      );
      expect(
        storage.saved?.belt.loaded,
        isEmpty,
        reason: '⚠️ SAVED, not merely mutated — a save deferred to the end of '
            'the duel gives the potion back to anyone who closes the tab, '
            'which is the dupe this ruling exists to forbid',
      );
    });

    test('it does NOT come back to the pack — it was drunk', () async {
      final storage = _MemStorage();
      final game = _game(storage, belt: [_draught]);
      await _controller(
        _FakeDriver(),
        belt: game.profile.belt.loaded,
        onItemConsumed: game.consumeBeltItem,
      ).spendBeltItem(_draught);
      expect(
        game.profile.backpack.countOf(_draught),
        0,
        reason: 'unloadFromBelt returns it; consuming must not — that would '
            'make every duel a source of free potions',
      );
    });

    test('two of the same potion: drinking one leaves the other', () async {
      final storage = _MemStorage();
      final game = _game(storage, belt: [_draught, _draught]);
      final controller = _controller(
        _FakeDriver(),
        belt: game.profile.belt.loaded,
        onItemConsumed: game.consumeBeltItem,
      );
      await controller.spendBeltItem(_draught);
      expect(
        controller.beltItems,
        [_draught],
        reason: 'removing every match would eat a whole stack per sip',
      );
      expect(storage.saved?.belt.loaded, [_draught]);
    });

    test('⚠️ an empty belt cannot submit anything', () async {
      final controller = _controller(_FakeDriver());
      expect(controller.canUseItem(_draught), isFalse);
      expect(
        await controller.spendBeltItem(_draught),
        isNull,
        reason: 'a potion the player does not have must not become a turn',
      );
    });

    test('an item the player owns but did not LOAD is refused', () async {
      var saved = 0;
      final controller = _controller(
        _FakeDriver(),
        belt: const [_draught],
        onItemConsumed: (_) async => saved++,
      );
      expect(
        controller.canUseItem(_tonic),
        isFalse,
        reason: 'the belt is what you can reach mid-duel; the pack is not',
      );
      expect(await controller.spendBeltItem(_tonic), isNull);
      expect(saved, 0, reason: 'and nothing was written for a refused move');
    });

    test('a rematch does not refill the belt', () async {
      final controller = _controller(_FakeDriver(), belt: const [_draught]);
      await controller.spendBeltItem(_draught);
      controller.newDuel();
      expect(
        controller.beltItems,
        isEmpty,
        reason: 'newDuel resets duel state; the belt is inventory, and '
            '"Duel again" refilling it is a dupe one tap wide',
      );
    });
  });

  group('using an item is a real turn', () {
    test('⭐ it resets the forfeit streak like any other played move',
        () async {
      final driver = _FakeDriver()..autoRespond = const ForfeitAction();
      final controller = _controller(driver, belt: const [_draught]);

      // Two timeouts, then a real decision, then two more timeouts. The limit
      // is 3 IN A ROW, so this must not surrender. (finishTurn is what the
      // screen calls when a turn's animation ends — without it the controller
      // is still "animating" and refuses the next move, item or otherwise.)
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      final drink = await controller.spendBeltItem(_draught);
      await controller.submitTurn(drink!);
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());
      controller.finishTurn();
      await controller.submitTurn(const ForfeitAction());

      expect(
        controller.playerDefeated,
        isFalse,
        reason: '⚠️ the streak must reset — a player drinking a potion is the '
            'opposite of an absent one. This flows through the ordinary '
            'non-forfeit path; a special case here is how it would rot',
      );
    });

    test('the control case: three straight forfeits still surrender',
        () async {
      final driver = _FakeDriver()..autoRespond = const ForfeitAction();
      final controller = _controller(driver, belt: const [_draught]);
      for (var i = 0; i < DuelController.forfeitLimit; i++) {
        await controller.submitTurn(const ForfeitAction());
        controller.finishTurn();
      }
      expect(
        controller.playerDefeated,
        isTrue,
        reason: 'without this the streak test above would pass on a rule that '
            'no longer fires at all',
      );
    });

    test('the battle log says what was drunk, in the second person', () async {
      final driver = _FakeDriver()..autoRespond = const ForfeitAction();
      final controller = _controller(driver, belt: const [_draught]);
      controller.player.hp = 40;
      final drink = await controller.spendBeltItem(_draught);
      await controller.submitTurn(drink!);
      expect(
        controller.battleLog,
        contains('You drink Sapwort Draught — healed 20'),
        reason: '"You drinks" is the third-person template leaking; the log '
            'is written to the player, and the number is what landed',
      );
    });

    test('the drinker heals and the charge bar is left alone', () async {
      final driver = _FakeDriver()..autoRespond = const ForfeitAction();
      final controller = _controller(driver, belt: const [_draught]);
      controller.player.hp = 40;
      controller.player.charge = 3;
      controller.player.element = MagicElement.pyro;
      final drink = await controller.spendBeltItem(_draught);
      await controller.submitTurn(drink!);
      expect(controller.player.hp, 60);
      expect(
        controller.player.charge,
        3,
        reason: 'drinking costs the TURN, not the cycle — losing the bar too '
            'would price a potion out of every deck',
      );
    });
  });

  group('enemies never use items', () {
    test('⚠️ a brain that emits one is a loud failure, not a healed monster',
        () async {
      final driver = LocalAiDriver(persona: _CheatingPersona());
      driver.bind(
        MageState(name: 'You'),
        MageState(name: 'Cheat'),
      );
      expect(
        () => driver.exchangeTurn(1, const ForfeitAction()),
        throwsA(isA<StateError>()),
        reason: 'items are the player\'s lane alone (ENEMIES §2.1). Silently '
            'passing it through is how a Shambler ends up drinking',
      );
    });

    test('the ordinary ladder brain never emits one', () {
      final persona = AiRoster.all.first;
      final brain = persona.buildBrain();
      final self = MageState(name: 'Foe')
        ..charge = 3
        ..element = MagicElement.pyro;
      final rng = Random(7);
      for (var i = 0; i < 200; i++) {
        expect(
          brain.chooseAction(self, MageState(name: 'You'), rng),
          isNot(isA<UseItemAction>()),
          reason: 'the guard above is a backstop, not the only thing standing '
              'between a monster and a potion',
        );
      }
    });
  });

  group('the arena draws the belt', () {
    testWidgets('⭐ a loaded potion is a control the player can see and tap',
        (tester) async {
      var consumed = <String>[];
      await _pumpArena(
        tester,
        belt: const [_draught],
        onItemConsumed: (id) async => consumed.add(id),
      );

      expect(
        find.text('Sapwort Draught'),
        findsOneWidget,
        reason: 'the belt row renders the item by name, not by def id',
      );
      expect(
        find.text('turn'),
        findsOneWidget,
        reason: '⚠️ the turn cost is ON the button — a heal that silently ate '
            'the turn is the most expensive surprise the arena can sell',
      );

      await tester.tap(find.text('Sapwort Draught'));
      await _settle(tester);

      expect(
        consumed,
        [_draught],
        reason: 'tapping spends it — through the controller, which is what '
            'persists it',
      );
    });

    testWidgets('a spent potion leaves the rail', (tester) async {
      await _pumpArena(
        tester,
        belt: const [_draught],
        onItemConsumed: (_) async {},
      );
      await tester.tap(find.text('Sapwort Draught'));
      await _settle(tester);
      expect(
        find.text('Sapwort Draught'),
        findsNothing,
        reason: 'a button that stays after the last sip is a button that '
            'lies about what is left',
      );
    });

    testWidgets('⚠️ an empty belt draws NO rail at all', (tester) async {
      await _pumpArena(tester, belt: const []);
      expect(
        find.byIcon(Icons.local_drink),
        findsNothing,
        reason: 'an empty rail spends arena height to say "you brought '
            'nothing"; the belt row is absent, not disabled-and-present',
      );
    });

    testWidgets('two loaded slots draw two buttons', (tester) async {
      await _pumpArena(tester, belt: const [_draught, _tonic]);
      expect(find.byIcon(Icons.local_drink), findsNWidgets(2));
      expect(find.text('Brookmint Tonic'), findsOneWidget);
    });
  });
}

// ---- fixtures -------------------------------------------------------------

class _MemStorage implements ProfileStorage {
  PlayerProfile? saved;
  @override
  Future<PlayerProfile?> load() async => saved;
  @override
  Future<void> save(PlayerProfile profile) async => saved = profile;
  @override
  Future<void> clear() async => saved = null;
}

/// A character wearing a two-slot belt with [belt] loaded on it.
GameState _game(_MemStorage storage, {List<String> belt = const []}) {
  final profile = PlayerProfile.newPlayer()
    ..itemInstances['b'] = ItemInstance(instanceId: 'b', defId: 'tuskhide_belt')
    ..belt = Belt(loaded: belt);
  profile.equipped[EquipSlot.belt] = 'b';
  return GameState(storage, profile);
}

DuelController _controller(
  OpponentDriver driver, {
  List<String> belt = const [],
  Future<void> Function(String defId)? onItemConsumed,
}) => DuelController(
  loadout: Loadout.starter,
  driver: driver,
  belt: belt,
  onItemConsumed: onItemConsumed,
);

/// The minimum driver a controller needs: an opponent that always forfeits.
class _FakeDriver implements OpponentDriver {
  MageAction autoRespond = const ForfeitAction();

  @override
  String get opponentName => 'Rival';
  @override
  int get opponentLevel => 1;
  @override
  ItemModifiers get opponentGear => ItemModifiers.none;
  @override
  MageApparel get opponentApparel => MageApparel.duskWitch;
  @override
  double get opponentHpScale => 1.0;
  @override
  double get opponentPowerScale => 1.0;
  @override
  bool get playerIsHost => true;
  @override
  bool get supportsRematch => false;

  @override
  Future<TurnExchange> exchangeTurn(int turn, MageAction playerAction) async =>
      TurnExchange(autoRespond);

  @override
  Future<void> reportSurrender() async {}
  @override
  void watchOpponentSurrender(void Function() onSurrendered) {}
  @override
  Future<void> dispose() async {}
}

/// A persona whose brain does the one thing no enemy may do.
class _CheatingPersona extends AiPersona {
  _CheatingPersona()
    : super(
        id: 'cheat',
        name: 'Potionhead',
        title: 'the Thirsty',
        level: 1,
        intelligence: 5,
        apparel: MageApparel.duskWitch,
        loadout: Loadout.starter,
        aggression: 0.5,
        caution: 0.5,
      );

  @override
  DuelAi buildBrain() => _PotionBrain();
}

class _PotionBrain implements DuelAi {
  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) =>
      const UseItemAction(
        _draught,
        ConsumableEffect(name: 'Sapwort Draught', healNowPercent: 20),
      );
}

/// Runs a whole turn's animation out. ⚠️ The arena never settles (it animates
/// continuously), so this is bounded pumping rather than [WidgetTester.
/// pumpAndSettle] — and it must outlast the turn, or the test tears the screen
/// down mid-animation and fails on a pending timer rather than on its subject.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _pumpArena(
  WidgetTester tester, {
  required List<String> belt,
  Future<void> Function(String defId)? onItemConsumed,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: DuelScreen(
        loadout: Loadout.starter,
        driver: LocalAiDriver(
          persona: AiRoster.all.first,
          rng: Random(2),
        ),
        belt: belt,
        onItemConsumed: onItemConsumed,
      ),
    ),
  );
  // Bounded pumps: the arena animates continuously, so it never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
