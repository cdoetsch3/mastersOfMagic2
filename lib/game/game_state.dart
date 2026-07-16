import 'package:flutter/widgets.dart';

import 'player_profile.dart';
import 'profile_storage.dart';
import 'progression.dart';

/// Owns the [PlayerProfile] and mediates every change to it, persisting after
/// each mutation. Screens read state and call intent methods; they never
/// touch storage directly.
class GameState extends ChangeNotifier {
  final ProfileStorage storage;
  PlayerProfile profile;
  bool loading = true;

  /// Set when a level-up happens so the UI can celebrate it once.
  int? pendingLevelUp;

  GameState(this.storage, this.profile);

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

  Future<void> _persist() => storage.save(profile);

  Future<void> _mutate(void Function() change) async {
    change();
    notifyListeners();
    await _persist();
  }

  // ---- Identity --------------------------------------------------------

  Future<void> setName(String name) =>
      _mutate(() => profile.name = name.trim().isEmpty ? 'Apprentice' : name.trim());

  // ---- Travel ----------------------------------------------------------

  bool canTravelTo(String locationId) =>
      profile.location.connections.contains(locationId);

  Future<void> travelTo(String locationId) async {
    if (!canTravelTo(locationId)) return;
    await _mutate(() {
      profile.locationId = locationId;
      profile.discoveredLocationIds.add(locationId);
    });
  }

  // ---- Duel results ----------------------------------------------------

  /// Applies XP/gold for a finished duel and flags any level-up.
  Future<void> recordDuelResult({required bool won}) async {
    final before = profile.level;
    await _mutate(() {
      if (won) {
        profile.xp += Progression.winXp;
        profile.gold += Progression.winGold;
        profile.duelsWon++;
      } else {
        profile.xp += Progression.lossXp;
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
          profile.presets.add(
              LoadoutPreset.starter('Loadout ${_roman(n)}'));
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

  static String _roman(int n) => (n >= 1 && n < _numerals.length)
      ? _numerals[n]
      : '$n';
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
    final scope =
        context.dependOnInheritedWidgetOfExactType<GameStateScope>();
    assert(scope != null, 'No GameStateScope found in context');
    return scope!.notifier!;
  }

  /// Read without subscribing (for callbacks/intents).
  static GameState read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<GameStateScope>()
        ?.widget as GameStateScope?;
    return scope!.notifier!;
  }
}
