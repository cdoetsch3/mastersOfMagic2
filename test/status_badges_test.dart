import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_status_badges.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:mom_engine/mom_engine.dart';

/// The HUD pips, and specifically the Flora streak.
///
/// ⚠️ Flora used to produce NO streak pip — `_streakMechanic` covered the four
/// cadence elements but not Flora, so a Flora run was invisible until it
/// activated. Reported from play: "Flora count not working, not seeing the
/// status PIP showing the streak."
void main() {
  StatusSnapshot snap(MagicElement element, int count) => StatusSnapshot([
    StatusView(id: 'streak', stacks: count, element: element),
  ]);

  StatusBadge? streakBadge(StatusSnapshot s) => badgesFromSnapshot(
    s,
  ).where((b) => b.kind == BadgeKind.streak).firstOrNull;

  group('the Flora streak is visible before Photosynthesis activates', () {
    test('Flora 1 through 4 each show a counted pip', () {
      // 5 is where the counter hands over to the Photo pip — see
      // the paid-off group below.
      for (var n = 1; n <= 4; n++) {
        final badge = streakBadge(snap(MagicElement.flora, n));
        expect(badge, isNotNull, reason: 'no pip at Flora $n');
        expect(badge!.label, 'Flora $n');
        expect(badge.color, MagicElement.flora.style.color);
      }
    });

    test('the pip names what the streak builds toward', () {
      expect(streakBadge(snap(MagicElement.flora, 3))!.sub, 'PHOTO');
    });
  });

  test('once active, Photo REPLACES the Flora counter', () {
    final badges = badgesFromSnapshot(
      StatusSnapshot(const [
        StatusView(id: 'streak', stacks: 5, element: MagicElement.flora),
        StatusView(id: 'photosynthesis', stacks: 1),
      ]),
    );
    expect(badges.any((b) => b.label == 'Photo'), isTrue);
    expect(badges.where((b) => b.kind == BadgeKind.streak), isEmpty);
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

  group('a paid-off streak stops taking up space with a number', () {
    test('Flora drops its counter entirely once Photosynthesis is active', () {
      // The "Photo / active" pip already says everything "Flora 5" would.
      final badges = badgesFromSnapshot(
        StatusSnapshot(const [
          StatusView(id: 'streak', stacks: 5, element: MagicElement.flora),
          StatusView(id: 'photosynthesis', stacks: 1),
        ]),
      );
      expect(
        badges.where((b) => b.kind == BadgeKind.streak),
        isEmpty,
        reason: 'the counter is redundant beside the Photo pip',
      );
      expect(badges.any((b) => b.label == 'Photo'), isTrue);
    });

    test('Aero becomes "Tailwind" with no number', () {
      // Tailwind has no pip of its own, so the streak pip becomes it.
      final badge = streakBadge(snap(MagicElement.aero, 3))!;
      expect(badge.label, 'Tailwind');
      expect(badge.sub, isNull);
      expect(badge.color, MagicElement.aero.style.color);
    });

    test('but they still COUNT on the way up', () {
      expect(streakBadge(snap(MagicElement.aero, 2))!.label, 'Aero 2');
      expect(streakBadge(snap(MagicElement.flora, 4))!.label, 'Flora 4');
    });

    test('cadence streaks keep counting forever', () {
      // For Aqua/Geo/Sanctus the number IS the mechanic — it says how far off
      // the next proc is — so it must never be replaced by a label.
      expect(streakBadge(snap(MagicElement.aqua, 9))!.label, 'Aqua 9');
      expect(streakBadge(snap(MagicElement.geo, 12))!.label, 'Geo 12');
    });
  });

  test('Empower reads as a state, not a stack count', () {
    // ⚠️ "×2" beside pips like "Dark 7" read as TWO Empowers. It does not
    // stack; it doubles.
    final badges = badgesFromSnapshot(
      StatusSnapshot(const [StatusView(id: 'empower', magnitude: 2)]),
    );
    final empower = badges.firstWhere((b) => b.label == 'Empower');
    expect(empower.sub, isNull);
  });

  group('the catalogue draws every status no arm names', () {
    StatusBadge one(StatusView v) {
      final badges = badgesFromSnapshot(StatusSnapshot([v]));
      expect(badges, hasLength(1), reason: '${v.id} must produce one pip');
      return badges.single;
    }

    test('⭐ a burn shows its damage per turn and its clock, as a debuff', () {
      final b = one(const StatusView(id: 'agony', turnsLeft: 3, magnitude: 7));
      expect(b.label, 'Agony');
      expect(b.sub, '7/t · 3t',
          reason: 'the pip reads exactly like Ignite\'s — the mutant this '
              'kills is the one the designer found: a Torment ticking with '
              'no pip at all');
      expect(b.kind, BadgeKind.debuff);
      expect(b.color, AppColors.ember,
          reason: 'debuffs invert to ember, whatever their fx colour');
    });

    test('a stance shows its number and clock, as a buff', () {
      final b = one(
        const StatusView(id: 'lightfoot', turnsLeft: 10, magnitude: 15),
      );
      expect(b.label, 'Lightfoot');
      expect(b.sub, '+15 · 10t');
      expect(b.kind, BadgeKind.buff);
    });

    test('the Divert pair shows both halves', () {
      final b = one(const StatusView(
          id: 'divert', turnsLeft: 15, magnitude: 20, secondaryMagnitude: 40));
      expect(b.sub, '20/40 · 15t');
    });

    test('a binary stance shows only its clock', () {
      final b = one(const StatusView(id: 'composure', turnsLeft: 25));
      expect(b.sub, '25t');
    });

    test('a moment never sits as a pip', () {
      expect(
        badgesFromSnapshot(const StatusSnapshot([StatusView(id: 'fester')])),
        isEmpty,
        reason: 'moments flash in the log; a pip would outlive its instant',
      );
    });

    test('⭐ EVERY lasting status in the catalogue renders a pip', () {
      // The guard the HUD lacked: a status the engine can apply but the
      // HUD cannot show is invisible damage. Any lasting catalogue entry,
      // handed to the builder as a bare view, must come back as a badge.
      for (final info in StatusCatalog.lasting) {
        final badges = badgesFromSnapshot(
          StatusSnapshot([StatusView(id: info.id, turnsLeft: 2, stacks: 1)]),
        );
        expect(badges, isNotEmpty, reason: '${info.id} has no pip');
      }
    });
  });
}
