import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/glimmerbrook.dart';
import 'package:masters_of_magic_2/game/items/catalogue/glimmerbrook_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'glimmerbrook';
  final all = GlimmerbrookBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(GlimmerbrookBestiary.commons, hasLength(5));
      expect(GlimmerbrookBestiary.minis, hasLength(4));
      expect(GlimmerbrookBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(GlimmerbrookBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the endurance/trick pair the design names', () {
      // ⭐ ENEMIES §2g's table: The Cold Below ⛰️ Juggernaut, Stillwater ✨
      // Aspect. Two Juggernauts would make the 1-of-2 draw cosmetic.
      expect(GlimmerbrookBestiary.theColdBelow.archetype.id, 'juggernaut');
      expect(GlimmerbrookBestiary.stillwater.archetype.id, 'aspect');
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
      // An id that drifts from its name is a rename nobody notices.
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything belongs to a real zone, and uses that zone element', () {
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(
          e.elements,
          [MagicElement.aqua],
          reason: '${e.id} — a pure zone means one element (ENEMIES §2h)',
        );
        expect(loc.elements, contains(e.elements.single));
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
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding. Without
      // it the first duplicate is a silent overwrite in any id-keyed map.
      for (final id in ids) {
        expect(id.startsWith('gb_'), isTrue, reason: '$id is not zone-tagged');
      }
    });

    test('no move name collides with the game\'s own vocabulary', () {
      // 🚫 ENEMIES §3.3. ⭐ A CORRECTNESS rule, not taste: charging is the core
      // verb, so a move called "Charge" is genuinely ambiguous in the battle
      // log. Same for an element name.
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
      // ⚠️ **The double-scaling trap, and the single easiest way to break a
      // zone.** The engine already scales damage by level
      // (`MageState.levelScale`, 4%/level compounding), so a zone's higher
      // band arrives via the ENCOUNTER LEVEL. Raws written "for level 8" apply
      // the curve twice.
      //
      // The two numbers are measured off Whispering Woods, not invented: its
      // hardest single move is Run Through (48–58, worst case 58 over 5
      // charges = 10.6 per charge). Anything past these is a zone that scaled
      // itself by hand.
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

    test('the Skirmisher acts in the quick band', () {
      // ⭐ ENEMIES §2.5 — tempo is expressed in PRIORITY, which is the only
      // place the theme and the archetype can both be served: the Chill Eel is
      // first, never fast, in a zone whose premise is stillness.
      final eel = GlimmerbrookBestiary.chillEel;
      expect(eel.archetype.id, 'skirmisher');
      for (final m in eel.moves) {
        expect(
          m.priority,
          lessThanOrEqualTo(5),
          reason: 'a Skirmisher that resolves at 9 acts AFTER the player',
        );
      }
    });

    test('the Lasher bites many times, so a shield chips', () {
      // ⭐ §2's "why a big shield is not always the answer" — one hit per
      // Barrier point, so a 3-hit move burns the wall in a way one big roll
      // cannot.
      final shoal = GlimmerbrookBestiary.shiverfishShoal;
      expect(shoal.archetype.id, 'lasher');
      for (final m in shoal.moves) {
        final effect = m.effect;
        expect(effect, isA<DamageEffect>());
        expect(
          (effect as DamageEffect).hits,
          greaterThan(1),
          reason: 'a Lasher with single hits is just a weak Adept',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt/Juggernaut are defined by deflection and
      // attrition. Without a ShieldEffect the archetype is only a bigger HP
      // number, which the player cannot read off the board.
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
      // the Hexer's "slippery and always connecting" is written as priority:
      // one move at 1 lands before shields (3) and quick attacks (5).
      final naiad = GlimmerbrookBestiary.frostgleamNaiad;
      expect(naiad.archetype.id, 'hexer');
      expect(
        naiad.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        naiad.moves.any(
          (m) => m.effect is DamageEffect && (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner hits harder than anything else in the zone', () {
      // ⚠️ "Bring a shield — one misplay ends you" is only true if its ceiling
      // is genuinely the zone's ceiling among the minis.
      int ceiling(EnemyDef e) => e.moves
          .map((m) => m.effect is DamageEffect
              ? (m.effect as DamageEffect).maxAmount *
                    (m.effect as DamageEffect).hits
              : 0)
          .reduce((a, b) => a > b ? a : b);

      final coil = GlimmerbrookBestiary.paleCoil;
      expect(coil.archetype.id, 'executioner');
      for (final e in GlimmerbrookBestiary.minis) {
        if (identical(e, coil)) continue;
        expect(
          ceiling(coil),
          greaterThan(ceiling(e)),
          reason: '${e.id} out-hits the Executioner',
        );
      }
    });

    test('the trick boss is the one that goes through walls', () {
      // ⭐ ✨ Stillwater's Aspect premise: it re-walls for ONE charge and its
      // own hits ignore yours, so a shielding war against water is
      // unwinnable. That contrast with the ⛰️ Juggernaut is the boss pool.
      final still = GlimmerbrookBestiary.stillwater;
      expect(
        still.moves.any(
          (m) => m.effect is DamageEffect && (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'Stillwater without a shield-piercer is a second Juggernaut',
      );
      final wall = still.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.chargeCost,
        1,
        reason: 'the one-charge wall IS the extreme; at 3 it is an ordinary boss',
      );
    });

    test('nothing in this zone lifesteals', () {
      // ⭐ ENEMIES §2.6 — the Siphon is Thornmire's lesson, and it lands only
      // if the player has not been quietly meeting lifesteal for five levels.
      // Glimmerbrook has no Siphon by design, so it must have no steal at all.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" spoils Thornmire\'s reveal',
          );
        }
      }
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
      for (final e in GlimmerbrookBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...GlimmerbrookBestiary.minis,
        ...GlimmerbrookBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in GlimmerbrookBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ ITEMS §8 — Crystal is where the ladder is first FELT, so it must be
      // a fight the player chose. A common that drops crystal collapses the
      // whole ladder into "kill anything repeatedly".
      for (final e in GlimmerbrookBestiary.commons) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('aqua_crystal')),
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in GlimmerbrookBestiary.minis) {
        expect(e.drops.possibleDrops, contains('aqua_crystal'));
      }
      for (final e in GlimmerbrookBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'aqua_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Crystal',
        );
      }
    });

    test('a pure Aqua zone drops only Aqua motes', () {
      // ⚠️ The hybrids drop two ladders on purpose; a pure zone doing it would
      // make the element economy unreadable.
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
      };
      for (final id in GlimmerbrookBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      // ⭐ ITEMS §8 — Rare is the first tier that can carry a MODIFIER at all,
      // which is why a mini-boss drop beats a Master-crafted item
      // categorically. The Brookstone Pendant is this zone's only one.
      for (final e in GlimmerbrookBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('brookstone_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('brookstone_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('brookstone_pendant').rarity,
        Rarity.rare,
      );
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

    test('both bosses hand over the gate item', () {
      // ⭐ Hearthwood's north road wants "three ordinary proofs" — this is the
      // second. ⚠️ On the main table it would be luck; it has to be
      // guaranteed, or progression is gated behind a dice roll.
      for (final b in GlimmerbrookBestiary.bosses) {
        expect(
          b.drops.always.any((d) => d.defId == 'proof_of_the_brook'),
          isTrue,
          reason: '${b.id} does not guarantee the proof',
        );
      }
    });

    test('the gate item is Bound, so it can never be bought', () {
      final proof = ItemCatalogue.byId('proof_of_the_brook');
      expect(proof, isA<KeyDef>());
      expect(proof.tradability, Tradability.bound);
      expect((proof as KeyDef).gates, 'hearthwood');
      expect(World.byId('hearthwood').gate, isNotNull);
    });

    test('potions stay a crafting product, not a drop faucet', () {
      // ⚠️ ITEMS §9b.8 — the MATERIAL is the real drop. A generous potion
      // faucet makes Potions & Alchemy pointless before Galehaven opens.
      for (final e in all) {
        expect(
          e.drops.mainChanceOf('sapwort_draught'),
          lessThanOrEqualTo(0.05),
          reason: '${e.id} is a draught vending machine',
        );
      }
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ An item nothing drops and nothing crafts is dead content, and the
      // Collector achievement would be uncompletable. ⭐ The crafted set is
      // DERIVED from RecipeBook, so a recipe removed without a drop added
      // fails here rather than going quietly dead.
      final crafted = RecipeBook.all.map((r) => r.outputId).toSet();
      final dropped = GlimmerbrookBestiary.allDrops;
      for (final d in GlimmerbrookItems.all) {
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
      final naiad = GlimmerbrookBestiary.brookNaiad;
      final cold = GlimmerbrookBestiary.theColdBelow;
      expect(naiad.maxHpAt(3), (MageState.scaledMaxHp(3) * 1.00).round());
      expect(cold.maxHpAt(8), (MageState.scaledMaxHp(8) * 3.60).round());
      expect(cold.maxHpAt(8), greaterThan(naiad.maxHpAt(8)));
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 3. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(3);
      for (final e in GlimmerbrookBestiary.commons) {
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
