import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';
import 'progression.dart';
import 'world.dart';

/// Every valid element id, for validating ids read off disk.
final Set<String> _elementNames =
    MagicElement.values.map((e) => e.name).toSet();

/// Every valid spell id, for the same disk-validation of stale saves.
final Set<String> _spellIds = Spellbook.all.map((s) => s.id).toSet();

/// A saved loadout: ordered element and spell slots by id. Persisted as part
/// of the player document; converts to a runtime [Loadout] for combat.
///
/// ⭐ Capacity is a **single shared pool** — see [slotsUsed]. The wire format
/// keeps two id lists only for backward compatibility with saves written before
/// the pools merged; it is a storage detail, not two separate budgets.
class LoadoutPreset {
  String name;
  List<String> elementIds;
  List<String> spellIds;

  LoadoutPreset({
    required this.name,
    required this.elementIds,
    required this.spellIds,
  });

  factory LoadoutPreset.starter(String name) => LoadoutPreset(
        name: name,
        elementIds: List.of(Progression.starterPresetElementIds),
        spellIds: List.of(Progression.starterPresetSpellIds),
      );

  /// Slots this preset fills, elements and spells counted alike — the pool is
  /// shared, so a fourth element costs what a tenth spell would have.
  int get slotsUsed => elementIds.length + spellIds.length;

  /// Truncates to the current caps (used to migrate saves made when the caps
  /// were larger). Clamps the per-kind *arena* limits first — the duel screen
  /// has a fixed number of shortcut keys — then the shared pool, trimming
  /// spells before elements since elements are the scarcer, more foundational
  /// pick.
  ///
  /// [slotBudget] defaults to the absolute ceiling, which with per-kind limits
  /// of 8 and 10 can never actually bite (8 + 10 = 18 < 20). It becomes the
  /// binding constraint once level gating turns on, at which point callers pass
  /// `Progression.usableSlotsAtLevel(level)`. Taking it as a parameter now means
  /// that switch is a one-line change at the call site rather than a rewrite.
  void clampToCaps({int slotBudget = Loadout.maxSlots}) {
    if (elementIds.length > Loadout.maxElementSlots) {
      elementIds = elementIds.sublist(0, Loadout.maxElementSlots);
    }
    if (spellIds.length > Loadout.maxSpellSlots) {
      spellIds = spellIds.sublist(0, Loadout.maxSpellSlots);
    }
    var overflow = slotsUsed - slotBudget;
    if (overflow <= 0) return;

    final spellsToDrop = overflow.clamp(0, spellIds.length);
    spellIds = spellIds.sublist(0, spellIds.length - spellsToDrop);
    overflow -= spellsToDrop;
    if (overflow > 0) {
      elementIds = elementIds.sublist(0, elementIds.length - overflow);
    }
  }

  /// Element ids that no longer name a real element — e.g. `radiant`, renamed
  /// to `sanctus` in the V2 roster change, or the pre-9-element names. Exposed
  /// so the UI can tell a player their preset lost a slot instead of silently
  /// shrinking it.
  List<String> get unknownElementIds =>
      elementIds.where((id) => !_elementNames.contains(id)).toList();

  /// Spell ids that no longer name a real spell (a removed or renamed spell in
  /// an old save). Same purpose as [unknownElementIds].
  List<String> get unknownSpellIds =>
      spellIds.where((id) => !_spellIds.contains(id)).toList();

  /// True when this preset carries any id that no longer resolves — the one
  /// call the UI needs to decide whether to warn the player about a stale save.
  bool get hasUnknownIds =>
      unknownElementIds.isNotEmpty || unknownSpellIds.isNotEmpty;

  /// Elements this preset resolves to. ⚠️ **Unknown ids are dropped, not
  /// thrown on** — a stale save must never crash the app on load. See
  /// [unknownElementIds] to detect that it happened.
  List<MagicElement> get elements => elementIds
      .where(_elementNames.contains)
      .map(MagicElement.values.byName)
      .toList();

  /// Spells this preset resolves to. Unknown ids are dropped, not thrown on —
  /// symmetric with [elements]; see [unknownSpellIds].
  List<Spell> get spells =>
      spellIds.where(_spellIds.contains).map(Spellbook.byId).toList();

  Loadout toLoadout() => Loadout(elements: elements, spells: spells);

  bool get isValid => elementIds.isNotEmpty && spellIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'elementIds': elementIds,
        'spellIds': spellIds,
      };

  factory LoadoutPreset.fromJson(Map<String, dynamic> json) => LoadoutPreset(
        name: json['name'] as String? ?? 'Loadout',
        elementIds:
            (json['elementIds'] as List?)?.cast<String>().toList() ?? [],
        spellIds: (json['spellIds'] as List?)?.cast<String>().toList() ?? [],
      );
}

/// The player's persistent save. One-to-one with a future Firestore document
/// at `players/{uid}` — every field serializes to a plain JSON value.
class PlayerProfile {
  String name;
  int xp;
  int gold;

  /// Premium currency (from microtransactions eventually).
  int gems;

  String locationId;

  /// Locations the player has visited (unlocks fast context; travel itself is
  /// still gated by the connection graph).
  Set<String> discoveredLocationIds;

  List<LoadoutPreset> presets;
  int activePresetIndex;

  /// Inventory is intentionally empty in Phase 1 (Phase 2: items + crafting).
  /// Shaped as id -> quantity so it maps cleanly to a Firestore map.
  Map<String, int> inventory;

  int duelsWon;
  int duelsLost;

  /// When this player was last active, for the friends list's presence dot.
  /// Refreshed whenever the save is written, so it tracks real activity rather
  /// than merely having the app open. Null for a save from before presence
  /// existed — treated as "unknown", not "offline forever".
  DateTime? lastSeenAt;

  PlayerProfile({
    required this.name,
    this.lastSeenAt,
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    String? locationId,
    Set<String>? discoveredLocationIds,
    List<LoadoutPreset>? presets,
    this.activePresetIndex = 0,
    Map<String, int>? inventory,
    this.duelsWon = 0,
    this.duelsLost = 0,
  })  : locationId = locationId ?? World.startLocationId,
        discoveredLocationIds =
            discoveredLocationIds ?? {World.startLocationId},
        presets = presets ?? [LoadoutPreset.starter('Loadout I')],
        inventory = inventory ?? {};

  factory PlayerProfile.newPlayer({String name = 'Apprentice'}) =>
      PlayerProfile(name: name);

  // ---- Derived ---------------------------------------------------------

  int get level => Progression.levelForXp(xp);
  int get xpIntoLevel => Progression.xpIntoLevel(xp);
  int get xpForThisLevel => Progression.xpToNext(level);
  int get unlockedPresetSlots => Progression.presetSlotsAtLevel(level);

  GameLocation get location => World.byId(locationId);

  /// Repairs a save written against an older map.
  ///
  /// The Plate I-b rebuild renamed and removed regions (`radiant_sanctum`,
  /// `the_caldera`, `crystal_caverns`, `nightfen_marsh`). Without this, an old
  /// save keeps an id that no longer resolves: [location] silently falls back
  /// to the start town while [locationId] still reads as the dead region, and
  /// the two disagree until the player happens to travel.
  ///
  /// Returns true if anything was changed, so callers can note the reset.
  bool migrateWorld() {
    var changed = false;
    if (!World.exists(locationId)) {
      locationId = World.startLocationId;
      changed = true;
    }
    final live = discoveredLocationIds.where(World.exists).toSet();
    if (live.length != discoveredLocationIds.length) {
      discoveredLocationIds = live;
      changed = true;
    }
    // Never leave the player with nowhere discovered.
    if (discoveredLocationIds.add(locationId)) changed = true;
    return changed;
  }

  LoadoutPreset get activePreset =>
      presets[activePresetIndex.clamp(0, presets.length - 1)];

  bool isSpellUnlocked(Spell spell) =>
      Progression.isSpellUnlockedAt(spell, level);

  bool isElementUnlocked(MagicElement element) =>
      Progression.isElementUnlockedAt(element, level);

  // ---- Serialization ---------------------------------------------------

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastSeenAt': lastSeenAt?.toUtc().toIso8601String(),
        'xp': xp,
        'gold': gold,
        'gems': gems,
        'locationId': locationId,
        'discoveredLocationIds': discoveredLocationIds.toList(),
        'presets': presets.map((p) => p.toJson()).toList(),
        'activePresetIndex': activePresetIndex,
        'inventory': inventory,
        'duelsWon': duelsWon,
        'duelsLost': duelsLost,
        'schemaVersion': 1,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final presets = (json['presets'] as List?)
            ?.map((p) => LoadoutPreset.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [LoadoutPreset.starter('Loadout I')];
    return PlayerProfile(
      name: json['name'] as String? ?? 'Apprentice',
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '')?.toLocal(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      locationId: json['locationId'] as String?,
      discoveredLocationIds:
          (json['discoveredLocationIds'] as List?)?.cast<String>().toSet(),
      presets: presets,
      activePresetIndex: (json['activePresetIndex'] as num?)?.toInt() ?? 0,
      inventory: (json['inventory'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ) ??
          {},
      duelsWon: (json['duelsWon'] as num?)?.toInt() ?? 0,
      duelsLost: (json['duelsLost'] as num?)?.toInt() ?? 0,
    );
  }
}
