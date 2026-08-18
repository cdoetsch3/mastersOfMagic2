import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/carrying.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/items/item_naming.dart';
import 'package:mom_engine/mom_engine.dart';

/// Sample definitions. ⚠️ Deliberately NOT the real catalogue — these exist to
/// exercise the shape, and the catalogue is a separate job.
const _staff = EquipmentDef(
  id: 'oak_quarterstaff',
  rarity: Rarity.common,
  lore: 'Cut green and dried slowly. Most mages start with one.',
  slot: EquipSlot.mainHand,
  form: 'Quarterstaff',
  material: 'Oak',
  socketCount: 1,
  salvage: [SalvageYield('oak_log', 1, 2)],
);

const _log = MaterialDef(
  id: 'oak_log',
  rarity: Rarity.common,
  lore: 'Heavy, and heavier once it rains.',
  skill: CraftSkill.woodcarving,
  tier: 1,
);

const _dust = MoteDef(
  id: 'flora_dust',
  rarity: Rarity.common,
  lore: 'The residue a living thing leaves when it is unmade.',
  tier: MoteTier.dust,
  element: MagicElement.flora,
);

const _component = ComponentDef(
  id: 'heartwood_splinter',
  rarity: Rarity.mythic,
  lore: 'It is still warm.',
  sourceId: 'whispering_woods',
);

const _ration = ConsumableDef(
  id: 'field_ration',
  rarity: Rarity.common,
  lore: 'Filling, and that is the only good thing about it.',
);

const _tonic = BeltableDef(
  id: 'lesser_tonic',
  rarity: Rarity.common,
  lore: 'Bitter enough that you remember drinking it.',
);

const _key = KeyDef(
  id: 'celestial_totem',
  rarity: Rarity.legendary,
  lore: 'Three essences, and a barrier that only reads all three.',
  gates: 'rimeholt',
);

void main() {
  group('fungibility is the axis the storage model turns on', () {
    test('things with per-instance rolls are not fungible', () {
      expect(_staff.isFungible, isFalse);
      expect(
        const ToolDef(
          id: 'oak_hatchet',
          rarity: Rarity.common,
          lore: '',
          skill: CraftSkill.woodcarving,
          tier: 1,
        ).isFungible,
        isFalse,
        reason: 'tools roll a quality, so two are not interchangeable',
      );
    });

    test('things fully described by their definition are fungible', () {
      for (final d in <ItemDef>[_log, _dust, _component, _key]) {
        expect(d.isFungible, isTrue, reason: '${d.id} should be fungible');
      }
    });

    test('a fungible slot must NOT carry an instance id', () {
      expect(
        () => InventorySlot.forDef(_log, instanceId: 'uuid-1'),
        throwsArgumentError,
        reason: 'two oak logs are interchangeable; the id would be dead state',
      );
      expect(InventorySlot.forDef(_log).instanceId, isNull);
    });

    test('a non-fungible slot MUST carry an instance id', () {
      expect(
        () => InventorySlot.forDef(_staff),
        throwsArgumentError,
        reason: 'its quality, aspect, sockets and enchant have nowhere to live',
      );
      expect(
        InventorySlot.forDef(_staff, instanceId: 'uuid-1').instanceId,
        'uuid-1',
      );
    });
  });

  group('inventory is one item per slot', () {
    test('twenty oak logs occupy twenty slots', () {
      // ⭐ ITEMS §10.3a — this is what makes carrying capacity a resource.
      final pack = [for (var i = 0; i < 20; i++) InventorySlot.forDef(_log)];
      expect(pack, hasLength(20));
      expect(pack.every((s) => s.defId == 'oak_log'), isTrue);
    });
  });

  group('instances survive the round trip', () {
    test('every roll is preserved', () {
      const inst = ItemInstance(
        instanceId: 'uuid-7',
        defId: 'oak_quarterstaff',
        quality: Quality.ornate,
        aspect: MagicElement.flora,
        socketed: ['ruby_chip'],
        enchantId: 'unbinding',
      );
      final back = ItemInstance.fromJson(inst.toJson());
      expect(back.instanceId, 'uuid-7');
      expect(back.quality, Quality.ornate);
      expect(back.aspect, MagicElement.flora);
      expect(back.socketed, ['ruby_chip']);
      expect(back.enchantId, 'unbinding');
    });

    test('an unrolled instance stays unrolled', () {
      const inst = ItemInstance(
        instanceId: 'uuid-8',
        defId: 'oak_quarterstaff',
      );
      final back = ItemInstance.fromJson(inst.toJson());
      expect(back.quality, isNull);
      expect(back.aspect, isNull);
      expect(back.socketed, isEmpty);
    });

    test('an unknown enum name degrades to null rather than throwing', () {
      // A save written by a newer build must not crash an older one outright.
      final back = ItemInstance.fromJson({
        'instanceId': 'uuid-9',
        'defId': 'x',
        'quality': 'transcendent',
      });
      expect(back.quality, isNull);
    });
  });

  group('gear totals cross the wire (ITEMS §7.4)', () {
    // ⚠️ Every field non-zero and every value DISTINCT: with repeated values
    // a toJson/fromJson pair that swaps two keys would still pass.
    const full = ItemModifiers(
      accuracyBonus: 1,
      dodge: 2,
      critChance: 3,
      critDamage: 4,
      deflectChance: 5,
      deflectAmount: 6,
      maxHpBonus: 7,
      damagePerCast: 8,
      damagePerCharge: 9,
      shieldStrengthPercent: 10,
      healingReceivedPercent: 11,
      regrowPercent: 12,
      beltSlots: 13,
    );

    test('every field survives the round trip', () {
      // ⭐ This is a lockstep contract, not a save format: a field that fails
      // to cross is a stat one client applies and the other does not.
      final back = ItemModifiers.fromJson(full.toJson());
      expect(back.accuracyBonus, 1);
      expect(back.dodge, 2);
      expect(back.critChance, 3);
      expect(back.critDamage, 4);
      expect(back.deflectChance, 5);
      expect(back.deflectAmount, 6);
      expect(back.maxHpBonus, 7);
      expect(back.damagePerCast, 8);
      expect(back.damagePerCharge, 9);
      expect(back.shieldStrengthPercent, 10);
      expect(back.healingReceivedPercent, 11);
      expect(back.regrowPercent, 12);
      expect(back.beltSlots, 13);
    });

    test('zeroes are dropped rather than shipped', () {
      expect(ItemModifiers.none.toJson(), isEmpty);
      expect(const ItemModifiers(dodge: 3).toJson(), {'dodge': 3});
    });

    test('a missing key reads as 0, a missing map as none', () {
      // An older client's ticket, or a room doc written before gear crossed
      // the wire — "unequipped" is the safe reading, a throw is not.
      final partial = ItemModifiers.fromJson({'critChance': 5});
      expect(partial.critChance, 5);
      expect(partial.critDamage, 0);
      expect(partial.maxHpBonus, 0);
      expect(partial.beltSlots, 0);
      expect(ItemModifiers.fromJson(null).isEmpty, isTrue);
      expect(ItemModifiers.fromJson({}).isEmpty, isTrue);
    });

    test('numbers arriving as doubles still read as ints', () {
      // ⚠️ Firestore hands numbers back as `num`; a hard `as int` would throw
      // in the middle of matchmaking.
      expect(ItemModifiers.fromJson({'maxHpBonus': 12.0}).maxHpBonus, 12);
    });
  });

  group('quality multiplies the stats (ruling, 2026-08-18)', () {
    // A wand's two real numbers, chosen because both land on an interesting
    // edge: 2 × 0.80 = 1.6 and 12 × 1.40 = 16.8.
    const wand = ItemModifiers(damagePerCast: 2, maxHpBonus: 12);

    test('the four tiers are ×0.80 / ×1.00 / ×1.20 / ×1.40', () {
      expect(Quality.rough.statPercent, 80);
      expect(Quality.standard.statPercent, 100,
          reason: 'Standard IS the baseline — anything else silently '
              'rebalances every drop in the game');
      expect(Quality.ornate.statPercent, 120);
      expect(Quality.master.statPercent, 140);
    });

    test('rounding is half AWAY from zero, not toward it', () {
      expect(wand.scaledBy(Quality.rough).damagePerCast, 2,
          reason: '2 × 0.80 = 1.6 → 2; truncation says 1, which would make '
              'a Rough wand worth half a Standard one');
      expect(wand.scaledBy(Quality.master).maxHpBonus, 17,
          reason: '12 × 1.40 = 16.8 → 17; binary floating point computes '
              '16.799999999999997, so a truncating implementation says 16');
      expect(
        const ItemModifiers(accuracyBonus: 5).scaledBy(Quality.ornate)
            .accuracyBonus,
        6,
        reason: '5 × 1.20 = 6 exactly — an off-by-one here is a whole stat');
      expect(const ItemModifiers(dodge: -3).scaledBy(Quality.ornate).dodge, -4,
          reason: '-3 × 1.20 = -3.6 → -4. Toward-zero truncation says -3, '
              'which would make Ornate an IMPROVEMENT on a penalty');
      expect(const ItemModifiers(dodge: -3).scaledBy(Quality.rough).dodge, -2,
          reason: '-3 × 0.80 = -2.4 → -2, the shrink a Rough item deserves');
    });

    test('Standard and null are the untouched definition', () {
      expect(wand.scaledBy(Quality.standard).maxHpBonus, 12);
      expect(wand.scaledBy(null).damagePerCast, 2,
          reason: '⭐ a drop rolls an aspect and a pre-ruling save has no '
              'quality field at all — both must keep the numbers they have '
              'always had, or every old save silently changes');
    });

    test('zero stays zero at every tier', () {
      for (final q in Quality.values) {
        expect(wand.scaledBy(q).critChance, 0,
            reason: 'quality multiplies power; it never invents a stat the '
                'definition does not have ($q)');
        expect(ItemModifiers.none.scaledBy(q).isEmpty, isTrue,
            reason: 'a Master rock is still a rock ($q)');
      }
    });

    test('⚠️ beltSlots is exempt at every tier', () {
      const belt = ItemModifiers(beltSlots: 2, maxHpBonus: 10);
      for (final q in Quality.values) {
        expect(belt.scaledBy(q).beltSlots, 2,
            reason: 'the one deliberately non-combat axis (ITEMS §6b.2) — a '
                'Master belt granting 3 slots turns a crafting roll into a '
                'carrying-capacity roll ($q)');
      }
      expect(belt.scaledBy(Quality.master).maxHpBonus, 14,
          reason: 'exempting the field must not exempt the item');
    });

    test('every combat field is scaled — none forgotten', () {
      // ⚠️ Total on purpose, like toJson: a field left out of scaledBy is a
      // stat the tooltip scales and the duel does not.
      const ten = ItemModifiers(
        accuracyBonus: 10,
        dodge: 10,
        critChance: 10,
        critDamage: 10,
        deflectChance: 10,
        deflectAmount: 10,
        maxHpBonus: 10,
        damagePerCast: 10,
        damagePerCharge: 10,
        shieldStrengthPercent: 10,
        healingReceivedPercent: 10,
        regrowPercent: 10,
        beltSlots: 10,
      );
      final m = ten.scaledBy(Quality.master);
      expect([
        m.accuracyBonus,
        m.dodge,
        m.critChance,
        m.critDamage,
        m.deflectChance,
        m.deflectAmount,
        m.maxHpBonus,
        m.damagePerCast,
        m.damagePerCharge,
        m.shieldStrengthPercent,
        m.healingReceivedPercent,
        m.regrowPercent,
      ], everyElement(14),
          reason: 'a combat field that reads 10 was never scaled');
      expect(m.beltSlots, 10);
    });
  });

  group('the name is composed from the facts, never stored', () {
    test('quality, material and form in that order', () {
      expect(
        composeItemName(
          quality: Quality.ornate,
          material: 'Bloodwood',
          form: 'Quarterstaff',
        ),
        'Ornate Bloodwood Quarterstaff',
      );
    });

    test('Standard is unwritten, so ordinary items read plainly', () {
      expect(
        composeItemName(
          quality: Quality.standard,
          material: 'Oak',
          form: 'Wand',
        ),
        'Oak Wand',
      );
    });

    test('a dropped item leads with its aspect', () {
      expect(
        composeItemName(
          aspectPrefix: aspectPrefixes['flora'],
          material: 'Yew',
          form: 'Robe',
        ),
        'Overgrown Yew Robe',
      );
    });

    test('there is an aspect prefix for all twelve elements', () {
      for (final e in MagicElement.values) {
        expect(
          aspectPrefixes[e.name],
          isNotNull,
          reason: '${e.name} has no aspect prefix (ITEMS §9b.5b)',
        );
      }
      expect(aspectPrefixes.values.toSet(), hasLength(12));
    });

    test('no aspect prefix collides with reserved vocabulary', () {
      // ⚠️ README §3: Bound, Sudden Death, Eclipsed and every element status
      // name already mean something specific.
      const reserved = {
        'Bound',
        'Eclipsed',
        'Ignite',
        'Waterlogged',
        'Photosynthesis',
        'Tailwind',
        'Stagger',
        'Blind',
      };
      for (final p in aspectPrefixes.values) {
        expect(reserved.contains(p), isFalse, reason: '"$p" is reserved');
      }
    });
  });

  group('rules the model must not let anyone break', () {
    test('the belt is a real slot, and never carries a set', () {
      expect(EquipSlot.values, contains(EquipSlot.belt));
      expect(EquipSlot.values, hasLength(10));
      expect(
        EquipSlot.belt.carriesSet,
        isFalse,
        reason: 'the belt is the one slot whose value is not combat power',
      );
    });

    test('only the five armour slots may carry a set', () {
      const armour = [
        EquipSlot.hat,
        EquipSlot.robeTop,
        EquipSlot.robeBottom,
        EquipSlot.boots,
        EquipSlot.gloves,
      ];
      for (final s in EquipSlot.values) {
        expect(s.carriesSet, armour.contains(s), reason: '$s (ITEMS §3.2)');
      }
    });

    test('a Component is Bound by construction, and is not a Material', () {
      expect(_component.tradability, Tradability.bound);
      expect(
        _component,
        isNot(isA<MaterialDef>()),
        reason:
            'modelling it as a Material lets bulk crafting reach it, '
            'which is the loophole ITEMS §6c closed',
      );
    });

    test('a Key is Bound and worthless, so it can never be sold or traded', () {
      expect(_key.tradability, Tradability.bound);
      expect(_key.value, 0);
    });

    test('salvage only exists on things that can be broken down', () {
      expect(_staff, isA<Salvageable>());
      expect(_log, isA<Salvageable>());
      expect(_dust, isNot(isA<Salvageable>()));
      expect(_key, isNot(isA<Salvageable>()));
    });

    test('only equipment is enchantable and socketed', () {
      expect(_staff, isA<Enchantable>());
      expect(_staff, isA<Socketed>());
      expect(_staff.socketCount, 1);
      expect(_dust, isNot(isA<Enchantable>()));
    });
  });

  group('the four containers each have one job', () {
    test('only Beltable things reach combat', () {
      expect(Carrying.accepts(ItemContainer.belt, _tonic), isTrue);
      expect(
        Carrying.accepts(ItemContainer.belt, _ration),
        isFalse,
        reason: 'a field ration is a between-encounters item',
      );
      expect(Carrying.accepts(ItemContainer.belt, _staff), isFalse);
    });

    test('every other container takes anything — space, not legality', () {
      for (final c in [
        ItemContainer.storeroom,
        ItemContainer.backpack,
        ItemContainer.mount,
      ]) {
        for (final d in <ItemDef>[_staff, _log, _ration, _tonic, _key]) {
          expect(Carrying.accepts(c, d), isTrue, reason: '$c / ${d.id}');
        }
      }
    });

    test('beltable is a TYPE, not a flag someone can forget to check', () {
      expect(_tonic, isA<Beltable>());
      expect(_ration, isNot(isA<Beltable>()));
    });

    test('⚠️ no belt means NO slots (ruling 2026-08-17)', () {
      expect(
        Carrying.beltSlotsFor(),
        0,
        reason: 'two free slots with an empty Belt slot read as a bug, and '
            'made the belt that grants slots look like it did nothing',
      );
      expect(Carrying.baseBeltSlots, 0);
    });

    test('the belt grows, but is clamped', () {
      expect(Carrying.beltSlotsFor(fromProgression: 3, fromGear: 2), 5,
          reason: 'capacity is gear plus progression and nothing else');
      expect(
        Carrying.beltSlotsFor(fromProgression: 50),
        Carrying.maxBeltSlots,
        reason: 'past the cap, "which do I bring?" stops being a decision',
      );
    });

    test('beltRefusal names WHICH problem it is', () {
      // ⚠️ "Full" and "you own no belt" send the player to different screens.
      expect(
        Carrying.beltRefusal(_tonic, used: 0, capacity: 0),
        contains('not wearing a belt'),
      );
      expect(
        Carrying.beltRefusal(_tonic, used: 2, capacity: 2),
        contains('full'),
      );
      expect(Carrying.beltRefusal(_tonic, used: 1, capacity: 2), isNull);
      expect(
        Carrying.beltRefusal(_ration, used: 0, capacity: 5),
        isNotNull,
        reason: 'space is not legality — a ration never reaches a duel',
      );
      expect(Carrying.beltRefusal(null, used: 0, capacity: 5), isNotNull);
    });

    test('the Storeroom is unbounded; the backpack is not', () {
      // ⭐ The scarcity in a Storeroom is WHICH CITY it is in, not its size.
      expect(Carrying.storeroomSlots, isNull);
      expect(Carrying.backpackSlots, greaterThan(0));
    });
  });
}
