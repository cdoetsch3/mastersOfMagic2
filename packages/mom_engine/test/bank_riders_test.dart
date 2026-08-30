import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The §7a bank's second slice: the two next-attack riders (Pierce, Unerring),
/// the finisher (Execute) and the three self-instants (Cleanse, Purify,
/// Meditate).
///
/// ⭐ Several of these assert on **how much RNG was drawn**, not only on the
/// outcome. That is deliberate: "Divert never rolls" and "Unerring does not
/// roll to hit" are claims about the stream, and a lockstep engine that draws a
/// different number of values on two clients desyncs even when both agree on
/// the damage. Counting is the only way to test the actual ruling.

/// Deterministic RNG that also COUNTS what was drawn. `nextDouble` returns
/// scripted values then 0.99; `nextInt` returns 0 (so a guarded chance always
/// fires and damage rolls take their minimum).
class CountingRandom implements Random {
  final List<double> doubles;
  var _i = 0;
  var intCalls = 0;
  var doubleCalls = 0;

  CountingRandom([this.doubles = const []]);

  @override
  double nextDouble() {
    doubleCalls++;
    return _i < doubles.length ? doubles[_i++] : 0.99;
  }

  @override
  int nextInt(int max) {
    intCalls++;
    return 0;
  }

  @override
  bool nextBool() => false;
}

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  /// One turn: Alice casts [s] in [e] (fully paid), Bruno does nothing.
  TurnResult cast(DuelEngine d, Spell s, MagicElement e, {String? choice}) {
    alice
      ..charge = s.chargeCost
      ..element = e;
    return d.resolveTurn(CastAction(s, e, choice), const ForfeitAction());
  }

  DuelEngine engine(Random rng) => DuelEngine(alice, bruno,
      rng: rng, elementEffects: false, baseMissPercent: 0);

  // ======================================================================
  // NEXT-ATTACK RIDERS — the Phase pattern (§7a)
  // ======================================================================
  group('Pierce', () {
    // A Divert built past the caps, so the clamps are doing visible work: 90%
    // to activate, 90% of the hit removed — never the whole thing.
    void turtle(MageState m) => m
      ..deflectChance = 100
      ..deflectAmount = 100;

    test('⭐ the attack it rides cannot be deflected at all', () {
      turtle(bruno);
      final duel = engine(CountingRandom());

      cast(duel, Spellbook.pierce, MagicElement.geo);
      expect(alice.pierceNext, isTrue, reason: 'the rider is banked');

      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(bruno.hp, 89,
          reason: "Bolt's min roll of 11 landed whole — a maxed Divert removed "
              'nothing');
    });

    test('the control: the clamp leaves a sliver, the rider leaves the lot',
        () {
      turtle(bruno);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(bruno.hp, 99,
          reason: 'unpierced, the 90% fraction cap still lets 1 of 11 through '
              '— that sliver is the whole point of the cap, and Pierce is what '
              'turns it back into a full hit');
    });

    test('⚠️ Divert never ROLLS — it is skipped, not overruled', () {
      turtle(bruno);

      // Control: two integer draws — the damage roll and the deflection roll.
      final control = CountingRandom();
      var duel = engine(control);
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(control.intCalls, 2,
          reason: 'unpierced: one damage roll, one deflect roll');

      // Pierced: the deflect draw is never made, so the stream advances by one.
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno');
      turtle(bruno);
      final pierced = CountingRandom();
      duel = engine(pierced);
      cast(duel, Spellbook.pierce, MagicElement.geo);
      final before = pierced.intCalls;
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(pierced.intCalls - before, 1,
          reason: 'pierced: the damage roll only — Divert drew nothing');
    });

    test('waits until an ATTACK spends it, exactly as Phase does', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.pierce, MagicElement.geo);
      cast(duel, Spellbook.ward, MagicElement.geo);
      expect(alice.pierceNext, isTrue,
          reason: 'a shield is not an offensive attack — the rider is unspent');
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(alice.pierceNext, isFalse, reason: 'the attack consumed it');
    });

    test('it beats a Divert STANCE, not just gear', () {
      // Glance grants Divert 10/20 — the spell-lane source Pierce is the
      // counter to, per §7a's counter-web.
      final duel = DuelEngine(bruno, alice,
          rng: CountingRandom(), elementEffects: false, baseMissPercent: 0);
      bruno
        ..charge = Spellbook.glance.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(
          CastAction(Spellbook.glance, MagicElement.geo), const ForfeitAction());
      expect(bruno.effectiveDeflectChance, greaterThan(0),
          reason: 'the stance is contributing through the seam');

      alice
        ..charge = Spellbook.pierce.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.pierce, MagicElement.geo));
      final hp = bruno.hp;
      alice
        ..charge = Spellbook.bolt.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(
          const ForfeitAction(), CastAction(Spellbook.bolt, MagicElement.geo));
      expect(hp - bruno.hp, 11,
          reason: 'the full roll landed through a running Divert stance');
    });
  });

  group('Unerring', () {
    // Dodge far past anything the game can assemble. ⭐ The hit chance floors
    // at CombatClamps.hitChanceFloorPercent (10) rather than going negative —
    // so the defender keeps a 10% sliver, and the question this group answers
    // is what Unerring does to the 90% that remains.
    const impossibleDodge = 500;

    // 0.5 → 50 < 90, a miss against the floored 10% hit chance.
    List<double> missRoll() => [0.5];

    test('the floor: even maxed dodge leaves a 10% sliver', () {
      bruno.dodge = impossibleDodge;
      // 0.95 → 95, which is NOT under the 90% miss chance: it lands.
      final duel = engine(CountingRandom([0.95]));
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(bruno.hp, 89,
          reason: 'the clamp is why stacked evasion is never immunity');
    });

    test('the control: the same attack, same roll, misses', () {
      bruno.dodge = impossibleDodge;
      final duel = engine(CountingRandom(missRoll()));
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(bruno.hp, 100, reason: '90 of every 100 rolls miss at the floor');
    });

    test('⭐ Unerring alone crosses the floor — it deletes the roll', () {
      bruno.dodge = impossibleDodge;
      final rng = CountingRandom(missRoll());
      final duel = engine(rng);

      cast(duel, Spellbook.unerring, MagicElement.geo);
      final before = rng.doubleCalls;
      cast(duel, Spellbook.bolt, MagicElement.geo);

      expect(bruno.hp, 89,
          reason: 'the very roll that missed above now never happens');
      expect(rng.doubleCalls - before, 0,
          reason: 'it does not out-roll the dodge and it is not a 100% clamp — '
              'it never reaches the expression the clamp guards');
    });

    test('it beats a dodge STANCE too', () {
      // Twinkle Toes is the deepest dodge the spell lane can buy.
      final duel = DuelEngine(bruno, alice,
          rng: CountingRandom([0.0]), elementEffects: false, baseMissPercent: 0);
      bruno
        ..charge = Spellbook.twinkleToes.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(CastAction(Spellbook.twinkleToes, MagicElement.geo),
          const ForfeitAction());
      expect(bruno.effectiveDodge, greaterThan(0));

      alice
        ..charge = Spellbook.unerring.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.unerring, MagicElement.geo));
      final hp = bruno.hp;
      alice
        ..charge = Spellbook.bolt.chargeCost
        ..element = MagicElement.geo;
      duel.resolveTurn(
          const ForfeitAction(), CastAction(Spellbook.bolt, MagicElement.geo));
      expect(hp - bruno.hp, 11, reason: 'Lightfoot ⟶ Unerring, as the web says');
    });

    test('is spent by the attack, and the next one can miss again', () {
      bruno.dodge = impossibleDodge;
      final duel = engine(CountingRandom([0.5, 0.5]));
      cast(duel, Spellbook.unerring, MagicElement.geo);
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(alice.unerringNext, isFalse, reason: 'one attack, one rider');
      final hp = bruno.hp;
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect(bruno.hp, hp, reason: 'the second Bolt found the dodge again');
    });

    test('a shield cast does not consume it', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.unerring, MagicElement.geo);
      cast(duel, Spellbook.ward, MagicElement.geo);
      expect(alice.unerringNext, isTrue, reason: 'riders wait for an attack');
    });

    test('the three riders coexist and are spent together', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.phase, MagicElement.geo);
      cast(duel, Spellbook.pierce, MagicElement.geo);
      cast(duel, Spellbook.unerring, MagicElement.geo);
      expect([alice.phaseNext, alice.pierceNext, alice.unerringNext],
          everyElement(isTrue),
          reason: 'different bypasses, so they stack rather than replace');
      cast(duel, Spellbook.bolt, MagicElement.geo);
      expect([alice.phaseNext, alice.pierceNext, alice.unerringNext],
          everyElement(isFalse),
          reason: 'one attack spends every rider it is holding');
    });
  });

  // ======================================================================
  // EXECUTE — the finisher (§7a ATTACKS)
  // ======================================================================
  group('Execute', () {
    setUp(() {
      alice = MageState(name: 'Alice');
      bruno = MageState(name: 'Bruno', maxHp: 1000);
    });

    bool critOf(TurnResult r) => r.events.whereType<DamageEvent>().first.crit;

    test('⭐ crits at 29% of max health', () {
      bruno.hp = 290;
      final duel = engine(CountingRandom());
      final r = cast(duel, Spellbook.execute, MagicElement.geo);
      expect(critOf(r), isTrue, reason: '29% is below the 30% line');
      expect(bruno.hp, 290 - 47,
          reason: 'the min roll of 31 at the default +50% crit damage');
    });

    test('does not crit at 31%', () {
      bruno.hp = 310;
      final duel = engine(CountingRandom());
      final r = cast(duel, Spellbook.execute, MagicElement.geo);
      expect(critOf(r), isFalse, reason: '31% is above the line');
      expect(bruno.hp, 310 - 31, reason: 'an ordinary attack, ordinary damage');
    });

    test('⚠️ the line is BELOW 30%, not at it', () {
      bruno.hp = 300;
      final duel = engine(CountingRandom());
      expect(critOf(cast(duel, Spellbook.execute, MagicElement.geo)), isFalse,
          reason: 'exactly 30% is not below 30%');
    });

    test('⭐ the guarantee routes through normal crit resolution', () {
      // The mutation this catches: an Execute that multiplied its own damage
      // where it is cast would still "crit" at 29% and still pass the test
      // above — but it would ignore the caster's crit damage, and it would be
      // invisible to the defender's side of the table (Composure).
      bruno.hp = 290;
      alice.critDamage = 200;
      final duel = engine(CountingRandom());
      final r = cast(duel, Spellbook.execute, MagicElement.geo);
      expect(critOf(r), isTrue);
      expect(bruno.hp, 290 - 93, reason: 'crit damage rides the guarantee: 31 x 3');
    });

    test('⭐ a Heavyhand STANCE rides the guaranteed crit', () {
      // The same claim through the seam rather than the base field: Heavyhand
      // contributes +30 crit damage, so the finisher hits for 31 x 1.8.
      bruno.hp = 290;
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.heavyhand, MagicElement.geo);
      expect(alice.effectiveCritDamage, 80, reason: '50 base + 30 stance');
      cast(duel, Spellbook.execute, MagicElement.geo);
      expect(bruno.hp, 290 - 56,
          reason: 'the stance reached the crit because the crit went through '
              'the ordinary door');
    });

    test('a guaranteed crit spends no crit roll', () {
      bruno.hp = 290;
      alice.critChance = 100;
      final guaranteed = CountingRandom();
      var duel = engine(guaranteed);
      cast(duel, Spellbook.execute, MagicElement.geo);
      expect(guaranteed.intCalls, 1,
          reason: 'the damage roll only — the crit was decided, not rolled');

      alice = MageState(name: 'Alice')..critChance = 100;
      bruno = MageState(name: 'Bruno', maxHp: 1000)..hp = 900;
      final rolled = CountingRandom();
      duel = engine(rolled);
      cast(duel, Spellbook.execute, MagicElement.geo);
      expect(rolled.intCalls, 2,
          reason: 'above the line it is an ordinary crit: damage + crit roll');
    });

    test('above the line, an ordinary no-crit build never crits', () {
      bruno.hp = 900;
      final duel = engine(CountingRandom());
      expect(critOf(cast(duel, Spellbook.execute, MagicElement.geo)), isFalse,
          reason: 'no Keen, no execute window, no crit');
    });
  });

  // ======================================================================
  // CLEANSE / PURIFY — debuff surgery (§7a INSTANTS)
  // ======================================================================
  group('Cleanse', () {
    test('removes exactly the debuff the caster named', () {
      alice.statuses.addAll([IgniteStatus(4), BlindStatus()]);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.cleanse, MagicElement.geo, choice: 'blind');

      expect(alice.statuses.whereType<BlindStatus>(), isEmpty,
          reason: 'the named debuff is the one that goes');
      expect(alice.statuses.whereType<IgniteStatus>(), isNotEmpty,
          reason: 'exactly ONE debuff — the burn is untouched');
    });

    test('lifts a DoT when that is what was named', () {
      alice.statuses.addAll([IgniteStatus(4), BlindStatus()]);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.cleanse, MagicElement.geo, choice: 'ignite');
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty,
          reason: 'DoT statuses are cleansable like any other debuff');
      expect(alice.hp, 100,
          reason: 'lifted before the end phase, so it never got its tick');
    });

    test('with no choice, takes the debuff with the most turns left', () {
      alice.statuses.addAll([
        BlindStatus(), // 3 turns
        IgniteStatus(4)..turnsLeft = 9,
      ]);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.cleanse, MagicElement.geo);
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty,
          reason: 'the default sheds the biggest running commitment');
      expect(alice.statuses.whereType<BlindStatus>(), isNotEmpty,
          reason: 'the shorter debuff is left standing');
    });

    test('never touches a buff, however long it has left', () {
      alice.statuses.addAll([
        IgniteStatus(4), // 3 turns, debuff
        HealOverTimeStatus(percentPerTurn: 1, turnsLeft: 40), // buff
      ]);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.cleanse, MagicElement.geo);
      expect(alice.statuses.whereType<HealOverTimeStatus>(), isNotEmpty,
          reason: 'the default reads the DEBUFF pool, not the longest clock');
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty);
    });

    test('casting it clean is legal and does nothing', () {
      final duel = engine(CountingRandom());
      final r = cast(duel, Spellbook.cleanse, MagicElement.geo);
      expect(r.events.whereType<SpellCastEvent>(), isNotEmpty,
          reason: 'a no-op rite still RESOLVES — it is not a fizzle');
      expect(alice.charge, 0, reason: 'and it still cost the turn');
    });

    test('a named debuff that is no longer there falls back to the default',
        () {
      alice.statuses.add(IgniteStatus(4));
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.cleanse, MagicElement.geo, choice: 'blind');
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty,
          reason: 'a stale pick still cleanses something rather than whiffing');
    });

    test('⭐ the choice serializes, and both clients decode the same move', () {
      const action = CastAction(Spellbook.cleanse, MagicElement.pyro, 'ignite');
      final wire = encodeAction(action);
      expect(wire, 'S|cleanse|pyro|ignite',
          reason: 'the status is a fourth field, not smuggled into the id');

      final back = decodeAction(wire) as CastAction;
      expect(back.spell.id, 'cleanse');
      expect(back.element, MagicElement.pyro);
      expect(back.statusChoice, 'ignite',
          reason: 'the pick survives the round trip');
      expect(encodeAction(back), wire, reason: 'encode/decode is a fixed point');
      expect(commitmentOf(wire, 'nonce'),
          commitmentOf(encodeAction(back), 'nonce'),
          reason: 'so the commitment hash is identical on both clients');
    });

    test('⚠️ a cast with no choice encodes exactly as it always did', () {
      expect(encodeAction(const CastAction(Spellbook.bolt, MagicElement.pyro)),
          'S|bolt|pyro',
          reason: 'no empty trailing field — old commitments must not shift');
      expect((decodeAction('S|cleanse|pyro') as CastAction).statusChoice, isNull,
          reason: 'three fields still decode, and mean "you pick"');
    });

    test('a status id can never smuggle a separator onto the wire', () {
      expect(
          () => encodeAction(
              const CastAction(Spellbook.cleanse, MagicElement.pyro, 'a|b')),
          throwsArgumentError,
          reason: 'a re-shaped move is a desync, not a bad cleanse');
    });
  });

  group('Purify', () {
    test('⭐ removes ALL debuffs and nothing else', () {
      alice
        ..nextOffensiveDamageScale = 0.5 // Stagger
        ..statuses.addAll([
          IgniteStatus(4),
          BlindStatus(),
          ArcaneKnowledgeStatus(3),
          HealOverTimeStatus(percentPerTurn: 5, turnsLeft: 4),
        ]);
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.purify, MagicElement.geo);

      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty);
      expect(alice.statuses.whereType<BlindStatus>(), isEmpty);
      expect(alice.nextOffensiveDamageScale, 1.0,
          reason: 'Stagger is an affliction too — the element lane\'s purge '
              'already treats it as one');
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), isNotEmpty,
          reason: 'buffs are untouched');
      expect(alice.statuses.whereType<HealOverTimeStatus>(), isNotEmpty,
          reason: 'a running HoT is a buff, not something done TO you');
      expect(alice.hp, 100, reason: 'the burn never reached the end phase');
    });

    test('a running stance survives it', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.lightfoot, MagicElement.geo);
      alice.statuses.add(IgniteStatus(4));
      cast(duel, Spellbook.purify, MagicElement.geo);
      expect(alice.effectiveDodge, 15,
          reason: 'Purify is recovery, not the mirror of Dispel');
      expect(alice.statuses.whereType<IgniteStatus>(), isEmpty);
    });

    test('casting it clean is legal and does nothing', () {
      final duel = engine(CountingRandom());
      final r = cast(duel, Spellbook.purify, MagicElement.geo);
      expect(r.events.whereType<SpellCastEvent>(), isNotEmpty);
      expect(alice.statuses, isEmpty);
    });
  });

  // ======================================================================
  // MEDITATE — duration surgery, buffs on a clock only (§7a INSTANTS)
  // ======================================================================
  group('Meditate', () {
    String meditateLine(TurnResult r) => r.events
        .whereType<BuffAppliedEvent>()
        .firstWhere((e) => e.statusId == 'meditated')
        .description;

    test('⭐ a stance gains five turns', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.lightfoot, MagicElement.geo);
      expect(alice.statuses.whereType<LightfootStatus>().single.turnsLeft, 9,
          reason: '10 turns, less the landing turn');
      cast(duel, Spellbook.meditate, MagicElement.geo);
      expect(alice.statuses.whereType<LightfootStatus>().single.turnsLeft, 13,
          reason: '9 + 5, less this turn\'s decrement — Meditate is what '
              'raises the stakes of the stance game');
    });

    test('the control: the same stance without Meditate just ticks down', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.lightfoot, MagicElement.geo);
      cast(duel, Spellbook.hasty, MagicElement.geo);
      expect(alice.statuses.whereType<LightfootStatus>().single.turnsLeft, 8,
          reason: 'a different priority-7 aux spell feeds nothing');
    });

    test('a turn-timed buff from another lane gains it too', () {
      alice.statuses.add(HealOverTimeStatus(percentPerTurn: 1, turnsLeft: 3));
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.meditate, MagicElement.geo);
      expect(alice.statuses.whereType<HealOverTimeStatus>().single.turnsLeft, 7,
          reason: 'polarity and a clock is the whole test — not which lane '
              'granted it');
    });

    test('⚠️ a turn-timed DEBUFF gains nothing', () {
      alice.statuses.add(IgniteStatus(1)); // 3 turns
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.meditate, MagicElement.geo);
      expect(alice.statuses.whereType<IgniteStatus>().single.turnsLeft, 2,
          reason: 'it is on a clock, but it is not YOURS — polarity keeps it '
              'out, or Meditate would be a self-inflicted Fester');
    });

    test('⭐ pending Empower and every next-attack rider gain nothing', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.lightfoot, MagicElement.geo);
      alice
        ..empowerMultiplier = 2
        ..phaseNext = true
        ..pierceNext = true
        ..unerringNext = true;

      final r = cast(duel, Spellbook.meditate, MagicElement.geo);

      // The ruling, stated as a count: exactly ONE thing was fed, and it was
      // the buff on a clock. If the riders were reachable, this reads 4.
      expect(meditateLine(r), contains('1 stance'),
          reason: 'only the turn-timed buff was extended');
      expect(alice.empowerMultiplier, 2, reason: 'still banked, still x2');
      expect([alice.phaseNext, alice.pierceNext, alice.unerringNext],
          everyElement(isTrue),
          reason: 'riders wait for an attack, not for a clock — a 2-charge '
              'spell must not start banking them');
    });

    test('a permanent buff has no clock to extend', () {
      alice.statuses.add(RegrowStatus(1));
      final duel = engine(CountingRandom());
      expect(meditateLine(cast(duel, Spellbook.meditate, MagicElement.geo)),
          contains('no stance'),
          reason: 'Regrow never ends, so "+5 turns" is meaningless on it');
    });

    test('deepens every stance at once', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.lightfoot, MagicElement.geo);
      cast(duel, Spellbook.keen, MagicElement.geo);
      expect(meditateLine(cast(duel, Spellbook.meditate, MagicElement.geo)),
          contains('2 stance'));
    });
  });

  // ======================================================================
  // The shared debuff pool — one answer, three spells
  // ======================================================================
  group('the debuff pool', () {
    test('sees debuff statuses and the two field-backed afflictions', () {
      alice
        ..priorityPenalty = 10
        ..nextOffensiveDamageScale = 0.5
        ..statuses.addAll([IgniteStatus(4), ArcaneKnowledgeStatus(2)]);
      expect(debuffsOn(alice).map((d) => d.id),
          ['ignite', 'waterlogged', 'stagger'],
          reason: 'a fixed order — Absolution indexes a shared RNG into it');
    });

    test('reports a timer where there is one, and 0 where there is not', () {
      alice
        ..nextOffensiveDamageScale = 0.5
        ..statuses.add(IgniteStatus(4)..turnsLeft = 6);
      final pool = debuffsOn(alice);
      expect(pool.firstWhere((d) => d.id == 'ignite').turnsLeft, 6);
      expect(pool.firstWhere((d) => d.id == 'stagger').turnsLeft, 0,
          reason: 'untimed, so it sorts last for the default pick');
      expect(defaultCleanseChoice(pool)!.id, 'ignite');
    });

    test('a stance is never in it, and always in Meditate\'s', () {
      final duel = engine(CountingRandom());
      cast(duel, Spellbook.divert, MagicElement.geo);
      expect(debuffsOn(alice), isEmpty,
          reason: 'Cleanse and Purify must never eat your own stance');
      expect(timedBuffsOn(alice), hasLength(1));
    });

    test('the shipped clocks declare themselves timed, correctly signed', () {
      expect(IgniteStatus(1), isA<TurnTimed>());
      expect(BlindStatus(), isA<TurnTimed>());
      expect(HealOverTimeStatus(percentPerTurn: 1, turnsLeft: 1),
          isA<TurnTimed>());
      expect(RegrowStatus(1), isNot(isA<TurnTimed>()),
          reason: 'permanent: there is no clock to move');
      expect(ArcaneKnowledgeStatus(1), isNot(isA<TurnTimed>()),
          reason: 'permanent, and stack-based');
      expect(CreepingDarkStatus(1), isNot(isA<TurnTimed>()),
          reason: 'stacks and activity decay, not a clock');
    });
  });

  // ======================================================================
  // The bank as a book
  // ======================================================================
  group('the bank', () {
    test('⭐ every banked spell resolves by id, so no move fails to decode', () {
      for (final s in [...Spellbook.bank, ...Spellbook.stances]) {
        expect(Spellbook.byId(s.id), same(s), reason: s.id);
      }
    });

    test('ids, costs and lanes match the §7a tables', () {
      expect({for (final s in Spellbook.bank) s.id: s.chargeCost}, {
        'pierce': 3,
        'unerring': 3,
        'execute': 4,
        'cleanse': 2,
        'purify': 5,
        'meditate': 2,
      });
      expect({for (final s in Spellbook.bank) s.id: s.priority}, {
        'pierce': SpellPriority.auxDefense,
        'unerring': SpellPriority.auxDefense,
        'execute': SpellPriority.attack,
        'cleanse': SpellPriority.auxDefense,
        'purify': SpellPriority.auxDefense,
        'meditate': SpellPriority.auxDefense,
      }, reason: 'all six point at the caster except the finisher');
    });

    test('no id collides anywhere in the promoted book', () {
      // ✅ REVERSED 2026-08-29: `all` now CONTAINS the bank (promotion), so
      // "not in all" became self-contradictory. The property that matters
      // survives as global uniqueness.
      final ids = Spellbook.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'a duplicated id makes byId ambiguous on the wire');
      for (final s in Spellbook.bank) {
        expect(ids, contains(s.id),
            reason: '${s.id} was promoted with the bank');
      }
    });

    test('every status the bank emits is catalogued', () {
      for (final id in [
        'pierce',
        'unerring',
        'cleansed',
        'cleanseEmpty',
        'purified',
        'meditated',
      ]) {
        expect(StatusCatalog.byId(id), isNotNull, reason: id);
      }
    });
  });
}
