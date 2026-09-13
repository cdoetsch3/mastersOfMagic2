// The enemy combat-stats seam (KINETIC_CONTRACT §2.2) — Phase C1 of the
// Kinetic wave. `EnemyDef.combatStats` reaches a campaign duel through
// `OpponentDriver.opponentCombatStats`, applied by `DuelController._buildMage`
// beside the gear application. This suite pins:
//   1. the seam carries each of the six stats, field-by-field;
//   2. a Q1 encounter is byte-identical to before the seam existed;
//   3. dodge/crit/deflect set on an EnemyDef actually change a duel's outcome;
//   4. RemoteDuelDriver (PvP) never sees this seam.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:mom_engine/mom_engine.dart';

/// Deterministic RNG mirroring `packages/mom_engine/test/combat_stats_test.dart`'s
/// `ScriptedRandom`: scripted values, then 0.99 forever (so a guarded
/// crit/deflect chance > 0 always fires, and `nextInt` always takes the
/// roll's minimum).
class _ScriptedRandom implements Random {
  final List<double> doubles;
  var _i = 0;
  _ScriptedRandom([this.doubles = const []]);
  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// A damage-neutral, HP-neutral archetype — a vehicle for these tests, never
/// shipped content, so the arithmetic below isn't coupled to a real
/// archetype's tuning.
const _neutralArchetype = EnemyArchetype(
  id: 'test_neutral',
  name: 'Test Neutral',
  tier: EnemyTier.common,
  hpScale: 1.0,
  damageScale: 1.0,
  intelligence: 1,
  moveCount: 1,
  minMoveCost: 0,
  maxMoveCost: 1,
  teaches: 'test fixture only',
);

Spell _probe() => Spell(
  id: 'probe',
  name: 'Probe',
  chargeCost: 0,
  priority: 9,
  effect: const DamageEffect(20, 20),
);

EnemyDef _synthDef(EnemyCombatStats stats) => EnemyDef(
  id: 'test_dummy',
  name: 'Test Dummy',
  zoneId: 'whispering_woods',
  rank: EnemyRank.common,
  archetype: _neutralArchetype,
  elements: const [MagicElement.flora],
  lore: 'A fixture used only by enemy_combat_stats_test.dart, never shipped.',
  moves: [_probe()],
  combatStats: stats,
);

/// The full seam, exactly as a campaign encounter builds it: `EnemyDef` →
/// `EnemyEncounter` → `LocalAiDriver` → `DuelController._buildMage`.
MageState _enemyFor(EnemyDef def, {int level = 1}) => DuelController(
  loadout: Loadout.starter,
  driver: LocalAiDriver(
    persona: EnemyEncounter(def: def, level: level).toPersona(),
    enemy: def,
    rng: Random(1),
  ),
  playerLevel: level,
).enemy;

void main() {
  group('the seam carries each combat stat, field-by-field', () {
    // ⚠️ One field nonzero per test, distinct values, so a mutant that swaps
    // two fields (e.g. writes dodge into accuracyBonus) or drops one entirely
    // (the "seam drops deflectAmount" class) is caught by the OTHER fields
    // staying at their engine baseline while only the intended one moves.
    test('accuracyBonus', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(accuracyBonus: 11)));
      expect(e.accuracyBonus, 11, reason: 'the seam dropped accuracyBonus');
      expect(e.dodge, 0);
      expect(e.critChance, 0);
      expect(e.critDamage, 50, reason: 'unset critDamage must stay at engine base');
      expect(e.deflectChance, 0);
      expect(e.deflectAmount, 0);
    });

    test('dodge', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(dodge: 13)));
      expect(e.accuracyBonus, 0);
      expect(e.dodge, 13, reason: 'the seam dropped dodge');
      expect(e.critChance, 0);
      expect(e.critDamage, 50);
      expect(e.deflectChance, 0);
      expect(e.deflectAmount, 0);
    });

    test('critChance', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(critChance: 17)));
      expect(e.accuracyBonus, 0);
      expect(e.dodge, 0);
      expect(e.critChance, 17, reason: 'the seam dropped critChance');
      expect(e.critDamage, 50);
      expect(e.deflectChance, 0);
      expect(e.deflectAmount, 0);
    });

    test('critDamage adds to the engine\'s base 50', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(critDamage: 19)));
      expect(e.accuracyBonus, 0);
      expect(e.dodge, 0);
      expect(e.critChance, 0);
      expect(
        e.critDamage,
        69,
        reason: 'the seam dropped critDamage, or overwrote the base instead of adding to it',
      );
      expect(e.deflectChance, 0);
      expect(e.deflectAmount, 0);
    });

    test('deflectChance', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(deflectChance: 23)));
      expect(e.accuracyBonus, 0);
      expect(e.dodge, 0);
      expect(e.critChance, 0);
      expect(e.critDamage, 50);
      expect(e.deflectChance, 23, reason: 'the seam dropped deflectChance');
      expect(e.deflectAmount, 0);
    });

    test('deflectAmount', () {
      final e = _enemyFor(_synthDef(const EnemyCombatStats(deflectAmount: 29)));
      expect(e.accuracyBonus, 0);
      expect(e.dodge, 0);
      expect(e.critChance, 0);
      expect(e.critDamage, 50);
      expect(e.deflectChance, 0);
      expect(e.deflectAmount, 29, reason: 'the seam dropped deflectAmount');
    });

    test('all six at once, so a "clobbers the others" mutant is also caught', () {
      final e = _enemyFor(
        _synthDef(
          const EnemyCombatStats(
            accuracyBonus: 11,
            dodge: 13,
            critChance: 17,
            critDamage: 19,
            deflectChance: 23,
            deflectAmount: 29,
          ),
        ),
      );
      expect(e.accuracyBonus, 11);
      expect(e.dodge, 13);
      expect(e.critChance, 17);
      expect(e.critDamage, 69);
      expect(e.deflectChance, 23);
      expect(e.deflectAmount, 29);
    });
  });

  group('⭐ THE INVARIANCE PIN', () {
    final fawn = WhisperingWoodsBestiary.listeningFawn;

    test('a real Q1 def ships stat-free', () {
      expect(
        fawn.combatStats,
        EnemyCombatStats.none,
        reason: 'a shipped Q1 EnemyDef must not carry combat stats — '
            'ITEMS §9b.8 ruling 5',
      );
    });

    test(
      'a Whispering Woods encounter builds an enemy MageState with every '
      'combat stat at the engine baseline',
      () {
        final e = _enemyFor(fawn, level: 5);
        expect(e.accuracyBonus, 0);
        expect(e.dodge, 0);
        expect(e.critChance, 0);
        expect(e.critDamage, 50, reason: 'the engine\'s own inert default');
        expect(e.deflectChance, 0);
        expect(e.deflectAmount, 0);
      },
    );

    test(
      'the seam-built mage is byte-identical to one built the pre-seam way, '
      'and a seeded duel against it produces identical events',
      () {
        const level = 5;

        // "Pre-seam": exactly the arithmetic `_buildMage` used before
        // `combatStats` existed — level baseline × archetype hpScale, with
        // `powerScale` set, and none of the six stat fields ever touched.
        MageState preSeamEnemy() => MageState(
          name: fawn.name,
          level: level,
          maxHp: (MageState.scaledMaxHp(level) * fawn.archetype.hpScale).round(),
        )..powerScale = fawn.archetype.damageScale;

        final seamEnemy = _enemyFor(fawn, level: level);
        final oldEnemy = preSeamEnemy();

        expect(seamEnemy.maxHp, oldEnemy.maxHp);
        expect(seamEnemy.powerScale, oldEnemy.powerScale);
        expect(seamEnemy.accuracyBonus, oldEnemy.accuracyBonus);
        expect(seamEnemy.dodge, oldEnemy.dodge);
        expect(seamEnemy.critChance, oldEnemy.critChance);
        expect(seamEnemy.critDamage, oldEnemy.critDamage);
        expect(seamEnemy.deflectChance, oldEnemy.deflectChance);
        expect(seamEnemy.deflectAmount, oldEnemy.deflectAmount);

        // Now prove it at the DUEL level: two fights, one whose enemy never
        // goes near the new seam (`oldEnemy`) and one built through the full
        // `EnemyDef` → `EnemyEncounter` → `LocalAiDriver` →
        // `DuelController._buildMage` chain (`seamEnemy2`), driven by
        // identical actions on an identically-seeded engine.
        final probe = _probe();
        final playerA = MageState(name: 'You', level: level);
        final playerB = MageState(name: 'You', level: level);
        final engineA = DuelEngine(
          playerA,
          preSeamEnemy(),
          rng: Random(42),
          baseMissPercent: 0,
        );
        final engineB = DuelEngine(
          playerB,
          _enemyFor(fawn, level: level),
          rng: Random(42),
          baseMissPercent: 0,
        );

        // 4 turns × 20 dmg = 80, comfortably under a level-5 fawn's ~94 HP
        // (hpScale 0.80) — the loop must not outrun the duel ending early.
        for (var turn = 0; turn < 4; turn++) {
          expect(engineA.isOver, isFalse, reason: 'turn $turn: fixture ran out of HP budget');
          playerA
            ..charge = 0
            ..element = MagicElement.flora;
          playerB
            ..charge = 0
            ..element = MagicElement.flora;
          final rA = engineA.resolveTurn(
            CastAction(probe, MagicElement.flora),
            const ForfeitAction(),
          );
          final rB = engineB.resolveTurn(
            CastAction(probe, MagicElement.flora),
            const ForfeitAction(),
          );
          expect(
            rB.events.map((e) => e.toString()).toList(),
            rA.events.map((e) => e.toString()).toList(),
            reason: 'turn $turn diverged — the seam changed a stat-free Q1 fight',
          );
          expect(playerB.hp, playerA.hp, reason: 'turn $turn HP diverged');
          expect(engineB.mage2.hp, engineA.mage2.hp, reason: 'turn $turn HP diverged');
        }
      },
    );
  });

  group('a set stat actually reaches the roll', () {
    test('dodge turns a would-be hit into a miss', () {
      final enemy = _enemyFor(_synthDef(const EnemyCombatStats(dodge: 30)));
      expect(enemy.dodge, 30, reason: 'sanity: the seam carried it');
      final player = MageState(name: 'You', level: 1);
      // 100 accuracy, 30 dodge, baseMissPercent 0 → 30 miss chance.
      // 0.2 → 20 < 30 → miss (packages/mom_engine/test/combat_stats_test.dart's
      // own dodge case).
      final duel = DuelEngine(
        player,
        enemy,
        rng: _ScriptedRandom([0.2]),
        baseMissPercent: 0,
      );
      final before = enemy.hp;
      player
        ..charge = 0
        ..element = MagicElement.pyro;
      duel.resolveTurn(CastAction(_probe(), MagicElement.pyro), const ForfeitAction());
      expect(
        enemy.hp,
        before,
        reason: 'the seam-carried dodge should have turned this hit into a miss',
      );
    });

    test('deflect removes a percent of an incoming hit', () {
      final enemy = _enemyFor(
        _synthDef(const EnemyCombatStats(deflectChance: 100, deflectAmount: 40)),
      );
      final player = MageState(name: 'You', level: 1);
      final duel = DuelEngine(
        player,
        enemy,
        rng: _ScriptedRandom(),
        baseMissPercent: 0,
      );
      final before = enemy.hp;
      player
        ..charge = 0
        ..element = MagicElement.pyro;
      duel.resolveTurn(CastAction(_probe(), MagicElement.pyro), const ForfeitAction());
      expect(
        before - enemy.hp,
        12,
        reason: '40% of 20 = 8 removed, 12 lands — the seam-carried deflect fired',
      );
    });

    test('crit chance and crit damage together raise the enemy\'s own attack', () {
      final enemy = _enemyFor(
        _synthDef(const EnemyCombatStats(critChance: 100, critDamage: 20)),
      );
      expect(enemy.critDamage, 70, reason: '50 engine base + 20 archetype lean');
      expect(enemy.powerScale, 1.0, reason: 'the fixture archetype is damage-neutral');
      final player = MageState(name: 'You', level: 1);
      final duel = DuelEngine(
        player,
        enemy,
        rng: _ScriptedRandom(),
        baseMissPercent: 0,
      );
      final before = player.hp;
      enemy
        ..charge = 0
        ..element = MagicElement.pyro;
      duel.resolveTurn(const ForfeitAction(), CastAction(_probe(), MagicElement.pyro));
      expect(
        before - player.hp,
        34,
        reason: '20 × (100+70)/100 = 34 — the seam-carried crit lean landed',
      );
    });
  });

  group('PvP guard', () {
    test('RemoteDuelDriver ignores the seam — its stats come from the gear wire only', () {
      final driver = RemoteDuelDriver(
        roomId: 'room',
        isHost: true,
        masterSeed: 1,
        opponentName: 'Rival',
        opponentLevel: 10,
        opponentGear: const ItemModifiers(critChance: 5),
        opponentRating: 1200,
      );
      expect(
        driver.opponentCombatStats,
        EnemyCombatStats.none,
        reason: 'a human rival must never get archetype-flavoured combat stats '
            '— only opponentGear counts in PvP',
      );
    });
  });
}
