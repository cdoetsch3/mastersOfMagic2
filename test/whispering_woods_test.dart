import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'whispering_woods';
  final all = WhisperingWoodsBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(WhisperingWoodsBestiary.commons, hasLength(5));
      expect(WhisperingWoodsBestiary.minis, hasLength(4));
      expect(WhisperingWoodsBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(WhisperingWoodsBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
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

    test('everything belongs to a real zone, and uses that zone element', () {
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(
          e.elements,
          [MagicElement.flora],
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

    test('move ids are unique across the whole zone', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('no move name collides with the game\'s own vocabulary', () {
      // 🚫 ENEMIES §3.3. ⭐ These are a CORRECTNESS rule, not taste: charging
      // is the core verb, so a move called "Charge" is genuinely ambiguous in
      // the battle log and the tutorial. Same for an element name.
      //
      // ⚠️ Pokémon-adjacent naming is deliberately NOT tested. A blocklist
      // only catches the handful of words someone thought to type, and gives
      // false confidence about the rest — §3.3a's verb narration is the real
      // fix, and the remainder is a review call.
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

    test(
      'the Siphon actually siphons, and nothing else leans on lifesteal',
      () {
        // ⭐ ENEMIES §2.6 — the Siphon is the archetype that invalidates a
        // strategy rather than punishing a mistake. If commons all lifesteal,
        // it stops being a shock.
        double steal(EnemyDef e) => e.moves
            .map(
              (m) => m.effect is DamageEffect
                  ? (m.effect as DamageEffect).lifesteal
                  : 0.0,
            )
            .fold(0.0, (a, b) => a > b ? a : b);

        final creeper = WhisperingWoodsBestiary.bindweedCreeper;
        expect(creeper.archetype.id, 'siphon');
        expect(steal(creeper), greaterThan(0));

        for (final e in WhisperingWoodsBestiary.commons) {
          if (e.archetype.id == 'siphon') continue;
          expect(steal(e), 0, reason: '${e.id} is not a Siphon but lifesteals');
        }
      },
    );
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

    test('commons can come up empty; bosses never do', () {
      // ⭐ A "nothing" weight is what keeps a main table honest — without it
      // every kill pays and the rare slots inflate.
      for (final e in WhisperingWoodsBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...WhisperingWoodsBestiary.minis,
        ...WhisperingWoodsBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in WhisperingWoodsBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
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
      // ⭐ Hearthwood's north road wants "three ordinary proofs" — this is one.
      // ⚠️ On the main table it would be luck; it has to be guaranteed, or
      // progression is gated behind a dice roll.
      for (final b in WhisperingWoodsBestiary.bosses) {
        expect(
          b.drops.always.any((d) => d.defId == 'proof_of_the_woods'),
          isTrue,
          reason: '${b.id} does not guarantee the proof',
        );
      }
    });

    test('the gate item is Bound, so it can never be bought', () {
      final proof = ItemCatalogue.byId('proof_of_the_woods');
      expect(proof, isA<KeyDef>());
      expect(proof.tradability, Tradability.bound);
      expect((proof as KeyDef).gates, 'hearthwood');
      expect(World.byId('hearthwood').gate, isNotNull);
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ An item nothing drops and nothing crafts is dead content, and the
      // Collector achievement would be uncompletable.
      const craftedOnly = {'oak_circlet', 'bindweed_belt', 'foragers_ration'};
      final dropped = WhisperingWoodsBestiary.allDrops;
      for (final d in ItemCatalogue.all) {
        if (craftedOnly.contains(d.id)) continue;
        expect(
          dropped.contains(d.id),
          isTrue,
          reason: '${d.id} is defined but nothing drops it',
        );
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final fawn = WhisperingWoodsBestiary.listeningFawn;
      final heart = WhisperingWoodsBestiary.heartwood;
      expect(fawn.maxHpAt(1), (100 * 0.80).round());
      expect(heart.maxHpAt(5), (MageState.scaledMaxHp(5) * 3.60).round());
      expect(heart.maxHpAt(5), greaterThan(fawn.maxHpAt(5)));
    });

    test('no common one-shots a fresh level-1 character', () {
      // ⚠️ A level-1 mage has 100 HP. Anything that can open with a kill is a
      // tutorial that ends the tutorial.
      const startingHp = 100;
      for (final e in WhisperingWoodsBestiary.commons) {
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

    test('every item carries lore too', () {
      for (final d in ItemCatalogue.all) {
        expect(d.lore.length, greaterThan(20), reason: '${d.id} lore is thin');
      }
    });
  });
}
