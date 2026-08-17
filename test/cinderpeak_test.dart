import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/cinderpeak_foothills.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/items/catalogue/cinderpeak_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'cinderpeak_foothills';
  final all = CinderpeakBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(CinderpeakBestiary.commons, hasLength(5));
      expect(CinderpeakBestiary.minis, hasLength(4));
      expect(CinderpeakBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(CinderpeakBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the mass/mind pair the design names', () {
      // ⭐ ENEMIES §2g's table: The Breathing Stone ⛰️ Juggernaut (a force),
      // Flintmaw 👑 Tyrant (a mind). ⚠️ This is the only Primal zone whose
      // pool has no Aspect, and that is deliberate — the mountain is the
      // element, and Flintmaw is what lives on it.
      expect(CinderpeakBestiary.theBreathingStone.archetype.id, 'juggernaut');
      expect(CinderpeakBestiary.flintmaw.archetype.id, 'tyrant');
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
          [MagicElement.pyro],
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
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding.
      for (final id in ids) {
        expect(id.startsWith('cp_'), isTrue, reason: '$id is not zone-tagged');
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
      // 6–11 band arrives via the ENCOUNTER LEVEL. Raws written "for level 11"
      // apply the curve twice. Both numbers are measured off Whispering Woods'
      // hardest move (Run Through, 58 worst case, 10.6 per charge).
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
      // ⭐ ENEMIES §2.5 — tempo is expressed in PRIORITY, not in prose.
      final skink = CinderpeakBestiary.flintSkink;
      expect(skink.archetype.id, 'skirmisher');
      for (final m in skink.moves) {
        expect(
          m.priority,
          lessThanOrEqualTo(5),
          reason: 'a Skirmisher that resolves at 9 acts AFTER the player',
        );
      }
    });

    test('the Bruiser is completely telegraphed', () {
      // ⭐ §2 — "reading the charge bar" is the whole lesson. A Bruiser whose
      // moves are all cheap has nothing to read, and its 1.15/1.10 statline
      // becomes free value.
      final brute = CinderpeakBestiary.ashjawBrute;
      expect(brute.archetype.id, 'bruiser');
      expect(
        brute.moves.map((m) => m.chargeCost).reduce((a, b) => a > b ? a : b),
        greaterThanOrEqualTo(5),
        reason: 'nothing the Brute does needs a visible wind-up',
      );
    });

    test('the Blighter wins by out-lasting, never by out-hitting', () {
      // ⭐ 0.60 damage is the lowest in the game. Every move multi-hit is how
      // that reads on the board: constant, and never frightening.
      final worm = CinderpeakBestiary.ventworm;
      expect(worm.archetype.id, 'blighter');
      for (final m in worm.moves) {
        final effect = m.effect;
        expect(effect, isA<DamageEffect>());
        expect(
          (effect as DamageEffect).hits,
          greaterThan(1),
          reason: 'the Ventworm hits once, which is not a fume',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt/Juggernaut are defined by attrition. Without a
      // ShieldEffect the archetype is only a bigger HP number, which the
      // player cannot read off the board.
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
      final queen = CinderpeakBestiary.theEmberqueen;
      expect(queen.archetype.id, 'hexer');
      expect(
        queen.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        queen.moves.any(
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

      final tusk = CinderpeakBestiary.charTusk;
      expect(tusk.archetype.id, 'executioner');
      for (final e in CinderpeakBestiary.minis) {
        if (identical(e, tusk)) continue;
        expect(
          ceiling(tusk),
          greaterThan(ceiling(e)),
          reason: '${e.id} out-hits the Executioner',
        );
      }
    });

    test('the Tyrant plays well rather than merely being large', () {
      // ⭐ §2 — "the intelligence is the threat". Flintmaw is the smaller boss
      // of the two by HP; what it has instead is a wall it can afford at ONE
      // charge and a hit at priority 2, which lands ahead of the player's own
      // shield at 3. Those two together are the archetype.
      final maw = CinderpeakBestiary.flintmaw;
      expect(maw.archetype.id, 'tyrant');
      expect(
        maw.archetype.hpScale,
        lessThan(CinderpeakBestiary.theBreathingStone.archetype.hpScale),
      );
      final wall = maw.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.chargeCost, 1, reason: 'a wall it cannot always afford');
      expect(
        maw.moves.any((m) => m.isOffensive && m.priority < 3),
        isTrue,
        reason: 'nothing Flintmaw throws beats a shield to the board',
      );
    });

    test('nothing in this zone lifesteals', () {
      // ⭐ ENEMIES §2.6 — the Siphon is Thornmire's lesson, and it lands only
      // if the player has not been quietly meeting lifesteal for ten levels.
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
      for (final e in CinderpeakBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...CinderpeakBestiary.minis,
        ...CinderpeakBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in CinderpeakBestiary.commons) {
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
      // a fight the player chose.
      for (final e in CinderpeakBestiary.commons) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('pyro_crystal')),
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in CinderpeakBestiary.minis) {
        expect(e.drops.possibleDrops, contains('pyro_crystal'));
      }
      for (final e in CinderpeakBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'pyro_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Crystal',
        );
      }
    });

    test('a pure Pyro zone drops only Pyro motes', () {
      // ⚠️ The hybrids drop two ladders on purpose; a pure zone doing it would
      // make the element economy unreadable.
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
      };
      for (final id in CinderpeakBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      // ⭐ The Cinder Loop is the game's first crit source and Q1's preview of
      // a Q2 mechanic (ITEMS §9b.8). It must stay a chase, not a tax.
      for (final e in CinderpeakBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('cinder_loop'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('cinder_loop'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('cinder_loop').rarity, Rarity.rare);
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
      // ⭐ The third of Hearthwood's "three ordinary proofs", and the one that
      // completes the set. ⚠️ On the main table it would be luck; it has to be
      // guaranteed, or progression is gated behind a dice roll.
      for (final b in CinderpeakBestiary.bosses) {
        expect(
          b.drops.always.any((d) => d.defId == 'proof_of_the_foothills'),
          isTrue,
          reason: '${b.id} does not guarantee the proof',
        );
      }
    });

    test('the gate item is Bound, so it can never be bought', () {
      final proof = ItemCatalogue.byId('proof_of_the_foothills');
      expect(proof, isA<KeyDef>());
      expect(proof.tradability, Tradability.bound);
      expect((proof as KeyDef).gates, 'hearthwood');
      expect(World.byId('hearthwood').gate, isNotNull);
    });

    test('⏳ the banking material actually banks', () {
      // ⚠️ ITEMS §9b.8 — copper has no Q1 recipe **by ruling**. That makes it
      // the one material a player could reasonably think is broken, so the
      // piles must be large enough to read as a promise rather than as litter.
      expect(
        RecipeBook.all.any((r) => r.inputs.any((i) => i.defId == 'copper_ore')),
        isFalse,
        reason: 'copper is no longer a banking material — update the doc',
      );
      for (final b in CinderpeakBestiary.bosses) {
        final copper = b.drops.main.firstWhere((d) => d.defId == 'copper_ore');
        expect(copper.max, greaterThanOrEqualTo(4));
      }
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ An item nothing drops and nothing crafts is dead content, and the
      // Collector achievement would be uncompletable. ⭐ The crafted set is
      // DERIVED from RecipeBook, so a recipe removed without a drop added
      // fails here rather than going quietly dead.
      final crafted = RecipeBook.all.map((r) => r.outputId).toSet();
      final dropped = CinderpeakBestiary.allDrops;
      for (final d in CinderpeakItems.all) {
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
      final brute = CinderpeakBestiary.ashjawBrute;
      final stone = CinderpeakBestiary.theBreathingStone;
      expect(brute.maxHpAt(6), (MageState.scaledMaxHp(6) * 1.15).round());
      expect(stone.maxHpAt(11), (MageState.scaledMaxHp(11) * 3.60).round());
      expect(stone.maxHpAt(11), greaterThan(brute.maxHpAt(11)));
    });

    test('⭐ the Cinder Moth really is meant to have 69 HP at level 9', () {
      // 📝 A player asked why this creature is so flimsy. It is not a bug, and
      // this test exists so the next person to ask gets an answer instead of a
      // rebalance: the Moth is a **Glasswing** (0.50 HP × 1.70 damage), the
      // archetype whose whole lesson is *"killing fast beats playing safe"*.
      // Half the health of an even fight is the teaching device — it is the
      // one enemy in the zone that punishes a player for turtling behind a
      // shield instead of ending the fight, and it can only do that by dying
      // fast enough to be worth racing.
      //
      // ⚠️ Its own move damage looks small for the same reason its HP does:
      // both are RAW numbers that the archetype multiplies (see the authoring
      // note on `cinderMoth`). 12–16 on "Go Out Bright" is 20–27 after 1.70×.
      final moth = CinderpeakBestiary.cinderMoth;
      expect(moth.archetype, Archetypes.glasswing);
      expect(MageState.scaledMaxHp(9), 137, reason: '100 × 1.04^8, rounded');
      expect(moth.maxHpAt(9), 69, reason: '137 × 0.50 = 68.5, rounded to 69');

      // 🚫 Kills a "fix" that quietly buffs the Moth toward the yardstick: it
      // must stay the flimsiest thing in the zone, well under an even fight.
      expect(moth.maxHpAt(9), lessThan(MageState.scaledMaxHp(9) * 0.6),
          reason: 'a Glasswing that survives a trade is not a Glasswing');
      for (final e in CinderpeakBestiary.commons) {
        expect(moth.maxHpAt(9), lessThanOrEqualTo(e.maxHpAt(9)),
            reason: '${e.id} is now flimsier than the zone\'s glass cannon');
      }
      // ⭐ Against the Adept — the 1.0×/1.0× yardstick every archetype is felt
      // against (§2.7) — the trade is explicit: it gives up half its health
      // and is paid in damage for it.
      expect(moth.archetype.damageScale,
          greaterThan(Archetypes.adept.damageScale),
          reason: 'it pays for the missing health in damage, or it pays for '
              'nothing');
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 6. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(6);
      for (final e in CinderpeakBestiary.commons) {
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
