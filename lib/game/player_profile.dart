import 'package:mom_engine/mom_engine.dart';

import 'items/inventory.dart';
import 'items/item_def.dart';
import 'items/item_instance.dart';

import 'adventure.dart';
import 'loadout.dart';
import 'progression.dart';
import 'skills.dart';
import 'pronouns.dart';
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

  /// The adventure in progress, if any.
  ///
  /// ⭐ **A run survives the app closing.** It used to live in `GameState`
  /// memory only, so force-quitting at encounter 4 of 9 came back to nothing —
  /// and a nine-fight run is longer than a bus ride. The earlier worry, that
  /// persisting it lets a player dodge a losing fight by force-quitting, is
  /// answered by *where* it resumes rather than by throwing the run away.
  ///
  /// ⚠️ **RULING (playtest, 2026-08): closing mid-FIGHT resumes at the START
  /// of the current encounter.** [AdventureRun.playerHp] only moves on
  /// `recordVictory`, so it is by construction the health the player walked
  /// *into* the current fight with — no mid-duel state is serialized, and none
  /// should be. Quitting a duel therefore costs that duel's progress and
  /// nothing else: no free escape from a fight going badly, no lost evening
  /// either. Everything won on the way in is already in the [backpack] (ruling
  /// 2026-08-17), so the only loot a stored run can carry is a victory picker
  /// that was never answered — [AdventureRun.unclaimed].
  AdventureRun? run;

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

  /// Total XP per skill, keyed by `CraftSkill.name` / `GatherSkill.name`
  /// (Skills.allKeys). ⭐ **XP is the stored fact; level is derived**
  /// (Skills.levelForXp) — storing both would let them disagree, the same
  /// reasoning as character [xp]/[level]. Absent key = never practised = 0.
  Map<String, int> skillXp;

  List<LoadoutPreset> presets;
  int activePresetIndex;

  /// What this character is carrying. ⭐ **One item per slot** — twenty Oak
  /// Logs fill it (ITEMS §10.3a).
  Backpack backpack;

  /// What can be reached during a duel. Loaded from [backpack].
  Belt belt;

  /// What is worn, by slot. ⚠️ Values are **instance ids** — equipment is
  /// never fungible, so the specific item matters (ITEMS §10.3a).
  ///
  /// 📝 Nothing writes this yet: items drop and are carried, but
  /// `ItemModifiers` still reaches no `MageState`. The slots exist so the
  /// paper doll can show what is empty, which is most of the value early on.
  Map<EquipSlot, String> equipped;

  /// Storerooms, keyed by **town id** (ITEMS §10.3c).
  ///
  /// ⚠️ **One per city, never a shared pool.** What you leave in Hearthwood is
  /// in Hearthwood; moving it means carrying it there yourself.
  Map<String, Storeroom> storerooms;

  /// Every non-fungible item this character owns, by instance id.
  ///
  /// ⭐ **One pool; containers hold ids.** A staff moved from the backpack to a
  /// Storeroom must be the *same* staff, so the instance cannot live inside
  /// whichever container currently names it.
  Map<String, ItemInstance> itemInstances;

  /// ⭐ **Chosen at character creation and used by every line of story text
  /// that refers to the player** — the mother's "my son"/"my daughter" most of
  /// all. Read [pronouns] rather than switching on this.
  PlayerGender gender;

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
    this.run,
    Set<String>? discoveredLocationIds,
    Map<String, int>? zoneClears,
    Map<String, int>? skillXp,
    List<LoadoutPreset>? presets,
    this.activePresetIndex = 0,
    Backpack? backpack,
    Belt? belt,
    Map<String, Storeroom>? storerooms,
    Map<String, ItemInstance>? itemInstances,
    Map<EquipSlot, String>? equipped,
    this.gender = PlayerGender.unspecified,
    this.duelsWon = 0,
    this.duelsLost = 0,
  }) : locationId = locationId ?? World.startLocationId,
       discoveredLocationIds = discoveredLocationIds ?? {World.startLocationId},
       zoneClears = zoneClears ?? {},
       skillXp = skillXp ?? {},
       presets = presets ?? [LoadoutPreset.starter('Loadout I')],
       backpack = backpack ?? Backpack.empty(),
       belt = belt ?? const Belt(),
       storerooms = storerooms ?? {},
       itemInstances = itemInstances ?? {},
       equipped = equipped ?? {};

  factory PlayerProfile.newPlayer({
    String name = 'Apprentice',
    PlayerGender gender = PlayerGender.unspecified,
  }) => PlayerProfile(name: name, gender: gender);

  // ---- Derived ---------------------------------------------------------

  /// How to talk about this character. ⭐ Never switch on [gender] at a call
  /// site — ask for the word you need, so adding a fourth set stays one edit.
  Pronouns get pronouns => gender.pronouns;

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

  /// The skill ledger, read side: level for a Skills.allKeys key.
  int skillLevel(String key) => Skills.levelForXp(skillXp[key] ?? 0);

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
    'run': run?.toJson(),
    'discoveredLocationIds': discoveredLocationIds.toList(),
    'zoneClears': zoneClears,
    if (skillXp.isNotEmpty) 'skillXp': skillXp,
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
    'equipped': {for (final e in equipped.entries) e.key.name: e.value},
    'gender': gender.name,
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
    final profile = PlayerProfile(
      name: json['name'] as String? ?? 'Apprentice',
      lastSeenAt: DateTime.tryParse(
        json['lastSeenAt'] as String? ?? '',
      )?.toLocal(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      resonancePrisms: (json['resonancePrisms'] as num?)?.toInt() ?? 0,
      // ⭐ Every stored location id is canonicalised on load (World.renamedIds)
      // so a rename never strands a save. Six fields hold one: this, the trip,
      // the discovered set, and the keys of zoneClears + storerooms.
      locationId: json['locationId'] == null
          ? null
          : World.canonicalId(json['locationId'] as String),
      trip: ActiveTrip.fromJson(json['trip'] as Map<String, dynamic>?),
      // Absent on saves from before runs were persisted — and absent, on a
      // run whose zone or creatures no longer resolve, is exactly right: the
      // player is simply not on an adventure. See AdventureRun.fromJson.
      run: AdventureRun.fromJson(json['run'] as Map<String, dynamic>?),
      discoveredLocationIds: (json['discoveredLocationIds'] as List?)
          ?.cast<String>()
          .map(World.canonicalId)
          .toSet(),
      // Absent on saves from before clears were tracked — an old character
      // reads as "has cleared nothing", which is the safe direction: it can
      // only withhold repeat-clear content, never grant it early.
      zoneClears:
          (json['zoneClears'] as Map?)?.map(
            (k, v) =>
                MapEntry(World.canonicalId(k as String), (v as num).toInt()),
          ) ??
          {},
      skillXp:
          (json['skillXp'] as Map?)?.map(
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
              World.canonicalId(k as String),
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
      equipped: _equippedFrom(json['equipped'] as Map?),
      // Absent on saves from before the field existed — PlayerGender.byName
      // reads that as unspecified, which is they/them.
      gender: PlayerGender.byName(json['gender'] as String?),
      duelsWon: (json['duelsWon'] as num?)?.toInt() ?? 0,
      duelsLost: (json['duelsLost'] as num?)?.toInt() ?? 0,
    );
    _migratePendingLoot(profile);
    return profile;
  }
}

/// ⚠️ **The migration of 2026-08-17** — the run-long loot tracker was deleted,
/// and a save written before that can hold a whole adventure's `pendingLoot`
/// that nobody will ever be offered again.
///
/// ⭐ **Hands it over rather than dropping it**, best-rarity-first up to the
/// free slots, instances registered for what lands. Deleting a feature must not
/// delete a playtester's rare, and a picker for a run they finished last week
/// would be stranger than simply finding it in the pack. Anything past the last
/// free slot is gone — the same arithmetic the live picker applies.
///
/// ⚠️ Lives **here**, in `fromJson`, rather than in `GameState.boot`: every
/// load path (local store, Firestore adoption on sign-in, tests) goes through
/// this constructor, and a migration that only one of them runs is a migration
/// that loses the haul on the other.
void _migratePendingLoot(PlayerProfile p) {
  final run = p.run;
  if (run == null || run.legacyPendingLoot.isEmpty) return;
  var pack = p.backpack;
  for (final i in lootDisplayOrder(
    run.legacyPendingLoot,
    run.legacyPendingInstances,
  )) {
    final slot = run.legacyPendingLoot[i];
    // ⚠️ The pack is the authority on whether it has room; a full one simply
    // ends the handover rather than overflowing.
    final next = pack.withAdded(slot);
    if (next == null) continue;
    pack = next;
    final id = slot.instanceId;
    final inst = id == null ? null : run.legacyPendingInstances[id];
    if (inst != null) p.itemInstances[id!] = inst;
  }
  p.backpack = pack;
  // Drained is drained: [AdventureRun.toJson] never writes these keys, so the
  // next save is a clean, post-ruling one.
  run.legacyPendingLoot.clear();
  run.legacyPendingInstances.clear();
}

/// ⚠️ An unknown slot name is dropped rather than throwing — a save written by
/// a newer build must not brick an older one.
Map<EquipSlot, String> _equippedFrom(Map? json) {
  final out = <EquipSlot, String>{};
  if (json == null) return out;
  for (final e in json.entries) {
    final slot = _slotByName(e.key as String);
    if (slot != null) out[slot] = e.value as String;
  }
  return out;
}

EquipSlot? _slotByName(String name) {
  for (final s in EquipSlot.values) {
    if (s.name == name) return s;
  }
  return null;
}
