import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/thornmire.dart';
import 'package:masters_of_magic_2/game/items/catalogue/thornmire_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'thornmire';
  final all = ThornmireBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(ThornmireBestiary.commons, hasLength(5));
      expect(ThornmireBestiary.minis, hasLength(4));
      expect(ThornmireBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(ThornmireBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the endurance/trick pair the design names', () {
      // ⭐ ENEMIES §2g's table: Mirethroat ⛰️ Juggernaut, The Drinking Grove ✨
      // Aspect. Two Juggernauts would make the 1-of-2 draw cosmetic.
      expect(ThornmireBestiary.mirethroat.archetype.id, 'juggernaut');
      expect(ThornmireBestiary.theDrinkingGrove.archetype.id, 'aspect');
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

    test('everything is Flora, Aqua or both — never anything else', () {
      // ⭐ ENEMIES §2h — a hybrid may assign one of its two elements per
      // creature or use both. ⚠️ A THIRD element is a Celestial/Ethereal
      // privilege only; early, an off-element hit reads as the game cheating.
      final loc = World.byId(zone);
      const legal = {MagicElement.flora, MagicElement.aqua};
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(e.elements, isNotEmpty, reason: '${e.id} has no element');
        for (final el in e.elements) {
          expect(legal, contains(el), reason: '${e.id} uses ${el.name}');
          expect(loc.elements, contains(el));
        }
      }
    });

    test('the Thirstvine is the §2h worked example: Flora alone', () {
      // ⭐ §2h names it outright — *"a Thirstvine is obviously Flora drinking
      // Aqua"* — as the case for assigning ONE of a hybrid's elements. It is
      // the zone's thesis creature, so the lean is the design speaking.
      expect(ThornmireBestiary.thirstvine.elements, [MagicElement.flora]);
      for (final e in all) {
        if (identical(e, ThornmireBestiary.thirstvine)) continue;
        expect(
          e.elements,
          hasLength(2),
          reason: '${e.id} leans, but no doc entry says it should',
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
        expect(id.startsWith('tm_'), isTrue, reason: '$id is not zone-tagged');
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
      // ⚠️ **The double-scaling trap.** The engine already scales damage by
      // level (`MageState.levelScale`, 4%/level compounding), so this zone's
      // 8–13 band arrives via the ENCOUNTER LEVEL. Both numbers are measured
      // off Whispering Woods' hardest move (Run Through: 58 worst case, 10.6
      // per charge), because THAT is the band the engine was tuned against.
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

    test('⭐ both Siphons siphon — the zone\'s whole lesson', () {
      // ⭐ ENEMIES §2.6 + §2d — Thornmire is the one zone that fields TWO
      // Siphons, deliberately: one is a shock, two is a *rule about this
      // place*, and a war of attrition here is unwinnable. ⚠️ If either of
      // these loses its lifesteal the zone stops teaching anything.
      double steal(EnemyDef e) => e.moves
          .map((m) => m.effect is DamageEffect
              ? (m.effect as DamageEffect).lifesteal
              : 0.0)
          .fold(0.0, (a, b) => a > b ? a : b);

      final siphons = ThornmireBestiary.commons
          .where((e) => e.archetype.id == 'siphon')
          .toList();
      expect(siphons, hasLength(2), reason: 'the two-drinker premise is gone');
      for (final s in siphons) {
        expect(steal(s), greaterThan(0), reason: '${s.id} does not drink');
      }
      for (final e in ThornmireBestiary.commons) {
        if (e.archetype.id == 'siphon') continue;
        expect(steal(e), 0, reason: '${e.id} is not a Siphon but lifesteals');
      }
    });

    test('the Adept is the yardstick the Siphons are felt against', () {
      // ⚠️ §2f flags the Adept's absence as a real gap: without a plain,
      // honest fight in the pool, "the vines drink, kill them fast" has
      // nothing to be a contrast TO.
      final walker = ThornmireBestiary.mirewalker;
      expect(walker.archetype.id, 'adept');
      expect(
        walker.moves.any((m) => m.effect is DamageEffect &&
            (m.effect as DamageEffect).lifesteal == 0),
        isTrue,
      );
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
      // lands before shields (3) and quick attacks (5).
      final mother = ThornmireBestiary.fenmother;
      expect(mother.archetype.id, 'hexer');
      expect(
        mother.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        mother.moves.any(
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

      final wicker = ThornmireBestiary.wickerdrowned;
      expect(wicker.archetype.id, 'executioner');
      for (final e in ThornmireBestiary.minis) {
        if (identical(e, wicker)) continue;
        expect(
          ceiling(wicker),
          greaterThan(ceiling(e)),
          reason: '${e.id} out-hits the Executioner',
        );
      }
    });

    test('the trick boss drinks as a habit, not as a payoff', () {
      // ⭐ ✨ The Drinking Grove's Aspect extreme is that its sustain is
      // CHEAP: a one-charge full-lifesteal move means there is no turn in
      // which it is not healing. ⚠️ That is what separates it from Whispering
      // Woods' Standing Green, which heals only when it commits.
      final grove = ThornmireBestiary.theDrinkingGrove;
      final cheapest = grove.moves.reduce(
        (a, b) => a.chargeCost <= b.chargeCost ? a : b,
      );
      expect(cheapest.chargeCost, 1);
      expect((cheapest.effect as DamageEffect).lifesteal, 1);
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
      for (final e in ThornmireBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...ThornmireBestiary.minis,
        ...ThornmireBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in ThornmireBestiary.commons) {
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
      // from a hand-authored list. Flora+Aqua therefore means both ladders, or
      // the derivation has been quietly replaced by a choice.
      final dropped = ThornmireBestiary.allDrops;
      for (final id in [
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ And nothing from a third element, which is a Celestial/Ethereal
      // privilege only (§2h).
      for (final id in dropped) {
        expect(
          id.startsWith('pyro_'),
          isFalse,
          reason: '$id is off-element for Flora+Aqua',
        );
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in ThornmireBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in ThornmireBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⏳ amber stays scarce, because it banks for a skill 30 levels up', () {
      // ⚠️ ITEMS §9b.8 — Amber is Uncommon and its consumer (Jewelry) opens at
      // Rimeholt, level 45. A material handed out freely for thirty levels
      // arrives worthless; the scarcity IS the value.
      expect(ItemCatalogue.byId('amber').rarity, Rarity.uncommon);
      for (final e in all) {
        expect(
          e.drops.mainChanceOf('amber'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} is an amber faucet',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      // ⭐ The Wickerbound Ring multiplies every Draught and Tonic — the Flora
      // answer to a fight you cannot end quickly, which is precisely what a
      // two-Siphon zone hands you.
      for (final e in ThornmireBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('wickerbound_ring'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('wickerbound_ring'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('wickerbound_ring').rarity, Rarity.rare);
    });

    test('the Epic chase is boss-only, and rare', () {
      final epics = ItemCatalogue.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      for (final id in epics) {
        for (final e in all) {
          if (e.drops.possibleDrops.contains(id)) {
            expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
            expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
          }
        }
      }
    });

    test('a hybrid hands over no gate item', () {
      // ⭐ Hearthwood's north road asks for *three ordinary proofs* — one per
      // Primal PURE zone. ⚠️ A fourth from a hybrid would let a player skip
      // one of the three zones the gate exists to route them through.
      final keys = ItemCatalogue.all.whereType<KeyDef>().map((k) => k.id);
      for (final id in keys) {
        expect(
          ThornmireBestiary.allDrops,
          isNot(contains(id)),
          reason: 'Thornmire drops "$id" — the three-proof gate is now four',
        );
      }
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ An item nothing drops and nothing crafts is dead content, and the
      // Collector achievement would be uncompletable. ⭐ The crafted set is
      // DERIVED from RecipeBook, so a recipe removed without a drop added
      // fails here rather than going quietly dead.
      final crafted = RecipeBook.all.map((r) => r.outputId).toSet();
      final dropped = ThornmireBestiary.allDrops;
      for (final d in ThornmireItems.all) {
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
      final walker = ThornmireBestiary.mirewalker;
      final throat = ThornmireBestiary.mirethroat;
      expect(walker.maxHpAt(8), (MageState.scaledMaxHp(8) * 1.00).round());
      expect(throat.maxHpAt(13), (MageState.scaledMaxHp(13) * 3.60).round());
      expect(throat.maxHpAt(13), greaterThan(walker.maxHpAt(13)));
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 8. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(8);
      for (final e in ThornmireBestiary.commons) {
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
