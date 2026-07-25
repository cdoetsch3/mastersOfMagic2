import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../ui/app_theme.dart';
import 'element_style.dart';

/// How a status flourish moves. Each reads distinctly at a glance, so two
/// statuses never look like the same event with a different tint.
enum StatusMotion {
  /// Motes drift upward and fade — things that burn, grow, or evaporate.
  rise,

  /// Heavy drops fall and pool at the feet — things that weigh you down.
  sink,

  /// Motes circle the mage — knowledge, accumulation.
  orbit,

  /// Motes pull inward from outside the frame — something closing in or
  /// settling onto you.
  converge,

  /// Motes fly outward — something being torn off you.
  scatter,

  /// An expanding ring with a bright core — a discharge of power.
  bloom,

  /// Jagged fracture lines radiating from the centre.
  crack,

  /// Horizontal speed lines — initiative and tempo.
  streak,

  /// Stacked chevrons swelling upward — amplification.
  chevron,

  /// An offset duplicate peeling away and dissolving — becoming intangible.
  ghost,

  /// Scattered motes snapping into a single straight line.
  align,

  /// A weak, short pulse — the "nothing actually happened" beat.
  dim,
}

/// The look of one status flourish.
class StatusFx {
  final Color color;
  final StatusMotion motion;

  const StatusFx(this.color, this.motion);
}

/// Every status's animation, keyed by the same id the engine stamps on
/// [BuffAppliedEvent] and [StatusCatalog]. `status_fx_test` asserts this covers
/// the catalogue, so a new status can't ship with a generic flash.
const Map<String, StatusFx> statusFx = {
  // ---- Debuffs ---------------------------------------------------------
  'ignite': StatusFx(AppColors.ember, StatusMotion.rise),
  'blind': StatusFx(Color(0xFFF5B23E), StatusMotion.bloom),
  'waterlogged': StatusFx(Color(0xFF3D8BD9), StatusMotion.sink),
  'stagger': StatusFx(Color(0xFF9C7A4B), StatusMotion.crack),

  // ---- Buffs -----------------------------------------------------------
  'photosynthesis': StatusFx(Color(0xFF5FB35B), StatusMotion.rise),
  'creepingDark': StatusFx(Color(0xFF8B5CD6), StatusMotion.converge),
  'arcaneKnowledge': StatusFx(Color(0xFFD65AB8), StatusMotion.orbit),
  'astralAlignment': StatusFx(Color(0xFF6E7BD6), StatusMotion.align),
  'grace': StatusFx(Color(0xFFF2E7C9), StatusMotion.converge),
  'haste': StatusFx(AppColors.teal, StatusMotion.streak),
  'empower': StatusFx(AppColors.gold, StatusMotion.chevron),
  'quicken': StatusFx(AppColors.sky, StatusMotion.streak),
  'phase': StatusFx(AppColors.gem, StatusMotion.ghost),

  // ---- Moments ---------------------------------------------------------
  'absolutionRising': StatusFx(Color(0xFFF2E7C9), StatusMotion.rise),
  'absolution': StatusFx(Color(0xFFF2E7C9), StatusMotion.bloom),
  'graceConsumed': StatusFx(Color(0xFFF2E7C9), StatusMotion.scatter),
  'graceAlready': StatusFx(Color(0xFFBDB6D4), StatusMotion.dim),
  'igniteDoused': StatusFx(Color(0xFF9FC6E8), StatusMotion.rise),
  'tailwindScattered': StatusFx(Color(0xFFE8C547), StatusMotion.scatter),
  'alignmentStripped': StatusFx(Color(0xFFAFC3E8), StatusMotion.scatter),
  'darkSeared': StatusFx(Color(0xFFF2E7C9), StatusMotion.bloom),
  'sanctusUnravelled': StatusFx(Color(0xFFD65AB8), StatusMotion.scatter),
};

/// The flourish for [statusId], falling back to a neutral gold pulse for any
/// buff that predates the ids.
StatusFx statusFxFor(String? statusId) =>
    statusFx[statusId] ?? const StatusFx(AppColors.gold, StatusMotion.dim);

/// A player-facing colour for a catalogue entry — used by the guide so a
/// status reads the same colour there as it does mid-duel.
Color statusColor(StatusInfo info) =>
    statusFx[info.id]?.color ?? info.element?.style.color ?? AppColors.gold;
