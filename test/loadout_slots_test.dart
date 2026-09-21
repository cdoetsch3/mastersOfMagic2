/// ⭐ **RULING (Christian, 2026-09-21): removing a spell must not shift the
/// others.** "I'm used to my R being one thing and my D being something else,
/// so if I need to replace my Q, I shouldn't have to re-assign everything. If
/// I remove the Q, the Q should be empty, and then the next thing I add should
/// go back to the Q."
///
/// So a preset's spells are **sparse** — [LoadoutPreset.spellSlots] is keyed
/// by keyboard position and holds nulls — while everything that only wants to
/// know *which* spells (validity, the catalogue, the ladder, the Academy) is
/// still handed the dense [LoadoutPreset.spellIds].
///
/// ⭐ Mutation-verified: every assertion below names the wrong implementation
/// it kills, and the one mutant this whole file exists to catch is the
/// innocent-looking `spellIds.remove(id)` — a list that closes its gaps, which
/// is exactly the behaviour the ruling forbids.
///
/// ⚠️ Element slots are deliberately NOT part of this: the ruling names
/// spells, and 1-5 is nowhere near the habit QWERT is.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:masters_of_magic_2/screens/tabs/spellbook_tab.dart';
import 'package:mom_engine/mom_engine.dart';

/// Three real spells standing in for the ruling's a / b / c.
const _a = 'flick';
const _b = 'bolt';
const _c = 'blast';
const _d = 'ward';
const _e = 'flurry';

/// A preset whose slot list is EXACTLY [slots] — the arithmetic below is
/// about which index holds what, so the cap-length padding would only add
/// noise. (The padding itself is tested separately.)
LoadoutPreset _preset(List<String?> slots) =>
    LoadoutPreset(name: 'Test', elementIds: const ['pyro'], spellSlots: slots);

void main() {
  group('removing leaves a hole', () {
    test('⭐ removing the first spell empties its slot and moves nothing', () {
      final preset = _preset([_a, _b, _c]);
      expect(preset.removeSpell(_a), isTrue);
      expect(
        preset.spellSlots,
        [null, _b, _c],
        reason:
            '⚠️ THE mutant this file exists to kill: a list that compacts '
            "(['bolt','blast']), which moves the player's W onto their Q and "
            'their E onto their W — the ruling in one line',
      );
      expect(
        preset.spellIds,
        [_b, _c],
        reason:
            '⚠️ the mutant this kills: a derived id list that leaks the '
            "holes (a null in the middle) — everything outside the key "
            'mapping asks "which spells", and the answer has no gaps',
      );
      expect(
        preset.spellCount,
        2,
        reason: 'the count is of spells held, not of slots owned',
      );
    });

    test('removing a spell that is not there changes nothing', () {
      final preset = _preset([_a, null, _c]);
      expect(preset.removeSpell(_d), isFalse);
      expect(
        preset.spellSlots,
        [_a, null, _c],
        reason:
            '⚠️ the mutant this kills: a remove that nulls slot 0 (or the '
            'first hole) when it cannot find its id',
      );
    });
  });

  group('adding goes back into the first hole', () {
    test('⭐ the spell after a removal lands in the emptied slot', () {
      final preset = _preset([_a, _b, _c])..removeSpell(_a);
      expect(preset.addSpell(_d), isTrue);
      expect(
        preset.spellSlots,
        [_d, _b, _c],
        reason:
            '⚠️ the mutant this kills: an append — Ward on the end would '
            'leave the Q empty forever and put the new spell on a key the '
            'player never chose',
      );
    });

    test('⭐ two holes fill left to right: the Q first, then the E', () {
      // "If I remove the Q and the E, the next thing I add should be the Q
      // (since it's first) and then the E."
      final preset = _preset([_a, _b, _c])
        ..removeSpell(_a)
        ..removeSpell(_b);
      expect(preset.addSpell(_d), isTrue);
      expect(preset.addSpell(_e), isTrue);
      expect(
        preset.spellSlots,
        [_d, _e, _c],
        reason:
            '⚠️ the mutant this kills: filling the LAST hole first (or in '
            'removal order), which hands the two new spells each other\'s key',
      );
    });

    test('⭐ and in the other removal order, too — slot order is what rules', () {
      // "(or the E and then the Q)" — the same answer either way.
      final preset = _preset([_a, _b, _c])
        ..removeSpell(_b)
        ..removeSpell(_a);
      expect(preset.addSpell(_d), isTrue);
      expect(
        preset.spellSlots,
        [_d, null, _c],
        reason:
            '⚠️ the mutant this kills: a fill that follows the order the '
            'holes were MADE in — the ruling says first slot, not first freed',
      );
      expect(preset.addSpell(_e), isTrue);
      expect(preset.spellSlots, [_d, _e, _c], reason: 'and then the second');
    });

    test('a full preset refuses the add and keeps every slot as it was', () {
      final preset = _preset([_a, _b, _c]);
      expect(
        preset.addSpell(_d),
        isFalse,
        reason:
            '⚠️ the mutant this kills: an add that grows the slot list past '
            'the cap, handing the player an eleventh spell with no key',
      );
      expect(preset.spellSlots, [
        _a,
        _b,
        _c,
      ], reason: 'a refused add must not have half-happened');
    });

    test('a preset built from ids is padded to the cap, so it can grow', () {
      final preset = LoadoutPreset(
        name: 'Starter-ish',
        elementIds: const ['pyro'],
        spellIds: const [_a, _b],
      );
      expect(
        preset.spellSlots.length,
        Loadout.maxSpellSlots,
        reason:
            '⚠️ the mutant this kills: slots sized to the ids given — a '
            'two-spell preset would then be "full" and refuse a third',
      );
      expect(preset.spellSlots.sublist(0, 2), [_a, _b]);
      expect(preset.addSpell(_c), isTrue);
      expect(preset.spellSlots[2], _c, reason: 'the third slot was free');
    });
  });

  test('setSpellAt writes one slot, and refuses an index it does not own', () {
    final preset = _preset([_a, _b, _c]);
    expect(preset.setSpellAt(1, _d), isTrue);
    expect(
      preset.spellSlots,
      [_a, _d, _c],
      reason:
          '⚠️ the mutant this kills: an insert rather than a write — the '
          'drag/drop this exists for swaps a slot, it does not push a row',
    );
    expect(preset.setSpellAt(1, null), isTrue);
    expect(preset.spellSlots, [_a, null, _c], reason: 'null empties the slot');
    expect(preset.setSpellAt(3, _d), isFalse);
    expect(preset.setSpellAt(-1, _d), isFalse);
    expect(preset.spellSlots, [
      _a,
      null,
      _c,
    ], reason: 'an out-of-range write is a no-op, never an append');
  });

  group('clampToCaps', () {
    test('⭐ a tighter budget drops the LAST slots, holes and all', () {
      final preset = _preset([_a, null, _c, null, _e])
        ..clampToCaps(spellBudget: 4);
      expect(
        preset.spellSlots,
        [_a, null, _c, null],
        reason:
            "⚠️ the mutant this kills: a clamp that compacts first — "
            "['flick','blast','flurry',null] keeps one more spell but moves "
            "the player's E onto their W, which is the ruling broken by a "
            'migration',
      );
      expect(preset.spellIds, [_a, _c], reason: 'and the dense view follows');
    });

    test('a budget the preset already fits leaves the slots alone', () {
      final preset = _preset([_a, null, _c])..clampToCaps();
      expect(
        preset.spellSlots,
        [_a, null, _c],
        reason:
            '⚠️ the mutant this kills: a clamp that normalises to the cap '
            'length on every boot, quietly re-opening ten slots for a preset '
            'that was gated down to three',
      );
    });
  });

  group('JSON', () {
    test('⭐ a round trip keeps the holes exactly where they were', () {
      final preset = _preset([null, _b, null, _d]);
      final back = LoadoutPreset.fromJson(preset.toJson());
      expect(
        back.spellSlots,
        [null, _b, null, _d],
        reason:
            '⚠️ the mutant this kills: a save that writes only the dense '
            'ids — the player closes the app with an empty Q and reopens it '
            'with everything shifted one key left',
      );
    });

    test('⭐ the dense spellIds key is still written, for older clients', () {
      final json = _preset([null, _b, _c]).toJson();
      expect(
        json['spellIds'],
        [_b, _c],
        reason:
            '⚠️ the mutant this kills: dropping the legacy key — a cloud '
            'profile saved here would read as an EMPTY loadout on a build '
            'that predates spellSlots',
      );
      expect(json['spellSlots'], [
        null,
        _b,
        _c,
      ], reason: 'and the slots are what this build reads back');
    });

    test('⭐ a legacy save (spellIds only) packs from slot 0 up', () {
      final back = LoadoutPreset.fromJson({
        'name': 'Old save',
        'elementIds': ['pyro'],
        'spellIds': [_a, _b],
      });
      expect(
        back.spellSlots.sublist(0, 2),
        [_a, _b],
        reason:
            '⚠️ the mutant this kills: a migration that leaves the old ids '
            'unread — every save written before this ruling would come back '
            'as an empty loadout',
      );
      expect(
        back.spellSlots.sublist(2).every((id) => id == null),
        isTrue,
        reason: 'and the rest of the cap is empty, not absent',
      );
      expect(
        back.spellSlots.length,
        Loadout.maxSpellSlots,
        reason: 'a migrated preset can still grow to the cap',
      );
    });

    test('spellSlots wins when both keys are present', () {
      final back = LoadoutPreset.fromJson({
        'name': 'Both',
        'elementIds': ['pyro'],
        'spellIds': [_b, _c],
        'spellSlots': [null, _b, _c],
      });
      expect(
        back.spellSlots,
        [null, _b, _c],
        reason:
            '⚠️ the mutant this kills: reading the legacy key first, which '
            'would flatten every load back to dense',
      );
    });
  });

  group('toLoadout carries the slot positions into the duel', () {
    test('⭐ slot 2 is key index 2 even when slot 0 is empty', () {
      final loadout = _preset([null, null, _c]).toLoadout();
      expect(
        loadout.spellAtSlot(2)?.id,
        _c,
        reason:
            '⚠️ THE duel mutant: a dense Loadout puts Blast at index 0, so '
            "the arena's Q casts it and the E does nothing — the exact "
            'complaint the ruling was filed about',
      );
      expect(
        loadout.spellAtSlot(0),
        isNull,
        reason: 'an emptied Q casts nothing, rather than borrowing a spell',
      );
      expect(loadout.spellAtSlot(1), isNull, reason: 'and so does the W');
      expect(
        loadout.spells.map((s) => s.id),
        [_c],
        reason:
            'the spell LIST stays dense — the engine, the AI and the ladder '
            'never see a hole',
      );
    });

    test('a dense loadout maps key to position, with no index list at all', () {
      final loadout = Loadout(
        elements: const [MagicElement.pyro],
        spells: [Spellbook.byId(_a), Spellbook.byId(_b)],
      );
      expect(
        loadout.spellAtSlot(1)?.id,
        _b,
        reason:
            '⚠️ the mutant this kills: a null index list read as "no slots" '
            '— every ladder bot and AI persona builds a Loadout this way',
      );
      expect(
        loadout.spellAtSlot(2),
        isNull,
        reason: 'past the end is empty, not a range crash',
      );
      expect(loadout.slotIndices, [0, 1], reason: 'the identity mapping');
    });

    test(
      'an unresolvable id is dropped WITHOUT closing the slot behind it',
      () {
        final loadout = _preset([_a, 'fireball', _c]).toLoadout();
        expect(
          loadout.spellAtSlot(2)?.id,
          _c,
          reason:
              '⚠️ the mutant this kills: a stale id from an old save dropped '
              'by compacting, which shifts every key after it',
        );
        expect(
          loadout.spellAtSlot(1),
          isNull,
          reason: 'the stale slot is empty',
        );
      },
    );
  });

  // ---- the screens ------------------------------------------------------

  testWidgets(
    '⭐ the Spellbook tray leaves a hole where the unequipped spell was',
    (tester) async {
      final game = await _pumpSpellbook(tester);
      final first = Spellbook.byId(game.profile.activePreset.spellIds.first);
      final second = Spellbook.byId(game.profile.activePreset.spellIds[1]);

      expect(
        _inTraySlot(0, first.name),
        findsOneWidget,
        reason: 'the fixture: the first spell starts in the Q slot',
      );
      await tester.tap(_inTraySlot(0, first.name));
      await tester.pumpAndSettle();

      expect(
        _traySlot(0),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: a tray that draws only the filled '
            'slots — the emptied Q would vanish and every chip after it would '
            'slide one place left, under the finger that just pressed',
      );
      expect(
        _inTraySlot(0, 'Q'),
        findsOneWidget,
        reason: 'and the empty cell still says which key it is',
      );
      expect(
        _inTraySlot(0, first.name),
        findsNothing,
        reason: 'the spell really did come out',
      );
      expect(
        _inTraySlot(1, second.name),
        findsOneWidget,
        reason:
            "⚠️ the mutant this kills: the removal compacting — the second "
            'spell must still be the W, not have been promoted to the Q',
      );
      expect(
        tester.getTopLeft(_traySlot(0)).dx,
        lessThan(tester.getTopLeft(_traySlot(1)).dx),
        reason: 'the hole holds its place in the row, it does not move behind',
      );
      expect(
        game.profile.activePreset.spellSlots[0],
        isNull,
        reason: 'and the saved preset is sparse, not merely the pixels',
      );
      expect(
        game.profile.activePreset.spellSlots[1],
        second.id,
        reason:
            '⚠️ the mutant this kills: a screen that draws holes over a '
            'preset it still compacts on save',
      );
    },
  );

  testWidgets('⭐ the arena leaves the Q tab empty and keeps the E live', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final loadout = _preset([null, null, _c]).toLoadout();
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          loadout: loadout,
          driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final blast = Spellbook.byId(_c);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spell-slot-2')),
        matching: find.text(blast.name),
      ),
      findsOneWidget,
      reason:
          '⚠️ THE duel mutant: a dense loadout paints Blast on the Q tab — '
          "the player's E, which they have the habit for, would be blank",
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spell-slot-0')),
        matching: find.text(blast.name),
      ),
      findsNothing,
      reason: 'and the emptied Q holds nothing',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spell-slot-0')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
      reason:
          '⚠️ the mutant this kills: an empty tab that is still tappable — '
          'a Q that eats a press mid-duel is worse than one that is plainly '
          'empty',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spell-slot-0')),
        matching: find.text('Q'),
      ),
      findsOneWidget,
      reason: 'the empty tab still wears its key, so the row stays readable',
    );
  });
}

// ---- harness ----------------------------------------------------------

Finder _traySlot(int slot) => find.byKey(ValueKey('tray-slot-$slot'));

Finder _inTraySlot(int slot, String text) =>
    find.descendant(of: _traySlot(slot), matching: find.text(text));

/// The Spellbook tab on a tall surface, on a fresh (level 1) profile — the
/// same harness `spellbook_browse_test.dart` uses, for the same reason: the
/// shelf only builds the tiles the viewport reaches.
Future<GameState> _pumpSpellbook(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(720, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final game = GameState(_Mem(), PlayerProfile.newPlayer());
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GameStateScope(state: game, child: const SpellbookTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return game;
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
