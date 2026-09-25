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

/// A save refused because the cloud no longer holds the version this client
/// last loaded — another device saved in between (sync race, 2026-09-25).
///
/// ⭐ **Typed, and the one failure [FirestoreProfileStorage.save] does not
/// swallow.** Every other save error is best-effort (the in-memory profile is
/// still the truth, the next save retries); this one means the in-memory
/// profile is *not* the truth any more, and only `GameState` can fix that —
/// by reloading. See `GameState._persist`.
class SaveConflictException implements Exception {
  /// The document whose precondition failed.
  final String path;

  const SaveConflictException(this.path);

  @override
  String toString() => 'SaveConflictException: $path changed on the server';
}

/// The document operations [FirestoreProfileStorage] needs.
///
/// ⭐ Exists so the split can be tested against a recording fake: "one deposit
/// writes one town document" is a claim about *which writes happen*, and there
/// is no way to make that claim about a static HTTP call.
abstract interface class DocStore {
  Future<Map<String, dynamic>?> get(String path);

  /// [get], plus the server `updateTime` the fields were read at.
  Future<VersionedDoc?> getVersioned(String path);

  Future<Map<String, Map<String, dynamic>>> list(String collectionPath);

  /// Applies [writes] atomically — all or none — and returns each write's
  /// new `updateTime`, index for index.
  ///
  /// A precondition that does not hold fails the whole batch and throws
  /// [SaveConflictException] — see [FirestoreRest.commit].
  Future<List<String?>> commit(List<FirestoreWrite> writes);

  Future<void> delete(String path);
}

/// The real thing, over [FirestoreRest].
class FirestoreDocStore implements DocStore {
  const FirestoreDocStore();

  @override
  Future<Map<String, dynamic>?> get(String path) => FirestoreRest.get(path);

  @override
  Future<VersionedDoc?> getVersioned(String path) =>
      FirestoreRest.getVersioned(path);

  @override
  Future<Map<String, Map<String, dynamic>>> list(String collectionPath) =>
      FirestoreRest.list(collectionPath);

  @override
  Future<List<String?>> commit(List<FirestoreWrite> writes) async {
    try {
      return await FirestoreRest.commit(writes);
    } on FirestorePreconditionException {
      throw SaveConflictException(
        writes.firstWhere((w) => w.isConditional).path,
      );
    }
  }

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

  /// The character document's server `updateTime` as of this client's last
  /// successful read or write of it — **the version of the whole save**.
  ///
  /// ⭐ **Optimistic concurrency (sync race, 2026-09-25).** Christian plays on
  /// a phone and a desktop; each holds a whole profile in memory, and before
  /// this each save wrote whole documents last-writer-wins. Device A deposited
  /// rolled gear (storeroom gains ids, character pool gains instances); device
  /// B then saved its stale character document but skipped the storeroom
  /// (unchanged *on B*) — leaving ids in the storeroom with no instance
  /// behind them. Every character write now names this version as its
  /// precondition, so the stale device's save is refused instead.
  String? _characterVersion;

  /// Whether the character document is known to exist on the server. False
  /// until a read or write proves it — so a first write is conditional on
  /// the document being *absent* (`exists=false`), and a client whose load
  /// failed can never seed over a save it could not see.
  bool _characterExists = false;

  /// Saves run one at a time, in call order.
  ///
  /// ⚠️ **Load-bearing since the precondition.** Two overlapping saves from
  /// this same client would both name the version the first one is about to
  /// replace, and the second would be refused as a conflict with itself.
  Future<void> _queue = Future.value();

  /// Bumped by every [load]. A save queued against an older world is dropped
  /// when its turn comes: the profile it captured has since been replaced.
  int _epoch = 0;

  /// Set when a save was refused; until the next [load], every save is
  /// refused too without touching the network — they were all made against
  /// the same stale world.
  bool _conflicted = false;

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
    _epoch++;
    _conflicted = false;
    try {
      final character = await store.getVersioned(_characterPath);
      // ⭐ The character document is the flag for "the new layout is complete
      // here" — see [_migrateFromLegacy]'s write order. Its absence, and only
      // its absence, sends us looking for a legacy save to convert.
      if (character == null) {
        _characterExists = false;
        _characterVersion = null;
        return await _migrateFromLegacy();
      }

      final user = await store.get(_userPath);
      final rooms = await store.list(_storeroomsPath);
      final shops = await store.list(_shopStockPath);
      final profile = ProfileDocuments.assemble(
        user: user,
        character: character.fields,
        storerooms: rooms,
        shopStock: shops,
      );
      _seedCachesFrom(profile);
      // ⚠️ Remembered only once the whole read succeeded: a version paired
      // with half a save would license a write against a world never seen.
      _characterExists = true;
      _characterVersion = character.updateTime;
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
  /// ⭐ **One atomic commit** (sync race, 2026-09-25). Everything this save
  /// changes — the character document, each changed or emptied town
  /// document, the account document when due — goes to the server as ONE
  /// `:commit` batch, so there is no order and no torn write: it all lands,
  /// or none of it does. Before, documents were PATCHed one at a time and
  /// last-writer-wins, and a stale device could land its character document
  /// while its untouched storeroom kept the other device's ids — exactly the
  /// dangling-id save Christian found.
  ///
  /// ⚠️ **The character write carries the precondition** —
  /// `currentDocument.updateTime` = [_characterVersion], or `exists=false` for
  /// a document never seen — and a refused precondition refuses the batch.
  /// Since that version is the version of the *whole save*, the character
  /// document rides in every batch that writes anything else too, even when
  /// its own fields did not change: a storeroom-only change must still move
  /// the version, or another device's stale view of that storeroom would slip
  /// through ungated.
  ///
  /// ⚠️ **Every update mask covers the fields last written as well as the
  /// fields written now** — see [_maskFor]. A masked write leaves unnamed
  /// fields alone, and `toJson` is sparse (an emptied `instanceIds` is simply
  /// absent), so a mask of the present keys alone left the old ids on the
  /// server: a single-device route to the very same dangling ids.
  ///
  /// Throws [SaveConflictException] when the batch is refused; every other
  /// failure is swallowed (see the catch).
  @override
  Future<void> save(PlayerProfile profile) => _enqueue(() => _saveNow(profile));

  Future<void> _enqueue(Future<void> Function() write) {
    final epoch = _epoch;
    final run = _queue.then((_) async {
      // A load has replaced the world this save was made in.
      if (epoch != _epoch) return;
      if (_conflicted) throw SaveConflictException(_characterPath);
      await write();
    });
    _queue = run.catchError((_) {});
    return run;
  }

  Future<void> _saveNow(PlayerProfile profile) async {
    try {
      await _ensureSeeded();
      final docs = ProfileDocuments.split(profile);
      final character = _canonical(docs.character);
      final rooms = _townWrites(
        _storeroomsPath,
        docs.storerooms,
        _writtenStorerooms,
      );
      final shops = _townWrites(
        _shopStockPath,
        docs.shopStock,
        _writtenShopStock,
      );
      final user = _userWrite(docs.user);
      final saveChanged =
          _writtenCharacter != character ||
          rooms.isNotEmpty ||
          shops.isNotEmpty;
      if (!saveChanged && user == null) return;

      final batch = [
        if (saveChanged)
          FirestoreWrite.update(
            _characterPath,
            docs.character,
            updateMask: _maskFor(docs.character, _writtenCharacter),
            ifUpdateTime: _characterExists ? _characterVersion : null,
            // A document never seen must still be absent. (One seen without a
            // version — a response that carried none — goes unconditionally.)
            ifExists: _characterExists ? null : false,
          ),
        ...rooms,
        ...shops,
        ?user,
      ];
      final times = await store.commit(batch);

      // ⭐ Atomic, so every cache advances together — or, on a throw above,
      // none does and the next save retries the whole batch.
      if (saveChanged) {
        _writtenCharacter = character;
        _characterExists = true;
        _characterVersion = times.first;
      }
      _advanceTowns(docs.storerooms, _writtenStorerooms);
      _advanceTowns(docs.shopStock, _writtenShopStock);
      if (user != null) _advanceUser(docs.user);
    } on SaveConflictException {
      _conflicted = true;
      rethrow;
    } catch (_) {
      // Best effort — the in-memory profile still holds the latest state, and
      // the caches only advance after a commit lands, so the next save
      // retries exactly what did not.
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
      _characterExists = false;
      _characterVersion = null;
      _conflicted = false;
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
  ///
  /// ⭐ **The migration is one commit like any other save**, and that is what
  /// makes it resumable now: [load] treats a missing character document as
  /// "no new-layout save here", and an atomic batch either lands the
  /// character document together with every town document, or lands nothing
  /// — so an interrupted migration leaves the account exactly as it found
  /// it, and the next sign-in converts the untouched legacy save from
  /// scratch. The character write is conditional on the document's absence,
  /// so of two devices migrating at once, the second is simply refused.
  Future<PlayerProfile?> _migrateFromLegacy() async {
    final legacy = await store.get(_legacyPath);
    if (legacy == null) return null;
    final profile = PlayerProfile.fromJson(legacy);
    await _enqueue(() => _saveNow(profile));
    return profile;
  }

  // ---- Write helpers ---------------------------------------------------

  /// The update mask for a document: every field in [now], plus every field
  /// the server held as of [written] (its canonical JSON, or null when never
  /// written or read).
  ///
  /// ⚠️ A field named in the mask but absent from the data is DELETED on the
  /// server. That is the whole reason for the union: a sparse `toJson` that
  /// stops emitting `instanceIds` must take the old list off the server too.
  static List<String> _maskFor(Map<String, dynamic> now, String? written) {
    final before = written == null ? null : jsonDecode(written);
    return {
      ...now.keys,
      if (before is Map) ...before.keys.cast<String>(),
    }.toList()..sort();
  }

  /// The writes that bring one town-keyed collection in line with [want]:
  /// an update for each town that differs, a delete for each town no longer
  /// wanted, nothing for the rest.
  List<FirestoreWrite> _townWrites(
    String collectionPath,
    Map<String, Map<String, dynamic>> want,
    Map<String, String> written,
  ) => [
    for (final entry in want.entries)
      if (written[entry.key] != _canonical(entry.value))
        FirestoreWrite.update(
          '$collectionPath/${entry.key}',
          entry.value,
          updateMask: _maskFor(entry.value, written[entry.key]),
        ),
    // A town whose storeroom was emptied drops out of `toJson` altogether
    // (the sparse-write filter), and its document has to follow it out —
    // otherwise a reset character walks into town and finds their old logs.
    for (final townId in written.keys)
      if (!want.containsKey(townId))
        FirestoreWrite.delete('$collectionPath/$townId'),
  ];

  /// After a commit landed, [written] is exactly [want].
  void _advanceTowns(
    Map<String, Map<String, dynamic>> want,
    Map<String, String> written,
  ) {
    written
      ..clear()
      ..addAll(want.map((k, v) => MapEntry(k, _canonical(v))));
  }

  /// The account-document write, or null when it is not due.
  FirestoreWrite? _userWrite(Map<String, dynamic> user) {
    final lastSeen = DateTime.tryParse(
      user[ProfileDocuments.lastSeenField] as String? ?? '',
    );
    if (_writtenUserSansPresence == _sansPresence(user) &&
        !_presenceIsStale(lastSeen)) {
      return null;
    }
    // ⚠️ Masked to the fields this client owns, and only those: the account
    // document is where other features (achievements, friends) will hang
    // their own fields, and a save must never erase them.
    return FirestoreWrite.update(_userPath, user);
  }

  void _advanceUser(Map<String, dynamic> user) {
    _writtenUserSansPresence = _sansPresence(user);
    _writtenLastSeen = DateTime.tryParse(
      user[ProfileDocuments.lastSeenField] as String? ?? '',
    );
  }

  static String _sansPresence(Map<String, dynamic> user) => _canonical({
    for (final e in user.entries)
      if (e.key != ProfileDocuments.lastSeenField) e.key: e.value,
  });

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
    _advanceUser(docs.user);
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
