import 'package:flutter/material.dart';

import '../game/adventure.dart';
import '../game/enemies/enemy_def.dart';
import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/opponent_driver.dart';
import '../game/world.dart';
import '../ui/app_theme.dart';
import 'duel_screen.dart';
import 'level_up_screen.dart';
import 'tabs/inventory_tab.dart' show rarityColour;

/// One run through a zone: what is in front of you, how far in you are, and
/// the only question that matters — press on, or walk out with what you have.
class AdventureScreen extends StatefulWidget {
  final GameLocation zone;

  const AdventureScreen({super.key, required this.zone});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final run = game.run;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: Text(widget.zone.name),
        automaticallyImplyLeading: false,
      ),
      body: run == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Progress(run: run),
                  const SizedBox(height: 14),
                  if (run.isOver)
                    _Ending(run: run, onLeave: () => Navigator.pop(context))
                  else
                    _NextFight(
                      run: run,
                      busy: _busy,
                      onFight: () => _fight(game, run),
                      onLeave: () => _leave(game),
                    ),
                  if (!run.isOver) ...[
                    const SizedBox(height: 14),
                    _Consumables(
                      game: game,
                      busy: _busy,
                      onUse: (id) => _use(game, id),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _Haul(run: run),
                ],
              ),
            ),
    );
  }

  Future<void> _fight(GameState game, AdventureRun run) async {
    final encounter = run.current;
    if (encounter == null || _busy) return;
    setState(() => _busy = true);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuelScreen(
          loadout: game.profile.activePreset.toLoadout(),
          driver: LocalAiDriver(
            persona: encounter.toPersona(),
            enemy: encounter.def,
          ),
          campaign: true,
          playerLevel: game.profile.level,
          // ⭐ HP carries between encounters — that is the whole tension of
          // pushing on. Charge and shields reset; only health persists.
          playerStartingHp: run.playerHp,
          // ⚠️ Settled here, awaited by the end screen, so the loot exists
          // before it is drawn.
          onSettle: (won, remainingHp) async {
            if (!won) {
              await game.loseEncounter();
              return const [];
            }
            return game.winEncounter(remainingHp: remainingHp);
          },
        ),
      ),
    );

    if (!mounted) return;
    // ⚠️ This path pushes DuelScreen directly rather than going through
    // launchDuel, so the level-up has to be surfaced here too — otherwise
    // levelling mid-run is silent, which is the most likely place to level.
    await _showLevelUpIfAny(game);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _showLevelUpIfAny(GameState game) async {
    final level = game.pendingLevelUp;
    final from = game.pendingLevelUpFrom;
    if (level == null || !mounted) return;
    game.acknowledgeLevelUp();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelUpScreen(from: from ?? level - 1, to: level),
      ),
    );
  }

  Future<void> _use(GameState game, String defId) async {
    final outcome = await game.useItem(defId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.panel,
        content: Text(
          outcome.message,
          style: const TextStyle(color: AppColors.text),
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _leave(GameState game) async {
    await game.leaveAdventure();
    if (mounted) setState(() {});
  }
}

class _Progress extends StatelessWidget {
  final AdventureRun run;

  const _Progress({required this.run});

  @override
  Widget build(BuildContext context) {
    // ⭐ "encounter 3 of 9" up front, and it is true — the whole run was rolled
    // before the first fight.
    final done = run.index;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            run.isFinished
                ? 'Run complete'
                : 'Encounter ${run.encounterNumber} of ${run.encounterCount}',
            style: const TextStyle(color: AppColors.text, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < run.encounterCount; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.only(right: 3),
                    color: i < done
                        ? AppColors.teal
                        : (run.encounters[i].def.rank == EnemyRank.common
                              ? AppColors.borderDim
                              : AppColors.gold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Health carried in: ${run.playerHp}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NextFight extends StatelessWidget {
  final AdventureRun run;
  final bool busy;
  final VoidCallback onFight;
  final VoidCallback onLeave;

  const _NextFight({
    required this.run,
    required this.busy,
    required this.onFight,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final next = run.current;
    if (next == null) return const SizedBox.shrink();
    final def = next.def;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.name,
                  style: const TextStyle(color: AppColors.text, fontSize: 18),
                ),
              ),
              Text(
                'Lv ${next.level}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${def.rank.label} · ${def.archetype.name}',
            style: const TextStyle(color: AppColors.gold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // ⭐ The lore channel: readable by anyone who cares, ignorable by
          // everyone else.
          Text(
            def.lore,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onFight,
                  child: Text(run.atBoss ? 'Face it' : 'Fight'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onLeave,
                  child: const Text('Return to town'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            // ⚠️ The stake, stated before the choice rather than after it.
            'Leaving keeps everything you have found. Losing keeps nothing.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _Ending extends StatelessWidget {
  final AdventureRun run;
  final VoidCallback onLeave;

  const _Ending({required this.run, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final (title, body, colour) = switch (run.outcome) {
      RunOutcome.cleared => (
        'The zone is cleared',
        'You beat what was waiting at the end of it.',
        AppColors.gold,
      ),
      RunOutcome.returned => (
        'You walk out',
        'Everything you found comes with you.',
        AppColors.teal,
      ),
      RunOutcome.died => (
        'You are carried out',
        'The run is over, and its loot is gone.',
        AppColors.ember,
      ),
      RunOutcome.running => ('', '', AppColors.text),
    };
    return GamePanel(
      child: Column(
        children: [
          Text(title, style: TextStyle(color: colour, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onLeave,
            child: const Text('Back to the map'),
          ),
        ],
      ),
    );
  }
}

/// What the run has produced so far. ⚠️ Labelled as *not yours yet* while the
/// run is live, because that is the entire push-your-luck decision.
class _Haul extends StatelessWidget {
  final AdventureRun run;

  const _Haul({required this.run});

  @override
  Widget build(BuildContext context) {
    if (run.outcome == RunOutcome.died) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final s in run.pendingLoot) {
      counts[s.defId] = (counts[s.defId] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          run.lootIsBanked ? 'Brought home' : 'Carried so far (not yet yours)',
        ),
        GamePanel(
          child: counts.isEmpty
              ? const Text(
                  'Nothing yet.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12),
                )
              : Column(
                  children: [
                    for (final e in counts.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name(e.key),
                                style: TextStyle(
                                  color: _colour(e.key),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '×${e.value}',
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  String _name(String defId) {
    final def = ItemCatalogue.tryById(defId);
    return def == null ? defId : ItemCatalogue.displayName(def, null);
  }

  Color _colour(String defId) {
    final def = ItemCatalogue.tryById(defId);
    return def == null ? AppColors.textFaint : rarityColour(def.rarity);
  }
}

/// Everything carried that can be used right now.
///
/// ⭐ **Generic**: it lists anything [Usable] with a real effect and shows what
/// that effect is, so a new consumable appears here with no UI change at all.
///
/// ⚠️ Between encounters only (ITEMS §6b.2). Using something here is free; the
/// belt is what costs a turn mid-duel.
class _Consumables extends StatelessWidget {
  final GameState game;
  final bool busy;
  final ValueChanged<String> onUse;

  const _Consumables({
    required this.game,
    required this.busy,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final slot in game.profile.backpack.contents) {
      final def = ItemCatalogue.tryById(slot.defId);
      if (def is Usable && !(def as Usable).effect.isNothing) {
        counts[slot.defId] = (counts[slot.defId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Consumables'),
        GamePanel(
          child: Column(
            children: [
              for (final e in counts.entries)
                _ConsumableRow(
                  def: ItemCatalogue.byId(e.key),
                  count: e.value,
                  onUse: busy ? null : () => onUse(e.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsumableRow extends StatelessWidget {
  final ItemDef def;
  final int count;
  final VoidCallback? onUse;

  const _ConsumableRow({required this.def, required this.count, this.onUse});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ItemCatalogue.displayName(def, null),
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              // ⭐ Built from the effect, so the number and its text cannot
              // disagree.
              Text(
                (def as Usable).effect.describe,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          '×$count',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onUse, child: const Text('Use')),
      ],
    ),
  );
}
