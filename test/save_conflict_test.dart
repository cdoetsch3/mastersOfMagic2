/// THE SYNC RACE (2026-09-25): two devices, each saving whole documents
/// last-writer-wins, left Christian's Hearthwood storeroom naming nine
/// instances his character document no longer held.
///
/// ⭐ What these defend: a cloud save is ONE atomic `:commit` carrying the
/// character document and every changed town document together; the
/// character write in it names the version this client loaded
/// (`currentDocument.updateTime`), so a stale device's batch is refused
/// whole; and `GameState` answers a refusal by reloading, once, with one
/// banner.
///
/// Driven through the real [FirestoreRest] over a `MockClient` standing in
/// for Firestore, so the batch and its precondition are asserted on the wire.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:masters_of_magic_2/game/firestore_rest.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_documents.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';

const _uid = 'u1';
const _charPath = 'users/$_uid/characters/main';
const _roomsPath = '$_charPath/storerooms';

/// One write of a `:commit` request, as the server received it.
typedef _Write = ({
  String path,
  bool isDelete,
  Map<String, dynamic>? currentDocument,
  List<String>? mask,
});

/// A tiny Firestore: documents by path, a version per document, reads, and
/// an atomic `:commit` that checks every precondition before applying any
/// write and honours update masks — the way the real one does.
class _FakeFirestore {
  final Map<String, Map<String, dynamic>> docs = {};
  final Map<String, int> versions = {};

  /// Every `:commit` request, in order, one list of writes each.
  final List<List<_Write>> commits = [];

  /// Every request that could change a document (commits, PATCHes,
  /// DELETEs) — "nothing was partially applied" is a claim about this.
  int mutatingRequests = 0;

  /// When set, the next commit answers with this instead of applying.
  http.Response? nextCommitResponse;

  /// When set, the next character GET answers with this instead.
  http.Response? nextCharacterGet;

  String versionOf(String path) =>
      '2026-09-25T10:00:00.${(versions[path] ?? 0).toString().padLeft(6, '0')}Z';

  void put(String path, Map<String, dynamic> fields) {
    docs[path] = fields;
    versions[path] = (versions[path] ?? 0) + 1;
  }

  /// Seeds the documents a saved [profile] would occupy.
  void seed(PlayerProfile profile) {
    final split = ProfileDocuments.split(profile);
    put('users/$_uid', split.user);
    put(_charPath, split.character);
    for (final e in split.storerooms.entries) {
      put('$_roomsPath/${e.key}', e.value);
    }
  }

  /// A snapshot of every document, for "nothing changed" assertions.
  String snapshot() => jsonEncode(docs);

  Map<String, dynamic> _doc(String path) => {
    'name': 'projects/p/databases/(default)/documents/$path',
    'fields': FirestoreRest.encodeFields(docs[path]!),
    'updateTime': versionOf(path),
  };

  static String _pathOf(String name) => name.split('/documents/').last;

  Future<http.Response> handle(http.Request req) async {
    final urlPath = Uri.decodeComponent(req.url.path);
    if (req.method == 'POST' && urlPath.endsWith('documents:commit')) {
      return _commit(req);
    }
    if (req.method != 'GET') {
      mutatingRequests++;
      return http.Response('unexpected ${req.method}', 500);
    }
    final path = urlPath.split('/documents/').last;
    if (path == _charPath && nextCharacterGet != null) {
      final r = nextCharacterGet!;
      nextCharacterGet = null;
      return r;
    }
    if (docs.containsKey(path)) {
      return http.Response(jsonEncode(_doc(path)), 200);
    }
    if (path.endsWith('/storerooms') || path.endsWith('/shopStock')) {
      final kids = docs.keys.where(
        (k) =>
            k.startsWith('$path/') &&
            !k.substring(path.length + 1).contains('/'),
      );
      return http.Response(
        jsonEncode({'documents': kids.map(_doc).toList()}),
        200,
      );
    }
    return http.Response('{"error":{"code":404}}', 404);
  }

  http.Response _commit(http.Request req) {
    mutatingRequests++;
    final raw = ((jsonDecode(req.body) as Map)['writes'] as List)
        .cast<Map<String, dynamic>>();
    final writes = <_Write>[
      for (final w in raw)
        (
          path: _pathOf(
            (w['delete'] ?? (w['update'] as Map)['name']) as String,
          ),
          isDelete: w.containsKey('delete'),
          currentDocument: w['currentDocument'] as Map<String, dynamic>?,
          mask: ((w['updateMask'] as Map?)?['fieldPaths'] as List?)
              ?.cast<String>(),
        ),
    ];
    commits.add(writes);
    if (nextCommitResponse != null) {
      final r = nextCommitResponse!;
      nextCommitResponse = null;
      return r;
    }
    // Every precondition first: one failure refuses the whole batch.
    for (final w in writes) {
      final pre = w.currentDocument;
      if (pre == null) continue;
      if (pre['updateTime'] != null && pre['updateTime'] != versionOf(w.path)) {
        return http.Response(
          '{"error":{"code":400,"status":"FAILED_PRECONDITION"}}',
          400,
        );
      }
      if (pre['exists'] == false && docs.containsKey(w.path)) {
        return http.Response(
          '{"error":{"code":409,"status":"ALREADY_EXISTS"}}',
          409,
        );
      }
    }
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < writes.length; i++) {
      final w = writes[i];
      if (w.isDelete) {
        docs.remove(w.path);
        versions.remove(w.path);
        results.add({});
        continue;
      }
      final fields = FirestoreRest.decodeFields(
        (raw[i]['update'] as Map)['fields'] as Map<String, dynamic>,
      );
      final next = {...?docs[w.path]};
      for (final f in w.mask ?? fields.keys) {
        if (fields.containsKey(f)) {
          next[f] = fields[f];
        } else {
          next.remove(f);
        }
      }
      put(w.path, next);
      results.add({'updateTime': versionOf(w.path)});
    }
    return http.Response(jsonEncode({'writeResults': results}), 200);
  }
}

/// A character wearing one rolled staff, with a second one in the pack.
PlayerProfile _mage() {
  final p = PlayerProfile.newPlayer(name: 'Christian')
    ..gold = 100
    ..backpack = Backpack.of(const [
      InventorySlot(defId: 'heartwood_stave', instanceId: 'spare'),
    ]);
  p.itemInstances['worn'] = const ItemInstance(
    instanceId: 'worn',
    defId: 'heartwood_stave',
  );
  p.itemInstances['spare'] = const ItemInstance(
    instanceId: 'spare',
    defId: 'heartwood_stave',
  );
  p.equipped[EquipSlot.mainHand] = 'worn';
  return p;
}

/// Moves the pack's first item into Hearthwood's storeroom — a deposit, the
/// mutation that raced.
void _deposit(PlayerProfile p) {
  final slot = p.backpack.slots.first!;
  p.backpack = p.backpack.withRemovedAt(0);
  p.storerooms['hearthwood'] = (p.storerooms['hearthwood'] ?? const Storeroom())
      .withDeposited(slot);
}

void main() {
  final originalClient = FirestoreRest.client;
  final originalTokenProvider = FirestoreRest.tokenProvider;
  late _FakeFirestore server;

  setUp(() {
    server = _FakeFirestore();
    FirestoreRest.client = MockClient(server.handle);
    FirestoreRest.tokenProvider = () async => null;
  });

  tearDown(() {
    FirestoreRest.client = originalClient;
    FirestoreRest.tokenProvider = originalTokenProvider;
  });

  group('one atomic commit per save', () {
    test('(a) one :commit carries the character write AND the town writes '
        'together', () async {
      server.seed(_mage());
      final storage = FirestoreProfileStorage(_uid);
      final profile = (await storage.load())!;

      _deposit(profile);
      await storage.save(profile);

      expect(
        server.mutatingRequests,
        1,
        reason:
            '⚠️ the mutant this kills: a document-at-a-time save, whose '
            'crash between writes lands half a deposit',
      );
      final paths = server.commits.single.map((w) => w.path);
      expect(paths, contains(_charPath), reason: 'the pool change');
      expect(
        paths,
        contains('$_roomsPath/hearthwood'),
        reason: 'the storeroom change, in the SAME batch',
      );
      expect(server.docs['$_roomsPath/hearthwood']!['instanceIds'], [
        'spare',
      ], reason: 'and the batch landed');
    });

    test('(b) the character write in the batch carries the loaded updateTime '
        'as its precondition', () async {
      server.seed(_mage());
      final loadedVersion = server.versionOf(_charPath);
      final storage = FirestoreProfileStorage(_uid);
      final profile = (await storage.load())!;

      _deposit(profile);
      await storage.save(profile);

      final batch = server.commits.single;
      expect(
        batch.firstWhere((w) => w.path == _charPath).currentDocument,
        {'updateTime': loadedVersion},
        reason:
            '⚠️ the mutant this kills: an unconditional character write — '
            'the last-writer-wins save that let a stale device clobber the '
            'pool',
      );
      expect(
        batch.where((w) => w.path != _charPath).map((w) => w.currentDocument),
        everyElement(isNull),
        reason:
            'the town writes need no precondition of their own: the one on '
            'the character write refuses the whole batch',
      );
    });

    for (final (label, response) in [
      (
        '400 FAILED_PRECONDITION',
        http.Response(
          '{"error":{"code":400,"status":"FAILED_PRECONDITION"}}',
          400,
        ),
      ),
      (
        '409 ABORTED',
        http.Response('{"error":{"code":409,"status":"ABORTED"}}', 409),
      ),
    ]) {
      test('(c) a $label on the commit throws SaveConflictException, and '
          'nothing was partially applied', () async {
        server.seed(_mage());
        final storage = FirestoreProfileStorage(_uid);
        final profile = (await storage.load())!;
        final before = server.snapshot();

        _deposit(profile);
        server.nextCommitResponse = response;

        await expectLater(
          storage.save(profile),
          throwsA(isA<SaveConflictException>()),
          reason:
              'the one save failure that must reach GameState — a '
              'swallowed conflict is a silently lost world',
        );
        expect(
          server.mutatingRequests,
          1,
          reason:
              '⚠️ one request, refused whole: no second write went out '
              'after the refusal',
        );
        expect(
          server.snapshot(),
          before,
          reason: 'nothing of the deposit reached the server',
        );

        // And every save until the next load is refused without a request.
        await expectLater(
          storage.save(profile),
          throwsA(isA<SaveConflictException>()),
          reason: 'the stale world stays stale until reloaded',
        );
        expect(
          server.mutatingRequests,
          1,
          reason: 'a known-stale save costs no network round trip',
        );
      });
    }

    test('a successful commit advances the remembered updateTime from its '
        'writeResults', () async {
      server.seed(_mage());
      final storage = FirestoreProfileStorage(_uid);
      final profile = (await storage.load())!;

      profile.gold += 1;
      await storage.save(profile);
      final afterFirst = server.versionOf(_charPath);
      profile.gold += 1;
      await storage.save(profile);

      expect(server.commits, hasLength(2), reason: 'two changes, two batches');
      expect(
        server.commits.last
            .firstWhere((w) => w.path == _charPath)
            .currentDocument,
        {'updateTime': afterFirst},
        reason:
            '⚠️ the mutant this kills: remembering only the loaded version — '
            'the second save would conflict with this device\'s own first',
      );
      expect(server.docs[_charPath]!['gold'], 102);
    });

    test('two overlapping saves from one device do not conflict with each '
        'other', () async {
      server.seed(_mage());
      final storage = FirestoreProfileStorage(_uid);
      final profile = (await storage.load())!;

      profile.gold += 1;
      final first = storage.save(profile);
      _deposit(profile);
      final second = storage.save(profile);

      await expectLater(
        Future.wait([first, second]),
        completes,
        reason:
            '⚠️ the mutant this kills: unserialised saves, where both name '
            'the version the first is about to replace and the second is '
            'refused as a conflict with itself',
      );
      expect(
        server.docs['$_roomsPath/hearthwood'],
        isNotNull,
        reason: 'the second save landed its storeroom',
      );
    });

    test('a storeroom whose last rolled item leaves takes its instanceIds '
        'off the server', () async {
      final stocked = _mage()
        ..backpack = Backpack.empty()
        ..storerooms['hearthwood'] = const Storeroom(
          stacks: {'oak_log': 6},
          instanceIds: ['spare'],
        );
      server.seed(stocked);
      final storage = FirestoreProfileStorage(_uid);
      final profile = (await storage.load())!;

      // Withdraw the staff; the logs stay, so the document stays too.
      profile.storerooms['hearthwood'] = const Storeroom(
        stacks: {'oak_log': 6},
      );
      profile.backpack = Backpack.of(const [
        InventorySlot(defId: 'heartwood_stave', instanceId: 'spare'),
      ]);
      await storage.save(profile);

      expect(
        server.docs['$_roomsPath/hearthwood'],
        {
          'stacks': {'oak_log': 6},
        },
        reason:
            '⚠️ the mutant this kills: a mask of only the keys `toJson` '
            'still emits — the emptied `instanceIds` is absent, so the old '
            'id would stay on the server and dangle the day the staff is '
            'sold: the same bug with no second device at all',
      );
    });

    test('the race itself: the stale device is refused and the fresh '
        'device\'s deposit survives intact', () async {
      server.seed(_mage());
      final phone = FirestoreProfileStorage(_uid);
      final desktop = FirestoreProfileStorage(_uid);
      final onPhone = (await phone.load())!;
      final onDesktop = (await desktop.load())!;

      _deposit(onPhone);
      await phone.save(onPhone);
      onDesktop.gold += 50; // stale: its pack still holds 'spare'

      await expectLater(
        desktop.save(onDesktop),
        throwsA(isA<SaveConflictException>()),
        reason: 'the desktop never saw the phone\'s deposit',
      );
      final reread = (await FirestoreProfileStorage(_uid).load())!;
      expect(reread.storerooms['hearthwood']!.instanceIds, [
        'spare',
      ], reason: 'the phone\'s deposit is on the server');
      expect(
        reread.itemInstances.containsKey('spare'),
        isTrue,
        reason:
            '⚠️ the bug: the stale character document used to land and the '
            'storeroom\'s id was left with no instance behind it',
      );
      expect(reread.gold, 100, reason: 'the stale device wrote nothing at all');
    });
  });

  group('(d) GameState on a conflict', () {
    test('reloads, sets the notice once, and does not loop', () async {
      final storage = _AlwaysConflicting(() {
        // The cloud's world, with one dangling storeroom id to repair — so
        // the reload's own follow-up save runs, and is refused too.
        final p = _mage()
          ..gold = 999
          ..storerooms['hearthwood'] = const Storeroom(instanceIds: ['ghost']);
        return p;
      });
      final game = GameState(storage, _mage());
      final notices = <String?>[];
      game.notice.addListener(() => notices.add(game.notice.value));

      await game.touchPresence();

      expect(
        storage.loads,
        1,
        reason:
            '⚠️ the mutant this kills: a reload whose refused follow-up '
            'save reloads again, forever',
      );
      expect(
        storage.saves,
        2,
        reason: 'the refused save, then the repair\'s one follow-up',
      );
      expect(notices, [
        '${GameState.conflictNotice} ${GameState.repairNotice(1)}',
      ], reason: 'exactly one banner, naming both facts');
      expect(
        game.profile.gold,
        999,
        reason: 'the cloud\'s world replaced the stale one in memory',
      );
      expect(
        game.profile.storerooms['hearthwood']!.instanceIds,
        isEmpty,
        reason: 'the reloaded profile was repaired before anyone saw it',
      );
    });

    test('the in-flight mutation is dropped, and the banner is the plain '
        'conflict line', () async {
      final storage = _AlwaysConflicting(() => _mage()..gold = 7);
      final game = GameState(storage, _mage());

      await game.setName('Renamed');

      expect(
        game.profile.name,
        'Christian',
        reason:
            'the rename was made against a stale world; the reload is the '
            'truth',
      );
      expect(game.notice.value, GameState.conflictNotice);
      expect(
        storage.saves,
        1,
        reason: 'a clean reload has nothing to write back',
      );
    });

    test(
      'a sign-in whose load failed cannot seed over the real save',
      () async {
        server.seed(
          _mage()
            ..gold = 4242
            ..storerooms['hearthwood'] = const Storeroom(
              stacks: {'oak_log': 9},
            ),
        );
        // The first read of the character fails (a flaky network), so load
        // reports "no save here" and syncWithAuth tries to seed the guest.
        server.nextCharacterGet = http.Response('unavailable', 503);
        final game = GameState(_NullStorage(), PlayerProfile.newPlayer());

        await game.syncWithAuth(_uid);

        expect(
          server.commits.first
              .firstWhere((w) => w.path == _charPath)
              .currentDocument,
          {'exists': false},
          reason:
              'a client that has never seen the character document may only '
              'create it, never overwrite it',
        );
        expect(
          server.docs['$_roomsPath/hearthwood'],
          isNotNull,
          reason:
              '⚠️ the mutant this kills: a seed that lands its town writes — '
              'the guest\'s empty storerooms would have deleted the real ones',
        );
        expect(
          game.profile.gold,
          4242,
          reason: 'the refused seed reloaded the real character instead',
        );
        expect(game.notice.value, GameState.conflictNotice);
      },
    );
  });

  group('repair on sign-in', () {
    test('a sign-in that adopts a damaged cloud save repairs it and writes '
        'the repair back', () async {
      // Christian's save as read on 2026-09-25: the storeroom names an id the
      // character document's pool does not hold.
      final damaged = _mage();
      damaged.storerooms['hearthwood'] = const Storeroom(
        stacks: {'oak_log': 3},
        instanceIds: ['chmikx1dnj4a'],
      );
      server.seed(damaged);
      final game = GameState(_NullStorage(), PlayerProfile.newPlayer());

      await game.syncWithAuth(_uid);

      expect(game.notice.value, GameState.repairNotice(1));
      expect(
        server.docs['$_roomsPath/hearthwood'],
        {
          'stacks': {'oak_log': 3},
        },
        reason:
            '⚠️ the mutant this kills: a repair made only in memory — the '
            'next device to load would find the dangling id all over again',
      );
    });
  });
}

/// A storage whose every save is refused — the worst case for a loop.
class _AlwaysConflicting implements ProfileStorage {
  final PlayerProfile Function() cloud;
  int loads = 0;
  int saves = 0;

  _AlwaysConflicting(this.cloud);

  @override
  Future<PlayerProfile?> load() async {
    loads++;
    // ⚠️ A circuit breaker, so a looping mutant fails this suite instead of
    // hanging it: the loop is pure microtasks, which starve the test timeout.
    if (loads > 5) throw StateError('reload loop');
    return cloud();
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    saves++;
    throw const SaveConflictException(_charPath);
  }

  @override
  Future<void> clear() async {}
}

class _NullStorage implements ProfileStorage {
  @override
  Future<PlayerProfile?> load() async => null;

  @override
  Future<void> save(PlayerProfile profile) async {}

  @override
  Future<void> clear() async {}
}
