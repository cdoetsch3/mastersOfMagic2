import 'package:mom_engine/mom_engine.dart';

/// One loadout slot: an element **or** a spell, never both.
///
/// Elements and spells draw from a single shared pool, so the two are the same
/// kind of thing as far as capacity is concerned — see [Loadout].
class LoadoutSlot {
  final MagicElement? element;
  final Spell? spell;

  const LoadoutSlot.element(MagicElement this.element) : spell = null;
  const LoadoutSlot.spell(Spell this.spell) : element = null;

  bool get isElement => element != null;
  bool get isSpell => spell != null;

  /// Stable identifier for saving — element names and spell ids share a
  /// namespace check in [Loadout.fromIds].
  String get id => element?.name ?? spell!.id;

  @override
  bool operator ==(Object other) =>
      other is LoadoutSlot &&
      other.element == element &&
      other.spell?.id == spell?.id;

  @override
  int get hashCode => Object.hash(element, spell?.id);
}

/// What the player brings into a duel: **one ordered pool of slots**, each
/// holding an element or a spell.
///
/// ⭐ The single pool is the point. Elements and spells compete for the same
/// capacity, so "do I want a fourth element or a tenth spell?" is a real
/// strategic choice rather than two independent budgets. [elements] and
/// [spells] are *views* over [slots], not separate storage — nothing can drift
/// out of sync because there is only one source of truth.
///
/// Slots are ORDERED: keyboard shortcuts bind to position within each view
/// (1-8 for elements, QWERT/ASDFG for spells), not to specific
/// elements/spells.
class Loadout {
  /// The one true collection. Order is preserved as authored.
  final List<LoadoutSlot> slots;

  const Loadout.fromSlots(this.slots);

  /// Convenience constructor for the common "these elements, these spells"
  /// shape. Concatenates into the shared pool, elements first.
  Loadout({
    required List<MagicElement> elements,
    required List<Spell> spells,
  }) : slots = [
          ...elements.map(LoadoutSlot.element),
          ...spells.map(LoadoutSlot.spell),
        ];

  /// Element slots, in pool order. Key "1" activates the first (index 0).
  List<MagicElement> get elements =>
      [for (final s in slots) if (s.element != null) s.element!];

  /// Spell slots, in pool order. QWERT = 1-5, ASDFG = 6-10.
  List<Spell> get spells =>
      [for (final s in slots) if (s.spell != null) s.spell!];

  /// Slots filled, counting elements and spells alike.
  int get slotsUsed => slots.length;

  // ---- Capacity ------------------------------------------------------
  //
  // See Progression.slotsAtLevel for the 5 -> 15 curve. These are the ceilings
  // the UI must be able to draw, not what any given player has unlocked.

  /// The most slots any player can reach: 15 from levelling + 5 from equipment.
  static const int maxSlots = 20;

  /// Per-kind ceilings the *arena* must still respect — the duel screen has
  /// only 8 element keys and 10 spell keys, so even a 20-slot pool cannot be
  /// spent entirely on one kind.
  static const int maxElementSlots = 8;
  static const int maxSpellSlots = 10;

  /// Default starter kit: every element, and a rounded spell selection.
  ///
  /// ⚠️ Deliberately over the level curve — level gating is intentionally the
  /// *last* thing to be enforced so playtesting has everything available
  /// (PROGRESSION_DESIGN §"Slot pool").
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

  /// Rebuilds a pool from saved ids, skipping anything unrecognised. Ids are
  /// resolved as elements first, then spells.
  static Loadout fromIds(Iterable<String> ids) {
    final slots = <LoadoutSlot>[];
    for (final id in ids) {
      final element =
          MagicElement.values.where((e) => e.name == id).firstOrNull;
      if (element != null) {
        slots.add(LoadoutSlot.element(element));
        continue;
      }
      final spell = Spellbook.all.where((s) => s.id == id).firstOrNull;
      if (spell != null) slots.add(LoadoutSlot.spell(spell));
    }
    return Loadout.fromSlots(slots);
  }

  /// Ids in pool order, for saving.
  List<String> toIds() => [for (final s in slots) s.id];
}
