/// The playtester's do-over (ruling 2026-08-25): Character reset returns a
/// profile to true new-character state — through the same dialog the button
/// shows, because a confirm flow that is only tested headless is a confirm
/// flow that quietly stops confirming.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/account_screen.dart';

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

/// A profile that has been PLAYED: levels, gold, gear worn, goods stored.
PlayerProfile _veteran() {
  final p = PlayerProfile.newPlayer(name: 'Christian')
    ..xp = 50000
    ..gold = 2220
    ..skillXp['woodcarving'] = 600
    ..backpack = Backpack.of(const [InventorySlot(defId: 'oak_log')])
    ..belt = const Belt(loaded: ['sapwort_draught'])
    ..storerooms['hearthwood'] = const Storeroom(stacks: {'oak_log': 6});
  p.itemInstances['h'] = const ItemInstance(
    instanceId: 'h',
    defId: 'heartwood_stave',
  );
  p.equipped[EquipSlot.mainHand] = 'h';
  return p;
}

void main() {
  test('resetProfile: everything a new character lacks is GONE, the name '
      'stays, and the reset survives the save', () async {
    final storage = _JsonMem();
    final game = GameState(storage, _veteran());
    await game.resetProfile();

    final fresh = PlayerProfile.newPlayer();
    expect(game.profile.name, 'Christian',
        reason: 'identity survives — it is a character reset, not an exit');
    expect(game.profile.xp, fresh.xp,
        reason: '⚠️ the mutant this kills: a reset that forgets combat XP');
    expect(game.profile.gold, fresh.gold);
    expect(game.profile.skillXp, isEmpty,
        reason: 'skill ledgers are part of the character, not the account');
    expect(game.profile.backpack.used, 0);
    expect(game.profile.belt.loaded, isEmpty);
    expect(game.profile.storerooms, isEmpty,
        reason: '⚠️ Storerooms survive DEATH by ruling — but a reset is not '
            'a death, it is a new character, and a new character owns nothing');
    expect(game.profile.equipped.values.whereType<String>(), isEmpty);
    expect(game.profile.itemInstances, isEmpty);

    final reloaded = (await storage.load())!;
    expect(reloaded.xp, fresh.xp,
        reason: 'an unreloadable reset is a reset that undoes itself');
    expect(reloaded.name, 'Christian');
  });

  testWidgets('the dialog warns, the cancel path changes NOTHING', (
    tester,
  ) async {
    final game = GameState(_JsonMem(), _veteran());
    await tester.pumpWidget(
      GameStateScope(
        state: game,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => confirmCharacterReset(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no way to undo'), findsOneWidget,
        reason: 'the ruled warning, verbatim in spirit');
    await tester.tap(find.text('Keep my character'));
    await tester.pumpAndSettle();
    expect(game.profile.xp, 50000,
        reason: '⚠️ the mutant this kills: a cancel that resets anyway');
    expect(game.profile.itemInstances, isNotEmpty);
  });

  testWidgets('the confirm path resets, through the real dialog', (
    tester,
  ) async {
    final game = GameState(_JsonMem(), _veteran());
    await tester.pumpWidget(
      GameStateScope(
        state: game,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => confirmCharacterReset(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset — no undo'));
    await tester.pumpAndSettle();
    expect(game.profile.xp, 0);
    expect(game.profile.name, 'Christian');
    expect(find.textContaining('fresh start'), findsOneWidget);
  });
}
