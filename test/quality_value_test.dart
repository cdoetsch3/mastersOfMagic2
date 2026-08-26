/// Quality's effect on an item's gold value (ECONOMY_CONTRACT §14d ruling 1,
/// Christian 2026-08-26).
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a ladder that drifts off the stat ladder, a null that is treated as
/// "no value" instead of Standard, a `.floor()` where the contract says
/// round-half-away, a price seam that forgets quality entirely, and — the one
/// this whole file exists for — a display path and a settle path that compute
/// the same number twice and are free to disagree.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/quality_value.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';

// `tuskhide_belt` — a tradeable BeltableDef-adjacent EquipmentDef whose value
// is read off the catalogue rather than restated, so a content edit cannot
// make this suite pass while quoting a number the game no longer uses.
const _gearId = 'tuskhide_belt';

ItemInstance _inst(Quality? q) =>
    ItemInstance(instanceId: 'i', defId: _gearId, quality: q);

void main() {
  final def = ItemCatalogue.byId(_gearId);

  group('qualityValue — the ×0.8/1.0/1.2/1.4 ladder (§14d.1)', () {
    test('every rung lands on the stat ladder, not a second copy of it', () {
      // ⭐ The expectation is computed from `Quality.statPercent` — the exact
      // getter `ItemModifiers.scaledBy` uses — so this fails the moment the
      // economy grows its own private 80/100/120/140. A test that hardcoded
      // `88, 110, 132, 154` would keep passing through exactly that mistake.
      for (final q in Quality.values) {
        expect(
          qualityValue(def, _inst(q)),
          (def.value * q.statPercent + 50) ~/ 100,
          reason: '${q.name} must ride the same ladder as stats, and the only '
              'way to guarantee that is to read statPercent',
        );
      }
    });

    test('Rough is cheaper, Ornate and Master are dearer, strictly', () {
      // Kills a stub returning `def.value` for everything: that stub passes
      // "Standard is unchanged" and fails here on all three other rungs.
      final rough = qualityValue(def, _inst(Quality.rough));
      final standard = qualityValue(def, _inst(Quality.standard));
      final ornate = qualityValue(def, _inst(Quality.ornate));
      final master = qualityValue(def, _inst(Quality.master));

      expect(standard, def.value, reason: 'Standard is the baseline rung, ×1.00');
      expect(
        [rough, standard, ornate, master],
        [
          lessThan(standard),
          anything,
          greaterThan(standard),
          greaterThan(ornate),
        ],
        reason: 'the ladder must be strictly increasing across all four rungs '
            '— a flat or inverted ladder is the ruling reversed',
      );
      // The concrete numbers for value 110, spelled out so a silent retune of
      // Quality.statPercent cannot slide past the derived assertion above.
      expect([rough, standard, ornate, master], [88, 110, 132, 154]);
    });

    test('⭐ null quality is Standard — old instances do not move a coin', () {
      // ⚠️ The regression this guards: reading null as "unqualified, so worth
      // less" (or crashing on it). Dropped gear rolls an aspect, not a
      // quality, and every instance minted before 2026-08-18 has no field at
      // all. Both must keep exactly the gold they have always had.
      expect(
        qualityValue(def, _inst(null)),
        def.value,
        reason: 'a null quality field reads as Standard ×1.00',
      );
      expect(
        qualityValue(def, null),
        def.value,
        reason: 'no instance at all — a fungible stack — is Standard too',
      );
      expect(
        qualityValue(def, null),
        qualityValue(def, _inst(Quality.standard)),
        reason: 'null and Standard are the same rung, not merely close',
      );
    });

    test('the ladder never produces a rounding tie — and says so out loud', () {
      // ⚠️ **A deliberate note-to-the-next-editor, not a tautology.** §14d.1
      // specifies round-half-away-from-zero, but every current rung (80, 100,
      // 120, 140) is a multiple of 20, so `value × pct` always ends in 0 and
      // the tie case is unreachable through `qualityValue` today. Add a rung
      // like 110 or 133 and the rounding rule becomes load-bearing for the
      // first time — this assertion fails at exactly that moment, so whoever
      // adds it learns they now owe a tie test instead of discovering it as a
      // one-gold discrepancy in a bug report.
      for (final q in Quality.values) {
        expect(
          q.statPercent % 20,
          0,
          reason: 'a rung that is not a multiple of 20 makes the half-away '
              'rule observable — write the tie test that becomes necessary',
        );
      }
      // The shared rule itself, exercised where it IS reachable.
      expect(
        ShopPricing.roundGold(0.5),
        1,
        reason: 'half away from zero — a .floor() here returns 0 and is the '
            'mutant both this seam and the sink are guarding against',
      );
    });

    test('zero stays zero at every rung', () {
      // ⭐ Mirrors `scaledBy`'s own promise: quality multiplies worth, it never
      // invents worth an item does not have. Kills a `+ pct` implementation.
      const worthless = EquipmentDef(
        id: 'zz_worthless',
        rarity: Rarity.common,
        lore: 'A test fixture, worth nothing at any quality.',
        slot: EquipSlot.ring,
        form: 'Ring',
        material: 'Tin',
        value: 0,
      );
      for (final q in Quality.values) {
        expect(
          qualityValue(worthless, ItemInstance(instanceId: 'i', defId: 'zz', quality: q)),
          0,
          reason: '${q.name} × 0 is 0 — a flat bonus implementation fails here',
        );
      }
    });
  });

  group('instanceVendorPrice — ONE seam for display and settle (§14d.1)', () {
    test('composes the ladder with the 0.6 sink, in that order', () {
      for (final q in Quality.values) {
        expect(
          instanceVendorPrice(def, _inst(q)),
          ShopPricing.vendorPrice(qualityValue(def, _inst(q))),
          reason: 'the sink applies to the quality-scaled value, not to the '
              'raw def.value with quality bolted on afterward',
        );
      }
    });

    test('⭐ a Master piece is worth strictly more gold than a Rough one', () {
      // The player-facing point of the whole ruling. Kills the seam that
      // resolves to `ShopPricing.vendorPrice(def.value)` regardless of
      // quality — the exact code this ruling replaced.
      expect(
        instanceVendorPrice(def, _inst(Quality.master)),
        greaterThan(instanceVendorPrice(def, _inst(Quality.rough))),
        reason: 'quality must reach the NPC price, or the ruling did nothing',
      );
      expect([
        instanceVendorPrice(def, _inst(Quality.rough)),
        instanceVendorPrice(def, _inst(Quality.standard)),
        instanceVendorPrice(def, _inst(Quality.ornate)),
        instanceVendorPrice(def, _inst(Quality.master)),
      ], [53, 66, 79, 92]);
    });

    test('an unqualified instance still prices exactly as it always did', () {
      // ⚠️ The compatibility promise: every pre-ruling instance in every
      // player's save must be worth the same gold today as yesterday.
      expect(
        instanceVendorPrice(def, _inst(null)),
        ShopPricing.vendorPrice(def.value),
        reason: 'null quality must reproduce the old flat expression exactly',
      );
    });
  });
}
