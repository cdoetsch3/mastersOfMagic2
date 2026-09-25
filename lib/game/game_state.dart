import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mom_engine/mom_engine.dart';

import 'active_trip.dart';
import 'adventure.dart';
import 'crafting/craft_quality.dart';
import 'economy/economy_config.dart';
import 'economy/quality_value.dart';
import 'economy/shop_catalogue.dart';
import 'economy/shop_pricing.dart';
import 'economy/shop_state.dart';
import 'gates.dart';
import 'enemies/bestiary.dart';
import 'academy.dart';
import 'achievements.dart';
import 'enemies/loot.dart';
import 'items/carrying.dart';
import 'items/equipping.dart';
import 'items/inventory.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'items/item_instance.dart';
import 'items/recipe_def.dart';
import 'ladder/ladder_record.dart' as ladder_record;
import 'skills.dart';
import 'player_profile.dart';
import 'profile_storage.dart';
import 'progression.dart';
import 'travel.dart';
import 'world.dart';

/// Owns the [PlayerProfile] and mediates every change to it, persisting after
/// each mutation. Screens read state and call intent methods; they never
/// touch storage directly.
class GameState extends ChangeNotifier {
  /// Swappable: local (shared_preferences) while a guest, Firestore once
  /// signed in. See [syncWithAuth].
  ProfileStorage storage;
  PlayerProfile profile;
  bool loading = true;

  /// The uid whose cloud profile is currently loaded (null = guest/local).
  String? _cloudUid;

  /// Set when a level-up happens so the UI can celebrate it once.
  int? pendingLevelUp;

  /// The level held *before* the pending level-up, so the screen can report
  /// what changed rather than only where you ended up.
  ///
  /// ⚠️ Needed because a single fight can cross more than one level, and
  /// "level 4 → 6" gains everything from both.
  int? pendingLevelUpFrom;

  /// The clock. Injectable so tests can move time instead of waiting five real
  /// minutes for a journey — without this the whole travel feature is
  /// untestable.
  ///
  /// ⚠️ Only used for *reading* elapsed time. A trip's `departedAt` is written
  /// by the server (`setToServerValue: REQUEST_TIME`) and validated in
  /// `firestore.rules`, because a client that could stamp its own departure
  /// could skip any wait.
  final DateTime Function() now;

  GameState(this.storage, this.profile, {DateTime Function()? now})
    : now = now ?? DateTime.now {
    settleTravel();
  }

  /// One-shot player-facing news about the save itself — a sync conflict, a
  /// repair — that no screen asked for. `HomeShell` shows it as a banner and
  /// clears it.
  ///
  /// ⭐ **A notifier, not a return value**, because the moments that produce
  /// it (boot, sign-in, any save) have no screen of their own to report to.
  final ValueNotifier<String?> notice = ValueNotifier<String?>(null);

  /// The banner after a refused save — see [_reloadAfterConflict].
  static const String conflictNotice =
      'Your save changed on another device — reloaded.';

  /// The banner after [PlayerProfile.repairContainers] dropped [count] items.
  static String repairNotice(int count) =>
      '$count ${count == 1 ? 'item' : 'items'} could not be recovered from an '
      'earlier sync conflict.';

  /// True while [_reloadAfterConflict] runs — its own guard against a loop.
  bool _reloading = false;

  static Future<GameState> boot(ProfileStorage storage) async {
    final loaded = await storage.load();
    final state = GameState(storage, loaded ?? PlayerProfile.newPlayer());
    state.loading = false;
    state._repair();
    // Migrate saves made when presets could hold more slots.
    for (final preset in state.profile.presets) {
      preset.clampToCaps();
    }
    state.profile.academyPreset.clampToCaps(
      elementBudget: Academy.elementSlots,
      spellBudget: Academy.spellSlots,
    );
    // ⚠️ …and saves made when a beltless character had two free belt slots.
    state.settleBeltOverflow();
    // ⚠️ …and saves from before a staff took both hands (ruling 2026-09-21).
    state.settleTwoHanded();
    await state._persist();
    return state;
  }

  /// Takes the offhand off a character wearing a two-hander over it — a
  /// wardrobe that no equip path can produce any more, but that a save from
  /// before the ruling still holds.
  ///
  /// ⭐ Idempotent and gentle: the knot goes to the pack when there is room,
  /// and otherwise stays where it is (a boot must never destroy an item); the
  /// next equip of anything resolves it through the normal displaced path.
  /// 📝 Wearing both is not a desync risk — gear totals are summed from the
  /// map — it is the illegal state the both-hands rule exists to forbid.
  void settleTwoHanded() {
    final main = wornDef(EquipSlot.mainHand);
    final offId = profile.equipped[EquipSlot.offHand];
    if (main == null || !main.twoHanded || offId == null) return;
    final offDefId = profile.itemInstances[offId]?.defId;
    if (offDefId == null) {
      profile.equipped.remove(EquipSlot.offHand); // dangling: nothing to keep
      return;
    }
    final next = profile.backpack.withAdded(
      InventorySlot(defId: offDefId, instanceId: offId),
    );
    if (next == null) return;
    profile.backpack = next;
    profile.equipped.remove(EquipSlot.offHand);
  }

  /// Reacts to sign-in/out. Signed in → load (or create) the cloud profile
  /// and route saves to Firestore; signed out → revert to the local guest
  /// profile. Called by the app whenever the auth user changes.
  Future<void> syncWithAuth(String? uid) async {
    if (uid == _cloudUid) return;
    _cloudUid = uid;
    if (uid != null) {
      final cloud = FirestoreProfileStorage(uid);
      final loaded = await cloud.load();
      storage = cloud;
      if (loaded != null) {
        // Adopt the existing cloud profile (progress from another session).
        _adopt(loaded);
        // ⚠️ Only a repair is worth a write here: adopting is a read.
        if (_repair()) await _persist();
      } else {
        // First time on this account — seed the cloud with the current
        // (guest) profile so nothing is lost. ⚠️ The seed is conditional on
        // the account having no character yet, so a load that failed on a
        // flaky network is refused here rather than overwriting a real save
        // with the guest's — and [_persist] reloads the real one instead.
        await _persist();
      }
    } else {
      final local = LocalProfileStorage();
      storage = local;
      profile = await local.load() ?? PlayerProfile.newPlayer();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await storage.save(profile);
    } on SaveConflictException {
      await _reloadAfterConflict();
    }
  }

  /// Another device saved since this one loaded, so this save was refused
  /// whole (`FirestoreProfileStorage.save`). Take the cloud's world.
  ///
  /// ⚠️ **The mutation in flight is lost, and that is correct**: it was made
  /// against a stale world — spending gold the other device already spent,
  /// depositing an item it already sold.
  ///
  /// ⚠️ **No loop.** A repair's follow-up save can itself be refused (a third
  /// save landed meanwhile); that refusal arrives while [_reloading] is set
  /// and is dropped. The next ordinary save retries against the version this
  /// reload fetched.
  Future<void> _reloadAfterConflict() async {
    if (_reloading) return;
    _reloading = true;
    try {
      final fresh = await storage.load();
      // Unreachable cloud: keep what is in memory; the next save asks again.
      if (fresh == null) return;
      _adopt(fresh);
      final repaired = profile.repairContainers();
      notice.value = repaired > 0
          ? '$conflictNotice ${repairNotice(repaired)}'
          : conflictNotice;
      notifyListeners();
      if (repaired > 0) await _persist();
    } finally {
      _reloading = false;
    }
  }

  /// Takes [loaded] as the profile, with the load-time migrations every
  /// cloud read needs (a cloud save is as old as a local one; each is
  /// idempotent, so running them again is free).
  void _adopt(PlayerProfile loaded) {
    profile = loaded;
    for (final preset in profile.presets) {
      preset.clampToCaps();
    }
    settleBeltOverflow();
  }

  /// [PlayerProfile.repairContainers], with its one banner. Returns whether
  /// anything changed, i.e. whether the caller must persist.
  bool _repair() {
    final dropped = profile.repairContainers();
    if (dropped == 0) return false;
    notice.value = repairNotice(dropped);
    return true;
  }

  @override
  void dispose() {
    notice.dispose();
    super.dispose();
  }

  Future<void> _mutate(void Function() change) async {
    change();
    // Every save is evidence the player is here, so presence rides along with
    // the write rather than needing its own heartbeat — no extra traffic, and
    // it tracks real activity instead of merely having the tab open.
    profile.lastSeenAt = DateTime.now();
    notifyListeners();
    await _persist();
  }

  /// Records activity without changing anything else — for moments that are
  /// presence but not progress (opening the app, entering a duel).
  Future<void> touchPresence() => _mutate(() {});

  // ---- Identity --------------------------------------------------------

  Future<void> setName(String name) => _mutate(
    () => profile.name = name.trim().isEmpty ? 'Apprentice' : name.trim(),
  );

  // ---- Travel ----------------------------------------------------------

  bool canTravelTo(String locationId) =>
      !isTravelling && profile.location.connections.contains(locationId);

  /// Why the gate at [locationId] will not let this character through, or null
  /// if it will. **Pure** — asks nothing, changes nothing.
  ///
  /// ⭐ **Asked AT the gate now, not at departure** (ruling, Christian
  /// 2026-09-25, mockup B). The road to a shut gate is always walkable; this
  /// is the guard's check when the player presses Unlock ([openGateAt]), and
  /// the gate screen's disabled button is the same answer drawn as tiles.
  ///
  /// Null in three cases, and the order matters:
  ///  1. the destination has no `gateItemIds` — most of the world, and the
  ///     four gates whose copy is written but whose items are not built yet;
  ///  2. it is already in `profile.openedGates` — ⭐ **checked before the
  ///     pack**, which is what makes an opening permanent (ruling, Christian
  ///     2026-09-21). Once through, never asked again;
  ///  3. every listed item is carried in the backpack.
  ///
  /// ⚠️ **Carried means the backpack.** A proof in a town storeroom is not on
  /// you, and the guard is looking at your hands.
  ///
  /// ⚠️ **The copy belongs to the Primal guard.** Pennycross is the only gate
  /// with items behind it today; the second one wants its own line rather
  /// than borrowing "the guard" and "proofs".
  String? gateRefusal(String locationId) {
    final want = World.byId(locationId).gateItemIds;
    if (want.isEmpty) return null;
    if (profile.openedGates.contains(locationId)) return null;
    final missing = [
      for (final id in want)
        if (profile.backpack.countOf(id) == 0) id,
    ];
    if (missing.isEmpty) return null;
    final names = <String>[];
    for (final id in missing) {
      final def = ItemCatalogue.tryById(id);
      names.add(def == null ? id : ItemCatalogue.displayName(def));
    }
    return 'The guard wants three proofs — you are missing '
        '${_listPhrase(names)}.';
  }

  /// Why the road to [toId] will not carry this character, or null if it will.
  /// **Pure** — same contract as [gateRefusal], so the Map tab can call it on
  /// every build.
  ///
  /// ⭐ **RULING (Christian, 2026-09-21): you cannot travel THROUGH a node you
  /// have not cleared.** *"I can travel to it, and I can travel back where I
  /// came from FROM it, but I shouldn't be able to travel to any other nodes
  /// through it until having beaten its boss at least once."* An uncleared
  /// zone is a dead end you may enter and must leave the way you entered — so
  /// Forgeholm is behind Old Quarry's boss, not behind a walk past it.
  ///
  /// Two halves, and they are genuinely different questions:
  ///  * **(a) the middle of the route.** Any stop that is neither the origin
  ///    nor the destination must be cleared. This is the Pennycross →
  ///    Forgeholm case: point-to-point travel would otherwise walk the whole
  ///    quarry without stopping in it.
  ///  * **(b) the ground you are standing on.** An uncleared origin offers
  ///    exactly one exit — [PlayerProfile.arrivedFromId], the door you came in
  ///    by. This is the Old-Quarry-to-Molten-Deep case, where the uncleared
  ///    node is a *stop* rather than a waypoint and (a) can never see it.
  ///
  /// ⭐ **Towns are never gates**, in either half. A town has no boss to beat,
  /// so `clearCountFor` would be zero forever and every road through
  /// Pennycross would shut — the rule would eat the world.
  ///
  /// ⚠️ **"Cleared" is [PlayerProfile.clearCountFor] > 0 — the boss, once.**
  /// Not discovery: walking into the quarry is exactly what this rule means to
  /// stop being enough.
  ///
  /// 📝 **A legacy save has no [PlayerProfile.arrivedFromId].** A character who
  /// was standing in an uncleared zone when this shipped cannot be asked which
  /// way they came, and stranding them is not an option — so under (b) a null
  /// lets them reach any **town** and refuses the other zones. That is the
  /// conservative reading: it can only cost a walk back to civilisation, never
  /// hand out a quarter of the map. One arrival writes the field and the
  /// normal rule takes over.
  ///
  /// ⭐ **(c) At a shut gate, the way you came is always open** (ruling
  /// 2026-09-25). 'Turn back' on the gate screen IS the road the player just
  /// walked, so neither half above may refuse it — [PlayerProfile.gateTurnBackId]
  /// is answered before them. ⚠️ Nothing else is refused here on the gate's
  /// account: `GateCheckpoint` shows the gate screen in place of the whole
  /// shell, so the one road a player at a shut gate can reach is this one.
  String? passageRefusal(String toId) {
    final fromId = profile.locationId;
    // (c) Before the route is even looked at — the rule it exempts from is
    // the route's.
    if (profile.shutGateHere != null && toId == profile.gateTurnBackId) {
      return null;
    }
    final route = Travel.route(fromId, toId);
    if (route == null || route.isTrivial) return null;

    // (a) The middle of the route. `stops` already has exactly the shape this
    // needs — origin first, destination last — so no accessor was added.
    for (final id in route.stops.sublist(1, route.stops.length - 1)) {
      if (_isUnclearedZone(id)) {
        return 'The road runs through ${World.byId(id).name}, and you have '
            'not cleared it.';
      }
    }

    // (b) The ground you are standing on.
    if (!_isUnclearedZone(fromId)) return null;
    final origin = World.byId(fromId).name;
    final cameFrom = profile.arrivedFromId;
    if (cameFrom == null) {
      if (World.byId(toId).isTown) return null;
      return 'Clear $origin first, or go back to a town.';
    }
    if (toId == cameFrom) return null;
    return 'Clear $origin first, or go back the way you came '
        '(${World.byId(cameFrom).name}).';
  }

  /// A place the passage rule can shut: not a town, and never cleared.
  bool _isUnclearedZone(String id) =>
      !World.byId(id).isTown && !profile.hasCleared(id);

  /// "A", "A and B", "A, B and C" — so a refusal naming two missing proofs
  /// reads like a sentence instead of a comma-separated dump.
  static String _listPhrase(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(", ")} and ${parts.last}';
  }

  /// True while a journey is under way.
  bool get isTravelling {
    settleTravel();
    return profile.trip != null;
  }

  /// Where the player actually is right now — the last stop reached, which is
  /// where they set out from until the first leg completes.
  String get currentLocationId {
    final trip = profile.trip;
    if (trip == null) return profile.locationId;
    return trip.stopReachedAt(now());
  }

  /// Begin a journey. The player arrives after the route's duration.
  ///
  /// Accepts any location with a route, not just a neighbour — WORLD_DESIGN
  /// §4b.2's point-to-point Travel. The Map tab still offers only neighbours
  /// until the travel UI is built; that is a UI limit, not a rule.
  ///
  /// ⭐ **A shut gate is NOT refused here** (ruling, Christian 2026-09-25,
  /// mockup B — reversing 2026-09-21's departure check). The trip proceeds
  /// and arrives at the gate ([PlayerProfile.shutGateHere]); the guard asks
  /// for the proofs there, on the gate screen, and nothing opens at
  /// departure any more.
  Future<bool> beginTravel(String toId, {String? mountId}) async {
    settleTravel();
    if (profile.trip != null || toId == profile.locationId) return false;
    if (passageRefusal(toId) != null) return false;
    final route = Travel.route(profile.locationId, toId);
    if (route == null || route.isTrivial) return false;

    // ⚠️ Client time, deliberately provisional. The server stamps the real
    // departure on write; this value only makes the UI honest until the
    // write lands, and cannot shorten a trip because the server overwrites it.
    await _mutate(() {
      profile.trip = ActiveTrip.fromRoute(
        route,
        now().toUtc(),
        mountId: mountId,
      );
    });
    return true;
  }

  /// Unlock the shut gate the player is standing at: the guard keeps the
  /// items, the gate opens for good, and any achievement it carries is
  /// earned — ⭐ **one write for all three**, so a crash can never leave the
  /// proofs spent and the gate shut, or the gate open with its achievement
  /// lost (ruling, Christian 2026-09-25). Returns whether it opened.
  ///
  /// Refuses (false, nothing written) unless [locationId] is
  /// [PlayerProfile.shutGateHere] and [gateRefusal] is satisfied — every
  /// item carried in the backpack.
  ///
  /// ⭐ **Consumed: exactly one of each gate item**, and nothing else in the
  /// pack — where the gate's guard keeps them ([Gates.guardKeepsItems]:
  /// Pennycross). A duplicate proof stays. ⚠️ A non-fungible item's instance
  /// record goes with its slot, or it would be orphaned in `itemInstances`.
  ///
  /// ⚠️ **Every other gate only looks** — Rimeholt's Celestial Totem is ruled
  /// keepable (CELESTIAL_CONTRACT §3.4), and this ruling did not reopen it.
  ///
  /// 📝 The achievement is added directly rather than through
  /// [grantAchievement], because that would be a second write. The caller
  /// tells "newly earned" by looking before it asks (see `GateScreen`).
  Future<bool> openGateAt(String locationId) async {
    settleTravel();
    if (profile.shutGateHere != locationId) return false;
    if (gateRefusal(locationId) != null) return false;
    final achievement = Gates.achievementFor(locationId);
    final spent = Gates.guardKeepsItems(locationId)
        ? World.byId(locationId).gateItemIds
        : const <String>[];
    await _mutate(() {
      for (final id in spent) {
        final pack = profile.backpack;
        final i = pack.slots.indexWhere((s) => s?.defId == id);
        final instanceId = pack.slots[i]?.instanceId;
        profile.backpack = pack.withRemovedAt(i);
        if (instanceId != null) profile.itemInstances.remove(instanceId);
      }
      profile.openedGates.add(locationId);
      if (achievement != null) profile.achievements.add(achievement.id);
    });
    return true;
  }

  /// Record achievement [id] as earned. ⭐ **Idempotent**: returns true only
  /// the first time, and a repeat grant writes nothing — so a caller may
  /// grant on every qualifying event and toast on `true` alone.
  ///
  /// ⚠️ An id the catalogue does not know (`Achievements.byId`) is refused,
  /// not stored: a typo would otherwise sit in every save forever, earned
  /// and invisible.
  Future<bool> grantAchievement(String id) async {
    if (Achievements.byId(id) == null) return false;
    if (profile.achievements.contains(id)) return false;
    await _mutate(() => profile.achievements.add(id));
    return true;
  }

  /// Arrive, if the clock says so. Cheap, idempotent, and safe to call often —
  /// this is what makes arriving while the app was closed unremarkable.
  ///
  /// ⚠️ Does not persist by itself. Callers that change state persist anyway;
  /// a settle with nothing to save should not cost a write on every frame.
  bool settleTravel() {
    final trip = profile.trip;
    if (trip == null) return false;
    final at = now();
    // Reveal stops as they are passed, so a cancel never strands the player
    // somewhere they have never seen.
    profile.discoveredLocationIds.addAll(trip.stopsSeenAt(at));
    if (!trip.isCompleteAt(at)) return false;
    // ⭐ The door you came in by, recorded **on arrival** (ruling 2026-09-21).
    // The trip's ORIGIN, not the last leg's start: a route that ran
    // Pennycross → Old Quarry → Forgeholm was only legal because the quarry
    // was cleared, and what an uncleared *destination* owes you a way back to
    // is where you set out from. See [passageRefusal] (b).
    profile.arrivedFromId = trip.fromId;
    profile.locationId = trip.toId;
    profile.trip = null;
    return true;
  }

  /// Arrive now if due, persisting and notifying if anything changed. For the
  /// UI's ticker.
  Future<void> tick() async {
    if (settleTravel()) await _mutate(() {});
  }

  /// ⭐ Abandon the journey, stopping at **the last place actually reached** —
  /// not back where it started (ruling, 2026-07-28). Instant.
  Future<void> cancelTravel() async {
    final trip = profile.trip;
    if (trip == null) return;
    final at = now();
    await _mutate(() {
      profile.locationId = trip.stopReachedAt(at);
      profile.discoveredLocationIds.addAll(trip.stopsSeenAt(at));
      profile.trip = null;
    });
  }

  /// Starts a journey to a neighbouring location. Kept for the Map tab, which
  /// offers neighbours only.
  ///
  /// ⭐ **Returns the refusal, if there is one** — the first thing this method
  /// has ever had to say. Every other way it declines (already travelling, not
  /// a neighbour) is a tile the UI had already greyed out, so `void` was
  /// honest; a refused road is different, because the player is owed a
  /// reason. Null means "under way, or nothing to say".
  ///
  /// ⭐ **One refusal: the road** ([passageRefusal]). The guard's used to come
  /// first; since the 2026-09-25 ruling a shut gate is somewhere you arrive,
  /// not something that stops you leaving, so it has nothing to say here.
  ///
  /// ⚠️ Returned, not thrown. `interactive_world_map`'s `_travel` already
  /// catches around this call to report a *save* failure as a modal, and a
  /// thrown refusal would arrive there wearing that alert's words.
  Future<String?> travelTo(String locationId) async {
    final refusal = passageRefusal(locationId);
    if (refusal != null) return refusal;
    if (!canTravelTo(locationId)) return null;
    await beginTravel(locationId);
    return null;
  }

  // ---- Duel results ----------------------------------------------------

  /// Applies XP/gold for a finished duel and flags any level-up.
  ///
  /// ⚠️ **[bossDefeated] must come from the caller, not be inferred here.**
  /// A zone counts as cleared when its *boss* falls, and this method cannot
  /// tell a boss from a wandering common — so it is passed in. ⭐ Deliberately
  /// **not** defaulted to `won`: an adventure in Phase 1 is a single ordinary
  /// duel, and treating any win as a clear would hand out repeat-clear content
  /// (ENEMIES §2e) the moment real bosses land.
  ///
  /// ⚠️ **[pvp] defaults to false, and that is the safe direction** (ruling
  /// 2026-08-17: a single-player loss pays no XP). A call site that forgets the
  /// flag under-pays a human duel; a default of `true` would let every farmable
  /// AI loss pay out, which is the abuse the ruling closes. `launchDuel` is the
  /// only path that can see a remote opponent, and it is the only one that
  /// passes it.
  Future<void> recordDuelResult({
    required bool won,
    int opponentLevel = 1,
    bool bossDefeated = false,
    String? locationId,
    bool pvp = false,
  }) async {
    final before = profile.level;
    await _mutate(() {
      // ⭐ XP scales with who you beat (10/level), so the fight worth taking
      // is the one that pays. Gold is deliberately still flat — scaling both
      // would make the economy climb as steeply as the power curve.
      profile.xp += Progression.xpForDuel(
        won: won,
        opponentLevel: opponentLevel,
        pvp: pvp,
      );
      if (won) {
        profile.gold += Progression.winGold;
        profile.duelsWon++;
        if (bossDefeated) {
          final zone = locationId ?? profile.locationId;
          profile.zoneClears[zone] = profile.clearCountFor(zone) + 1;
        }
      } else {
        profile.gold += Progression.lossGold;
        profile.duelsLost++;
      }
    });
    final after = profile.level;
    if (after > before) {
      pendingLevelUp = after;
      pendingLevelUpFrom = before;
      notifyListeners();
    }
  }

  /// Applies one rated-duel result to the profile (LADDER_DESIGN §2) — the
  /// same save path as every other mutation. ⭐ Wraps the PURE
  /// `ladder_record.applyRatedResult` (imported under a prefix so this
  /// method can share its name without shadowing it) in [_mutate], exactly
  /// like [recordDuelResult] wraps its own XP/gold math. See
  /// `ladder/ladder_result.dart`'s `settleRatedDuel`, the only caller.
  Future<void> applyRatedResult({
    required bool academy,
    required int newRating,
    required bool won,
  }) => _mutate(() {
    ladder_record.applyRatedResult(
      profile,
      academy: academy,
      newRating: newRating,
      won: won,
    );
  });

  /// Records the id of the ladder bot this player last fought (LADDER §3:
  /// the search excludes it next time so two people online at once — or one
  /// person queuing twice in a row — don't both/always meet the same face).
  /// Null after a HUMAN match: only a bot leaves a face to avoid repeating.
  Future<void> setLastOpponentBotId(String? id) =>
      _mutate(() => profile.lastOpponentBotId = id);

  // ---- Gathering --------------------------------------------------------

  /// Harvests the gathering spot in front of the player.
  ///
  /// ⭐ **One simultaneous harvest** (ITEMS §9b.7 ruling): the whole yield in
  /// one act, the node spent, the run moves on.
  ///
  /// ⭐ **Straight into the backpack** (ruling 2026-08-17). Gathered materials
  /// are fungible, so nothing is registered in the instance pool and there is
  /// nothing to choose from — a picker for eight identical logs would be a
  /// chore, not a decision.
  ///
  /// ⚠️ **All or nothing, and a refusal leaves the spot standing.** Splitting a
  /// yield across a nearly-full pack would silently drop the remainder, which
  /// is the failure mode this whole redesign exists to end; instead the node
  /// stays unspent and rides along with the run until there is room. The
  /// quantity is re-rolled on the next attempt — a refused harvest costs
  /// nothing, including the roll it never used.
  ///
  /// Skill XP banks on a **successful** harvest only: a refusal is not effort.
  ///
  /// 📝 The gesture act (node.def.step) is not played yet; when the engines
  /// exist, [performance] arrives the same way craft()'s does.
  Future<GatherOutcome> gatherNode({Random? rng}) async {
    final r = run;
    final node = r?.currentNode;
    if (r == null || node == null) {
      return const GatherOutcome.refused('There is nothing to gather here.');
    }
    final def = node.def;
    final roll = rng ?? Random();
    final amount = def.min + roll.nextInt(def.max - def.min + 1);
    final free = profile.backpack.free;
    // ⭐ Room, not slots (stacking ruling, 2026-09-25) — a yield that stacks
    // tops up what is carried first. For every yield today (logs, ore,
    // herbs) the two are the same number.
    if (profile.backpack.roomFor(def.yieldsDefId) < amount) {
      final yieldDef = ItemCatalogue.tryById(def.yieldsDefId);
      final name = yieldDef == null
          ? def.yieldsDefId
          : ItemCatalogue.displayName(yieldDef);
      return GatherOutcome.refused(
        'No room for $amount × $name — '
        '${free == 0 ? 'your pack is full' : 'only $free slots free'}. '
        'The spot will wait.',
      );
    }
    final levelBefore = profile.skillLevel(def.skill.name);
    await _mutate(() {
      node.spent = true;
      var pack = profile.backpack;
      for (var i = 0; i < amount; i++) {
        // ⚠️ Checked above, but the pack is still asked — it is the only
        // authority on its own room, and `?? pack` here means a miscount can
        // cost an item rather than crash on a null. One at a time, so a
        // stacking yield tops up exactly as a single add would.
        pack = pack.withAdded(InventorySlot(defId: def.yieldsDefId)) ?? pack;
      }
      profile.backpack = pack;
      profile.skillXp[def.skill.name] =
          (profile.skillXp[def.skill.name] ?? 0) + def.xp;
    });
    final levelAfter = profile.skillLevel(def.skill.name);
    return GatherOutcome.gathered(
      defId: def.yieldsDefId,
      amount: amount,
      xp: def.xp,
      skillKey: def.skill.name,
      leveledTo: levelAfter > levelBefore ? levelAfter : null,
    );
  }

  // ---- Crafting ---------------------------------------------------------

  /// How many [defId] a craft may count on: what is carried, plus what this
  /// town's Storeroom holds when standing in a town.
  ///
  /// ⭐ **One reader for the craft gate and for every "have N" the Workbench
  /// prints**, so they cannot disagree. A row that reads "3 / 3 ✓" above a
  /// refusal that reads "Needs 1 more Oak Log" is the exact bug this exists to
  /// make unrepresentable.
  ///
  /// ⚠️ **Town-only, resolved exactly as [equipFromStoreroom] resolves it**
  /// (`profile.location.isTown`): a Storeroom is per city (ITEMS §10.3c), so
  /// on the road this is the backpack and nothing else. 📝 Stacks only — a
  /// Storeroom's `instanceIds` are distinct physical things, never the
  /// fungible inputs a recipe names.
  int materialCount(String defId) {
    final split = materialSplit(defId);
    return split.pack + split.stored;
  }

  /// [materialCount] split into its two sources, for a UI that wants to say
  /// *where* the materials are ("3 / 3 ✓ (1 stored)").
  ({int pack, int stored}) materialSplit(String defId) {
    final pack = profile.backpack.countOf(defId);
    if (!profile.location.isTown) return (pack: pack, stored: 0);
    final stored = profile.storerooms[profile.locationId]?.stacks[defId] ?? 0;
    return (pack: pack, stored: stored);
  }

  /// Makes [recipe]'s output from the materials to hand: checks the gate,
  /// consumes the inputs, mints the item, pays skill XP.
  ///
  /// ⭐ **Works anywhere** (ITEMS §9b.2 — stations are convenience, never a
  /// gate). ⭐ **Inputs come from the backpack *and*, in town, from this
  /// town's Storeroom** (ruling 2026-09-21) — [materialCount] is the one
  /// reader of "how many do I have". Consumption is **pack first, Storeroom
  /// second**: the pack is what the player carries into the field, so
  /// emptying it first frees the slots the output wants.
  ///
  /// ⚠️ **Space is no longer safe by arithmetic.** Every recipe consumes ≥1
  /// slot of fungible inputs and yields exactly 1 slot, so a craft whose
  /// inputs all came from the pack can never overflow it — but an input drawn
  /// from the Storeroom frees no slot, so such a craft can *net* a pack slot
  /// and the output may not fit. When it does not, the output is deposited
  /// into this town's Storeroom instead (you are standing in one, and it is
  /// unbounded) and [CraftOutcome.note] says so. ⚠️ The output is never
  /// silently dropped: a crafted item that vanishes is the worst failure
  /// available here. The assert still guards the recipe that would break the
  /// arithmetic for a pure-pack craft.
  ///
  /// ⭐ **The performance seam is live** (ruling 2026-08-18, quality affects
  /// stats): [performance] is the crafting act's grade (0–1) and feeds the
  /// §9b.9d pipeline, which mints a [Quality] onto the output. 📝 Until the
  /// minigame lands nothing calls this with a grade below 1, so the Workbench
  /// button crafts at a perfect grade — the roll still decides the tier, which
  /// is exactly the ruling ("the grade is a ceiling, never a guarantee").
  ///
  /// [rng] is injectable so a test can pin the roll; production rolls fresh.
  Future<CraftOutcome> craft(
    RecipeDef recipe, {
    double performance = 1,
    Random? rng,
  }) async {
    final skillKey = recipe.skill.name;
    final have = profile.skillLevel(skillKey);
    if (have < recipe.skillLevel) {
      return CraftOutcome.refused(
        'Needs ${Skills.displayName(skillKey)} ${recipe.skillLevel} — '
        'you are $have.',
      );
    }
    for (final input in recipe.inputs) {
      final short = input.count - materialCount(input.defId);
      if (short > 0) {
        final def = ItemCatalogue.tryById(input.defId);
        final name = def == null ? input.defId : ItemCatalogue.displayName(def);
        return CraftOutcome.refused('Needs $short more $name.');
      }
    }
    final outputDef = ItemCatalogue.tryById(recipe.outputId);
    if (outputDef == null) {
      // A recipe pointing at nothing is a content bug, not a player problem.
      return CraftOutcome.refused('That cannot be made.');
    }
    assert(
      recipe.inputs.fold<int>(0, (a, i) => a + i.count) >= recipe.outputCount,
      'a recipe that nets slots would make craft() able to overflow the pack',
    );

    // ⭐ The quality roll, through the one pipeline (§9b.9d): the grade sets
    // the ceiling, the margin lifts the floor, and the level caps both. ⚠️
    // Rolled ONCE per act — one execution is one performance, so a recipe that
    // ever yields two non-fungible items yields two of the same tier.
    // 📝 Bench and tool bonuses are the margin's other two terms and are not
    // modelled yet; when they are, they arrive here.
    final margin = CraftQuality.margin(
      skillLevel: have,
      recipeGate: recipe.skillLevel,
    );
    final quality = CraftQuality.roll(
      grade: performance.clamp(0, 1),
      margin: margin,
      rng: rng ?? Random(),
      skillCeiling: CraftQuality.skillCeiling(margin),
    );

    final levelBefore = profile.skillLevel(skillKey);
    final gained = Skills.xpForRecipe(recipe);
    // ⚠️ Read once, before the write: the Storeroom this craft may draw from
    // and stow into is the one under the character's feet, and nothing inside
    // [_mutate] may move them.
    final here = profile.locationId;
    final inTown = profile.location.isTown;
    ItemInstance? minted;
    var stowed = false;
    await _mutate(() {
      var pack = profile.backpack;
      var room = profile.storerooms[here];
      for (final input in recipe.inputs) {
        // ⭐ Pack first, Storeroom second — see the doc comment. Reversing
        // these two loops would hoard the pack and starve the output of slots.
        var need = input.count;
        // ⭐ By count, across stacks (2026-09-25): 30 Dust from [25, 5] is
        // one removal of 30, smallest stack first, and leaves nothing.
        final fromPack = pack.countOf(input.defId) < need
            ? pack.countOf(input.defId)
            : need;
        pack = pack.withRemovedFirst(input.defId, n: fromPack);
        need -= fromPack;
        while (need > 0 && inTown) {
          final took = (room ?? const Storeroom()).withWithdrawn(
            InventorySlot(defId: input.defId),
          );
          // ⚠️ Gated above on the same `stacks` this reads, so a short
          // withdrawal cannot happen; the break is defensive, and it errs
          // toward the player (the craft completes having consumed less)
          // rather than toward a throw inside a save.
          if (took.taken == null) break;
          room = took.room;
          need--;
        }
      }
      for (var n = 0; n < recipe.outputCount; n++) {
        InventorySlot slot;
        if (outputDef.isFungible) {
          slot = InventorySlot(defId: outputDef.id);
        } else {
          // ⭐ The roll rides the instance, which is the only thing that
          // knows what THIS one is worth (Equipping.modifiersOf reads it).
          // ⚠️ Fungible outputs — every consumable — get no instance and so
          // no quality, deliberately: two draughts are interchangeable.
          minted = ItemInstance(
            instanceId: _mintCraftId(),
            defId: outputDef.id,
            quality: quality,
          );
          profile.itemInstances[minted!.instanceId] = minted!;
          slot = InventorySlot(
            defId: outputDef.id,
            instanceId: minted!.instanceId,
          );
        }
        final next = pack.withAdded(slot);
        if (next != null) {
          pack = next;
        } else if (inTown) {
          // ⚠️ The pack only fills here when inputs came out of storage — the
          // arithmetic covers every other craft. Stow rather than drop.
          room = (room ?? const Storeroom()).withDeposited(slot);
          stowed = true;
        }
      }
      profile.backpack = pack;
      // ⚠️ Only when this craft touched it — an untouched town must not grow
      // an empty Storeroom entry in every save.
      if (room != null) profile.storerooms[here] = room;
      profile.skillXp[skillKey] = (profile.skillXp[skillKey] ?? 0) + gained;
    });
    final levelAfter = profile.skillLevel(skillKey);
    return CraftOutcome.made(
      defId: outputDef.id,
      xp: gained,
      skillKey: skillKey,
      leveledTo: levelAfter > levelBefore ? levelAfter : null,
      instance: minted,
      note: stowed
          ? 'Made ${ItemCatalogue.displayName(outputDef, minted)} — stowed in '
                'your storeroom (pack full).'
          : null,
    );
  }

  static int _craftMintCounter = 0;

  /// Instance ids for crafted goods — same shape as drop minting (loot.dart),
  /// distinct prefix so provenance is readable in a raw save.
  String _mintCraftId() =>
      'c${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${(_craftMintCounter++).toRadixString(36)}';

  // ---- Adventures -------------------------------------------------------

  /// The run in progress, if any.
  ///
  /// ⭐ **Stored on the profile, not here**, so every existing [_mutate] write
  /// carries it to disk for free — see the resume ruling on
  /// [PlayerProfile.run]. This pair stays because a run is *asked for* as
  /// `game.run` from a dozen call sites, and routing them through the profile
  /// would say nothing extra.
  AdventureRun? get run => profile.run;
  set run(AdventureRun? value) => profile.run = value;

  /// Starts a run at [zone].
  ///
  /// ⚠️ Async now that the run is saved — the rolled line **is** the run, and
  /// a crash before the first fight must not leave a zone half-entered.
  Future<AdventureRun> beginAdventure(GameLocation zone, {Random? rng}) async {
    // 📝 No overwrite guard any more: a run no longer *holds* anything the
    // player has earned (ruling 2026-08-17). Everything kept is already in the
    // pack, so starting a new adventure can only discard a picker that was
    // walked away from — which is the same answer as declining it.
    final started = AdventureRun.roll(
      zone: zone,
      roster: Bestiary.forZone(zone.id),
      // ⚠️ **[maxHp], not the bare level curve.** The duel builds the player's
      // pool as curve + gear (DuelController._buildMage), so seeding the run
      // from the curve alone walked a fully-healed mage into the first fight
      // already missing every point their robes grant — the "148 / 159 when
      // combat loaded" report. Healing in the field reads [maxHp] too, so
      // this is also the only seed that makes a full ration a no-op at full
      // health rather than a top-up of a gap that should not exist.
      playerHp: maxHp,
      rng: rng ?? Random(),
    );
    await _mutate(() => profile.run = started);
    return started;
  }

  /// Records a won encounter, rolling its drops onto the run as an
  /// **unanswered picker** ([AdventureRun.unclaimed]).
  ///
  /// ⭐ Returns the def ids that dropped, so the end screen can show them
  /// **before** it renders. Rolling after the duel screen popped would leave
  /// nothing to display.
  ///
  /// ⚠️ Nothing reaches the backpack here. The player chooses immediately after
  /// the fight ([claimVictoryLoot]) — the drops sit on the run only for the
  /// seconds in between, and survive a force-quit taken in those seconds.
  Future<List<String>> winEncounter({
    required int remainingHp,
    Random? rng,
  }) async {
    final r = run;
    if (r == null || r.isOver) return const [];
    final enemy = r.current!;
    // ⭐ Defaulting inside rollKill (lootRng, one long-lived stream) — the
    // hygiene half of the 2026-08-17 drop audit; both shapes measured at 10%.
    // ⭐ rollKill, not rollDrops: the rank is what earns a boss its
    // guaranteed rare-or-better piece of this zone's gear (ruling 2026-09-25).
    final loot = rollKill(
      enemy.def.drops,
      rank: enemy.def.rank,
      zoneId: r.zoneId,
      rng: rng,
    );
    // ⚠️ `atFinalBoss`, not `atBoss`: a zone counts as cleared when the LAST
    // boss of the line falls. Identical to `atBoss` in every zone but The
    // Eclipsed Citadel, whose two bosses are a sequence (ENEMIES §2e) — there,
    // `atBoss` would bank the clear on Totality and leave Procarius unfought.
    final wasBoss = r.atFinalBoss;
    r.recordVictory(
      loot: loot.slots,
      instances: loot.instances,
      remainingHp: remainingHp,
    );
    // ⭐ No explicit save: the run lives on the profile, so the write inside
    // recordDuelResult below banks the new index and HP along with the XP.
    await recordDuelResult(
      won: true,
      opponentLevel: enemy.level,
      bossDefeated: wasBoss,
      locationId: r.zoneId,
    );
    // ⚠️ **The boss fight is not special.** Its drops go through the very same
    // picker as encounter one's, so the last fight of a run cannot drift into
    // rules of its own.
    notifyListeners();
    return [for (final slot in loot.slots) slot.defId];
  }

  /// Records a lost encounter — ⚠️ **the defeat penalty of the 2026-08-17
  /// ruling: the backpack is emptied.**
  ///
  /// > *"If you die in single-player, you lose everything in your INVENTORY —
  /// > but nothing that's equipped, and the belt (the worn belt AND its loaded
  /// > consumables) is SAFE."*
  ///
  /// ⭐ Three exemptions, each load-bearing:
  /// - **Worn gear** never enters the backpack, so it is safe by construction;
  ///   the `equipped` check below only guards the instance *pool*, so a wipe
  ///   can never orphan the staff still in your hand.
  /// - **The belt** is a list of def ids, not pack slots, so its loaded
  ///   consumables are untouched here — deliberately, per the ruling: the
  ///   things that keep you alive are the things you do not lose for dying.
  /// - **Storerooms** hold their own instance ids and are never iterated.
  ///
  /// Returns how many items were lost — ⚠️ stacks counted by their `count`
  /// since 2026-09-25 — so the screen can say it plainly. A penalty the player
  /// is not told about is indistinguishable from a bug.
  Future<int> loseEncounter({Random? rng}) async {
    final r = run;
    if (r == null || r.isOver) return 0;
    final enemy = r.current!;
    var lost = 0;
    await _mutate(() {
      final worn = profile.equipped.values.toSet();
      for (final slot in profile.backpack.contents) {
        // ⭐ Items, not slots — a 25-stack of Dust is 25 things lost, and the
        // banner says "items".
        lost += slot.count;
        final id = slot.instanceId;
        // ⚠️ An instance the paper doll still points at must outlive the wipe —
        // removing it would leave `equipped` naming an item that no longer
        // exists, which reads as your gear evaporating.
        if (id != null && !worn.contains(id)) profile.itemInstances.remove(id);
      }
      profile.backpack = Backpack.empty();
      r.recordDefeat();
    });
    // The defeat rides to disk on recordDuelResult's write, same as a win.
    // ⚠️ No `pvp` flag: a campaign death is single-player, so it pays 0 XP.
    await recordDuelResult(won: false, opponentLevel: enemy.level);
    notifyListeners();
    return lost;
  }

  /// Records a **fled** encounter: the player rolled a clean escape and the
  /// run ends here (2026-08-17 flee ruling).
  ///
  /// ⭐ **This is the walk-out path, not the defeat path.** Fleeing routes
  /// through [leaveAdventure] — outcome [RunOutcome.returned], the pending
  /// haul intact and waiting on the take-home picker, the backpack untouched.
  /// ⚠️ Deliberately does NOT call [recordDuelResult]: a duel nobody won pays
  /// no XP, adds no gold, and must not tick `duelsLost`. Routing this anywhere
  /// near [loseEncounter] would hand the player the full death penalty for
  /// successfully getting away, which is the exact bug the ruling replaced.
  Future<void> fleeEncounter({required int remainingHp}) async {
    final r = run;
    if (r == null || r.isOver) return;
    // Truthful to the last, even though the run is ending: the HP the player
    // escaped with is the HP the ending screen reads. Set before the call so
    // it rides [leaveAdventure]'s own write to disk rather than a second one.
    r.playerHp = remainingHp;
    await leaveAdventure();
  }

  /// Uses a carried item between encounters.
  ///
  /// ⭐ Removes it **only if it was actually spent** — an item that changed
  /// nothing stays in the pack, because a game that eats your food for no
  /// benefit is worse than one that refuses.
  Future<UseOutcome> useItem(String defId) async {
    final r = run;
    if (r == null) return const UseOutcome.refused('Not on an adventure.');
    final outcome = r.use(
      defId,
      // ⭐ Gear reaches the road too: worn HP raises the pool a potion heals
      // against, and healing received % multiplies what it restores.
      maxHp: maxHp,
      carried: profile.backpack.countOf(defId) > 0,
      healingReceivedPercent: equipmentTotals.healingReceivedPercent,
      // ⭐ The belt's potency reaches the road too (ruling 2026-09-25).
      consumablePotencyPercent: equipmentTotals.consumablePotencyPercent,
    );
    if (outcome.consumed) {
      // ⚠️ One write for both halves — the item leaving the pack and the HP it
      // bought must never land on disk separately.
      await _mutate(() {
        profile.backpack = profile.backpack.withRemovedFirst(defId);
      });
    }
    notifyListeners();
    return outcome;
  }

  /// Drinks one [defId] **off the belt**, between encounters.
  ///
  /// ⭐ The twin of [useItem], and deliberately a separate door: the belt is
  /// not the pack, so the carried check reads the belt and the spend unloads a
  /// belt slot rather than emptying a pack slot. Everything in between — the
  /// effect, the healing-received multiplier, the refusal at full health — is
  /// the same `AdventureRun.use`, so a potion cannot heal differently for
  /// hanging on your hip.
  ///
  /// ⚠️ **Free between fights** (ITEMS §6b.2). The belt only costs a turn
  /// *mid-duel* — see [consumeBeltItem], which is the in-combat door. Charging
  /// a turn here would charge it against nothing.
  ///
  /// ⚠️ Unloads **one** copy, and only when the use was actually consumed: two
  /// draughts on the belt means one drink leaves one, and a refusal leaves
  /// both. A refusal that still emptied the slot would be the game drinking
  /// your potion for you.
  Future<UseOutcome> useBeltItem(String defId) async {
    final r = run;
    if (r == null) return const UseOutcome.refused('Not on an adventure.');
    final outcome = r.use(
      defId,
      maxHp: maxHp,
      carried: profile.belt.loaded.contains(defId),
      healingReceivedPercent: equipmentTotals.healingReceivedPercent,
      // ⭐ The belt's potency reaches the road too (ruling 2026-09-25).
      consumablePotencyPercent: equipmentTotals.consumablePotencyPercent,
    );
    if (outcome.consumed) {
      // ⚠️ One write for both halves — the potion leaving the belt and the HP
      // it bought must never land on disk separately.
      await _mutate(() {
        profile.belt = profile.belt.withUnloaded(defId);
      });
    }
    notifyListeners();
    return outcome;
  }

  /// Destroys the backpack slot at [index]. **Nothing comes back.**
  ///
  /// ⭐ **The road's answer to a full pack** (playtest ruling, 2026-09-21). A
  /// player who filled twenty slots with dust had no way to make room for the
  /// boss drop, because selling needs a shop and a shop needs a town. So the
  /// road gets destruction and only destruction: no refund, no Storeroom, no
  /// "drop it here and come back" pile to implement and then explain.
  ///
  /// ⚠️ **Refused in town**, with the answer rather than a shrug — in town the
  /// shop pays for the same slot, and a player who burns a staff standing in
  /// front of a buyer was failed by the UI, not by themselves.
  ///
  /// ⚠️ **The instance dies with the slot** (the one-pool rule, ITEMS §10.3a).
  /// A rolled item's `ItemInstance` lives in `profile.itemInstances`, not in
  /// the slot; dropping the slot and leaving the instance leaks a staff into
  /// the save forever, growing every file that ever dropped one.
  ///
  /// Returns a player-facing refusal, or null when the item is gone.
  Future<String?> discardFromBackpack(int index) async {
    final r = run;
    // ⚠️ The gate is the *run*, not the location: the road is where there is
    // no shop, and a finished run is already standing in town in every way
    // that matters — ⭐ except while the boss's spoils or the boss's gathering
    // spot are still in front of the player (`AdventureRun.onTheRoad`, ruling
    // 2026-09-25). The boss picker is the one most likely to meet a full pack.
    if (r == null || !r.onTheRoad) return 'Sell it in town.';
    if (index < 0 || index >= profile.backpack.slots.length) {
      return 'There is nothing there.';
    }
    final slot = profile.backpack.slots[index];
    if (slot == null) return 'There is nothing there.';
    await _mutate(() {
      profile.backpack = profile.backpack.withRemovedAt(index);
      final id = slot.instanceId;
      if (id != null) profile.itemInstances.remove(id);
    });
    return null;
  }

  /// Walks out early.
  ///
  /// ⭐ **Ends the run and nothing else** — and since the 2026-08-17 ruling
  /// that is the whole truth: every fight already handed its loot over, so
  /// there is nothing left to bank, nothing to claim, and no in-between state
  /// on disk. Walking out is now exactly as cheap as it sounds.
  Future<void> leaveAdventure() async {
    final r = run;
    if (r == null || r.isOver) return;
    await _mutate(r.returnToTown);
  }

  /// The ticks the victory picker opens with: indices into `run.unclaimed`,
  /// best first, already trimmed to what will fit.
  ///
  /// ⭐ **Rarity descending, so the last free slot is spent on the best thing
  /// found.** A playtester once lost a rare to a silent overflow that abandoned
  /// whatever happened to be last in the list; a player who just taps confirm
  /// must never lose the item they were excited about.
  ///
  /// ⭐ **Trimmed by what fits, not by free slots** (stacking ruling,
  /// 2026-09-25) — `lootThatFits` offers each row to the pack, so Dust that
  /// tops up a carried stack is ticked even when no slot is free.
  List<int> get defaultVictoryChoice {
    final r = run;
    if (r == null) return const [];
    return lootThatFits(profile.backpack, r.unclaimed, r.unclaimedInstances);
  }

  /// Takes the chosen part of the last victory's drops; abandons the rest.
  ///
  /// [chosen] holds indices into `run.unclaimed`. ⭐ **Everything not chosen is
  /// gone for good**, and that is the point: the player decides what a full
  /// pack costs them, at the moment the loot appears, rather than finding out
  /// afterwards that something was quietly dropped.
  ///
  /// ⚠️ **Clamped, never refused.** A selection bigger than the free slots
  /// keeps its [lootDisplayOrder] prefix and abandons the remainder — a confirm
  /// button that silently does nothing reads as a broken game, and refusing
  /// would strand the run holding a picker it can never close.
  ///
  /// Returns what landed and what was left, so the screen can report both
  /// halves; a loss the player is not told about is the bug this replaced.
  Future<({List<InventorySlot> taken, List<InventorySlot> left})>
  claimVictoryLoot(Iterable<int> chosen) async {
    final r = run;
    if (r == null || r.unclaimed.isEmpty) {
      return (taken: const <InventorySlot>[], left: const <InventorySlot>[]);
    }
    final taken = <InventorySlot>[];
    final left = <InventorySlot>[];
    await _mutate(() {
      // ⭐ The clamp is `lootThatFits` — the picker's own walk — so a row the
      // picker ticked is a row that lands, stacks and all (2026-09-25).
      final wanted = lootThatFits(
        profile.backpack,
        r.unclaimed,
        r.unclaimedInstances,
        // ⚠️ Filtered for range here rather than trusted: these indices come
        // from a screen, and a stale one must not read off the end.
        only: {
          for (final i in chosen)
            if (i >= 0 && i < r.unclaimed.length) i,
        },
      ).toSet();

      var pack = profile.backpack;
      // ⚠️ Added in display order — the order `lootThatFits` measured in. With
      // stacks, the order changes what fits, so any other walk could refuse a
      // row the clamp just promised.
      for (final i in lootDisplayOrder(r.unclaimed, r.unclaimedInstances)) {
        final slot = r.unclaimed[i];
        // ⚠️ The pack is still asked even though `wanted` is already clamped —
        // it is the only authority on whether it has room, and belt-and-braces
        // here is what stops loot vanishing rather than overflowing.
        final next = wanted.contains(i) ? pack.withAdded(slot) : null;
        if (next == null) {
          left.add(slot);
          continue;
        }
        pack = next;
        taken.add(slot);
        // ⭐ Only an instance whose slot was taken enters the pool. An
        // abandoned staff's rolls must not outlive the staff: a dangling
        // instance is a save that grows forever and a name for an item nobody
        // owns (ITEMS §10.3a, and `PlayerProfile` guards the other direction).
        final id = slot.instanceId;
        final inst = id == null ? null : r.unclaimedInstances[id];
        if (inst != null) profile.itemInstances[id!] = inst;
      }
      profile.backpack = pack;
      // ⚠️ Emptied **inside** the write, taken and abandoned alike. Clearing
      // after it would save a run still holding loot that is already in the
      // backpack, and reopening the app would hand it over a second time.
      r.unclaimed.clear();
      r.unclaimedInstances.clear();
    });
    return (taken: taken, left: left);
  }

  // ---- Storeroom --------------------------------------------------------

  /// Puts the backpack slot at [index] into [townId]'s Storeroom.
  ///
  /// ⚠️ **Per city** (ITEMS §10.3c) — this never touches another town's.
  /// The sum of everything worn. ⭐ The single number the duel, the belt and
  /// the Inventory screen all read (Equipping.totals).
  ItemModifiers get equipmentTotals => Equipping.totals(
    equipped: profile.equipped,
    instances: profile.itemInstances,
  );

  /// The health pool the player actually fights with: the level curve plus
  /// whatever the worn gear adds.
  ///
  /// ⭐ **One definition, read by both [useItem] and the Pack panel's Health
  /// line** (the adventure screen, above its Use buttons), so
  /// the "61 / 120" on screen is the same 120 a ration heals against. Two call
  /// sites computing this apart is how "the potion did nothing" gets reported
  /// as a bug when the player was simply already full.
  int get maxHp =>
      MageState.scaledMaxHp(profile.level) + equipmentTotals.maxHpBonus;

  /// The [EquipmentDef] currently worn in [slot], or null for an empty slot
  /// (or a dangling instance id, which wears nothing).
  ///
  /// ⭐ **The wardrobe question `Equipping` cannot answer for itself** — its
  /// rules are pure over a def, and the both-hands rule needs to know what is
  /// already on. Public because the Inventory tab asks the same question to
  /// grey out the same button.
  EquipmentDef? wornDef(EquipSlot slot) {
    final id = profile.equipped[slot];
    if (id == null) return null;
    final def = ItemCatalogue.tryById(profile.itemInstances[id]?.defId ?? '');
    return def is EquipmentDef ? def : null;
  }

  /// Equips the item in backpack slot [index].
  ///
  /// Returns a player-facing refusal, or null on success. ⭐ **A swap, not a
  /// move**: whatever was worn in that slot lands in the vacated backpack
  /// slot, so equipping can never fail for space.
  ///
  /// ⚠️ **Except a two-hander** (ruling, Christian 2026-09-21). A staff
  /// displaces the offhand as well as the main hand, and the offhand has no
  /// vacated slot of its own to land in — so this is the one equip that can
  /// be refused for space, and it is refused *before* anything moves.
  Future<String?> equipFromBackpack(int index) async {
    final slot = profile.backpack.slots[index];
    final inst = slot?.instanceId == null
        ? null
        : profile.itemInstances[slot!.instanceId];
    final def = ItemCatalogue.tryById(inst?.defId ?? '');
    final no = Equipping.refusal(def, playerLevel: profile.level);
    if (no != null) return no;
    final equipDef = def! as EquipmentDef;
    final equipSlot = equipDef.slot;
    final handsNo = Equipping.handsRefusal(
      def: equipDef,
      wornMainHand: wornDef(EquipSlot.mainHand),
    );
    if (handsNo != null) return handsNo;

    // ⭐ **Computed before a single mutation.** The whole next pack is built
    // here and only assigned once it is known to fit, so a refusal leaves the
    // wardrobe and the pack exactly as they were — the alternative is a staff
    // half-equipped over a knot with nowhere to go.
    final displaced = _displacedBy(equipDef);
    var pack = profile.backpack.withRemovedAt(index);
    for (final wornId in displaced) {
      final wornDefId = profile.itemInstances[wornId]?.defId;
      // ⚠️ A dangling id is nothing to carry — it is dropped from the
      // wardrobe below either way.
      if (wornDefId == null) continue;
      final next = pack.withAdded(
        InventorySlot(defId: wornDefId, instanceId: wornId),
      );
      // ⚠️ The FIRST add can never fail — the item being equipped just
      // vacated a slot. Only a two-hander's second casualty, the offhand, can
      // run out of room, which is why this refusal names it.
      if (next == null) return Equipping.noRoomForOffhandMessage;
      pack = next;
    }

    await _mutate(() {
      profile.backpack = pack;
      // ⭐ The offhand leaves the doll, not just the totals: a staff worn over
      // an invisible knot would still be a knot the duel could read.
      if (equipDef.twoHanded) profile.equipped.remove(EquipSlot.offHand);
      profile.equipped[equipSlot] = slot!.instanceId!;
    });
    return null;
  }

  /// The worn instance ids that wearing [def] takes off, in the order they
  /// are stowed: whatever held its own slot, then — for a two-hander — the
  /// offhand it leaves no room for.
  ///
  /// ⭐ **One list, both equip paths**, so the pack and the Storeroom can
  /// never disagree about what a staff costs you.
  List<String> _displacedBy(EquipmentDef def) => [
    if (profile.equipped[def.slot] != null) profile.equipped[def.slot]!,
    if (def.twoHanded && profile.equipped[EquipSlot.offHand] != null)
      profile.equipped[EquipSlot.offHand]!,
  ];

  /// Takes off whatever is in [slot], into the backpack.
  Future<String?> unequip(EquipSlot slot) async {
    final worn = profile.equipped[slot];
    if (worn == null) return 'Nothing is equipped there.';
    final defId = profile.itemInstances[worn]?.defId;
    if (defId == null) return 'Nothing is equipped there.';
    // ⚠️ Unequip is the one direction that needs space — there is no slot
    // being vacated to reuse.
    if (profile.backpack.isFull) return 'Your pack is full.';
    await _mutate(() {
      profile.equipped.remove(slot);
      profile.backpack =
          profile.backpack.withAdded(
            InventorySlot(defId: defId, instanceId: worn),
          ) ??
          profile.backpack;
    });
    return null;
  }

  /// Equips a stored instance directly from the current town's Storeroom —
  /// the displaced item is stowed there in exchange.
  ///
  /// ⭐ The Storeroom-as-wardrobe move (ITEMS §10.3c): in a city you can dress
  /// from storage without a backpack shuffle. ⚠️ Town-only by nature — the
  /// Storeroom is per city, and you are not in one on the road.
  ///
  /// ⭐ A two-hander stows the displaced **offhand** here too (ruling
  /// 2026-09-21) — and unlike the backpack path this can never be refused for
  /// space, because a Storeroom is unbounded (ITEMS §10.3c).
  Future<String?> equipFromStoreroom(String instanceId) async {
    final here = profile.locationId;
    if (!profile.location.isTown) return 'Storerooms are in town.';
    final room = profile.storerooms[here];
    if (room == null || !room.instanceIds.contains(instanceId)) {
      return 'That is not stored here.';
    }
    final def = ItemCatalogue.tryById(
      profile.itemInstances[instanceId]?.defId ?? '',
    );
    final no = Equipping.refusal(def, playerLevel: profile.level);
    if (no != null) return no;
    final equipDef = def! as EquipmentDef;
    final equipSlot = equipDef.slot;
    final handsNo = Equipping.handsRefusal(
      def: equipDef,
      wornMainHand: wornDef(EquipSlot.mainHand),
    );
    if (handsNo != null) return handsNo;
    final displaced = _displacedBy(equipDef);
    await _mutate(() {
      final taken = room.withWithdrawn(
        InventorySlot(defId: def.id, instanceId: instanceId),
      );
      var nextRoom = taken.room;
      for (final wornId in displaced) {
        final wornDefId = profile.itemInstances[wornId]?.defId;
        if (wornDefId == null) continue;
        nextRoom = nextRoom.withDeposited(
          InventorySlot(defId: wornDefId, instanceId: wornId),
        );
      }
      profile.storerooms[here] = nextRoom;
      if (equipDef.twoHanded) profile.equipped.remove(EquipSlot.offHand);
      profile.equipped[equipSlot] = instanceId;
    });
    return null;
  }

  Future<void> deposit(String townId, int index) => _mutate(() {
    final slot = profile.backpack.slots[index];
    if (slot == null) return;
    final room = profile.storerooms[townId] ?? const Storeroom();
    profile.storerooms[townId] = room.withDeposited(slot);
    profile.backpack = profile.backpack.withRemovedAt(index);
  });

  /// Empties the whole backpack into [townId]'s Storeroom in one action.
  ///
  /// ⭐ **Backpack only — equipped gear is never touched** (ruling
  /// 2026-08-09). Worn items live in `profile.equipped`, not the backpack, so
  /// this is safe by construction: iterating the pack cannot reach them. What
  /// you are wearing when you tap this is exactly what you are still wearing
  /// after.
  ///
  /// Returns how many items moved, so the UI can say so — a bulk action that
  /// reports nothing reads as having done nothing.
  Future<int> depositAll(String townId) async {
    if (profile.backpack.used == 0) return 0;
    var moved = 0;
    await _mutate(() {
      var room = profile.storerooms[townId] ?? const Storeroom();
      for (final slot in profile.backpack.contents) {
        room = room.withDeposited(slot);
        // ⭐ Items, not slots: a 12-stack moves 12 (2026-09-25).
        moved += slot.count;
      }
      profile.storerooms[townId] = room;
      profile.backpack = Backpack.empty();
    });
    return moved;
  }

  /// Takes as many of [defId] out of [townId]'s Storeroom as the backpack has
  /// room for. Returns how many actually moved.
  ///
  /// ⭐ **Bounded by space, never an error** (designer, 2026-08-17). Taking 7 of
  /// 40 because seven slots were free is a *success* — the caller says so, and
  /// the alternative (refusing unless it all fits) would make the button
  /// useless in exactly the situation it exists for. ⚠️ Stacks only: a
  /// non-fungible is one instance, and "take all" of one thing is [withdraw].
  Future<int> takeAllFromStoreroom(String townId, String defId) async {
    // ⚠️ Cheap refusals before [_mutate], so a no-op never costs a disk write.
    final have = profile.storerooms[townId]?.stacks[defId] ?? 0;
    // ⭐ Room, not free slots (stacking ruling, 2026-09-25): 40 Dust into an
    // empty pack is 25 + 15 in two slots, and a full pack with a short Dust
    // stack still takes the difference.
    final space = profile.backpack.roomFor(defId);
    if (have == 0 || space == 0) return 0;
    var moved = 0;
    await _mutate(() {
      var room = profile.storerooms[townId]!;
      var pack = profile.backpack;
      // ⭐ Goes through the same two writers a single Take does, one item at a
      // time, so a bulk move cannot invent an item a single move would refuse
      // — and the pack forms its stacks exactly as it would one by one.
      while (moved < space) {
        final result = room.withWithdrawn(InventorySlot(defId: defId));
        final taken = result.taken;
        if (taken == null) break;
        final next = pack.withAdded(taken);
        if (next == null) break;
        room = result.room;
        pack = next;
        moved++;
      }
      profile.storerooms[townId] = room;
      profile.backpack = pack;
    });
    return moved;
  }

  /// Takes [want] out of [townId]'s Storeroom, if the backpack has room.
  ///
  /// ⚠️ "Has room" is [Backpack.roomFor], not a free slot — a full pack still
  /// takes a Dust onto a short stack (2026-09-25).
  Future<bool> withdraw(String townId, InventorySlot want) async {
    if (profile.backpack.roomFor(want.defId) < want.count) return false;
    var ok = false;
    await _mutate(() {
      final room = profile.storerooms[townId];
      if (room == null) return;
      final result = room.withWithdrawn(want);
      if (result.taken == null) return;
      final pack = profile.backpack.withAdded(result.taken!);
      if (pack == null) return;
      profile.storerooms[townId] = result.room;
      profile.backpack = pack;
      ok = true;
    });
    return ok;
  }

  // ---- Shop (ECONOMY_CONTRACT.md) -----------------------------------------
  //
  // ⚠️ **Clock-free below this line, by design.** The screen computes `today`
  // once, via `ShopState.epochDayOf(DateTime.now())`, at the moment it opens
  // — every method here takes that `int` rather than reaching for the clock
  // itself, so a fixed-date test can drive an entire shop session without
  // faking `DateTime.now()` anywhere.
  //
  // ⚠️ **In-town trades move goods directly shop⇄Storeroom, never the
  // backpack** (§14b's build-wave addition) — the backpack is what carries
  // goods *between* towns; it plays no part in a purchase or a sale made
  // while standing in the shop that offers it.
  //
  // ⭐ **Basket settle, not per-line trades** (designer's ruling): a shop
  // session accumulates buy/sell quantities in memory only — [priceShopBasket]
  // and [shopBasketBlockReason] are pure reads a screen can call on every
  // build, and [settleShopBasket] is the ONE mutation that commits the whole
  // basket atomically. Nothing here debits gold, moves stock, or touches the
  // Storeroom/backpack a line at a time.

  /// §5.1's category-default equilibrium (`E`) — `zone-native materials 60 ·
  /// imported materials 20 · consumable-ingredient materials 10 ·
  /// consumables 6` (§14d ruling 2, Christian 2026-08-26) — read off
  /// [ShopCatalogue.categoryFor], which owns the "scarcer wins" precedence
  /// between the buckets. ⚠️ **This is the "config sibling" role**
  /// `config/economy`'s `equilibriumOverrides` (§7) will one day fill;
  /// `config/economy` does not exist as shipped code yet, so this is the
  /// compiled default the contract names, not a stand-in for a real seam.
  int shopEquilibriumFor(String townId, String itemId) =>
      EconomyConfig.current.equilibriumOverrides[itemId] ??
      switch (ShopCatalogue.categoryFor(townId, itemId)) {
        ShopItemCategory.nativeMaterial => EconomyConfig.equilibriumNative,
        ShopItemCategory.importedMaterial => EconomyConfig.equilibriumImported,
        ShopItemCategory.consumableIngredient =>
          EconomyConfig.equilibriumConsumableIngredient,
        ShopItemCategory.consumable => EconomyConfig.equilibriumConsumable,
      };

  /// [ShopCatalogue.locationModFor], with `config/economy`'s per-cell
  /// override (§7: key `townId.itemId`, value in PERCENT — -25 → ×0.75)
  /// consulted first. ⭐ The one seam every price reads its location factor
  /// through, so a live-tuned cell reaches every quote at once.
  double shopLocationModFor(String townId, String itemId) {
    final pct = EconomyConfig.current.locationModOverrides['$townId.$itemId'];
    if (pct != null) return 1 + pct / 100;
    return ShopCatalogue.locationModFor(townId, itemId);
  }

  /// [townId]'s live `eventMod` map for [today] (§6.2) — deterministic, so
  /// this is cheap to recompute per quote rather than cache.
  Map<String, double> shopEventsFor(String townId, int today) =>
      ShopState.eventsFor(
        shopId: townId,
        today: today,
        candidateItemIds: ShopCatalogue.stockFor(townId),
        itemsPerDay: EconomyConfig.current.eventItemsPerShopPerDay.round(),
        magnitudePercent: EconomyConfig.current.eventMagnitudePercent,
      );

  /// Resolves [townId]'s nightly catch-up against [today] and persists it.
  /// ⭐ **Call once, when the Shop screen opens, before quoting any price** —
  /// every price below reads `profile.shopStock[townId]`, and an unresolved
  /// town reads as stale (or, on a first visit, entirely absent). A no-op on
  /// a closed town (§14b.2 — nothing to resolve).
  Future<void> resolveShop(String townId, int today) async {
    if (!ShopCatalogue.isOpen(townId)) return;
    final resolved = ShopState.resolve(
      state: profile.shopStock[townId],
      today: today,
      itemIds: ShopCatalogue.stockFor(townId),
      equilibriumOf: (id) => shopEquilibriumFor(townId, id),
      resupplyRate: EconomyConfig.current.resupplyRate,
    );
    await _mutate(() => profile.shopStock[townId] = resolved);
  }

  /// ⭐ **The one basket-pricing walk** (build brief's "BASKET PRICING"):
  /// every line is recomputed marginally from [townId]'s *persisted* stock —
  /// [buy]/[sellStacks]/[sellInstances] are proposals, never read from or
  /// written to `profile` — walking the basket in a fixed order: items
  /// sorted by id, and within one item, its buy line prices before its sell
  /// line. ⚠️ **That per-item order is load-bearing** whenever the same item
  /// is both bought and sold in one basket (buying more oak while also
  /// selling old oak): the sell walk starts from the stock the buy walk left
  /// behind, so "buy 5 then sell 5 of the same item" reads as what it is — a
  /// round trip through both spreads — rather than two trades priced as if
  /// neither happened.
  ///
  /// ⭐ **The single source of truth for both the rows' numbers and the
  /// settle bar's net** — a screen never prices a line itself, so what a row
  /// displays and what [settleShopBasket] charges cannot drift apart (the
  /// mutant this whole seam exists to kill).
  ShopBasketQuote priceShopBasket({
    required String townId,
    required int today,
    required Map<String, int> buy,
    required Map<String, int> sellStacks,
    required Set<String> sellInstances,
  }) {
    final state = profile.shopStock[townId];
    final stocked = ShopCatalogue.stockFor(townId).toSet();
    final events = shopEventsFor(townId, today);
    final ids = {...buy.keys, ...sellStacks.keys}.toList()..sort();
    final buyGoldOf = <String, int>{};
    final sellGoldOf = <String, int>{};
    for (final id in ids) {
      final def = ItemCatalogue.tryById(id);
      if (def == null || !stocked.contains(id)) continue;
      final equilibrium = shopEquilibriumFor(townId, id);
      var stock = state?.stockOf(id) ?? equilibrium;
      final locationMod = shopLocationModFor(townId, id);
      final eventMod = events[id] ?? 1.0;
      final buyQty = buy[id] ?? 0;
      if (buyQty > 0) {
        final q = ShopPricing.buyQuote(
          n: buyQty,
          base: def.value,
          equilibrium: equilibrium,
          stock: stock,
          locationMod: locationMod,
          eventMod: eventMod,
        );
        buyGoldOf[id] = q.totalGold;
        stock = q.newStock;
      }
      final sellQty = sellStacks[id] ?? 0;
      if (sellQty > 0) {
        sellGoldOf[id] = ShopPricing.sellQuote(
          n: sellQty,
          base: def.value,
          equilibrium: equilibrium,
          stock: stock,
          locationMod: locationMod,
          eventMod: eventMod,
        ).totalGold;
      }
    }
    // ⚠️ A sell of something this shop does NOT stock never entered the loop
    // above (it is filtered out by `!stocked.contains(id)`) — priced here
    // instead, flat, with no stock walk at all (§2.4, ruling 3's pure sink).
    for (final entry in sellStacks.entries) {
      if (entry.value <= 0 || stocked.contains(entry.key)) continue;
      final def = ItemCatalogue.tryById(entry.key);
      if (def == null) continue;
      sellGoldOf[entry.key] = ShopPricing.vendorPrice(def.value) * entry.value;
    }
    // ⭐ §14d ruling 1: gear prices off its QUALITY-scaled value, through the
    // one [instanceVendorPrice] seam the Shop screen's gear row also calls —
    // so what a row shows and what this settle charges cannot disagree.
    final instanceGoldOf = <String, int>{};
    for (final instId in sellInstances) {
      final instance = profile.itemInstances[instId];
      final defId = instance?.defId;
      final def = defId == null ? null : ItemCatalogue.tryById(defId);
      if (def != null) {
        instanceGoldOf[instId] = instanceVendorPrice(def, instance);
      }
    }
    return ShopBasketQuote(
      buyGoldOf: buyGoldOf,
      sellGoldOf: sellGoldOf,
      instanceGoldOf: instanceGoldOf,
    );
  }

  /// Why [settleShopBasket] would refuse this basket right now, or `null` if
  /// it would succeed — a pure read so the settle bar can grey its own
  /// button without staging a trade. ⚠️ **Checked again, identically, inside
  /// [settleShopBasket] itself** — a screen that trusted only its own cached
  /// read could race a stock change between a render and the tap that
  /// follows it.
  String? shopBasketBlockReason({
    required String townId,
    required int today,
    required Map<String, int> buy,
    required Map<String, int> sellStacks,
    required Set<String> sellInstances,
  }) {
    if (buy.isEmpty && sellStacks.isEmpty && sellInstances.isEmpty) {
      return null;
    }
    final state = profile.shopStock[townId];
    final stocked = ShopCatalogue.stockFor(townId).toSet();
    for (final entry in buy.entries) {
      if (entry.value <= 0) continue;
      if (!stocked.contains(entry.key)) return 'Not stocked here.';
      final equilibrium = shopEquilibriumFor(townId, entry.key);
      final stock = state?.stockOf(entry.key) ?? equilibrium;
      if (entry.value > stock) return 'Not enough in stock.';
    }
    final room = profile.storerooms[townId] ?? const Storeroom();
    final pack = profile.backpack;
    for (final entry in sellStacks.entries) {
      if (entry.value <= 0) continue;
      final def = ItemCatalogue.tryById(entry.key);
      if (def == null) return 'Unknown item.';
      if (def.tradability == Tradability.bound) {
        return 'Bound — cannot be sold.';
      }
      final available = (room.stacks[entry.key] ?? 0) + pack.countOf(entry.key);
      if (entry.value > available) return 'You do not have that many.';
    }
    for (final instId in sellInstances) {
      final defId = profile.itemInstances[instId]?.defId;
      final def = defId == null ? null : ItemCatalogue.tryById(defId);
      if (def == null) return 'Unknown item.';
      if (def.tradability == Tradability.bound) {
        return 'Bound — cannot be sold.';
      }
    }
    final quote = priceShopBasket(
      townId: townId,
      today: today,
      buy: buy,
      sellStacks: sellStacks,
      sellInstances: sellInstances,
    );
    if (profile.gold + quote.net < 0) return 'Not enough gold.';
    return null;
  }

  /// ⭐ **The one atomic settle.** Commits every buy and sell line in the
  /// basket in a single [_mutate] — one gold delta, one set of stock writes,
  /// one Storeroom/backpack shuffle, one save — never a line at a time.
  /// Refuses (via [shopBasketBlockReason], re-checked here so nothing can
  /// slip between a stale render and this call) rather than partially
  /// filling: a basket that could not fully settle changes nothing.
  ///
  /// ⭐ **Charges exactly [priceShopBasket]'s [ShopBasketQuote.net]** — this
  /// method never re-derives gold by any other arithmetic, so the number the
  /// settle bar showed is the number that lands on `profile.gold`.
  Future<ShopSettleOutcome> settleShopBasket({
    required String townId,
    required int today,
    required Map<String, int> buy,
    required Map<String, int> sellStacks,
    required Set<String> sellInstances,
  }) async {
    if (!ShopCatalogue.isOpen(townId)) {
      return const ShopSettleOutcome.refused(
        "This town's shop is closed this season.",
      );
    }
    if (buy.isEmpty && sellStacks.isEmpty && sellInstances.isEmpty) {
      return const ShopSettleOutcome.refused('Nothing to settle.');
    }
    final reason = shopBasketBlockReason(
      townId: townId,
      today: today,
      buy: buy,
      sellStacks: sellStacks,
      sellInstances: sellInstances,
    );
    if (reason != null) return ShopSettleOutcome.refused(reason);

    final quote = priceShopBasket(
      townId: townId,
      today: today,
      buy: buy,
      sellStacks: sellStacks,
      sellInstances: sellInstances,
    );
    final stocked = ShopCatalogue.stockFor(townId).toSet();
    final events = shopEventsFor(townId, today);

    await _mutate(() {
      final state = profile.shopStock[townId];
      final nextStock = {...?state?.stock};
      var room = profile.storerooms[townId] ?? const Storeroom();
      var pack = profile.backpack;

      // ⭐ Same fixed order as [priceShopBasket]'s walk (id-sorted,
      // buy-then-sell per item) — replaying stock in any other order here
      // would leave the shelf at a count the quote above never actually
      // priced.
      final ids = {...buy.keys, ...sellStacks.keys}.toList()..sort();
      for (final id in ids) {
        final def = ItemCatalogue.tryById(id);
        if (def == null) continue;
        final isStocked = stocked.contains(id);
        final equilibrium = shopEquilibriumFor(townId, id);
        var stock = state?.stockOf(id) ?? equilibrium;
        final locationMod = shopLocationModFor(townId, id);
        final eventMod = events[id] ?? 1.0;
        var stockChanged = false;

        final buyQty = buy[id] ?? 0;
        if (buyQty > 0 && isStocked) {
          final q = ShopPricing.buyQuote(
            n: buyQty,
            base: def.value,
            equilibrium: equilibrium,
            stock: stock,
            locationMod: locationMod,
            eventMod: eventMod,
          );
          stock = q.newStock;
          stockChanged = true;
          for (var i = 0; i < buyQty; i++) {
            room = room.withDeposited(InventorySlot(defId: id));
          }
        }

        final sellQty = sellStacks[id] ?? 0;
        if (sellQty > 0) {
          if (isStocked) {
            final q = ShopPricing.sellQuote(
              n: sellQty,
              base: def.value,
              equilibrium: equilibrium,
              stock: stock,
              locationMod: locationMod,
              eventMod: eventMod,
            );
            stock = q.newStock;
            stockChanged = true;
          }
          final roomHave = room.stacks[id] ?? 0;
          final fromRoom = sellQty < roomHave ? sellQty : roomHave;
          for (var i = 0; i < fromRoom; i++) {
            room = room.withWithdrawn(InventorySlot(defId: id)).room;
          }
          for (var i = 0; i < sellQty - fromRoom; i++) {
            pack = pack.withRemovedFirst(id);
          }
        }

        if (stockChanged) nextStock[id] = stock;
      }

      for (final instId in sellInstances) {
        final defId = profile.itemInstances[instId]?.defId;
        if (defId == null) continue;
        if (room.instanceIds.contains(instId)) {
          room = room
              .withWithdrawn(InventorySlot(defId: defId, instanceId: instId))
              .room;
        } else {
          final packIndex = pack.slots.indexWhere(
            (s) => s?.instanceId == instId,
          );
          if (packIndex >= 0) pack = pack.withRemovedAt(packIndex);
        }
        profile.itemInstances.remove(instId);
      }

      profile.gold += quote.net;
      profile.storerooms[townId] = room;
      profile.backpack = pack;
      profile.shopStock[townId] = TownShopState(
        stock: nextStock,
        lastResetDay: state?.lastResetDay ?? today,
      );
    });
    return ShopSettleOutcome.ok(
      net: quote.net,
      buyGold: quote.buyGold,
      sellGold: quote.sellGold,
    );
  }

  // ---- Belt --------------------------------------------------------------

  /// How many things this character can carry into a duel, right now.
  ///
  /// ⭐ **One definition, read by the UI and by every belt method here.** Since
  /// the 2026-08-17 ruling this is worn gear and nothing else: no belt, no
  /// slots (`Carrying.baseBeltSlots` is 0).
  int get beltCapacity =>
      Carrying.beltSlotsFor(fromGear: equipmentTotals.beltSlots);

  /// Hangs one [defId] from the backpack on the belt.
  ///
  /// ⭐ **A MOVE, not a copy** (designer, 2026-08-17): the draught is *on your
  /// belt*, not simultaneously in your pack, so loading frees a pack slot and
  /// unloading costs one. Anything else is a duplication bug the player would
  /// find before a test did.
  ///
  /// ⚠️ Belt contents are def ids, so only fungible consumables ride here —
  /// which is exactly what `Beltable` is (no `BeltableDef` carries an
  /// instance). Rolled, socketed gear cannot be belted and does not need to be.
  ///
  /// Returns a player-facing refusal, or null on success.
  Future<String?> loadOntoBelt(String defId) async {
    final def = ItemCatalogue.tryById(defId);
    // ⭐ Legality and space are Carrying's rules, so the belt cannot disagree
    // with the container rules the rest of the game is written against — and
    // the greyed-out dialog button quotes the identical string.
    final no = Carrying.beltRefusal(
      def,
      used: profile.belt.used,
      capacity: beltCapacity,
    );
    if (no != null) return no;
    // ⚠️ The one check Carrying cannot make: it never sees a pack.
    if (profile.backpack.countOf(defId) == 0) {
      return 'That is not in your pack.';
    }
    await _mutate(() {
      profile.backpack = profile.backpack.withRemovedFirst(defId);
      profile.belt = profile.belt.withLoaded(defId);
    });
    return null;
  }

  /// Takes one [defId] off the belt and back into the pack.
  ///
  /// ⚠️ **Needs a free pack slot** — the mirror of [unequip], and for the same
  /// reason: nothing is being vacated in exchange, so a full pack must refuse
  /// rather than quietly destroy the potion.
  Future<String?> unloadFromBelt(String defId) async {
    if (!profile.belt.loaded.contains(defId)) {
      return 'That is not on your belt.';
    }
    if (profile.backpack.isFull) return 'Your pack is full.';
    await _mutate(() {
      profile.belt = profile.belt.withUnloaded(defId);
      profile.backpack =
          profile.backpack.withAdded(InventorySlot(defId: defId)) ??
          profile.backpack;
    });
    return null;
  }

  /// Drinks one [defId] off the belt: the slot empties and **nothing comes
  /// back** — the mirror of [unloadFromBelt], minus the pack.
  ///
  /// ⭐ **Consumed on USE, and saved right then** (ruling 2026-08-18). The
  /// duel calls this the moment the move is submitted, not when the duel ends,
  /// so a potion drunk in a fight the player then loses, flees or closes the
  /// tab on is gone either way. Anything later is a duplication bug wearing a
  /// crash for a disguise: a save written at the end of a duel that never ends
  /// hands the player their potion back.
  ///
  /// ⚠️ Silently does nothing if it is not loaded, rather than throwing. The
  /// caller ([DuelController.spendBeltItem]) has already gated on the same
  /// list, so reaching here twice means a double-tap, and a duel is not the
  /// place to raise.
  Future<void> consumeBeltItem(String defId) async {
    if (!profile.belt.loaded.contains(defId)) return;
    await _mutate(() => profile.belt = profile.belt.withUnloaded(defId));
  }

  /// Brings a loaded belt back inside its capacity, returning what no longer
  /// fits. Returns how many items were moved off the belt.
  ///
  /// ⚠️ **The 2026-08-17 migration.** Every save written before that ruling
  /// could hold two belted items with no belt worn; capacity is now 0, and an
  /// over-capacity belt must neither crash nor eat what it holds. The order is
  /// deliberate, cheapest-surprise first:
  ///
  /// 1. **Backpack** — where the item came from and the first place the player
  ///    will look for it.
  /// 2. **This town's Storeroom**, if the pack is full and the character is
  ///    standing in a town — the same move "Deposit all" makes, to the only
  ///    Storeroom that is reachable from here (ITEMS §10.3c).
  /// 3. **Stays loaded**, if the pack is full on the road. ⭐ Nothing is ever
  ///    destroyed: an over-capacity belt is legal, rendered (the paper doll
  ///    draws every loaded item, not just the ones inside capacity) and
  ///    unloadable, so the player can resolve it the moment they have a slot.
  ///    Silently deleting a potion to satisfy a number is the one outcome that
  ///    is never worth it.
  ///
  /// ⭐ Idempotent, so it can run on every load — including the cloud profile
  /// adopted at sign-in — without ever moving the same item twice.
  int settleBeltOverflow() {
    final capacity = beltCapacity;
    if (profile.belt.used <= capacity) return 0;
    // ⭐ The first `capacity` stay put: the player loaded them in that order,
    // and keeping the head is the only choice that does not reshuffle a belt
    // that was already correct at the front.
    final keep = profile.belt.loaded.take(capacity).toList();
    final overflow = profile.belt.loaded.skip(capacity).toList();
    final stranded = <String>[];
    var pack = profile.backpack;
    final here = profile.locationId;
    var room = profile.storerooms[here];
    var moved = 0;
    for (final defId in overflow) {
      final next = pack.withAdded(InventorySlot(defId: defId));
      if (next != null) {
        pack = next;
        moved++;
        continue;
      }
      if (profile.location.isTown) {
        room = (room ?? const Storeroom()).withDeposited(
          InventorySlot(defId: defId),
        );
        moved++;
        continue;
      }
      stranded.add(defId);
    }
    profile.backpack = pack;
    if (room != null) profile.storerooms[here] = room;
    profile.belt = Belt(loaded: [...keep, ...stranded]);
    return moved;
  }

  void acknowledgeLevelUp() {
    pendingLevelUp = null;
    pendingLevelUpFrom = null;
    notifyListeners();
  }

  // ---- Loadout presets -------------------------------------------------

  Future<void> selectPreset(int index) => _mutate(() {
    if (index >= 0 && index < profile.presets.length) {
      profile.activePresetIndex = index;
    }
  });

  Future<void> savePreset(int index, LoadoutPreset preset) => _mutate(() {
    if (index >= 0 && index < profile.presets.length) {
      profile.presets[index] = preset;
    }
  });

  /// The Academy loadout (academy.dart): editable anywhere — it is not the
  /// campaign's, so the town rule does not apply — and clamped to the
  /// Academy's own caps.
  Future<void> saveAcademyPreset(LoadoutPreset preset) => _mutate(() {
    profile.academyPreset = preset
      ..clampToCaps(
        elementBudget: Academy.elementSlots,
        spellBudget: Academy.spellSlots,
      );
  });

  /// Adds a new preset if the player has an unlocked slot free.
  Future<void> addPresetSlot() => _mutate(() {
    if (profile.presets.length < profile.unlockedPresetSlots) {
      final n = profile.presets.length + 1;
      profile.presets.add(LoadoutPreset.starter('Loadout ${_roman(n)}'));
    }
  });

  bool get canAddPresetSlot =>
      profile.presets.length < profile.unlockedPresetSlots;

  /// Loadout editing is only allowed while standing in a town (design rule).
  bool get canEditLoadoutHere => profile.location.isTown;

  // ---- Dev / demo helpers ---------------------------------------------

  Future<void> resetProfile() async {
    profile = PlayerProfile.newPlayer(name: profile.name);
    await _mutate(() {});
  }

  static const List<String> _numerals = ['', 'I', 'II', 'III', 'IV', 'V'];

  static String _roman(int n) =>
      (n >= 1 && n < _numerals.length) ? _numerals[n] : '$n';
}

/// Inherited access to the single [GameState]. `GameStateScope.of(context)`
/// subscribes the caller so it rebuilds on any profile change.
class GameStateScope extends InheritedNotifier<GameState> {
  const GameStateScope({
    super.key,
    required GameState state,
    required super.child,
  }) : super(notifier: state);

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameStateScope>();
    assert(scope != null, 'No GameStateScope found in context');
    return scope!.notifier!;
  }

  /// Read without subscribing (for callbacks/intents).
  static GameState read(BuildContext context) {
    final scope =
        context
                .getElementForInheritedWidgetOfExactType<GameStateScope>()
                ?.widget
            as GameStateScope?;
    return scope!.notifier!;
  }
}

/// A snapshot of what a pending shop basket would cost/earn, computed
/// **purely** from persisted stock — nothing in [GameState.priceShopBasket]
/// reads or writes `profile`. ⭐ **The single source of truth for both the
/// Buy/Sell rows' numbers and the settle bar's net.**
class ShopBasketQuote {
  /// Gold cost per pending buy line, keyed by item id. Absent = no pending
  /// buy for that item.
  final Map<String, int> buyGoldOf;

  /// Gold earned per pending sell line (fungible stacks — the marginal walk
  /// when the shop stocks the item, the flat vendor sink when it does not),
  /// keyed by item id.
  final Map<String, int> sellGoldOf;

  /// Gold earned per sold gear instance, keyed by instance id — always
  /// [ShopPricing.vendorPrice] (§2.4 ruling 3: gear is never shop stock).
  final Map<String, int> instanceGoldOf;

  const ShopBasketQuote({
    required this.buyGoldOf,
    required this.sellGoldOf,
    required this.instanceGoldOf,
  });

  int get buyGold => buyGoldOf.values.fold(0, (a, b) => a + b);

  int get sellGold =>
      sellGoldOf.values.fold(0, (a, b) => a + b) +
      instanceGoldOf.values.fold(0, (a, b) => a + b);

  /// What Settle would charge to `profile.gold` — positive banks gold,
  /// negative spends it.
  int get net => sellGold - buyGold;

  static const empty = ShopBasketQuote(
    buyGoldOf: {},
    sellGoldOf: {},
    instanceGoldOf: {},
  );
}

/// What settling a shop basket produced.
class ShopSettleOutcome {
  /// Player-facing reason nothing happened, or null on success.
  final String? refusal;

  /// The gold delta actually applied to `profile.gold` — matches
  /// [ShopBasketQuote.net] exactly (⭐ the invariant [GameState
  /// .settleShopBasket] exists to keep).
  final int net;
  final int buyGold;
  final int sellGold;

  const ShopSettleOutcome.refused(this.refusal)
    : net = 0,
      buyGold = 0,
      sellGold = 0;

  const ShopSettleOutcome.ok({
    required this.net,
    required this.buyGold,
    required this.sellGold,
  }) : refusal = null;

  bool get succeeded => refusal == null;
}

/// What a craft attempt produced.
class CraftOutcome {
  /// Player-facing reason nothing happened, or null on success.
  final String? refusal;

  final String? defId;
  final int xp;
  final String? skillKey;

  /// Non-null when this craft crossed a skill level — the UI's cue to
  /// celebrate, mirroring the character pendingLevelUp shape.
  final int? leveledTo;

  /// What was minted, when the output was non-fungible.
  ///
  /// ⭐ **The instance, not just the tier**, because the result panel names the
  /// item — and the name is composed from the instance's own facts
  /// (`ItemCatalogue.displayName`), never written down. Null for consumables,
  /// which are fungible and roll nothing.
  final ItemInstance? instance;

  /// The tier the craft rolled (§9b.9d), for a panel that wants only that.
  Quality? get quality => instance?.quality;

  /// Player-facing news about a *successful* craft that the usual banner
  /// would not carry — today, only "the output went to your storeroom".
  ///
  /// ⚠️ **Not a refusal.** The craft happened; this says where the item
  /// landed. A UI that ignores it leaves the player hunting a pack that never
  /// received the item (ruling 2026-09-21).
  final String? note;

  const CraftOutcome.refused(this.refusal)
    : defId = null,
      xp = 0,
      skillKey = null,
      leveledTo = null,
      instance = null,
      note = null;

  const CraftOutcome.made({
    required this.defId,
    required this.xp,
    required this.skillKey,
    this.leveledTo,
    this.instance,
    this.note,
  }) : refusal = null;

  bool get succeeded => refusal == null;
}

/// What a harvest produced.
class GatherOutcome {
  final String? refusal;
  final String? defId;
  final int amount;
  final int xp;
  final String? skillKey;
  final int? leveledTo;

  const GatherOutcome.refused(this.refusal)
    : defId = null,
      amount = 0,
      xp = 0,
      skillKey = null,
      leveledTo = null;

  const GatherOutcome.gathered({
    required this.defId,
    required this.amount,
    required this.xp,
    required this.skillKey,
    this.leveledTo,
  }) : refusal = null;

  bool get succeeded => refusal == null;
}
