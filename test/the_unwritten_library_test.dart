/// The Unwritten Library's roster LAWS (Lv 54–58, Umbra + Arcane) and its
/// catalogue checks — ENEMIES §2e plus ETHEREAL_CONTRACT §4.7.
///
/// ⚠️ **`umbra_*`, `climbers_ration` and `censer_draught` are owned by
/// parallel Ethereal worktrees** (The Umbral Wastes, Hallowmarch and The
/// Reliquary Deep). Everything this zone DEFINES is asserted normally; the
/// whole-table resolution law is written and `skip:`ped by name, so the merge
/// coordinator has exactly one line to delete once the lanes land together.
/// ⭐ `arcane_*` is NOT in that list — it is already on main, defined by The
/// Glass Archive (CELESTIAL §3.2).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_unwritten_library.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_unwritten_library_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Library itself authors — that is what
/// the "no local id hides in here" test below proves.
const _parallelLaneIds = <String>{
  'umbra_dust',
  'umbra_shard',
  'umbra_crystal',
  'climbers_ration',
  'censer_draught',
};

void main() {
  const zone = 'the_unwritten_library';
  final all = UnwrittenLibraryBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        UnwrittenLibraryBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        UnwrittenLibraryBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        UnwrittenLibraryBestiary.bosses,
        hasLength(2),
        reason: 'one drawn of two',
      );
    });

    test('📝 the repeat-clear third boss *Your Entry* is NOT built', () {
      // ❓ ENEMIES §2e gives it no archetype and no ruling, and §4.7 says
      // "nothing in this catalogue depends on it". ⚠️ Kills the mutant that
      // helpfully adds it as a Tyrant (the doc's *recommendation*, not its
      // ruling) and silently breaks the 5/4/2 template every other law here
      // is written against.
      expect(
        all.map((e) => e.id),
        isNot(contains('your_entry')),
        reason: 'Your Entry has no archetype yet; §2e leaves it unruled',
      );
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'a twelfth creature means the template was abandoned',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (§7.1) — a bestiary
      // left out of `Bestiary.all` compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'UnwrittenLibraryBestiary is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'forZone and the class list disagree about the roster',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(
        UnwrittenLibraryBestiary.minis.map((e) => e.archetype.id).toSet(),
        {'champion', 'redoubt', 'executioner', 'hexer'},
        reason: 'two minis share an archetype, so a run can draw a mirror',
      );
    });

    test('the boss pair is what is written and the nobody writing it, '
        'NOT a mirror', () {
      // ⭐⭐ ENEMIES §2f's best change in the pass: The Author was a TYRANT and
      // became an ASPECT, because §2g gives Tyrant to "a person, a will,
      // something that decided" and this zone's premise is that there is no
      // author. ⚠️ A mutant that restores the Tyrant compiles, plays fine,
      // and contradicts the zone out loud.
      expect(UnwrittenLibraryBestiary.theRecord.archetype.id, 'juggernaut');
      expect(UnwrittenLibraryBestiary.theAuthor.archetype.id, 'aspect');
      expect(
        UnwrittenLibraryBestiary.bosses.map((b) => b.archetype.id),
        isNot(contains('tyrant')),
        reason:
            'a Tyrant here says somebody decided, which is the one thing '
            'this Library does not have',
      );
      // ⚠️ §2f also forbids repeating the neighbour's pair: The Reliquary
      // Deep (52–56) is Juggernaut + Tyrant, so the Aspect is load-bearing
      // twice over.
      expect(
        UnwrittenLibraryBestiary.bosses.map((b) => b.archetype.id).toSet(),
        hasLength(2),
        reason: 'the two bosses are the same archetype',
      );
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

    test('the five commons are the five archetypes §2e names', () {
      // ⚠️ Blankspine is a §2f re-assignment — Glasswing, *was Sentinel*. A
      // mutant that reverts it turns "the easiest thing in the room to
      // destroy" into a 1.25-HP wall and still compiles.
      expect(
        UnwrittenLibraryBestiary.commons.map((e) => e.archetype.id).toList(),
        ['adept', 'glasswing', 'lasher', 'skirmisher', 'siphon'],
      );
      expect(
        UnwrittenLibraryBestiary.blankspine.archetype.id,
        isNot('sentinel'),
        reason:
            '§2f made Blankspine a Glasswing; a book opens, it does not '
            'hold',
      );
    });

    test('⭐ the Siphon is kept, and it is Ink-Drinker', () {
      // §2f cut the Siphon from 8 zones to 3 on a literal test — "the zone's
      // premise must be drinking, eating or being fed". This is one of the
      // three, and it is the only Siphon in the zone.
      expect(all.where((e) => e.archetype.id == 'siphon').map((e) => e.id), [
        'ink_drinker',
      ], reason: '§2f keeps exactly one Siphon here, named');
    });

    test('⚠️ no Drudge anywhere — §2f puts zero above level 30', () {
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('drudge')),
        reason: 'a 0.80/0.70 body at level 54 is a wasted encounter slot',
      );
    });

    test('ids and names are unique', () {
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // An id that drifts from its name is a rename nobody notices.
      // ⭐ Ink-Drinker is the hyphen case this rule has to survive.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
      expect(UnwrittenLibraryBestiary.inkDrinker.id, 'ink_drinker');
    });

    test('the per-creature element assignment matches §2e exactly', () {
      // ⭐ Hard-coded rather than derived: §2h lets a hybrid assign one
      // element or both per creature, so there is no formula to check
      // against — only the table.
      const umbra = [MagicElement.umbra];
      const arcane = [MagicElement.arcane];
      const both = [MagicElement.umbra, MagicElement.arcane];
      expect(UnwrittenLibraryBestiary.theDictatingHand.elements, both);
      expect(UnwrittenLibraryBestiary.blankspine.elements, umbra);
      expect(UnwrittenLibraryBestiary.footnote.elements, arcane);
      expect(UnwrittenLibraryBestiary.erratum.elements, arcane);
      expect(UnwrittenLibraryBestiary.inkDrinker.elements, umbra);
      expect(UnwrittenLibraryBestiary.theIndex.elements, arcane);
      expect(UnwrittenLibraryBestiary.colophon.elements, arcane);
      expect(UnwrittenLibraryBestiary.redaction.elements, umbra);
      expect(UnwrittenLibraryBestiary.theAmanuensis.elements, both);
      expect(UnwrittenLibraryBestiary.theRecord.elements, arcane);
      // ⚠️ The Aspect MUST be single-element (ENEMIES §2.5), and Umbra is the
      // half that means *nobody*.
      expect(
        UnwrittenLibraryBestiary.theAuthor.elements,
        umbra,
        reason:
            'the Aspect is Umbra per ENEMIES §2e, and single-element per §2.5',
      );
    });

    test('⚠️ NOTHING in this zone carries an off-element', () {
      // §2e.2 licenses one off-element move in four creatures across fifteen
      // zones — The Long Count, Burnt Index, the Cherub, The Fourth Item. ⭐
      // None of them is here, so the guardrail for this zone is "zero", and a
      // mutant that helpfully adds a third element to a boss fails here.
      const zoneElements = {MagicElement.umbra, MagicElement.arcane};
      for (final e in all) {
        expect(
          e.elements.where((el) => !zoneElements.contains(el)),
          isEmpty,
          reason: '${e.id} carries an element §2e.2 never licensed here',
        );
      }
      // ⭐⭐ And here is WHY there is nothing to license: **Arcane is
      // countered by Umbra**, which is this zone's own other half. §2h's one
      // non-tunable row forbids a creature carrying the zone's own counter,
      // so the only third element that could read as "the Library, elsewhere"
      // is already inside the pair. ⚠️ Pinned so that moving the counter
      // wheel is a loud failure here rather than a quiet re-opening of
      // §2e.2's table.
      expect(
        MagicElement.arcane.counteredBy,
        MagicElement.umbra,
        reason: 'the counter wheel moved; re-derive §2e.2 before trusting it',
      );
      expect(MagicElement.umbra.counteredBy, MagicElement.sanctus);
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2f: the Adept is mandatory and usually lands on the anchor name.
      // The Dictating Hand is the zone's yardstick and its ✅ in §2e's table.
      expect(
        UnwrittenLibraryBestiary.theDictatingHand.archetype.id,
        'adept',
        reason:
            'the anchor is the yardstick the rest of the zone is felt against',
      );
      expect(
        all.where((e) => e.archetype.id == 'adept'),
        hasLength(1),
        reason: '§2f: exactly one Adept per zone',
      );
    });

    test('the zone band is 54–58, a dungeon, Umbra + Arcane', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 54);
      expect(loc.maxLevel, 58);
      expect(loc.kind, LocationKind.dungeon, reason: '🏰 in ENEMIES §2e');
      expect(loc.elements, [MagicElement.umbra, MagicElement.arcane]);
      expect(loc.tier, MagicTier.ethereal);
      expect(
        loc.gate,
        isNull,
        reason:
            'the Library gates nothing — the Citadel is the gated zone (§3.4)',
      );
    });
  });

  group('combat stats match §2.3 (CELESTIAL §2.3\'s table)', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        UnwrittenLibraryBestiary.theDictatingHand.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        UnwrittenLibraryBestiary.blankspine.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Lasher trades crit damage for crit frequency', () {
      expect(
        UnwrittenLibraryBestiary.footnote.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Skirmisher is quick and hard to pin', () {
      expect(
        UnwrittenLibraryBestiary.erratum.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
      );
    });

    test('⭐ the Siphon connects, survives, and never crits', () {
      // §2.3's Siphon row and its whole reasoning: it must CONNECT to steal
      // and SURVIVE to keep stealing — and a lifesteal crit heals it for the
      // crit too, which is the stalemate §2.2 fears. ⚠️ A mutant that "tidies"
      // this by giving it the Skirmisher's 8 dodge breaks the §2.3 ordering
      // (Siphon 6 < Skirmisher 8 < Hexer 10) that the cap is expressed in.
      expect(
        UnwrittenLibraryBestiary.inkDrinker.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, dodge: 6),
      );
      expect(
        UnwrittenLibraryBestiary.inkDrinker.combatStats.critChance,
        0,
        reason: 'a lifesteal crit heals it for the crit too',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        UnwrittenLibraryBestiary.theIndex.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you, at the UNREDUCED row', () {
      // 📝 §2.3 recommends 25/24 for a dungeon Redoubt but names exactly two
      // creatures — Bedrock Colossus and Reliquary Colossus — and this is
      // neither. The verbatim row stands until the probe widens the
      // deviation; this expect is where that decision is recorded.
      expect(
        UnwrittenLibraryBestiary.colophon.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        UnwrittenLibraryBestiary.redaction.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        UnwrittenLibraryBestiary.theAmanuensis.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut is unstoppable and unsubtle', () {
      expect(
        UnwrittenLibraryBestiary.theRecord.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('⚠️ the Aspect is §2.4\'s UMBRA row, verbatim', () {
      // crit 15 / +60, defl 20 / 18. ⭐ +60 rather than §2.4's +70: the Umbral
      // Wastes' Aspect keeps the game's single largest crit-damage number
      // (build manager, 2026-09-22). §2.4's reasoning is about
      // the ELEMENT, not the zone: "Umbra's lean is crit damage, and Creeping
      // Dark is growth toward one enormous consequence." ⚠️ +70 is the
      // largest number on any stat block in the game and is deliberately
      // paired with a LOW 15% chance — a mutant that "balances" it by raising
      // the chance turns a decided consequence into a coin flip.
      expect(
        UnwrittenLibraryBestiary.theAuthor.combatStats,
        const EnemyCombatStats(
          critChance: 15,
          critDamage: 60,
          deflectChance: 20,
          deflectAmount: 18,
        ),
      );
      expect(
        UnwrittenLibraryBestiary.theAuthor.combatStats.critChance,
        lessThan(20),
        reason: 'the 220% crit is decided, not frequent',
      );
    });

    test('enemy dodge never exceeds the §2.3 cap of 10', () {
      for (final e in all) {
        expect(
          e.combatStats.dodge,
          lessThanOrEqualTo(10),
          reason:
              '${e.id} — enemy dodge should read as slippery, never '
              'unhittable',
        );
      }
    });

    test('no inert stat: an amount never appears without its chance', () {
      // ⚠️ §2.1's three inert-stat traps — a "buff" with a zero chance to
      // trigger is dead weight nobody notices until they read the code.
      for (final e in all) {
        final s = e.combatStats;
        expect(
          s.critDamage == 0 || s.critChance > 0,
          isTrue,
          reason: '${e.id} has crit damage but critChance == 0',
        );
        expect(
          s.deflectAmount == 0 || s.deflectChance > 0,
          isTrue,
          reason: '${e.id} has deflect amount but deflectChance == 0',
        );
        expect(
          s.deflectChance == 0 || s.deflectAmount > 0,
          isTrue,
          reason: '${e.id} has deflect chance but deflectAmount == 0',
        );
      }
    });
  });

  group('creatures are creatures, not mages', () {
    test('no creature here is a mage', () {
      // ⚠️ ENEMIES §3.4 names the mage bosses — the Archmage and Procarius —
      // and neither is in this zone, so the move-count law below applies to
      // every creature with no exemption.
      expect(
        all.map((e) => e.name),
        isNot(contains('Procarius, the Eclipsed')),
      );
    });

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

    test('move ids are unique across the WHOLE bestiary, and all ul_', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a
      // collision with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('ul_'), isTrue, reason: '$id is not zone-tagged');
      }
      // ⭐ Mages cast Spellbook ids by design (EnemyDef.isMage), and two
      // mages may share one — the law is over CREATURE kits only.
      final everything = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everything.toSet(),
        hasLength(everything.length),
        reason: 'a ul_ move id collides with another zone\'s',
      );
    });

    test('no move name collides with the game\'s own vocabulary', () {
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

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree. ⚠️ No mage
      // exemption applies in this zone: the Library fields no mage boss.
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
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so a 54–58 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and does not
      // grow — which a builder authoring a level-58 boss will want to doubt
      // more than anyone before them.
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
            lessThanOrEqualTo(12),
            reason: '${e.id}\'s "${m.name}" is too efficient per charge',
          );
        }
      }
    });

    test('the Lasher is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule, and it is the whole of what makes a
      // Lasher read differently from a plain attacker: each hit meets the
      // wall on its own, which is "damage in pieces" (§2e).
      for (final m in UnwrittenLibraryBestiary.footnote.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: 'footnote\'s "${m.name}" arrives in one piece',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt/Juggernaut are defined partly by attrition.
      // Without a ShieldEffect the archetype is only a bigger HP number.
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'juggernaut'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason:
              '${e.id} is a ${e.archetype.name} with nothing to hide behind',
        );
      }
    });

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final wall = UnwrittenLibraryBestiary.colophon.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(SpellPriority.shield),
        reason: 'a book that closes after you shield closes on nothing',
      );
    });

    test('no shield ever sits on the attack rung', () {
      // ⚠️ The priority ladder's one hard "never" (the shipped integer
      // ladder): a shield at 9 goes up after everything it was meant to stop.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.effect is! ShieldEffect) continue;
          expect(
            m.priority,
            lessThanOrEqualTo(SpellPriority.shield),
            reason: '${e.id}\'s "${m.name}" shields too late to matter',
          );
        }
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final amanuensis = UnwrittenLibraryBestiary.theAmanuensis;
      expect(amanuensis.archetype.id, 'hexer');
      expect(
        amanuensis.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        amanuensis.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Skirmisher corrects you before you have finished being '
        'wrong', () {
      // ⭐ §2e's own line for Erratum, and §2.5's "quick" tempo lean: the
      // Skirmisher's signature is WHERE IT SITS on the ladder, not what it
      // does. Both moves at 5 — ahead of every ordinary attack, behind every
      // shield. ⚠️ A mutant that moves either to 9 keeps the statline and
      // deletes the lesson.
      for (final m in UnwrittenLibraryBestiary.erratum.moves) {
        expect(
          m.priority,
          SpellPriority.quick,
          reason: '"${m.name}" is not on the quick rung',
        );
      }
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — at L58 a mini five-charge raw lands far past a one-shot of
      // the 935 HP bar the band tops out at. Kills a mutant that restores the
      // archetype's own maxMoveCost of 5.
      final redaction = UnwrittenLibraryBestiary.redaction;
      expect(redaction.archetype.id, 'executioner');
      for (final m in redaction.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
    });

    test('⭐ ONLY the Siphon lifesteals', () {
      // §2.6 — the Siphon is the archetype that invalidates a strategy rather
      // than punishing a mistake, and it only reads that way if it is the one
      // thing in the zone that drinks. ⚠️ A lifesteal rider elsewhere (the
      // shipped Frostfell Redoubt carries one) would spoil the reveal.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          if (e.archetype.id == 'siphon') continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" takes what is yours',
          );
        }
      }
      for (final m in UnwrittenLibraryBestiary.inkDrinker.moves) {
        expect(
          (m.effect as DamageEffect).lifesteal,
          greaterThan(0),
          reason: 'the Ink-Drinker\'s "${m.name}" does not drink',
        );
      }
    });

    test('every creature has at least one move it can afford from zero', () {
      for (final e in all) {
        expect(e.moves, isNotEmpty, reason: '${e.id} has no moves');
        expect(
          e.moves.map((m) => m.chargeCost).reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(5),
          reason: '${e.id} cannot reach any of its own moves',
        );
      }
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id this zone OWNS resolves against the catalogue', () {
      // ⚠️ Excludes the three parallel lanes' ids only — everything the
      // Library defines itself, plus Q3's arcane_*, must resolve today.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_parallelLaneIds.contains(id)) continue;
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('every id in every table is a real item', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = UnwrittenLibraryItems.all.map((d) => d.id).toSet();
      expect(
        mine.intersection(_parallelLaneIds),
        isEmpty,
        reason: 'the exemption list is excusing an id this lane owns',
      );
      // ⭐ arcane_* is deliberately NOT exempt — The Glass Archive is on main.
      expect(
        _parallelLaneIds,
        isNot(contains('arcane_dust')),
        reason: 'arcane_* ships with the Celestial quarter (§3.2)',
      );
      expect(ItemCatalogue.tryById('arcane_dust'), isNotNull);
    });

    test('⭐ the hide role lands on the two commons §2e marks `hide`', () {
      // ⚠️⚠️ The join §4.7's drop table and §2e's roster needed a ruling.
      // The contract's third common row is labelled "the Siphon"; its roster
      // gives `hide` to The Dictating Hand AND Ink-Drinker and `material` to
      // Blankspine, which does not fit 2+2+1. The ROSTER won, because §0.1
      // and §0.3 both defer creature facts to it and a drop role is a
      // creature fact (§2e.1). ⚠️ Honouring the stale label would have paid
      // Ink-Drinker a GATHERABLE material against a role defined as
      // "kill-only… it exists only because something died".
      for (final e in [
        UnwrittenLibraryBestiary.theDictatingHand,
        UnwrittenLibraryBestiary.inkDrinker,
      ]) {
        expect(
          e.drops.possibleDrops,
          contains('blankspine_vellum'),
          reason: '${e.id} carries `hide` in §2e and pays no hide',
        );
      }
      expect(
        UnwrittenLibraryBestiary.blankspine.drops.possibleDrops,
        contains('nightink'),
        reason: 'blankspine carries `material` in §2e and pays no material',
      );
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
      for (final e in UnwrittenLibraryBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...UnwrittenLibraryBestiary.minis,
        ...UnwrittenLibraryBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in UnwrittenLibraryBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.tryById(id);
          if (def == null) continue; // cross-lane; covered by the skip above
          expect(
            def.rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ the hybrid pays BOTH mote ladders and nothing else', () {
      final dropped = UnwrittenLibraryBestiary.allDrops;
      for (final id in [
        'umbra_dust',
        'umbra_shard',
        'umbra_crystal',
        'arcane_dust',
        'arcane_shard',
        'arcane_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.umbra && el != MagicElement.arcane) ...[
            '${el.name}_dust',
            '${el.name}_shard',
            '${el.name}_crystal',
          ],
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in UnwrittenLibraryBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in UnwrittenLibraryBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ neither boss carries a key — this is NOT a gate zone', () {
      // §2e.1 puts `key` on BOTH bosses of a gate zone, `always`, never
      // weighted. The three Ethereal fragments fall in Hallowmarch, The
      // Umbral Wastes and The Collapsed Academy — `the_kept_third`,
      // `the_dark_third`, `the_written_third` — and none of them is here.
      for (final b in UnwrittenLibraryBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('third')),
            reason: '${b.id} drops something that reads like a gate part',
          );
          expect(ItemCatalogue.tryById(id), isNot(isA<KeyDef>()));
        }
      }
      expect(
        UnwrittenLibraryItems.all.whereType<KeyDef>(),
        isEmpty,
        reason: 'the Library defines a key it has no gate for',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in UnwrittenLibraryBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('colophon_signet'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('colophon_signet'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('colophon_signet').rarity, Rarity.rare);
    });

    test('the epic is boss-only, and it is the game\'s first Codex', () {
      final epics = UnwrittenLibraryItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_open_colophon',
      ], reason: '§4.7 authors exactly one epic');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
        }
      }
    });
  });

  group('the catalogue matches §4.7', () {
    test('7 defs, all resolvable under this zone', () {
      expect(UnwrittenLibraryItems.all, hasLength(7), reason: '§7.1\'s count');
      for (final def in UnwrittenLibraryItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⭐ this zone defines NO mote family, and that is the ruling', () {
      // §3.2 — `umbra_*` belongs to The Umbral Wastes and `arcane_*` to The
      // Glass Archive, seven levels downhill in the Celestial quarter, under
      // the shipped rule "the mote lives with the zone that first yields it".
      // ⚠️ A helpful builder re-defining arcane_dust here makes two defs with
      // one id and the catalogue silently keeps one.
      expect(
        UnwrittenLibraryItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'the Library pays in two families and owns neither',
      );
      expect(
        ItemCatalogue.zoneOf('arcane_dust'),
        'the_glass_archive',
        reason: 'arcane_* moved out of the zone that first yields it',
      );
    });

    test('three materials, one of each consuming skill, all tier 10', () {
      // ⭐ ITEMS §9b.8 ruling 7: a hybrid gets three. Potions / Jewelry /
      // Tailoring, which is also what §6's two nodes plus one hide encode.
      final mats = UnwrittenLibraryItems.all.whereType<MaterialDef>().toList();
      expect(mats, hasLength(3));
      expect(mats.map((m) => m.skill).toSet(), {
        CraftSkill.potionsAndAlchemy,
        CraftSkill.jewelry,
        CraftSkill.tailoring,
      });
      for (final m in mats) {
        expect(m.tier, 10, reason: '${m.id} is not the band\'s tier');
      }
      expect(
        UnwrittenLibraryItems.colophonStone.rarity,
        Rarity.uncommon,
        reason: 'uncommon survives on gem-grade materials only (§0.2)',
      );
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in UnwrittenLibraryItems.all) {
          if (def is EquipmentDef) {
            expect(
              def.equipLevel,
              inInclusiveRange(loc.minLevel, loc.maxLevel),
              reason: '${def.id} equips outside its own zone\'s band',
            );
          } else {
            expect(
              def.equipLevel,
              lessThanOrEqualTo(loc.minLevel),
              reason:
                  '${def.id} is a mote, material or consumable and must be '
                  'usable the moment it drops',
            );
          }
        }
        // ⚠️ §4.7 pins these three specifically.
        expect(UnwrittenLibraryItems.blankspineBelt.equipLevel, 56);
        expect(UnwrittenLibraryItems.colophonSignet.equipLevel, 56);
        expect(UnwrittenLibraryItems.theOpenColophon.equipLevel, 58);
      },
    );

    test('the crafted belt composes its name; the two drops are written', () {
      // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
      // material+form grammar composes the name and cannot drift from it.
      expect(
        UnwrittenLibraryItems.blankspineBelt.properName,
        isNull,
        reason: 'a written name on crafted gear reintroduces the drift',
      );
      expect(
        UnwrittenLibraryItems.colophonSignet.properName,
        'Colophon Signet',
      );
      expect(
        UnwrittenLibraryItems.theOpenColophon.properName,
        'The Open Colophon',
      );
    });

    test('⭐ the belt ladder\'s last authored rung is 9, and it is capacity '
        'ONLY', () {
      // §4.7: "Belt ladder complete: … Penitent 8 → Blankspine 9", and
      // `Carrying.maxBeltSlots` is 10, so one rung is left deliberately.
      // ⚠️ ITEMS §6b.2 — the belt is the one slot whose value is NOT combat
      // power. A mutant that adds 20 maxHp here is invisible and wrong.
      final belt = UnwrittenLibraryItems.blankspineBelt;
      expect(belt.modifiers.beltSlots, 9);
      expect(belt.slot, EquipSlot.belt);
      expect(
        belt.modifiers,
        const ItemModifiers(beltSlots: 9),
        reason: 'the belt carries something other than capacity',
      );
    });

    test('⭐⭐ the Codex is the game\'s first non-Knot off-hand', () {
      // §4.7, answering ITEMS §9b.6's own 💡. ⚠️ It must NOT be two-handed
      // and must NOT be a main hand — it is what a wand is held *with*, which
      // is the whole point of the pairing.
      final codex = UnwrittenLibraryItems.theOpenColophon;
      expect(codex.slot, EquipSlot.offHand);
      expect(codex.form, 'Codex');
      expect(codex.twoHanded, isFalse);
      expect(
        codex.modifiers,
        const ItemModifiers(accuracyBonus: 9, critChance: 8, damagePerCast: 12),
        reason:
            '§4.7\'s numbers are what make wand + codex measure up to '
            'the_unbuilt_stair',
      );
      // ⚠️ No other off-hand in the game is a Codex; if a second one lands,
      // §9b.6's family identities need re-deriving, not copying.
      final codices = ItemCatalogue.all.whereType<EquipmentDef>().where(
        (d) => d.form == 'Codex',
      );
      expect(codices, hasLength(1), reason: 'the book family has a second');
    });

    test(
      '⭐ the Draught is the largest heal in the game, flat, and beltable',
      () {
        final draught = UnwrittenLibraryItems.nightinkDraught;
        expect(draught, isA<Beltable>(), reason: 'a Draught is drunk mid-duel');
        expect(draught.effect.heal, 320);
        expect(
          draught.effect.healPerTurn,
          0,
          reason: 'a Draught is a lump — that is what a Tonic is not (§3.3)',
        );
        // ⚠️ Ruled flat (2026-09-21): no maxHp term anywhere downstream.
        expect(draught.effect.healFor(), 320);
        // ⭐ §3.3's ladder tops out here. Nothing shipped heals more.
        final biggest = ItemCatalogue.all
            .whereType<Usable>()
            .map((d) => d.effect.healFor())
            .reduce((a, b) => a > b ? a : b);
        expect(
          biggest,
          320,
          reason: 'something out-heals the ladder\'s own top rung',
        );
        expect(
          draught.value,
          lessThan(4 * UnwrittenLibraryItems.nightink.value),
          reason: 'buy→craft→vendor must not profit (§5.4)',
        );
      },
    );

    test('⚠️ blankspine_vellum is a hide, so no node may ever yield it', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('blankspine_vellum')),
        reason:
            'a blankspine is a vellum is a hide (§3.1); a node for it would '
            'be a second source that contradicts its own fiction',
      );
      // ⭐ It is the zone's `hide` drop role, and §3.5.1's second-material
      // fallback therefore does NOT apply here.
      expect(
        UnwrittenLibraryItems.blankspineVellum.skill,
        CraftSkill.tailoring,
      );
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('two nodes — the third material is a kill-only hide', () {
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id).toSet(), {
        'ul_nightink_well',
        'ul_colophon_shelf',
      });
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} compiles but never spawns',
        );
      }
    });

    test('every node yields a real material THIS zone defines', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(def, isA<MaterialDef>());
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields a non-stackable',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} harvests another zone\'s material',
        );
        expect(n.min, greaterThan(1));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node skill follows the material\'s consuming skill (§6a.1)', () {
      // ⭐ Potions ← Foraging, Jewelry (gems) ← Mining. A node that pays the
      // wrong ledger row levels a skill the material never feeds.
      expect(GatherNodes.ulNightinkWell.skill, GatherSkill.foraging);
      expect(GatherNodes.ulColophonShelf.skill, GatherSkill.mining);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 115);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final colophon = UnwrittenLibraryBestiary.colophon;
      final record = UnwrittenLibraryBestiary.theRecord;
      expect(
        colophon.maxHpAt(58),
        (MageState.scaledMaxHp(58) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        colophon.maxHpAt(58),
        2057,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        record.maxHpAt(58),
        (MageState.scaledMaxHp(58) * Archetypes.juggernaut.hpScale).round(),
      );
      expect(record.maxHpAt(58), 3366);
      expect(UnwrittenLibraryBestiary.theAuthor.maxHpAt(58), 2431);
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 54. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(54);
      expect(startingHp, 799);
      for (final e in UnwrittenLibraryBestiary.commons) {
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

    test('every item carries lore that is not a stat line', () {
      for (final def in UnwrittenLibraryItems.all) {
        expect(
          def.lore.endsWith('.'),
          isTrue,
          reason: '${def.id} lore is not a sentence',
        );
        expect(
          RegExp(r'\d').hasMatch(def.lore),
          isFalse,
          reason: '${def.id} lore leaks a number instead of describing a thing',
        );
        expect(def.lore.length, greaterThan(40), reason: '${def.id} lore thin');
      }
    });
  });
}
