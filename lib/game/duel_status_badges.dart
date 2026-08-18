import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../ui/app_theme.dart';
import 'element_style.dart';

/// A2 HUD pip: one chip per active status/streak on a mage. Buffs keep an
/// element/accent border; debuffs invert to a solid ember fill, so which side
/// a chip belongs to reads by color alone (TYPE_EFFECTS_DESIGN.md §5.4).
enum BadgeKind { streak, buff, debuff }

class StatusBadge {
  final String label;
  final String? sub;
  final Color color;
  final BadgeKind kind;

  const StatusBadge(
    this.label, {
    this.sub,
    required this.color,
    required this.kind,
  });
}

/// The mechanic a consecutive streak of [element] is building toward.
String? _streakMechanic(MagicElement element) => switch (element) {
  MagicElement.flora => 'PHOTO',
  MagicElement.aqua => 'WATERLOG',
  MagicElement.aero => 'TAILWIND',
  MagicElement.geo => 'STAGGER',
  MagicElement.sanctus => 'ABSOLUTION',
  _ => null, // only these five carry consecutive-streak effects
};

/// What a gated streak reads once it has paid off and stopped counting.
String _streakPayoffLabel(MagicElement element) => switch (element) {
  MagicElement.aero => 'Tailwind',
  _ => element.style.label,
};

/// Badges for one mage, built from a [StatusSnapshot] rather than live engine
/// state — that is what lets the duel screen reveal a pip at the moment its
/// event animates instead of showing every status the instant the turn
/// resolves. Order: streak, buffs, debuffs.
List<StatusBadge> badgesFromSnapshot(StatusSnapshot snap) {
  final badges = <StatusBadge>[];

  // --- Streak (only the elements that build toward something) -----------
  //
  // ⭐ A counter is only worth screen space while it is still *counting*. Once
  // a gated streak has paid off, the count is frozen at its threshold and says
  // nothing the payoff pip does not — so it makes way:
  //   • Flora  — drops out entirely; the "Photo / active" pip below covers it.
  //   • Aero   — becomes "Tailwind", since Tailwind has no pip of its own.
  // Cadence streaks (Aqua/Geo/Sanctus) keep counting, because for those the
  // number is the mechanic: it says how far off the next proc is.
  final streak = snap['streak'];
  if (streak != null && streak.element != null) {
    final element = streak.element!;
    final mechanic = _streakMechanic(element);
    final cap = ElementTuning.streakCap(element);
    final paidOff = cap != null && streak.stacks >= cap;

    if (mechanic != null && !(paidOff && element == MagicElement.flora)) {
      badges.add(
        StatusBadge(
          paidOff
              ? _streakPayoffLabel(element)
              : '${element.style.label} ${streak.stacks}',
          sub: paidOff ? null : mechanic,
          color: element.style.color,
          kind: BadgeKind.streak,
        ),
      );
    }
  }

  // --- Buffs (mine) -----------------------------------------------------
  final photo = snap['photosynthesis'];
  if (photo != null) {
    // Streak-gated now: active or not, so no count. The Flora streak pip
    // already shows the run that sustains it.
    badges.add(
      StatusBadge(
        'Photo',
        sub: 'active',
        color: MagicElement.flora.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  final ak = snap['arcaneKnowledge'];
  if (ak != null) {
    badges.add(
      StatusBadge(
        'AK ×${ak.stacks}',
        sub: '+${ak.magnitude}%',
        color: MagicElement.arcane.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  final align = snap['astralAlignment'];
  if (align != null) {
    badges.add(
      StatusBadge(
        'Align ×${align.stacks}',
        sub: '${align.magnitude}% pierce',
        color: MagicElement.astral.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  final dark = snap['creepingDark'];
  if (dark != null) {
    final tier = dark.stacks >= CreepingDarkStatus.midnightThreshold
        ? 'MIDNIGHT'
        : dark.stacks >= CreepingDarkStatus.duskThreshold
        ? 'DUSK'
        : dark.stacks >= CreepingDarkStatus.shadowThreshold
        ? 'SHADOW'
        : 'veiled';
    badges.add(
      StatusBadge(
        'Dark ${dark.stacks}',
        sub: tier,
        color: MagicElement.umbra.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  final hot = snap['healOverTime'];
  if (hot != null) {
    // ⭐ A Tonic that ticks invisibly is a Tonic the player believes did
    // nothing — the turn it cost is the loudest part of the transaction, so
    // the payout has to be on screen for the turns it lasts.
    badges.add(
      StatusBadge(
        'Tonic',
        sub: '${hot.magnitude}%/t · ${hot.turnsLeft}t',
        color: MagicElement.flora.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  if (snap['grace'] != null) {
    badges.add(
      StatusBadge(
        'Grace',
        sub: 'blocks 1',
        color: MagicElement.sanctus.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  if (snap['haste'] != null) {
    badges.add(
      const StatusBadge('Haste', color: AppColors.teal, kind: BadgeKind.buff),
    );
  }
  if (snap['empower'] != null) {
    // ⚠️ No "×2" subtitle. Next to a stack count like "Dark 7" it read as
    // *two* Empowers rather than a doubling — and Empower does not stack.
    badges.add(
      const StatusBadge('Empower', color: AppColors.gold, kind: BadgeKind.buff),
    );
  }
  if (snap['quicken'] != null) {
    badges.add(
      const StatusBadge('Quicken', color: AppColors.sky, kind: BadgeKind.buff),
    );
  }
  if (snap['phase'] != null) {
    badges.add(
      const StatusBadge('Phase', color: AppColors.gem, kind: BadgeKind.buff),
    );
  }

  // --- Debuffs (afflicting me) ------------------------------------------
  final ignite = snap['ignite'];
  if (ignite != null) {
    badges.add(
      StatusBadge(
        'Ignite',
        sub: '${ignite.magnitude}/t · ${ignite.turnsLeft}t',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }
  final blind = snap['blind'];
  if (blind != null) {
    badges.add(
      StatusBadge(
        'Blind',
        sub: '${blind.turnsLeft}t',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }
  if (snap['stagger'] != null) {
    badges.add(
      const StatusBadge(
        'Staggered',
        sub: 'next −50%',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }
  if (snap['waterlogged'] != null) {
    badges.add(
      const StatusBadge(
        'Waterlogged',
        sub: 'slowed',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }

  return badges;
}

/// Live-state convenience wrapper — used outside a turn replay (e.g. before
/// the first turn), where lagging behind the animation isn't a concern.
List<StatusBadge> statusBadgesFor(MageState mage) =>
    badgesFromSnapshot(StatusSnapshot.of(mage));
