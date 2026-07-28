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

  group('Photosynthesis text matches the streak-gated mechanic', () {
    // ⚠️ This class of drift already bit us: the effect was rewritten from
    // per-cast stacking to a 5-cast streak gate, and every tooltip, the
    // element sheet and the status catalogue still described stacks. The
    // name-matching test above passes either way, so it caught nothing.

    String floraText() {
      final lore = elementLore[MagicElement.flora]!;
      final info = StatusCatalog.byId('photosynthesis')!;
      return '${lore.description} ${lore.trigger} ${lore.beatsEffect} '
              '${lore.weakEffect} ${info.description} ${info.trigger}'
          .toLowerCase();
    }

    test('no Photosynthesis text still talks about stacks', () {
      expect(floraText(), isNot(contains('stack')),
          reason: 'Photosynthesis has no stacks — it is on or off');
    });

    test('the text states the real streak threshold', () {
      final threshold = PhotosynthesisStatus.streakThreshold;
      expect(threshold, 5);
      expect(floraText(), contains('5'),
          reason: 'the player must be told how many casts it takes');
    });

    test('the text states the real heal rate', () {
      expect(PhotosynthesisStatus.healPercent, 1);
      expect(floraText(), contains('1%'),
          reason: 'the heal rate in the tooltip must match the engine');
    });

    test('Pyro and Aqua describe their Flora interactions correctly', () {
      // Ignite breaks the STREAK now, and a bloom (not a stack) blocks
      // Waterlogged.
      final pyro = elementLore[MagicElement.pyro]!.beatsEffect.toLowerCase();
      expect(pyro, contains('streak'),
          reason: 'Ignite breaks the streak, not stacks: "$pyro"');

      final aqua = elementLore[MagicElement.aqua]!.weakEffect.toLowerCase();
      expect(aqua, isNot(contains('stack')), reason: aqua);
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
