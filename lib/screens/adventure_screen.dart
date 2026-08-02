import 'package:flutter/material.dart';

import '../game/adventure.dart';
import '../game/enemies/enemy_def.dart';
import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/opponent_driver.dart';
import '../game/world.dart';
import '../ui/app_theme.dart';
import 'duel_screen.dart';
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

    // ⭐ HP carries between encounters — that is the whole tension of pushing
    // on. Charge and shields reset, per GAME_DESIGN's adventure loop.
    var survivingHp = run.playerHp;
    var won = false;

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
          playerStartingHp: run.playerHp,
          onResult: (playerWon) => won = playerWon,
          onPlayerHpRemaining: (hp) => survivingHp = hp,
        ),
      ),
    );

    if (!mounted) return;
    if (won) {
      await game.winEncounter(remainingHp: survivingHp);
    } else {
      await game.loseEncounter();
    }
    if (mounted) setState(() => _busy = false);
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
