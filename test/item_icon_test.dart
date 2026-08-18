import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/inventory.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/tabs/inventory_tab.dart';
import 'package:masters_of_magic_2/ui/item_icon.dart';

/// Item icons, which — like the arena backdrop before them — are code that
/// ships **before** the art it draws.
///
/// ⚠️ **The failure this file exists to prevent is silent in both
/// directions.** `assets/items/<zone>/` is empty and declared in pubspec, so
/// every inventory screen today asks for files that are not there. If the
/// fallback ever stops being silent, the backpack grows twenty broken-image
/// boxes and no other test notices; if the request path ever drifts from
/// [itemIconFor], fifty-two PNGs land and nothing changes on screen and no
/// other test notices that either.
///
/// ⭐ **No manifest for icons** (unlike `assets/creatures/<zone>/`). The
/// creature manifest earns its keep because eleven hand-written creature ids
/// per zone are a roster worth checking against the art; here `ItemCatalogue`
/// already IS the roster and `ItemCatalogue.zoneOf` already IS the index, so a
/// manifest could only restate them. What is checked instead is the reverse,
/// in [_iconsOnDiskAreNamedForItems]: nothing on disk is named for an item or
/// a zone that does not exist.
void main() {
  /// A one-pixel PNG, so the fake bundle can answer with something a real
  /// decoder accepts. ⚠️ Returning junk bytes would take the same errorBuilder
  /// path as a missing file, and the "it was requested" tests below would pass
  /// while proving nothing about a file that is actually there.
  final onePixelPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  /// The inventory screen with one Oak Log in the pack and one Sapwort Draught
  /// on the belt. ⚠️ The surface is tall on purpose — a `ListView` only builds
  /// what fits, and the default 800×600 leaves the Storeroom below the fold
  /// where it never renders at all (see `loop_ui_test.dart`).
  Future<GameState> pump(
    WidgetTester tester, {
    AssetBundle? bundle,
    bool firstFrameOnly = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = GameState(_Mem(), PlayerProfile.newPlayer());
    game.profile.backpack = game.profile.backpack.withAdded(
      const InventorySlot(defId: 'oak_log'),
    )!;
    game.profile.storerooms['hearthwood'] = const Storeroom(
      stacks: {'bindweed_fibre': 3},
    );
    const tab = Scaffold(body: InventoryTab());
    await tester.pumpWidget(
      MaterialApp(
        home: GameStateScope(
          state: game,
          child: bundle == null
              ? tab
              : DefaultAssetBundle(bundle: bundle, child: tab),
        ),
      ),
    );
    if (!firstFrameOnly) await tester.pump();
    return game;
  }

  group('an icon that is not there', () {
    testWidgets('the inventory renders, and nothing is thrown', (tester) async {
      // ⭐ The real bundle, deliberately: assets/items/ is empty today, so
      // this is the state the game actually ships in and no fake is needed to
      // reach it. It stays a true statement once the art lands.
      await pump(tester);

      expect(
        tester.takeException(),
        isNull,
        reason: 'drop the errorBuilder from ItemIcon and every inventory '
            'screen in the game reports "Unable to load asset"',
      );
    });

    testWidgets("the fallback is exactly today's text, unmoved", (
      tester,
    ) async {
      await pump(tester, bundle: _MissingBundle());

      expect(
        find.text('Oak Log'),
        findsWidgets,
        reason: 'the backpack tile falls back to the wrapped name it drew '
            'before ItemIcon existed — swap the fallback for a placeholder '
            'glyph and every pack slot in the game goes blank until art lands',
      );
      expect(
        find.text('Bindweed Fibre'),
        findsOneWidget,
        reason: 'the Storeroom row keeps its label; the icon there sits '
            'BESIDE the text, so a missing PNG must remove nothing',
      );
      expect(
        find.byType(ItemIcon),
        findsWidgets,
        reason: 'a missing PNG must not take the widget out of the tree — '
            'guard the call sites with a file-exists check and the pipeline '
            'is dead the day the art lands, with nothing failing to say so',
      );
    });

    testWidgets('⚠️ the fallback is there on the very first frame', (
      tester,
    ) async {
      await pump(tester, bundle: _MissingBundle(), firstFrameOnly: true);

      // ⭐ An asset load is asynchronous **even when it is going to fail**, so
      // an `errorBuilder` on its own is not enough: the widget draws an empty
      // box until the failure comes back. ⚠️ Delete `frameBuilder` from
      // ItemIcon and every inventory screen in the game flashes blank tiles
      // on open, for art that does not exist — four tests in loop_ui_test
      // caught exactly that, which is why this one is here to say why.
      expect(
        find.text('Oak Log'),
        findsWidgets,
        reason: 'the pack tile must never show a hole where the name was; '
            'frame zero is the frame the player actually sees when the tab '
            'opens',
      );
    });

    testWidgets('an absent icon reserves no space at all', (tester) async {
      await pump(tester, bundle: _MissingBundle());

      // ⭐ The whole no-op claim, measured rather than eyeballed. Every icon
      // added to a row that had none carries a [ItemIcon.gap], and the gap is
      // drawn as extra WIDTH ON THE IMAGE precisely so the errorBuilder takes
      // it away too. ⚠️ Implement the gap as a `Padding` around the image (or
      // as a `SizedBox` sibling at the call site) and this widget still
      // measures 8px wide with nothing in it — every Storeroom row, loot row,
      // duel chip and dialog title shifts right for art that does not exist.
      final gapped = tester
          .widgetList<ItemIcon>(find.byType(ItemIcon))
          .where((i) => i.gap > 0);
      expect(
        gapped,
        isNotEmpty,
        reason: 'no gapped icon on screen means this test is measuring '
            'nothing — the Storeroom row and the pack tile both mount one',
      );
      for (final icon in gapped) {
        expect(
          tester.getSize(find.byWidget(icon)).width,
          0,
          reason: '${icon.defId}: with no PNG this must be exactly zero wide, '
              'gap included — anything else is a layout shift the designer '
              'never approved, for art that is not there',
        );
      }
    });
  });

  group('an icon that is there', () {
    testWidgets("the item's own path is what gets asked for", (tester) async {
      final bundle = _RecordingBundle(onePixelPng);
      await pump(tester, bundle: bundle);

      expect(
        bundle.requested,
        contains('assets/items/whispering_woods/oak_log.png'),
        reason: 'the maintainer generates files named for item ids under a '
            'zone folder — point itemIconFor at any other name (the display '
            'name, a flat directory, the instance id) and the PNGs ship '
            'without ever being read',
      );
      expect(
        bundle.requested,
        contains('assets/items/whispering_woods/bindweed_fibre.png'),
        reason: 'the Storeroom asks by DEF id; ask by the stack key it '
            'happens to hold and non-fungibles would ask for a UUID',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'an icon that IS present must decode quietly too — the '
            'errorBuilder is a fallback, not the normal path',
      );
    });

    testWidgets('the gap appears only once the art does', (tester) async {
      final bundle = _RecordingBundle(onePixelPng);
      // ⚠️ **`runAsync`, not `pumpAndSettle`.** Decoding a PNG is real
      // asynchronous work on a real thread; the fake-async clock a widget
      // test normally runs on cannot drive it, so the image never arrives and
      // this test would measure the loading frame forever.
      await tester.runAsync(() async {
        await pump(tester, bundle: bundle);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final gapped = tester
          .widgetList<ItemIcon>(find.byType(ItemIcon))
          .where((i) => i.gap > 0);
      for (final icon in gapped) {
        expect(
          tester.getSize(find.byWidget(icon)).width,
          icon.size! + icon.gap,
          reason: '${icon.defId}: a present icon must claim its box AND its '
              'gap — drop the "+ gap" from the width and the icon lands '
              'jammed against the label it belongs to',
        );
      }
    });

    testWidgets('nothing is requested from outside its own zone', (
      tester,
    ) async {
      final bundle = _RecordingBundle(onePixelPng);
      await pump(tester, bundle: bundle);

      final wrongZone = bundle.requested
          .where((k) => k.startsWith('assets/items/'))
          .where((k) => !k.startsWith('assets/items/whispering_woods/'))
          .toSet();
      expect(
        wrongZone,
        isEmpty,
        reason: 'only Whispering Woods items are on this screen, so a request '
            'under another zone means zoneOf is guessing — and the maintainer '
            'would have to produce files in directories nobody documented',
      );
    });
  });

  group('the naming convention', () {
    test('every Primal zone folders its own items', () {
      // ⚠️ These five strings are the deliverable. They are written out flat
      // rather than derived, because a test that builds the expectation with
      // the same expression as the code under test proves only that the
      // expression is deterministic.
      expect(
        itemIconFor('oak_log'),
        'assets/items/whispering_woods/oak_log.png',
      );
      expect(
        itemIconFor('sapwort_draught'),
        'assets/items/glimmerbrook/sapwort_draught.png',
      );
      expect(
        itemIconFor('cinder_loop'),
        'assets/items/cinderpeak_foothills/cinder_loop.png',
      );
      expect(
        itemIconFor('wickerbound_ring'),
        'assets/items/thornmire/wickerbound_ring.png',
      );
      expect(
        itemIconFor('the_charlock'),
        'assets/items/ashfall_vale/the_charlock.png',
      );
    });

    test('⚠️ an id no catalogue claims has no path to ask for', () {
      expect(
        itemIconFor('sunken_widget_of_nowhere'),
        isNull,
        reason: 'a save written before a content patch must not send the '
            'bundle looking for assets/items/null/<id>.png on every rebuild',
      );
    });

    test('every item in the catalogue knows which zone defines it', () {
      // ⭐ The claim that makes the whole convention safe: an item resolvable
      // by id but owned by no zone is an icon that can never load, and the
      // only symptom is a picture that never appears.
      for (final def in ItemCatalogue.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          isNotNull,
          reason: '${def.id} is in ItemCatalogue.all but in no zone list — '
              'add its catalogue to ItemCatalogue.byZone',
        );
      }
      expect(
        ItemCatalogue.all.length,
        52,
        reason: 'the Primal quarter is 18/9/8/9/8; if this number moved, '
            'docs/ITEM_ART.md is now short an entry (or carries a stale one) '
            'and nothing else in the suite would say so',
      );
    });

    test('⚠️ every byZone key is a real place', () {
      final zones = World.locations.map((l) => l.id).toSet();
      for (final key in ItemCatalogue.byZone.keys) {
        expect(
          zones,
          contains(key),
          reason: '"$key" is not a World location id, so pubspec would be '
              'declaring a directory for a place that does not exist',
        );
      }
    });
  });

  test(_iconsOnDiskAreNamedForItems, () {
    // ⭐ The check a manifest.json would otherwise be carrying, and it passes
    // on today's empty directories — which is the point: it is armed for the
    // day the art lands, not written afterwards.
    final root = Directory('assets/items');
    if (!root.existsSync()) {
      fail(
        'assets/items/ is missing — pubspec declares it, so the build is '
        'already broken; the .gitkeep files are what keep it in the repo',
      );
    }
    for (final zoneDir in root.listSync().whereType<Directory>()) {
      final zone = zoneDir.uri.pathSegments[zoneDir.uri.pathSegments.length - 2];
      expect(
        ItemCatalogue.byZone.keys,
        contains(zone),
        reason: 'assets/items/$zone/ is a folder for nowhere — itemIconFor '
            'can only ever ask under a zone in byZone, so nothing in it will '
            'ever load',
      );
      final stems = zoneDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.png'))
          .map((n) => n.substring(0, n.length - 4));
      for (final stem in stems) {
        expect(
          ItemCatalogue.tryById(stem),
          isNotNull,
          reason: '$zone/$stem.png is an icon for nothing — itemIconFor can '
              'only ever ask for a def id, so nothing will ever load it',
        );
        expect(
          ItemCatalogue.zoneOf(stem),
          zone,
          reason: '$stem.png is filed under $zone but the catalogue defines '
              'it in ${ItemCatalogue.zoneOf(stem)} — the game will look in '
              'the other folder and find nothing',
        );
      }
    }
  });
}

/// Named so the empty-directory case reads as a fact rather than a skip.
const _iconsOnDiskAreNamedForItems =
    '⚠️ every PNG in assets/items/ is a real item, in its own zone';

/// The bundle the game would have if the icons had already been generated: one
/// valid pixel at every `assets/items/` key, everything else exactly as it
/// really is. Remembers what it was asked for.
///
/// ⚠️ **Only the items are faked.** `AssetImage` resolves through
/// `AssetManifest.bin` before it ever asks for the image, so a bundle that
/// answers *every* key with a PNG hands the manifest parser a PNG and the load
/// fails inside `obtainKey` — which looks exactly like a missing file and
/// would have made the assertions above unfalsifiable.
class _RecordingBundle extends CachingAssetBundle {
  final Uint8List _png;
  final List<String> requested = [];

  _RecordingBundle(this._png);

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key.startsWith('assets/items/')) {
      return ByteData.view(_png.buffer, _png.offsetInBytes, _png.lengthInBytes);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);
}

/// The bundle the game has **today** — nothing under `assets/items/`,
/// everything else exactly as it really is.
///
/// ⭐ **Faked rather than relied on**, unlike the arena backdrop's equivalent.
/// The empty-directory state is the one thing about this pipeline guaranteed
/// to stop being true: the first `--mode icon` run puts real PNGs on disk, and
/// a "the fallback still shows" test that read the real bundle would start
/// failing the day the deliverable succeeded. ⚠️ Only `assets/items/` is
/// faked, for the `AssetManifest.bin` reason spelled out on [_RecordingBundle].
class _MissingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/items/')) {
      throw FlutterError('Unable to load asset: $key');
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);
}

/// Storage that keeps nothing on disk — the profile under test is built in
/// memory, as in `loop_ui_test.dart`.
class _Mem implements ProfileStorage {
  PlayerProfile? stored;

  @override
  Future<PlayerProfile?> load() async => stored;

  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;

  @override
  Future<void> clear() async => stored = null;
}
