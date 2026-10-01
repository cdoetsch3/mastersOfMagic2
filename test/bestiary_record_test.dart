/// The Bestiary's record on the profile (ruling, Christian playtest
/// 2026-09-30, note 8): `PlayerProfile.bestiary`, creature id →
/// `{seen, slain}`, persisted beside `achievements`; `seen` ticks when a
/// fight begins, `slain` when it is won.
///
/// ⭐ Mutation-verified: each `reason:` names the wrong implementation it
/// kills — a field never serialised, a sparse write, a hook in the wrong
/// method, a kill counted on a loss.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/bestiary_record.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/adventure_screen.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

final _woods = World.byId('whispering_woods');

Future<(GameState, _Mem)> _onAdventure() async {
  final mem = _Mem();
  final game = GameState(mem, PlayerProfile.newPlayer());
  await game.beginAdventure(_woods, rng: Random(3));
  return (game, mem);
}

void main() {
  group('PlayerProfile.bestiary round-trip', () {
    test('⭐ survives toJson/fromJson under "bestiary"', () {
      final p = PlayerProfile.newPlayer()
        ..bestiary['listening_fawn'] = const BestiaryEntry(seen: 3, slain: 2)
        ..bestiary['heartwood'] = const BestiaryEntry(seen: 1);
      final json = p.toJson();

      expect(json['bestiary'], {
        'listening_fawn': {'seen': 3, 'slain': 2},
        'heartwood': {'seen': 1, 'slain': 0},
      }, reason: 'kills a toJson that never writes the field (or renames it)');
      expect(PlayerProfile.fromJson(json).bestiary, {
        'listening_fawn': const BestiaryEntry(seen: 3, slain: 2),
        'heartwood': const BestiaryEntry(seen: 1),
      }, reason: 'kills a fromJson that drops the field, or swaps seen/slain');
    });

    test('absent reads as "met nothing"', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('bestiary');
      expect(
        PlayerProfile.fromJson(json).bestiary,
        isEmpty,
        reason:
            'kills a fromJson that throws or invents entries on a save '
            'from before 2026-09-30',
      );
    });

    test('a malformed count reads as 0, never as a kill', () {
      final entry = BestiaryEntry.fromJson({'seen': 2, 'slain': 'many'});
      expect(
        entry,
        const BestiaryEntry(seen: 2),
        reason: 'kills a reader that throws on, or trusts, a damaged count',
      );
    });

    test('⭐ the character document always carries it — even empty', () {
      final docs = ProfileDocuments.split(PlayerProfile.newPlayer());
      expect(
        docs.character.containsKey('bestiary'),
        isTrue,
        reason:
            'kills a sparse write: the field set must not vary, so the '
            'update mask always names it (profile_storage _maskFor)',
      );
    });

    test('⭐ round-trips through the cloud documents', () {
      final p = PlayerProfile.newPlayer()
        ..bestiary['listening_fawn'] = const BestiaryEntry(seen: 4, slain: 1);
      final docs = ProfileDocuments.split(p);
      final back = ProfileDocuments.assemble(
        user: docs.user,
        character: docs.character,
      );
      expect(
        back.bestiary['listening_fawn'],
        const BestiaryEntry(seen: 4, slain: 1),
        reason:
            'kills a split that moves the field off the character '
            'document, or an assemble that loses it',
      );
    });
  });

  group('the hooks', () {
    test(
      '⭐ seen ticks when the fight begins — and nothing else does',
      () async {
        final (game, mem) = await _onAdventure();
        final id = game.run!.current!.def.id;

        await game.beginEncounter();

        expect(
          game.profile.bestiary[id],
          const BestiaryEntry(seen: 1),
          reason:
              'kills a seen hooked into winEncounter/loseEncounter (still 0 '
              'here), or a beginEncounter that also counts a kill',
        );
        expect(
          mem.stored?.bestiary[id],
          const BestiaryEntry(seen: 1),
          reason: 'kills a beginEncounter that mutates without saving',
        );
      },
    );

    test('⭐ slain ticks on a win, and the win does not tick seen', () async {
      final (game, _) = await _onAdventure();
      final id = game.run!.current!.def.id;

      await game.beginEncounter();
      await game.winEncounter(remainingHp: 80, rng: Random(3));

      expect(
        game.profile.bestiary[id],
        const BestiaryEntry(seen: 1, slain: 1),
        reason:
            'kills a winEncounter that forgets slain (slain 0), or one '
            'that also counts seen (seen 2)',
      );
    });

    test('⭐ a loss counts the meeting, never a kill', () async {
      final (game, _) = await _onAdventure();
      final id = game.run!.current!.def.id;

      await game.beginEncounter();
      await game.loseEncounter();

      expect(
        game.profile.bestiary[id],
        const BestiaryEntry(seen: 1),
        reason:
            'kills slain hooked into loseEncounter (or into recordDuelResult, '
            'which both paths call)',
      );
    });

    test('no run, no record', () async {
      final game = GameState(_Mem(), PlayerProfile.newPlayer());
      await game.beginEncounter();
      expect(
        game.profile.bestiary,
        isEmpty,
        reason: 'kills a beginEncounter that writes without a fight to begin',
      );
    });

    testWidgets('⭐ pressing Fight is the moment seen ticks', (tester) async {
      final (game, _) = await _onAdventure();
      final id = game.run!.current!.def.id;
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: GameStateScope(
            state: game,
            child: AdventureScreen(zone: _woods),
          ),
        ),
      );

      expect(game.profile.bestiary[id], isNull);
      await tester.tap(find.text('Fight'));
      await tester.pump();

      expect(
        game.profile.bestiary[id]?.seen,
        1,
        reason:
            'kills an AdventureScreen._fight that pushes the duel without '
            'calling beginEncounter',
      );

      // Tear the duel down so its clocks do not outlive the test.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
