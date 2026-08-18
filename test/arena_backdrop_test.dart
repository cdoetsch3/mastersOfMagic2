import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:masters_of_magic_2/ui/creature_art.dart';

/// The arena backdrop, which is the one asset that ships **after** the code
/// that draws it.
///
/// ⚠️ **The failure this file exists to prevent is silent in both directions.**
/// `assets/backgrounds/` is empty and declared in pubspec, so every duel today
/// asks for a file that is not there. If the fallback ever stops being silent,
/// every fight in the game grows a broken-image box and no other test notices;
/// if the request path ever drifts from `backdropFor`, the PNGs land and
/// nothing changes on screen and no other test notices that either.
///
/// ⭐ **No manifest for backgrounds** (unlike `assets/creatures/<zone>/`). One
/// file per zone named for the zone id means the *filename is the index* —
/// there is nothing a manifest could say that `backdropFor(zoneId)` does not
/// already say. What the creature manifest buys is a roster-to-art check over
/// eleven files with hand-written ids; the equivalent here is
/// [_backdropsOnDiskAreNamedForZones], which catches the only mistake the flat
/// convention allows: a file named for a place that does not exist.
void main() {
  /// A one-pixel PNG, so the fake bundle can answer with something a real
  /// decoder accepts. ⚠️ Returning junk bytes would take the same errorBuilder
  /// path as a missing file and the "it was requested" test would pass while
  /// proving nothing about a file that is actually there.
  final onePixelPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Widget arena({AssetBundle? bundle}) {
    // ⭐ A real bestiary opponent, not a bare persona: the duel screen only
    // draws a backdrop when the driver carries an `EnemyDef`, because that is
    // the only thing that knows which zone the fight is in.
    final fawn = Bestiary.byId('listening_fawn')!;
    expect(fawn.zoneId, 'whispering_woods');
    final screen = DuelScreen(
      loadout: Loadout.starter,
      driver: LocalAiDriver(
        persona: AiRoster.all.first,
        enemy: fawn,
        rng: Random(1),
      ),
      playerLevel: 3,
    );
    return MaterialApp(
      home: bundle == null
          ? screen
          : DefaultAssetBundle(bundle: bundle, child: screen),
    );
  }

  void landscape(WidgetTester tester) {
    // The arena refuses to draw in portrait — it shows a rotate prompt, and a
    // test that forgot this would assert against a screen with no Stack in it.
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('a backdrop that is not there yet', () {
    testWidgets('the arena renders, and nothing is thrown', (tester) async {
      landscape(tester);
      await tester.pumpWidget(arena());
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'drop the errorBuilder from ArenaBackdrop and every duel in '
            'the game reports "Unable to load asset" — assets/backgrounds/ is '
            'empty today, so this is the state the game actually ships in',
      );
      expect(
        find.byType(ArenaBackdrop),
        findsOneWidget,
        reason: 'the missing PNG must not take the backdrop widget out of the '
            'tree — remove it from the Stack and the pipeline is dead the day '
            'the art lands, with nothing failing to say so',
      );
      expect(
        find.text('LV 3'),
        findsOneWidget,
        reason: 'the rest of the arena must still be there; without this the '
            'no-exception check above would also pass on a screen that failed '
            'to build at all',
      );
    });

    testWidgets('the backdrop is the bottom of the stack', (tester) async {
      landscape(tester);
      await tester.pumpWidget(arena());
      await tester.pump();

      final stack = tester.widget<Stack>(
        find
            .ancestor(
              of: find.byType(ArenaBackdrop),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(
        stack.children.first,
        isA<ArenaBackdrop>(),
        reason: 'move it up one place and it covers the ground ellipse; move '
            'it above the sprites and a dimmed forest is painted over the two '
            'combatants — the whole point is that it loses to everything',
      );
    });
  });

  group('a backdrop that is there', () {
    testWidgets('the zone\'s own path is what gets asked for', (tester) async {
      landscape(tester);
      final bundle = _RecordingBundle(onePixelPng);
      await tester.pumpWidget(arena(bundle: bundle));
      await tester.pump();

      expect(
        bundle.requested,
        contains('assets/backgrounds/whispering_woods.png'),
        reason: 'the maintainer generates files named for zone ids — point '
            'backdropFor at any other name (a manifest key, the zone display '
            'name, a subdirectory) and the PNGs ship without ever being read',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'a backdrop that IS present must decode quietly too — the '
            'errorBuilder is a fallback, not the normal path',
      );
    });

    testWidgets('a missing one is not requested from somewhere else', (
      tester,
    ) async {
      landscape(tester);
      final bundle = _RecordingBundle(onePixelPng);
      await tester.pumpWidget(arena(bundle: bundle));
      await tester.pump();

      expect(
        bundle.requested.where((k) => k.startsWith('assets/backgrounds/')),
        {'assets/backgrounds/whispering_woods.png'},
        reason: 'exactly one backdrop per duel: a second request would mean '
            'the arena is guessing at extensions or variants, and the '
            'maintainer would have to produce files nobody documented',
      );
    });
  });

  group('the naming convention', () {
    test('every Primal zone resolves to <zone id>.png', () {
      // ⚠️ These five strings are the deliverable. They are written out flat
      // rather than derived, because a test that builds the expectation with
      // the same expression as the code under test proves only that the
      // expression is deterministic.
      expect(backdropFor('whispering_woods'), 'assets/backgrounds/whispering_woods.png');
      expect(backdropFor('glimmerbrook'), 'assets/backgrounds/glimmerbrook.png');
      expect(
        backdropFor('cinderpeak_foothills'),
        'assets/backgrounds/cinderpeak_foothills.png',
      );
      expect(backdropFor('thornmire'), 'assets/backgrounds/thornmire.png');
      expect(backdropFor('ashfall_vale'), 'assets/backgrounds/ashfall_vale.png');
    });

    test(_backdropsOnDiskAreNamedForZones, () {
      // ⭐ The check a manifest.json would otherwise be carrying. A backdrop is
      // reached by zone id and by nothing else, so a file whose stem is not a
      // zone id is unreachable weight in the bundle — and, worse, looks like
      // finished work in a directory listing.
      final dir = Directory('assets/backgrounds');
      final stems = dir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.png'))
          .map((n) => n.substring(0, n.length - 4))
          .toSet();
      final zones = World.locations.map((l) => l.id).toSet();
      for (final stem in stems) {
        expect(
          zones,
          contains(stem),
          reason: '$stem.png is a backdrop for nowhere — backdropFor() can '
              'only ever ask for a zone id, so nothing will ever load it',
        );
      }
    });
  });
}

/// Named so the empty-directory case reads as a fact rather than a skip.
const _backdropsOnDiskAreNamedForZones =
    '⚠️ every PNG in assets/backgrounds/ is named for a real zone';

/// The bundle the game would have if the backdrops had already been generated:
/// one valid pixel at every `assets/backgrounds/` key, everything else exactly
/// as it really is. Remembers what it was asked for.
///
/// ⚠️ **Only the backgrounds are faked.** `AssetImage` resolves through
/// `AssetManifest.bin` before it ever asks for the image, so a bundle that
/// answers *every* key with a PNG hands the manifest parser a PNG and the load
/// fails inside `obtainKey` — which looks exactly like a missing file and
/// would have made the assertion below unfalsifiable.
class _RecordingBundle extends CachingAssetBundle {
  final Uint8List _png;
  final List<String> requested = [];

  _RecordingBundle(this._png);

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key.startsWith('assets/backgrounds/')) {
      return ByteData.view(_png.buffer, _png.offsetInBytes, _png.lengthInBytes);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);
}
