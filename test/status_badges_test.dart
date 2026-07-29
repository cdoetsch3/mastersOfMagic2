import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_status_badges.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:mom_engine/mom_engine.dart';

/// The HUD pips, and specifically the Flora streak.
///
/// ⚠️ Flora used to produce NO streak pip — `_streakMechanic` covered the four
/// cadence elements but not Flora, so a Flora run was invisible until it
/// bloomed. Reported from play: "Flora count not working, not seeing the
/// status PIP showing the streak."
void main() {
  StatusSnapshot snap(MagicElement element, int count) => StatusSnapshot([
    StatusView(id: 'streak', stacks: count, element: element),
  ]);

  StatusBadge? streakBadge(StatusSnapshot s) => badgesFromSnapshot(
    s,
  ).where((b) => b.kind == BadgeKind.streak).firstOrNull;

  group('the Flora streak is visible before it blooms', () {
    test('Flora 1 through 5 each show a counted pip', () {
      for (var n = 1; n <= 5; n++) {
        final badge = streakBadge(snap(MagicElement.flora, n));
        expect(badge, isNotNull, reason: 'no pip at Flora $n');
        expect(badge!.label, 'Flora $n');
        expect(badge.color, MagicElement.flora.style.color);
      }
    });

    test('the pip names what the streak builds toward', () {
      expect(streakBadge(snap(MagicElement.flora, 3))!.sub, 'BLOOM');
    });
  });

  test('once in bloom, Photo shows ALONGSIDE the Flora 5 streak', () {
    // At 5 the streak pip still reads Flora 5 (it is capped there by the
    // engine) and the Photosynthesis buff pip appears next to it.
    final badges = badgesFromSnapshot(
      StatusSnapshot(const [
        StatusView(id: 'streak', stacks: 5, element: MagicElement.flora),
        StatusView(id: 'photosynthesis', stacks: 1),
      ]),
    );
    expect(
      badges.any((b) => b.kind == BadgeKind.streak && b.label == 'Flora 5'),
      isTrue,
    );
    expect(badges.any((b) => b.label == 'Photo'), isTrue);
  });

  test('the other counted streaks still show', () {
    expect(streakBadge(snap(MagicElement.aero, 2))!.label, 'Aero 2');
    expect(streakBadge(snap(MagicElement.aqua, 4))!.label, 'Aqua 4');
    expect(streakBadge(snap(MagicElement.geo, 3))!.sub, 'STAGGER');
  });

  test('an element with no streak mechanic shows no streak pip', () {
    // Pyro has no consecutive-cast effect.
    expect(streakBadge(snap(MagicElement.pyro, 4)), isNull);
  });
}
