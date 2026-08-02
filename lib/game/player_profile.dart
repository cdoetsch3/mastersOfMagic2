import 'package:mom_engine/mom_engine.dart';

import 'items/inventory.dart';
import 'items/item_instance.dart';

import 'loadout.dart';
import 'progression.dart';
import 'active_trip.dart';
import 'world.dart';

/// Every valid element id, for validating ids read off disk.
final Set<String> _elementNames = MagicElement.values
    .map((e) => e.name)
    .toSet();

/// Every valid spell id, for the same disk-validation of stale saves.
final Set<String> _spellIds = Spellbook.all.map((s) => s.id).toSet();

/// A saved loadout: ordered element and spell ids. Persisted as part of the
/// player document; converts to a runtime [Loadout] for combat.
///
/// ⭐ Elements and spells are **two separate pools**, each with its own cap
/// (5 and 10). Filling one has no effect on the other.
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

  int get elementCount => elementIds.length;
  int get spellCount => spellIds.length;

  /// Truncates each pool to its own cap. Migrates saves written when the pools
  /// were merged and either could run larger — a preset with 8 elements, say,
  /// loses the last three rather than crashing on load.
  ///
  /// [elementBudget]/[spellBudget] default to the absolute ceilings; callers
  /// pass `Progression.usableElementsAtLevel(level)` and the spell equivalent
  /// once level gating turns on, so that switch stays a one-line change.
  void clampToCaps({
    int elementBudget = Loadout.maxElementSlots,
    int spellBudget = Loadout.maxSpellSlots,
  }) {
    if (elementIds.length > elementBudget) {
      elementIds = elementIds.sublist(0, elementBudget);
    }
    if (spellIds.length > spellBudget) {
      spellIds = spellIds.sublist(0, spellBudget);
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
    elementIds: (json['elementIds'] as List?)?.cast<String>().toList() ?? [],
    spellIds: (json['spellIds'] as List?)?.cast<String>().toList() ?? [],
  );
}

/// The player's persistent save. One-to-one with a future Firestore document
/// at `players/{uid}` — every field serializes to a plain JSON value.
class PlayerProfile {
  String name;
  int xp;
  int gold;

  /// **Resonance Prisms ("RP")** — the premium currency, from
  /// microtransactions eventually. Time Crystals are *crafted from* RP; they
  /// are not the same thing (ITEMS_DESIGN §6d.1).
  ///
  /// Renamed from `gems`, which collided with equipment gem sockets and the
  /// Concordant Crown's twelve elemental gems.
  int resonancePrisms;

  String locationId;

  /// The journey in progress, if any.
  ///
  /// ⚠️ While this is set, [locationId] is where the trip **began**, not where
  /// the player is. Ask [ActiveTrip.stopReachedAt] for that — the answer
  /// depends on the clock, so it cannot be a stored field.
  ActiveTrip? trip;

  /// Locations the player has visited (unlocks fast context; travel itself is
  /// still gated by the connection graph).
  Set<String> discoveredLocationIds;

  /// How many times this character has beaten each zone's **boss**.
  ///
  /// ⚠️ **Not the same as [discoveredLocationIds]** — walking somewhere is not
  /// clearing it, and the two must never be conflated. Discovery is about the
  /// map; this is about the bestiary.
  ///
  /// ⭐ **A count, not a flag**, because two separate features need the number:
  /// ACHIEVEMENTS §2.3 tracks `clearCount` per zone, and ENEMIES §2e's
  /// repeat-clear encounters ask "has this character been here before".
  /// `cleared` is derivable from the count; the count is not derivable from a
  /// flag.
  ///
  /// ⭐ **Per character, not per account.** Two mages who played different
  /// routes should meet different content.
  ///
  /// ⚠️ **This is the ONE zone fact that lives on the character document.**
  /// ACHIEVEMENTS §2.1 puts zone progress in a `progress/` subcollection, and
  /// that is right for `enemiesDefeated` and `dropsSeen` — both unbounded. It
  /// is wrong for this one: bounded at 26 entries, written at most once per
  /// clear, and needed by the map on **every** app open. See the §2.3
  /// amendment.
  Map<String, int> zoneClears;

  List<LoadoutPreset> presets;
  int activePresetIndex;

  /// What this character is carrying. ⭐ **One item per slot** — twenty Oak
  /// Logs fill it (ITEMS §10.3a).
  Backpack backpack;

  /// What can be reached during a duel. Loaded from [backpack].
  Belt belt;

  /// Storerooms, keyed by **town id** (ITEMS §10.3c).
  ///
  /// ⚠️ **One per city, never a shared pool.** What you leave in Aldermere is
  /// in Aldermere; moving it means carrying it there yourself.
  Map<String, Storeroom> storerooms;

  /// Every non-fungible item this character owns, by instance id.
  ///
  /// ⭐ **One pool; containers hold ids.** A staff moved from the backpack to a
  /// Storeroom must be the *same* staff, so the instance cannot live inside
  /// whichever container currently names it.
  Map<String, ItemInstance> itemInstances;

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
    this.resonancePrisms = 0,
    String? locationId,
    this.trip,
    Set<String>? discoveredLocationIds,
    Map<String, int>? zoneClears,
    List<LoadoutPreset>? presets,
    this.activePresetIndex = 0,
    Backpack? backpack,
    Belt? belt,
    Map<String, Storeroom>? storerooms,
    Map<String, ItemInstance>? itemInstances,
    this.duelsWon = 0,
    this.duelsLost = 0,
  }) : locationId = locationId ?? World.startLocationId,
       discoveredLocationIds = discoveredLocationIds ?? {World.startLocationId},
       zoneClears = zoneClears ?? {},
       presets = presets ?? [LoadoutPreset.starter('Loadout I')],
       backpack = backpack ?? Backpack.empty(),
       belt = belt ?? const Belt(),
       storerooms = storerooms ?? {},
       itemInstances = itemInstances ?? {};

  factory PlayerProfile.newPlayer({String name = 'Apprentice'}) =>
      PlayerProfile(name: name);

  // ---- Derived ---------------------------------------------------------

  /// Whether this character has beaten [locationId]'s boss at least once.
  ///
  /// ⭐ Read this — never `zoneClears[id]` directly — so the one definition of
  /// "cleared" stays in one place.
  bool hasCleared(String locationId) => clearCountFor(locationId) > 0;

  /// How many times this character has cleared [locationId].
  ///
  /// ⭐ ACHIEVEMENTS §5.1's First Clear needs `>= 1`; the Purge tier needs
  /// several, because the mini pool shows 2 of 4 and the boss pool 1 of 2 —
  /// about **4.2 clears** to meet every elevated enemy in a zone.
  int clearCountFor(String locationId) => zoneClears[locationId] ?? 0;

  /// How many distinct combat zones this character has finished.
  int get zonesCleared => zoneClears.length;

  int get level => Progression.levelForXp(xp);
  int get xpIntoLevel => Progression.xpIntoLevel(xp);
  int get xpForThisLevel => Progression.xpToNext(level);
  int get unlockedPresetSlots => Progression.presetSlotsAtLevel(level);

  GameLocation get location => World.byId(locationId);

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
    'resonancePrisms': resonancePrisms,
    'locationId': locationId,
    'trip': trip?.toJson(),
    'discoveredLocationIds': discoveredLocationIds.toList(),
    'zoneClears': zoneClears,
    'presets': presets.map((p) => p.toJson()).toList(),
    'activePresetIndex': activePresetIndex,
    'backpack': backpack.toJson(),
    'belt': belt.toJson(),
    'storerooms': {
      for (final e in storerooms.entries)
        if (!e.value.isEmpty) e.key: e.value.toJson(),
    },
    'itemInstances': {
      for (final e in itemInstances.entries) e.key: e.value.toJson(),
    },
    'duelsWon': duelsWon,
    'duelsLost': duelsLost,
    'schemaVersion': 2,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final presets =
        (json['presets'] as List?)
            ?.map((p) => LoadoutPreset.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [LoadoutPreset.starter('Loadout I')];
    return PlayerProfile(
      name: json['name'] as String? ?? 'Apprentice',
      lastSeenAt: DateTime.tryParse(
        json['lastSeenAt'] as String? ?? '',
      )?.toLocal(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      resonancePrisms: (json['resonancePrisms'] as num?)?.toInt() ?? 0,
      locationId: json['locationId'] as String?,
      trip: ActiveTrip.fromJson(json['trip'] as Map<String, dynamic>?),
      discoveredLocationIds: (json['discoveredLocationIds'] as List?)
          ?.cast<String>()
          .toSet(),
      // Absent on saves from before clears were tracked — an old character
      // reads as "has cleared nothing", which is the safe direction: it can
      // only withhold repeat-clear content, never grant it early.
      zoneClears:
          (json['zoneClears'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ) ??
          {},
      presets: presets,
      activePresetIndex: (json['activePresetIndex'] as num?)?.toInt() ?? 0,
      backpack: Backpack.fromJson(json['backpack'] as List?),
      belt: Belt.fromJson(json['belt'] as List?),
      storerooms:
          (json['storerooms'] as Map?)?.map(
            (k, v) => MapEntry(
              k as String,
              Storeroom.fromJson(v as Map<String, dynamic>?),
            ),
          ) ??
          {},
      itemInstances:
          (json['itemInstances'] as Map?)?.map(
            (k, v) => MapEntry(
              k as String,
              ItemInstance.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
      duelsWon: (json['duelsWon'] as num?)?.toInt() ?? 0,
      duelsLost: (json['duelsLost'] as num?)?.toInt() ?? 0,
    );
  }
}
