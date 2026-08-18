/// GameState.craft — the gate, the consumption, the mint, the XP.
///
/// ⭐ Mutation-verified: each assertion names the wrong implementation it
/// kills. Storage goes through real JSON (the object-identity fake would
/// pass while the save format was broken).
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/crafting/craft_quality.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/item_naming.dart';
import 'package:masters_of_magic_2/game/items/recipes/primal_recipes.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

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

GameState _carrying(Map<String, int> items, {Map<String, int>? skillXp}) {
  final profile = PlayerProfile.newPlayer()
    ..backpack = Backpack.of([
      for (final e in items.entries)
        for (var n = 0; n < e.value; n++) InventorySlot(defId: e.key),
    ]);
  if (skillXp != null) profile.skillXp.addAll(skillXp);
  return GameState(_JsonMem(), profile);
}

void main() {
  group('crafting', () {
    test('consumes the inputs, mints the output, pays the XP', () async {
      final game = _carrying({'oak_log': 5});
      final out = await game.craft(PrimalRecipes.oakWand);

      expect(out.succeeded, isTrue);
      expect(game.profile.backpack.countOf('oak_log'), 3,
          reason: 'a craft that does not consume is a duplication engine');
      expect(game.profile.backpack.countOf('oak_wand'), 1);
      expect(game.profile.skillXp['woodcarving'], 12,
          reason: 'the Wand eats 2 logs at gate 1: 2 × (4 + 2×1) = 12, banked '
              'on the ledger');
      // Equipment is non-fungible: the mint must register an instance.
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'oak_wand');
      expect(slot!.instanceId, isNotNull);
      expect(game.profile.itemInstances[slot.instanceId], isNotNull,
          reason: 'an unregistered instance id dangles forever');
    });

    test('a potion is fungible and mints no instance', () async {
      final game = _carrying({'sapwort': 2});
      final out = await game.craft(PrimalRecipes.sapwortDraught);
      expect(out.succeeded, isTrue);
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'sapwort_draught');
      expect(slot!.instanceId, isNull,
          reason: 'two draughts are interchangeable — an id would be '
              'meaningless state (ITEMS §10.3a)');
    });

    test('refuses below the skill gate, naming the gap', () async {
      final game = _carrying({'birch_log': 5});
      final out = await game.craft(PrimalRecipes.birchWand);
      expect(out.refusal, contains('Woodcarving 10'));
      expect(game.profile.backpack.countOf('birch_log'), 5,
          reason: 'a refusal must not eat materials');
    });

    test('passes the gate once the ledger says 10', () async {
      // 585 XP walks the ladder past level 10.
      final game =
          _carrying({'birch_log': 5}, skillXp: {'woodcarving': 600});
      final out = await game.craft(PrimalRecipes.birchWand);
      expect(out.succeeded, isTrue);
    });

    test('refuses missing materials, counting the shortfall', () async {
      final game = _carrying({'oak_log': 1});
      final out = await game.craft(PrimalRecipes.oakQuarterstaff);
      expect(out.refusal, contains('2 more'),
          reason: 'the message must say how far short, not merely "no"');
    });

    test('reports the level-up on the craft that crosses it', () async {
      // 19 XP in: the Draught is 2 sapwort at gate 1, so +12 lands on 31 —
      // past the 20 that opens level 2, short of the 45 that opens level 3.
      final game = _carrying({'sapwort': 2}, skillXp: {'potionsAndAlchemy': 19});
      final out = await game.craft(PrimalRecipes.sapwortDraught);
      expect(out.leveledTo, 2,
          reason: 'the UI celebrates off this field; null means silence');
    });

    test('a two-input recipe consumes both lines', () async {
      final game = _carrying(
        {'fawnhide': 2, 'bindweed_fibre': 3},
        skillXp: {'tailoring': 100},
      );
      final out = await game.craft(PrimalRecipes.fawnhideBelt);
      expect(out.succeeded, isTrue);
      expect(game.profile.backpack.countOf('fawnhide'), 0);
      expect(game.profile.backpack.countOf('bindweed_fibre'), 2,
          reason: 'only the recipe line is consumed, never the whole stack');
    });

    test('the whole craft survives a JSON reload', () async {
      final storage = _JsonMem();
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'oak_log'),
        ]);
      final game = GameState(storage, profile);
      await game.craft(PrimalRecipes.oakKnot);

      final back = GameState(storage, (await storage.load())!);
      expect(back.profile.backpack.countOf('oak_knot'), 1);
      expect(back.profile.skillLevel('woodcarving'), 1);
      expect(back.profile.skillXp['woodcarving'], 12,
          reason: 'XP that does not survive the save never existed');
    });
  });

  // ---- the quality roll (ruling 2026-08-18: quality affects stats) --------
  //
  // ⭐ These test the WIRING, not the pipeline — craft_quality's own rules are
  // covered in gesture_and_nodes_test. What can break here is the wrong grade,
  // the wrong margin, a dropped ceiling, or a mint that forgets the roll.
  group('Master at the cap is rare, and skill buys it back (§9b.9f)', () {
    /// The Master rate over [n] flawless rolls at [margin], one seed each.
    double masterRate(int margin, {int n = 4000}) {
      var hits = 0;
      for (var seed = 0; seed < n; seed++) {
        final q = CraftQuality.roll(
          grade: 1.0,
          margin: margin,
          rng: Random(seed),
          skillCeiling: CraftQuality.skillCeiling(margin),
        );
        if (q == Quality.master) hits++;
      }
      return hits / n;
    }

    test('at margin 5 a flawless act mints Master rarely but truly', () {
      final rate = masterRate(5);
      expect(rate, greaterThan(0.01),
          reason: '⚠️ the mutant this kills: an ease of 0 at the cap, which '
              'would silently turn "difficult" into "impossible" and make '
              'skillCeiling read as margin ≥ 6');
      expect(rate, lessThan(0.08),
          reason: '⭐ the ruling: the tier the cap just opened is the tier '
              'you barely make — undamped weights sit near 10%, and this '
              'bound is what pins the masterEase damping into the roll');
    });

    test('the Master rate climbs with margin, all the way up', () {
      final atCap = masterRate(5);
      final past = masterRate(10);
      final deep = masterRate(15);
      expect(past, greaterThan(atCap),
          reason: 'skill past the cap must keep buying odds — a flat ease '
              'would freeze the cap rate forever');
      expect(deep, greaterThan(past),
          reason: '⭐ at margin 15 the floor lifts to Ornate and the band '
              'narrows — the deep-margin veteran sees Master most of all');
      expect(deep, greaterThan(0.3),
          reason: 'the §9b.9d floor ruling: deep margin makes Master the '
              'expected outcome of a flawless act, not a jackpot');
    });

    test('masterEase is clamped at both ends', () {
      expect(CraftQuality.masterEase(15), 1.0,
          reason: 'full weight from the point the floor takes over');
      expect(CraftQuality.masterEase(0), CraftQuality.masterEase(-5),
          reason: 'an uncapped raw roll below the cap still tames Master '
              'instead of going negative and inverting the pick');
    });
  });

  group('crafting rolls quality onto what it mints (§9b.9d)', () {
    test('the mint carries the roll, and the outcome reports it', () async {
      final game = _carrying({'oak_log': 2});
      final out = await game.craft(PrimalRecipes.oakWand, rng: Random(1));

      expect(out.quality, isNotNull,
          reason: 'minting plain is the pre-ruling behaviour — the whole '
              'point of this change');
      final slot = game.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'oak_wand')!;
      expect(game.profile.itemInstances[slot.instanceId]!.quality, out.quality,
          reason: 'the outcome must report the roll that was actually '
              'STORED, or the result panel names an item nobody owns');
      expect(out.instance!.instanceId, slot.instanceId);
    });

    test('a fungible output rolls nothing — two draughts are the same', () async {
      final game = _carrying({'sapwort': 2});
      final out = await game.craft(PrimalRecipes.sapwortDraught, rng: Random(1));
      expect(out.quality, isNull,
          reason: 'a quality on a fungible item has nowhere to live and '
              'would make two of them different (ITEMS §10.3a)');
    });

    test('⚠️ the grade is passed through: a botched act cannot exceed Rough',
        () async {
      for (var seed = 0; seed < 40; seed++) {
        final game = _carrying({'oak_log': 2});
        final out = await game.craft(
          PrimalRecipes.oakWand,
          performance: 0,
          rng: Random(seed),
        );
        expect(out.quality, Quality.rough,
            reason: 'grade 0 caps at Rough (executionCeiling); a craft that '
                'ignores [performance] and rolls at 1 escapes it');
      }
    });

    test('⚠️ the margin is level MINUS the gate, not the level', () async {
      // Birch is gated at Woodcarving 10; a level-10 crafter is at margin 0,
      // so even a perfect act can still roll Rough (the explicit ruling).
      var roughs = 0;
      var masters = 0;
      for (var seed = 0; seed < 60; seed++) {
        final game = _carrying(
          {'birch_log': 2},
          skillXp: {'woodcarving': _skillXpForLevel(10)},
        );
        final q = (await game.craft(PrimalRecipes.birchWand, rng: Random(seed)))
            .quality;
        if (q == Quality.rough) roughs++;
        if (q == Quality.master) masters++;
      }
      expect(roughs, greaterThan(0),
          reason: 'at the gate the material still fights back — passing the '
              'raw skill level as the margin (10, not 0) lifts the floor to '
              'Standard and kills this');
      expect(masters, 0,
          reason: 'the skill ceiling is wired: below margin 5 the level caps '
              'the attempt at Ornate, and a null skillCeiling lets Master '
              'through');
    });

    test('⭐ deep margin lifts the floor off Rough and opens Master', () async {
      // Oak is gated at 1; level 16 is margin 15 — the floor's top step.
      var masters = 0;
      for (var seed = 0; seed < 60; seed++) {
        final game = _carrying(
          {'oak_log': 2},
          skillXp: {'woodcarving': _skillXpForLevel(16)},
        );
        final q = (await game.craft(PrimalRecipes.oakWand, rng: Random(seed)))
            .quality;
        expect(q, isNot(Quality.rough),
            reason: 'margin 15 with a perfect grade floors at Ornate');
        expect(q, isNot(Quality.standard),
            reason: 'same floor — Standard is below it');
        if (q == Quality.master) masters++;
      }
      expect(masters, greaterThan(0),
          reason: 'a skill ceiling that never reaches Master makes the top '
              'tier unobtainable');
    });

    test('the result panel can name the roll: "Ornate Oak Wand"', () async {
      // Margin 15 with a perfect grade floors at Ornate, so the name always
      // carries a quality word here (Standard is unwritten by design).
      final game = _carrying(
        {'oak_log': 2},
        skillXp: {'woodcarving': _skillXpForLevel(16)},
      );
      final out = await game.craft(PrimalRecipes.oakWand, rng: Random(0));
      final name = ItemCatalogue.displayName(
        ItemCatalogue.byId(out.defId!),
        out.instance,
      );
      expect(name, '${qualityWord(out.quality!)} Oak Wand',
          reason: 'the Workbench names the item off the OUTCOME — an outcome '
              'that does not carry the instance can only say "Oak Wand", and '
              'the reveal is the best beat in crafting');
    });

    test('the roll survives a JSON reload', () async {
      final storage = _JsonMem();
      final profile = PlayerProfile.newPlayer()
        ..backpack = Backpack.of(const [
          InventorySlot(defId: 'oak_log'),
          InventorySlot(defId: 'oak_log'),
        ]);
      final game = GameState(storage, profile);
      final out = await game.craft(PrimalRecipes.oakWand, rng: Random(7));

      final back = GameState(storage, (await storage.load())!);
      final slot = back.profile.backpack.slots
          .firstWhere((s) => s?.defId == 'oak_wand')!;
      expect(back.profile.itemInstances[slot.instanceId]!.quality, out.quality,
          reason: 'a roll that does not survive the save is an item that '
              'changes its stats when you close the tab');
    });

    test('⚠️ a save written before this ruling loads plain and scales ×1.00',
        () async {
      // An instance minted by the old craft(): no quality key at all.
      final old = ItemInstance.fromJson(const {
        'instanceId': 'old-1',
        'defId': 'oak_wand',
      });
      expect(old.quality, isNull, reason: 'a missing key must not throw');
      expect(
        Equipping.modifiersOf(ItemCatalogue.byId('oak_wand'), old)
            .damagePerCast,
        2,
        reason: 'the Oak Wand has always been +2 per cast, and an old save '
            'must not silently change the moment quality lands');
    });
  });
}

/// Exactly enough skill XP to stand on [level] (the ladder is 20 + 5·(n−1)).
///
/// ⚠️ Computed, not a literal: a hand-typed number silently means a different
/// level the day the curve is tuned, and these tests turn on the exact margin.
int _skillXpForLevel(int level) {
  var xp = 0;
  for (var n = 1; n < level; n++) {
    xp += 20 + 5 * (n - 1);
  }
  return xp;
}
