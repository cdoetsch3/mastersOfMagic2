import 'package:flutter/material.dart';

import '../game/adventure.dart';
import '../game/enemies/enemy_def.dart';
import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
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

  /// What the take-home step actually moved, once it has been answered.
  ///
  /// ⚠️ Screen-local on purpose: the run drops its pending loot the moment it
  /// is claimed (it has to — see `GameState.takeRunLoot`), so this is the only
  /// place the "here is what you walked away with" summary can come from.
  List<InventorySlot>? _tookHome;
  List<InventorySlot> _leftBehind = const [];

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
                  if (!run.isOver && run.atSectionStart)
                    _Beat(zone: widget.zone, section: run.section),
                  if (run.isOver)
                    _Ending(
                      run: run,
                      zone: widget.zone,
                      // ⚠️ The way out is closed until the haul has been
                      // answered for — leaving with loot still pending is how
                      // the run gets reopened later holding items the player
                      // thought they had already taken.
                      onLeave: run.awaitingLootChoice
                          ? null
                          : () => Navigator.pop(context),
                    )
                  else
                    _NextFight(
                      run: run,
                      busy: _busy,
                      onFight: () => _fight(game, run),
                      onLeave: () => _leave(game),
                    ),
                  if (!run.isOver) ...[
                    const SizedBox(height: 14),
                    _Supplies(
                      game: game,
                      run: run,
                      busy: _busy,
                      onUse: (id) => _use(game, id),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (!run.isOver)
                    _Haul(run: run)
                  else if (run.awaitingLootChoice)
                    _TakeHome(
                      run: run,
                      free: game.profile.backpack.free,
                      initial: game.defaultLootChoice.toSet(),
                      busy: _busy,
                      onTake: (chosen) => _takeHome(game, chosen),
                    )
                  else if (_tookHome != null)
                    _BroughtHome(taken: _tookHome!, left: _leftBehind),
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
          playerGear: game.equipmentTotals,
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
    // ⚠️ Refusals are shown too — "You are already at full health." must be
    // seen, because a silent no-op reads as the button being broken.
    _say(outcome.message);
    setState(() {});
  }

  Future<void> _leave(GameState game) async {
    // ⭐ Ends the run only. The loot picker is what hands anything over, and it
    // renders in place of the fight panel on the next build.
    await game.leaveAdventure();
    if (mounted) setState(() {});
  }

  Future<void> _takeHome(GameState game, Set<int> chosen) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await game.takeRunLoot(chosen);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _tookHome = result.taken;
      _leftBehind = result.left;
    });
    // ⚠️ The abandoned count is said out loud. Losing things quietly is the
    // whole bug this step replaced.
    final left = result.left.length;
    _say(
      '${result.taken.length} came home with you'
      '${left == 0 ? '.' : ' — $left left behind for good.'}',
    );
  }

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.panel,
      content: Text(message, style: const TextStyle(color: AppColors.text)),
    ),
  );
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
  final GameLocation zone;

  /// ⚠️ Null while the take-home step is still open — the door out is not
  /// offered until the haul has been answered for.
  final VoidCallback? onLeave;

  const _Ending({required this.run, required this.zone, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final (title, body, colour) = switch (run.outcome) {
      RunOutcome.cleared => (
        'The zone is cleared',
        // ⭐ Arrival poses the question; the epilogue answers it. Falls back
        // rather than showing a blank — most zones have no epilogue yet.
        zone.epilogue ?? 'You beat what was waiting at the end of it.',
        AppColors.gold,
      ),
      RunOutcome.returned => (
        'You walk out',
        // ⚠️ No longer promises "everything" — what comes home is the choice
        // below, and a line that says otherwise makes the picker read as a
        // bug.
        run.awaitingLootChoice
            ? 'Decide what comes home with you.'
            : 'You walk out with what you chose.',
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

/// What the run has produced so far. ⚠️ Labelled as *not yours yet*, because
/// that is the entire push-your-luck decision.
///
/// ⭐ Mid-run only. Once the run ends the same list is shown by [_TakeHome] as
/// something to choose from, and by [_BroughtHome] as something that happened —
/// three panels because the player is being asked three different questions.
class _Haul extends StatelessWidget {
  final AdventureRun run;

  const _Haul({required this.run});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in run.pendingLoot) {
      counts[s.defId] = (counts[s.defId] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Carried so far (not yet yours)'),
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

  String _name(String defId) => _lootName(InventorySlot(defId: defId), null);

  Color _colour(String defId) => _lootColour(defId);
}

/// The name to print for a dropped slot.
///
/// ⭐ Takes the [instance] so a rolled staff reads "Ornate Heartwood
/// Quarterstaff" rather than the bare form — the picker is where the player
/// decides whether that roll is worth a slot, so it has to say what the roll
/// was. ⚠️ Falls back to the raw id for an item the catalogue no longer knows,
/// rather than crashing on a save the content patched out from under.
String _lootName(InventorySlot slot, ItemInstance? instance) {
  final def = ItemCatalogue.tryById(slot.defId);
  return def == null ? slot.defId : ItemCatalogue.displayName(def, instance);
}

Color _lootColour(String defId) {
  final def = ItemCatalogue.tryById(defId);
  return def == null ? AppColors.textFaint : rarityColour(def.rarity);
}

/// The take-home step: what the run yielded, and which of it fits.
///
/// ⭐ **Shown at every ending that kept its loot** — walking out and clearing
/// the boss alike (designer's ruling). One ritual, so the player always sees
/// the haul and always chooses; a picker that only appeared when the pack was
/// full would be a surprise exactly when it hurt most.
///
/// ⚠️ **Everything left here is gone for good.** That is stated on the panel,
/// not just in the confirmation, because the old behaviour — silently dropping
/// the overflow — cost a playtester a rare they never knew they had.
class _TakeHome extends StatefulWidget {
  final AdventureRun run;
  final int free;

  /// Rarity-first and pre-trimmed by `GameState.defaultLootChoice`, so tapping
  /// straight through never spends the last slot on a log.
  final Set<int> initial;
  final bool busy;
  final ValueChanged<Set<int>> onTake;

  const _TakeHome({
    required this.run,
    required this.free,
    required this.initial,
    required this.busy,
    required this.onTake,
  });

  @override
  State<_TakeHome> createState() => _TakeHomeState();
}

class _TakeHomeState extends State<_TakeHome> {
  late final Set<int> _picked = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final loot = widget.run.pendingLoot;
    final atCapacity = _picked.length >= widget.free;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Take home'),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ Live, because "why is that one greyed out" has to answer
              // itself.
              Text(
                'Taking ${_picked.length} of ${loot.length} — '
                '${widget.free} ${widget.free == 1 ? 'slot' : 'slots'} free',
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                'Whatever you leave is abandoned for good.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < loot.length; i++)
                _LootChoiceRow(
                  slot: loot[i],
                  instance:
                      widget.run.pendingInstances[loot[i].instanceId ?? ''],
                  picked: _picked.contains(i),
                  // ⚠️ A full selection blocks *adding*, never removing —
                  // locking the rows outright would trap the player in a
                  // selection they cannot change.
                  onTap: widget.busy || (atCapacity && !_picked.contains(i))
                      ? null
                      : () => setState(
                          () => _picked.contains(i)
                              ? _picked.remove(i)
                              : _picked.add(i),
                        ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.busy ? null : () => widget.onTake(_picked),
                  child: Text(
                    _picked.isEmpty
                        ? 'Leave it all behind'
                        : 'Take ${_picked.length} home',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LootChoiceRow extends StatelessWidget {
  final InventorySlot slot;
  final ItemInstance? instance;
  final bool picked;
  final VoidCallback? onTap;

  const _LootChoiceRow({
    required this.slot,
    required this.instance,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = onTap == null && !picked;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              picked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: picked ? AppColors.teal : AppColors.borderDim,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _lootName(slot, instance),
                style: TextStyle(
                  // ⭐ Rarity on sight (ITEMS §8) — the one cue that makes the
                  // choice quick.
                  color: dimmed ? AppColors.textFaint : _lootColour(slot.defId),
                  fontSize: 13,
                ),
              ),
            ),
            if (dimmed)
              const Text(
                'no room',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

/// The receipt: what actually came home, and what it cost to leave.
class _BroughtHome extends StatelessWidget {
  final List<InventorySlot> taken;
  final List<InventorySlot> left;

  const _BroughtHome({required this.taken, required this.left});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Brought home'),
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (taken.isEmpty)
              const Text(
                'Nothing came home.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            for (final s in taken)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _lootName(s, null),
                  style: TextStyle(color: _lootColour(s.defId), fontSize: 13),
                ),
              ),
            // ⚠️ Named, not merely counted. An abandoned item the player never
            // sees again should at least be seen once.
            if (left.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Left behind: ${left.map((s) => _lootName(s, null)).join(', ')}',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

/// Everything carried that can be used right now.
///
/// ⭐ **Generic**: it lists anything [Usable] with a real effect and shows what
/// that effect is, so a new consumable appears here with no UI change at all.
///
/// ⭐ **It states the health it is healing against.** "Restores 25% health" is
/// only half an answer; a player at 118/120 needs to see the 118 to understand
/// why the ration will be refused (`GameState.maxHp` is the same pool the use
/// actually heals, so the two cannot disagree).
///
/// ⚠️ Between encounters only (ITEMS §6b.2). Using something here is free; the
/// belt is what costs a turn mid-duel.
class _Supplies extends StatelessWidget {
  final GameState game;
  final AdventureRun run;
  final bool busy;
  final ValueChanged<String> onUse;

  const _Supplies({
    required this.game,
    required this.run,
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
    final max = game.maxHp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Supplies'),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health ${run.playerHp} / $max'
                '${run.playerHp >= max ? ' — nothing to heal' : ''}',
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              const SizedBox(height: 4),
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

/// The narrative beat for the section the player has just entered.
///
/// ⭐ **Paced, not front-loaded.** Whispering Woods' story is slowly realising
/// something is wrong; delivering that in one arrival paragraph would give the
/// answer before the player had the question.
///
/// ⚠️ Renders nothing when a zone has no beat for this section — most zones
/// have none yet, and a run must not stall waiting for text.
class _Beat extends StatelessWidget {
  final GameLocation zone;
  final int section;

  const _Beat({required this.zone, required this.section});

  @override
  Widget build(BuildContext context) {
    if (section >= zone.beats.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GamePanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.forest, color: AppColors.teal, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                zone.beats[section],
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
