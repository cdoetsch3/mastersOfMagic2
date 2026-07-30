import 'package:flutter/widgets.dart';

import 'active_trip.dart';
import 'player_profile.dart';
import 'profile_storage.dart';
import 'progression.dart';
import 'travel.dart';

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
  Future<void> recordDuelResult({
    required bool won,
    int opponentLevel = 1,
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
      } else {
        profile.gold += Progression.lossGold;
        profile.duelsLost++;
      }
    });
    final after = profile.level;
    if (after > before) {
      pendingLevelUp = after;
      notifyListeners();
    }
  }

  void acknowledgeLevelUp() {
    pendingLevelUp = null;
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
