import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mom_engine/mom_engine.dart';

import 'active_trip.dart';
import 'adventure.dart';
import 'enemies/bestiary.dart';
import 'enemies/loot.dart';
import 'items/equipping.dart';
import 'items/inventory.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'items/item_instance.dart';
import 'items/recipe_def.dart';
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

  static Future<GameState> boot(ProfileStorage storage) async {
    final loaded = await storage.load();
    final state = GameState(storage, loaded ?? PlayerProfile.newPlayer());
    state.loading = false;
    // Migrate saves made when presets could hold more slots.
    for (final preset in state.profile.presets) {
      preset.clampToCaps();
    }
    await state._persist();
    return state;
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
      if (loaded != null) {
        // Adopt the existing cloud profile (progress from another session).
        profile = loaded;
        for (final preset in profile.presets) {
          preset.clampToCaps();
        }
      } else {
        // First time on this account — seed the cloud with the current
        // (guest) profile so nothing is lost.
        await cloud.save(profile);
      }
      storage = cloud;
    } else {
      final local = LocalProfileStorage();
      storage = local;
      profile = await local.load() ?? PlayerProfile.newPlayer();
    }
    notifyListeners();
  }

  Future<void> _persist() => storage.save(profile);

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
  Future<bool> beginTravel(String toId, {String? mountId}) async {
    settleTravel();
    if (profile.trip != null || toId == profile.locationId) return false;
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
  Future<void> travelTo(String locationId) async {
    if (!canTravelTo(locationId)) return;
    await beginTravel(locationId);
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
  Future<void> recordDuelResult({
    required bool won,
    int opponentLevel = 1,
    bool bossDefeated = false,
    String? locationId,
  }) async {
    final before = profile.level;
    await _mutate(() {
      // ⭐ XP scales with who you beat (10/level), so the fight worth taking
      // is the one that pays. Gold is deliberately still flat — scaling both
      // would make the economy climb as steeply as the power curve.
      profile.xp += Progression.xpForDuel(
        won: won,
        opponentLevel: opponentLevel,
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

  // ---- Crafting ---------------------------------------------------------

  /// Makes [recipe]'s output from backpack materials: checks the gate,
  /// consumes the inputs, mints the item, pays skill XP.
  ///
  /// ⭐ **Works anywhere** (ITEMS §9b.2 — stations are convenience, never a
  /// gate). Inputs come from the backpack only for now; 📝 pulling from the
  /// local Storeroom in town is a later nicety.
  ///
  /// ⚠️ **Space is safe by arithmetic**: every recipe consumes ≥1 slot of
  /// fungible inputs and yields exactly 1 slot, so a craft never overflows a
  /// pack that could afford its inputs. The assert guards the recipe that
  /// would break the theorem.
  ///
  /// 📝 **The performance seam**: when the crafting minigame lands, its
  /// execution score arrives through [performance] (0–1) and becomes the
  /// quality roll (§9b.4). Until quality moves stats, output is minted plain
  /// and the score is accepted but unused — the seam exists so the minigame
  /// bolts on without rewiring this method.
  Future<CraftOutcome> craft(RecipeDef recipe, {double performance = 1}) async {
    final skillKey = recipe.skill.name;
    final have = profile.skillLevel(skillKey);
    if (have < recipe.skillLevel) {
      return CraftOutcome.refused(
        'Needs ${Skills.displayName(skillKey)} ${recipe.skillLevel} — '
        'you are $have.',
      );
    }
    for (final input in recipe.inputs) {
      final short = input.count - profile.backpack.countOf(input.defId);
      if (short > 0) {
        final def = ItemCatalogue.tryById(input.defId);
        final name = def == null
            ? input.defId
            : ItemCatalogue.displayName(def);
        return CraftOutcome.refused('Needs $short more $name.');
      }
    }
    final outputDef = ItemCatalogue.tryById(recipe.outputId);
    if (outputDef == null) {
      // A recipe pointing at nothing is a content bug, not a player problem.
      return CraftOutcome.refused('That cannot be made.');
    }
    assert(
      recipe.inputs.fold<int>(0, (a, i) => a + i.count) >=
          recipe.outputCount,
      'a recipe that nets slots would make craft() able to overflow the pack',
    );

    final levelBefore = profile.skillLevel(skillKey);
    final gained = Skills.xpForRecipe(recipe);
    ItemInstance? minted;
    await _mutate(() {
      var pack = profile.backpack;
      for (final input in recipe.inputs) {
        for (var n = 0; n < input.count; n++) {
          pack = pack.withRemovedFirst(input.defId);
        }
      }
      for (var n = 0; n < recipe.outputCount; n++) {
        InventorySlot slot;
        if (outputDef.isFungible) {
          slot = InventorySlot(defId: outputDef.id);
        } else {
          // ⭐ Minted plain — no quality until quality changes stats (ruling
          // 2026-08-09); the [performance] seam is where it will come from.
          minted = ItemInstance(
            instanceId: _mintCraftId(),
            defId: outputDef.id,
          );
          profile.itemInstances[minted!.instanceId] = minted!;
          slot = InventorySlot(
            defId: outputDef.id,
            instanceId: minted!.instanceId,
          );
        }
        pack = pack.withAdded(slot) ?? pack;
      }
      profile.backpack = pack;
      profile.skillXp[skillKey] = (profile.skillXp[skillKey] ?? 0) + gained;
    });
    final levelAfter = profile.skillLevel(skillKey);
    return CraftOutcome.made(
      defId: outputDef.id,
      xp: gained,
      skillKey: skillKey,
      leveledTo: levelAfter > levelBefore ? levelAfter : null,
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
    // ⚠️ **An unclaimed haul must not die to an overwrite.** The picker can be
    // dodged — force-quit on the end screen, then enter another zone from the
    // map — and this line is where that path would silently destroy the loot.
    // Claiming the rarity-first default instead means dodging the picker
    // costs the choice, never the rare (validator guard, 2026-08-10).
    if (run?.awaitingLootChoice == true) {
      await takeRunLoot(defaultLootChoice);
    }
    final started = AdventureRun.roll(
      zone: zone,
      roster: Bestiary.forZone(zone.id),
      playerHp: MageState.scaledMaxHp(profile.level),
      rng: rng ?? Random(),
    );
    await _mutate(() => profile.run = started);
    return started;
  }

  /// Records a won encounter, rolling its drops into the run's pending loot.
  ///
  /// ⭐ Returns the def ids that dropped, so the end screen can show them
  /// **before** it renders. Rolling after the duel screen popped would leave
  /// nothing to display.
  Future<List<String>> winEncounter({
    required int remainingHp,
    Random? rng,
  }) async {
    final r = run;
    if (r == null || r.isOver) return const [];
    final enemy = r.current!;
    final loot = rollDrops(enemy.def.drops, rng ?? Random());
    final wasBoss = r.atBoss;
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
    // ⚠️ **A cleared run does NOT hand its loot over here.** Dropping the boss
    // ends the run, and the take-home step ([takeRunLoot]) is what moves loot
    // into the pack — one ritual for both endings, so the boss path and the
    // walk-out path cannot drift apart.
    notifyListeners();
    return [for (final slot in loot.slots) slot.defId];
  }

  /// Records a lost encounter. ⚠️ The run's loot is gone.
  Future<void> loseEncounter({Random? rng}) async {
    final r = run;
    if (r == null || r.isOver) return;
    final enemy = r.current!;
    r.recordDefeat();
    // The defeat rides to disk on recordDuelResult's write, same as a win.
    await recordDuelResult(won: false, opponentLevel: enemy.level);
    notifyListeners();
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

  /// Walks out early.
  ///
  /// ⭐ **Ends the run and nothing else.** The loot stays pending, because what
  /// comes home is now the player's choice and the picker has not been answered
  /// yet — see [takeRunLoot]. ⚠️ That leaves a legal in-between state on disk
  /// (a finished run still holding loot), which is why `AdventureRun`
  /// advertises it as [AdventureRun.awaitingLootChoice] and the Home tab offers
  /// the way back to it.
  Future<void> leaveAdventure() async {
    final r = run;
    if (r == null || r.isOver) return;
    await _mutate(r.returnToTown);
  }

  /// The selection the take-home picker opens with: indices into
  /// `run.pendingLoot`, best first, already trimmed to what will fit.
  ///
  /// ⭐ **Rarity descending.** A playtester lost a rare to the old silent
  /// overflow, which abandoned whatever happened to be last in the list — so
  /// the default now spends the last free slot on the best thing found, and a
  /// player who just taps confirm never loses the item they were excited about.
  List<int> get defaultLootChoice {
    final r = run;
    if (r == null) return const [];
    return _bestFirst(r.pendingLoot).take(profile.backpack.free).toList();
  }

  /// Takes the chosen part of a finished run's loot home; abandons the rest.
  ///
  /// [chosen] holds indices into `run.pendingLoot`. ⭐ **Everything not chosen
  /// is gone for good**, and that is the point: the player decides what a full
  /// pack costs them, where before `_bankRunLoot` silently dropped whatever
  /// overflowed.
  ///
  /// ⚠️ **Clamped, never refused.** A selection bigger than the free slots
  /// keeps its [_bestFirst] prefix and abandons the remainder — a confirm
  /// button that silently does nothing reads as a broken game, and refusing
  /// would strand the run in its unclaimed state forever.
  ///
  /// Returns what landed and what was left, so the screen can report both
  /// halves; a loss the player is not told about is the bug this replaced.
  Future<({List<InventorySlot> taken, List<InventorySlot> left})> takeRunLoot(
    Iterable<int> chosen,
  ) async {
    final r = run;
    if (r == null || !r.lootIsBanked) {
      return (taken: const <InventorySlot>[], left: const <InventorySlot>[]);
    }
    final taken = <InventorySlot>[];
    final left = <InventorySlot>[];
    await _mutate(() {
      final wanted = _bestFirst(
        r.pendingLoot,
        // ⚠️ Filtered for range here rather than trusted: these indices come
        // from a screen, and a stale one must not read off the end.
        only: {
          for (final i in chosen)
            if (i >= 0 && i < r.pendingLoot.length) i,
        },
      ).take(profile.backpack.free).toSet();

      var pack = profile.backpack;
      for (var i = 0; i < r.pendingLoot.length; i++) {
        final slot = r.pendingLoot[i];
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
        // ⭐ Only an instance whose slot came home enters the pool. An
        // abandoned staff's rolls must not outlive the staff: a dangling
        // instance is a save that grows forever and a name for an item nobody
        // owns (ITEMS §10.3a, and `PlayerProfile` guards the other direction).
        final id = slot.instanceId;
        final inst = id == null ? null : r.pendingInstances[id];
        if (inst != null) profile.itemInstances[id!] = inst;
      }
      profile.backpack = pack;
      // ⚠️ Emptied **inside** the write, taken and abandoned alike. Clearing
      // after it would save a run still holding loot that is already in the
      // backpack, and reopening the app would hand it over a second time.
      r.pendingLoot.clear();
      r.pendingInstances.clear();
    });
    return (taken: taken, left: left);
  }

  /// Indices into [loot] (optionally only those in [only]), rarest first.
  ///
  /// ⚠️ **One ordering for both the default selection and the clamp.** If they
  /// disagreed, confirming the default could abandon a different item than the
  /// one the picker showed as taken. Ties break on drop order, explicitly,
  /// because Dart's sort is not stable.
  List<int> _bestFirst(List<InventorySlot> loot, {Set<int>? only}) {
    final order = [
      for (var i = 0; i < loot.length; i++)
        if (only == null || only.contains(i)) i,
    ];
    order.sort((a, b) {
      final byRarity = _rarityRank(loot[b].defId) - _rarityRank(loot[a].defId);
      return byRarity != 0 ? byRarity : a - b;
    });
    return order;
  }

  /// ⚠️ An id no catalogue entry claims sorts below common rather than
  /// throwing — a save written before a content patch removed an item must
  /// still be able to walk out of the woods.
  static int _rarityRank(String defId) =>
      ItemCatalogue.tryById(defId)?.rarity.index ?? -1;

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
  /// ⭐ **One definition, read by both [useItem] and the Supplies panel**, so
  /// the "61 / 120" on screen is the same 120 a ration heals against. Two call
  /// sites computing this apart is how "the potion did nothing" gets reported
  /// as a bug when the player was simply already full.
  int get maxHp =>
      MageState.scaledMaxHp(profile.level) + equipmentTotals.maxHpBonus;

  /// Equips the item in backpack slot [index].
  ///
  /// Returns a player-facing refusal, or null on success. ⭐ **A swap, not a
  /// move**: whatever was worn in that slot lands in the vacated backpack
  /// slot, so equipping can never fail for space.
  Future<String?> equipFromBackpack(int index) async {
    final slot = profile.backpack.slots[index];
    final inst = slot?.instanceId == null
        ? null
        : profile.itemInstances[slot!.instanceId];
    final def = ItemCatalogue.tryById(inst?.defId ?? '');
    final no = Equipping.refusal(def, playerLevel: profile.level);
    if (no != null) return no;
    final equipSlot = (def! as EquipmentDef).slot;
    await _mutate(() {
      final wasWorn = profile.equipped[equipSlot];
      var pack = profile.backpack.withRemovedAt(index);
      if (wasWorn != null) {
        final wornDef = profile.itemInstances[wasWorn]?.defId;
        if (wornDef != null) {
          pack =
              pack.withAdded(
                InventorySlot(defId: wornDef, instanceId: wasWorn),
              ) ??
              pack;
        }
      }
      profile.backpack = pack;
      profile.equipped[equipSlot] = slot!.instanceId!;
    });
    return null;
  }

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
    final equipSlot = (def! as EquipmentDef).slot;
    await _mutate(() {
      final taken = room.withWithdrawn(
        InventorySlot(defId: def.id, instanceId: instanceId),
      );
      var nextRoom = taken.room;
      final wasWorn = profile.equipped[equipSlot];
      if (wasWorn != null) {
        final wornDef = profile.itemInstances[wasWorn]?.defId;
        if (wornDef != null) {
          nextRoom = nextRoom.withDeposited(
            InventorySlot(defId: wornDef, instanceId: wasWorn),
          );
        }
      }
      profile.storerooms[here] = nextRoom;
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
        moved++;
      }
      profile.storerooms[townId] = room;
      profile.backpack = Backpack.empty();
    });
    return moved;
  }

  /// Takes [want] out of [townId]'s Storeroom, if the backpack has room.
  Future<bool> withdraw(String townId, InventorySlot want) async {
    if (profile.backpack.isFull) return false;
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

  const CraftOutcome.refused(this.refusal)
    : defId = null,
      xp = 0,
      skillKey = null,
      leveledTo = null;

  const CraftOutcome.made({
    required this.defId,
    required this.xp,
    required this.skillKey,
    this.leveledTo,
  }) : refusal = null;

  bool get succeeded => refusal == null;
}
