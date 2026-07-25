import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/status_fx.dart';
import 'package:mom_engine/mom_engine.dart';

/// The animation table and the status catalogue have to stay in step: every
/// status the engine can apply needs its own flourish, or it silently falls
/// back to a generic pulse and looks like every other status.
void main() {
  group('status animations cover the catalogue', () {
    test('every catalogued status has its own animation', () {
      for (final info in StatusCatalog.all) {
        expect(statusFx[info.id], isNotNull,
            reason: "'${info.id}' (${info.name}) has no StatusFx entry");
      }
    });

    test('no animation entry is orphaned', () {
      for (final id in statusFx.keys) {
        expect(StatusCatalog.byId(id), isNotNull,
            reason: "statusFx has '$id' but the catalogue does not");
      }
    });

    test('an unknown id still animates, rather than throwing', () {
      expect(statusFxFor('who-knows').motion, StatusMotion.dim);
      expect(statusFxFor(null).motion, StatusMotion.dim);
    });

    test('lasting statuses are visually distinct from one another', () {
      // Two lasting statuses sharing BOTH colour and motion would be
      // indistinguishable mid-duel. Moments may share (several are the same
      // Sanctus flare by design), but conditions you carry must not.
      final seen = <String, String>{};
      for (final info in StatusCatalog.lasting) {
        final fx = statusFx[info.id]!;
        final key = '${fx.color.toARGB32()}/${fx.motion}';
        expect(seen[key], isNull,
            reason: "'${info.id}' looks identical to '${seen[key]}'");
        seen[key] = info.id;
      }
    });

    test('the guide colour resolves for every status', () {
      for (final info in StatusCatalog.all) {
        expect(statusColor(info), isNotNull, reason: info.id);
      }
    });
  });
}
