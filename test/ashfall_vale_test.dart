import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/ashfall_vale.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/items/catalogue/ashfall_vale_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'ashfall_vale';
  final all = AshfallValeBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(AshfallValeBestiary.commons, hasLength(5));
      expect(AshfallValeBestiary.minis, hasLength(4));
      expect(AshfallValeBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(AshfallValeBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('⭐ the argument is legible in the two minis\' statlines', () {
      // ⭐ ENEMIES §2g, "assignments worth keeping through any refinement":
      // First Green is the Redoubt and Last Ember is the Executioner, because
      // **regrowth wins by outlasting and fire wins by being faster**. ⚠️ Swap
      // these two and the zone's theme survives only in the names.
      expect(AshfallValeBestiary.firstGreen.archetype.id, 'redoubt');
      expect(AshfallValeBestiary.lastEmber.archetype.id, 'executioner');
      expect(
        AshfallValeBestiary.firstGreen.archetype.hpScale,
        greaterThan(AshfallValeBestiary.lastEmber.archetype.hpScale),
      );
      expect(
        AshfallValeBestiary.lastEmber.archetype.damageScale,
        greaterThan(AshfallValeBestiary.firstGreen.archetype.damageScale),
      );
    });

    test('the boss pair is the two sides of the argument', () {
      // ⭐ §2d — *"the two-boss pool IS the theme"*: which boss you draw tells
      // you which side is winning today. The Blackened Crown 👑 is a mind that
      // decided (fire won); The Rooting ✨ is the element itself (green won).
      expect(AshfallValeBestiary.theBlackenedCrown.archetype.id, 'tyrant');
      expect(AshfallValeBestiary.theRooting.archetype.id, 'aspect');
    });

    test('archetypes sit in the tier their rank calls for', () {
      const expected = {
        EnemyRank.common: EnemyTier.common,
        EnemyRank.mini: EnemyTier.mini,
        EnemyRank.boss: EnemyTier.boss,
      };
      for (final e in all) {
        expect(
          e.archetype.tier,
          expected[e.rank],
          reason: '${e.id} is a ${e.rank.name} but its archetype is not',
        );
      }
    });

    test('ids and names are unique', () {
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything is Pyro, Flora or both — never anything else', () {
      // ⭐ ENEMIES §2h — a hybrid may assign one of its two elements per
      // creature or use both. ⚠️ A THIRD element is a Celestial/Ethereal
      // privilege only; early, an off-element hit reads as the game cheating.
      final loc = World.byId(zone);
      const legal = {MagicElement.pyro, MagicElement.flora};
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(e.elements, isNotEmpty, reason: '${e.id} has no element');
        for (final el in e.elements) {
          expect(legal, contains(el), reason: '${e.id} uses ${el.name}');
          expect(loc.elements, contains(el));
        }
      }
    });

    test('⭐ exactly one creature has taken a side, and the doc names it', () {
      // ⭐ BESTIARY_ART on Last Ember: *"nothing green on it anywhere — the
      // ONE creature in the zone that is only fire."* That sentence is both a
      // lean and a prohibition: it is why every other creature carries both,
      // including The Blackened Crown, which merely looks like it won.
      expect(AshfallValeBestiary.lastEmber.elements, [MagicElement.pyro]);
      for (final e in all) {
        if (identical(e, AshfallValeBestiary.lastEmber)) continue;
        expect(
          e.elements,
          hasLength(2),
          reason: '${e.id} has settled an argument the zone leaves open',
        );
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
    });
  });

  group('creatures are creatures, not mages', () {
    test('no move borrows an id from the player Spellbook', () {
      // ⚠️ ENEMIES §3 — a boar does not cast Bolt. Sharing an id would also
      // make the two catalogues collide in the battle log.
      final spellIds = Spellbook.all.map((s) => s.id).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            spellIds.contains(m.id),
            isFalse,
            reason: '${e.id}\'s "${m.name}" reuses a Spellbook id',
          );
        }
      }
    });

    test('move ids are unique across the whole zone, and all prefixed', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id.startsWith('av_'), isTrue, reason: '$id is not zone-tagged');
      }
    });

    test('no move name collides with the game\'s own vocabulary', () {
      // 🚫 ENEMIES §3.3 — charging is the core verb, so a move called "Charge"
      // is genuinely ambiguous in the battle log. Same for an element name.
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          final n = m.name.toLowerCase();
          expect(
            reservedVerbs.contains(n),
            isFalse,
            reason: '"${m.name}" is one of the game\'s own verbs',
          );
          expect(
            elements.contains(n),
            isFalse,
            reason: '"${m.name}" is an element name',
          );
        }
      }
    });

    test('every creature has at least one move it can afford from zero', () {
      // ⚠️ Otherwise it can never act on turn one and the fight opens dead.
      for (final e in all) {
        expect(e.moves, isNotEmpty, reason: '${e.id} has no moves');
        expect(
          e.moves.map((m) => m.chargeCost).reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(5),
          reason: '${e.id} cannot reach any of its own moves',
        );
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree.
      for (final e in all) {
        final a = e.archetype;
        expect(
          e.moves.length,
          a.moveCount,
          reason: '${e.id} is a ${a.name}, which wants ${a.moveCount} moves',
        );
        final costs = e.moves.map((m) => m.chargeCost);
        expect(
          costs.reduce((x, y) => x < y ? x : y),
          greaterThanOrEqualTo(a.minMoveCost),
          reason: '${e.id} has a cheaper move than a ${a.name} should',
        );
        expect(
          costs.reduce((x, y) => x > y ? x : y),
          lessThanOrEqualTo(a.maxMoveCost),
          reason: '${e.id} has a more expensive move than a ${a.name} should',
        );
      }
    });

    test('raw damage stays in the Whispering Woods band', () {
      // ⚠️ **The double-scaling trap**, and this is the zone most exposed to
      // it: at 10–14 the temptation to "write bigger numbers" is strongest.
      // The engine already scales damage by level (`MageState.levelScale`,
      // 4%/level compounding), so the band arrives via the ENCOUNTER LEVEL.
      // Both ceilings are measured off Whispering Woods' hardest move (Run
      // Through: 58 worst case, 10.6 per charge).
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.maxAmount * effect.hits,
            lessThanOrEqualTo(60),
            reason: '${e.id}\'s "${m.name}" is above the shared ceiling',
          );
          expect(
            effect.averageTotal / m.chargeCost,
            lessThanOrEqualTo(11),
            reason: '${e.id}\'s "${m.name}" is too efficient per charge',
          );
        }
      }
    });

    test('⭐ fire is faster and green outlasts, in the turn order', () {
      // ⭐ The theme written into mechanics rather than lore. Last Ember's
      // cheaper move resolves in the QUICK band (≤5) — no other Executioner in
      // the quarter does — while First Green's wall goes up at priority 2 and
      // its damage move heals it back. ⚠️ This is the pair of assertions that
      // fails if someone "tidies" the priorities.
      final ember = AshfallValeBestiary.lastEmber;
      expect(
        ember.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(5),
        reason: 'Last Ember is no longer faster than anything',
      );

      final green = AshfallValeBestiary.firstGreen;
      final wall = green.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.priority, lessThan(3), reason: 'the wall arrives too late');
      expect(
        green.moves.any((m) => m.effect is DamageEffect &&
            (m.effect as DamageEffect).lifesteal > 0),
        isTrue,
        reason: 'regrowth that does not regrow is just a Sentinel',
      );
    });

    test('the Skirmisher acts in the quick band', () {
      // ⭐ ENEMIES §2.5 — tempo is expressed in PRIORITY, not in prose.
      final moth = AshfallValeBestiary.scorchmoth;
      expect(moth.archetype.id, 'skirmisher');
      for (final m in moth.moves) {
        expect(
          m.priority,
          lessThanOrEqualTo(5),
          reason: 'a Skirmisher that resolves at 9 acts AFTER the player',
        );
      }
    });

    test('the Siphon siphons, and nothing else common does', () {
      // ⭐ ENEMIES §2.6 — the Ashroot Sapling is §2b applied exactly: a plant
      // that absorbs should absorb. If the other four commons also stole, it
      // would stop being a shock and become the zone's weather.
      double steal(EnemyDef e) => e.moves
          .map((m) => m.effect is DamageEffect
              ? (m.effect as DamageEffect).lifesteal
              : 0.0)
          .fold(0.0, (a, b) => a > b ? a : b);

      final sapling = AshfallValeBestiary.ashrootSapling;
      expect(sapling.archetype.id, 'siphon');
      expect(steal(sapling), greaterThan(0));
      for (final e in AshfallValeBestiary.commons) {
        if (e.archetype.id == 'siphon') continue;
        expect(steal(e), 0, reason: '${e.id} is not a Siphon but lifesteals');
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt/Juggernaut are defined by attrition. Without a
      // ShieldEffect the archetype is only a bigger HP number.
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'juggernaut'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason: '${e.id} is a ${e.archetype.name} with nothing to hide behind',
        );
      }
    });

    test('the Hexer gets ahead of the whole board', () {
      // ⭐ 📝 The engine has no creature-applied debuff yet (§4.2 unbuilt), so
      // "slippery and always connecting" is written as priority: one move at 1
      // lands before shields (3) and quick attacks (5). ⭐ Kindleroot's is also
      // the zone's argument in a single action — it burns and it grows.
      final root = AshfallValeBestiary.kindleroot;
      expect(root.archetype.id, 'hexer');
      final first = root.moves.reduce(
        (a, b) => a.priority <= b.priority ? a : b,
      );
      expect(first.priority, 1);
      expect((first.effect as DamageEffect).lifesteal, greaterThan(0));
      expect(
        root.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner hits harder than anything else in the zone', () {
      // ⚠️ "Bring a shield — one misplay ends you" is only true if its ceiling
      // is genuinely the ceiling among the minis.
      int ceiling(EnemyDef e) => e.moves
          .map((m) => m.effect is DamageEffect
              ? (m.effect as DamageEffect).maxAmount *
                    (m.effect as DamageEffect).hits
              : 0)
          .reduce((a, b) => a > b ? a : b);

      final ember = AshfallValeBestiary.lastEmber;
      for (final e in AshfallValeBestiary.minis) {
        if (identical(e, ember)) continue;
        expect(
          ceiling(ember),
          greaterThan(ceiling(e)),
          reason: '${e.id} out-hits the Executioner',
        );
      }
    });

    test('the two bosses threaten in opposite ways', () {
      // ⭐ 👑 vs ✨. The Crown out-thinks you: a wall it can always afford and
      // a hit at priority 2, ahead of your own shield at 3. The Rooting simply
      // arrives: nothing keeps it out, and it never stops healing. ⚠️ If both
      // bosses played the same way the 1-of-2 draw would say nothing.
      final crown = AshfallValeBestiary.theBlackenedCrown;
      final rooting = AshfallValeBestiary.theRooting;

      final wall = crown.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.chargeCost, 1, reason: 'a wall the Crown cannot always hold');
      expect(crown.moves.any((m) => m.isOffensive && m.priority < 3), isTrue);

      expect(
        rooting.moves.any((m) => m.effect is ShieldEffect),
        isFalse,
        reason: 'The Rooting hiding behind a wall is a second Crown',
      );
      expect(
        rooting.moves.any((m) => m.effect is DamageEffect &&
            (m.effect as DamageEffect).ignoresShields),
        isTrue,
        reason: 'something is keeping The Rooting out',
      );
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item', () {
      // ⚠️ Dart forbids field access in const expressions, so drops name items
      // by string. This is the guard that makes that safe.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('every main table draws exactly one entry, by weight', () {
      for (final e in all) {
        if (e.drops.main.isEmpty) continue;
        expect(
          e.drops.totalWeight,
          greaterThan(0),
          reason: '${e.id} has a main table that can never resolve',
        );
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      // ⭐ A "nothing" weight is what keeps a main table honest — without it
      // every kill pays and the rare slots inflate.
      for (final e in AshfallValeBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...AshfallValeBestiary.minis,
        ...AshfallValeBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in AshfallValeBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a hybrid drops BOTH parents\' mote ladders', () {
      // ⭐ ITEMS §8 — the mote a zone yields derives from its ELEMENTS, never
      // from a hand-authored list. Pyro+Flora therefore means both ladders.
      final dropped = AshfallValeBestiary.allDrops;
      for (final id in [
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'flora_dust', 'flora_shard', 'flora_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ And nothing from a third element (§2h).
      for (final id in dropped) {
        expect(
          id.startsWith('aqua_'),
          isFalse,
          reason: '$id is off-element for Pyro+Flora',
        );
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in AshfallValeBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in AshfallValeBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⭐ the quarter\'s only Epic drops here, from bosses, at ~10%', () {
      // ⭐ The Charlock is regrowth as a stat, off the boss that IS regrowth
      // (ITEMS §9b.8). ⚠️ Rarity decides which kinds of property may exist at
      // all, so an Epic on a common table would break the whole ladder — and
      // 10% of a main draw is the same rate Whispering Woods gives the
      // Heartwood Staff.
      expect(ItemCatalogue.byId('the_charlock').rarity, Rarity.epic);
      for (final b in AshfallValeBestiary.bosses) {
        expect(
          b.drops.possibleDrops,
          contains('the_charlock'),
          reason: '${b.id} cannot drop the Epic',
        );
        expect(b.drops.mainChanceOf('the_charlock'), lessThanOrEqualTo(0.15));
        expect(b.drops.mainChanceOf('the_charlock'), greaterThan(0.0));
      }
      for (final e in [
        ...AshfallValeBestiary.commons,
        ...AshfallValeBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('the_charlock')),
          reason: '${e.id} drops an Epic',
        );
      }
    });

    test('a hybrid hands over no gate item', () {
      // ⭐ Hearthwood's north road asks for *three ordinary proofs* — one per
      // Primal PURE zone. ⚠️ A fourth from a hybrid would let a player skip
      // one of the three zones the gate exists to route them through.
      final keys = ItemCatalogue.all.whereType<KeyDef>().map((k) => k.id);
      for (final id in keys) {
        expect(
          AshfallValeBestiary.allDrops,
          isNot(contains(id)),
          reason: 'Ashfall Vale drops "$id" — the three-proof gate is now four',
        );
      }
    });

    test('potions stay a crafting product, not a drop faucet', () {
      // ⚠️ ITEMS §9b.8 — the MATERIAL is the real drop. A generous potion
      // faucet makes Potions & Alchemy pointless before Galehaven opens.
      for (final e in all) {
        expect(
          e.drops.mainChanceOf('brookmint_tonic'),
          lessThanOrEqualTo(0.05),
          reason: '${e.id} is a tonic vending machine',
        );
      }
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ An item nothing drops and nothing crafts is dead content, and the
      // Collector achievement would be uncompletable. ⭐ The crafted set is
      // DERIVED from RecipeBook, so a recipe removed without a drop added
      // fails here rather than going quietly dead.
      final crafted = RecipeBook.all.map((r) => r.outputId).toSet();
      final dropped = AshfallValeBestiary.allDrops;
      for (final d in AshfallValeItems.all) {
        if (crafted.contains(d.id)) continue;
        expect(
          dropped.contains(d.id),
          isTrue,
          reason: '${d.id} is defined but nothing drops or crafts it',
        );
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final husk = AshfallValeBestiary.cinderbloomHusk;
      final crown = AshfallValeBestiary.theBlackenedCrown;
      expect(husk.maxHpAt(10), (MageState.scaledMaxHp(10) * 1.00).round());
      expect(crown.maxHpAt(14), (MageState.scaledMaxHp(14) * 2.60).round());
      expect(crown.maxHpAt(14), greaterThan(husk.maxHpAt(14)));
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 10. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(10);
      for (final e in AshfallValeBestiary.commons) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          final worst = effect.maxAmount * effect.hits;
          expect(
            worst,
            lessThan(startingHp),
            reason: '${e.id}\'s "${m.name}" can hit for $worst',
          );
        }
      }
    });
  });

  group('the lore channel is populated', () {
    test('every creature carries a field note, in the right voice', () {
      for (final e in all) {
        expect(e.lore.length, greaterThan(40), reason: '${e.id} lore is thin');
        expect(
          e.lore.endsWith('.'),
          isTrue,
          reason: '${e.id} lore is not a sentence',
        );
        // ⚠️ Lore is an observation, never a stat line in prose.
        expect(
          RegExp(
            r'\d+\s*(hp|damage|dmg)',
            caseSensitive: false,
          ).hasMatch(e.lore),
          isFalse,
          reason: '${e.id} lore leaks mechanics',
        );
      }
    });
  });
}
