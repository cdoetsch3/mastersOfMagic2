import 'package:masters_of_magic_2/game/element_lore.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';

/// Player-facing text drifts from the rules every time a number changes — the
/// lifesteal nerf, the Astral rework and the Radiant→Sanctus rename each left
/// tooltips claiming things the engine no longer did. These check the text
/// against the data rather than against a memory of it.
void main() {
  group('every spell is described', () {
    test('has flavour text', () {
      for (final spell in Spellbook.all) {
        expect(spellDescriptions[spell.id], isNotNull,
            reason: '${spell.name} has no description');
        expect(spellDescriptions[spell.id]!.length, greaterThan(15),
            reason: '${spell.name} description is a stub');
      }
    });

    test('has an icon', () {
      for (final spell in Spellbook.all) {
        expect(spellIcons[spell.id], isNotNull,
            reason: '${spell.name} has no icon');
      }
    });

    test('no description is orphaned', () {
      final ids = Spellbook.all.map((s) => s.id).toSet();
      for (final id in spellDescriptions.keys) {
        expect(ids, contains(id), reason: "'$id' is described but not a spell");
      }
    });

    test('the generated tooltip quotes the real numbers', () {
      for (final spell in Spellbook.all) {
        final tip = spellTooltip(spell);
        expect(tip, contains(spell.name));
        if (spell.effect case DamageEffect(:final minAmount, :final maxAmount)) {
          expect(tip, contains('$minAmount-$maxAmount'),
              reason: '${spell.name} tooltip must show its real damage');
        }
      }
    });
  });

  group('lifesteal text matches the actual rate', () {
    test('the tooltip states the true percentage', () {
      for (final spell in Spellbook.all) {
        if (spell.effect case DamageEffect(:final lifesteal)
            when lifesteal > 0) {
          final percent = (lifesteal * 100).round();
          expect(spellTooltip(spell), contains('$percent%'),
              reason: '${spell.name} must say it heals $percent%');
        }
      }
    });

    test('no lifesteal blurb still claims a full steal', () {
      // The old copy said "equal to health damage dealt" / "wholesale".
      for (final spell in Spellbook.all) {
        if (spell.effect case DamageEffect(:final lifesteal)
            when lifesteal > 0 && lifesteal < 1) {
          final blurb = spellDescriptions[spell.id]!.toLowerCase();
          expect(blurb, isNot(contains('equal to')),
              reason: '${spell.name} implies a 1:1 steal');
          expect(blurb, isNot(contains('wholesale')),
              reason: '${spell.name} implies a full steal');
        }
      }
    });
  });

  group('element lore', () {
    test('covers every element', () {
      for (final element in MagicElement.values) {
        final lore = elementLore[element];
        expect(lore, isNotNull, reason: '${element.name} has no lore');
        expect(lore!.description.length, greaterThan(40), reason: element.name);
        expect(lore.trigger, isNotEmpty, reason: element.name);
      }
    });

    test('names the effect the status catalogue names', () {
      // Where an element's effect is a catalogued status, the two must agree —
      // otherwise the guide and the element sheet describe it differently.
      const pairs = {
        MagicElement.pyro: 'ignite',
        MagicElement.flora: 'photosynthesis',
        MagicElement.aqua: 'waterlogged',
        MagicElement.geo: 'stagger',
        MagicElement.solar: 'blind',
        MagicElement.astral: 'astralAlignment',
        MagicElement.umbra: 'creepingDark',
        MagicElement.arcane: 'arcaneKnowledge',
      };
      pairs.forEach((element, statusId) {
        final info = StatusCatalog.byId(statusId)!;
        final loreName = elementLore[element]!.effectName.toLowerCase();
        expect(loreName, info.name.toLowerCase(),
            reason: '${element.name}: lore calls it "$loreName", the '
                'catalogue calls it "${info.name}"');
      });
    });
  });

  group('every element sheet quotes the engine\'s real numbers', () {
    // ⚠️ This class of drift already bit us. Photosynthesis was reworked from
    // per-cast stacking to a 5-cast streak gate, and every tooltip still
    // described stacks — while this file passed, because the only cross-check
    // was that the effect NAME matched the catalogue. A name test cannot see a
    // mechanic change.
    //
    // Now every number a player is told comes from [ElementTuning], which the
    // engine itself reads. Change a value there and this fails until the text
    // is updated with it.

    String sheetFor(MagicElement e) {
      final lore = elementLore[e]!;
      return '${lore.description} ${lore.trigger} ${lore.beatsEffect} '
          '${lore.weakEffect}';
    }

    /// True when [n] appears in [text] as a standalone number — so 5 does not
    /// match the 5 inside 50 or 15.
    bool quotes(String text, int n) =>
        RegExp('(?<![0-9])$n(?![0-9])').hasMatch(text);

    // Every numeric claim each element sheet must make, sourced from the
    // engine rather than retyped.
    final claims = <MagicElement, Map<String, int>>{
      MagicElement.pyro: {
        'proc chance': ElementTuning.ignitePercent,
        'burn share': ElementTuning.igniteBurnPercentOfDamage,
        'tick count': ElementTuning.igniteTicks,
      },
      MagicElement.aqua: {
        'cast cadence': ElementTuning.waterloggedEveryNthCast,
        'priority penalty': ElementTuning.waterloggedPriorityPenalty,
      },
      MagicElement.flora: {
        'streak length': ElementTuning.photosynthesisStreak,
        'heal percent': ElementTuning.photosynthesisHealPercent,
      },
      MagicElement.electro: {
        'proc chance': ElementTuning.staticFeedbackPercent,
      },
      MagicElement.aero: {
        'streak length': ElementTuning.tailwindStreak,
      },
      MagicElement.geo: {
        'cast cadence': ElementTuning.staggerEveryNthCast,
        'damage share': ElementTuning.staggerDamagePercent,
      },
      MagicElement.solar: {
        'chance per charge': ElementTuning.blindPercentPerCharge,
        'miss chance': ElementTuning.blindMissPercent,
        'duration': ElementTuning.blindTurns,
      },
      MagicElement.lunar: {
        'cycle length': ElementTuning.moonCycleTurns,
        'full moon bonus': ElementTuning.lunarFullMoonBonusPercent,
      },
      MagicElement.astral: {
        'stack ceiling': ElementTuning.alignmentMaxStacks,
        'pierce per stack': ElementTuning.alignmentPercentPerStack,
      },
      MagicElement.sanctus: {
        'cast cadence': ElementTuning.absolutionEveryNthCast,
        'dark seared': ElementTuning.absolutionSearsDark,
      },
      MagicElement.umbra: {
        'stack ceiling': ElementTuning.creepingDarkMaxStacks,
        'shadow threshold': ElementTuning.shadowThreshold,
        'dusk threshold': ElementTuning.duskThreshold,
      },
      MagicElement.arcane: {
        'min charge': ElementTuning.arcaneKnowledgeMinCharge,
        'stack ceiling': ElementTuning.arcaneKnowledgeMaxStacks,
      },
    };

    test('all twelve elements are covered', () {
      expect(claims.keys.toSet(), MagicElement.values.toSet(),
          reason: 'a new element needs its numbers guarded too');
    });

    for (final entry in claims.entries) {
      test('${entry.key.name} states its real numbers', () {
        final sheet = sheetFor(entry.key);
        entry.value.forEach((label, value) {
          expect(quotes(sheet, value), isTrue,
              reason: '${entry.key.name}: the sheet never mentions $value '
                  '($label). Either the engine changed or the text is stale.\n'
                  'Sheet: $sheet');
        });
      });
    }

    test('Photosynthesis text no longer talks about stacks', () {
      // The specific regression that started all this.
      final text = '${sheetFor(MagicElement.flora)} '
              '${StatusCatalog.byId('photosynthesis')!.description}'
          .toLowerCase();
      expect(text, isNot(contains('stack')),
          reason: 'Photosynthesis has no stacks — it is in bloom or it is not');
    });

    test('the Flora interactions on Pyro and Aqua match the new mechanic', () {
      expect(elementLore[MagicElement.pyro]!.beatsEffect.toLowerCase(),
          contains('streak'),
          reason: 'Ignite breaks the streak now, not stacks');
      expect(elementLore[MagicElement.aqua]!.weakEffect.toLowerCase(),
          isNot(contains('stack')));
    });
  });

  group('no player-facing text references removed concepts', () {
    // Sentinels for renames that already bit us once.
    const gone = ['radiant', 'ice ', 'holy'];

    test('spell descriptions are clean', () {
      for (final entry in spellDescriptions.entries) {
        final text = entry.value.toLowerCase();
        for (final word in gone) {
          expect(text, isNot(contains(word)),
              reason: "'${entry.key}' mentions removed concept '$word'");
        }
      }
    });

    test('element lore is clean', () {
      for (final entry in elementLore.entries) {
        final text = '${entry.value.description} ${entry.value.trigger} '
                '${entry.value.beatsEffect} ${entry.value.weakEffect}'
            .toLowerCase();
        for (final word in gone) {
          expect(text, isNot(contains(word)),
              reason: "${entry.key.name} lore mentions '$word'");
        }
      }
    });

    test('the status catalogue is clean', () {
      for (final info in StatusCatalog.all) {
        final text = '${info.description} ${info.trigger}'.toLowerCase();
        for (final word in gone) {
          expect(text, isNot(contains(word)),
              reason: "'${info.id}' mentions '$word'");
        }
      }
    });
  });
}
