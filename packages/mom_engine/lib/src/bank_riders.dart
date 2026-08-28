/// The §7a bank's **next-attack riders and status surgery** — the machinery
/// behind Pierce, Unerring, Execute, Cleanse, Purify and Meditate.
///
/// The riders themselves are fields on [MageState] and the finisher is a field
/// on [DamageEffect]; what lives here is the part that needed a shared answer:
/// **what counts as a debuff on this mage, and what counts as a stance worth
/// deepening.**
///
/// ⭐ **One pool, three consumers.** Sanctus's Absolution already had to answer
/// the debuff question, and answered it inline. Cleanse and Purify ask exactly
/// the same one, so the answer moved here and Absolution now reads it too — two
/// spells drifting apart on what a debuff *is* would be a bug invisible in
/// either spell's own tests. The pool's ORDER is part of its contract:
/// Absolution's random pick indexes into it, so both lockstep clients must
/// build it identically, every time.
library;

import 'mage.dart';
import 'status.dart';

/// One affliction that can be lifted off a mage, and the door that lifts it.
class RemovableDebuff {
  /// The status id — what a Cleanse names on the wire, and what the log says.
  final String id;

  /// Turns left on its clock, or 0 when it has none.
  ///
  /// ⚠️ An untimed debuff reports 0 and therefore sorts LAST for the default
  /// pick. That is a ruling, not an accident: the default exists to shed the
  /// biggest running commitment, and "most turns left" is the measure of one. A
  /// binary debuff with no clock is a thing you cleanse on purpose, by naming
  /// it.
  final int turnsLeft;

  /// Removes it from the mage. Safe to call once.
  final void Function() remove;

  const RemovableDebuff({
    required this.id,
    required this.turnsLeft,
    required this.remove,
  });
}

/// Every debuff currently on [mage], in a **fixed, lockstep-safe order**:
/// [StatusPolarity.debuff] statuses in the order they were applied, then the
/// two field-backed afflictions.
///
/// ⭐ Asks polarity, never a type. That is what makes the banked debuffs —
/// Agony, Torment, Murk, Blight, Wither — join Cleanse's, Purify's and
/// Absolution's reach the moment they exist, with their `polarity` getter as
/// the entire integration.
///
/// ⚠️ Waterlogged and Stagger are in here even though they are not
/// [TurnStatus]es, which is why this cannot simply be
/// [MageState.statusesWithPolarity]. They are afflictions with catalogue ids
/// and HUD pips, and §4c.1 already names them in Absolution's purge list — a
/// Cleanse that could not shed a Stagger while the element lane's purge could
/// would read as a bug, not as a boundary.
///
/// 📝 A caster's OWN Waterlogged is unreachable in practice: it is consumed
/// when their action's priority is computed, before any cast resolves. It is
/// listed anyway because Absolution can find it on either mage.
List<RemovableDebuff> debuffsOn(MageState mage) {
  final pool = <RemovableDebuff>[];
  for (final s in mage.statusesWithPolarity(StatusPolarity.debuff)) {
    final timer = s is TurnTimed ? (s as TurnTimed).turnsLeft : 0;
    pool.add(RemovableDebuff(
      id: s.id,
      turnsLeft: timer,
      remove: () => mage.statuses.remove(s),
    ));
  }
  if (mage.priorityPenalty > 0) {
    pool.add(RemovableDebuff(
      id: 'waterlogged',
      turnsLeft: 0,
      remove: () => mage.priorityPenalty = 0,
    ));
  }
  if (mage.nextOffensiveDamageScale < 1.0) {
    pool.add(RemovableDebuff(
      id: 'stagger',
      turnsLeft: 0,
      remove: () => mage.nextOffensiveDamageScale = 1.0,
    ));
  }
  return pool;
}

/// The debuff a Cleanse takes when the caster named none — **the one with the
/// most turns left**, ties broken by pool order (oldest first).
///
/// ⭐ Documented as THE default rather than hidden as a fallback: an AI, a
/// replay and a UI without its pick-a-status sheet must all reach the same
/// answer, and both lockstep clients compute it from the same board rather than
/// sending it. Returns null only for an empty pool.
RemovableDebuff? defaultCleanseChoice(List<RemovableDebuff> pool) {
  RemovableDebuff? best;
  for (final d in pool) {
    if (best == null || d.turnsLeft > best.turnsLeft) best = d;
  }
  return best;
}

/// Meditate's targets: every **turn-timed buff** on [mage].
///
/// ⚠️ The whole spell is this two-part boundary (ruled 2026-08-26). A
/// next-attack rider — Phase, Pierce, Unerring — or an Empower is a plain field
/// with no clock, so it is not here and cannot be. A debuff on a clock (Ignite,
/// Blind) is on a clock the caster would *love* extended, so polarity keeps it
/// out. Drop either half and a 2-charge spell starts banking Empowers, or
/// starts feeding the enemy's burn.
///
/// ⭐ What it DOES reach is the stance game: every [StatStanceStatus] is a
/// timed buff, so Meditate deepens a Twinkle Toes or an Overkill — which is why
/// §7a pairs it with Dispel as the answer.
Iterable<TurnTimed> timedBuffsOn(MageState mage) => mage
    .statusesWithPolarity(StatusPolarity.buff)
    .whereType<TurnTimed>();

/// Turns Meditate adds to each timed buff (§7a INSTANTS).
const int meditateBonusTurns = 5;
