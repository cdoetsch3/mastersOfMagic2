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

  const StatusBadge(this.label, {this.sub, required this.color, required this.kind});
}

/// The mechanic a consecutive streak of [element] is building toward.
String? _streakMechanic(MagicElement element) => switch (element) {
      MagicElement.aqua => 'WATERLOG',
      MagicElement.aero => 'TAILWIND',
      MagicElement.geo => 'STAGGER',
      MagicElement.sanctus => 'ABSOLUTION',
      _ => null, // only these four carry consecutive-streak effects
    };

/// Extracts the active status badges for [mage] — its own buffs and the
/// debuffs afflicting it — for the duel HUD. Order: streak, buffs, debuffs.
List<StatusBadge> statusBadgesFor(MageState mage) {
  final badges = <StatusBadge>[];

  // --- Streak (only the three consecutive-effect elements) --------------
  final streakEl = mage.streakElement;
  if (streakEl != null && mage.streakCount > 0) {
    final mechanic = _streakMechanic(streakEl);
    if (mechanic != null) {
      badges.add(StatusBadge('${streakEl.style.label} ${mage.streakCount}',
          sub: mechanic, color: streakEl.style.color, kind: BadgeKind.streak));
    }
  }

  // --- Buffs (mine) -----------------------------------------------------
  final photo = mage.statuses.whereType<PhotosynthesisStatus>().firstOrNull;
  if (photo != null) {
    badges.add(StatusBadge('Photo ×${photo.stacks}',
        sub: 'heal', color: MagicElement.flora.style.color, kind: BadgeKind.buff));
  }
  final ak = mage.statuses.whereType<ArcaneKnowledgeStatus>().firstOrNull;
  if (ak != null) {
    badges.add(StatusBadge('AK ×${ak.stacks}',
        sub: '+${ak.bonusPercent}%',
        color: MagicElement.arcane.style.color,
        kind: BadgeKind.buff));
  }
  final align = mage.statuses.whereType<AstralAlignmentStatus>().firstOrNull;
  if (align != null) {
    badges.add(StatusBadge('Align ×${align.stacks}',
        sub: '${align.piercePercent}% pierce',
        color: MagicElement.astral.style.color,
        kind: BadgeKind.buff));
  }
  if (mage.hasGrace) {
    badges.add(StatusBadge('Grace',
        sub: 'blocks 1', color: MagicElement.sanctus.style.color,
        kind: BadgeKind.buff));
  }
  final dark = mage.statuses.whereType<CreepingDarkStatus>().firstOrNull;
  if (dark != null) {
    final tier = dark.midnight
        ? 'MIDNIGHT'
        : dark.dusk
            ? 'DUSK'
            : dark.shadow
                ? 'SHADOW'
                : 'veiled';
    badges.add(StatusBadge('Dark ${dark.stacks}',
        sub: tier, color: MagicElement.umbra.style.color, kind: BadgeKind.buff));
  }
  if (mage.hasHaste) {
    badges.add(const StatusBadge('Haste', color: AppColors.teal, kind: BadgeKind.buff));
  }
  if (mage.empowerMultiplier != null) {
    badges.add(StatusBadge('Empower',
        sub: '×${mage.empowerMultiplier}', color: AppColors.gold, kind: BadgeKind.buff));
  }
  if (mage.quickenPriority != null) {
    badges.add(const StatusBadge('Quicken', color: AppColors.sky, kind: BadgeKind.buff));
  }
  if (mage.phaseNext) {
    badges.add(const StatusBadge('Phase', color: AppColors.gem, kind: BadgeKind.buff));
  }

  // --- Debuffs (afflicting me) ------------------------------------------
  final ignite = mage.statuses.whereType<IgniteStatus>().firstOrNull;
  if (ignite != null) {
    badges.add(StatusBadge('Ignite',
        sub: '${ignite.perTick}/t · ${ignite.turnsLeft}t',
        color: AppColors.ember,
        kind: BadgeKind.debuff));
  }
  final blind = mage.statuses.whereType<BlindStatus>().firstOrNull;
  if (blind != null) {
    badges.add(StatusBadge('Blind',
        sub: '${blind.turnsLeft}t', color: AppColors.ember, kind: BadgeKind.debuff));
  }
  if (mage.nextOffensiveDamageScale < 1.0) {
    badges.add(const StatusBadge('Staggered',
        sub: 'next −50%', color: AppColors.ember, kind: BadgeKind.debuff));
  }
  if (mage.priorityPenalty > 0) {
    badges.add(const StatusBadge('Waterlogged',
        sub: 'slowed', color: AppColors.ember, kind: BadgeKind.debuff));
  }

  return badges;
}
