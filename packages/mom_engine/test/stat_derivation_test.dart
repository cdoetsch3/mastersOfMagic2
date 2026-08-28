import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The foundation the 34-spell combat-stat bank is built on
/// (TYPE_EFFECTS_DESIGN.md §7a): **polarity** on every status, **derivation**
/// instead of mutate-and-revert, the **global output clamps**, and the
/// **aux-offense lane** at priority 8.
///
/// ⚠️ Nothing shipped implements [StatModifier] yet, so in a real duel every
/// sum below is 0 and every clamp is slack. That is the point: the seam has to
/// be proven correct while it is still inert, because once thirty-four spells
/// are pushing numbers through it, a bug here reads as a balance problem.

/// `nextDouble` walks [doubles] then returns 0.99; `nextInt` walks [ints] then
/// returns 0. Two independent scripts, because the hit roll draws a double and
/// the crit/deflect rolls draw ints — sharing one script would make every test
/// below depend on the engine's internal call order.
class ScriptedRandom implements Random {
  final List<double> doubles;
  final List<int> ints;
  var _d = 0;
  var _i = 0;
  ScriptedRandom({this.doubles = const [], this.ints = const []});
  @override
  double nextDouble() => _d < doubles.length ? doubles[_d++] : 0.99;
  @override
  int nextInt(int max) => _i < ints.length ? ints[_i++] : 0;
  @override
  bool nextBool() => false;
}

/// A fixed-damage spell: `_roll(n, n)` draws no RNG at all, so the only
/// [Random] calls in these tests are the ones under test.
Spell dmg(int amount) => Spell(
    id: 'dmg$amount', name: 'Dmg$amount', chargeCost: 0,
    priority: SpellPriority.attack, effect: DamageEffect(amount, amount));

/// A stand-in for the banked stat granters (Lightfoot, Murk, Keen…): one
/// signed contribution to one [CombatStat], for [turnsLeft] turns.
class _StatChip extends TurnStatus implements StatModifier {
  final CombatStat stat;
  final int amount;
  int turnsLeft;

  _StatChip(this.stat, this.amount, {this.turnsLeft = 1});

  @override
  StatusPolarity get polarity =>
      amount >= 0 ? StatusPolarity.buff : StatusPolarity.debuff;

  @override
  String get id => 'chip-${stat.name}';

  @override
  int contributionTo(CombatStat s) => s == stat ? amount : 0;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  void cast(DuelEngine d, Spell s, [MagicElement e = MagicElement.pyro]) {
    alice
      ..charge = s.chargeCost
      ..element = e;
    d.resolveTurn(CastAction(s, e), const ForfeitAction());
  }

  // ======================================================================
  // Polarity — the hook Dispel / Cleanse / Purify / Absolution query
  // ======================================================================
  group('polarity', () {
    test('every shipped TurnStatus carries the ruled polarity', () {
      final ruled = <TurnStatus, StatusPolarity>{
        IgniteStatus(5): StatusPolarity.debuff,
        BlindStatus(): StatusPolarity.debuff,
        PhotosynthesisStatus(): StatusPolarity.buff,
        CreepingDarkStatus(3): StatusPolarity.buff,
        ArcaneKnowledgeStatus(): StatusPolarity.buff,
        AstralAlignmentStatus(): StatusPolarity.buff,
        PendingAbsolutionStatus(): StatusPolarity.neutral,
        RegrowStatus(2): StatusPolarity.buff,
        HealOverTimeStatus(percentPerTurn: 9, turnsLeft: 3):
            StatusPolarity.buff,
      };
      for (final MapEntry(key: status, value: expected) in ruled.entries) {
        expect(status.polarity, expected,
            reason: '⚠️ ${status.id} is ruled $expected — a status that drifts '
                'here silently changes what Dispel and Purify can touch');
      }
    });

    test('the catalogue agrees with the runtime status, id by id', () {
      // ⚠️ Kills the drift where a status class is reclassified and its
      // catalogue entry — which is what the field-backed statuses and the HUD
      // read — is left saying the opposite.
      final runtime = <TurnStatus>[
        IgniteStatus(5),
        BlindStatus(),
        PhotosynthesisStatus(),
        CreepingDarkStatus(3),
        ArcaneKnowledgeStatus(),
        AstralAlignmentStatus(),
      ];
      for (final s in runtime) {
        expect(StatusCatalog.polarityOf(s.id), s.polarity,
            reason: "'${s.id}' must read the same in the catalogue as it does "
                'in the engine');
      }
    });

    test('the field-backed statuses are classified too', () {
      // ⭐ Waterlogged, Stagger, Grace, Haste, Empower, Quicken and Phase are
      // plain fields on MageState, so the catalogue is the ONLY place they can
      // carry a polarity — and Dispel/Cleanse need them.
      const debuffs = ['waterlogged', 'stagger'];
      const buffs = ['grace', 'haste', 'empower', 'quicken', 'phase'];
      for (final id in debuffs) {
        expect(StatusCatalog.polarityOf(id), StatusPolarity.debuff,
            reason: "'$id' is what Cleanse and Purify exist to remove");
      }
      for (final id in buffs) {
        expect(StatusCatalog.polarityOf(id), StatusPolarity.buff,
            reason: "'$id' is what Dispel exists to strip");
      }
    });

    test('moments are neutral — a flash in the log is not a condition', () {
      for (final m in StatusCatalog.moments) {
        expect(m.polarity, StatusPolarity.neutral,
            reason: '⚠️ ${m.id}: a moment classified buff/debuff would join '
                "Dispel's or Purify's target list with nothing to remove");
      }
    });

    test('the catalogue can list a polarity, and lists only lasting ones', () {
      final buffs =
          StatusCatalog.lastingWithPolarity(StatusPolarity.buff).toList();
      expect(buffs.map((s) => s.id), contains('empower'));
      expect(buffs.map((s) => s.id), isNot(contains('ignite')));
      expect(buffs.every((s) => s.lingers), isTrue,
          reason: '⚠️ kills a selector built off `all` instead of `lasting`: '
              'a moment in Dispel\'s target list is a strip with nothing to '
              'strip');
      expect(
          StatusCatalog.lastingWithPolarity(StatusPolarity.debuff)
              .map((s) => s.id),
          containsAll(['ignite', 'blind', 'waterlogged', 'stagger']));
    });

    test('statusesWithPolarity selects, in application order', () {
      alice.statuses
        ..add(RegrowStatus(2)) // buff
        ..add(IgniteStatus(5)) // debuff
        ..add(ArcaneKnowledgeStatus()); // buff
      expect(
          alice
              .statusesWithPolarity(StatusPolarity.buff)
              .map((s) => s.id)
              .toList(),
          ['regrow', 'arcaneKnowledge'],
          reason: '⚠️ order is load-bearing: Absolution picks from this list '
              'with the shared seed, so both lockstep clients must build it '
              'identically');
      expect(
          alice
              .statusesWithPolarity(StatusPolarity.debuff)
              .map((s) => s.id)
              .toList(),
          ['ignite']);
    });

    test("Absolution's pool is polarity-driven, so buffs are never purged", () {
      // Only buffs on the holder → nothing to purge → Grace instead. ⚠️ Kills
      // the mutant that purges any status rather than a debuff: a Sanctus mage
      // eating their own Regrow would be a bug reported as "my gear stopped
      // working".
      final duel =
          DuelEngine(alice, bruno, rng: ScriptedRandom(), baseMissPercent: 0);
      alice.statuses.add(RegrowStatus(2));
      alice
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2 // the next Sanctus cast is the 3rd
        ..charge = 0
        ..element = MagicElement.sanctus;
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.sanctus),
          const ForfeitAction());
      expect(alice.statuses.whereType<RegrowStatus>(), hasLength(1),
          reason: 'a buff is not in the purge pool');
      expect(alice.hasGrace, isTrue,
          reason: 'an empty debuff pool banks Grace instead');
    });
  });

  // ======================================================================
  // Derivation — effective = base + gear + Σ(statuses), per roll
  // ======================================================================
  group('stat derivation', () {
    test('the seam sums to zero with no StatModifier present', () {
      // ⭐ The state this lane ships in. Kills a seam that quietly adds a
      // constant, or reads a stale cached sum.
      alice.statuses.add(IgniteStatus(5)); // a status, but not a modifier
      for (final stat in CombatStat.values) {
        expect(alice.statusContributionTo(stat), 0, reason: stat.name);
      }
      expect(alice.effectiveAccuracyBonus, alice.accuracyBonus);
      expect(alice.effectiveDodge, alice.dodge);
      expect(alice.effectiveCritChance, alice.critChance);
      expect(alice.effectiveCritDamage, alice.critDamage);
      expect(alice.effectiveDeflectChance, alice.deflectChance);
      expect(alice.effectiveDeflectAmount, alice.deflectAmount);
    });

    test('contributions add to base+gear, and sum across statuses', () {
      bruno.dodge = 10; // base + gear, written once at build time
      bruno.statuses
        ..add(_StatChip(CombatStat.dodge, 15))
        ..add(_StatChip(CombatStat.dodge, 20));
      expect(bruno.effectiveDodge, 45,
          reason: '⚠️ kills replace-the-base (35), highest-wins (30) and '
              'statuses-only (35): different lanes SUM (§7a law 4)');
      expect(bruno.dodge, 10,
          reason: 'reading the derived value must not write anything back');
    });

    test('a contribution is signed — a debuff subtracts', () {
      alice.accuracyBonus = 20;
      alice.statuses.add(_StatChip(CombatStat.accuracy, -35)); // the Murk lane
      expect(alice.effectiveAccuracyBonus, -15,
          reason: '⚠️ kills an abs()/clamp-at-zero seam: a debuff must be able '
              'to push a stat negative, and the CLAMP is on the output');
    });

    test('a contribution reaches only its own stat', () {
      alice.statuses.add(_StatChip(CombatStat.critChance, 25));
      expect(alice.effectiveCritChance, 25);
      expect(alice.effectiveCritDamage, 50,
          reason: '⚠️ kills a seam that adds every contribution to every stat');
    });

    test('⭐ a cast/expire cycle leaves the BASE stats untouched', () {
      // The whole reason the seam exists. A mutate-and-revert implementation
      // passes every "the buff works" test and fails exactly here: it writes
      // 40 into the field on application, and after expiry the mage is left
      // permanently altered (or, worse, reverted twice).
      alice.accuracyBonus = 5;
      bruno.dodge = 40;

      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(doubles: [0.2]),
          elementEffects: false,
          baseMissPercent: 0);
      alice.statuses.add(_StatChip(CombatStat.accuracy, 40, turnsLeft: 1));

      expect(alice.accuracyBonus, 5,
          reason: 'applying a status writes nothing into the base field');
      expect(alice.effectiveAccuracyBonus, 45);

      cast(duel, dmg(20));
      // 100 + 45 − 40 = 105 → clamped to 100 → no roll, guaranteed hit.
      // ⚠️ Without the derivation it is 100 + 5 − 40 = 65, and the scripted
      // 0.2 (20 < 35) misses. The hit IS the proof the roll read the status.
      expect(bruno.hp, 80,
          reason: 'the hit roll read the status at resolution time');

      // One turn, so the chip expired in that turn's bookkeeping.
      expect(alice.statuses.whereType<_StatChip>(), isEmpty,
          reason: 'the chip is gone');
      expect(alice.accuracyBonus, 5,
          reason: '⚠️ THE mutant: mutate-and-revert leaves 45 here (never '
              'reverted) or −35 (reverted twice)');
      expect(alice.effectiveAccuracyBonus, 5,
          reason: 'and the derived value falls back to base+gear on its own');
    });

    test('crit chance and crit damage both derive, per hit', () {
      alice.critChance = 0;
      alice.statuses
        ..add(_StatChip(CombatStat.critChance, 100))
        ..add(_StatChip(CombatStat.critDamage, 30));
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      cast(duel, dmg(20));
      // 50 base + 30 = 80% crit bonus → 20 × 1.8 = 36.
      expect(bruno.hp, 64,
          reason: '⚠️ kills reading the stored critChance (0 → no crit, hp 80) '
              'and the stored critDamage (50 → hp 70)');
    });

    test('deflect derives both halves of the Divert pair', () {
      bruno.statuses
        ..add(_StatChip(CombatStat.deflectActivation, 100))
        ..add(_StatChip(CombatStat.deflectAmount, 40));
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 88,
          reason: '⚠️ kills reading the stored deflect fields (both 0 → hp 80): '
              '40% of 20 is 8 removed, 12 lands');
    });
  });

  // ======================================================================
  // Global clamps — on the OUTPUT, never on the components (§7a, ruled)
  // ======================================================================
  group('global clamps', () {
    test('⭐ the hit chance floors at 10% under max dodge + max accuracy debuff',
        () {
      // The ledger entry. Both dials jammed far past anything the game can
      // reach, so only a floor can save the attack.
      bruno.dodge = 200;
      alice.statuses.add(_StatChip(CombatStat.accuracy, -200));

      // 89.9 < 90 → a miss. The floor is 10% HIT, so 90% MISS.
      var duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(doubles: [0.899]),
          elementEffects: false,
          baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 100,
          reason: '⚠️ kills a floor set too high (at 20% the miss chance is 80 '
              'and this roll would land)');

      // 90.1 < 90 is false → it lands. There is always a sliver.
      alice = MageState(name: 'Alice')
        ..statuses.add(_StatChip(CombatStat.accuracy, -200));
      bruno = MageState(name: 'Bruno')..dodge = 200;
      duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(doubles: [0.901]),
          elementEffects: false,
          baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ THE mutant: no floor at all leaves a −300 hit chance and '
              'a 100% miss, so this roll would whiff and stacked evasion would '
              'be literally unhittable');
    });

    test('the floor is on the output, not on dodge or accuracy', () {
      // ⚠️ Kills the rejected design — clamping the components. If dodge were
      // capped at (say) 90, a 200-dodge mage and a 90-dodge mage would play
      // identically; because the clamp is on the output, a modest accuracy
      // buff on top of a −200 debuff still changes nothing (both floor), while
      // the stats themselves stay whatever they are.
      expect(CombatClamps.hitChance(-300), 10);
      expect(CombatClamps.hitChance(105), 100);
      expect(CombatClamps.hitChance(65), 65,
          reason: 'an ordinary hit chance passes through untouched');
      bruno.dodge = 200;
      expect(bruno.effectiveDodge, 200,
          reason: 'the stat itself is never clamped — only the roll it feeds');
    });

    test('the hit chance caps at 100 — an over-accurate attack draws no roll',
        () {
      alice.statuses.add(_StatChip(CombatStat.accuracy, 60));
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(doubles: [0.0]),
          elementEffects: false,
          baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ 160 accuracy leaves a miss chance of −60; a seam that '
              'rolled against a negative miss (0.0 < −60 is false) would pass '
              'by luck, so the cap is what makes it principled');
    });

    test('⭐ deflect ACTIVATION caps at 90%', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 50;
      // nextInt(100) → 89: 89 < 90, the deflect fires.
      var duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(ints: [89]),
          elementEffects: false,
          baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 90, reason: '50% of 20 removed, 10 lands');

      // nextInt(100) → 90: 90 < 90 is false, so the "certain" deflect fails.
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno')
        ..deflectChance = 100
        ..deflectAmount = 50;
      duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(ints: [90]),
          elementEffects: false,
          baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ THE mutant: an uncapped 100% activation deflects this '
              'roll too (hp 90) and deflection becomes a certainty');
    });

    test('⭐ the deflected FRACTION caps at 90%', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 100;
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 98,
          reason: '⚠️ THE mutant: an uncapped 100% fraction erases the hit '
              'entirely (hp 100). 90% of 20 is 18, so 2 always lands');
    });

    test('the deflect caps apply to the derived total, not the stored field',
        () {
      // 50 of gear plus a 50-point status. Three outcomes tell three
      // implementations apart, which is the whole value of this case.
      bruno
        ..deflectChance = 100
        ..deflectAmount = 50;
      bruno.statuses
          .add(_StatChip(CombatStat.deflectAmount, 50, turnsLeft: 5));
      expect(bruno.effectiveDeflectAmount, 100,
          reason: 'the stat itself is never clamped — only the roll it feeds');
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      cast(duel, dmg(20));
      expect(bruno.hp, 98,
          reason: '⚠️ three mutants, three numbers: ignoring the status leaves '
              'hp 90 (only the gear 50% removed), summing without the cap '
              'leaves hp 100 (the hit erased), and the ruling gives 90% of 20 '
              '= 18 removed, so 2 lands');
    });

    test('a negative deflect stat never becomes a certainty', () {
      // ⚠️ clamp(x, 0, 90) on a negative input: "never", not "always". Kills a
      // one-sided clamp that only caps the top.
      expect(CombatClamps.deflectActivation(-40), 0);
      expect(CombatClamps.deflectFraction(-40), 0);
    });
  });

  // ======================================================================
  // Priority — the aux-offense lane (§7a, ruled 2026-08-26)
  // ======================================================================
  group('aux-offense lane', () {
    test('Discharge sits at priority 8, not 7', () {
      expect(Spellbook.discharge.priority, SpellPriority.auxOffense,
          reason: '⚠️ it points at the enemy and deals no damage — the exact '
              'definition of the new lane (was 7)');
      expect(SpellPriority.auxOffense, 8);
      expect(SpellPriority.auxDefense, 7,
          reason: 'self-targeting aux keeps the old rung');
    });

    test('Overload is priority 9, the attack lane', () {
      // §7a rules "Overload → 9". It got there on the 2026-07-28 ruling, so
      // this pins it rather than moving it — a silent revert to 7 would give a
      // full attack a quick spell's timing.
      expect(Spellbook.overload.priority, SpellPriority.attack);
    });

    test('⭐ a self-targeting aux resolves BEFORE an enemy-targeting one', () {
      // The consequence the split exists for: Bruno's commitment lands, then
      // Alice's interference. Hallow (7) banks Grace even though the Discharge
      // (8) empties the bar it was paid from.
      alice
        ..charge = 2
        ..element = MagicElement.geo;
      bruno
        ..charge = 1
        ..element = MagicElement.aqua;
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      final r = duel.resolveTurn(
          CastAction(Spellbook.discharge), CastAction(Spellbook.hallow));
      expect(bruno.hasGrace, isTrue,
          reason: '⚠️ THE mutant: with Discharge back at 7 the two collide and '
              "Hallow can fizzle — the stance must beat the interference");
      expect(bruno.charge, 0);
      expect(r.events.whereType<SpellFizzledEvent>(), isEmpty);
    });

    test('…and still beats a real attack, which is why 8 and not 9', () {
      alice
        ..charge = 2
        ..element = MagicElement.geo;
      bruno
        ..charge = 4
        ..element = MagicElement.aqua;
      final duel = DuelEngine(alice, bruno,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      final r = duel.resolveTurn(
          CastAction(Spellbook.discharge), CastAction(Spellbook.ruin));
      expect(r.events.whereType<SpellFizzledEvent>(), hasLength(1),
          reason: '⚠️ at priority 9 Discharge would trade with Ruin instead of '
              'pre-empting it, and the charge-control lane would be dead');
      expect(alice.hp, 100);
    });
  });
}
