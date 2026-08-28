/// The **stat stances** — the self-targeting half of the banked combat-stat
/// generation (TYPE_EFFECTS_DESIGN.md §7a, "STATUS SETS").
///
/// Five sets live here: **Lightfoot** (dodge), **Divert** (the deflect pair),
/// **Truesight** (own accuracy), **Keen** (crit chance) and **Heavyhand**
/// (crit damage). Ten spells grant them, two price points each, and every one
/// of them resolves in the aux-DEFENSE lane at priority 7.
///
/// ⭐ **One STATUS per set; the spells are only price points** (law 5). Twinkle
/// Toes does not grant "Lightfoot II" — it grants *Lightfoot*, at its own
/// numbers, and in doing so REPLACES whatever Lightfoot was already there,
/// magnitude and duration together. Last cast wins, in both directions: a
/// Lightfoot cast on top of a running Twinkle Toes is a downgrade, and that is
/// the point. Stacking was rejected (it turns two 4-cost spells into a cap
/// crisis) and so was best-of-both merging (it silently manufactures a stance
/// nobody priced: Twinkle Toes' 30 turns at some other spell's magnitude).
///
/// ⭐ **Nothing here touches a base stat.** Every status is a [StatModifier];
/// the numbers reach a roll only through [MageState.statusContributionTo] and
/// the `effective*` getters, recomputed per roll. Expiry is therefore a pure
/// removal — there is nothing to revert, which is exactly why the seam was
/// built that way (see combat_stats.dart).
///
/// ⭐ **The clamps are not re-applied here.** [CombatClamps] guards the
/// assembled OUTPUT of a roll — hit chance, deflect activation, deflected
/// fraction — and a stance that clamped its own contribution would make the
/// guarantee unreadable in two places at once. A stance declares its number;
/// the roll decides what the number is allowed to become.
library;

import 'combat_stats.dart';
import 'events.dart';
import 'mage.dart';
import 'spell.dart';
import 'status.dart';
import 'status_catalog.dart';

/// A self-granted stance that moves one or more [CombatStat]s for a fixed
/// number of turns and does nothing else — no ticks, no ops, no stacks.
///
/// ⚠️ **The duration counts the turn it lands**, the way Ignite's three ticks
/// do: the stance is applied in the main phase at priority 7, and that same
/// turn's end-phase bookkeeping is its first decrement. A 10-turn Lightfoot is
/// therefore live for the rest of the cast turn (so the priority-8 and -9
/// spells that follow it already feel it — §7a's whole reason for the aux
/// split) plus nine turns after. The alternative — Blind's "starts next turn"
/// skip — was rejected for stances: paying 2 charge for a defensive commitment
/// that cannot answer the attack landing behind it in the same turn reads as
/// the spell not working.
abstract class StatStanceStatus extends TurnStatus implements StatModifier {
  /// Turns of life left, decremented once per end phase.
  int turnsLeft;

  StatStanceStatus(this.turnsLeft);

  /// ⭐ Every stance is a [StatusPolarity.buff] — which is what puts all ten
  /// spells in Dispel's target list for free, and keeps them out of Cleanse's,
  /// Purify's and Absolution's. None of those spells will ever name a stance.
  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  /// Stances never tick: they are read, not run.
  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;

  /// The stance's numbers in the player's words — '+15 dodge'. Used to build
  /// the log line, so the number a player is told is read off the object that
  /// will actually be feeding the rolls.
  String get grantLine;
}

/// **Lightfoot** — dodge, `+N` (§7a, Christian's worked example).
///
/// Feeds [CombatStat.dodge], which the hit roll subtracts *at the moment of
/// resolution*. The 10% hit floor is what stops it (or anything stacked with
/// it) ever making a mage unhittable.
class LightfootStatus extends StatStanceStatus {
  /// Dodge points contributed while it lasts.
  final int dodge;

  LightfootStatus({required this.dodge, required int turns}) : super(turns);

  /// The 2-cost price point: +15 dodge, 10 turns.
  static LightfootStatus lightfoot() => LightfootStatus(dodge: 15, turns: 10);

  /// The 4-cost price point: +20 dodge, 30 turns — the duration is what the
  /// extra charge mostly buys.
  static LightfootStatus twinkleToes() =>
      LightfootStatus(dodge: 20, turns: 30);

  @override
  String get id => 'lightfoot';

  @override
  int contributionTo(CombatStat stat) =>
      stat == CombatStat.dodge ? dodge : 0;

  @override
  String get grantLine => '+$dodge dodge';
}

/// **Divert** — deflection, always a PAIR: how often a deflection fires, and
/// how much of the hit it removes.
///
/// ⭐ **One status carrying two numbers, deliberately** — not two statuses that
/// happen to be cast together. Half a Divert is not a thing you can hold: an
/// activation chance with nothing to remove deflects zero damage, and a
/// deflected fraction that never fires is inert. Splitting them would also let
/// a future spell replace one half and leave the other, which is a stance
/// nobody priced.
class DivertStatus extends StatStanceStatus {
  /// Percent chance an incoming hit is deflected at all.
  final int activationPercent;

  /// Percent of a deflected hit that is removed.
  final int deflectedPercent;

  DivertStatus({
    required this.activationPercent,
    required this.deflectedPercent,
    required int turns,
  }) : super(turns);

  /// The 1-cost price point: 10/20 for 10 turns — a sliver, as designed.
  static DivertStatus glance() => DivertStatus(
      activationPercent: 10, deflectedPercent: 20, turns: 10);

  /// The 3-cost price point: 20/40 for 15 turns.
  static DivertStatus divert() => DivertStatus(
      activationPercent: 20, deflectedPercent: 40, turns: 15);

  @override
  String get id => 'divert';

  @override
  int contributionTo(CombatStat stat) => switch (stat) {
        CombatStat.deflectActivation => activationPercent,
        CombatStat.deflectAmount => deflectedPercent,
        _ => 0,
      };

  @override
  String get grantLine =>
      '$activationPercent% to deflect $deflectedPercent% of a hit';
}

/// **Truesight** — own accuracy, `+N`.
///
/// ⭐ Every granter also **cleanses Blind** on cast (§7a). That rider lives on
/// the spell ([StanceEffect.cleanses]), not on this status: the cleanse is a
/// thing the cast *does*, once, and a mage Blinded a turn later is Blind again
/// with their Truesight still running. Encoding it as a property of the status
/// would quietly make Truesight a Blind immunity, which is a different spell.
class TruesightStatus extends StatStanceStatus {
  /// Accuracy points contributed while it lasts.
  final int accuracy;

  TruesightStatus({required this.accuracy, required int turns}) : super(turns);

  /// The 1-cost price point: +20 accuracy, 10 turns.
  static TruesightStatus truesight() =>
      TruesightStatus(accuracy: 20, turns: 10);

  /// The 3-cost price point: +35 accuracy, 25 turns.
  static TruesightStatus hawkeye() => TruesightStatus(accuracy: 35, turns: 25);

  @override
  String get id => 'truesight';

  @override
  int contributionTo(CombatStat stat) =>
      stat == CombatStat.accuracy ? accuracy : 0;

  @override
  String get grantLine => '+$accuracy accuracy';
}

/// **Keen** — crit chance, `+N%`.
///
/// ⚠️ Inert on its own against a **Composure** stance (which resolves incoming
/// crits as normal hits) — that is the counter, and it is why crit chance has
/// no cap of its own.
class KeenStatus extends StatStanceStatus {
  /// Crit-chance percentage points contributed while it lasts.
  final int critChance;

  KeenStatus({required this.critChance, required int turns}) : super(turns);

  /// The 2-cost price point: +15% crit chance, 12 turns.
  static KeenStatus keen() => KeenStatus(critChance: 15, turns: 12);

  /// The 4-cost price point: +25% crit chance, 30 turns.
  static KeenStatus ardent() => KeenStatus(critChance: 25, turns: 30);

  @override
  String get id => 'keen';

  @override
  int contributionTo(CombatStat stat) =>
      stat == CombatStat.critChance ? critChance : 0;

  @override
  String get grantLine => '+$critChance% crit chance';
}

/// **Heavyhand** — crit damage, `+N`.
///
/// ⚠️ Pure upside only while something is critting: it multiplies a crit that
/// already happened and does nothing at all without crit chance under it (the
/// mage's base 50% crit damage is likewise inert at 0% chance). The pair is
/// each other's brake, which is why neither needs a cap.
class HeavyhandStatus extends StatStanceStatus {
  /// Extra crit damage, in percentage points, on top of the base 50.
  final int critDamage;

  HeavyhandStatus({required this.critDamage, required int turns})
      : super(turns);

  /// The 2-cost price point: +30 crit damage, 12 turns.
  static HeavyhandStatus heavyhand() =>
      HeavyhandStatus(critDamage: 30, turns: 12);

  /// The 4-cost price point: +50 crit damage, 30 turns.
  static HeavyhandStatus overkill() =>
      HeavyhandStatus(critDamage: 50, turns: 30);

  @override
  String get id => 'heavyhand';

  @override
  int contributionTo(CombatStat stat) =>
      stat == CombatStat.critDamage ? critDamage : 0;

  @override
  String get grantLine => '+$critDamage% crit damage';
}

/// The moment logged when a Truesight granter burns a Blind away.
const String blindLiftedStatusId = 'blindLifted';

/// Lands [effect] on [caster] and returns the events for it — the whole of
/// law 5, in one place.
///
/// Order is load-bearing: the **cleanse runs first**, so a Truesight cast into
/// a Blind reads as one clean beat in the log (Blind lifted, then the stance),
/// and so a future cleanse that ever targets the stance's own set could not
/// eat the stance it is landing alongside.
///
/// ⚠️ **Removal by ID, not by runtime type.** The set is identified by the
/// thing law 5 keys on — the status id — so a second class ever granting
/// `lightfoot` (a gear-lane stance, an enemy innate) collides with the spell
/// lane exactly as the law says it should, rather than sitting invisibly
/// beside it and summing.
List<DuelEvent> applyStance(MageState caster, StanceEffect effect) {
  final events = <DuelEvent>[];

  final cleanse = effect.cleanses;
  if (cleanse != null &&
      caster.statuses.any((s) => s.id == cleanse.statusId)) {
    caster.statuses.removeWhere((s) => s.id == cleanse.statusId);
    events.add(BuffAppliedEvent(
        caster, '${_nameOf(cleanse.statusId)} lifted',
        statusId: cleanse.momentId));
  }

  // Law 5: the granter REPLACES the set's existing status outright. A refresh
  // of the same spell is the same operation — a fresh instance at full
  // duration — which is why there is no separate refresh path to drift.
  caster.statuses.removeWhere((s) => s.id == effect.statusId);
  final granted = effect.grant();
  caster.statuses.add(granted);

  final line = granted is StatStanceStatus
      ? '${_nameOf(effect.statusId)} — ${granted.grantLine}, '
          '${granted.turnsLeft} turns'
      : _nameOf(effect.statusId);
  events.add(BuffAppliedEvent(caster, line, statusId: effect.statusId));
  return events;
}

/// The catalogued player-facing name for [statusId] — read from the catalogue
/// rather than retyped, so the log and the guide can never call one status two
/// different things.
String _nameOf(String statusId) =>
    StatusCatalog.byId(statusId)?.name ?? statusId;
