import 'dart:io';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The catalogue is the single source of truth for statuses — the HUD, the log,
/// the animation table and the player guide all read it. These tests are what
/// stop it drifting from what the engine actually emits.
void main() {
  group('StatusCatalog', () {
    test('ids are unique', () {
      final ids = StatusCatalog.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every entry is filled in', () {
      for (final s in StatusCatalog.all) {
        expect(s.id, isNotEmpty);
        expect(s.name, isNotEmpty, reason: s.id);
        expect(s.description.length, greaterThan(20), reason: s.id);
        expect(s.trigger, isNotEmpty, reason: s.id);
      }
    });

    test('lookup works and is total over the list', () {
      for (final s in StatusCatalog.all) {
        expect(StatusCatalog.byId(s.id), same(s));
      }
      expect(StatusCatalog.byId('nope'), isNull);
    });

    test('moments never linger, lasting statuses always do', () {
      for (final s in StatusCatalog.lasting) {
        expect(s.kind, isNot(StatusKind.moment), reason: s.id);
      }
      for (final s in StatusCatalog.moments) {
        expect(s.kind, StatusKind.moment, reason: s.id);
      }
    });

    // The check that actually keeps this honest: scrape every statusId the
    // engine passes to BuffAppliedEvent and require a catalogue entry. Add a
    // status without documenting it and this fails.
    test('every statusId the engine emits is catalogued', () {
      final src = File('lib/src/duel.dart').readAsStringSync();
      final emitted = RegExp(r"statusId:\s*'([a-zA-Z]+)'")
          .allMatches(src)
          .map((m) => m.group(1)!)
          .toSet();

      expect(emitted, isNotEmpty,
          reason: 'the scrape found nothing — bad regex?');
      for (final id in emitted) {
        expect(StatusCatalog.byId(id), isNotNull,
            reason: "duel.dart emits '$id' with no StatusCatalog entry");
      }
    });

    // And the reverse for pips: everything StatusSnapshot can report needs an
    // entry too, or the HUD would show a chip the guide can't explain.
    test('every snapshot id is catalogued as a lasting status', () {
      const snapshotIds = {
        'photosynthesis', 'arcaneKnowledge', 'creepingDark', 'astralAlignment',
        'ignite', 'blind', 'haste', 'grace', 'empower', 'quicken', 'phase',
        'waterlogged', 'stagger',
      };
      for (final id in snapshotIds) {
        final info = StatusCatalog.byId(id);
        expect(info, isNotNull, reason: "snapshot reports '$id'");
        expect(info!.lingers, isTrue,
            reason: "'$id' shows as a pip so it must be a lasting status");
      }
    });
  });
}
