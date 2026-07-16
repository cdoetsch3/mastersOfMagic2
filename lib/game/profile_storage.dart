import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'player_profile.dart';

/// Persistence boundary for the player save. Local now; a `FirestoreProfile
/// Storage` implementing this same interface swaps in when Firebase lands,
/// with no changes to the game code that consumes it.
abstract interface class ProfileStorage {
  Future<PlayerProfile?> load();
  Future<void> save(PlayerProfile profile);
  Future<void> clear();
}

/// Stores the profile as a single JSON blob in shared_preferences (backed by
/// localStorage on web). Keyed to mirror a future `players/{uid}` document.
class LocalProfileStorage implements ProfileStorage {
  static const String _key = 'player_profile_v1';

  @override
  Future<PlayerProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt save — treat as a fresh player rather than crashing.
      return null;
    }
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
