import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Cloud persistence at `players/{uid}` — used when the player is signed in,
/// so progress follows the account across devices. All calls degrade
/// gracefully (return null / no-op) if Firestore is unreachable or not yet
/// enabled, so the app keeps working locally.
class FirestoreProfileStorage implements ProfileStorage {
  final String uid;
  FirestoreProfileStorage(this.uid);

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('players').doc(uid);

  @override
  Future<PlayerProfile?> load() async {
    try {
      final snap = await _doc.get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return PlayerProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    try {
      // Offline persistence queues this and syncs when back online.
      await _doc.set(profile.toJson());
    } catch (_) {
      // Best effort — the local cache still holds the latest state.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _doc.delete();
    } catch (_) {}
  }
}
