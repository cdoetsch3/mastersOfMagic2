import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mom_engine/mom_engine.dart';

import 'active_trip.dart';
import 'adventure.dart';
import 'crafting/craft_quality.dart';
import 'enemies/bestiary.dart';
import 'enemies/loot.dart';
import 'items/carrying.dart';
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
    // ⚠️ …and saves made when a beltless character had two free belt slots.
    state.settleBeltOverflow();
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
        // ⚠️ A cloud save is as old as a local one — same migration, same
        // reason (settleBeltOverflow is idempotent, so this is free).
        settleBeltOverflow();
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
    if (free < amount) {
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
        // cost an item rather than crash on a null.
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
      instance: minted,
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
    // ⭐ Defaulting inside rollDrops (lootRng, one long-lived stream) — the
    // hygiene half of the 2026-08-17 drop audit; both shapes measured at 10%.
    final loot = rollDrops(enemy.def.drops, rng);
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
  /// Returns how many slots were emptied, so the screen can say it plainly. A
  /// penalty the player is not told about is indistinguishable from a bug.
  Future<int> loseEncounter({Random? rng}) async {
    final r = run;
    if (r == null || r.isOver) return 0;
    final enemy = r.current!;
    var lost = 0;
    await _mutate(() {
      final worn = profile.equipped.values.toSet();
      for (final slot in profile.backpack.contents) {
        lost++;
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
  List<int> get defaultVictoryChoice {
    final r = run;
    if (r == null) return const [];
    return lootDisplayOrder(
      r.unclaimed,
      r.unclaimedInstances,
    ).take(profile.backpack.free).toList();
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
      final wanted = lootDisplayOrder(
        r.unclaimed,
        r.unclaimedInstances,
        // ⚠️ Filtered for range here rather than trusted: these indices come
        // from a screen, and a stale one must not read off the end.
        only: {
          for (final i in chosen)
            if (i >= 0 && i < r.unclaimed.length) i,
        },
      ).take(profile.backpack.free).toSet();

      var pack = profile.backpack;
      for (var i = 0; i < r.unclaimed.length; i++) {
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
    final free = profile.backpack.free;
    if (have == 0 || free == 0) return 0;
    var moved = 0;
    await _mutate(() {
      var room = profile.storerooms[townId]!;
      var pack = profile.backpack;
      // ⭐ Goes through the same two writers a single Take does, one item at a
      // time, so a bulk move cannot invent an item a single move would refuse.
      while (moved < free) {
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

  /// What was minted, when the output was non-fungible.
  ///
  /// ⭐ **The instance, not just the tier**, because the result panel names the
  /// item — and the name is composed from the instance's own facts
  /// (`ItemCatalogue.displayName`), never written down. Null for consumables,
  /// which are fungible and roll nothing.
  final ItemInstance? instance;

  /// The tier the craft rolled (§9b.9d), for a panel that wants only that.
  Quality? get quality => instance?.quality;

  const CraftOutcome.refused(this.refusal)
    : defId = null,
      xp = 0,
      skillKey = null,
      leveledTo = null,
      instance = null;

  const CraftOutcome.made({
    required this.defId,
    required this.xp,
    required this.skillKey,
    this.leveledTo,
    this.instance,
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
