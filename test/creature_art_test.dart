/// The creature-art pipeline, checked end to end **while four fifths of the
/// art does not exist yet**.
///
/// ⚠️ **Everything here fails silently in production.** A creature with no PNG
/// falls back to a silhouette, which is exactly what a creature whose PNG was
/// dropped in the wrong zone, or named for the display name instead of the id,
/// or written to a directory nobody declared in pubspec also looks like. The
/// art lands, the screen does not change, and no other test in the suite says
/// a word. So the checks below are all about the *gap between a file on disk
/// and a pixel on screen*: the path is asked for, the directory is declared,
/// the stem is a real id of that zone, and the description that produced the
/// image exists in the first place.
///
/// ⭐ **The counterpart of `test/arena_backdrop_test.dart`**, and it inherits
/// that file's hard-won trap: the fake bundle fakes ONLY `assets/creatures/`
/// keys, because `AssetImage` resolves `AssetManifest.bin` before it asks for
/// the image and a bundle that answers *every* key with a PNG breaks
/// `obtainKey` — which looks exactly like a missing file and would make the
/// was-requested assertion unfalsifiable.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/creature_sprite.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/ui/creature_art.dart';
import 'package:mom_engine/mom_engine.dart';

/// The five Primal zones, in level order.
///
/// ⚠️ Written out rather than derived from `Bestiary.all`, so that a zone
/// whose bestiary is deleted or renamed fails here instead of quietly
/// shrinking every "for every zone" loop below to four.
const _primalZones = <String>[
  'whispering_woods',
  'glimmerbrook',
  'cinderpeak_foothills',
  'thornmire',
  'ashfall_vale',
];

/// The one zone whose art has actually shipped.
const _zoneWithArt = 'whispering_woods';

/// ⚠️ **Not a creature.** `assets/creatures/<zone>/manifest.json` is written by
/// `tool/pixelate.py` alongside the sprites; `.gitkeep` is what keeps an
/// as-yet-empty zone directory alive through a clone. Both live in the same
/// directory as the PNGs and neither has a creature id for a stem, so the
/// filesystem check below has to exempt them **by name** — a blanket
/// "only look at .png" filter would also excuse a stray `.jpeg` sprite that
/// `Image.asset` will never find.
const _notCreatureFiles = <String>{'manifest.json', '.gitkeep'};

void main() {
  /// A one-pixel PNG, so the fake bundle can answer with something a real
  /// decoder accepts. ⚠️ Junk bytes would take the same errorBuilder path as a
  /// missing file, and the "it was requested" tests would pass while proving
  /// nothing about a file that is actually there.
  final onePixelPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Widget solo(EnemyDef def, {AssetBundle? bundle}) {
    final view = Center(child: CreatureView(def: def, height: 160));
    return MaterialApp(
      home: bundle == null
          ? view
          : DefaultAssetBundle(bundle: bundle, child: view),
    );
  }

  /// The silhouette `_PixelFallback` draws for a creature with no grid: a
  /// rounded box painted in the creature's own element colour.
  ///
  /// ⭐ Matched **on the colour**, not merely on "some DecoratedBox exists".
  /// The fallback's whole job is to say which element you are fighting, and a
  /// finder that ignored the paint would pass just as happily on a hardcoded
  /// Flora green behind every creature in the game.
  Finder silhouetteOf(EnemyDef def) {
    final element = def.elements.isEmpty ? MagicElement.flora : def.elements.first;
    final body = SpritePalette.forElement(element).body;
    return find.descendant(
      of: find.byType(CreatureView),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == body,
      ),
    );
  }

  group('the filename contract', () {
    test('a creature\'s asset is its zone directory and its own id', () {
      // ⚠️ Five strings written out flat, one per zone, rather than built with
      // the same interpolation as `creatureAssetFor`. A test that derives the
      // expectation the way the code does proves only that string
      // interpolation is deterministic; these are the paths the maintainer
      // actually types when saving a file.
      expect(
        creatureAssetFor(Bestiary.byId('listening_fawn')!),
        'assets/creatures/whispering_woods/listening_fawn.png',
      );
      expect(
        creatureAssetFor(Bestiary.byId('brook_naiad')!),
        'assets/creatures/glimmerbrook/brook_naiad.png',
      );
      expect(
        creatureAssetFor(Bestiary.byId('ashjaw_brute')!),
        'assets/creatures/cinderpeak_foothills/ashjaw_brute.png',
      );
      expect(
        creatureAssetFor(Bestiary.byId('the_green_drowning')!),
        'assets/creatures/thornmire/the_green_drowning.png',
      );
      expect(
        creatureAssetFor(Bestiary.byId('the_blackened_crown')!),
        'assets/creatures/ashfall_vale/the_blackened_crown.png',
      );
    });

    test('every Primal zone owns exactly eleven creatures', () {
      for (final zone in _primalZones) {
        expect(
          Bestiary.forZone(zone).length,
          11,
          reason: '$zone must be 11 (5 common, 4 mini, 2 boss) — the art '
              'contract is a fixed list of eleven filenames per zone, so a '
              'roster that grew or shrank silently leaves art missing or '
              'orphaned with nothing else to notice',
        );
      }
      expect(
        Bestiary.all.length,
        55,
        reason: 'the whole Primal quarter is 5 x 11; a sixth zone landing in '
            'Bestiary.all needs its own pubspec directory and description '
            'section before its art can load',
      );
    });

    test('no two creatures anywhere want the same file', () {
      // ⚠️ Ids only have to be unique *within* a zone for the asset path to be
      // unique — but they are unique globally today and `Bestiary.byId` walks
      // the whole list, so a duplicate would silently reroute encounters as
      // well as art.
      final paths = Bestiary.all.map(creatureAssetFor).toList();
      expect(
        paths.toSet().length,
        paths.length,
        reason: 'two creatures sharing an asset path means one of them can '
            'never have its own art — and Bestiary.byId would only ever '
            'return the first of the pair',
      );
    });

    test(_everyPngIsARealCreatureOfItsZone, () {
      // ⭐ The check that makes an empty directory safe to ship. It passes
      // today for four zones because they contain nothing, and it starts doing
      // real work the moment the maintainer drops a file in — catching the two
      // mistakes the convention still allows: a typo'd stem, and a PNG dropped
      // into the wrong zone (which is invisible, because both zones' creatures
      // just keep drawing silhouettes).
      var pngsSeen = 0;
      for (final zone in _primalZones) {
        final dir = Directory('assets/creatures/$zone');
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'assets/creatures/$zone/ is declared in pubspec.yaml and a '
              'declared directory must exist — delete it (or lose it to a '
              'clone, because git does not track empty directories) and '
              '`flutter build` stops with "unable to find directory entry"',
        );

        final ids = Bestiary.forZone(zone).map((e) => e.id).toSet();
        for (final file in dir.listSync().whereType<File>()) {
          final name = file.uri.pathSegments.last;
          if (_notCreatureFiles.contains(name)) continue;

          expect(
            name.endsWith('.png'),
            isTrue,
            reason: '$zone/$name is neither a PNG nor a known non-sprite file '
                '— creatureAssetFor only ever asks for <id>.png, so a .jpg or '
                '.webp here is weight in the bundle that nothing can load',
          );
          final stem = name.substring(0, name.length - 4);
          expect(
            ids,
            contains(stem),
            reason: '$zone/$name is art for nobody in $zone. Either the stem '
                'is a typo of a creature id, or the sprite belongs to another '
                'zone — and both failures look identical in game, because the '
                'creature it was meant for simply keeps its silhouette',
          );
          pngsSeen++;
        }
      }
      expect(
        pngsSeen,
        greaterThanOrEqualTo(11),
        reason: 'whispering_woods has shipped 11 sprites — if this loop stops '
            'seeing them the check above has become vacuous and would pass on '
            'a directory full of garbage',
      );
    });

    test('the generator writes where the game reads', () {
      // ⚠️ **The two ends of the pipeline are written in different languages
      // and nothing else makes them agree.** `tool/pixelate.py` decides where
      // a sprite lands; `creatureAssetFor` decides where one is looked for.
      // Change either and the art is generated perfectly into a directory the
      // game never asks about.
      //
      // 📝 Deliberately a spot-check on two literals rather than a parse of
      // the Python. It is brittle to a refactor of the tool — on purpose:
      // whoever refactors it should have to look at this line.
      final tool = File('tool/pixelate.py').readAsStringSync();
      expect(
        tool,
        contains('OUT_DIR = ROOT / "assets" / "creatures"'),
        reason: 'creature mode must write under assets/creatures/ — the same '
            'prefix creatureAssetFor asks for',
      );
      expect(
        tool,
        contains('out_dir = OUT_DIR / args.zone'),
        reason: 'and it must sub-divide by zone id, because the game asks for '
            'assets/creatures/<zone>/<id>.png — a flat output directory would '
            'produce eleven files per zone that nothing can load',
      );
      expect(
        creatureAssetFor(Bestiary.byId('brook_naiad')!),
        startsWith('assets/creatures/glimmerbrook/'),
        reason: 'the Dart half of the same claim, so this test fails if '
            'either end moves rather than only if the Python does',
      );
    });

    test(_everyZoneDirectoryIsDeclaredInPubspec, () {
      // ⚠️ **The plumbing failure with no symptom.** Flutter's asset globs are
      // not recursive: art can sit in `assets/creatures/<zone>/`, be committed,
      // be correctly named, and still never reach the bundle because nobody
      // added the line. In game that is indistinguishable from having no art.
      final declared = File('pubspec.yaml')
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.startsWith('- assets/creatures/'))
          .map((l) => l.substring('- assets/creatures/'.length))
          .map((l) => l.endsWith('/') ? l.substring(0, l.length - 1) : l)
          .toSet();

      expect(
        declared,
        _primalZones.toSet(),
        reason: 'every Primal zone directory must be declared before its art '
            'exists, and nothing else may be: an undeclared zone ships its '
            'PNGs nowhere, and a declared-but-absent one fails the build',
      );

      final onDisk = Directory('assets/creatures')
          .listSync()
          .whereType<Directory>()
          .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toSet();
      expect(
        onDisk,
        declared,
        reason: 'a directory under assets/creatures/ with no pubspec line is '
            'art that will never load; a pubspec line with no directory is a '
            'build that will never run',
      );
    });
  });

  group('a creature with no art at all', () {
    testWidgets('every creature renders quietly, whatever is on disk', (
      tester,
    ) async {
      // ⭐ Every creature, not a sample, and against **both** bundles: the real
      // `assets/` tree as it stands today (four zones empty), and a bundle
      // where nothing loads at all. ⚠️ Asserting against the real tree alone
      // would make this test quietly change meaning every time the maintainer
      // adds a PNG — which is the whole class of failure this file exists to
      // stop.
      for (final missing in [false, true]) {
        for (final def in Bestiary.all) {
          await tester.pumpWidget(
            solo(def, bundle: missing ? _MissingArtBundle() : null),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'drop the errorBuilder from CreatureView and ${def.id} '
                'reports "Unable to load asset" — with four zones empty that '
                'is most of the bestiary throwing on sight',
          );
          expect(
            find.byType(CreatureView),
            findsOneWidget,
            reason: '${def.id} must still be in the tree; without this the '
                'no-exception check would also pass on a build that collapsed',
          );
        }
      }
    });

    testWidgets('the silhouette is painted in its own element', (tester) async {
      // ⚠️ **Driven through a bundle with no creature art in it**, not through
      // whatever happens to be on disk. Written the other way this test read
      // "the four zones are empty today" — true now, false the morning the
      // PNGs land, and it would have failed the maintainer for succeeding.
      // What is actually being asserted is the last link of the fallback
      // chain: no PNG, no grid, therefore an elemental silhouette.
      //
      // ⚠️ Whispering Woods is excluded because its eleven creatures have
      // hand-placed pixel grids and take the OTHER branch — they are covered
      // by the test below.
      final noGrid = Bestiary.all
          .where((d) => d.zoneId != _zoneWithArt)
          .toList();
      expect(
        noGrid.length,
        44,
        reason: 'four zones x 11 have no pixel grid — if this number moves, '
            'either a roster changed or a zone grew grids, and the loop below '
            'is no longer testing what it says it is',
      );

      for (final def in noGrid) {
        await tester.pumpWidget(solo(def, bundle: _MissingArtBundle()));
        await tester.pump();

        expect(
          silhouetteOf(def),
          findsOneWidget,
          reason: '${def.id} has no PNG and no pixel grid, so it must fall all '
              'the way through to a silhouette in its own element colour — '
              'point the fallback at one fixed palette and every creature in '
              'four zones becomes the same coloured lump',
        );
        expect(
          find.byType(CreatureSprite),
          findsNothing,
          reason: '${def.id} has no entry in WhisperingWoodsArt, so borrowing '
              'a grid would mean drawing another zone\'s creature — the exact '
              'mistake the mage sprite was making before this widget existed',
        );
      }
    });

    testWidgets('a creature WITH a pixel grid still gets it', (tester) async {
      // ⭐ The other half of the fallback chain. Without this, deleting the
      // grid lookup entirely would leave every test above passing.
      //
      // ⚠️ **The art has to be taken away on purpose.** `flutter test` serves
      // the real `assets/` tree, so the Listening Fawn's shipped PNG loads
      // here exactly as it does in game and the grid never gets a turn — this
      // test read as a failure until the bundle below started refusing
      // creature keys. 📝 Worth knowing for its own sake: with Whispering
      // Woods' eleven sprites on disk, **no pixel grid is reachable in the
      // shipped game today**; the grids only serve zones whose art has not
      // arrived, and they have none.
      final fawn = Bestiary.byId('listening_fawn')!;
      await tester.pumpWidget(solo(fawn, bundle: _MissingArtBundle()));
      await tester.pump();

      expect(
        find.byType(CreatureSprite),
        findsOneWidget,
        reason: 'the Listening Fawn has a hand-placed grid and no loadable '
            'PNG in the test bundle — it must reach the grid, not the plain '
            'silhouette that the other 44 creatures get',
      );
      expect(
        silhouetteOf(fawn),
        findsNothing,
        reason: 'a creature that has a grid must not ALSO draw the '
            'unfinished-looking box behind it',
      );
    });
  });

  group('a creature whose art has landed', () {
    testWidgets('the zone-correct path is what gets asked for', (tester) async {
      // ⚠️ **The whole point of the exercise.** Four directories are empty, so
      // nothing on screen can tell you whether the request path is right until
      // the PNGs exist — at which point a wrong path means the art ships and
      // the game looks identical.
      for (final id in const [
        'listening_fawn',
        'brook_naiad',
        'ashjaw_brute',
        'the_green_drowning',
        'the_blackened_crown',
      ]) {
        final def = Bestiary.byId(id)!;
        final bundle = _RecordingBundle(onePixelPng);
        await tester.pumpWidget(solo(def, bundle: bundle));
        await tester.pump();

        expect(
          bundle.requested,
          contains('assets/creatures/${def.zoneId}/$id.png'),
          reason: 'the maintainer generates <zone>/<id>.png — point '
              'creatureAssetFor at any other name (the display name, a flat '
              'directory, a manifest key) and every PNG in the quarter ships '
              'without ever being read',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'a sprite that IS present must decode quietly — the '
              'errorBuilder is the fallback, not the normal path',
        );
      }
    });

    testWidgets('exactly one file is asked for per creature', (tester) async {
      final def = Bestiary.byId('stillwater')!;
      final bundle = _RecordingBundle(onePixelPng);
      await tester.pumpWidget(solo(def, bundle: bundle));
      await tester.pump();

      expect(
        bundle.requested.where((k) => k.startsWith('assets/creatures/')),
        {'assets/creatures/glimmerbrook/stillwater.png'},
        reason: 'one sprite per creature: a second request would mean the '
            'view is guessing at extensions, resolutions or a manifest, and '
            'the maintainer would have to produce files nobody documented',
      );
    });

    testWidgets('the PNG wins over the pixel grid', (tester) async {
      // ⭐ The fallback chain has to be an ORDER, not a set. The Listening Fawn
      // is the only creature that can prove it: it is the one with both.
      final fawn = Bestiary.byId('listening_fawn')!;
      final bundle = _RecordingBundle(onePixelPng);
      await tester.pumpWidget(solo(fawn, bundle: bundle));
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(CreatureSprite),
        findsNothing,
        reason: 'once a PNG loads it must replace the pixel grid — if the grid '
            'still wins, the generated art for all 55 creatures is dead weight '
            'in the bundle and the maintainer would never see it',
      );
    });
  });

  group('the descriptions the art is generated from', () {
    // ⭐ **Parsed, not pinned.** A const list of 44 names would pass forever
    // without anyone opening the document, which is the opposite of the point:
    // the failure being guarded against is a creature reaching the roster with
    // nothing to hand a generator. The doc turns out to be safely parseable —
    // every entry is a line of the exact shape `**Name** — *rank · role ·
    // element*`, an anchor nothing else in the file uses (headings start `#`,
    // descriptions are blockquotes, backdrops are named by their file path).
    //
    // ⚠️ The parse is checked **in both directions** below. A regex that
    // silently stopped matching would otherwise make the coverage test pass by
    // finding nothing and comparing nothing.
    final doc = File('docs/BESTIARY_ART.md').readAsStringSync();
    final described = RegExp(r'^\*\*([^*]+)\*\* — \*', multiLine: true)
        .allMatches(doc)
        .map((m) => m.group(1)!)
        .toList();

    test('the parser still finds the entries it is anchored on', () {
      expect(
        described.length,
        55,
        reason: 'the entry format changed (or the file moved) and the coverage '
            'check below has quietly become a comparison of two empty sets — '
            'entries are `**Name** — *rank · archetype · element*`',
      );
      expect(
        described.toSet().length,
        described.length,
        reason: 'a duplicated heading means one creature has two descriptions '
            'and — since the counts match — another has none',
      );
    });

    test('every creature in the Primal quarter is described', () {
      final roster = Bestiary.all.map((e) => e.name).toSet();
      expect(
        described.toSet(),
        roster,
        reason: 'docs/BESTIARY_ART.md is the ONLY input to the art pipeline: a '
            'creature with no entry can never be generated, and an entry with '
            'no creature is a description of something that was renamed or '
            'cut. Names must match the EnemyDef `name` exactly, because that '
            'is the only thing tying a paragraph of prose to an id',
      );
    });

    test('every zone still ends with its arena backdrop brief', () {
      // 📝 Backdrops are the sibling pipeline (`test/arena_backdrop_test.dart`
      // checks the code path); this only checks the description exists, since
      // both quarters of the work are generated from this one file.
      for (final zone in _primalZones) {
        expect(
          doc,
          contains('`assets/backgrounds/$zone.png`'),
          reason: 'the $zone backdrop brief names its own output file — lose '
              'it and the maintainer has no prompt to generate from',
        );
      }
    });
  });
}

/// Named so the four empty directories read as a fact rather than a skip.
const _everyPngIsARealCreatureOfItsZone =
    '⚠️ every PNG under assets/creatures/ is a creature of the zone it sits in';

const _everyZoneDirectoryIsDeclaredInPubspec =
    '⚠️ every zone directory is declared in pubspec, and every declared one exists';

/// The bundle a zone with no art has: every `assets/creatures/` key missing,
/// everything else real.
///
/// ⚠️ Needed because `flutter test` reads the **actual** `assets/` directory —
/// so Whispering Woods' eleven shipped PNGs load in tests, and the only way to
/// exercise the pixel-grid branch of the fallback is to refuse them here. The
/// error mirrors what a real missing asset raises, so `Image.asset` takes its
/// normal errorBuilder path rather than a synthetic one.
class _MissingArtBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/creatures/')) {
      throw FlutterError('Unable to load asset: $key');
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);
}

/// The bundle the game would have if the sprites had already been generated:
/// one valid pixel at every `assets/creatures/` key, everything else exactly as
/// it really is. Remembers what it was asked for.
///
/// ⚠️ **Only the creatures are faked.** `AssetImage` resolves through
/// `AssetManifest.bin` before it ever asks for the image, so a bundle that
/// answers *every* key with a PNG hands the manifest parser a PNG and the load
/// fails inside `obtainKey` — which looks exactly like a missing file and would
/// make the was-requested assertions unfalsifiable. This trap cost the arena
/// work real time; it is repeated here rather than shared because the two
/// files fake different prefixes and a shared helper would hide which.
class _RecordingBundle extends CachingAssetBundle {
  final Uint8List _png;
  final List<String> requested = [];

  _RecordingBundle(this._png);

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key.startsWith('assets/creatures/')) {
      return ByteData.view(_png.buffer, _png.offsetInBytes, _png.lengthInBytes);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);
}
