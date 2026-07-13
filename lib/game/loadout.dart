import 'package:mom_engine/mom_engine.dart';

/// What the player brings into a duel. Slots are ORDERED — keyboard
/// shortcuts bind to slot positions (1-8 for elements, QWERT/ASDFG for
/// spells), not to specific elements/spells. Later, slots themselves are
/// unlocked via leveling.
class Loadout {
  /// Element slots, up to 8. Key "1" activates slot 1 (index 0), etc.
  final List<MagicElement> elements;

  /// Spell slots, up to 10. QWERT = slots 1-5, ASDFG = slots 6-10.
  final List<Spell> spells;

  const Loadout({required this.elements, required this.spells});

  static const int maxElementSlots = 8;
  static const int maxSpellSlots = 10;

  /// Default starter kit: every element, and a rounded spell selection.
  static final Loadout starter = Loadout(
    elements: List.of(MagicElement.values),
    spells: [
      Spellbook.flick,
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.jolt,
      Spellbook.flurry,
      Spellbook.sap,
      Spellbook.ward,
      Spellbook.bulwark,
      Spellbook.empower,
      Spellbook.cataclysm,
    ],
  );
}
