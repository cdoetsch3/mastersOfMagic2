import 'dart:io';
import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The ten **stat stances** of the banked generation (TYPE_EFFECTS_DESIGN.md
/// §7a "STATUS SETS"): Lightfoot, Divert, Truesight, Keen and Heavyhand, two
/// price points each.
///
/// ⭐ Every case here is written to fail against a *specific* wrong
/// implementation, and the `reason:` names it. The four that matter most:
/// stacking instead of replacing, best-of-both merging instead of last-cast-
/// wins, mutate-and-revert instead of derivation, and a set whose two spells
/// quietly grant two different statuses.

/// `nextDouble` walks [doubles] then returns 0.99; `nextInt` walks [ints] then
/// returns 0. Two independent scripts, matching `stat_derivation_test` — the
/// hit roll draws a double, the crit and deflect rolls draw ints, and sharing
/// one script would tie every case below to the engine's internal call order.
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

/// A fixed-damage attack: `_roll(n, n)` draws no RNG, so the only [Random]
/// calls in these tests are the rolls under test.
Spell dmg(int amount) => Spell(
    id: 'dmg$amount', name: 'Dmg$amount', chargeCost: 0,
    priority: SpellPriority.attack, effect: DamageEffect(amount, amount));

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  /// A duel with the noise turned off: no element procs, no base miss — so a
  /// number that moves moved because a stance moved it.
  void newDuel({List<double> doubles = const [], List<int> ints = const []}) {
    duel = DuelEngine(alice, bruno,
        rng: ScriptedRandom(doubles: doubles, ints: ints),
        elementEffects: false,
        baseMissPercent: 0);
  }

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    newDuel();
  });

  /// [caster] casts [spell]; the other mage forfeits. Charge is topped up to
  /// exactly the cost, the way a real cycle would have paid for it.
  List<DuelEvent> castBy(MageState caster, Spell spell,
      [MagicElement element = MagicElement.pyro]) {
    caster
      ..charge = spell.chargeCost
      ..element = element;
    final action = CastAction(spell, element);
    final isAlice = identical(caster, alice);
    return duel
        .resolveTurn(isAlice ? action : const ForfeitAction(),
            isAlice ? const ForfeitAction() : action)
        .events;
  }

  void idleTurns(int n) {
    for (var i = 0; i < n; i++) {
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
    }
  }

  /// The one stance of [id] on [m] — and the assertion that there is exactly
  /// one, which is half of law 5 on its own.
  StatStanceStatus theStance(MageState m, String id) {
    final found = m.statuses.whereType<StatStanceStatus>().where((s) => s.id == id);
    expect(found, hasLength(1),
        reason: "⚠️ exactly one '$id' — two means the granters stacked "
            'instead of replacing (§7a law 5)');
    return found.first;
  }

  // ======================================================================
  // The table — costs, lane, and one status per SET
  // ======================================================================
  group('the ruled table', () {
    test('every stance is a self-targeting aux spell at priority 7', () {
      for (final s in Spellbook.stances) {
        expect(s.priority, SpellPriority.auxDefense,
            reason: '⚠️ ${s.name} at 8 would be an enemy-targeting spell, and '
                'at 9 a stance would land after the attack it exists to '
                'blunt — the split is the whole point of the lane (§7a)');
        expect(s.isHarmful, isFalse,
            reason: '${s.name} points at nobody but its caster');
        expect(s.isOffensive, isFalse, reason: s.name);
      }
      expect(Spellbook.stances, hasLength(10));
    });

    test('the charge costs are the ruled price points', () {
      const ruled = {
        'lightfoot': 2, 'twinkleToes': 4,
        'glance': 1, 'divert': 3,
        'truesight': 1, 'hawkeye': 3,
        'keen': 2, 'ardent': 4,
        'heavyhand': 2, 'overkill': 4,
      };
      expect({for (final s in Spellbook.stances) s.id: s.chargeCost}, ruled,
          reason: '⚠️ the price points ARE the design — a stance mispriced by '
              'one charge is a different spell in a different unlock bucket');
    });

    test('⭐ a SET is one status at two prices, not two statuses', () {
      // Kills the most natural wrong build: giving Twinkle Toes its own
      // status. It passes every "the buff works" test and silently lets a
      // player hold both halves of a set at once.
      const sets = {
        'lightfoot': ['lightfoot', 'twinkleToes'],
        'divert': ['glance', 'divert'],
        'truesight': ['truesight', 'hawkeye'],
        'keen': ['keen', 'ardent'],
        'heavyhand': ['heavyhand', 'overkill'],
      };
      sets.forEach((statusId, spellIds) {
        for (final id in spellIds) {
          final spell = Spellbook.stances.firstWhere((s) => s.id == id);
          final grants = (spell.effect as StanceEffect).grants;
          expect(grants.single.statusId, statusId,
              reason: "⚠️ $id must grant '$statusId', and only it — a set's "
                  'price points share ONE status or they are not a set');
        }
      });
    });

    test('the ids are free — nothing collides with the shipped book', () {
      final shipped = Spellbook.all.map((s) => s.id).toSet();
      for (final s in Spellbook.stances) {
        expect(shipped, isNot(contains(s.id)), reason: s.id);
      }
      expect(Spellbook.stances.map((s) => s.id).toSet(), hasLength(10),
          reason: 'and none of them collides with each other');
    });

    test('a cast builds a FRESH status, never a shared instance', () {
      // ⚠️ THE mutant: a const Spell holding one mutable status object. Every
      // mage in every duel in the process would then share one clock.
      final grant = (Spellbook.lightfoot.effect as StanceEffect).grants.single;
      expect(grant.build(), isNot(same(grant.build())));
    });
  });

  // ======================================================================
  // Law 5 — casting a granter REPLACES the set's status
  // ======================================================================
  group('replace on cast (law 5)', () {
    test('⭐ Twinkle Toes over a running Lightfoot replaces BOTH numbers', () {
      castBy(bruno, Spellbook.lightfoot); // +15 dodge, 10 turns
      idleTurns(3); // …now four turns old: 6 left
      expect(theStance(bruno, 'lightfoot').turnsLeft, 6);

      castBy(bruno, Spellbook.twinkleToes); // +20 dodge, 30 turns

      final s = theStance(bruno, 'lightfoot');
      expect(bruno.effectiveDodge, 20,
          reason: '⚠️ 35 is stacking (two statuses summing through the seam), '
              '15 is a granter that refused to overwrite a running stance');
      expect(s.turnsLeft, 29,
          reason: 'the new clock, decremented once by the cast turn itself — '
              "⚠️ 5 is a build that took the new magnitude and kept the old "
              "spell's remaining duration");
    });

    test('⭐ …and Lightfoot over Twinkle Toes DOWNGRADES it', () {
      // The case that kills best-of-both merging, which the doc rejected by
      // name: it survives every "the bigger spell wins" test and only shows
      // up here, where last-cast-wins must lose the player something.
      castBy(bruno, Spellbook.twinkleToes); // +20, 30 turns
      castBy(bruno, Spellbook.lightfoot); //  +15, 10 turns

      final s = theStance(bruno, 'lightfoot');
      expect(bruno.effectiveDodge, 15,
          reason: '⚠️ THE mutant: 20 is best-of-both keeping the better '
              'magnitude. Last cast wins, in both directions — a cheap stance '
              'cast over an expensive one is the player\'s mistake to make');
      expect(s.turnsLeft, 9,
          reason: '⚠️ 28 is best-of-both keeping the longer clock, which would '
              'hand out a 30-turn stance nobody priced');
    });

    test('a same-spell recast refreshes the clock', () {
      castBy(bruno, Spellbook.lightfoot);
      idleTurns(3);
      expect(theStance(bruno, 'lightfoot').turnsLeft, 6);

      castBy(bruno, Spellbook.lightfoot);
      expect(theStance(bruno, 'lightfoot').turnsLeft, 9,
          reason: '⚠️ 5 is a recast that did nothing but tick, and 15 is one '
              'that added the new duration to the old');
      expect(bruno.effectiveDodge, 15);
    });

    test('the sets do not touch each other', () {
      // Different axes, different lanes of the counter-web: a Keen cast must
      // not disturb a running Lightfoot. ⚠️ Kills a replace keyed on "any
      // stance" rather than on the status id.
      castBy(alice, Spellbook.lightfoot);
      castBy(alice, Spellbook.keen);
      castBy(alice, Spellbook.heavyhand);
      expect(alice.statuses.whereType<StatStanceStatus>().map((s) => s.id),
          containsAll(['lightfoot', 'keen', 'heavyhand']));
      expect(alice.effectiveDodge, 15);
      expect(alice.effectiveCritChance, 15);
      expect(alice.effectiveCritDamage, 80);
    });

    test('the Divert pair replaces as ONE status, both numbers together', () {
      castBy(bruno, Spellbook.divert); // 20/40, 15 turns
      expect(bruno.effectiveDeflectChance, 20);
      expect(bruno.effectiveDeflectAmount, 40);

      castBy(bruno, Spellbook.glance); // 10/20, 10 turns
      theStance(bruno, 'divert');
      expect([bruno.effectiveDeflectChance, bruno.effectiveDeflectAmount],
          [10, 20],
          reason: '⚠️ THE mutant: half a replace. [10, 40] or [20, 20] is a '
              'build treating the pair as two independent axes, which lets a '
              'player keep the better half of a stance they overwrote');
    });
  });

  // ======================================================================
  // The Truesight set's rider — cleansing Blind on cast
  // ======================================================================
  group('Truesight cleanses Blind', () {
    for (final spell in [Spellbook.truesight, Spellbook.hawkeye]) {
      test('${spell.name} burns a running Blind away', () {
        alice.statuses.add(BlindStatus());
        final events = castBy(alice, spell);

        expect(alice.statuses.whereType<BlindStatus>(), isEmpty,
            reason: '⚠️ THE mutant: a granter that only grants. §7a says '
                'EVERY Truesight granter cleanses Blind — it is the '
                "element-agnostic answer to Solar's blinder");
        expect(theStance(alice, 'truesight'), isNotNull,
            reason: 'and the stance still lands — the cleanse is a rider, not '
                'a replacement for the spell');
        expect(
            events
                .whereType<BuffAppliedEvent>()
                .map((e) => e.statusId)
                .toList(),
            ['blindLifted', 'truesight'],
            reason: '⚠️ order is the log line a player reads: the Blind lifts, '
                'THEN the stance lands');
      });
    }

    test('a stance from another set leaves Blind alone', () {
      // ⚠️ Kills a cleanse wired into `applyStance` for every stance rather
      // than onto the Truesight spells — which would make ten spells answer
      // Blind and the counter-web meaningless.
      alice.statuses.add(BlindStatus());
      castBy(alice, Spellbook.lightfoot);
      expect(alice.statuses.whereType<BlindStatus>(), hasLength(1));
    });

    test('cleansing nothing logs nothing', () {
      final events = castBy(alice, Spellbook.truesight);
      expect(
          events
              .whereType<BuffAppliedEvent>()
              .where((e) => e.statusId == 'blindLifted'),
          isEmpty,
          reason: '⚠️ a moment that fires on empty air teaches the player they '
              'were Blinded when they were not');
    });

    test('it clears the Blind in hand, and grants no immunity to the next', () {
      // The boundary the catalogue promises. Truesight is a cleanse, not a
      // ward — Grace is the ward, and it costs its own charge.
      castBy(alice, Spellbook.hawkeye);
      alice.statuses.add(BlindStatus());
      expect(alice.statuses.whereType<BlindStatus>(), hasLength(1),
          reason: '⚠️ a build that filtered Blind out while Truesight is up '
              'would quietly turn a 1-charge cleanse into a 25-turn immunity');
    });
  });

  // ======================================================================
  // Each stance moves its getter AND the roll that getter feeds
  // ======================================================================
  group('the stances reach the rolls', () {
    test('⭐ Lightfoot moves dodge, and the hit roll reads it', () {
      castBy(bruno, Spellbook.lightfoot);
      expect(bruno.effectiveDodge, 15);
      expect(bruno.dodge, 0, reason: 'and writes nothing into the base field');

      // 100 − 15 = 85 hit, so 15 miss. The scripted 10 < 15 misses.
      newDuel(doubles: [0.10]);
      castBy(alice, dmg(20));
      expect(bruno.hp, 100,
          reason: '⚠️ THE mutant: without the status in the roll the hit '
              'chance is 100, no roll is drawn at all, and Bruno is at 80');
    });

    test('⭐ Truesight moves accuracy, and buys back a dodged hit', () {
      bruno.dodge = 40; // gear, written once
      castBy(alice, Spellbook.truesight);
      expect(alice.effectiveAccuracyBonus, 20);

      // 100 + 20 − 40 = 80 hit → 20 miss; the scripted 30 lands.
      newDuel(doubles: [0.30]);
      castBy(alice, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ THE mutant: without the status the miss chance is 40 and '
              'the same roll whiffs (hp 100). The HIT is the proof the roll '
              'read the stance at resolution time');
    });

    test('⭐ Keen moves crit chance, and the crit fires because of it', () {
      castBy(alice, Spellbook.keen);
      expect(alice.effectiveCritChance, 15);
      expect(alice.critChance, 0, reason: 'the base field is untouched');

      newDuel(ints: [14]); // 14 < 15 → crit
      castBy(alice, dmg(20));
      expect(bruno.hp, 70,
          reason: '⚠️ THE mutant: reading the stored critChance leaves 0, the '
              'roll is skipped entirely, and 20 lands flat (hp 80). 20 × 1.5 '
              '= 30 is the crit');
    });

    test('⭐ Heavyhand moves crit damage, on top of the base 50', () {
      alice.critChance = 100; // gear: something must be critting first
      castBy(alice, Spellbook.heavyhand);
      expect(alice.effectiveCritDamage, 80);
      expect(alice.critDamage, 50, reason: 'the base field is untouched');

      newDuel(ints: [0]);
      castBy(alice, dmg(20));
      expect(bruno.hp, 64,
          reason: '⚠️ THE mutant: reading the stored critDamage gives 20 × 1.5 '
              '= 30 (hp 70); replacing the base instead of adding to it gives '
              '20 × 1.3 = 26 (hp 74). It ADDS: 20 × 1.8 = 36');
    });

    test('⭐ Divert is one status carrying two numbers, and the roll uses both',
        () {
      castBy(bruno, Spellbook.glance); // 10/20
      expect(bruno.statuses.whereType<StatStanceStatus>(), hasLength(1),
          reason: 'one status, not one per number');
      expect([bruno.effectiveDeflectChance, bruno.effectiveDeflectAmount],
          [10, 20]);

      newDuel(ints: [9]); // 9 < 10 → the deflect fires
      castBy(alice, dmg(20));
      expect(bruno.hp, 84,
          reason: '⚠️ three mutants, three numbers: no status leaves hp 80 (no '
              'roll is even drawn), an activation-only status leaves hp 80 '
              'again (nothing to remove), and reading the pair correctly '
              'removes 20% of 20 — 4 — so 16 lands');
    });

    test('the deflect halves land on the right stats', () {
      // ⚠️ Kills a swapped pair, which is invisible at 10/20 in a duel log and
      // very visible in the win rate: 20% of hits losing 10% is not the same
      // spell as 10% of hits losing 20%.
      castBy(bruno, Spellbook.divert);
      final s = theStance(bruno, 'divert');
      expect(s.contributionTo(CombatStat.deflectActivation), 20);
      expect(s.contributionTo(CombatStat.deflectAmount), 40);
      expect(s.contributionTo(CombatStat.dodge), 0,
          reason: 'and nothing leaks into a neighbouring axis');
    });

    test('a stance sums with gear rather than replacing it', () {
      bruno.dodge = 10; // gear lane
      castBy(bruno, Spellbook.twinkleToes); // spell lane, +20
      expect(bruno.effectiveDodge, 30,
          reason: '⚠️ 20 is a spell lane that overwrote the gear lane. §7a law '
              '4: different currencies may pay twice');
    });
  });

  // ======================================================================
  // Expiry — the stat falls back to base, and the base never moved
  // ======================================================================
  group('expiry', () {
    test('⭐ the stance expires on its ruled clock and the BASE is untouched',
        () {
      bruno.dodge = 10; // gear underneath, which must survive all of this
      castBy(bruno, Spellbook.lightfoot); // 10 turns, one spent on the cast

      idleTurns(8); // …9 turns in; one left
      expect(theStance(bruno, 'lightfoot').turnsLeft, 1);
      expect(bruno.effectiveDodge, 25);

      idleTurns(1); // the tenth turn
      expect(bruno.statuses.whereType<StatStanceStatus>(), isEmpty,
          reason: '⚠️ a 10-turn stance that outlives its tenth turn is an '
              'off-by-one every duration in the bank inherits');
      expect(bruno.dodge, 10,
          reason: '⚠️ THE mutant: mutate-and-revert leaves 25 here (never '
              'reverted) or −5 (reverted twice). Derivation cannot get this '
              'wrong, which is exactly why the seam exists');
      expect(bruno.effectiveDodge, 10,
          reason: 'and the derived value falls back to gear on its own');
    });

    test('the long price point really is the long one', () {
      castBy(alice, Spellbook.overkill); // 30 turns
      idleTurns(20);
      expect(theStance(alice, 'heavyhand').turnsLeft, 9,
          reason: '⚠️ kills a duration read off the cheap price point — the '
              'extra charge buys the clock, and nothing else here');
      expect(alice.effectiveCritDamage, 100);
    });

    test('an expired stance stops feeding its roll', () {
      alice.critChance = 100;
      castBy(alice, Spellbook.heavyhand); // +30 crit damage, 12 turns
      idleTurns(11);
      expect(alice.statuses.whereType<StatStanceStatus>(), isEmpty);

      newDuel(ints: [0]);
      castBy(alice, dmg(20));
      expect(bruno.hp, 70,
          reason: '⚠️ hp 64 is a contribution still being summed after the '
              'status was removed — a cached sum, not a derived one');
    });
  });

  // ======================================================================
  // Wiring — catalogue, polarity, snapshot
  // ======================================================================
  group('wiring', () {
    const lasting = ['lightfoot', 'divert', 'truesight', 'keen', 'heavyhand'];

    test('every stance is catalogued as a lasting BUFF', () {
      for (final id in lasting) {
        final info = StatusCatalog.byId(id);
        expect(info, isNotNull, reason: "'$id' is not in the catalogue");
        expect(info!.lingers, isTrue, reason: '$id shows as a HUD pip');
        expect(info.polarity, StatusPolarity.buff,
            reason: "⚠️ '$id' classified anything else drops out of Dispel's "
                "pool and into Cleanse's — the counter-web reads polarity, "
                'never a status name');
      }
      expect(StatusCatalog.byId('blindLifted')!.lingers, isFalse,
          reason: 'the cleanse is a moment, not a condition you carry');
    });

    test('the runtime status agrees with its catalogue entry, id by id', () {
      for (final spell in Spellbook.stances) {
        for (final grant in (spell.effect as StanceEffect).grants) {
          final status = grant.build();
          expect(StatusCatalog.polarityOf(status.id), status.polarity,
              reason: "⚠️ '${status.id}' must read the same in the catalogue "
                  'as it does in the engine');
        }
      }
    });

    test('every statusId the stance lane emits is catalogued', () {
      // The same scrape `status_catalog_test` runs over duel.dart — the rules
      // for these spells live in their own file, so the guard has to follow
      // them there or ten spells could ship with no player-facing text.
      //
      // ⚠️ Two spellings since the two banked lanes' effects were unified: the
      // named `statusId:`/`momentId:` of a cleanse rider, and the positional
      // first argument of a [StanceGrant]. Missing the second would have let
      // the whole spell table slip past this guard silently — which is exactly
      // what it did the moment the shape changed.
      final src = File('lib/src/bank_stances.dart').readAsStringSync() +
          File('lib/src/spellbook.dart').readAsStringSync();
      final emitted = RegExp(
              r"(?:statusId|momentId):\s*'([a-zA-Z]+)'|StanceGrant\('([a-zA-Z]+)'")
          .allMatches(src)
          .map((m) => m.group(1) ?? m.group(2)!)
          .toSet()
        // The one id that reaches an event through a named constant rather
        // than a literal, so the scrape cannot see it.
        ..add(blindLiftedStatusId);
      expect(emitted, containsAll(['lightfoot', 'divert', 'blind']),
          reason: 'the scrape found nothing useful — bad regex?');
      for (final id in emitted) {
        expect(StatusCatalog.byId(id), isNotNull,
            reason: "the stance lane emits '$id' with no StatusCatalog entry");
      }
    });

    test('the snapshot reports each stance with its number and its clock', () {
      castBy(alice, Spellbook.twinkleToes);
      castBy(alice, Spellbook.hawkeye);
      castBy(alice, Spellbook.ardent);
      castBy(alice, Spellbook.overkill);
      final snap = StatusSnapshot.of(alice);

      expect(snap['lightfoot']!.magnitude, 20);
      expect(snap['truesight']!.magnitude, 35);
      expect(snap['keen']!.magnitude, 25);
      expect(snap['heavyhand']!.magnitude, 50);
      expect(snap['lightfoot']!.turnsLeft, 26,
          reason: '⚠️ a pip with no clock (0) cannot tell a player whether the '
              'stance they are counting on survives the next exchange');
    });

    test('⭐ the snapshot carries BOTH of Divert\'s numbers', () {
      castBy(bruno, Spellbook.divert);
      final view = StatusSnapshot.of(bruno)['divert']!;
      expect([view.magnitude, view.secondaryMagnitude], [20, 40],
          reason: '⚠️ THE mutant: reporting one number. The pair is the whole '
              'stance — an activation chance alone tells the player nothing '
              'about what a deflection is worth');
      expect(view.turnsLeft, 14);
    });

    test('a stance is visible to the lockstep snapshot the turn it lands', () {
      // ⚠️ Kills a status added outside the event stream: the HUD replays
      // frames, so a stance that only appears in the end-of-turn state would
      // pop into existence a beat late on both clients.
      alice
        ..charge = Spellbook.keen.chargeCost
        ..element = MagicElement.pyro;
      final result = duel.resolveTurn(
          CastAction(Spellbook.keen, MagicElement.pyro), const ForfeitAction());
      expect(result.frames.any((f) => f.mage1['keen'] != null), isTrue);
    });
  });
}
