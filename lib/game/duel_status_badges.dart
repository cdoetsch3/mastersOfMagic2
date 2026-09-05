import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../ui/app_theme.dart';
import 'element_style.dart';
import 'status_fx.dart';

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
  // Every bespoke arm below records the id it consumed, so the catalogue
  // fallback at the end knows what is still unshown.
  final handled = <String>{};
  StatusView? take(String id) {
    handled.add(id);
    return snap[id];
  }

  // --- Streak (only the elements that build toward something) -----------
  //
  // ⭐ A counter is only worth screen space while it is still *counting*. Once
  // a gated streak has paid off, the count is frozen at its threshold and says
  // nothing the payoff pip does not — so it makes way:
  //   • Flora  — drops out entirely; the "Photo / active" pip below covers it.
  //   • Aero   — becomes "Tailwind", since Tailwind has no pip of its own.
  // Cadence streaks (Aqua/Geo/Sanctus) keep counting, because for those the
  // number is the mechanic: it says how far off the next proc is.
  final streak = take('streak');
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
  final photo = take('photosynthesis');
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
  final ak = take('arcaneKnowledge');
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
  final align = take('astralAlignment');
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
  final dark = take('creepingDark');
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
  final hot = take('healOverTime');
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
  if (take('grace') != null) {
    badges.add(
      StatusBadge(
        'Grace',
        sub: 'blocks 1',
        color: MagicElement.sanctus.style.color,
        kind: BadgeKind.buff,
      ),
    );
  }
  if (take('haste') != null) {
    badges.add(
      const StatusBadge('Haste', color: AppColors.teal, kind: BadgeKind.buff),
    );
  }
  if (take('empower') != null) {
    // ⚠️ No "×2" subtitle. Next to a stack count like "Dark 7" it read as
    // *two* Empowers rather than a doubling — and Empower does not stack.
    badges.add(
      const StatusBadge('Empower', color: AppColors.gold, kind: BadgeKind.buff),
    );
  }
  if (take('quicken') != null) {
    badges.add(
      const StatusBadge('Quicken', color: AppColors.sky, kind: BadgeKind.buff),
    );
  }
  if (take('phase') != null) {
    badges.add(
      const StatusBadge('Phase', color: AppColors.gem, kind: BadgeKind.buff),
    );
  }

  // --- Debuffs (afflicting me) ------------------------------------------
  final ignite = take('ignite');
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
  final blind = take('blind');
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
  if (take('stagger') != null) {
    badges.add(
      const StatusBadge(
        'Staggered',
        sub: 'next −50%',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }
  if (take('waterlogged') != null) {
    badges.add(
      const StatusBadge(
        'Waterlogged',
        sub: 'slowed',
        color: AppColors.ember,
        kind: BadgeKind.debuff,
      ),
    );
  }


  // --- Everything else: the catalogue draws it ---------------------------
  //
  // ⭐ The §7a bank added ~30 statuses and NONE of them had an arm above —
  // Agony and Torment ticked away with no pip, which the designer noticed on
  // his first playtest. Rather than thirty more hand-written arms (and a
  // thirty-first the day the next one lands), anything the snapshot carries
  // that no arm consumed is drawn from the catalogue: its name, its polarity
  // for the side it sits on, its fx colour, and a subtitle built from the
  // numbers the snapshot already has. Moments never sit as pips.
  for (final view in snap.statuses) {
    if (handled.contains(view.id)) continue;
    final info = StatusCatalog.byId(view.id);
    if (info == null || !info.lingers) continue;
    final debuff = info.polarity == StatusPolarity.debuff;
    badges.add(
      StatusBadge(
        info.name,
        sub: _genericSub(view),
        color: debuff ? AppColors.ember : statusColor(info),
        kind: debuff ? BadgeKind.debuff : BadgeKind.buff,
      ),
    );
  }

  return badges;
}

/// The subtitle for a catalogue-drawn pip, from the snapshot's own numbers.
///
/// Per-id units where the bare number would mislead: a burn is damage per
/// turn, Mending is percent per turn, the percent stances say so, and the
/// Divert pair shows both halves. Everything else reads `±magnitude · Nt`,
/// or just the clock when there is no magnitude.
String? _genericSub(StatusView v) {
  final t = v.turnsLeft > 0 ? '${v.turnsLeft}t' : null;
  String withClock(String head) => t == null ? head : '$head · $t';
  switch (v.id) {
    case 'agony' || 'torment':
      return withClock('${v.magnitude}/t');
    case 'mending' || 'regrow':
      return withClock('${v.magnitude}%/t');
    case 'divert':
      return withClock('${v.magnitude}/${v.secondaryMagnitude}');
    case 'keen' || 'wither' || 'steadfast':
      return withClock('${v.magnitude > 0 ? '+' : ''}${v.magnitude}%');
  }
  if (v.magnitude != 0) {
    return withClock('${v.magnitude > 0 ? '+' : ''}${v.magnitude}');
  }
  return t;
}

/// Live-state convenience wrapper — used outside a turn replay (e.g. before
/// the first turn), where lagging behind the animation isn't a concern.
List<StatusBadge> statusBadgesFor(MageState mage) =>
    badgesFromSnapshot(StatusSnapshot.of(mage));
