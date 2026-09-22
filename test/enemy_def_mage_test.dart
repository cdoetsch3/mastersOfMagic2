/// [EnemyDef.isMage] — the game-wide law on the newest field.
///
/// ⭐ **A mage brings a Spellbook loadout, not a creature kit** (ENEMIES §3.4).
/// The flag is a licence off three creature laws — the archetype's move count
/// and cost band, the zone move-id prefix, and the contract's raw-damage
/// ceiling — so ⚠️ **the dangerous mutation is not setting it wrongly on a
/// mage; it is setting it quietly on a creature**, which switches those three
/// laws off in whichever zone test enforces them.
///
/// ⭐ This file is therefore the one place the whole bestiary is swept: a new
/// zone that defaults a creature to `isMage: true` fails HERE even if its own
/// test never thought to look.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_collapsed_academy.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⭐ Every creature in the game that is a MAGE, by id. ⚠️ Adding a row here
/// is a design decision (ENEMIES §3.4 names exactly two candidates — the
/// Archmage and Procarius), not a way to make this file go green.
const _knownMages = <String>{'the_archmage', 'procarius_the_eclipsed'};

void main() {
  test('isMage defaults false for every shipped creature but the mages', () {
    final mages = Bestiary.all.where((e) => e.isMage).map((e) => e.id).toSet();
    expect(
      mages,
      _knownMages,
      reason:
          'a creature picked up isMage, which silently exempts it from its '
          'zone test\'s move-count, prefix and raw-damage laws',
    );
  });

  test('the default really is false, not merely unset everywhere', () {
    // ⚠️ Kills the mutant that flips the default: every zone omitting the
    // argument would then become a roster of mages, and the sweep above would
    // still pass if it had been written as "the mages are among them".
    const plain = EnemyDef(
      id: 'x',
      name: 'X',
      zoneId: 'x',
      rank: EnemyRank.common,
      archetype: Archetypes.adept,
      elements: [MagicElement.arcane],
      lore: 'A control creature that exists only inside this test.',
      moves: [],
    );
    expect(plain.isMage, isFalse);
  });

  test('a mage\'s moves are Spellbook objects; a creature\'s never are', () {
    // ⭐ The law the flag BUYS, swept game-wide: the exemption is only
    // defensible because the Spellbook answers the same questions its own
    // way. A mage whose moves were hand-authored would be exempt from
    // everything and bound by nothing.
    final book = {for (final s in Spellbook.all) s.id: s};
    for (final e in Bestiary.all) {
      for (final m in e.moves) {
        if (e.isMage) {
          expect(
            book[m.id],
            same(m),
            reason: '${e.id} is a mage but "${m.name}" is not in Spellbook.all',
          );
        } else {
          expect(
            book.containsKey(m.id),
            isFalse,
            reason: '${e.id} is a creature but "${m.name}" is a player spell',
          );
        }
      }
    }
  });

  test('the Archmage is the mage this field was added for', () {
    expect(CollapsedAcademyBestiary.theArchmage.isMage, isTrue);
    expect(
      CollapsedAcademyBestiary.theLastThreeItems.isMage,
      isFalse,
      reason: 'its boss partner is a syllabus, not a scholar',
    );
  });
}
