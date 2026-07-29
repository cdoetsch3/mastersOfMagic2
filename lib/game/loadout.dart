import 'package:mom_engine/mom_engine.dart';

/// What the player brings into a duel: **a pool of elements and a separate
/// pool of spells.**
///
/// ⭐ The two pools are firmly separate, and small on purpose. A duel is partly
/// about reading your opponent — what they might charge, what they might cast —
/// and that only works if the set they can draw from is legible. Five elements
/// and ten spells is a knowable hand; a single merged pool of twenty was not.
/// (This reverts an earlier experiment that merged them into one budget; the
/// flexibility cost more counterplay than it bought.)
///
/// Both pools are ORDERED: keyboard shortcuts bind to position (1-5 for
/// elements, QWERT/ASDFG for spells), not to specific elements or spells.
class Loadout {
  /// Element slots, in order. Key "1" activates the first.
  final List<MagicElement> elements;

  /// Spell slots, in order. QWERT = 1-5, ASDFG = 6-10.
  final List<Spell> spells;

  const Loadout({required this.elements, required this.spells});

  // ---- Capacity ------------------------------------------------------
  //
  // ⭐ Two independent caps, never a shared budget. A fourth element does not
  // cost a tenth spell — they are different resources. See Progression for the
  // per-pool unlock schedules (gating not yet enforced).

  /// The most elements a loadout can hold. Also the number of element
  /// shortcut keys the arena binds (1-5).
  static const int maxElementSlots = 5;

  /// The most spells a loadout can hold. Also the number of spell shortcut
  /// keys the arena binds (QWERT + ASDFG).
  static const int maxSpellSlots = 10;

  /// Default starter kit: a rounded five elements and ten spells.
  ///
  /// ⚠️ Deliberately fills both pools to the cap while level gating is off, so
  /// playtesting has a full hand available. The per-pool *unlock schedule*
  /// (PROGRESSION_DESIGN §"Slot pool") does not bind until gating turns on,
  /// which is one of the last things before v1.
  static final Loadout starter = Loadout(
    elements: const [
      MagicElement.pyro,
      MagicElement.aqua,
      MagicElement.flora,
      MagicElement.electro,
      MagicElement.geo,
    ],
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

  /// Rebuilds a loadout from saved ids, skipping anything unrecognised.
  static Loadout fromIds({
    required Iterable<String> elementIds,
    required Iterable<String> spellIds,
  }) {
    final elements = <MagicElement>[];
    for (final id in elementIds) {
      final e = MagicElement.values.where((e) => e.name == id).firstOrNull;
      if (e != null) elements.add(e);
    }
    final spells = <Spell>[];
    for (final id in spellIds) {
      final s = Spellbook.all.where((s) => s.id == id).firstOrNull;
      if (s != null) spells.add(s);
    }
    return Loadout(elements: elements, spells: spells);
  }

  List<String> elementIds() => [for (final e in elements) e.name];
  List<String> spellIds() => [for (final s in spells) s.id];
}
