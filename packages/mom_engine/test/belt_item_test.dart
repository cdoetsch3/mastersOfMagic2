/// Drinking a belt consumable (ITEMS §10.3b; rulings 2026-08-18).
///
/// The three things a potion IS: your action for the turn, a heal nothing in
/// the combat system can stop, and a beat that lands **after** the attacks.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — the potion that resolves as a cast, the one that saves a corpse,
/// the tonic that stacks, the heal that ignores gear.
library;

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The catalogue's two real shapes, as the app resolves them.
const _draught = ConsumableEffect(
  name: 'Sapwort Draught',
  healNowPercent: 20,
);
const _tonic = ConsumableEffect(
  name: 'Brookmint Tonic',
  hotPercentPerTurn: 9,
  hotTurns: 3,
);

UseItemAction _drink(ConsumableEffect effect) =>
    UseItemAction('some_potion', effect);

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno, elementEffects: false, baseMissPercent: 0);
  });

  group('the instant heal', () {
    test('is a percent of MAX health, not of what is missing', () {
      alice.hp = 50; // of 100
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.hp,
        70,
        reason: '20% of the 100 max — reading it off missing health would '
            'make the same potion better the closer to death you are',
      );
    });

    test('⭐ healing-received gear applies on top (ruled)', () {
      alice.hp = 40;
      alice.healingReceivedPercent = 50;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.hp,
        70,
        reason: '20 × 1.5 = 30 — a potion that skipped MageState.heal would '
            'heal a flat 20 and quietly make the stat lie',
      );
    });

    test('never overheals past full', () {
      alice.hp = 95;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(alice.hp, 100, reason: 'heal() caps; the event must not undo it');
    });

    test('the event reports what LANDED, not what the label promised', () {
      alice.hp = 95;
      final result = duel.resolveTurn(
        _drink(_draught),
        const ChargeAction(MagicElement.geo),
      );
      final used = result.events.whereType<ItemUsedEvent>().single;
      expect(
        used.healed,
        5,
        reason: 'a 20 in the log against a 5-point bar move is the "potions '
            'do nothing" bug report',
      );
      expect(used.item, 'Sapwort Draught', reason: 'the log names the item');
    });

    test('a heal that rounds to nothing still heals 1', () {
      final tiny = MageState(name: 'Tiny', maxHp: 20)..hp = 1;
      final other = MageState(name: 'Other');
      DuelEngine(tiny, other, elementEffects: false, baseMissPercent: 0)
          .resolveTurn(
        _drink(const ConsumableEffect(name: 'Dram', healNowPercent: 1)),
        const ChargeAction(MagicElement.geo),
      );
      expect(
        tiny.hp,
        2,
        reason: 'matches ItemEffect.healFor and RegrowStatus — an item that '
            'visibly does nothing reads as a bug',
      );
    });
  });

  group('it costs the turn, and only the turn', () {
    test('⚠️ charge and element survive the drink', () {
      alice.charge = 3;
      alice.element = MagicElement.pyro;
      alice.hp = 50;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(alice.charge, 3, reason: 'drinking is not casting: nothing paid');
      expect(
        alice.element,
        MagicElement.pyro,
        reason: 'the cycle is not ended — that is a cast\'s cost, not a '
            "potion's",
      );
    });

    test('no charge is GAINED either — it is not a channel', () {
      alice.element = MagicElement.pyro;
      alice.charge = 1;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.charge,
        1,
        reason: 'a potion turn that also channelled would be strictly better '
            'than channelling',
      );
    });

    test('the opponent still acts against a drinker', () {
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      alice.hp = 100;
      duel.resolveTurn(_drink(_draught), CastAction(Spellbook.blast));
      expect(
        alice.hp,
        lessThan(100),
        reason: 'Blast lands: drinking defends nothing',
      );
    });

    test('the cast streak is untouched — a potion is not a cast', () {
      alice.element = MagicElement.pyro;
      alice.charge = 2;
      duel.resolveTurn(
        CastAction(Spellbook.blast, MagicElement.pyro),
        const ChargeAction(MagicElement.geo),
      );
      final streakBefore = alice.streakCount;
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(
        alice.streakCount,
        streakBefore,
        reason: 'a potion that advanced the streak would let a player buy '
            'Tailwind and Absolution out of the shop',
      );
    });
  });

  group('nothing in the combat system can stop it', () {
    test('⭐ a blinded, dodged, base-miss-ridden mage still drinks', () {
      // Every accuracy dial jammed to "you cannot possibly land anything".
      final unlucky = DuelEngine(alice, bruno,
          elementEffects: false, baseMissPercent: 100);
      alice.hp = 50;
      alice.statuses.add(BlindStatus());
      bruno.dodge = 100;
      final result = unlucky.resolveTurn(
        _drink(_draught),
        const ChargeAction(MagicElement.geo),
      );
      expect(
        alice.hp,
        70,
        reason: 'the potion lane never runs the hit roll — routing it through '
            '_resolveCast is exactly the bug this pins',
      );
      expect(
        result.events.whereType<SpellMissedEvent>(),
        isEmpty,
        reason: 'a potion cannot miss, so it cannot report a miss',
      );
    });

    test('a Discharge cannot fizzle it — there is no charge to pull', () {
      alice.charge = 5;
      alice.element = MagicElement.pyro;
      alice.hp = 50;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      final result = duel.resolveTurn(
        _drink(_draught),
        CastAction(Spellbook.discharge),
      );
      expect(alice.charge, 0, reason: 'the Discharge still drains the bar');
      expect(
        alice.hp,
        70,
        reason: 'a potion has no cost to be pulled below — fizzling one would '
            'mean the belt answers to the charge economy it sits outside of',
      );
      expect(result.events.whereType<SpellFizzledEvent>(), isEmpty);
    });

    test("a shield is irrelevant: you heal through your own wall", () {
      alice.hp = 50;
      alice.shield = ActiveShield.elemental(MagicElement.geo, 30);
      duel.resolveTurn(_drink(_draught), const ChargeAction(MagicElement.geo));
      expect(alice.hp, 70);
      expect(
        alice.shield?.remaining,
        30,
        reason: 'the heal must not walk through _applyOneHit and chip the '
            'wall it is standing behind',
      );
    });
  });

  group('the potion lane sits AFTER the attacks (P3)', () {
    test('⚠️ a lethal hit kills before the drink — the corpse does not drink',
        () {
      alice.hp = 1;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      final result = duel.resolveTurn(
        _drink(_draught),
        CastAction(Spellbook.blast),
      );
      expect(
        alice.alive,
        isFalse,
        reason: '⚠️ PINNED RULING: a potion resolving before the attacks '
            'would make the belt a better shield than a shield — you drank '
            'instead of defending, and the opponent committed blind',
      );
      expect(
        result.events.whereType<ItemUsedEvent>(),
        isEmpty,
        reason: 'the lane is skipped once the duel is over, exactly as the '
            'end phase is',
      );
    });

    test('a survivable hit is topped up the same turn', () {
      alice.hp = 100;
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      final result = duel.resolveTurn(
        _drink(_draught),
        CastAction(Spellbook.blast),
      );
      final damage = result.events.whereType<DamageEvent>().single.toHp;
      expect(
        alice.hp,
        100 - damage + 20,
        reason: 'the drink lands after the hit, on the health that survived it',
      );
    });

    test('the drink is reported after the hit, before the end-of-turn ticks',
        () {
      alice.hp = 100;
      alice.statuses.add(IgniteStatus(4));
      bruno.charge = 2;
      bruno.element = MagicElement.aqua;
      final events = duel
          .resolveTurn(_drink(_draught), CastAction(Spellbook.blast))
          .events;
      final hit = events.indexWhere((e) => e is DamageEvent);
      final drink = events.indexWhere((e) => e is ItemUsedEvent);
      final burn = events.indexWhere(
        (e) => e is EffectDamageEvent && e.source == 'Ignite',
      );
      expect(hit, lessThan(drink), reason: 'attacks land first');
      expect(
        drink,
        lessThan(burn),
        reason: 'and the end phase ticks last — a drink after the burn would '
            'let a potion answer damage it never saw',
      );
    });
  });

  group('the Tonic — heal over time', () {
    test('⭐ attaches a HealOverTimeStatus that ticks the ruled 3 turns', () {
      alice.hp = 40;
      var ticks = 0;
      var healedTotal = 0;
      // ⚠️ Exactly three turns, so the expiry is pinned as tightly as the
      // ticks: a status that lingers one turn past its last heal still shows
      // a pip promising a payout that will never come.
      for (var turn = 0; turn < 3; turn++) {
        final result = duel.resolveTurn(
          turn == 0 ? _drink(_tonic) : const ChargeAction(MagicElement.pyro),
          const ChargeAction(MagicElement.geo),
        );
        for (final e in result.events.whereType<EffectHealEvent>()) {
          if (e.source != 'Brookmint Tonic') continue;
          ticks++;
          healedTotal += e.amount;
        }
      }
      expect(
        ticks,
        3,
        reason: '9% × 3 turns, first tick on the turn it is drunk — a fourth '
            'tick means advanceAndCheckExpiry is off by one',
      );
      expect(healedTotal, 27, reason: '9 per tick off a 100 max');
      expect(
        alice.statuses.whereType<HealOverTimeStatus>(),
        isEmpty,
        reason: 'it expires rather than lingering as a permanent Regrow',
      );
    });

    test('the instant heal is 0, so the event says so', () {
      alice.hp = 40;
      final used = duel
          .resolveTurn(_drink(_tonic), const ChargeAction(MagicElement.geo))
          .events
          .whereType<ItemUsedEvent>()
          .single;
      expect(
        used.healed,
        0,
        reason: 'the payout is the ticks; claiming an instant heal here would '
            'double-count it in the log',
      );
    });

    test('⚠️ a second Tonic REFRESHES rather than stacking', () {
      alice.hp = 30;
      duel.resolveTurn(_drink(_tonic), const ChargeAction(MagicElement.geo));
      final second = duel.resolveTurn(
        _drink(_tonic),
        const ChargeAction(MagicElement.geo),
      );
      expect(
        alice.statuses.whereType<HealOverTimeStatus>().length,
        1,
        reason: 'two ticking copies would let a pocketful of Tonics buy a '
            'permanent Regrow the turn cost never paid for',
      );
      expect(
        second.events
            .whereType<EffectHealEvent>()
            .where((e) => e.source == 'Brookmint Tonic')
            .length,
        1,
        reason: 'and only one tick lands on the refresh turn',
      );
    });

    test('ticks scale with healing-received gear, via the status machinery',
        () {
      alice.hp = 40;
      alice.healingReceivedPercent = 100;
      final tick = duel
          .resolveTurn(_drink(_tonic), const ChargeAction(MagicElement.geo))
          .events
          .whereType<EffectHealEvent>()
          .firstWhere((e) => e.source == 'Brookmint Tonic');
      expect(
        tick.amount,
        18,
        reason: '9 doubled — the tick goes through heal() like every other '
            'StatusHeal, which is why it rides the same lane',
      );
    });
  });

  group('both mages may drink on the same turn', () {
    test('each heals their own bar, deterministically', () {
      alice.hp = 50;
      bruno.hp = 50;
      final result = duel.resolveTurn(_drink(_draught), _drink(_draught));
      expect(alice.hp, 70);
      expect(bruno.hp, 70);
      expect(
        result.events.whereType<ItemUsedEvent>().map((e) => e.mage.name),
        ['Alice', 'Bruno'],
        reason: 'fixed mage1→mage2 order: lockstep clients must emit the same '
            'event list, and a set-iteration order would not',
      );
    });
  });
}
