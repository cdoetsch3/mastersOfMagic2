import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';

Future<GameState> _game() async {
  final g = GameState(_Mem(), PlayerProfile.newPlayer());
  await g.beginAdventure(World.byId('whispering_woods'), rng: Random(1));
  g.profile.backpack = g.profile.backpack.withAdded(
    const InventorySlot(defId: 'foragers_ration'),
  )!;
  return g;
}

void main() {
  group('using an item is generic, not per-item', () {
    test('anything Usable with an effect can be used', () {
      // ⭐ The UI asks the interface, never the id — a new consumable works
      // with no code change.
      final usable = ItemCatalogue.all.whereType<Usable>().where(
        (d) => !d.effect.isNothing,
      );
      expect(usable, isNotEmpty);
      for (final d in usable) {
        expect(d.effect.describe, isNot('No effect'));
      }
    });

    test('healing is FLAT — the bottle holds what it holds', () {
      // ⭐ Ruling 2026-09-21. `healFor` takes no max health at all, so there
      // is nothing for a percentage to be a percentage OF: the signature is
      // itself the pin, and a mutant reintroducing a scale term cannot even
      // compile against this call.
      const effect = ItemEffect(heal: 25);
      expect(
        effect.healFor(),
        25,
        reason: 'a 25 restores 25, to a level 1 and to a level 40 alike',
      );
      expect(
        const ItemEffect(healPerTurn: 10, healTurns: 3).healFor(),
        30,
        reason:
            'out of combat a Tonic pays its whole course at once — 10 a '
            'tick summed, not one tick and not a percentage',
      );
      expect(const ItemEffect().healFor(), 0, reason: 'nothing heals nothing');
    });

    test(
      'an effect describes itself, so text cannot drift from the number',
      () {
        expect(
          const ItemEffect(heal: 25).describe,
          'Restores 25 health',
          reason:
              '⚠️ no % anywhere (ruling 2026-09-21) — the old text promised '
              'a fraction of the reader',
        );
        expect(
          const ItemEffect(healPerTurn: 10, healTurns: 3).describe,
          'Restores 10 health a turn for 3 turns',
        );
        expect(const ItemEffect().describe, 'No effect');
      },
    );
  });

  group('using it between encounters', () {
    test('a wounded player is healed and the item is spent', () async {
      final g = await _game();
      g.run!.playerHp = 40;
      final before = g.profile.backpack.countOf('foragers_ration');
      final outcome = await g.useItem('foragers_ration');
      expect(outcome.consumed, isTrue);
      expect(g.run!.playerHp, greaterThan(40));
      expect(g.profile.backpack.countOf('foragers_ration'), before - 1);
    });

    test('⚠️ at full health it is refused, NOT eaten', () async {
      final g = await _game();
      final outcome = await g.useItem('foragers_ration');
      expect(outcome.consumed, isFalse);
      expect(
        g.profile.backpack.countOf('foragers_ration'),
        1,
        reason:
            'a game that eats your food for nothing is worse than one '
            'that refuses',
      );
      expect(outcome.message, contains('full health'));
    });

    test('healing never overshoots max', () async {
      final g = await _game();
      g.run!.playerHp = 99;
      await g.useItem('foragers_ration');
      expect(g.run!.playerHp, 100);
    });

    test('what you are not carrying cannot be used', () async {
      final g = await _game();
      final outcome = await g.useItem('sapwort_draught');
      expect(outcome.consumed, isFalse);
      expect(outcome.message, contains('not carrying'));
    });

    test('a material is not usable', () async {
      final g = await _game();
      g.profile.backpack = g.profile.backpack.withAdded(
        const InventorySlot(defId: 'oak_log'),
      )!;
      final outcome = await g.useItem('oak_log');
      expect(outcome.consumed, isFalse);
      expect(g.profile.backpack.countOf('oak_log'), 1);
    });

    test('⚠️ nothing can be used once the run is over', () async {
      final g = await _game();
      g.run!.playerHp = 10;
      await g.loseEncounter();
      final outcome = await g.useItem('foragers_ration');
      expect(outcome.consumed, isFalse);
    });

    test('every refusal says something', () {
      // A silent no-op is the worst possible outcome here.
      for (final o in [
        const UseOutcome.refused('x'),
        const UseOutcome.used('y'),
      ]) {
        expect(o.message.trim(), isNotEmpty);
      }
    });
  });
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
