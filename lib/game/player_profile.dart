import 'package:mom_engine/mom_engine.dart';

import 'economy/shop_state.dart';
import 'items/inventory.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'items/item_instance.dart';

import 'adventure.dart';
import 'bestiary_record.dart';
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
///
/// ⭐ **Spells are SPARSE, everything else is dense** (ruling, 2026-09-21:
/// "if I remove the Q, the Q should be empty"). [spellSlots] is keyed by
/// keyboard position and may hold nulls; [spellIds] hands every reader that
/// only cares *which* spells the dense list it always got.
///
/// ⚠️ **Elements stay dense on purpose.** The ruling names spells, and the
/// 1-5 element keys are nowhere near the muscle memory QWERT is — an element
/// is chosen by what it is, not by where its finger goes. Holes there would
/// be complexity bought for nobody.
class LoadoutPreset {
  String name;
  List<String> elementIds;

  /// Spells by **keyboard slot**: index 0 is Q, 4 is T, 5 is A, 9 is G. A
  /// null is an *empty slot*, never a gap to be closed — removing Q must
  /// leave R on R, and the next spell added goes back into Q.
  ///
  /// Fixed length: [Loadout.maxSpellSlots], or shorter once [clampToCaps] has
  /// cut it to a tighter budget.
  List<String?> spellSlots;

  /// [spellIds] packs into slot 0 upward; pass [spellSlots] instead to place
  /// spells (and holes) exactly.
  LoadoutPreset({
    required this.name,
    required this.elementIds,
    List<String> spellIds = const [],
    List<String?>? spellSlots,
  }) : spellSlots = spellSlots == null
           ? _packSlots(spellIds)
           : List<String?>.of(spellSlots);

  /// A dense id list laid into a full-length slot list from slot 0 up.
  static List<String?> _packSlots(List<String> ids) {
    final slots = List<String?>.filled(Loadout.maxSpellSlots, null);
    for (var i = 0; i < ids.length && i < slots.length; i++) {
      slots[i] = ids[i];
    }
    return slots;
  }

  /// A detached copy. ⚠️ The loadout editor mutates one of these and saves
  /// it — never the preset the screen is currently drawing, whose slots a
  /// refused edit must leave exactly as they were.
  LoadoutPreset copy() => LoadoutPreset(
    name: name,
    elementIds: List.of(elementIds),
    spellSlots: List.of(spellSlots),
  );

  factory LoadoutPreset.starter(String name) => LoadoutPreset(
    name: name,
    elementIds: List.of(Progression.starterPresetElementIds),
    spellIds: List.of(Progression.starterPresetSpellIds),
  );

  /// The Academy's starting hand: a rounded level-50 kit across the whole
  /// book, so a first Academy bout is playable before anyone edits it.
  /// ⚠️ Every id here must resolve — `academy_test` checks — because a
  /// default that silently dropped a spell would hand a guest a 9-spell
  /// loadout with no way to know why.
  factory LoadoutPreset.academy() => LoadoutPreset(
    name: 'Academy',
    elementIds: ['pyro', 'aqua', 'flora', 'electro', 'geo'],
    spellIds: [
      'bolt',
      'surge',
      'cataclysm',
      'aegis',
      'bulwark',
      'agony',
      'lightfoot',
      'keen',
      'cleanse',
      'empower',
    ],
  );

  /// The spells this preset holds, in slot order, **without the holes** — the
  /// answer to "which spells", which is what every reader outside the key
  /// mapping wants: validity, the catalogue check, the ladder, the Academy.
  List<String> get spellIds => [for (final id in spellSlots) ?id];

  int get elementCount => elementIds.length;
  int get spellCount => spellIds.length;

  // ---- Slot mutations ---------------------------------------------------

  /// Empties the slot holding [id], **leaving the hole**; returns whether a
  /// slot held it. ⚠️ Never compacts: that is the whole ruling.
  bool removeSpell(String id) {
    final at = spellSlots.indexOf(id);
    if (at < 0) return false;
    spellSlots[at] = null;
    return true;
  }

  /// Puts [id] in the FIRST empty slot — so the Q just emptied is the Q the
  /// next spell fills. Returns false, changing nothing, when none is free.
  bool addSpell(String id) {
    final free = spellSlots.indexOf(null);
    if (free < 0) return false;
    spellSlots[free] = id;
    return true;
  }

  /// Writes [id] (or null, to empty it) into slot [index] — what a drag of
  /// one tray chip onto another will want. Out of range is a refused no-op.
  bool setSpellAt(int index, String? id) {
    if (index < 0 || index >= spellSlots.length) return false;
    spellSlots[index] = id;
    return true;
  }

  /// Truncates each pool to its own cap. Migrates saves written when the pools
  /// were merged and either could run larger — a preset with 8 elements, say,
  /// loses the last three rather than crashing on load.
  ///
  /// ⚠️ The spell pool loses its **last slots**, holes included — it does not
  /// compact first. A budget of 4 over `[a, null, c, null, e]` keeps
  /// `[a, null, c, null]` and drops `e`; compacting would hand back `[a, c,
  /// e, null]` and move the player's D onto their W, which is the habit this
  /// whole shape exists to protect.
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
    if (spellSlots.length > spellBudget) {
      spellSlots = spellSlots.sublist(0, spellBudget);
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

  /// Spells this preset resolves to, densely. Unknown ids are dropped, not
  /// thrown on — symmetric with [elements]; see [unknownSpellIds].
  List<Spell> get spells =>
      spellIds.where(_spellIds.contains).map(Spellbook.byId).toList();

  /// Spells **by slot**, null where the slot is empty *or* where a stale id no
  /// longer resolves. The [E] tray and any future drag/drop draw exactly this.
  List<Spell?> get spellsBySlot => [
    for (final id in spellSlots)
      (id != null && _spellIds.contains(id)) ? Spellbook.byId(id) : null,
  ];

  /// ⚠️ **Carries the slot positions across**, so the arena's Q stays the
  /// spell in slot 0 even when slot 0 was emptied and refilled. A dense
  /// `Loadout` built from [spells] alone is what slid R onto E.
  Loadout toLoadout() {
    final spells = <Spell>[];
    final slotIndices = <int>[];
    for (var i = 0; i < spellSlots.length; i++) {
      final id = spellSlots[i];
      if (id == null || !_spellIds.contains(id)) continue;
      spells.add(Spellbook.byId(id));
      slotIndices.add(i);
    }
    return Loadout(
      elements: elements,
      spells: spells,
      spellSlotIndices: slotIndices,
    );
  }

  bool get isValid => elementIds.isNotEmpty && spellIds.isNotEmpty;

  /// ⭐ **Both keys are written, always.** `spellSlots` is the truth, but the
  /// dense `spellIds` stays beside it so a cloud profile saved here and read
  /// by an older client still finds the loadout it knows how to parse — it
  /// loses the holes, not the spells. Drop the old key only once no shipped
  /// build reads it.
  Map<String, dynamic> toJson() => {
    'name': name,
    'elementIds': elementIds,
    'spellIds': spellIds,
    'spellSlots': spellSlots,
  };

  /// A save without `spellSlots` — every save written before this ruling —
  /// packs its dense `spellIds` from slot 0 up, which is exactly where those
  /// spells were.
  factory LoadoutPreset.fromJson(Map<String, dynamic> json) => LoadoutPreset(
    name: json['name'] as String? ?? 'Loadout',
    elementIds: (json['elementIds'] as List?)?.cast<String>().toList() ?? [],
    spellIds: (json['spellIds'] as List?)?.cast<String>().toList() ?? [],
    spellSlots: (json['spellSlots'] as List?)
        ?.map((e) => e as String?)
        .toList(),
  );
}

/// The player's persistent save — every field serializes to a plain JSON
/// value.
///
/// ⭐ **Still one whole object in memory, even though the cloud now stores it
/// in pieces.** `users/{uid}/characters/{cid}` holds most of it, `lastSeenAt`
/// lives on the account document, and the two per-town maps became one
/// document each; `ProfileDocuments` does the cutting and the reassembly, and
/// nothing above the storage layer knows. Local guest saves are still the one
/// blob this `toJson` produces.
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

  /// The place the last completed journey **set out from** — the door you came
  /// in by (ruling, Christian 2026-09-21: you cannot travel *through* a node
  /// you have not cleared).
  ///
  /// ⭐ **The trip's ORIGIN, not merely any neighbour.** An uncleared zone lets
  /// you turn around; it does not let you pick whichever exit you like. Old
  /// Quarry has three roads off it, and "back the way you came" means the one
  /// you walked in on — so this stores a single id rather than being inferred
  /// from [location]'s connections, which would open all three.
  ///
  /// ⚠️ Null on a fresh character and on every save written before the passage
  /// rule — see `GameState.passageRefusal`, which reads a null here as "we do
  /// not know which way you came" and falls back to letting you reach a town.
  ///
  /// 📝 Only [GameState.settleTravel] writes this, on arrival. Cancelling
  /// mid-route deliberately does not: a cancel drops you at a stop the passage
  /// rule already required to be cleared (or a town), so the rule that reads
  /// this field never fires there and a stale value cannot be observed.
  String? arrivedFromId;

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

  /// Ids of tier gates this character has already talked their way past
  /// (`GameLocation.gateItemIds`).
  ///
  /// ⭐ **Permanent, and the whole point of the field** (ruling, Christian
  /// 2026-09-21). Once an id is in here the items are never looked for again,
  /// so selling, banking or losing them cannot shut a road that is already
  /// open. 📝 Since 2026-09-25 only `GameState.openGateAt` writes it — on
  /// Unlock at the gate, not at departure — and Pennycross's proofs are spent
  /// in the same write. A `bool` per gate in disguise —
  /// a set, because gates are added faster than fields are.
  ///
  /// ⚠️ **Not [discoveredLocationIds]**. Seeing a place on the map and being
  /// allowed through its gate are different permissions, and conflating them
  /// would open Pennycross the moment its name appeared.
  Set<String> openedGates;

  /// Ids of the achievements this character has earned (`achievements.dart`).
  ///
  /// ⭐ **Ids only** — the name and blurb live in the catalogue, so rewording
  /// an achievement never touches a save. Written by
  /// `GameState.grantAchievement` (and, atomically with the opening, by
  /// `GameState.openGateAt`). ⚠️ Absent on every save before 2026-09-25, and
  /// absent reads as "earned nothing" — the only direction that cannot hand
  /// out something unearned.
  Set<String> achievements;

  /// What this character knows of each creature, by `EnemyDef.id` (ruling,
  /// Christian playtest 2026-09-30, note 8) — the Bestiary screen's record.
  ///
  /// ⭐ **Sparse**: a creature never fought has no entry, and absent reads as
  /// "not yet met". Written by `GameState.beginEncounter` (seen) and
  /// `GameState.winEncounter` (slain) — read [BestiaryEntry] for which moment
  /// each count marks.
  ///
  /// ⚠️ Absent on every save before 2026-09-30, and absent reads as "met
  /// nothing" — the same safe direction as [achievements].
  ///
  /// 📝 On the character document, not in a subcollection: bounded by the
  /// roster (one entry per `Bestiary.all` creature), and the Profile row
  /// reads its count on every open.
  Map<String, BestiaryEntry> bestiary;

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

  /// The one Academy loadout (academy.dart) — outside the preset slots,
  /// never level-gated, never the campaign's active preset.
  LoadoutPreset academyPreset;

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

  /// Per-character general shop state, keyed by **town id** (ECONOMY
  /// CONTRACT §11.1), mirroring [storerooms]' shape exactly.
  ///
  /// ⚠️ **One per town, never a shared pool** — same reasoning as
  /// [storerooms] (ECONOMY CONTRACT §1): stock is client-authoritative
  /// personal state, not a document two clients could race. A town this
  /// character has never visited has no entry at all; `ShopState.resolve`
  /// treats that absence as "reset fresh from equilibrium," the same way an
  /// absent [storerooms] entry reads as "nothing stored here yet."
  Map<String, TownShopState> shopStock;

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

  /// This character's Elo on the Geared ladder (LADDER_DESIGN §2), or null.
  ///
  /// ⭐ **Null means "never played a rated match on this ladder" — it is not
  /// a default.** The Geared seed depends on level and gear at the moment of
  /// the *first* rated match (`1080 + 12 × level + 75`), so there is no fixed
  /// number to default to here; computing the seed is the caller's job, the
  /// first time it reads null.
  int? ratingGeared;

  /// This character's Elo on the Academy ladder (LADDER_DESIGN §2), or null
  /// for the same reason as [ratingGeared] — though the Academy seed (1200)
  /// happens to be fixed, nulling it keeps the two ladders symmetric and lets
  /// "never played" stay a single, ladder-agnostic check.
  int? ratingAcademy;

  /// Rated games played on the Geared ladder — feeds the LADDER §2 K
  /// schedule (40 for the first 30, then 20).
  int ratedGamesGeared;

  /// Rated games played on the Academy ladder — same K schedule, separately.
  int ratedGamesAcademy;

  /// The highest [ratingGeared] this character has ever reached — LADDER §2's
  /// K-10 rule triggers once a player has *ever* reached 2400, not merely
  /// sits there now, so the peak must survive a later drop.
  int peakGeared;

  /// The highest [ratingAcademy] has ever reached. Symmetric with
  /// [peakGeared].
  int peakAcademy;

  /// Academy ladder wins. ⚠️ **A separate record from [duelsWon].**
  /// [duelsWon]/[duelsLost] are the geared/campaign record; the Academy plays
  /// at a fixed level with no gear, so it earns its own win/loss count rather
  /// than folding into the number a level-30 grind produced.
  int academyWins;

  /// Academy ladder losses. See [academyWins].
  int academyLosses;

  /// The [LadderBot] id this player most recently fought via quick match
  /// (LADDER_DESIGN §3), or null. ⭐ Read by the search as `excludeBotId` so
  /// the very next bot pick can't repeat the same face; set back to null
  /// after a HUMAN match, since there is no bot to avoid repeating.
  String? lastOpponentBotId;

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
    this.arrivedFromId,
    this.run,
    Set<String>? discoveredLocationIds,
    Set<String>? openedGates,
    Set<String>? achievements,
    Map<String, BestiaryEntry>? bestiary,
    Map<String, int>? zoneClears,
    Map<String, int>? skillXp,
    List<LoadoutPreset>? presets,
    this.activePresetIndex = 0,
    LoadoutPreset? academyPreset,
    Backpack? backpack,
    Belt? belt,
    Map<String, Storeroom>? storerooms,
    Map<String, TownShopState>? shopStock,
    Map<String, ItemInstance>? itemInstances,
    Map<EquipSlot, String>? equipped,
    this.gender = PlayerGender.unspecified,
    this.duelsWon = 0,
    this.duelsLost = 0,
    this.ratingGeared,
    this.ratingAcademy,
    this.ratedGamesGeared = 0,
    this.ratedGamesAcademy = 0,
    this.peakGeared = 0,
    this.peakAcademy = 0,
    this.academyWins = 0,
    this.academyLosses = 0,
    this.lastOpponentBotId,
  }) : locationId = locationId ?? World.startLocationId,
       discoveredLocationIds = discoveredLocationIds ?? {World.startLocationId},
       openedGates = openedGates ?? {},
       achievements = achievements ?? {},
       bestiary = bestiary ?? {},
       zoneClears = zoneClears ?? {},
       skillXp = skillXp ?? {},
       presets = presets ?? [LoadoutPreset.starter('Loadout I')],
       academyPreset = academyPreset ?? LoadoutPreset.academy(),
       backpack = backpack ?? Backpack.empty(),
       belt = belt ?? const Belt(),
       storerooms = storerooms ?? {},
       shopStock = shopStock ?? {},
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

  /// The record for creature [enemyId] — an empty one when never fought.
  BestiaryEntry bestiaryEntryFor(String enemyId) =>
      bestiary[enemyId] ?? const BestiaryEntry();

  /// Counts a fight against [enemyId] beginning. ⚠️ Mutates only — the caller
  /// (`GameState.beginEncounter`) owns the save.
  void noteSeen(String enemyId) =>
      bestiary[enemyId] = bestiaryEntryFor(enemyId).withSeen();

  /// Counts a win over [enemyId]. ⚠️ Mutates only — it rides the save of the
  /// result that earned it (`GameState.winEncounter`).
  void noteSlain(String enemyId) =>
      bestiary[enemyId] = bestiaryEntryFor(enemyId).withSlain();

  /// How many distinct combat zones this character has finished.
  int get zonesCleared => zoneClears.length;

  /// The skill ledger, read side: level for a Skills.allKeys key.
  int skillLevel(String key) => Skills.levelForXp(skillXp[key] ?? 0);

  int get level => Progression.levelForXp(xp);
  int get xpIntoLevel => Progression.xpIntoLevel(xp);
  int get xpForThisLevel => Progression.xpToNext(level);
  int get unlockedPresetSlots => Progression.presetSlotsAtLevel(level);

  GameLocation get location => World.byId(locationId);

  /// The shut gate this character is standing at, or null — ⭐ **the whole
  /// arrival seam of the gate ruling** (Christian, 2026-09-25, mockup B).
  ///
  /// Derived, not stored: standing (not travelling) at a place with
  /// `gateItemIds` that is not in [openedGates]. The trip there is never
  /// refused; it simply arrives here, and `GateCheckpoint` shows the gate
  /// screen instead of the town for as long as this is non-null. Unlocking
  /// ([openedGates] gains the id) or turning back (a [trip] begins) is what
  /// clears it — no flag to set, and none to forget to clear.
  ///
  /// ⚠️ **A player who opened the gate under the old rule never sees the
  /// screen** — their [openedGates] already holds the id.
  ///
  /// 📝 **Legacy, and deliberately left alone:** those players opened
  /// Pennycross when the proofs were shown, not spent, so they still carry
  /// them. Nothing takes them now — they may sell them; the screen they will
  /// never see is the only place that would have asked.
  ///
  /// 📝 A save from before gates were enforced, standing in Pennycross with
  /// nothing in [openedGates], DOES land at the gate on its next launch —
  /// the direction `openedGates`' JSON note already chose ("asked to show
  /// them once more"). [gateTurnBackId] gives it a way out.
  String? get shutGateHere {
    if (trip != null) return null;
    final here = location;
    if (here.gateItemIds.isEmpty) return null;
    if (openedGates.contains(here.id)) return null;
    return here.id;
  }

  /// Where 'Turn back' at a shut gate goes: [arrivedFromId], the way you came.
  ///
  /// ⚠️ **A legacy save has no [arrivedFromId]** (see the note there), so it
  /// falls back to the first **town** among the gate's roads — Hearthwood,
  /// for Pennycross — and failing that, the first road at all. Never null:
  /// a gate with no way back would strand the player on a screen with one
  /// working button.
  String get gateTurnBackId {
    final came = arrivedFromId;
    if (came != null && came != locationId) return came;
    final roads = location.connections;
    return roads.firstWhere(
      (id) => World.byId(id).isTown,
      orElse: () => roads.first,
    );
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
    'resonancePrisms': resonancePrisms,
    'locationId': locationId,
    'trip': trip?.toJson(),
    if (arrivedFromId != null) 'arrivedFromId': arrivedFromId,
    'run': run?.toJson(),
    'discoveredLocationIds': discoveredLocationIds.toList(),
    'openedGates': openedGates.toList(),
    'achievements': achievements.toList(),
    // ⭐ Always written, even empty (like [achievements]), so the character
    // document's field set never varies and the update mask always covers it.
    'bestiary': {for (final e in bestiary.entries) e.key: e.value.toJson()},
    'zoneClears': zoneClears,
    if (skillXp.isNotEmpty) 'skillXp': skillXp,
    'presets': presets.map((p) => p.toJson()).toList(),
    'activePresetIndex': activePresetIndex,
    'academyPreset': academyPreset.toJson(),
    'backpack': backpack.toJson(),
    'belt': belt.toJson(),
    'storerooms': {
      for (final e in storerooms.entries)
        if (!e.value.isEmpty) e.key: e.value.toJson(),
    },
    'shopStock': {
      for (final e in shopStock.entries)
        if (!e.value.isEmpty) e.key: e.value.toJson(),
    },
    'itemInstances': {
      for (final e in itemInstances.entries) e.key: e.value.toJson(),
    },
    'equipped': {for (final e in equipped.entries) e.key.name: e.value},
    'gender': gender.name,
    'duelsWon': duelsWon,
    'duelsLost': duelsLost,
    'ratingGeared': ratingGeared,
    'ratingAcademy': ratingAcademy,
    'ratedGamesGeared': ratedGamesGeared,
    'ratedGamesAcademy': ratedGamesAcademy,
    'peakGeared': peakGeared,
    'peakAcademy': peakAcademy,
    'academyWins': academyWins,
    'academyLosses': academyLosses,
    'lastOpponentBotId': lastOpponentBotId,
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
      // ⚠️ Absent reads as null, and null is NOT "came from nowhere, go
      // anywhere": `GameState.passageRefusal` treats it as a legacy save
      // standing somewhere unknown and lets it reach a town only.
      arrivedFromId: json['arrivedFromId'] == null
          ? null
          : World.canonicalId(json['arrivedFromId'] as String),
      trip: ActiveTrip.fromJson(json['trip'] as Map<String, dynamic>?),
      // Absent on saves from before runs were persisted — and absent, on a
      // run whose zone or creatures no longer resolve, is exactly right: the
      // player is simply not on an adventure. See AdventureRun.fromJson.
      run: AdventureRun.fromJson(json['run'] as Map<String, dynamic>?),
      discoveredLocationIds: (json['discoveredLocationIds'] as List?)
          ?.cast<String>()
          .map(World.canonicalId)
          .toSet(),
      // Absent on every save written before the Primal gate was enforced, and
      // absent reads as "has opened nothing" — the safe direction: a character
      // who really did carry the proofs is asked to show them once more, which
      // costs a walk; the other way round would unlock the tier for free.
      openedGates: (json['openedGates'] as List?)
          ?.cast<String>()
          .map(World.canonicalId)
          .toSet(),
      // Absent before 2026-09-25 — see [achievements].
      achievements: (json['achievements'] as List?)?.cast<String>().toSet(),
      // Absent before 2026-09-30 — see [bestiary].
      bestiary: (json['bestiary'] as Map?)?.map(
        (k, v) => MapEntry(k as String, BestiaryEntry.fromJson(v)),
      ),
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
      // Absent on saves from before the Academy — the default hand, exactly
      // what a new player gets.
      academyPreset: json['academyPreset'] is Map
          ? LoadoutPreset.fromJson(
              (json['academyPreset'] as Map).cast<String, dynamic>(),
            )
          : null,
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
      // Absent on saves from before shops existed — an old character reads
      // as "has visited no town's shop yet," which ShopState.resolve already
      // treats identically to a town whose entry is simply missing.
      shopStock:
          (json['shopStock'] as Map?)?.map(
            (k, v) => MapEntry(
              World.canonicalId(k as String),
              TownShopState.fromJson(v as Map<String, dynamic>?),
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
      // Null stays null — see [ratingGeared]/[ratingAcademy]'s doc comment.
      // (json[...] as num?)?.toInt() already reads an absent key as null;
      // there is no `?? default` here on purpose.
      ratingGeared: (json['ratingGeared'] as num?)?.toInt(),
      ratingAcademy: (json['ratingAcademy'] as num?)?.toInt(),
      ratedGamesGeared: (json['ratedGamesGeared'] as num?)?.toInt() ?? 0,
      ratedGamesAcademy: (json['ratedGamesAcademy'] as num?)?.toInt() ?? 0,
      peakGeared: (json['peakGeared'] as num?)?.toInt() ?? 0,
      peakAcademy: (json['peakAcademy'] as num?)?.toInt() ?? 0,
      academyWins: (json['academyWins'] as num?)?.toInt() ?? 0,
      academyLosses: (json['academyLosses'] as num?)?.toInt() ?? 0,
      lastOpponentBotId: json['lastOpponentBotId'] as String?,
    );
    _migratePendingLoot(profile);
    return profile;
  }

  /// Makes the instance pool and the containers agree again; returns how
  /// many items were dropped (0 = the save was already consistent, and then
  /// nothing — not one map — is touched).
  ///
  /// ⭐ **The cleanup after the sync race of 2026-09-25.** Two devices each
  /// saved whole documents last-writer-wins, and Christian's save came back
  /// with nine Hearthwood and one Pennycross storeroom ids that had no
  /// instance behind them — rendered in the Inventory as raw ids. The race
  /// itself is closed by the character document's version precondition
  /// (`FirestoreProfileStorage`); this sweeps up what it already did:
  ///
  /// 1. every id in [backpack], [equipped] or any `storerooms[*].instanceIds`
  ///    with no entry in [itemInstances] is dropped — an item whose rolls are
  ///    gone cannot be rebuilt, and a slot that names nothing is worse than
  ///    an empty one;
  /// 2. every [itemInstances] entry that no container names is dropped — a
  ///    staff nobody holds is a save that grows forever;
  /// 3. every backpack stack whose `count` is outside 1..`stackSize` is
  ///    clamped into it (ruling 2026-09-25), and each one counts.
  ///
  /// ⚠️ **Drops the id, never the container.** A storeroom's fungible stacks
  /// are untouched, and a storeroom left empty stays in the map (the sparse
  /// write filter in [toJson] already omits it on the way out).
  ///
  /// ⚠️ **Only on a whole profile.** Direction 2 is only sound once every
  /// container is loaded — the storerooms arrive as their own cloud documents
  /// — so this is a method `GameState` calls after a load has assembled all
  /// of them, never part of [fromJson] (which also sees partial fixtures).
  /// 📝 The adventure's own `unclaimed` loot keeps a separate instance map and
  /// never names this pool, so it is neither a container nor an orphan here.
  int repairContainers() {
    var dropped = 0;
    bool known(String? id) => id == null || itemInstances.containsKey(id);

    if (!backpack.contents.every((s) => known(s.instanceId))) {
      final slots = [...backpack.slots];
      for (var i = 0; i < slots.length; i++) {
        if (slots[i] != null && !known(slots[i]!.instanceId)) {
          slots[i] = null;
          dropped++;
        }
      }
      backpack = Backpack.of(slots);
    }

    // 3. ⭐ **A stack outside 1..stackSize is clamped** (stacking ruling,
    // Christian 2026-09-25) — 40 Dust in one slot becomes 25, a 0 becomes 1 —
    // and counted as a repair. A slot holding more than its cap is items the
    // pack never paid room for; clamping, not splitting, because a split
    // could need slots the pack does not have. ⚠️ An id the catalogue no
    // longer knows is left alone: its cap is unknown, and guessing 1 would
    // destroy a stack a later content patch might claim again.
    if (backpack.contents.any(_countOutOfRange)) {
      final slots = [...backpack.slots];
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        if (s == null || !_countOutOfRange(s)) continue;
        final size = ItemCatalogue.byId(s.defId).stackSize;
        slots[i] = s.withCount(s.count < 1 ? 1 : size);
        dropped++;
      }
      backpack = Backpack.of(slots);
    }

    for (final slot in equipped.keys.toList()) {
      if (!known(equipped[slot])) {
        equipped.remove(slot);
        dropped++;
      }
    }

    for (final town in storerooms.keys.toList()) {
      final room = storerooms[town]!;
      final kept = room.instanceIds.where(known).toList();
      if (kept.length == room.instanceIds.length) continue;
      dropped += room.instanceIds.length - kept.length;
      storerooms[town] = Storeroom(stacks: room.stacks, instanceIds: kept);
    }

    final held = <String>{
      for (final s in backpack.contents)
        if (s.instanceId != null) s.instanceId!,
      ...equipped.values,
      for (final room in storerooms.values) ...room.instanceIds,
    };
    for (final id in itemInstances.keys.toList()) {
      if (!held.contains(id)) {
        itemInstances.remove(id);
        dropped++;
      }
    }
    return dropped;
  }
}

/// Whether [s] holds a count its def cannot — see `repairContainers` step 3.
/// ⚠️ False for an id the catalogue no longer knows: no cap, nothing to fix.
bool _countOutOfRange(InventorySlot s) {
  final def = ItemCatalogue.tryById(s.defId);
  return def != null && (s.count < 1 || s.count > def.stackSize);
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
