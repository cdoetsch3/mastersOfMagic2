import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_rest.dart';
import 'player_profile.dart';
import 'profile_documents.dart';

/// Persistence boundary for the player save. Two implementations: a single
/// JSON blob in the browser for a guest, and a set of Firestore documents for
/// a signed-in account.
///
/// ⭐ **The interface did not change for the restructure, and that is the
/// point.** Splitting one document into several is a fact about Firestore, not
/// about the game: `GameState` still hands over a whole [PlayerProfile] and
/// still gets a whole one back. See [FirestoreProfileStorage.save] for how the
/// "don't rewrite nine town documents for one deposit" requirement is met
/// without a hint parameter that every call site could forget to pass.
abstract interface class ProfileStorage {
  Future<PlayerProfile?> load();
  Future<void> save(PlayerProfile profile);
  Future<void> clear();
}

/// Stores the profile as a single JSON blob in shared_preferences (backed by
/// localStorage on web).
///
/// ⚠️ **Unchanged by the storage restructure, on purpose.** The split exists to
/// answer Firestore's per-document write cost and its 1 MiB ceiling; neither
/// applies here. Keeping this trivial also keeps it the honest reference for
/// what a profile *is* — and every guest save already on a playtester's disk
/// still loads byte for byte.
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

/// The four document operations [FirestoreProfileStorage] needs.
///
/// ⭐ Exists so the split can be tested against a recording fake: "one deposit
/// writes one town document" is a claim about *which writes happen*, and there
/// is no way to make that claim about a static HTTP call.
abstract interface class DocStore {
  Future<Map<String, dynamic>?> get(String path);
  Future<Map<String, Map<String, dynamic>>> list(String collectionPath);
  Future<void> set(String path, Map<String, dynamic> fields);
  Future<void> delete(String path);
}

/// The real thing, over [FirestoreRest].
class FirestoreDocStore implements DocStore {
  const FirestoreDocStore();

  @override
  Future<Map<String, dynamic>?> get(String path) => FirestoreRest.get(path);

  @override
  Future<Map<String, Map<String, dynamic>>> list(String collectionPath) =>
      FirestoreRest.list(collectionPath);

  @override
  Future<void> set(String path, Map<String, dynamic> fields) =>
      FirestoreRest.set(path, fields);

  @override
  Future<void> delete(String path) => FirestoreRest.delete(path);
}

/// Cloud persistence for a signed-in account, spread over the document layout
/// in [ProfileDocuments].
///
/// All calls degrade gracefully (return null / no-op) if Firestore is
/// unreachable, so the app keeps working with whatever is in memory.
class FirestoreProfileStorage implements ProfileStorage {
  final String uid;

  /// Injectable so tests can record which documents a save actually touches.
  final DocStore store;

  FirestoreProfileStorage(this.uid, {this.store = const FirestoreDocStore()});

  String get _userPath => 'users/$uid';
  String get _characterPath =>
      '$_userPath/characters/${ProfileDocuments.soleCharacterId}';
  String get _storeroomsPath => '$_characterPath/storerooms';
  String get _shopStockPath => '$_characterPath/shopStock';

  /// ⚠️ The pre-restructure location. Read once, on the first sign-in after
  /// the upgrade, and **never written** — see [_migrateFromLegacy].
  String get _legacyPath => 'players/$uid';

  /// What the server is believed to hold, as this client would encode it:
  /// town id -> canonical JSON. A save writes only the entries that differ.
  final Map<String, String> _writtenStorerooms = {};
  final Map<String, String> _writtenShopStock = {};
  String? _writtenCharacter;
  String? _writtenUserSansPresence;
  DateTime? _writtenLastSeen;

  /// Whether the caches above have been reconciled with the server at least
  /// once this session. Until then a save cannot know which town documents
  /// exist, so it cannot know which have become orphans.
  bool _seeded = false;

  /// How stale the account document's presence stamp may get before a save
  /// rewrites it for that reason alone.
  ///
  /// ⭐ Without this every single mutation writes two documents instead of one,
  /// because `GameState._mutate` stamps `lastSeenAt` on every save — the
  /// timestamp is *always* different. A minute is well inside the five-minute
  /// window `presence.dart` calls "online", and presence is deliberately
  /// coarse there for the same reason it is throttled here.
  static const Duration presenceWriteInterval = Duration(minutes: 1);

  @override
  Future<PlayerProfile?> load() async {
    try {
      final character = await store.get(_characterPath);
      // ⭐ The character document is the flag for "the new layout is complete
      // here" — see [save]'s write order. Its absence, and only its absence,
      // sends us looking for a legacy save to convert.
      if (character == null) return await _migrateFromLegacy();

      final user = await store.get(_userPath);
      final rooms = await store.list(_storeroomsPath);
      final shops = await store.list(_shopStockPath);
      final profile = ProfileDocuments.assemble(
        user: user,
        character: character,
        storerooms: rooms,
        shopStock: shops,
      );
      _seedCachesFrom(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Writes the profile back, touching only what actually changed.
  ///
  /// ⭐ **Change is detected, not declared.** The obvious alternative — a
  /// `dirtyTowns` hint threaded down from `GameState` — makes every future call
  /// site responsible for remembering to name the town it touched, and the
  /// failure mode of forgetting is a silently unsaved storeroom. Comparing
  /// against what was last written cannot be forgotten, needs no interface
  /// change, and keeps `LocalProfileStorage` trivial. The cost is re-encoding
  /// nine small maps per save, which is nothing next to one network round trip.
  ///
  /// ⚠️ **Write order is load-bearing: parts first, character document last.**
  /// Two reasons, and they agree:
  ///
  /// 1. **Resumability.** [load] treats a missing character document as "no
  ///    new-layout save here", so writing it last makes it a commit marker. A
  ///    migration that dies after three of nine storerooms leaves no character
  ///    document, so the next sign-in re-reads the untouched legacy save and
  ///    starts again — and the three town documents already written match what
  ///    it would write, so they are skipped rather than rewritten. Nothing
  ///    half-converted is ever mistaken for a finished save.
  /// 2. **Which way a torn write leans.** A crash between the town writes and
  ///    the character write leaves an item both in the storeroom (new) and in
  ///    the backpack (stale character document). The other order loses it from
  ///    both. For a game whose whole subject is the player's stuff, a
  ///    duplicated log is a far kinder failure than a destroyed heirloom.
  @override
  Future<void> save(PlayerProfile profile) async {
    try {
      await _ensureSeeded();
      final docs = ProfileDocuments.split(profile);
      // 1. The parts.
      await _syncTownDocs(_storeroomsPath, docs.storerooms, _writtenStorerooms);
      await _syncTownDocs(_shopStockPath, docs.shopStock, _writtenShopStock);
      // 2. The account document.
      await _writeUserDoc(docs.user);
      // 3. The commit marker.
      final encoded = _canonical(docs.character);
      if (_writtenCharacter != encoded) {
        await store.set(_characterPath, docs.character);
        _writtenCharacter = encoded;
      }
    } catch (_) {
      // Best effort — the in-memory profile still holds the latest state, and
      // every cache above is only advanced *after* its write succeeded, so the
      // next save retries exactly what did not land.
    }
  }

  /// Erases this account's save.
  ///
  /// ⚠️ **This is the one place the legacy document is deleted.** Leaving it
  /// would make `clear` a lie: [load] would find no character document, fall
  /// into migration, and resurrect the character from the very save the player
  /// asked to be rid of. The "leave the legacy doc as a dead backup" ruling is
  /// about *migrating*, and it still holds there.
  @override
  Future<void> clear() async {
    try {
      for (final id in (await store.list(_storeroomsPath)).keys) {
        await store.delete('$_storeroomsPath/$id');
      }
      for (final id in (await store.list(_shopStockPath)).keys) {
        await store.delete('$_shopStockPath/$id');
      }
      await store.delete(_characterPath);
      await store.delete(_userPath);
      await store.delete(_legacyPath);
    } catch (_) {
    } finally {
      _writtenStorerooms.clear();
      _writtenShopStock.clear();
      _writtenCharacter = null;
      _writtenUserSansPresence = null;
      _writtenLastSeen = null;
      _seeded = false;
    }
  }

  // ---- Migration -------------------------------------------------------

  /// Converts `players/{uid}` into the new layout, if there is one to convert.
  ///
  /// ⭐ **Idempotent by construction, because it re-derives everything from an
  /// immutable source.** The legacy document is read and never written, so
  /// running this twice produces byte-identical documents the second time —
  /// which [save]'s change detection then skips entirely.
  ///
  /// Returns null for a genuinely new account, which is [load]'s "no save
  /// here" answer; `GameState.syncWithAuth` then seeds the cloud from the
  /// in-memory (guest) profile, creating `users/{uid}` and `characters/main`.
  Future<PlayerProfile?> _migrateFromLegacy() async {
    final legacy = await store.get(_legacyPath);
    if (legacy == null) return null;
    final profile = PlayerProfile.fromJson(legacy);
    await save(profile);
    return profile;
  }

  // ---- Write helpers ---------------------------------------------------

  /// Brings one town-keyed collection in line with [want]: writes what differs,
  /// deletes what is no longer wanted, leaves the rest alone.
  Future<void> _syncTownDocs(
    String collectionPath,
    Map<String, Map<String, dynamic>> want,
    Map<String, String> written,
  ) async {
    for (final entry in want.entries) {
      final encoded = _canonical(entry.value);
      if (written[entry.key] == encoded) continue;
      await store.set('$collectionPath/${entry.key}', entry.value);
      written[entry.key] = encoded;
    }
    // A town whose storeroom was emptied drops out of `toJson` altogether
    // (the sparse-write filter), and its document has to follow it out —
    // otherwise a reset character walks into town and finds their old logs.
    for (final townId in written.keys.toList()) {
      if (want.containsKey(townId)) continue;
      await store.delete('$collectionPath/$townId');
      written.remove(townId);
    }
  }

  Future<void> _writeUserDoc(Map<String, dynamic> user) async {
    final lastSeen = DateTime.tryParse(
      user[ProfileDocuments.lastSeenField] as String? ?? '',
    );
    final sansPresence = _canonical({
      for (final e in user.entries)
        if (e.key != ProfileDocuments.lastSeenField) e.key: e.value,
    });
    if (_writtenUserSansPresence == sansPresence &&
        !_presenceIsStale(lastSeen)) {
      return;
    }
    await store.set(_userPath, user);
    _writtenUserSansPresence = sansPresence;
    _writtenLastSeen = lastSeen;
  }

  bool _presenceIsStale(DateTime? lastSeen) {
    final written = _writtenLastSeen;
    // Identical stamps — including two nulls, a profile that has never been
    // touched — are not stale by any reading.
    if (lastSeen == written) return false;
    if (lastSeen == null || written == null) return true;
    return lastSeen.difference(written).abs() >= presenceWriteInterval;
  }

  /// Fills the caches from a profile just read off the server, so a save that
  /// follows a load with nothing changed in between writes nothing at all.
  void _seedCachesFrom(PlayerProfile profile) {
    final docs = ProfileDocuments.split(profile);
    _writtenStorerooms
      ..clear()
      ..addAll(docs.storerooms.map((k, v) => MapEntry(k, _canonical(v))));
    _writtenShopStock
      ..clear()
      ..addAll(docs.shopStock.map((k, v) => MapEntry(k, _canonical(v))));
    _writtenCharacter = _canonical(docs.character);
    _writtenUserSansPresence = _canonical({
      for (final e in docs.user.entries)
        if (e.key != ProfileDocuments.lastSeenField) e.key: e.value,
    });
    _writtenLastSeen = DateTime.tryParse(
      docs.user[ProfileDocuments.lastSeenField] as String? ?? '',
    );
    _seeded = true;
  }

  /// ⚠️ A save that has never seen the server cannot tell an orphaned town
  /// document from one that was never there — so before the first write of a
  /// session that did not begin with a successful [load], ask.
  Future<void> _ensureSeeded() async {
    if (_seeded) return;
    for (final e in (await store.list(_storeroomsPath)).entries) {
      _writtenStorerooms[e.key] = _canonical(e.value);
    }
    for (final e in (await store.list(_shopStockPath)).entries) {
      _writtenShopStock[e.key] = _canonical(e.value);
    }
    _seeded = true;
  }
}

/// A JSON encoding that does not depend on key order.
///
/// ⚠️ Without the sort, every town would look changed on the first save after
/// a load: the map comes back from the wire in one order and is rebuilt from
/// the profile in another, and the "did this town change" comparison would be
/// answered by insertion order rather than by contents.
String _canonical(Object? value) => jsonEncode(_sorted(value));

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}
