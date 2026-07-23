import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:mom_engine/mom_engine.dart';

/// The V2 roster renamed `radiant` → `sanctus`. Saves written before that
/// rename still carry the old id, and a save must never be able to crash the
/// app on load — it degrades, visibly.
void main() {
  group('LoadoutPreset tolerates stale element ids', () {
    test('a pre-rename save loads instead of throwing', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'Old save',
        'elementIds': ['pyro', 'radiant', 'aqua'],
        'spellIds': ['flick'],
      });

      expect(preset.elements, [MagicElement.pyro, MagicElement.aqua]);
      expect(preset.unknownElementIds, ['radiant']);
    });

    test('unknown ids are reported, not silently swallowed', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'Ancient save',
        'elementIds': ['fire', 'water', 'ice', 'flora'],
        'spellIds': ['flick'],
      });

      expect(preset.elements, [MagicElement.flora]);
      expect(preset.unknownElementIds, ['fire', 'water', 'ice']);
    });

    test('a healthy save reports nothing unknown', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'Current',
        'elementIds': ['solar', 'lunar', 'astral'],
        'spellIds': ['flick'],
      });

      expect(preset.elements,
          [MagicElement.solar, MagicElement.lunar, MagicElement.astral]);
      expect(preset.unknownElementIds, isEmpty);
    });

    test('every element name round-trips through a save', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'All twelve',
        'elementIds': MagicElement.values.map((e) => e.name).toList(),
        'spellIds': ['flick'],
      });

      expect(preset.elements, MagicElement.values);
      expect(preset.unknownElementIds, isEmpty);
    });
  });

  group('LoadoutPreset tolerates stale spell ids too', () {
    test('an unknown spell id is dropped, not thrown on', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'Save with a removed spell',
        'elementIds': ['pyro'],
        'spellIds': ['flick', 'fireball', 'bolt'], // fireball never existed
      });

      expect(preset.spells.map((s) => s.id), ['flick', 'bolt']);
      expect(preset.unknownSpellIds, ['fireball']);
      expect(preset.hasUnknownIds, isTrue);
    });

    test('a clean preset reports no unknown ids', () {
      final preset = LoadoutPreset.fromJson({
        'name': 'Current',
        'elementIds': ['solar'],
        'spellIds': ['flick', 'hallow'],
      });

      expect(preset.unknownSpellIds, isEmpty);
      expect(preset.hasUnknownIds, isFalse);
    });
  });
}
