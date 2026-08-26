/// THE STORAGE RESTRUCTURE (designer, 2026-08-26): the cloud save left one
/// `players/{uid}` document for `users/{uid}` + `characters/{cid}` + one
/// document per town.
///
/// ⭐ What these tests actually defend, in order of how much a regression would
/// cost a playtester: an existing save survives the conversion; a half-finished
/// conversion finishes rather than corrupts; and a deposit in Hearthwood does
/// not rewrite the eight towns nobody touched.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_state.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

// ---- A Firestore that remembers exactly who touched what ------------------

/// An in-memory [DocStore] that records every read, write and delete, so a
/// test can assert on the *set of writes* rather than only on the end state.
class _RecordingStore implements DocStore {
  final Map<String, Map<String, dynamic>> docs = {};
  final List<String> writes = [];
  final List<String> deletes = [];
  final List<String> reads = [];

  /// Paths whose next write throws — for simulating a migration that dies
  /// partway through.
  final Set<String> failWrites = {};

  @override
  Future<Map<String, dynamic>?> get(String path) async {
    reads.add(path);
    final d = docs[path];
    return d == null ? null : jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> list(String collectionPath) async {
    reads.add('$collectionPath/');
    return {
      for (final e in docs.entries)
        if (e.key.startsWith('$collectionPath/') &&
            !e.key.substring(collectionPath.length + 1).contains('/'))
          e.key.split('/').last:
              jsonDecode(jsonEncode(e.value)) as Map<String, dynamic>,
    };
  }

  @override
  Future<void> set(String path, Map<String, dynamic> fields) async {
    if (failWrites.contains(path)) throw StateError('simulated outage: $path');
    writes.add(path);
    docs[path] = jsonDecode(jsonEncode(fields)) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String path) async {
    deletes.add(path);
    docs.remove(path);
  }

  void forget() {
    writes.clear();
    deletes.clear();
    reads.clear();
  }
}

const _uid = 'u1';
const _userPath = 'users/$_uid';
const _charPath = 'users/$_uid/characters/main';
const _roomsPath = '$_charPath/storerooms';
const _shopsPath = '$_charPath/shopStock';
const _legacyPath = 'players/$_uid';

/// A profile that has been PLAYED, with something in more than one town —
/// nine-town rewrites are invisible on a character who has visited one.
PlayerProfile _veteran() {
  final p = PlayerProfile.newPlayer(name: 'Christian')
    ..xp = 50000
    ..gold = 2220
    ..resonancePrisms = 12
    ..duelsWon = 7
    ..duelsLost = 2
    ..lastSeenAt = DateTime.utc(2026, 8, 20, 9)
    ..skillXp['woodcarving'] = 600
    ..zoneClears['whispering_woods'] = 3
    ..backpack = Backpack.of(const [InventorySlot(defId: 'oak_log')])
    ..belt = const Belt(loaded: ['sapwort_draught'])
    ..storerooms['hearthwood'] = const Storeroom(stacks: {'oak_log': 6})
    ..storerooms['pennycross'] = const Storeroom(
      stacks: {'copper_ore': 4},
      instanceIds: ['h'],
    )
    ..shopStock['hearthwood'] = const TownShopState(
      stock: {'sapwort_draught': 3},
      lastResetDay: 20000,
    );
  p.itemInstances['h'] = const ItemInstance(
    instanceId: 'h',
    defId: 'heartwood_stave',
  );
  p.equipped[EquipSlot.mainHand] = 'h';
  return p;
}

/// The fields that decide whether two profiles are the same save. Compared as
/// JSON so a new field is covered the day it is added, rather than the day
/// someone remembers to extend this list.
String _essence(PlayerProfile p) => jsonEncode(p.toJson());

void main() {
  group('the document map', () {
    test('split puts each town in its own document and leaves the big maps '
        'off the character', () {
      final docs = ProfileDocuments.split(_veteran());

      expect(
        docs.storerooms.keys,
        unorderedEquals(['hearthwood', 'pennycross']),
        reason: 'one document per town that holds anything',
      );
      expect(docs.shopStock.keys, ['hearthwood']);
      expect(
        docs.character.containsKey('storerooms'),
        isFalse,
        reason:
            '⚠️ the mutant this kills: a split that copies the big maps '
            'onto the character doc as well, which is the profile-size '
            'problem the restructure exists to solve',
      );
      expect(docs.character.containsKey('shopStock'), isFalse);
      expect(
        docs.character['itemInstances'],
        isNotEmpty,
        reason:
            'item INSTANCES stay on the character by ruling — they are '
            'per-item property sheets, not a location map',
      );
      expect(docs.character['xp'], 50000);
    });

    test('the account document carries presence and a social label, and '
        'presence leaves the character document', () {
      final docs = ProfileDocuments.split(_veteran());

      expect(docs.user['displayName'], 'Christian');
      expect(docs.user['lastSeenAt'], '2026-08-20T09:00:00.000Z');
      expect(docs.user['schemaVersion'], ProfileDocuments.schemaVersion);
      expect(
        docs.character.containsKey('lastSeenAt'),
        isFalse,
        reason:
            '⚠️ the mutant this kills: presence left on the character, '
            'which would make a friends-list read walk into a stranger\'s '
            'character subcollection for one timestamp',
      );
      expect(
        docs.character['name'],
        'Christian',
        reason:
            'the character still owns its own name; displayName is the '
            'copy, not the source',
      );
    });

    test('skillXp is always present on the character document, even empty', () {
      final docs = ProfileDocuments.split(PlayerProfile.newPlayer());
      expect(docs.character['skillXp'], isEmpty);
      expect(
        docs.character.containsKey('skillXp'),
        isTrue,
        reason:
            '⚠️ the mutant this kills: the one sparsely-written field '
            'missing from the update mask, so a reset leaves the old skill '
            'ledger alive in the cloud',
      );
    });

    test('split then assemble round-trips a maximal profile', () {
      final original = _veteran();
      final docs = ProfileDocuments.split(original);
      final back = ProfileDocuments.assemble(
        user: docs.user,
        character: docs.character,
        storerooms: docs.storerooms,
        shopStock: docs.shopStock,
      );

      expect(
        _essence(back),
        _essence(original),
        reason: 'the whole save, field for field, through the cut',
      );
      expect(back.storerooms['pennycross']!.instanceIds, ['h']);
      // ⚠️ `.toUtc()` because `fromJson` localises the stamp and Dart's
      // `DateTime ==` compares the zone flag as well as the instant — the two
      // are the same moment, which is all presence asks of it.
      expect(back.lastSeenAt!.toUtc(), original.lastSeenAt);
      expect(back.shopStock['hearthwood']!.lastResetDay, 20000);
    });

    test('assemble tolerates a character with no account document and no '
        'towns', () {
      final docs = ProfileDocuments.split(PlayerProfile.newPlayer());
      final back = ProfileDocuments.assemble(character: docs.character);
      expect(back.name, 'Apprentice');
      expect(back.storerooms, isEmpty);
      expect(back.lastSeenAt, isNull);
    });
  });

  group('migration off players/{uid}', () {
    test('a legacy save converts, lands in the new layout, and reads back as '
        'the same save', () async {
      final store = _RecordingStore();
      final legacy = _veteran();
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(legacy.toJson())) as Map<String, dynamic>;

      final storage = FirestoreProfileStorage(_uid, store: store);
      final migrated = await storage.load();

      expect(migrated, isNotNull);
      expect(
        _essence(migrated!),
        _essence(legacy),
        reason:
            'the conversion is lossless — this is a playtester\'s only '
            'character',
      );
      expect(
        store.docs.keys,
        containsAll(<String>[
          _userPath,
          _charPath,
          '$_roomsPath/hearthwood',
          '$_roomsPath/pennycross',
          '$_shopsPath/hearthwood',
        ]),
      );

      // And what a fresh client reads back is the same save again.
      final reader = FirestoreProfileStorage(_uid, store: store);
      final reloaded = await reader.load();
      expect(_essence(reloaded!), _essence(legacy));
    });

    test('the legacy document is left untouched as a dead backup', () async {
      final store = _RecordingStore();
      final before =
          jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(before)) as Map<String, dynamic>;

      await FirestoreProfileStorage(_uid, store: store).load();

      expect(
        store.docs[_legacyPath],
        before,
        reason:
            '⚠️ the mutant this kills: a migration that moves rather '
            'than copies, leaving nothing to fall back to',
      );
      expect(store.writes, isNot(contains(_legacyPath)));
      expect(store.deletes, isNot(contains(_legacyPath)));
    });

    test(
      'the character document is written LAST — it is the commit marker',
      () async {
        final store = _RecordingStore();
        store.docs[_legacyPath] =
            jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;

        await FirestoreProfileStorage(_uid, store: store).load();

        expect(
          store.writes.last,
          _charPath,
          reason:
              '⚠️ the mutant this kills: the marker written first, which '
              'makes a half-converted save look finished and strands every '
              'storeroom that had not been written yet',
        );
        expect(
          store.writes.indexOf('$_roomsPath/hearthwood'),
          lessThan(store.writes.indexOf(_charPath)),
          reason: 'parts before the whole',
        );
      },
    );

    test('re-running on an already-migrated account writes NOTHING', () async {
      final store = _RecordingStore();
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;
      await FirestoreProfileStorage(_uid, store: store).load();

      store.forget();
      final second = FirestoreProfileStorage(_uid, store: store);
      final profile = await second.load();
      await second.save(profile!);

      expect(
        store.writes,
        isEmpty,
        reason:
            '⚠️ the mutant this kills: idempotence that is only true of '
            'the end state — re-migrating and rewriting nine documents on '
            'every sign-in is the write bill this restructure exists to cut',
      );
      expect(store.deletes, isEmpty);
      expect(
        store.reads,
        isNot(contains(_legacyPath)),
        reason: 'a finished migration never looks at the legacy doc again',
      );
    });

    test('a migration that dies partway RESUMES, and rewrites only what it '
        'did not get to', () async {
      final store = _RecordingStore();
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;

      // The outage hits the second storeroom, so the first one is on disk and
      // the character document — the marker — never is.
      store.failWrites.add('$_roomsPath/pennycross');
      await FirestoreProfileStorage(_uid, store: store).load();
      expect(store.docs.containsKey('$_roomsPath/hearthwood'), isTrue);
      expect(
        store.docs.containsKey(_charPath),
        isFalse,
        reason: 'no marker, so this is not yet a save',
      );

      // Next sign-in, network healthy.
      store.failWrites.clear();
      store.forget();
      final resumed = FirestoreProfileStorage(_uid, store: store);
      final profile = await resumed.load();

      expect(
        _essence(profile!),
        _essence(_veteran()),
        reason:
            'the interrupted conversion completes from the untouched '
            'legacy doc — nothing is lost to the outage',
      );
      expect(
        store.writes,
        isNot(contains('$_roomsPath/hearthwood')),
        reason:
            '⚠️ the mutant this kills: a resume that starts over and '
            'rewrites the documents that already landed',
      );
      expect(store.writes, contains('$_roomsPath/pennycross'));
      expect(store.writes.last, _charPath);
    });

    test(
      'a fresh account gets users/{uid} and characters/main on first save',
      () async {
        final store = _RecordingStore();
        final storage = FirestoreProfileStorage(_uid, store: store);

        expect(
          await storage.load(),
          isNull,
          reason: 'nothing legacy, nothing new — a genuinely new account',
        );
        await storage.save(PlayerProfile.newPlayer(name: 'Nova'));

        expect(store.docs[_charPath]!['name'], 'Nova');
        expect(store.docs[_userPath]!['displayName'], 'Nova');
        expect(
          store.docs.keys.where((k) => k.startsWith(_roomsPath)),
          isEmpty,
          reason:
              'a new character has stored nothing, so there is no town '
              'document to write',
        );
      },
    );
  });

  group('one town changes, one document is written', () {
    /// A storage already in the steady state, with a profile loaded off it.
    Future<(_RecordingStore, FirestoreProfileStorage, GameState)>
    played() async {
      final store = _RecordingStore();
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;
      final storage = FirestoreProfileStorage(_uid, store: store);
      await storage.load();
      store.forget();
      final fresh = FirestoreProfileStorage(_uid, store: store);
      final game = GameState(fresh, (await fresh.load())!);
      store.forget();
      return (store, fresh, game);
    }

    test('a deposit in one town writes that town and the character, and no '
        'other town', () async {
      final (store, _, game) = await played();

      await game.deposit('hearthwood', 0);

      expect(store.writes, contains('$_roomsPath/hearthwood'));
      expect(
        store.writes,
        contains(_charPath),
        reason: 'the backpack lost a slot, so the character changed too',
      );
      expect(
        store.writes,
        isNot(contains('$_roomsPath/pennycross')),
        reason:
            '⚠️ THE mutant this kills: save() rewriting every town on '
            'every mutation, which is the whole cost the split was meant to '
            'remove — a nine-town character would pay nine writes to stash '
            'one log',
      );
      expect(
        store.writes,
        isNot(contains('$_shopsPath/hearthwood')),
        reason: 'the shop was not touched either',
      );
    });

    test('presence alone rewrites neither a town nor the character', () async {
      final (store, _, game) = await played();

      await game.touchPresence();

      expect(store.writes.where((w) => w.startsWith(_roomsPath)), isEmpty);
      expect(
        store.writes,
        isNot(contains(_charPath)),
        reason:
            'presence moved off the character document, so a heartbeat '
            'no longer rewrites the whole save',
      );
    });

    test('an emptied storeroom DELETES its document', () async {
      final (store, _, game) = await played();

      // Take the six logs back out; the town then holds nothing.
      final moved = await game.takeAllFromStoreroom('hearthwood', 'oak_log');
      expect(moved, greaterThan(0));
      // Drain whatever the backpack could not hold in one pass.
      while ((game.profile.storerooms['hearthwood']?.stacks['oak_log'] ?? 0) >
          0) {
        game.profile.backpack = Backpack.empty();
        await game.takeAllFromStoreroom('hearthwood', 'oak_log');
      }

      expect(
        store.deletes,
        contains('$_roomsPath/hearthwood'),
        reason:
            '⚠️ the mutant this kills: a town that drops out of the '
            'profile but whose document lingers, so the next load hands the '
            'player back goods they already carried away',
      );
      expect(store.docs.containsKey('$_roomsPath/hearthwood'), isFalse);
    });

    test(
      'a reset clears every town document and the account doc survives',
      () async {
        final (store, storage, game) = await played();

        await game.resetProfile();

        expect(store.docs.keys.where((k) => k.startsWith(_roomsPath)), isEmpty);
        expect(store.docs.keys.where((k) => k.startsWith(_shopsPath)), isEmpty);
        expect(store.docs[_charPath]!['xp'], 0);
        expect(
          store.docs[_charPath]!['skillXp'],
          isEmpty,
          reason:
              '⚠️ the mutant this kills: a sparse field left out of the '
              'update mask, so the cloud keeps a ledger the player reset',
        );
        expect(store.docs[_userPath], isNotNull);

        final reloaded = await FirestoreProfileStorage(
          _uid,
          store: store,
        ).load();
        expect(reloaded!.xp, 0);
        expect(reloaded.name, 'Christian', reason: 'a reset, not an exit');
        expect(reloaded.storerooms, isEmpty);
      },
    );

    test('clear() erases the legacy document too, or load would resurrect the '
        'character', () async {
      final store = _RecordingStore();
      store.docs[_legacyPath] =
          jsonDecode(jsonEncode(_veteran().toJson())) as Map<String, dynamic>;
      final storage = FirestoreProfileStorage(_uid, store: store);
      await storage.load();

      await storage.clear();

      expect(store.docs, isEmpty);
      expect(
        await FirestoreProfileStorage(_uid, store: store).load(),
        isNull,
        reason:
            '⚠️ the mutant this kills: clear() sparing the legacy doc, '
            'so the very next load migrates the deleted character back',
      );
    });
  });

  group('the guest path is untouched', () {
    test('an existing local blob still loads, and is still written whole', () {
      // The exact bytes a pre-restructure build wrote: one document, big maps
      // and presence included.
      final blob = jsonEncode(_veteran().toJson());
      final decoded = jsonDecode(blob) as Map<String, dynamic>;

      expect(
        decoded.containsKey('storerooms'),
        isTrue,
        reason:
            '⚠️ the mutant this kills: the split leaking into the local '
            'format, which would strand every guest save on disk',
      );
      expect(decoded.containsKey('shopStock'), isTrue);
      expect(decoded.containsKey('lastSeenAt'), isTrue);

      final back = PlayerProfile.fromJson(decoded);
      expect(_essence(back), blob);
      expect(back.storerooms['hearthwood']!.stacks['oak_log'], 6);
      expect(back.lastSeenAt, DateTime.utc(2026, 8, 20, 9).toLocal());
    });
  });
}
